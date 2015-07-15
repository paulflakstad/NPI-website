<%-- 
    Document   : eventcalendar.jsp - customized for the NPI website
    Created on : 29.apr.2011, 11:30:49
    Author     : Paul-Inge Flakstad <flakstad at npolar.no>
--%><%@page import="java.io.IOException"%>
<%@page import="org.opencms.main.CmsException"%>
<%@page import="org.opencms.util.CmsHtmlExtractor"%>
<%@ page import="java.util.*,
                 java.text.SimpleDateFormat,
                 no.npolar.common.eventcalendar.*,
                 no.npolar.util.*,
                 org.opencms.file.CmsResource,
                 org.opencms.file.CmsObject,
                 org.opencms.jsp.I_CmsXmlContentContainer,
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
 * Gets the appropriate date format for an event, by evaluating the event's "time display" mode (date only or date and time).
 */
private SimpleDateFormat getDatetimeAttributeFormat(CmsObject cmso, CmsResource eventResource) throws CmsException {
    SimpleDateFormat dfFullIso = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ssZ", cmso.getRequestContext().getLocale());
    SimpleDateFormat dfShortIso = new SimpleDateFormat("yyyy-MM-dd", cmso.getRequestContext().getLocale());
    
    // Examine if the event is "display date only", and select the appropriate date format to use for the "datetime" attribute
    boolean dateonly = cmso.readPropertyObject(eventResource, "display", false).getValue("").equalsIgnoreCase("dateonly");
    SimpleDateFormat dfIso = dateonly ? dfShortIso : dfFullIso;
    dfIso.setTimeZone(TimeZone.getTimeZone("GMT+1"));
    
    return dfIso;
}

/** Tests if a given category is a subcategory of or identical to another category. */
public boolean isCategoryOrSubCategory(CmsCategory test, CmsCategory reference) {
    if (test.getRootPath().startsWith(reference.getRootPath()))
        return true;
    return false;
}

/** 
 * Tries to match a category's category or parent category against a list of possible matches. 
 * Used here to retrieve the "top level" (parent) category of a given category.
 * @return The first matching category, or null if there is no match.
 */
public CmsCategory matchCategoryOrParent(List<CmsCategory> possibleMatches, CmsCategory category, CmsObject cmso, String categoryReferencePath) throws CmsException {
    //Iterator<CmsCategory> iTop = topLevelCategories.iterator();
    CmsCategoryService cs = CmsCategoryService.getInstance();
    String catPath = category.getPath();
    CmsCategory tempCat = null;
    while (catPath.contains("/") && (catPath = catPath.substring(0, catPath.lastIndexOf("/"))) != "") {
        try {
            tempCat = cs.readCategory(cmso, catPath, categoryReferencePath);
            if (possibleMatches.contains(tempCat))
                return tempCat;
        } catch (Exception e) {
            return null;
        }
    }
    return null;
}

/**
 * Prints a list of events, as an unordered list.
 */
public void printEventsList(CmsAgent cms, 
                            List events, 
                            String eventTimeOverride,
                            String listHeading, 
                            boolean showEventDescription, 
                            SimpleDateFormat df, 
                            String baseParamString, 
                            List displayCategories,
                            String categoryReferencePath,
                            JspWriter out)
                        throws org.opencms.main.CmsException, 
                                java.io.IOException {
    
    String sectionHeadStart = "<h4 class=\"events-list-section-heading\">";
    String sectionHeadEnd = "</h4>";
    CmsObject cmso = cms.getCmsObject();
    CmsCategoryService catService = CmsCategoryService.getInstance();
    
    Iterator i = events.iterator();
    
    out.println(sectionHeadStart + listHeading + sectionHeadEnd);
    out.println("<ul class=\"event-list\">");
    while (i.hasNext()) {
        EventEntry event = (EventEntry)i.next();
        CmsResource eventResource = cmso.readResource(event.getStructureId());
        
        resolveCategoryFiltersForResource(cmso, eventResource, categoryReferencePath, out);
            
        SimpleDateFormat dfIso = getDatetimeAttributeFormat(cmso, eventResource);
        
        String start = null, end = null;
        try {
            start = "<time itemprop=\"startDate\" datetime=\"" + dfIso.format(new Date(event.getStartTime())) + "\">" + df.format(new Date(event.getStartTime())) + "</time>";
            end = "<time itemprop=\"endDate\" datetime=\"" + dfIso.format(new Date(event.getEndTime())) + "\">" + df.format(new Date(event.getEndTime())) + "</time>";
        } catch (Exception e ) {
           // Do nothing
        }

        out.println("<li itemscope itemtype=\"http://schema.org/Event\">" +
                        "<span class=\"event-time\">" +
                                (eventTimeOverride == null ?
                                    (start + (!event.isOneDayEvent() ? (" &ndash; " + end) : "")) 
                                    : 
                                    eventTimeOverride) +
                        "</span>" +
                        "<span class=\"event-info\">" +
                            "<a href=\"" + 
                                cms.link(cmso.getSitePath(eventResource)) +
                                (baseParamString.isEmpty() ? "" : ("?" + baseParamString)) + "\"" + 
                                (event.isExpired() ? " class=\"event-pastevent\"" : "") +
                            " itemprop=\"url\">" +
                                "<span itemprop=\"name\">" + event.getTitle() + "</span>" +
                            "</a>" +
                            (showEventDescription ? ("<p class=\"event-descr\" itemprop=\"description\">" + event.getDescription() + "</p>") : "") +
                        "</span>");
        if (!displayCategories.isEmpty()) {
            printDisplayCategories(cmso, eventResource, displayCategories, categoryReferencePath, "span", out);
        }
        
        out.println("</li>");

    }
    out.println("</ul>");
}

/**
 * Reads the categories for the given resource, and adds a category filter for
 * each one.
 */
private synchronized void resolveCategoryFiltersForResource(CmsObject cmso, CmsResource r, String categoryReferencePath, JspWriter out) throws org.opencms.main.CmsException, java.io.IOException {
    
    // Add any category to the category filters list
    CmsCategoryService cs = CmsCategoryService.getInstance();
    // Get the "top level" categories, e.g. a list containing "Event type", "Theme" and "Organizational"
    List<CmsCategory> topLevelCategories = cs.readCategories(cmso, null, false, categoryReferencePath);
    List<CmsCategory> eventCats = cs.readResourceCategories(cmso, cmso.getSitePath(r));
    Iterator<CmsCategory> iEventCats = eventCats.iterator();
    while (iEventCats.hasNext()) {
        CmsCategory eventCat = iEventCats.next();
        //addCategoryFilter(eventCat);
        
        CategoryFilterSet cfs = null;
        
        if (topLevelCategories.contains(eventCat)) { // Then this is a "top level" category, like "Event type" or "Theme"
            // Don't create a filter, just make sure a filter set exists for this root category
            cfs = new CategoryFilterSet(eventCat);
            if (!catFilterSets.containsKey(cfs.getTitle()))
                catFilterSets.put(cfs.getTitle(), cfs);
        } 
        else { // Not a "top level" category
            // Get the category's "top level" (parent) category:
            CmsCategory topLevelCategory = matchCategoryOrParent(topLevelCategories, eventCat, cmso, categoryReferencePath);
            // Get the filter set
            cfs = catFilterSets.get(topLevelCategory.getTitle());
            // Add the filter to the filter set
            cfs.addCategoryFilter(new CategoryFilter(eventCat), out);
        }
    }
    /*
    // Add any category to the category filters list
    CmsCategoryService cs = CmsCategoryService.getInstance();
    List<CmsCategory> eventCats = cs.readResourceCategories(cmso, cmso.getSitePath(r));
    Iterator<CmsCategory> iEventCats = eventCats.iterator();
    while (iEventCats.hasNext()) {
        CmsCategory eventCat = iEventCats.next();
        addCategoryFilter(eventCat);
    }
    //*/
}

/**
 * Adds the given category to the list of category filters. If the category
 * already exists in the list, its counter is incremented.
 */
/*
private synchronized void addCategoryFilter(CmsCategory cat) {
    //CategoryFilter cf = new CategoryFilter(cat.getTitle(), cat.getPath());
    CategoryFilter cf = new CategoryFilter(cat);
    
    if (!catFilters.contains(cf)) {
        catFilters.add(cf);
    } 
    catFilters.get(catFilters.indexOf(cf)).incrementCounter();
}
*/

/**
 * Prints a list of events, as a table.
 */
public void printEventsTable(CmsAgent cms, 
                                List events, 
                                String eventTimeOverride,
                                String eventTableStart,
                                boolean showEventDescription, 
                                boolean tagExpiredEvents,
                                SimpleDateFormat df, 
                                String baseParamString, 
                                List displayCategories,
                                String categoryReferencePath,
                                JspWriter out)
                            throws org.opencms.main.CmsException, java.io.IOException {
    
    CmsObject cmso = cms.getCmsObject();
    
    Iterator i = events.iterator();
    int eventsCounter = 2;
    
    if (i.hasNext()) {
        out.println(eventTableStart);
        while (i.hasNext()) {
            EventEntry event = (EventEntry)i.next();
            CmsResource eventResource = cmso.readResource(event.getStructureId());
            
            out.println("<!-- category reference path is '" + categoryReferencePath + "' -->");
            resolveCategoryFiltersForResource(cmso, eventResource, categoryReferencePath, out);
            
            SimpleDateFormat dfIso = getDatetimeAttributeFormat(cmso, eventResource);
            
            String start = null, end = null;
            try {
                start = "<time itemprop=\"startDate\" datetime=\"" + dfIso.format(new Date(event.getStartTime())) + "\">" + df.format(new Date(event.getStartTime())) + "</time>";
                end = "<time itemprop=\"endDate\" datetime=\"" + dfIso.format(new Date(event.getEndTime())) + "\">" + df.format(new Date(event.getEndTime())) + "</time>";
            } catch (Exception e ) {
               // Do nothing
            }
            
            out.println("<tr class=\"" + (++eventsCounter % 2 == 0 ? "even" : "odd") + "\" itemscope itemtype=\"http://schema.org/Event\">" +
                            "<td class=\"event-time\">" +
                                (eventTimeOverride == null ?
                                    (start + (event.hasEndTime() && !event.isOneDayEvent() ? (" &ndash;<br />" + end) : "")) 
                                    :
                                    eventTimeOverride) +
                            "</td>" +
                            "<td class=\"event-info\">" +
                            
                                "<h4>" +
                                    "<a href=\"" + 
                                        cms.link(cmso.getSitePath(eventResource)) +
                                        (baseParamString.isEmpty() ? "" : ("?" + baseParamString)) + "\"" + 
                                        (tagExpiredEvents ?
                                            (event.isExpired() ? " class=\"event-pastevent\"" : "") : 
                                            "") +
                                    " itemprop=\"url\">" + 
                                        "<span itemprop=\"name\">" + event.getTitle() + "</span>" +
                                    "</a>" +
                                "</h4>" +
                                (showEventDescription ? ("<p class=\"event-descr\" itemprop=\"description\">" + event.getDescription() + "</p>") : "") +
                            "</td>");

            printDisplayCategories(cmso, eventResource, displayCategories, categoryReferencePath, "td", out);

            out.println("</tr>");
        }
        out.println("</tbody></table>");
    }
}

/**
* Prints any display categories.
* @param cmso An initialized CmsObject, needed to access the VFS
* @param eventResource The event itself, needed to read its assigned categories
* @param displayCategories A list of parent categories whose child categories should be displayed (see inline comments at the top of the method body)
* @param categoryReferencePath The category reference path. See CmsCategoryService javadoc for details.
* @param tag The HTML tag to surround the value(s) of each displayCategory with (typically "td" or "span").
*/
public void printDisplayCategories(CmsObject cmso, 
                                    CmsResource eventResource,
                                    List displayCategories, 
                                    String categoryReferencePath, 
                                    String tag, 
                                    JspWriter out) 
                                throws org.opencms.main.CmsException, 
                                        java.io.IOException {
    
    CmsCategoryService catService = CmsCategoryService.getInstance();
    // "displayCategories" holds any categories that should be displayed 
    // along with the event, as a kind of additional info
    // The concept of "displayCategory" is based on parent/child categories.
    // Each "displayCategory" should be a parent category, and the category 
    // that is displayed will actually be the child category, NOT the 
    // "displayCategory" itself.
    // E.g.: If the "displayCategory" is the category "Country", the displayed 
    // category will be "Norway" (if the event belongs to the category 
    // Country and its sub-category Norway)
    if (!displayCategories.isEmpty()) {
        // Get all categories for this event
        List eventCategories = catService.readResourceCategories(cmso, cmso.getSitePath(eventResource));
        
        
        
        // Loop over all the categories that should be displayed
        Iterator iDispCat = displayCategories.iterator();
        while (iDispCat.hasNext()) {
            List eventCategoriesToDisplay = new ArrayList(eventCategories);
            // Get the category that should be displayed
            // (e.g. "Country")
            CmsCategory displayCategory = (CmsCategory)iDispCat.next();

            // Read the sub-categories of the display category
            List possibleDisplayableCategories = catService.readCategories(cmso, displayCategory.getPath(), false, cmso.getSitePath(eventResource));
            
            // Create a list holding any category present as both a possible categories and an actual event category
            // (After the retainAll()-call, this list should then contain the categories we actually want to display)
            eventCategoriesToDisplay.retainAll(possibleDisplayableCategories);
            Iterator iEventDisplayCat = eventCategoriesToDisplay.iterator();
            String categoriesString = "<" + tag + " class=\"event-cat\">";
            while (iEventDisplayCat.hasNext()) {
                categoriesString += ((CmsCategory)iEventDisplayCat.next()).getTitle();
                if (iEventDisplayCat.hasNext())
                    categoriesString += ", ";
            }
            out.println(categoriesString + "</" + tag + ">");
        }
    } // Done printing display categories
}

/**
 * A category filter. When a filter is applied, the list should contain only
 * resources that are tagged with the filter's corresponding category.
 */
public class CategoryFilter {
    private String name = null;
    private String uri  = null;
    private int counter = 0;
    private CmsCategory category = null;
    
    /**
    * Creates a new filter from the given category.
    */
    public CategoryFilter(CmsCategory category) {
        this.name = category.getTitle();
        this.uri = category.getPath();
        this.category = category;
    }
    /** Increments the counter for this filter */
    public void incrementCounter() { this.counter++; }
    /** Gets the name (title) for this filter's corresponding category */
    public String getName() { return this.name; }
    /** Gets the URI (path) for this filter's corresponding category */
    public String getUri() { return this.uri; }
    /** Gets the counter for this filter -- that is, how many resources match the filter */
    public int getCounter() { return this.counter; }
    /** Gets this filter's corresponding category */
    public CmsCategory getCategory() { return this.category; }
    /** Overrides Object#equals(Object): Returns true if name and uri are identical */
    @Override
    public boolean equals(Object that) {
        if (this == that)
            return true;
        if (that == null) 
            return false;
        if (!(that instanceof CategoryFilter))
            return false;
        return this.name.equals(((CategoryFilter)that).name) && this.uri.equals(((CategoryFilter)that).uri);
    } 
}

public class CategoryFilterSet {
    //private Map<CmsCategory, List<CategoryFilter>> filterSet = null;
    private List<CategoryFilter> filterSet = null;
    private CmsCategory parentCategory = null;
    
    public CategoryFilterSet(CmsCategory parentCategory) {
        //this.filterSet = new HashMap<CmsCategory, List<CategoryFilter>>();
        this.filterSet = new ArrayList<CategoryFilter>();
        this.parentCategory = parentCategory;
    }
    
    
    
    
    
    /** Adds a key to the set, with an empty CategoryFilter list as the associated value */
    //public void addKey(CmsCategory rootCategory) { this.filterSet.put(rootCategory, new ArrayList<CategoryFilter>()); }
    //public void addKey(String name) { this.filterSet.put(name, new ArrayList<CategoryFilter>()); }
    //public List<CategoryFilter> getCategoryFilters(CmsCategory rootCategory) { return this.filterSet.get(rootCategory); }
    public List<CategoryFilter> getCategoryFilters() { return this.filterSet; }
    
    //public void addCategoryFilter(CmsCategory rootCategory, CategoryFilter filter, JspWriter out) throws java.io.IOException {
    public void addCategoryFilter(CategoryFilter filter, JspWriter out) throws java.io.IOException {
        if (!this.filterSet.contains(filter)) {
            out.println("<!-- the filters in '" + parentCategory.getTitle() + "' did not include '" + filter.getName() + ", adding it ... -->");
            this.filterSet.add(filter);
        }
        filter = this.filterSet.get(this.filterSet.indexOf(filter));
        filter.incrementCounter();
        out.println("<!-- added filter for " + filter.getName() + " (counter is now " + filter.getCounter() + ") -->");
        
        out.println("<!-- size of the filter set is now " + this.filterSet.size() + " -->");
    }
    
    public String getTitle() { return this.parentCategory.getTitle(); }
    
    /** Overrides Object#equals(Object): Returns true if the parent categorie's root paths are identical */
    @Override
    public boolean equals(Object that) {
        if (this == that)
            return true;
        if (that == null) 
            return false;
        if (!(that instanceof CategoryFilter))
            return false;
        return this.parentCategory.getRootPath().equals(((CategoryFilterSet)that).parentCategory.getRootPath());
    } 
    
    /** Gets all available keys, which can then be used to fetch all available filters */
    //public Set<String> keySet() { return this.filterSet.keySet(); }
}

/** A list containing all category filters */
//static List<CategoryFilter> catFilters = new ArrayList<CategoryFilter>();
/** A map containing all category filter sets */
static Map<String, CategoryFilterSet> catFilterSets = new HashMap<String, CategoryFilterSet>();
%>
<%
CmsAgent cms                            = new CmsAgent(pageContext, request, response);
CmsObject cmso                          = cms.getCmsObject();
Locale locale                           = cms.getRequestContext().getLocale();
String requestFileUri                   = cms.getRequestContext().getUri();
String requestFolderUri                 = cms.getRequestContext().getFolderUri();

// Constants
final boolean DEBUG                     = request.getParameter("debug") == null ? false : true;
final String AJAX_EVENTS_PROVIDER       = "/system/modules/no.npolar.common.event/elements/events-provider.jsp";

// Parameter names
final String PARAM_NAME_RESOURCE_URI    = "resourceUri";
final String PARAM_NAME_CATEGORY        = "cat";
final String PARAM_NAME_EXPIRED         = "exp";
final String PARAM_NAME_DATE            = "d";
final String PARAM_NAME_MONTH           = "m";
final String PARAM_NAME_YEAR            = "y";
final String PARAM_NAME_WEEK            = "w";

// AJAX parameter names
final String PARAM_NAME_HIDE_EXPIRED    = "hide_expired";
final String PARAM_NAME_EVENTS_FOLDER   = "events_folder";
final String PARAM_NAME_EXCLUDE_FOLDER  = "exlude_folder";
final String PARAM_NAME_OVERVIEW        = "overview";
final String PARAM_NAME_CALENDAR_CLASS  = "calendar_class";
final String PARAM_NAME_WEEK_NUMBERS    = "week_numbers";
final String PARAM_NAME_DESCRIPTIONS    = "descriptions";
final String PARAM_NAME_LOCALE          = "locale";
final String PARAM_NAME_LABEL_SINGULAR  = "labelsingular";
final String PARAM_NAME_LABEL_PLURAL    = "labelplural";
final String PARAM_NAME_CATEGORY_PATH   = "categorypath";

// The keyword for "all categories"
final String KEYWORD_ALL_CATEGORIES     = "all";

// The keyword for "all years" (everything / "catch all")
final String PARAM_TIME_VAL_ALL         = "-1";

final boolean PARAM_EXPIRED_SET = request.getParameter(PARAM_NAME_EXPIRED) != null;

final boolean PARAM_DATE_SET = request.getParameter(PARAM_NAME_DATE) != null;
final boolean PARAM_MONTH_SET = request.getParameter(PARAM_NAME_MONTH) != null;
final boolean PARAM_YEAR_SET = request.getParameter(PARAM_NAME_YEAR) != null;
final boolean PARAM_WEEK_SET = request.getParameter(PARAM_NAME_WEEK) != null;

// Flag: are there no parameters used for time-filtering events present
final boolean NO_TIME_PARAMS = !PARAM_YEAR_SET 
                                && !PARAM_MONTH_SET 
                                && !PARAM_WEEK_SET
                                && !PARAM_DATE_SET;

// Flag: has "view all" been explicitly selected?
final boolean CATCH_ALL_SELECTED = (PARAM_TIME_VAL_ALL).equals(request.getParameter(PARAM_NAME_YEAR))
                                    && request.getParameter(PARAM_NAME_MONTH) == null
                                    && request.getParameter(PARAM_NAME_WEEK) == null
                                    && request.getParameter(PARAM_NAME_DATE) == null;

// Flag: are we're currently displaying a full list (that is, a list with no filters applied)?
final boolean FULL_LIST = request.getParameter(PARAM_NAME_CATEGORY) == null && (NO_TIME_PARAMS ||CATCH_ALL_SELECTED);

final boolean HIDE_EXPIRED_SELECTED = PARAM_EXPIRED_SET ? false : (PARAM_DATE_SET ? false : true);

// Check if the outer template should be included, and include it if needed:
boolean includeTemplate = false;
if (cmso.readResource(requestFileUri).getTypeId() == OpenCms.getResourceManager().getResourceType("np_eventcal").getTypeId()) {
    includeTemplate = true;
    cms.includeTemplateTop();
    out.println("<div class=\"twocol\">");
    out.println("<h1>" + cms.property("Title", requestFileUri, "[No title]") + "</h1>");
}

// The calendar instance
EventCalendar calendar = new EventCalendar(TimeZone.getDefault());

// The category service provider
CmsCategoryService catService = CmsCategoryService.getInstance();

// If this template is called from another jsp (i.e. using the "include" method), 
// then the parameter "resourceUri" should have been set, containing the path to 
// the config file
String resourceUri = request.getParameter("resourceUri");
// If no parameter "resourceUri" was present, assume that this template is 
// called via a resource of type "np_eventcal"
if (resourceUri == null) 
    resourceUri = requestFileUri;

//==============================================================================
//========================= READ THE CONFIG FILE ===============================
//==============================================================================
// Config variables
String eventsFolder             = null;
String categoryPath             = null;
//ArrayList undatedEventsFolders  = new ArrayList();
String undatedEventsFolder      = null; // Hard to manage a list, so use only one
List undatedEventsFolders       = new ArrayList(); // DUMMY list, methods in .jar need a list (MUST FIX!!!)
ArrayList displayCategories     = new ArrayList(); // List of categories to display in the events list
String hostCategoryPath         = null;
String calendarLinkPath         = null;
String calendarAddClass         = null;
String labelSingular            = null;
String labelPlural              = null;
ArrayList excludedEventsFolders = new ArrayList();
ArrayList excludedNavCategories = new ArrayList();
Calendar minTime                = Calendar.getInstance();
Calendar maxTime                = Calendar.getInstance();
Date initialTime                = new Date();
long minTimeLong                = 0;
long maxTimeLong                = 0;
int categoriesSort              = -1;
int initialRange                = -99; // 99 = catch all | 0 = current year | 1 = current month | 2 = current day | 3 = current week | 4 = upcoming and in progress | 98 = today and next N upcoming
int displayType                 = -1; // 0 = calendar only  |  1 = calendar & listing  |  2 = calendar, listing & navigation
boolean showWeekNumbers         = true;
boolean showEventDescription    = true;
boolean hideExpiredEvents       = true;

// Read the config file (xmlcontent resource of type "np_eventcal"):
I_CmsXmlContentContainer configuration = cms.contentload("singleFile", resourceUri, false);
while (configuration.hasMoreContent()) {
    // The folder to collect events from (events will be collected from the entire sub-tree)
    eventsFolder = cms.contentshow(configuration, "EventsFolder");
    // The root path to the categories, typically ${EVENTS_FOLDER}/_categories/
    categoryPath = cms.contentshow(configuration, "CategoriesRoot");
    // The preferred sorting mode for categories in the category navigation
    categoriesSort = Integer.valueOf(cms.contentshow(configuration, "CategoriesSort")).intValue();
    // The root path to the host category (if used it will be a special filter, unlike the other filters)
    hostCategoryPath = cms.contentshow(configuration, "HostCategory");
    if (CmsAgent.elementExists(hostCategoryPath)) {
        hostCategoryPath = cms.getRequestContext().removeSiteRoot(hostCategoryPath);
        /*if (CmsAgent.elementExists(hostCategoryPath))
            throw new NullPointerException("hostCategoryPath=" + hostCategoryPath);*/
    }
    // The preferred display type (type of view)
    displayType = Integer.valueOf(cms.contentshow(configuration, "DisplayType")).intValue();
    // Whether or not to use week numbers
    showWeekNumbers = Boolean.valueOf(cms.contentshow(configuration, "ShowWeekNumbers")).booleanValue();
    // Whether or not to show event descriptions in listings
    showEventDescription = Boolean.valueOf(cms.contentshow(configuration, "EventDescription")).booleanValue();
    // Whether or not to hide events that are finished
    hideExpiredEvents = HIDE_EXPIRED_SELECTED;//Boolean.valueOf(cms.contentshow(configuration, "HideExpiredEvents")).booleanValue();
    // The calendar link path (any links in the calendar will point to this file)
    calendarLinkPath = cms.contentshow(configuration, "CalendarLink");
    // The calendar class postfix (will be appended to the calendar's class)
    calendarAddClass = cms.contentshow(configuration, "CalendarAddClass");
    
    // A folder containing events with undetermined dates
    undatedEventsFolder = cms.contentshow(configuration, "UndatedFolder");
    undatedEventsFolders.add(undatedEventsFolder);
    
    // Any folders containing events that should not show
    I_CmsXmlContentContainer loop = cms.contentloop(configuration, "ExcludeFolder");
    while (loop.hasMoreContent()) {
        excludedEventsFolders.add(cms.contentshow(loop));
    }
    // Categories that should not be part of the navigation
    loop = cms.contentloop(configuration, "ExcludeNavCategory");
    while (loop.hasMoreContent()) {
        excludedNavCategories.add(catService.getCategory(cmso, cms.contentshow(loop)));
    }
    // Categories that should be displayed as part of the event entry in the list of events
    loop = cms.contentloop(configuration, "DisplayCategory");
    while (loop.hasMoreContent()) {
        displayCategories.add(catService.getCategory(cmso, cms.contentshow(loop)));
    }
    // Custom label (to override the "Event" label
    loop = cms.contentloop(configuration, "EventLabel");
    while (loop.hasMoreContent()) {
        labelSingular = cms.contentshow(loop, "SingularForm");
        labelPlural = cms.contentshow(loop, "PluralForm");
        labelSingular = CmsAgent.elementExists(labelSingular) ? labelSingular : null;
        labelPlural = CmsAgent.elementExists(labelPlural) ? labelPlural : null;
    }
    // Minimum calendar time (used for calendar navigation purposes only)
    try {
        minTimeLong = Long.valueOf(cms.contentshow(configuration, "MinTime")).longValue();
        minTime.setTimeInMillis(minTimeLong);
    } catch (Exception e) {
        minTime = null;
    }
    // Maximum calendar time (used for calendar navigation purposes only)
    try {
        maxTimeLong = Long.valueOf(cms.contentshow(configuration, "MaxTime")).longValue();
        maxTime.setTimeInMillis(maxTimeLong);
    } catch (Exception e) {
        maxTime = null;
    }
    try {
        initialTime = new Date(Long.valueOf(cms.contentshow(configuration, "InitialTime")).longValue());
    } catch (Exception e) {
        // Retain initailTime = new Date();
    }
    try {
        initialRange = Integer.valueOf(cms.contentshow(configuration, "InitialRange")).intValue();
    } catch (Exception e) {
        initialRange = EventCalendar.RANGE_CATCH_ALL;
    }
}
//==============================================================================
//======================== DONE READING CONFIG FILE ============================
//==============================================================================




//
// Constants
//

// The start date of every month is the 1st (obviously hehe :)
final int MONTH_START_DATE = 1;
// The path to the overview page
final String OVERVIEW_FILE              = CmsAgent.elementExists(calendarLinkPath) ? calendarLinkPath : requestFileUri;//requestFileUri;//"/no/categories/events.html";
// The maximum length for host names
final int MAXLENGTH_HOST                = 30;
// Sort modes for category navigators
final int SORT_MODE_RELEVANCY           = 2;
final int SORT_MODE_TITLE               = 1;
final int SORT_MODE_RESOURCENAME        = 0;

// Labels
//final String LABEL_NO_EVENTS            = cms.label("label.for.np_event.noevents");//"Ingen arrangementer";
final String LABEL_TIME                 = cms.label("label.for.np_event.time");
final String LABEL_EVENT                = labelSingular == null ? cms.label("label.for.np_event.event") : labelSingular;//"Arrangement";
final String LABEL_EVENTS               = labelPlural == null ? cms.label("label.for.np_event.events") : labelPlural;//"Arrangementer";
final String LABEL_SELECT               = cms.label("label.for.np_event.select"); //"Velg";
final String LABEL_MONTH                = cms.label("label.for.np_event.month");//"Måned";
final String LABEL_YEAR                 = cms.label("label.for.np_event.year");//"År";
final String LABEL_HOST                 = cms.label("label.for.np_event.host");//"Arrangør";
final String LABEL_VIEW_ALL             = cms.label("label.for.np_event.viewall");//"Vis hele";
final String LABEL_NO_CATEGORIES        = cms.label("label.for.np_event.nocategories");//"Ingen kategorier";
final String LABEL_NO_SUB_CATEGORIES    = cms.label("label.for.np_event.nosubcategories");//"Ingen underkategorier";
final String LABEL_ALL                  = cms.label("label.for.np_event.all");//"Alle";
final String LABEL_NONE                 = cms.label("label.for.np_event.none");//"Ingen";
final String LABEL_TOTAL                = cms.label("label.for.np_event.total");//"Totalt";
final String LABEL_DATE_NOT_DETERMINED  = cms.label("label.for.np_event.datenotset");//"Dato ikke fastsatt";
final String LABEL_WITHOUT_DATE         = cms.label("label.for.np_event.withoutdate").toLowerCase();//"uten fastsatt dato";
final String LABEL_ALL_DATED            = cms.label("label.for.np_event.alldated");
final String LABEL_NO_EVENTS            = LABEL_NONE + " " + LABEL_EVENTS.toLowerCase();//"Ingen arrangementer";
final String LABEL_TODAY                = cms.label("label.for.np_event.today"); // Today / I dag
final String LABEL_EXPIRED              = cms.label("label.for.np_event.viewexpired"); // Expired / Avsluttede
final String LABEL_UPCOMING             = cms.label("label.for.np_event.upcoming"); // Kommer / Upcoming
final String LABEL_IN                   = cms.label("label.for.np_event.in"); // Startet tidligere / Started earlier
final String LABEL_IN_PROGRESS          = cms.label("label.for.np_event.inprogress"); // Startet tidligere / Started earlier
final String LABEL_STARTS               = cms.label("label.for.np_event.starts"); // Starter / Starts
final String LABEL_STARTS_IN            = cms.label("label.for.np_event.startsin"); // Starter i / Starts in
final String LABEL_FINISHED             = cms.label("label.for.np_event.finished"); // Avsluttet / Finished
final String LABEL_FINISHED_IN          = cms.label("label.for.np_event.finishedin"); // Avsluttet i / Finished in
final String LABEL_ONGOING_AND_UPCOMING = cms.label("label.for.np_event.ongoingupcoming"); // Pågående og kommende / In progress and upcoming
final String LABEL_NEXT                 = cms.label("label.for.np_event.nextevent"); // Neste / Next
final String LABEL_NONE_THIS_MONTH      = cms.label("label.for.np_event.nonethismonth"); // Ingen denne måneden / None this month
final String LABEL_SELECT_MONTH         = cms.label("label.for.np_event.selectmonth"); // Velg måned / Select month
final String LABEL_SELECT_YEAR          = cms.label("label.for.np_event.selectyear"); // Velg år / Select year

// Config values with fallbacks to default values
final int YEAR_LOW                      = minTime != null ? minTime.get(Calendar.YEAR) : 1;
final int YEAR_HIGH                     = maxTime != null ? maxTime.get(Calendar.YEAR) : 2100;
//final String NO_DATE_EVENTS_FOLDER      = CmsAgent.elementExists(undatedEventsFolder) ? undatedEventsFolder : null;
final String CATEGORIES_PATH            = CmsAgent.elementExists(categoryPath) ? categoryPath : requestFolderUri;//requestFolderUri;//"/no/categories/";

// Form element snippets
final String SELECT_START               = "<select name=\"";
final String SELECT_END                 = "</select>";
final String OPTION_START               = "<option value=\"";
final String OPTION_END                 = "</option>";
final String OPTION_SELECTED            = " selected=\"selected\"";
final String CHECKBOX_START             = "<input type=\"checkbox\" name=\"";
final String INPUT_HIDDEN_START         = "<input type=\"hidden\" value=\"";

// The date format to use on lists and alike
SimpleDateFormat df = new SimpleDateFormat(cms.label("label.event.dateformat.dateonly"), locale);
SimpleDateFormat headingDate = new SimpleDateFormat(cms.label("label.event.dateformat.full"), locale);

// Date format to read/write MySQL-style date strings
SimpleDateFormat sqlFormat = new SimpleDateFormat(EventCalendar.MYSQL_DATETIME_FORMAT);

// Get a copy of the parameter map, removing the "resourceUri" parameter (which we don't want to pass on!)
Map baseParamMap = new HashMap(cms.getRequest().getParameterMap());
try { baseParamMap.remove(PARAM_NAME_RESOURCE_URI); } catch (NullPointerException npe) {} // baseParamMap may be NULL

// Time related variables
int year, month, monthStartWeek, week, weekday, daysInMonth, daysSincePrevWeekStart;//, daysInView;

// String variables used in the calendar
String eventsHtml = "";
String dayViewLink = null;

// List of categories given as request parameters (e.g.: /file.html?y=2010&m=5)
ArrayList paramCategoryStrings = null;
// List of CmsCategory objects - resolved based on the "cat" parameter(s)
ArrayList paramCategories = null;

// Set the initial calendar time
calendar.setTime(initialTime);
calendar.setFirstDayOfWeek(Calendar.MONDAY); // Set start of week to Monday
int m = calendar.get(Calendar.MONTH);
int y = calendar.get(Calendar.YEAR);//displayType == 0 ? calendar.get(Calendar.YEAR) : -1;//calendar.get(Calendar.YEAR);
int d = calendar.get(Calendar.DATE);
int w = calendar.get(Calendar.WEEK_OF_YEAR);
// Set the initial calendar range
int range = initialRange;

if (displayType == 0) {
    range = EventCalendar.RANGE_CURRENT_MONTH;
}

if (DEBUG) {
    out.println("<h5>Calendar initialized. Inital time is " + sqlFormat.format(calendar.getTime()) + ". Initial range is " + range + ".</h5>");
}

//
// Process time parameters. (Possible parameter names are "y", "m", "w" and "d")
//
// Time parameters set: y, m, d
if (request.getParameter(PARAM_NAME_DATE) != null 
        && request.getParameter(PARAM_NAME_MONTH) != null 
        && request.getParameter(PARAM_NAME_YEAR) != null) {
    d = Integer.valueOf(request.getParameter(PARAM_NAME_DATE)).intValue();
    if (d < 1 && d <= calendar.getMaximum(Calendar.DATE))
        throw new IllegalArgumentException("Illegal number for date: " + d + ". " +
                "Value must be in the range 1-" + calendar.getMaximum(Calendar.DATE) + ".");
    m = Integer.valueOf(request.getParameter(PARAM_NAME_MONTH)).intValue();
    if (m < 0 || m > 11)
        throw new IllegalArgumentException("Illegal number for month: " + m + ". Value must be in the range 0 to 11.");
    y = Integer.valueOf(request.getParameter(PARAM_NAME_YEAR)).intValue();
    if (y < 0)
        throw new IllegalArgumentException("Illegal number for year: " + y + ". Value cannot be negative.");
    range = EventCalendar.RANGE_CURRENT_DATE;
}
// Time parameters set: y, w
else if (request.getParameter(PARAM_NAME_YEAR) != null 
            && request.getParameter(PARAM_NAME_WEEK) != null) {
    y = Integer.valueOf(request.getParameter(PARAM_NAME_YEAR)).intValue();
    if (y < 0)
        throw new IllegalArgumentException("Illegal number for year: " + y + ". Value cannot be negative.");
    w = Integer.valueOf(request.getParameter(PARAM_NAME_WEEK)).intValue();
    if (w < 1 || w > calendar.getMaximum(Calendar.WEEK_OF_YEAR))
        throw new IllegalArgumentException("Illegal number for week: " + w + "." +
                " Value must be in the range 1-" + calendar.getMaximum(Calendar.WEEK_OF_YEAR) + ".");
    calendar.set(Calendar.YEAR, y);
    calendar.set(Calendar.WEEK_OF_YEAR, w);
    m = calendar.get(Calendar.MONTH);
    calendar.timeWarp(EventCalendar.WARP_FIRST_DAY_OF_WEEK);
    d = calendar.get(Calendar.DATE);
    range = EventCalendar.RANGE_CURRENT_WEEK;
    //out.println("<h4>Initially: " + testFormat.format(calendar.getTime()) + "</h4>");
}
// Time parameters set: y, m
else if (request.getParameter(PARAM_NAME_MONTH) != null 
            && request.getParameter(PARAM_NAME_YEAR) != null) {
    m = Integer.valueOf(request.getParameter(PARAM_NAME_MONTH)).intValue();
    if (m < -1 | m > 11)
        throw new IllegalArgumentException("Illegal number for month: " + m + ". Value must be in the range -1 (all) to 11.");
    y = Integer.valueOf(request.getParameter(PARAM_NAME_YEAR)).intValue();
    /*if (y < 0)
        throw new IllegalArgumentException("Illegal number for year: " + y + ". Value cannot be negative.");*/
    if (y == -1)
        range = EventCalendar.RANGE_CATCH_ALL;
    else if (m == -1)
        range = EventCalendar.RANGE_CURRENT_YEAR;
    else
        range = EventCalendar.RANGE_CURRENT_MONTH;
}
// Time parameters set: y
else if (request.getParameter(PARAM_NAME_YEAR) != null) {
    y = Integer.valueOf(request.getParameter(PARAM_NAME_YEAR)).intValue();
    if (y == -1)
        range = EventCalendar.RANGE_CATCH_ALL;
    else
        range = EventCalendar.RANGE_CURRENT_YEAR;
}

//
// Set the calendar date (time parameters have been processed above, so should be safe at this point)
// Note: the config value is used ONLY when no time parameters were present in the request.
//
if (m > -1)
    calendar.set(Calendar.MONTH, m);
m = calendar.get(Calendar.MONTH); // IMPORTANT because if m=-1, it will cause trouble after this point
calendar.set(Calendar.YEAR, y);
calendar.set(Calendar.DATE, d);

// Store the initial time 
initialTime = calendar.getTime();
// Also store the initial values individually
weekday = calendar.get(Calendar.DAY_OF_WEEK);           // Weekday
week    = calendar.get(Calendar.WEEK_OF_YEAR);          // Week of year
month   = calendar.get(Calendar.MONTH);                 // Month
year    = calendar.get(Calendar.YEAR);                  // Year
daysInMonth = calendar.getActualMaximum(Calendar.DATE); // Number of days in the current month

if (DEBUG) { out.println("\n<!-- \nProcessed calendar parameters.\n- Time is set to " + sqlFormat.format(calendar.getTime()) + ".\n- Range is set to " + range + ".\n-->"); }

long now = new Date().getTime();
Calendar todayCalendar = new GregorianCalendar();
todayCalendar.setTimeInMillis(now);
//long initialNow = todayCalendar.getTimeInMillis();
// Get a long value for "start of today"
todayCalendar.set(Calendar.HOUR_OF_DAY, todayCalendar.getMinimum(Calendar.HOUR_OF_DAY));
todayCalendar.set(Calendar.MINUTE, todayCalendar.getMinimum(Calendar.MINUTE));
todayCalendar.set(Calendar.SECOND, todayCalendar.getMinimum(Calendar.SECOND));
long todayStartMillis = todayCalendar.getTimeInMillis();
// Get the long value for "end of today"
todayCalendar.set(Calendar.HOUR_OF_DAY, todayCalendar.getMaximum(Calendar.HOUR_OF_DAY));
todayCalendar.set(Calendar.MINUTE, todayCalendar.getMaximum(Calendar.MINUTE));
todayCalendar.set(Calendar.SECOND, todayCalendar.getMaximum(Calendar.SECOND));
long todayEndMillis = todayCalendar.getTimeInMillis();
// Get the long value for "n months ago"
todayCalendar.set(Calendar.MONTH, todayCalendar.get(Calendar.MONTH) - 3);
long pastStartMillis = todayCalendar.getTimeInMillis();
// Reset the "today" calendar
//todayCalendar.setTimeInMillis(initialNow);
todayCalendar.setTimeInMillis(now);

//
// Determine if the current range includes today
//
boolean rangeIncludesToday = false;
switch (range) {
    case EventCalendar.RANGE_CATCH_ALL:
        rangeIncludesToday = true;
        break;
    case EventCalendar.RANGE_CURRENT_YEAR:
        rangeIncludesToday = calendar.get(Calendar.YEAR) == todayCalendar.get(Calendar.YEAR);
        break;
    case EventCalendar.RANGE_CURRENT_MONTH:
        rangeIncludesToday = calendar.get(Calendar.YEAR) == todayCalendar.get(Calendar.YEAR) && 
                                calendar.get(Calendar.MONTH) == todayCalendar.get(Calendar.MONTH);
        break;
    case EventCalendar.RANGE_CURRENT_WEEK:
        rangeIncludesToday = calendar.get(Calendar.YEAR) == todayCalendar.get(Calendar.YEAR) && 
                                calendar.get(Calendar.MONTH) == todayCalendar.get(Calendar.MONTH) &&
                                calendar.get(Calendar.WEEK_OF_YEAR) == todayCalendar.get(Calendar.WEEK_OF_YEAR);
        break;
    case EventCalendar.RANGE_CURRENT_DATE:
        rangeIncludesToday = calendar.get(Calendar.YEAR) == todayCalendar.get(Calendar.YEAR) && 
                                calendar.get(Calendar.MONTH) == todayCalendar.get(Calendar.MONTH) &&
                                calendar.get(Calendar.DATE) == todayCalendar.get(Calendar.DATE);
        break;
    default:
        break;
}


// Set the range heading for the event list(s)
String headingInRange = null;
switch (range) {
    case EventCalendar.RANGE_CURRENT_WEEK:
        headingInRange = cms.label("label.for.np_event.week") + " " + calendar.get(Calendar.WEEK_OF_YEAR) + ", " + calendar.get(Calendar.YEAR);
        break;
    case EventCalendar.RANGE_CURRENT_MONTH:
        headingInRange = calendar.getDisplayName(Calendar.MONTH, Calendar.SHORT, locale) + " " + calendar.get(Calendar.YEAR);
        break;
    case EventCalendar.RANGE_CURRENT_YEAR:
        headingInRange = "" + calendar.get(Calendar.YEAR);
        break;
    default:
        headingInRange = "";
        break;
}



//
// Process category parameter(s), the parameter name is "cat"
//
if (request.getParameter(PARAM_NAME_CATEGORY) != null) {
    List pc = Arrays.asList(request.getParameterValues(PARAM_NAME_CATEGORY));
    paramCategoryStrings = new ArrayList(pc);
    paramCategories = new ArrayList();
    // Remove all occurrences of "all categories" and create the list of CmsCategory objects
    Iterator iParamCategories = paramCategoryStrings.iterator();
    while (iParamCategories.hasNext()) {
        String paramCatPath = (String)iParamCategories.next();
        if (KEYWORD_ALL_CATEGORIES.equals(paramCatPath)) { // Pseudo: if ("all" equals this "cat"-parameter's value)
            iParamCategories.remove(); // Remove it. (The "all" keyword does not apply to every category filter, only the host category.
        } else {
            try {
                // Get the category object
                CmsCategory cat = catService.readCategory(cmso, paramCatPath, requestFileUri);    
                // Store it in the list
                paramCategories.add(cat);
                if (DEBUG) { out.println("\n<!-- Found category filter: '" + cat.getRootPath() + "' (relative path: '" + cat.getPath() + "') -->"); }
            } catch (Exception readCatError) {
                if (DEBUG) { out.println("\n<!-- Exception when reading category: " + readCatError.getMessage() + " -->"); }
            }
        }
    }
}

/*
// Get the "top level" categories (e.g. "Event type")
List topLevelCategories = catService.readCategories(cmso, null, false, CATEGORIES_PATH);
// Get all categories under the specified category folder
List allCategories = catService.readCategories(cmso, null, true, CATEGORIES_PATH);
// Get the "leaf" or "bottom level" categories by subtracting all the "top level categories" from "all categories"
List leafCategories = new ArrayList(allCategories);
leafCategories.removeAll(topLevelCategories);
*/



//
// Get all events in the current range
//
boolean sortDescending = true; // Whether or not to sort descending
boolean overlapLenient = true; // Whether or not to include events that only partially overlaps the range
boolean categoryInclusive = false; // Whether or not to expand (true) or narrow down (false) the resulting event list when multiple category filters are applied

/*
boolean calendarRepresentsCurrentMonth = calendar.get(Calendar.YEAR) == todayCalendar.get(Calendar.YEAR) 
                                         && calendar.get(Calendar.MONTH) == todayCalendar.get(Calendar.MONTH); // the event calendar month is the actual current month
*/

// IMPORTANT! Invoke getEvents(...) here -- it must be done prior to invoking getDatedEvents(), getUndatedEvents() or getExcludedEvents()
List allEventsInRange = calendar.getEvents(range, 
                                           cms, 
                                           eventsFolder, 
                                           undatedEventsFolders, 
                                           excludedEventsFolders, 
                                           paramCategories,
                                           hideExpiredEvents,
                                           sortDescending,
                                           overlapLenient,
                                           categoryInclusive,
                                           -1);
List noDateEvents = calendar.getUndatedEvents();
//List datedEvents = calendar.getDatedEvents();
//List excludedEvents = calendar.getExcludedEvents();

// Set overlap lenient mode to "false":
// Get events in current range, NON-LENIENT overlap mode (exclude events that start before the range and stretches into it)
overlapLenient = false;
List<EventEntry> eventsStartingInRange = calendar.getEvents(range, cms, eventsFolder,
                                                    undatedEventsFolders, excludedEventsFolders, paramCategories,
                                                    hideExpiredEvents, sortDescending, overlapLenient, categoryInclusive, -1);

// Get events in current range, LENIENT overlap mode (include events that start before the range and stretches into the range)
overlapLenient = true;
List<EventEntry> eventsOverlappingRange = new ArrayList<EventEntry>();
try {
    eventsOverlappingRange.addAll(calendar.getEvents(range, cms, eventsFolder,
                                                    undatedEventsFolders, excludedEventsFolders, paramCategories,
                                                    hideExpiredEvents, sortDescending, overlapLenient, categoryInclusive, -1));
} catch (NumberFormatException nfe) {
    // Bug? WTF???
}

// Get expired events
List<EventEntry> eventsExpired = calendar.getExpiredEvents();//new ArrayList<EventEntry>();
eventsExpired.removeAll(noDateEvents);

// Remove any duplicates
eventsOverlappingRange.removeAll(eventsStartingInRange);
eventsOverlappingRange.removeAll(eventsExpired);
eventsStartingInRange.removeAll(eventsExpired);

//Sort the lists by start time
Collections.sort(eventsStartingInRange, EventEntry.COMPARATOR_START_TIME);
Collections.sort(eventsOverlappingRange, EventEntry.COMPARATOR_START_TIME);
Collections.sort(eventsExpired, EventEntry.COMPARATOR_START_TIME);
// To make the list of expired events more user-friendly, reverse the order
Collections.reverse(eventsExpired);
//datedEvents.clear();
List datedEvents = new ArrayList();
datedEvents.addAll(eventsStartingInRange);
datedEvents.addAll(eventsOverlappingRange);
datedEvents.addAll(eventsExpired);



/*
List<EventEntry> eventsStartingToday = new ArrayList<EventEntry>();
if (rangeIncludesToday) {
    Iterator iInRange = eventsStartingInRange.iterator();
    while (iInRange.hasNext()) {
        EventEntry ee = (EventEntry)iInRange.next();
        if (ee.startsOnDate(new Date(todayCalendar.getTimeInMillis())) && NO_TIME_PARAMS) {
            eventsStartingToday.add(ee);
            iInRange.remove();
            //out.println("<!-- Event taking place today: " + ee.getTitle() + " -->");
        }
    }
}
*/
if (DEBUG) { out.println("\n<!-- Collecting events. Range is " + range + " (today is" + (rangeIncludesToday ? "" : " not") + " included) -->\n"); }
List<EventEntry> eventsStartingToday = calendar.getEvents(todayStartMillis, 
                                         todayEndMillis,
                                         cms,
                                         eventsFolder,
                                         undatedEventsFolders,
                                         excludedEventsFolders,
                                         paramCategories,
                                         !NO_TIME_PARAMS, // Exclude expired
                                         sortDescending,
                                         true, // Overlap lenient mode
                                         categoryInclusive,
                                         -1);

// Get all events occuring today (either starting today or with a timespan overlapping today) ...
List<EventEntry> eventsOverlappingToday = calendar.getEvents(todayStartMillis, 
                                                     todayEndMillis,
                                                     cms,
                                                     eventsFolder,
                                                     undatedEventsFolders,
                                                     excludedEventsFolders,
                                                     paramCategories,
                                                     true, // Exclude expired
                                                     sortDescending,
                                                     true, // Overlap lenient mode
                                                     categoryInclusive,
                                                     -1);
// .. then remove events starting today. The resulting list should now contain only events overlapping today.
eventsOverlappingToday.removeAll(eventsStartingToday);

eventsStartingInRange.removeAll(eventsStartingToday);
eventsStartingInRange.removeAll(eventsOverlappingToday);
/*
// Get a set of the N next events occuring after today
List<EventEntry> eventsNextAfterToday = calendar.getEvents(todayEndMillis, 
                                                             Long.MAX_VALUE,
                                                             cms,
                                                             eventsFolder,
                                                             undatedEventsFolders,
                                                             excludedEventsFolders,
                                                             paramCategories,
                                                             true, // Exclude expired
                                                             sortDescending,
                                                             false, // Overlap lenient mode
                                                             categoryInclusive,
                                                             -1);
*/
Collections.sort(eventsOverlappingToday, EventEntry.COMPARATOR_START_TIME);
//Collections.sort(eventsNextAfterToday, EventEntry.COMPARATOR_START_TIME);

if (datedEvents.isEmpty()) {
    datedEvents.addAll(eventsStartingToday);
    datedEvents.addAll(eventsOverlappingToday);
    //datedEvents.addAll(eventsNextAfterToday);
}
/*
out.println("\n<!-- eventsStartingToday.size() = " + eventsStartingToday.size() + " -->");
Iterator<EventEntry> lol = eventsStartingToday.iterator();
while (lol.hasNext()) {
    out.println("<!-- " + lol.next().getTitle() + " -->");
}
*/
/*
out.println("\n<!-- eventsNextAfterToday.size() = " + eventsNextAfterToday.size() + " -->");
lol = eventsNextAfterToday.iterator();
while (lol.hasNext()) {
    out.println("<!-- " + lol.next().getTitle() + " -->");
}
*/
int numCurrentRangeEvents = datedEvents.size(); // The number of dated events, for convenience
int numNoDateEvents = noDateEvents.size(); // The number of undated events, for convenience

// Determine the number of events shown in the current overview
int numEvents = numCurrentRangeEvents; // Total number of events in the current view. As default, the number of dated events.
if (range == EventCalendar.RANGE_CURRENT_YEAR || range == EventCalendar.RANGE_CATCH_ALL)
    numEvents += noDateEvents.size(); // Modify by adding the number of undated events, for the ranges where the undated events are shown





//
// Process the parameters
//
HashMap parameterMap = new HashMap(baseParamMap); // Get the parameter map (<String, String[]>)
// Remove all modifiable time parameters
parameterMap.remove(PARAM_NAME_YEAR);
parameterMap.remove(PARAM_NAME_MONTH);
parameterMap.remove(PARAM_NAME_DATE);
parameterMap.remove(PARAM_NAME_WEEK);
parameterMap.remove(PARAM_NAME_RESOURCE_URI);
// Get the resulting map's parameter string
String existingParams = getParameterString(parameterMap);
// Create the "base" link: a link to the overview page, without any time parameters
String href = cms.link(OVERVIEW_FILE) + "?" + (existingParams.length() == 0 ? "" : (existingParams + "&amp;"));


//
// Hidden parameters, used in form(s) generated by this template
//
String hiddenParams = ""; // will hold the shared form's parameter string (shared form for month/year)
String hiddenParamsHost = ""; // will hold the host form's parameter string
try {
    Iterator catItr = paramCategories.iterator();
    while (catItr.hasNext()) {
        CmsCategory hiddenCategory = (CmsCategory)catItr.next();
        hiddenParams += INPUT_HIDDEN_START + hiddenCategory.getPath() + "\" name=\"" + PARAM_NAME_CATEGORY + "\" />";
        // The host category is set in the config file, and this string is _always_ the host category's root path
        if (CmsAgent.elementExists(hostCategoryPath)) { 
            // If this isn't a host category (we allow only a single host), add the category to the host form's parameter string
            if (!hiddenCategory.getRootPath().startsWith(cmso.readResource(hostCategoryPath).getRootPath())) {
                hiddenParamsHost += INPUT_HIDDEN_START + hiddenCategory.getPath() + "\" name=\"" + PARAM_NAME_CATEGORY + "\" />";
            }
        }
        
    }
    /*
    Iterator catItr = paramCategoryStrings.iterator();
    while (catItr.hasNext()) {
        String value = (String)catItr.next();
        hiddenParams += INPUT_HIDDEN_START + value + "\" name=\"" + PARAM_NAME_CATEGORY + "\" />";
        if (CmsAgent.elementExists(hostCategoryPath)) { // The host category is set in the config file, so it is _always_ a root path
            // If this isn't a host category (we allow only one host), add the category to the host form's parameter string
            //if (!value.startsWith(cmso.readResource(hostCategoryPath).getRootPath()))
            if (!value.startsWith(catService.readCategory(cmso, hostCategoryPath, null).getPath()))
                hiddenParamsHost += INPUT_HIDDEN_START + value + "\" name=\"" + PARAM_NAME_CATEGORY + "\" />";
        }
        
    }
    */
} catch (NullPointerException npe) {
    // Ignore
}


if (CmsAgent.elementExists(hostCategoryPath)) {
    // Add time selection parameters to the host form's parameter string
    Map allParams = new HashMap(baseParamMap); // Get all parameters
    allParams.remove(PARAM_NAME_CATEGORY); // Remove category parameters
    Iterator iAllParams = allParams.keySet().iterator();
    while (iAllParams.hasNext()) {
        String key = (String)iAllParams.next();
        hiddenParamsHost += INPUT_HIDDEN_START + ((String[])allParams.get(key))[0] + "\" name=\"" + key + "\" />";
    }
}





if (displayType > 1) {
    //
    // Range view navigators
    //

    //
    // Month selection:
    //
    String monthSelect = "";
    if (range != EventCalendar.RANGE_CATCH_ALL) {
    //if (!NO_TIME_PARAMS && range != EventCalendar.RANGE_CATCH_ALL) {
        monthSelect += LABEL_MONTH + ": ";
        monthSelect += SELECT_START + PARAM_NAME_MONTH + "\" onchange=\"submit()\">";
        calendar.set(Calendar.MONTH, Calendar.JANUARY); // Set to january to enable printing of all months
        overlapLenient = true;
        sortDescending = false;
        categoryInclusive = false;
        for (int monthNo = 0; monthNo < 12; monthNo++) {
            int numMatches = 0;
            int numAllMonthsMatches = 0;
            try {
                numMatches = calendar.getEvents(EventCalendar.RANGE_CURRENT_MONTH, cms, eventsFolder, 
                                                    null, excludedEventsFolders, paramCategories, 
                                                    hideExpiredEvents, sortDescending, overlapLenient, categoryInclusive, -1).size();
                
                /*//
                // DEBUGGIN!
                //
                Iterator tempItr = calendar.getEvents(EventCalendar.RANGE_CURRENT_MONTH, cms, eventsFolder, 
                                                    null, excludedEventsFolders, paramCategories, 
                                                    hideExpiredEvents, sortDescending, overlapLenient, categoryInclusive, -1).iterator();
                out.println("\n<!-- MONTH: " + calendar.getDisplayName(Calendar.MONTH, Calendar.LONG, locale) + " -->");
                while (tempItr.hasNext()) {
                    EventEntry tempEv = (EventEntry)tempItr.next();
                    out.println("<!-- Event: " + tempEv.getTitle() + " -->");
                }
                // Done debuggin
                //*/
            } catch (NullPointerException npe) {
                // No matches, set numCatMatches to negative value
                numMatches = -1;
            }
            if (monthNo == 0) {
                try {
                    numAllMonthsMatches = calendar.getEvents(EventCalendar.RANGE_CURRENT_YEAR, cms, eventsFolder, 
                                                                null, excludedEventsFolders, paramCategories, 
                                                                hideExpiredEvents, sortDescending, overlapLenient, categoryInclusive, -1).size();
                } catch (NullPointerException npe) {  }
            }
            // Done with number of matches for this host category


            if (monthNo == 0) { // if (january)
                // Prevent "month" dropdown from showing "january" as default
                //if (NO_TIME_PARAMS)
                //    monthSelect += OPTION_START + "\"" + OPTION_SELECTED + ">" + LABEL_SELECT_MONTH + " &hellip;" + OPTION_END; // Add this
                monthSelect += OPTION_START + PARAM_TIME_VAL_ALL + "\">" + LABEL_ALL + " (" + (numAllMonthsMatches ) + ")" + OPTION_END; // Add this one before the "january" option
            }
            if (numMatches > 0 || (datedEvents.isEmpty() && m == monthNo)) {
                monthSelect += OPTION_START + calendar.get(Calendar.MONTH) + "\"";
                if (range == EventCalendar.RANGE_CURRENT_MONTH || range == EventCalendar.RANGE_CURRENT_DATE) {
                    //if (!NO_TIME_PARAMS && (m == calendar.get(Calendar.MONTH) && request.getParameter(PARAM_NAME_DATE) == null)) // Don't set a selected month when viewing specific dates (the user will be unable to select that entire month)
                    if (m == calendar.get(Calendar.MONTH) && request.getParameter(PARAM_NAME_DATE) == null) // Don't set a selected month when viewing specific dates (the user will be unable to select that entire month)
                        monthSelect += OPTION_SELECTED;
                }

                monthSelect += ">" + calendar.getDisplayName(Calendar.MONTH, Calendar.LONG, locale) + " (" + numMatches + ")" + OPTION_END;
            }
            calendar.add(Calendar.MONTH, 1);
        }
        monthSelect += SELECT_END;
        calendar.setTime(initialTime); // RESET!
    }

    //
    // Year selection:
    //
    String yearSelect = "";
    yearSelect += LABEL_YEAR + ": "; 
    yearSelect += SELECT_START + PARAM_NAME_YEAR + "\" onchange=\"submit()\">";
    
    if (!datedEvents.isEmpty()) {
        // Get a list of every single event, disregarding the range
        List allEvents = calendar.getEvents(EventCalendar.RANGE_CATCH_ALL, cms, eventsFolder, 
                                            null, excludedEventsFolders, paramCategories, 
                                            hideExpiredEvents, sortDescending, overlapLenient, categoryInclusive, -1);
        List allEventsNotUndated = calendar.getDatedEvents();
        // We need to do some trickery here to make sure we also include any expired event(s) listed under "today":
        List eventsTodayTemp = new ArrayList(eventsStartingToday); // Make a temporary list, containing all events starting today
        eventsTodayTemp.addAll(eventsOverlappingToday); // Then add all events overlapping today
        eventsTodayTemp.removeAll(allEventsNotUndated); // Then remove any events already present in "allEventsNotUndated"
        allEventsNotUndated.addAll(eventsTodayTemp); // The only events left in our temp list should now be expired events listed under "today" - add them
        Collections.sort(allEventsNotUndated, EventEntry.COMPARATOR_START_TIME);

        Calendar yearSelectStartCalendar = Calendar.getInstance();
        Calendar yearSelectEndCalendar = Calendar.getInstance();
        // The event at the last index is the last event, the list is sorted descending
        yearSelectStartCalendar.setTimeInMillis(((EventEntry)allEventsNotUndated.get(0)).getStartTime());
        //yearSelectStartCalendar.setTimeInMillis(firstDatedEvent.getStartTime());
        // Get the very last event
        EventEntry veryLastEvent = (EventEntry)allEventsNotUndated.get(allEventsNotUndated.size()-1);
        yearSelectEndCalendar.setTimeInMillis(veryLastEvent.hasEndTime() ? veryLastEvent.getEndTime() : veryLastEvent.getStartTime());
        //yearSelectEndCalendar.setTimeInMillis(lastDatedEvent.hasEndTime() ? lastDatedEvent.getEndTime() : lastDatedEvent.getStartTime());
        // Now we have the interval for the years drop-down:
        int beginYear = yearSelectStartCalendar.get(Calendar.YEAR);
        int endYear = yearSelectEndCalendar.get(Calendar.YEAR);
        
        // To provide the year range, two calendars are employed. One will hold the
        // start time of the first dated event, the other will hold either the start
        // time, or - if it exists - the end time, of the last dated event.
        /*Calendar calFirstEvent = Calendar.getInstance();
        calFirstEvent.setTimeInMillis(firstDatedEvent.getStartTime());
        Calendar calLastEvent = Calendar.getInstance();
        calLastEvent.setTimeInMillis(lastDatedEvent.hasEndTime() ? lastDatedEvent.getEndTime() : lastDatedEvent.getStartTime());
        calendar.set(Calendar.YEAR, calFirstEvent.get(Calendar.YEAR));*/
        
        
        //calendar.set(Calendar.YEAR, beginYear); // TESTING IN ATTEMPT TO MAKE ALL VALID YEARS APPEAR IN THE DROP-DOWN
        calendar.set(Calendar.YEAR, endYear); // TESTING IN ATTEMPT TO MAKE ALL VALID YEARS APPEAR IN THE DROP-DOWN
        
        out.println("<!-- YEARS INTERVAL: " + beginYear + " - " + endYear + ", range is " + range + " -->");
        
        List<String> yearOptions = new ArrayList<String>();
        
        //while (calendar.get(Calendar.YEAR) <= endYear) {
        while (calendar.get(Calendar.YEAR) >= beginYear) {
            int numMatches = 0;                  
            try {
                //if (calendar.get(Calendar.YEAR) == beginYear) {
                if (calendar.get(Calendar.YEAR) == endYear) {
                    /*if (NO_TIME_PARAMS)
                        yearSelect += OPTION_START + "\"" + OPTION_SELECTED + ">" + LABEL_SELECT_YEAR + " &hellip;" + OPTION_END;*/
                    // Add the "All" option
                    numMatches = allEvents.size();
                    yearSelect += OPTION_START + PARAM_TIME_VAL_ALL + "\"" + (range == EventCalendar.RANGE_CATCH_ALL ? OPTION_SELECTED : "") + ">" + 
                            LABEL_ALL + " (" + numMatches + ")" + OPTION_END;
                }
                // Get the events within the current year
                numMatches = calendar.getEvents(EventCalendar.RANGE_CURRENT_YEAR, cms, eventsFolder, 
                                                        undatedEventsFolders, excludedEventsFolders, paramCategories, 
                                                        hideExpiredEvents, sortDescending, overlapLenient, categoryInclusive, -1).size();

            } catch (NullPointerException npe) {
                // No matches, set numCatMatches to negative value
                numMatches = -1;
            }
            if (numMatches > 0) {
                String yearOption = OPTION_START + calendar.get(Calendar.YEAR) + "\"" + 
                        //(!NO_TIME_PARAMS && (y == calendar.get(Calendar.YEAR) && range != EventCalendar.RANGE_CATCH_ALL) ? OPTION_SELECTED : "") + ">" +
                        (y == calendar.get(Calendar.YEAR) && range != EventCalendar.RANGE_CATCH_ALL ? OPTION_SELECTED : "") + ">" +
                        calendar.get(Calendar.YEAR) + " (" + numMatches + ")" + OPTION_END;
                yearOptions.add(yearOption);
                yearSelect += yearOption;
            }
            //calendar.set(Calendar.YEAR, calendar.get(Calendar.YEAR)+1);
            calendar.set(Calendar.YEAR, calendar.get(Calendar.YEAR)-1);
            // Done with number of matches for this year
        }
    } else {
        yearSelect += OPTION_START + PARAM_TIME_VAL_ALL + "\">" + LABEL_ALL + " (" +
                calendar.getEvents(EventCalendar.RANGE_CATCH_ALL, cms, 
                                    eventsFolder, undatedEventsFolders, excludedEventsFolders, paramCategories, 
                                    hideExpiredEvents, sortDescending, overlapLenient, categoryInclusive, -1).size() + 
                ")" + OPTION_END;
        yearSelect += OPTION_START + calendar.get(Calendar.YEAR) + "\"" + OPTION_SELECTED + ">" + calendar.get(Calendar.YEAR) + OPTION_END;
    }
    yearSelect += SELECT_END;
    calendar.setTime(initialTime); // RESET!
    //yearSelect += "<option value=\"2010\"" + (y == 2010 ? OPTION_SELECTED : "") + ">2010</option>" +
    //                "<option value=\"2011\"" + (y == 2011 ? OPTION_SELECTED : "") + ">2011</option></select>";
    
    
    //
    // Expired events selection
    //
    String expSelect = "";
    //if (!NO_TIME_PARAMS) {
        expSelect += LABEL_EXPIRED + ": "; 
        expSelect += CHECKBOX_START + PARAM_NAME_EXPIRED + "\" " + (HIDE_EXPIRED_SELECTED ? "" : " checked=\"checked\"") + " style=\"margin:0;\" onchange=\"submit()\" />";
    //}


    //
    // Host selection
    //
    String hostSelect = "";
    if (CmsAgent.elementExists(hostCategoryPath)) {
        hostSelect = LABEL_HOST + ": "; // Label ("Arrangør")
        hostSelect += SELECT_START + PARAM_NAME_CATEGORY + "\" onchange=\"submit()\">";
        hostSelect += OPTION_START + "all\">" + LABEL_ALL + OPTION_END;
        ArrayList hostFilters = new ArrayList();

        List hostCategories = catService.readCategories(cmso, cms.getResourceName(hostCategoryPath), true, CATEGORIES_PATH);
        Iterator hostItr = hostCategories.iterator();
        while (hostItr.hasNext()) {
            CmsCategory hostCat = (CmsCategory)hostItr.next();
            String hostCatPath = hostCat.getPath();
            String hostName = hostCat.getTitle();
            //out.println("<!-- Current host is '" + hostName + "' -->");
            String optionState = "";
            if (paramCategories != null) {
                //if (paramCategories.contains(hostCatPath))
                if (paramCategories.contains(hostCat))
                    optionState = OPTION_SELECTED;
            }


            List catMatches;
            try {
                catMatches = new ArrayList(paramCategories);
            } catch (NullPointerException npe) {
                catMatches = new ArrayList();
            }
            // Add this host to the list of host (add the root path of the category)
            //catMatches.add(hostCat.getRootPath());
            // Add this host to the list of host (add the category)
            catMatches.add(hostCat);

            // Determine the number of matches for this category (or: this how many events this host is hosting)
            int numCatMatches = 0;

            // Get the number of dated events
            try {
                int datedCatMatches = calendar.getEvents(range, cms,
                                                    eventsFolder, undatedEventsFolders, excludedEventsFolders, catMatches, 
                                                    hideExpiredEvents, sortDescending, overlapLenient, categoryInclusive, -1).size();
                numCatMatches = datedCatMatches;
                //out.println("<!-- Dated matches for '" + hostName + "': " + datedCatMatches + " -->");
            } catch (NullPointerException npe) {
                // No matches, set numCatMatches to negative value
                numCatMatches = -1;
            }
            // Get the number of matches in undated events (if an undated events folder exists, and the range is set so that undated events are listed)
            if (!noDateEvents.isEmpty() && (range == EventCalendar.RANGE_CURRENT_YEAR || range == EventCalendar.RANGE_CATCH_ALL)) {
                try {
                    int undatedCatMatches = calendar.getEvents(0, Integer.MAX_VALUE, cms, 
                                                undatedEventsFolder, null, excludedEventsFolders, catMatches, 
                                                false, sortDescending, overlapLenient, categoryInclusive, -1).size();
                    numCatMatches += undatedCatMatches;
                    //out.println("<!-- Undated matches for '" + hostName + "': " + undatedCatMatches + " -->");
                } catch (NullPointerException npe) {
                    // Sustain previous value for numCatMatches
                    //out.println("<!-- NPE when retrieving undated matches -->");
                }

            }
            // Done with number of matches for this host category

            if (numCatMatches > 0) {
                // Shorten host name to max. length
                if (hostName.length() > MAXLENGTH_HOST)
                    hostName = hostName.substring(0, MAXLENGTH_HOST).concat("...");
                // Append an option to filter by this host category
                // NB! The initial comment (sortComment) is VITAL for sorting!
                String sortComment = "";
                if (categoriesSort == SORT_MODE_RELEVANCY)
                    sortComment = "<!-- " + (numCatMatches < 10 ? ("0" + numCatMatches) : numCatMatches) + " -->";
                else if (categoriesSort == SORT_MODE_TITLE) 
                    sortComment = "<!-- " + hostName + " -->";
                hostFilters.add(new String(sortComment +
                        OPTION_START + hostCatPath + "\"" + optionState + ">" + hostName + " (" + numCatMatches + ")" + OPTION_END));
            }


        }
        // Sort the host filters according to number of matches
        if (!hostFilters.isEmpty()) {
            Collections.sort(hostFilters);
            if (categoriesSort == SORT_MODE_RELEVANCY)
                Collections.reverse(hostFilters);
            Iterator itr = hostFilters.iterator();
            while(itr.hasNext()) {
                hostSelect += (String)itr.next();
            }
        }
        hostSelect += SELECT_END;
        hostSelect += hiddenParamsHost;
    }



    out.println("<div class=\"view-select\">");
    out.println("<form name=\"viewselect\" action=\"" + cms.link(OVERVIEW_FILE) + "\" method=\"get\">");
    out.println("<div class=\"view-option\">" + yearSelect + "</div>");
    if (!monthSelect.isEmpty())
        out.println("<div class=\"view-option\">" + monthSelect + "</div>");
    if (!expSelect.isEmpty())
        out.println("<div class=\"view-option\"><label>" + expSelect + "</label></div>");
    out.println(hiddenParams);
    out.println("</form>");
    if (CmsAgent.elementExists(hostCategoryPath) && hostSelect.length() > 0) {
        out.println("<form name=\"hostselect\" action=\"" + cms.link(OVERVIEW_FILE) + "\" method=\"get\">");
        out.println("<div class=\"view-option\">" + hostSelect + "</div>");
        out.println("</form>");
    }
    
    /*
    if (!FULL_LIST) {
        out.println("<div class=\"view-option\">"
                        + "<a href=\"" + cms.link(requestFileUri) + "?" 
                            + PARAM_NAME_YEAR + "=" + PARAM_YEAR_VAL_ALL 
                            + (HIDE_EXPIRED_SELECTED ? "" : "&amp;exp=on")
                            + "\" rel=\"nofollow\">" + LABEL_VIEW_ALL + "</a>"
                    + "</div>");
    }
    */
    out.println("</div><!-- .view-select -->");
}







// Set the date to the 1st before proceeding to print the calendar
calendar.set(Calendar.DATE, MONTH_START_DATE);  
//out.println("<h5>Initializing calendar print. Time is set to " + sqlFormat.format(calendar.getTime()) + ". Range is set to " + range + ".</h5>");


//
// Set up the links to previous / next month.
//
String existingParamsString = (existingParams.length() > 0 ? ("&amp;" + existingParams) : ""); // Start with the ampersand if there are any params
String prevMonthLink = requestFileUri + "?" + calendar.getParameterString(EventCalendar.PARAMETER_TYPE_PREV_MONTH) + existingParamsString;
String nextMonthLink = requestFileUri + "?" + calendar.getParameterString(EventCalendar.PARAMETER_TYPE_NEXT_MONTH) + existingParamsString;
String currMonthLink = OVERVIEW_FILE +  "?" + calendar.getParameterString(EventCalendar.PARAMETER_TYPE_CURRENT_MONTH) + existingParamsString;

//
// Set up the AJAX links to previous / next month.
//
String ajaxParams = "";
ajaxParams += (cms.elementExists(calendarAddClass) ? "&amp;" + PARAM_NAME_CALENDAR_CLASS + "=" + calendarAddClass : "") +
                "&amp;" + PARAM_NAME_DESCRIPTIONS + "=" + showEventDescription +
                // Always show all events in the calendar, even if set to "hide expired"
                "&amp;" + PARAM_NAME_HIDE_EXPIRED + "=" + false +
                //"&amp;" + PARAM_NAME_HIDE_EXPIRED + "=" + hideExpiredEvents +
                (cmso.existsResource(OVERVIEW_FILE) ? "&amp;" + PARAM_NAME_OVERVIEW + "=" + OVERVIEW_FILE : "") +
                "&amp;" + PARAM_NAME_WEEK_NUMBERS + "=" + showWeekNumbers +
                "&amp;" + PARAM_NAME_EVENTS_FOLDER + "=" + eventsFolder +
                "&amp;" + PARAM_NAME_CATEGORY_PATH + "=" + CATEGORIES_PATH + //categoryPath +
                "&amp;" + PARAM_NAME_LABEL_SINGULAR + "=" + LABEL_EVENT + 
                "&amp;" + PARAM_NAME_LABEL_PLURAL + "=" + LABEL_EVENTS + 
                "&amp;" + PARAM_NAME_LOCALE + "=" + locale.toString();
                Iterator excludedFoldersItr = excludedEventsFolders.iterator();
                while (excludedFoldersItr.hasNext()) {
                    ajaxParams += "&amp;" + PARAM_NAME_EXCLUDE_FOLDER + "=" + excludedFoldersItr.next();
                }
String prevMonthAjaxUri = cms.link(AJAX_EVENTS_PROVIDER) + "?" + calendar.getParameterString(EventCalendar.PARAMETER_TYPE_PREV_MONTH) + ajaxParams;
String nextMonthAjaxUri = cms.link(AJAX_EVENTS_PROVIDER) + "?" + calendar.getParameterString(EventCalendar.PARAMETER_TYPE_NEXT_MONTH) + ajaxParams;

    
    
//
// Print the calendar
//
boolean hiddenCalendar = range == EventCalendar.RANGE_CURRENT_YEAR || range == EventCalendar.RANGE_CATCH_ALL;
if (displayType > 3)
    hiddenCalendar = true;


if (displayType == 0 || displayType == 1) { // For these display-types, we need a container that can be populated with AJAX
    out.println("<div id=\"events-month-list\">");
}

if (displayType > 0) {
    out.println("<div class=\"calendar-wrap\">"); // Don't print the wrapper if we're in "calendar only" mode
}

if (!hiddenCalendar) {
    // Calendar heading. E.g.: January 2010
    String calendarHeading = calendar.getDisplayName(Calendar.MONTH, Calendar.LONG, locale) + " " + calendar.get(Calendar.YEAR);
    // Make the calendar heading a link, if it should be
    if (CmsAgent.elementExists(calendarLinkPath))
        calendarHeading = "<a href=\"" + cms.link(currMonthLink) + "\" rel=\"nofollow\">" + calendarHeading + "</a>";
    
    // Calendar heading: the month name and links to previous / next month
    out.println("<table class=\"calendar" + (CmsAgent.elementExists(calendarAddClass) ? (" " + calendarAddClass) : "") + "\"" +
                        //" border=\"0\" cellspacing=\"0\" cellpadding=\"0\"" + // These attributes are obsolete in HTML5, replaced with CSS
                        ">" +
            "<tr class=\"calendar-head\">" +
            "<th class=\"calendar-navi\">" +
                //"<a class=\"button\" href=\"" + cms.link(prevYearLink) + "\">&lt;&lt;</a>" +
                (displayType <= 1 ?
                    "<a onclick=\"loadMonth('" + cms.link(prevMonthAjaxUri) + "')\" rel=\"nofollow\">&laquo;</a>" :
                    "<a href=\"" + cms.link(prevMonthLink) + "\" rel=\"nofollow\">&laquo;</a>") +
            "</th>" +
            "<th class=\"month\" colspan=\"" + (showWeekNumbers ? "6" : "5") + "\">" +
                //calendar.getDisplayName(Calendar.MONTH, Calendar.LONG, locale) + " " + calendar.get(Calendar.YEAR) + 
                calendarHeading +
            "</th>" +
            "<th class=\"calendar-navi\">" +
                (displayType <= 1 ?
                    "<a onclick=\"loadMonth('" + cms.link(nextMonthAjaxUri) + "')\" rel=\"nofollow\">&raquo;</a>" :
                    "<a href=\"" + cms.link(nextMonthLink) + "\" rel=\"nofollow\">&raquo;</a>") +
                //"<a class=\"button\" href=\"" + cms.link(nextYearLink) + "\">&gt;&gt;</a>" +
            "</th>" +
            "</tr>" +
            // Print the weekday names
            "<tr class=\"calendar-head weekday-names\">" + 
            (showWeekNumbers ? "<td class=\"weeklabel\">" + cms.label("label.for.np_event.week") + "</td>" : ""));

    // Step back to the first day of the previous week, keep the number of days since that day.
    // (If the current month does not start with a weekday that is the first weekday of the month,
    // this means that we're jumping to one of the last days of the previous month)
    daysSincePrevWeekStart = calendar.timeWarp(EventCalendar.WARP_FIRST_DAY_OF_PREV_WEEK); 

    // Print out the 7 weekday names, starting with the first day of the week (that's the current day at the loop start)
    for (int i = 0; i < 7; i++) {
        out.println("<td>" + calendar.getDisplayName(Calendar.DAY_OF_WEEK, Calendar.SHORT, locale) + "</td>");
        calendar.add(Calendar.DATE, 1); // Move forward to the next day
    }
    out.println("</tr>"); // End the <tr> of weekday names

    // Get the start week of the current month
    monthStartWeek = calendar.get(Calendar.WEEK_OF_YEAR);

    // Loop while we're in the same month OR in the first week of the month (we'll print out the last days of the last month if 
    // this month does not start with a weekday equal to FIRST_DAY_OF_WEEK)
    while (calendar.get(Calendar.MONTH) == month || calendar.get(Calendar.WEEK_OF_YEAR) == monthStartWeek) {
        week = calendar.get(Calendar.WEEK_OF_YEAR);
        out.println("<tr class=\"week\">");
        if (calendar.get(Calendar.DAY_OF_WEEK) == calendar.getFirstDayOfWeek() && showWeekNumbers)
            out.print("<td class=\"week-of-year\">" + 
                        (CmsAgent.elementExists(calendarLinkPath) ?
                            ("<a href=\"" + href + PARAM_NAME_WEEK + "=" + calendar.get(Calendar.WEEK_OF_YEAR) + 
                            "&amp;" + PARAM_NAME_YEAR + "=" + calendar.get(Calendar.YEAR) + 
                            "&amp;" + existingParams + 
                            "\" rel=\"nofollow\">" + calendar.get(Calendar.WEEK_OF_YEAR) + "</a>")
                            : 
                            calendar.get(Calendar.WEEK_OF_YEAR)) + 
                        "</td>");

        while (calendar.get(Calendar.WEEK_OF_YEAR) == week) {
            out.print("<td"); // Start this day's table cell

            sortDescending = true;
            List todaysEvents = new ArrayList();
            // Always show ALL events (including expired) in the calendar, even if set to "hide expired events"
            try {
                todaysEvents.addAll(calendar.getEvents(EventCalendar.RANGE_CURRENT_DATE, cms, 
                                                    eventsFolder, undatedEventsFolders, excludedEventsFolders, paramCategories, 
                                                    false, sortDescending, overlapLenient, categoryInclusive, -1));
            } catch (NumberFormatException nfe) {
                // Bug? WTF???
            }
            /*List todaysEvents = calendar.getEvents(EventCalendar.RANGE_CURRENT_DATE, cms, 
                                                    eventsFolder, undatedEventsFolders, excludedEventsFolders, paramCategories, 
                                                    false, sortDescending, overlapLenient, categoryInclusive, -1);*/
            /*List todaysEvents = calendar.getEvents(EventCalendar.RANGE_CURRENT_DATE, cms, 
                                                    eventsFolder, undatedEventsFolders, excludedEventsFolders, paramCategories, 
                                                    hideExpiredEvents, sortDescending, overlapLenient, categoryInclusive, -1);*/
            sortDescending = false;

            EventEntry event = null;

            if (todaysEvents.size() > 0) {
                dayViewLink = "<a href=\"" + cms.link(OVERVIEW_FILE) + "?" +
                        PARAM_NAME_YEAR + "=" + calendar.get(Calendar.YEAR) + "&amp;" + 
                        PARAM_NAME_MONTH + "=" + calendar.get(Calendar.MONTH) + "&amp;" + 
                        PARAM_NAME_DATE + "=" + calendar.get(Calendar.DATE) + "&amp;" + 
                        existingParams + "\" rel=\"nofollow\">" + 
                        calendar.get(Calendar.DATE) + "</a>";
                Iterator eventsItr = todaysEvents.iterator();
                while (eventsItr.hasNext()) {
                    event = (EventEntry)eventsItr.next();
                    if (event.getHtml() != null) {
                        eventsHtml += (String)event.getHtml(); // Add HTML
                    }
                }
            }
            if (eventsHtml.length() > 0) {
                eventsHtml = "<div class=\"day-info\">" + eventsHtml + "</div>";
                // ToDo: Replace all ' inside the string
                out.print(" onmouseover=\"return overlib('" + 
                        //CmsStringUtil.escapeHtml(eventsHtml) + 
                        //CmsHtmlExtractor.extractText(eventsHtml, "utf-8").replaceAll("'", "\\'") + 
                        CmsStringUtil.escapeHtml(eventsHtml).replaceAll("'", "\\\\'") + 
                        "');\" onmouseout=\"return nd();\"");
            }
            out.print(calendar.get(Calendar.MONTH) != month ? 
                (calendar.get(Calendar.MONTH) == month - 1 ? " class=\"nodate previous\"" : " class=\"nodate next\"") : "");

            boolean isSelected = range == EventCalendar.RANGE_CURRENT_DATE && 
                                    (calendar.get(Calendar.DATE) == d && calendar.get(Calendar.MONTH) == m && calendar.get(Calendar.YEAR) == y);
            if (isSelected || calendar.representsToday()) {
                out.print(" class=\"");
                out.print(calendar.representsToday() ? "today" : "");
                if (isSelected) {
                    out.print((calendar.representsToday() ? " " : "") + "selected"); // Make a space before "selected" if the class is already "today"
                }
                out.print("\"");
            }
            out.print(">" + (eventsHtml.length() > 0 ? dayViewLink : String.valueOf(calendar.get(Calendar.DATE))) + "</td>");
            calendar.add(Calendar.DATE, 1);
            eventsHtml = "";
        }

        out.print("</tr>");
    }
    out.print("</table>");
} // if (view is monthview or dayview)







calendar.setTime(initialTime);

if (displayType > 0) {
    out.println("</div><!-- .calendar-wrap  -->");
    
    // Get the string of parameters (if any)
    String baseParamString = getParameterString(baseParamMap);
    
    //
    // Print events list(s)
    //
    /*if (range == EventCalendar.RANGE_CATCH_ALL || range == EventCalendar.RANGE_CURRENT_YEAR) {
        if (numCurrentRangeEvents > 0 && numNoDateEvents > 0) {
            out.println("<h2>" + numEvents + " " + 
                    (numEvents == 1 ? LABEL_EVENT.toLowerCase() : LABEL_EVENTS.toLowerCase()) + ":</h2>");
        }
    }*/
    // Removed this one
    
    /*
    if (numEvents > 0) {
        out.println("<h3>" + numEvents + " " + 
                    (numEvents == 1 ? LABEL_EVENT.toLowerCase() : LABEL_EVENTS.toLowerCase()) + ":</h3>");
    }
    */
    
    // Table start (common for dated and undated events)
    // This code begins the HTML for the table and prints the first row (containing the table headers)
    String eventTableStart = "<table class=\"events\"><tbody>";
    eventTableStart += "<tr><th>" + LABEL_TIME + "</th><th>" + LABEL_EVENT + "</th>";
    if (!displayCategories.isEmpty()) {
        Iterator iDispCat = displayCategories.iterator();
        while (iDispCat.hasNext()) {
            CmsCategory dispCat = (CmsCategory)iDispCat.next();
            eventTableStart += "<th>" + dispCat.getTitle() + "</th>";
        }
    }
    eventTableStart += "</tr>";
    
    String expiredHeading = LABEL_FINISHED;
    
    // Debug:
    //out.println("<h5>datedEvents.isEmpty() = " + Boolean.toString(datedEvents.isEmpty()) + " </h5>");
    
    // Dated events
    if (!datedEvents.isEmpty()) {
        
        // Set up the string describing what list is displaying
        String datedRangeListHeading = null;
        // Also, set up a string to use for the sections within the list of dated events
        String datedRangeSubListHeading = null;

        if (range == EventCalendar.RANGE_CURRENT_DATE) {
            headingDate = new SimpleDateFormat(cms.label("label.event.dateformat.full"), locale);
            datedRangeListHeading = headingDate.format(calendar.getTime()); // E.g. "August 15, 2011"
        }
        else if (range == EventCalendar.RANGE_CURRENT_MONTH) {
            headingDate = new SimpleDateFormat(cms.label("label.event.dateformat.month"), locale);
            datedRangeListHeading = headingDate.format(calendar.getTime()); // E.g. "August"
        }
        else if (range == EventCalendar.RANGE_CURRENT_YEAR) {
            datedRangeListHeading = Integer.toString(calendar.get(Calendar.YEAR)); // E.g. "2011"
        }
        else if (range == EventCalendar.RANGE_CURRENT_WEEK) {
            datedRangeListHeading = cms.label("label.for.np_event.week") + " " + calendar.get(Calendar.WEEK_OF_YEAR) + " " + calendar.get(Calendar.YEAR); // E.g. "Week 12 2011"
        }
        else if (range == EventCalendar.RANGE_CATCH_ALL) {
            //datedRangeListHeading = CmsAgent.elementExists(undatedEventsFolder) ? LABEL_ALL_DATED : "";
            datedRangeListHeading = CmsAgent.elementExists(undatedEventsFolder) ? LABEL_ONGOING_AND_UPCOMING : "";
        }
        datedRangeSubListHeading = datedRangeListHeading;
        datedRangeListHeading += datedRangeListHeading.isEmpty() ? "" : ": ";
        datedRangeListHeading = datedRangeListHeading + numCurrentRangeEvents + "&nbsp;" +
                        (numCurrentRangeEvents == 1 ? LABEL_EVENT.toLowerCase() : LABEL_EVENTS.toLowerCase());
        datedRangeListHeading = datedRangeListHeading.substring(0, 1).toUpperCase() + datedRangeListHeading.substring(1); // Capitalize

        // Removed this heading for table view
        if (displayType < 1)
            out.println("<h3 class=\"event-list-heading\">" + datedRangeListHeading + "</h3>");

        String inRangeHeading = range == EventCalendar.RANGE_CURRENT_DATE ? (LABEL_STARTS + " " + datedRangeSubListHeading) : (range == EventCalendar.RANGE_CATCH_ALL ? LABEL_UPCOMING.concat(NO_TIME_PARAMS ? "" : " " + LABEL_IN) : (LABEL_STARTS_IN + " ")) + datedRangeSubListHeading;
        switch (range) {
            case (EventCalendar.RANGE_CURRENT_DATE):
                inRangeHeading = LABEL_STARTS + " " + datedRangeSubListHeading;
                break;
            default:
                inRangeHeading = LABEL_UPCOMING.concat(datedRangeSubListHeading.isEmpty() ? "" : " " + LABEL_IN + " ") + datedRangeSubListHeading;
                break;
        }
        
        expiredHeading = (PARAM_DATE_SET ? LABEL_FINISHED : LABEL_FINISHED_IN) + " " + datedRangeSubListHeading;
        
        //
        // List of dated events. Table for rich listings, list for simpler listings
        //
        if (displayType > 1) { // Option 1: as a table
            //printEventsTable(cms, datedEvents, null, eventTableStart, showEventDescription, true, df, baseParamString, displayCategories, CATEGORIES_PATH, out);
            // More user-friendly listing: differenciate collections of events
            
            out.println("<!-- Now printing events list (as a table). NO_TIME_PARAMS is '" + NO_TIME_PARAMS + "' -->");
            
            if (rangeIncludesToday 
                    //&& !eventsStartingToday.isEmpty()  // Require that there is at least one event ocurring today
                    //&& !PARAM_DATE_SET // Don't print this list if we're viewing the list for a specific date
                    //&& NO_TIME_PARAMS
                    ) {
                out.println("<h3 id=\"h-events-start-today\">" + LABEL_TODAY + "</h3>");
                if (eventsStartingToday.isEmpty()) 
                    out.println("<p>" + LABEL_NONE + "</p>");
                else {
                    //printEventsTable(cms, eventsStartingToday, null, eventTableStart, showEventDescription, true, df, baseParamString, displayCategories, CATEGORIES_PATH, out);
                    List<EventEntry> eventsStartingAndOverlappingToday = new ArrayList<EventEntry>();
                    eventsStartingAndOverlappingToday.addAll(eventsStartingToday);
                    eventsStartingAndOverlappingToday.addAll(eventsOverlappingToday);
                    printEventsTable(cms, eventsStartingAndOverlappingToday, null, eventTableStart, showEventDescription, true, df, baseParamString, displayCategories, CATEGORIES_PATH, out);
                }
            }
            //if (NO_TIME_PARAMS) {
                /*if (rangeIncludesToday && !eventsNextAfterToday.isEmpty()) {
                    out.println("<h3 id=\"h-events-next\">" + LABEL_IN_PROGRESS + "</h3>");
                    printEventsTable(cms, eventsOverlappingToday, null, eventTableStart, showEventDescription, true, df, baseParamString, displayCategories, CATEGORIES_PATH, out);
                }*/
                /*
                if (!eventsNextAfterToday.isEmpty() // Require that there is at least one "next" event
                        //&& rangeIncludesToday 
                        ) {
                    out.println("<h3 id=\"h-events-next\">" + LABEL_UPCOMING + "</h3>");
                    printEventsTable(cms, eventsNextAfterToday, null, eventTableStart, showEventDescription, true, df, baseParamString, displayCategories, CATEGORIES_PATH, out);
                }
                */
            //} 
            //else {
                // 1: events starting in range (begginging this year/month/week/date)
                if (!eventsStartingInRange.isEmpty()) {
                    out.println("<h3 id=\"h-events-start-in-range\">" + inRangeHeading + "</h3>");
                    printEventsTable(cms, eventsStartingInRange, null, eventTableStart, showEventDescription, true, df, baseParamString, displayCategories, CATEGORIES_PATH, out);
                }
                // 2: events overlapping current range (started earlier)
                if (!eventsOverlappingRange.isEmpty()) {
                    out.println("<h3 id=\"h-events-overlapping-range\">" + LABEL_IN_PROGRESS + "</h3>");
                    printEventsTable(cms, eventsOverlappingRange, null, eventTableStart, showEventDescription, true, df, baseParamString, displayCategories, CATEGORIES_PATH, out);
                }
                // 3: Expired events (only for listings other than "catch all" - for that list, we'll show expired events at the very bottom)
                if (!eventsExpired.isEmpty() && range != EventCalendar.RANGE_CATCH_ALL) {
                    out.println("<h3 id=\"h-events-expired\">" + expiredHeading + "</h3>");
                    printEventsTable(cms, eventsExpired, null, eventTableStart, showEventDescription, true, df, baseParamString, displayCategories, CATEGORIES_PATH, out);
                }
            //}
            /*// 4: undated events (if any), ordered by title
            if (!noDateEvents.isEmpty()) {
                if (range == EventCalendar.RANGE_CURRENT_YEAR || range == EventCalendar.RANGE_CATCH_ALL) {
                    Collections.sort(noDateEvents, EventEntry.COMPARATOR_TITLE);
                    String noDateListHeading = (numNoDateEvents == 0 ? LABEL_NO_EVENTS : 
                                                    (numNoDateEvents + " " + (numNoDateEvents == 1 ? LABEL_EVENT.toLowerCase() : LABEL_EVENTS.toLowerCase()))) + 
                                                    " " + LABEL_WITHOUT_DATE + (numNoDateEvents == 0 ? "." : ":");
                    out.println("<h3>" + noDateListHeading + "</h3>");
                    printEventsTable(cms, noDateEvents, 
                            "<em>" + LABEL_DATE_NOT_DETERMINED + "</em>", eventTableStart, 
                            showEventDescription, false, df, baseParamString, displayCategories, CATEGORIES_PATH, out);
                }
            } // End of "undated events" list
            */
        }
        else { // Option 2: as a list
            // Today's events
            
            if (rangeIncludesToday && !eventsStartingToday.isEmpty()) {
                printEventsList(cms, eventsStartingToday, null, LABEL_TODAY, showEventDescription, df, baseParamString, displayCategories, CATEGORIES_PATH, out);
            }
            
            // Events in range (besides today, if today is inside the range)
            if (!eventsStartingInRange.isEmpty()) {
                //printEventsList(cms, eventsStartingInRange, null, LABEL_UPCOMING, showEventDescription, df, baseParamString, displayCategories, CATEGORIES_PATH, out);
                printEventsList(cms, eventsStartingInRange, null, inRangeHeading, showEventDescription, df, baseParamString, displayCategories, CATEGORIES_PATH, out);
            }
            
            // Events in progress
            if (!eventsOverlappingRange.isEmpty()) {
                printEventsList(cms, eventsOverlappingRange, null, LABEL_IN_PROGRESS, showEventDescription, df, baseParamString, displayCategories, CATEGORIES_PATH, out);
            }
            
            if (displayType == 0 || displayType == 1) { // Do this only for calendar only display modes
                // First, set the range to "current month" by calling getEvents
                calendar.getEvents(EventCalendar.RANGE_CURRENT_MONTH, cms, eventsFolder,
                                                undatedEventsFolders, excludedEventsFolders, paramCategories,
                                                hideExpiredEvents, sortDescending, overlapLenient, categoryInclusive, 1);
                // Then determine if the actual today is currently represented in the calendar.
                // (This is a prerequisite for displaying the "next" list.)
                boolean calendarContainsToday = new Date().getTime() > calendar.getRangeStart() && new Date().getTime() < calendar.getRangeEnd();
                int eventsInList = eventsStartingToday.size() + eventsStartingInRange.size() + eventsOverlappingRange.size();
                if (calendarContainsToday) {
                    if (eventsInList <= 1) {
                        // ... then we'll look for the next event
                        List<EventEntry> nextEvents = new ArrayList<EventEntry>();
                        // Set overlap lenient mode to "false":
                        overlapLenient = false;
                        // We'll check each one of the next upcoming months, one by one: Keep count of how many months ahead we've checked
                        int monthsAheadChecked = 0;
                        while (nextEvents.isEmpty() && monthsAheadChecked < 36) { // Use the month check to prevent an infinite loop here!
                            try {
                                // Look at next month
                                calendar.add(Calendar.MONTH, 1);
                                // Get events in current range, NON-LENIENT overlap mode 
                                // (This will exclude events that start before the range and stretches into the range)
                                nextEvents.addAll(calendar.getEvents(EventCalendar.RANGE_CURRENT_MONTH, cms, eventsFolder,
                                                    undatedEventsFolders, excludedEventsFolders, paramCategories,
                                                    hideExpiredEvents, sortDescending, overlapLenient, categoryInclusive, -1));
                            } 
                            catch (java.lang.NumberFormatException nfe) {
                                // Bug? WTF?
                            }
                            monthsAheadChecked++;
                        }
                        
                        /*while (nextEvents.isEmpty()) { // Why don't we create an infinite loop here! x)
                            try {
                                // Look at next month
                                calendar.add(Calendar.MONTH, 1);
                                // Get events in current range, NON-LENIENT overlap mode 
                                // (This will exclude events that start before the range and stretches into the range)
                                nextEvents.addAll(calendar.getEvents(EventCalendar.RANGE_CURRENT_MONTH, cms, eventsFolder,
                                                    undatedEventsFolders, excludedEventsFolders, paramCategories,
                                                    hideExpiredEvents, sortDescending, overlapLenient, categoryInclusive, -1));
                            } 
                            catch (java.lang.NumberFormatException nfe) {
                                // No future events
                                out.println("<!-- NO FUTURE EVENTS! -->");
                                futureEventsExist = false;
                            }
                        }*/
                        calendar.setTime(initialTime); // Reset calendar
                        
                        if (!nextEvents.isEmpty()) {
                            // Sort
                            Collections.sort(nextEvents, EventEntry.COMPARATOR_START_TIME);
                            // Print the next events
                            printEventsList(cms, nextEvents.subList(0, 1), null, LABEL_NEXT, showEventDescription, df, baseParamString, displayCategories, CATEGORIES_PATH, out);
                        }
                    }
                }
            }
            
            // Expired events
            if (!eventsExpired.isEmpty()) {
                //printEventsList(cms, eventsExpired, null, LABEL_EXPIRED, showEventDescription, df, baseParamString, displayCategories, CATEGORIES_PATH, out);
                printEventsList(cms, eventsExpired, null, expiredHeading, showEventDescription, df, baseParamString, displayCategories, CATEGORIES_PATH, out);
            }
        }
    }
    else { // datedEvents was empty - print the "next" list
        out.println("<!-- datedEvents was empty -->");
        if (displayType == 0 || displayType == 1) { // Do this only for calendar only display modes
            // First, set the range to "current month" by calling getEvents
            calendar.getEvents(EventCalendar.RANGE_CURRENT_MONTH, cms, eventsFolder,
                                            undatedEventsFolders, excludedEventsFolders, paramCategories,
                                            hideExpiredEvents, sortDescending, overlapLenient, categoryInclusive, 1);
            // Then determine if the actual today is currently represented in the calendar.
            // (This is a prerequisite for displaying the "next" list.)
            boolean calendarContainsToday = new Date().getTime() > calendar.getRangeStart() && new Date().getTime() < calendar.getRangeEnd();
            if (calendarContainsToday) {
                List<EventEntry> nextEvents = new ArrayList<EventEntry>();
                // Set overlap lenient mode to "false":
                overlapLenient = false;
                while (nextEvents.isEmpty()) {
                    // Look at next month
                    calendar.add(Calendar.MONTH, 1);
                    // Get events in current range, NON-LENIENT overlap mode 
                    // (This will exclude events that start before the range and stretches into the range)
                    nextEvents.addAll(calendar.getEvents(EventCalendar.RANGE_CURRENT_MONTH, cms, eventsFolder,
                                        undatedEventsFolders, excludedEventsFolders, paramCategories,
                                        hideExpiredEvents, sortDescending, overlapLenient, categoryInclusive, -1));
                }
                calendar.setTime(initialTime); // Reset calendar
                // Sort
                Collections.sort(nextEvents, EventEntry.COMPARATOR_START_TIME);
                // Print the next events
                //out.println("<p><em>" + LABEL_NONE_THIS_MONTH + "</em></p>");
                printEventsList(cms, nextEvents.subList(0, 1), null, LABEL_NEXT, showEventDescription, df, baseParamString, displayCategories, CATEGORIES_PATH, out);
            }
        }
    }
    if (displayType == 0 || displayType == 1) { // Then we need to end the AJAX content container
        out.println("</div><!-- #events-month-list -->");
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    //
    // Section: Undated events - events whose start date has yet to be determined
    //
    
    // Don't print the next section if the config is missing an undated events folder
    if (!noDateEvents.isEmpty()) {
        if (range == EventCalendar.RANGE_CURRENT_YEAR || range == EventCalendar.RANGE_CATCH_ALL) {
            Collections.sort(noDateEvents, EventEntry.COMPARATOR_TITLE);
            String noDateListHeading = (numNoDateEvents == 0 ? LABEL_NO_EVENTS : 
                                            (numNoDateEvents + " " + (numNoDateEvents == 1 ? LABEL_EVENT.toLowerCase() : LABEL_EVENTS.toLowerCase()))) + 
                                            " " + LABEL_WITHOUT_DATE + (numNoDateEvents == 0 ? "." : ":");
            out.println("<h3>" + noDateListHeading + "</h3>");
            //
            // List of undated events. Table for rich listings, lists for simpler listings
            //
            if (displayType > 1) { // Option 1: as a table
                printEventsTable(cms, noDateEvents, "<em>" + LABEL_DATE_NOT_DETERMINED + "</em>", eventTableStart, showEventDescription, false, df, baseParamString, displayCategories, CATEGORIES_PATH, out);
            }
            else { // Option 2: as a list
                if (!noDateEvents.isEmpty()) {
                    printEventsList(cms, noDateEvents, "<em>" + LABEL_DATE_NOT_DETERMINED + "</em>", LABEL_WITHOUT_DATE, showEventDescription, df, baseParamString, displayCategories, CATEGORIES_PATH, out);
                }
            }
        }
    } // End of "undated events" list
    
    
    // Expired events for "catch all" view
    if (!eventsExpired.isEmpty() && range == EventCalendar.RANGE_CATCH_ALL) {
        expiredHeading = LABEL_FINISHED;
        out.println("<h3 id=\"h-events-expired\">" + expiredHeading + "</h3>");
        printEventsTable(cms, eventsExpired, null, eventTableStart, showEventDescription, true, df, baseParamString, displayCategories, CATEGORIES_PATH, out);
    }
    
    
    //
    // Category navigation, moved to right hand side + disabled the calendar
    //
    if (includeTemplate)
        out.println("</div><!-- .twocol -->");
}












if (displayType > 2 && displayType < 5) {
        
    out.println("<div class=\"onecol\">");
    //
    // Category navigation
    //
    if (DEBUG) { out.println("<!-- Filter sets: " + catFilterSets.size() + " -->"); }
    
    // Get the parameter string for the current request
    String parameterString = getParameterString(baseParamMap);
    
    Iterator<String> iCatFilterSets = catFilterSets.keySet().iterator();
    while (iCatFilterSets.hasNext()) {
        try {
            CategoryFilterSet set = catFilterSets.get(iCatFilterSets.next());
            List<CategoryFilter> filters = set.getCategoryFilters();
            if (filters != null) {
                Iterator<CategoryFilter> iFilters = filters.iterator();
                if (iFilters.hasNext()) {
                    String filtersHtml = "";
                    while (iFilters.hasNext()) {
                        CategoryFilter filter = iFilters.next();
                        
                        // Create a flag: Don't print category filters that should be excluded
                        boolean hideCategoryFilter = false;
                        Iterator<CmsCategory> noShowItr = excludedNavCategories.iterator();
                        while (noShowItr.hasNext()) {
                            if (isCategoryOrSubCategory(filter.getCategory(), noShowItr.next())) {
                                hideCategoryFilter = true; // This filter is for an excluded category: hide it
                                break; // No need to continue
                            }
                        }
                        if (!hideCategoryFilter) {
                            String filterLink = "";
                            if (parameterString.contains(filter.getUri())) {
                                filterLink = "<a style=\"font-weight:bold;\" class=\"remove\" href=\"" + cms.link(OVERVIEW_FILE) + "?" + parameterString;
                                filterLink = filterLink.replace(PARAM_NAME_CATEGORY + "=".concat(filter.getUri()), "");
                                filterLink = filterLink.replace("&amp;&amp;", "&amp;"); // If multiple categories were in the URL, we just created "&&"
                                filterLink = filterLink.endsWith("?") ? filterLink.substring(0, filterLink.length() - 1) : filterLink; // Remove trailing ?
                                filterLink = filterLink.endsWith("&amp;") ? filterLink.substring(0, filterLink.length() - 5) : filterLink; // Remove trailing &
                                filterLink += "\" rel=\"nofollow\">" + filter.getName() + " <span class=\"remove-filter\""
                                            + " style=\"background:red; border-radius:3px; color:white; padding:0 0.3em;\""
                                            + ">X</span></a>";
                            }
                            else {
                                filterLink = "<a href=\"" + cms.link(OVERVIEW_FILE) + "?" + 
                                                            parameterString + "&amp;" + PARAM_NAME_CATEGORY + "=" + filter.getUri() + "\" rel=\"nofollow\">" + 
                                                            filter.getName() + " (" + filter.getCounter() + ")</a>";
                            }
                            filtersHtml += "<li>" + filterLink + "</li>";
                        }
                    }
                    if (!filtersHtml.isEmpty()) {
                        out.println("<h4>" + set.getTitle() + "</h4>");
                        out.println("<ul>" + filtersHtml + "</ul>");
                    }
                } else {
                    // No filters in this filter set
                }
            } else {
                // Error(?): Fetching filters for this filter set returned null!
            }
        } catch (Exception e) {
            //
        }
    }
    catFilterSets.clear(); // MUY IMPORTANTE!
    
    
    
    
    /*
    if (!catFilters.isEmpty()) {
        // Get the "top level" categories (e.g. a list containing: "Event type", "Theme" and "Organization")
        List topLevelCategories = catService.readCategories(cmso, null, false, CATEGORIES_PATH);
        
        Iterator<CmsCategory> fds = topLevelCategories.iterator();
        while (fds.hasNext()) {
            out.println("<!-- \n\n TOP LEVEL CATEGORY: " + fds.next().getTitle() + " \n\n-->");
        }
        
        // Get the parameter string for the current request
        String parameterString = getParameterString(baseParamMap);
        String categoryFiltersList = "<ul>";
        String categoryFiltersHead = null;
        
        Iterator<CategoryFilter> cfi = catFilters.iterator();
        while (cfi.hasNext()) {
            CategoryFilter cf = cfi.next();
            
            out.println("<!-- Evaluating filter '" + cf.getName() + " (" + cf.getCounter() + ") -->");
            
            // Create a flag: Don't print category filters that should be excluded or that are "top level categories" we don't want to 
            boolean hideCategoryFilter = false;
            if (topLevelCategories.contains(cf.getCategory())) {
                hideCategoryFilter = true; // This filter is for a "top-level" category: hide it
                categoryFiltersHead = cf.getName();
            } 
            else {
                Iterator<CmsCategory> noShowItr = excludedNavCategories.iterator();
                while (noShowItr.hasNext()) {
                    CmsCategory excludedNavCategory = noShowItr.next();
                    if (isCategoryOrSubCategory(cf.getCategory(), excludedNavCategory)) {
                        hideCategoryFilter = true; // This filter is for an excluded category: hide it
                    }
                }
            }
            if (!hideCategoryFilter) { 
                out.println("<!-- " + cf.getName() + "(" + cf.getCounter() + ") -->");
                String cfLink = "";
                if (parameterString.contains(cf.getUri())) {
                    cfLink = "<a style=\"font-weight:bold;\" class=\"remove\" href=\"" + cms.link(OVERVIEW_FILE) + "?" + parameterString;
                    cfLink = cfLink.replace(PARAM_NAME_CATEGORY + "=".concat(cf.getUri()), "");
                    cfLink = cfLink.replace("&amp;&amp;", "&amp;"); // If multiple categories were in the URL, we just created "&&"
                    cfLink = cfLink.endsWith("?") ? cfLink.substring(0, cfLink.length() - 1) : cfLink; // Remove trailing ?
                    cfLink = cfLink.endsWith("&amp;") ? cfLink.substring(0, cfLink.length() - 5) : cfLink; // Remove trailing &
                    cfLink += "\" rel=\"nofollow\">" + cf.getName() + " <span class=\"remove-filter\""
                                + " style=\"background:red; border-radius:3px; color:white; padding:0 0.3em;\""
                                + ">X</span></a>";
                    //out.println(cf.getName() + " " + cfLink);
                    //hasSelectedSubCategory = true;
                    //break;
                }
                else {
                    cfLink = "<a href=\"" + cms.link(OVERVIEW_FILE) + "?" + 
                                                parameterString + "&amp;" + PARAM_NAME_CATEGORY + "=" + cf.getUri() + "\" rel=\"nofollow\">" + 
                                                cf.getName() + " (" + cf.getCounter() + ")</a>";
                }
                categoryFiltersList += "<li>" + cfLink + "</li>";
            }
        }
        categoryFiltersList += "</ul>";
        
        out.println("<h4>" + categoryFiltersHead + "</h4>");
        out.println(categoryFiltersList);
    }
    catFilters.clear(); // Muy importante!
    */
    /*
    Iterator allCatItr = allCategories.iterator();
    if (allCatItr.hasNext()) {
        int k = 0;

        // Get the parameter string for the current request
        String parameterString = getParameterString(baseParamMap);
        // The navigation block, add the nofloat class if the range is the whole year (then the calendar should not show)
        //out.println("<div class=\"event-links nav" + (hiddenCalendar ? " nofloat" : "") + "\">");
        out.println("<div class=\"onecol\">");

        // Loop over all categories
        while (allCatItr.hasNext()) {
            boolean hideCategoryFilter = false;
            k++;
            // Get the category
            CmsCategory cat = (CmsCategory)allCatItr.next();
            // Don't print category selections we don't want to 
            Iterator noShowItr = excludedNavCategories.iterator();
            while (noShowItr.hasNext()) {
                CmsCategory excludedNavCategory = (CmsCategory)noShowItr.next();
                if (cat.getRootPath().startsWith(excludedNavCategory.getRootPath())) {
                    //out.println("<!-- skipped filter: " + cat.getTitle() + " -->");
                    hideCategoryFilter = true;
                }
            }

            // cat is a top level category
            if (topLevelCategories.indexOf(cat) > -1 && !hideCategoryFilter) {
                // Print the category name as a heading
                //out.println("<div class=\"cat-set\">" + 
                out.println("" + 
                        "<h4>" + cat.getTitle() + "</h4>");
                // Read the sub-categories
                List subCategories = catService.readCategories(cmso, cat.getPath(), true, CATEGORIES_PATH);
                //out.println("<!-- cat.getPath() = '" + cat.getPath() + "' -->"); // Example result: cat.getPath() = 'person/'
                Iterator iSubCat = subCategories.iterator();
                boolean hasSelectedSubCategory = false; // Switch for determining if a subcategory of the top-level category is selected
                if (iSubCat.hasNext()) {
                    String list = "<ul class=\"blocklist categories\">\n";
                    // A list to hold the sub-categories (the filters) - we use a list for easy sorting
                    ArrayList catFilters = new ArrayList();

                    // Loop over all subcategories under this top level category
                    while (iSubCat.hasNext()) {
                        CmsCategory subCat = (CmsCategory)iSubCat.next();
                        // If the category is present in the current parameters, set up a link to remove it
                        if (parameterString.contains(subCat.getPath())) {
                            String removeLink = "<a class=\"remove\" href=\"" + cms.link(OVERVIEW_FILE) + "?" + parameterString;
                            removeLink = removeLink.replace(PARAM_NAME_CATEGORY + "=".concat(subCat.getPath()), "");
                            removeLink = removeLink.replace("&amp;&amp;", "&amp;"); // If multiple categories were in the URL, we just created "&&"
                            removeLink = removeLink.endsWith("?") ? removeLink.substring(0, removeLink.length() - 1) : removeLink; // Remove trailing ?
                            removeLink = removeLink.endsWith("&amp;") ? removeLink.substring(0, removeLink.length() - 5) : removeLink; // Remove trailing &
                            removeLink += "\" rel=\"nofollow\">X</a>";
                            out.println(subCat.getTitle() + " " + removeLink);
                            hasSelectedSubCategory = true;
                            break;
                        }
                        // Category is not present in the current request parameters: create a link to filter by this category
                        else {
                            // Number of matches for this category
                            calendar.set(Calendar.MONTH, m); 
                            calendar.set(Calendar.YEAR, y);
                            calendar.set(Calendar.DATE, d);
                            List catMatches;
                            try {
                                catMatches = new ArrayList(paramCategories);
                            } catch (NullPointerException npe) {
                                catMatches = new ArrayList();
                            }
                            catMatches.add(subCat);
                            int numCatMatches = 0;
                            try {
                                List ex = range == EventCalendar.RANGE_CATCH_ALL ? undatedEventsFolders : null;
                                numCatMatches = calendar.getEvents(range, cms, 
                                                                    eventsFolder, ex, excludedEventsFolders, catMatches, 
                                                                    hideExpiredEvents, sortDescending, overlapLenient, categoryInclusive, -1).size();
                            } catch (NullPointerException npe) {
                                // No matches, set numCatMatches to negative value
                                //numCatMatches = -1;
                                numCatMatches = 0;
                            }
                            // Done with number of matches for this category

                            if (numCatMatches > 0) {      
                                // Append a link to filter by this category 
                                // NB: the initial comment (sortComment) is VITAL for sorting!
                                String sortComment = "";
                                if (categoriesSort == SORT_MODE_RELEVANCY)
                                    sortComment = "<!-- " + (numCatMatches < 10 ? ("0" + numCatMatches) : numCatMatches) + " -->";
                                else if (categoriesSort == SORT_MODE_TITLE)
                                    sortComment = "<!-- " + subCat.getTitle() + " -->";
                                String filter = sortComment +
                                            "<a href=\"" + cms.link(OVERVIEW_FILE) + "?" + 
                                            parameterString + "&amp;" + PARAM_NAME_CATEGORY + "=" + subCat.getPath() + "\" rel=\"nofollow\">" + 
                                            subCat.getTitle() + " (" + numCatMatches + ")</a>";
                                catFilters.add(filter);
                            }
                        }
                    }
                    
                    if (!catFilters.isEmpty()) {
                        //out.println("<!-- " + catFilters.size() + " filters for this category -->");
                        Collections.sort(catFilters);
                        if (categoriesSort == SORT_MODE_RELEVANCY)
                            Collections.reverse(catFilters);
                        Iterator iFilter = catFilters.iterator();
                        while (iFilter.hasNext()) {
                            list += "<li class=\"category\">" + (String)iFilter.next() + "</li>\n";
                        }
                    }
                    
                    // If no subcategory has been added, add a "nothing" info text
                    if (!list.contains("</li>")) {
                        list += "<li class=\"category\">" + LABEL_NO_CATEGORIES + "</li>";
                    }
                    // Append the list end tag
                    list += "</ul>\n";

                    if (!hasSelectedSubCategory) {
                        // Print the list of subcategory filter links for this top level category
                        out.println(list);
                    }
                }
                else {
                    out.println("" + LABEL_NO_SUB_CATEGORIES + ".");
                }
            }
        }
    } else {
        out.println("<ul><li>" + LABEL_NO_CATEGORIES + ".</li></ul>");
    }
    //*/
    out.println("<!-- END of category filtering -->");
    out.println("</div><!-- .onecol -->"); //this is output by the template
}





// Include the outer template, if needed
if (includeTemplate) {
    cms.includeTemplateBottom();
}
%>