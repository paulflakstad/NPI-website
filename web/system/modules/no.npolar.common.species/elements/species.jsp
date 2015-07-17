<%-- 
    Document   : species
    Created on : May 8, 2013, 12:34:03 PM
    Author     : flakstad
--%><%@ page import="no.npolar.util.CmsAgent,
                 no.npolar.util.contentnotation.*,
                 java.util.Locale,
                 java.util.Date,
                 java.util.List,
                 java.util.ArrayList,
                 java.util.Iterator,
                 java.util.Map,
                 java.util.HashMap,
                 java.util.Arrays,
                 java.net.*,
                 java.io.*,
                 java.util.regex.*,
                 java.text.SimpleDateFormat,
                 javax.xml.parsers.*,
                 org.apache.commons.lang.StringEscapeUtils,
                 org.w3c.dom.*,
                 org.opencms.jsp.I_CmsXmlContentContainer,
                 org.opencms.file.CmsObject,
                 org.opencms.file.CmsUser,
                 org.opencms.file.CmsResource,
                 org.opencms.relations.CmsCategoryService,
                 org.opencms.relations.CmsCategory,
                 org.opencms.util.CmsUUID" session="true" %><%!
                 
/**
* Gets an exception's stack strace as a string.
*/
public String getStackTrace(Exception e) {
    String trace = "";
    StackTraceElement[] ste = e.getStackTrace();
    for (int i = 0; i < ste.length; i++) {
        StackTraceElement stElem = ste[i];
        trace += stElem.toString() + "<br />";
    }
    return trace;
}

public String getRedListId(String uri) {
    String rlid = "";
    if (uri == null || uri.isEmpty())
        return "Error: Attempting to extract ID from empty or null string.";
    
    if (uri.contains("/"))
        rlid = uri.substring(uri.lastIndexOf("/") + 1).trim();
    
    try {
        return String.valueOf(Integer.valueOf(rlid));
    } catch (NumberFormatException e) {
        return "ERROR: " + e.getMessage();
    }
}

public String getXMLNodeTextValue(Element doc, String tag) {
    String value = null;
    NodeList nl = doc.getElementsByTagName(tag);
    if (nl.getLength() > 0 && nl.item(0).hasChildNodes()) {
        value = nl.item(0).getFirstChild().getNodeValue();
    }
    return value;
}

public String getXMLNodeTextValueMatchAttr(Element doc, String tag, String attrName, String attrVal) {
    String value = null;
    NodeList nl = doc.getElementsByTagName(tag);
    
    for (int i = 0; i < nl.getLength(); i++) {
        Node n = nl.item(i);
        if (n.hasAttributes()) {
            NamedNodeMap attr = n.getAttributes();
            if (attr.getNamedItem(attrName).getTextContent().equals(attrVal))
                return n.getFirstChild().getNodeValue();
        }
    }
    
    return null;
}
%><%
// Action element and CmsObject
CmsAgent cms                        = new CmsAgent(pageContext, request, response);
CmsObject cmso                      = cms.getCmsObject();
// Commonly used variables
String requestFileUri               = cms.getRequestContext().getUri();
String requestFolderUri             = cms.getRequestContext().getFolderUri();
Locale locale                       = cms.getRequestContext().getLocale();
String loc                          = locale.toString();

HttpSession sess                    = cms.getRequest().getSession(true);

// Common page element handlers
final String PARAGRAPH_HANDLER      = "../../no.npolar.common.pageelements/elements/paragraphhandler.jsp";
final String LINKLIST_HANDLER       = "../../no.npolar.common.pageelements/elements/linklisthandler.jsp";
final String ADDITIONAL_NAV_HANDLER = "../../no.npolar.site.npweb/elements/additional-navigation-handler.jsp";
//final String SHARE_LINKS            = "../../no.npolar.site.npweb/elements/share-addthis-" + loc + ".txt";
//final String SHARE_LINK_MIN         = "../../no.npolar.site.npweb/elements/share-link-min-" + loc + ".txt";

// Direct edit switches
final boolean EDITABLE              = false;
final boolean EDITABLE_TEMPLATE     = false;
// Comments?
final boolean COMMENTS              = false;
// Labels
final String LABEL_BY               = cms.labelUnicode("label.np.by");
final String LABEL_LAST_MODIFIED    = cms.labelUnicode("label.np.lastmodified");
final String PAGE_DATE_FORMAT       = cms.labelUnicode("label.np.dateformat.normal");

final Map<String, String> redListStatusLabel = new HashMap<String, String>();
redListStatusLabel.put("ex", cms.labelUnicode("label.species.redlist.ex"));
redListStatusLabel.put("ew", cms.labelUnicode("label.species.redlist.ew"));
redListStatusLabel.put("re", cms.labelUnicode("label.species.redlist.re"));
redListStatusLabel.put("cr", cms.labelUnicode("label.species.redlist.cr"));
redListStatusLabel.put("en", cms.labelUnicode("label.species.redlist.en"));
redListStatusLabel.put("vu", cms.labelUnicode("label.species.redlist.vu"));
redListStatusLabel.put("nt", cms.labelUnicode("label.species.redlist.nt"));
redListStatusLabel.put("dd", cms.labelUnicode("label.species.redlist.dd"));
redListStatusLabel.put("lc", cms.labelUnicode("label.species.redlist.lc"));
redListStatusLabel.put("ne", cms.labelUnicode("label.species.redlist.ne"));
redListStatusLabel.put("na", cms.labelUnicode("label.species.redlist.na"));

// File information variables
String byline                       = null;
String author                       = null;
String authorMail                   = null;
//String shareLinksString             = null;
//boolean shareLinks                  = false;
// XML content containers
I_CmsXmlContentContainer container  = null;
// String variables for structured content elements
String pageTitle                    = null;
String pageIntro                    = null;
String redListStatus                = null;
String redListLink                  = null;
String redListInfo                  = null;
boolean redListSvalbardSpecific     = false;
// Include-file variables
String includeFile                  = cms.property("template-include-file");
boolean wrapInclude                 = cms.property("template-include-file-wrap") != null ?
                                            (cms.property("template-include-file-wrap").equalsIgnoreCase("outside") ? false : true) : true;
// Template ("outer" or "master" template)
String template                     = cms.getTemplate();
String[] elements                   = cms.getTemplateIncludeElements();

final boolean SPECIES_PAGE          = requestFolderUri.startsWith(loc.equalsIgnoreCase("no") ? "/no/arter/" : "/en/species/"); // The parent folder containing all species pages
final String TITLE_RED_LIST_STATUS  = cms.labelUnicode("label.species.redlist.status"); // The title for the "Red List status" category
final String RED_LIST_STATUS_PATH   = "redlist/"; // The (relative) path to the "Red List status" category


//
// Include upper part of main template
//
cms.include(template, elements[0], EDITABLE_TEMPLATE);

// IMPORTANT: Do this *after* calling the outer template!
ContentNotationResolver cnr = null;
try {
    cnr = (ContentNotationResolver)session.getAttribute(ContentNotationResolver.SESS_ATTR_NAME);
    //out.println("\n\n<!-- Content notation resolver resolver ready - " + cnr.getGlobalFilePaths().size() + " global files loaded. -->");
} catch (Exception e) {
    out.println("\n\n<!-- Content notation resolver needs to be initialized before it can be used. -->");
}

//
// Get file creation and last modification info
//
CmsResource reqFile = cmso.readResource(requestFileUri);
CmsUser creatorUser = cmso.readUser(reqFile.getUserCreated()); // Get the user who created the file
CmsUser modUser = cmso.readUser(reqFile.getUserLastModified()); // Get the user who modified the file
String creatorName  = creatorUser.getFirstname() + " " + creatorUser.getLastname();
String modifierName = modUser.getFirstname() + " " + modUser.getLastname();
Date modifiedDate = new Date(reqFile.getDateLastModified()); // Create dates (representing the moment in time they are created. These objects are changed below.)
Date createdDate = new Date(reqFile.getDateCreated());
SimpleDateFormat dFormat = new SimpleDateFormat(PAGE_DATE_FORMAT, locale); // Create the desired output format
//out.println("Created by " + creatorName + " at " + dFormat.format(createdDate) + ".");
//out.println("Last modified by " + modifierName + " at " + dFormat.format(modifiedDate) + ".");


// Load the file
container = cms.contentload("singleFile", "%(opencms.uri)", EDITABLE);
// Set the content "direct editable" (or not)
cms.editable(EDITABLE);

//
// Process file contents
//
while (container.hasMoreContent()) {
    //out.println("<div class=\"page\">"); // REMOVED <div class="page">
    
    out.println("<article class=\"main-content\">");
    
    pageTitle = cms.contentshow(container, "PageTitle");
    pageIntro = cms.contentshow(container, "Intro");
    author = cms.contentshow(container, "Author");
    authorMail = cms.contentshow(container, "AuthorMail");
    /*shareLinksString= cms.contentshow(container, "ShareLinks");
    if (!CmsAgent.elementExists(shareLinksString))
        shareLinksString = "false"; // Default value if this element does not exist in the file (backward compatibility)

    try {
        shareLinks      = Boolean.valueOf(shareLinksString).booleanValue();
    } catch (Exception e) {
        shareLinks = false; // Default value if above line fails (it shouldn't, but just to be safe...)
    }*/
    
    // Author and/or translator names - print them as mailto-links if e-mail addresses are present
    //if (CmsAgent.elementExists(author) || shareLinks) {
    if (CmsAgent.elementExists(author)) {
        byline = "<div class=\"byline\">";
        if (CmsAgent.elementExists(author)) {
            byline += "<div class=\"names\">";
            author = CmsAgent.removeUsername(author); // I.e. convert "Paul Flakstad (paul)" to "Paul Flakstad"
            byline += LABEL_BY + " ";
            byline += (CmsAgent.elementExists(authorMail) ? ("<a href=\"mailto:" + authorMail + "\">" + author + "</a>") : author);
            //byline += "&nbsp;&ndash;&nbsp;"; // Dash between name(s) and timestamp
            byline += "</div><!-- .names -->";
        }
        /*if (shareLinks) {
            byline += cms.getContent(SHARE_LINK_MIN);
        }*/
        byline += "</div><!-- .byline -->";
    }

    if (CmsAgent.elementExists(authorMail)) {
        byline = CmsAgent.obfuscateEmailAddr(byline, false);
    }
    
    //
    // Red List status
    //
    redListStatus = cms.contentshow(container, "RedListStatus");
    redListLink = cms.contentshow(container, "RedListLink");
    if (CmsAgent.elementExists(redListStatus)) {
        if (redListStatus.equalsIgnoreCase("auto")) {
            if (CmsAgent.elementExists(redListLink)) {
                String redListLinkUrl = redListLink;
                try {
                    if (redListLinkUrl.startsWith("http://www.artsportalen.artsdatabanken.no/#/")) {
                        redListLinkUrl = redListLinkUrl.replace("http://www.artsportalen.artsdatabanken.no/#/", "http://www.artsportalen.artsdatabanken.no/");
                    }
                    
                    //out.println("<!-- Red List ID: " + getRedListId(redListLink) + " -->");
                    
                    // NEW VERSION: USING SERVICE
                    String serviceUrl = "http://webtjenester.artsdatabanken.no/Rodlistebase2010.asmx/Rodlistevurdering?Key=&RodlisteID=" + getRedListId(redListLink);
                    
                    HttpURLConnection serviceConn = (HttpURLConnection) new URL (serviceUrl).openConnection();
                    serviceConn.connect();
                    
                    if (serviceConn.getResponseCode() == 200) {
                        // Parse XML
                        InputStream is                      = new URL(serviceUrl).openStream(); // Create an input stream for the XML data
                        DocumentBuilderFactory domFactory   = DocumentBuilderFactory.newInstance(); // A DOM factory
                        domFactory.setNamespaceAware(true); // Be aware - never forget this!
                        DocumentBuilder builder             = domFactory.newDocumentBuilder(); // DOM builder
                        Document doc                        = builder.parse(is); // Parse the XML from stream

                        if (COMMENTS) {
                            out.println("<!-- Fetched XML and created DOM. -->");
                            out.println("<!-- Arranging XML elements ... -->");
                        }

                        Element docEl = doc.getDocumentElement();
                        
                        redListStatus =  getXMLNodeTextValueMatchAttr(docEl, "Kategori", "Aar", "2010");
                        
                        try { redListSvalbardSpecific = getXMLNodeTextValue(docEl, "Ekspertgruppe").contains("Svalbard"); } catch (Exception e) { }
                        try { redListInfo = getXMLNodeTextValue(docEl, "Kriteriedokumentasjon"); } catch (Exception e) { }
                    }
                    // END NEW VERSION
                    
                    
                    // BEGIN OLD VERSION
                    /*
                    HttpURLConnection httpConn = (HttpURLConnection) new URL (redListLinkUrl).openConnection();
                    httpConn.connect();
                    
                    int responseCode = httpConn.getResponseCode();

                    // Get the Red List status code from the linked page
                    if (responseCode == 200) {
                        Pattern p = Pattern.compile("<span class=\"kategori\\s+[A-Z]{2}\">[A-Z]{2}°?</span>"); // This is what we're interested in
                        BufferedReader in = new BufferedReader(new InputStreamReader(httpConn.getInputStream()));
                        String inputLine;
                        out.println("<!--\nChecking Red List link (" + redListLink + ") for status code ...\n-->");
                        while ((inputLine = in.readLine()) != null) {
                            Matcher m = p.matcher(inputLine);
                            if (m.find()) {
                                String match = inputLine.substring(m.start(), m.end()); // This string will hold the entire span, e.g. <span class="kategori LC">LC</span>
                                out.println("<!-- \nFound status code: " + match + "! \n-->");
                                redListStatus = CmsAgent.getTagStringValue(match).toLowerCase().substring(0,2); // Extract only the Red List code, e.g. LC
                                break;
                            }
                        }
                        in.close();
                    } else {
                        out.println("<!--\nERROR processing Red List link returned response code " + responseCode + "\n-->");
                    }
                    */
                    // END OLD VERSION
                } catch (Exception e) {
                    out.println("<!--\nERROR processing Red List link: " + e.getMessage() + "\n-->");
                    redListStatus = cms.contentshow(container, "RedListStatus");
                    redListLink = cms.contentshow(container, "RedListLink");
                }
            } else {
                redListStatus = null;
            }
        }
    }
    
    
    /*
    if (CmsAgent.elementExists(author)) {
        author = CmsAgent.removeUsername(author);
        byline = "<div class=\"byline\">" + LABEL_BY + " ";
        byline += CmsAgent.elementExists(authorMail) ? ("<a href=\"mailto:" + authorMail + "\">" + author + "</a>") : author;
        //byline += " &ndash; " + LABEL_LAST_MODIFIED.toLowerCase() + " " + dFormat.format(modifiedDate);
        byline += "</div>";
        if (CmsAgent.elementExists(authorMail))
            byline = CmsAgent.obfuscateEmailAddr(byline, false);
    }
    */
    out.println(CmsAgent.elementExists(pageTitle) ? ("<h1>" + pageTitle + "</h1>") : "");
    if (byline != null)
        out.println(byline);
    if (CmsAgent.elementExists(redListStatus)) {
        out.print("<div class=\"redlist-status\"><p>");
        
        if (CmsAgent.elementExists(redListLink))
            out.print("<a href=\"" + redListLink + "\">");
        if (redListInfo != null)
            out.print("<span data-hoverbox=\"" + StringEscapeUtils.escapeHtml(redListInfo) + "\"><i class=\"icon-info-circled-1\"></i>");
        out.print(TITLE_RED_LIST_STATUS);
        if (redListSvalbardSpecific)
            out.print(" (Svalbard)");
        out.print(": " + redListStatus.toUpperCase() + " - " + cms.labelUnicode("label.species.redlist.".concat(redListStatus.substring(0, 2)).toLowerCase()));
        if (redListInfo != null)
            out.print("</span>");
        if (CmsAgent.elementExists(redListLink))
            out.print("</a>");
        out.println("</p></div>");
    }
    if (CmsAgent.elementExists(pageIntro))
        out.println("<div class=\"ingress\" id=\"page-summary\">" + pageIntro + "</div><!-- .ingress -->");

    //
    // Paragraphs, handled by a separate file
    //
    cms.include(PARAGRAPH_HANDLER);
    
    //*
    //
    // MOSJ indicators
    // 
    //String keyword = pageTitle.split("\\s")[0]; // Get the first word in the title (this should be the "regular" species name) -- this won't do, use keyword(s) instead
    String keywordsStr = cms.contentshow(container, "MOSJKeyword");
    if (CmsAgent.elementExists(keywordsStr)) {
        List<String> keywords = new ArrayList<String>(Arrays.asList(keywordsStr.split(";")));
        Iterator<String> iKeywords = keywords.iterator();

        String indUri = "/system/modules/no.npolar.common.species/elements/species-mosj-indicators.jsp?"
                + "locale=" + loc;
        if (!keywords.isEmpty()) {
            while (iKeywords.hasNext())
                indUri += "&keyword=" + iKeywords.next().replaceAll("\\s", "%20");
        }

        //out.println("<!-- Looking up MOSJ indicators using keyword '" + keyword + "' ... -->");
        out.println("<div class=\"paragraph\">");
        out.println("<h3>" + cms.labelUnicode("label.species.mosjindicators.head") + ":</h3>");
        out.println("<div id=\"mosj-indicators\">");
        out.println("<p><img align=\"left\" src=\"/system/modules/no.npolar.site.npweb/resources/style/loader.gif\" alt=\"\" /> " + cms.labelUnicode("label.species.mosjindicators.loading") + "</p>");
        out.println("</div>");
        out.println("<script type=\"text/javascript\">");
        //out.println("$(\"#mosj-indicators\").load(\"/no/arter/_test-mosj-indicator-list.jsp?keyword=" + keyword + "&amp;locale="+loc + "\");");
        out.println("$(\"#mosj-indicators\").load(\"" + cms.link(indUri) + "\");");
        out.println("</script>");
        out.println("</div>");
        //*/
    }
    
    // Extension
    if (includeFile != null && wrapInclude) {
        out.println("<!-- Extension found (wrap inside): '" + includeFile + "' -->");
        cms.includeAny(includeFile, "resourceUri");
    }

    
    cms.include("/system/modules/no.npolar.common.pageelements/elements/cn-reflist.jsp");
    
    
    /*if (shareLinks) {
        out.println(cms.getContent(SHARE_LINKS));
        //request.setAttribute("share", "true");
        sess.setAttribute("share", "true");
    }*/
    
    
    out.println("</article><!-- .main-content -->");
    out.println("<div id=\"rightside\" class=\"column small\">");
    
    //
    // Handle additional navigation - used by "big events" (big event = an event with multiple pages)
    //
    //cms.include(ADDITIONAL_NAV_HANDLER);
    String navAddPath = cmso.readPropertyObject(requestFileUri, "menu-file-additional", true).getValue("");
    if (!navAddPath.isEmpty()) {
        cms.includeAny(navAddPath, "resourceUri");
    }
    
    //
    // Pre-defined and generic link lists, handled by a separate file
    //
    //request.setAttribute("autoRelatedPages", "true"); // Must be set to let the linklist handler know we want to list the fact pages
    sess.setAttribute("autoRelatedPages", "true"); // Must be set to let the linklist handler know we want to list the fact pages
    cms.include(LINKLIST_HANDLER);
    out.println("</div><!-- #rightside -->");
    
    
    
    
    /* // REMOVED <div class="page">
    // If the include file should NOT be wrapped inside the ivorypage content div
    if (!wrapInclude)
        out.println("</div><!-- .page -->");
    */

    // Include file from property "template-include-file"
    if (includeFile != null && !wrapInclude) {
        out.println("<!-- Extension found (don't wrap inside): '" + includeFile + "' -->");
        cms.includeAny(includeFile, "resourceUri");
    }
    /* // REMOVED <div class="page">
    // If the include should be wrapped inside the ivorypage content div
    if (wrapInclude)
        out.println("</div><!-- .page (or script div) -->");
    */

} // While container.hasMoreContent()

cms.include("/system/modules/no.npolar.common.pageelements/elements/cn-pageindex.jsp");


//
// Include lower part of main template
//
cms.include(template, elements[1], EDITABLE_TEMPLATE);
%>