<%-- 
    Document   : eventcalendar.jsp - customized for the NPI website
    Created on : 29.apr.2011, 11:30:49
    Author     : Paul-Inge Flakstad <flakstad at npolar.no>
--%><%@ page import="java.util.*,
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

        out.println("<li>" +
                        "<span class=\"event-time\">" +
                            (eventTimeOverride == null ?
                            (df.format(new Date(event.getStartTime())) +
                            (!event.isOneDayEvent() ? (" &ndash; " + df.format(new Date(event.getEndTime()))) : "")) :
                            eventTimeOverride) +
                        "</span>" +
                        "<span class=\"event-info\">" +
                            "<a href=\"" + 
                                cms.link(cmso.getSitePath(eventResource)) +
                                (baseParamString.isEmpty() ? "" : ("?" + baseParamString)) + "\"" + 
                                (event.isExpired() ? " class=\"event-pastevent\"" : "") +
                            ">" +
                                event.getTitle() +
                            "</a>" +
                            (showEventDescription ? ("<p>" + event.getDescription() + "</p>") : "") +
                        "</span>");
        if (!displayCategories.isEmpty()) {
            printDisplayCategories(cmso, eventResource, displayCategories, categoryReferencePath, "span", out);
        }
        
        out.println("</li>");

    }
    out.println("</ul>");
}

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
            out.println("<tr class=\"" + (++eventsCounter % 2 == 0 ? "even" : "odd") + "\">" +
                            "<td class=\"event-time\">" +
                                (eventTimeOverride == null ?
                                    (df.format(new Date(event.getStartTime())) +
                                        (event.hasEndTime() && !event.isOneDayEvent() ? (" &ndash;<br />" + df.format(new Date(event.getEndTime()))) : "")) :
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
                                    ">" + 
                                        event.getTitle() +
                                    "</a>" +
                                "</h4>" +
                                (showEventDescription ? ("<p>" + event.getDescription() + "</p>") : "") +
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
%>
<%
final boolean DEBUG                     = request.getParameter("debug") == null ? false : true;
final String AJAX_EVENTS_PROVIDER      = "/system/modules/no.npolar.common.event/elements/events-provider.jsp";
CmsAgent cms                            = new CmsAgent(pageContext, request, response);
CmsObject cmso                          = cms.getCmsObject();
Locale locale                           = cms.getRequestContext().getLocale();
String requestFileUri                   = cms.getRequestContext().getUri();
String requestFolderUri                 = cms.getRequestContext().getFolderUri();

// Determine if no parameters used for filtering events are present
// (in which case a complete list of events should be collected and presented)
boolean fullList = request.getParameter("y") == null &&
                    request.getParameter("m") == null &&
                    request.getParameter("w") == null &&
                    request.getParameter("d") == null &&
                    request.getParameter("cat") == null;

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
int initialRange                = -99;
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
    // Whether or not to hide events that are over
    hideExpiredEvents = Boolean.valueOf(cms.contentshow(configuration, "HideExpiredEvents")).booleanValue();
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

// Parameter names
final String PARAM_NAME_RESOURCE_URI    = "resourceUri";
final String PARAM_NAME_CATEGORY        = "cat";
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
final String LABEL_EXPIRED              = cms.label("label.for.np_event.expired"); // Expired / Avsluttede
final String LABEL_UPCOMING             = cms.label("label.for.np_event.upcoming"); // Kommer / Upcoming
final String LABEL_IN_PROGRESS          = cms.label("label.for.np_event.inprogress"); // Startet tidligere / Started earlier
final String LABEL_STARTS               = cms.label("label.for.np_event.starts"); // Starter / Starts
final String LABEL_STARTS_IN            = cms.label("label.for.np_event.startsin"); // Starter i / Starts in
final String LABEL_FINISHED_IN          = cms.label("label.for.np_event.finishedin"); // Avsluttet i / Finished in
final String LABEL_ONGOING_AND_UPCOMING = cms.label("label.for.np_event.ongoingupcoming"); // Pågående og kommende / In progress and upcoming
final String LABEL_NEXT                 = cms.label("label.for.np_event.nextevent"); // Neste / Next
final String LABEL_NONE_THIS_MONTH      = cms.label("label.for.np_event.nonethismonth"); // Ingen denne måneden / None this month

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
final String INPUT_HIDDEN_START         = "<input type=\"hidden\" value=\"";

// The date format to use on lists and alike
SimpleDateFormat df = new SimpleDateFormat(cms.label("label.event.dateformat.dateonly_short"), locale);
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

// List of categories present as request parameters (e.g.: /file.html?y=2010&m=5)
ArrayList paramCategoryStrings = null;
// List of CmsCategory objects - based on the "cat" parameter
ArrayList paramCategories = null;


//calendar.setTime(new Date()); // Set calendar time to NOW
calendar.setTime(initialTime); // Set the initial calendar time
calendar.setFirstDayOfWeek(Calendar.MONDAY); // Set start of week to Monday
int m = calendar.get(Calendar.MONTH);
int y = calendar.get(Calendar.YEAR);//displayType == 0 ? calendar.get(Calendar.YEAR) : -1;//calendar.get(Calendar.YEAR);
int d = calendar.get(Calendar.DATE);
int w = calendar.get(Calendar.WEEK_OF_YEAR);
//int range = EventCalendar.RANGE_CURRENT_MONTH; // Set range to current month
int range = initialRange;//defaultRange; // TEMPORARY

if (displayType == 0) {
    range = EventCalendar.RANGE_CURRENT_MONTH;
}

if (DEBUG) {
    out.println("<h5>Calendar initialized. Inital time is " + sqlFormat.format(calendar.getTime()) + ". Initial range is " + range + ".</h5>");
}

//
// Date parameters, possible parameter names are "y", "m", "w" and "d"
//
// Parameters set: y, m, d
if (request.getParameter(PARAM_NAME_DATE) != null && request.getParameter(PARAM_NAME_MONTH) != null 
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
// Parameters set: y, w
else if (request.getParameter(PARAM_NAME_YEAR) != null && request.getParameter(PARAM_NAME_WEEK) != null) {
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
// Parameters set: y, m
else if (request.getParameter(PARAM_NAME_MONTH) != null && request.getParameter(PARAM_NAME_YEAR) != null) {
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
// Parameters set: y
else if (request.getParameter(PARAM_NAME_YEAR) != null) {
    y = Integer.valueOf(request.getParameter(PARAM_NAME_YEAR)).intValue();
    /*if (y < 0)
        throw new IllegalArgumentException("Illegal number for year: " + y + ". Value cannot be negative.");*/
    if (y == -1)
        range = EventCalendar.RANGE_CATCH_ALL;
    else
        range = EventCalendar.RANGE_CURRENT_YEAR;
}
//
// Set the calendar date, after the calendar parameters have been read
//

// Date, month and year should have been checked by now, so it should be safte to set them at this point
if (m > -1)
    calendar.set(Calendar.MONTH, m);
// IMPORTANT:
m = calendar.get(Calendar.MONTH); // Because if m=-1, it will cause trouble after this point
calendar.set(Calendar.YEAR, y);
calendar.set(Calendar.DATE, d);

initialTime = calendar.getTime(); // Modify the initial time (the config value is used ONLY when no time parameters are used)
if (DEBUG) {
    out.println("<h5>Processed calendar parameters. Time is set to " + sqlFormat.format(calendar.getTime()) + ". Range is set to " + range + ".</h5>");
}


// Set range heading for sub-lists
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
// Category parameter, parameter name is "cat"
//
// ToDo: Need to fill this list with CmsCategory objects instead of Strings.
// This will enable the use of relative paths like event/meeting/ instead of 
// root paths like /sites/default/no/_categories/event/meeting/
if (request.getParameter(PARAM_NAME_CATEGORY) != null) {
    List pc = Arrays.asList(request.getParameterValues(PARAM_NAME_CATEGORY));
    /*
    // OLD outcommented
    paramCategories = new ArrayList(pc);
    // Remove all occurrences of "all categories"
    Iterator iParamCategories = paramCategories.iterator();
    while (iParamCategories.hasNext()) {
        if (KEYWORD_ALL_CATEGORIES.equals((String)iParamCategories.next())) {
            iParamCategories.remove();
        }
    }
    // End OLD */
    
    // NEW: create CmsCategory objects instead of using Strings
    paramCategoryStrings = new ArrayList(pc);
    paramCategories = new ArrayList();
    // Remove all occurrences of "all categories" 
    // and create the list of CmsCategory objects
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
                out.println("\n<!-- Found category filter: '" + cat.getRootPath() + "' (relative path: '" + cat.getPath() + "') -->");
            } catch (Exception readCatError) {
                out.println("\n<!-- Exception when reading category: " + readCatError.getMessage() + " -->");
            }
        }
    }
}

// Get the "top level" paramCategories
List topLevelCategories = catService.readCategories(cmso, null, false, CATEGORIES_PATH);
// Get all paramCategories under the specified category folder
List allCategories = catService.readCategories(cmso, null, true, CATEGORIES_PATH);
// Get the "leaf" or "bottom level" paramCategories by subtracting the top level paramCategories from all paramCategories
List leafCategories = new ArrayList(allCategories);
leafCategories.removeAll(topLevelCategories);
 



//
// Keep the current values individually
//
weekday = calendar.get(Calendar.DAY_OF_WEEK);           // Weekday
week    = calendar.get(Calendar.WEEK_OF_YEAR);          // Week of year
month   = calendar.get(Calendar.MONTH);                 // Month
year    = calendar.get(Calendar.YEAR);                  // Year
daysInMonth = calendar.getActualMaximum(Calendar.DATE); // Number of days in the current month



//
// Get all events in the current range
//
// Set initial argument variables
boolean sortDescending = true;
boolean overlapLenient = true;
boolean categoryInclusive = false;
// NB: getEvents(...) must be called prior to calling getDatedEvents(), getUndatedEvents() or getExcludedEvents()
List allEventsInRange = calendar.getEvents(range, cms, eventsFolder, 
                                        undatedEventsFolders, excludedEventsFolders, paramCategories, 
                                        hideExpiredEvents, sortDescending, overlapLenient, categoryInclusive, -1);
//List datedEvents = calendar.getDatedEvents();
List noDateEvents = calendar.getUndatedEvents();
//List excludedEvents = calendar.getExcludedEvents();

//
// New getEvents() - group/sort events by "relevancy"
//
Calendar todayCalendar = new GregorianCalendar();
todayCalendar.setTimeInMillis(new Date().getTime());
boolean calendarRepresentsCurrentMonth = 
            calendar.get(Calendar.YEAR) == todayCalendar.get(Calendar.YEAR) && 
            calendar.get(Calendar.MONTH) == todayCalendar.get(Calendar.MONTH); // same month
//boolean categoryInclusive = false;
//boolean sortDescending = true;
// Set overlap lenient mode to "false":
// Get events in current range, NON-LENIENT overlap mode 
// (This will exclude events that start before the range and stretches into the range)
overlapLenient = false;
List<EventEntry> eventsStartingInRange = calendar.getEvents(range, cms, eventsFolder,
                                                    undatedEventsFolders, excludedEventsFolders, paramCategories,
                                                    hideExpiredEvents, sortDescending, overlapLenient, categoryInclusive, -1);


// Get events in current range, LENIENT overlap mode (include events that start before the range and stretches into the range)
overlapLenient = true;
List<EventEntry> eventsOverlappingRange = calendar.getEvents(range, cms, eventsFolder,
                                                    undatedEventsFolders, excludedEventsFolders, paramCategories,
                                                    hideExpiredEvents, sortDescending, overlapLenient, categoryInclusive, -1);

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
//datedEvents.clear();
List datedEvents = new ArrayList();
datedEvents.addAll(eventsStartingInRange);
datedEvents.addAll(eventsOverlappingRange);
datedEvents.addAll(eventsExpired);

//
// Set rangeIncludesToday, used to determine whether to highlight today
//
boolean rangeIncludesToday = false;
switch (range) {
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

List<EventEntry> eventsStartingToday = new ArrayList<EventEntry>();
if (rangeIncludesToday) {
    Iterator iInRange = eventsStartingInRange.iterator();
    while (iInRange.hasNext()) {
        EventEntry ee = (EventEntry)iInRange.next();
        if (ee.startsOnDate(new Date(todayCalendar.getTimeInMillis()))) {
            eventsStartingToday.add(ee);
            iInRange.remove();
        }
    }
}



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
                monthSelect += OPTION_START + "-1\">" + LABEL_ALL + " (" + (numAllMonthsMatches ) + ")" + OPTION_END; // Add this one before the "january" option
            }
            if (numMatches > 0 || (datedEvents.isEmpty() && m == monthNo)) {
                monthSelect += OPTION_START + calendar.get(Calendar.MONTH) + "\"";
                if (range == EventCalendar.RANGE_CURRENT_MONTH || range == EventCalendar.RANGE_CURRENT_DATE) {
                    if (m == calendar.get(Calendar.MONTH) && request.getParameter(PARAM_NAME_DATE) == null) // Don't set a selected month when viewing specific dates
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
        calendar.set(Calendar.YEAR, beginYear); // TESTING IN ATTEMPT TO MAKE ALL VALID YEARS APPEAR IN THE DROP-DOWN
        
        out.println("<!-- YEARS INTERVAL: " + beginYear + " - " + endYear + " -->");
        
        while (calendar.get(Calendar.YEAR) <= endYear) {
            int numMatches = 0;                  
            try {
                if (calendar.get(Calendar.YEAR) == beginYear) {
                    // Add the "All" option
                    numMatches = allEvents.size();
                    yearSelect += OPTION_START + "-1\"" + (range == EventCalendar.RANGE_CATCH_ALL ? OPTION_SELECTED : "") + ">" + 
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
                yearSelect += OPTION_START + calendar.get(Calendar.YEAR) + "\"" + 
                        (y == calendar.get(Calendar.YEAR) && range != EventCalendar.RANGE_CATCH_ALL ? OPTION_SELECTED : "") + ">" +
                        calendar.get(Calendar.YEAR) + " (" + numMatches + ")" + OPTION_END;
            }
            calendar.set(Calendar.YEAR, calendar.get(Calendar.YEAR)+1);
            // Done with number of matches for this year
        }
    } else {
        yearSelect += OPTION_START + "-1\">" + LABEL_ALL + " (" +
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
    // Host selection
    //
    String hostSelect = "";
    if (CmsAgent.elementExists(hostCategoryPath)) {
        hostSelect = LABEL_HOST + ": "; // Label ("Arrangør")
        hostSelect += "<select name=\"" + PARAM_NAME_CATEGORY + "\" onchange=\"submit()\">";
        hostSelect += "<option value=\"all\">" + LABEL_ALL + "</option>";
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
                        "<option value=\"" + hostCatPath + "\"" + optionState + ">" + hostName + " (" + numCatMatches + ")" + "</option>"));
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
        hostSelect += "</select>";
        hostSelect += hiddenParamsHost;
    }



    out.println("<div class=\"view-select\">");
    out.println("<form name=\"viewselect\" action=\"" + cms.link(OVERVIEW_FILE) + "\" method=\"get\">");
    out.println("<div class=\"view-option\">" + yearSelect + "</div>");
    out.println("<div class=\"view-option\">" + monthSelect + "</div>");
    out.println(hiddenParams);
    out.println("</form>");
    if (CmsAgent.elementExists(hostCategoryPath) && hostSelect.length() > 0) {
        out.println("<form name=\"hostselect\" action=\"" + cms.link(OVERVIEW_FILE) + "\" method=\"get\">");
        out.println("<div class=\"view-option\">" + hostSelect + "</div>");
        out.println("</form>");
    }
    
    if (!fullList)
        out.println("<div class=\"view-option\"><a href=\"" + cms.link(requestFileUri) + "?y=-1\" rel=\"nofollow\">" + LABEL_VIEW_ALL + "</a></div>");
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
                        " border=\"0\" cellspacing=\"0\" cellpadding=\"0\"" + 
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
            // Always show ALL events (including expired) in the calendar, even if set to "hide expired events"
            List todaysEvents = calendar.getEvents(EventCalendar.RANGE_CURRENT_DATE, cms, 
                                                    eventsFolder, undatedEventsFolders, excludedEventsFolders, paramCategories, 
                                                    false, sortDescending, overlapLenient, categoryInclusive, -1);
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
                out.print(" onmouseover=\"return overlib('" + CmsStringUtil.escapeHtml(eventsHtml) + "');\" onmouseout=\"return nd();\"");
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

        String inRangeHeading = range == EventCalendar.RANGE_CURRENT_DATE ? (LABEL_STARTS + " ") : (range == EventCalendar.RANGE_CATCH_ALL ? LABEL_ONGOING_AND_UPCOMING : (LABEL_STARTS_IN + " ")) + datedRangeSubListHeading;
        String expiredHeading = LABEL_FINISHED_IN + " " + datedRangeSubListHeading;
        
        //
        // List of dated events. Table for rich listings, list for simpler listings
        //
        if (displayType > 1) { // Option 1: as a table
            //printEventsTable(cms, datedEvents, null, eventTableStart, showEventDescription, true, df, baseParamString, displayCategories, CATEGORIES_PATH, out);
            // More user-friendly listing: differenciate collections of events
            // 1: events starting in range (begginging this year/month/week/date)
            if (!eventsStartingInRange.isEmpty()) {
                out.println("<h3 id=\"events-start-in-range\">" + inRangeHeading + "</h3>");
                printEventsTable(cms, eventsStartingInRange, null, eventTableStart, showEventDescription, true, df, baseParamString, displayCategories, CATEGORIES_PATH, out);
            }
            // 2: events overlapping current range (started earlier)
            if (!eventsOverlappingRange.isEmpty()) {
                out.println("<h3 id=\"events-overlapping-range\">" + LABEL_IN_PROGRESS + "</h3>");
                printEventsTable(cms, eventsOverlappingRange, null, eventTableStart, showEventDescription, true, df, baseParamString, displayCategories, CATEGORIES_PATH, out);
            }
            // 3: Expired events (only for listings other than "catch all" - for that list, we'll show expired events at the very bottom)
            if (!eventsExpired.isEmpty() && range != EventCalendar.RANGE_CATCH_ALL) {
                out.println("<h3 id=\"events-expired\">" + expiredHeading + "</h3>");
                printEventsTable(cms, eventsExpired, null, eventTableStart, showEventDescription, true, df, baseParamString, displayCategories, CATEGORIES_PATH, out);
            }
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
                        printEventsList(cms, nextEvents.subList(0, 1), null, LABEL_NEXT, showEventDescription, df, baseParamString, displayCategories, CATEGORIES_PATH, out);
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
        out.println("<h3>" + LABEL_EXPIRED + "</h3>");
        printEventsTable(cms, eventsExpired, null, eventTableStart, showEventDescription, true, df, baseParamString, displayCategories, CATEGORIES_PATH, out);
    }
    
    
    //
    // Category navigation, moved to right hand side + disabled the calendar
    //
    if (includeTemplate)
        out.println("</div><!-- .twocol -->");
}












if (displayType > 2 && displayType < 5) {
    //
    // Category navigation
    //
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
                            /*if (!noDateEvents.isEmpty() && (range == EventCalendar.RANGE_CURRENT_YEAR || range == EventCalendar.RANGE_CATCH_ALL)) {
                                try {
                                    Iterator iUndatedFolders = undatedEventsFolders.iterator();
                                    while (iUndatedFolders.hasNext()) {
                                        String undatedFolder = (String)iUndatedFolders.next();
                                        numCatMatches += calendar.getEvents(0, Integer.MAX_VALUE, cms, 
                                                                        undatedFolder, null, excludedEventsFolders, catMatches, 
                                                                        hideExpiredEvents, sortDescending, overlapLenient, categoryInclusive, -1).size();
                                    }
                                } catch (NullPointerException npe) {
                                    // Sustain previous value for numCatMatches
                                }
                            }*/
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
    
    out.println("<!-- END of category filtering -->");
}





// Include the outer template, if needed
if (includeTemplate) {
    out.println("</div><!-- .onecol -->"); //this is output by the template
    cms.includeTemplateBottom();
}
%>