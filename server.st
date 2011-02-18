Namespace current: Shampoo [

    Object subclass: ShampooServer [
        | server client |

        startOn: aPort [
            <category: 'private'>
            server := TCP.ServerSocket port: aPort.
            server waitForConnection.
            client := server accept.

            ['hello world' displayOn: client.
             client flush.
             Transcript << (client nextLine); cr.
            ] repeat.            
        ]

        ShampooServer class >> startOn: aPort [
            <category: 'networking'>
            self new startOn: aPort
        ]
    ]
]
