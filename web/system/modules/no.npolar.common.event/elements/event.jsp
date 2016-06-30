<%-- 
    Document   : event
    Created on : 18.mar.2011, 18:49:12
    Author     : Paul-Inge Flakstad <flakstad at npolar.no>
--%><%@ page import="com.google.ical.values.DateTimeValueImpl,
                 com.google.ical.values.DateValue,
                 com.google.ical.values.DateValueImpl,
                 com.google.ical.iter.RecurrenceIteratorFactory,
                 com.google.ical.iter.RecurrenceIterator,
                 no.npolar.util.*,
                 no.npolar.common.eventcalendar.*,
                 java.util.Arrays,
                 java.util.ArrayList,
                 java.util.Calendar,
                 java.util.Date,
                 java.util.GregorianCalendar,
                 java.util.HashMap,
                 java.util.Iterator,
                 java.util.List,
                 java.util.Locale,
                 java.util.Map,
                 java.util.Set,
                 java.util.TimeZone,
                 java.text.SimpleDateFormat,
                 org.opencms.jsp.*,
                 org.opencms.loader.CmsImageScaler,
                 org.opencms.file.*,
                 org.opencms.file.collectors.*,
                 org.opencms.file.types.*,
                 org.opencms.relations.*,
                 org.opencms.workplace.CmsWorkplaceManager,
                 org.opencms.workplace.CmsWorkplaceSettings,
                 org.opencms.xml.content.*,
                 org.opencms.main.*,
                 org.opencms.util.CmsRequestUtil,
                 org.opencms.util.CmsUUID" 
        session="true"
%><%!
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
public Long getBegin(CmsJspActionElement cms) {
    String paramBegin = cms.getRequest().getParameter("begin");
    if (paramBegin != null) {
        try {
            return Long.valueOf(paramBegin);
        } catch (Exception e) {
        }
    }
    return null;
}
%><%
CmsAgent cms                        = new CmsAgent(pageContext, request, response);
CmsObject cmso                      = cms.getCmsObject();
String requestFileUri               = cms.getRequestContext().getUri();
String requestFolderUri             = cms.getRequestContext().getFolderUri();
Locale locale                       = cms.getRequestContext().getLocale();
String loc                          = locale.toString();

final Date NOW                      = getNowDate(cms.getRequest().getSession());
final Long RECURRENCE_BEGIN         = getBegin(cms);

SimpleDateFormat dmy                = new SimpleDateFormat(cms.label("label.event.dateformat.dmy"), locale);

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
//final String LABEL_DATE_NOT_DETERMINED  = cms.label("label.for.np_event.datenotset");//"Dato ikke fastsatt";
final String LABEL_VENUE            = cms.label("label.for.np_event.venue");
final String LABEL_ADDRESS          = cms.label("label.Contact.Address");

final String LABEL_ADD_TO_CALENDAR  = loc.equalsIgnoreCase("no") ? "Legg til i<br />min kalender" : "Add to my<br />calendar";
final String URI_ICAL_EXPORT        = "/system/modules/no.npolar.common.event/elements/icalendar.jsp".concat("?event=" + requestFileUri);

final String URI_PARAGRAPH_HANDLER  = "/system/modules/no.npolar.common.pageelements/elements/paragraphhandler.jsp";

final String CAT_PATH_NPI_SEMINAR   = "event/npi-seminar/";
final int IMG_LOGO_MAX_HEIGHT       = 120;

String imageTag                     = null;

String pdfUri                       = null;
String pdfTitle                     = null;
//boolean pdfNewWindow                = false;

String venueName                    = null;
String venueAddress                 = null;
String venueWebsite                 = null;
String venueGoogleMap               = null;

// XML content containers
I_CmsXmlContentContainer container, contactinfo, pdflink, venue;

// Main template
String template                     = cms.getTemplate();
String[] elements                   = cms.getTemplateIncludeElements();

//
// Include upper part of main template
//
cms.include(template, elements[0], EDITABLE_TEMPLATE);

container = cms.contentload("singleFile", requestFileUri, EDITABLE);
while (container.hasMoreContent()) {
     
    String calendarAddStr = cms.contentshow(container, "CalendarAdd");
    boolean calendarAdd = CmsAgent.elementExists(calendarAddStr) ? Boolean.valueOf(calendarAddStr).booleanValue() : true;
    
    // For convenience, we'll use an EventEntry object
    EventEntry event = new EventEntry(cms, cmso.readResource(requestFileUri));
    
    // Do special stuff if this is a recurring event
    EventEntry nextRecurrence = null;
    List<EventEntry> recurrences = event.getRecurrences(RECURRENCE_BEGIN != null ? RECURRENCE_BEGIN : NOW.getTime(), 2);
    try {
        if (RECURRENCE_BEGIN != null && (RECURRENCE_BEGIN != event.getStartTime())) {
            // This is a recurrence of the base event
            event = recurrences.get(0);
            nextRecurrence = recurrences.get(1);
        } else {
            // This is the base event
            nextRecurrence = recurrences.get(0);
        }
    } catch (Exception e) {
        // Assume no such (recurrence) event(s)
    }
    
    String rRule = event.getRecurrenceRule();
    
    out.println("<div itemscope itemtype=\"http://schema.org/Event\">");
    out.println("<h1 itemprop=\"name\">" + event.getTitle() + "</h1>");
    out.println("<div class=\"ingress\" itemprop=\"description\">" + event.getDescription() + "</div>");
    
    
    // Time
    out.println("<div class=\"event-links nofloat\">");
    
    //if (begins != null && !requestFolderUri.endsWith(UNDATED_FOLDER)) {
        if (calendarAdd) {
            
            out.println("<div class=\"icon-calendar-add\" style=\"float:right; font-size:0.8em; text-align:center;\">"
                        + "<a href=\"" + cms.link(CmsRequestUtil.appendParameter(URI_ICAL_EXPORT, "begin", String.valueOf(event.getStartTime()))) + "\">"
                            + "<img alt=\"Calendar\" src=\"" + cms.link("/system/modules/no.npolar.site.npweb/resources/style/icon-calendar-add.png") + "\">"
                            + "<br>" 
                            + LABEL_ADD_TO_CALENDAR 
                        + "</a>"
                    + "</div>");
        }
        
        // The begin date displayed screen will be either the "original" date, 
        // or the *most relevant* begin date (today, if it recurs today, or the 
        // closest "next" recurring date if not).
        // Also, the recurrence rules are limited to being applied only to 
        // events with no specified end time. (Not ideal - should be fixed.)
        out.println("<div class=\"event-metadata\">");
        out.println("<div class=\"event-metadata-label\">" + LABEL_TIME + "</div>");
        out.println("<div class=\"event-metadata-value\">");
        out.println(event.getTimespanHtml(cms, NOW));
        /*out.println("<time itemprop=\"startDate\" datetime=\"" + beginsIso + "\">" + begins + "</time>");
        if (ends != null)
            out.print(" &ndash; <time itemprop=\"endDate\" datetime=\"" + endsIso + "\">" + ends + "</time>");*/
        if (rRule != null) {
            // This is a recurring event - tell the user about the next 
            // recurrence (possibly also the next after that too)
            try {
                if (nextRecurrence != null) {
                    String nextRecurrenceUri = CmsRequestUtil.appendParameter(nextRecurrence.getUri(cmso), "begin", String.valueOf(nextRecurrence.getBegin(NOW).getTime()));
                    out.print(" <i class=\"icon-arrows-cw\""
                            + " data-tooltip=\"" + LABEL_RECURRING_EVENT + "\""
                            + " title=\"" + LABEL_RECURRING_EVENT + "\""
                            + "></i> " 
                            + "<a href=\"" + cms.link(nextRecurrenceUri) + "\""
                            + " rel=\"nofollow\""
                            + ">"
                            + LABEL_NEXT_EVENT.toLowerCase() + ": " + dmy.format(nextRecurrence.getBegin(NOW))
                            + "</a>"
                            );
                }
            } catch (Exception e) {
                out.println("<!-- Error processing recurring event: " + e.getMessage() + " -->");
            }
        }
        out.println("</div>");
        out.println("</div><!-- .event-metadata -->");
    /*} else if (requestFolderUri.endsWith(UNDATED_FOLDER)) {
        out.println(LABEL_DATE_NOT_DETERMINED);
    }*/
    
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
        //pdfNewWindow = Boolean.valueOf(cms.contentshow(pdflink, "NewWindow")).booleanValue();
        // PDFs should always open in new window
        out.println("<a href=\"" + cms.link(pdfUri) + "\" class=\"pdf\" target=\"_blank\">" + pdfTitle + "</a>");
        if (labelPrinted) {
            out.println("<br />");
        }
    }
    if (labelPrinted) {
        out.println("</div>");
        out.println("</div><!-- .event-metadata -->");
    }
    
    out.println("</div>");
    
    if (event.isAssignedCategory(cmso, CAT_PATH_NPI_SEMINAR)) {
        try {
            out.println(cms.getContent("/".concat(loc).concat("/html/npi-seminar-series-header.html"), "body", locale));
        } catch (Exception e) {
            out.println("<h4>Error:</h4><p>" + e.getMessage() + "</p>");
        }
    }
    
    //
    // The "Paragraph" elements is a common page element, with its own designated handler
    //
    cms.include(URI_PARAGRAPH_HANDLER);
    
    
    
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
                /*
                out.println(LABEL_CONTACT_PERSON + ": " + name);
                if (cms.elementExists(email)) {
                    out.println(" (" + getJavascriptEmail(email) + ")");
                }
                out.println("<br/>");
                //*/
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
}

cms.include(template, elements[1], EDITABLE_TEMPLATE);
%>