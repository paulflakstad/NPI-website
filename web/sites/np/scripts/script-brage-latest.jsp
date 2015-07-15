<%-- 
    Document   : script-brage-latest
    Created on : Jan 24, 2013, 2:47:27 PM
    Author     : flakstad
--%><%@page import="org.dom4j.*,
                org.dom4j.io.*,
                org.opencms.jsp.CmsJspActionElement,
                java.net.URL,
                java.util.List,
                java.util.Iterator,
                java.util.Date,
                java.util.Locale,
                java.text.SimpleDateFormat" %>
<%!
/**
 * Converts the RSS date node to a Date object.
 */
public Date getDateFromNode(Node dateNode) {
    final SimpleDateFormat RSS_DATE_FORMAT = new SimpleDateFormat("EEE, dd MMM yyyy hh:mm:ss Z"); 
    try {
        return RSS_DATE_FORMAT.parse(dateNode.getText());
    } catch (Exception e) {
        return null;
    }
}

public String getDescriptionFromNode(Node descrNode) {
    String descr = null;
    try {
        // Get the description text. It consists of the title, followed by 
        // the authors or editors, and sometimes an abstract. We want to strip
        // everything but the author/editor name(s), and we don't care if they
        // are authors or editors - we'll just list the names themselves.
        descr = descrNode.getText();
        // Get the substring starting after the "Authors:" label
        if (descr.contains("Authors:")) {
            descr = descr.substring(descr.indexOf("Authors:") + "Authors:".length());
            // Remove the abstract bit
            if (descr.contains("Abstract:"))
                descr = descr.substring(0, descr.indexOf("Abstract:"));
        }
        // Get the substring starting after the "Editors:" label
        else if (descr.contains("Editors:")) {
            descr = descr.substring(descr.indexOf("Editors:") + "Editors:".length());
            // Remove the abstract bit
            if (descr.contains("Abstract:"))
                descr = descr.substring(0, descr.indexOf("Abstract:"));
        }
        else
            throw new Exception();
    } catch (Exception e) {
        descr = "";
    }
    
    return descr;
}

/**
 * Gets the enclosure link details. The returned 
 */
public String[] getEnclosureFromNode(Node enclosureNode) {
    /*String url = enclosureNode.selectSingleNode(enclosureNode.getPath().concat("/@url")).getText();
    double length = Long.valueOf(enclosureNode.selectSingleNode(enclosureNode.getPath().concat("/@length")).getText()).longValue();
    String type = enclosureNode.selectSingleNode(enclosureNode.getPath().concat("/@type")).getText();*/
    
    String url = enclosureNode.selectSingleNode(enclosureNode.getUniquePath().concat("/@url")).getText();
    double length = Long.valueOf(enclosureNode.selectSingleNode(enclosureNode.getUniquePath().concat("/@length")).getText()).longValue();
    String type = enclosureNode.selectSingleNode(enclosureNode.getUniquePath().concat("/@type")).getText();
    
    String[] details = new String[3];
    details[0] = url;
    details[1] = Double.toString((double)Math.round((length / (1024*1024)) * 10) / 10); // Convert the "length" attribute to megabytes, defined with 1 decimal place. 
    details[2] = type;
    
    //String link = "<a href=\"" + details[0] + "\" target=\"_blank\">Download PDF (" + details[1] + " MB)</a>\n<!-- " + enclosureNode.getUniquePath() + "-->";
    return details;
}
%><%
CmsJspActionElement cms = new CmsJspActionElement(pageContext, request, response);
//if (cms.template("main")) {
    String loc = cms.getRequestContext().getLocale().toString();
    
    String url = cms.getRequest().getParameter("url");
    String dateFormat = cms.getRequest().getParameter("dateFormat");
    //String title = loc.equalsIgnoreCase("no") ? "Norsk Polarinstitutt i media" : "The Norwegian Polar Institute in the media";
    
    int maxEntries = 100000; // Just a really high number. It must be lower than Integer.MAXVALUE
    String maxEntriesStr = cms.getRequest().getParameter("maxentries");
    try {
        maxEntries = Integer.valueOf(maxEntriesStr).intValue();
    } catch (Exception e) {
        // Keep initial value
        //out.println("<h4 style=\"color:#ff0000;\">Cannot parse " + maxEntriesStr + " as an integer.</h4>");
    } 
    final String DISPLAY_ALL_PATH = cms.getRequest().getParameter("displayAllPath");
    final String DISPLAY_ALL_TEXT = cms.getRequest().getParameter("displayAllText");
    
    final String MORE_INFO = loc.equalsIgnoreCase("no") ? "Mer&nbsp;info" : "More&nbsp;info";
    final String NO_DATE = loc.equalsIgnoreCase("no") ? "Ingen publiseringdato" : "Publish date not available";
    final String ERROR_LIST = loc.equalsIgnoreCase("no") ? "Feil under innlasting" : "Error retrieving list";
    
    // HARD CODED DEFAULT URL AND DATE FORMAT
    if (url == null) {
        out.println(ERROR_LIST + ".");
        return; 
    }
    if (dateFormat == null)
        dateFormat = "dd. MMMM yyyy";
    
    final URL rssUrl = new URL(url);
    final SimpleDateFormat listFormat = new SimpleDateFormat(dateFormat, loc != null ? new Locale(loc) : new Locale("no"));
    
    SAXReader reader = new SAXReader();
    Document doc = reader.read(rssUrl);
    //String title = doc.selectSingleNode("//rss/channel/title").getStringValue();
    // Get the RSS item nodes as a list
    List names = doc.selectNodes("//rss/channel/item");///title");
    
    // Loop all items
    if (!names.isEmpty()) {
        String titleTagOpen = "<span";
        String titleTagClose = "</span>";
        if (DISPLAY_ALL_PATH != null) {
            titleTagOpen = "<a href=\"" + DISPLAY_ALL_PATH + "\"";
            titleTagClose = "</a>";
        }
        
        out.println("<ul class=\"item-list\">");
        
        //out.println("<li>The current language is " + new Locale(loc).getDisplayLanguage() + "</li>");
        
        Iterator i = names.iterator();
        int oddEven = 2;
        while (i.hasNext() && oddEven < (maxEntries + 2)) {
            Node itemNode   = (Node)i.next();                
            // Get the relevant item detail nodes
            //Node srcNode    = itemNode.selectSingleNode("source");
            Node titleNode  = itemNode.selectSingleNode("title");
            Node descrNode  = itemNode.selectSingleNode("description");
            Node linkNode   = itemNode.selectSingleNode("link");
            Node pubDateNode= itemNode.selectSingleNode("pubDate");
            Node enclosureNode = itemNode.selectSingleNode("enclosure");
            
            Date itemDate   = getDateFromNode(pubDateNode); // Get the item date
            String dateStr =  itemDate != null ? listFormat.format(itemDate) : NO_DATE; // Format the date
            
            String descr = getDescriptionFromNode(descrNode); // Get the description string
            descr += descr.length() > 0 && !descr.endsWith(".") ? "." : ""; // Add a "." to the end (if it's not there already).
            
            String[] enclosureDetails = getEnclosureFromNode(enclosureNode);
            
            out.println("<li class=\"item\">");
            //out.println("<h3 class=\"item-title\"><a href=\"" + linkNode.getText() + "\">" + titleNode.getText() + "</a></h3>");
            out.println("<h3 class=\"item-title\"><a href=\"" + enclosureDetails[0] + "\" target=\"_blank\">" + titleNode.getText() + " (PDF,&nbsp;" + enclosureDetails[1] + "&nbsp;MB)</a></h3>");
            out.println("<p>"+ dateStr + ". " + descr + " <a href=\"" + linkNode.getText() + "\">" + MORE_INFO + "</a></p>");
            out.println("</li>");
            oddEven++;
        }
        out.println("</ul>");
        
    }
%>
