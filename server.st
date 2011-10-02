Namespace current: Shampoo [

    Exception subclass: ClientDisconnected [
        <category: 'Shampoo-Server'>
        <comment: 'I am just an exception. My instances point out that a client
has disconnected from the server.'>
    ]

    Exception subclass: FatalError [
        <category: 'Shampoo-Server'>
        <comment: 'I am just an exception. My instances represent a fatal,
unrecoverable error.'>
    ]

    Object subclass: ShampooTranscript [
        <category: 'Shampoo-Server'>
        <comment: 'I am a network-oriented version of the standard GNU Smalltalk
Transcript. I send every text being printed to a client, but also mirror the
text to the standard output, as the original Transcript does'>

        servers := Set new.
        serversMutex := Semaphore forMutualExclusion.
        oldAssoc := nil.

        ShampooTranscript class >> message: aString [
            <category: 'transcript'>
            self fallback: aString.
            serversMutex critical: [servers do: [:each | each echo: aString]]
        ]

        ShampooTranscript class >> fallback: aString [
            <category: 'transcript'>
            oldAssoc ifNotNil: [oldAssoc key perform: oldAssoc value with: aString].
        ]

        ShampooTranscript class >> add: aServer [
            <category: 'setup'>
            serversMutex critical: [servers add: aServer]
        ]
            
        ShampooTranscript class >> remove: aServer [
            <category: 'setup'>
            serversMutex critical: [servers remove: aServer]
        ]
    
        ShampooTranscript class >> install [
            <category: 'installation'>
            | message |
            message := Transcript message.
            (message key = ShampooTranscript and: [message value = #message:])
                ifFalse: [oldAssoc := message.
                          Transcript message: (ShampooTranscript -> #message:)]
        ]
    ]

    Object subclass: RequestFetcher [
        <category: 'Shampoo-Server'>
        <comment: 'My instances incapsulate a fetching process. Long XML messages
often come in parts, so my intention is to fetch a single message from a socket
until a parser will able to parse it.'>

        | sock stanza |

        RequestFetcher class >> fetch: aSocket [
            <category: 'instance creation'>
            ^self new init: aSocket; fetch
        ]
    
        init: aSocket [
            <category: 'private'>
            sock := aSocket.
            stanza := String new writeStream
        ]

        parsed [
            <category: 'private'>
            ^ShampooXML.ShNode from: stanza contents
        ]

        fetch [
            <category: 'private'>
            [sock isPeerAlive] whileTrue:
                [stanza nextPutAll: (sock upTo: $>); nextPut: $>.
                 [^self parsed]
                    on: ShampooXML.Malformed
                    do: [:e | nil]].
            sock isPeerAlive ifFalse: [ClientDisconnected new signal]
        ]
    ]

    Object subclass: ConnectionState [
        <category: 'Shampoo-Server'>
        <comment: 'My subclasses represent various states of a user session on
the server. Yes, the server aims to look like as a finite state machine.'>

        | connection |

        ConnectionState class >> of: aConnection [
            <category: 'instance creation'>
            ^(self new)
                connection: aConnection;
                yourself
        ]

        connection: aConnection [
            <category: 'private'>
            connection := aConnection
        ]

        switchTo: aConnectionStateClass [
            <category: 'fsm'>
            connection state: (aConnectionStateClass of: connection)
        ]

        process: aRequest [
            <category: 'fsm'>
            self subclassResponsibility
        ]

        echo: aString [
            <category: 'fsm'>
            "Do nothing by default. 'self subclassResponsibility' would be better?"
        ]
    ]

    ConnectionState subclass: NotAuthorizedState [
        <category: 'Shampoo-Server'>
        <comment: 'My instances represent a non-authorized state of a user
session. When entered, I send a magic string to a client. If the client will
prove his identity, I will switch the session to the AutiorizedState.'>
        | magic |

        register [
            <category: 'other'>
            "Send a magic number to a client"
            connection send: (MagicResponse number: self magic)
        ]

        process: aRequest [
            <category: 'fsm'>
            "Anti-If campaign probably hates me."
            aRequest class == LoginRequest
                ifTrue: [^self checkLogin: aRequest]
                ifFalse: [self fatal]
        ]

        checkLogin: aRequest [
            <category: 'private'>
            "Really hates."
            (connection server creds with: self magic) = aRequest creds
                ifTrue: [self switchTo: AuthorizedState.
                         ^ServerInfoResponse id: aRequest id]
                ifFalse: [self fatal]
        ]

        fatal [
            <category: 'private'>
            "TODO: Drop this method?"
            FatalError new signal
        ]

        magic [
            <category: 'private'>
            ^magic ifNil: [magic := Random between: 0 and: 16rFFFFFFFF]
        ]
    ]

    ConnectionState subclass: AuthorizedState [
        <category: 'Shampoo-Server'>
        <comment: 'My instances represent an authorized state of a user session.
This state is also can be called "active". The most of Shampoo requests are
processed in this state.'>

        process: aRequest [
            <category: 'fsm'>
            ^aRequest execute
        ]

        echo: aString [
            <category: 'fsm'>
            connection send: (EchoResponse id: -1 text: aString)
        ]
    ]

    Object subclass: ClientConnection [
        <category: 'Shampoo-Server'>
        <comment: 'My instances represent a client connection. A client connection
is actually a finite state machine, see ConnectionState class and its subclasses'>

        | sock server disconnectedHandler state |

        ClientConnection class >> on: aSocket onDisconnect: aBlock parent: aServer [
            <category: 'instance creation'>
            ^self new on: aSocket onDisconnect: aBlock parent: aServer
        ]
        
        on: aSocket onDisconnect: aBlock parent: aServer [
            <category: 'private'>
            sock := aSocket.
            server := aServer.
            disconnectedHandler := aBlock.
            self state register
        ]

        go [
            <category: 'loop'>
            [sock isPeerAlive] whileTrue:
                [[self process: (RequestFetcher fetch: sock)]
                on: ClientDisconnected do: [:e | self signalDisconnected]]
        ]

        signalDisconnected [
            <category: 'private'>
            disconnectedHandler ifNotNil: [:handler | handler value: self]
        ]

        process: anXMLRequest [
            <category: 'fsm'>
            | r |
            r := Request from: anXMLRequest.
            [(self state process: r) asXML printOn: sock.
             sock flush] on: FatalError do: [:e | self drop]
        ]

        state: aClientConnectionState [
            <category: 'fsm'>
            state := aClientConnectionState
        ]

        state [
            <category: 'fsm'>
            ^state ifNil: [state := NotAuthorizedState of: self]
        ]

        echo: aString [
            <category: 'fsm'>
            self state echo: aString
        ]

        send: aPacket [
            <category: 'networking'>
            aPacket asXML printOn: sock.
            sock flush
        ]

        drop [
            <category: 'networking'>
            sock close.
            self signalDisconnected
        ]

        server [
            <category: 'accessors'>
            ^server
        ]
    ]

    Object subclass: ShampooServer [
        <category: 'Shampoo-Server'>
        <comment: 'I am the heart of the Shampoo system. My instances manage
connections and... hmm, looks like thats all.'>

        | server clients clientsMutex creds |

        clients [
            <category: 'private'>
            ^clients ifNil: [clients := OrderedCollection new]
        ]

        acceptedClient [
            <category: 'private'>
            | client |
            client := ClientConnection
                on: server accept
                onDisconnect: [:cl | self handleDisconnected: cl]
                parent: self.
            clientsMutex critical: [self clients add: client].
            ^client
        ]

        handleDisconnected: aClient [
            <category: 'delegation'>
            "This method is delegated to a client session in a block"
            clientsMutex critical: [self clients remove: aClient]
        ]

        startOn: aPort creds: aCreds [
            <category: 'private'>
            clientsMutex := Semaphore forMutualExclusion.
            server := TCP.ServerSocket port: aPort.
            creds := aCreds.

            [server isOpen] whileTrue:
                [server waitForConnection.
                 [self acceptedClient go] fork]
        ]

        echo: aString [
            <category: 'transcript'>
            clientsMutex critical: [self clients do: [:each | each echo: aString]]
        ]

        ShampooServer class >> startOn: aPort login: aLogin pass: aPass [
            <category: 'instance creation'>
            ^self startOn: aPort creds: (AuthInfo login: aLogin pass: aPass)
        ]

        ShampooServer class >> startOn: aPort creds: aCreds [
            <category: 'instance creation'>
            [| srv |
             srv := self new.
             ShampooTranscript add: srv.
             srv startOn: aPort creds: aCreds] fork
        ]

        creds [
            <category: 'accessors'>
            ^creds shallowCopy
        ]
    ]
]

Eval [
    Shampoo.ShampooTranscript install.
]
