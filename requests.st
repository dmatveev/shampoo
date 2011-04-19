Namespace current: Shampoo [

    Object subclass: Request [
        | id |

        Request class >> from: anXML [
            | attrs class |
            attrs := anXML attrMap.
            class := self subclasses detect: [:each | each is: (attrs at: 'type')].
            ^(class new: (attrs at: 'id') asInteger)
                init: anXML;
                yourself
        ]

        Request class >> new: anInteger [
            ^(self new)
                id: anInteger;
                yourself
        ]

        init: anXML [
            "Default implementation, do nothing"
        ]

        id: anInteger [
            id := anInteger
        ]
    ]

    Request subclass: NamespacesRequest [
        NamespacesRequest class >> is: aString [
            ^aString = 'Namespaces'
        ]
    ]

    Request subclass: ClassesRequest [
        | namespace |

        ClassesRequest class >> is: aString [
            ^aString = 'Classes'
        ]

        init: anXML [
            namespace := anXML attrMap at: 'namespace'
        ]
    ]

    Request subclass: ClassRequest [
        | class |

        ClassRequest class >> is: aString [
            ^aString = 'Class'
        ]

        init: anXML [
            class := anXML attrMap at: 'class'
        ]
    ]

    Request subclass: CategoriesRequest [
        | class side |

        CategoriesRequest class >> is: aString [
            ^aString = 'Categories'
        ]

        init: anXML [
            | attrs |
            attrs := anXML attrMap.
            class := attrs at: 'class'.
            side := (attrs at: 'side') asSymbol
        ]
    ]

    Request subclass: MethodsRequest [
        | class side category |

        MethodsRequest class >> is: aString [
            ^aString = 'Methods'
        ]

        init: anXML [
            | attrs |
            attrs := anXML attrMap.
            class := attrs at: 'class'.
            side := (attrs at: 'side') asSymbol.
            category := attrs at: 'category'
        ]
    ]

    Request subclass: MethodSourceRequest [
        | class side name |

        MethodSourceRequest class >> is: aString [
            ^aString = 'MethodSource'
        ]

        init: anXML [
            | attrs |
            attrs := anXML attrMap.
            class := attrs at: 'class'.
            side := (attrs at: 'side') asSymbol.
            name := attrs at: 'method'
        ]
    ]

    Request subclass: CompileClassRequest [
        | class instvars |

        CompileClassRequest class >> is: aString [
            ^aString = 'CompileClass'
        ]

        init: anXML [
            | attrs |
            anXML inspect.
            attrs := anXML attrMap.
            class := attrs at: 'class'.
            instvars := (anXML elementsNamed: 'instvar')
                            collect:  [:each | each attrMap at: 'name']
        ]

    ]

    Request subclass: CompileMethodRequest [
        | class side source |

        CompileMethodRequest class >> is: aString [
            ^aString = 'CompileMethod'
        ]

        init: anXML [
            | attrs |
            attrs := anXML attrMap.
            class := attrs at: 'class'.
            side := (attrs at: 'side') asSymbol.
            source := anXML characterData
        ]
    ]
]
