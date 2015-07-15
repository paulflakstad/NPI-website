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
                 org.opencms.main.CmsException,
                 org.opencms.xml.A_CmsXmlDocument,
                 org.opencms.xml.content.*"  session="true" 
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
final String MORE_LINK_URI  = locale.toString().equalsIgnoreCase("no") ? "/no/aktuelt/" : "/en/activities/";
final String MORE_LINK_TEXT = locale.toString().equalsIgnoreCase("no") ? "Flere aktiviteter" : "More events";
final String HEADING        = locale.toString().equalsIgnoreCase("no") ? "Aktiviteter" : "Events";


List events = calendar.getEvents(EventCalendar.RANGE_UPCOMING_AND_IN_PROGRESS, cms, EVENTS_FOLDER, null, null, null, false, false, 4);
Iterator iEvents = events.iterator();
if (iEvents.hasNext()) {
    %>
    <h2><%= HEADING %></h2>
    <ul class="news-list" itemscope itemtype="http://schema.org/Event">
    <%
    while (iEvents.hasNext()) {
        EventEntry event = (EventEntry)iEvents.next();
        %>
        <li class="news">
            <div class="news-list-itemtext">
                <div class="timestamp"><%= event.getTimespanHtml(cms) %></div>
                <h3 itemprop="name"><a href="<%= cms.link(event.getUri(cmso)) %>"><%= event.getTitle() %></a></h3>
                <p itemprop="description"><%= event.getDescription() %></p>
            </div>
        </li>
        <%
    }
    %>
    </ul>
    <a class="cta more news-list-more" href="<%= cms.link(MORE_LINK_URI) %>"><%= MORE_LINK_TEXT %></a>
    <%
} else {
    %>
    <!--<p>No upcoming events.</p>-->
    <%
}
%>