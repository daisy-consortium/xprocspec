<p:declare-step xmlns:p="http://www.w3.org/ns/xproc" type="px:test-preprocess" xmlns:cx="http://xmlcalabash.com/ns/extensions" xmlns:c="http://www.w3.org/ns/xproc-step" xmlns:px="http://www.daisy.org/ns/pipeline/xproc" exclude-inline-prefixes="#all"
    version="1.0" xpath-version="2.0" xmlns:t="http://xproc.org/ns/testsuite" xmlns:pkg="http://expath.org/ns/pkg" pkg:import-uri="http://josteinaj.no/ns/2013/xprocspec/preprocess.xpl" xmlns:x="http://www.daisy.org/ns/pipeline/xproc/test">

    <p:input port="source"/>
    <p:output port="result" sequence="true">
        <p:pipe port="scenarios" step="for-each"/>
    </p:output>

    <p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>

    <p:declare-step type="x:perform-imports" name="perform-imports">
        <p:input port="source"/>
        <p:output port="result" sequence="true">
            <p:pipe port="source" step="perform-imports"/>
            <p:pipe port="result" step="perform-imports.imports"/>
        </p:output>
        <p:for-each>
            <p:iteration-source select="/*/x:import"/>
            <p:load>
                <p:with-option name="href" select="resolve-uri(/*/@href,base-uri(/*))"/>
            </p:load>
        </p:for-each>
        <p:identity name="perform-imports.imports"/>
    </p:declare-step>

    <!-- transform other test vocabularies to xprocspec -->
    <p:choose>
        <p:when test="/*/namespace-uri()='http://www.daisy.org/ns/pipeline/xproc/test'">
            <p:output port="result" primary="true" sequence="true"/>
            <p:identity/>
        </p:when>
        <p:when test="/*/namespace-uri()='http://xproc.org/ns/testsuite'">
            <p:output port="result" primary="true" sequence="true"/>
            <p:variable name="href" select="concat('file:/tmp/',replace(replace(base-uri(/*),'^.*/([^/]*)$','$1'),'\.[^\.]*',''),'.xpl')"/>
            <p:choose>
                <p:when test="/t:test-suite">
                    <p:output port="result" primary="true" sequence="true"/>
                    <p:for-each>
                        <p:iteration-source select="/t:test-suite/t:test"/>
                        <p:load>
                            <p:with-option name="href" select="resolve-uri(/*/@href,base-uri())"/>
                        </p:load>
                    </p:for-each>
                </p:when>
                <p:otherwise>
                    <p:output port="result" primary="true" sequence="true"/>
                    <p:identity/>
                </p:otherwise>
            </p:choose>
            <p:for-each>
                <p:variable name="href" select="concat('file:/tmp/',replace(replace(base-uri(/*),'^.*/([^/]*)$','$1'),'\.[^\.]*',''),'.xpl')"/>
                <p:viewport match="t:pipeline//*[@href and not(@href='')] | t:compare-pipeline//*[@href and not(@href='')]">
                    <p:add-attribute match="/*" attribute-name="href">
                        <p:with-option name="attribute-value" select="resolve-uri(/*/@href,base-uri(/*))"/>
                    </p:add-attribute>
                </p:viewport>
                <p:xslt>
                    <p:input port="parameters">
                        <p:empty/>
                    </p:input>
                    <p:input port="stylesheet">
                        <p:document href="xprocTestSuite-to-xprocspec.xsl"/>
                    </p:input>
                </p:xslt>
                <p:add-attribute match="/*" attribute-name="script" name="xproctestsuite">
                    <p:with-option name="attribute-value" select="$href"/>
                </p:add-attribute>

                <p:store>
                    <p:input port="source" select="/*/x:script/*"/>
                    <p:with-option name="href" select="$href"/>
                </p:store>

                <p:identity>
                    <p:input port="source">
                        <p:pipe port="result" step="xproctestsuite"/>
                    </p:input>
                </p:identity>
                <p:delete match="/*/x:script"/>
            </p:for-each>
        </p:when>
        <p:otherwise>
            <p:output port="result" primary="true" sequence="true"/>
            <p:sink/>
            <p:identity>
                <p:input port="source">
                    <p:empty/>
                </p:input>
            </p:identity>
        </p:otherwise>
    </p:choose>

    <p:for-each name="for-each">
        <p:output port="scenarios" sequence="true">
            <p:pipe port="result" step="for-each.scenarios"/>
        </p:output>
        <p:identity name="main-document"/>
        <x:perform-imports/>

        <p:for-each>
            <p:output port="result" sequence="true"/>

            <!-- create a new x:description document for each x:scenario element with inferred inputs, options and parameters -->
            <p:add-attribute match="/*" attribute-name="script">
                <p:with-option name="attribute-value" select="resolve-uri(/*/@script,base-uri(/*))"/>
            </p:add-attribute>
            <p:viewport match="//x:call[@step]">
                <p:add-attribute match="/*" attribute-name="x:step">
                    <p:with-option name="attribute-value" select="concat('{',namespace-uri-from-QName(resolve-QName(/*/@step,/*)),'}',tokenize(/*/@step,':')[last()])"/>
                </p:add-attribute>
            </p:viewport>
            <p:xslt>
                <p:input port="parameters">
                    <p:empty/>
                </p:input>
                <p:input port="stylesheet">
                    <p:document href="infer-scenarios.xsl"/>
                </p:input>
            </p:xslt>
            <p:for-each>
                <p:iteration-source select="/*/*"/>
                <p:variable name="step" select="//x:call/@x:step"/>
                <p:insert match="/*" position="first-child">
                    <p:input port="insertion">
                        <p:pipe port="result" step="step-declarations"/>
                    </p:input>
                </p:insert>
                <p:delete>
                    <p:with-option name="match" select="concat('/*/x:script-declaration/*[not(@x:type=&quot;',$step,'&quot;)]')"/>
                </p:delete>
            </p:for-each>
        </p:for-each>
        <p:identity name="for-each.scenarios"/>
        <p:sink/>

        <p:identity>
            <p:input port="source">
                <p:pipe port="result" step="main-document"/>
            </p:input>
        </p:identity>
        <p:group>
            <p:variable name="script-uri" select="resolve-uri(/*/@script,base-uri(/*))"/>
            <p:for-each>
                <p:iteration-source select="//x:call"/>
                <p:add-attribute match="/*" attribute-name="step">
                    <p:with-option name="attribute-value" select="concat('{',namespace-uri-from-QName(resolve-QName(/*/@step,/*)),'}',tokenize(/*/@step,':')[last()])"/>
                </p:add-attribute>
                <p:delete match="/*/*"/>
            </p:for-each>
            <p:wrap-sequence wrapper="wrapper"/>
            <p:delete match="x:call[concat(@step-namespace,@step-name)=preceding::x:call/concat(@step-namespace,@step-name)]"/>
            <p:for-each>
                <p:iteration-source select="/*/*"/>
                <p:identity/>
            </p:for-each>
            <p:identity name="calls"/>

            <p:load>
                <p:with-option name="href" select="$script-uri"/>
            </p:load>
            <p:viewport match="//p:declare-step | //p:pipeline">
                <p:add-attribute match="/*" attribute-name="x:type">
                    <p:with-option name="attribute-value" select="concat('{',namespace-uri-from-QName(resolve-QName(/*/@type,/*)),'}',tokenize(/*/@type,':')[last()])"/>
                </p:add-attribute>
            </p:viewport>
            <p:identity name="script"/>

            <p:for-each>
                <p:iteration-source>
                    <p:pipe port="result" step="calls"/>
                </p:iteration-source>
                <p:variable name="step" select="/*/@step"/>
                <p:for-each>
                    <p:iteration-source select="(//p:declare-step | //p:pipeline)[@x:type=$step]">
                        <p:pipe port="result" step="script"/>
                    </p:iteration-source>
                    <p:identity/>
                </p:for-each>
                <p:identity name="step-declaration"/>
                <p:count/>
                <p:choose>
                    <p:when test="number(.)=0">
                        <!-- TODO: step not found; throw error? -->
                        <p:identity>
                            <p:input port="source">
                                <p:empty/>
                            </p:input>
                        </p:identity>
                    </p:when>
                    <p:otherwise>
                        <p:identity>
                            <p:input port="source">
                                <p:pipe port="result" step="step-declaration"/>
                            </p:input>
                        </p:identity>
                        <p:delete match="/*/*[not(self::p:input or self::p:output or self::p:option)]"/>
                    </p:otherwise>
                </p:choose>
            </p:for-each>
            <p:for-each>
                <p:insert match="/p:pipeline" position="first-child">
                    <p:input port="insertion">
                        <p:inline>
                            <p:input port="source" primary="true"/>
                        </p:inline>
                        <p:inline>
                            <p:input port="parameters" kind="parameter" primary="true"/>
                        </p:inline>
                        <p:inline>
                            <p:output port="result" primary="true"/>
                        </p:inline>
                    </p:input>
                </p:insert>
                <p:rename match="/p:pipeline" new-name="p:declare-step"/>
                <p:delete match="/p:pipeline/p:input[@port=following-sibling::p:input/@port]"/>
                <p:delete match="/p:pipeline/p:output[@port=following-sibling::p:output/@port]"/>
            </p:for-each>
            <p:wrap-sequence wrapper="x:step-declaration"/>
        </p:group>
        <p:identity name="step-declarations"/>
        <p:sink/>
    </p:for-each>

</p:declare-step>
