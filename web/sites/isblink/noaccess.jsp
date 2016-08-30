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
%><%!
/**
 * Method copied from master template. 
 */
public boolean isAllowedAccess(CmsAgent cms) {
    if (OpenCms.getRoleManager().hasRole(cms.getCmsObject(), CmsRole.WORKPLACE_USER)) {
        // Logged-in user -> allow
        return true;
    }

    try {
        // 158.39.64/65      // Tromsø
        // 158.39.97.80-94   // VPN
        // 158.39.97.128-255 // Troll
        // 193.156.10/15     // Svalbard

        String ip = cms.getRequest().getRemoteAddr();
        String[] ipParts = ip.split("\\.");
        int ipA = Integer.parseInt(ipParts[0]);
        int ipB = Integer.parseInt(ipParts[1]);
        int ipC = Integer.parseInt(ipParts[2]);
        int ipD = Integer.parseInt(ipParts[3]);

        if (ipA == 158 && ipB == 39) {
            if (ipC == 64 || ipC == 65) {
                return true;
            } else if (ipC == 97) {
                if ((ipD >= 80 && ipD <= 94) || (ipD >= 128 && ipD <= 255)) {
                    return true;
                }
            }
        } else if (ipA == 193 && ipB == 156) {
            if (ipC == 10 || ipC == 15) {
                return true;
            }
        }
        return false;
    } catch (Exception e) {
        return false;
    }
}
%><%
CmsAgent cms = new CmsAgent(pageContext, request, response);
CmsObject cmso = cms.getCmsObject();
String requestFileUri = cms.getRequestContext().getUri();
//String reportHandler = "/report-error.jsp";
String ip = cms.getRequest().getRemoteAddr();
final String PARAM_NAME_REPORT = "report";

boolean loggedInUser = OpenCms.getRoleManager().hasRole(cms.getCmsObject(), CmsRole.WORKPLACE_USER);
boolean reportSent = false;
boolean reportFailed = false;

String reporting = cms.getRequest().getParameter(PARAM_NAME_REPORT);
if (reporting != null) {
    String onlinePage = OpenCms.getLinkManager().getOnlineLink(cmso, requestFileUri);
    Map params = new HashMap(cms.getRequest().getParameterMap());
    Set pKeys = params.keySet();
    try {
        CmsSimpleMail m = new CmsSimpleMail();

        m.addTo("web" + "@" + "npolar" + "." + "no");
        m.setSubject("User reported error at " + onlinePage);
        m.setFrom("no-reply" + "@" + "npolar" + "." + "no");

        String msg = "A user reported a potential access control error on the page at "
                + onlinePage
                + "\n\nHere are the details:\n\n";
        for (Object pKey : pKeys) {
            if (!pKey.equals("report")) {
                msg += "" + (String)pKey + ": " + ((String[])params.get(pKey))[0] + "\n";
            }
        }
        m.setMsg(msg);
        m.send();
        reportSent = true;
    } catch (Exception e) {
        reportFailed = true;
    }
}

// Redirect non-logged-in users that are allowed access
// (E.g. when refreshing this page at work, following an at-home attempt)
if (isAllowedAccess(cms) && !loggedInUser) {
    cms.sendRedirect(OpenCms.getLinkManager().getOnlineLink(cms.getCmsObject(), "/no/"), HttpServletResponse.SC_MOVED_TEMPORARILY);
    return;
}

%><!DOCTYPE HTML>
<html lang="no">
    <head>
        <title>Ingen tilgang / No access</title>
        <meta name="robots" content="noindex">
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width,initial-scale=1,minimum-scale=0.5,user-scalable=yes">
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
            ul {
                font-family: monospace;
                list-style: none;
                display: block;
                padding: 0;
                margin: 0;
            }
            section + section {
                border: 1px solid #eee;
                background-color: #fcfcd3;
                padding: 2rem;
                margin-top: 3rem;
            }
            footer {
                display:block;
                padding:1em;
                margin:3rem auto 1em auto;
                border-top:1px solid #eee;
                font-size:0.8em;
            }
            h2 {
                font-size: 1.2em;
                margin: 0;
            }
            h3 {
                font-size: 0.9em;
            }
            dl {
                font-family: monospace;
            }
            dt {
                font-weight: bold;
            }
            form {
                text-align: left;
                font-size: smaller;
            }
            textarea,label {
                display:block;
                width:100%;
                margin-bottom: 0.5rem;
            }
            input[type="text"], 
            input[type="email"] {
                width: 100%;
                border: 1px solid #ddd;
                max-width: 20em;
                display: inline-block;
                padding: 0.5em;
            }
            input[readonly] {
                background-color:#eee;
                color:#888;
            }
            button {
                display:inline-block;
                background-color:#0190c6;
                color:white;
                padding:1em 2em;
                border:none;
                border-radius:3px;
                cursor: pointer;
            }
            button:hover,
            button:focus {
                background-color:#00a9e9;
            }
            .hidden.result {
                display:none;
            }
            .show-fail .result--fail,
            .show-ok .result--ok {
                display: block !important;
            }
            .show-ok #error-reporting {
                display:none;
            }
        </style>
        <!--[if lt IE 9]>
            <script src="//ajax.googleapis.com/ajax/libs/jquery/1.11.2/jquery.min.js"></script>
       <![endif]-->
       <!--[if gte IE 9]><!-->
            <script src="//ajax.googleapis.com/ajax/libs/jquery/2.1.1/jquery.min.js"></script>
       <!--<![endif]-->
    </head>
    <body class="<%= reportFailed ? "show-fail" : (reportSent ? "show-ok" : "") %>">
        <div id="page">
            <article>
                <h1>Ingen tilgang <br><span lang="en">No access</span></h1>
                <section>
                    <p>Siden du forespurte, er tilgjengelig kun for brukere på Polarinstituttets nettverk.</p>
                    <p lang="en">The page you requested is available only to users on the Polar Institute's network.</p>
                </section>
                <section class="error-reporting">
                    <h2>Overrasket? <br><span lang="en">Surprised?</span></h2>
                    <% 
                    //if (!reportSent) {       
                    %>
                    <p>Vi fant det riktig å nekte deg tilgang.<br>Mistenker du at dette er feil?</p>
                    <p lang="en">We decided not to grant you access.<br>Do you suspect we were mistaken?</p>
                    
                    <div class="dialog modal collapsed" id="error-reporting">
                        <h3>Meld fra om mulig feil i tilgangskontrollen <br><span lang="en">Report potential issue with access control</span></h3>
                        <form class="async">
                            <label for="description">Kommentar / <span lang="en">Comment</span></label>
                            <textarea id="description" name="description"></textarea>
                            <label>Din e-post / <span lang="en">Your email</span> <input type="email" name="email" required></label>
                            <label>IP <input name="IP" type="text" readonly="readonly" value="<%= ip %>"></label>
                            <label>X-Forwarded-For <input name="X-Forwarded-For" type="text" readonly="readonly" value="<%= cms.getRequest().getHeader("X-Forwarded-For") %>"></label>
                            <label>WL-Proxy-Client-IP <input name="WL-Proxy-Client-IP" type="text" readonly="readonly" value="<%= cms.getRequest().getHeader("WL-Proxy-Client-IP") %>"></label>
                            <label>HTTP_CLIENT_IP <input name="HTTP_CLIENT_IP" type="text" readonly="readonly" value="<%= cms.getRequest().getHeader("HTTP_CLIENT_IP") %>"></label>
                            <label>HTTP_X_FORWARDED_FOR <input name="HTTP_X_FORWARDED_FOR" type="text" readonly="readonly" value="<%= cms.getRequest().getHeader("HTTP_X_FORWARDED_FOR") %>"></label>
                            <input type="hidden" value="yes" name="<%= PARAM_NAME_REPORT %>">
                            <button type="submit">Send</button>
                        </form>
                        <section style="text-align: left; display:none;">
                        <h3>All headers</h3>
                        <dl>
                            <%
                            // Print all headers
                            Enumeration headerNames = request.getHeaderNames();
                            while (headerNames.hasMoreElements()) {
                                String headerName = (String)headerNames.nextElement();
                                Enumeration headerValues = request.getHeaders(headerName);
                                out.println("<dt>" + headerName + "</dt><dd>");
                                while (headerValues.hasMoreElements()) {
                                    out.println((String)headerValues.nextElement());
                                }
                                out.println("</dd>");
                            }
                            %>
                        </dl>
                        </section>
                    </div>
                    <%
                    //} else {
                    %>
                    <div class="hidden result result--ok">
                        <p><strong>Takk!</strong> Vi vil undersøke dette, og kontakter deg snart.</p>
                        <p lang="en"><strong>Thanks!</strong> We'll look into this and get back to you shortly.</p>
                    </div>
                    <div class="hidden result result-fail">
                        <p><strong>Noe gikk galt.</strong> Beklager, men rapporteringen fungerer ikke for øyeblikket. Vennligst prøv igjen, eller gi oss beskjed via e-post.<p>
                        <p lang="en"><strong>Something went wrong.</strong> We're sorry, but the reporting is not working at the moment. Please try again, or report manually via email.<p>
                    </div>
                    <%
                    //}
                    %>
                        <!--
                    <ul>
                        <li>IP: <%= ip %></li>
                        <li>X-Forwarded-For: "<%= cms.getRequest().getHeader("X-Forwarded-For") %>"</li>
                        <li>WL-Proxy-Client-IP: "<%= cms.getRequest().getHeader("WL-Proxy-Client-IP") %>"</li>
                        <li>HTTP_CLIENT_IP: "<%= cms.getRequest().getHeader("HTTP_CLIENT_IP") %>"</li>
                        <li>HTTP_X_FORWARDED_FOR: "<%= cms.getRequest().getHeader("HTTP_X_FORWARDED_FOR") %>"</li>
                    </ul>
                        -->
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
<script>
function showOK() {
    $("#error-reporting form").hide();
    $(".hidden.result.result--ok").show();
}
function showFail() {
    $(".hidden.result.result--ok").hide();
    $(".hidden.result.result--fail").show();
}
$(document).ready(function() {
    $(".modal.collapsed").hide();
    $(".error-reporting").first("p").append("<p><button class='report'>Ja / <span lang='en'>Yes</span></button></p>");
    $(".report").click(function(e) {
        $(".modal.collapsed").slideDown();
        $(this).hide();
    });
    $("form.async").submit(function(e) {
        e.preventDefault(); // avoid to execute the actual submit of the form
        var formData = $(this).serialize();
        $.ajax({
            type: "POST",
            data: formData,
            success: function(data) {
                showOK();
            },
            error: function(data) {
                showFail();
            }
        });
    });
});
</script>
                                
    </body>
</html>
