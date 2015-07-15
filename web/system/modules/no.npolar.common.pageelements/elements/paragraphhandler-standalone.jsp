<%-- 
    Document   : paragraphhandler.jsp - Common paragraph template
    Dependency : no.npolar.common.gallery, no.npolar.util
    Created on : 03.jun.2010, 20:58:57
    Updated on : 20.sep.2011, 14:49:00
    Author     : Paul-Inge Flakstad <flakstad at npolar.no>
--%>
<%@ page import="no.npolar.util.*,
                 no.npolar.util.contentnotation.*,
                 java.util.*,
                 java.util.regex.*,
                 java.io.IOException,
                 org.opencms.jsp.I_CmsXmlContentContainer,
                 org.opencms.file.CmsObject,
                 org.opencms.file.CmsResource,
                 org.opencms.main.OpenCms,
                 org.opencms.main.CmsException,
                 org.opencms.loader.CmsImageScaler" session="true" %>
<%!
/**
* Wraps an image in a container, possibly also with image text and source.
*/
public String getImageContainer(CmsAgent cms, 
                                String imageTag,
                                int imageWidth, 
                                int imagePadding,
                                String imageText, 
                                String imageSource, 
                                String imageType, 
                                String imageSize, 
                                String mediaClass,
                                String imageFloat) {
    
    final String IMAGE_CONTAINER = "span";
    final String TEXT_CONTAINER = "span";
    // CSS class strings to append to the HTML, defined by the given image size
    final Map<String, String> sizeClasses = new HashMap<String, String>();
    sizeClasses.put("S", " thumb");
    sizeClasses.put("M", "");
    sizeClasses.put("L", " big");
    sizeClasses.put("XL", "");
    
    String imageFrameHTML =
            "<" + IMAGE_CONTAINER + " class=\"media" // The base class
             + (mediaClass == null ? "" : (" " + mediaClass))
             + ("left".equalsIgnoreCase(imageFloat) || "right".equalsIgnoreCase(imageFloat) ? " pull-".concat(imageFloat.toLowerCase()) : "") // Add " pull-left" / " pull-right" if necessary
             + sizeClasses.get(imageSize) // Add " thumb" / " big" if necessary
             + "\">"
             + imageTag;

    if (cms.elementExists(imageText) || cms.elementExists(imageSource)) {
        imageFrameHTML += 
                "<" + TEXT_CONTAINER + " class=\"caption highslide-caption\">" +
                    (cms.elementExists(imageText) ? cms.stripParagraph(imageText) : "") + 
                    (cms.elementExists(imageSource) ? ("<span class=\"credit\"> " + imageType + ": " + imageSource + "</span>") : "") +
                "</" + TEXT_CONTAINER + ">";
    }
    imageFrameHTML += "</" + IMAGE_CONTAINER + ">";
    return imageFrameHTML;
}

/**
* Wraps a video in a container, possibly also with caption and credit.
*/
public void printVideoContainer(CmsAgent cms, String videoUri,
                                int videoWidth, int videoPadding,
                                String caption, String credit, String videoFloatChoice, String mediaClass,
                                JspWriter outWriter) 
                throws CmsException, JspException, IOException {
    final String VIDEO_CONTAINER = "span";
    final String TEXT_CONTAINER = "span";
    String videoFrameHTML =
             "<span class=\"media" 
             + (mediaClass == null ? "" : (" " + mediaClass))
             + ("left".equalsIgnoreCase(videoFloatChoice) || "right".equalsIgnoreCase(videoFloatChoice) ? " pull-".concat(videoFloatChoice.toLowerCase()) : "")
             + "\">";
    // Print the first part
    outWriter.print(videoFrameHTML);
    // Then let the video handler print the video
    Map params = new HashMap();
    params.put("resourceUri", videoUri);
    params.put("width", videoWidth);
    // Allow overriding of caption and credit
    if (caption != null & !caption.isEmpty())
        params.put("caption", caption);
    if (credit != null & !credit.isEmpty())
        params.put("credit", credit);
    String videoTemplate = cms.getCmsObject().readPropertyObject(videoUri, "template-elements", false).getValue("Undefined template-elements");
    cms.include(videoTemplate, null, params);

    // Reset HTML
    videoFrameHTML = ""; 
    /*if (cms.elementExists(caption) || cms.elementExists(credit)) {
        videoFrameHTML += 
                "<" + TEXT_CONTAINER + " class=\"imagetext highslide-caption\">" +
                    (cms.elementExists(caption) ? cms.stripParagraph(caption) : "") + 
                    (cms.elementExists(credit) ? ("<span class=\"imagecredit\"> Video: " + credit + "</span>") : "") +
                "</" + TEXT_CONTAINER + ">";
    }*/
    videoFrameHTML += "</span>";
    outWriter.print(videoFrameHTML);
}

/**
* Gets an exception's stack trace as a string.
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
%>

<%
CmsAgent cms                        = new CmsAgent(pageContext, request, response);
CmsObject cmso                      = cms.getCmsObject();

ContentNotationResolver cnr = null;
try {
    cnr = (ContentNotationResolver)session.getAttribute(ContentNotationResolver.SESS_ATTR_NAME);
} catch (Exception e) {
    out.println("\n<!-- Content notation resolver should be initialized in master template. Initializing one now to prevent crash ... -->");
    cnr = new ContentNotationResolver();
    session.setAttribute(ContentNotationResolver.SESS_ATTR_NAME, cnr);
}

// CmsImageProcessor is just a CmsImageScaler class, with some additional helper methods
CmsImageProcessor imgPro            = new CmsImageProcessor();
// 4 = "Scale to exact target size". For other image scaler types, see http://www.opencms.org/javadoc/core/org/opencms/loader/CmsImageScaler.html#getType()
imgPro.setType(4); 
// The image saving quality, in percent
imgPro.setQuality(100);

String requestFileUri               = cms.getRequestContext().getUri();
String requestFolderUri             = cms.getRequestContext().getFolderUri();
Locale locale                       = cms.getRequestContext().getLocale();
String loc                          = locale.toString();

int galleryCounter                  = 0;

// IMPORTANT: Embedded gallery version requires the gallery module installed!!!
final String GALLERY_HANDLER        = "/system/modules/no.npolar.common.gallery/elements/gallery-standalone.jsp";

final boolean EDITABLE              = false;
// boolean EDITABLE_TEMPLATE     = false; // Don't want this here, it's in the template already (i.e. "ivorypage.jsp" or "newsbulletin.jsp")
final int IMAGE_PADDING             = 4;//0; // The padding for the image. Needed to generate the width attribute for image containers.

// Image widths - one for floated images, one for full-width images
// (Assume images are CSS-scaled, but use these dimensions to make the image files as small as possible)
final int IMAGE_WIDTH_FLOAT = 380;
final int IMAGE_WIDTH_FULL = 940;

// Image variables
String imagePath                    = null; // The image path
String imageTag                     = null; // The <img> tag
String imageSource                  = null; // The image's source or copyright proprietor
String imageCaption                 = null; // The image caption
String imageTitle                   = null; // The image title (the alt text)
int    imageRescaleWidth            = -1;   // The width (in pixels) to rescale image to
String imageFloatChoice             = null; // Left, right, none
String imageTypeChoice              = null; // Photo, graphics, etc.
String imageSizeChoice              = null; // S, M, L (M is default)

List<String> imagesBefore = new ArrayList<String>();
List<String> imagesFullWidthBefore = new ArrayList<String>();
List<String> imagesFullWidthAfter = new ArrayList<String>();

I_CmsXmlContentContainer container, 
                            paragraphs, 
                            textBoxContainer,
                            imageContainer,
                            videoContainer; // XML content containers
String title, text;                         // String variables for structured content elements

final String DEFAULT_ELEMENT_NAME_PARAGRAPH = "Paragraph";
final String DEFAULT_PARAGRAPH_HEADING_ATTRIBS = "";
String paragraphElementName = DEFAULT_ELEMENT_NAME_PARAGRAPH;
String paragraphHeadingAttribs = DEFAULT_PARAGRAPH_HEADING_ATTRIBS;
String paragraphMediaClass = "";
String[] paragraphWrapper = {"<section class=\"paragraph clearfix\">", "</section>"};
String[] paragraphTextWrapper = { "", "" };

if (request.getAttribute("paragraphContainer") != null) {
    container = (I_CmsXmlContentContainer)request.getAttribute("paragraphContainer");
    if (request.getAttribute("paragraphElementName") != null) 
        paragraphElementName = (String)request.getAttribute("paragraphElementName");
    if (request.getAttribute("paragraphHeadingAttribs") != null) 
        paragraphHeadingAttribs = (String)request.getAttribute("paragraphHeadingAttribs");
    if (request.getAttribute("paragraphWrapper") != null) 
        try { paragraphWrapper = (String[])request.getAttribute("paragraphWrapper"); } catch (Exception e) {}
    if (request.getAttribute("paragraphMediaClass") != null)
        paragraphMediaClass = (String)request.getAttribute("paragraphMediaClass");
    if (request.getAttribute("paragraphTextWrapper") != null) 
        paragraphTextWrapper = (String[])request.getAttribute("paragraphTextWrapper");
}
else {
    // Load the content
    throw new NullPointerException("No paragraph container set by request.setAttribute().");
}

    // We will only be processing the "Paragraph" element
    paragraphs = cms.contentloop(container, paragraphElementName);
    // Process content (paragraphs)
    while (paragraphs.hasMoreContent()) {
        // Clear the image lists
        imagesBefore.clear();
        imagesFullWidthAfter.clear();
        imagesFullWidthBefore.clear();
        
        // Could/should be replaced by a one-liner: out.println(paragraphWrapper[0]);
        if (paragraphWrapper[0].length() == 0) {
            %>
            <section class="paragraph clearfix">
            <%
        }
        else {
            out.println(paragraphWrapper[0]);
        }
        
        // Get the paragraph title and text
        title   = cms.contentshow(paragraphs, "Title").replaceAll(" & ", " &amp; ");
        text    = cms.contentshow(paragraphs, "Text");
        
        try { title = cnr.resolve(title); } catch (Exception e) { out.println("<!-- ERROR trying to resolve content notation -->"); }
        try { text = cnr.resolve(text); } catch (Exception e) { out.println("<!-- ERROR trying to resolve content notation -->"); }

        // Print the paragraph title
        if (CmsAgent.elementExists(title)) {
            out.println("<h2" + paragraphHeadingAttribs + ">" + title + "</h2>");
        }
        if (paragraphTextWrapper[0].length() > 0) {
            out.println(CmsAgent.obfuscateEmailAddr(text, true));
            out.println(paragraphTextWrapper[1]);
        }


        //
        // Images
        //
        try {
            imageContainer = cms.contentloop(paragraphs, "Image");
            while (imageContainer.hasMoreContent()) {
                imagePath       = cms.contentshow(imageContainer, "URI");
                imageCaption    = cms.contentshow(imageContainer, "Text");
                imageTitle      = cms.contentshow(imageContainer, "Title");
                imageSource     = cms.contentshow(imageContainer, "Source");
                imageTypeChoice = cms.labelUnicode("label.pageelements." + cms.contentshow(imageContainer, "ImageType").toLowerCase());
                imageSizeChoice = cms.contentshow(imageContainer, "Size");
                if (!CmsAgent.elementExists(imageSizeChoice))
                    imageSizeChoice = "M"; // Default
                imageFloatChoice= cms.contentshow(imageContainer, "Float");
                imageRescaleWidth = "right".equalsIgnoreCase(imageFloatChoice) || "left".equalsIgnoreCase(imageFloatChoice) ? IMAGE_WIDTH_FLOAT : IMAGE_WIDTH_FULL;

                int imageHeight  = -1;
                int imageWidth   = imageRescaleWidth;//IMG_WIDTH_M;
                
                String imageSrc = "";

                // Check to make sure that the image exists
                //if (cmso.existsResource(imagePath)) {
                if (cmso.existsResource(imagePath.substring(0, imagePath.indexOf("?") == -1 ? imagePath.length() : imagePath.indexOf("?")))) {
                    int[] imageDimensions = cms.getImageSize(cmso.readResource(imagePath));
                    // DOWNSCALE only!
                    if (imageDimensions[0] > imageRescaleWidth) {
                        // Downscale needed
                        imageHeight = CmsAgent.calculateNewImageHeight(imageRescaleWidth, imageDimensions[0], imageDimensions[1]);

                        imgPro.setWidth(imageRescaleWidth);
                        imgPro.setHeight(imageHeight);

                        // Get the "src" attribute from the downscaled image's <img> tag
                        imageSrc = (String)CmsAgent.getTagAttributesAsMap(cms.img(imagePath, imgPro.getReScaler(imgPro), null)).get("src");
                    }
                    else {
                        // No downscale needed
                        imageSrc = cms.link(imagePath);
                        imageWidth = imageDimensions[0];
                    }
                    // ALWAYS wrap the scaled image in a link to the original image (even if no downscale was applied)
                    imageTag = "<img src=\"" + imageSrc + "\" alt=\"" + (CmsAgent.elementExists(imageTitle) ? imageTitle : "") + "\" />";
                    imageTag = "<a href=\"" + cms.link(imagePath) + "\"" + 
                                        " title=\"" + cms.labelUnicode("label.pageelements.largerimage") + "\"" +
                                        " class=\"highslide\"" +
                                        " onclick=\"return hs.expand(this);\">" +
                                            imageTag +
                                        "</a>";
                }
                else {
                    imageTag = "<img src=\"\" alt=\"\" />";
                    throw new ServletException("The referred image '" + (imagePath == null ? "null" : imagePath) + "' does not exist.");
                }
                
                try { imageCaption = cnr.resolve(imageCaption); } catch (Exception e) { out.println("<!-- ERROR trying to resolve content notation for image caption -->"); }
                
                // Output the image container
                String imageHtml = getImageContainer(cms, imageTag, imageWidth, IMAGE_PADDING, imageCaption, imageSource, imageTypeChoice, imageSizeChoice, paragraphMediaClass, imageFloatChoice);
                if ("after".equalsIgnoreCase(imageFloatChoice))
                    imagesFullWidthAfter.add(imageHtml);
                else {
                    if ("none".equalsIgnoreCase(imageFloatChoice))
                        imagesFullWidthBefore.add(imageHtml);
                    else
                        imagesBefore.add(imageHtml);
                    
                }
            }
        }
        catch (NullPointerException npe1) {
            throw new ServletException("Null pointer encountered while reading image information.");
        }


        //
        // Videos
        //
        try {
            //out.println("\n<!-- Entering video section -->");
            String videoPath = null;
            String videoCaption = null;
            String videoCredit = null;
            String videoSizeChoice = null;
            String videoFloatChoice = null;
            
            videoContainer = cms.contentloop(paragraphs, "Video");
            /*
            if (!videoContainer.getCollectorResult().isEmpty())
                out.println("<!-- Videos in this paragraph: " + videoContainer.getCollectorResult().size() + " -->");
            else
                out.println("<!-- No videos in this paragraph -->");
            */
            while (videoContainer.hasMoreContent()) {
                videoPath       = cms.contentshow(videoContainer, "URI");
                videoCaption    = cms.contentshow(videoContainer, "Caption");
                videoCredit     = cms.contentshow(videoContainer, "Credit");
                videoSizeChoice = cms.contentshow(videoContainer, "Size");
                videoFloatChoice= cms.contentshow(videoContainer, "Float");
                
                int videoWidth = -1;
                
                // Check to make sure that the video exists
                if (!cmso.existsResource(videoPath)) {
                    throw new ServletException("A video was added to a paragraph, but the video does not exist. (Path was '" +
                            (videoPath == null ? "null" : videoPath) + "').");
                }
                
                try { videoCaption = cnr.resolve(videoCaption); } catch (Exception e) { out.println("<!-- ERROR trying to resolve content notation for video caption -->"); }
                
                // Output the video container
                printVideoContainer(cms, videoPath, -1, 0, videoCaption, videoCredit, videoFloatChoice, paragraphMediaClass, out);
                
            }
            
        }
        catch (NullPointerException npe1) {
            throw new ServletException("Null pointer encountered while printing video.");
        }
        
        
        
        
        
        
        //
        // Images before the paragraph text
        //
        Iterator<String> i = imagesFullWidthBefore.iterator();
        while (i.hasNext()) {
            out.println(i.next());
        }
        i = imagesBefore.iterator();
        while (i.hasNext()) {
            out.println(i.next());
        }
        
        
        //
        // Text box
        //
        try {
            String tbTitle, tbText;
            // Print out the text box
            textBoxContainer = cms.contentloop(paragraphs, "TextBox");
            while (textBoxContainer.hasMoreContent()) {
                tbTitle                 = cms.contentshow(textBoxContainer, "Title");
                tbText                  = cms.contentshow(textBoxContainer, "Text");
                
                try { tbTitle = cnr.resolve(tbTitle); } catch (Exception e) { out.println("<!-- ERROR trying to resolve content notation for text box title -->"); }
                try { tbText = cnr.resolve(tbText); } catch (Exception e) { out.println("<!-- ERROR trying to resolve content notation for text box content -->"); }
                
                out.println("<aside class=\"textbox pull-right\">");
                if (cms.elementExists(tbTitle)) {
                    out.println("<h5>" + tbTitle + "</h5>");
                }
                if (cms.elementExists(tbText)) {
                    out.println("<div class=\"textbox-content\">" + tbText + "</div>");
                }
                out.println("</aside><!-- .textbox -->");
            }
        }
        catch (NullPointerException npe1) {
            throw new ServletException("Null pointer encountered while creating text box.");
        }
        
        //
        // Paragraph text
        //
        if (cms.elementExists(text) && paragraphTextWrapper[0].length() == 0) {
            out.println(CmsAgent.obfuscateEmailAddr(text, true));
        }
        
        
        
        //
        // Images after the paragraph text
        //
        i = imagesFullWidthAfter.iterator();
        while (i.hasNext()) {
            out.println(i.next());
        }
        
        if (paragraphTextWrapper[0].length() == 0) {
            %>
            </section><!-- .paragraph -->
            <%
        } else {
            out.println(paragraphWrapper[1]);
        }
        
        //
        // Embedded gallery
        //
        try {
            I_CmsXmlContentContainer embeddedGalleries = cms.contentloop(paragraphs, "EmbeddedGallery");
            while (embeddedGalleries.hasMoreContent()) {
                String galleryUri = cms.contentshow(embeddedGalleries);
                if (CmsAgent.elementExists(galleryUri)) {
                    request.setAttribute("resourceUri", galleryUri); // Set the path to the gallery
                    request.setAttribute("galleryIndex", Integer.valueOf(++galleryCounter)); // Set the gallery counter (one page may contain multiple galleries)
                    request.setAttribute("thumbnailSize", Integer.valueOf(100)); // Set thumbnail size (override the value in the gallery file)
                    request.setAttribute("headingType", "h3"); // Set the heading type
                    cms.include(GALLERY_HANDLER);
                }
            }
        }
        catch (NullPointerException npe2) {
            throw new ServletException("NullPointer encountered while reading path to embedded gallery.");
        }
        
        //
        // Extension
        //
        try {
            String extFile = cms.contentshow(paragraphs, "Extension");
            // Extension
            if (CmsAgent.elementExists(extFile)) {
                //out.println("<!-- Paragraph extension: '" + extFile + "' -->");
                cms.includeAny(extFile, "resourceUri");
            }           
        } catch (Exception e3) {
            out.println("<!-- Oh noes! The paragraph extension crashed it..! Message was: " + e3.getMessage() + " -->");
        }
    }
//out.println("<!-- PARAGRAPH_HANDLER: done with container. -->");

session.setAttribute(ContentNotationResolver.SESS_ATTR_NAME, cnr);
%>