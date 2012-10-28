Namespace current: Smalltalk [
    Namespace current: ShampooSamples [
        Object subclass: SampleClassA [
            <category: 'Shampoo-Tests'>
            | a b c |

            one := 1.
            two := 2.
            three := 3.
        ]

        SampleClassA class extend [
            | d |
        ]

        Object subclass: SampleClassB [
            <category: 'Shampoo-Tests'>
            doSomething [
                <category: 'sample-category'>
                ^42
            ]

            doSomethingElse: something withArg: anArg [
                <category: 'sample-category'>
                ^something + anArg
            ]

            aMethodWithoutCategory [
                ^self class name
            ]

            foo [
                <category: 'accessors'>
                ^1337
            ]

            bar [
                <category: 'accessors'>
                ^'Smalltalk is cool!'
            ]
        ]

        Object subclass: SampleClassD [
            <category: 'Shampoo-Tests'>

            methodWithExistingCategory [
                <category: 'change me'>
            ]

            myCategoryWillBeRemoved1 [
                <category: 'to be removed'>
            ]

            myCategoryWillBeRemoved2 [
                <category: 'to be removed'>
            ]

            myCategoryWillBeRemoved3 [
                <category: 'to be removed'>
            ]
        ]

        nil subclass: SampleClassE [
            <category: 'Shampoo-Tests'>
        ]

        Object subclass: SampleClassF [
            <category: 'Shampoo-Tests'>
        ]

        Object subclass: SampleClassG [
            <category: 'Shampoo-Tests'>

            foo [
                <category: 'to be renamed'>
            ]

            bar [
                <category: 'to be renamed'>
            ]

            baz [
                <category: 'to be renamed'>
            ]
        ]

        Object subclass: SampleClassSide [
            <category: 'Shampoo-Tests'>
        ]
    ]
]

Namespace current: Shampoo [
    "We do not need these methods in the original implementation but do need it
for tests"

    Response extend [
        id [
            <category: '*Shampoo-Tests'>
            ^id
        ]
    ]

    MagicResponse extend [
        magic [
            <category: '*Shampoo-Tests'>
            ^number
        ]
    ]

    OperationalResponse extend [
        success [
            <category: '*Shampoo-Tests'>
            ^success
        ]
    ]

    ClassInfoResponse extend [
        className [
            <category: '*Shampoo-Tests'>
            ^class
        ]

        attrs [
            <category: '*Shampoo-Tests'>
            ^attrs
        ]
    ]

    MethodResponse extend [
        methodName [
            <category: '*Shampoo-Tests'>
            ^methodName
        ]
        
        methodSource [
            <category: '*Shampoo-Tests'>
            ^methodSource
        ]
    ]

    TestCase subclass: ShampooTestCase [
        <category: 'Shampoo-Tests'>

        defaultLogPolicyClass [
            <category: 'logging'>
            ^TestVerboseLog
        ]

        requestFrom: aString [
            ^Request from: (ShampooXML.ShNode from: aString)
        ]
    ]

    ShampooTestCase subclass: LoginTest [
        <category: 'Shampoo-Tests'>

        | login server info |

        setUp [
            "Magic is 1337"
            info := LoginTest authInfoSample.
            login := self requestFrom: LoginTest loginSample.
        ]

        testCreds [
            self should:
            [login creds = (info with: LoginTest magicSample)]
        ]

        LoginTest class >> loginSample [
            ^'<request id="25" type="Login">
      <creds login="dmitry" magic="0bf2f198be57c763af1c9a6f2359fdc8" />
  </request>'
        ]

        LoginTest class >> authInfoSample [
           ^AuthInfo login: 'dmitry' pass: 'pass'.
        ]

        LoginTest class >> magicSample [
            ^1337
        ]
    ]

    ShampooTestCase subclass: NamespacesTest [
        <category: 'Shampoo-Tests'>

        | namespaces r items |

        setUp [
            namespaces := self requestFrom: self namespacesSample.
            r := namespaces execute.
            items := r items at: 'namespace'
        ]

        testNamespaces [
            self should: [items includes: 'Shampoo'];
                 should: [items includes: 'ShampooSamples']
        ]

        testIndirectSubspaces [
            "Currently Shampoo supports only 'root' namespaces. Indirect subspaces should not
             be included in the response"
            | indirect |
            indirect := [Namespace allInstances detect: [:each | each environment ~= Smalltalk]]
                        ifError: [nil].
            indirect ifNotNil: [self shouldnt: [items includes: indirect name]]
        ]

        namespacesSample [
            ^'<request id="23" type="Namespaces" />'
        ]
    ]

    ShampooTestCase subclass: ClassesTest [
        <category: 'Shampoo-Tests'>

        | classes |

        setUp [
            classes := self requestFrom: self classesSample
        ]

        testClasses [
            | r items |
            r := classes execute.
            items := r items at: 'class'.
            self should: [items includes: 'SampleClassA'];
                 should: [items includes: 'SampleClassB']
        ]

        classesSample [
            ^'<request id="10" type="Classes" namespace="ShampooSamples" />'
        ]
    ]

    ShampooTestCase subclass: ClassTest [
        <category: 'Shampoo-Tests'>

        | class nilSubclass classSide r nilr classr |

        setUp [
            class := self requestFrom: self classSample.
            nilSubclass := self requestFrom: self nilSubclassSample.
            classSide := self requestFrom: self classSideSample.
            r := class execute.
            nilr := nilSubclass execute.
            classr := classSide execute
        ]

        testSuperclass [
            self should: [(r attrs at: 'superclass') = 'Object'];
                 should: [(nilr attrs at: 'superclass') = 'nil']
        ]

        testInstvars [
            | vars |
            vars := r items at: 'instvar'.
            self should: [vars includes: 'a'];
                 should: [vars includes: 'b'];
                 should: [vars includes: 'c']
        ]

        performClassVarsTestFor: aResponse [
            | vars |
            vars := aResponse items at: 'classvar'.
            self should: [vars includes: 'one'];
                 should: [vars includes: 'two'];
                 should: [vars includes: 'three']
        ]

        testClassvars [
            self performClassVarsTestFor: r
        ]

        testClassSideInstvars [
            | vars |
            vars := classr items at: 'instvar'.
            self should: [vars includes: 'd'];
                 shouldnt: [vars includes: 'a'];
                 shouldnt: [vars includes: 'b'];
                 shouldnt: [vars includes: 'c']
        ]

        testClassSideClassvars [
            self performClassVarsTestFor: classr
        ]

        classSample [
            ^'<request id="15" type="Class" namespace="ShampooSamples"
               class="SampleClassA" side="instance"/>'
        ]

        nilSubclassSample [
            ^'<request id="15" type="Class" namespace="ShampooSamples"
               class="SampleClassE" side="instance"/>'
        ]

        classSideSample [
            ^'<request id="15" type="Class" namespace="ShampooSamples"
               class="SampleClassA" side="class"/>'
        ]
    ]

    ShampooTestCase subclass: CatsTest [
        <category: 'Shampoo-Tests'>

        | cats emptyCats |

        setUp [
            cats := self requestFrom: self catsSample.
            emptyCats := self requestFrom: self emptyCatsSample.
        ]

        testCats [
            | r items |
            r := cats execute.
            items := r items at: 'category'.
            self should: [items includes: 'sample-category'];
                 should: [items includes: 'accessors']
        ]

        testEmptyCats [
            | r items |
            r := emptyCats execute.
            items := r items at: 'category'.
            self should: [items isEmpty]
        ]

        catsSample [
            ^'<request id="500" type="Categories" namespace="ShampooSamples"
               class="SampleClassB" side="instance"/>'
        ]

        emptyCatsSample [
            ^'<request id="500" type="Categories" namespace="ShampooSamples"
               class="SampleClassA" side="instance"/>'
        ]
    ]

    ShampooTestCase subclass: MethodsTest [
        <category: 'Shampoo-Tests'>

        | methods asterisk |

        setUp [
            methods := self requestFrom: self methodsSample.
            asterisk := self requestFrom: self asteriskSample.
        ]

        testMethods [
            | r items |
            r := methods execute.
            items := r items at: 'method'.
            self should: [items includes: 'doSomethingElse:withArg:'];
                 should: [items includes: 'doSomething'];
                 shouldnt: [items includes: 'foo'];
                 shouldnt: [items includes: 'bar']
        ]

        testAsterisk [
            | r items |
            r := asterisk execute.
            items := r items at: 'method'.
            self should: [items includes: 'doSomethingElse:withArg:'];
                 should: [items includes: 'doSomething'];
                 should: [items includes: 'foo'];
                 should: [items includes: 'bar']
        ]

        methodsSample [
            ^'<request id="500" type="Methods" namespace="ShampooSamples"
               class="SampleClassB" side="instance" category="sample-category"/>'
        ]

        asteriskSample [
            ^'<request id="500" type="Methods" namespace="ShampooSamples"
               class="SampleClassB" side="instance" category="*"/>'
        ]
    ]

    ShampooTestCase subclass: MethodTest [
        <category: 'Shampoo-Tests'>

        | method |

        setUp [
            method := self requestFrom: self methodSample
        ]

        testMethod [
            | r |
            "I am not sure about this test"
            r := method execute.
            self should: [r methodName = 'doSomethingElse:withArg:']
        ]

        methodSample [
            ^'<request id="123" type="MethodSource" namespace="ShampooSamples"
               class="SampleClassB" side="instance" method="doSomethingElse:withArg:"/>'
        ]
    ]

    ShampooTestCase subclass: CompileClassTest [
        <category: 'Shampoo-Tests'>

        | compileClass r compiledClass |

        setUp [
            compileClass := self requestFrom: self compileClassSample.
            r := compileClass execute.
            compiledClass := ShampooSamples at: #SampleClassC.
        ]

        testCompiledClass [
            self should: [compiledClass ~= nil]
        ]

        testInstvars [
            | vars |
            vars := compiledClass instVarNames asStringArray.
            self should: [vars includes: 'one'];
                 should: [vars includes: 'two'];
                 should: [vars includes: 'three']
        ]

        testClassvars [
            | vars |
            vars := compiledClass classVarNames asStringArray.
            self should: [vars includes: 'classOne'];
                 should: [vars includes: 'classTwo'];
                 should: [vars includes: 'classThree']
        ]

        compileClassSample [
            ^'<request id="80" type="CompileClass" superspace="Smalltalk" super="Object" namespace="ShampooSamples" class="SampleClassC">
      <instvar>one</instvar>
      <instvar>two</instvar>
      <instvar>three</instvar>
      <classvar>classOne</classvar>
      <classvar>classTwo</classvar>
      <classvar>classThree</classvar>
      <poolvar>poolOne</poolvar>
      <poolvar>poolTwo</poolvar>
      <poolvar>poolThree</poolvar>
  </request>'
        ]
    ]

    ShampooTestCase subclass: CompileClassSideTest [
        <category: 'Shampoo-Tests'>

        | classSide rside classSideResult |

        setUp [
            classSide := self requestFrom: self classSideSample.
            rside := classSide execute.
            classSideResult := ShampooSamples.SampleClassSide class
        ]

        testClassInstVars [
            | vars |
            vars := classSideResult instVarNames asStringArray.
            self should: [vars includes: 'classOne'];
                 should: [vars includes: 'classTwo'];
                 should: [vars includes: 'classThree']
        ]

        classSideSample [
            ^'<request id="80" type="CompileClass" namespace="ShampooSamples" class="SampleClassSide" side="class">
      <instvar>classOne</instvar>
      <instvar>classTwo</instvar>
      <instvar>classThree</instvar>
  </request>'
        ]
    ]

    ShampooTestCase subclass: CompileMethodTest [
        <category: 'Shampoo-Tests'>

        setUp [
            (self requestFrom: self compileMethodSample) execute.
            (self requestFrom: self compileMethodCatSample) execute.
            (self requestFrom: self compileMethodCatOvwrSample) execute.
        ]

        testCompiledMethod [
            | value |
            value := ShampooSamples.SampleClassD new sampleCompiledMethod: 11.
            self should: [value = 42]
        ]

        testMethodNoCategory [
            | method |
            method := ShampooSamples.SampleClassD
                      methodDictionary at: #sampleCompiledMethod:.
            self should:
            [method descriptor category = 'still unclassified']
        ]

        testMethodCategory [
            | method |
            method := ShampooSamples.SampleClassD
                      methodDictionary at: #sampleMethodWithCategory.
            self should:
            [method descriptor category = 'some category']
        ]

        testMethodCategoryOverwrite [
            | method |
            method := ShampooSamples.SampleClassD
                      methodDictionary at: #anotherMethodWithCategory.
            self should:
            [method descriptor category = 'used one']
        ]

        compileMethodSample [
            ^
'<request id="80"
  type="CompileMethod"
  namespace="ShampooSamples"
  class="SampleClassD"
  side="instance"
  category="*">
sampleCompiledMethod: anInteger [
    ^anInteger * 4 - 2
]
</request>'
        ]

        compileMethodCatSample [
            ^
'<request id="80"
  type="CompileMethod"
  namespace="ShampooSamples"
  class="SampleClassD"
  side="instance"
  category="some category">
sampleMethodWithCategory [
]
</request>'
        ]

        compileMethodCatOvwrSample [
            ^
'<request id="80"
  type="CompileMethod"
  namespace="ShampooSamples"
  class="SampleClassD"
  side="instance"
  category="unused category">
anotherMethodWithCategory [
   &lt;category: ''used one''&gt;
]
</request>'
        ]
    ]

    ShampooTestCase subclass: DoItTest [
        <category: 'Shampoo-Tests'>

        | doit locals |

        setUp [
            ShampooSamples at: #someUniqueKeyForDoIt put: nil.
            doit := self requestFrom: self doItSample.
            locals := self requestFrom: self localsDoItSample.
        ]

        testDoIt [
            | r |
            r := doit execute.
            self should: [42 = (ShampooSamples at: #someUniqueKeyForDoIt)];
                 should: [r statusString = 'success']
        ]

        testWithLocals [
            | r |
            r := locals execute.
            self should: ['149' = (ShampooSamples at: #someUniqueKeyForLocals)]
        ]

        doItSample [
            ^'<request id="80" type="DoIt">ShampooSamples at: #someUniqueKeyForDoIt put: 42</request>'
        ]

        localsDoItSample [
            ^'<request id="80" type="DoIt">
            | c d |
            c := OrderedCollection new.
            c add: 1; add: 2; add: 3.
            d := (c collect: [:e | e squared])
                inject: String new
                into: [:a :e | a, e asString].
            ShampooSamples at: #someUniqueKeyForLocals put: d
            </request>'
        ]
    ]

    ShampooTestCase subclass: PrintItTest [
        <category: 'Shampoo-Tests'>

        | printit |

        setUp [
            printit := self requestFrom: self printItSample
        ]

        testPrintIt [
            | r |
            r := printit execute.
            self should: [r value = 8]
        ]

        printItSample [
            ^'<request id="80" type="PrintIt">2 + 2 * 2</request>'
        ]
    ]

    ShampooTestCase subclass: OperationalResponseTest [
        <category: 'Shampoo-Tests'>

        | succ fail |

        setUp [
            succ := OperationalResponse success: 1.
            fail := OperationalResponse failure: 1.
        ]

        testSuccess [
            self should: [succ statusString = 'success']
        ]

        testFailure [
            self should: [fail statusString = 'failure']
        ]
    ]

    ShampooTestCase subclass: MessageParserTest [
        <category: 'Shampoo-Tests'>
        
        | justParser overParser underParser brokenParser |
        
        setUp [
            justParser := MessageParser new.
            overParser := MessageParser new.
            underParser := MessageParser new.
            brokenParser := MessageParser new.
        ]

        happy [
            ^'Content-Length: 2', String crlf,
                String crlf,
                ':)'
        ]

        sad [
            ^'Content-Length: 2', String crlf,
                String crlf,
                ':('
        ]

        testSimple [
            | msg r |
            msg := self happy.
            r := justParser process: msg.
            self should: [r first = ':)']
        ]

        testOver [
            | msg r |
            msg := self happy, self sad.
            r := overParser process: msg.
            self
                should: [r first = ':)'];
                should: [r second = ':(']
        ]

        testUnder [
            | msg r |
            msg := self happy, (self sad copyFrom: 1 to: 7).
            r := underParser process: msg.
            self
                should: [r first = ':)'];
                should: [r size = 1]
        ]

        testBroken [
            | msg part1 part2 r |
            msg := self sad.
            part1 := msg copyFrom: 1 to: 7.
            part2 := msg copyFrom: 8.
            r := brokenParser process: part1.
            self should: [r isEmpty].
            r := brokenParser process: part2.
            self should: [r first = ':(']
        ]
    ]

    Object subclass: ShampooGenericMock [
        | methods |
        
        methods [
            <category: 'accessors'>
            ^methods ifNil: [methods := Dictionary new]
        ]

        doesNotUnderstand: aMessage [
            <category: 'behavior'>
            | block |
            block := methods
               at: aMessage selector
               ifAbsent: [^super doesNotUnderstand: aMessage].
            ^block ifNotNil:
            [block valueWithArguments: aMessage arguments].
        ]

        on: aMessageSelector do: aBlock [
            self methods at: aMessageSelector put: aBlock
        ]

        ignore: aMessageSelector [
            self on: aMessageSelector do: nil.
        ]

        forgetAbout: aMessageSelector [
            self methods removeKey: aMessageSelector ifAbsent: []
        ]
    ]

    ShampooGenericMock subclass: ShampooConnectionMock [
        | state |

        server [
            ^self
        ]

        state [
            ^state
        ]

        state: aState [
            state := aState
        ]
    ]

    ShampooTestCase subclass: ShampooNotAuthStateTest [
        | state connMock |
        
        setUp [
            connMock := ShampooConnectionMock new.
            state := NotAuthorizedState of: connMock
        ]

        testCheckLoginSucc [
            | rq resp |
            rq := self requestFrom: LoginTest loginSample.
            connMock 
                on: #authenticates:with:
                do: [:creds :magic | true].
            [resp := state process: rq] ifError: [self fail].
            connMock forgetAbout: #authenticates:with:.

            self
              should: [connMock state class = AuthorizedState];
              should: [resp class = ServerInfoResponse]
        ]

        testCheckLoginFail [
            | rq failed |
            rq := self requestFrom: LoginTest loginSample.
            connMock
                on: #authenticates:with:
                do: [:creds :magic | false].
            [state process: rq] on: FatalError do: [failed := true].
            connMock forgetAbout: #authenticates:with:.
            self assert: failed.
        ]
    ]

    ShampooTestCase subclass: ShampooConnectionTest [
        | conn sockMock srvMock |
        
        setUp [
            sockMock := ShampooGenericMock new.
            sockMock
                ignore: #nextPutAll:;
                ignore: #crlf;
                ignore: #flush.

            srvMock := ShampooGenericMock new.
            conn := ClientConnection
               on: sockMock
               onDisconnect: [:cl | srvMock gotDisconnect]
               parent: srvMock.
        ]

        testFetchMessages [
            | msg r |
            
            msg := 'Content-Length: 9', String crlf,
                String crlf,
                'Smalltalk'.
            
            sockMock
                on: #ensureReadable do: [true];
                on: #availableBytes do: [msg size];
                on: #next: do: [:n | msg].
                
            r := conn fetchMessages.
            self should: [r first = 'Smalltalk'].
        ]

        testFetchMessagesFail [
            | caught |
            sockMock on: #ensureReadable do: [Error new signal].
            [conn fetchMessages]
            on: ClientDisconnected do: [:e | caught := true].
            self assert: caught.
        ]

        testSend [
            | packetMock strings |
            strings := OrderedCollection new.
            packetMock := ShampooGenericMock new.
            packetMock on: #asXML do: ['Shampoo'].
            "I think that testing this thing by catching
             #nextPutAll is not a very good idea."
            sockMock on: #nextPutAll: do: [:s | strings add: s].
            conn send: packetMock.
            self
                should: [strings first = 'Content-Length: 9'];
                should: [strings second = '''Shampoo'''].
        ]

        testDisconnect [
            | got |
            srvMock on: #gotDisconnect do: [got := true].
            sockMock
                on: #isPeerAlive do: [true];
                on: #ensureReadable do: [Error new signal].
            conn go.
            self assert: got.
        ]
    ]

    ShampooTestCase subclass: ShampooRemoveClassTest [
        | foo bar baz |

        setUp [
            foo := Object subclass: #ShampooFooClass.
            bar := Object subclass: #ShampooBarClass.
            baz := bar subclass: #ShampooBazClass.
        ]

        have: aClassName in: aNamespace [
            ^aNamespace includesKey: aClassName
        ]

        have: aSymbol isSubclassOf: aClass [
            ^aClass allSubclasses contains: [:cl | cl name = aSymbol]
        ]

        have: aSymbol isSubclassInstanceOf: aMetaclass [
            ^aMetaclass allSubclasses contains:
            [:mcl | mcl instanceClass name = aSymbol].
        ]

        testSimpleRemove [
            | rq |
            rq := self requestFrom: self removeFooSample.
            self
                should: [rq execute success].
            self
                shouldnt: [self have: #ShampooFooClass in: Smalltalk];
                shouldnt: [self have: #ShampooFooClass isSubclassOf: Object];
                shouldnt: [self have: #ShampooFooClass isSubclassInstanceOf: Object class]
        ]

        testHierarchyRemove [
            | rq |
            rq := self requestFrom: self removeBarSample.
            self
                shouldnt: [rq execute success].
            self
                should:   [self have: #ShampooBarClass in: Smalltalk];
                should:   [self have: #ShampooBarClass isSubclassOf: Object];
                should:   [self have: #ShampooBarClass isSubclassInstanceOf: Object class].
            self
                should:   [self have: #ShampooBazClass in: Smalltalk];
                should:   [self have: #ShampooBazClass isSubclassOf: Object];
                should:   [self have: #ShampooBazClass isSubclassInstanceOf: Object class]
        ]

        removeFooSample [
            ^'<request id="129" type="RemoveClass" namespace="Smalltalk" class="ShampooFooClass" />'
        ]

        removeBarSample [
            ^'<request id="129" type="RemoveClass" namespace="Smalltalk" class="ShampooBarClass" />'
        ]
    ]

    ShampooTestCase subclass: ShampooRemoveMethodTest [
        setUp [
            ShampooSamples.SampleClassF compile: 'foo [^123]'.
            ShampooSamples.SampleClassF class compile: 'bar [^#bar]'.
        ]

        testInstanceSide [
            | rq |
            rq := self requestFrom: self removeFooSample.
            self should: [rq execute success].
            self shouldnt: [ShampooSamples.SampleClassF canUnderstand: #foo ]
        ]

        testClassSide [
            | rq |
            rq := self requestFrom: self removeBarSample.
            self should: [rq execute success].
            self shouldnt: [ShampooSamples.SampleClassF class canUnderstand: #bar ]
        ]

        removeFooSample [
            ^'<request id="33" type="RemoveMethod" namespace="ShampooSamples" class="SampleClassF" side="instance" method="foo" />'
        ]
    
        removeBarSample  [
            ^'<request id="33" type="RemoveMethod" namespace="ShampooSamples" class="SampleClassF" side="class" method="bar" />'
        ]
    ]

    ShampooTestCase subclass: ShampooChangeCategoryTest [
        | rq foo |

        setUp [
            | method |
            method := ShampooSamples.SampleClassD methodDictionary
                      at: #methodWithExistingCategory.
            method descriptor category: 'change me'.

            rq := self requestFrom: self changeCatSample.
        ]

        testChange [
            | method |
            rq execute.
            method := ShampooSamples.SampleClassD methodDictionary
                      at: #methodWithExistingCategory.
            self should: [method descriptor category = 'changed']
        ]
       
        changeCatSample [
            ^
'<request
  id="192"
  type="ChangeCategory"
  namespace="ShampooSamples"
  class="SampleClassD"
  side="instance"
  category="changed"
  method="methodWithExistingCategory"
/>'
        ]
    ]
    
    ShampooTestCase subclass: ShampooRemoveCategoryTest [
        selectors [
            ^#( #myCategoryWillBeRemoved1
                #myCategoryWillBeRemoved2
                #myCategoryWillBeRemoved3 )
        ]

        setUp [
            self selectors do:
            [:each || method |
                    method := ShampooSamples.SampleClassD
                              methodDictionary at: each.
                    method descriptor category: 'to be removed'].

            (self requestFrom: self removeCatSample) execute.
        ]

        testRemoval [
            self selectors do:
            [:each || method |
                    method := ShampooSamples.SampleClassD
                              methodDictionary at: each.
                    self should: [method descriptor category =
                                  'still unclassified']]
        ]

        removeCatSample [
            ^
'<request
  id="11"
  type="RemoveCategory"
  namespace="ShampooSamples"
  class="SampleClassD"
  side="instance"
  category="to be removed"
/>'
        ]
    ]

    ShampooTestCase subclass: RenameCategoryTest [
        | rq |

        setUp [
            rq := self requestFrom: self renameCatSample.
            
            SampleClassG methodDictionary values do:
            [:each | each descriptor category: 'to be renamed'].
        ]

        testCategoryRename [
            | resp |
            resp := rq execute.
            self should: [resp success].

            SampleClassG methodDictionary values do:
            [:each | self should: [each descriptor category = 'finally renamed']]
        ]

        renameCatSample [
            ^
'<request
  id="133"
  type="RenameCategory"
  namespace="ShampooSamples"
  class="SampleClassG"
  side="instance"
  from="to be renamed"
  to="finally renamed"
/>'
        ]
    ]
]
