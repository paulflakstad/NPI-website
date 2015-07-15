<%-- 
    Document   : paragraphhandler.jsp - Common paragraph template
    Dependency : no.npolar.common.gallery
    Created on : 03.jun.2010, 20:58:57
    Updated on : 20.sep.2011, 14:49:00
    Author     : Paul-Inge Flakstad <flakstad at npolar.no>
--%>
<%@ page import="no.npolar.util.*,
                 java.util.Arrays,
                 java.util.Locale,
                 java.util.List,
                 java.util.Map,
                 java.util.HashMap,
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
public String getImageContainer(CmsAgent cms, boolean useSpans, String imageTag,
                                int imageWidth, int imagePadding,
                                String imageText, String imageSource, 
                                String imageType, String imageFloat) {
    final String IMAGE_CONTAINER = useSpans ? "span" : "div";
    final String TEXT_CONTAINER = useSpans ? "span" : "p";
    String imageFrameHTML =
            "<" + IMAGE_CONTAINER + " class=\"illustration" + (useSpans ? " ".concat(imageFloat.toLowerCase()) : " poster") + "\" " +
            "style=\"width:" + (imageWidth + (imagePadding*2)) + "px;\">" +
                imageTag;

    if (cms.elementExists(imageText) || cms.elementExists(imageSource)) {
        imageFrameHTML += 
                "<" + TEXT_CONTAINER + " class=\"imagetext highslide-caption\">" +
                    (cms.elementExists(imageText) ? cms.stripParagraph(imageText) : "") + 
                    (cms.elementExists(imageSource) ? ("<span class=\"imagecredit\"> " + imageType + ": " + imageSource + "</span>") : "") +
                "</" + TEXT_CONTAINER + "><!-- END imagetext -->";
    }
    imageFrameHTML += "</" + IMAGE_CONTAINER + ">";
    return imageFrameHTML;
}

/**
* Wraps a video in a container, possibly also with caption and credit.
*/
public void printVideoContainer(CmsAgent cms, String videoUri,
                                int videoWidth, int videoPadding,
                                String caption, String credit, String floatMode, 
                                JspWriter outWriter) 
                throws CmsException, JspException, IOException {
    boolean useSpans = floatMode.equalsIgnoreCase("None") ? false : true;
    final String VIDEO_CONTAINER = useSpans ?  "span" : "div";
    final String TEXT_CONTAINER = useSpans ? "span" : "p";
    String videoFrameHTML =
             "<" + VIDEO_CONTAINER + " class=\"illustration" + (useSpans ? " ".concat(floatMode.toLowerCase()) : " poster") + "\" " +
            "style=\"width:" + (videoWidth + (videoPadding*2)) + "px;\">";
    // Print the first part
    outWriter.print(videoFrameHTML);
    // Then let the video handler print the video
    Map params = new HashMap();
    params.put("resourceUri", videoUri);
    params.put("width", videoWidth);
    String videoTemplate = cms.getCmsObject().readPropertyObject(videoUri, "template-elements", false).getValue("Undefined template-elements");
    cms.include(videoTemplate, null, params);

    // Reset HTML
    videoFrameHTML = ""; 
    if (cms.elementExists(caption) || cms.elementExists(credit)) {
        videoFrameHTML += 
                "<" + TEXT_CONTAINER + " class=\"imagetext highslide-caption\">" +
                    (cms.elementExists(caption) ? cms.stripParagraph(caption) : "") + 
                    (cms.elementExists(credit) ? ("<span class=\"imagecredit\"> Video: " + credit + "</span>") : "") +
                "</" + TEXT_CONTAINER + "><!-- END caption -->";
    }
    videoFrameHTML += "</" + VIDEO_CONTAINER + ">";
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

// The global width settings, read from properties
final int IMG_WIDTH_S   = Integer.parseInt(cms.getCmsObject().readPropertyObject(requestFileUri, "image.size.s", true).getValue("140"));
final int IMG_WIDTH_M   = Integer.parseInt(cms.getCmsObject().readPropertyObject(requestFileUri, "image.size.m", true).getValue("200"));
final int IMG_WIDTH_L   = Integer.parseInt(cms.getCmsObject().readPropertyObject(requestFileUri, "image.size.l", true).getValue("300"));
final int IMG_WIDTH_XL  = Integer.parseInt(cms.getCmsObject().readPropertyObject(requestFileUri, "image.size.xl", true).getValue("675"));

// Valid image float values
/*final String IMAGE_FLOAT_LEFT       = "Left";
final String IMAGE_FLOAT_RIGHT      = "Right";
final String IMAGE_FLOAT_NONE       = "None";*/

// Valid image size values
final List<String> IMAGE_SIZES      = Arrays.asList("S", "M", "L", "XL");
final List<Integer> IMAGE_PX_SIZES  = Arrays.asList(IMG_WIDTH_S, IMG_WIDTH_M, IMG_WIDTH_L, IMG_WIDTH_XL);

// Valid image type labels
/*final String IMAGE_LABEL_PHOTO      = cms.labelUnicode("label.np.photo");
final String IMAGE_LABEL_GRAPHICS   = cms.labelUnicode("label.np.graphics");
final String IMAGE_LABEL_FIGURE     = cms.labelUnicode("label.np.figure");
final String IMAGE_LABEL_MAP        = cms.labelUnicode("label.np.map");
final String IMAGE_LABEL_ILLUSTR    = cms.labelUnicode("label.np.illustration");*/

// Image variables
String imagePath                    = null; // The image path
String imageTag                     = null; // The <img> tag
String imageSource                  = null; // The image's source or copyright proprietor
String imageCaption                 = null; // The image caption
String imageTitle                   = null; // The image title (the alt text)
int    imageSizeChoice              = -1;   // XS, S, M, L, XL - but in pixel values
String imageFloatChoice             = null; // Left, right, none
String imageTypeChoice              = null; // Photo, graphics, etc.
String scaledImageTag               = null; // The <img> tag for the scaled version

I_CmsXmlContentContainer container, 
                            paragraphs, 
                            textBoxContainer,
                            flashContainer,
                            imageContainer,
                            videoContainer; // XML content containers
String title, text;                         // String variables for structured content elements

final String DEFAULT_ELEMENT_NAME_PARAGRAPH = "Paragraph";
String paragraphElementName = DEFAULT_ELEMENT_NAME_PARAGRAPH;

if (request.getAttribute("paragraphContainer") != null) {
    container = (I_CmsXmlContentContainer)request.getAttribute("paragraphContainer");
    if (request.getAttribute("paragraphElementName") != null) 
        paragraphElementName = (String)request.getAttribute("paragraphElementName");
}
else {
    // Load the content
    container = cms.contentload("singleFile", "%(opencms.uri)", EDITABLE);
}

//out.println("<!-- PARAGRAPH_HANDLER: paragraphElementName was '" + paragraphElementName + "', paragraphContainer was '" + container + "' -->");
//out.println("<!-- PARAGRAPH_HANDLER: entering container... -->");
// Process the content
while (container.hasMoreContent()) {
    //out.println("<!-- PARAGRAPH_HANDLER: inside container... -->");
    // We will only be processing the "Paragraph" element
    paragraphs = cms.contentloop(container, paragraphElementName);
    // Process content (paragraphs)
    while (paragraphs.hasMoreContent()) {
        out.println("<div class=\"paragraph\">");
        // Get the paragraph title and text
        title   = cms.contentshow(paragraphs, "Title").replaceAll(" & ", " &amp; ");
        text    = cms.contentshow(paragraphs, "Text");

        // Print the paragraph title
        if (CmsAgent.elementExists(title)) {
            out.println("<h2>" + title + "</h2>");
        }


        /*
        //
        // Large image
        //
        try {
            imageContainer = cms.contentloop(paragraphs, "PosterImage");
            while (imageContainer.hasMoreContent()) {
                imagePath    = cms.contentshow(imageContainer, "URI");
                imageCaption = cms.contentshow(imageContainer, "Text");
                imageSource  = cms.contentshow(imageContainer, "Source");
                imageTitle   = cms.contentshow(imageContainer, "Title");

                if (cms.elementExists(imagePath)) {
                    int originalWidth = cms.getImageSize(cmso.readResource(imagePath))[0];
                    int imageWidth = originalWidth > IMG_WIDTH_XL ? IMG_WIDTH_XL : originalWidth;
                    imageTag = "<img src=\"" + imagePath + "\" alt=\"" + imageTitle + "\" width=\"" + imageWidth + "\" />";
                    if (imageWidth < originalWidth) {
                        imageTag = "<a href=\"" + imagePath + "\" class=\"highslide\" onclick=\"return hs.expand(this);\">" +
                                imageTag + "</a>";
                    }
                    //out.println(getNonFloatImageContainer(cms, imageTag, imageWidth, imageCaption, imageSource));
                    out.println(getImageContainer(cms, false, imageTag, imageWidth, IMAGE_PADDING, imageCaption, imageSource));
                }
            }
        }
        catch (NullPointerException npe1) {
            throw new ServletException("Null pointer encountered while reading image information.");
        }
        */

        //
        // Flash content
        //
        try {
            String swfPath, swfBackgroundColor, swfAlign, swfQuality;
            int swfWidth, swfHeight;
            boolean swfPlay, swfLoop, swfAllowNetworkAccess;
            // Print out Flash content
            flashContainer = cms.contentloop(paragraphs, "FlashContent");
            while (flashContainer.hasMoreContent()) {
                swfPath                 = cms.contentshow(flashContainer, "URI");
                swfWidth                = Integer.parseInt(cms.contentshow(flashContainer, "Width"));
                swfHeight               = Integer.parseInt(cms.contentshow(flashContainer, "Height"));
                swfAlign                = cms.contentshow(flashContainer, "Align");
                swfQuality              = cms.contentshow(flashContainer, "Quality");
                swfPlay                 = Boolean.parseBoolean(cms.contentshow(flashContainer, "Play"));
                swfLoop                 = Boolean.parseBoolean(cms.contentshow(flashContainer, "Loop"));
                swfAllowNetworkAccess   = Boolean.parseBoolean(cms.contentshow(flashContainer, "AllowNetworkAccess"));
                swfBackgroundColor      = cms.contentshow(flashContainer, "BackgroundColor");

                String swfName          = CmsResource.getName(swfPath);
                if (cms.elementExists(swfPath)) {
%>
                    <div class="flashcontent" style="position:relative; z-index:1;">
                    <script language="javascript">
                        if (AC_FL_RunContent == 0) {
                                alert("This page requires AC_RunActiveContent.js.");
                        } else {
                                AC_FL_RunContent(
                                        'codebase', 'http://download.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=9,0,0,0',
                                        'width', '<%= swfWidth %>',
                                        'height', '<%= swfHeight %>',
                                        'src', '<%= swfName.substring(0, swfName.lastIndexOf(".")) %>',
                                        'quality', '<%= swfQuality %>',
                                        'pluginspage', 'http://www.macromedia.com/go/getflashplayer',
                                        'align', '<%= swfAlign %>',
                                        'play', '<%= Boolean.toString(swfPlay) %>',
                                        'loop', '<%= Boolean.toString(swfLoop) %>',
                                        'scale', 'showall',
                                        'wmode', 'transparent',
                                        'devicefont', 'false',
                                        'id', '<%= swfName.substring(0, swfName.lastIndexOf(".")) %>',
                                        'bgcolor', '<%= swfBackgroundColor %>',
                                        'name', '<%= swfName.substring(0, swfName.lastIndexOf(".")) %>',
                                        'menu', 'true',
                                        'allowFullScreen', 'false',
                                        'allowScriptAccess','sameDomain',
                                        'movie', '<%= swfName.substring(0, swfName.lastIndexOf(".")) %>',
                                        'salign', ''
                                        ); //end AC code
                        }
                    </script>
                    <noscript>
                        <object classid="clsid:d27cdb6e-ae6d-11cf-96b8-444553540000" codebase="http://download.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=9,0,0,0" width="620" height="280" id="bildevisning5" align="middle">
                            <param name="allowScriptAccess" value="sameDomain" />
                            <param name="allowFullScreen" value="false" />
                            <param name="wmode" value="transparent" />
                            <param name="movie" value="<%= swfPath %>" />
                            <param name="loop" value="<%= Boolean.toString(swfLoop) %>" />
                            <param name="quality" value="<%= swfQuality %>" />
                            <param name="bgcolor" value="<%= swfBackgroundColor %>" />
                            <embed src="<%= swfPath %>"
                                    loop="<%= Boolean.toString(swfLoop) %>"
                                    quality="<%= swfQuality %>"
                                    bgcolor="<%= swfBackgroundColor %>"
                                    width="<%= swfWidth %>"
                                    height="<%= swfHeight %>"
                                    name="<%= swfName.substring(0, swfName.lastIndexOf(".")) %>"
                                    align="<%= swfAlign %>"
                                    allowScriptAccess="sameDomain"
                                    allowFullScreen="false"
                                    wmode="transparent"
                                    type="application/x-shockwave-flash"
                                    pluginspage="http://www.macromedia.com/go/getflashplayer" />
                        </object>
                </noscript>
                </div>
<%
                }
            }
        }
        catch (NullPointerException npe1) {
            throw new ServletException("Null pointer encountered while creating flash container.");
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
                imageTypeChoice = cms.labelUnicode("label.np." + cms.contentshow(imageContainer, "ImageType").toLowerCase());
                imageSizeChoice = IMAGE_PX_SIZES.get(IMAGE_SIZES.indexOf(cms.contentshow(imageContainer, "Size"))).intValue();
                imageFloatChoice= cms.contentshow(imageContainer, "Float");

                int imageHeight  = -1;
                int imageWidth   = imageSizeChoice;//IMG_WIDTH_M;

                // Check to make sure that the image exists
                if (cmso.existsResource(imagePath)) {
                //if (cmso.existsResource(imagePath.substring(0, imagePath.indexOf("?") == -1 ? imagePath.length() : imagePath.indexOf("?")))) {
                    int[] imageDimensions = cms.getImageSize(cmso.readResource(imagePath));
                    // DOWNSCALE only!
                    if (imageDimensions[0] > imageSizeChoice) {
                        // Downscale needed
                        imageHeight = CmsAgent.calculateNewImageHeight(imageSizeChoice, imageDimensions[0], imageDimensions[1]);

                        imgPro.setWidth(imageSizeChoice);
                        imgPro.setHeight(imageHeight);

                        // Get the <img> tag for the scaled image
                        scaledImageTag = cms.img(imagePath, imgPro.getReScaler(imgPro), null);

                        scaledImageTag = "<a href=\"" + cms.link(imagePath) + "\"" + 
                                            " title=\"" + cms.labelUnicode("label.np.largerimage") + "\"" +
                                            " class=\"highslide\"" +
                                            " onclick=\"return hs.expand(this);\">" +
                                                scaledImageTag +
                                         "</a>";
                    }
                    else {
                        // No downscale needed
                        scaledImageTag = "<img src=\"" + cms.link(imagePath) + "\" />";
                        imageWidth = imageDimensions[0];
                    }
                }
                else {
                    scaledImageTag = "<img src=\"\" alt=\"\" />";
                    throw new ServletException("The image does not exist. (Path was '" +
                            (imagePath == null ? "null" : imagePath) + "').");
                }

                // Insert class and required 'alt' attribute inside the <img> tag
                scaledImageTag = scaledImageTag.replace("<img", "<img class=\"illustration-image\"");
                scaledImageTag = scaledImageTag.replace("/>", "alt=\"".concat(imageTitle).concat("\" />"));

                boolean isFloatImage = imageSizeChoice != IMG_WIDTH_XL;
                boolean useSpans = !imageFloatChoice.equalsIgnoreCase("none");
                if (useSpans && !isFloatImage)
                    useSpans = false;
                // Output the image container
                if (isFloatImage) 
                    out.println(getImageContainer(cms, useSpans, scaledImageTag, imageWidth, IMAGE_PADDING, imageCaption, imageSource, imageTypeChoice, imageFloatChoice));
                else 
                    out.println(getImageContainer(cms, useSpans, scaledImageTag, imageWidth, IMAGE_PADDING, imageCaption, imageSource, imageTypeChoice, imageFloatChoice));
            }
        }
        catch (NullPointerException npe1) {
            throw new ServletException("Null pointer encountered while reading image information.");
        }


        //
        // Videos
        //
        try {
            out.println("\n<!-- Entering video section -->");
            String videoPath = null;
            String videoCaption = null;
            String videoCredit = null;
            String videoSizeChoice = null;
            String videoFloatChoice = null;
            
            videoContainer = cms.contentloop(paragraphs, "Video");
            if (!videoContainer.getCollectorResult().isEmpty())
                out.println("<!-- Videos in this paragraph: " + videoContainer.getCollectorResult().size() + " -->");
            else
                out.println("<!-- No videos in this paragraph -->");
            
            while (videoContainer.hasMoreContent()) {
                videoPath       = cms.contentshow(videoContainer, "URI");
                videoCaption    = cms.contentshow(videoContainer, "Caption");
                videoCredit     = cms.contentshow(videoContainer, "Credit");
                videoSizeChoice = cms.contentshow(videoContainer, "Size");
                videoFloatChoice= cms.contentshow(videoContainer, "Float");
                
                int videoWidth   = IMAGE_PX_SIZES.get(IMAGE_SIZES.indexOf(videoSizeChoice)).intValue();
                
                // Check to make sure that the video exists
                if (!cmso.existsResource(videoPath)) {
                    throw new ServletException("A video was added to a paragraph, but the video does not exist. (Path was '" +
                            (videoPath == null ? "null" : videoPath) + "').");
                }
                
                // Output the video container
                printVideoContainer(cms, videoPath, videoWidth+(2*IMAGE_PADDING), 0, videoCaption, videoCredit, videoFloatChoice, out);
                
            }
            
        }
        catch (NullPointerException npe1) {
            throw new ServletException("Null pointer encountered while printing video.");
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
                
                out.println("<div class=\"textbox\">");
                if (cms.elementExists(tbTitle)) {
                    out.println("<h5>" + tbTitle + "</h5>");
                }
                if (cms.elementExists(tbText)) {
                    out.println("<div class=\"textbox-content\">" + tbText + "</div>");
                }
                out.println("</div><!-- .textbox -->");
            }
        }
        catch (NullPointerException npe1) {
            throw new ServletException("Null pointer encountered while creating text box.");
        }
        
        
        
        //
        // Paragraph text
        //
        if (cms.elementExists(text))
            out.println(CmsAgent.obfuscateEmailAddr(text, true));

        out.println("</div> <!-- .paragraph -->");
        
        
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
            if (extFile != null) {
                out.println("<!-- Paragraph extension: '" + extFile + "' -->");
                cms.includeAny(extFile, "resourceUri");
            }           
        } catch (Exception e3) {
            out.println("<!-- Oh noes! The paragraph extension crashed it: " + e3.getMessage() + " -->");
        }
    }
}
//out.println("<!-- PARAGRAPH_HANDLER: done with container. -->");
%>