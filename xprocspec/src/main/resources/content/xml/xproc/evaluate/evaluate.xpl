<p:declare-step xmlns:p="http://www.w3.org/ns/xproc" type="pxi:test-evaluate" name="main" xmlns:cx="http://xmlcalabash.com/ns/extensions" xmlns:c="http://www.w3.org/ns/xproc-step" xmlns:pxi="http://www.daisy.org/ns/xprocspec/xproc-internal/"
    exclude-inline-prefixes="#all" version="1.0" xpath-version="2.0" xmlns:x="http://www.daisy.org/ns/xprocspec">

    <p:input port="source" sequence="true"/>
    <p:output port="result" sequence="true"/>
    <p:option name="logfile" select="''"/>
    
    <p:option name="step-available-rng" select="'false'"/>

    <p:import href="compare.xpl"/>
    <p:import href="../utils/logging-library.xpl"/>
    <p:import href="../utils/validate-with-relax-ng.xpl"/>
    <p:import href="../utils/document.xpl"/>
    
    <!-- for custom x:expect implementations: -->
    <p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>

    <p:for-each name="current-test">
        <!-- for each scenario -->

        <p:variable name="base" select="base-uri(/*)"/>

        <p:choose>
            <p:when test="/*[self::c:errors]">
                <pxi:message message=" * error document; skipping">
                    <p:with-option name="logfile" select="$logfile">
                        <p:empty/>
                    </p:with-option>
                </pxi:message>
                <p:identity name="c-error"/>
            </p:when>
            <p:when test="count(/*/x:scenario/*)=0">
                <!-- skip scenario -->
                <p:identity/>
                <pxi:message message=" * skipping scenario '$1' ($2)">
                    <p:with-option name="param1" select="/x:description/x:scenario/@label"/>
                    <p:with-option name="param2" select="$base"/>
                    <p:with-option name="logfile" select="$logfile">
                        <p:empty/>
                    </p:with-option>
                </pxi:message>
            </p:when>
            <p:otherwise>
                <p:variable name="temp-dir" select="/*/@temp-dir"/>
                <p:variable name="skip-scenario" select="if (/x:description/x:scenario[@pending]) then 'true' else 'false'"/>

                <pxi:message message=" * evaluating scenario '$1' ($2)">
                    <p:with-option name="param1" select="/x:description/x:scenario/@label"/>
                    <p:with-option name="param2" select="$base"/>
                    <p:with-option name="logfile" select="$logfile">
                        <p:empty/>
                    </p:with-option>
                </pxi:message>

                <p:identity name="try.input"/>
                <p:try>
                    <p:group>
                        <p:identity name="description.pre-document-resolution"/>
                        <p:delete match="//x:document[ancestor::*[@pending]]"/>
                        <pxi:message message="   * resolving x:document elements...">
                            <p:with-option name="logfile" select="$logfile">
                                <p:empty/>
                            </p:with-option>
                        </pxi:message>
                        <p:viewport match="//x:document">
                            <!-- resolve all x:documents in the description -->
                            <pxi:document>
                                <p:input port="description">
                                    <p:pipe port="result" step="description.pre-document-resolution"/>
                                </p:input>
                                <p:with-option name="logfile" select="$logfile">
                                    <p:empty/>
                                </p:with-option>
                            </pxi:document>
                        </p:viewport>
                        <p:identity name="description"/>

                        <pxi:message message="   * grouping x:expect elements with their x:context...">
                            <p:with-option name="logfile" select="$logfile">
                                <p:empty/>
                            </p:with-option>
                        </pxi:message>
                        <p:add-attribute match="/*" attribute-name="xml:base">
                            <!-- since it won't be preserved through XSLT transforms (see this thread: http://lists.w3.org/Archives/Public/xproc-dev/2013Mar/0013.html) -->
                            <p:with-option name="attribute-value" select="base-uri(/*)"/>
                        </p:add-attribute>
                        <p:xslt>
                            <!-- group elements; there's no good way to do it in pure xproc afaik -->
                            <p:input port="parameters">
                                <p:empty/>
                            </p:input>
                            <p:input port="stylesheet">
                                <p:document href="group-assertions-with-context.xsl"/>
                            </p:input>
                        </p:xslt>

                        <pxi:message message="   * evaluating each context/expect group...">
                            <p:with-option name="logfile" select="$logfile">
                                <p:empty/>
                            </p:with-option>
                        </pxi:message>
                        <p:for-each>
                            <p:iteration-source select="/x:description/x:scenario/x:context-group"/>
                            <p:identity name="context-group"/>
                            <pxi:message message="     * setting context to '$1'">
                                <p:with-option name="param1" select="(/x:context-group/x:context/@label)[1]"/>
                                <p:with-option name="logfile" select="$logfile">
                                    <p:empty/>
                                </p:with-option>
                            </pxi:message>
                            <p:for-each name="context.documents">
                                <p:output port="result" sequence="true"/>
                                <p:iteration-source select="/x:context-group/x:context/x:document"/>
                                <p:identity/>
                            </p:for-each>
                            <p:for-each name="context">
                                <p:output port="result" sequence="true"/>
                                <p:iteration-source select="/x:document/*"/>
                                <p:identity/>
                            </p:for-each>
                            <p:count name="context.size"/>
                            <p:for-each name="assertions">
                                <p:iteration-source select="/x:context-group/*[position()&gt;1]">
                                    <p:pipe port="result" step="context-group"/>
                                </p:iteration-source>
                                <pxi:message message="       * testing assertion '$1'">
                                    <p:with-option name="param1" select="(/x:expect/@label)[1]"/>
                                    <p:with-option name="logfile" select="$logfile">
                                        <p:empty/>
                                    </p:with-option>
                                </pxi:message>
                                <p:identity name="assertion"/>

                                <p:choose>

                                    <p:when test="/x:expect[@pending] or $skip-scenario='true'">
                                        <p:identity>
                                            <p:input port="source">
                                                <p:inline>
                                                    <x:test-result result="skipped"/>
                                                </p:inline>
                                            </p:input>
                                        </p:identity>
                                        <pxi:message message="         * assertion skipped">
                                            <p:with-option name="logfile" select="$logfile">
                                                <p:empty/>
                                            </p:with-option>
                                        </pxi:message>
                                    </p:when>

                                    <p:when test="/x:expect[@type='xpath']">
                                        <!-- evaluate @test against context -->
                                        <p:variable name="test" select="/*/@test"/>
                                        <p:variable name="equals" select="(/*/@equals,'true()')[1]"/>

                                        <!-- the XPath expression must evalutate to true() for all documents on the output port, and there must be at least one document on the output port -->
                                        <p:identity>
                                            <p:input port="source">
                                                <p:pipe port="result" step="context"/>
                                            </p:input>
                                        </p:identity>
                                        <pxi:message message="         * is xpath assertion">
                                            <p:with-option name="logfile" select="$logfile">
                                                <p:empty/>
                                            </p:with-option>
                                        </pxi:message>
                                        <p:choose>
                                            <p:xpath-context>
                                                <p:pipe port="result" step="context.size"/>
                                            </p:xpath-context>
                                            <p:when test=".='0'">
                                                <pxi:message message="         * no documents in context => xpath assertion can't fail">
                                                    <p:with-option name="logfile" select="$logfile">
                                                        <p:empty/>
                                                    </p:with-option>
                                                </pxi:message>
                                            </p:when>
                                            <p:otherwise>
                                                <p:identity/>
                                            </p:otherwise>
                                        </p:choose>
                                        <p:identity name="assertion.context"/>

                                        <p:xslt name="xpath-xslt">
                                            <p:input port="parameters">
                                                <p:empty/>
                                            </p:input>
                                            <p:input port="source">
                                                <p:pipe port="result" step="assertion"/>
                                            </p:input>
                                            <p:input port="stylesheet">
                                                <p:document href="assertion-to-xslt.xsl"/>
                                            </p:input>
                                        </p:xslt>
                                        <p:for-each>
                                            <p:iteration-source>
                                                <p:pipe port="result" step="assertion.context"/>
                                            </p:iteration-source>
                                            <p:xslt>
                                                <p:with-param name="temp-dir" select="$temp-dir"/>
                                                <p:with-param name="test-base-uri" select="$base"/>
                                                <p:input port="stylesheet">
                                                    <p:pipe port="result" step="xpath-xslt"/>
                                                </p:input>
                                            </p:xslt>
                                        </p:for-each>

                                        <p:wrap-sequence wrapper="x:test-result"/>
                                        <p:xslt>
                                            <p:with-param name="test" select="$test"/>
                                            <p:with-param name="equals" select="$equals"/>
                                            <p:input port="stylesheet">
                                                <p:document href="format-test-result.xsl"/>
                                            </p:input>
                                        </p:xslt>
                                    </p:when>

                                    <p:when test="/x:expect[@type='compare']">
                                        <p:variable name="normalize-space" select="/*/@normalize-space"/>

                                        <pxi:message message="         * is document comparison">
                                            <p:with-option name="logfile" select="$logfile">
                                                <p:empty/>
                                            </p:with-option>
                                        </pxi:message>
                                        <p:for-each name="expect">
                                            <p:output port="result" sequence="true"/>
                                            <p:iteration-source select="/x:expect/x:document/*"/>
                                            <p:identity/>
                                        </p:for-each>

                                        <pxi:compare>
                                            <p:input port="source">
                                                <p:pipe port="result" step="context"/>
                                            </p:input>
                                            <p:input port="alternate">
                                                <p:pipe port="result" step="expect"/>
                                            </p:input>
                                            <p:with-option name="normalize-space" select="$normalize-space">
                                                <p:empty/>
                                            </p:with-option>
                                            <p:with-option name="logfile" select="$logfile">
                                                <p:empty/>
                                            </p:with-option>
                                        </pxi:compare>
                                        <p:rename match="/*" new-name="x:test-result"/>
                                        <p:delete match="/*/x:was"/>
                                        <p:add-attribute match="/*" attribute-name="result">
                                            <p:with-option name="attribute-value" select="if (/*/@result='true') then 'passed' else 'failed'"/>
                                        </p:add-attribute>
                                        <pxi:message message="         * assertion $1">
                                            <p:with-option name="param1" select="/*/@result"/>
                                            <p:with-option name="logfile" select="$logfile">
                                                <p:empty/>
                                            </p:with-option>
                                        </pxi:message>
                                    </p:when>

                                    <p:when test="/x:expect[@type='count']">
                                        <!-- the minimum amount of documents -->
                                        <p:variable name="min" select="/*/@min"/>

                                        <!-- the maximum amount of documents -->
                                        <p:variable name="max" select="/*/@max"/>

                                        <p:count name="count">
                                            <p:input port="source">
                                                <p:pipe port="result" step="context"/>
                                            </p:input>
                                        </p:count>
                                        <pxi:message message="         * is document count assertion">
                                            <p:with-option name="param1" select="/*/@result"/>
                                            <p:with-option name="logfile" select="$logfile">
                                                <p:empty/>
                                            </p:with-option>
                                        </pxi:message>
                                        <p:wrap-sequence wrapper="x:test-result"/>
                                        <p:add-attribute match="/*" attribute-name="result">
                                            <p:with-option name="attribute-value" select="if (($min='' or number($min) &lt;= number(.)) and ($max='' or number($max) &gt;= number(.))) then 'passed' else 'failed'"/>
                                        </p:add-attribute>
                                        <pxi:message message="         * assertion $1">
                                            <p:with-option name="param1" select="/*/@result"/>
                                            <p:with-option name="logfile" select="$logfile">
                                                <p:empty/>
                                            </p:with-option>
                                        </pxi:message>
                                        <p:rename match="/x:test-result/c:result" new-name="x:was"/>
                                        <p:identity name="test-result"/>


                                        <p:group>
                                            <p:string-replace match="/*/text()" name="expected">
                                                <p:with-option name="replace"
                                                    select="concat('&quot;',if ($min and $max) then concat('At least ',$min,' and at most ',$max,' documents.') else if ($min) then concat('At least ',$min,' documents.') else if ($max) then concat('At most ',$max,' documents.') else 'Any number of documents','&quot;')"/>
                                                <p:input port="source">
                                                    <p:inline>
                                                        <x:expected>EXPECTED</x:expected>
                                                    </p:inline>
                                                </p:input>
                                            </p:string-replace>

                                            <p:insert match="/*" position="first-child">
                                                <p:input port="source">
                                                    <p:pipe port="result" step="test-result"/>
                                                </p:input>
                                                <p:input port="insertion">
                                                    <p:pipe port="result" step="expected"/>
                                                </p:input>
                                            </p:insert>
                                        </p:group>

                                    </p:when>

                                    <p:when test="/x:expect[@type='validate' and @grammar='relax-ng']">
                                        <!--
                                            TODO:
                                            add support for Relax NG validation
                                            skip validation when Relax NG validation is not supported and display a warning instead
                                        -->
                                        <p:identity>
                                            <p:input port="source">
                                                <p:inline>
                                                    <x:test-result result="skipped">
                                                        <x:was>Relax NG validation is not implemented yet.</x:was>
                                                    </x:test-result>
                                                </p:inline>
                                            </p:input>
                                        </p:identity>
                                        <pxi:message message="         * is Relax NG assertion">
                                            <p:with-option name="logfile" select="$logfile">
                                                <p:empty/>
                                            </p:with-option>
                                        </pxi:message>
                                    </p:when>

                                    <p:when test="/x:expect[@type='validate' and @grammar='schematron']">
                                        <!--
                                            TODO:
                                            add support for Schematron validation
                                            skip validation when Schematron validation is not supported and display a warning instead
                                        -->
                                        <p:identity>
                                            <p:input port="source">
                                                <p:inline>
                                                    <x:test-result result="skipped">
                                                        <x:was>Schematron validation is not implemented yet.</x:was>
                                                    </x:test-result>
                                                </p:inline>
                                            </p:input>
                                        </p:identity>
                                        <pxi:message message="         * is Schematron assertion">
                                            <p:with-option name="logfile" select="$logfile">
                                                <p:empty/>
                                            </p:with-option>
                                        </pxi:message>
                                    </p:when>

                                    <p:when test="/x:expect[@type='validate' and @grammar='xml-schema']">
                                        <!--
                                            TODO:
                                            add support for XML Schema validation
                                            skip validation when XML Schema validation is not supported and display a warning instead
                                        -->
                                        <p:identity>
                                            <p:input port="source">
                                                <p:inline>
                                                    <x:test-result result="skipped">
                                                        <x:was>XML Schema validation is not implemented yet.</x:was>
                                                    </x:test-result>
                                                </p:inline>
                                            </p:input>
                                        </p:identity>
                                        <pxi:message message="         * is XML Schema assertion">
                                            <p:with-option name="logfile" select="$logfile">
                                                <p:empty/>
                                            </p:with-option>
                                        </pxi:message>
                                    </p:when>

                                    <p:when test="/x:expect[@type='custom']">
                                        <p:xslt name="custom.expect-invocation">
                                            <p:with-param name="temp-dir" select="$temp-dir"/>
                                            <p:with-param name="test-base-uri" select="$base"/>
                                            <p:input port="stylesheet">
                                                <p:document href="expect-to-custom-invocation.xsl"/>
                                            </p:input>
                                        </p:xslt>
                                        
                                        <!-- multiplex context and expect document sequences for cx:eval -->
                                        <p:for-each name="custom.expect">
                                            <p:output port="result" sequence="true"/>
                                            <p:iteration-source select="/x:expect/x:document">
                                                <p:pipe port="result" step="assertion"/>
                                            </p:iteration-source>
                                            <p:add-attribute match="/*" attribute-name="xml:base">
                                                <p:with-option name="attribute-value" select="base-uri(/*)"/>
                                            </p:add-attribute>
                                            <p:add-attribute match="/*" attribute-name="port" attribute-value="expect"/>
                                        </p:for-each>
                                        <p:for-each name="custom.context">
                                            <p:output port="result" sequence="true"/>
                                            <p:iteration-source>
                                                <p:pipe port="result" step="context.documents"/>
                                            </p:iteration-source>
                                            <p:add-attribute match="/*" attribute-name="xml:base">
                                                <p:with-option name="attribute-value" select="base-uri(/*)"/>
                                            </p:add-attribute>
                                            <p:add-attribute match="/*" attribute-name="port" attribute-value="context"/>
                                        </p:for-each>
                                        
                                        <cx:eval>
                                            <p:input port="pipeline">
                                                <p:pipe port="result" step="custom.expect-invocation"/>
                                            </p:input>
                                            <p:input port="source">
                                                <p:pipe port="result" step="custom.context"/>
                                                <p:pipe port="result" step="custom.expect"/>
                                            </p:input>
                                            <p:input port="options">
                                                <p:empty/>
                                            </p:input>
                                        </cx:eval>
                                    </p:when>

                                    <p:otherwise>
                                        <p:identity>
                                            <!-- this should not happen since the description document is already validated; XProc requires a p:otherwise though... -->
                                            <p:input port="source">
                                                <p:inline>
                                                    <x:test-result result="failed">
                                                        <x:was>Unknown assertion type.</x:was>
                                                    </x:test-result>
                                                </p:inline>
                                            </p:input>
                                        </p:identity>
                                        <pxi:message message="         * could not determine type of assertion">
                                            <p:with-option name="logfile" select="$logfile">
                                                <p:empty/>
                                            </p:with-option>
                                        </pxi:message>
                                    </p:otherwise>
                                </p:choose>
                                
                                <p:add-attribute match="/*" attribute-name="contextref" name="test-result.missing-attributes">
                                    <p:with-option name="attribute-value" select="/*/@contextref">
                                        <p:pipe port="result" step="assertion"/>
                                    </p:with-option>
                                </p:add-attribute>
                                <p:xslt>
                                    <p:input port="parameters">
                                        <p:empty/>
                                    </p:input>
                                    <p:input port="stylesheet">
                                        <p:document href="test-result.re-add-attributes.xsl"/>
                                    </p:input>
                                    <p:input port="source">
                                        <p:pipe port="result" step="test-result.missing-attributes"/>
                                        <p:pipe port="current" step="assertions"/>
                                    </p:input>
                                </p:xslt>
                            </p:for-each>
                        </p:for-each>
                        <p:identity name="test-results"/>

                        <p:insert match="/*" position="last-child">
                            <p:input port="source">
                                <p:pipe port="result" step="description"/>
                            </p:input>
                            <p:input port="insertion">
                                <p:pipe port="result" step="test-results"/>
                            </p:input>
                        </p:insert>

                        <p:wrap-sequence wrapper="calabash-issue-102"/>
                    </p:group>
                    <p:catch name="catch">
                        <p:identity>
                            <p:input port="source">
                                <p:pipe port="error" step="catch"/>
                            </p:input>
                        </p:identity>
                        <p:add-attribute match="/*" attribute-name="xml:base">
                            <p:with-option name="attribute-value" select="$base"/>
                        </p:add-attribute>
                        <p:add-attribute match="/*" attribute-name="test-base-uri">
                            <p:with-option name="attribute-value" select="$base"/>
                        </p:add-attribute>
                        <p:add-attribute match="/*" attribute-name="error-location" attribute-value="evaluate.xpl - evaluation of assertions"/>

                        <p:identity name="errors-without-was"/>
                        <p:wrap-sequence wrapper="x:was">
                            <p:input port="source">
                                <p:pipe port="result" step="try.input"/>
                            </p:input>
                        </p:wrap-sequence>
                        <p:add-attribute match="/*" attribute-name="xml:base">
                            <p:with-option name="attribute-value" select="base-uri(/*/*)"/>
                        </p:add-attribute>
                        <p:wrap-sequence wrapper="c:error"/>
                        <p:add-attribute match="/*" attribute-name="type" attribute-value="was"/>
                        <p:identity name="was"/>
                        <p:insert match="/*" position="last-child">
                            <p:input port="source">
                                <p:pipe port="result" step="errors-without-was"/>
                            </p:input>
                            <p:input port="insertion">
                                <p:pipe port="result" step="was"/>
                            </p:input>
                        </p:insert>

                        <p:wrap-sequence wrapper="calabash-issue-102"/>
                    </p:catch>
                </p:try>
                <p:for-each>
                    <!-- temporary fix for https://github.com/ndw/xmlcalabash1/issues/102 -->
                    <p:iteration-source select="/calabash-issue-102/*"/>
                    <p:identity/>
                </p:for-each>
            </p:otherwise>
        </p:choose>

        <!-- validate output grammar -->
        <p:group>
            <p:identity name="try.input"/>
            <p:try>
                <p:group>
                    <p:add-attribute match="/*" attribute-name="xml:base">
                        <p:with-option name="attribute-value" select="base-uri(/*)"/>
                    </p:add-attribute>
                    <p:xslt>
                        <!-- create missing namespaces in c:error/@code (see https://github.com/ndw/xmlcalabash1/issues/107) -->
                        <p:input port="parameters">
                            <p:empty/>
                        </p:input>
                        <p:input port="stylesheet">
                            <p:document href="calabash-issue-107.xsl"/>
                        </p:input>
                    </p:xslt>
                    <pxi:validate-with-relax-ng>
                        <p:input port="schema">
                            <p:document href="../../schema/xprocspec.evaluate.rng"/>
                        </p:input>
                        <p:with-option name="step-available" select="$step-available-rng">
                            <p:empty/>
                        </p:with-option>
                    </pxi:validate-with-relax-ng>
                    <p:wrap-sequence wrapper="calabash-issue-102"/>
                </p:group>
                <p:catch name="catch">
                    <p:identity>
                        <p:input port="source">
                            <p:pipe port="error" step="catch"/>
                        </p:input>
                    </p:identity>
                    <p:add-attribute match="/*" attribute-name="xml:base">
                        <p:with-option name="attribute-value" select="$base"/>
                    </p:add-attribute>
                    <p:add-attribute match="/*" attribute-name="test-base-uri">
                        <p:with-option name="attribute-value" select="$base"/>
                    </p:add-attribute>
                    <p:add-attribute match="/*" attribute-name="error-location" attribute-value="evaluate.xpl - validation of output grammar"/>

                    <p:identity name="errors-without-was"/>
                    <p:wrap-sequence wrapper="x:was">
                        <p:input port="source">
                            <p:pipe port="result" step="try.input"/>
                        </p:input>
                    </p:wrap-sequence>
                    <p:add-attribute match="/*" attribute-name="xml:base">
                        <p:with-option name="attribute-value" select="base-uri(/*/*)"/>
                    </p:add-attribute>
                    <p:wrap-sequence wrapper="c:error"/>
                    <p:add-attribute match="/*" attribute-name="type" attribute-value="was"/>
                    <p:identity name="was"/>
                    <p:insert match="/*" position="last-child">
                        <p:input port="source">
                            <p:pipe port="result" step="errors-without-was"/>
                        </p:input>
                        <p:input port="insertion">
                            <p:pipe port="result" step="was"/>
                        </p:input>
                    </p:insert>

                    <p:wrap-sequence wrapper="calabash-issue-102"/>
                </p:catch>
            </p:try>
            <p:for-each>
                <!-- temporary fix for https://github.com/ndw/xmlcalabash1/issues/102 -->
                <p:iteration-source select="/calabash-issue-102/*"/>
                <p:identity/>
            </p:for-each>
        </p:group>

    </p:for-each>

</p:declare-step>
