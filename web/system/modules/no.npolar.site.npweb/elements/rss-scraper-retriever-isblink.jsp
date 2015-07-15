<%-- 
    Document   : rss-scraper-retriever-isblink
    Created on : Jan 12, 2015, 10:00:52 AM
    Author     : Paul-Inge Flakstad, Norwegian Polar Institute
--%><%@page import="org.opencms.util.CmsStringUtil"%>
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
        url = "https://www.retriever-info.com/feed/2008283/feed-isblink/index.xml";
    if (dateFormat == null)
        dateFormat = "d. MMMM yyyy";
    
    final URL rssUrl = new URL(url);
    final SimpleDateFormat rssDateFormat = new SimpleDateFormat("EEE, dd MMM yyyy hh:mm:ss Z"); 
    final SimpleDateFormat listFormat = new SimpleDateFormat(dateFormat, loc != null ? new Locale(loc) : new Locale("no"));
    
    StringBuilder sb = new StringBuilder(256);
    
    SAXReader reader = new SAXReader();
    Document doc = reader.read(rssUrl);
    //String title = doc.selectSingleNode("//rss/channel/title").getStringValue();
    List names = doc.selectNodes("//rss/channel/item");///title");
    
    if (!names.isEmpty()) {
        
        //sb.append("<ul class=\"boxes clearfix blocklist\" style=\"padding:0; margin:0;\">");
        
        Iterator i = names.iterator();
        int oddEven = 2;
        while (i.hasNext() && oddEven < (maxEntries + 2)) {
            Node itemNode   = (Node)i.next();
            
            Node srcNode    = null;
            Node titleNode  = null;
            Node descrNode  = null;
            Node linkNode   = null;
            Node pubDateNode= null;
            Node mediaType  = null;
            
            try { srcNode    = itemNode.selectSingleNode("ret:source"); } catch (Exception e) {}
            try { titleNode  = itemNode.selectSingleNode("title"); } catch (Exception e) {}
            try { descrNode  = itemNode.selectSingleNode("description"); } catch (Exception e) {}
            try { linkNode   = itemNode.selectSingleNode("link"); } catch (Exception e) {}
            try { pubDateNode= itemNode.selectSingleNode("pubDate"); } catch (Exception e) {}
            try { mediaType  = itemNode.selectSingleNode("ret:mediatype"); } catch (Exception e) {}
            
            Date itemDate   = null;
            try {
                itemDate   = rssDateFormat.parse(pubDateNode.getText());
            } catch (Exception e) {
                //out.println("Unable to parse date string '" + pubDateNode.getText() + "'<br/>");
            }
            
            sb.append("<li class=\"span1 featured-box\">");

                sb.append("<a class=\"featured-link\" href=\"" + linkNode.getText() + "\" target=\"_blank\">");
                
                    sb.append("<div class=\"card\">");
                    
                        sb.append("<h3 class=\"card-heading\">" + titleNode.getText() + "</h3>");
                        if (timestamp) {
                            sb.append("<time class=\"timestamp\">" 
                                            + (itemDate != null ? listFormat.format(itemDate) : "NO DATE") 
                                            + (srcNode != null ? (" &ndash; " + srcNode.getText()) : "") 
                                        + "</time>");
                        }
                        if (summary) {
                            sb.append("<p itemprop=\"description\">" 
                                            + (mediaType != null ? ("<span class=\"tag\">" + mediaType.getText() + "</span> ") : "")
                                            + descrNode.getText() 
                                        + "</p>");
                        }

                    sb.append("</div>");
                sb.append("</a>");
            sb.append("</li>");
                
            oddEven++;
        }
        
        //sb.append("</ul>");
        
    }
    out.println("<ul class=\"boxes clearfix blocklist\" style=\"padding:0; margin:0;\" id=\"feed-retriever\"><li>Laster ...</li></ul>");
    %>
    <script type="text/javascript">
        $('#feed-retriever').html('<%= CmsStringUtil.escapeJavaScript(sb.toString()) %>');
    </script>
    <%
%>
