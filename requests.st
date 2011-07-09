Namespace current: Shampoo [

    Object subclass: Request [
        | id |

        Request class >> from: anXML [
            | attrs class |
            attrs := anXML attrMap.
            class := Request allSubclasses detect:
                [:each | (each respondsTo: #is:) and: [each is: (attrs at: 'type')]].
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

        id [
            ^id
        ]

        init: anXML [
            "Default implementation, do nothing"
        ]

        execute [
            ^self subclassResponsibility
        ]
    ]

    Request subclass: LoginRequest [
        | creds |

        LoginRequest class >> is: aString [
            ^aString = 'Login'
        ]

        init: anXML [
            creds := LoginInfo fromXML: (anXML elementsNamed: 'creds') first.
        ]

        creds [
            ^creds
        ]
    ]

    Request subclass: NamespacesRequest [
        NamespacesRequest class >> is: aString [
            ^aString = 'Namespaces'
        ]

        execute [
            | names |
            names := ((Namespace allInstances select: [:each | each environment = Smalltalk])
                        collect: [:each | each name asString]) asSet asOrderedCollection.
            ^NamespacesResponse id: id names: (#('Smalltalk'), names)
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
            space allClassesDo: [:each | names add: each name asString].
            ^ClassesResponse id: id names: names
        ]
    ]

    Request subclass: ClassRequest [
        | className spaceName side |

        ClassRequest class >> is: aString [
            ^aString = 'Class'
        ]

        init: anXML [
            | attrs |
            attrs := anXML attrMap.
            className := attrs at: 'class'.
            spaceName := attrs at: 'namespace'.
            side := (attrs at: 'side') asSymbol.
        ]

        execute [
            | class |
            class := (Smalltalk at: spaceName asSymbol) at: className asSymbol.
            (side = #class) ifTrue: [class := class class].
            ^ClassResponse
                id: id
                class: className
                superclass: class superclass printString
                instvars: class instVarNames asStringArray
                classvars: class classVarNames asStringArray
                poolvars: class sharedPools asStringArray
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
            class methodDictionary ifNotNil: [:d | d values do:
            [:each | cats add: each descriptor category]].

            ^MethodCategoriesResponse
                id: id
                class: className
                categories: cats asSortedCollection
        ]
    ]

    Request subclass: MethodsRequest [
        | className spaceName side cat |

        MethodsRequest class >> is: aString [
            ^aString = 'Methods'
        ]

        init: anXML [
            | attrs |
            attrs := anXML attrMap.
            className := attrs at: 'class'.
            spaceName := attrs at: 'namespace'.
            side := (attrs at: 'side') asSymbol.
            cat := attrs at: 'category'
        ]

        execute [
            | class methods allMethods |
            class := (Smalltalk at: spaceName asSymbol) at: className asSymbol.
            (side = #class) ifTrue: [class := class class].

            allMethods := class methodDictionary ifNil: [#()] ifNotNil: [:x | x associations].

            methods := (cat = '*'
                ifTrue: [allMethods]
                ifFalse: [allMethods select: [:e | e value descriptor category = cat]]).

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
        | className superName superSpace spaceName instvars classvars poolvars side |

        CompileClassRequest class >> is: aString [
            ^aString = 'CompileClass'
        ]

        init: anXML [
            | attrs fetchBlock |
            attrs := anXML attrMap.
            side := (attrs at: 'side' ifAbsent: ['instance']) asSymbol.

            fetchBlock := [:type | (anXML elementsNamed: type) collect:
                                   [:each | each characterData]].

            "This data is common for bost `instance` and `class` sides"
            className := attrs at: 'class'.
            spaceName := attrs at: 'namespace'.
            instvars := fetchBlock value: 'instvar'.

            side = #instance
                ifTrue: [superName := attrs at: 'super'.
                         superSpace := attrs at: 'superspace'.
                         classvars := fetchBlock value: 'classvar'.
                         poolvars := fetchBlock value: 'poolvar']
        ]

        execute [
            | parent class currentSpace targetSpace failed |

            targetSpace := Smalltalk at: spaceName asSymbol.
            class := targetSpace at: className asSymbol ifAbsent: [nil].
            failed := false.

            side = #instance
                ifTrue: ["Looks a bit kludgy, but currently I dont know how to make it better
                          TODO: refactor"
                         currentSpace := Namespace current.

                         parent := (Smalltalk at: superSpace asSymbol) at: superName asSymbol.

                         Namespace current: targetSpace.

                         [class := parent
                            subclass: className asSymbol
                            instanceVariableNames: instvars elementsString
                            classVariableNames: classvars elementsString
                            poolDictionaries: '' " poolvars elementsString "
                            category: ''.
                         ] on: Exception do: [:e | e inspect. failed := true].

                         Namespace current: currentSpace]

                ifFalse: [class := targetSpace at: className asSymbol ifAbsent: [nil].
                          [class class instanceVariableNames: instvars elementsString]
                              on: Exception do: [:e | e inspect. failed := true]].

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

    Exception subclass: EvalFailure [
    ]

    Request subclass: EvalRequest [
        | code |

        init: anXML [
            code := '[', anXML characterData, '] value'
        ]

        execute [
            ^Behavior evaluate: code ifError: [EvalFailure new signal].
        ]
    ]

    EvalRequest subclass: DoItRequest [
        DoItRequest class >> is: aString [
            ^aString = 'DoIt'
        ]

        execute [
            [super execute] on: EvalFailure do: [:e | ^OperationalResponse failure: id].
            ^OperationalResponse success: id
        ]
    ]

    EvalRequest subclass: PrintItRequest [
        | code |

        PrintItRequest class >> is: aString [
            ^aString = 'PrintIt'
        ]

        execute [
            | s |
            [s := super execute] on: EvalFailure do: [:e | ^OperationalResponse failure: id].
            ^PrintItResponse id: id value: s
        ]
    ]
]
