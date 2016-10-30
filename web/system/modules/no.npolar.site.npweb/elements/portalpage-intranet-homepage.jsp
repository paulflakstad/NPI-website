<%-- 
    Document   : portalpage-intranet-homepage (based on "portalpage-2")
    Created on : Oct 29, 2016, 2:22:51 PM
    Author     : Paul-Inge Flakstad, Norwegian Polar Institute <flakstad at npolar.no>
--%><%@ page import="no.npolar.util.*,
                 no.npolar.util.contentnotation.*,
                 java.util.Locale,
                 java.util.Date,
                 java.util.Map,
                 java.util.HashMap,
                 java.util.Iterator,
                 java.text.SimpleDateFormat,
                 org.apache.commons.lang.StringEscapeUtils,
                 org.opencms.jsp.I_CmsXmlContentContainer,
                 org.opencms.file.CmsObject,
                 org.opencms.file.CmsResource,
                 org.opencms.file.types.*,
                 org.opencms.loader.CmsImageScaler,
                 org.opencms.util.CmsUUID,
                 org.opencms.util.CmsRequestUtil" session="true" %><%!
                 
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
//final String PARAGRAPH_HANDLER      = "../../no.npolar.common.pageelements/elements/paragraphhandler.jsp";
final String LINKLIST_HANDLER       = "../../no.npolar.common.pageelements/elements/linklisthandler.jsp";
//final String SHARE_LINKS            = "../../no.npolar.site.npweb/elements/share-addthis-" + loc + ".txt";
// Image size
final int IMAGE_SIZE_S              = 120;//217;
final int IMAGE_SIZE_M              = 320;
final int IMAGE_SIZE_L              = 500;
//final int IMAGE_PADDING             = 4;
// Direct edit switches
final boolean EDITABLE              = false;
final boolean EDITABLE_TEMPLATE     = false;
// Labels
//final String LABEL_BY               = cms.labelUnicode("label.np.by");
//final String LABEL_LAST_MODIFIED    = cms.labelUnicode("label.np.lastmodified");
//final String PAGE_DATE_FORMAT       = cms.labelUnicode("label.np.dateformat.normal");
//final String LABEL_SHARE            = cms.labelUnicode("label.np.share");
// Image handle / scaler
CmsImageScaler imageHandle          = null;
CmsImageScaler targetScaler         = new CmsImageScaler();
targetScaler.setWidth(IMAGE_SIZE_S);
targetScaler.setType(1);
targetScaler.setType(4); // Avoid white lines in bottom/right of image
targetScaler.setQuality(100);
int sectionColspan                  = -1;
// XML content containers
I_CmsXmlContentContainer container  = null;
//I_CmsXmlContentContainer paragraph  = null;
I_CmsXmlContentContainer carousel   = null;
I_CmsXmlContentContainer carouselItems   = null;
//I_CmsXmlContentContainer bigSection = null;
I_CmsXmlContentContainer section    = null;
I_CmsXmlContentContainer sectionContent    = null;
//I_CmsXmlContentContainer readMore   = null;
// String variables for structured content elements
String pageTitle                    = null;
String pageIntro                    = null;
// Template ("outer" or "master" template)
String template                     = cms.getTemplate();
String[] elements                   = null;
try {
    elements = cms.getTemplateIncludeElements();
} catch (Exception e) {
    elements = new String[] { "head", "foot" };
}

//
// Include upper part of main template
//
cms.include(template, elements[0], EDITABLE_TEMPLATE);


// IMPORTANT: Do this *after* calling the outer template!
ContentNotationResolver cnr = null;
try {
    cnr = (ContentNotationResolver)session.getAttribute(ContentNotationResolver.SESS_ATTR_NAME);
    //out.println("\n\n<!-- Content notation resolver resolver ready - " + cnr.getGlobalFilePaths().size() + " global files loaded. -->");
} catch (Exception e) {
    out.println("\n\n<!-- Content notation resolver needs to be initialized before it can be used. -->");
}


// Load the file
container = cms.contentload("singleFile", "%(opencms.uri)", EDITABLE);
// Set the content "direct editable" (or not)
cms.editable(EDITABLE);

String htmlCarousel = "";
String htmlCarouselNavi = "";

//
// Process file contents
//
while (container.hasMoreResources()) {
    
    pageTitle = cms.contentshow(container, "Title").replaceAll(" & ", " &amp; ");
    pageIntro = cms.contentshow(container, "Intro");
    
    out.println("<article class=\"main-content portal\">");
    
    //
    // We need a left/right divide, which is not supported by the "portalpage". 
    // However, the content is fairly permanent (because it's mostly dynamic),
    // so we hard-code the divide after N sections.
    //
    
    // Start the primary wrapper (i.e. left side)
    out.println("<div class=\"main-content__primary\">");
    
    if (CmsAgent.elementExists(pageTitle)) {
        out.println("<h1>" + pageTitle + "</h1>");
    }
    
    if (CmsAgent.elementExists(pageIntro)) {
        try { pageIntro = cnr.resolve(pageIntro); } catch (Exception e) {}
        out.println("<div class=\"ingress\">" + pageIntro + "</div>");
    }
    
    
    // Featured content (carousel)
    carousel = cms.contentloop(container, "Carousel");
    while (carousel.hasMoreResources()) {
        // Image sizes (aspect ratio is 16:9)
        final int CAROUSEL_IMAGE_WIDTH = 1200; //550;
        final int CAROUSEL_IMAGE_HEIGHT = 800; //323;
        htmlCarousel += "<ul id=\"slides\">";
        carouselItems = cms.contentloop(carousel, "CarouselItem");
        int ciCount = 0;
        while (carouselItems.hasMoreResources()) {
            
            String ciTitle = cms.contentshow(carouselItems, "Title").replaceAll(" & ", " &amp; ");
            String ciText = cms.contentshow(carouselItems, "Text");
            String ciImage = cms.contentshow(carouselItems, "Image");
            String ciLink = cms.contentshow(carouselItems, "Link");
            ciLink = CmsAgent.elementExists(ciLink) ? ciLink : "#".concat(String.valueOf(ciCount));
            //*
            // Scale image if necessary
            CmsImageScaler imageOri = new CmsImageScaler(cmso, cmso.readResource(ciImage));
            
            if (imageOri.getWidth() > CAROUSEL_IMAGE_WIDTH || imageOri.getHeight() > CAROUSEL_IMAGE_HEIGHT) {
                CmsImageScaler reScaler = new CmsImageScaler(CmsImageScaler.SCALE_PARAM_WIDTH + ":" + CAROUSEL_IMAGE_WIDTH + "," + 
                                            CmsImageScaler.SCALE_PARAM_HEIGHT + ":" + CAROUSEL_IMAGE_HEIGHT + "," +
                                            CmsImageScaler.SCALE_PARAM_TYPE + ":" + 2 + "," +
                                            CmsImageScaler.SCALE_PARAM_QUALITY + ":" + 100);
                String imageTag = cms.img(ciImage, reScaler, null);
                //out.println("<!-- cms.img() returned " + imageTag + " -->");
                String imageSrc = (String)CmsAgent.getTagAttributesAsMap(imageTag).get("src");
                ciImage = imageSrc;
            }
            //*/
            
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
    //*
    
    request.setAttribute("paragraphContainer", container);
    request.setAttribute("paragraphElementName", "BigSection");
    request.setAttribute("paragraphHeadingAttribs", " style=\"margin-top:0;\"");
    request.setAttribute("paragraphWrapper", new String[]{"<section class=\"paragraph clearfix\" id=\"portalpage-first\">", "</section><!-- .test -->"});
    cms.include(PARAGRAPH_HANDLER);
    //*/
    
    
    
    section = cms.contentloop(container, "Section");
    int sCount = 0;
    //boolean initialWrapperEnded = false;
    while (section.hasMoreResources()) {
        sCount++;
        
        // Left/right divide: Do it after N sections
        if (sCount == 5) {
            // End the primary wrapper, start the secondary (i.e. right side)
            out.println("</div>");
            out.println("<div class=\"main-content__secondary\">");
        }
        
        String sectionHeading = cms.contentshow(section, "Heading");
        sectionColspan = Integer.valueOf(cms.contentshow(section, "Columns")).intValue();
        boolean overlayHeadings = Boolean.valueOf(cms.contentshow(section, "OverlayHeadings")).booleanValue();
        boolean boxed = Boolean.valueOf(cms.contentshow(section, "Boxed")).booleanValue();
        boolean textAsHoverBox = Boolean.valueOf(cms.contentshow(section, "TextAsHoverBox")).booleanValue();
        String dynamicContentUri = cms.contentshow(section, "DynamicContent");
        boolean isDynamicContentSection = CmsAgent.elementExists(dynamicContentUri);
        String sectionMoreLink = cms.contentshow(section, "MoreLink");
        String sectionMoreLinkText = cms.contentshow(section, "MoreLinkText");
                
        // Start the right column
        out.println("<section class=\"clearfix " 
                + widthClasses[sectionColspan] + " layout-group"  
                + (overlayHeadings ? " overlay-headings" : "")
                + (boxed ? " boxed" : "") 
                + (isDynamicContentSection ? " dynamic" : "")
                + "\">");
        if (CmsAgent.elementExists(sectionHeading)) {
            out.println("<h2 class=\"section-heading bluebar-dark\">" + sectionHeading + "</h2>");
        }
        
        if (!isDynamicContentSection) { // Dynamic content must handle wrapping itself
            out.println("<div class=\"boxes clearfix\">");
        }
        
        // "Section content" contains one or multiple instances of "portal-boxes"
        sectionContent = cms.contentloop(section, "Content");
        int scCount = 0; // Section content iteration counter
        if (CmsAgent.elementExists(dynamicContentUri)) {
            // Set a session variable describing the container into which the dynamic content will be included
            cms.getRequest().getSession().setAttribute("dynamic_container", "portal_page_section");
            if (CmsAgent.elementExists(sectionHeading) && !sectionHeading.isEmpty()) // Request to suppress the list's own heading
                cms.getRequest().getSession().setAttribute("override_heading", "none");
            if (dynamicContentUri.contains("?")) {
                try {
                    String scDynamicPath = dynamicContentUri.split("\\?")[0];
                    String scDynamicQuery = dynamicContentUri.split("\\?")[1];
                    cms.include(scDynamicPath, null, CmsRequestUtil.createParameterMap(scDynamicQuery));
                } catch (Exception e) {
                    out.println("<!-- Error including dynamic content: " + e.getMessage() + " -->");
                }
            } else {
                cms.includeAny(dynamicContentUri, "resourceUri");
            }
            // Clear session variables
            cms.getRequest().getSession().removeAttribute("dynamic_container");
            cms.getRequest().getSession().removeAttribute("override_heading");
        } else {
            while (sectionContent.hasMoreResources()) {
                scCount++;
                String htmlSectionImage = "";
                String htmlSection = "";

                String scDynamic = cms.contentshow(sectionContent, "DynamicContent");
                String scTitle = cms.contentshow(sectionContent, "Title").replaceAll(" & ", " &amp; ");
                String scText = cms.contentshow(sectionContent, "Text");
                String scMoreLink = cms.contentshow(sectionContent, "MoreLink");
                if (CmsAgent.elementExists(scMoreLink)) {
                    // Escape the URI, if necessary
                    if (scMoreLink.contains("?")) {
                        scMoreLink = StringEscapeUtils.escapeHtml(scMoreLink);
                    }
                }
                String scMoreLinkText = cms.contentshow(sectionContent, "MoreLinkText");
                String scCssClass = cms.contentshow(sectionContent, "CssClass");

                I_CmsXmlContentContainer scImage = cms.contentloop(sectionContent, "Image");
                while (scImage.hasMoreResources()) {
                    String scImageUri = cms.contentshow(scImage, "URI");
                    String scImageAlt = cms.contentshow(scImage, "Title");
                    
                    // Modify alt text
                    if (scImageAlt != null && (scImageAlt.equalsIgnoreCase("none") || scImageAlt.equals("-")))
                        scImageAlt = "";

                    String imageTagPrimaryAttribs = " src=\"" + cms.link(scImageUri) + "\"";
                    String imageTagSecondaryAttribs = " alt=\"" + scImageAlt + "\"";
                    // Scale image, if needed
                    imageHandle = new CmsImageScaler(cmso, cmso.readResource(scImageUri));
                    int imageMaxWidth = sectionColspan == 4 ? IMAGE_SIZE_M : IMAGE_SIZE_L;
                    if (imageHandle.getWidth() > imageMaxWidth) { // Image larger than defined size, needs downscale
                        targetScaler.setWidth(imageMaxWidth);
                        //targetScaler.setHeight(new CmsImageProcessor().getNewHeight(imageMaxWidth, imageHandle.getWidth(), imageHandle.getHeight()));
                        CmsImageScaler downScaler = imageHandle.getReScaler(targetScaler);
                        imageTagPrimaryAttribs = cms.img(scImageUri, downScaler, null, true);
                    }
                    
                    htmlSectionImage = "<img " + imageTagPrimaryAttribs + imageTagSecondaryAttribs + " />";
                }
                // Switch on image existence instead of "overlay headings"
                out.print("<div class=\"span1 " + (htmlSectionImage.isEmpty() ? "portal" : "featured") + "-box" + (textAsHoverBox ? " hb-text" : "")); 
                
                if (CmsAgent.elementExists(scCssClass)) {
                    out.print(" " + scCssClass);
                }
                out.println("\">");

                String link = CmsAgent.elementExists(scMoreLink) ? "<a" 
                                                                    + (overlayHeadings ? " class=\"featured-link\"" : "") 
                                                                    + " href=\"" + cms.link(scMoreLink) + "\""
                                                                    + (CmsAgent.elementExists(scText) 
                                                                        && textAsHoverBox
                                                                            ? " data-hoverbox=\"" + org.apache.commons.lang.StringEscapeUtils.escapeHtml(scText) + "\"" 
                                                                            : "")
                                                                    + ">"
                                                               : "";
                
                if (boxed && !link.isEmpty()) {
                    out.println(link);
                }
                if (!htmlSectionImage.isEmpty()) {
                    out.println("<div class=\"card\">");
                }
                if (!boxed && !link.isEmpty()) {
                    out.println(link);
                }
                if (overlayHeadings) {
                    out.println("<div class=\"autonomous\">");
                }
                
                // <div class="fourcol-equal single left"> OR <div class="fourcol-equal single" id="rightside">
                
                if (CmsAgent.elementExists(scTitle)) {
                    
                    String scHeadingType = CmsAgent.elementExists(sectionHeading) ? "h3" : "h2";
                    
                    out.print("<" + scHeadingType + " class=\"portal-box-heading" + (overlayHeadings ? " overlay" : " bluebar-dark") + "\">");
                    out.println("<span>" + scTitle + "</span>");
                    out.println("</" + scHeadingType + ">");
                }
                if (!htmlSectionImage.isEmpty()) {
                    out.println(htmlSectionImage);
                }
                if (overlayHeadings) {
                    out.println("</div>");
                }

                if (!boxed && CmsAgent.elementExists(scMoreLink)) {
                    out.println("</a>");
                }

                out.println("<div class=\"box-text\">");

                if (CmsAgent.elementExists(scText) && !textAsHoverBox) {
                    out.println(scText);
                }

                if (CmsAgent.elementExists(scDynamic)) {
                    if (scDynamic.contains("?")) {
                        try {
                            String[] pathAndQuery = scDynamic.split("\\?");
                            cms.include(pathAndQuery[0], null, CmsRequestUtil.createParameterMap(pathAndQuery[1]));
                        } catch (Exception e) {
                            out.println("<!-- Error including dynamic content: " + e.getMessage() + " -->");
                        }
                    } else {
                        cms.includeAny(scDynamic, "resourceUri");
                    }
                }

                if (!boxed && !textAsHoverBox && CmsAgent.elementExists(scMoreLink)) {
                    out.println("<p><a class=\"cta more\" href=\"" + cms.link(scMoreLink) + "\">" 
                            + (CmsAgent.elementExists(scMoreLinkText) ? scMoreLinkText : "Read more") 
                            + "</a></p>");
                }

                out.println("</div><!-- .box-text -->");

                if (!htmlSectionImage.isEmpty()) {
                    out.println("</div><!-- .card -->");
                }

                if (boxed && CmsAgent.elementExists(scMoreLink)) {
                    out.println("</a>");
                }

                out.println("</div><!-- .portal-box / .featured-box -->");
            }
        }
        // "More" link?
        if (CmsAgent.elementExists(sectionMoreLink) && !sectionMoreLink.isEmpty()) {
            out.println("<a class=\"cta more\" href=\"" + cms.link(sectionMoreLink) + "\">" 
                        + (CmsAgent.elementExists(sectionMoreLinkText) ? sectionMoreLinkText : "Read more") 
                    + "</a>");
        }
        
        if (!isDynamicContentSection) {
            // End the "boxes" wrapper
            out.println("</div>");
        }
        
        // End the section wrapper
        out.println("</section><!-- .layout-group -->");
    }
    
    // End the secondary wrapper (i.e. right side)
    out.println("</div>");
    
    // End the section wrapper
    out.println("</article><!-- .main-content.portal -->");

} // While container.hasMoreContent()


//
// Include lower part of main template
//
cms.include(template, elements[1], EDITABLE_TEMPLATE);
%>