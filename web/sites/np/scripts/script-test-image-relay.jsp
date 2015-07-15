<%-- 
    Document   : script-test-image-relay
    Created on : 09.jun.2011, 09:37:58
    Author     : Paul-Inge Flakstad <flakstad at npolar.no>
--%><%@ page import="no.npolar.util.CmsAgent,
                 java.util.*,
                 java.net.*,
                 java.io.*,
                 java.text.SimpleDateFormat,
                 org.opencms.jsp.I_CmsXmlContentContainer,
                 org.opencms.file.*,
                 org.opencms.file.types.*,
                 org.opencms.main.*,
                 org.opencms.util.CmsUUID,
                 org.opencms.xml.*,
                 org.opencms.xml.types.*,
                 org.opencms.xml.content.*,
                 org.opencms.util.*" session="true" %><%!
                 
/**
* Gets an exception's stack strace as a string.
*/
public String getStackTrace(Exception e) {
    String trace = "<div style=\"border:1px solid #900; color:#900; font-family:Courier, Monospace; font-size:80%; padding:1em; margin:2em;\">";
    trace+= "<p style=\"font-weight:bold;\">" + e.getMessage() + "</p>";
    StackTraceElement[] ste = e.getStackTrace();
    for (int i = 0; i < ste.length; i++) {
        StackTraceElement stElem = ste[i];
        trace += stElem.toString() + "<br />";
    }
    trace += "</div>";
    return trace;
}
%><%
// Action element and CmsObject
CmsAgent cms                        = new CmsAgent(pageContext, request, response);
CmsObject cmso                      = cms.getCmsObject();
// Commonly used variables
String requestFileUri               = cms.getRequestContext().getUri();
String requestFolderUri             = cms.getRequestContext().getFolderUri();
Locale locale                       = cms.getRequestContext().getLocale();
String loc                          = locale.toString();

CmsFile image = cmso.readFile("/images/icons/facebook.png");
byte[] imgRaw = image.getContents();
String imgName = "myimage.png";


try {
    // Construct data
    /*String data = URLEncoder.encode("HTTP_RAW_POST_DATA", "UTF-8") + "=" + URLEncoder.encode(new String(imgRaw, "UTF-8"), "UTF-8");
    data += "&" + URLEncoder.encode("FILE_NAME", "UTF-8") + "=" + URLEncoder.encode(imgName, "UTF-8");*/
    
    String data = "HTTP_RAW_POST_DATA=" + new String(imgRaw, "UTF-8");
    data += "&FILE_NAME=" + imgName;
    // Send data
    URL url = new URL("http://www.npolar.no/image-genny.jsp");
    URLConnection conn = url.openConnection();
    conn.setDoOutput(true);
    OutputStreamWriter writer = new OutputStreamWriter(conn.getOutputStream());
    writer.write(data);
    writer.flush();
    writer.close();

    // Get the response
    BufferedReader reader = new BufferedReader(new InputStreamReader(conn.getInputStream()));
    String line;
    while ((line = reader.readLine()) != null) {
        out.print(line);
    }
    writer.close();
    reader.close();

} catch (Exception e) {
    out.println(getStackTrace(e));
}
%>