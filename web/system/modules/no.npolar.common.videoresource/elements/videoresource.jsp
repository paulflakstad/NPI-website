<%-- 
    Document   : videoresource
    Created on : 29.okt.2010, 15:51:14
    Author     : Paul-Inge Flakstad <flakstad at npolar.no>
--%><%@page contentType="text/html" 
            pageEncoding="UTF-8"
            import="org.opencms.file.CmsObject,
                java.net.*,
                java.util.*,
                java.util.regex.*,
                org.opencms.main.OpenCms,
                org.opencms.jsp.*,
                org.opencms.file.*,
                org.opencms.file.types.CmsResourceTypeBinary,
                org.opencms.util.*,
                no.npolar.util.*" 
%><%!
public static String alterDimensions(String code, int newWidth) {
    String alteredCode = code;
    String regex = "width=\\\"([0-9]+)\\\"";
    String replacement = "width=\"" + newWidth + "\"";

    Pattern p = Pattern.compile(regex);
    Matcher m = p.matcher(alteredCode); // Get a Matcher object
    String width = null;
    double widthValue = -1;
    String height = null;
    double heightValue = -1;
    Set widthMatches = new HashSet();
    Set heightMatches = new HashSet();



    //System.out.println("searching...\n");
    while(m.find()) {
        widthMatches.add(alteredCode.substring(m.start(), m.end()));
        //System.out.println("match: [" + match + "]");
    }

    if (!widthMatches.isEmpty()) {
        if (widthMatches.size() > 1) {
            throw new IllegalArgumentException("Unable to alter code: More than one width was specified.");
        }
        Iterator i = widthMatches.iterator();
        while (i.hasNext()) {
            width = (String)i.next();
            // Get the value of the heigth attribute as a double
            widthValue = Integer.valueOf(width.substring(width.indexOf("\"") + 1, width.lastIndexOf("\"") - 1)).doubleValue();
            alteredCode = alteredCode.replaceAll(width, replacement);
        }
    } 
    else {
        throw new IllegalArgumentException("Unable to alter code: No width was specified.");
    }

    // Done altering the width attributes, continue with heights
    regex = "height=\\\"([0-9]+)\\\"";
    p = Pattern.compile(regex);
    m = p.matcher(alteredCode);
    while (m.find()) {
        heightMatches.add(alteredCode.substring(m.start(), m.end()));
    }

    if (!heightMatches.isEmpty()) {
        if (heightMatches.size() > 1) {
            throw new IllegalArgumentException("Unable to alter code: More than one height was specified.");
        }
        Iterator i = heightMatches.iterator();
        while (i.hasNext()) {
            height = (String)i.next(); // height="some number"
            // Get the value of the heigth attribute as a double
            heightValue = Integer.valueOf(height.substring(height.indexOf("\"") + 1, height.lastIndexOf("\"") - 1)).doubleValue();
            // Find the height to width ratio
            double ratio = heightValue / widthValue;
            // Calculate the new height
            double newHeight = (newWidth * ratio);
            replacement = "height=\"" + new Double(newHeight).intValue() + "\"";
            alteredCode = alteredCode.replaceAll(height, replacement);
        }
    }

    return alteredCode;
}

public String getVideoMimeType(String videoUri) {
    List<String> mp4 = new ArrayList<String>(Arrays.asList(new String[] { "mp4", "m4a", "m4b", "m4p", "m4v", "3gp", "3g2" }));
    List<String> ogg = new ArrayList<String>(Arrays.asList(new String[] { "ogg", "ogv" }));
    
    // Extract the extension from the given uri
    String s = CmsResource.getName(videoUri);
    if (s.contains(".")) {
        s = s.substring(s.lastIndexOf(".") + 1);
    }
    
    if (mp4.contains(s)) 
        return "video/mp4";
    if (ogg.contains(s))
        return "video/ogg";
    
    return "video/unknown";
}
%>
<%
CmsAgent cms = new CmsAgent(pageContext, request, response);
CmsObject cmso = cms.getCmsObject();
String requestFileUri = cms.getRequestContext().getUri();
String requestFolderUri = cms.getRequestContext().getFolderUri();
Locale locale = cms.getRequestContext().getLocale();
String loc = locale.toString();

// Direct edit switches
final boolean EDITABLE              = true;
final boolean EDITABLE_TEMPLATE     = false;
boolean includeTemplate             = OpenCms.getResourceManager().getResourceType(cmso.readResource(requestFileUri)).getTypeId() == 
                                            OpenCms.getResourceManager().getResourceType("videoresource").getTypeId();
// Template ("outer" or "master" template)
String template                     = cms.getTemplate();
String[] elements                   = cms.getTemplateIncludeElements();

//
// Include upper part of main template
//
if (includeTemplate)
    cms.include(template, elements[0], EDITABLE_TEMPLATE);
        
// The client ID used when setting up the YouTubeService object
final String YT_CLIENT_ID = "flakstad@npolar.no";

// The service used to retrieve specific videos
final String YT_VIDEO_FEED_SERVICE = "http://gdata.youtube.com/feeds/api/videos/";
// The standard YouTube height-to-width ratio
final double YT_HEIGH_WIDTH_RATIO = 360.0 / 640.0;

// Video types, as defined in /system/modules/no.npolar.common.videoresource/schemas/video.xsd
final String VIDEO_TYPE_YOUTUBE = "yt";
final String VIDEO_TYPE_VIMEO = "vimeo";
final String VIDEO_TYPE_HTML5 = "html5";
final String VIDEO_TYPE_LOCAL = "local";
final String VIDEO_TYPE_GENERIC = "generic";

// The video file variables
String title = null;
String description = null;
String transcript = null;
String credit = null;
String source = null;
String type = null;
String image = null;
boolean autostart = false;

// Read video file (XMLContent file)
String resourceUri = request.getParameter("resourceUri") != null ? request.getParameter("resourceUri") : requestFileUri;
String wrapperClass = request.getParameter("wrapperClass") != null ? request.getParameter("wrapperClass") : "media";
String overrideCaption = request.getParameter("caption") != null ? request.getParameter("caption") : "";
String overrideCredit = request.getParameter("credit") != null ? request.getParameter("credit") : "";

I_CmsXmlContentContainer videoFile = cms.contentload("singleFile", resourceUri, false);

while (videoFile.hasMoreContent()) {
    title = cms.contentshow(videoFile, "Title");
    description = cms.contentshow(videoFile, "Description");
    transcript = cms.contentshow(videoFile, "Transcript");
    credit = cms.contentshow(videoFile, "Credit");
    source = cms.contentshow(videoFile, "VideoSource");
    type = cms.contentshow(videoFile, "VideoType");
    image = cms.contentshow(videoFile, "Image");
    autostart = Boolean.valueOf(cms.contentshow(videoFile, "AutoStart")).booleanValue();
}
// Done reading video file



// Print the title and description only if the request page is a videoresource page
// (or: don't print the title/descr if the video is included in e.g. a paragraph of a news article or ivorypage)
if (includeTemplate) {
    out.println("<h1>" + title + "</h1>");
    if (cms.elementExists(description))
        out.println("<div class=\"ingress\">" + description + "</div>");
}

if (!(type.equalsIgnoreCase(VIDEO_TYPE_LOCAL) || type.equalsIgnoreCase(VIDEO_TYPE_GENERIC))) {
    out.println("<span class=\"" + wrapperClass + "\"><span class=\"video-wrapper\">");
}

//
// Read width in prioritized order:
//  1: from request parameter ("width")
//  2: from property (image.size.xl - which should be the max width)
//  3: from default (640)
//
int width = request.getParameter("width") == null ? -1 : Integer.valueOf(request.getParameter("width")).intValue();
if (width == -1) {
    try {
        CmsProperty widthProp = cmso.readPropertyObject(requestFileUri, "image.size.xl", true);
        width = Integer.valueOf(widthProp.getValue("640")).intValue();
    } catch (Exception e) {
        width = 640;
    }        
}
int height = Double.valueOf(Double.parseDouble(Integer.toString(width)) * YT_HEIGH_WIDTH_RATIO).intValue();

// Handle different video types
if (type.equalsIgnoreCase(VIDEO_TYPE_YOUTUBE)) {
    //String videoKey = "video:";

    // Get the video ID
    //out.println("<br />Query part of URL: " + source.substring(source.indexOf("?")+1));
    Map ytUrlParts = CmsRequestUtil.createParameterMap(source.substring(source.indexOf("?")+1));
    String videoId = ((String[])(ytUrlParts.get("v")))[0]; //  = "u_7fbIP_QPY"

    String videoUrl = YT_VIDEO_FEED_SERVICE + videoId;
    try {
        // The video is included in another page.
        // Assume the dimensions is set on the wrapper - set the width/height to 
        // high numbers (making sure it's larger than the wrapper's maximum size)
        if (!includeTemplate) {
            width = 1280;
            height = 720;
        }
        // Construct embed code
        String embedCode = 
                "\n<iframe"
                        + " width=\"560\" height=\"315\""
                        //+ " width=\"100%\" height=\"auto\""
                        //+ " style=\"width:100%; height:100%;\"" 
                        // https is vital here, in order to avoid missing controls bug in Firefox
                        + " src=\"https://www.youtube.com/embed/" + videoId 
                            // We should never auto-start, and the remaining params are now the defaults
                            //+ "?theme=dark&amp;wmode=transparent&amp;html5=1" + (autostart ? "&amp;autoplay=1" : "") 
                            + "\""
                        + " frameborder=\"0\"" 
                        + " allowfullscreen=\"\">"
                + "</iframe>";
        
        out.println(embedCode);
    } catch (Exception e) {
        out.println("<p>Error displaying video: " + e.getMessage() + "</p>");
    }
} // Done with YouTube video

// Vimeo video
else if (type.equalsIgnoreCase(VIDEO_TYPE_VIMEO)) {
    // Get the video ID
    String videoId = source.replace("http://", "");
    videoId = videoId.substring(videoId.indexOf("/") + 1);
    if (videoId.contains("?")) {
        videoId = videoId.substring(0, videoId.indexOf("?"));
    }

    String videoUrl = YT_VIDEO_FEED_SERVICE + videoId;
    try {
        // The video is included in another page.
        // Assume the dimensions is set on the wrapper - set the width/height to 
        // high numbers (making sure it's larger than the wrapper's maximum size)
        if (!includeTemplate) {
            width = 1280;
            height = 720;
        }
        // Construct embed code
        String embedCode = 
                "\n<iframe"
                        + " width=\"100%\" height=\"auto\" style=\"width:100%; height:100%;\"" 
                        + " src=\"http://player.vimeo.com/video/" + videoId + (autostart ? "?autoplay=1" : "") + "\""
                        //+ " width=\"WIDTH\" height=\"HEIGHT\""
                        + " frameborder=\"0\" webkitAllowFullScreen mozallowfullscreen allowFullScreen></iframe>";
        out.println(embedCode);
    } catch (Exception e) {
        out.println("<p>Error displaying video: " + e.getMessage() + "</p>");
    }
} // Done with Vimeo video

else if (type.equalsIgnoreCase(VIDEO_TYPE_HTML5)) {
    String videoCode = "";
    // The HTML5 video tag can contain multiple video sources.
    // Since the video resource accepts only 1 source, we must find any additional
    // sources by checking the folder of the given source. Any binary file with
    // the same name (but different extension) as the given source is considered 
    // an alternative, and added to the list of source URIs. 
    // The main source should always be the MP4 version, because that one needs
    // to come be the first alternative (due to iOS interpretation of the video
    // tag). 
    // ToDo: Make sure the order of the video source alternatives is always 
    // correct, by determining it programatically (e.g. by evaluating the 
    // file extension or MIME type).
    ArrayList<String> videoSources = new ArrayList<String>(1);
    videoSources.add(source);
    // Get the file name
    String sourceName = CmsResource.getName(source);
    // Try to remove the file extension
    try { sourceName = sourceName.substring(0, sourceName.lastIndexOf(".")); } catch (Exception e) { }
    
    // Get all binary files contained in the source video's parent folder
    List<CmsResource> alternativeFiles = cmso.readResources(CmsResource.getParentFolder(source), CmsResourceFilter.DEFAULT_FILES.addRequireType(CmsResourceTypeBinary.getStaticTypeId()), false);
    Iterator<CmsResource> iFolderFiles = alternativeFiles.iterator();
    while (iFolderFiles.hasNext()) {
        CmsResource r = iFolderFiles.next();
        String filePath = cms.getRequestContext().getSitePath(r);
        // Get the file name
        String fileName = r.getName();
        // Try to remove the file extension
        try { fileName = fileName.substring(0, fileName.lastIndexOf(".")); } catch (Exception e) { }
        // If this is not the given source (which we've already added), and the
        // name is equal to the given source ...
        if (!source.equals(filePath)
            && fileName.equals(sourceName))
            videoSources.add(filePath); // ... add this video as an alternative source
    }
    
    try {
        // Construct video code
        videoCode += "\n<video width=\"100%\" height=\"auto\" controls>";
        Iterator<String> iVideoSources = videoSources.iterator();
        while (iVideoSources.hasNext()) {
            String srcUri = iVideoSources.next();
            videoCode += "\n<source"
                                + " src=\"" + cms.link(srcUri) + "\""
                                //+ " src=\"" + org.opencms.main.OpenCms.getLinkManager().getOnlineLink(cmso, srcUri) + "\""
                                + " type=\"" + org.opencms.main.OpenCms.getResourceManager().getMimeType(srcUri, null) + "\""
                                //+ " type=\"" + getVideoMimeType(srcUri) + "\""
                                + ">";
        }
        videoCode += "\nSorry, it seems your browser can't play this video. You may still <a href=\"" + cms.link(source) + "\">download it</a>.";
        videoCode += "\n</video>";
        out.println(videoCode);
    } catch (Exception e) {
        out.println("<p>Error displaying video: " + e.getMessage() + "</p>");
    }
}

// Local video file
else if (type.equalsIgnoreCase(VIDEO_TYPE_LOCAL)) {
    // We play local videos using JWPlayer - neccessary javascript and CSS must be included, and the player must be "/jwplayer/player.swf"!
    if (cmso.existsResource(source)) {
        String html = "<div id=\"videocontainer\">For å se denne siden, må du installere <a target=\"_blank\" href=\"http://www.adobe.com/go/getflash/\">Flash-plugin</a>.</div>" +
                        "\n<script type=\"text/javascript\">" +
                          "\nvar flashvars = { file:'" + cms.link(source) + "',autostart:'" + autostart + "' };" +
                          "\nvar params = { allowfullscreen:'true', allowscriptaccess:'always' };" +
                          "\nvar attributes = { id:'player1', name:'player1' };" +
                          "\nswfobject.embedSWF('" + cms.link("/system/modules/no.npolar.common.videoresource/resources/jwplayer/player.swf") + "','videocontainer','" + width + "','" + height + "','9.0.115','false', flashvars, params, attributes);" +
                        "\n</script>";
        out.print(html);
    } else {
        out.println("<p>ERROR: Video source was '" + source + "', but no such resource exists.</p>");
    }
}

// Generic video (embed code)
else if (type.equalsIgnoreCase(VIDEO_TYPE_GENERIC)) {
    out.println(alterDimensions(source, width));
}

if (!(type.equalsIgnoreCase(VIDEO_TYPE_LOCAL) || type.equalsIgnoreCase(VIDEO_TYPE_GENERIC))) {
    out.println("</span><!-- .video-wrapper -->");
}

String caption = overrideCaption.isEmpty() ? description : overrideCaption;
credit = overrideCredit.isEmpty() ? credit : overrideCredit;


if (!includeTemplate && CmsAgent.elementExists(caption)) {
    out.println("<span class=\"caption\">" + CmsAgent.stripParagraph(caption) + "</span>");
}

if (CmsAgent.elementExists(credit)) {
    out.println("<span class=\"credit\">Video: " + credit + ("yt".equals(type) || "vimeo".equals(type) ? (" / ".concat("yt".equals(type) ? "YouTube" : "Vimeo")) : "" ) + "</span>");
}

if (!(type.equalsIgnoreCase(VIDEO_TYPE_LOCAL) || type.equalsIgnoreCase(VIDEO_TYPE_GENERIC))) {
    out.println("</span><!-- media wrapper (typically .media) -->");
}

//
// Include lower part of main template
//
if (includeTemplate) {
    if (CmsAgent.elementExists(transcript)) {
        out.println(transcript);
    }
    cms.include(template, elements[1], EDITABLE_TEMPLATE);
}
%>