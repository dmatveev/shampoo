Namespace current: Shampoo [

    Object subclass: AuthInfo [
        | login passHash |

        <category: 'Shampoo-Auth'>
        <comment: 'My instances represent an authentification info stored on
server. My instances live on the server side permamently (as long as the server
does) and are used to verify the user''s identity.

The authentification scheme used in the Shampoo is a classical PSK (Pre-Shared
Key). When you start a server, you have to define a login and a password (see
ShampooServer>>startOn:login:pass:). Obviously the same login and password
should be specified by a client then.

When a client connects to the server, the server generates a pseudo-random magic
string (a number) and sends it to the client. The client then should calculate
an MD5 hash of a password, concatenate it with the magic string and then take
a hash of the concatenation again. This hash is then sent back to the server.

Server performs the same operations and then compares the hashes. So the password
is not transmitted across the network, and the server also does not store it
in the plain form in the memory.'>

        AuthInfo class >> login: aLogin pass: aPass [
            <category: 'instance creation'>
            ^(self new)
                login: aLogin pass: aPass;
                yourself
        ]

        login: aLogin pass: aPass [
            <category: 'private'>
            login := aLogin.
            passHash := (MD5 new: aPass) hexDigest
        ]

        with: aMagic [
            <category: 'psk'>
            ^(LoginInfo new)
                login: login
                magicHash: (MD5 new: (aMagic printString, passHash)) hexDigest
        ]
    ]

    Object subclass: LoginInfo [
        | login magicHash |

        <category: 'Shampoo-Auth'>
        <comment: 'My instances represent an authentification info provided by
a user. My instances come to the server via socket and are used to verify the
user''s identity. See more info in the AuthInfo''s class comment.'>

        LoginInfo class >> fromXML: anXML [
            <category: 'instance creation'>
            ^(self new)
                login: (anXML attrMap at: 'login')
                magicHash: (anXML attrMap at: 'magic');
                yourself
        ]

        login: aString magicHash: aHash [
            <category: 'private'>
            login := aString.
            magicHash := aHash
        ]

        = aLoginInfo [
            <category: 'testing'>
            ^(aLoginInfo class = self class) and: [self hash = aLoginInfo hash]
        ]

        hash [
            <category: 'testing'>
            ^login hash bitXor: magicHash hash
        ]
    ]
]
