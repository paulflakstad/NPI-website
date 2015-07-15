<%-- 
    Document   : linklisthandler.jsp - Common linklist template
    Created on : 03.jun.2010, 19:52:03
    Author     : Paul-Inge Flakstad <flakstad at npolar.no>
--%>
<%@ page import="no.npolar.util.*,
                 java.util.Arrays,
                 java.util.Locale,
                 java.util.HashMap,
                 java.util.SortedMap,
                 java.util.TreeMap,
                 java.util.List,
                 java.util.Iterator,
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
        //out.println("<!-- Encoding determined as: '" + enc + "' -->");
    } else {
        enc = "utf-8";
        //out.println("<!-- Encoding could not be determined, fallback to '" + enc + "' -->");
    }

    StringBuffer contentBuffer = new StringBuffer(1024);
    //BufferedReader in = new BufferedReader(new InputStreamReader(conn.getInputStream())); // No particular encoding
    BufferedReader in = new BufferedReader(new InputStreamReader(conn.getInputStream(), enc.toLowerCase())); // Particular encoding
    String inputLine;
    while ((inputLine = in.readLine()) != null) {
        //System.out.println(inputLine);
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
* Generates the HTML code for the items (links) in the list.
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
        //out.println("<li><em>Sorted alphabetically:</em></li>");
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
*/
public String getLinkListHtml(String linkListTitle, String listItems) {
    String html = "";
    //html += "<div class=\"link-group\">";
    if (linkListTitle != null)
        html += "<h4>" + linkListTitle + "</h4>";
    //html += "<ul class=\"linklist\">";
    html += "<ul>";
    // Add the items
    html += listItems;
    html += "</ul>";
    //html += "</div> <!-- link-group -->";
    
    return html;
}

%><%
CmsAgent cms                        = new CmsAgent(pageContext, request, response);
//CmsObject cmso                      = cms.getCmsObject();
final boolean EDITABLE              = false;


// Load the file
I_CmsXmlContentContainer container  = cms.contentload("singleFile", "%(opencms.uri)", EDITABLE);
while (container.hasMoreContent()) {
    I_CmsXmlContentContainer linkList = null;
    String linkListTitle = null;
    String listOrder = null;
    
    
    
    
    //
    // Generic link lists - same routine as above, but with an additional list heading
    //
    
    linkList = cms.contentloop(container, "OtherLinks");
    while (linkList.hasMoreContent()) {
        // Get the list title and order
        linkListTitle = cms.contentshow(linkList, "Title").replaceAll(" & ", " &amp; ");
        listOrder = cms.contentshow(linkList, "ListOrder");
        out.println(getLinkListHtml(linkListTitle, getListItems(cms, linkList, listOrder)));
    }
    
    //
    // Done with the generic link lists
    //
       
    //
    // Pre-defined link lists
    //
    
    // A list of the XSD element names of the pre-defined lists, and an iterator
    List<String> preDefinedLinkLists = Arrays.asList("Attachments", "RelatedPages", "FactSheets", "ExternalLinks");
    Iterator preDefItr = preDefinedLinkLists.iterator();
    
    // Iterate over the list of pre-defined link lists
    while (preDefItr.hasNext()) {
        // Get the name of the pre-defined link list element (the XSD element name, e.g. "Attachments")
        String preDefinedLinkList = (String)preDefItr.next();
        // Make a container for the list
        linkList = cms.contentloop(container, preDefinedLinkList);
        // NOTE: For the next line of code to work, the label key _must_ be the lower-case of the XSD element name
        linkListTitle = cms.labelUnicode("label.np.".concat(preDefinedLinkList.toLowerCase())); 
           
        // Process the list
        while (linkList.hasMoreContent()) {
            // Get the list order
            listOrder = cms.contentshow(linkList, "ListOrder");
            out.println(getLinkListHtml(linkListTitle, getListItems(cms, linkList, listOrder)));
        }
    } // while-loop for pre-defined link lists
    
    //
    // Done with pre-defined link lists
    // 
}
%>