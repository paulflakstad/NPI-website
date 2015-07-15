<%-- 
    Document   : portal-media-snippets
    Created on : Dec 21, 2011, 12:55:59 PM
    Author     : flakstad
--%>
<%@page import="org.dom4j.*,
                org.dom4j.io.*,
                org.opencms.jsp.CmsJspActionElement,
                java.net.URL,
                java.util.List,
                java.util.Iterator,
                java.util.Date,
                java.util.Locale,
                java.text.SimpleDateFormat" %>
<%
CmsJspActionElement cms = new CmsJspActionElement(pageContext, request, response);
//if (cms.template("main")) {
    String loc = cms.getRequestContext().getLocale().toString();
    
    String url = cms.getRequest().getParameter("url");
    String dateFormat = cms.getRequest().getParameter("dateFormat");
    //String title = loc.equalsIgnoreCase("no") ? "Norsk Polarinstitutt i media" : "The Norwegian Polar Institute in the media";
    
    int maxEntries = 4; // Just a really high number. It must be lower than Integer.MAXVALUE
    String maxEntriesStr = cms.getRequest().getParameter("maxentries");
    try {
        maxEntries = Integer.valueOf(maxEntriesStr).intValue();
    } catch (Exception e) {
        // Keep initial value
        //out.println("<h4 style=\"color:#ff0000;\">Cannot parse " + maxEntriesStr + " as an integer.</h4>");
    } 
    final String DISPLAY_ALL_PATH = loc.equalsIgnoreCase("no") ? "/no/om-oss/formidling/norsk-polarinstitutt-i-media.html" : "/en/about-us/outreach/the-norwegian-polar-institute-in-the-media.html";
    final String DISPLAY_ALL_TEXT = loc.equalsIgnoreCase("no") ? "Vis alle medieklipp" : "View all media clips";
    
    // HARD CODED DEFAULT URL AND DATE FORMAT
    if (url == null)
        url = "http://meltwaternews.com/magenta/xml/html/53/rss/42208.rss2.XML";
    if (dateFormat == null)
        dateFormat = loc.equalsIgnoreCase("no") ? "dd. MMMM yyyy" : "dd MMMM yyyy";
    
    final URL rssUrl = new URL(url);
    final SimpleDateFormat rssDateFormat = new SimpleDateFormat("EEE, dd MMM yyyy hh:mm:ss Z"); 
    final SimpleDateFormat listFormat = new SimpleDateFormat(dateFormat, loc != null ? new Locale(loc) : new Locale("no"));
    
    SAXReader reader = new SAXReader();
    Document doc = reader.read(rssUrl);
    //String title = doc.selectSingleNode("//rss/channel/title").getStringValue();
    List names = doc.selectNodes("//rss/channel/item");///title");
    
    // New version, created when news were added to the frontpage
    if (!names.isEmpty()) {
        String titleTagOpen = "<span";
        String titleTagClose = "</span>";
        if (DISPLAY_ALL_PATH != null) {
            titleTagOpen = "<a href=\"" + DISPLAY_ALL_PATH + "\"";
            titleTagClose = "</a>";
        }
        //title = titleTagOpen + " class=\"icon news\">" + title + titleTagClose; 
        /*
        out.println("<h2 class=\"list-title\">" + 
                        titleTagOpen + ">" + title + titleTagClose + // <a ...>title</a> OR <span ...>title</span>
                        //"<a href=\"" + url +"\" class=\"icon rss\">RSS</a>" +
                    "</h2>");
        */
        //out.println("<div class=\"news-list\">");
        out.println("<ul>");
        
        Iterator i = names.iterator();
        int oddEven = 2;
        while (i.hasNext() && oddEven < (maxEntries + 3)) {
            Node itemNode   = (Node)i.next();                
            
            Node srcNode    = itemNode.selectSingleNode("source");
            Node titleNode  = itemNode.selectSingleNode("title");
            Node descrNode  = itemNode.selectSingleNode("description");
            Node linkNode   = itemNode.selectSingleNode("link");
            Node pubDateNode= itemNode.selectSingleNode("pubDate");
            Date itemDate   = null;
            try {
                itemDate   = rssDateFormat.parse(pubDateNode.getText());
            } catch (Exception e) {
                out.println("Unable to parse date string '" + pubDateNode.getText() + "'<br/>");
            }
            out.print("<li>");
            out.print("<a href=\"" + linkNode.getText() + "\">" + titleNode.getText() + "</a>");
            out.println("</li>");
            
            /*
            out.println("<div class=\"news\">");
            out.println("<div class=\"news-list-itemtext\"><h3><a href=\"" + linkNode.getText() + "\" target=\"_blank\">" + 
                    titleNode.getText() + 
                    "</a></h3>");
            out.println("<div class=\"timestamp\">" + 
                    (itemDate != null ? listFormat.format(itemDate) : "NO DATE") + " - " + srcNode.getText() + "</div>");
            out.println("<p>" + descrNode.getText() + "</p></div>");
            out.println("</div><!-- .news -->");
            */
            oddEven++;
        }
        out.println("<li><em><a href=\"" + DISPLAY_ALL_PATH + "\">" + DISPLAY_ALL_TEXT + "</a></em></li>");
        out.println("</ul>");
        //out.println("</div><!-- .news-list -->");
        
    }
%>
