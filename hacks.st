Collection extend [
    elementsString [
        <category: '*shampoo-hacks'>
        ^self inject: '' into: [:acc :each | acc, each asString, ' ']
    ]

    asStringArray [
        <category: '*shampoo-hacks'>
        "Many reflection methods return different results in various dialects.
         #instVarNames in GNU Smalltalk returns an IdentitySet of Symbols, the
         same method returns an Array of Strings in Squeak.

         This kludge works as an abstraction over it all"
        ^(self collect: [:each | each asString]) asArray
    ]
]

String class extend [
    crlf [
        <category: '*shampoo-hacks'>
        ^String new writeStream
            nextPut: Character cr;
            nextPut: Character lf;
            contents
    ]
]

Namespace current: Sockets [
StreamSocket extend [
    crlf [
        <category: '*shampoo-hacks'>
        self nextPutAll: String crlf
    ]
]]
