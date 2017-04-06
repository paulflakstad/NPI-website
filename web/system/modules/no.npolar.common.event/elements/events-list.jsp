<%-- 
    Document   : events-list.jsp - remake of eventcalendar.jsp
    Created on : 2016-01-14
    Author     : Paul-Inge Flakstad, Norwegian Polar Institute <flakstad at npolar.no>
--%><%@page import="no.npolar.data.api.SearchFilterSets"%>
<%@page import="no.npolar.data.api.SearchFilterSet"%>
<%@page import="org.opencms.util.CmsRequestUtil"%>
<%@ page import="java.util.*,
                 java.text.SimpleDateFormat,
                 java.io.IOException,
                 no.npolar.common.eventcalendar.*,
                 no.npolar.common.eventcalendar.view.*,
                 com.google.ical.iter.RecurrenceIteratorFactory,
                 com.google.ical.iter.RecurrenceIterator,
                 com.google.ical.values.DateValueImpl,
                 com.google.ical.values.DateValue,
                 org.opencms.workplace.CmsWorkplaceManager,
                 org.opencms.workplace.CmsWorkplaceSettings,
                 no.npolar.util.*,
                 org.opencms.db.CmsUserSettings,
                 org.opencms.file.CmsResource,
                 org.opencms.file.CmsObject,
                 org.opencms.jsp.I_CmsXmlContentContainer,
                 org.opencms.xml.A_CmsXmlDocument,
                 org.opencms.xml.content.*,
                 org.opencms.main.OpenCms,
                 org.opencms.main.CmsException,
                 org.opencms.relations.CmsCategory,
                 org.opencms.relations.CmsCategoryService,
                 org.opencms.util.CmsHtmlExtractor,
                 org.opencms.util.CmsUUID,
                 org.opencms.util.CmsStringUtil"  session="true" 
%><%!
public String rangeExplain(CollectorTimeRange r) {
    SimpleDateFormat df = new SimpleDateFormat("yyyy-MM-dd");
    return r.toString().concat(" [" + df.format(new Date(r.getStart())) + " - " + df.format(new Date(r.getEnd())) + "]");
}

/**
 * Prints a list of events, as an unordered list.
 */
public void printEventsList(CmsAgent cms, 
                            List events, 
                            String eventTimeOverride,
                            String listHeading, 
                            boolean showCalendarIcon,
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
    
    Iterator i = events.iterator();
    
    //out.println(sectionHeadStart + listHeading + sectionHeadEnd);
    out.println("<ul class=\"event-list\" id=\"event-list\">");
    while (i.hasNext()) {
        EventEntry event = (EventEntry)i.next();
        CmsResource eventResource = cmso.readResource(event.getStructureId());

        Calendar eventStartCal = EventCalendarUtils.getDateStartCal(new Date(event.getStartTime()));
        
        // Relocated this call, is now in JSP body
        //resolveCategoryFiltersForResource(cmso, eventResource, categoryReferencePath, out);
        /*    
        //SimpleDateFormat dfIso = getDatetimeAttributeFormat(cmso, eventResource);
        SimpleDateFormat dfIso = event.getDatetimeAttributeFormat(cms.getRequestContext().getLocale());
        
        String start = null, end = null;
        try {
            start = "<time itemprop=\"startDate\" datetime=\"" + dfIso.format(new Date(event.getStartTime())) + "\">" + df.format(new Date(event.getStartTime())) + "</time>";
            end = "<time itemprop=\"endDate\" datetime=\"" + dfIso.format(new Date(event.getEndTime())) + "\">" + df.format(new Date(event.getEndTime())) + "</time>";
        } catch (Exception e ) {
           // Do nothing
        }
        */
        String eventUri = cms.link(cmso.getSitePath(eventResource));
        if (!baseParamString.isEmpty()) {
            eventUri += "?" + baseParamString;
        }
        if (event.hasRecurrenceRule()) {
            eventUri = CmsRequestUtil.appendParameter(eventUri, "begin", Long.toString(event.getStartTime()));
        }
        

        out.println("<li class=\"card card--h" + (showCalendarIcon ? " card--symbolic" : "") + "\" itemscope itemtype=\"http://schema.org/Event\">");
        if (showCalendarIcon) {
            out.println("<span class=\"icon icon--calendar card__icon\">" +
                            "<span class=\"icon icon--calendar__month\">" + eventStartCal.getDisplayName(Calendar.MONTH, Calendar.SHORT, cms.getRequestContext().getLocale()) + "</span>" +
                            "<span class=\"icon icon--calendar__date\">" + eventStartCal.get(Calendar.DATE) + "</span>" +
                            "<span class=\"icon icon--calendar__year\">" + eventStartCal.get(Calendar.YEAR) + "</span>" +
                        "</span>");
        }
        
        out.println("<span class=\"event-info card__content\">" +
                            "<h3 class=\"card__title\">" 
                            + "<a href=\"" + eventUri + "\"" +
                                //cms.link(cmso.getSitePath(eventResource)) +
                                //(baseParamString.isEmpty() ? "" : ("?" + baseParamString)) + "\"" + 
                                //(event.isExpired() ? " class=\"event-pastevent\"" : "") +
                            " itemprop=\"url\">" +
                                "<span itemprop=\"name\">" + event.getTitle() + "</span>" +
                            "</a>" +
                            "</h3>" +
                            "<p class=\"event-time\">" +
                                (eventTimeOverride == null ?
                                    event.getTimespanHtml(cms, getOpenCmsCurrentTime(cms.getCmsObject()))
                                    //(start + (!event.isOneDayEvent() ? (" &ndash; " + end) : "")) 
                                    : 
                                    eventTimeOverride) +
                            "</p>" +
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
 * Reads the categories for the given resource, and adds a category filter for each one.
 */
/*private void resolveCategoryFiltersForResource(CmsObject cmso, CmsResource r, String categoryReferencePath, JspWriter out) throws org.opencms.main.CmsException {
    // Add any category to the category filters list
    CmsCategoryService cs = CmsCategoryService.getInstance();
    // Get the categories assigned to the (event) resource
    List<CmsCategory> eventCats = cs.readResourceCategories(cmso, cmso.getSitePath(r));
    for (CmsCategory cat : eventCats) {
        try { out.println("<!--    - " + cat.getName() + " -->"); } catch (Exception e) {}
    }
    createCategoryFilters(eventCats, cmso, categoryReferencePath, out);
}*/

private void resolveCategoryFiltersForPaths(CmsObject cmso, Map<String, Integer> categoryRootPaths, String categoryReferencePath, JspWriter out) throws org.opencms.main.CmsException {
    if (categoryRootPaths == null || categoryRootPaths.isEmpty()) 
        return;

    catFilterSets.clear();

    // Add any category to the category filters list
    CmsCategoryService cs = CmsCategoryService.getInstance();
    // Get the "top level" categories, e.g. a list containing "Event type", "Theme" and "Organizational"
    List<CmsCategory> topLevelCategories = cs.readCategories(cmso, null, false, categoryReferencePath);
    
    
    for (String categoryRootPath : categoryRootPaths.keySet()) {
        try { 
            CmsCategory cat = cs.getCategory(cmso, categoryRootPath);
            int catHits = categoryRootPaths.get(categoryRootPath);
            out.println("<!-- Read category: " + cat.getName() + " -->");

            // Get the locale for the category (use the request context's locale as default)
            // This check was added to fix a periodic bug where filters were displayed in both English and Norwegian
            String categoryLocale = cmso.readPropertyObject(cmso.getRequestContext().removeSiteRoot(cat.getRootPath()), "locale", true).getValue(cmso.getRequestContext().getLocale().toString());
            if (categoryLocale.equals(cmso.getRequestContext().getLocale().toString())) { // If the category's locale matches the request context's locale

                if (topLevelCategories.contains(cat)) { // Then this is a "top level" category, like "Event type" or "Theme"
                    //try { out.println("<!--    - Ensuring top-level category '" + cat.getName() + "' exists -->"); } catch (Exception e) {}
                    // Don't create any filter, just make sure a filter set exists with this root category
                    createOrGetCategoryFilterSet(cat);
                } 
                else { // Not a "top level" category
                    //try { out.println("<!--    - Creating filter for category '" + cat.getName() + "' (" + catHits + " hits) -->"); } catch (Exception e) {}
                    // Get the category's "top level" (parent) category:
                    CmsCategory topLevelCategory = EventCalendarUtils.matchCategoryOrParent(topLevelCategories, cat, cmso, categoryReferencePath);
                    CategoryFilter categoryFilter = new CategoryFilter(cat, catHits-1); // Minus one here because addCategoryFilter() below will add 1 to the counter
                    createOrGetCategoryFilterSet(topLevelCategory).addCategoryFilter(categoryFilter);
                }
            } else {
                //try { out.println("<!--    - Skipped category '" + cat.getName() + "' (other locale) -->"); } catch (Exception e) {}
            }
        } catch (Exception e) {
            try { out.println("<!-- ERROR reading category " + categoryRootPath + ": " + e.getMessage() + " -->"); } catch (Exception ee) {}
        }
    }
    //createCategoryFilters(categories, cmso, categoryReferencePath, out);
}

/**
 * Creates a category filter for each of the given categories. (If a category already has a filter, its counter is incremented instead.)
 */
private synchronized void createCategoryFilters(List<CmsCategory> categories, CmsObject cmso, String categoryReferencePath, JspWriter out) throws org.opencms.main.CmsException {
    if (categories == null || categories.isEmpty())
        return;

    // Add any category to the category filters list
    CmsCategoryService cs = CmsCategoryService.getInstance();
    // Get the "top level" categories, e.g. a list containing "Event type", "Theme" and "Organizational"
    List<CmsCategory> topLevelCategories = cs.readCategories(cmso, null, false, categoryReferencePath);

    try { out.println("<!--    - Processing these " + categories.size() + " categories... -->"); } catch (Exception e) {}
    //if (categories != null && categories.isEmpty()) {
        Iterator<CmsCategory> iCats = categories.iterator();
        try {
            while (iCats.hasNext()) {
                CmsCategory cat = iCats.next();
                try { out.println("<!--    - Processing '" + cat.getName() + "'... -->"); } catch (Exception e) {}
                if (cat != null) {
                    // Get the locale for the category (use the request context's locale as default)
                    // This check was added to fix a periodic bug where filters were displayed in both English and Norwegian
                    String categoryLocale = cmso.readPropertyObject(cmso.getRequestContext().removeSiteRoot(cat.getRootPath()), "locale", true).getValue(cmso.getRequestContext().getLocale().toString());
                    if (categoryLocale.equals(cmso.getRequestContext().getLocale().toString())) { // If the category's locale matches the request context's locale
                        
                        if (topLevelCategories.contains(cat)) { // Then this is a "top level" category, like "Event type" or "Theme"
                            try { out.println("<!--    - Ensuring top-level category '" + cat.getName() + "' exists -->"); } catch (Exception e) {}
                            // Don't create any filter, just make sure a filter set exists with this root category
                            createOrGetCategoryFilterSet(cat);
                        } 
                        else { // Not a "top level" category
                            try { out.println("<!--    - Adding filter for category '" + cat.getName() + "' -->"); } catch (Exception e) {}
                            // Get the category's "top level" (parent) category:
                            CmsCategory topLevelCategory = EventCalendarUtils.matchCategoryOrParent(topLevelCategories, cat, cmso, categoryReferencePath);
                            createOrGetCategoryFilterSet(topLevelCategory).addCategoryFilter(new CategoryFilter(cat));
                        }
                    } else {
                        try { out.println("<!--    - Skipped category '" + cat.getName() + "' (other locale) -->"); } catch (Exception e) {}
                    }
                }
            }
        } catch (NullPointerException npe) {
            try { out.println("<!-- Undefined NULL error when attempting to create category filters -->"); } catch (Exception e) {}
            throw new NullPointerException("Undefined NULL error when attempting to create category filters!");
        }
    //}
}

/**
 * Gets a category filter set identified by the given root category. If no such set exists, it is created first.
 */
private synchronized CategoryFilterSet createOrGetCategoryFilterSet(CmsCategory category) {
    if (catFilterSets == null) {
        catFilterSets = new HashMap<String, CategoryFilterSet>();
    }
    if (!catFilterSets.containsKey(category.getTitle())) {
        // No such filter set, create the set and add it
        CategoryFilterSet filterSet = new CategoryFilterSet(category);
        catFilterSets.put(filterSet.getTitle(), filterSet);
    }
    return catFilterSets.get(category.getTitle());
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
    // that is displayed will be the tagged child category for the event, 
    // NOT the "displayCategory" itself.
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
 * Gets the workplace timestamp as a Date instance.
 * 
 * If time warp is active, the returned datetime will be the "warped" time. 
 * Otherwise, the actual "now" is returned.
 *
 * @param cmso An initialized CmsObject.
 * @return Date The current workplace "now" - either the actual "now" or a time-warped "now".
 */
public static Date getOpenCmsCurrentTime(CmsObject cmso) {
    long userCurrentTime = new Date().getTime();
    Object timeWarpObj = cmso.getRequestContext().getCurrentUser().getAdditionalInfo(CmsUserSettings.ADDITIONAL_INFO_TIMEWARP);
    try {
        userCurrentTime = (Long)timeWarpObj;
    } catch (ClassCastException e) {
        try {
            userCurrentTime = Long.parseLong((String)timeWarpObj);
            if (userCurrentTime <= 0) {
                userCurrentTime = new Date().getTime();
            }
        } catch (Throwable t) {}
    } catch (Throwable t) {}
 
    return new Date(userCurrentTime);
}

/**
 * A map for all category filter sets. 
 */
static Map<String, CategoryFilterSet> catFilterSets = new HashMap<String, CategoryFilterSet>();
%>
<%
CmsAgent cms                            = new CmsAgent(pageContext, request, response);
CmsObject cmso                          = cms.getCmsObject();
Locale locale                           = cms.getRequestContext().getLocale();
String requestFileUri                   = cms.getRequestContext().getUri();
String requestFolderUri                 = cms.getRequestContext().getFolderUri();

final Date DATE_NOW                     = getOpenCmsCurrentTime(cmso);

// Constants
final boolean DEBUG                     = true; //request.getParameter("debug") == null ? false : true;
final String AJAX_EVENTS_PROVIDER       = "/system/modules/no.npolar.common.event/elements/events-provider-ajax.jsp";

// Parameter names
final String PARAM_NAME_RESOURCE_URI    = "resourceUri";
final String PARAM_NAME_CATEGORY        = "cat";
final String PARAM_NAME_EXPIRED         = "exp";

// AJAX parameter names
final String PARAM_NAME_EVENTS_FOLDER   = "events_folder";
final String PARAM_NAME_EVENT_FOLDERS_ADD = "event_folders_add";
final String PARAM_NAME_EXCLUDE_FOLDER  = "exclude_folder";
final String PARAM_NAME_OVERVIEW        = "overview";
final String PARAM_NAME_CALENDAR_CLASS  = "calendar_class";
final String PARAM_NAME_WEEK_NUMBERS    = "week_numbers";
final String PARAM_NAME_DESCRIPTIONS    = "descriptions";
final String PARAM_NAME_LOCALE          = "locale";
final String PARAM_NAME_LABEL_SINGULAR  = "labelsingular";
final String PARAM_NAME_LABEL_PLURAL    = "labelplural";
final String PARAM_NAME_CATEGORY_PATH   = "categorypath";
final String PARAM_NAME_HEADING         = "heading";
final String PARAM_NAME_LIMIT           = "limit";
final String PARAM_NAME_OFFSET          = "offset";

// The keyword for "all categories"
final String KEYWORD_ALL_CATEGORIES     = "all";

final boolean ARCHIVE_MODE = request.getParameter(PARAM_NAME_EXPIRED) != null ? true : false;

// Check if the outer template should be included, and include it if needed:
boolean includeTemplate = false;
if (cmso.readResource(requestFileUri).getTypeId() == OpenCms.getResourceManager().getResourceType("np_eventcal").getTypeId()) {
    includeTemplate = true;
    cms.includeTemplateTop();
    out.println("<article class=\"main-content\">");
    out.println("<h1>" + cms.property("Title", requestFileUri, "[No title]") + "</h1>");
}

// The calendar instance
EventCalendar collectorCal = new EventCalendar(TimeZone.getDefault());

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
List<String> eventFolders       = new ArrayList<String>();
String categoryPath             = null;
String undatedEventsFolder      = null; // Hard to manage a list, so use only one
List undatedEventsFolders       = new ArrayList(); // DUMMY list, methods in .jar need a list (ToDo: FIX!!!)
ArrayList displayCategories     = new ArrayList(); // List of categories to display in the events list
String hostCategoryPath         = null;
String calendarLinkPath         = null;
//String calendarAddClass         = null;
String labelSingular            = null;
String labelPlural              = null;
ArrayList excludedEventsFolders = new ArrayList();
ArrayList excludedNavCategories = new ArrayList();
Calendar minTime                = Calendar.getInstance();
Calendar maxTime                = Calendar.getInstance();
Date initialTime                = DATE_NOW;
long minTimeLong                = 0;
long maxTimeLong                = 0;
int categoriesSort              = -1;
//int initialRange                = -99; // 99 = catch all | 0 = current year | 1 = current month | 2 = current day | 3 = current week | 4 = upcoming and in progress | 98 = today and next N upcoming
CollectorTimeRange initialRange = null;
int displayType                 = -1; // 0 = calendar only  |  1 = calendar & listing  |  2 = calendar, listing & navigation
//boolean showWeekNumbers         = true;
boolean showEventDescription    = true;
boolean showCalendarIcon        = true;
//boolean hideExpiredEvents       = true;
boolean categoryFiltering       = true;

// Read the config file (xmlcontent resource of type "np_eventcal"):
I_CmsXmlContentContainer configuration = cms.contentload("singleFile", resourceUri, false);
while (configuration.hasMoreResources()) {
    // Folder(s) to collect events from (will collect from the entire sub-tree)
    
// Main folder - categories etc. will be based on this one
    eventsFolder = cms.contentshow(configuration, "EventsFolder");
    if (!CmsAgent.elementExists(eventsFolder)) {
        eventsFolder = requestFolderUri;
    }
    // Additional folders 
    // (as of 2017-04, used only on the intranet to include events from public site)
    I_CmsXmlContentContainer additionalFoldersLoop = cms.contentloop(configuration, "AdditionalFolder");
    while (additionalFoldersLoop.hasMoreResources()) {
        eventFolders.add( cms.contentshow(additionalFoldersLoop) );
    }
    // It is important that the main folder is the LAST one in the list
    eventFolders.add(eventsFolder);
    /*
    eventsFolder = eventFolders.get(0);
    if (!CmsAgent.elementExists(eventsFolder)) {
        eventsFolder = requestFolderUri;
        eventFolders.add(eventsFolder);
    }
    //*/
    /*
    // Main folder - categories etc. will be based on this one
    eventsFolder = cms.contentshow(configuration, "EventsFolder");
    if (!CmsAgent.elementExists(eventsFolder)) {
        eventsFolder = requestFolderUri;
    }
    //*/
    
    // The root path to the categories, typically ${EVENTS_FOLDER}/_categories/
    categoryPath = cms.contentshow(configuration, "CategoriesRoot");
    // The preferred sorting mode for categories in the category navigation
    categoriesSort = Integer.valueOf(cms.contentshow(configuration, "CategoriesSort")).intValue();
    // The root path to the host category (if used it will be a special filter, unlike the other filters)
    hostCategoryPath = cms.contentshow(configuration, "HostCategory");
    if (CmsAgent.elementExists(hostCategoryPath)) {
        hostCategoryPath = cms.getRequestContext().removeSiteRoot(hostCategoryPath);
    }
    // The preferred display type (type of view)
    displayType = Integer.valueOf(cms.contentshow(configuration, "DisplayType")).intValue();
    categoryFiltering = displayType == 3 || displayType == 4;
    // Whether or not to use week numbers
    //showWeekNumbers = Boolean.valueOf(cms.contentshow(configuration, "ShowWeekNumbers")).booleanValue();
    // Whether or not to show event descriptions in listings
    showEventDescription = Boolean.valueOf(cms.contentshow(configuration, "EventDescription")).booleanValue();
    // Whether or not to hide events that are finished
    //hideExpiredEvents = !ARCHIVE_MODE; //HIDE_EXPIRED_SELECTED;//Boolean.valueOf(cms.contentshow(configuration, "HideExpiredEvents")).booleanValue();
    // The calendar link path (any links in the calendar will point to this file)
    calendarLinkPath = cms.contentshow(configuration, "CalendarLink");
    // The calendar class postfix (will be appended to the calendar's class)
    //calendarAddClass = cms.contentshow(configuration, "CalendarAddClass");
    
    // A folder containing events with undetermined dates
    undatedEventsFolder = cms.contentshow(configuration, "UndatedFolder");
    if (CmsAgent.elementExists(undatedEventsFolder)) {
        undatedEventsFolders.add(undatedEventsFolder);
    }
    
    // Any folders containing events that should not show
    I_CmsXmlContentContainer loop = cms.contentloop(configuration, "ExcludeFolder");
    while (loop.hasMoreResources()) {
        excludedEventsFolders.add(cms.contentshow(loop));
    }
    // Categories that should not be part of the navigation
    loop = cms.contentloop(configuration, "ExcludeNavCategory");
    while (loop.hasMoreResources()) {
        try {
            excludedNavCategories.add(catService.getCategory(cmso, cms.contentshow(loop)));
        } catch (Exception e) {
            // Should log this
        }
    }
    // Categories that should be displayed as part of the event entry in the list of events
    loop = cms.contentloop(configuration, "DisplayCategory");
    while (loop.hasMoreResources()) {
        try {
            displayCategories.add(catService.getCategory(cmso, cms.contentshow(loop)));
        } catch (Exception e) {
            // Should log this
        }
    }
    // Custom label (to override the "Event" label
    loop = cms.contentloop(configuration, "EventLabel");
    while (loop.hasMoreResources()) {
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
        initialTime = new Date(Long.parseLong(cms.contentshow(configuration, "InitialTime")));
    } catch (Exception e) {
        // Retain initialTime = DATE_NOW;
    }
    try {
        initialRange = new CollectorTimeRange(Integer.valueOf(cms.contentshow(configuration, "InitialRange")).intValue(), initialTime);
    } catch (Exception e) {
        initialRange = new CollectorTimeRange(CollectorTimeRange.RANGE_UPCOMING_AND_IN_PROGRESS, initialTime);
    }
}
//==============================================================================
//======================== DONE READING CONFIG FILE ============================
//==============================================================================




//
// Constants
//

// The path to the overview page
final String OVERVIEW_FILE              = CmsAgent.elementExists(calendarLinkPath) ? calendarLinkPath : requestFileUri;//requestFileUri;//"/no/categories/events.html";

final String LABEL_DATE_NOT_DETERMINED  = cms.label("label.for.np_event.datenotset");//"Dato ikke fastsatt";
final String LABEL_WITHOUT_DATE         = cms.label("label.for.np_event.withoutdate").toLowerCase();//"uten fastsatt dato";
final String LABEL_EVENT                = labelSingular == null ? cms.label("label.for.np_event.event") : labelSingular;//"Arrangement";
final String LABEL_EVENTS               = labelPlural == null ? cms.label("label.for.np_event.events") : labelPlural;//"Arrangementer";
final String LABEL_ONGOING_AND_UPCOMING = cms.label("label.for.np_event.ongoingupcoming"); // Pågående og kommende / In progress and upcoming
final String LABEL_FINISHED             = cms.label("label.for.np_event.finished"); // Avsluttet / Finished
final String LABEL_NONE                 = cms.label("label.for.np_event.none");//"Ingen";
final String LABEL_NO_EVENTS            = LABEL_NONE + " " + LABEL_EVENTS.toLowerCase();//"Ingen arrangementer";
final String LABEL_VIEW_CURRENT         = cms.label("label.for.np_event.viewactive");
final String LABEL_VIEW_EXPIRED         = cms.label("label.for.np_event.viewexpired");
final String LABEL_VIEWING_CURRENT      = cms.label("label.for.np_event.viewingactive") + " " + LABEL_EVENTS.toLowerCase();
final String LABEL_VIEWING_EXPIRED      = cms.label("label.for.np_event.viewingexpired") + " " + LABEL_EVENTS.toLowerCase();

final String LABEL_LOAD_MORE            = cms.label("label.for.np_event.loadmore");//Last flere
final String LABEL_FILTERS              = cms.label("label.for.np_event.filters");//Filtre

final String CATEGORIES_PATH            = CmsAgent.elementExists(categoryPath) ? categoryPath : requestFolderUri;//requestFolderUri;//"/no/categories/";

// The date format to use on lists and alike
SimpleDateFormat df = new SimpleDateFormat(cms.label("label.event.dateformat.dateonly"), locale);
//SimpleDateFormat headingDate = new SimpleDateFormat(cms.label("label.event.dateformat.full"), locale);

// Date format to read/write MySQL-style date strings
SimpleDateFormat sqlFormat = new SimpleDateFormat(EventCalendar.MYSQL_DATETIME_FORMAT);

// Get a copy of the parameter map, removing the "resourceUri" parameter (which we don't want to pass on!)
Map baseParamMap = new HashMap(cms.getRequest().getParameterMap());
try { baseParamMap.remove(PARAM_NAME_RESOURCE_URI); } catch (NullPointerException npe) {} // baseParamMap may be NULL

// Will hold relative paths to any filter categories present in the request parameters. 
// E.g.: /file.html?cat=event/seminar/&cat=event/npi-seminar/
ArrayList paramFilterCategoryPaths = null;
// Holds the actual CmsCategory instances, which we'll resolve from the relative paths
ArrayList paramFilterCategories = null;

// Set the initial calendar time (by default "now", but possibly overridden)
collectorCal.setTime(initialTime);
collectorCal.setFirstDayOfWeek(Calendar.MONDAY); // Set start of week to Monday

// Set the initial calendar range
CollectorTimeRange range = initialRange;
int rangeType = initialRange.getRange();

if (DEBUG) { out.println("<!-- Calendar initialized. Inital time is " + sqlFormat.format(collectorCal.getTime()) + ". Initial range is " + rangeExplain(range) + ". -->"); }

// Construct the range
range = new CollectorTimeRange(rangeType, collectorCal.getTime());
if (DEBUG) {
    out.println("\n<!-- \nMain collector settings ready:"
                        + "\n - Time is set to " + sqlFormat.format(collectorCal.getTime()) + "."
                        + "\n - Range is set to " + rangeExplain(range) + ".\n-->");
}


//
// Process category parameter(s), the parameter name is PARAM_NAME_CATEGORY (= "cat" at time of writing this)
//
if (request.getParameter(PARAM_NAME_CATEGORY) != null) {
    List pc = Arrays.asList(request.getParameterValues(PARAM_NAME_CATEGORY));
    paramFilterCategoryPaths = new ArrayList(pc);
    paramFilterCategories = new ArrayList();
    // Remove all occurrences of "all categories" and create the list of CmsCategory objects
    Iterator iParamCategories = paramFilterCategoryPaths.iterator();
    while (iParamCategories.hasNext()) {
        String paramCatPath = (String)iParamCategories.next();
        if (KEYWORD_ALL_CATEGORIES.equals(paramCatPath)) { // Pseudo: if ("all" equals this "cat"-parameter's value)
            iParamCategories.remove(); // Remove it. (The "all" keyword does not apply to every category filter, only the host category.
        } else {
            try {
                // Get the category object
                CmsCategory cat = catService.readCategory(cmso, paramCatPath, requestFileUri);
                // Store it in the list
                paramFilterCategories.add(cat);
                //if (DEBUG) { out.println("\n<!-- Found category filter: '" + cat.getRootPath() + "' (relative path: '" + cat.getPath() + "') -->"); }
            } catch (Exception readCatError) {
                //if (DEBUG) { out.println("\n<!-- Exception when reading category: " + readCatError.getMessage() + " -->"); }
            }
        }
    }
}

try {
    if (catFilterSets.isEmpty() && !paramFilterCategories.isEmpty()) {
        // This routine is needed ONLY for "remove filter" links in cases where 
        // a user has first activated a filter, and then changed the time 
        // parameters so that no events are listed.
        createCategoryFilters(paramFilterCategories, cmso, CATEGORIES_PATH, out);
    } else {}
} catch (Exception e) {
    // Ignore, probably an NPE stemming from paramCategories being null
    
    //out.println("<!-- ERROR creating category filters: " + e.getMessage() + " -->");
}












//##############################################################################
// Collect and sort events
//
// New strategy: Unless we have a parameter that says "show expired", we show
//  in-progress and upcoming events. (All of them.)
//  Otherwise, we show the expired ones ("archive"). In that case, we really 
//  should use a "show older" type thing, to avoid detrimental load time.
//
// Also, we ditch the year/month selector for now.
//
// ToDo: Introduce offset to the EventsCollector
//
List<EventEntry> events = new ArrayList<EventEntry>();
//List<EventEntry> eventsInRange = new ArrayList<EventEntry>();
//List<EventEntry> noDateEvents = new ArrayList<EventEntry>();
//List<EventEntry> eventsExpired = new ArrayList<EventEntry>();

if (DEBUG) { out.println("\n<!--\nReady to collect events. Range is " + rangeExplain(range) + " \n-->\n"); }

// Limit
final int DEFAULT_LIMIT = 20;
int limit = DEFAULT_LIMIT;
try { limit = Integer.valueOf(request.getParameter("limit")); } catch (Exception e) {};
EventsCollector eventsCollector = null;


/*
EventsCollector eventsCollector = new EventsCollector(cms, eventsFolder)
                                        .addCategoriesToMatch(paramFilterCategories)
                                        .excludeFolders(excludedEventsFolders) 
                                        .setSortOrder(!ARCHIVE_MODE)
                                        .setOverlapLeniency(!ARCHIVE_MODE)
                                        .setCategoryMatchMode(true)
                                        .setExpiredHandling(ARCHIVE_MODE)
                                        .setRecurrencesHandling(true)
                                        .setUndatedHandling(false);
//*/
// Redefine the range if we're viewing the archive
if (ARCHIVE_MODE) {
    range = new CollectorTimeRange(CollectorTimeRange.RANGE_EXPIRED, DATE_NOW);
}
for (String folder : eventFolders) {
    String siteRootOri = cms.getRequestContext().getSiteRoot();
    String siteRootTemp = null;
            
    if (folder.startsWith("/sites/")) {
        // This is a root path to another site on this OpenCms installation
        // (VERY rarely used - as of 2017-04 only on the intranet site)
        String[] folderParts = folder.substring(1).split("/");
        try {
            siteRootTemp = "/" + folderParts[0] + "/" + folderParts[1];
            cms.getRequestContext().setSiteRoot(siteRootTemp);
            folder = cms.getRequestContext().removeSiteRoot(folder);
        } catch (Exception e) {
            throw e;
        }
    }
    eventsCollector = new EventsCollector(cms, folder)
            .addCategoriesToMatch(paramFilterCategories)
            .excludeFolders(excludedEventsFolders) 
            .setSortOrder(!ARCHIVE_MODE)
            .setOverlapLeniency(!ARCHIVE_MODE)
            .setCategoryMatchMode(true)
            .setExpiredHandling(ARCHIVE_MODE)
            .setRecurrencesHandling(true)
            .setUndatedHandling(false)
            ;
    
    events.addAll(eventsCollector.get(range, limit));
    
    // Reset site root if necessary
    if (siteRootTemp != null) {
        cms.getRequestContext().setSiteRoot(siteRootOri);
    }
}

// If we're mixing from multiple folders, we need to sort events
if (eventFolders.size() > 1) {
    Collections.sort(events, ARCHIVE_MODE ? EventEntry.COMPARATOR_START_TIME_DESC : EventEntry.COMPARATOR_START_TIME);
}
    
/*
if (!ARCHIVE_MODE) {
    events.addAll(eventsCollector.get(range, limit));
    if (DEBUG) { 
        out.println("\n<!-- Added " + events.size() + " dated events"
                + " (" + (eventsCollector.isExpiredInclusive() ? "in" : "ex") + "cluding expired events"
                + ", " + (eventsCollector.isOverlapLenient() ? "in" : "ex") + "cluding events that only partially overlap the range). -->\n"); 
    }
    //*/
    /*
    // Get undated events
    if (!undatedEventsFolders.isEmpty()) {
        EventsCollector undatedCollector = new EventsCollector(cms)
                                                .addCategoriesToMatch(paramFilterCategories)
                                                .excludeFolders(excludedEventsFolders)
                                                .setExpiredHandling(true)
                                                .setUndatedHandling(true)
                                                .setRecurrencesHandling(false);

        Iterator<String> iUndatedEventsFolders = undatedEventsFolders.iterator();
        while (iUndatedEventsFolders.hasNext()) {
            String undatedEventFolder = iUndatedEventsFolders.next();
            noDateEvents.addAll(undatedCollector.get(undatedEventFolder, CollectorTimeRange.getCatchAllRange(), -1));
        }
    }
    if (DEBUG) { out.println("\n<!-- Collected " + noDateEvents.size() + " undated events. -->\n"); }
    //*/
/*
} 
    
else { // if (ARCHIVE_MODE) 
//*/
if (ARCHIVE_MODE) {

    //events.addAll(eventsCollector.get(new CollectorTimeRange(CollectorTimeRange.RANGE_EXPIRED, DATE_NOW), limit));

    // We need to MANUALLY remove any event(s) that started before "now", but have not yet expired.
    Iterator<EventEntry> iExpired = events.iterator();
    while (iExpired.hasNext()) {
        EventEntry e = iExpired.next();
        if (!e.isExpired(DATE_NOW)) {
            iExpired.remove();
        }
    }
    //eventsExpired.removeAll(noDateEvents); // ToDo: This shouldn't be necessary...
    //if (DEBUG) { out.println("\n<!-- Collected " + events.size() + " expired events. -->\n"); }
}

if (DEBUG) {
    out.println("\n<!-- Added " + events.size() + " " + (ARCHIVE_MODE ? "expired" : "dated") + " events"
            + " (" + (eventsCollector.isExpiredInclusive() ? "in" : "ex") + "cluding expired events"
            + ", " + (eventsCollector.isOverlapLenient() ? "in" : "ex") + "cluding events that only partially overlap the range). -->\n"); 
}

//int numCurrentRangeEvents = eventsInRange.size(); // The number of dated events, for convenience
//int numNoDateEvents = noDateEvents.size(); // The number of undated events, for convenience

out.println("<!-- \nCategories:");
Map<String, Integer> resultCategories = eventsCollector.getResultCategories();
for (String resCat : resultCategories.keySet()) {
    out.println("   - " + resCat + " (" + resultCategories.get(resCat) + ")");
}
out.println("\n-->");
//
// Done collecting and sorting events
//
//##############################################################################





if (categoryFiltering) {
    out.println("<!-- BEGIN category filters -->");
    
    out.println("<!-- Resolving category filters ... -->");
    resolveCategoryFiltersForPaths(cmso, eventsCollector.getResultCategories(), CATEGORIES_PATH, out);

    try {
        if (catFilterSets.isEmpty() && !paramFilterCategories.isEmpty()) {
            // This is needed to create "remove filter" links in the case where 
            // a user has first activated a filter, and then changed the time 
            // parameters so that no events are listed.
            createCategoryFilters(paramFilterCategories, cmso, CATEGORIES_PATH, out);
        } else {
            
        }
    } catch (NullPointerException npe) {
        // Ignore
    }

    //
    // Category navigation
    //
    if (DEBUG) { out.println("<!-- Filter sets: " + catFilterSets.size() + " -->"); }
}
    
    

    %>
    <!--<div class="searchbox-big search-widget<%= categoryFiltering ? " search-widget--filterable" : "" %>">-->
    <div class="search-panel">
        <!--<h2>Viser nå <strong><%= ARCHIVE_MODE ? "avsluttede" : "aktuelle" %></strong> hendelser</h2>-->
        <h2 class="search-panel__heading"><%= ARCHIVE_MODE ? LABEL_VIEWING_EXPIRED : LABEL_VIEWING_CURRENT %></h2>
        <p>
            <a class="cta" href="<%= cms.link(requestFileUri).concat(ARCHIVE_MODE ? "" : "?exp=on") %>">
                <!--<svg class="icon icon-undo"><use xlink:href="#icon-undo"></use></svg> -->
                <!--Se <%= ARCHIVE_MODE ? "aktuelle" : "avsluttede" %>-->
                <%= ARCHIVE_MODE ? LABEL_VIEW_CURRENT : LABEL_VIEW_EXPIRED %>
            </a>
        </p>
        
        <%
        if (categoryFiltering) { 
            SearchFilterSets filterSets = new SearchFilterSets();
            out.println(filterSets.getFiltersWrapperHtmlStart(LABEL_FILTERS));
        %>
                    <div class="layout-group quadruple layout-group--quadruple filter-widget">
                        <!--<div class="boxes">-->
        <%
    
    // Get the parameter string for the current request
    String parameterString = EventCalendarUtils.getParameterString(baseParamMap);
    
    
    Iterator<String> iCatFilterSets = catFilterSets.keySet().iterator();
    while (iCatFilterSets.hasNext()) {
        try {
            // Get the next set of category filters
            CategoryFilterSet set = catFilterSets.get(iCatFilterSets.next());
            // Exclude all filters flagged as "excluded" in the config file
            set.excludeAll(excludedNavCategories);
            // Sort the filters in the set
            set.sortCategoryFilters(categoriesSort);
            // Get the filters
            List<CategoryFilter> filters = set.getCategoryFilters();
            
            if (filters != null) {
                Iterator<CategoryFilter> iFilters = filters.iterator();
                if (iFilters.hasNext()) {
                    String filtersHtml = "";
                    while (iFilters.hasNext()) {
                        CategoryFilter filter = iFilters.next();
                        // Create the "apply filter" or "remove filter" link
                        String filterLink = filter.getApplyOrRemoveLink(PARAM_NAME_CATEGORY, cms.link(OVERVIEW_FILE), parameterString);
                        filtersHtml += "<li>" + filterLink + "</li>";
                    }
                    if (!filtersHtml.isEmpty()) {
                        %>
                            <div class="layout-box filter-set">
                                <h3 class="filter-set__heading"><%= set.getTitle() %></h3>
                                <ul class="filter-set__filters">
                                    <%= filtersHtml %>
                                </ul>
                            </div>
                        <%
                    }
                } else {
                    // No filters in this filter set
                }
            } else {
                // Error(?): Fetching filters for this filter set returned null?
            }
        } catch (Exception e) {
            // WTF?
        }
    }
    %>
                        <!--</div>-->
                    </div>
                      
            <%
                out.println(filterSets.getFiltersWrapperHtmlEnd());
            } // END if (category filters)
            %>
        <!--</form>-->
    </div>
    <%
    // Clear the static list of category filter sets
    catFilterSets.clear(); // MUY IMPORTANTE! ##################################
    if (categoryFiltering) {
    %>
    <div id="filters-details"></div>
    <!-- END category filters -->
    <%
    }








//if (displayType > 0) {
    
    // Get the string of parameters (if any)
    String baseParamString = EventCalendarUtils.getParameterString(baseParamMap);
    String expiredHeading = LABEL_FINISHED;
        
    // Current / in-progress events
    if (!ARCHIVE_MODE) {

        if (!events.isEmpty()) {
            printEventsList(cms, events, null, "Aktuelle: " + LABEL_ONGOING_AND_UPCOMING, showCalendarIcon, showEventDescription, df, baseParamString, displayCategories, CATEGORIES_PATH, out);
        }
        /*
        if (!noDateEvents.isEmpty()) {
            if (range.getRange() == CollectorTimeRange.RANGE_YEAR || range.getRange() == CollectorTimeRange.RANGE_CATCH_ALL) {
                Collections.sort(noDateEvents, EventEntry.COMPARATOR_TITLE);
                String noDateListHeading = (numNoDateEvents == 0 ? LABEL_NO_EVENTS : 
                                                (numNoDateEvents + " " + (numNoDateEvents == 1 ? LABEL_EVENT.toLowerCase() : LABEL_EVENTS.toLowerCase()))) + 
                                                " " + LABEL_WITHOUT_DATE + (numNoDateEvents == 0 ? "." : ":");
                
                %>
                <h2><%= noDateListHeading %></h2>
                <%
                // List of undated events
                if (!noDateEvents.isEmpty()) {
                    printEventsList(cms, noDateEvents, "<em>" + "NO DATE:" + LABEL_DATE_NOT_DETERMINED + "</em>", LABEL_WITHOUT_DATE, showCalendarIcon, showEventDescription, df, baseParamString, displayCategories, CATEGORIES_PATH, out);
                }
            }
        } // End of "undated events" list
        */
    } 
    // Expired events (archive mode)
    else {
        if (!events.isEmpty()) {
            expiredHeading = LABEL_FINISHED;
            //out.println("<h2 id=\"h-events-expired\">Arkiv: " + expiredHeading + "</h2>");
            printEventsList(cms, events, null, expiredHeading, showCalendarIcon, showEventDescription, df, baseParamString, displayCategories, CATEGORIES_PATH, out);
            //printEventsTable(cms, eventsExpired, null, eventTableStart, showEventDescription, false, df, baseParamString, displayCategories, CATEGORIES_PATH, out);
        }
    }

    Map<String, String[]> ajaxParams = new HashMap<String, String[]>();
    ajaxParams.put(PARAM_NAME_EVENTS_FOLDER, new String[] { eventsFolder });
    if (eventFolders.size() > 1) {
        String additionalFolders = "";
        for (String additionalFolder : eventFolders.subList(0, eventFolders.size() - 1)) {
            additionalFolders += (additionalFolders.isEmpty() ? "" : ",") + additionalFolder;
        }
        ajaxParams.put(PARAM_NAME_EVENT_FOLDERS_ADD, new String[] { additionalFolders });
    }
    ajaxParams.put(PARAM_NAME_CATEGORY_PATH, new String[] { categoryPath });
    ajaxParams.put(PARAM_NAME_LOCALE, new String[] { locale.toString() });
    ajaxParams.put(PARAM_NAME_OFFSET, new String[] { String.valueOf(limit) });
    ajaxParams.put(PARAM_NAME_DESCRIPTIONS, new String[] { String.valueOf(showEventDescription) });
    baseParamMap.put(PARAM_NAME_LIMIT, new String[] { String.valueOf(limit+DEFAULT_LIMIT) });

    String moreLink = CmsRequestUtil.appendParameters(cms.link(requestFileUri), baseParamMap, true);
    String ajaxLink = CmsRequestUtil.appendParameters(cms.link(AJAX_EVENTS_PROVIDER), baseParamMap, true);
    ajaxLink = CmsRequestUtil.appendParameters(ajaxLink, ajaxParams, true);
    if (events.size() < eventsCollector.getTotalResults()) {
        out.println("<a class=\"load-more async\" data-parent=\"event-list\" href=\"" + CmsRequestUtil.appendParameters(cms.link(requestFileUri), baseParamMap, true) + "\">" + LABEL_LOAD_MORE + "</a>");
    }
    //if (includeTemplate) {
    //    out.println("</article><!-- .main-content -->");
    //}
//}
%>    
<script>
    var lastItemLoaded = false;
    
    $(".load-more").each( function() {
        $(this).attr("href", "<%= ajaxLink %>");
    });
    
    $("a").click( function(event) {
        if ($(this).hasClass("async")) {
            event.preventDefault();
            
            if ($(this).hasClass("load-more")) {
                var uri = $(this).attr("href");
                var parentId = $(this).attr("data-parent");
                var errorLoading = false;
                console.log("Loading " + uri);
                
                $.ajax({
                    url : uri,
                    type : "GET",
                    success : function(response) {
                        if (response.indexOf("initTrace") < 0) { // initTrace appears in error messages
                            $("#"+parentId).append(response);
                        } else {
                            errorLoading = true;
                        }
                    },
                    error : function() {
                        $("#"+parentId).append("<li><em>Something went wrong!</em></li>");
                        errorLoading = true;
                    }
                });
                
                
                
                //$("#event-list").append($.load(uri));// + " #event-list li");
                $(this).attr("href", updateLoadMoreUri(uri, parseInt(<%= DEFAULT_LIMIT %>)));
                if (lastItemLoaded || errorLoading) {
                    $(this).remove();
                }
            }
        }
    });
    
    function updateLoadMoreUri(/*String*/uri, /*int*/itemsLoaded) {
        var limitRemoved = removeParameter(uri, "<%= PARAM_NAME_LIMIT %>");
        console.log("Limit removed: " + JSON.stringify(limitRemoved));
        uri = limitRemoved.uri;
        
        var offsetRemoved = removeParameter(uri, "<%= PARAM_NAME_OFFSET %>");
        console.log("Offset removed: " + JSON.stringify(offsetRemoved));
        uri = offsetRemoved.uri;
        if ((parseInt(offsetRemoved.paramVal) + itemsLoaded) >= parseInt(<%= eventsCollector.getTotalResults() %>)) {
            lastItemLoaded = true;
        }
        
        return uri += "&<%= PARAM_NAME_LIMIT %>=" + (parseInt(limitRemoved.paramVal)+itemsLoaded) 
                    + "&<%= PARAM_NAME_OFFSET %>=" + (parseInt(offsetRemoved.paramVal) + itemsLoaded);
    }
    
    function removeParameter(/*String*/uri, /*String*/parameterName) {
        try {
            console.log("  Looking for '" + parameterName + "'...");
            var pos = uri.indexOf(parameterName);
            var param = uri.substring(pos);
            if (param.indexOf("&") > -1) {
                param = param.substring(0, param.indexOf("&"));
            }
            console.log("  Found '" + param + "' at position " + pos);
            uri = uri.replace(param, "");
            console.log("  Removing '" + param + "' from URI");
            uri = uri.replace("&&", "&");
            var param = param.substring(param.indexOf("=") + 1);
            return { "uri" : uri, "paramKey" : parameterName, "paramVal" : param };
        } catch (err) {
            return { "uri" : uri, "paramKey" : parameterName, "paramVal" : "0" };
        }
    }
</script>
<%
// Include the outer template, if needed
if (includeTemplate) {
    out.println("</article><!-- .main-content -->");
    cms.includeTemplateBottom();
}

%>
