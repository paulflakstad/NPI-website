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
/**
* Gets a fitting class name for specifying the maximum number of items 
* to allow in a layout-group container.
* <p>
* For a large number of items, the fallback is the class name for "maximum 
* allowed items".
* 
* @param totalItems The actual items.
* @return A fitting class name.
*/
public static String getLayoutClass(int totalItems) {
   String[] layoutClasses = { "", "single", "double", "triple" };
   while (true) {
       try {
           return layoutClasses[totalItems];
       } catch (ArrayIndexOutOfBoundsException e) {
           return layoutClasses[layoutClasses.length-1];
       }
   }
}
/*
public static String getImageClass(String imgUri, CmsJspActionElement cms) {
    String s ="";
    try {
        ImageUtil.get
    } catch (Exception e) {}
    return s;
}
//*/
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
final String URI_REFERENCES_LIST    = "/system/modules/no.npolar.common.pageelements/elements/cn-reflist.jsp";

final String CAT_PATH_NPI_SEMINAR   = "event/npi-seminar/";
final String CAT_PATH_BOOK_CAFE     = "event/book-cafe/";

final int IMG_LOGO_MAX_HEIGHT       = 120;

String imageTag                     = null;

String pdfUri                       = null;
String pdfTitle                     = null;
//boolean pdfNewWindow                = false;

String venueName                    = null;
String venueAddress                 = null;
String venueWebsite                 = null;
String venueGoogleMap               = null;

String bannerUri                    = cmso.readPropertyObject(requestFileUri, "image.banner", false).getValue(null);

// XML content containers
I_CmsXmlContentContainer container, contactinfo, pdflink, venue, personlist, persons, partners;

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
    out.println("<h1 itemprop=\"name\"" + (bannerUri == null ? "" : " class=\"bots-only\"") + ">" + event.getTitle() + "</h1>");
    if (bannerUri != null) {
        out.println(ImageUtil.getImage(cms, cmso.getRequestContext().removeSiteRoot(bannerUri), event.getTitle()));
    }
    out.println("<div class=\"ingress\" itemprop=\"description\">" + event.getDescription() + "</div>");
    
    
    // Time
    %>
    <aside class="article-meta event-links nofloat">
    <%
    
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
    
    if (event.isAssignedCategory(cmso, CAT_PATH_BOOK_CAFE)) {
        try {
            out.println(cms.getContent("/".concat(loc).concat("/html/om-polar-bokkafe.html")));
        } catch (Exception e) {
            out.println("<!-- ERROR: " + e.getMessage() + " -->");
        }
    } else if (event.isAssignedCategory(cmso, CAT_PATH_NPI_SEMINAR)) {
        try {
            out.println(cms.getContent("/".concat(loc).concat("/html/om-np-seminarserie.html")));
        } catch (Exception e) {
            out.println("<!-- ERROR: " + e.getMessage() + " -->");
        }
    }
    %>
    </aside>
    <%
        
        I_CmsXmlContentContainer timetableEl = cms.contentloop(container, "TimeTable");
        int groupNo = 0;
        String ttEntryStart = "";
        String ttEntryEnd = "";
        if (timetableEl.hasMoreResources()) {
            String ttCaption = cms.contentshow(timetableEl, "Title");
            
            %>
            <div class="toggleable collapsed" style="margin-top: 2em; margin-bottom: 2em;">
            <h2 tabindex="0" class="toggletrigger" style="margin-bot"><%= ttCaption %></h2>
            <div class="toggletarget">
                <%
                    String ttDownloadable = cms.contentshow(timetableEl, "Downloadable");
                    if (CmsAgent.elementExists(ttDownloadable)) {
                        %>
                        <p><a class="cta cta--download alt download" href="<%= cms.link(ttDownloadable) %>" style="margin:2.5em 0 2em 0;" target="_blank">Download as PDF</a></p>
                        <%
                    }
                %>
            <table class="timetable">
            <%
            
            I_CmsXmlContentContainer headingsEl = cms.contentloop(timetableEl, "TimeTableDetailHeading");
            List<String> ttHeadings = new ArrayList<String>();
            //ttHeadings.add("Time");
            while (headingsEl.hasMoreResources()) {
                ttHeadings.add(cms.contentshow(headingsEl));
            }
            if (ttHeadings.size() > 1) {
                out.println("<td></td>"); // Don't use a header for the "Time" column
                int headingNo = 1;
                for (String ttHeading : ttHeadings) {
                    out.println("<th scope=\"col\" id=\"timetable-heading-" + (++headingNo) + "\">" + ttHeading + "</th>");
                }
            }
            
            I_CmsXmlContentContainer groupEl = cms.contentloop(timetableEl, "TimeTableGroup");
            while (groupEl.hasMoreResources()) {
                String ttGroupHeading = cms.contentshow(groupEl, "Heading");
                if (CmsAgent.elementExists(ttGroupHeading)) {
                    %>
                    <tr>
                        <th scope="row" class="table__heading table__heading--subsection" colspan="<%= ttHeadings.size() == 0 ? 2 : ttHeadings.size()+1 %>" id="timetable-group-<%= ++groupNo %>">
                            <%= ttGroupHeading %>
                        </th>
                    </tr>
                    <%
                }
                I_CmsXmlContentContainer entryEl = cms.contentloop(groupEl, "Entry");
                int entryNo = 0;
                while (entryEl.hasMoreResources()) {
                    String ttEntryStartTmp = cms.contentshow(entryEl, "Start");
                    if (CmsAgent.elementExists(ttEntryStartTmp) && !ttEntryStartTmp.trim().isEmpty()) {
                        ttEntryStart = ttEntryStartTmp;
                    } else {
                        ttEntryStart = ttEntryEnd; // Set start time to previous entry's end time
                    }
                    // End time is required
                    ttEntryEnd = cms.contentshow(entryEl, "End");
                    boolean isSingleTime = ttEntryEnd.equals(".") || ttEntryEnd.equals(ttEntryStart);
                    
                    String ttEntryTime = "<th scope=\"row\" id=\"timetable-time-" + groupNo + "-" + (++entryNo) + "\">"
                                            + ttEntryStart 
                                            + (isSingleTime ? "" : ("&ndash;" + ttEntryEnd))
                                        + "</th>";
                    
                    String ttEntryType = cms.contentshow(entryEl, "Type");
                    out.println("<tr class=\"" + ttEntryType + "\">");
                    out.println(ttEntryTime);
                    
                    I_CmsXmlContentContainer detailsEl = cms.contentloop(entryEl, "Detail");
                    String ttEntryDetails = "";
                    int detailsHeadingNo = 1; // 1 is always "Time"
                    while (detailsEl.hasMoreResources()) {
                        detailsHeadingNo++;
                        ttEntryDetails += "<td headers=\""
                                                + "timetable-group-" + groupNo 
                                                + " timetable-time-" + groupNo + "-" + entryNo
                                                + " timetable-heading-" + detailsHeadingNo
                                                //+ (detailsHeadingNo > 2 ? (" timetable-heading-"+detailsHeadingNo) : "")
                                        + "\">"
                                            + cms.contentshow(detailsEl)
                                        + "</td>";
                    }
                    if (detailsHeadingNo <= ttHeadings.size()) {
                        if (detailsHeadingNo == 2) {
                            ttEntryDetails = "<td colspan=\"" + ttHeadings.size() + "\"" + ttEntryDetails.substring(3);
                        } else {
                            while (detailsHeadingNo <= ttHeadings.size()) {
                                ttEntryDetails += "<td></td>";
                                detailsHeadingNo++;
                            }
                        }
                    }
                    out.println(ttEntryDetails);
                    out.println("</tr>");
                }
            }
            %>
            </table>
            </div>
            </div>
            <%
        }

        // If we're using a local form to handle signups, we can evaluate the 
        // deadline from that form.
        I_CmsXmlContentContainer signupEl = cms.contentloop(container, "SignupForm");
        if (signupEl.hasMoreResources()) {
            %>
            <div class="event__signup">
            <%
            String signupUri = cms.contentshow(signupEl, "URI");
            String signupLabel = cms.contentshow(signupEl, "SignupLabel");
            String signupButtonText = cms.contentshow(signupEl, "ButtonText");
            String signupDeadline = "";
            boolean signupIsExpired = false;
            
            if (cmso.existsResource(signupUri) 
                    && (cmso.readResource(signupUri).getTypeId() == OpenCms.getResourceManager().getResourceType("np_form").getTypeId())) {
                signupDeadline = cmso.readPropertyObject(signupUri, "expires", false).getValue("");
                if (!signupDeadline.isEmpty()) {
                    Date signupDeadlineDate = new Date(Long.valueOf(signupDeadline));
                    // Create a calendar representing the day before the deadline.
                    // We'll use it when displaying the deadline to the user.
                    // We do this because most deadlines are actually set to 
                    // sometime the day after the "real" deadline, in order to 
                    // mitigate issues with last-minute-signups and people in 
                    // different time zones.
                    Calendar signupDeadlineCal = new GregorianCalendar();
                    signupDeadlineCal.setTime(signupDeadlineDate);
                    signupDeadlineCal.add(Calendar.DATE, -1);
                    
                    signupIsExpired = signupDeadlineDate.before(NOW);
                    signupDeadline = CmsAgent.formatDate(String.valueOf(signupDeadlineCal.getTimeInMillis()), cms.label("label.event.dateformat.dm"), locale);
                }
            }
            if (signupIsExpired) {
                %>
                <button class="cta button button--cta" disabled="disabled"><%= signupButtonText %></button>
                <p class="button__caption"><%= signupLabel + " " + cms.label("label.event.signup.expired").toLowerCase() + signupDeadline %></p>
                <%
            } else {
                %>
                <a class="cta button button--cta" href="<%= cms.link(signupUri) %>"><%= signupButtonText %></a>
                <%
                if (!signupDeadline.isEmpty()) {
                    %>
                    <p class="button__caption"><%= signupLabel + " " + cms.label("label.event.signup.deadline").toLowerCase() + signupDeadline %></p>
                    <%    
                }
            }
            %>
            </div>
            <%
        }
        
        
    /*
    if (event.isAssignedCategory(cmso, CAT_PATH_NPI_SEMINAR)) {
        try {
            out.println(cms.getContent("/".concat(loc).concat("/html/npi-seminar-series-header.html"), "body", locale));
        } catch (Exception e) {
            out.println("<h4>Error:</h4><p>" + e.getMessage() + "</p>");
        }
    }
    //*/
    //
    // The "Paragraph" elements is a common page element, with its own designated handler
    //
    cms.include(URI_PARAGRAPH_HANDLER);

    
    
    personlist = cms.contentloop(container, "People");
    if (personlist.hasMoreResources()) {
        String listTitle = cms.contentshow(personlist, "Title");
        persons = cms.contentloop(personlist, "Person");
        
        
        String layoutClass = getLayoutClass(persons.getCollectorResult().size());
        %>
        <aside class="article-related article-meta max-wide">
        <!--<aside class="layout-group <%= layoutClass %> article-related article-meta max-wide">-->
            <h2 class="article-meta__heading"><%= listTitle %></h2>
            <div class="article-meta__content cards--people">
        <%
            
            while (persons.hasMoreResources()) {
                String name = cms.contentshow(persons, "Name");
                String affiliation = cms.contentshow(persons, "Affiliation");
                String text = cms.contentshow(persons, "Text");
                String webpage = cms.contentshow(persons, "Webpage");
                String imageUri = null;
                I_CmsXmlContentContainer image = cms.contentloop(persons, "Image");
                if (image.hasMoreResources()) {
                    imageUri = cms.contentshow(image, "URI");
                }
                %>
                <!--<div class="layout-box">-->
                    <!-- card--h = horizontal layout -->
                    <!-- card--alt = alternative version, with round, fix-width images -->
                    <div class="card card--h card--alt">
                        <%
                            if (CmsAgent.elementExists(imageUri)) {
                                %>
                                <div class="card__media">
                                        <!--<img src="content/blogg/n-ice2015/2015-03-17/2015-03-17-greenhouse-gases-research-3-crop.jpg" alt="">-->
                                        <!--<img src="http://tromsoby.no/file/images/webbaner_ny.preview.jpg" alt="" class="image--landscape">-->
                                        <!--<%= ImageUtil.getImage(cms, imageUri, name, ImageUtil.SIZE_S) %>-->
                                        <%= ImageUtil.getImage(cms, imageUri, name, ImageUtil.CROP_RATIO_1_1, 200, 20, ImageUtil.SIZE_S, 90, null) %>
                                </div>
                                <%
                            }
                        %>
                        <div class="card__content">
                            <h3 class="card__title"><%= CmsAgent.elementExists(webpage) ? ("<a href=\""+webpage+"\">"+name+"</a>") : name %></h3>
                            <% if (CmsAgent.elementExists(affiliation) || CmsAgent.elementExists(webpage)) { %>
                            <div class="card__details">
                                <% if (CmsAgent.elementExists(affiliation)) { %>
                                <p><%= affiliation %></p>
                                <% } if (CmsAgent.elementExists(webpage)) { %>
                                <!--<ul class="card__details-links">-->
                                    <!--<li class="card__details-link"><a href="<%= cms.link(webpage) %>">Mer&hellip;</a></li>-->
                                <!--</ul>-->
                                <% } %>
                            </div>
                            <% } %>
                            <%= text %>
                        </div>
                    </div>
                <!--</div>-->
                <%
            }
        
        %>
            </div>
        </aside>
        <%
    }

partners = cms.contentloop(container, "PartnerLogo");
StringBuilder partnersHtml = new StringBuilder();
while (partners.hasMoreResources()) {
    String targetUri = cms.contentshow(partners, "TargetURI");
    String imageUri = cms.contentshow(partners, "ImageURI");
    String imageAlt = cms.contentshow(partners, "AltText");

    // Decide the scale width based on the logo dimensions (ratio)
    String[] imageDims = cmso.readPropertyObject(imageUri, "image.size", false).getValue("w:1,h:1").split(",");
    // If the width is considerably larger than the height, call this a "landscape" image
    boolean isLandscape = Double.valueOf(imageDims[0].substring(2)) / Double.valueOf(imageDims[1].substring(2)) > 1.4; 
    int logoWidth = isLandscape ? 140 : 90; // same as the css max-widths => sharp images
    String logoImageHtml = ImageUtil.getImage(cms, imageUri, imageAlt, ImageUtil.CROP_RATIO_NO_CROP, logoWidth, 100, ImageUtil.SIZE_M, 100, null);
    logoImageHtml = logoImageHtml.contains(" class=\"") ? 
                        logoImageHtml.replace(" class=\"", " class=\"image--".concat(isLandscape ? "h " : "v ")) 
                        :
                        logoImageHtml.replace("<img ", "<img class=\"image--".concat(isLandscape ? "h" : "v").concat("\" ")); 

    partnersHtml.append("<li>");
    partnersHtml.append("<a href=\"" + targetUri + "\" data-tooltip=\"" + imageAlt + "\">");
    partnersHtml.append(logoImageHtml);
    partnersHtml.append("<span class=\"bots-only\">" + imageAlt + "</span>");
    partnersHtml.append("</a>");
    partnersHtml.append("</li>");
}
if (!partnersHtml.toString().isEmpty()) {
    %>
    <aside class="partners">
        <ul class="list--h">
            <%= partnersHtml.toString() %>
        </ul>
    </aside>
    <%
}
    
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
            %>
            <aside class="article-meta event-links nofloat">
            <%
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
            %>
            </aside>
            <%
        }
    }
    
    out.println("</div>");
}


// Include the list of references (if any)
cms.include(URI_REFERENCES_LIST);

cms.include(template, elements[1], EDITABLE_TEMPLATE);
%>