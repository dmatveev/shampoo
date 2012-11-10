Namespace current: Shampoo [

    Object subclass: Response [
        <category: 'Shampoo-Responses'>
        <comment: 'I am an abstract class. My subclasses represent various types
of responses and hold all the required information. They also know how to
serialize themselves into a network-transfer-friendly format.'>

        | id |

        Response class >> id: anInteger [
            <category: 'instance creation'>
            ^(self new)
                id: anInteger;
                yourself
        ]

        id: anInteger [
            <category: 'private'>
            id := anInteger
        ]

        type [
            <category: 'private'>
            ^self shouldNotImplement
        ]

        do: aBlock [
            "Evaluate a one-argument block, pass self to it.
             This method is actually a kludge and it will be probably
             removed later"
            
            <category: 'collection'>
            ^aBlock value: self
        ]

        asXML [
            <category: 'marshalling'>
            ^(ShampooXML.ShNode tagname: 'response')
                addAttribute: 'id' value: id asString;
                addAttribute: 'type' value: self type;
                yourself
        ]
    ]

    Response subclass: ServerInfoResponse [
        <category: 'Shampoo-Responses'>
        <comment: 'My instances hold information about the server (image). Actually,
the server can send me any time, even without an appropriate request'>

        type [
            <category: 'private'>
            ^'Info'
        ]

        asXML [
            <category: 'marshalling'>
            ^(super asXML)
                addNode: (ShampooXML.ShText text: Smalltalk version);
                yourself
        ]
    ]

    Response subclass: OperationalResponse [
        <category: 'Shampoo-Responses'>
        <comment: 'My instances are used to hold a success/failure status of
an operation. An operation is usually a result of a request execution.'>

        | success message |

        OperationalResponse class >> success: anInteger [
            <category: 'instance creation'>
            ^(OperationalResponse id: anInteger)
                success: true;
                yourself
        ]

        OperationalResponse class >> failure: anInteger [
            <category: 'instance creation'>
            ^(OperationalResponse id: anInteger)
                success: false;
                yourself
        ]

        OperationalResponse class >> failure: anInteger with: anError [
            <category: 'instance creation'>
            ^self failure: anInteger text: anError description
        ]

        OperationalResponse class >> failure: anInteger text: aString [
            <category: 'instance creation'>
            ^(OperationalResponse id: anInteger)
                success: false;
                message: aString;
                yourself
        ]

        statusString [
            <category: 'accessors'>
            ^success ifTrue: ['success'] ifFalse: ['failure']
        ]

        success: aBoolean [
            <category: 'private'>
            success := aBoolean
        ]

        message: aString [
            <category: 'private'>
            message := aString
        ]

        type [
            <category: 'private'>
            ^'OperationalResponse'
        ]

        asXML [
            <category: 'marshalling'>
            | r |
            r := super asXML.
            r addAttribute: 'status' value: self statusString.
            message ifNotNil:
            [r addNode: (ShampooXML.ShText text: message)].
            ^r
        ]
    ]

    Object subclass: CollectionResponseDecorator [
        <category: 'Shampoo-Responses'>
        <comment: 'I am a decorator, a Smalltalk alternative to the multiple
inheritance. My instances are used to add some additional state and behavior
dynamically to the existing objects. The additions introduced by me could not
be added somewhere in the root of the class (sub)hierarchy, some classes in
the hierarchy should behave like me, and some should not. That''s why I am
here.'>

        | items wrapped |

        CollectionResponseDecorator class >> on: aWrappedObject [
            <category: 'instance creation'>
            ^self new on: aWrappedObject
        ]

        on: aWrappedObject [
            <category: 'private'>
            wrapped := aWrappedObject
        ]

        items [
            <category: 'accessors'>
            ^items ifNil: [items := Dictionary new]
        ]

        itemsAt: itemTypeString put: anArray [
            <category: 'accessors'>
            self items at: itemTypeString put: anArray copy
        ]

        asXML [
            <category: 'marshalling'>
            | root |
            root := wrapped asXML.

            self items keysAndValuesDo:
                [:key :values | values do: [:each |
                root addNode: ((ShampooXML.ShNode tagname: key asString)
                                   addNode: (ShampooXML.ShText text: each);
                                   yourself)]].

            ^root
        ]

        do: aBlock [
            "CollectionResponseDecorator usually wraps Response objects.
             Response objects partly understand the collection protocol,
             especially a #do: message. This wrapper does not proxy this
             message to the underlying object."
            <category: 'decorating'>
            ^aBlock value: self
        ]

        doesNotUnderstand: aMessage [
            <category: 'decorating'>
            "Proxy an unknown message to an underlying object"
            ^wrapped perform: aMessage selector
                     withArguments: aMessage arguments
        ]
    ]

    Response subclass: NamespacesResponse [
        <category: 'Shampoo-Responses'>
        <comment: 'My instances represent a list of namespaces in the image'>

        NamespacesResponse class >> id: anInteger names: anArray [
            <category: 'instance creation'>
            ^(CollectionResponseDecorator on: (self id: anInteger))
                itemsAt: 'namespace' put: anArray;
                yourself
        ]

        type [
            <category: 'private'>
            ^'Namespaces'
        ]
    ]

    Response subclass: ClassesResponse [
        <category: 'Shampoo-Responses'>
        <comment: 'My instances represent a lists of classes in a concrete
namespace.'>

        ClassesResponse class >> id: anInteger names: anArray [
            <category: 'instance creation'>
            ^(CollectionResponseDecorator on: (self id: anInteger))
                itemsAt: 'class' put: anArray;
                yourself
        ]

        type [
            <category: 'private'>
            ^'Classes'
        ]
    ]

    Response subclass: ClassInfoResponse [
        <category: 'Shampoo-Responses'>
        <comment: 'My instances hold some generic information about a concrete
class in the concrete namespace. See more in my subclasses.'>

        | class attrs |

        ClassInfoResponse class >> id: anInteger class: aClass [
            <category: 'instance creation'>
            ^self id: anInteger class: aClass attrs: nil
        ]

        ClassInfoResponse class >> id: anInteger class: aClass attrs: anArray [
            <category: 'instance creation'>
            ^(self id: anInteger)
                class: aClass attrs: anArray
                yourself
        ]

        class: aClass attrs: anArray [
            <category: 'private'>
            class := aClass.
            anArray isNil ifFalse: [attrs := Dictionary from: anArray].
        ]

        asXML [
            <category: 'marshalling'>
            | r |
            r := super asXML.
            r addAttribute: 'class' value: class.
            attrs ifNotNil:
              [:dict |
              dict keysAndValuesDo: 
                  [:key :value | r addAttribute: key value: value]].
            ^r
        ]
    ]

    ClassInfoResponse subclass: ClassResponse [
        <category: 'Shampoo-Responses'>
        <comment: 'My instances hold information about a class and its state.'>

        ClassResponse class >> id: anInteger class: aClass superclass: aSuperClass
                               instvars: anInstVars classvars: aClassVars poolvars: aPoolDicts [
            <category: 'instance creation'>
            | obj |
            obj := self id: anInteger class: aClass attrs: {'superclass' -> aSuperClass}.
            ^(CollectionResponseDecorator on: obj)
                itemsAt: 'instvar'  put: anInstVars;
                itemsAt: 'classvar' put: aClassVars;
                itemsAt: 'poolvar'  put: aPoolDicts;
                yourself
        ]

        type [
            <category: 'private'>
            ^'Class'
        ]
   ]

    ClassInfoResponse subclass: MethodCategoriesResponse [
        <category: 'Shampoo-Responses'>
        <comment: 'My instances hold a lists of method categories of a concrete class'>

        MethodCategoriesResponse class >> id: anInteger class: aClass categories: anArray [
            <category: 'instance creation'>
            ^(CollectionResponseDecorator on: (self id: anInteger class: aClass))
                itemsAt: 'category' put: anArray;
                yourself
        ]

        type [
            <category: 'private'>
            ^'Categories'
        ]
    ]

    ClassInfoResponse subclass: MethodsResponse [
        <category: 'Shampoo-Responses'>
        <comment: 'My instances hold a lists of methods in a concrete category
of the concrete class'>
        
        MethodsResponse class >> id: anInteger class: aClass methods: anArray [
            <category: 'instance creation'>
            ^(CollectionResponseDecorator on: (self id: anInteger class: aClass))
                itemsAt: 'method' put: anArray;
                yourself
        ]

        type [
            <category: 'private'>
            ^'Methods'
        ]
    ]

    ClassInfoResponse subclass: MethodResponse [
        <category: 'Shampoo-Responses'>
        <comment: 'My instances hold a source code of a concrete method in a
concrete class'>

        | methodName methodSource |

        MethodResponse class >> id: anInteger class: aClass method: aNameString source: aSourceString [
            <category: 'instance creation'>
            ^(self id: anInteger class: aClass)
                method: aNameString methodSource: aSourceString;
                yourself
        ]

        method: aNameString methodSource: aSourceString [
            <category: 'private'>
            methodName := aNameString.
            methodSource := PrettyPrinter prettifyMethod: aSourceString
        ]

        type [
            <category: 'private'>
            ^'MethodSource'
        ]

        asXML [
            <category: 'marshalling'>
            ^(super asXML)
                addAttribute: 'method' value: methodName;
                addNode: (ShampooXML.ShText text: methodSource);
                yourself
        ]
    ]

    Response subclass: PrintItResponse [
        <category: 'Shampoo-Responses'>
        <comment: 'My instances hold an output of a PrintIt request'>

        | value |

        PrintItResponse class >> id: anInteger value: anObject [
            <category: 'instance creation'>
            ^(self id: anInteger)
                value: anObject;
                yourself
        ]

        value: anObject [
            <category: 'private'>
            value := anObject
        ]

        value [
            <category: 'accessors'>
            ^value
        ]

        type [
            <category: 'private'>
            ^'PrintIt'
        ]

        asXML [
            <category: 'marshalling'>
            ^(super asXML)
                addNode: (ShampooXML.ShText text: value printString);
                yourself
        ]
    ]

    Response subclass: EchoResponse [
        <category: 'Shampoo-Responses'>
        <comment: 'My instances hold Transcript outputs. My instances are sent
to all clients when the Transcript have something to print out, there is no
appropriate request.'>

        | text |

        EchoResponse class >> id: anInteger text: aString [
            <category: 'instance creation'>
            ^(self id: anInteger)
                text: aString;
                yourself
        ]

        text: aString [
            <category: 'private'>
            text := aString
        ]

        type [
            <category: 'private'>
            ^'Echo'
        ]

        asXML [
            <category: 'marshalling'>
            ^(super asXML)
                addNode: (ShampooXML.ShText text: text);
                yourself
        ]
    ]

    Response subclass: MagicResponse [
        <category: 'Shampoo-Responses'>
        <comment: 'I am not actually a response, I am like a request that
goes from the server to a client. My instances hold a magic number used by
a client for password encryption during the authentication.'>

        | number |

        MagicResponse class >> number: anInteger [
            <category: 'instance creation'>
            ^(self id: 0)
                number: anInteger;
                yourself
        ]

        number: anInteger [
            <category: 'private'>
            number := anInteger
        ]

        type [
            <category: 'private'>
            ^'Magic'
        ]

        asXML [
            <category: 'marshalling'>
            ^(super asXML)
                addNode: (ShampooXML.ShText text: number printString);
                yourself
        ]
    ]

    Response subclass: FileOutResponse [
        | isLast xml |

        FileOutResponse class >>
        id: anInteger class: aClassName source: aString [
            <category: 'instance creation'>
            ^(self id: anInteger)
                class: aClassName source: aString;
                yourself
        ]

        FileOutResponse class >>
        id: anInteger category: aCategory source: aString [
            <category: 'instance creation'>
            ^(self id: anInteger)
                category: aCategory source: aString;
                yourself
        ]

        class: aClassName source: aString [
            <category: 'private'>
            xml := super asXML.
            xml addAttribute: 'class' value: aClassName;
                addNode: (ShampooXML.ShText text: aString)
        ]

        category: aCategory source: aString [
            <category: 'private'>
            xml := super asXML.
            xml addAttribute: 'category' value: aCategory;
                addNode: (ShampooXML.ShText text: aString)
        ]

        isLast [
            <category: 'accessors'>
            ^isLast ifNil: [isLast := false]
        ]

        isLast: aBoolean [
            <category: 'accessors'>
            isLast := aBoolean
        ]

        type [
            <category: 'private'>
            ^'FileOut'
        ]

        asXML [
            <category: 'marshalling'>
            | r |
            r := xml copy.
            self isLast ifTrue:
            [r addAttribute: 'last' value: 'true'].
            ^r
        ]
    ]
]
