<%-- 
    Document   : newslist.jsp - uses the "TeaserImage" (as used in the new newsbulletin type, which has "Paragraph" sections)
    Created on : 04.jun.2010, 13:41:52
    Author     : Paul-Inge Flakstad <flakstad at npolar.no>
--%>
<%@ page import="no.npolar.util.*,
                 no.npolar.util.exception.MalformedPropertyValueException,
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
                                Locale locale) throws ServletException {
        String html = "<div class=\"news\">";
        if (imageLink != null)
            html += imageLink;
        html += "<div class=\"news-list-itemtext\">";
        html += "<h3><a href=\"" + cms.link(fileName) + "\">" + title + "</a></h3>";
        if (displayTimestamp)
            html += "<div class=\"timestamp\">" + CmsAgent.formatDate(published, dateFormat, locale) + "</div>";
        if (displayDescription) {
            html += "<p>";
            html += teaser + "</p>";
        }
        html += "</div><!-- .news-list-itemtext -->";
        html += "</div><!-- .news -->";
        return html;
    }

    public String getImageLinkHtml(CmsAgent cms, String imagePath, int imageWidth, String fileName) 
            throws CmsException, MalformedPropertyValueException, JspException {
        //if (imageContainer.hasMoreContent()) { // "if" instead of "while" => don't loop over all images, just get the first one (if any)
        if (CmsAgent.elementExists(imagePath)) {
            String imageLink = null;
            //String imagePath = cms.contentshow(imageContainer, "URI");
            int imageHeight = cms.calculateNewImageHeight(imageWidth, imagePath);
            //CmsImageProcessor imgPro = new CmsImageProcessor("__scale=t:3,q:100,w:".concat(String.valueOf(imageWidth)).concat("h:").concat(String.valueOf(imageHeight)));
            CmsImageProcessor imgPro = new CmsImageProcessor();
            imgPro.setType(4);
            imgPro.setQuality(100);
            imgPro.setWidth(imageWidth);
            imgPro.setHeight(imageHeight);
            imageLink = "<a href=\"" + cms.link(fileName) + "\">" +
                            "<img" + cms.img(imagePath, imgPro.getReScaler(imgPro), null, true) +
                            //" alt=\"" + cms.contentshow(imageContainer, "Title") + "\" />" +
                            " alt=\"\" />" +
                        "</a>";
            return imageLink;
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
                                    Locale locale) throws ServletException, CmsException, IOException {
        String title       = cms.contentshow(newsBulletin, "Title");
        String published   = cms.contentshow(newsBulletin, "Published");
        String teaser      = cms.contentshow(newsBulletin, "Teaser");
        String imageLink   = null;
        

        if (visitedFiles < itemsWithImages) {
            try {
                //out.println("<h5>Image path was '" + cms.contentshow(newsBulletin, "TeaserImage") + "', imageLink is " + getImageLinkHtml(cms, cms.contentshow(newsBulletin, "TeaserImage"), imageWidth, fileName) + "</h5>");
                /*I_CmsXmlContentContainer imageContainer = cms.contentloop(newsBulletin, "TeaserImage");
                imageLink = getImageLinkHtml(cms, imageContainer, imageWidth, fileName);*/
                imageLink = getImageLinkHtml(cms, cms.contentshow(newsBulletin, "TeaserImage"), imageWidth, fileName);
            }
            catch (Exception npe) {
                imageLink = "EXCEPTION";
                //throw new ServletException("Exception while reading teaser image in news bulletin file '" + fileName + "': " + npe.getMessage());
            }
            
        } // if (newsbulletin should have image)

        // HTML OUTPUT
        out.println(getItemHtml(cms, fileName, title, teaser, imageLink, published, dateFormat, displayDescription, displayTimestamp, locale));
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
    public void printCatFilterTree(CmsObject cmso, 
                                    CmsCategory category, 
                                    String categoryReferencePath, 
                                    boolean hideRootElement, 
                                    String hiddenCategoryPath,
                                    String requestFileUri, 
                                    List paramFilterCategories, 
                                    JspWriter out) throws org.opencms.main.CmsException, java.io.IOException {
        // Get the category service instance
        CmsCategoryService cs = CmsCategoryService.getInstance();
        // Determine whether or not the current category was present in the reqest parameters (meaning we're currently filtering by this category)
        boolean categoryInParameter = false;
        if (paramFilterCategories != null) {
            if (paramFilterCategories.contains(category.getPath())) {
                categoryInParameter = true;
            }
        }
        // Start the list, but only if the root element is not hidden
        if (!hideRootElement) {
            out.println("<ul>");
            out.println("<li>" +
                        "<a href=\"" + requestFileUri + "?cat=" + category.getPath() + "\"" + 
                            (categoryInParameter ? " style=\"font-weight:bold;\"" : "") + ">" + category.getTitle() + 
                        "</a>");
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
                        printCatFilterTree(cmso, category, categoryReferencePath, false, hiddenCategoryPath, requestFileUri, paramFilterCategories, out);
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
%><%
CmsAgent cms                = new CmsAgent(pageContext, request, response);
CmsObject cmso              = cms.getCmsObject();
final CmsObject CMSO        = OpenCms.initCmsObject(cmso);
Locale locale               = cms.getRequestContext().getLocale();
String requestFileUri       = cms.getRequestContext().getUri();
CmsCategoryService cs       = CmsCategoryService.getInstance();

// Determine if the list is included from another file
boolean isIncluded          = cms.getRequest().getParameter("resourceUri") != null;
// Determine the URI of the list resource
String resourceUri          = !isIncluded ? requestFileUri : cms.getRequest().getParameter("resourceUri");
// reverseCollector was intended used as a trigger for ascending sort order (which has no collector)
boolean reverseCollector    = false; 

// If the list is not included from another file, include the "master" template top
if (!isIncluded) {
    cms.includeTemplateTop();
    out.println("<div class=\"twocol\">");
}
// Set to "true" here. If neglected, enabling direct edit on list item won't work.
cms.editable(false);


// Constants
final String DEFAULT_ROOT_CATEGORY_PATH = null;
final String DEFAULT_CATEGORY_REFERENCE_PATH = "/";
final String PARAM_NAME_CATEGORY = "cat";
final String CAT_ROOT       = "/" + locale.toString() + "/";
final int IMG_WIDTH_XS      = Integer.parseInt(cms.getCmsObject().readPropertyObject(resourceUri, "image.size.xs", true).getValue("100"));
final int IMG_WIDTH_S       = Integer.parseInt(cms.getCmsObject().readPropertyObject(resourceUri, "image.size.s", true).getValue("140"));
final int TYPE_ID_NEWSBULL  = OpenCms.getResourceManager().getResourceType("newsbulletin").getTypeId(); // The ID for resource type "newsbulletin" (316)
final String DATE_FORMAT    = cms.labelUnicode("label.for.newsbulletin.dateformat");
final String JS_KEY_REGULAR = "/nothing.js";
final String HEADING_TYPE   = isIncluded ? "h2" : "h1";

final String LABEL_READ_MORE= cms.labelUnicode("label.np.readmore");

/*final int TOP = 1;
final int BOTTOM = 0;
int stickyPlacement = BOTTOM;*/

// Help and config variables
int i                       = 0;
int visitedFiles            = 0;
int maxEntries              = -1;
int itemsWithImages         = -1;
int itemImageWidth          = -1;
String listType             = null;
String listTitle            = null;
String listText             = null;
String listFolder           = null;
String category             = null;
String dateFormat           = null;
String sortOrder            = null;
String moreLink             = null;
String moreLinkTitle        = null;
boolean showCatFilters      = false;
boolean moreLinkNewWindow   = false;
boolean editableItems       = false;
boolean subTree             = false;
boolean displayDescription  = false;
boolean displayTimestamp    = false;
ArrayList stickies          = new ArrayList(0);


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
    listType            = cms.contentshow(configuration, "Type");
    listTitle           = cms.contentshow(configuration, "Title");
    listText            = cms.contentshow(configuration, "Text");
    listFolder          = cms.contentshow(configuration, "ListFolder");
    category            = cms.contentshow(configuration, "Category");
    showCatFilters      = Boolean.valueOf(cms.contentshow(configuration, "ShowCategoryFilters")).booleanValue();
    subTree             = Boolean.valueOf(cms.contentshow(configuration, "SubTree")).booleanValue();
    displayDescription  = Boolean.valueOf(cms.contentshow(configuration, "DisplayDescription")).booleanValue();
    displayTimestamp    = Boolean.valueOf(cms.contentshow(configuration, "DisplayTimestamp")).booleanValue();
    sortOrder           = cms.contentshow(configuration, "SortOrder");
    maxEntries          = Integer.valueOf(cms.contentshow(configuration, "MaxEntries")).intValue();
    itemsWithImages     = Integer.valueOf(cms.contentshow(configuration, "ItemsWithImages")).intValue();
    try {
        itemImageWidth  = Integer.valueOf(cms.contentshow(configuration, "ItemImageWidth")).intValue(); 
    } catch (Exception e) {
        itemImageWidth = IMG_WIDTH_XS;
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
    }
    
    I_CmsXmlContentContainer filter = cms.contentloop(configuration, "CategoryFilter");
    while (filter.hasMoreContent()) {
        filterHeading = cms.contentshow(filter, "Heading");
        filterCategoryReferencePath = cms.contentshow(filter, "CategoryReferencePath");
        filterRootCategoryPath = cms.contentshow(filter, "RootCategory");
        filterHideRootElement = Boolean.valueOf(cms.contentshow(filter, "HideRootElement")).booleanValue();
        filterPreSelectedCategoryPath = cms.contentshow(filter, "PreSelectedCategory");
        filterHiddenCategoryPath = cms.contentshow(filter, "HiddenCategory");
        out.println("<!-- ########## read filterHiddenCategoryPath '" + filterHiddenCategoryPath + " ############# -->");
        filterSubCategories = Boolean.valueOf(cms.contentshow(filter, "SubCategories")).booleanValue();
        out.println("<!-- ########## value of 'filterSubCategories': " + String.valueOf(filterSubCategories) + " ########## -->");
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

/*--------------------- LIST CONTENT OUTPUT -------------------------*/

// Print the list title and intro text
if (CmsAgent.elementExists(listTitle))
    out.println("<" + HEADING_TYPE + ">" + listTitle + "</" + HEADING_TYPE + ">");
if (CmsAgent.elementExists(listText))
    out.println(listText);





//
// List type: regular
//
if (listType.endsWith(JS_KEY_REGULAR)) { // Property value is used as switch - check is done on the javascript file name
    I_CmsXmlContentContainer newsBulletin;  // Container
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
        paramFilterCategories.remove(category);
        
        if (!paramFilterCategories.isEmpty() || CmsAgent.elementExists(category)) { // Category filtering
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
            newsBulletin = cms.contentload("allKeyValuePairFiltered", param, editableItems);
            
            //List collectedItems = newsBulletin.getCollectorResult();
            //
            // Must do a manual sort because the "date" sort in the collector 
            // sorts by attribute.datereleased, not collector.date!
            //
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
            Collections.sort(newsBulletin.getCollectorResult(), DATE_ORDER_DESC);
            
        } 
        else { // No category filtering
            // Get all the news bulletins in the given folder
            newsBulletin = cms.contentload(collector, listFolder.concat("|").concat(Integer.toString(TYPE_ID_NEWSBULL)), editableItems);
        }
        out.println("<div class=\"news-list\">");
        
        // TEMP
        /*List nb = newsBulletin.getCollectorResult();
        Iterator itr = nb.iterator();
        out.println("<h4>Paths of the resources in the list:</h4>");
        while (itr.hasNext()) {
            out.println("" + cmso.getSitePath((CmsResource)itr.next()) + "<br />");
        }*/

        // Process "auto-collected" files (non-stickies)
        while (newsBulletin.hasMoreContent() && numAutoCollectedItems > 0) {
            fileName    = cms.contentshow(newsBulletin, "%(opencms.filename)");
            printNewsBulletin(out, cms, fileName, newsBulletin, itemImageWidth, visitedFiles, itemsWithImages, dateFormat, displayDescription, displayTimestamp, locale);
            // Increment file counter
            visitedFiles++;
            if (visitedFiles >= numAutoCollectedItems)
                break;
        } // while (folder contains more bulletins && list should contain more)


        // Process sticky files
        if (!stickies.isEmpty() && visitedFiles < maxEntries) {
            for (i = 0; i < stickies.size(); i++) {
                fileName    = (String)stickies.get(i);
                newsBulletin = cms.contentload("singleFile", fileName, editableItems);
                if (newsBulletin.hasMoreContent()) {
                    printNewsBulletin(out, cms, fileName, newsBulletin, itemImageWidth, visitedFiles, itemsWithImages, dateFormat, displayDescription, displayTimestamp, locale);
                }
                visitedFiles++;
                if (visitedFiles >= maxEntries)
                    break;
            }
        }
        if (CmsAgent.elementExists(moreLink)) {
            out.println("<p><a href=\"" + cms.link(moreLink) + "\"" + (moreLinkNewWindow ? " target=\"_blank\"" : "") + ">" + 
                                (CmsAgent.elementExists(moreLinkTitle) ? moreLinkTitle : LABEL_READ_MORE) + "</a><p>");
        }
        out.println("</div><!-- END news-list -->");
    }
    catch (Exception e) { 
        out.print("Exception in newslist: " + e.getMessage());
    }
} // if (list type is regular list)


//
// List type: archive
//
else {
    /*--------------------------------------------------------
    * The "archive" list type has a very simple logic,
    * and its configuration is very limited.
    * The logic is as follows:
    * 1.) The list folder must be a folder that contains
    *        one or several subfolder(s) - each subfolder
    *        is an archive.
    * 2.) The archive folders must be named so that the
    *        archive order can be sorted by the name.
    *        The most recent archive will be on top.
    * An example:
    *       * list folder:      /no/news/archive/
    *       * archive folder:   /no/news/archive/2008/
    *       * archive folder:   /no/news/archive/2009/
    *       * archive folder:   /no/news/archive/2010/
    -----------------------------------------------------------*/
    I_CmsXmlContentContainer newsBulletins; // Container
    String archiveFolderPath, archiveFolderTitle, fileName; // String variables

    try {
        
        List archives = cmso.getSubFolders(listFolder);         // Each subfolders of the list folder is an archive
        Collections.sort(archives, Collections.reverseOrder()); // Sort the archives
        Iterator itr = archives.iterator();

        //out.println("<h3>" + archives.size() + " archives</h3>");
        while (itr.hasNext()) {
            CmsResource archiveFolderResource   = (CmsResource)itr.next();
            archiveFolderPath                   = listFolder.concat(archiveFolderResource.getName()).concat("/");
            archiveFolderTitle                  = cmso.readPropertyObject(archiveFolderResource, "Title", false).getValue();
            
            List subArchives                    = cmso.getSubFolders(archiveFolderPath, CmsResourceFilter.requireType(CmsResourceTypeFolder.getStaticTypeId()));
            
            out.println("<h2 class=\"news-archive-title on-off\">" + archiveFolderTitle+ "</h2>");
            
            if (subArchives.size() > 0) {
                Collections.sort(subArchives, Collections.reverseOrder());
                Iterator itrSubArchives = subArchives.iterator();
                
                out.println("<div class=\"news-list\">");
                
                while (itrSubArchives.hasNext()) {
                    //CmsResource subArchiveFolderResource = (CmsResource)itrSubArchives.next();
                    archiveFolderResource = (CmsResource)itrSubArchives.next();
                    archiveFolderPath = cmso.getSitePath(archiveFolderResource);
                    archiveFolderTitle = cmso.readPropertyObject(archiveFolderResource, "Title", false).getValue("[MISSING ARCHIVE TITLE]");
                    //out.println("<h3 class=\"news-archive-title on-off\">" + archiveFolderTitle+ "</h3>");
                    out.println("<h4>" + archiveFolderTitle + "<!-- archive resource is " + archiveFolderPath + " --></h4>");
                    newsBulletins = cms.contentload(collector, 
                            archiveFolderPath.concat("|").concat(Integer.toString(TYPE_ID_NEWSBULL)), editableItems);
                    
                    while (newsBulletins.hasMoreContent()) {
                        fileName = cms.contentshow(newsBulletins, "%(opencms.filename)");
                        printNewsBulletin(out, cms, fileName, newsBulletins, -1, 0, 0, dateFormat, displayDescription, displayTimestamp, locale);
                    }
                }
                out.println("</div><!-- .news-list -->");
            }
            else {
                newsBulletins = cms.contentload(collector, archiveFolderPath.concat("|").concat(Integer.toString(TYPE_ID_NEWSBULL)), editableItems);
                out.println("<div class=\"news-list\">");
                // Get all the news bulletins in the given folder
                while (newsBulletins.hasMoreContent()) {
                    fileName    = cms.contentshow(newsBulletins, "%(opencms.filename)");
                    printNewsBulletin(out, cms, fileName, newsBulletins, -1, 0, 0, dateFormat, displayDescription, displayTimestamp, locale);
                }
                out.println("</div><!-- .news-list -->");
            }
        }
    }
    catch (Exception e) { out.print("Exception in news archive list '" + resourceUri + "': " + e.getMessage()); }
}




//
// Category filter display
//
if (showCatFilters) {
    if (!isIncluded) { // REQUIRE the list to be standalone, as filters should be placed in the right "onecol" column
        out.println("</div><!-- .twocol -->");
        out.println("<div class=\"onecol\">");
        
        // BEGIN NEW CATEGORY FILTER
        out.println("<h4 class=\"category-filter-heading\">" + filterHeading + "</h4>");
        CmsCategory filterCategory = null;
        //try {
            try {
                filterCategory = cs.getCategory(cmso, filterRootCategoryPath);
                if (filterSubCategories) {
                    // Print the tree of sub-categories below filterCategory (e.g. filterCategory: np/ ==yields==> Category tree: np/it/, np/komm/->np/komm/info/ and so on)
                    printCatFilterTree(cmso, filterCategory, filterCategoryReferencePath, 
                                        filterHideRootElement, filterHiddenCategoryPath,
                                        requestFileUri, paramFilterCategories, out);
                }
            } catch (Exception e) {
                filterCategory = null;
            }
            
        /*} catch (Exception e) {
            Map baseParams = new HashMap(request.getParameterMap());

            //List availableCategories = cs.readCategories(cmso, null, true, CAT_ROOT);
            List availableCategories = cs.readCategories(cmso, null, true, filterCategoryReferencePath);
            Iterator iAvailableCategories = availableCategories.iterator();
            if (iAvailableCategories.hasNext()) {
                out.println("<ul class=\"catnav\">");
                while (iAvailableCategories.hasNext()) {
                    String paramString = CmsAgent.getParameterString(baseParams);
                    CmsCategory cat = (CmsCategory)iAvailableCategories.next();
                    out.println("<!-- cat.getRootPath() = " + cat.getRootPath() + ", filterHiddenCategoryPath = " + filterHiddenCategoryPath + " -->");
                    if (!cat.getRootPath().startsWith(filterHiddenCategoryPath)) {
                        //out.println(cat.getTitle() + " | ");

                        if (paramFilterCategories.contains(cat.getPath())) { // Currently filtering by this category
                            paramString = paramString.replace(PARAM_NAME_CATEGORY.concat("=").concat(cat.getPath()), "");
                            String removeLinkPath = requestFileUri + (paramString.length() > 0 ? "?".concat(paramString) : "");
                            // Remove trailing ?
                            if (removeLinkPath.endsWith("?"))
                                removeLinkPath = removeLinkPath.substring(0, removeLinkPath.length() - 1);

                            out.print("<li>");
                            out.println("<a" +
                                            " class=\"selected-nav\"" +
                                            " style=\"display:inline-block; padding:0.25em; border:1px solid #ddd; background:#eee;\"" +
                                            " href=\"" + removeLinkPath + "\">" + cat.getTitle() + " [X]</a>");
                            out.print("</li>");
                        }
                        else {
                            String addFilterPath = requestFileUri + "?" + PARAM_NAME_CATEGORY.concat("=").concat(cat.getPath());
                            out.println("<li><a href=\"" + addFilterPath + "\">" + cat.getTitle() + "</a></li>");
                        }
                        if (iAvailableCategories.hasNext()) {
                            //out.println(" | ");
                        }
                    }

                }
                out.println("</ul>");
            }
        }*/
        // END NEW CATEGORY FILTER
        
        
        /* // OLD CATEGORY FILTER
        Map baseParams = new HashMap(request.getParameterMap());

        List availableCategories = cs.readCategories(cmso, null, true, CAT_ROOT);
        //out.println("Filter: ");
        out.println("<h4>" + cms.labelUnicode("label.np.filters") + ":</h4>");
        Iterator iAvailableCategories = availableCategories.iterator();
        if (iAvailableCategories.hasNext()) {
            out.println("<ul class=\"catnav\">");
            while (iAvailableCategories.hasNext()) {
                String paramString = CmsAgent.getParameterString(baseParams);
                CmsCategory cat = (CmsCategory)iAvailableCategories.next();
                //out.println(cat.getTitle() + " | ");

                if (paramFilterCategories.contains(cat.getRootPath())) { // Currently filtering by this category
                    paramString = paramString.replace(PARAM_NAME_CAT.concat("=").concat(cat.getRootPath()), "");
                    String removeLinkPath = requestFileUri + (paramString.length() > 0 ? "?".concat(paramString) : "");
                    // Remove trailing ?
                    if (removeLinkPath.endsWith("?"))
                        removeLinkPath = removeLinkPath.substring(0, removeLinkPath.length() - 1);

                    out.print("<li>");
                    out.println("<a" +
                                    " class=\"selected-nav\"" +
                                    " style=\"display:inline-block; padding:0.25em; border:1px solid #ddd; background:#eee;\"" +
                                    " href=\"" + removeLinkPath + "\">" + cat.getTitle() + " [X]</a>");
                    out.print("</li>");
                }
                else {
                    String addFilterPath = requestFileUri + "?" + PARAM_NAME_CAT.concat("=").concat(cat.getRootPath());
                    out.println("<li><a href=\"" + addFilterPath + "\">" + cat.getTitle() + "</a></li>");
                }
                if (iAvailableCategories.hasNext()) {
                    //out.println(" | ");
                }

            }
            out.println("</ul>");
        }
        // END OLD CATEGORY FILTER
        */
    }
}



// Finally, if the list is not included from another file, include the "master" template bottom
if (!isIncluded) {
    out.println("</div><!-- .twocol (or .onecol, if this is a standalone list with filters) -->");
    cms.includeTemplateBottom();
}
%>