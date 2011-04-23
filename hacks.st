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
]
