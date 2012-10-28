Namespace current: Shampoo [

    Object subclass: Request [
        <category: 'Shampoo-Requests'>
        <comment: 'I am an abstract class. My instances represent various requests
sent (usually) from a client to the server. Each request knows how to deserialize
from an XML and what action to perform on the server side. Each request usually
has an appropriate Response subclass, and returns a Response object on #execute.'>

        | id |

        Request class >> from: anXML [
            <category: 'instance creation'>
            | attrs class |
            attrs := anXML attrMap.
            class := Request allSubclasses detect:
            [:each | (each respondsTo: #is:) and: [each is: (attrs at: 'type')]].
            ^(class new: (attrs at: 'id') asInteger)
                init: anXML;
                yourself
        ]

        Request class >> new: anInteger [
            <category: 'instance creation'>
            ^(self new)
                id: anInteger;
                yourself
        ]

        id: anInteger [
            <category: 'accessors'>
            id := anInteger
        ]

        id [
            <category: 'accessors'>
            ^id
        ]

        init: anXML [
            <category: 'private'>
            "Default implementation, do nothing"
        ]

        execute [
            <category: 'execution'>
            ^self subclassResponsibility
        ]

        failSafe: aBlock [
            <category: 'execution'>
            aBlock
            on: Error
            do: [:err | ^OperationalResponse failure: id with: err].
            ^OperationalResponse success: id
        ]
    ]

    Request subclass: LoginRequest [
        <category: 'Shampoo-Requests'>
        <comment: 'My instances represent a login request and transfer
authentication data from a client to the server. I am the one of the
few requests than do not understand an #execute message.'>

        | creds |

        LoginRequest class >> is: aString [
            <category: 'identification'>
            ^aString = 'Login'
        ]

        init: anXML [
            <category: 'private'>
            creds := LoginInfo fromXML: (anXML elementsNamed: 'creds') first.
        ]

        creds [
            <category: 'accessors'>
            ^creds
        ]
    ]

    Request subclass: NamespacesRequest [
        <category: 'Shampoo-Requests'>
        <comment: 'My instances are used to query a list of available namespaces
in the image.'>

        NamespacesRequest class >> is: aString [
            <category: 'identification'>
            ^aString = 'Namespaces'
        ]

        execute [
            <category: 'execution'>
            | names |
            names := ((Namespace allInstances select: [:each | each environment = Smalltalk])
                        collect: [:each | each name asString]) asSet asSortedCollection.
            ^NamespacesResponse id: id names: (#('Smalltalk'), names)
        ]
    ]

    Request subclass: ClassesRequest [
        <category: 'Shampoo-Requests'>
        <comment: 'My instances are used to query a list of classes in a
namespace.'>

        | namespace |

        ClassesRequest class >> is: aString [
            <category: 'identification'>
            ^aString = 'Classes'
        ]

        init: anXML [
            <category: 'private'>
            namespace := anXML attrMap at: 'namespace'
        ]

        execute [
            <category: 'execution'>
            | space names |
            names := SortedCollection new.
            space := Smalltalk at: namespace asSymbol.
            space allClassesDo: [:each | names add: each name asString].
            ^ClassesResponse id: id names: names
        ]
    ]

    Request subclass: ClassRequest [
        <category: 'Shampoo-Requests'>
        <comment: 'My instances are used to query an information about a
class in a namespace'>

        | className spaceName side |

        ClassRequest class >> is: aString [
            <category: 'identification'>
            ^aString = 'Class'
        ]

        init: anXML [
            <category: 'private'>
            | attrs |
            attrs := anXML attrMap.
            className := attrs at: 'class'.
            spaceName := attrs at: 'namespace'.
            side := (attrs at: 'side') asSymbol.
        ]

        execute [
            <category: 'execution'>
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
        <category: 'Shampoo-Requests'>
        <comment: 'My instances are used to query a list of the method categories
in a concrete class from a concrete namespace.'>

        | className spaceName side |

        CategoriesRequest class >> is: aString [
            <category: 'identification'>
            ^aString = 'Categories'
        ]

        init: anXML [
            <category: 'private'>
            | attrs |
            attrs := anXML attrMap.
            className := attrs at: 'class'.
            spaceName := attrs at: 'namespace'.
            side := (attrs at: 'side') asSymbol
        ]

        execute [
            <category: 'execution'>
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
        <category: 'Shampoo-Requests'>
        <comment: 'My instances are used to query a list of methods in a concrete
category of a concrete class from a concrete namespace.'>

        | className spaceName side cat |

        MethodsRequest class >> is: aString [
            <category: 'identification'>
            ^aString = 'Methods'
        ]

        init: anXML [
            <category: 'private'>
            | attrs |
            attrs := anXML attrMap.
            className := attrs at: 'class'.
            spaceName := attrs at: 'namespace'.
            side := (attrs at: 'side') asSymbol.
            cat := attrs at: 'category'
        ]

        execute [
            <category: 'execution'>
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
        <category: 'Shampoo-Requests'>
        <comment: 'My instances are used to query the source of a concrete method
in a concrete class from a concrete namespace.'>

        | className spaceName side name |

        MethodSourceRequest class >> is: aString [
            <category: 'identification'>
            ^aString = 'MethodSource'
        ]

        init: anXML [
            <category: 'private'>
            | attrs |
            attrs := anXML attrMap.
            className := attrs at: 'class'.
            spaceName := attrs at: 'namespace'.
            side := (attrs at: 'side') asSymbol.
            name := attrs at: 'method'
        ]

        execute [
            <category: 'execution'>
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
        <category: 'Shampoo-Requests'>
        <comment: 'My instances are used to compile a method in a concrete class from a concrete namespace.'>

        | className superName superSpace spaceName instvars classvars poolvars side |

        CompileClassRequest class >> is: aString [
            <category: 'identification'>
            ^aString = 'CompileClass'
        ]

        init: anXML [
            <category: 'private'>
            | attrs fetchBlock |
            attrs := anXML attrMap.
            side := (attrs at: 'side' ifAbsent: ['instance']) asSymbol.

            fetchBlock := [:type | (anXML elementsNamed: type) collect:
                                   [:each | each text]].

            "This data is common for both 'instance' and 'class' sides"
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
            <category: 'execution'>
            | parent class currentSpace targetSpace error |

            targetSpace := Smalltalk at: spaceName asSymbol.
            class := targetSpace at: className asSymbol ifAbsent: [nil].

            side = #instance
                ifTrue: ["Looks a bit kludgy, but currently I dont know how to make it better
                          TODO: refactor"
                         parent := (Smalltalk at: superSpace asSymbol) at: superName asSymbol.
                         currentSpace := Namespace current.
                         Namespace current: targetSpace.

                         [class := parent
                            subclass: className asSymbol
                            instanceVariableNames: instvars elementsString
                            classVariableNames: classvars elementsString
                            poolDictionaries: '' " poolvars elementsString "
                            category: ''.
                         ] on: Error do: [:err | error := err].

                         Namespace current: currentSpace]

                ifFalse: [class := targetSpace at: className asSymbol ifAbsent: [nil].
                          [class class instanceVariableNames: instvars elementsString]
                              on: Error do: [:err | error := err]].

            error isNil
                ifTrue: [^OperationalResponse success: id]
                ifFalse: [^OperationalResponse failure: id with: error]
        ]
    ]

    Request subclass: CompileMethodRequest [
        <category: 'Shampoo-Requests'>
        <comment: 'My instances represent a request to (re)compile a concrete
method in the concrete class at the concrete namespace.'>
        
        | className spaceName side source cat |

        CompileMethodRequest class >> is: aString [
            <category: 'identification'>
            ^aString = 'CompileMethod'
        ]

        init: anXML [
            <category: 'initialization'>
            | attrs |
            attrs := anXML attrMap.
            className := attrs at: 'class'.
            spaceName := attrs at: 'namespace'.
            side := (attrs at: 'side') asSymbol.
            cat := attrs at: 'category'.
            source := anXML text
        ]

        execute [
            <category: 'execution'>
            | class method |
            class := (Smalltalk at: spaceName asSymbol) at: className asSymbol.
            (side = #class) ifTrue: [class := class class].

            [method := class compile: source]
            on: Error do: [:err | ^self fail: err].

            (cat ~= '*')
            & (method descriptor category ~= cat)
            & (method descriptor category = 'still unclassified')
            ifTrue: [method descriptor category: cat].
            
            ^OperationalResponse success: id
        ]

        fail: anError [
            <category: 'execution'>
            ^OperationalResponse failure: id with: anError
        ]
    ]

    Request subclass: EvalRequest [
        <category: 'Shampoo-Requests'>
        <comment: 'My instances represent an abstract evaluation request. I hold
an expression string to evalute. Expression may be local and may have side
effects (introducing new classes, modifying the image, etc), I do not care. The
code of an expression is wrapped in a block automatically -- to make local
variables in "||" available. See my subclasses for more info.'>
        | code |
        
        init: anXML [
            <category: 'initializtion'>
            code := '[', anXML text, '] value'
        ]

        execute [
            <category: 'execution'>
            ^Behavior evaluate: code
        ]
    ]

    EvalRequest subclass: DoItRequest [
        <category: 'Shampoo-Requests'>
        <comment: 'My instances represent DoIt requests. A DoIt request
evaluates an expession quite and returns only success/failure status to the
client.'>

        DoItRequest class >> is: aString [
            <category: 'identification'>
            ^aString = 'DoIt'
        ]

        execute [
            <category: 'execution'>
            [super execute]
            on: Error
            do: [:err | ^OperationalResponse failure: id with: err].
            ^OperationalResponse success: id
        ]
    ]

    EvalRequest subclass: PrintItRequest [
        <category: 'Shampoo-Requests'>
        <comment: 'My instances represent PrintIt requests. A PrinIt request
evaluates an expession and returns its result in a printed form to the client.'>

        PrintItRequest class >> is: aString [
            <category: 'identification'>
            ^aString = 'PrintIt'
        ]

        execute [
            <category: 'execution'>
            | s |
            [s := super execute]
            on: Error
            do: [:err | ^OperationalResponse failure: id with: err].
            ^PrintItResponse id: id value: s
        ]
    ]

    Request subclass: RemoveClassRequest [
        <category: 'Shampoo-Requests'>
        <comment: 'My instances remove classes when executed. Be careful!'>

        | spaceName className |

        RemoveClassRequest class >> is: aString [
            <category: 'identification'>
            ^aString = 'RemoveClass'
        ]

        init: anXML [
            <category: 'private'>
            | attrs |
            attrs := anXML attrMap.
            spaceName := attrs at: 'namespace'.
            className := attrs at: 'class'
        ]

        execute [
            <category: 'execution'>
            ^self failSafe:
            [| namespace parent class |
             namespace := Smalltalk at: spaceName asSymbol.
             class := namespace classAt: className asSymbol.

             class subclasses isEmpty ifFalse:
             [^OperationalResponse
             failure: id
             text: 'failed to remove class ', className, ', it has subclasses.'].

             parent := class superclass.
             parent removeSubclass: class.
             parent class removeSubclass: class class.
             namespace removeKey: className asSymbol ifAbsent: []]
        ]
    ]

    Request subclass: RemoveMethodRequest [
        <category: 'Shampoo-Requests'>
        <comment: 'My instances remove methods from classes when executed. Be careful!'>

        | spaceName className side selector |

        RemoveMethodRequest class >> is: aString [
            <category: 'identification'>
            ^aString = 'RemoveMethod'
        ]

        init: anXML [
            <category: 'private'>
            | attrs |
            attrs := anXML attrMap.
            spaceName := attrs at: 'namespace'.
            className := attrs at: 'class'.
            side := (attrs at: 'side') asSymbol.
            selector := (attrs at: 'method') asSymbol.
        ]

        execute [
            <category: 'execution'>
            ^self failSafe:
            [| namespace class |
             namespace := Smalltalk at: spaceName asSymbol.
             class := namespace classAt: className asSymbol.
             (side = #class) ifTrue: [class := class class].
             class removeSelector: selector]
        ]
    ]

    Request subclass: ChangeCategoryRequest [
        <category: 'Shampoo-Requests'>
        <comment: 'My instances change methods categories when executed'>

        | spaceName className side cat selector |
            
        ChangeCategoryRequest class >> is: aString [
            <category: 'identification'>
            ^aString = 'ChangeCategory'
        ]

        init: anXML [
            <category: 'private'>
            | attrs |
            attrs := anXML attrMap.
            spaceName := attrs at: 'namespace'.
            className := attrs at: 'class'.
            side := (attrs at: 'side') asSymbol.
            cat := (attrs at: 'category').
            selector := (attrs at: 'method') asSymbol.
        ]

        execute [
            <category: 'execution'>
            ^self failSafe:
            [| namespace class method |
             namespace := Smalltalk at: spaceName asSymbol.
             class := namespace classAt: className asSymbol.
             (side = #class) ifTrue: [class := class class].

             method := class methodDictionary at: selector.
             method descriptor category:
             (cat = '*' ifTrue: [nil] ifFalse: [cat])]
        ]
    ]

    Request subclass: RemoveCategoryRequest [
        <category: 'Shampoo-Requests'>
        <comment: 'My instances remove methods categories when executed.
The methods of the removed category are marked as uncategorized.'>
         
        | spaceName className side cat |

        RemoveCategoryRequest class >> is: aString [
            <category: 'identification'>
            ^aString = 'RemoveCategory'
        ]

        init: anXML [
            <category: 'private'>
            | attrs |
            attrs := anXML attrMap.
            spaceName := attrs at: 'namespace'.
            className := attrs at: 'class'.
            side := (attrs at: 'side') asSymbol.
            cat := (attrs at: 'category').
        ]

        execute [
            <category: 'execution'>
            ^self failSafe:
            [| namespace class method |
             namespace := Smalltalk at: spaceName asSymbol.
             class := namespace classAt: className asSymbol.
             (side = #class) ifTrue: [class := class class].

             class methodDictionary values do:
             [:method | method descriptor category = cat
                        ifTrue: [method descriptor category: nil]]]
        ]
    ]

    Request subclass: RenameCategoryRequest [
        <category: 'Shampoo-Requests'>
        <comment: 'My instances rename method categories in the class.'>
         
        | spaceName className side cat from to|

        RenameCategoryRequest class >> is: aString [
            <category: 'identification'>
            ^aString = 'RenameCategory'
        ]

        init: anXML [
            <category: 'private'>
            | attrs |
            attrs := anXML attrMap.
            spaceName := attrs at: 'namespace'.
            className := attrs at: 'class'.
            side := (attrs at: 'side') asSymbol.
            from := attrs at: 'from'.
            to := attrs at: 'to'.
        ]

        execute [
            <category: 'execution'>
            ^self failSafe:
            [| namespace class method |
             namespace := Smalltalk at: spaceName asSymbol.
             class := namespace classAt: className asSymbol.
             (side = #class) ifTrue: [class := class class].

             class methodDictionary values do:
             [:method | method descriptor category = from
                        ifTrue: [method descriptor category: to]]]
        ]
    ]
]
