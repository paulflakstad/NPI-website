<%-- 
    Document   : linklisthandler.jsp - Common linklist template
    Created on : 03.jun.2010, 19:52:03
    Author     : Paul-Inge Flakstad <flakstad at npolar.no>
--%>
<%@ page import="no.npolar.util.*,
                 java.util.Arrays,
                 java.util.ArrayList,
                 java.util.Locale,
                 java.util.HashMap,
                 java.util.SortedMap,
                 java.util.TreeMap,
                 java.util.List,
                 java.util.Iterator,
                 org.opencms.file.CmsResource,
                 org.opencms.main.CmsException,
                 org.opencms.jsp.I_CmsXmlContentContainer,
                 org.opencms.file.CmsObject,
                 java.net.URLConnection,
                 java.net.URL,
                 java.io.InputStreamReader,
                 java.io.BufferedReader" session="true" 
%><%!
/**
* Gets a title value, by reading either the Title property (local files) or the html title tag (external files).
*/
public String getTitleValue(String url) throws java.io.IOException {
    URLConnection conn = new URL(url).openConnection();
    String enc = conn.getHeaderField("Content-Type"); // e.g.: 'text/html; charset=UTF-8'
    if (enc.indexOf("=") > -1) {
        enc = enc.substring(enc.indexOf("=") + 1); // extract the substring 'UTF-8'
    } else {
        enc = "utf-8";
    }

    StringBuffer contentBuffer = new StringBuffer(1024);
    //BufferedReader in = new BufferedReader(new InputStreamReader(conn.getInputStream())); // No particular encoding
    BufferedReader in = new BufferedReader(new InputStreamReader(conn.getInputStream(), enc.toLowerCase())); // Particular encoding
    String inputLine;
    while ((inputLine = in.readLine()) != null) {
        contentBuffer.append(inputLine);
        if (inputLine.contains("</title>"))
            break;
    }
    in.close();
    String content = contentBuffer.toString();
    // Extract the string inside the <title> tag
    content = content.substring(0, content.indexOf("</title>"));
    String titleValue = content.substring(content.indexOf("<title>") + 7); // 7 is the length of "<title>"
    return titleValue;
}

/**
* Gets an exception's stack trace, as a string.
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

/**
* Generates the HTML code for the items (links) in the "FactPages" list.
*/
public String getFactPages(CmsAgent cms, I_CmsXmlContentContainer linkList) throws JspException, CmsException {
    String html = "";
    
    while (linkList.hasMoreContent()) {
        String uri = cms.contentshow(linkList);
        html += "<li><a href=\"" + uri + "\">" + cms.property("Title", uri, "[No title]") + "</a></li>";
    }
    
    return html;
}


/**
* Generates the HTML code for the items (links) in all list other than the "FactPages" list.
*/
public String getListItems(CmsAgent cms, I_CmsXmlContentContainer linkList, String listOrder) throws JspException, CmsException {
    String listItems = "";
    String linkUri, linkTitle;
    boolean linkNewWindow;
        
    int unknownTitleEncountered = 0;
    SortedMap mapping = new TreeMap();
    
    // The label used for when no title is given and no title can be resolved
    final String LABEL_UNKNOWN_TITLE = cms.labelUnicode("label.linklist.unknowntitle") + ": ";//"Ukjent tittel: ";
    // The string value of the "alphabetically" option in the list config (must correspond to the XSD)
    final String LABEL_LIST_ORDER_ALPHABETICALLY = "Alphabetically";

    // Make a container for the links
    I_CmsXmlContentContainer links = cms.contentloop(linkList, "LinkListLink");
    // Process each link
    while (links.hasMoreContent()) {
        // Get the URI
        linkUri = cms.contentshow(links, "URI");
        //linkImageUri = cms.contentshow(links, "ImageURI");
        // Get the title (the link text)
        linkTitle = cms.contentshow(links, "Title");
        // Get the "new window/tab" switch
        linkNewWindow = Boolean.valueOf(cms.contentshow(links, "NewWindow")).booleanValue();

        // If no title was found, try to resolve the title by looking at
        // 1) The "Title" property, if the file is locally stored OR
        // 2) The <title> tag, if the file is external
        if (!cms.elementExists(linkTitle)) {
            // Local file:
            if (cms.getCmsObject().existsResource(linkUri)) {
                // Read the title from the "Title" property
                linkTitle = cms.getCmsObject().readPropertyObject(linkUri, "Title", false).getValue();
                // Remove "labels" from start of title
                String [] removeThis = { "Faktaark: ", "Fact sheet: " };
                for (int i = 0; i < removeThis.length; i++) {
                    if (linkTitle.startsWith(removeThis[i])) 
                        linkTitle = linkTitle.substring(removeThis[i].length());
                }
            } 

            // External file:
            else {
                // Try to read the html <title> tag of the external linkList
                try {
                    linkTitle = getTitleValue(linkUri);
                } catch (Exception e) {
                    // Unable to read the title from the URL
                    //linkTitle = LABEL_UNKNOWN_TITLE;
                    linkTitle = LABEL_UNKNOWN_TITLE + linkUri;
                    //throw new NullPointerException(e.getMessage());
                }
            }
        }

        // Create the complete link tag, wrapped in a <li> for placement in an html list
        String linkTag = "<li><a href=\"" + cms.link(linkUri.replaceAll("&", "&amp;")) + "\"" + (linkNewWindow ? " target=\"_blank\"" : "") + ">" + 
                            // linkImageTag + 
                            linkTitle + 
                            "</a></li>";
        // If we're sorting alphabetically, place the link in a map for sorting.
        // The map's key is the link title, and the value is the complete html code for the link
        if (listOrder.equals(LABEL_LIST_ORDER_ALPHABETICALLY)) {
            // The key is either:
            // 1) The real title (if resolved in any way), OR 
            // 2) The unique key LABEL_UNKNOWN_TITLEXXX, where XXX is an integer representing the number of unknowns present prior to this one
            mapping.put(!linkTitle.equals(LABEL_UNKNOWN_TITLE) ? linkTitle : linkTitle.concat(Integer.toString(unknownTitleEncountered++)), 
                        linkTag);
        }
        // If we're not sorting alphabetically, print the link directly
        else {
            listItems += linkTag;
        }

    } // link loop

    // If the mapping is not empty, it means we're sorting alphabetically, and no links have been printed yet
    if (!mapping.isEmpty()) {
        // Get an iterator and iterate the entire map
        Iterator itr = mapping.keySet().iterator();
        while (itr.hasNext()) {
            // Print the link
            listItems += mapping.get(itr.next());
        }
    }
    return listItems;
}

/**
* Helper method to print the HTML code for a list.
* ToDo: FIX if-clause!!!
*/
public String getLinkListHtml(String linkListTitle, String listItems, String moreLinkUri, String moreLinkText) {
    String html = "";
    if (!listItems.isEmpty() || moreLinkUri != null) { // Require at least one of listItems OR moreLinkUri to be non-empty
        html += beginLinkListHtml(linkListTitle);
        //html += "<ul class=\"linklist\">";
        html += "<div class=\"toggleable\">";
        html += "<ul>";
        // Add the items
        html += listItems;
        if (moreLinkUri != null && moreLinkText != null) { // "More" link: Require both URI and text
            html += "<li><a href=\"" + moreLinkUri + "\"><em>" + moreLinkText + "</em></a></li>";
        }
        html += "</ul>";
        html += "</div>";
        html += endLinkListHtml();
    }
    return html;
}

public String beginLinkListHtml(String linkListTitle) {
    String html = "<h3 class=\"toggler-wrapper\">";
    html += "<a class=\"toggler\">";
    //html += "<aside>";
    if (linkListTitle != null) {
        html += linkListTitle;
    } else {
        html += "Related links";
    }
    html += "</a></h3>";
    return html;
}

public String endLinkListHtml() {
    //return "</aside>";
    return "";
}

/**
 * Gets a list of "auto-related" resources for a given resource.
 * @param relatedToUri The URI of the resource to find "auto-related" resources for
 */
public List getAutoRelatedResources(CmsObject cmso, String relatedToUri) throws CmsException {
    List list = cmso.readResourcesWithProperty("/", "uri.related"); 
    List<CmsResource> matches = new ArrayList<CmsResource>();

    Iterator itr = list.iterator();
    if (itr.hasNext()) {
        while (itr.hasNext()) {
            CmsResource r = (CmsResource)itr.next();
            String[] propStr = cmso.readPropertyObject(r, "uri.related", false).getValue("").split("\\|");
            for (int i = 0; i < propStr.length; i++) {
                if (propStr[i].equals(cmso.getRequestContext().getSiteRoot().concat(relatedToUri)))
                    matches.add(r);
            }
        }
    }
    return matches;
}

public String getAutoRelatedResourcesHtml(CmsObject cmso, String relatedToUri, int limitItems) throws CmsException {
    if (limitItems == -1)
        limitItems = Integer.MAX_VALUE;
    String html = "";
    List<CmsResource> resources = getAutoRelatedResources(cmso, relatedToUri);
    if (!resources.isEmpty()) {
        //html += "<ul>";
        int i = 0;
        Iterator<CmsResource> itr = resources.iterator();
        while (itr.hasNext() && i < limitItems) {
            CmsResource r = itr.next();
            html += "<li><a href=\"" + cmso.getSitePath(r) + "\">" + cmso.readPropertyObject(r, "Title", false).getValue("[NO TITLE]") + "</a></li>";
        }
        //html += "</ul>";
    }
    return html;
}

%><%
CmsAgent cms                        = new CmsAgent(pageContext, request, response);
CmsObject cmso                      = cms.getCmsObject();
String loc                          = cms.getRequestContext().getLocale().toString();
HttpSession sess                    = cms.getRequest().getSession(true);
final boolean EDITABLE              = false;
StringBuilder html                  = new StringBuilder(512);

final String LABEL_SEE_ALSO         = loc.equalsIgnoreCase("no") ? "Se også" : "See also";

// Get the URI for the current page
String currentPageUri = cms.getRequestContext().getUri();
if (currentPageUri.endsWith("/"))
    currentPageUri = currentPageUri + "index.html";


// Load the file
I_CmsXmlContentContainer container  = cms.contentload("singleFile", "%(opencms.uri)", EDITABLE);
while (container.hasMoreContent()) {
    I_CmsXmlContentContainer linkList = null;
    String linkListTitle = null;
    String listOrder = null;
    
    
    
    
    //
    // Custom link lists - same routine as above, but with an additional list heading
    //
    
    linkList = cms.contentloop(container, "OtherLinks");
    while (linkList.hasMoreContent()) {
        // Get the list title and order
        linkListTitle = cms.contentshow(linkList, "Title").replaceAll(" & ", " &amp; ");
        listOrder = cms.contentshow(linkList, "ListOrder");
        html.append(getLinkListHtml(linkListTitle, getListItems(cms, linkList, listOrder), null, null));
    }
    
    //
    // Done with the custom link lists
    //
       
    //
    // Pre-defined link lists
    //
    
    // A list of the XSD element names of the pre-defined lists, and an iterator
    List<String> preDefinedLinkLists = Arrays.asList("Attachments", "FactPages", "RelatedPages", "FactSheets", "MediaLinks", "ExternalLinks");
    Iterator preDefItr = preDefinedLinkLists.iterator();
    
    // "Auto-related" pages: pages that link to the current page as a "FactPage".
    // These should be listed along with "Related pages".
    List autoRelated = new ArrayList();
    boolean autoRelatedPages = false;
    try {
        // Not all pages should list auto-related pages, so a setting is needed.
        // The setting (true|false) is done using a request attribute:
        //autoRelatedPages = Boolean.valueOf((String)request.getAttribute("autoRelatedPages"));
        autoRelatedPages = Boolean.valueOf((String)sess.getAttribute("autoRelatedPages"));
    } catch (Exception e) {
        // Retain initial value
    } 
    // If the current page should list auto-related pages, collect the list now
    if (autoRelatedPages) {
        autoRelated = getAutoRelatedResources(cmso, currentPageUri);
        // Store the manually added related pages in the session (we'll use it in the moreLinkUri file)
        //cms.getRequest().getSession().setAttribute("manualRelatedPages", linkList); 
    }
    
    // Iterate over the list of all possible pre-defined link lists
    while (preDefItr.hasNext()) {
        // Get the name of the pre-defined link list element (the XSD element name, e.g. "Attachments")
        String preDefinedLinkList = (String)preDefItr.next();
        // Make a container for the list
        linkList = cms.contentloop(container, preDefinedLinkList);
        // NOTE: For the next line of code to work, the label key _must_ be the lower-case of the XSD element name
        linkListTitle = cms.labelUnicode("label.np.".concat(preDefinedLinkList.toLowerCase()));
        // "More" link for the list (to display after the last item)
        String moreLinkUri = null;
        String moreLinkText = null;
        
        if (!"FactPages".equals(preDefinedLinkList)) {
            if (preDefinedLinkList.equals("RelatedPages")) {
                if (autoRelatedPages) {
                    // Set up the "More" link - it should point to a complete list of pages linking to this one in their "FactPages" list
                    if (autoRelated.size() > 0) {
                        if (loc.equalsIgnoreCase("no")) {
                            moreLinkUri = "/no/relaterte-sider.html?uri=" + currentPageUri;
                            moreLinkText = "Vis alle relaterte sider (+" + autoRelated.size() + ")";
                        } 
                        else {
                            moreLinkUri = "/en/related-resources.html?uri=" + currentPageUri;
                            moreLinkText = "View all related pages (+" + autoRelated.size() + ")";
                        }
                        // Handle case: Element "RelatedPages" does not exist, but auto-related pages exist
                        if (!linkList.getXmlDocument().hasValue(preDefinedLinkList, cms.getRequestContext().getLocale())) { // Check if any "RelatedPages" links are present
                            //html.append("<!-- 'RelatedPages' did not exist, displaying only auto-related pages -->");
                            moreLinkText = (loc.equalsIgnoreCase("no") ? "Vis alle" : "View all") + " (" + autoRelated.size() + ")";
                            int maxItems = 4; // List this many auto-related pages directly
                            if (autoRelated.size() > maxItems) {
                                // Print a list of the N first auto-related pages + a link to the full list
                                html.append(getLinkListHtml(linkListTitle, getAutoRelatedResourcesHtml(cmso, currentPageUri, maxItems), moreLinkUri, moreLinkText));
                            }
                            else {
                                // Print all the auto-related pages (no need to link to the list itself)
                                html.append(getLinkListHtml(linkListTitle, getAutoRelatedResourcesHtml(cmso, currentPageUri, maxItems), null, null));
                            }
                        } else {
                            //html.append("<!-- 'RelatedPages' existed -->");
                        }
                    }
                }
            }
            // Process the list
            while (linkList.hasMoreContent()) {
                // Get the list order
                listOrder = cms.contentshow(linkList, "ListOrder");
                html.append(getLinkListHtml(linkListTitle, getListItems(cms, linkList, listOrder), moreLinkUri, moreLinkText));
            }
        }
        else {
            // Print the "Fact pages" link list
            html.append(getLinkListHtml(linkListTitle, getFactPages(cms, linkList), null, null));
        }
    } // while-loop for pre-defined link lists
    
    if (html.length() > 0) {
        %>
        <aside class="article-meta">
            <h2 class="article-meta__heading"><%= LABEL_SEE_ALSO %></h2>
            <div class="article-meta__content">
                <%= html.toString() %>
            </div>
        </aside>
        <%
    }
    
    //
    // Done with pre-defined link lists
    // 
}
%>