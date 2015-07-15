<%-- 
    Document   : seminars.jsp
    Created on : 01.des.2010, 14:01:51
    Author     : Paul-Inge Flakstad <flakstad at npolar.no>
--%><%@ page import="java.util.*,
                 java.text.SimpleDateFormat,
                 no.npolar.common.eventcalendar.*,
                 no.npolar.util.*,
                 org.opencms.file.CmsResource,
                 org.opencms.file.CmsObject,
                 org.opencms.main.CmsException,
                 org.opencms.xml.A_CmsXmlDocument,
                 org.opencms.xml.content.*,
                 org.opencms.relations.CmsCategory,
                 org.opencms.relations.CmsCategoryService,
                 org.opencms.util.CmsUUID,
                 org.opencms.util.CmsStringUtil"  session="true" 
%><%!
public String getEventsOverview(CmsAgent cms, String heading, List events, SimpleDateFormat df, Date nextDateIfNone, boolean fadePastEvents) throws CmsException {
    // Heading types and labels
    final String HEADING_LIST = "h2";
    final String HEADING_EVENT = "h4";
    final String LABEL_NONE = "None";
    //final String SEMINAR_PREFIX = cms.getRequestContext().getLocale().toString() == "no" ? "ICE-seminar: " : "ICE seminar: ";
    // Counter
    int i = 0;
    // Objects/variables
    CmsObject cmso = cms.getCmsObject();
    EventEntry event = null;
    String html = "";
    
    // Create the markup
    html += "<" + HEADING_LIST + ">" + heading + "</" + HEADING_LIST + ">";
    if (!events.isEmpty()) {
        Iterator itr = events.iterator();
        html += "<table class=\"events odd-even-table\">";
        i = 2;
        while (itr.hasNext()) {
            html += "<tr class=\"" + (i++ % 2 == 0 ? "even" : "odd") +"\">";
            event = (EventEntry)itr.next();
            boolean pastEvent = false;
            if (fadePastEvents) {
                if (event.hasEndTime()) {
                    pastEvent = !event.endsAfter(new Date()); // Event is over if it ends before "now"
                } else { // No end time, only start time
                    pastEvent = event.startsBefore(new Date()); // Event is over if it starts before "now"
                }
            }
            String title = event.getTitle();
            //if (title.startsWith(SEMINAR_PREFIX))
            //    title = title.substring(SEMINAR_PREFIX.length() - 1);
            html += "<td class=\"event-time\">" + df.format(new Date(event.getStartTime())) + "</td>";
            html += "<td><" + HEADING_EVENT + ">" + 
                            "<a href=\"" + cms.link(cmso.getSitePath(cmso.readResource(event.getStructureId()))) + "\"" +
                                (pastEvent ? " class=\"event-pastevent\"" : "") + ">" + title + "</a>" +
                            "</" + HEADING_EVENT + ">" +
                            "<p>" + event.getDescription() + "</p>" +
                        "</td></tr>";
        }
        html += "</table>";

    } else {
        html += "<em>" + LABEL_NONE + "</em>";
        if (nextDateIfNone != null) {
            html += "<em>, next is " + df.format(nextDateIfNone) +
                    "</em>";
        }
    }
    
    return html;
}
%><%
CmsAgent cms                            = new CmsAgent(pageContext, request, response);
CmsObject cmso                          = cms.getCmsObject();
Locale locale                           = cms.getRequestContext().getLocale();
String requestFileUri                   = cms.getRequestContext().getUri();
String requestFolderUri                 = cms.getRequestContext().getFolderUri();

final boolean DEBUG = request.getParameter("debug") == null ? false : true;

// The title for the category used to label ICE seminars
final String CATEGORY_TITLE_ICE_SEMINAR = locale.toString().equalsIgnoreCase("no") ? "NP-seminar" : "NPI seminar";
final String EVENTS_FOLDER              = cms.getRequestContext().getFolderUri();//locale.toString().equalsIgnoreCase("no") ? "/no/hendelser/" : "/en/events/";

// Labels
final String LABEL_TODAY    = locale.toString().equalsIgnoreCase("no") ? "I dag" : "Today";
final String LABEL_UPCOMING = locale.toString().equalsIgnoreCase("no") ? "Neste" : "Next";
final String LABEL_PAST     = locale.toString().equalsIgnoreCase("no") ? "Tidligere" : "Past";

SimpleDateFormat df = new SimpleDateFormat(cms.label("label.event.dateformat.dateonly_short"), locale);
SimpleDateFormat dfTimeOnly = new SimpleDateFormat(cms.label("label.event.dateformat.timeonly"), locale);


// Get the category service provider
CmsCategoryService catService = CmsCategoryService.getInstance();
List categories = catService.readCategories(cmso, null, true, EVENTS_FOLDER);
List paramCategories = new ArrayList();

// Loop over the categories, and remove all that are not "ICE seminar"
Iterator allCatItr = categories.iterator();
//CmsCategory categorySeminar = null;
while (allCatItr.hasNext()) {
    CmsCategory category = (CmsCategory)allCatItr.next();
    if (DEBUG) { out.println("<!-- Evaluating category '" + category.getTitle() + "' ... -->"); };
    if (category.getTitle().equalsIgnoreCase(CATEGORY_TITLE_ICE_SEMINAR)) {
        // add category path
        paramCategories.add(category.getRootPath());
        if (DEBUG) { out.println("<!-- Category '" + category.getTitle() + "' added as filter. -->"); };
    } else {
        // Remove category
        //allCatItr.remove();
        //out.println("- Removed '" + category.getTitle() + "', (no match with '" + CATEGORY_TITLE_ICE_SEMINAR + "')<br />");
    }
}
/*
out.println("<h3>Category filter:</h3>");
Iterator catItr = paramCategories.iterator();
if (catItr.hasNext()) {
    while (catItr.hasNext()) {
        String cat = (String)catItr.next();
        out.println(cat + "<br />");
    }
} else {
    out.println("None");
}
*/

// Create the calendar instance
EventCalendar calendar = new EventCalendar(TimeZone.getDefault());
Calendar timeCal = new GregorianCalendar(TimeZone.getDefault());
// Get a long value for "start of today"
timeCal.set(Calendar.HOUR_OF_DAY, timeCal.getMinimum(Calendar.HOUR_OF_DAY));
timeCal.set(Calendar.MINUTE, timeCal.getMinimum(Calendar.MINUTE));
timeCal.set(Calendar.SECOND, timeCal.getMinimum(Calendar.SECOND));
long todayStartMillis = timeCal.getTimeInMillis();
// Get the long value for "end of today"
timeCal.set(Calendar.HOUR_OF_DAY, timeCal.getMaximum(Calendar.HOUR_OF_DAY));
timeCal.set(Calendar.MINUTE, timeCal.getMaximum(Calendar.MINUTE));
timeCal.set(Calendar.SECOND, timeCal.getMaximum(Calendar.SECOND));
long todayEndMillis = timeCal.getTimeInMillis();
// Get the long value for "n months ago"
timeCal.set(Calendar.MONTH, timeCal.get(Calendar.MONTH) - 3);
long pastStartMillis = timeCal.getTimeInMillis();


// Get today's events that are labelled "ICE seminar"
List seminarsToday = calendar.getEvents(EventCalendar.RANGE_CURRENT_DATE, cms, EVENTS_FOLDER, null, null, paramCategories, false, false, -1);

// Get the next two events that are labelled "ICE seminar"
List seminarsNext = calendar.getEvents(todayEndMillis, Long.MAX_VALUE, cms, EVENTS_FOLDER, null, null, paramCategories, true, false, 5);
Collections.sort(seminarsNext, EventEntry.COMPARATOR_START_TIME);

//SimpleDateFormat dfFull = new SimpleDateFormat("dd. MM. yyyy HH:mm:ss", locale);
//out.println("<h4>" + dfFull.format(new Date(todayStartMillis)) + "</h4>");
//out.println("<h4>" + dfFull.format(new Date(todayEndMillis)) + "</h4>");

// We now need to modify the seminarsNext list.
// This list should only contain the n events that take place on the "next" day.
// E.g. we don't want multiple days in this list.
// So: remove all events that take place after the first encountered event
Iterator itr = seminarsNext.iterator();
// Calendar for the date of the first encountered event
Calendar firstEventDay = new GregorianCalendar(); 
// Calendar to use to check against the firstDayEvent calendar
Calendar eventDay = new GregorianCalendar();
// Counter, also used as a marker when shrinking the list
int i = 0;
while (itr.hasNext()) {
    EventEntry event = (EventEntry)itr.next();
    if (DEBUG) { out.println("<h5>Iteration #" + (i+1) + ", event is <em>" + event.getTitle() + "</em>, i=" + i + "</h5>"); }
    //out.println("<br/>Examining <em>" + event.getTitle() + "</em>...");
    if (i == 0) {
        firstEventDay.setTimeInMillis(event.getStartTime());
    }
    // Save the event's time to a variable
    eventDay.setTimeInMillis(event.getStartTime());
    
    // If (this event takes place on another date than the first event's date) 
    if (eventDay.get(Calendar.DATE) != firstEventDay.get(Calendar.DATE) || 
            eventDay.get(Calendar.MONTH) != firstEventDay.get(Calendar.MONTH) || 
            eventDay.get(Calendar.YEAR) != firstEventDay.get(Calendar.YEAR)) {
        // The current event takes place on another day than the day of the first event
        // (It is also important to use break, since i must not be incremented)
        if (i == 1) {
            if (DEBUG) { out.println("<h5>Hit CONTINUE on <em>" + event.getTitle() + "</em>, i=" + i + "</h5>"); }
            i++;
            continue; // If there is only one event in the list at this point, allow continue 
        }
        else {
            if (DEBUG) { out.println("<h5>Hit BREAK on <em>" + event.getTitle() + "</em>, i=" + i + "</h5>"); }
            break; // Else, break
        }
        // The above if-else means:
        // If there are 1+n events on the same date, include all (max 1+n events total)
        // If there is only one event on the "next" date, allow one more date to be examined (max 2 events total)
        // Since there usually is only one seminar on any given date, the list will normally contain the next 2 events
    }
    i++;
    
}
//out.println("<h4>There are " + i + " events on the next relevant date (of " + seminarsNext.size() + " events total).</h4>");
try {
    // Shrink the list: use the counter as a marker for the breaking point
    //seminarsNext.retainAll(seminarsNext.subList(0, i));
    seminarsNext = seminarsNext.subList(0, i);
} catch (Exception nullException) { // Happened, don't know why
    // Keep seminarsNext as is
    //out.println("<h4>Something crashed when trimming the list</h4>");
}

// Get past events that are labelled "ICE seminar", limit to the last month
List seminarsPast = calendar.getEvents(pastStartMillis, todayStartMillis, cms, EVENTS_FOLDER, null, null, paramCategories, false, true, -1);

// Print the three overviews (today, upcoming, past)
if (!seminarsToday.isEmpty()) 
    out.println(getEventsOverview(cms, LABEL_TODAY, seminarsToday, dfTimeOnly, (firstEventDay == null ? null : new Date(firstEventDay.getTimeInMillis())), false));
out.println(getEventsOverview(cms, LABEL_UPCOMING, seminarsNext, df, null, false));
//out.println(getEventsOverview(cms, LABEL_PAST, seminarsPast, df, null, false));

out.println(cms.getContent(requestFolderUri+"seminars-bottom.html", "body", locale));
/*out.println("<p style=\"padding-top:1em; font-style:italic;\">Looking for a specific seminar not in these lists? View <a href=\"/en/events/index.html?m=-1&amp;y=-1&amp;cat=/sites/ice/en/events/_categories/event-type/ice-seminar/\">" + 
                "all ICE seminars</a> on the event calendar." + 
            "</p>");*/
%>