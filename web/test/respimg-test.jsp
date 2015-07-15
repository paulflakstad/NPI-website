<%-- 
    Document   : respimg-test
    Created on : Sep 15, 2014, 1:33:13 PM
    Author     : Paul-Inge Flakstad, Norwegian Polar Institute
--%>
<%@page import="org.opencms.util.CmsStringUtil"%>
<%@page contentType="text/html" pageEncoding="UTF-8"
%><%@page import="java.util.*,
        no.npolar.util.*,
        org.opencms.file.*,
        org.opencms.file.types.*,
        org.opencms.jsp.*,
        org.opencms.loader.CmsImageScaler,
        org.opencms.main.CmsException" 
%><%!

/**
 * @see http://www.smashingmagazine.com/2014/05/14/responsive-images-done-right-guide-picture-srcset/
 * @author Paul-Inge Flakstad, Norwegian Polar Institute
 */
    /** Size used for images which are tiny, even on small screens. */
    public static final int SIZE_XS = 0;
    
    /** Size used for images which appear small on large screens, occupying up to 33.3% of the viewport width. */
    public static final int SIZE_S = 1;
    
    /** Size used for images which appear medium on large screens, occupying up to 50% of the viewport width. */
    public static final int SIZE_M = 2;
    
    /** Size used for images which appear large/full-width on large screens, occupying up to 100% of the viewport width. */
    public static final int SIZE_L = 3;
    
    /** Size used for images that are always full-width (or wider). */
    public static final int SIZE_XL = 3;
    
    /** Default maximum absolute widths (in pixels). The indices are adjusted to fit the int values of the SIZE_X members. */
    public static int[] DEFAULT_MAX_ABS_SIZES = { 150, 450, 650, 1000, 1200 }; // XS, S, M, L, XL
    
    /** The default image size. When no size is given, we must assume "large/full-width" (up to 100% of the viewport width). */
    public static final int DEFAULT_SIZE = SIZE_L;
    
    /** The default maximum pixel width of the image. If the original image is wider, a down-scaled (this width). */
    public static final int DEFAULT_MAX_WIDTH = 1200;
    
    /** The default maximum image width, relative to the viewport (in percent). */
    public static final int DEFAULT_MAX_VP_WIDTH = 100;
    
    /** The default minimum image width, relative to the viewport (in percent). */
    public static final int DEFAULT_MIN_VP_WIDTH = 50;
    
    /** The default breakpoint. Typically, 50em is roughly 800px. */
    public static final String DEFAULT_BREAKPOINT = "50em";
    
    /** The default quality to use when creating the various image versions. */
    public static final int DEFAULT_QUALITY = 90;
    
    /** */
    public static final String PARAM_NAME_FINGERPRINT = "fp";
    
    /** Crop ratio 1:1 (an even square). */
    public static final String CROP_RATIO_1_1 = "1:1";
    /** Crop ratio 4:3 (typical photo and "old TV" format). */
    public static final String CROP_RATIO_4_3 = "4:3";
    /** Crop ratio 16:9 ("widescreen" format). */
    public static final String CROP_RATIO_16_9 = "16:9";
    /** "Crop ratio" no cropping. */
    public static final String CROP_RATIO_NO_CROP = null;
    
    public static final int SCALE_TYPE_CROP = 2;
    public static final int SCALE_TYPE_NOCROP = 4;
    
    public static final String OCMS_EL_NAME_IMAGE_URI = "URI";
    public static final String OCMS_EL_NAME_IMAGE_TITLE = "Title";
    public static final String OCMS_EL_NAME_IMAGE_TEXT = "Text";
    public static final String OCMS_EL_NAME_IMAGE_SOURCE = "Source";
    public static final String OCMS_EL_NAME_IMAGE_TYPE = "ImageType";
    public static final String OCMS_EL_NAME_IMAGE_SIZE = "Size";
    public static final String OCMS_EL_NAME_IMAGE_FLOAT = "Float";
    
    /**
     * Calculates the rescaled height of an image, based on the new width and 
     * assuming the aspect ratio should be kept intact.
     * @param imagePath The path to the image.
     * @param newWidth The new width.
     * @return The new height.
     */
    public static int getRescaledHeight(CmsObject cmso, String imagePath, int rescaledWidth) throws JspException {
        CmsImageScaler image = null;
        try {
            image = new CmsImageScaler(cmso, cmso.readResource(imagePath));
        } catch (Exception e) {
            throw new JspException("Error reading details from image '" + imagePath + "': " + e.getMessage());
        }
        double newHeight = 0.0;
        double ratio = 0.0;
        ratio = (double)image.getWidth() / rescaledWidth; // IMPORTANT! Cast one to double, or ratio will get an integer value..!!!
        newHeight = (double)image.getHeight() / ratio;
        return (int)newHeight;
    }
    
    /**
     * Constructs a string representation of the given srcset list.
     * @param srcset The srcset list.
     * @return A string representation of the given srcset list.
     */
    protected static String srcsetToString(List<String> srcset) {
        String s = "";
        if (srcset != null && !srcset.isEmpty()) {
            Iterator<String> i = srcset.iterator();
            while (i.hasNext()) {
                s += i.next();
                if (i.hasNext())
                    s += ",\n\t\t ";
            }
        }
        return s;
    }
    
    public static String getMediaWrapper(String mediaElement, String captionLede, String caption, String credit, String mediaExtraClass) {
        String s = "<figure class=\"media"; 
        if (hasContent(mediaExtraClass)) {
            s += " " + mediaExtraClass;
        }
        s += "\">";
        
        s += mediaElement; // E.g. <img src="myimage.jpg" alt="lolcat" />
        
        if (hasContent(captionLede) || hasContent(caption) || hasContent(credit)) {
            s += "<figcaption class=\"caption highslide-caption\">";
            if (hasContent(captionLede)) {
                s += "<span class=\"figure-caption-lede\">" + captionLede + "</span>";
            }
            if (hasContent(caption)) {
                s += caption;
            }
            if (hasContent(credit)) {
                s += "<span class=\"credit figure-credit\">" + credit + "</span>";
            }
            s += "</figcaption>";
        }
        s += "</figure>";
        return s;
    }
    
    public static boolean hasContent(String s) {
        return s != null && s.trim().length() > 0;
    }
    
    public static List<String> getSrcset(CmsJspActionElement cms, String imageUri, int maxAbsoluteWidth, int scaleType, int quality) throws JspException  {
        CmsObject cmso = cms.getCmsObject();
        boolean isParameterizedImageUri = imageUri.indexOf("?") != -1;
        String imageUriNoParams = isParameterizedImageUri ? imageUri.substring(0, imageUri.indexOf("?")) : imageUri;
        List<String> srcset = new ArrayList<String>();
        try {
            CmsImageScaler imageInfo = new CmsImageScaler(cmso, cmso.readResource(imageUriNoParams));
			
            // If the given abs. width is larger than the original image's width, adjust the abs. width accordingly (equal to the original image's width)
            if (maxAbsoluteWidth > imageInfo.getWidth())
                    maxAbsoluteWidth = imageInfo.getWidth();
				
            int numImagesGenerated = 0; // Just a precaution ...
            for (int scaleWidth = maxAbsoluteWidth < 400 ? maxAbsoluteWidth : 400; scaleWidth <= maxAbsoluteWidth && numImagesGenerated < 20; numImagesGenerated++) {
				
                srcset.add(
                        cms.link(
                            imageUri + (isParameterizedImageUri ? "&" : "?")
                                + "__scale="
                                    + "w:" + scaleWidth
                                    + ",h:" + getRescaledHeight(cmso, imageUri, scaleWidth)
                                    + ",t:" + scaleType
                                    + ",q:" + quality
                                + "&" + PARAM_NAME_FINGERPRINT + "=" + getDateLastModified(cmso, imageUriNoParams)
                        )
                        + " " + scaleWidth + "w"
                        );
                
                if (scaleWidth >= maxAbsoluteWidth)
                    break; // important! (prevents infinite loop)
                
                scaleWidth += 400;
                if (scaleWidth > maxAbsoluteWidth)
                    scaleWidth = maxAbsoluteWidth;
            }
        } catch (Exception e) {
            throw new JspException("Error scaling image '" + imageUriNoParams + "': " + e.getMessage());
        }
        // All image URIs are now in the srcset list, like so:
        // [0]: "/my/image.jpg?w:400,h:300,t:4,q:90&fp=fdsf1sdf1ds9515fsd19f1sd9f1s
        // [1]: "/my/image.jpg?w:800,h:600,t:4,q:90&fp=fdsf1sdf1ds9515fsd19f1sd9f1s
        // [2]: "/my/image.jpg?w:1200,h:900,t:4,q:90&fp=fdsf1sdf1ds9515fsd19f1sd9f1s
        
        // Finally, reverse the list
        if (!srcset.isEmpty())
            Collections.reverse(srcset);
        
        return srcset;
    }
    
    public static String getDateLastModified(CmsObject cmso, String resourceUri) throws JspException {
        // Add a fingerprint to image URIs, which may be used to improve 
        // performance by leveraging caching headers:
        // https://developers.google.com/speed/docs/insights/LeverageBrowserCaching
        String dlm = "";
        try {
            // Get the "date last modified" to use as fingerprint - creating image URIs like /my-image.jpg?fp=14561616159
            dlm = String.valueOf(cmso.readResource(resourceUri).getDateLastModified());
        } catch (Exception e) {
            throw new JspException("Error reading 'date last modified' for image '" + resourceUri + "': " + e.getMessage());
        }
        return dlm;
    }
    
    public static String getAltText(CmsObject cmso, String imageUri, String altText) throws JspException {
        String alt = altText;
        if (alt == null) {
            try {
                alt = cmso.readPropertyObject(imageUri, CmsPropertyDefinition.PROPERTY_DESCRIPTION, false).getValue("");
            } catch (Exception e) {
                throw new JspException("Error reading property 'Description' for image '" + imageUri + "': " + e.getMessage());
            }
        } else if (alt.equalsIgnoreCase("none") || alt.equalsIgnoreCase("-")) {
            alt = "";
        }
        return alt;
    }
    
    public static String getImageUriFromSrcset(String srcsetEntry) {
        if (srcsetEntry != null && !srcsetEntry.isEmpty()) {
            return srcsetEntry.substring(0, srcsetEntry.indexOf(" "));
        }
        return "";
    }
    
    public static String getFallbackImageUri(List<String> srcset, String imageUri) {
        String fallbackUri = imageUri;
        if (!srcset.isEmpty()) {
            fallbackUri = getImageUriFromSrcset(srcset.get(0)); // The widest image in the set
        }
        return fallbackUri;
    }
    
    /**
     * Produces a ready-to-use img element, complete with srcset, sizes, src and 
     * alt attributes, based on the given parameters.
     * <p>
     * A simple approach is applied: generate several versions of an image, 
     * covering a range of resolutions. Furthermore, if the image will never be 
     * full-width in viewports wider than the linear breakpoint, include info 
     * to indicate its maximum width (relative to the viewport). The latter 
     * is a hint to the browser to help it pick the appropriate version of the 
     * image. (For widths narrower than the linear breakpoint, we assume that 
     * any image may span full-width.)
     * <p>
     * <strong>Example:</strong><br />Assume 3 images are generated:
     * <ul><li>400px</li><li>800px</li><li>1200px</li></ul>
     * If the viewport width is 1080px, the browser could pick:
     * <ul>
     * <li>the 800px image, if the image will span max. 50%</li>
     * <li>the 1200px image, if the image will span full-width</li>
     * </ul>
     * If the viewport width is 720px, the browser could pick:
     * <ul>
     * <li>the 400px image, if the image will span max. 50%</li>
     * <li>the 800px image, if the image will span full-width</li>
     * </ul>
     * @param cms Needed to access the image and the VFS. Mandatory.
     * @param imageUri The path to the image in the VFS. Mandatory.
     * @param alt The alternative text. Provide a null value to use the "Description" property, or "none" / "-" to leave it empty.
     * @param cropRatio The crop ratio. Must be given as "[width]:[height]", i.e.: "4:3", or a null value (indicating "don't crop"). Some typical ratios are offered by the CROP_RATIO_X static members of this class, for example {@link ImageUtil#CROP_RATIO_1_1}.
     * @param maxAbsoluteWidth The maximum image width, in pixels. If the given image is wider, a down-scaled (to this width) version will be generated and used as the largest image version. Provide -1 to use the default, {@link ImageUtil#DEFAULT_MAX_WIDTH}.
     * @param maxViewportRelativeWidth The maximum image width, relative to the viewport (in percent). Provide -1 to use the default, {@link ImageUtil#DEFAULT_MAX_VP_WIDTH}.
     * @param size The image size. Must be one of the SIZE_X static members of this class, for example {@link ImageUtil#SIZE_M}. Provide -1 to use the default, {@link ImageUtil#DEFAULT_SIZE}.
     * @param linearBreakpoint The linear/float breakpoint, i.e.: "50em", or "800px". Provide a null value to use the default, {@link ImageUtil#DEFAULT_BREAKPOINT}.
     * @return A ready-to-use img element, complete with srcset, sizes, src and alt attributes.
     * @throws ImageAccessException 
     */
    public static synchronized String getImage (
            CmsJspActionElement cms
            , String imageUri
            , String alt
            , String cropRatio
            , int maxAbsoluteWidth
            , int maxViewportRelativeWidth
            , int size
            , int quality
            , String linearBreakpoint
            )
             throws JspException
    {
        boolean isParameterizedImageUri = imageUri.indexOf("?") != -1;
        String imageResourcePath = isParameterizedImageUri ? imageUri.substring(0, imageUri.indexOf("?")) : imageUri;
        CmsObject cmso = cms.getCmsObject();
        // 1. Create a set of scaled sizes (namely S, M & L - L being the fallback)
        
        // For each version, construct its srcset entry by adding the URI
        // and the width, e.g.: "small.jpg 320w" (320 is the width of the image).
        List<String> srcset = new ArrayList<String>();
        // Generate the versions here ...
        int scaleType = cropRatio == null ? SCALE_TYPE_NOCROP : SCALE_TYPE_CROP;
        if (!cmso.existsResource(imageResourcePath , CmsResourceFilter.requireType(CmsResourceTypeImage.getStaticTypeId()))) {
            throw new JspException("Attempting to scale image '" + imageResourcePath + "', which does not exist.");
        }
        /*
        // Add a fingerprint to image URIs, which may be used to improve 
        // performance by leveraging caching headers:
        // https://developers.google.com/speed/docs/insights/LeverageBrowserCaching
        String fp = "";
        try {
            // Get the "date last modified" to use as fingerprint - creating image URIs like /my-image.jpg?fp=14561616159
            fp = PARAM_NAME_FINGERPRINT + "=" + String.valueOf(cms.getCmsObject().readResource(imageResourcePath).getDateLastModified());
        } catch (Exception e) {
            throw new JspException("Error reading 'date last modified' for image '" + imageResourcePath + "': " + e.getMessage());
        }
        //*/
        
        /*
        if (alt == null) {
            try {
                alt = cmso.readPropertyObject(imageResourcePath, CmsPropertyDefinition.PROPERTY_DESCRIPTION, false).getValue("");
            } catch (Exception e) {
                throw new JspException("Error reading property 'Description' for image '" + imageResourcePath + "': " + e.getMessage());
            }
        } else if (alt.equalsIgnoreCase("none") || alt.equalsIgnoreCase("-")) {
            alt = "";
        }
        //*/
        
        alt = getAltText(cmso, imageResourcePath, alt);
        
        srcset = getSrcset(cms, imageUri, maxAbsoluteWidth, scaleType, quality);
        /*
        try {
            CmsImageScaler imageInfo = new CmsImageScaler(cmso, cmso.readResource(imageResourcePath));
			
            // If the given abs. width is larger than the original image's width, adjust the abs. width accordingly (equal to the original image's width)
            if (maxAbsoluteWidth > imageInfo.getWidth())
                    maxAbsoluteWidth = imageInfo.getWidth();
				
            int numImagesGenerated = 0; // Just a precaution ...
            for (int scaleWidth = maxAbsoluteWidth < 400 ? maxAbsoluteWidth : 400; scaleWidth <= maxAbsoluteWidth && numImagesGenerated < 5; numImagesGenerated++) {
				
                srcset.add(
                        imageUri + (isParameterizedImageUri ? "&" : "?")
                        + "w:" + scaleWidth
                        + ",h:" + getRescaledHeight(cmso, imageUri, scaleWidth)
                        + ",t:" + scaleType
                        + ",q:" + quality
                        + "&" + fp
                        + " " + scaleWidth + "w"
                        );
                
                if (scaleWidth >= maxAbsoluteWidth)
                    break; // important! (prevents infinite loop)
                
                scaleWidth += 400;
                if (scaleWidth > maxAbsoluteWidth)
                    scaleWidth = maxAbsoluteWidth;
            }
        } catch (Exception e) {
            throw new JspException("Error scaling image '" + imageResourcePath + "': " + e.getMessage());
        }
        // All image URIs are now in the srcset list, like so:
        // [0]: "/my/image.jpg?w:400,h:300,t:4,q:90&fp=fdsf1sdf1ds9515fsd19f1sd9f1s
        // [1]: "/my/image.jpg?w:800,h:600,t:4,q:90&fp=fdsf1sdf1ds9515fsd19f1sd9f1s
        // [2]: "/my/image.jpg?w:1200,h:900,t:4,q:90&fp=fdsf1sdf1ds9515fsd19f1sd9f1s
        //*/
        String srcsetString = srcsetToString(srcset);
        
        String sizes = "";
        if (!srcsetString.isEmpty()) {
            // The "sizes" attribute, determined by the given width info. 
            // (Use a very simple approach: if an image is NOT fullwidth, it will not 
            // occupy more than 50% of the viewport width on large screens.)
            if (size < 0) {
                size = DEFAULT_SIZE;
            }
            if (size < SIZE_L) {
                sizes += "(min-width:" + (linearBreakpoint != null ? linearBreakpoint : DEFAULT_BREAKPOINT) + ") " + DEFAULT_MIN_VP_WIDTH + "vw, "; // widths larger than the breakpoint
            }
            // The default
            sizes += (maxViewportRelativeWidth < 0 ? maxViewportRelativeWidth : DEFAULT_MAX_VP_WIDTH) + "vw";
        }
        
        String fallbackUri = getFallbackImageUri(srcset, imageUri);
        /*
        String defaultSrc = imageUri;
        if (!srcset.isEmpty()) {
            defaultSrc = getImageUriFromSrcset(srcset.get(srcset.size() - 1)); // The widest image in the set
        }
        //*/
        
        // Construct the img tag
        String img = "<img";
        if (!srcsetString.isEmpty()) {
            img += "\n\t srcset=\"" + srcsetString + "\"";
            img += "\n\t sizes=\"" + sizes + "\"";
        }
        img += "\n\t src=\"" + cms.link(fallbackUri) + "\"";
        img += "\n\t alt=\"" + alt.replace("\"", "\\\"") + "\"";
        img += " />";
        
        return img;
    }
    
    public static synchronized String getImage(CmsJspActionElement cms, String imageUri, String alt, int maxWidth, int size, int quality) throws JspException {
        return getImage(cms, imageUri, alt, CROP_RATIO_NO_CROP, getDefaultMaxWidth(size), DEFAULT_MAX_VP_WIDTH, size, quality, DEFAULT_BREAKPOINT);
    }
    
    public static synchronized String getImage(CmsJspActionElement cms, String imageUri, String alt, int maxWidth, int size) throws JspException {
        return getImage(cms, imageUri, alt, getDefaultMaxWidth(size), size, DEFAULT_QUALITY);
    }
    public static synchronized String getImage(CmsJspActionElement cms, String imageUri, String alt, int size) throws JspException {
        return getImage(cms, imageUri, alt, getDefaultMaxWidth(size), size);
    }
    public static synchronized String getImage(CmsJspActionElement cms, String imageUri, String alt) throws JspException {
        return getImage(cms, imageUri, alt, DEFAULT_MAX_WIDTH);
    }
    public static synchronized String getImage(CmsJspActionElement cms, String imageUri) throws JspException {
        return getImage(cms, imageUri, null);
    }
    
    public static int getDefaultMaxWidth(int size) {
        return DEFAULT_MAX_ABS_SIZES[size];
    }
%><!DOCTYPE html>
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <title>Responsive image test</title>
        <style type="text/css">
            html { background: #777; }
            article { width:96%; max-width:1200px; background: #fff; margin:0 auto; padding:2%; box-shadow:0 0 1em rgba(0,0,0,0.9); }
            pre { font-size:0.8em; font-family: 'Courier New', monospace; background: #fafafa; border:1px solid #ddd; padding:1em; word-wrap: break-all; }
            img { max-width: 100%; }
        </style>
    </head>
    <body>
        <article>
        <h1>Responsive image test</h1>
        <%
        CmsAgent cms = new CmsAgent(pageContext, request, response);
        CmsObject cmso = cms.getCmsObject();
        //String imagePath = "/images/forskning/iskjerne-boring-NP035797.jpg"; //850×???
        String imagePath = "/images/news/2012/Polarmxkerx_foto_Hallvard_Strxmx_Norsk_Polarinstitutt.jpg"; // 3888×2592
        
        final int ABS_WIDTH = 720;
        final int SIZE = SIZE_XL;
        
        //String html = getImage(cms, imagePath, "lololol", CROP_RATIO_NO_CROP, ABS_WIDTH, 100, SIZE_M, 100, "30em");
        String html = getImage(cms, imagePath, "lololol", SIZE);
        %>
        <h2>CMS-generated HTML (using a max. absolute width of <%= DEFAULT_MAX_ABS_SIZES[SIZE] %>px)</h2>
        <pre><%= CmsStringUtil.escapeHtml(html) %></pre>
        <h2>The browser's interpretation</h2>
        <div><%= html %></div>
        <!--<h2>Generated images in the source set:</h2>
        <%
        List<String> srcset = getSrcset(cms, imagePath, DEFAULT_MAX_ABS_SIZES[SIZE], SCALE_TYPE_NOCROP, DEFAULT_QUALITY);
        Iterator<String> iSrcset = srcset.iterator();
        while (iSrcset.hasNext()) {
            String imageUri = getImageUriFromSrcset(iSrcset.next());
            %>
            <p><img src="<%= cms.link(imageUri) %>" alt="" /></p>
            <%
        }
        String defaultImageUri = getFallbackImageUri(srcset, imagePath);
        %>
        <h2>Fallback image:</h2>
        <img src="<%= cms.link(defaultImageUri) %>" alt="" />
        -->
        </article>
    </body>
</html>