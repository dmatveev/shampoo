Namespace current: Shampoo [

    Object subclass: AuthInfo [
        | login passHash |

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
            ^(LoginInfo new)
                login: login
                magicHash: (MD5 new: (aMagic printString, passHash)) hexDigest
        ]
    ]

    Object subclass: LoginInfo [
        | login magicHash |

        LoginInfo class >> fromXML: anXML [
            <category: 'instance creation'>
            ^(self new)
                login: (anXML attrMap at: 'login')
                magicHash: (anXML attrMap at: 'magic');
                yourself
        ]

        login: aString magicHash: aHash [
            login := aString.
            magicHash := aHash
        ]

        = aLoginInfo [
            ^(aLoginInfo class = self class) and: [self hash = aLoginInfo hash]
        ]

        hash [
            ^login hash bitXor: magicHash hash
        ]
    ]
]
