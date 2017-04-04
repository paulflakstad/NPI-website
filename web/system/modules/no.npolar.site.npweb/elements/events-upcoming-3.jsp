<%-- 
    Document   : events-upcoming-3
    Created on : Nov 17, 2015, 12:40:19 PM
    Author     : Paul-Inge Flakstad, Norwegian Polar Institute <flakstad at npolar.no>
    Comment    : This file Really should be renamed "events-upcoming-isblink"
--%><%-- 
    Document   : events-upcoming (based loosely on polar-bokkafe-list)
    Created on : Mar 27, 2014, 12:53:17 PM
    Author     : Paul-Inge Flakstad, Norwegian Polar Institute
--%><%@ page import="java.util.*,
                 java.text.SimpleDateFormat,
                 no.npolar.common.eventcalendar.*,
                 no.npolar.util.*,
                 org.opencms.file.CmsResource,
                 org.opencms.file.CmsResourceFilter,
                 org.opencms.file.CmsObject,
                 org.opencms.jsp.CmsJspActionElement,
                 org.opencms.loader.CmsResourceManager,
                 org.opencms.main.CmsException,
                 org.opencms.main.OpenCms,
                 org.opencms.xml.A_CmsXmlDocument,
                 org.opencms.xml.content.*"  session="true" 
%><%!
    /**
     * Determines if the given event begins and ends in the exact same month.
     */
    public boolean isOneMonthEvent(EventEntry event) {
        if (!event.hasEndTime())
            return true;
        
        Calendar cStart = new GregorianCalendar();
        Calendar cEnd = new GregorianCalendar();
        cStart.setTime(new Date(event.getStartTime()));
        cEnd.setTime(new Date(event.getEndTime()));
        
        return cStart.get(Calendar.YEAR) == cEnd.get(Calendar.YEAR) && cStart.get(Calendar.MONTH) == cEnd.get(Calendar.MONTH);
    }
    
    /**
     * Determines if the given event begins (and ends) in the current year.
     */
    public boolean isCurrentYearEvent(EventEntry event) {
        Calendar cStart = new GregorianCalendar();
        cStart.setTime(new Date(event.getStartTime()));
        Calendar cEnd = new GregorianCalendar();
        Calendar now = new GregorianCalendar();
        
        if (cStart.get(Calendar.YEAR) == now.get(Calendar.YEAR)) {
            if (event.hasEndTime()) {
                cEnd.setTime(new Date(event.getEndTime()));
                return cEnd.get(Calendar.YEAR) == now.get(Calendar.YEAR);
            }
            return true;
        }
        
        return false;
    }
    
    /**
     * Gets the event's time span, as ready-to-use HTML.
     * !!! NOTE !!!
     * This is, as of 2016-03-18, an improved version of the EventEntry class' 
     * native method.
     */
    public String getTimespanHtml(CmsJspActionElement cms, EventEntry event) throws CmsException {
        Locale locale = cms.getRequestContext().getLocale();
	String loc = locale.toString();
        /*SimpleDateFormat datetime = new SimpleDateFormat(cms.label("label.event.dateformat.datetime"), locale);
        SimpleDateFormat dateonly = new SimpleDateFormat(cms.label("label.event.dateformat.dateonly"), locale);
        SimpleDateFormat timeonly = new SimpleDateFormat(cms.label("label.event.dateformat.timeonly"), locale);
        SimpleDateFormat month = new SimpleDateFormat(cms.label("label.event.dateformat.month"), locale);*/
        SimpleDateFormat dmyt = new SimpleDateFormat(loc.equalsIgnoreCase("no") ? "d. MMMM yyyy H:mm" : "d MMMM yyyy H:mm", locale);
        SimpleDateFormat dmy = new SimpleDateFormat(loc.equalsIgnoreCase("no") ? "d. MMMM yyyy" : "d MMMM yyyy", locale);
        SimpleDateFormat dm = new SimpleDateFormat(loc.equalsIgnoreCase("no") ? "d. MMMM" : "d MMMM", locale);
        SimpleDateFormat dmt = new SimpleDateFormat(loc.equalsIgnoreCase("no") ? "d. MMMM H:mm" : "d MMMM H:m", locale);
        SimpleDateFormat d = new SimpleDateFormat(loc.equalsIgnoreCase("no") ? "d." : "d", locale);
        SimpleDateFormat t = new SimpleDateFormat("H:mm", locale);
        SimpleDateFormat iso = event.getDatetimeAttributeFormat(locale);
        
        boolean currentYearEvent = isCurrentYearEvent(event);
        
        // Select initial date format
        SimpleDateFormat df = event.isDisplayDateOnly() ? (currentYearEvent ? dm : dmy) : (currentYearEvent ? dmt : dmyt);
        
        String begins = null;
        String ends = null;
        String beginsIso = null;
        String endsIso = null;
        try {
            SimpleDateFormat beginFormat = df;
            beginsIso = iso.format(new Date(event.getStartTime()));
            // If there is an end-time
            if (event.hasEndTime()) {
                SimpleDateFormat endFormat = df;
                if (event.isOneDayEvent()) {
                    if (!event.isDisplayDateOnly()) {
                        // End time is on the same day as begin time, format only the hour/minute
                        endFormat = t;
                    } 
                    else {
                        // Shouldn't happen
                        endFormat = new SimpleDateFormat("");
                    }
                } 
                else {
                    // Not one-day event, but maybe same month?
                    if (isOneMonthEvent(event) && event.isDisplayDateOnly()) {
                        endFormat = dmy;
                        beginFormat = d;
                    }
                }
                ends = endFormat.format(new Date(event.getEndTime())).replaceAll("\\s", "&nbsp;");
                endsIso = iso.format(new Date(event.getEndTime()));
            }
            begins = beginFormat.format(new Date(event.getStartTime())).replaceAll("\\s", "&nbsp;");
        } catch (NumberFormatException nfe) {
            // Keep ends=null
        }
        
        String s = "";
        
        s += "<time itemprop=\"startDate\" datetime=\"" + beginsIso + "\">" + begins + "</time>";
        
        if (ends != null) {
            // Sometimes we want to use a space, sometimes not...
            String spaceOrNot = begins.contains("nbsp") && ends.contains("nbsp") ? " " : "";
            s += spaceOrNot + "&ndash;" + spaceOrNot 
                    + "<time itemprop=\"endDate\" datetime=\"" + endsIso + "\">" + ends + "</time>";
        }
        
        return s;
    }
%><%
CmsAgent cms                = new CmsAgent(pageContext, request, response);
CmsObject cmso              = cms.getCmsObject();
Locale locale               = cms.getRequestContext().getLocale();
//String requestFileUri       = cms.getRequestContext().getUri();
//String requestFolderUri     = cms.getRequestContext().getFolderUri();
EventCalendar calendar      = new EventCalendar(TimeZone.getDefault());

//final boolean DEBUG = false;

// The title for the category used to label "Polar book cafe" events
//final String CATEGORY_PATH_BOOK_CAFE    = "event/book-cafe/";
//final String CATEGORY_TITLE_BOOK_CAFE   = locale.toString().equalsIgnoreCase("no") ? "Polar bokkafe" : "Polar book cafe";
final String EVENTS_FOLDER_INTRANET  = locale.toString().equalsIgnoreCase("no") ? "/no/hendelser/" : "/en/events/";
final String EVENTS_FOLDER_EXTRANET  = locale.toString().equalsIgnoreCase("no") ? "/no/hendelser/" : "/en/events/";
//final String HEADING        = locale.toString().equalsIgnoreCase("no") ? "Aktiviteter" : "Events";
final String MORE_LINK_TEXT = locale.toString().equalsIgnoreCase("no") ? "Flere aktiviteter" : "More events";
final String NO_EVENTS		= locale.toString().equalsIgnoreCase("no") ? "Kalenderen er tom fremover!" : "No upcoming events in the calendar!";

final String SITE_ROOT_INTRANET = "/sites/isblink";
final String SITE_ROOT_EXTRANET = "/sites/np";

//final String DF_FULL = "d. MMM YYYY hh:mm";
//SimpleDateFormat datetime = new SimpleDateFormat(cms.label("label.event.dateformat.datetime"), locale);
//SimpleDateFormat dateonly = new SimpleDateFormat(cms.label("label.event.dateformat.dateonly"), locale);
//SimpleDateFormat timeonly = new SimpleDateFormat(cms.label("label.event.dateformat.timeonly"), locale);
//SimpleDateFormat dfIso = getDatetimeAttributeFormat(locale);


// The list should contain no more than this
final int EVENT_ENTRIES_MAX = 4;

// Step 1: fetch all regular events
List<EventEntry> events = calendar.getEvents(EventCalendar.RANGE_UPCOMING_AND_IN_PROGRESS, cms, EVENTS_FOLDER_INTRANET, null, null, null, false, false, EVENT_ENTRIES_MAX);

// Step 2: Mix in events from the public site
try {
    // Switch to public site
    cms.getRequestContext().setSiteRoot(SITE_ROOT_EXTRANET);
    // Inject events and sort the resulting list
    events.addAll(calendar.getEvents(EventCalendar.RANGE_UPCOMING_AND_IN_PROGRESS, cms, EVENTS_FOLDER_EXTRANET, null, null, null, false, false, EVENT_ENTRIES_MAX));
    Collections.sort(events, no.npolar.common.eventcalendar.EventEntry.COMPARATOR_START_TIME);
    // Switch back to intranet site
    cms.getRequestContext().setSiteRoot(SITE_ROOT_INTRANET);
} catch (Exception e) {
    out.println("\n\n<!-- Unable to read events from the public site -->\n\n");
}

// Step 3: fetch all promoted events
List<EventEntry> promotedEvents = new ArrayList<EventEntry>(0);
try {
    List<CmsResource> featuredResources = cmso.readResourcesWithProperty(
            EVENTS_FOLDER_INTRANET
            , "featured"
            , "true"
            , CmsResourceFilter.DEFAULT_FILES.addRequireType(OpenCms.getResourceManager().getResourceType(EventEntry.RESOURCE_TYPE_NAME_EVENT).getTypeId())
    );
    for (CmsResource r : featuredResources) {
        EventEntry e = new EventEntry(cmso, r);
        if (!e.isExpired(new Date())) {
            promotedEvents.add(e);
        }
    }
    
    // Step 4: Remove duplicates
    if (!promotedEvents.isEmpty()) {
        Collections.sort(promotedEvents, EventEntry.COMPARATOR_START_TIME);
        events.removeAll(promotedEvents); // avoid duplicates
        events.addAll(0, promotedEvents);
        
        // Step 5: Trim the events list
        if (events.size() > EVENT_ENTRIES_MAX) {
            events = events.subList(0, EVENT_ENTRIES_MAX);
        }
    }
} catch (Exception e) {
    // ignore
}

Iterator iEvents = events.iterator();
if (iEvents.hasNext()) {
    %>
    <!--<ul style="display:block; margin:0; padding:0; list-style:none;">-->
    <ul>
	<!--<div class="boxes clearfix">-->
    <%
    int i = 0;
    while (iEvents.hasNext()) {
        EventEntry event = (EventEntry)iEvents.next();
        //Date startDate = new Date(event.getStartTime());
        //SimpleDateFormat startDateFormat = datetime;
        boolean promotedEvent = ++i <= promotedEvents.size();
        
        //if (event.hasEndTime() && event.isDisplayDateOnly()) {
        //    Format start date (i.e. either "18 Dec 2014", "18 Dec" or just "18") depending on end date
        //    Date endDate = new Date(event.getEndTime());  
        //}
        %>
        <li class="event<%= promotedEvent ? " event--promoted" : "" %>" itemscope="" itemtype="http://schema.org/Event">
            <a href="<%= cms.link(event.getUri(cmso)) %>">
                <!--<div class="card">-->
                    <!--<div class="autonomous">-->
                        <strong class="event_title" itemprop="name"><%= event.getTitle() %></strong>
                        <!--<p itemprop="description"><%= event.getDescription() %></p>-->
                    <!--</div>-->
                <!--</div>-->
            </a>
            <div class="timestamp smalltext"><%= getTimespanHtml(cms, event) %></div>
        </li>
        <%
    }
    %>
    </ul>
    <!--<a class="cta more news-list-more" href="<%= EVENTS_FOLDER_INTRANET %>"><%= MORE_LINK_TEXT %></a>-->
	<!--</div>-->
    <%

} else {
    %>
    <p><em><%= NO_EVENTS %></em></p>
    <%
}
%>