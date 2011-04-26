Eval [
    PackageLoader fileInPackages: #(#Shampoo #SUnit).
]

Namespace current: Shampoo [
    TestCase subclass: RequestsTest [
        | namespaces classes class cats methods method | 

        setUp [
            namespaces := self request: NamespacesRequest from: self namespacesSample.
            classes := self request: ClassesRequest from: self classesSample.
            class := self request: ClassRequest from: self classSample.
            cats := self request: CategoriesRequest from: self catsSample.
            methods := self request: MethodsRequest from: self methodsSample.
            method := self request: MethodRequest from: self methodSample.
        ]

        namespacesSample [
            ^'<request id="23" type="Namespaces" />'
        ]

        classesSample [
            ^'<request id="10" type="Classes" namespace="SomeNamespace" />'
        ]

        classSample [
            ^'<request id="15" type="Class" namespace="ConcreteNamespace" class="ConcreteClass" />'
        ]

        catsSample [
            ^'<request id="500" type="Categories" namespace="SomeNamespace" class="SomeClass" side="instance"/>'
        ]

        methodsSample [
            ^'<request id="500" type="Methods" namespace="SomeNamespace" class="SomeClass" side="instance" category="some category"/>'
        ]

        methodSample [
            ^'<request id="123" type="MethodSource" namespace="SomeNamespace" class="SomeClass" side="instance" method="method name"/>'
        ]

        request: aRequestClass from: aString [
            | xml |
            xml := XML.XMLParser
                        processDocumentString: aString
                        beforeScanDo: [:p | p validate: false].
            ^aRequestClass from: xml root
        ]
    ]
]
