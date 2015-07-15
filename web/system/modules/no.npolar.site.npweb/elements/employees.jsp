<%-- 
    Document   : employees.jsp - this JSP should be _identical_ to categorylist.jsp, 
                    except for the javascript searchbox/autocomplete stuff.
    Created on : 18.apr.2011, 15:42:57
    Author     : Paul-Inge Flakstad <flakstad at npolar.no>
--%>
<%@ page import="java.util.*,
                 java.text.SimpleDateFormat,
                 no.npolar.util.*,
                 org.opencms.file.CmsResource,
                 org.opencms.file.CmsResourceFilter,
                 org.opencms.file.CmsObject,
                 org.opencms.file.collectors.CmsCategoryResourceCollector,
                 org.opencms.jsp.I_CmsXmlContentContainer,
                 org.opencms.jsp.CmsJspActionElement,
                 org.opencms.jsp.util.CmsJspContentAccessBean,
                 org.opencms.xml.A_CmsXmlDocument,
                 org.opencms.xml.content.*,
                 org.opencms.main.OpenCms,
                 org.opencms.relations.CmsCategory,
                 org.opencms.relations.CmsCategoryService,
                 org.opencms.util.CmsUUID,
                 org.opencms.util.CmsStringUtil"  session="true" 
%>
<%!
public String getParameterString(Map params) {
    if (params == null)
        return "";
    Set keys = params.keySet();
    Iterator ki = keys.iterator();
    String key = null;
    String val = null;
    String paramStr = "";
    while (ki.hasNext()) {
        key = (String)ki.next();
        if (params.get(key).getClass().getCanonicalName().equals("java.lang.String[]")) { // Multiple values (standard form)
            for (int i = 0; i < ((String[])params.get(key)).length; i++) {
                val = ((String[])params.get(key))[i];
                if (val.trim().length() > 0) {
                    if (paramStr.length() > 0)
                        paramStr += "&amp;";
                    paramStr += key + "=" + val;
                }
            }
        }
        else if (params.get(key).getClass().getCanonicalName().equals("java.lang.String")) { // Single value
            if (paramStr.length() == 0)
                paramStr += key + "=" + (String)params.get(key);
            else
                paramStr += "&amp;" + key + "=" + (String)params.get(key);
        }
    }
    return paramStr;
}

/**
* Prints the hierarchical category tree under the "category" top node.
* Dependant upon the recursive method printCategorySubTree(...).
* @param cmso An initialized CmsObject
* @param category The root node for the tree
* @param categoryReferencePath The category reference path, used to resolve categories
* @param requestFileUri The URI of the request file, used in construction of links
* @param paramFilterCategories A list of category identifiers present in the request parameters, used to determine "active" links
* @param out The writer to use when generating HTML output
*/
public void printCategoryTree(CmsObject cmso, CmsCategory category, String categoryReferencePath, String requestFileUri, List paramFilterCategories, JspWriter out) 
        throws org.opencms.main.CmsException, java.io.IOException {
    
    // Set the flag indicating if the category's path was given as a request parameter (meaning we're filtering the list by this category)
    boolean categoryInParameter = false;
    if (paramFilterCategories != null) {
        if (paramFilterCategories.contains(category.getPath())) {
            categoryInParameter = true;
        }
    }
    // Start the list of category filter links
    out.println("<ul class=\"category-filter\"><li><a href=\"" + requestFileUri + "?cat=" + category.getPath() + "\"" + 
                            (categoryInParameter ? " style=\"font-weight:bold;\"" : "") + ">" + category.getTitle() + 
                        "</a>");
    // Call the recursive method to print the subtree under this category
    printCategorySubTree(cmso, category, categoryReferencePath, requestFileUri, paramFilterCategories, out);
    // End the list of category filter links
    out.println("</li></ul>");
}
/*
* Recursive method to prints a hierarchical category tree. 
* @param cmso An initialized CmsObject
* @param category The root node for the tree
* @param categoryReferencePath The category reference path, used to resolve categories
* @param requestFileUri The URI of the request file, used in construction of links
* @param paramFilterCategories A list of category identifiers present in the request parameters, used to determine "active" links
* @param out The writer to use when generating HTML output
*/
public void printCategorySubTree(CmsObject cmso, CmsCategory category, String categoryReferencePath, String requestFileUri, List paramFilterCategories, JspWriter out) 
        throws org.opencms.main.CmsException, java.io.IOException {
    
    
    CmsCategoryService cs = CmsCategoryService.getInstance();
    List subCats = cs.readCategories(cmso, category.getPath(), false, categoryReferencePath); // Get the sub-categories of filterCategory
    if (subCats != null) {
        if (!subCats.isEmpty()) {
            Iterator iSub = subCats.iterator();
            out.println("<ul>");
            while (iSub.hasNext()) {
                category = (CmsCategory)iSub.next();
                boolean categoryInParameter = false; // Flag indicating if the category's path was given as a request parameter
                if (paramFilterCategories != null) {
                    if (paramFilterCategories.contains(category.getPath())) {
                        categoryInParameter = true;
                    }
                }
                    
                out.println("<li>" +
                        "<a href=\"" + requestFileUri + "?cat=" + category.getPath() + "\"" + 
                            (categoryInParameter ? " style=\"font-weight:bold;\"" : "") + ">" + category.getTitle() + 
                        "</a>");
                printCategorySubTree(cmso, category, categoryReferencePath, requestFileUri, paramFilterCategories, out);
                out.println("</li>");
            }
            out.println("</ul>");
        }
    }
}


    /**
    * Recursive method to prints a hierarchical category tree. 
    * @param cmso An initialized CmsObject
    * @param category The root node for the tree
    * @param categoryReferencePath The category reference path, used to resolve categories
    * @param hideRootElement If set to true, the topmost (root) element of the tree will not be displayed in the filter tree
    * @param hiddenCategoryPaths A list containing root paths to categories that should not be displayed in the filter tree
    * @param requestFileUri The URI of the request file, used in construction of links
    * @param paramFilterCategories A list of category identifiers (paths) present in the request parameters, used to determine "active" links
    * @param out The writer to use when generating HTML output
    */
    public void printCatFilterTree(CmsJspActionElement cms, //CmsObject cmso, 
                                    CmsCategory category, 
                                    String categoryReferencePath, 
                                    boolean hideRootElement, 
                                    List hiddenCategoryPaths,
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
        List subCats = cs.readCategories(cms.getCmsObject(), category.getPath(), false, categoryReferencePath);
        // For each sub-category, call this method
        if (subCats != null) {
            if (!subCats.isEmpty()) {
                Iterator iSub = subCats.iterator();
                while (iSub.hasNext()) {
                    category = (CmsCategory)iSub.next();
                    //if (!category.getRootPath().equals(hiddenCategoryPath)) {
                    if (!hiddenCategoryPaths.contains(category.getRootPath())) {
                        printCatFilterTree(cms, category, categoryReferencePath, false, hiddenCategoryPaths, requestFileUri, paramFilterCategories, out);
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

    public void printCatFilterList(CmsJspActionElement cms,//CmsObject cmso, 
                                    List categories, // A list of CmsCategory objects
                                    boolean printSubCategories,
                                    String categoryReferencePath, 
                                    List hiddenCategoryPaths,
                                    String requestFileUri, 
                                    List paramFilterCategories, 
                                    JspWriter out) throws org.opencms.main.CmsException, java.io.IOException {
        
        // Get the iterator for the list of categories
        Iterator iCat = categories.iterator();
        
        // Start the list
        out.println("<ul>");
        
        // Print each list item
        while (iCat.hasNext()) {
            CmsCategory category = (CmsCategory)iCat.next();
            // Proceed only if the category is not in the list of "hidden" categories
            if (!hiddenCategoryPaths.contains(category.getRootPath())) {
                // Determine whether or not the current category was present in the reqest parameters (meaning we're currently filtering by this category)
                boolean categoryInParameter = false;
                if (paramFilterCategories != null) {
                    if (paramFilterCategories.contains(category.getPath())) {
                        categoryInParameter = true;
                    }
                }
                
                out.println("<li>");
                if (!printSubCategories) {
                    out.println("<a href=\"" + cms.link(requestFileUri) + "?cat=" + category.getPath() + "\"" + 
                                    (categoryInParameter ? " style=\"font-weight:bold;\"" : "") + ">" + category.getTitle() + 
                                "</a>");
                } else {
                    printCatFilterTree(cms, category, categoryReferencePath,
                                        false, hiddenCategoryPaths,
                                        requestFileUri, paramFilterCategories, out);
                }
                out.println("</li>");
            }
        }
        
        // End the list
        out.println("</ul>");
    }
%>
<%
final boolean DEBUG                     = request.getParameter("debug") == null ? false : true;
//final String AJAX_EVENTS_PROVIDER      = "/system/modules/no.npolar.common.event/elements/events-provider.jsp";
final CmsAgent cms                            = new CmsAgent(pageContext, request, response);
final CmsObject cmso                          = cms.getCmsObject();
Locale locale                           = cms.getRequestContext().getLocale();
String loc                              = locale.toString();
String requestFileUri                   = cms.getRequestContext().getUri();
String requestFolderUri                 = cms.getRequestContext().getFolderUri();


// Handle form parameters
String requestedEmployeeName = request.getParameter("employeename");
if (requestedEmployeeName != null) {
    //out.println("<!-- Requested employee name: '" + requestedEmployeeName + "' -->");
    if (requestedEmployeeName.isEmpty())
        requestedEmployeeName = null;
} else {
    //out.println("<!-- no employee name requested (employeename='" + request.getParameter("employeename") + "') -->");
}
boolean suggestionUsed = false;
boolean formUriIsPersonFile = false;
String requestedEmployeeUri = request.getParameter("employeeuri");
if (requestedEmployeeUri != null) {
    //out.println("<!-- Employee uri found: " + request.getParameter("employeeuri") + " -->");
    formUriIsPersonFile = cmso.readResource(requestedEmployeeUri).getTypeId() == OpenCms.getResourceManager().getResourceType("person").getTypeId();
    if (cmso.existsResource(requestedEmployeeUri) && formUriIsPersonFile) { // Check existence and resourcetype
        // Determine if the search used the suggestion list (in which case this is a "direct hit")
        
        // This one depends on the parent folder, which is not so good, because 
        // the parent folder may use a different (e.g. misspelled) title than the 
        // person file. The suggestions list is built using person file titles.
        //suggestionUsed = cmso.readPropertyObject(CmsResource.getParentFolder(requestedEmployeeUri), "Title", false).getValue("").equals(requestedEmployeeName);
        
        String[] nameParts = cmso.readPropertyObject(requestedEmployeeUri, "Title", false).getValue("x,y").split(",");
        if (nameParts.length == 2) {
            String name = nameParts[1].trim().concat(" ").concat(nameParts[0]).trim();
            suggestionUsed = name.equals(requestedEmployeeName);
            //out.println("<!-- Comparing names: '" + requestedEmployeeName + "' was reqested, '" + name + "' was read from title -->");
            
        }
        
        // If this was a "direct hit": Send a redirect to the requested person
        if (suggestionUsed) {
            //out.println("<!-- Suggestion used, initiate redirect... -->");
            response.sendRedirect(requestedEmployeeUri);
        } else {
            //out.println("<!-- Suggestion NOT used, DON'T initiate redirect... -->");
        }
        //return; // Don't use "return", set to null instead:
        requestedEmployeeUri = null;
    }
}

final boolean EDITABLE_LIST_ITMES       = false;

final String DEFAULT_ROOT_CATEGORY_PATH = "/";
final String DEFAULT_CATEGORY_REFERENCE_PATH = "/" + loc + "/";
final String DEFAULT_SORT_MODE = "Title";

// The categories parameter name
final String PARAM_NAME_CATEGORY        = "cat";
// The categories "reference path" - OpenCms will append a _categories/ postfix and look for categories under the emerging path (e.g. /no/ansatte/_categories/)
// This means that any category parameters should be relative to this (e.g. /np/komm/ would be correct for the communications department)
//final String CAT_REFERENCE_PATH       = "/no/ansatte/";// + locale.toString() + "/ansatte/";

// Labels
//final String LABEL_VIEW_EMPLOYEE = loc.equalsIgnoreCase("no") ? "Vis ansattprofil" : "View profile";
final String MSG_EMPTY_LIST = cms.label("label.for.categorylist.emptylist");// loc.equalsIgnoreCase("no") ? "Ingen" : "None";

// Check if the outer template should be included here, and include it if needed:
boolean includeTemplate = false;

if (cmso.readResource(requestFileUri).getTypeId() == OpenCms.getResourceManager().getResourceType("np_catlist").getTypeId()) {
    includeTemplate = true;
    cms.includeTemplateTop();
    out.println("<article class=\"main-content\">");
    //out.println("<div class=\"twocol\">");
    out.println("<h1>" + cms.property("Title", requestFileUri, "[No title]") + "</h1>");
}


// The category service provider
CmsCategoryService cs = CmsCategoryService.getInstance();

/*
// TEST
String testResource = "/no/ansatte/ann.elin.steinsund.html";
out.println("<br />TEST:<br /> reading categories found on file " + testResource);
List rc = cs.readResourceCategories(cmso, testResource);
Iterator irc = rc.iterator();
while (irc.hasNext()) {
    CmsCategory resCat = (CmsCategory)irc.next();
    out.println("<br />- Category on resource: " + resCat.getTitle() + "<br />-- Root path: " + resCat.getRootPath() + "<br />-- Path: " + resCat.getPath());
}
out.println("<br />---");


String[] paramCats = request.getParameterValues(PARAM_NAME_CATEGORY);
for (int i = 0; i < paramCats.length; i++) {
    out.println("<br />Category parameter present: " + cs.readCategory(cmso, paramCats[i], CAT_ROOT).getTitle());
}
*/


/*if (CmsAgent.elementExists(category)) {
    //categoryTypes = CmsCategoryService.getInstance().readCategory(cmso, CmsResource.getName(category), "/no/").getPath();
    categoryTypes = cs.readCategory(cmso, CmsResource.getName(category), CAT_ROOT).getPath();
}*/



// If this template is included by another file, the parameter resourceUri must be set to contain the path to the config file
String resourceUri = request.getParameter("resourceUri");
if (resourceUri == null) 
    resourceUri = requestFileUri;

//==============================================================================
// Read the config file
//
String title = null;
String text = null;
String listHeading = null;
String resourceType = null;
String folder = null;
boolean subTree = false; 
String filterHeading = null;
String filterCategoryReferencePath = DEFAULT_CATEGORY_REFERENCE_PATH;
String filterRootCategoryPath = null;
String filterPreSelectedCategoryPath = null;
List<String> filterHiddenCategoryPaths = new ArrayList<String>();
boolean filterHideRootElement = false;
boolean filterSubCategories = false;
boolean filterMultiCategory = false;
String initialList = null;
String sortBy = null;
String position = null;
String emptyListMessage = null;

//CmsJspContentAccessBean contentReader = new CmsJspContentAccessBean(cmso, cmso.readResource(resourceUri));


I_CmsXmlContentContainer configuration = cms.contentload("singleFile", resourceUri, false);
while (configuration.hasMoreContent()) {
    title = cms.contentshow(configuration, "Title");
    text = cms.contentshow(configuration, "Text");
    listHeading = cms.contentshow(configuration, "ListHeading");
    resourceType = cms.contentshow(configuration, "ResourceType");
    folder = cms.contentshow(configuration, "Folder");
    subTree = Boolean.valueOf(cms.contentshow(configuration, "SubTree")).booleanValue();
    
    I_CmsXmlContentContainer filter = cms.contentloop(configuration, "Filter");
    while (filter.hasMoreContent()) {
        filterHeading = cms.contentshow(filter, "Heading");
        filterCategoryReferencePath = cms.contentshow(filter, "CategoryReferencePath");
        filterRootCategoryPath = cms.contentshow(filter, "RootCategory");
        filterHideRootElement = Boolean.valueOf(cms.contentshow(filter, "HideRootElement")).booleanValue();
        filterPreSelectedCategoryPath = cms.contentshow(filter, "PreSelectedCategory");
        I_CmsXmlContentContainer hiddenCategories = cms.contentloop(filter, "HiddenCategory");
        while (hiddenCategories.hasMoreContent()) {
            filterHiddenCategoryPaths.add(cms.contentshow(hiddenCategories));
        }
        filterSubCategories = Boolean.valueOf(cms.contentshow(filter, "SubCategories")).booleanValue();
        filterMultiCategory = Boolean.valueOf(cms.contentshow(filter, "MultiCategory")).booleanValue();
    }
    
    initialList = cms.contentshow(configuration, "InitialList");
    sortBy = cms.contentshow(configuration, "SortBy");
    position = cms.contentshow(configuration, "Position");
    emptyListMessage = cms.contentshow(configuration, "EmptyListMessage");
}
//
// Done reading config file
//==============================================================================



// Get the resource type ID for the resource type given in the config
int resourceTypeId = OpenCms.getResourceManager().getResourceType(resourceType).getTypeId();
// In case no reference category was specified, or if the reference category path given points to a non-exisiting resource, fallback to default
if (!CmsAgent.elementExists(filterCategoryReferencePath) || !cmso.existsResource(filterCategoryReferencePath)) {
    filterCategoryReferencePath = DEFAULT_CATEGORY_REFERENCE_PATH;
}
// In case no root category was specified, fallback to default
if (!CmsAgent.elementExists(filterRootCategoryPath)) {
    filterRootCategoryPath = DEFAULT_ROOT_CATEGORY_PATH;
}

// Store any category parameter(s)
List paramFilterCategories  = new ArrayList(0);
if (request.getParameterValues(PARAM_NAME_CATEGORY) != null) {
    paramFilterCategories = Arrays.asList(request.getParameterValues(PARAM_NAME_CATEGORY));
}
// If there were none, check if the "pre-selected category" option was used 
// (The "pre-selected category" option should be considered ONLY when there are no "regular" category parameters present)
else if (CmsAgent.elementExists(filterPreSelectedCategoryPath)) {
    paramFilterCategories.add(cs.getCategory(cmso, filterPreSelectedCategoryPath).getPath());
}
//String[] categoryParameters = request.getParameterValues(PARAM_NAME_CATEGORY);

// Use a boolean for convenience (isFilterd = true ==> category parameter(s) existed)
boolean isFiltered = !paramFilterCategories.isEmpty();//categoryParameters.length > 0;

// In case no sorting exists (this is an added option)
if (!CmsAgent.elementExists(sortBy)) {
    sortBy = DEFAULT_SORT_MODE;
}




/* // Old stuff (before recursive method) outcommented
List subCats = cs.readCategories(cmso, filterCategory.getPath(), false, CAT_ROOT);
if (!subCats.isEmpty()) {
    Iterator iSub = subCats.iterator();
    while (iSub.hasNext()) {
        filterCategory = (CmsCategory)iSub.next();
        out.println("<br /><a href=\"" + requestFileUri + "?cat=" + filterCategory.getPath() + "\">" + filterCategory.getTitle() + "</a>");
    }
}
*/
//out.println("<br />---Recursive:<br />");


/*// MOVED TO BOTTOM 
// Filter links
CmsCategory filterCategory = cs.getCategory(cmso, filterRootCategoryPath);//readCategory(cmso, filterRootCategoryPath, CAT_ROOT);
out.println("<h4><a href=\"" + requestFileUri + "?cat=" + filterCategory.getPath() + "\">" + filterCategory.getTitle() + "</a></h4>");
if (filterSubCategories) {
    // Print the tree of sub-categories below filterCategory (e.g. filterCategory: np/ ==yields==> Category tree: np/it/, np/komm/->np/komm/info/ and so on)
    printCategoryTree(cmso, filterCategory, CAT_REFERENCE_PATH, requestFileUri, out);
}
*/
//out.println("<br />---<br />");



//out.println("<div class=\"twocol\">");


// The value for the "categoryTypes" key (used in the collector parameter string)
String categoryTypes = "";
String categoryNames = "";

if (isFiltered) {
    Iterator iCat = paramFilterCategories.iterator();
    if (iCat.hasNext()) {
        if (categoryTypes.length() > 0)
            categoryTypes += ","; // Add an initial comma, if the string already contains any filter(s)
        if (categoryNames.length() > 0)
            categoryNames += ", ";
        while (iCat.hasNext()) {
            String catStr = (String)iCat.next(); // Get the category root path
            //categoryTypes += cs.readCategory(cmso, CmsResource.getName(cat), CAT_ROOT).getPath();
            //CmsCategory cat = cs.readCategory(cmso, catStr, CAT_REFERENCE_PATH);
            CmsCategory cat = cs.readCategory(cmso, catStr, filterCategoryReferencePath);
            String catPath = cat.getPath();
            String catName = cat.getTitle();
            categoryTypes += catPath;
            categoryNames += catName;
            if (DEBUG) { out.println("<br />Added category filter for collector:<br />-" + catPath); }
            //categoryTypes += cat;
            if (iCat.hasNext()) {
                categoryTypes += ",";
                categoryNames += ", ";
            }
        }
    }
    if (categoryTypes.endsWith(",")) {
        categoryTypes = categoryTypes.substring(0, categoryTypes.length() - 1);
    }
    if (categoryNames.endsWith(", ")) {
        categoryNames = categoryNames.substring(0, categoryNames.length() - 2);
    }
}

/*
// List content
List matchingResources = new ArrayList();
CmsResourceFilter resourceFilter = CmsResourceFilter.DEFAULT;
resourceFilter.addRequireType(resourceTypeId);
*/

//String collector = "allIn";
//collector += subTree ? "subTree" : "Folder";

String collector = "allKeyValuePairFiltered";
String paramSort = sortBy.equalsIgnoreCase("Title") ? "date" : sortBy.toLowerCase();

String param = "resource=" + folder + "|" +
                   "resourceType=" + resourceType + "|" + 
                   (categoryTypes.length() == 0 ? "" : "categoryTypes=" + categoryTypes + "|") +
                   "subTree=" + Boolean.toString(subTree) + "|" +
                   "sortBy=" + paramSort + "|" +
                   //"sortBy=date|" +
                   //"sortBy=title|" + // Non-existing value, only possible values are [date|category]
                   "sortAsc=false";

if (DEBUG) { out.println("<br />Collector parameter created: " + param); }

long start = System.currentTimeMillis();

// Collect list items
I_CmsXmlContentContainer listItems = null;
if (isFiltered) {
	listItems = cms.contentload(collector, param, EDITABLE_LIST_ITMES);
} else {
	param = folder + "|" + resourceTypeId;
	//listItems = cms.contentload("allIn".concat(subTree ? "SubTree" : "Folder").concat("PriorityTitle"), param, editableListItems);
	listItems = cms.contentload("allInSubTreePriorityTitleDesc", param, EDITABLE_LIST_ITMES);
}

// Get the results list. This list contains all employees if no category filter was used.
// If a partial name was submitted using the search box (but no category filter), 
// then this list will still contain all employees (making the size incorrect).
List result = listItems.getCollectorResult();
int listItemsCount = result.size();
long stop = System.currentTimeMillis();
//out.println("<!-- collecting files took " + (stop - start) + "ms -->");

// A separate list for search matches
List searchMatches = new ArrayList();

start = System.currentTimeMillis();

    //
    // Sort items by title or date (the native "date" sorting uses attribute:datereleased, not collector.date, so it is useless!)
    // This is the second sort. It could/should be avoided by implementing a custom collector
    //
if (sortBy.equalsIgnoreCase("Title")) {
    final Comparator<CmsResource> TITLE_IGNORE_CASE_ORDER = new Comparator<CmsResource>() {
                                                        //private CmsAgent cms = new CmsAgent(pageContext, request, response);
                                                        public int compare(CmsResource one, CmsResource another) {
                                                            String oneTitle = cms.property("Title", cmso.getSitePath(one), "").toLowerCase();
                                                            String anotherTitle = cms.property("Title", cmso.getSitePath(another), "").toLowerCase();
                                                            return oneTitle.compareTo(anotherTitle);
                                                        }
                                                    };
    Collections.sort(result, TITLE_IGNORE_CASE_ORDER);
    // Done sorting by title
} else if (sortBy.equalsIgnoreCase("date")) {
    final Comparator<CmsResource> DATE_ORDER = new Comparator<CmsResource>() {
                                                        //private CmsAgent cms = new CmsAgent(pageContext, request, response);
                                                        public int compare(CmsResource one, CmsResource another) {
                                                            String oneTitle = cms.property("collector.date", cmso.getSitePath(one), "1");
                                                            String anotherTitle = cms.property("collector.date", cmso.getSitePath(another), "1");
                                                            return oneTitle.compareTo(anotherTitle);
                                                        }
                                                    };
    Collections.sort(result, DATE_ORDER);
}
stop = System.currentTimeMillis();
//out.println("<!-- initial sort took " + (stop - start) + "ms -->");
start = System.currentTimeMillis();

// Find the search matches and print the autocomplete javascript data
if (!result.isEmpty()) {
    String autoCompleteData = "var employees = [";
    Iterator i = result.iterator();
    while (i.hasNext()) {
        CmsResource employeeResource = (CmsResource)i.next();
        String employeeName = cmso.readPropertyObject(employeeResource, "Title", false).getValue("");
        String employeeDescr = cmso.readPropertyObject(employeeResource, "Description", false).getValue("");
        // search matches
        String itemPath = cmso.getSitePath(employeeResource);
        String itemTitle = cmso.readPropertyObject(itemPath, "Title", false).getValue(itemPath);
        try {
            String[] itemTitleArr = itemTitle.split(",");
            itemTitle = itemTitleArr[1].trim().concat(" ").concat(itemTitleArr[0].trim());
        } catch (Exception e) {
            // Title malformed on the person file. Should be [Last name, First name], e.g. "Flakstad, Paul-Inge"
        }
        if (requestedEmployeeName != null) {
            // Important: Replace spaces and hyphens with a full stop (period). Thi
            if (itemPath.replace("index.html", "").contains(requestedEmployeeName.replaceAll(" ", ".").replaceAll("-", ".").toLowerCase()) 
                    || itemTitle.toLowerCase().contains(requestedEmployeeName.toLowerCase())) {
                searchMatches.add(employeeResource);
                //out.println("<!-- Found search match: " + itemTitle + " -->");
            }
        }
        // javascript data
        if (employeeName.contains(",")) {
            String[] employeeNameParts = CmsStringUtil.splitAsArray(employeeName, ",");
            if (employeeNameParts.length == 2)
                employeeName = employeeNameParts[1].trim().concat(" ").concat(employeeNameParts[0]).trim();
        }
        autoCompleteData += "\n\t\t\t{ label:\"" + employeeName + "\", value:\"" + cmso.getSitePath(employeeResource) + "\", descr:\"" + employeeDescr + "\" }";
        if (i.hasNext()) {
            autoCompleteData += ", ";
        } else {
            autoCompleteData += "\n\t];\n";
        }
    }
    %>
    <script type="text/javascript">
        /*<![CDATA[*/
        $(function() {
            <%= autoCompleteData %>
            // Mappings for special characters
            var accentMap = {
                    "á": "a",
                    "â": "a",
                    "å": "a",
                    "ç": "c",
                    "é": "e",
                    "è": "e",
                    "ö": "o",
                    "ø": "o",
                    "ü": "u",
                    "æ": "a"
            };
            // Used to find stuff using the mappings for special characters
            var normalize = function( term ) {
                    var ret = "";
                    for ( var i = 0; i < term.length; i++ ) {
                            ret += accentMap[ term.charAt(i) ] || term.charAt(i);
                    }
                    return ret;
            };
            
            $("#employeename").autocomplete({
                            minLength: 0
                            //,source: employees
                            ,source: function( request, response ) {
                                var matcher = new RegExp( $.ui.autocomplete.escapeRegex( request.term ), "i" );
                                response( $.grep( employees, function( value ) {
                                    value = value.label || value.value || value;
                                    return matcher.test( value ) || matcher.test( normalize( value ) );
                                }) );
                            }
                            ,focus: function(event, ui) {
                                //$("#employeename").val(ui.item.label);
                                return false;
                            }
                            ,select: function(event, ui) {
                                $("#employeename").val(ui.item.label);
                                $("#employeeuri").val(ui.item.value);
                                $("#employeelookup").submit();
                                return false;
                            }
                        }).data("autocomplete")._renderItem = function( ul, item ) {
                                return $( "<li></li>" )
                                        .data( "item.autocomplete", item )
                                        .append( "<a>" + item.label + "<br /><em>" + item.descr + "</em></a>" )
                                        .appendTo( ul );
                            };
        });
        document.write('<div class="searchbox-big">');
        document.write('<h2><%= cms.labelUnicode("label.np.searchbyname") %></h2>');
        document.write('<form id="employeelookup" method="post" action="<%= cms.link(requestFileUri) %>">');
        //document.write('<%= cms.labelUnicode("label.np.searchbyname") %>: ');
        document.write('<input type="text" name="employeename" size="30" id="employeename" value="<%= (requestedEmployeeName != null ? requestedEmployeeName : "") %>" /> ');
        document.write('<input type="hidden" name="employeeuri" id="employeeuri" value="" />');
        document.write('<input type="submit" value=" <%= cms.label("label.np.search") %> " />');
        document.write('</form>');
        //document.write('<p></p>');
        document.write('</div>');
        $("#employeename").focus();
        /*]]>*/
    </script>
    <%
    /*
    String autoCompleteData = "var data = [";
    Iterator i = result.iterator();
    while (i.hasNext()) {
        CmsResource employeeResource = (CmsResource)i.next();
        String employeeName = cmso.readPropertyObject(employeeResource, "Title", false).getValue("");
        if (employeeName.contains(",")) {
            String[] employeeNameParts = CmsStringUtil.splitAsArray(employeeName, ",");
            if (employeeNameParts.length == 2)
                employeeName = employeeNameParts[1].trim().concat(" ").concat(employeeNameParts[0]).trim();
        }
        autoCompleteData += "'" + employeeName + "'";
        if (i.hasNext()) {
            autoCompleteData += ", ";
        } else {
            autoCompleteData += "];";
        }
    }
    out.println("<script type=\"text/javascript\">");
    out.println("$(function() {");
    out.println(autoCompleteData);
    out.println("$(\"#name\").autocomplete({ source: data });");
    out.println("});");
    out.println("document.write('<form id=\"employeelookup\" method=\"post\" action=\"lookup-employee.jsp\">');");
    out.println("document.write('<input type=\"text\" name=\"name\" size=\"30\" id=\"name\" />');");
    out.println("document.write('<input type=\"hidden\" name=\"uri\" id=\"uri\" />');");
    out.println("document.write('<input type=\"submit\" value=\"Søk ansatt\" />');");
    out.println("document.write('</form>');");
    out.println("</script>");
    */
}
stop = System.currentTimeMillis();
//out.println("<!-- javascript output took " + (stop - start) + "ms -->");


// Resolve macros in the various text bits
// %(param.cat)     ==> current category name/names
// %(list.count)    ==> number of items in list
if (CmsAgent.elementExists(listHeading)) {
    listHeading = listHeading.replaceAll("%\\(param\\.cat\\)", categoryNames); 
    listHeading = listHeading.replaceAll("%\\(list\\.count\\)", Integer.toString(listItemsCount)); 
}
if (CmsAgent.elementExists(text)) {
    text = text.replaceAll("%\\(param\\.cat\\)", categoryNames);
    text = text.replaceAll("%\\(list\\.count\\)", Integer.toString(listItemsCount));
}
if (CmsAgent.elementExists(emptyListMessage)) {
    emptyListMessage = emptyListMessage.replaceAll("%\\(param\\.cat\\)", categoryNames);
    // No need to resolve %(list.count) here, it will always be zero whenever this text is used
}
// Done resolving macros

// Print text above the list
if (CmsAgent.elementExists(text)) {
    out.println("<div class=\"ingress\">" + text + "</div>");
}
// Print the list heading
//if (requestedEmployeeName != null) {
if (!searchMatches.isEmpty()) {
    out.println("<h3>" + cms.label("label.np.searchmatches") + " <em>" + requestedEmployeeName + "</em> (" + searchMatches.size() + ")</h3>");
    // TEST! Remove all employees that were not a match for the search term
    result.retainAll(searchMatches);
    //out.println("<!-- Retained " + searchMatches.size() + " resources, all matching search term -->");
    //out.println("<!-- searchMatches.size(): " + searchMatches.size() + " -->");
    //out.println("<!-- result.size(): " + result.size() + " -->");
} else {
    out.println("<h3>" + listHeading + "</h3>");
}

// Print the result list
//out.println("<ul>");
// If the resulting list is empty
if (result.isEmpty()) {
    // Print the "empty list" text, fallback to default is no custom text was given
    //out.println("<li>" + (CmsAgent.elementExists(emptyListMessage) ? emptyListMessage : MSG_EMPTY_LIST) + "</li>");
    out.println("<p>" + (CmsAgent.elementExists(emptyListMessage) ? emptyListMessage : MSG_EMPTY_LIST) + "</p>");
} 
else {
    //out.println("<table summary=\"\" class=\"odd-even-table\" cellspacing=\"2\" cellpadding=\"0\" border=\"0\">");
    out.println("<table class=\"odd-even-table\">");
    //out.println("<caption>CAPTION</caption>");
    out.println("<tbody>");
    out.println("<tr class=\"table-header-row\">" +
                    "<th style=\"width:40%;\">" + cms.label("label.Person.Name") + "</th>" +
                    "<th style=\"width:60%;\">" + cms.label("label.Person.Position") + "</th>" +
                "</tr>");
    while (listItems.hasMoreContent()) {
        String itemPath = cms.contentshow(listItems, "%(opencms.filename)");
        String itemTitle = cmso.readPropertyObject(itemPath, "Title", false).getValue(itemPath);
        String itemDescription = cmso.readPropertyObject(itemPath, "Description", false).getValue(itemPath);
        /*
        // Handle case where person search did not return hits
        if (requestedEmployeeName != null) {
            if (!itemPath.replace("index.html", "").contains(requestedEmployeeName.toLowerCase()) && !itemTitle.toLowerCase().contains(requestedEmployeeName.toLowerCase())) {
                continue;
            }
        }
        */
        //out.println("<li><a href=\"" + cms.link(itemPath) + "\">" + itemTitle + (!itemDescription.startsWith("/") ? (" &ndash; " + itemDescription) : "") + "</a></li>");
        out.println("<tr itemscope itemtype=\"http://schema.org/Person\">" +
                        "<td><a href=\"" + cms.link(itemPath) + "\" itemprop=\"url\"><span itemprop=\"name\">" + itemTitle + "</span></a></td>" +
                        (!itemDescription.startsWith("/") ? ("<td><span itemprop=\"jobTitle\">" + itemDescription + "</span>"
                                                               + "<span style=\"display:none;\" itemprop=\"affiliation\"> " + (loc.equalsIgnoreCase("no") ? "Norsk Polarinstitutt" : "Norwegian Polar Institute") + "</span>"
                                                           + "</td>") : "") + 
                    "</tr>");
    }
    out.println("</tbody>");
    out.println("</table>");
}
//out.println("</ul>");
// Done with the result list

// MOVED HERE FROM TOP
// Also added wrapper divs
if (includeTemplate) {
    out.println("</article><!-- .main-content -->");
    out.println("<div id=\"rightside\" class=\"column small\">");
    //out.println("</div><!-- .twocol -->");
    //out.println("<div class=\"onecol\">");
} 

//
// Category filter links
//
out.println("<aside>");
out.println("<h4>" + filterHeading + "</h4>");
//out.println("<h3 class=\"category-filter-heading\">" + filterHeading + "</h3>");
start = System.currentTimeMillis();
// Case 1: A root category was selected
if (filterRootCategoryPath != DEFAULT_ROOT_CATEGORY_PATH) {
    // First, read the root category for this filter collection
    CmsCategory filterCategory = cs.getCategory(cmso, filterRootCategoryPath);//readCategory(cmso, filterRootCategoryPath, CAT_ROOT);
    //out.println("<ul class=\"category-filter\"><li><a href=\"" + requestFileUri + "?cat=" + filterCategory.getPath() + "\">" + filterCategory.getTitle() + "</a>");
    if (filterSubCategories) {
        // Print the tree of sub-categories below filterCategory (e.g. filterCategory: np/ ==yields==> Category tree: np/it/, np/komm/->np/komm/info/ and so on)
        //printCatFilterTree(cmso, filterCategory, CAT_REFERENCE_PATH, requestFileUri, paramFilterCategories, out);
        //printCatFilterTree(cmso, filterCategory, filterCategoryReferencePath, requestFileUri, paramFilterCategories, out);
        printCatFilterTree(cms, filterCategory, filterCategoryReferencePath, 
                            filterHideRootElement, filterHiddenCategoryPaths,
                            requestFileUri, paramFilterCategories, out);
    } else {
        List subCategoriesOfRoot = cs.readCategories(cmso, filterCategory.getPath(), false, filterCategoryReferencePath);
        //out.println("<!-- ############ subcategories of root: " + subCategoriesOfRoot.size() + " ############ -->");
        printCatFilterList(cms, subCategoriesOfRoot,
                            false, filterCategoryReferencePath, filterHiddenCategoryPaths, 
                            requestFileUri, paramFilterCategories, out);
    }
} 
// Case 2: No root category was selected
else {
    // Read all available categories ...
    List availableCategories = cs.readCategories(cmso, null, false, filterCategoryReferencePath); // the "false" argument means don't fetch sub-categories
    // ... and print each one of them
    printCatFilterList(cms, availableCategories, filterSubCategories, 
                        filterCategoryReferencePath, filterHiddenCategoryPaths, 
                        requestFileUri, paramFilterCategories, out);
    
    /*
    //Map baseParams = new HashMap(request.getParameterMap());
    Iterator iAvailableCategories = availableCategories.iterator();
    if (iAvailableCategories.hasNext()) {
        out.println("<ul class=\"catfilter-nav\">");
        out.println("<li>");
        while (iAvailableCategories.hasNext()) {
            CmsCategory cat = (CmsCategory)iAvailableCategories.next();
            printCatFilterTree(cms, cat, filterCategoryReferencePath,
                                filterHideRootElement, filterHiddenCategoryPaths,
                                requestFileUri, paramFilterCategories, out);

        }
        out.println("</li>");
        out.println("</ul>");
    }
    */
}
out.println("</aside>");
stop = System.currentTimeMillis();
//out.println("<!-- printing category filters took " + (stop - start) + "ms -->");
//out.println("</li></ul>");
if (includeTemplate) {
    out.println("</div><!-- #rightside -->");
    //out.println("</div><!-- .onecol -->");
}
// END OF MOVED SECTION


if (includeTemplate) {
    cms.includeTemplateBottom();
}
%>