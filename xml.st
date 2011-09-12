Namespace current: Smalltalk [
Namespace current: ShampooXML [
    Exception subclass: Malformed [
    ]

    Object subclass: ShNode [
        | underlyingXML |

        ShNode class >> tagname: aString [
            <category: 'instance creation'>
            ^(self new)
                underlyingXML: (XML.Element tag: aString);
                yourself
        ]

        ShNode class >> from: aString [
            <category: 'instance creation'>
            [| doc |
            doc := XML.XMLParser processDocumentString: aString
                                 beforeScanDo: [:p | p validate: false].
            ^(self new)
                underlyingXML: doc root;
                yourself
            ] on: XML.MalformedSignal
              do: [:e | Malformed new signal]
        ]

        underlyingXML: anObject [
            <category: 'private'>
            underlyingXML := anObject
        ]

        underlyingXML [
            <category: 'private'>
            ^underlyingXML
        ]

        attrMap [
            <category: 'bridge'>
            ^Dictionary from:
                (underlyingXML attributes collect:
                [:each | each key type -> each value])
        ]

        addAttribute: anAttrName value: aValueString [
            <category: 'bridge'>
            | attr |
            attr := XML.Attribute name: anAttrName value: aValueString.
            underlyingXML addAttribute: attr
        ]

        addNode: aNode [
            <category: 'bridge'>
            underlyingXML addNode: aNode underlyingXML
        ]

        elementsNamed: aString [
            <category: 'bridge'>
            ^(underlyingXML elementsNamed: aString) collect:
                [:each | ShNode new underlyingXML: each]
        ]

        text [
            <category: 'bridge'>
            ^underlyingXML characterData
        ]

        printOn: aStream [
            <category: 'bridge'>
            underlyingXML printOn: aStream
        ]
    ]

    ShNode subclass: ShText [
        ShText class >> text: aString [
            ^(self new)
                underlyingXML: (XML.Text text: aString);
                yourself
        ]
    ]
]
]
