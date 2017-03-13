<%-- 
    Document   : script-placenames-searchbox
    Created on : Dec 9, 2011, 2:23:23 PM
    Author     : Paul-Inge Flakstad, Norwegian Polar Institute
--%><%@ page import="org.opencms.jsp.*, 
                 org.opencms.file.CmsPropertyDefinition,
                 java.util.*, 
                 java.util.regex.*,
                 java.net.*,
                 java.io.*,
                 no.npolar.util.*" session="true" pageEncoding="UTF-8"
%><%
//
// Fetches and outputs the HTML+js for the placenames searchbox.
//

CmsAgent cms = new CmsAgent(pageContext, request, response);
Locale locale = cms.getRequestContext().getLocale();
String loc = locale.toString();

final String LABEL_LOOKUP_PLACE_NAME = loc.equalsIgnoreCase("no") ? "Finn stadnamn" : "Lookup place name";
final String LABEL_GO_TO_SERVICE = loc.equalsIgnoreCase("no") ? 
        "eller <a href=\"http://stadnamn.npolar.no/\">gå til stadnamn-tjenesten</a>" : 
        "or <a href=\"http://placenames.npolar.no/\">go to the place names service</a>";

final String PROTOCOL = "http://";
final String HOST = "stadnamn.npolar.no";
final String SERVICE = "/api/auto".concat(loc.equalsIgnoreCase("en") ? "?lang=en" : "");



URL u;
URLConnection uc = null;
StringBuffer contentBuffer = new StringBuffer(1024);

try {
    u = new URL(PROTOCOL + HOST + SERVICE);
    uc = u.openConnection();
    BufferedReader in = new BufferedReader(
                            new InputStreamReader(
                            uc.getInputStream()));
    String inputLine;
    while ((inputLine = in.readLine()) != null) {
        contentBuffer.append(inputLine.replaceAll("<script>", "<script type=\"text/javascript\">") + "\n");
    }
    in.close();
    String content = contentBuffer.toString();

    if (content.isEmpty() || !content.contains("href=")) {
        throw new NullPointerException();
    }
    
    out.println("<div class=\"search-panel\">");
    out.println("<div class=\"search-widget\">");
    out.println("<h2>" + LABEL_LOOKUP_PLACE_NAME + "</h2>");
    out.println("<div class=\"searchbox\">");
    out.println(content.replace("type=\"submit\"", "type=\"submit\" class=\"search-button\""));
    out.println("<p><strong>" + LABEL_GO_TO_SERVICE + "</strong></p>");
    out.println("</div>");
    out.println("</div>");
    out.println("</div>");
    out.println("<script type=\"text/javascript\">");
    out.println("$(\"#geoname_autocomplete\").focus();");
    out.println("</script>");
} catch (Exception e) {
    out.println("<-- placenames searchbox unavailable -->");
}
%>