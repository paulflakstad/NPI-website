<%-- 
    Document   : event
    Created on : 18.mar.2011, 18:49:12
    Author     : Paul-Inge Flakstad <flakstad at npolar.no>
--%><%@page import="com.google.ical.values.DateTimeValueImpl"%>
<%@page import="org.opencms.workplace.CmsWorkplaceManager"%>
<%@page import="org.opencms.workplace.CmsWorkplaceSettings"%>
<%@page import="com.google.ical.values.DateValue"%>
<%@page import="com.google.ical.values.DateValueImpl"%>
<%@page import="java.util.GregorianCalendar"%>
<%@page import="com.google.ical.iter.RecurrenceIteratorFactory"%>
<%@page import="com.google.ical.iter.RecurrenceIterator"%>
<%@page import="java.util.TimeZone"%>
<%@ page import="no.npolar.util.*,
                 no.npolar.common.eventcalendar.*,
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
                 org.opencms.main.*,
                 org.opencms.util.CmsUUID" session="true"
%><%!

public DateValue toDateValue(Date d) {
    Calendar helperCal = new GregorianCalendar(TimeZone.getTimeZone("GMT+1:00"), new Locale("no"));
    helperCal.setTime(d);
    return new DateValueImpl(helperCal.get(Calendar.YEAR), helperCal.get(Calendar.MONTH)+1, helperCal.get(Calendar.DATE));
}
public Date toDate(DateValue dv) {
    Calendar helperCal = new GregorianCalendar(TimeZone.getTimeZone("GMT+1:00"), new Locale("no"));
    helperCal.set(dv.year(), dv.month()-1, dv.day(), 12, 0, 0);
    return helperCal.getTime();
}
public boolean isSameDate(DateValue dv, Date d) {
    return new SimpleDateFormat("yyyyMMdd").format(d).equals(dv.toString());
}
public String getRecurrenceRule(CmsObject cmso, EventEntry event) {
    String rule = null;
    try {
        rule = cmso.readPropertyObject(cmso.readResource(event.getStructureId()), "rrule", false).getValue(null);
        return "RRULE:".concat(rule);
    } catch (Exception e) {
        //
    }
    return rule;
}
    
    /**
     * Gets a Calendar that represents the END of the day defined by the 
     * given date.
     */
    public Calendar getDateEndCal(Date d) {
        Calendar dateEndCal = new GregorianCalendar();
        dateEndCal.setTime(d);
        dateEndCal.set(Calendar.HOUR_OF_DAY, 23);
        dateEndCal.set(Calendar.MINUTE, 59);
        dateEndCal.set(Calendar.SECOND, 59);
        return dateEndCal;
    }
    
    public Date getClosestPastStartDate(DateValue marker, CmsAgent cms, EventEntry event) {
        try {
            RecurrenceIterator iRecur = getRecurrenceIterator(cms, event);
            if (iRecur == null)
                return new Date(event.getStartTime()); // Not a recurring event, return initial start time
            
            Date markerDate = toDate(marker); // The marker date
            Date endMarkerDate = new Date(getDateEndCal(markerDate).getTimeInMillis()); // Timestamp: The end of the marker date
            Date closest = null;
            
            // Safety 
            int iterations = 0;
            int maxIterations = 1000;
            
            // Loop recurrences
            while (iRecur.hasNext() && iterations++ < maxIterations) {
                Date recStartDate = toDate((DateValue)iRecur.next());
                if (recStartDate.after(endMarkerDate)) // Is the recurrence start date after the marker date?
                    break; // Yes: break
                /*if (event.hasEndTime() && !event.isOneDayEvent()) { // Is the recurrence a multiple-day event?
                    if (new Date(recStartDate.getTime() + (event.getEndTime() - event.getStartTime())).after(endMarkerDate)) // Is the recurrence end time after the 
                        break;
                }*/
                closest = recStartDate; // No - then so far it has the closest start date
            }
            
            if (closest == null)
                return new Date(event.getStartTime()); // Found nothing, return the event's initial start time

            return closest; // Found a date in the past, return it
            
        } catch(Exception e) {
            return new Date(event.getStartTime());
        }
    }
    public RecurrenceIterator getRecurrenceIterator(CmsAgent cms, EventEntry event) throws java.text.ParseException {
        // Get the recurrence rule
        String recRule = getRecurrenceRule(cms.getCmsObject(), event);
        if (recRule == null) {
            // Not recurring - return the initial start time
            return null;
        }
        // Get the initial begin timestamp
        Date initialStartTime = new Date(event.getStartTime());
        // Get the iterator for the recurrence dates, using the recurrence rule (RRULE) found on the event
        RecurrenceIterator iRecur = RecurrenceIteratorFactory.createRecurrenceIterator(recRule
                                                                                        , toDateValue(initialStartTime)
                                                                                        , TimeZone.getTimeZone("GMT+1:00")
                                                                                        );
        return iRecur;
    }
    /**
     * Gets an event's begin time, as a Date instance. If the event is non-
     * recurring, the regular begin time is returned. If the event is recurring,
     * the closest "next" begin time is returned. (Could be "today".)
     */
    public Date getBegin(CmsAgent cms, EventEntry event) {        
        // Get the initial begin timestamp
        Date initialStartTime = new Date(event.getStartTime());

        // This event is set to recur
        try {
            RecurrenceIterator iRecur = getRecurrenceIterator(cms, event);
            if (iRecur == null) {
                // Not recurring - return the initial start time
                return initialStartTime;
            }
                
            // Set up local time zone
            TimeZone tz = TimeZone.getTimeZone("GMT+1:00");
            // Get the current workplace time (possibly "warped", if time warp is active)
            Date currentTime = getNowDate(cms.getRequest().getSession());
            
            if (!event.isOneDayEvent() && event.hasEndTime()) {
                // Advance to the closest start date in the past (relative to current workplace time)
                iRecur.advanceTo(toDateValue(getClosestPastStartDate(toDateValue(currentTime), cms, event)));
            } else { // One-day event (or no end time specified)
                // Advance to the current workplace date
                iRecur.advanceTo(toDateValue(currentTime));
            }

            if (iRecur.hasNext()) {
                // Get the event's "next" recurring date (could be "today")
                DateValue dv = (DateValue)iRecur.next();
                Calendar cal = new GregorianCalendar(tz, cms.getRequestContext().getLocale());
                // First, set the time to the *initial* start time, so that any "event begin" clock time is preserved
                cal.setTime(initialStartTime);
                // Then update year, month and day
                cal.set(dv.year(), dv.month()-1, dv.day());
                // And return the Date instance representing the "next" beginning date
                return cal.getTime();
            }
        } catch (Exception e) {
            //out.println("<!-- Error processing recurring event: " + e.getMessage() + " -->");
        }
        return null;
    }
/*public Date getBegin(CmsAgent cms, EventEntry event) {
    // Get the recurrence rule
    String recRule = getRecurrenceRule(cms.getCmsObject(), event);
    // Get the initial begin timestamp
    Date initialStartTime = new Date(event.getStartTime());
    
    if (recRule == null) {
        // Not recurring - return the initial start time
        return initialStartTime;
    }
    
    // This event is set to recur
    try {
        // Set up local time zone
        TimeZone tz = TimeZone.getTimeZone("GMT+1:00");
        // Get the current workplace time (possibly "warped", if time warp is active)
        Date currentTime = getNowDate(cms.getRequest().getSession());
        
        // Get the iterator for the recurrence dates, using the recurrence rule (RRULE) found on the event
        RecurrenceIterator iRecur = RecurrenceIteratorFactory.createRecurrenceIterator(recRule
                                                                                        , toDateValue(initialStartTime)
                                                                                        , tz
                                                                                        );
        
        // Advance to the current workplace date
        iRecur.advanceTo(toDateValue(currentTime));
        
        if (iRecur.hasNext()) {
            // Get the event's "next" recurring date (could be "today")
            DateValue dv = (DateValue)iRecur.next();
            Calendar cal = new GregorianCalendar(tz, cms.getRequestContext().getLocale());
            // First, set the time to the *initial* start time, so that any "event begin" clock time is preserved
            cal.setTime(initialStartTime);
            // Then update year, month and day
            cal.set(dv.year(), dv.month()-1, dv.day());
            // And return the Date instance representing the "next" beginning date
            return cal.getTime();
        }
    } catch (Exception e) {
        //out.println("<!-- Error processing recurring event: " + e.getMessage() + " -->");
    }
    return null;
}*/

public Date getEnd(CmsAgent cms, EventEntry event, Date eventStart) {
    long longBeginOri = event.getStartTime();
    long longBegin = eventStart.getTime();
    
    if (longBeginOri < longBegin && getRecurrenceRule(cms.getCmsObject(), event) != null) {
        // Some adjustment has been made. Assume that's because this is a recurring event
        //  - adjust end time equally
        long diff = longBegin - longBeginOri;
        return new Date(event.getEndTime() + diff);
    }
    return new Date(event.getEndTime());
}

public Date getNowDate(HttpSession s) {
    Date now = new Date();
    try {
        // Try to set the current date to the warped time (if active), fallback to the "actual" now
        CmsWorkplaceSettings settings = (CmsWorkplaceSettings)s.getAttribute(CmsWorkplaceManager.SESSION_WORKPLACE_SETTINGS);
        long timewarp = settings.getUserSettings().getTimeWarp();
        if (timewarp > 1) {
            return new Date(timewarp);
        }
    } catch (Exception e) {
        
    }
    return now;
}

public String getParameterString(Map params) {
    if (params == null)
        return null;
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

%><%
CmsAgent cms                        = new CmsAgent(pageContext, request, response);
CmsObject cmso                      = cms.getCmsObject();
String requestFileUri               = cms.getRequestContext().getUri();
String requestFolderUri             = cms.getRequestContext().getFolderUri();
Locale locale                       = cms.getRequestContext().getLocale();
String loc                          = locale.toString();

/*########## HARD-CODED FOR NANSEN-AMUNDSEN - NO GOOD... ##################################*/
final String OVERVIEW_FILE          = "/no/events/index.html";
final String CATEGORIES_PATH        = "/no/events/";
final String UNDATED_FOLDER         = "/no_date/";

final String SHARE_LINKS            = "../../no.npolar.site.npweb/elements/share-addthis-" + loc + ".txt";
final String SHARE_LINK_MIN         = "../../no.npolar.site.npweb/elements/share-link-min-" + loc + ".txt";
final String LABEL_TO_OVERVIEW      = cms.label("label.for.np_event.tooverview");//"Til oversikten";
final String LINK_TO_OVERVIEW       = "<a href=\"" + cms.link(OVERVIEW_FILE) + "?" + getParameterString(request.getParameterMap()) + "\">" + 
                                            LABEL_TO_OVERVIEW + "</a>";

SimpleDateFormat datetime           = new SimpleDateFormat(cms.label("label.event.dateformat.datetime"), locale);
SimpleDateFormat dateonly           = new SimpleDateFormat(cms.label("label.event.dateformat.dateonly"), locale);
SimpleDateFormat timeonly           = new SimpleDateFormat(cms.label("label.event.dateformat.timeonly"), locale);
SimpleDateFormat dvFormat           = new SimpleDateFormat("yyyyMMdd");

//datetime                            = new SimpleDateFormat("dd. MMMM HH:mm", locale); // MOVE to workplace.properties
//dateonly                            = new SimpleDateFormat("dd. MMMM", locale); // MOVE to workplace.properties

final TimeZone LOCAL_TIME_ZONE      = TimeZone.getTimeZone("GMT+1:00");

final boolean EDITABLE              = true;
final boolean EDITABLE_TEMPLATE     = true;

final String LABEL_RECURRING_EVENT  = cms.label("label.for.np_event.recurringevent");
final String LABEL_NEXT_EVENT       = cms.label("label.for.np_event.nextevent");
final String LABEL_WHEN             = cms.label("label.for.np_event.when");
final String LABEL_WHERE            = cms.label("label.for.np_event.where");
final String LABEL_HOST             = cms.label("label.for.np_event.host");
final String LABEL_LINK             = cms.label("label.for.np_event.link");
final String LABEL_ATTACHMENT       = cms.label("label.for.np_event.attachment");
final String LABEL_CONTACT_PERSON   = cms.label("label.for.np_event.contactperson");
final String LABEL_PHONE            = cms.label("label.for.np_event.phone");
final String LABEL_TIME             = cms.label("label.for.np_event.time");
final String LABEL_DATE_NOT_DETERMINED  = cms.label("label.for.np_event.datenotset");//"Dato ikke fastsatt";
final String LABEL_VENUE            = cms.label("label.for.np_event.venue");
final String LABEL_ADDRESS          = cms.label("label.Contact.Address");

final String LABEL_ADD_TO_CALENDAR  = loc.equalsIgnoreCase("no") ? "Legg til i<br />min kalender" : "Add to my<br />calendar";
final String PATH_ICAL_EXPORT       = cms.link("/system/modules/no.npolar.common.event/elements/icalendar.jsp").concat("?event=" + requestFileUri);

final int IMG_LOGO_MAX_HEIGHT       = 120;

String imageTag                     = null;

String pdfUri                       = null;
String pdfTitle                     = null;
boolean pdfNewWindow                = false;

String venueName                    = null;
String venueAddress                 = null;
String venueWebsite                 = null;
String venueGoogleMap               = null;

I_CmsXmlContentContainer container, contactinfo, pdflink, venue;     // XML content containers

// Template:
String template                     = cms.getTemplate();
String[] elements                   = cms.getTemplateIncludeElements();

//
// Include upper part of main template
//
cms.include(template, elements[0], EDITABLE_TEMPLATE);

//
// Get file creation and last modification info
//
CmsResource reqFile = cmso.readResource(requestFileUri);

// Get the category service
CmsCategoryService catService = CmsCategoryService.getInstance();
// Read assigned categories for this resource
List assignedCategories = catService.readResourceCategories(cmso, requestFileUri);
Iterator iCat = assignedCategories.iterator();
boolean isNPISeminar = false;
while (iCat.hasNext()) {
    CmsCategory cat = (CmsCategory)iCat.next();
    //out.println("\n<!-- Path: " + cat.getPath() + " -->");
    if (cat.getPath().equals("event/npi-seminar/"))
        isNPISeminar = true;
}
//out.println("\n<!-- NPI Seminar: " + String.valueOf(isNPISeminar) + " -->");

container = cms.contentload("singleFile", requestFileUri, EDITABLE);
while (container.hasMoreContent()) {
    String timeDisplay = cms.contentshow(container, "TimeDisplay");
    SimpleDateFormat df = timeDisplay.equals("datetime") ? datetime : dateonly;
    //SimpleDateFormat dfIso = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ssZ", locale);
    //dfIso.setTimeZone(TimeZone.getTimeZone("GMT+1"));
    SimpleDateFormat dfIso = getDatetimeAttributeFormat(cmso, cmso.readResource(requestFileUri));
    
    // Get the long values of the begin/end timestamps
    long longBegin = Long.valueOf(cms.contentshow(container, "Begin")).longValue();
    long longEnd = 0;
    try {
        longEnd = Long.valueOf(cms.contentshow(container, "End")).longValue();
    } catch (Exception e) {
        longEnd = 0;
    }
    
    String calendarAddStr = cms.contentshow(container, "CalendarAdd");
    boolean calendarAdd = CmsAgent.elementExists(calendarAddStr) ? Boolean.valueOf(calendarAddStr).booleanValue() : true;
    
    // For convenience, we'll use an EventEntry object
    EventEntry event = new EventEntry(longBegin,
                                      longEnd,
                                      cms.contentshow(container, "Title"),
                                      cms.contentshow(container, "Description"),
                                      reqFile.getResourceId(),
                                      reqFile.getStructureId(),
                                      locale);
    // Format the begin/end time
    String begins = null;
    String ends = null;
    String beginsIso = null;
    String endsIso = null;
    Date beginDate = getBegin(cms, event);// new Date(longBegin);
    Date endDate = null;
    
    try {
        begins = df.format(beginDate).replaceAll("\\s", "&nbsp;");
        beginsIso = dfIso.format(beginDate);
        // If there is an end-time
        if (longEnd > 0) {
            endDate = getEnd(cms, event, beginDate);
            if (event.isOneDayEvent())
                // End time is on the same day as begin time, format only the hour/minute
                ends = timeonly.format(endDate).replaceAll("\\s", "&nbsp;");
            else
                ends = df.format(endDate).replaceAll("\\s", "&nbsp;");
            endsIso = dfIso.format(endDate);
        }
    } catch (NumberFormatException nfe) {
        // Keep ends=null
    }
    String rRule = getRecurrenceRule(cmso, event);
    
    out.println("<div itemscope itemtype=\"http://schema.org/Event\">");
    out.println("<h1 itemprop=\"name\">" + event.getTitle() + "</h1>");
    out.println("<div class=\"byline\">" + cms.getContent(SHARE_LINK_MIN) + "</div>");
    out.println("<div class=\"ingress\" itemprop=\"description\">" + event.getDescription() + "</div>");
    
    
    // Time
    out.println("<div class=\"event-links nofloat\">");
    
    if (begins != null && !requestFolderUri.endsWith(UNDATED_FOLDER)) {
        if (calendarAdd) {
            out.println("<div class=\"icon-calendar-add\" style=\"float:right; font-size:0.8em; text-align:center;\">"
                        + "<a href=\"" + PATH_ICAL_EXPORT + "\"><img alt=\"Calendar\" src=\"" + cms.link("/system/modules/no.npolar.site.npweb/resources/style/icon-calendar-add.png") + "\">"
                        + "<br />" + LABEL_ADD_TO_CALENDAR + "</a>"
                    + "</div>");
        }
        //
        // The begin date displayed screen will be either the "original" date, 
        // or the *most relevant* begin date (today, if it recurs today, or the 
        // closest "next" recurring date if not).
        // Also, the recurrence rules are limited to being applied only to 
        // events with no specified end time. (Not ideal - should be fixed.)
        //
        out.println("<div class=\"event-metadata\">");
        out.println("<div class=\"event-metadata-label\">" + LABEL_TIME + "</div>");
        out.println("<div class=\"event-metadata-value\">");
        out.println("<time itemprop=\"startDate\" datetime=\"" + beginsIso + "\">" + begins + "</time>");
        if (ends != null)
            out.print(" &ndash; <time itemprop=\"endDate\" datetime=\"" + endsIso + "\">" + ends + "</time>");
        if (rRule != null) {
            // This is a recurring event - tell the user about the next 
            // recurrence (possibly also the next after that too)
            try {
                Date currentTime = getNowDate(session);
                // Get the iterator for the recurrence dates, using the recurrence rule (RRULE) found on the event
                RecurrenceIterator iRecur = RecurrenceIteratorFactory.createRecurrenceIterator(rRule, toDateValue(beginDate), LOCAL_TIME_ZONE);
                // Then advance to the current date
                iRecur.advanceTo(toDateValue(currentTime));
                int iterations = 0;
                while (iRecur.hasNext() && ++iterations < 1000) { // Loop with safety on
                    // Get the recurring date
                    DateValue dv = (DateValue)iRecur.next();
                    
                    // Handle case: 
                    // "Recurring" date isn't really a recurring date, but actually the event's "original" start time ...
                    if (isSameDate(dv, beginDate)) {
                        continue; // ... so just continue - we're interested in the next recurring instance
                    }
                    // Handle case:
                    // Recurring date isn't the "original" start time, but it is "today" ...
                    if (isSameDate(dv, currentTime)) {
                        continue; // ... so we still need to get the next recurring instance
                    }
                    
                    out.print(" <i class=\"icon-arrows-cw\""
                            + " data-tooltip=\"" + LABEL_RECURRING_EVENT + "\""
                            + " title=\"" + LABEL_RECURRING_EVENT + "\""
                            + "></i> " 
                            + LABEL_NEXT_EVENT.toLowerCase() + ": " + dateonly.format(toDate(dv)));
                    break;
                }
            } catch (Exception e) {
                out.println("<!-- Error processing recurring event: " + e.getMessage() + " -->");
            }
        }
        out.println("</div>");
        out.println("</div><!-- .event-metadata -->");
    } else if (requestFolderUri.endsWith(UNDATED_FOLDER)) {
        out.println(LABEL_DATE_NOT_DETERMINED);
    }
    
    // Venue (same box)
    venue = cms.contentloop(container, "Venue");
    while (venue.hasMoreContent()) {
        venueName       = cms.contentshow(venue, "Name");
        venueAddress    = cms.contentshow(venue, "Address");
        venueWebsite    = cms.contentshow(venue, "Website");
        venueGoogleMap  = cms.contentshow(venue, "GoogleMap");
        venueName = "<span itemprop=\"name\">" + venueName + "</span>";
        if (cms.elementExists(venueWebsite)) {
            venueName = "<a href=\"" + venueWebsite + "\" target=\"_blank\" class=\"event-venue-website\">" + venueName + "</a>";
        }
        //out.println("<div class=\"event-links nofloat\">");
        //out.println("<div class=\"event-venue-text\">");
        out.println("<div class=\"event-metadata\">");
        out.println("<div class=\"event-metadata-label\">" + LABEL_VENUE + "</div>");
        out.println("<div class=\"event-metadata-value\" itemprop=\"location\">");
        if (cms.elementExists(venueGoogleMap)) {
            out.println("<div class=\"event-venue-map\">");
            out.println(venueGoogleMap);
            out.println("</div><!-- event-venue-map -->");
        }
        out.println("<div itemscope itemtype=\"http://schema.org/Place\">");
        out.println(venueName);
        out.println("<div itemprop=\"address\">" + venueAddress + "</div>");
        out.println("</div>");
        out.println("</div>");
        out.println("</div><!-- .event-metadata -->");
        //out.println("</div><!-- event-venue-text -->");
        //out.println("</div><!-- .event-venue -->");
    }
    
    // Event website or -page (same box)
    String link = cms.contentshow(container, "Link");
    if (cms.elementExists(link)) {
        out.println("<div class=\"event-metadata\">");
        out.println("<div class=\"event-metadata-label\">" + LABEL_LINK + "</div>");
        out.println("<div class=\"event-metadata-value\"><a href=\"" + link + "\" target=\"_blank\">" + link + "</a></div>");
        out.println("</div><!-- .event-metadata -->");
    }
    
    
    // PDF attachment (same box)
    pdflink = cms.contentloop(container, "PDF");
    boolean labelPrinted = false;
    while (pdflink.hasMoreContent()) {
        if (!labelPrinted) {
            out.println("<div class=\"event-metadata\">");
            out.println("<div class=\"event-metadata-label\">" + LABEL_ATTACHMENT + "</div>");
        out.println("<div class=\"event-metadata-value\">");
            labelPrinted = true;
        }
        pdfUri = cms.contentshow(pdflink, "URI");
        pdfTitle = cms.contentshow(pdflink, "Title");
        if (!CmsAgent.elementExists(pdfTitle)) {
            pdfTitle = cms.property("Title", pdfUri);
        }
        pdfNewWindow = Boolean.valueOf(cms.contentshow(pdflink, "NewWindow")).booleanValue();
        out.println("<a href=\"" + cms.link(pdfUri) + "\" class=\"pdf\"" + (pdfNewWindow ? " target=\"_blank\"" : "") + ">" + pdfTitle + "</a>");
        if (labelPrinted) {
            out.println("<br />");
        }
    }
    if (labelPrinted) {
        out.println("</div>");
        out.println("</div><!-- .event-metadata -->");
    }
    
    out.println("</div>");
    
    if (isNPISeminar) {
        try {
            out.println(cms.getContent("/".concat(loc).concat("/html/npi-seminar-series-header.html"), "body", locale));
        } catch (Exception e) {
            out.println("<h4>Error:</h4><p>" + e.getMessage() + "</p>");
        }
    }
    
    //
    // The "Paragraph" elements is a common page element, with its own designated handler
    //
    cms.include("../../no.npolar.common.pageelements/elements/paragraphhandler.jsp");
    
    
    
    // Contact info (host)
    contactinfo = cms.contentloop(container, "Contact");
    while (contactinfo.hasMoreContent()) {
        String host         = cms.contentshow(contactinfo, "Host");
        String hostWebsite  = cms.contentshow(contactinfo, "HostWebsite");
        String hostLogo     = cms.contentshow(contactinfo, "HostLogo");
        String name         = cms.contentshow(contactinfo, "Name");
        String email        = cms.contentshow(contactinfo, "Email");
        String phone        = cms.contentshow(contactinfo, "Phone");
        String address      = cms.contentshow(contactinfo, "Address");
        
        if (CmsAgent.elementExists(host) 
                || CmsAgent.elementExists(name) 
                || CmsAgent.elementExists(email) 
                || CmsAgent.elementExists(phone) 
                || CmsAgent.elementExists(address)) {
            out.println("<div class=\"event-links nofloat\">");
            if (CmsAgent.elementExists(host)) {
                // Host logo
                
                out.println("<div class=\"event-metadata\">");
                out.println("<div class=\"event-metadata-label\">" + LABEL_HOST + "</div>");
                out.println("<div class=\"event-metadata-value\">");
                if (CmsAgent.elementExists(hostLogo)) {
                    imageTag = "src=\"" + cms.link(hostLogo) + "\"";
                    CmsImageScaler imageHandle = new CmsImageScaler(cmso, cmso.readResource(hostLogo));
                    // Scale image, if needed
                    if (imageHandle.getHeight() > IMG_LOGO_MAX_HEIGHT) {
                        CmsImageScaler imageReScaler = imageHandle.getReScaler(imageHandle);
                        imageReScaler.setType(4);
                        imageReScaler.setQuality(100);
                        imageReScaler.setHeight(IMG_LOGO_MAX_HEIGHT);
                        imageReScaler.setWidth((int)(((double)IMG_LOGO_MAX_HEIGHT / imageHandle.getHeight()) * imageHandle.getWidth()));
                        imageTag = cms.img(hostLogo, imageReScaler, null, true);
                    }
                    // Print the image tag first, to align it at the top right of the box. Make the image a link, if possible
                    out.println((CmsAgent.elementExists(hostWebsite) ? "<a href=\"" + hostWebsite + "\" target=\"_blank\">" : "") + 
                            "<img " + imageTag + " alt=\"" + host + "\" class=\"floatright\" />" +
                            (CmsAgent.elementExists(hostWebsite) ? "</a>" : ""));
                }
                if (CmsAgent.elementExists(hostWebsite))
                    out.println("<a href=\"" + hostWebsite + "\" target=\"_blank\">" + host + "</a>");
                else
                    out.println(host);
                out.println("</div>");
                out.println("</div><!-- .event-metadata -->");
            }
            if (CmsAgent.elementExists(name)) {
                /*out.println(LABEL_CONTACT_PERSON + ": " + name);
                if (cms.elementExists(email)) {
                    out.println(" (" + getJavascriptEmail(email) + ")");
                }
                out.println("<br/>");*/
                out.println("<div class=\"event-metadata\">");
                out.println("<div class=\"event-metadata-label\">" + LABEL_CONTACT_PERSON + "</div>");
                out.println("<div class=\"event-metadata-value\">");
                if (cms.elementExists(email)) {
                    String emailLink = "<a href=\"mailto:" + email + "\">" + name + "</a>";
                    emailLink = CmsAgent.getJavascriptMailto(emailLink);
                    out.println(emailLink);
                }
                else {
                    out.println(name);
                }
                out.println("</div>");
                out.println("</div><!-- .event-metadata -->");
            }
            
            if (CmsAgent.elementExists(phone)) {
                out.println("<div class=\"event-metadata\">");
                out.println("<div class=\"event-metadata-label\">" + LABEL_PHONE + "</div>");
                out.println("<div class=\"event-metadata-value\">" + phone + "</div>");
                out.println("</div><!-- .event-metadata -->");
            }
            
            if (CmsAgent.elementExists(address)) {
                out.println("<div class=\"event-metadata\">");
                out.println("<div class=\"event-metadata-label\">" + LABEL_ADDRESS + "</div>");
                out.println("<div class=\"event-metadata-value\">" + address + "</div>");
                out.println("</div><!-- .event-metadata -->");
            }
            
            out.println("</div>");
        }
    }
    
    out.println("</div>");
    
    //out.println(cms.getContent(SHARE_LINKS));
    //request.setAttribute("share", "true");
    //session.setAttribute("share", "true");
    
    
            
        
    

    // Get the top level categories
    //List topLevelCategories = catService.readCategories(cmso, "/no/categories/_categories/type/", true, "/no/categories/_categories/");
    List topLevelCategories = catService.readCategories(cmso, null, false, CATEGORIES_PATH);
    /*out.println("<p>readCategories() returned " + topLevelCategories.size() + " top level categories:</p><ul>");
    Iterator tempItr = topLevelCategories.iterator();
    while (tempItr.hasNext()) {
        out.println("<li>" + ((CmsCategory)tempItr.next()).getTitle() + "</li>");
    }
    out.println("</ul>");*/

    // Remove all top level categories (any assigned category must be a leaf category, according to the XSD)
    //assignedCategories.removeAll(topLevelCategories);
    
    
    //
    // Removed section below due to issues with "to overview"-link
    //
    /*
    Iterator itr = assignedCategories.iterator();
    CmsCategory cat = null;
    out.println("<div class=\"event-links nofloat\">");
    //out.println("<h4><a href=\"" + cms.link(OVERVIEW_FILE) + "?" + getParameterString(request.getParameterMap()) + "\">" + 
    //                LABEL_TO_OVERVIEW + "</a></h4>");
    out.println("<h4>" + LINK_TO_OVERVIEW + "</h4>");
    //out.println("<h4>Tags:</h4>");
    //String[] cats = request.getParameterValues("cat");
    //List selCatList = Arrays.asList(cats);
    
    HashMap paramMap = new HashMap(request.getParameterMap()); // Get all parameters
    String paramStr = "";
    if (paramMap != null) {
        paramMap.remove("cat"); // Remove any categories that are in the parameter already
        Iterator paramItr = paramMap.keySet().iterator(); 
        while (paramItr.hasNext()) {
            paramStr += "&amp;";
            String key = (String)paramItr.next();
            String[] values = (String[])paramMap.get(key);
            for (int i = 0; i < values.length; i++) {
                paramStr += key + "=" + values[i];
                if (i+1 < values.length)
                    paramStr += "&amp;";
            }
        }
    }
    
    
    
    while (itr.hasNext()) {
        cat = (CmsCategory)itr.next();
        if (topLevelCategories.contains(cat)) {
            out.print(cat.getTitle());
            out.println(": ");
        }
        else {
            out.print("<a href=\"" + cms.link(OVERVIEW_FILE) + "?cat=" + cat.getRootPath() + paramStr + "\">");
            out.print(cat.getTitle());
            out.println("</a>");
            if (itr.hasNext())
                out.println(", ");
        }
    }
    out.println("</div>");
    */
}
cms.include(template, elements[1], EDITABLE_TEMPLATE);
%>