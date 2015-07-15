<%-- 
    Document   : icalendar
    Created on : Feb 5, 2013, 5:36:32 PM
    Author     : flakstad
--%><%@page import="org.opencms.util.CmsHtmlExtractor"%>
<%@page import="java.util.GregorianCalendar"%>
<%@page import="java.util.TimeZone,
		 no.npolar.util.*,
                 no.npolar.common.eventcalendar.*,
                 java.nio.charset.Charset,
                 java.util.Calendar,
                 java.util.Arrays,
                 java.util.ArrayList,
                 java.util.Locale,
                 java.util.Date,
                 java.util.HashMap,
                 java.util.Map,
                 java.util.Set,
                 java.util.List,
                 java.util.Iterator,
                 java.text.SimpleDateFormat,
                 org.opencms.jsp.*,
                 org.opencms.loader.CmsImageScaler,
                 org.opencms.file.*,
                 org.opencms.file.collectors.*,
                 org.opencms.file.types.*,
                 org.opencms.relations.*,
                 org.opencms.xml.content.*,
                 org.opencms.main.*" buffer="none" contentType="text/calendar; charset=UTF-8" pageEncoding="UTF-8"
%><%!
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

%><%

CmsAgent cms                        = new CmsAgent(pageContext, request, response);
CmsObject cmso                      = cms.getCmsObject();
String requestFileUri               = request.getParameter("event");

if (requestFileUri == null) 
    throw new IllegalArgumentException("Unable to create calendar entry: The event ID is missing.");
if (!cmso.existsResource(requestFileUri, CmsResourceFilter.DEFAULT_FILES.addRequireType(OpenCms.getResourceManager().getResourceType("np_event").getTypeId())))
    throw new IllegalArgumentException("Unable to create calendar entry: There is no event with the given ID '" + requestFileUri + "'.");

Locale locale                       = new Locale(cmso.readPropertyObject(requestFileUri, "locale", true).getValue("en"));
String loc                          = locale.toString();
CmsResource reqFile                 = cmso.readResource(requestFileUri);

SimpleDateFormat datetime           = new SimpleDateFormat(cms.label("label.event.dateformat.datetime"), locale);
SimpleDateFormat dateonly           = new SimpleDateFormat(cms.label("label.event.dateformat.dateonly"), locale);

String venueName                    = null;
I_CmsXmlContentContainer container, venue;     // XML content containers

container = cms.contentload("singleFile", requestFileUri, locale, false);
while (container.hasMoreContent()) {
    String timeDisplay = cms.contentshow(container, "TimeDisplay");
    boolean isDateOnlyEvent = !timeDisplay.equals("datetime");
    SimpleDateFormat df = isDateOnlyEvent ? dateonly : datetime;
    
    SimpleDateFormat dfIso = getDatetimeAttributeFormat(cmso, cmso.readResource(requestFileUri));
    
    // Get the long values of the begin/end timestamps
    long longBegin = Long.valueOf(cms.contentshow(container, "Begin")).longValue();
    long longEnd = 0;
    try {
        longEnd = Long.valueOf(cms.contentshow(container, "End")).longValue();
    } catch (Exception e) {
        longEnd = 0;
    }
    
    // For convenience, we'll use an EventEntry object
    EventEntry event = new EventEntry(longBegin,
                                      longEnd,
                                      cms.contentshow(container, "Title"),
                                      cms.contentshow(container, "Description"),
                                      reqFile.getResourceId(),
                                      reqFile.getStructureId(),
                                      locale);
    // Format the begin/end time
    String beginsIso = null;
    String endsIso = null;
    
    try {
        beginsIso = dfIso.format(new Date(longBegin));
        // If there is an end-time
        if (longEnd > 0) {
            Date endDate = new Date(longEnd);
            if (isDateOnlyEvent) {
                // This event is "date only", and it has an end date ==> The event 
                // should span the entire end date, so set the end time to the day 
                // thereafter (by adding one day to the end time)
                long msInOneDay = 1000*60*60*24;
                endDate.setTime(endDate.getTime() + msInOneDay);
            }
            endsIso = dfIso.format(endDate);
        }
    } catch (NumberFormatException nfe) {
        // Keep ends=null
    }
    
    String ics = "";
    
    // Start it
    ics += "BEGIN:VCALENDAR" + "\n";
    ics += "METHOD:PUBLISH" + "\n";
    ics += "VERSION:2.0" + "\n";
    ics += "PRODID:-//Norwegian Polar Institute//Event calendar 1.0//EN" + "\n";
    ics += "BEGIN:VEVENT" + "\n";
    // The unique ID: use the event resource's structure ID in OpenCms
    ics += "UID:" + reqFile.getStructureId() + "\n";
    // Mandatory title ("summary")
    ics += "SUMMARY:" + event.getTitle() + "\n";
    // Optional description
    ics += "DESCRIPTION:" + event.getDescription() + "\n";
    // Mandatory start time
    ics += "DTSTART:" + beginsIso + "\n";
    // Optional end time
    if (endsIso != null)
        ics +="DTEND:" + endsIso + "\n";
    
    // Optional venue
    venue = cms.contentloop(container, "Venue");
    while (venue.hasMoreContent()) {
        venueName = cms.contentshow(venue, "Name");
        if (CmsAgent.elementExists(venueName)) {
            String venueAddress = cms.contentshow(venue, "Address");
            if (CmsAgent.elementExists(venueAddress))
                venueName += ", " + CmsHtmlExtractor.extractText(venueAddress, "UTF-8").replaceAll("\\n", ", ").replaceAll(",,", ","); // Get the address, remove all markup and line breaks
            ics += "LOCATION:" + venueName + "\n";
        }
    }
    // End it
    ics += "END:VEVENT" + "\n";
    ics += "END:VCALENDAR";
    
    // Generate the file name
    String fname = event.getTitle().toLowerCase().replaceAll(" ", "-").replaceAll(";", "").replaceAll(",", "").replaceAll(":", "") + ".ics";
    
    // Get the iCalendar's bytes
    byte[] rawContent = ics.getBytes(Charset.forName("UTF-8"));
    // Set appropriate headers
    cms.setContentType("text/calendar;charset=UTF-8"); // REALLY important!
    cms.getResponse().setContentLength(rawContent.length);
    cms.getResponse().setHeader("Content-Disposition", "attachment; filename=\"" + fname + "\"");
    // Write the response
    cms.getResponse().getOutputStream().write(rawContent, 0, rawContent.length);
    cms.getResponse().getOutputStream().flush();
} %>