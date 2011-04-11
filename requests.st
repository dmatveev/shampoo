Namespace current: Shampoo [

    Object subclass: Request [
        Request class >> from: anXML [
            | attrs class |
            attrs := anXML attrMap.
            class := self subclasses detect: [:each | each is: (attrs at: 'type')].
            ^class from: anXML
        ]
    ]

    Request subclass: NamespacesRequest [
        NamespacesRequest class >> is: aString [
            ^aString = 'Namespaces'
        ]

        NamespacesRequest class >> from: anXML [
        ]
    ]

    Request subclass: ClassesRequest [
        NamespacesRequest class >> is: aString [
            ^aString = 'Classes'
        ]

        NamespacesRequest class >> from: anXML [
        ]
    ]

    Request subclass: ClassRequest [
        NamespacesRequest class >> is: aString [
            ^aString = 'Class'
        ]

        NamespacesRequest class >> from: anXML [
        ]
    ]

    Request subclass: CategoriesRequest [
        NamespacesRequest class >> is: aString [
            ^aString = 'Categories'
        ]

        NamespacesRequest class >> from: anXML [
        ]
    ]

    Request subclass: MethodsRequest [
        NamespacesRequest class >> is: aString [
            ^aString = 'Methods'
        ]

        NamespacesRequest class >> from: anXML [
        ]
    ]

    Request subclass: MethodSourceRequest [
        NamespacesRequest class >> is: aString [
            ^aString = 'MethodSource'
        ]

        NamespacesRequest class >> from: anXML [
        ]
    ]

    Request subclass: CompileClassRequest [
        NamespacesRequest class >> is: aString [
            ^aString = 'CompileClass'
        ]

        NamespacesRequest class >> from: anXML [
        ]
    ]

    Request subclass: CompileMethodRequest [
        NamespacesRequest class >> is: aString [
            ^aString = 'CompileMethod'
        ]

        NamespacesRequest class >> from: anXML [
        ]
    ]
]
