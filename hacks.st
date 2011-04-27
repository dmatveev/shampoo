Namespace current: Shampoo [
    Object class extend [
        mergeBehaviorFrom: aSharedBehaviorSubclass [
            <category: '*shampoo-hacks'>

            aSharedBehaviorSubclass instVarNames do: [:each | self addInstVarName: each].

            aSharedBehaviorSubclass methodDictionary ifNotNil:
            [:dict | dict keysAndValuesDo: [:key :value | self compile: value methodSourceString]]
        ]
    ]
]

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
