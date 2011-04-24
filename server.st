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
                    do: [:e | Transcript << 'Incomplete stanza, waiting...'; nl]].
            sock isPeerAlive ifFalse: [ClientDisconnected new signal]
        ]
    ]

    Object subclass: ClientConnection [
        | sock disconnectedHandler |

        ClientConnection class >> on: aSocket onDisconnect: aBlock[
            <category: 'instance creation'>
            ^self new on: aSocket onDisconnect: aBlock
        ]
        
        on: aSocket onDisconnect: aBlock [
            <category: 'private'>
            sock := aSocket.
            disconnectedHandler := aBlock
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
            r execute asXML printOn: sock.
            sock flush
        ]
    ]

    Object subclass: ShampooServer [
        | server clients clientsMutex |

        clients [
            ^clients ifNil: [clients := OrderedCollection new]
        ]

        acceptedClient [
            <category: 'private'>
            | client |
            client := ClientConnection
                on: server accept
                onDisconnect: [:client | self handleDisconnected: client].
            clientsMutex critical: [self clients add: client].
            ^client
        ]

        handleDisconnected: aClient [
            Transcript << 'The client has been disconnected'; nl.
            clientsMutex critical: [self clients remove: aClient]
        ]

        startOn: aPort [
            <category: 'private'>
            clientsMutex := Semaphore forMutualExclusion.
            server := TCP.ServerSocket port: aPort.

            [server isOpen] whileTrue:
                [server waitForConnection.
                 [self acceptedClient go] fork]
        ]

        ShampooServer class >> startOn: aPort [
            <category: 'instance creation'>
            [self new startOn: aPort] fork
        ]
    ]
]
