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
            names := (Namespace allInstances collect: [:each | each name asString]) asSet.
            ^NamespacesResponse id: id names: (#('Smalltalk'), names asSortedCollection)
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
        | className spaceName |

        ClassRequest class >> is: aString [
            ^aString = 'Class'
        ]

        init: anXML [
            | attrs |
            attrs := anXML attrMap.
            className := attrs at: 'class'.
            spaceName := attrs at: 'namespace'
        ]

        execute [
            | class |
            class := (Smalltalk at: spaceName asSymbol) at: className asSymbol.
            ^ClassResponse
                id: id
                class: className
                instvars: class instVarNames
                classvars: class classVarNames
                poolvars: class sharedPools
        ]
    ]

    Request subclass: CategoriesRequest [
        | className spaceName side |

        CategoriesRequest class >> is: aString [
            ^aString = 'Categories'
        ]

        init: anXML [
            | attrs |
            attrs := anXML attrMap.
            className := attrs at: 'class'.
            spaceName := attrs at: 'namespace'.
            side := (attrs at: 'side') asSymbol
        ]

        execute [
            | class cats |
            class := (Smalltalk at: spaceName asSymbol) at: className asSymbol.
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
        | className spaceName side category |

        MethodsRequest class >> is: aString [
            ^aString = 'Methods'
        ]

        init: anXML [
            | attrs |
            attrs := anXML attrMap.
            className := attrs at: 'class'.
            spaceName := attrs at: 'namespace'.
            side := (attrs at: 'side') asSymbol.
            category := attrs at: 'category'
        ]

        execute [
            | class methods |
            class := (Smalltalk at: spaceName asSymbol) at: className asSymbol.
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
        | className spaceName side name |

        MethodSourceRequest class >> is: aString [
            ^aString = 'MethodSource'
        ]

        init: anXML [
            | attrs |
            attrs := anXML attrMap.
            className := attrs at: 'class'.
            spaceName := attrs at: 'namespace'.
            side := (attrs at: 'side') asSymbol.
            name := attrs at: 'method'
        ]

        execute [
            | class method |
            class := (Smalltalk at: spaceName asSymbol) at: className asSymbol.
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
        | className superName superSpace spaceName instvars classvars poolvars |

        CompileClassRequest class >> is: aString [
            ^aString = 'CompileClass'
        ]

        init: anXML [
            | attrs fetchBlock |
            attrs := anXML attrMap.
            className := attrs at: 'class'.
            spaceName := attrs at: 'namespace'.
            superName := attrs at: 'super'.
            superSpace := attrs at: 'superspace'.
            fetchBlock := [:type | (anXML elementsNamed: type) collect:
                                    [:each | each characterData]].
            instvars := fetchBlock value: 'instvar'.
            classvars := fetchBlock value: 'classvar'.
            poolvars := fetchBlock value: 'poolvar'.
        ]

        execute [
            | parent class currentSpace targetSpace failed |

            "Looks a bit kludgy, but currently I dont know how to make it better
             TODO: refactor"

            currentSpace := Namespace current.
            targetSpace := Smalltalk at: spaceName asSymbol.

            class := targetSpace at: className asSymbol ifAbsent: [nil].
            parent := (Smalltalk at: superSpace asSymbol) at: superName asSymbol.

            failed := false.
            Namespace current: targetSpace.

            [class := parent
                subclass: className asSymbol
                instanceVariableNames: instvars elementsString
                classVariableNames: classvars elementsString
                poolDictionaries: '' "poolvars elementsString"
                category: ''
            ] on: Exception do: [:e | e inspect. failed := true].

            Namespace current: currentSpace.

            failed
                ifTrue: [^OperationalResponse failure: id]
                ifFalse: [^OperationalResponse success: id]
        ]
    ]

    Request subclass: CompileMethodRequest [
        | className spaceName side source |

        CompileMethodRequest class >> is: aString [
            ^aString = 'CompileMethod'
        ]

        init: anXML [
            | attrs |
            attrs := anXML attrMap.
            className := attrs at: 'class'.
            spaceName := attrs at: 'namespace'.
            side := (attrs at: 'side') asSymbol.
            source := anXML characterData
        ]

        execute [
            | class failed |
            class := (Smalltalk at: spaceName asSymbol) at: className asSymbol.
            (side = #class) ifTrue: [class := class class].

            class compile: source ifError: [^OperationalResponse failure: id].
            ^OperationalResponse success: id
        ]
    ]
]
