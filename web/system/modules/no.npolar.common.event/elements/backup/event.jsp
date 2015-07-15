<%-- 
    Document   : event
    Created on : 18.mar.2011, 18:49:12
    Author     : Paul-Inge Flakstad <flakstad at npolar.no>
--%><%@ page import="no.npolar.util.*,
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
%><%
/* HARD-CODED FOR NANSEN-AMUNDSEN - NO GOOD... */
final String OVERVIEW_FILE          = "/no/events/index.html";
final String CATEGORIES_PATH        = "/no/events/";
final String UNDATED_FOLDER         = "/no_date/";

CmsAgent cms                        = new CmsAgent(pageContext, request, response);
CmsObject cmso                      = cms.getCmsObject();

final String LABEL_TO_OVERVIEW      = cms.label("label.for.np_event.tooverview");//"Til oversikten";
final String LINK_TO_OVERVIEW       = "<a href=\"" + cms.link(OVERVIEW_FILE) + "?" + getParameterString(request.getParameterMap()) + "\">" + 
                                            LABEL_TO_OVERVIEW + "</a>";

String requestFileUri               = cms.getRequestContext().getUri();
String requestFolderUri             = cms.getRequestContext().getFolderUri();
Locale locale                       = cms.getRequestContext().getLocale();
String loc                          = locale.toString();

SimpleDateFormat datetime           = new SimpleDateFormat(cms.label("label.event.dateformat.datetime"), locale);
SimpleDateFormat dateonly           = new SimpleDateFormat(cms.label("label.event.dateformat.dateonly"), locale);
SimpleDateFormat timeonly           = new SimpleDateFormat(cms.label("label.event.dateformat.timeonly"), locale);

//datetime                            = new SimpleDateFormat("dd. MMMM HH:mm", locale); // MOVE to workplace.properties
//dateonly                            = new SimpleDateFormat("dd. MMMM", locale); // MOVE to workplace.properties

final String SHARE_LINKS            = "../../no.npolar.common.pageelements/elements/share-addthis-" + loc + ".txt";
final String RELATED_RESOURCE_LIST  = "./list-related-resources.jsp";

final boolean EDITABLE              = true;
final boolean EDITABLE_TEMPLATE     = false;

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

final int IMG_LOGO_MAX_HEIGHT       = 120;

String imageTag                     = null;

String pdfUri                       = null;
String pdfTitle                     = null;
boolean pdfNewWindow                = false;
boolean shareLinks                  = true;
boolean showRelatedResourceList     = true;
boolean groupRelatedResources       = false;

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
    out.println("\n<!-- Path: " + cat.getPath() + " -->");
    if (cat.getPath().equals("event/npi-seminar/"))
        isNPISeminar = true;
}
out.println("\n<!-- NPI Seminar: " + String.valueOf(isNPISeminar) + " -->");

container = cms.contentload("singleFile", requestFileUri, EDITABLE);
while (container.hasMoreContent()) {
    String timeDisplay = cms.contentshow(container, "TimeDisplay");
    SimpleDateFormat df = timeDisplay.equals("datetime") ? datetime : dateonly;
    
    // Get the long values of the begin/end timestamps
    long longBegin = Long.valueOf(cms.contentshow(container, "Begin")).longValue();
    long longEnd = 0;
    try {
        longEnd = Long.valueOf(cms.contentshow(container, "End")).longValue();
    } catch (Exception e) {
        longEnd = 0;
    }
    
    // For convenience, we'll use an EventEntry object
    EventEntry event = new EventEntry(longBegin, longEnd, 
                                        cms.contentshow(container, "Title"), cms.contentshow(container, "Description"), 
                                        reqFile.getResourceId(), reqFile.getStructureId(), locale);
    // Format the begin/end time
    String begins = null;
    String ends = null;
    try {
        begins = df.format(new Date(longBegin));
        // If there is an end-time
        if (longEnd > 0) {
            if (event.isOneDayEvent())
                // End time is on the same day as begin time, format only the hour/minute
                ends = timeonly.format(new Date(longEnd));
            else
                ends = df.format(new Date(longEnd));
        }
    } catch (NumberFormatException nfe) {
        // Keep ends=null
    }
    
    out.println("<h1>" + event.getTitle() + "</h1>");
    out.println("<div class=\"ingress\">" + event.getDescription() + "</div>");
    
    
    // Time
    out.println("<div class=\"event-links nofloat\">");
    
    if (begins != null && !requestFolderUri.endsWith(UNDATED_FOLDER)) {
        out.println("<div class=\"event-metadata\">");
        out.println("<div class=\"event-metadata-label\">" + LABEL_TIME + "</div>");
        out.println("<div class=\"event-metadata-value\">");
        out.print(begins);
        if (ends != null)
            out.print(" &ndash; " + ends);
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
        if (cms.elementExists(venueWebsite)) {
            venueName = "<a href=\"" + venueWebsite + "\" target=\"_blank\" class=\"event-venue-website\">" + venueName + "</a>";
        }
        //out.println("<div class=\"event-links nofloat\">");
        //out.println("<div class=\"event-venue-text\">");
        out.println("<div class=\"event-metadata\">");
        out.println("<div class=\"event-metadata-label\">" + LABEL_VENUE + "</div>");
        out.println("<div class=\"event-metadata-value\">");
        if (cms.elementExists(venueGoogleMap)) {
            out.println("<div class=\"event-venue-map\">");
            out.println(venueGoogleMap);
            out.println("</div><!-- event-venue-map -->");
        }
        out.println("" + venueName + "");
        out.println(venueAddress);
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
        out.println(cms.getContent("/".concat(loc).concat("/html/npi-seminar-series-header.html"), "body", locale));
    }
    
    //
    // The "Paragraph" elements is a common page element, with its own designated handler
    //
    cms.include("../../no.npolar.common.pageelements/elements/paragraphhandler.jsp");
    
    try {
        showRelatedResourceList = Boolean.valueOf(cms.contentshow(container, "RelatedResources")).booleanValue();
    } catch (Exception e) {
        // Retain default value
    }
    if (showRelatedResourceList) {
        try {
            groupRelatedResources = Boolean.valueOf(cms.contentshow(container, "GroupRelatedResources")).booleanValue();
        } catch (Exception e) {
            // Retain default value
        }
        request.setAttribute("group_related", String.valueOf(groupRelatedResources));
        cms.include(RELATED_RESOURCE_LIST);
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
        
        if (cms.elementExists(name) || cms.elementExists(email) || cms.elementExists(phone) || cms.elementExists(address)) {
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
            if (cms.elementExists(name)) {
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
            
            if (cms.elementExists(phone)) {
                out.println("<div class=\"event-metadata\">");
                out.println("<div class=\"event-metadata-label\">" + LABEL_PHONE + "</div>");
                out.println("<div class=\"event-metadata-value\">" + phone + "</div>");
                out.println("</div><!-- .event-metadata -->");
            }
            
            if (cms.elementExists(address)) {
                out.println("<div class=\"event-metadata\">");
                out.println("<div class=\"event-metadata-label\">" + LABEL_ADDRESS + "</div>");
                out.println("<div class=\"event-metadata-value\">" + address + "</div>");
                out.println("</div><!-- .event-metadata -->");
            }
            
            out.println("</div>");
        }
    }
    
    
    
    if (shareLinks) {
        out.println(cms.getContent(SHARE_LINKS));
    }
    
            
    
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