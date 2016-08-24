<%-- 
    Document   : noaccess
    Created on : Aug 24, 2016, 11:43:34 AM
    Author     : Paul-Inge Flakstad, Norwegian Polar Institute <flakstad at npolar.no>
--%><%@page contentType="text/html" pageEncoding="UTF-8"
%><%@page import="org.opencms.jsp.*,
		org.opencms.file.types.*,
		org.opencms.file.*,
                org.opencms.util.CmsStringUtil,
                org.opencms.util.CmsHtmlExtractor,
                org.opencms.util.CmsRequestUtil,
                org.opencms.security.CmsRoleManager,
                org.opencms.security.CmsRole,
                org.opencms.mail.CmsSimpleMail,
                org.opencms.main.OpenCms,
                org.opencms.xml.content.*,
                org.opencms.db.CmsResourceState,
                org.opencms.flex.CmsFlexController,
		java.util.*,
                java.text.SimpleDateFormat,
                java.text.DateFormat,
                no.npolar.common.menu.*,
                no.npolar.util.CmsAgent,
                no.npolar.util.contentnotation.*"
%><%@taglib prefix="cms" uri="http://www.opencms.org/taglib/cms"
%><%
CmsAgent cms = new CmsAgent(pageContext, request, response);
String ip = cms.getRequest().getRemoteAddr();
%><!DOCTYPE HTML>
<html lang="no">
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width,initial-scale=1,minimum-scale=0.5,user-scalable=yes" />
        <title>Ingen tilgang / No access</title>
        <style type="text/css">
            html,
            body {
                margin:0;
                padding:0;
                background:#555;
                font-family:Tahoma, Geneva, sans-serif;
                text-align:center;
            }
            #page {
                width:94%;
                max-width:800px;
                max-width:calc(800px - 3%);
                margin:0 auto;
                padding:3em 3% 0 3%;
                background:#fff;
                box-shadow:0 0 1em rgba(0,0,0,0.7);
            }
            *[lang="en"] {
                font-style:italic;
            }
            article {
            }
            footer {
                display:block;
                padding:1em;
                margin:5em auto 1em auto;
                border-top:1px solid #eee;
                font-size:0.8em;
            }
        </style>
    </head>
    <body>
        <div id="page">
            <article>
                <h1>Ingen tilgang – <span lang="en">No access</span></h1>
                <section>
                    <p>Siden du forespurte, er tilgjengelig kun for brukere på Polarinstituttets nettverk.</p>
                    <p lang="en">The page you requested is available only to users on the Polar Institute's network.</p>	
                    <p>
                        (IP <%= ip %>)
                    </p>
                </section>
            </article>
            <footer>
                <p>
                    <a href="http://www.npolar.no/">Gå til Norsk Polarinstitutt</a> – <a lang="en" href="http://www.npolar.no/">Go to the Norwegian Polar Institute</a>
                </p>
                <a href="http://www.npolar.no/">
                    <img src="http://www.npolar.no/npcms/export/system/modules/no.npolar.site.npweb/resources/style/np-logo-no-text.png" alt="">
                </a>
            </footer>
        </div>
    </body>
</html>
