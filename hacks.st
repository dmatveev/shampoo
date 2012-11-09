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

    or [
        <category: '*shampoo-hacks'>
        ^self fold: [:a :b | a | b]
    ]

    and [
        <category: '*shampoo-hacks'>
        ^self fold: [:a :b | a & b]
    ]
]

BlockClosure extend [
    not [
        <category: '*shampoo-hacks'>
        self numArgs ~= 1 ifTrue:
        [^self error: '#not is for single argument blocks only'].
        
        ^[:value | (self value: value) not]
    ]
]

PositionableStream extend [
    forwardWhile: aBlock [
        <category: '*shampoo-hacks'>
        [self atEnd not and: [aBlock value: self peek]]
        whileTrue: [self next]
    ]
]

SequenceableCollection extend [
    drop: anInteger [
        <category: '*shampoo-hacks'>
        anInteger > self size ifTrue: [^self class new].
        ^self copyFrom: anInteger + 1
    ]

    take: anInteger [
        <category: '*shampoo-hacks'>
        anInteger > self size ifTrue: [^self copy].
        anInteger = 0 ifTrue: [^self class new].
        ^self copyFrom: 1 to: anInteger
    ]

    breakIf: aBlock [
        <category: '*shampoo-hacks'>
        | r |
        r := ReadStream on: self.
        r forwardWhile: aBlock not.
        ^{ self copyFrom: 1 to: r position.
           r upToEnd }
    ]

    dropWhile: aBlock [
        <category: '*shampoo-hacks'>
        | r |
        r := ReadStream on: self.
        r forwardWhile: aBlock.
        ^self copyFrom: r position + 1
    ]

    takeWhile: aBlock [
        <category: '*shampoo-hacks'>
        | r |
        r := ReadStream on: self.
        r forwardWhile: aBlock.
        ^self copyFrom: 1 to: r position
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
 
String extend [       
    isClosingBracket [
        <category: '*shampoo-hacks'>
        ^self trimSeparators = ']'
    ]
]

WriteStream extend [
    putStrLn: aString [
        <category: '*shampoo-hacks'>
        self nextPutAll: aString; nl
    ]
]

Namespace current: Sockets [
    StreamSocket extend [
        crlf [
            <category: '*shampoo-hacks'>
            self nextPutAll: String crlf
        ]
    ]
]
