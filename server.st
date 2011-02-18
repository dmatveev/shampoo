Namespace current: Shampoo [

    Object subclass: RequestFetcher [
        | sock stanza |

        RequestFetcher class >> fetch: aSocket [
            <category: 'instance creation'>

            ^self new init: aSocket; fetch
        ]
    
        init: aSocket [
            <category: 'private'>

            sock := aSocket.
            stanza := WriteStream on: ''.
        ]

        parsed [
            <category: 'private'>
            ^XML XMLParser processDocumentString: stanza contents
                           beforeScanDo: [:p | p validate: false]
        ]

        fetch [
            <category: 'private'>

            [sock isPeerAlive] whileTrue:
                [[stanza nextPutAll: (sock upTo: $>); nextPut: $>.
                  stanza contents printNl.
                  ^self parsed]
                ifError: [Transcript << 'Waiting stanza to complete'; nl]].
        ]
    ]

    Object subclass: ClientConnection [
        | sock |

        ClientConnection class >> on: aSocket [
            <category: 'instance creation'>

            ^self new on: aSocket
        ]
        
        on: aSocket [
            <category: 'private'>

            sock := aSocket.
            [sock isPeerAlive]
                whileTrue: [self process: (RequestFetcher fetch: sock)]
        ]

        process: aRequest [
            aRequest inspect printNl
        ]
    ]

    Object subclass: ShampooServer [
        | server client |

        startOn: aPort [
            <category: 'private'>
            server := TCP.ServerSocket port: aPort.
            server waitForConnection.
            client := ClientConnection on: server accept
        ]

        ShampooServer class >> startOn: aPort [
            <category: 'networking'>

            [self new startOn: aPort] fork
        ]
    ]
]
