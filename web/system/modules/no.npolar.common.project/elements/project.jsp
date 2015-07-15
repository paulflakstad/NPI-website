<%-- 
    Document   : project-service-redirect
    Created on : Apr 3, 2014, 8:41:25 PM
    Author     : Paul-Inge Flakstad, Norwegian Polar Institute
--%><%-- 
    Document   : project.jsp
    Description: Detail template for project files (resources of type "np_project").
    Created on : Mar 13, 2013, 3:25:53 PM
    Author     : flakstad
--%><%@ page import="java.util.Collections,
                 no.npolar.util.CmsAgent,
                 no.npolar.util.CmsImageProcessor,
                 java.net.*,
                 java.io.*,
                 java.util.Collections,
                 java.util.List,
                 java.util.ArrayList,
                 java.util.Date,
                 java.util.Map,
                 java.util.HashMap,
                 java.util.Locale,
                 java.util.Iterator,
                 java.text.SimpleDateFormat,
                 org.opencms.file.CmsObject,
                 org.opencms.file.CmsFile,
                 org.opencms.file.CmsResource,
                 org.opencms.file.CmsResourceFilter,
                 org.opencms.file.collectors.I_CmsResourceCollector,
                 org.opencms.file.types.CmsResourceTypeImage, 
                 org.opencms.file.CmsUser,
                 org.opencms.file.CmsProperty,
                 org.opencms.json.*,
                 org.opencms.jsp.I_CmsXmlContentContainer, 
                 org.opencms.main.OpenCms,
                 org.opencms.main.CmsException,
                 org.opencms.loader.CmsImageScaler,
                 org.opencms.staticexport.CmsStaticExportManager,
                 org.opencms.relations.CmsCategory,
                 org.opencms.relations.CmsCategoryService,
                 org.opencms.util.CmsHtmlExtractor,
                 org.opencms.util.CmsRequestUtil,
                 org.opencms.util.CmsUriSplitter,
                 org.opencms.xml.content.CmsXmlContent,
                 org.opencms.xml.content.CmsXmlContentFactory,
                 org.opencms.xml.types.I_CmsXmlContentValue" session="true"
%><%!
    /** 
     * Tries to match a category or any of its parent categories against a list of possible matching categories. 
     * Used typically to retrieve the "top level" (parent) category of a given category.
     *
     * @param possibleMatches The list of possible matching categories (typically "top level" categories).
     * @param category The category to match against the list of possible matches (typically any category assigned to an event).
     * @param cmso An initialized CmsObject.
     * @param categoryReferencePath The category reference path - i.e. a path that is used to determine which categories are available.
     * 
     * @return The first category in the list of possible matches that matches the given category, or null if there is no match.
     */
    public static CmsCategory matchCategoryOrParent(List<CmsCategory> possibleMatches, CmsCategory category, CmsObject cmso, String categoryReferencePath) throws CmsException {
        CmsCategoryService cs = CmsCategoryService.getInstance();
        String catPath = category.getPath();
        CmsCategory tempCat = null;
        while (catPath.contains("/") && !(catPath = catPath.substring(0, catPath.lastIndexOf("/"))).equals("")) {
            try {
                tempCat = cs.readCategory(cmso, catPath, categoryReferencePath);
                if (possibleMatches.contains(tempCat))
                    return tempCat;
            } catch (Exception e) {
                return null;
            }
        }
        return null;
    }
%><%
// JSP action element + some commonly used stuff
CmsAgent cms                = new CmsAgent(pageContext, request, response);
CmsObject cmso              = cms.getCmsObject();
String requestFileUri       = cms.getRequestContext().getUri();
String requestFolderUri     = cms.getRequestContext().getFolderUri();
String resourceUri          = request.getParameter("resourceUri") == null ? requestFileUri : request.getParameter("resourceUri");
Locale locale               = cms.getRequestContext().getLocale();
String loc                  = locale.toString();

final boolean JSON          = request.getParameter("format") != null && request.getParameter("format").equalsIgnoreCase("json");

if (!JSON) {
    %>
    <style type="text/css">
        
        .paragraph, .ingress { margin-bottom: 1em; }
        .paragraph p:first-child { margin-top:0; }
    </style>
    <%

// Common page element handlers
final String PARAGRAPH_HANDLER      = "../../no.npolar.common.pageelements/elements/paragraphhandler.jsp";
final boolean EDITABLE      = false;

final String DF_Y           = "yyyy";
final String DF_MY          = "MMMM yyyy";
final String DF_DMY         = "d. MMMM yyyy";

final String[] STATUS       = new String[] { "Avsluttet", "Aktivt", "Planlagt" };
final int STATUS_FINISHED   = 0;
final int STATUS_ACTIVE     = 1;
final int STATUS_PLANNED    = 2;

// Template ("outer" or "master" template)
final boolean EDITABLE_TEMPLATE = false;
String template             = cms.getTemplate();
String[] elements           = cms.getTemplateIncludeElements();
// Include upper part of main template
cms.include(template, elements[0], EDITABLE_TEMPLATE);

String title            = null;
String titleAbbrev      = null;
String area             = null;
boolean featured        = false;
String npiId            = null;
String risId            = null;
String keywords         = null;
String websiteTitle     = null;
String websiteUri       = null;
Date dateBegins         = null;
Date dateEnds           = null;
String timeDisplay      = null;
String programmeTitle   = null;
String programmeUri     = null;
String status           = null;
String personName       = null;
String personUri        = null;
String personFirstName  = null;
String personLastName   = null;
String participantTitle = null;
String participantUri   = null;
String logoUri          = null;
String imageUri         = null;
String imageAlt         = null;
String imageCaption     = null;
String imageSource      = null;
String imageType        = null;
String imageSize        = null;
String imageFloat       = null;
String description      = null;

List<String> leadersStr = new ArrayList<String>();
List<String> participantsStr = new ArrayList<String>();

I_CmsXmlContentContainer container = cms.contentload("singleFile", resourceUri, EDITABLE);

while (container.hasMoreContent()) {
    // Title
    title = cms.contentshow(container, "Title");
    titleAbbrev = cms.contentshow(container, "AbbrevTitle");
    out.println("<h1>" + title + (CmsAgent.elementExists(titleAbbrev) ? " (" + titleAbbrev + ")" : "") + "</h1>");

    // Description
    description = cms.contentshow(container, "Description");
    out.println("<div class=\"ingress\">");
    if (CmsAgent.elementExists(description))
        out.println(description);
    out.println("</div>");

    featured = Boolean.valueOf(cms.contentshow(container, "Featured")).booleanValue();
    npiId = cms.contentshow(container, "NpiIdentifier");
    risId = cms.contentshow(container, "RisIdentifier");
    keywords = cms.contentshow(container, "Keywords");


    //out.println("<div style=\"font-size:0.8em; overflow:auto; margin-bottom:3em; background:#eee; border:1px solid #ccc; margin-left:3px; margin-right:3px; box-shadow:0 0 3px #aaa; padding:0.4em 0;\">");
    out.println("<div class=\"event-links nofloat\" style=\"font-size:0.7em; padding-bottom:0.6em; margin-top:-2em; margin-bottom:2em;\">");

    logoUri = cms.contentshow(container, "Logo");
    if (CmsAgent.elementExists(logoUri)) {
        //out.println("<span class=\"media pull-right\"><img src=\"" + cms.link(logoUri) + "\" alt=\"" + title + "\" /></span>");
        out.println("<img class=\"pull-right\" style=\"margin:0 0 1em 1em; width:18%;\" src=\"" + cms.link(logoUri) + "\" alt=\"" + title + "\" />");
    }

    //out.println("<div class=\"pull-right\" style=\"width:76%;\">");
    out.println("<div>");

    // Timespan
    try { dateBegins = new Date(Long.valueOf(cms.contentshow(container, "Begin")).longValue()); } catch (Exception e) { dateBegins = null; }
    try { dateEnds = new Date(Long.valueOf(cms.contentshow(container, "End")).longValue()); } catch (Exception e) { dateEnds = null; }
    timeDisplay = cms.contentshow(container, "TimeDisplay");
    SimpleDateFormat df = new SimpleDateFormat("year".equalsIgnoreCase(timeDisplay) ? DF_Y : "month".equalsIgnoreCase(timeDisplay) ? DF_MY : DF_DMY);
    //out.println("<p>" + df.format(dateBegins) + (dateEnds != null ? (" &ndash; " + df.format(dateEnds)) : "") + "</p>");

    // Status
    Date now = new Date();
    if (now.before(dateBegins)) {
        status = STATUS[STATUS_PLANNED];
    }
    else if (dateEnds != null && now.after(dateEnds)) {
        status = STATUS[STATUS_FINISHED];
    } 
    else {
        status = STATUS[STATUS_ACTIVE];
    }

    out.println("<strong>" + status + "</strong>: " 
            + (status.equals(STATUS[STATUS_ACTIVE]) && dateEnds == null ? "siden " : "")
            + df.format(dateBegins) + (dateEnds != null ? (" &ndash; " + df.format(dateEnds)) : "") + "");

    //status = cms.contentshow(container, "Status");
    //out.println("<p>Status: " + STATUS[Integer.valueOf(status)] + "</p>");

    // Programme
    /*I_CmsXmlContentContainer programme = cms.contentloop(container, "Programme");
    while (programme.hasMoreContent()) {
        programmeTitle = cms.contentshow(programme, "Text");
        programmeUri = cms.contentshow(programme, "URI");
        if (CmsAgent.elementExists(programmeTitle)) {
            if (CmsAgent.elementExists(programmeUri))
                programmeTitle = "<a href=\"" + programmeUri + "\">" + programmeTitle + "</a>";
            out.println("<br /><strong>Forskningsprogram</strong>: " + programmeTitle);
        }
    }*/

    // Area
    area = cms.contentshow(container, "Area");
    if (CmsAgent.elementExists(area))
        out.println("<br /><strong>Område</strong>: " + area);

    // Website
    I_CmsXmlContentContainer website = cms.contentloop(container, "Website");
    while (website.hasMoreContent()) {
        websiteTitle = cms.contentshow(website, "Text");
        websiteUri = cms.contentshow(website, "URI");
        if (CmsAgent.elementExists(websiteUri)) {
            if (!CmsAgent.elementExists(websiteTitle))
                websiteTitle = title;
            out.println("<br /><strong>Nettsted</strong>: <a href=\"" + websiteUri + "\">" + websiteTitle + "</a>");
        }
    }

    // People
    I_CmsXmlContentContainer people = cms.contentloop(container, "Leaders");
    while (people.hasMoreContent()) {
        personFirstName = cms.contentshow(people, "FirstName");
        personLastName = cms.contentshow(people, "LastName");
        // Require both first and last name
        if (CmsAgent.elementExists(personFirstName) && CmsAgent.elementExists(personLastName)) {
            personName = personFirstName + " " + personLastName;
            personUri = cms.contentshow(people, "URI");
            String person = personName;
            if (CmsAgent.elementExists(personUri)) {
                person = "<a href=\"" + personUri + "\">" + person + "</a>";
            }
            if (!person.isEmpty()) {
                // Add leader
                leadersStr.add(person);
            }
        }
        // Reset variables
        personFirstName = null;
        personLastName = null;
        personName = null;
        personUri = null;
    }
    people = cms.contentloop(container, "Participants");
    while (people.hasMoreContent()) {
        personFirstName = cms.contentshow(people, "FirstName");
        personLastName = cms.contentshow(people, "LastName");
        // Require both first and last name
        if (CmsAgent.elementExists(personFirstName) && CmsAgent.elementExists(personLastName)) {
            personName = personFirstName + " " + personLastName;
            personUri = cms.contentshow(people, "URI");
            String person = personName;
            if (CmsAgent.elementExists(personUri)) {
                // URI existed, wrap name in link
                person = "<a href=\"" + personUri + "\">" + person + "</a>";
            }
            if (!person.isEmpty()) {
                // Add participant
                participantsStr.add(person);
            }
        }
        // Reset variables
        personFirstName = null;
        personLastName = null;
        personName = null;
        personUri = null;
    }

    if (!leadersStr.isEmpty()) {
        out.println("<br /><strong>Leder" + (leadersStr.size() > 1 ? "e" : "") + "</strong>: ");
        Iterator<String> iLeaders = leadersStr.iterator();
        while (iLeaders.hasNext()) {
            out.print(iLeaders.next());
            if (iLeaders.hasNext())
                out.print(", ");
        }
    }
    if (!participantsStr.isEmpty()) {
        out.println("<br /><strong>Deltaker" + (participantsStr.size() > 1 ? "e" : "") + "</strong>: ");
        Iterator<String> iParticipants = participantsStr.iterator();
        while (iParticipants.hasNext()) {
            out.print(iParticipants.next());
            if (iParticipants.hasNext())
                out.print(", ");
        }
    }
    //out.println("<br />Test");out.println("<br />Test");out.println("<br />Test");out.println("<br />Test");out.println("<br />Test");out.println("<br />Test");out.println("<br />Test");

    //
    // Categories
    //

    // This map will hold the categories to display. The top-level parent category is the key (heading), while all bottom-level child categories are in the "actual" categories
    Map<String, List> categoriesToDisplay = new HashMap<String, List>();
    CmsCategoryService cs = CmsCategoryService.getInstance();
    // Get the "top level" categories, e.g. a list containing "Research programme" and "Theme"
    List<CmsCategory> topLevelCategories = cs.readCategories(cmso, null, false, CmsResource.getParentFolder(resourceUri));
    // Get all of this project's categories
    List<CmsCategory> resourceCategories = cs.readResourceCategories(cmso, resourceUri);
    Iterator<CmsCategory> iResCats = resourceCategories.iterator();
    while (iResCats.hasNext()) {
        // Get the single category
        CmsCategory resCat = iResCats.next();
        if (topLevelCategories.contains(resCat)) { // Then this is a "top level" category, like "Research programme" or "Theme"
            // Store the top-level category in the map as a key. (Key for all its child categories.) It will be used as a heading on screen.
            if (!categoriesToDisplay.containsKey(resCat.getTitle()))
                categoriesToDisplay.put(resCat.getTitle(), new ArrayList<CmsCategory>());
        } 
        else { // Not a "top level" category
            // Get the category's "top level" (parent) category:
            CmsCategory topLevelCategory = matchCategoryOrParent(topLevelCategories, resCat, cmso, CmsResource.getParentFolder(resourceUri));
            // Add the category under the correct top-level (parent) category
            categoriesToDisplay.get(topLevelCategory.getTitle()).add(resCat);
        }
    }
    // Display the categories: One line per map key, e.g. "Theme: Glaciers, Climate"
    if (!categoriesToDisplay.isEmpty()) {
        Iterator<String> iKeys = categoriesToDisplay.keySet().iterator();
        while (iKeys.hasNext()) {
            String key = iKeys.next(); // This is the title of the top-level (parent) category - we'll use it only as a heading
            List val = categoriesToDisplay.get(key); // This is all it's child categories

            if (!val.isEmpty()) {
                out.print("<br /><strong>" + key + "</strong>: ");
                Iterator<CmsCategory> iCat = val.iterator();
                while (iCat.hasNext()) {
                    out.print(iCat.next().getTitle());
                    if (iCat.hasNext())
                        out.print(", ");
                }
            }
        }
    }
    //
    // Done with categories
    //



    out.println("</div>");
    out.println("</div>");

    // Featured image
    I_CmsXmlContentContainer image = cms.contentloop(container, "Image");
    while (image.hasMoreContent()) {
        imageUri = cms.contentshow(image, "URI");
        imageAlt = cms.contentshow(image, "Title");
        imageCaption = cms.contentshow(image, "Text");
        imageSource = cms.contentshow(image, "Source");
        imageSize = cms.contentshow(image, "Size");
        imageType = cms.contentshow(image, "ImageType");
        imageFloat = cms.contentshow(image, "Float");
    }

    //
    // Paragraphs, handled by a separate file
    //
    cms.include(PARAGRAPH_HANDLER);
    /*
    // People
    I_CmsXmlContentContainer people = cms.contentloop(container, "Leader");
    while (people.hasMoreContent()) {
        personTitle = cms.contentshow(people, "Text");
        personUri = cms.contentshow(people, "URI");
        String leader = personTitle;
        if (CmsAgent.elementExists(personUri))
            leader = "<a href=\"" + personUri + "\">" + leader + "</a>";
        // Add leader to list
        leadersStr.add(leader);
        // Reset
        personTitle = null;
        personUri = null;
    }
    people = cms.contentloop(container, "Participant");
    while (people.hasMoreContent()) {
        personTitle = cms.contentshow(people, "Text");
        personUri = cms.contentshow(people, "URI");
        String leader = personTitle;
        if (CmsAgent.elementExists(personUri))
            leader = "<a href=\"" + personUri + "\">" + leader + "</a>";
        // Add leader to list
        participantsStr.add(leader);
        // Reset
        personTitle = null;
        personUri = null;
    }

    if (!leadersStr.isEmpty()) {
        out.println("<h4 style=\"margin-bottom:0;\">Leader" + (leadersStr.size() > 1 ? "s" : "") + "</h4>");
        Iterator<String> iLeaders = leadersStr.iterator();
        while (iLeaders.hasNext()) {
            out.print(iLeaders.next());
            if (iLeaders.hasNext())
                out.print(", ");
        }
    }
    if (!participantsStr.isEmpty()) {
        out.println("<h4 style=\"margin-bottom:0;\">Participant" + (participantsStr.size() > 1 ? "s" : "") + "</h4>");
        Iterator<String> iParticipants = participantsStr.iterator();
        while (iParticipants.hasNext()) {
            out.print(iParticipants.next());
            if (iParticipants.hasNext())
                out.print(", ");
        }
    }
    */
    // Partners
    List<String> partners = new ArrayList<String>();
    String partnerTitle, partnerUri;
    I_CmsXmlContentContainer partner = cms.contentloop(container, "Partner");
    while (partner.hasMoreContent()) {
        partnerTitle = cms.contentshow(partner, "Text");
        partnerUri = cms.contentshow(partner, "URI");
        if (CmsAgent.elementExists(partnerUri)) {
            partners.add("<a href=\"" + partnerUri + "\">" + partnerTitle + "</a>");
        }
        else
            partners.add(partnerTitle);
    }
    Iterator<String> iPartners = partners.iterator();
    if (iPartners.hasNext()) {
        out.println("<h3>Samarbeidspartnere</h3>");
        out.println("<ul>");
        while (iPartners.hasNext()) {
            out.print("<li>" + iPartners.next() + "</li>");
        }
        out.println("</ul>");
    }
}

// Include lower part of main template
cms.include(template, elements[1], EDITABLE_TEMPLATE);
}
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
else if (JSON) {
    Map params = new HashMap();
    params.put("file", resourceUri);
    cms.include("export-json.jsp", null, params);
}
%>