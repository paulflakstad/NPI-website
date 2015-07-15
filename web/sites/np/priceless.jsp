<%-- 
    Document   : priceless
    Created on : Feb 6, 2014, 9:46:15 AM
    Author     : Paul-Inge Flakstad, Norwegian Polar Institute
--%><%@page contentType="text/html" pageEncoding="UTF-8" import="no.npolar.util.CmsAgent, org.opencms.file.CmsObject"%>
<%
CmsAgent cms = new CmsAgent(pageContext, request, response);
CmsObject cmso = cms.getCmsObject();
String no = request.getParameter("no");
String en = request.getParameter("en");
String de = request.getParameter("de");

if (no == null || no.isEmpty()
    || en == null || en.isEmpty()
    || de == null || de.isEmpty()
    || !cmso.existsResource(no) 
    || !cmso.existsResource(en) 
    || !cmso.existsResource(de)) {
    %>
    <h2>At least one parameter was missing or referenced a non-existing target.</h2>
    <%
    return;
}

%>
<!DOCTYPE html>
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <title>Velg språk / Select language / Sprache wählen</title>
        <style>
            body {
                font-family: Tahoma, Sans-serif;
                padding:0.2em;
                padding-top:2em;
                text-align: center;
                color:#34808a;
            }
            h1 {
                display:inline-block;
                padding:0.6em 0;
                margin:0;
                border-top:1px solid #b8d8dc;
            }
            h1:first-child {
                border-top:none;
            }
            
            .qr-sel-lang,
            .qr-sel-lang:visited,
            .qr-sel-lang:hover {
                display:inline-block;
                padding:0 1em 0 180px;
                height:80px;
                line-height:80px;
                background-color:#eee;
                background-repeat:no-repeat;
                background-position:left;
                margin-top:1em;
                text-decoration:none;
                border-radius:0.5em;
                box-shadow:0 0 0.3em rgba(0,0,0,0.5);
                color:#34808a;
            }
            .qr-sel-lang:hover {
                background-color:#f5f5f5;
                box-shadow:0 0 0.1em rgba(0,0,0,0.5);
            }
            #no { background-image:url("<%= cms.link("/system/modules/no.npolar.site.npweb/resources/img/flags/no.png") %>"); padding-left:130px; }
            #en { background-image:url("<%= cms.link("/system/modules/no.npolar.site.npweb/resources/img/flags/en.png") %>"); }
            #de { background-image:url("<%= cms.link("/system/modules/no.npolar.site.npweb/resources/img/flags/de.png") %>"); padding-left: 155px; }
        </style>
    </head>
    <body>
        <div>
            <h2><a class="qr-sel-lang" id="no" href="<%= no %>">Norsk</a></h2>
            <h2><a class="qr-sel-lang" id="en" href="<%= en %>">English</a></h2>
            <h2><a class="qr-sel-lang" id="de" href="<%= de %>">Deutsch</a></h2>
        </div>
        <div>
            <h1>Vennligst velg ditt språk</h1><br />
            <h1>Please select your language</h1><br />
            <h1>Bitte wählen Sie Ihre Sprache</h1><br />
        </div>
    </body>
</html>
