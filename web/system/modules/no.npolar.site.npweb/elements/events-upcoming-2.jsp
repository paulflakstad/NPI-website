<%-- 
    Document   : events-upcoming (based loosely on polar-bokkafe-list)
    Created on : Mar 27, 2014, 12:53:17 PM
    Author     : Paul-Inge Flakstad, Norwegian Polar Institute
--%><%@ page import="java.util.*,
                 java.text.SimpleDateFormat,
                 no.npolar.common.eventcalendar.*,
                 no.npolar.util.*,
                 org.opencms.file.CmsResource,
                 org.opencms.file.CmsObject,
                 org.opencms.jsp.CmsJspActionElement,
                 org.opencms.main.CmsException,
                 org.opencms.xml.A_CmsXmlDocument,
                 org.opencms.xml.content.*"  session="true" 
%><%!
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
     * Gets the event's time span, as ready-to-use HTML.
     * @return 
     */
    public String getTimespanHtml(CmsJspActionElement cms, EventEntry event) throws CmsException {
        Locale locale = cms.getRequestContext().getLocale();
		String loc = locale.toString();
        /*SimpleDateFormat datetime = new SimpleDateFormat(cms.label("label.event.dateformat.datetime"), locale);
        SimpleDateFormat dateonly = new SimpleDateFormat(cms.label("label.event.dateformat.dateonly"), locale);
        SimpleDateFormat timeonly = new SimpleDateFormat(cms.label("label.event.dateformat.timeonly"), locale);
        SimpleDateFormat month = new SimpleDateFormat(cms.label("label.event.dateformat.month"), locale);*/
        SimpleDateFormat full = new SimpleDateFormat(loc.equalsIgnoreCase("no") ? "d. MMM yyyy H:mm" : "d MMM yyyy H:mm", locale);
        SimpleDateFormat datenotime = new SimpleDateFormat(loc.equalsIgnoreCase("no") ? "d. MMM yyyy" : "d MMM yyyy", locale);
        SimpleDateFormat dateonly = new SimpleDateFormat(loc.equalsIgnoreCase("no") ? "d." : "d", locale);
        SimpleDateFormat timeonly = new SimpleDateFormat("H:mm", locale);
        SimpleDateFormat dfIso = event.getDatetimeAttributeFormat(locale);
        
        // Select initial date format
        SimpleDateFormat df = event.isDisplayDateOnly() ? datenotime : full;
        
        String begins = null;
        String ends = null;
        String beginsIso = null;
        String endsIso = null;
        try {
            SimpleDateFormat beginFormat = df;
            beginsIso = dfIso.format(new Date(event.getStartTime()));
            // If there is an end-time
            if (event.hasEndTime()) {
                SimpleDateFormat endFormat = df;
                if (event.isOneDayEvent()) {
                    if (!event.isDisplayDateOnly()) {
                        // End time is on the same day as begin time, format only the hour/minute
                        endFormat = timeonly;
                    } 
                    else {
                        // Shouldn't happen
                        endFormat = new SimpleDateFormat("");
                    }
                } 
                else {
                    // Not one-day event, but maybe same month?
                    if (isOneMonthEvent(event) && event.isDisplayDateOnly()) {
                        endFormat = datenotime;
                        beginFormat = dateonly;
                    }
                }
                ends = endFormat.format(new Date(event.getEndTime())).replaceAll("\\s", "&nbsp;");
                endsIso = dfIso.format(new Date(event.getEndTime()));
            }
            begins = beginFormat.format(new Date(event.getStartTime())).replaceAll("\\s", "&nbsp;");
        } catch (NumberFormatException nfe) {
            // Keep ends=null
        }
        
        String s = "";
        
        s += "<time itemprop=\"startDate\" datetime=\"" + beginsIso + "\">" + begins + "</time>";
        if (ends != null)
            s += " &ndash; <time itemprop=\"endDate\" datetime=\"" + endsIso + "\">" + ends + "</time>";
        
        return s;
    }
%><%
CmsAgent cms                = new CmsAgent(pageContext, request, response);
CmsObject cmso              = cms.getCmsObject();
Locale locale               = cms.getRequestContext().getLocale();
//String requestFileUri                   = cms.getRequestContext().getUri();
//String requestFolderUri                 = cms.getRequestContext().getFolderUri();
EventCalendar calendar      = new EventCalendar(TimeZone.getDefault());

//final boolean DEBUG = false;

// The title for the category used to label "Polar book cafe" events
//final String CATEGORY_PATH_BOOK_CAFE    = "event/book-cafe/";
//final String CATEGORY_TITLE_BOOK_CAFE   = locale.toString().equalsIgnoreCase("no") ? "Polar bokkafe" : "Polar book cafe";
final String EVENTS_FOLDER  = locale.toString().equalsIgnoreCase("no") ? "/no/hendelser/" : "/en/events/";
final String MORE_LINK_TEXT = locale.toString().equalsIgnoreCase("no") ? "Flere aktiviteter" : "More events";
//final String HEADING        = locale.toString().equalsIgnoreCase("no") ? "Aktiviteter" : "Events";
final String NO_EVENTS		= locale.toString().equalsIgnoreCase("no") ? "Kalenderen er tom fremover!" : "No upcoming events in the calendar!";

final String DF_FULL = "d. MMM YYYY hh:mm";
SimpleDateFormat datetime = new SimpleDateFormat(cms.label("label.event.dateformat.datetime"), locale);
SimpleDateFormat dateonly = new SimpleDateFormat(cms.label("label.event.dateformat.dateonly"), locale);
SimpleDateFormat timeonly = new SimpleDateFormat(cms.label("label.event.dateformat.timeonly"), locale);
//SimpleDateFormat dfIso = getDatetimeAttributeFormat(locale);


List events = calendar.getEvents(EventCalendar.RANGE_UPCOMING_AND_IN_PROGRESS, cms, EVENTS_FOLDER, null, null, null, false, false, 4);
Iterator iEvents = events.iterator();
if (iEvents.hasNext()) {
    %>
    <!--<ul style="display:block; margin:0; padding:0; list-style:none;">-->
	<div class="boxes clearfix">
    <%
    while (iEvents.hasNext()) {
        EventEntry event = (EventEntry)iEvents.next();
        Date startDate = new Date(event.getStartTime());
        SimpleDateFormat startDateFormat = datetime;
        
        if (event.hasEndTime() && event.isDisplayDateOnly()) {
            // Format start date (i.e. either "18 Dec 2014", "18 Dec" or just "18") depending on end date
            Date endDate = new Date(event.getEndTime());
            
        }
        %>
        <div class="span1 featured-box" itemscope="" itemtype="http://schema.org/Event">
            <a class="featured-link" href="<%= cms.link(event.getUri(cmso)) %>">
                <div class="card">
                    <!--<div class="autonomous">-->
                        <h3 class="card-heading" itemprop="name"><%= event.getTitle() %></h3>
                        <div class="timestamp"><i class="icon-calendar"></i><%= getTimespanHtml(cms, event) %></div>
                        <p itemprop="description"><%= event.getDescription() %></p>
                    <!--</div>-->
                </div>
            </a>
        </div>
        <%
    }
    %>
    <!--</ul>-->
    <a class="cta more news-list-more" href="<%= EVENTS_FOLDER %>"><%= MORE_LINK_TEXT %></a>
	</div>
    <%

} else {
    %>
    <!--<p>No upcoming events.</p>-->
    <%
}
%>