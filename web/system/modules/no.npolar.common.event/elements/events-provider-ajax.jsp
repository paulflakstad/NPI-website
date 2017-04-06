<%-- 
    Document   : events-list.jsp - remake of eventcalendar.jsp
    Created on : 2016-01-14
    Author     : Paul-Inge Flakstad, Norwegian Polar Institute <flakstad at npolar.no>
--%><%@ page import="java.util.*,
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
                 org.opencms.util.CmsRequestUtil,
                 org.opencms.util.CmsUUID,
                 org.opencms.util.CmsStringUtil"  session="true" 
%><%!
public String rangeExplain(CollectorTimeRange r) {
    SimpleDateFormat df = new SimpleDateFormat("yyyy-MM-dd");
    return r.toString().concat(" [" + df.format(new Date(r.getStart())) + " - " + df.format(new Date(r.getEnd())) + "]");
}

/**
 * Prints a events as list items.
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
    
    Iterator i = events.iterator();
    
    if (listHeading != null && !listHeading.isEmpty()) {
        out.println(sectionHeadStart + listHeading + sectionHeadEnd);
        out.println("<ul class=\"event-list\" id=\"event-list\">");
    }
    //out.println("<ul class=\"event-list\" id=\"event-list\">");
    while (i.hasNext()) {
        EventEntry event = (EventEntry)i.next();
        CmsResource eventResource = cmso.readResource(event.getStructureId());
        
        // Relocated this call, is now in JSP body
        //resolveCategoryFiltersForResource(cmso, eventResource, categoryReferencePath, out);
            
        //SimpleDateFormat dfIso = getDatetimeAttributeFormat(cmso, eventResource);
        SimpleDateFormat dfIso = event.getDatetimeAttributeFormat(cms.getRequestContext().getLocale());
        
        String start = null, end = null;
        try {
            start = "<time itemprop=\"startDate\" datetime=\"" + dfIso.format(new Date(event.getStartTime())) + "\">" + df.format(new Date(event.getStartTime())) + "</time>";
            end = "<time itemprop=\"endDate\" datetime=\"" + dfIso.format(new Date(event.getEndTime())) + "\">" + df.format(new Date(event.getEndTime())) + "</time>";
        } catch (Exception e ) {
           // Do nothing
        }

        String eventUri = cms.link(cmso.getSitePath(eventResource));
        if (!baseParamString.isEmpty()) {
            //eventUri += "?" + baseParamString;
        }
        if (event.isRecurrence()) {
            eventUri = CmsRequestUtil.appendParameter(eventUri, "begin", Long.toString(event.getStartTime()));
        }

        out.println("<li itemscope itemtype=\"http://schema.org/Event\">" +
                        "<span class=\"event-time\">" +
                                (eventTimeOverride == null ?
                                    event.getTimespanHtml(cms, getOpenCmsCurrentTime(cms.getCmsObject()))
                                    //(start + (!event.isOneDayEvent() ? (" &ndash; " + end) : "")) 
                                    : 
                                    eventTimeOverride) +
                        "</span>" +
                        "<span class=\"event-info\">" +
                            "<a href=\"" + eventUri + "\"" +
                                //cms.link(cmso.getSitePath(eventResource)) +
                                //(baseParamString.isEmpty() ? "" : ("?" + baseParamString)) + "\"" + 
                                //(event.isExpired() ? " class=\"event-pastevent\"" : "") +
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
    if (listHeading != null && !listHeading.isEmpty()) { 
        out.println("</ul>");
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
%><%
CmsAgent cms                            = new CmsAgent(pageContext, request, response);
CmsObject cmso                          = cms.getCmsObject();
Locale locale                           = cms.getRequestContext().getLocale();
String requestFileUri                   = cms.getRequestContext().getUri();
String requestFolderUri                 = cms.getRequestContext().getFolderUri();

final Date DATE_NOW                     = getOpenCmsCurrentTime(cmso);

// Constants
final boolean DEBUG                     = false; //request.getParameter("debug") == null ? false : true;
final String AJAX_EVENTS_PROVIDER       = "/system/modules/no.npolar.common.event/elements/events-provider-ajax.jsp";

// Parameter names
final String PARAM_NAME_RESOURCE_URI    = "resourceUri";
final String PARAM_NAME_CATEGORY        = "cat";
final String PARAM_NAME_EXPIRED         = "exp";

// AJAX parameter names
//final String PARAM_NAME_HIDE_EXPIRED    = "hide_expired";
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

if (request.getParameter(PARAM_NAME_LOCALE) != null) {
    locale = new Locale(request.getParameter(PARAM_NAME_LOCALE));
    cms.getRequestContext().setLocale(locale);
}

//==============================================================================
//========================= READ THE CONFIG FILE ===============================
//==============================================================================
// Config variables
String eventsFolder             = request.getParameter(PARAM_NAME_EVENTS_FOLDER);

List<String> eventFolders       = new ArrayList<String>();
// Additional folders - not recommended...
// As of 2017-04, it is used only on the intranet site, to inject events from the public site)
String additionalFoldersStr     = request.getParameter(PARAM_NAME_EVENT_FOLDERS_ADD);
if (additionalFoldersStr != null && !additionalFoldersStr.trim().isEmpty()) {
    for (String additionalFolderUri : additionalFoldersStr.split(",")) {
        if (!additionalFolderUri.trim().isEmpty()) {
            eventFolders.add(additionalFolderUri);
        }
    }
}
// Add the main folder as the LAST item in the list
eventFolders.add(eventsFolder);

String categoryPath             = request.getParameter(PARAM_NAME_CATEGORY_PATH);
String undatedEventsFolder      = null; // Hard to manage a list, so use only one
List undatedEventsFolders       = new ArrayList(); // DUMMY list, methods in .jar need a list (ToDo: FIX!!!)
ArrayList displayCategories     = new ArrayList(); // List of categories to display in the events list
//String hostCategoryPath         = null;
//String calendarLinkPath         = null;
//String calendarAddClass         = null;
String labelSingular            = request.getParameter(PARAM_NAME_LABEL_SINGULAR);
String labelPlural              = request.getParameter(PARAM_NAME_LABEL_PLURAL);

List excludedEventsFolders = new ArrayList();
if (request.getParameter(PARAM_NAME_EXCLUDE_FOLDER) != null) {
    excludedEventsFolders = Arrays.asList(request.getParameter(PARAM_NAME_EXCLUDE_FOLDER));
}
//ArrayList excludedNavCategories = new ArrayList();
//Calendar minTime                = Calendar.getInstance();
Calendar maxTime                = Calendar.getInstance();
Date initialTime                = DATE_NOW;
//long minTimeLong                = 0;
//long maxTimeLong                = 0;
int categoriesSort              = -1;
//int initialRange                = -99; // 99 = catch all | 0 = current year | 1 = current month | 2 = current day | 3 = current week | 4 = upcoming and in progress | 98 = today and next N upcoming
CollectorTimeRange initialRange = CollectorTimeRange.getCatchAllRange();
int displayType                 = -1; // 0 = calendar only  |  1 = calendar & listing  |  2 = calendar, listing & navigation
//boolean showWeekNumbers         = true;
boolean showEventDescription    = Boolean.valueOf(request.getParameter(PARAM_NAME_DESCRIPTIONS));
//boolean hideExpiredEvents       = true;
boolean categoryFiltering       = true;





//
// Constants
//

final String LABEL_LOAD_MORE            = "Last flere";

final String CATEGORIES_PATH            = CmsAgent.elementExists(categoryPath) ? categoryPath : requestFolderUri;//requestFolderUri;//"/no/categories/";

// The date format to use on lists and alike
SimpleDateFormat df = new SimpleDateFormat(cms.label("label.event.dateformat.dateonly"), locale);

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
                CmsCategory cat = catService.readCategory(cmso, paramCatPath, categoryPath);
                // Store it in the list
                paramFilterCategories.add(cat);
                out.println("\n<!-- Found category filter: '" + cat.getRootPath() + "' (relative path: '" + cat.getPath() + "') -->");
            } catch (Exception readCatError) {
                out.println("\n<!-- Exception when reading category: " + readCatError.getMessage() + " -->");
            }
        }
    }
}

// Set the initial calendar time (by default "now", but possibly overridden)
collectorCal.setTime(initialTime);

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
/*List<EventEntry> eventsInRange = new ArrayList<EventEntry>();
List<EventEntry> noDateEvents = new ArrayList<EventEntry>();
List<EventEntry> eventsExpired = new ArrayList<EventEntry>();*/

// Limit
final int DEFAULT_LIMIT = 20;
int limit = DEFAULT_LIMIT;
try { limit = Integer.valueOf(request.getParameter(PARAM_NAME_LIMIT)); } catch (Exception e) {};
int offset = 0;
try { offset = Integer.valueOf(request.getParameter(PARAM_NAME_OFFSET)); } catch (Exception e) {};


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

    events = eventsCollector.get(range, limit);

    if (DEBUG) { out.println("\n<!-- Collected " + events.size() + " events"
                                + " (" + (eventsCollector.isExpiredInclusive() ? "in" : "ex") + "cluding expired events"
                                + ", " + (eventsCollector.isOverlapLenient() ? "in" : "ex") + "cluding events that only partially overlap the range). -->\n"); }
*/
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
/*} 
else { // if (ARCHIVE_MODE)

    events = eventsCollector.get(new CollectorTimeRange(CollectorTimeRange.RANGE_EXPIRED, DATE_NOW), limit);
    */
    /*
    // We need to MANUALLY remove any event(s) that started before "now", but have not yet expired.
    Iterator<EventEntry> iExpired = eventsExpired.iterator();
    while (iExpired.hasNext()) {
        EventEntry e = iExpired.next();
        if (!e.isExpired(DATE_NOW)) {
            iExpired.remove();
        }
    }
    //eventsExpired.removeAll(noDateEvents); // ToDo: This shouldn't be necessary...

    if (DEBUG) { out.println("\n<!-- Collected " + eventsExpired.size() + " expired events. -->\n"); }
    */
//}


//int numCurrentRangeEvents = eventsInRange.size(); // The number of dated events, for convenience
//int numNoDateEvents = noDateEvents.size(); // The number of undated events, for convenience
if (DEBUG) {
    out.println("\n<!-- Added " + events.size() + " " + (ARCHIVE_MODE ? "expired" : "dated") + " events"
            + " (" + (eventsCollector.isExpiredInclusive() ? "in" : "ex") + "cluding expired events"
            + ", " + (eventsCollector.isOverlapLenient() ? "in" : "ex") + "cluding events that only partially overlap the range). -->\n"); 
}
//
// Done collecting and sorting events
//
//##############################################################################









//if (displayType > 0) {
    
    // Get the string of parameters (if any)
    String baseParamString = EventCalendarUtils.getParameterString(baseParamMap);
    String heading = request.getParameter(PARAM_NAME_HEADING) == null ? "" : request.getParameter(PARAM_NAME_HEADING);
        
    // Current / in-progress events
    //if (!ARCHIVE_MODE) {

        //if (!eventsInRange.isEmpty()) {
            printEventsList(cms, events.subList(offset, events.size()), null, heading, showEventDescription, df, baseParamString, displayCategories, CATEGORIES_PATH, out);
        //}
        /*
        if (!noDateEvents.isEmpty()) {
            if (range.getRange() == CollectorTimeRange.RANGE_YEAR || range.getRange() == CollectorTimeRange.RANGE_CATCH_ALL) {
                Collections.sort(noDateEvents, EventEntry.COMPARATOR_TITLE);
                String noDateListHeading = (numNoDateEvents == 0 ? LABEL_NO_EVENTS : 
                                                (numNoDateEvents + " " + (numNoDateEvents == 1 ? LABEL_EVENT.toLowerCase() : LABEL_EVENTS.toLowerCase()))) + 
                                                " " + LABEL_WITHOUT_DATE + (numNoDateEvents == 0 ? "." : ":");
                // List of undated events
                if (!noDateEvents.isEmpty()) {
                    printEventsList(cms, noDateEvents, "<em>" + "NO DATE:" + LABEL_DATE_NOT_DETERMINED + "</em>", LABEL_WITHOUT_DATE, showEventDescription, df, baseParamString, displayCategories, CATEGORIES_PATH, out);
                }
            }
        } // End of "undated events" list
        */

    /*} 
    // Expired events (archive mode)
    else {
        if (!eventsExpired.isEmpty()) {
            printEventsList(cms, eventsExpired, null, heading, showEventDescription, df, baseParamString, displayCategories, CATEGORIES_PATH, out);
            //printEventsTable(cms, eventsExpired, null, eventTableStart, showEventDescription, false, df, baseParamString, displayCategories, CATEGORIES_PATH, out);
        }
    }*/

    if (events.size() < eventsCollector.getTotalResults()) {
        baseParamMap.put(PARAM_NAME_LIMIT, new String[] { String.valueOf(limit+DEFAULT_LIMIT) });
        baseParamMap.put(PARAM_NAME_OFFSET, new String[] { String.valueOf(limit) });
        //out.println("<a class=\"load-more async\" data-parent=\"event-list\" href=\"" + CmsRequestUtil.appendParameters(cms.link(AJAX_EVENTS_PROVIDER), baseParamMap, true) + "\">" + LABEL_LOAD_MORE + "</a>");
    }
    
    //if (includeTemplate) {
    //    out.println("</article><!-- .main-content -->");
    //}
//}

%>
