XML.Element extend [
    attrMap [
        <category: '*shampoo-accessors'>
        ^Dictionary from:
            (self attributes collect: [ :each | each key type -> each value ])
    ]
]

Namespace current: Shampoo [

    Exception subclass: ClientDisconnected [
    ]

    Exception subclass: FatalError [
    ]

    Object subclass: ShampooTranscript [
        servers := Set new.
        serversMutex := Semaphore forMutualExclusion.
        oldAssoc := nil.

        ShampooTranscript class >> message: aString [
            self fallback: aString.
            serversMutex critical: [servers do: [:each | each echo: aString]]
        ]

        ShampooTranscript class >> fallback: aString [
            oldAssoc ifNotNil: [oldAssoc key perform: oldAssoc value with: aString].
        ]

        ShampooTranscript class >> add: aServer [
            serversMutex critical: [servers add: aServer]
        ]
            
        ShampooTranscript class >> remove: aServer [
            serversMutex critical: [servers remove: aServer]
        ]
    
        ShampooTranscript class >> install [
            | message |
            message := Transcript message.
            (message key = ShampooTranscript and: [message value = #message:])
                ifFalse: [oldAssoc := message.
                          Transcript message: (ShampooTranscript -> #message:)]
        ]
    ]

    Object subclass: RequestFetcher [
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
            ^XML.XMLParser processDocumentString: stanza contents
                           beforeScanDo: [:p | p validate: false]
        ]

        fetch [
            <category: 'private'>
            [sock isPeerAlive] whileTrue:
                [stanza nextPutAll: (sock upTo: $>); nextPut: $>.
                 [^self parsed]
                    on: XML.MalformedSignal
                    do: [:e | nil]].
            sock isPeerAlive ifFalse: [ClientDisconnected new signal]
        ]
    ]

    Object subclass: ConnectionState [
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
    ]

    ConnectionState subclass: NotAuthorizedState [
        process: aRequest [
            "Anti-If campaign probably hates me."
            aRequest class == LoginRequest
                ifTrue: [^self checkLogin: aRequest]
                ifFalse: [self fatal]
        ]

        checkLogin: aRequest [
            "Really hates."
            connection server creds = aRequest creds
                ifTrue: [self switchTo: AuthorizedState.
                         ^ServerInfoResponse id: aRequest id]
                ifFalse: [self fatal]
        ]

        fatal [
            FatalError new signal
        ]
    ]

    ConnectionState subclass: AuthorizedState [
        process: aRequest [
            ^aRequest execute
        ]
    ]

    Object subclass: ClientConnection [
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
        ]

        go [
            [sock isPeerAlive] whileTrue:
                [[self process: (RequestFetcher fetch: sock)]
                on: ClientDisconnected do: [:e | self signalDisconnected]]
        ]

        signalDisconnected [
            <category: 'private'>
            disconnectedHandler ifNotNil: [:handler | handler value: self]
        ]

        process: anXMLRequest [
            | r |
            r := Request from: anXMLRequest root.
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
            (EchoResponse id: -1 text: aString) asXML printOn: sock.
            sock flush
        ]

        drop [
            sock close.
            self signalDisconnected
        ]

        server [
            <category: 'accessors'>
            ^server
        ]
    ]

    Object subclass: UserCreds [
        | login passHash |

        UserCreds class >> login: aLogin pass: aPass [
            <category: 'instance creation'>
            ^(self new)
                login: aLogin;
                pass: aPass;
                yourself
        ]

        UserCreds class >> login: aLogin passHash: aString [
            <category: 'instance creation'>
            ^(self new)
                login: aLogin;
                passHash: aString;
                yourself
        ]

        UserCreds class >> fromXML: anXML [
            ^UserCreds
                login: (anXML attrMap at: 'login')
                passHash: (anXML attrMap at: 'pass')
        ]

        login: aLogin [
            <category: 'private'>
            login := aLogin.
        ]

        pass: aPass [
            passHash := (MD5 new: aPass) hexDigest.
        ]

        passHash: aString [
            passHash := aString
        ]

        hash [
            <category: 'equality'>
            ^login hash bitXor: passHash hash
        ]

        = aCreds [
            ^(self hash = aCreds hash)
        ]
    ]

    Object subclass: ShampooServer [
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
                onDisconnect: [:client | self handleDisconnected: client]
                parent: self.
            clientsMutex critical: [self clients add: client].
            ^client
        ]

        handleDisconnected: aClient [
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
            clientsMutex critical: [self clients do: [:each | each echo: aString]]
        ]

        ShampooServer class >> startOn: aPort login: aLogin pass: aPass [
            <category: 'instance creation'>
            ^self startOn: aPort creds: (UserCreds login: aLogin pass: aPass)
        ]

        ShampooServer class >> startOn: aPort creds: aCreds [
            <category: 'instance creation'>
            [| srv |
             srv := self new.
             ShampooTranscript add: srv.
             srv startOn: aPort creds: aCreds] fork
        ]

        creds [
            ^creds
        ]
    ]
]

Eval [
    Shampoo.ShampooTranscript install.
]
