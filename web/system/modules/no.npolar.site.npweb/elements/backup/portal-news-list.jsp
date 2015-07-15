<%-- 
    Document   : portal-yr-content
    Created on : 15.mar.2011, 11:29:02
    Author     : Paul-Inge Flakstad <flakstad at npolar.no>
--%><%@page import="org.opencms.jsp.*,
                org.opencms.file.*,
                org.opencms.file.types.*,
                org.opencms.loader.CmsImageScaler,
                org.opencms.main.*,
                java.util.*,
                java.io.*,
                java.text.NumberFormat,
                javax.xml.xpath.*,
                java.net.*,
                org.xml.sax.*,
                no.npolar.util.*" 
        contentType="text/html" 
        pageEncoding="UTF-8" 
%><%
CmsAgent cms                = new CmsAgent(pageContext, request, response);
CmsObject cmso              = cms.getCmsObject();
Locale locale               = cms.getRequestContext().getLocale();
String loc                  = locale.toString();
String requestFileUri       = cms.getRequestContext().getUri();
String requestFolderUri     = cms.getRequestContext().getFolderUri();

final int TYPE_ID_NEWSITEM  = OpenCms.getResourceManager().getResourceType("newsbulletin").getTypeId(); // The ID for resource type "newsbulletin" (316)
final int MAX_NEWSITEMS     = 3; // The number of news items to list
final String COLLECTOR      = "allInSubTreePriorityDateDesc";
final String LABEL_MORE_NEWS= loc.equals("no") ? "Flere nyheter" : "More news";

// Image size
final int IMAGE_SIZE_S              = 217;
final int IMAGE_PADDING             = 4;
// Image handle / scaler
CmsImageScaler imageHandle          = null;
CmsImageScaler targetScaler         = new CmsImageScaler();
targetScaler.setWidth(IMAGE_SIZE_S);
targetScaler.setType(1);
targetScaler.setQuality(100);

String listFolder           = loc.equals("no") ? "/no/om-oss/nyheter/" : "/en/about-us/news/";
String heading              = "<h3>" + (loc.equals("no") ? "Nyheter" : "News") + "</h3>";

I_CmsXmlContentContainer newsitems = cms.contentload(COLLECTOR, listFolder.concat("|"+TYPE_ID_NEWSITEM).concat("|"+MAX_NEWSITEMS), false);

String imageUri = null;

while (newsitems.hasMoreContent()) {
    String title = cms.contentshow(newsitems, "Title");
    String newsItemUri = cms.contentshow(newsitems, "%(opencms.filename)");
            
    if (imageUri == null) { // Will be null only on the first iteration
        // Get the most recent news item's image
        imageUri = cms.contentshow(newsitems, "TeaserImage");
        
        String imageTagPrimaryAttribs = " src=\"" + cms.link(imageUri) + "\" width=\"" + IMAGE_SIZE_S + "\"";
        String imageTagSecondaryAttribs = " class=\"illustration-image\" alt=\"" + title + "\"";
        // Scale image, if needed
        imageHandle = new CmsImageScaler(cmso, cmso.readResource(imageUri));
        if (imageHandle.getWidth() > IMAGE_SIZE_S) { // Image larger than defined size, needs downscale
            CmsImageScaler downScaler = imageHandle.getReScaler(targetScaler);
            //downScaler.setHeight(CmsAgent.calculateNewImageHeight(IMAGE_SIZE_S, imageHandle.getWidth(), imageHandle.getHeight()));
            //downScaler.setWidth(IMAGE_SIZE_S);
            imageTagPrimaryAttribs = cms.img(imageUri, downScaler, null, true);
        }
        out.println("<span class=\"illustration\" style=\"width:" + (IMAGE_SIZE_S + (2*IMAGE_PADDING)) + "px;\">");
        //out.println("<img class=\"illustration-image\" src=\"" + cms.link(imageUri) + "\" alt=\"" + title + "\" width=\"217\" />");
        out.println("<a href=\"" + cms.link(newsItemUri) + "\" title=\"" + title + "\">");
        out.println("<img " + imageTagPrimaryAttribs + imageTagSecondaryAttribs + " />");
        out.println("</a>");
        out.println("</span>");
        out.println(heading);
        out.println("<ul>");
    }
    out.println("<li><a href=\"" + cms.link(newsItemUri) + "\">" + title + "</a></li>");
}
if (imageUri != null) {
    out.println("<li><a href=\"" + cms.link(listFolder) + "\"><span style=\"font-style:italic;\">" + LABEL_MORE_NEWS + " &raquo;</span></a></li>");
    out.println("</ul>");
}
else
    out.println(heading + "<p><em>No news</em></p>");
%>