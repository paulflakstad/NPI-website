<%-- 
    Document   : script-placenames-searchbox
    Created on : Dec 9, 2011, 2:23:23 PM
    Author     : flakstad
--%><%-- 
    Document   : script-jobbnorge-scrape
    Created on : 28.jul.2011, 13:11:01
    Author     : Paul-Inge Flakstad <flakstad at npolar.no>
--%><%@ page import="org.opencms.jsp.*, 
                 org.opencms.file.CmsPropertyDefinition,
                 java.util.*, 
                 java.util.regex.*,
                 java.net.*,
                 java.io.*,
                 no.npolar.util.*" session="true" 
%><%
CmsAgent cms = new CmsAgent(pageContext, request, response);
Locale locale = cms.getRequestContext().getLocale();
String loc = locale.toString();

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
        contentBuffer.append(inputLine + "\n");
    }
    in.close();
    String content = contentBuffer.toString();

    if (content.isEmpty() || !content.contains("href=")) {
        // Then there are no available positions at this time
        throw new NullPointerException();
    }
    out.println(content);
} catch (Exception e) {
    out.println("<-- placenames searchbox unavailable -->");
}
%>