<%-- 
    Document   : rss-scraper-meltwater
    Created on : 01.jun.2011, 12:03:39
    Author     : Paul-Inge Flakstad <flakstad at npolar.no>
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
    String style = cms.getRequest().getParameter("style");
    
    String timestampStr = cms.getRequest().getParameter("timestamp");
    String summaryStr = cms.getRequest().getParameter("summary");
    
    boolean timestamp = timestampStr == null ? true : Boolean.valueOf(timestampStr).booleanValue();
    boolean summary = summaryStr == null ? true : Boolean.valueOf(summaryStr).booleanValue();
    
    boolean styleNewsList = style != null && style.equalsIgnoreCase("newslist");
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
    
    // HARD CODED DEFAULT URL AND DATE FORMAT
    if (url == null)
        url = "http://meltwaternews.com/magenta/xml/html/53/rss/42208.rss2.XML";
    if (dateFormat == null)
        dateFormat = "dd. MMMM yyyy";
    
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
        if (styleNewsList) {
            out.println("<div class=\"news-list\">");
        }
        else {
            out.println("<div class=\"resourcelist\">");
            out.println("<ul>");
        }
        
        Iterator i = names.iterator();
        int oddEven = 2;
        while (i.hasNext() && oddEven < (maxEntries + 2)) {
            Node itemNode   = (Node)i.next();
            
            Node srcNode    = null;
            Node titleNode  = null;
            Node descrNode  = null;
            Node linkNode   = null;
            Node pubDateNode= null;
            
            try { srcNode    = itemNode.selectSingleNode("source"); } catch (Exception e) {}
            try { titleNode  = itemNode.selectSingleNode("title"); } catch (Exception e) {}
            try { descrNode  = itemNode.selectSingleNode("description"); } catch (Exception e) {}
            try { linkNode   = itemNode.selectSingleNode("link"); } catch (Exception e) {}
            try { pubDateNode= itemNode.selectSingleNode("pubDate"); } catch (Exception e) {}
            
            Date itemDate   = null;
            try {
                itemDate   = rssDateFormat.parse(pubDateNode.getText());
            } catch (Exception e) {
                //out.println("Unable to parse date string '" + pubDateNode.getText() + "'<br/>");
            }
            if (styleNewsList) {
                out.println("<div class=\"news\" style=\"border-top:1px solid #eee;\">");
                out.println("<div class=\"news-list-itemtext\" style=\"width:100%; float:none;\">");
                out.println("<h3>");
            } else {
                out.println("<li>");
                out.println("<div class\"text\">");
            }
            out.println("<a href=\"" + linkNode.getText() + "\" target=\"_blank\">" + 
                    titleNode.getText() + 
                    "</a></h3>");
            if (styleNewsList) {
                out.println("</h3>");
            }
            if (timestamp) {
                out.println("<div class=\"timestamp\">" + 
                    (itemDate != null ? listFormat.format(itemDate) : "NO DATE") + (srcNode != null ? (" - " + srcNode.getText()) : "") + "</div>");
            }
            if (summary) 
                out.println("<p class=\"teaser\">" + descrNode.getText() + "</p>");
            
            if (styleNewsList) {
                out.println("</div>");
                out.println("</div><!-- .news -->");
            } else {
                out.println("</div>");
                out.println("</li>");
            }
            oddEven++;
        }
        if (styleNewsList)
            out.println("</div><!-- .news-list -->");
        else {
            out.println("</div>");
            out.println("</ul>");
        }
        
    }
%>
