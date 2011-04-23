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

        id: anInteger [
            id := anInteger
        ]

        init: anXML [
            "Default implementation, do nothing"
        ]

        execute [
            ^self subclassResponsibility
        ]
    ]

    Request subclass: NamespacesRequest [
        NamespacesRequest class >> is: aString [
            ^aString = 'Namespaces'
        ]

        execute [
            | names |
            names := (Namespace allInstances collect: [:each | each name asString]).
            ^NamespacesResponse id: id names: names asSet asSortedCollection
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

        execute [
            | space names |
            names := SortedCollection new.
            space := Smalltalk at: namespace asSymbol.
            space allClassesDo: [:each | names add: each name].
            ^ClassesResponse id: id names: names
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

        execute [
            ^ClassResponse
                id: id
                class: class
                instvars: (Smalltalk at: class asSymbol) instVarNames
        ]
    ]

    Request subclass: CategoriesRequest [
        | className side |

        CategoriesRequest class >> is: aString [
            ^aString = 'Categories'
        ]

        init: anXML [
            | attrs |
            attrs := anXML attrMap.
            className := attrs at: 'class'.
            side := (attrs at: 'side') asSymbol
        ]

        execute [
            | class cats |
            class := Smalltalk at: className asSymbol.
            (side = #class) ifTrue: [class := class class].

            cats := Set new.
            class methodDictionary values do:
            [:each | cats add: each descriptor category].

            ^MethodCategoriesResponse
                id: id
                class: className
                categories: cats asSortedCollection
        ]
    ]

    Request subclass: MethodsRequest [
        | className side category |

        MethodsRequest class >> is: aString [
            ^aString = 'Methods'
        ]

        init: anXML [
            | attrs |
            attrs := anXML attrMap.
            className := attrs at: 'class'.
            side := (attrs at: 'side') asSymbol.
            category := attrs at: 'category'
        ]

        execute [
            | class methods |
            class := Smalltalk at: className asSymbol.
            (side = #class) ifTrue: [class := class class].

            methods := class methodDictionary associations select:
                        [:each | each value descriptor category = category].

            ^MethodsResponse
                id: id
                class: className
                methods: (methods collect: [:each | each key asString]) asSortedCollection
        ]
    ]

    Request subclass: MethodSourceRequest [
        | className side name |

        MethodSourceRequest class >> is: aString [
            ^aString = 'MethodSource'
        ]

        init: anXML [
            | attrs |
            attrs := anXML attrMap.
            className := attrs at: 'class'.
            side := (attrs at: 'side') asSymbol.
            name := attrs at: 'method'
        ]

        execute [
            | class method |
            class := Smalltalk at: className asSymbol.
            (side = #class) ifTrue: [class := class class].

            method := class methodDictionary at: name asSymbol.

            ^MethodResponse
                id: id
                class: className
                method: name
                source: method methodSourceString
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

        execute [
            "TODO Implement it"
            ^nil
        ]

    ]

    Request subclass: CompileMethodRequest [
        | className side source |

        CompileMethodRequest class >> is: aString [
            ^aString = 'CompileMethod'
        ]

        init: anXML [
            | attrs |
            attrs := anXML attrMap.
            className := attrs at: 'class'.
            side := (attrs at: 'side') asSymbol.
            source := anXML characterData
        ]

        execute [
            | class failed |
            class := Smalltalk at: className asSymbol.
            (side = #class) ifTrue: [class := class class].

            class compile: source ifError: [^OperationalResponse failure: id].
            ^OperationalResponse success: id
        ]
    ]
]
