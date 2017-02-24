<%-- 
    Document   : rss-proxy-jobbnorge.xml.jsp
    Description: Proxy (mirror) for the feed of available positions.
                    A proxy is employed to avoid CORS issues when accessing the
                    feed via javascript, and for cache control.
                    The output should be cached. (Initially cached for 10 mins.)
    Created on : Feb 21 2017, 16:26
    Author     : Paul-Inge Flakstad, Norwegian Polar Institute
--%>
<%@page import="org.opencms.flex.CmsFlexController" %>
<%@page import="org.apache.commons.mail.EmailException" %>
<%@page import="org.dom4j.Document" %>
<%@page import="org.dom4j.io.SAXReader" %>
<%@page import="org.opencms.jsp.CmsJspActionElement" %>
<%@page import="org.opencms.file.CmsObject" %>
<%@page import="org.opencms.main.OpenCms" %>
<%@page import="org.opencms.mail.CmsSimpleMail" %>
<%@page import="java.net.URL" %>
<%@page import="java.util.Locale" %>
<%@page contentType="application/rss+xml" pageEncoding="UTF-8" %>
<%@page trimDirectiveWhitespaces="true" %>
<%!
/**
 * Sends an email, notifying responsibles about an error.
 */
private void sendErrorNotification(CmsObject cmso) throws EmailException {
    CmsSimpleMail sm = new CmsSimpleMail();
    sm.setFrom("no-reply@npolar.no", "NPI website");
    sm.addTo("web@npolar.no");
    sm.setSubject("Error on available positions proxy");
    sm.setMsg("An error was registered just now on the available positions proxy pscript " 
            + OpenCms.getLinkManager().getOnlineLink(cmso, cmso.getRequestContext().getUri()) + "."
            + " Please check the page and correct any errors. Do not reply to this e-mail, it was sent by OpenCms.");
    sm.send();
}
%><%
// AUTHOR'S NOTE:
// --------------
// I experienced that when the "cache" property was set to "timeout=10", the 
// content type defined here was used only in the 1st (uncached) response. 
// Successive (cached) responses had "text/html" when this script's file 
// extension was .jsp, and "text/xml" when it was .xml.
// 
// The only way to avoid the issue seems to be explicity bypassing OpenCms' flex 
// cache, by setting the "cache" property to "bypass".
// 
// More info: 
//  - http://lists.opencms.org/pipermail/opencms-dev/2009q2/032279.html
//  - http://documentation.opencms.org/opencms-documentation/caching-in-opencms/the-flex-cache/

final String CONTENT_TYPE_RSS = "application/rss+xml";
// Invoking CmsJspActionElement#setContentType(String) is not sufficient
CmsFlexController.getController(request).getTopResponse().setContentType(CONTENT_TYPE_RSS);
response.setContentType(CONTENT_TYPE_RSS);

CmsJspActionElement cms = new CmsJspActionElement(pageContext, request, response);
CmsObject cmso = cms.getCmsObject();

// See also the CmsFlexController call above.
// Initially sufficient, based on tests - but results became unpredictable after 
// having set the cache property in OpenCms.
cms.setContentType(CONTENT_TYPE_RSS);

Locale locale = cms.getRequestContext().getLocale();
String loc = locale.toString();

// Define the feed that we're gonna access
final String URI = "https://www.jobbnorge.no/apps/joblist/joblistbuilder.ashx?id=f80a5414-0e95-425a-82e1-a64fa9060bc5" 
                    + (loc.equalsIgnoreCase("no") ? "" : "&trid=2"); // trid=2 => English
final URL FEED_URL = new URL(URI);

// Access the feed
try {
    SAXReader reader = new SAXReader();
    Document feed = null;
    // First test availability
    try {
        feed = reader.read(FEED_URL);
        feed.selectNodes("//rss/channel");
    } catch (Exception e) {
        // Feed not available: Notify responsibles
        sendErrorNotification(cmso);
        return;
    }
    // Feed available: Mirror it
    out.println(feed.asXML());
} catch (Exception e) {
    // Freak error: Notify responsibles
    sendErrorNotification(cmso);
}
%>