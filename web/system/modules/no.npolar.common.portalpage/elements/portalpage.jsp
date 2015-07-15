<%-- 
    Document   : portalpage
    Created on : Nov 16, 2012, 5:58:36 PM
    Author     : flakstad
--%><%-- 
    Document   : portalpage-redesigned
    Created on : Mar 21, 2012, 4:33:31 PM
    Author     : flakstad
--%><%@page import="no.npolar.util.CmsImageProcessor"%>
<%@ page import="no.npolar.util.CmsAgent,
                 java.util.Locale,
                 java.util.Date,
                 java.util.Map,
                 java.util.HashMap,
                 java.util.Iterator,
                 java.text.SimpleDateFormat,
                 org.opencms.jsp.I_CmsXmlContentContainer,
                 org.opencms.file.CmsObject,
                 org.opencms.file.CmsResource,
                 org.opencms.file.types.*,
                 org.opencms.loader.CmsImageScaler,
                 org.opencms.util.CmsUUID" session="true" %><%!
                 
/**
* Gets an exception's stack strace as a string.
*/
public String getStackTrace(Exception e) {
    String trace = "";
    StackTraceElement[] ste = e.getStackTrace();
    for (int i = 0; i < ste.length; i++) {
        StackTraceElement stElem = ste[i];
        trace += stElem.toString() + "<br />";
    }
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
HttpSession sess                    = cms.getRequest().getSession(true);

HashMap<String, String> widthMap = new HashMap<String, String>();
String[] widthClasses = { "", "single", "double", "triple", "quadruple" };
// Common page element handlers
final String PARAGRAPH_HANDLER      = "../../no.npolar.common.pageelements/elements/paragraphhandler-standalone.jsp";
final String LINKLIST_HANDLER       = "../../no.npolar.common.pageelements/elements/linklisthandler.jsp";
final String SHARE_LINKS            = "../../no.npolar.site.npweb/elements/share-addthis-" + loc + ".txt";
// Image size
final int IMAGE_SIZE_S              = 120;//217;
final int IMAGE_PADDING             = 4;
// Direct edit switches
final boolean EDITABLE              = false;
final boolean EDITABLE_TEMPLATE     = false;
// Labels
final String LABEL_BY               = cms.labelUnicode("label.np.by");
final String LABEL_LAST_MODIFIED    = cms.labelUnicode("label.np.lastmodified");
final String PAGE_DATE_FORMAT       = cms.labelUnicode("label.np.dateformat.normal");
final String LABEL_SHARE            = cms.labelUnicode("label.np.share");
// Image handle / scaler
CmsImageScaler imageHandle          = null;
CmsImageScaler targetScaler         = new CmsImageScaler();
targetScaler.setWidth(IMAGE_SIZE_S);
targetScaler.setType(1);
targetScaler.setQuality(100);
// File information variables
int portalWidth                     = 3;
// XML content containers
I_CmsXmlContentContainer container  = null;
I_CmsXmlContentContainer paragraph  = null;
I_CmsXmlContentContainer carousel   = null;
I_CmsXmlContentContainer carouselItems   = null;
I_CmsXmlContentContainer bigSection = null;
I_CmsXmlContentContainer section    = null;
I_CmsXmlContentContainer sectionContent    = null;
I_CmsXmlContentContainer readMore   = null;
// String variables for structured content elements
String pageTitle                    = null;
String pageIntro                    = null;
String shareLinksString             = null;
boolean shareLinks                  = false;
// Template ("outer" or "master" template)
String template                     = cms.getTemplate();
String[] elements                   = cms.getTemplateIncludeElements();

//
// Include upper part of main template
//
cms.include(template, elements[0], EDITABLE_TEMPLATE);



// Load the file
container = cms.contentload("singleFile", "%(opencms.uri)", EDITABLE);
// Set the content "direct editable" (or not)
cms.editable(EDITABLE);

String htmlCarousel = "";
String htmlCarouselNavi = "";

//
// Process file contents
//
while (container.hasMoreContent()) {
    //out.println("<div class=\"page\">"); // REMOVED <div class="page">
    
    portalWidth = 2;// Integer.valueOf(cms.contentshow(container, "Columns")).intValue();
    //String htmlPortalWrapperClass = "fourcol-equal " + (portalWidth == 3 ? "triple right" : "quadruple");
    //out.println("<div class=\"" + htmlPortalWrapperClass + "\">"); // e.g. <div class="fourcol-equal quadruple">
    
    
    
    pageTitle = cms.contentshow(container, "Title").replaceAll(" & ", " &amp; ");
    pageIntro = cms.contentshow(container, "Intro");
    shareLinksString= cms.contentshow(container, "ShareLinks");
    if (!CmsAgent.elementExists(shareLinksString))
        shareLinksString = "true"; // Default value if this element does not exist in the file (backward compatibility)

    try {
        shareLinks      = Boolean.valueOf(shareLinksString).booleanValue();
    } catch (Exception e) {
        shareLinks = true; // Default value if above line fails (it shouldn't, but just to be safe...)
    }
    
    
    // Start the left column
    //out.println("<div class=\"fourcol-equal double left\">");
    out.println("<div class=\"portal left\">");
    
    // Title and page intro
    if (CmsAgent.elementExists(pageTitle))
    out.println("<h1>" + pageTitle + "</h1>");
    if (CmsAgent.elementExists(pageIntro))
        out.println("<div class=\"ingress\">" + pageIntro + "</div>");
    
    
    // Featured content (carousel)
    carousel = cms.contentloop(container, "Carousel");
    while (carousel.hasMoreContent()) {
        htmlCarousel += "<ul id=\"slides\">";
        carouselItems = cms.contentloop(carousel, "CarouselItem");
        int ciCount = 0;
        while (carouselItems.hasMoreContent()) {
            //ciCount++;
            String ciTitle = cms.contentshow(carouselItems, "Title").replaceAll(" & ", " &amp; ");
            String ciText = cms.contentshow(carouselItems, "Text");
            String ciImage = cms.contentshow(carouselItems, "Image");
            String ciLink = cms.contentshow(carouselItems, "Link");
            ciLink = CmsAgent.elementExists(ciLink) ? ciLink : "#".concat(String.valueOf(ciCount));
            
            // Scale image if necessary
            CmsImageScaler imageOri = new CmsImageScaler(cmso, cmso.readResource(ciImage));
            if (imageOri.getWidth() > 550 || imageOri.getHeight() > 323) {
                CmsImageScaler reScaler = new CmsImageScaler(CmsImageScaler.SCALE_PARAM_WIDTH + ":" + 550 + "," + 
                                            CmsImageScaler.SCALE_PARAM_HEIGHT + ":" + 323 + "," +
                                            CmsImageScaler.SCALE_PARAM_TYPE + ":" + 2 + "," +
                                            CmsImageScaler.SCALE_PARAM_QUALITY + ":" + 100);
                String imageTag = cms.img(ciImage, reScaler, null);
                //out.println("<!-- cms.img() returned " + imageTag + " -->");
                String imageSrc = (String)CmsAgent.getTagAttributesAsMap(imageTag).get("src");
                ciImage = imageSrc;
            }
            
            
            //htmlCarouselNavi += "\n<em" + (ciCount == 0 ? " class=\"swipe-current-pos\"" : "") + " title=\"" + ciTitle + "\" onclick=\"slider.slide("+ciCount+",300);return false;\">&bull;</em>";
            htmlCarousel += "\n<li class=\"slide\">" +
                                "\n<div class=\"content\">" +
                                    "\n<a href=\"" + ciLink + "\"><img alt=\"" + ciTitle + "\" src=\"" + cms.link(ciImage) + "\" /></a>" +
                                    "\n<div class=\"featured-text overlay\" onclick=\"javascript:window.location = '" + ciLink + "'\">" + 
                                    "\n<h4>" + ciTitle + "</h4>" +
                                        "\n" + ciText + 
                                    "\n</div>" +
                                "\n</div>" +
                            "\n</li>";
            ciCount++;
        }
        
        htmlCarouselNavi += "<nav>"
                                + "<a href=\"#\" id=\"featured-prev\" class=\"prev\"></a>"
                                + "<div class=\"pagination\"></div>"
                                + "<a href=\"#\" id=\"featured-next\" class=\"next\"></a>"
                            + "</nav>";
        htmlCarousel += "\n</ul>";
        
        out.println("<div id=\"featured\" class=\"portal-box\">");
        out.println(htmlCarousel);
        out.println(htmlCarouselNavi);
        out.println("</div><!-- #featured.portal-box -->");
    }
    
    
    
    //while (readMore.hasMoreContent()) {
        request.setAttribute("paragraphContainer", container);
        request.setAttribute("paragraphElementName", "ReadMore");
        request.setAttribute("paragraphWrapper", new String[]{"<div class=\"paragraph portal-box\">", "</div><!-- .paragraph.portal-box -->"});
        //if (portalWidth == 4) { // Print it here only if the portal width is "fullwidth" - if not, we'll print it later
            //out.println("<div class=\"portal-box\">");
            cms.include(PARAGRAPH_HANDLER);
            //out.println("</div>");
        //}
    //}
    
    
    // Print the left side "paragraph" sections
    request.setAttribute("paragraphContainer", container);
    request.setAttribute("paragraphElementName", "BigSection");
    request.setAttribute("paragraphHeadingAttribs", " class=\"big-heading\"");
    request.setAttribute("paragraphWrapper", new String[]{"", ""});
    
    out.println("<div class=\"portal-box\">");
    cms.include(PARAGRAPH_HANDLER);
    out.println("</div><!-- .portal-box -->");
    
    
    // End the left column
    out.println("</div><!-- .column.portal.left -->");
    
    
    
    
    
    // ###########################################################################
    // ###########################                     ###########################
    // ########################### LEFT / RIGHT DIVIDE ###########################
    // ###########################                     ###########################
    // ###########################################################################
    
    
    
    
    
    // Start the right column
    out.println("<div class=\"portal right\">");
    
    section = cms.contentloop(container, "Section");
    int sCount = 0;
    boolean initialWrapperEnded = false;
    while (section.hasMoreContent()) {
        sCount++;        
        
        // "Section content" contains one or multiple instances of "portal-boxes"
        sectionContent = cms.contentloop(section, "Content");
        int scCount = 0;
        
        while (sectionContent.hasMoreContent()) {
            String htmlSectionImage = "";
            String htmlSection = "";
            
            String scDynamic = cms.contentshow(sectionContent, "DynamicContent");
            String scTitle = cms.contentshow(sectionContent, "Title").replaceAll(" & ", " &amp; ");
            String scText = cms.contentshow(sectionContent, "Text");
            String scMoreLink = cms.contentshow(sectionContent, "MoreLink");
            String scMoreLinkText = cms.contentshow(sectionContent, "MoreLinkText");
            I_CmsXmlContentContainer scImage = cms.contentloop(sectionContent, "Image");
            while (scImage.hasMoreContent()) {
                String scImageUri = cms.contentshow(scImage, "URI");
                String scImageAlt = cms.contentshow(scImage, "Title");
                String scImageText = cms.contentshow(scImage, "Text").replaceAll(" & ", " &amp; ");
                String scImageSource = cms.contentshow(scImage, "Source");
                String scImageSize = cms.contentshow(scImage, "Size");
                String scImageFloat = cms.contentshow(scImage, "Float");
                String scImageType = cms.labelUnicode("label.np." + cms.contentshow(scImage, "ImageType").toLowerCase());
                
                String imageTagPrimaryAttribs = " src=\"" + cms.link(scImageUri) + "\" width=\"" + IMAGE_SIZE_S + "\"";
                String imageTagSecondaryAttribs = " class=\"illustration-image\" alt=\"" + scImageAlt + "\"";
                // Scale image, if needed
                imageHandle = new CmsImageScaler(cmso, cmso.readResource(scImageUri));
                if (imageHandle.getWidth() > IMAGE_SIZE_S) { // Image larger than defined size, needs downscale
                    CmsImageScaler downScaler = imageHandle.getReScaler(targetScaler);
                    imageTagPrimaryAttribs = cms.img(scImageUri, downScaler, null, true);
                    
                }
                htmlSectionImage += "\n<span class=\"media pull-right thumb\">" +
                                        //"\n<img width=\"217\" alt=\"" + scImageAlt + "\" src=\"" + cms.link(scImageUri) + "\" class=\"illustration-image\" />";
                                        "\n<img src=\"" + CmsAgent.getTagAttributesAsMap("<img " + imageTagPrimaryAttribs + " />").get("src") + "\"" + imageTagSecondaryAttribs + " />";
                if (CmsAgent.elementExists(scImageText) || CmsAgent.elementExists(scImageSource)) {
                    htmlSectionImage += "\n<span class=\"caption\">";
                    if (CmsAgent.elementExists(scImageText))
                        htmlSectionImage += CmsAgent.stripParagraph(scImageText);
                    if (CmsAgent.elementExists(scImageSource))
                        htmlSectionImage += "<span class=\"credit\"> " + scImageType + ": " + scImageSource + "</span>";
                    htmlSectionImage += "</span>";
                }
                htmlSectionImage += "\n</span>";
            }
            
            
            out.println("<div class=\"portal-box\">");
            // <div class="fourcol-equal single left"> OR <div class="fourcol-equal single" id="rightside">
            if (CmsAgent.elementExists(scTitle)) {
                /*
                out.print("<h3 class=\"portal-box-heading bluebar-dark\">" + scTitle);
                if (CmsAgent.elementExists(scMoreLink))
                    out.println(" <span class=\"heading-more\"><a href=\"" + cms.link(scMoreLink) + "\">" + scMoreLinkText +"</a></span>");
                out.println("</h3>");
                */
                out.print("<h3 class=\"portal-box-heading bluebar-dark\"" + (CmsAgent.elementExists(scMoreLink) ? " style=\"padding:0;\"" : "") + ">" 
                        + (CmsAgent.elementExists(scMoreLink) ? "<a href=\"" + cms.link(scMoreLink) + "\">" : "")
                        + scTitle
                        + (CmsAgent.elementExists(scMoreLinkText) ? " <span class=\"heading-more\">" + scMoreLinkText + "</span>" : "")
                        + (CmsAgent.elementExists(scMoreLink) ? "</a>" : "")
                        + "</h3>"
                        );
            }
            if (!htmlSectionImage.isEmpty()) {
                out.println(htmlSectionImage);
            }
            if (CmsAgent.elementExists(scText))
                out.println(scText);
            if (CmsAgent.elementExists(scDynamic)) {
                cms.includeAny(scDynamic, "resourceUri");
            }
            
            out.println("</div><!-- .portal-box -->");
            scCount++;
        }
    }
    // End the section wrapper
    out.println("</div><!-- .column.portal.right -->");
    if (shareLinks) {
        out.println(cms.getContent(SHARE_LINKS));
        sess.setAttribute("share", "true");
    }

} // While container.hasMoreContent()


//
// Include lower part of main template
//
cms.include(template, elements[1], EDITABLE_TEMPLATE);
%>