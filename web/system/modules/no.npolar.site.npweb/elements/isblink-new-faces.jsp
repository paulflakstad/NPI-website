<%-- 
    Document   : isblink-new-faces
    Created on : Nov 7, 2014, 12:09:19 PM
    Author     : Paul-Inge Flakstad, Norwegian Polar Institute
--%><%@ page import="no.npolar.util.*,
                 no.npolar.util.exception.MalformedPropertyValueException,
                 org.apache.commons.lang.StringEscapeUtils,
                 org.opencms.file.CmsObject,
                 org.opencms.file.CmsResource,
                 org.opencms.file.types.CmsResourceTypeFolder,
                 org.opencms.file.CmsResourceFilter,
                 org.opencms.main.OpenCms,
                 org.opencms.main.CmsException,
                 org.opencms.jsp.I_CmsXmlContentContainer,
                 org.opencms.relations.CmsCategory,
                 org.opencms.relations.CmsCategoryService,
                 java.io.IOException,
                 java.text.SimpleDateFormat,
                 java.util.Calendar,
                 java.util.GregorianCalendar,
                 java.util.Date,
                 java.util.List,
                 java.util.Map,
                 java.util.HashMap,
                 java.util.Collections,
                 java.util.Comparator,
                 java.util.Arrays,
                 java.util.ArrayList,
                 java.util.Iterator,
                 java.util.Locale" session="false"
%><%@ taglib prefix="cms" uri="http://www.opencms.org/taglib/cms"
%><%!
    public String getFeaturedImageSrc(CmsAgent cms, String filePath, int imageWidth) 
            throws CmsException, MalformedPropertyValueException, JspException {
        if (CmsAgent.elementExists(filePath)) {
            String imagePath = cms.property("image.thumb", filePath, null);
            
            if (imagePath == null)
                throw new JspException("The file '" + filePath + "' has no property value for 'image.thumb'");
            
            imagePath = cms.getRequestContext().removeSiteRoot(imagePath);
            
            if (!cms.getCmsObject().existsResource(imagePath))
                throw new JspException("The file '" + filePath + "' referenced image '" + imagePath + "' as 'image.thumb', but this image does not exist.");
            
            //String imageLink = null;
            //String imagePath = cms.contentshow(imageContainer, "URI");
            
            //int imageHeight = cms.calculateNewImageHeight(imageWidth, imagePath);
            //int imageHeight = (int)(((double)imageWidth / 16) * 9); // Calculate width based on 16:9 proportions (used for type 2 - crop)
            int imageHeight = imageWidth; // Used for type 2 - crop (square)
            
            
            //CmsImageProcessor imgPro = new CmsImageProcessor("__scale=t:3,q:100,w:".concat(String.valueOf(imageWidth)).concat("h:").concat(String.valueOf(imageHeight)));
            CmsImageProcessor imgPro = new CmsImageProcessor();
            //imgPro.setType(4); // Exact size
            imgPro.setType(2); // Crop
            imgPro.setQuality(100);
            imgPro.setWidth(imageWidth);
            imgPro.setHeight(imageHeight);
            return (String)CmsAgent.getTagAttributesAsMap(cms.img(imagePath, imgPro.getReScaler(imgPro), null, false)).get("src");
        }
        return "";
    }
%><%
CmsAgent cms                = new CmsAgent(pageContext, request, response);
CmsObject cmso              = cms.getCmsObject();
//final CmsObject CMSO        = OpenCms.initCmsObject(cmso);
Locale locale               = cms.getRequestContext().getLocale();
//String requestFileUri       = cms.getRequestContext().getUri();
String listFolder           = "/no/nye-fjes/";
final int TYPE_ID_NEWSBULL  = OpenCms.getResourceManager().getResourceType("newsbulletin").getTypeId(); // The ID for resource type "newsbulletin" (316)
//final boolean editableItems = false;
final boolean subTree       = true;

final boolean DEBUG         = false;

// The collector
//String collector = "allInSubTreePriorityDateDesc";
// List of items
//I_CmsXmlContentContainer collectedResources;
// URI to single collected item
String collectedResourceUri;

try {
    //collectedResources = cms.contentload(collector, listFolder.concat("|").concat(Integer.toString(TYPE_ID_NEWSBULL)), editableItems);
    
    // Loop all news items to get a complete list of available years
    
    Date now = new Date();
    
    Calendar limitLowCal = new GregorianCalendar();
    limitLowCal.add(Calendar.MONTH, -3); // Step 3 months back in time
    Date limitLow = limitLowCal.getTime();
    
    if (DEBUG) out.print("<p>Looking back as fas as " + new SimpleDateFormat("d MMM yyyy", locale).format(limitLow) + " ... ");
    
    
    List<CmsResource> resources = cmso.readResources(listFolder, CmsResourceFilter.DEFAULT_FILES.addRequireType(TYPE_ID_NEWSBULL), subTree);
    
    if (DEBUG) out.print("found " + resources.size() + " total. Filtering ... ");
    
    //Iterator iNewsItems = newsItems.getCollectorResult().iterator();
    //List<CmsResource> newsItemsToRemove = new ArrayList<CmsResource>();
    
    Iterator<CmsResource> iResources = resources.iterator();
    while (iResources.hasNext()) {
        // Get resource
        CmsResource r = iResources.next();
        // Get the timestamp from the resource as a Date
        Date newsDate = new Date(Long.valueOf(cmso.readPropertyObject(r, "collector.date", false).getValue("1")));
        
        // Remove current item if it wasn't published within the specified time range
        if (newsDate.before(limitLow) || newsDate.after(now)) {
            //newsItemsToRemove.add(r);
            iResources.remove();
        }
    }
    
    if (DEBUG) out.println("done. " + resources.size() + " remaining after filtering.</p>");
    
    // Remove all news items out of range
    //collectedResources.getCollectorResult().removeAll(newsItemsToRemove);
    
    

    // Process files
    if (!resources.isEmpty()) {
        iResources = resources.iterator();
        %>
        <div style="text-align:center;">
        <h2>Nye fjes :)</h2>
        <ul style="display: block; padding:0; margin:0; list-style: none; width:100%;">
        <%
        while (iResources.hasNext()) {
            CmsResource r = iResources.next();
            collectedResourceUri = cmso.getSitePath(r);// cms.contentshow(collectedResources, "%(opencms.filename)");
            String imgSrc = null;
            String altText = cms.property("Title", collectedResourceUri, "");
            String tooltipText = cms.property("Description", collectedResourceUri, altText);
            String noImgAnchorStyle = "";
            try {
                imgSrc = getFeaturedImageSrc(cms, collectedResourceUri, 250);
            } catch (Exception e) {
                //
                imgSrc = "/no/images/ansatte/person.png";
                //noImgAnchorStyle = " display: inline-block; font-size: 50px; margin: 0; padding: 0; text-align: center; vertical-align: bottom; width: 100%;";
            }
            %>
            <li style="display:inline-block; width:12%; border:none; padding:0; margin:0;">
                <a href="<%= cms.link(collectedResourceUri) %>" data-tooltip="<%= tooltipText %>" style="display:block; position:relative;<%= noImgAnchorStyle %>">
                    <% if (imgSrc != null) { %>
                    <img src="<%= cms.link(imgSrc) %>" alt="<%= altText %>" style="display:block;" />
                    <% } else { %>
                    <i class="icon-user" style="position:absolute; top:0; right:0; bottom:0; left:0; margin: 0 -0.2em;"></i>
                    <% }%>
                </a>
            </li>
            <%
        } // while
        %>
        </ul>
        </div>
        <%
    } // if    
}
catch (Exception e) {
    out.print("Error listing new faces: " + e.getMessage());
}
%>