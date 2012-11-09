Namespace current: Shampoo [

    Error subclass: ClientDisconnected [
        <category: 'Shampoo-Server'>
        <comment: 'I am just an exception. My instances point out that a client
has disconnected from the server.'>
    ]

    Error subclass: FatalError [
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

        ShampooTranscript class >> initialize [
            <category: 'class initialization'>
            self install
        ]

        ShampooTranscript class >> message: aString [
            <category: 'transcript'>
            self fallback: aString.
            serversMutex critical: [servers do: [:each | each echo: aString]]
        ]

        ShampooTranscript class >> fallback: aString [
            <category: 'transcript'>
            oldAssoc ifNotNil:
            [oldAssoc key perform: oldAssoc value with: aString]
        ]

        ShampooTranscript class >> add: aServer [
            <category: 'setup'>
            serversMutex critical: [servers add: aServer]
        ]

        ShampooTranscript class >> remove: aServer [
            <category: 'setup'>
            serversMutex critical:
            [servers remove: aServer ifAbsent: []]
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
                ifFalse: [FatalError new signal]
        ]

        checkLogin: aRequest [
            <category: 'private'>
            "Really hates."
            (connection server authenticates: aRequest creds with: self magic)
                ifTrue: [self switchTo: AuthorizedState.
                         ^ServerInfoResponse id: aRequest id]
                ifFalse: [FatalError new signal]
        ]

        magic [
            <category: 'private'>
            ^magic ifNil: [magic := Random between: 0 and: 16rFFFF]
        ]
    ]

    ConnectionState subclass: AuthorizedState [
        <category: 'Shampoo-Server'>
        <comment: 'My instances represent authorized states of a user session.
Such state is also can be called "active". The most of Shampoo requests are
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

    Object subclass: ProcessObject [
        <category: 'Shampoo-Server'>
        <comment: 'My instances represent objects bound to processes.
Such object do live inside its process and does the most of its operations
in the process context.'>

        | process |

        proc: aProcess [
            <category: 'accessors'>
            process := aProcess
        ]

        suspend [
            <category: 'suspend/resume'>
            process ifNotNil: [process suspend]
        ]

        resume [
            <category: 'suspend/resume'>
            process ifNotNil: [process resume]
        ]
    ]

    Object subclass: ClientConnection [
        <category: 'Shampoo-Server'>
        <comment: 'My instances represent a client connection. A client connection
is actually a finite state machine, see ConnectionState class and its subclasses'>

        | sock server disconnectedHandler state parser |

        ClientConnection class >> on: aSocket onDisconnect: aBlock parent: aServer [
            <category: 'instance creation'>
            ^aSocket
               ifNil: [nil]
               ifNotNil: [self new on: aSocket onDisconnect: aBlock parent: aServer]
        ]
        
        on: aSocket onDisconnect: aBlock parent: aServer [
            <category: 'private'>
            sock := aSocket.
            server := aServer.
            disconnectedHandler := aBlock.
            state := NotAuthorizedState of: self.
            state register.
            parser := MessageParser new.
        ]

        go [
            <category: 'loop'>
            [sock isPeerAlive] whileTrue:
                [[self fetchMessages do: [:m | self process: m]]
                  on: ClientDisconnected
                  do: [:e | ^self signalDisconnected]].
            self signalDisconnected
        ]

        fetchMessages [
            <category: 'private'>
            [sock ensureReadable] ifError: [ClientDisconnected new signal].
            ^parser process: (sock next: sock availableBytes)
        ]

        signalDisconnected [
            <category: 'private'>
            disconnectedHandler ifNotNil: [:handler | handler value: self]
        ]

        process: anXMLRequest [
            <category: 'fsm'>
            | r xml |
            [xml := ShampooXML.ShNode from: anXMLRequest]
            ifError:
            [^server inform:
             'Shampoo: failed to parse ', anXMLRequest printString].
            r := Request from: xml.
            [(self state process: r) do: [:resp | self send: resp]]
            on: FatalError do: [:e | self close]
        ]

        state: aClientConnectionState [
            <category: 'fsm'>
            state := aClientConnectionState
        ]

        state [
            <category: 'fsm'>
            ^state
        ]

        echo: aString [
            <category: 'fsm'>
            self state echo: aString
        ]

        send: aPacket [
            <category: 'networking'>
            | msg |
            msg := aPacket asXML printString.
            sock
                nextPutAll: 'Content-Length: ', msg size printString;
                crlf;
                crlf;
                nextPutAll: msg;
                crlf.
            sock flush
        ]

        close [
            <category: 'networking'>
            sock close
        ]

        server [
            <category: 'accessors'>
            ^server
        ]
    ]

    ProcessObject subclass: ShampooServer [
        <category: 'Shampoo-Server'>
        <comment: 'I am the heart of the Shampoo system. My instances manage
connections and... hmm, looks like thats all.'>

        | server clients clientsMutex creds |

        servers := Dictionary new.
        serversMutex := Semaphore forMutualExclusion.

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
            ^client
        ]

        authenticates: aCreds with: aMagic [
            <category: 'authentication'>
            ^(creds with: aMagic) = aCreds
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

            ShampooTranscript add: self.

            [server isOpen] whileTrue:
                [| conn |
                 [server waitForConnection]
                 ifError: [^self inform:
                           'Shampoo: failed to listen for incoming connections'].
                 conn := self acceptedClient.
                 conn ifNotNil:
                     [clientsMutex critical: [self clients add: conn].
                      [conn go] fork]]
        ]

        echo: aString [
            <category: 'transcript'>
            clientsMutex critical:
            [self clients do: [:each | each echo: aString]]
        ]

        ShampooServer class >> startOn: aPort login: aLogin pass: aPass [
            <category: 'instance creation'>
            ^self startOn: aPort creds: (AuthInfo login: aLogin pass: aPass)
        ]

        ShampooServer class >> closeAll [
            <category: 'networking'>
            serversMutex critical:
            [servers values do: [:each | each close].
             servers empty]
        ]

        ShampooServer class >> closeOn: aPort [
            <category: 'networking'>
            serversMutex critical:
                [| srv |
                 srv := servers at: aPort ifAbsent: [^nil].
                 servers removeKey: aPort.
                 srv close]
        ]

        ShampooServer class >> startOn: aPort creds: aCreds [
            <category: 'instance creation'>
            serversMutex critical:
            [(servers includesKey: aPort) ifFalse:
                 [| srv |
                  srv := self new.
                  servers at: aPort put: srv.
                  srv proc: [srv startOn: aPort creds: aCreds] fork]]
        ]

        ShampooServer class >> update: aspect [
            <category: 'change and update'>
            aspect == #aboutToSnapshot    ifTrue: [^self broadcast: #suspend ].
            aspect == #finishedSnapshot   ifTrue: [^self broadcast: #resume  ].
            aspect == #returnFromSnapshot ifTrue: [^self broadcast: #restart ].
        ]

        ShampooServer class >> initialize [
            <category: 'class initialization'>
            ObjectMemory addDependent: self
        ]

        ShampooServer class >> broadcast: aMessage [
            <category: 'private'>
            serversMutex critical:
            [servers values do: [:srv | srv perform: aMessage]]
        ]

        suspend [
            <category: 'private'>
            self closeConnections.
            super suspend.
        ]

        restart [
            <category: 'private'>
            self close.
            self proc: [self startOn: server port creds: creds] fork.
        ]

        closeConnections [
            <category: 'private'>
            clientsMutex critical:
            [self clients copy do: [:cl | cl close]].
            "And that's all. Every client connection
             will be removed from the set in the
             ShampooServer>>handleDisconnected:."
        ]
   
        close [
            <category: 'private'>
            [server close] ifError: [].
            self closeConnections.
            ShampooTranscript remove: self
        ]
    
        inform: aMessage [
            <category: 'error handling'>
            ShampooTranscript fallback: aMessage.
            ^nil
        ]
    ]
]

Eval [
    Shampoo.ShampooTranscript initialize.
    Shampoo.ShampooServer initialize.
]
