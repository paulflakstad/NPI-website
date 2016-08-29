<%-- 
    Document   : newslist-advanced-filters - Major update of newslist.jsp/list.jsp. Also meant to replace newslist-list-style.jsp (as of March 2014).
    Created on : Dec 31, 2012, 1:15:13 PM
    Author     : Paul-Inge Flakstad, Norwegian Polar Institute
--%><%-- 
    Document   : newslist.jsp - uses the "TeaserImage" (as used in the new newsbulletin type, which has "Paragraph" sections)
    Created on : 04.jun.2010, 13:41:52
    Author     : Paul-Inge Flakstad, Norwegian Polar Institute
--%>
<%@ page import="no.npolar.util.*,
                 no.npolar.util.exception.MalformedPropertyValueException,
                 org.apache.commons.lang.StringEscapeUtils,
                 org.opencms.file.CmsObject,
                 org.opencms.file.CmsResource,
                 org.opencms.file.types.CmsResourceTypeFolder,
                 org.opencms.file.CmsResourceFilter,
                 org.opencms.loader.CmsImageScaler,
                 org.opencms.main.OpenCms,
                 org.opencms.main.CmsException,
                 org.opencms.jsp.I_CmsXmlContentContainer,
                 org.opencms.relations.CmsCategory,
                 org.opencms.relations.CmsCategoryService,
                 org.opencms.util.CmsStringUtil,
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
    public String getItemHtml(CmsAgent cms, 
                                String fileName,
                                String title,
                                String teaser,
                                String imageLink,
                                String published,
                                String dateFormat,
                                boolean displayDescription, 
                                boolean displayTimestamp,
                                boolean displayLabel,
                                boolean asPortalPageCard,
                                Locale locale) throws ServletException {
        final SimpleDateFormat DATE_FORMAT_ISO = new SimpleDateFormat("yyyy-MM-dd", locale);
        final String TIMESTAMP = "<time class=\"timestamp\" datetime=\"" + DATE_FORMAT_ISO.format(new Date(Long.valueOf(published).longValue())) + "\">" 
                                    + CmsAgent.formatDate(published, dateFormat, locale) 
                                + "</time>";
        String html = "";
        if (!asPortalPageCard) {
            html += "<li class=\"news\">";

            if (displayTimestamp)
                html += TIMESTAMP;

            html += "<a href=\"" + cms.link(fileName) + "\">";

            if (imageLink != null) {
                html += "<span class=\"media thumb pull-right\">";
                html += imageLink;
                html += "</span>";
            }

            html += "<h3 class=\"news-title\">" + title + "</h3>";

            html += "</a>";

            //html += "<div class=\"news-list-itemtext\">";
            if (displayDescription) {
                html += "<p>";
                html += teaser + "</p>";
            }
            //html += "</div><!-- .news-list-itemtext -->";

            html += "</li><!-- .news -->";
        } 
        else { // Portal page card
            /*try {
                teaser = CmsStringUtil.trimToSize(teaser, 175, "&hellip;");
            } catch (Exception e) {}*/
            html += "<div class=\"span1 featured-box\">";
                html += "<a class=\"featured-link\" href=\"" + cms.link(fileName) + "\">";
                    html += "<div class=\"card\">";
                        if (imageLink != null) {
                            html += imageLink;
                        }
                        html += "<h3 class=\"card-heading\">" + title + "</h3>";
                        if (displayTimestamp)
                            html += TIMESTAMP;
                        if (displayDescription)
                            html += "<p itemprop=\"description\">" + teaser + "</p>";
                        if (displayLabel) {
                            String label = "";
                            try {
                                label = cms.getCmsObject().readPropertyObject(fileName, "Title.addon", true).getValue("");
                            } catch (Exception ignore) {}
                            html += "<span class=\"card-label tag\">" + label + "</span>";
                        }
                    html += "</div>";
                html += "</a>";
            html += "</div>";
        }
        return html;
        
        /*
        String html = "<li class=\"news\">";
        if (imageLink != null) {
            html += "<span class=\"media thumb pull-right\">";
            html += imageLink;
            html += "</span>";
        }
        html += "<div class=\"news-list-itemtext\">";
        if (displayTimestamp)
            html += "<time class=\"timestamp\" datetime=\"" + DATE_FORMAT_ISO.format(new Date(Long.valueOf(published).longValue())) + "\">" 
                        + CmsAgent.formatDate(published, dateFormat, locale) 
                    + "</time>";
        html += "<h3 class=\"news-title\"><a href=\"" + cms.link(fileName) + "\">" + title + "</a></h3>";
        if (displayDescription) {
            html += "<p>";
            html += teaser + "</p>";
        }
        html += "</div><!-- .news-list-itemtext -->";
        html += "</li><!-- .news -->";
        return html;
        */
        
        /*String html = "<div class=\"news\">";
        if (imageLink != null) {
            html += "<span class=\"media thumb pull-right\">";
            html += imageLink;
            html += "</span>";
        }
        html += "<div class=\"news-list-itemtext\">";
        html += "<h3><a href=\"" + cms.link(fileName) + "\">" + title + "</a></h3>";
        if (displayTimestamp)
            html += "<time class=\"timestamp\" datetime=\"" + DATE_FORMAT_ISO.format(new Date(Long.valueOf(published).longValue())) + "\">" 
                        + CmsAgent.formatDate(published, dateFormat, locale) 
                    + "</time>";
        if (displayDescription) {
            html += "<p>";
            html += teaser + "</p>";
        }
        html += "</div><!-- .news-list-itemtext -->";
        html += "</div><!-- .news -->";
        return html;*/
    }

    public String getImageLinkHtml(CmsAgent cms, String imagePath, int imageWidth, String fileName) 
            throws CmsException, MalformedPropertyValueException, JspException {
        //if (imageContainer.hasMoreContent()) { // "if" instead of "while" => don't loop over all images, just get the first one (if any)
        if (CmsAgent.elementExists(imagePath)) {
            /*
            String imageLink = null;
            //String imagePath = cms.contentshow(imageContainer, "URI");
            
            // Exact size: Calculate new height based on given width
            int imageHeight = cms.calculateNewImageHeight(imageWidth, imagePath);
            // Crop: Calculate new height based on a ratio
            //int imageHeight = (int)(((double)imageWidth / 16) * 9); // Ratio is 16:9
            
            
            //CmsImageProcessor imgPro = new CmsImageProcessor("__scale=t:3,q:100,w:".concat(String.valueOf(imageWidth)).concat("h:").concat(String.valueOf(imageHeight)));
            //CmsImageProcessor imgPro = new CmsImageProcessor(); // Not needed?
            CmsImageScaler imgPro = new CmsImageScaler();
            imgPro.setType(4); // Exact size
            //imgPro.setType(2); // Crop
            imgPro.setQuality(100);
            imgPro.setWidth(imageWidth);
            imgPro.setHeight(imageHeight);
            //*/
            /*
            imageLink = "<a href=\"" + cms.link(fileName) + "\">"
                            + "<img src=\"" + CmsAgent.getTagAttributesAsMap(cms.img(imagePath, imgPro.getReScaler(imgPro), null, false)).get("src") + "\""
                            //" alt=\"" + cms.contentshow(imageContainer, "Title") + "\" />" +
                            + " alt=\"\" />"
                        + "</a>";
            return imageLink;
            //*/
            try { 
                return ImageUtil.getImage(cms, imagePath, "", ImageUtil.CROP_RATIO_16_9, imageWidth, 50, ImageUtil.SIZE_S, 90, "320px"); 
            } catch (Exception e) {
                return "<!-- ERROR producing img tag: " + e.getMessage() + " -->";
            }
            /*
            return "<img"
                    + " src=\"" + CmsAgent.getTagAttributesAsMap(cms.img(imagePath, imgPro.getReScaler(imgPro), null, false)).get("src") + "\""
                    + " alt=\"\" />";*/
        }
        return "";
    }
    
    public void printNewsBulletin(JspWriter out, 
                                    CmsAgent cms,
                                    String fileName,
                                    I_CmsXmlContentContainer newsBulletin,
                                    int imageWidth,
                                    int visitedFiles,
                                    int itemsWithImages,
                                    String dateFormat,
                                    boolean displayDescription, 
                                    boolean displayTimestamp,
                                    boolean displayLabel,
                                    boolean asPortalPageCard,
                                    Locale locale) throws ServletException, CmsException, IOException {
        String title       = cms.contentshow(newsBulletin, "Title");
        String published   = cms.contentshow(newsBulletin, "Published");
        String teaser      = cms.contentshow(newsBulletin, "Teaser");
        String imageLink   = null;
        

        if (visitedFiles < itemsWithImages) {
            try {
                //out.println("<h5>Image path was '" + cms.contentshow(newsBulletin, "TeaserImage") + "', imageLink is " + getImageLinkHtml(cms, cms.contentshow(newsBulletin, "TeaserImage"), imageWidth, fileName) + "</h5>");
                /*
                I_CmsXmlContentContainer imageContainer = cms.contentloop(newsBulletin, "TeaserImage");
                imageLink = getImageLinkHtml(cms, imageContainer, imageWidth, fileName);
                //*/
                imageLink = getImageLinkHtml(cms, cms.contentshow(newsBulletin, "TeaserImage"), imageWidth, fileName);
            }
            catch (Exception npe) {
                imageLink = "EXCEPTION";
                //throw new ServletException("Exception while reading teaser image in news bulletin file '" + fileName + "': " + npe.getMessage());
            }
            
        } // if (newsbulletin should have image)

        // HTML OUTPUT            
        out.println(getItemHtml(cms, fileName, title, teaser, imageLink, published, dateFormat, displayDescription, displayTimestamp, displayLabel, asPortalPageCard, locale));
    }
    
    /**
    * Recursive method to prints a hierarchical category tree. 
    * @param cmso An initialized CmsObject
    * @param category The root node for the tree
    * @param categoryReferencePath The category reference path, used to resolve categories
    * @param hideRootElement If set to true, the topmost (root) element of the tree will not be displayed in the filter tree
    * @param requestFileUri The URI of the request file, used in construction of links
    * @param paramFilterCategories A list of category identifiers (paths) present in the request parameters, used to determine "active" links
    * @param out The writer to use when generating HTML output
    */
    public void printCatFilterTree(CmsAgent cms, 
                                    CmsCategory category, 
                                    String categoryReferencePath, 
                                    boolean hideRootElement, 
                                    String hiddenCategoryPath,
                                    String requestFileUri, 
                                    List paramFilterCategories, 
                                    JspWriter out) throws org.opencms.main.CmsException, java.io.IOException {
        // Get any timespan parameter(s) existing in the request
        String timespanParam = getTimespanParam(cms);
        // Get the CmsObject
        CmsObject cmso = cms.getCmsObject();
        // Get the category service instance
        CmsCategoryService cs = CmsCategoryService.getInstance();
        // Parameter categories string
        String paramCatString = "";
        // Determine whether or not the current category was present in the request parameters (meaning we're currently filtering by this category)
        boolean categoryInParameter = false;
        if (paramFilterCategories != null) {
            if (paramFilterCategories.contains(category.getPath())) {
                categoryInParameter = true;
            }
            // Create the parameter categories string
            Iterator<String> iParamFilterCategories = paramFilterCategories.iterator();
            while (iParamFilterCategories.hasNext()) {
                String paramFilterCategory = iParamFilterCategories.next();
                paramCatString += (paramCatString.isEmpty() ? "" : "&amp;") + "cat=" + paramFilterCategory;
            }
        }
        // Start the list, but only if the root element is not hidden
        if (!hideRootElement) {
            String categoryLinkParam = "";
            if (!categoryInParameter)
                categoryLinkParam += "cat=" + category.getPath() + (paramCatString.isEmpty() ? "" : "&amp;") + paramCatString;
            else {
                categoryLinkParam += paramCatString.replace("cat="+category.getPath(), "").replace("&amp;&amp;", "&amp;");
            }
            if (timespanParam != null)
                categoryLinkParam += (categoryLinkParam.isEmpty() || categoryLinkParam.endsWith("&amp;") ? "" : "&amp;") + timespanParam;
            
            out.println("<ul>");
            out.println("<li>" +
                        "<a href=\"" + requestFileUri + (categoryLinkParam.isEmpty() ? "" : "?" + categoryLinkParam) + "\""
                            + (categoryInParameter ? " style=\"font-weight:bold;\"" : "") 
                            + ">" 
                            + category.getTitle()
                            + (categoryInParameter ? " <span class=\"remove-filter\" style=\"background:red; border-radius:3px; color:white; padding:0 0.3em;\">X</span>" : "")
                        + "</a>");
        }
        // Get a list of any sub-categories of the category
        List subCats = cs.readCategories(cmso, category.getPath(), false, categoryReferencePath);
        // For each sub-category, call this method
        if (subCats != null) {
            if (!subCats.isEmpty()) {
                Iterator iSub = subCats.iterator();
                while (iSub.hasNext()) {
                    category = (CmsCategory)iSub.next();
                    if (!category.getRootPath().equals(hiddenCategoryPath)) {
                        printCatFilterTree(cms, category, categoryReferencePath, false, hiddenCategoryPath, requestFileUri, paramFilterCategories, out);
                    }
                }
            }
        }
        // End the list, but only if the root element is not hidden
        if (!hideRootElement) {
            out.println("</li>");
            out.println("</ul>");
        }
    }
    
    public String getTimespanParam(CmsAgent cms) {
        String paramYear = cms.getRequest().getParameter("y");
        if (paramYear != null && !paramYear.isEmpty())
            return "y=" + paramYear;
        return null;
    }

    public boolean categoryMatch(CmsAgent cms, CmsResource r, List<String> matchCategories) throws CmsException {
        CmsObject cmso = cms.getCmsObject();
        CmsCategoryService cs = CmsCategoryService.getInstance();
        // Get active filter categories
        List paramCategoryFilters = new ArrayList(); 
        try {
            paramCategoryFilters = Arrays.asList(cms.getRequest().getParameterValues("cat"));
        } catch (Exception e) { }
        
        // Add given categories
        if (matchCategories != null)
            paramCategoryFilters.addAll(matchCategories);
        
        if (paramCategoryFilters.isEmpty())
            return true; // No category filters set, this is by default a match
        
        // Category filter(s) present, need to check against the resource's assigned categories
        List<String> assignedCatPaths = new ArrayList<String>(); // Will hold the assigned category paths (same format as the parameter-defined categories)
        // Get the resource's assigned categories
        List<CmsCategory> assignedCategories = cs.readResourceCategories(cmso, cmso.getSitePath(r));
        Iterator<CmsCategory> iAssCat = assignedCategories.iterator();
        while (iAssCat.hasNext()) {
            CmsCategory assignedCategory = iAssCat.next();
            assignedCatPaths.add(assignedCategory.getPath());
        }
        if (assignedCatPaths.containsAll(paramCategoryFilters))
            return true;
        return false;
    }
%><%
CmsAgent cms                = new CmsAgent(pageContext, request, response);
CmsObject cmso              = cms.getCmsObject();
final CmsObject CMSO        = OpenCms.initCmsObject(cmso);
Locale locale               = cms.getRequestContext().getLocale();
String requestFileUri       = cms.getRequestContext().getUri();
CmsCategoryService cs       = CmsCategoryService.getInstance();

HttpSession sess            = null;
String dynamicContainer     = "";
String overrideHeading      = "";

final boolean DEBUG         = false;

// Determine if the list is included from another file
boolean isIncluded          = cms.getRequest().getParameter("resourceUri") != null;
if (isIncluded) {
    // Get container description (if any)
    sess = cms.getRequest().getSession();
    dynamicContainer = sess.getAttribute("dynamic_container") != null ? (String)sess.getAttribute("dynamic_container") : "";
    overrideHeading = sess.getAttribute("override_heading") != null ? (String)sess.getAttribute("override_heading") : "";
}
// Determine the URI of the list resource
String resourceUri          = !isIncluded ? requestFileUri : cms.getRequest().getParameter("resourceUri");
// reverseCollector was intended used as a trigger for ascending sort order (which has no collector)
boolean reverseCollector    = false;

// This is specific to portal pages. Portal pages ("np_portalpage") are a 
// commonly used container page type. They will often includes various news 
// lists.
boolean itemsAsPortalPageCards = false;//OpenCms.getResourceManager().getResourceType("np_portalpage").getTypeId() == cmso.readResource(requestFileUri).getTypeId();
if (isIncluded && dynamicContainer.equals("portal_page_section")) {
    // This parameter was set by a portal page, indicating the list should appear as a section of the portal page.
    itemsAsPortalPageCards = true;
}
        
// If the list is not included from another file, include the "master" template top
if (!isIncluded) {
    cms.includeTemplateTop();
    //out.println("<div class=\"twocol\">");
    out.println("<article class=\"main-content\">");
}
// Set to "true" here. If neglected, enabling direct edit on list item won't work.
cms.editable(false);


// Constants
//final String DEFAULT_ROOT_CATEGORY_PATH = null;
final String DEFAULT_CATEGORY_REFERENCE_PATH = "/";
final int DEFAULT_IMAGE_WIDTH = 480;
final String PARAM_NAME_CATEGORY = "cat";
//final String CAT_ROOT       = "/" + locale.toString() + "/";
//final int IMG_WIDTH_XS      = Integer.parseInt(cms.getCmsObject().readPropertyObject(resourceUri, "image.size.xs", true).getValue("100"));
//final int IMG_WIDTH_S       = Integer.parseInt(cms.getCmsObject().readPropertyObject(resourceUri, "image.size.s", true).getValue("140"));
final int TYPE_ID_NEWSBULL  = OpenCms.getResourceManager().getResourceType("newsbulletin").getTypeId(); // The ID for resource type "newsbulletin" (316)
final String DATE_FORMAT    = cms.labelUnicode("label.for.newsbulletin.dateformat");
//final String JS_KEY_REGULAR = "/nothing.js";
final String HEADING_TYPE   = isIncluded ? "h2" : "h1";

final String LABEL_READ_MORE= cms.labelUnicode("label.np.readmore");
final String LABEL_VIEW = cms.labelUnicode("label.for.newsbulletin.filter.view");
final String LABEL_LATEST = cms.labelUnicode("label.for.newsbulletin.latest");
final String LABEL_LATEST_NEWS = cms.labelUnicode("label.for.newsbulletin.latestnews");
final String LABEL_FILTER_YEAR_LABEL = cms.labelUnicode("label.for.newsbulletin.filter.yearlabel");
final String LABEL_FILTER_REMOVE = cms.labelUnicode("label.for.newsbulletin.filter.remove");
final String LABEL_FILTER_ALL = cms.labelUnicode("label.for.newsbulletin.filter.all");

/*
final int TOP = 1;
final int BOTTOM = 0;
int stickyPlacement = BOTTOM;
//*/

// Help and config variables
int i                       = 0;
int visitedFiles            = 0;
int maxEntries              = -1;
int itemsWithImages         = -1;
int itemImageWidth          = -1;
//String listType             = null;
boolean itemsAsCards        = false;
String listTitle            = null;
String listText             = null;
String listFolder           = null;
String category             = null;
List<String> matchCategories= new ArrayList<String>();
String dateFormat           = null;
String sortOrder            = null;
String moreLink             = null;
String moreLinkTitle        = null;
String moreLinkHtml         = null;      
boolean showCatFilters      = false;
boolean moreLinkNewWindow   = false;
boolean editableItems       = false;
boolean subTree             = false;
boolean displayRangeSelect  = true;
boolean displayDescription  = false;
boolean displayTimestamp    = false;
boolean displayLabel        = false;
ArrayList stickies          = new ArrayList(0);

// ToDo: Standardize category filtering, see 
// no.npolar.common.eventcalendar.ResourceCategoriesFilter.java
// (... which should really be moved to the util package)
String filterHeading = null;
String filterCategoryReferencePath = DEFAULT_CATEGORY_REFERENCE_PATH;
String filterRootCategoryPath = null;
String filterPreSelectedCategoryPath = null;
String filterHiddenCategoryPath = null;
boolean filterHideRootElement = false;
boolean filterSubCategories = false;
boolean filterMultiCategory = false;

/*
List paramFilterCategories  = new ArrayList(0);
if (request.getParameterValues(PARAM_NAME_CAT) != null) {
    paramFilterCategories = Arrays.asList(request.getParameterValues(PARAM_NAME_CAT));
}
*/



// Load the list file, which is the list configuration
I_CmsXmlContentContainer configuration = cms.contentload("singleFile", resourceUri, true); 
// Read the configuration
while (configuration.hasMoreContent()) {
    //listType            = cms.contentshow(configuration, "Type");
    listTitle           = cms.contentshow(configuration, "Title");
    listText            = cms.contentshow(configuration, "Text");
    listFolder          = cms.contentshow(configuration, "ListFolder");
    displayRangeSelect  = Boolean.valueOf(cms.contentshow(configuration, "DisplayRangeSelect")).booleanValue();
    //category            = cms.contentshow(configuration, "Category");
    // Store all "match category" (initially active filters) categories
    I_CmsXmlContentContainer matchCat = cms.contentloop(configuration, "Category");
    while (matchCat.hasMoreContent()) {
        if (CmsAgent.elementExists(cms.contentshow(matchCat))) {
            CmsCategory catTemp = cs.getCategory(cmso, cms.contentshow(matchCat));
            matchCategories.add(cs.readCategory(cmso, catTemp.getPath(), "/"+locale.toString()+"/").getPath());
            //matchCategories.add(cs.readCategory(cmso, cms.contentshow(matchCat), filterCategoryReferencePath).getPath()); // add(cms.contentshow(matchCat));
            if (DEBUG) { out.println("<!-- added match category: " + matchCategories.get(matchCategories.size()-1) + " -->"); }
        }
    }
    showCatFilters      = Boolean.valueOf(cms.contentshow(configuration, "ShowCategoryFilters")).booleanValue();
    subTree             = Boolean.valueOf(cms.contentshow(configuration, "SubTree")).booleanValue();
    displayDescription  = Boolean.valueOf(cms.contentshow(configuration, "DisplayDescription")).booleanValue();
    displayTimestamp    = Boolean.valueOf(cms.contentshow(configuration, "DisplayTimestamp")).booleanValue();
    displayLabel        = Boolean.valueOf(cms.contentshow(configuration, "DisplayLabel")).booleanValue();
    //itemsAsPortalPageCards = Boolean.valueOf(cms.contentshow(configuration, "ItemsAsPortalPageCards")).booleanValue();
    itemsAsCards        = Boolean.valueOf(cms.contentshow(configuration, "ItemsAsPortalPageCards")).booleanValue();
    sortOrder           = cms.contentshow(configuration, "SortOrder");
    maxEntries          = Integer.valueOf(cms.contentshow(configuration, "MaxEntries")).intValue();
    itemsWithImages     = Integer.valueOf(cms.contentshow(configuration, "ItemsWithImages")).intValue();
    try {
        itemImageWidth  = Integer.valueOf(cms.contentshow(configuration, "ItemImageWidth")).intValue(); 
    } catch (Exception e) {
        itemImageWidth = DEFAULT_IMAGE_WIDTH;//IMG_WIDTH_XS;
    }
    editableItems   = Boolean.valueOf(cms.contentshow(configuration, "EditableItems")).booleanValue();
    dateFormat      = cms.contentshow(configuration, "DateFormat");
    //stickyPlacement = Integer.valueOf(cms.contentshow(configuration, "ItemImageWidth")).intValue();

    // Get the sticky file paths (items that have been manually placed in the list)
    I_CmsXmlContentContainer sticky = cms.contentloop(configuration, "Sticky");
    while (sticky.hasMoreContent()) {
        stickies.add(cms.contentshow(sticky)); // Add the URI to the list of stickies
    }
    
    I_CmsXmlContentContainer nestedLink = cms.contentloop(configuration, "MoreLink");
    if (nestedLink.hasMoreContent()) { // There should be only one, so use "if" instead of "while"
        moreLink = cms.contentshow(nestedLink, "URI");
        moreLinkTitle = cms.contentshow(nestedLink, "Title");
        moreLinkNewWindow = Boolean.valueOf(cms.contentshow(nestedLink, "NewWindow")).booleanValue();
        if (CmsAgent.elementExists(moreLink)) {
            moreLink = StringEscapeUtils.escapeHtml(moreLink);
            moreLinkHtml = "<a href=\"" + cms.link(moreLink) + "\"" 
                            + (moreLinkNewWindow ? " target=\"_blank\"" : "") 
                            + " class=\"cta more" + (itemsAsPortalPageCards ? "" : " news-list-more") + "\""
                            + ">" + 
                                (CmsAgent.elementExists(moreLinkTitle) ? moreLinkTitle : LABEL_READ_MORE) 
                            + "</a>";
        }
    }
    
    I_CmsXmlContentContainer filter = cms.contentloop(configuration, "CategoryFilter");
    while (filter.hasMoreContent()) {
        filterHeading = cms.contentshow(filter, "Heading");
        filterCategoryReferencePath = cms.contentshow(filter, "CategoryReferencePath");
        filterRootCategoryPath = cms.contentshow(filter, "RootCategory");
        filterHideRootElement = Boolean.valueOf(cms.contentshow(filter, "HideRootElement")).booleanValue();
        filterPreSelectedCategoryPath = cms.contentshow(filter, "PreSelectedCategory");
        filterHiddenCategoryPath = cms.contentshow(filter, "HiddenCategory");
        //out.println("<!-- ########## read filterHiddenCategoryPath '" + filterHiddenCategoryPath + " ############# -->");
        filterSubCategories = Boolean.valueOf(cms.contentshow(filter, "SubCategories")).booleanValue();
        //out.println("<!-- ########## value of 'filterSubCategories': " + String.valueOf(filterSubCategories) + " ########## -->");
        filterMultiCategory = Boolean.valueOf(cms.contentshow(filter, "MultiCategory")).booleanValue();
    }
}

// Modify configuration values, if needed
if (!CmsAgent.elementExists(dateFormat))
    dateFormat = DATE_FORMAT;
// If no folder has been specified, use the list file's own parent folder as the list folder
if (!CmsAgent.elementExists(listFolder) || listFolder.trim().length() == 0)
    listFolder = CmsResource.getParentFolder(resourceUri);
if (itemsWithImages == -1)
    itemsWithImages = Integer.MAX_VALUE;
// In case no root category was specified, fallback to using the default root path
if (CmsAgent.elementExists(filterCategoryReferencePath) && !CmsAgent.elementExists(filterRootCategoryPath)) {
    try {
        filterRootCategoryPath = cs.readCategory(cmso, cms.property("category", "search"), filterCategoryReferencePath).getRootPath();
    } catch (Exception e) {
        filterRootCategoryPath = null;
    }
    //filterRootCategoryPath = null;
    //filterRootCategoryPath = DEFAULT_ROOT_CATEGORY_PATH;
}
if (sortOrder.equals("Path"))
    sortOrder = "";
else if (sortOrder.equals("PriorityDate"))
    reverseCollector = true;

// Construct the collector type name
String collector = "allIn" + (subTree ? "SubTree" : "Folder") + sortOrder;//"PriorityDateDesc";
// Determine how many items should be "auto-collected" (how many items are NOT stickies)
int numAutoCollectedItems = maxEntries - stickies.size();

// Store any categories present as request parameters
List paramFilterCategories  = new ArrayList(0);
if (request.getParameterValues(PARAM_NAME_CATEGORY) != null) {
    paramFilterCategories = Arrays.asList(request.getParameterValues(PARAM_NAME_CATEGORY));
}
// If there were none, check if the "pre-selected category" option was used 
// (The "pre-selected category" option should be considered ONLY when there are no "regular" category parameters present)
else if (CmsAgent.elementExists(filterPreSelectedCategoryPath)) {
    paramFilterCategories.add(cs.getCategory(cmso, filterPreSelectedCategoryPath).getPath());
}





// Year filters
int paramYear = -1;
try {
    paramYear = Integer.valueOf(request.getParameter("y")).intValue();
} catch (Exception e) {
    // Retain initial value
}







/*--------------------- LIST CONTENT OUTPUT -------------------------*/
String headAndDescr = "";
if (!overrideHeading.isEmpty()) {
    if (overrideHeading.equalsIgnoreCase("none"))
        listTitle = "";
    else
        listTitle = overrideHeading;
}
if (CmsAgent.elementExists(listTitle)) {
    headAndDescr += "\n<" + HEADING_TYPE + (itemsAsPortalPageCards || itemsAsCards ? " class=\"section-heading bluebar-dark\"" : "") + ">" 
                        + listTitle 
                    + "</" + HEADING_TYPE + ">";
}
if (CmsAgent.elementExists(listText)) {
    headAndDescr += "\n" + listText;
}
// Print the list title and intro text
// (But not if we're generating each list item as a "card" for a portal page)
if (!headAndDescr.isEmpty() && !(itemsAsPortalPageCards || itemsAsCards)) {
    out.println(headAndDescr);
}





//
// List of news items
//
I_CmsXmlContentContainer newsItems;  // Container
String fileName;

try {
    /*if (CmsAgent.elementExists(category)) { // Category filtering
        String param = "resource=" + listFolder + "|" +
                       "resourceType=newsbulletin|" + 
                       "categoryTypes=" + CmsCategoryService.getInstance().readCategory(cmso, CmsResource.getName(category), "/no/").getPath() + "|" +
                       "subTree=" + Boolean.toString(subTree) + "|" +
                       "sortBy=date|" +
                       "sortAsc=false";
        out.println("<h5>category was: '" + category + "'</h5>");
        out.println("<h5>parameterString was: '" + param + "'</h5>");
        newsBulletin = cms.contentload("allKeyValuePairFiltered", param, editableItems);
    }*/

    // Remove any category both in parameter and in the config, to avoid duplicate category filter
    //paramFilterCategories.remove(category);
    paramFilterCategories.removeAll(matchCategories);

    //
    // Handle case "filtering on a category"
    //
    /*
    if (!paramFilterCategories.isEmpty()            // Parameter-defined
            || CmsAgent.elementExists(category)) {  // Pre-selected category, defined in the config file
        // Create a string that can be used for the collector parameter 'categoryTypes'
        String categoryTypes = "";
        if (CmsAgent.elementExists(category)) {
            //categoryTypes = CmsCategoryService.getInstance().readCategory(cmso, CmsResource.getName(category), "/no/").getPath();
            //categoryTypes = cs.readCategory(cmso, CmsResource.getName(category), CAT_ROOT).getPath();

            //categoryTypes = cs.readCategory(cmso, CmsResource.getName(category), filterRootCategoryPath).getPath();
            //final String KEYWORD_CATEGORIES = "/_categories/";
            //CmsCategory catTemp = cs.readCategory(cmso, cms.getRequestContext().removeSiteRoot(category), "/"+locale.toString()+"/");
            //CmsCategory catTemp = cs.getCategory(cmso, cms.getRequestContext().removeSiteRoot(category));
            CmsCategory catTemp = cs.getCategory(cmso, category);
            //out.println("<!-- cat.getPath() = '" + catTemp.getPath() + "' -->");
            //out.println("<!-- cat.getBasePath() = '" + catTemp.getBasePath() + "' -->");
            //out.println("<!-- cat.getName() = '" + catTemp.getName() + "' -->");
            categoryTypes = cs.readCategory(cmso, catTemp.getPath(), "/"+locale.toString()+"/").getPath();
            //categoryTypes = cs.readCategory(cmso, catTemp.getPath(), catTemp.getBasePath()).getPath();
            //categoryTypes = cs.readCategory(cmso, category, cms.getRequestContext().getFolderUri()).getPath();
        }

        Iterator iCat = paramFilterCategories.iterator();
        if (iCat.hasNext()) {
            if (categoryTypes.length() > 0)
                categoryTypes += ","; // Add an initial comma, if the string already contains any filter(s)
            while (iCat.hasNext()) {
                String catStr = (String)iCat.next(); // Get the category root path
                CmsCategory cat = cs.readCategory(cmso, catStr, filterCategoryReferencePath);
                String catPath = cat.getPath();
                categoryTypes += catPath;
                //categoryTypes += cs.readCategory(cmso, CmsResource.getName(cat), CAT_ROOT).getPath();
                //categoryTypes += cs.readCategory(cmso, CmsResource.getName(catStr), filterRootCategoryPath).getPath();
                if (iCat.hasNext())
                    categoryTypes += ",";
            }
        }
        if (categoryTypes.endsWith(",")) {
            categoryTypes = categoryTypes.substring(0, categoryTypes.length() - 1);
        }

        String param = "resource=" + listFolder + "|" +
                       "resourceType=newsbulletin|" + 
                       "categoryTypes=" + categoryTypes + "|" +
                       "subTree=" + Boolean.toString(subTree) + "|" +
                       "sortBy=date|" +
                       "sortAsc=true";
        //out.println("<h5>category was: '" + category + "'</h5>");
        //out.println("<h5>parameterString was: '" + param + "'</h5>");
        newsItems = cms.contentload("allKeyValuePairFiltered", param, editableItems);

        // Comparator used for sorting.
        // We must sort _MANUALLY_ because the "sortBy=date" is no good (it  
        // sorts by attribute.datereleased, not collector.date)
        final Comparator<CmsResource> DATE_ORDER_DESC = new Comparator<CmsResource>() {
                                                            //private CmsAgent cms = new CmsAgent(pageContext, request, response);
                                                            public int compare(CmsResource one, CmsResource another) {
                                                                String oneDate = "";
                                                                String anotherDate = "";
                                                                try {
                                                                    oneDate = CMSO.readPropertyObject(one, "collector.date", false).getValue("1");
                                                                    anotherDate = CMSO.readPropertyObject(another, "collector.date", false).getValue("1");
                                                                } catch (Exception e) {
                                                                    oneDate = "1";
                                                                    anotherDate = "1";
                                                                }
                                                                return anotherDate.compareTo(oneDate);
                                                            }
                                                        };

        final Comparator<CmsResource> DATE_ORDER = new Comparator<CmsResource>() {
                                                            //private CmsAgent cms = new CmsAgent(pageContext, request, response);
                                                            public int compare(CmsResource one, CmsResource another) {
                                                                String oneDate = "";
                                                                String anotherDate = "";
                                                                try {
                                                                    oneDate = CMSO.readPropertyObject(one, "collector.date", false).getValue("1");
                                                                    anotherDate = CMSO.readPropertyObject(another, "collector.date", false).getValue("1");
                                                                } catch (Exception e) {
                                                                    oneDate = "1";
                                                                    anotherDate = "1";
                                                                }
                                                                return oneDate.compareTo(anotherDate);
                                                            }
                                                        };
        // Do the manual sort
        Collections.sort(newsItems.getCollectorResult(), DATE_ORDER_DESC);

    }
    //*/
    
    //
    // Handle case "No category filtering":
    //
    //else {
        // Get all the news bulletins in the given folder
        newsItems = cms.contentload(collector, listFolder.concat("|").concat(Integer.toString(TYPE_ID_NEWSBULL)), editableItems);
    //}
    
    
    long start = System.currentTimeMillis();
    // Loop all news items to get a complete list of available years
    List availableYears = new ArrayList();
    List<CmsResource> allNews = cmso.readResources(listFolder, CmsResourceFilter.DEFAULT_FILES.addRequireType(OpenCms.getResourceManager().getResourceType("newsbulletin").getTypeId()), subTree);
    
    
    Date limitLow = new GregorianCalendar(0, Calendar.JANUARY, 1).getTime();
    Date limitHigh = new GregorianCalendar(9999, Calendar.JANUARY, 1).getTime();
    if (paramYear > 0) {
        limitLow = new GregorianCalendar(paramYear, Calendar.JANUARY, 1).getTime();
        limitHigh = new GregorianCalendar(paramYear+1, Calendar.JANUARY, 1).getTime();
    }
    
    //Iterator iNewsItems = newsItems.getCollectorResult().iterator();
    Iterator<CmsResource> iNewsItems = allNews.iterator();
    List<CmsResource> newsItemsToRemove = new ArrayList<CmsResource>();
    while (iNewsItems.hasNext()) {
        // Get the news item
        CmsResource newsItem = iNewsItems.next();
        // Get the timestamp from the news item
        Date newsDate = new Date(Long.valueOf(cmso.readPropertyObject(newsItem, "collector.date", false).getValue("1")));
        
        // Get the year for this item (using a calendar object)
        GregorianCalendar newsDateCal = new GregorianCalendar();
        newsDateCal.setTime(newsDate);
        String newsDateYear = Integer.toString(newsDateCal.get(Calendar.YEAR));
        
        // Add this item's publish year to list of available years, if it's not there already
        if (!availableYears.contains(newsDateYear)) {
            availableYears.add(newsDateYear);
        }
        
        // Remove current item if:
        // - it wasn't published within the specified year range, OR ...
        // - a category was set, and this item didn't match it
        if (newsDate.before(limitLow) || newsDate.after(limitHigh) || !categoryMatch(cms, newsItem, matchCategories)) {
            //iNewsItems.remove();
            newsItemsToRemove.add(newsItem);
            /*
            List<CmsCategory> assCat = cs.readResourceCategories(cmso, cmso.getSitePath(newsItem));
            if (!assCat.isEmpty()) {
                Iterator<CmsCategory> iAssCat = assCat.iterator();
                while (iAssCat.hasNext()) {
                    CmsCategory assignedCategory = iAssCat.next();
                    out.println("<!-- Category path: " + assignedCategory.getPath() + " -->");
                }
            }
            */
        }
    }
    
    // Remove all news items out of range
    newsItems.getCollectorResult().removeAll(newsItemsToRemove);
    
    // Sort lists of years
    Collections.sort(availableYears);
    Collections.reverse(availableYears);
    
    
    //
    // Timespan filter(s)
    //
    if (displayRangeSelect) {
        out.println("<div>");
        out.println("<form action=\"#\" method=\"get\">");
        out.println("<fieldset style=\"border:1px solid #ddd; background:#eee; padding:1em; margin:1em 0;\">");
        out.println("<legend>" + LABEL_VIEW + ":</legend>");
        out.println("<select name=\"y\" onchange=\"submit()\">");
        out.println("<option value=\"-1\">" + LABEL_LATEST.replace("{0}", Integer.toString(maxEntries)) + "</option>");
        Iterator iYears = availableYears.iterator();
        while (iYears.hasNext()) {
            String year = (String)iYears.next();
            out.println("<option value=\"" + year + "\"" + (year.equals(String.valueOf(paramYear)) ? " selected=\"selected\"" : "") + ">" + LABEL_FILTER_YEAR_LABEL + " " + year + "</option>");
        }
        out.println("<option value=\"0\"" + (paramYear == 0 ? " selected=\"selected\"" : "") + ">" + LABEL_FILTER_ALL + "</option>");
        out.println("</select>");
        out.println("</fieldset>");
        // Make sure we also include the category filter(s) (if any)
        if (!paramFilterCategories.isEmpty()) {
            Iterator iParamFilterCategories = paramFilterCategories.iterator();
            while (iParamFilterCategories.hasNext()) {
                out.println("<input type=\"hidden\" name=\"cat\" value=\"" + (String)iParamFilterCategories.next() + "\" />");
            }
        }
        out.println("</form>");
        out.println("</div>");
        long stop = System.currentTimeMillis();
        if (DEBUG) { out.println("<!-- Completed year filtering in " + (stop-start) + " ms. -->"); }
    }
    
    
    if (itemsAsPortalPageCards) {
        //out.println(headAndDescr.replaceFirst(">", " class=\"section-heading bluebar-dark\">"));
        out.println(headAndDescr);
        out.println("<div class=\"boxes clearfix\">");
    } else if (itemsAsCards) {
        out.println("<div class=\"portal portal-mimic\" style=\"width:100%;overflow:visible;font-size:1em;float:none;\">");
        out.println("<section class=\"clearfix quadruple layout-group dynamic\">");
        out.println(headAndDescr);
        out.println("<div class=\"boxes clearfix\">");
    } else {
        out.println("<ul class=\"news-list\">");
    }

    // TEMP
    /*List nb = newsBulletin.getCollectorResult();
    Iterator itr = nb.iterator();
    out.println("<h4>Paths of the resources in the list:</h4>");
    while (itr.hasNext()) {
        out.println("" + cmso.getSitePath((CmsResource)itr.next()) + "<br />");
    }*/

    // Process "auto-collected" files (non-stickies)
    while (newsItems.hasMoreContent() && numAutoCollectedItems > 0) {
        fileName    = cms.contentshow(newsItems, "%(opencms.filename)");
        printNewsBulletin(out
                            , cms
                            , fileName
                            , newsItems
                            , itemImageWidth
                            , visitedFiles
                            , itemsWithImages
                            , dateFormat
                            , displayDescription
                            , displayTimestamp
                            , displayLabel
                            , itemsAsPortalPageCards || itemsAsCards
                            , locale);
        if (paramYear == -1) {
            // Increment file counter
            visitedFiles++;
            if (visitedFiles >= numAutoCollectedItems)
                break;
        }
    } // while (folder contains more bulletins && list should contain more)


    if (paramYear == -1) { // Ignore any stickies if a specific year was given
        // Process sticky files
        if (!stickies.isEmpty() && visitedFiles < maxEntries) {
            for (i = 0; i < stickies.size(); i++) {
                fileName    = (String)stickies.get(i);
                newsItems = cms.contentload("singleFile", fileName, editableItems);
                if (newsItems.hasMoreContent()) {
                    printNewsBulletin(out, 
                                        cms, 
                                        fileName, 
                                        newsItems
                                        , itemImageWidth
                                        , visitedFiles
                                        , itemsWithImages
                                        , dateFormat
                                        , displayDescription
                                        , displayTimestamp
                                        , displayLabel
                                        , itemsAsPortalPageCards || itemsAsCards
                                        , locale);
                }
                visitedFiles++;
                if (visitedFiles >= maxEntries)
                    break;
            }
        }
    }
    if (!(itemsAsPortalPageCards || itemsAsCards)) {
        out.println("</ul><!-- END news-list -->");
        if (moreLinkHtml != null)
            out.println(moreLinkHtml);
    }
    
    if (!isIncluded) {
        out.println("</article><!-- .main-content -->");
    } 
    else if (itemsAsPortalPageCards || itemsAsCards) {
        out.println("</div>"); // End the "boxes" wrapper
        if (moreLinkHtml != null)
            out.println(moreLinkHtml);
        if (!itemsAsPortalPageCards) {
            out.println("</section>");
            out.println("</div>"); // End the "portal-mimic" container
        }
    }
        
}
catch (Exception e) {
    out.print("Exception in newslist: " + e.getMessage());
}





//
// Category filters
//
if (showCatFilters) {
    if (!isIncluded) { // REQUIRE the list to be standalone, as filters should be placed in the right column
        //out.println("</div><!-- .twocol -->");
        //out.println("<div class=\"onecol\">");
        out.println("<div id=\"rightside\" class=\"column small\">");
        out.println("<aside>");
        
        // BEGIN NEW CATEGORY FILTER
        out.println("<h4 class=\"category-filter-heading\">" + filterHeading + "</h4>");
        CmsCategory filterCategory = null;
        try {
            filterCategory = cs.getCategory(cmso, filterRootCategoryPath);
            if (filterSubCategories) {
                // Print the tree of sub-categories below filterCategory (e.g. filterCategory: np/ ==yields==> Category tree: np/it/, np/komm/->np/komm/info/ and so on)
                printCatFilterTree(cms, filterCategory, filterCategoryReferencePath, 
                                    filterHideRootElement, filterHiddenCategoryPath,
                                    requestFileUri, paramFilterCategories, out);
            }
        } catch (Exception e) {
            filterCategory = null;
        }
        
        if (!paramFilterCategories.isEmpty()) {
            out.println("<a href=\"" + requestFileUri + (paramYear > 0 ? ("?y=" + paramYear) : "") + "\">"
                            + "<span class=\"remove-filter\" style=\"background:red; border-radius:3px; color:white; padding:0 0.3em;\">X</span> " 
                            + LABEL_FILTER_REMOVE 
                        + "</a>");
        }
        
        out.println("</aside>");
        out.println("</div><!-- .twocol (or .onecol, if this is a standalone list with filters) -->");
    }
}



// Finally, if the list is not included from another file, include the "master" template bottom
if (!isIncluded) {
    //out.println("</div><!-- .twocol (or .onecol, if this is a standalone list with filters) -->");
    cms.includeTemplateBottom();
}
%>