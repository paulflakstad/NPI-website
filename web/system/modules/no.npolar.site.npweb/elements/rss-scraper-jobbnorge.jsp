<%-- 
    Document   : rss-scraper-retriever-isblink
    Created on : Jan 12, 2015, 10:00:52 AM
    Author     : Paul-Inge Flakstad, Norwegian Polar Institute
--%><%@page import="org.apache.commons.mail.EmailException,
                org.dom4j.*,
                org.dom4j.io.*,
                org.opencms.jsp.CmsJspActionElement,
                org.opencms.file.CmsObject,
                org.opencms.main.OpenCms,
                org.opencms.mail.CmsSimpleMail,
                org.opencms.util.CmsStringUtil,
                java.net.URL,
                java.util.List,
                java.util.Iterator,
                java.util.Date,
                java.util.Locale,
                java.text.SimpleDateFormat" 
%><%!
public String stdErr(CmsObject cmso, String altUrl) throws EmailException  {
    sendErrorNotification(cmso);
    return "<h2>Whoops, sorry!</h2>"
            + "<p>We're experiencing problems with our list of available positions!</p>"
            + "<p>Please come back later, or try <a href=\"" + altUrl + "\">" + altUrl + "</a></p>";
}

private void sendErrorNotification(CmsObject cmso) throws EmailException {
    CmsSimpleMail sm = new CmsSimpleMail();
    sm.setFrom("no-reply@npolar.no", "NPI website");
    sm.addTo("nettredaktor@npolar.no");
    sm.setSubject("Error on available positions page");
    sm.setMsg("An error was registered just now on the available positions page " + OpenCms.getLinkManager().getOnlineLink(cmso, cmso.getRequestContext().getUri()) + "."
            + " Please check the page and correct any errors. Do not reply to this e-mail, it was sent by OpenCms.");
    sm.send();
}
%><%
    
CmsJspActionElement cms = new CmsJspActionElement(pageContext, request, response);
CmsObject cmso = cms.getCmsObject();
//if (cms.template("main")) {
    Locale locale = cms.getRequestContext().getLocale();
    String loc = locale.toString();
    
    // Localized strings
    final String BACKLINK = "https://www.jobbnorge.no/" + (loc.equalsIgnoreCase("no") ? "ledige-stillinger/norsk-polarinstitutt" : "en/available-jobs/norwegian-polar-institute");
    final String LABEL_SUMMARY = loc.equalsIgnoreCase("no") ? "Ledige stillinger akkurat n�" : "Currently available positions";
    final String LABEL_CAPTION = loc.equalsIgnoreCase("no") ? "Ledige stillinger akkurat n�" : "Currently available positions";
    final String LABEL_TITLE = loc.equalsIgnoreCase("no") ? "Stilling" : "Job title";
    final String LABEL_MUNICIPALITY = loc.equalsIgnoreCase("no") ? "Kommune" : "Municipality";
    final String LABEL_COUNTY = loc.equalsIgnoreCase("no") ? "Fylke" : "County";
    final String LABEL_DEPARTMENT = loc.equalsIgnoreCase("no") ? "Avdeling" : "Department";
    final String LABEL_DEADLINE = loc.equalsIgnoreCase("no") ? "S�knadsfrist" : "Deadline";
    final String LABEL_WORKPLACE = loc.equalsIgnoreCase("no") ? "Arbeidssted" : "Work place";
    final String LABEL_NO_POSITIONS = loc.equalsIgnoreCase("no") ? "Vi har ingen ledige stillinger utlyst for �yeblikket." : "There are no available positions at this time";
    final String LABEL_SOURCE_CREDIT = "<a href=\"" + BACKLINK + "\">" + (loc.equalsIgnoreCase("no") ? "Liste hentet fra" : "Listing fetched from") + " jobbnorge.no</a>";
    
    final int MAX_LOOPS = 500; // Just a high number (used as a safety mechanism)
    
    // The feed URL
    
    final String URL = "http://www.jobbnorge.no/apps/joblist/joblistbuilder.ashx?id=f80a5414-0e95-425a-82e1-a64fa9060bc5" 
                        + (loc.equalsIgnoreCase("no") ? "" : "&trid=2"); // trid=2 ==> English
        
    // This is now the URL
    final URL FEED_URL = new URL(URL);
    
    //final SimpleDateFormat DATE_FORMAT_RSS = new SimpleDateFormat("EEE, dd MMM yyyy hh:mm:ss Z"); // Standardized in the RSS spec
    final SimpleDateFormat DATE_FORMAT_DEADLINE = new SimpleDateFormat("dd.MM.yyyy"); // How deadlines are represented in the feed
    final SimpleDateFormat DATE_FORMAT_OUTPUT = new SimpleDateFormat(loc.equalsIgnoreCase("no") ? "d. MMMM" : "d MMMM", locale); // Output format
    
    StringBuilder sb = new StringBuilder(256);
    %>
    
    <section class="paragraph clearfix">
    
    <%
    try {
        SAXReader reader = new SAXReader();
        Document feed = null;
        
        // Test RSS availability
        try {
            feed = reader.read(FEED_URL);
            feed.selectNodes("//rss/channel");
        } catch (Exception e) {
            // RSS not available
            out.println(stdErr(cmso, BACKLINK));
            return;
        }
        //String feedTitle = doc.selectSingleNode("//rss/channel/title").getStringValue();
        List feedItems = feed.selectNodes("//rss/channel/item");///title");
        //items.clear(); // Uncomment to test empty list (no available positions)
        
        if (!feedItems.isEmpty()) {    
            Iterator ifeedItems = feedItems.iterator();
            int oddEven = 2;
            while (ifeedItems.hasNext() && oddEven++ < (MAX_LOOPS+2)) {
                Node itemNode   = (Node)ifeedItems.next();

                Node titleNode = null; // The job title
                Node linkNode = null; // Link to full text version at Jobbnorge.no
                Node deadlineNode = null; // The application deadline
                Node locationNode = null; // The job location
                Node deptNode = null; // The department in which the position is placed

                // The node names used here must be up-to-date with the RSS feed
                try { titleNode = itemNode.selectSingleNode("title"); } catch (Exception e) {}
                try { linkNode = itemNode.selectSingleNode("link"); } catch (Exception e) {}
                try { deadlineNode = itemNode.selectSingleNode("jn:deadline"); } catch (Exception e) {}
                try { locationNode = itemNode.selectSingleNode("jn:location"); } catch (Exception e) {}
                try { deptNode = itemNode.selectSingleNode("jn:departmentname"); } catch (Exception e) {}
                
                Date deadlineDate = DATE_FORMAT_DEADLINE.parse(deadlineNode.getText());
                boolean deadlineClose = deadlineDate.getTime() - new Date().getTime() < (2*24*60*60*1000); // 2 days
                
                //sb.append(deptNode.selectSingleNode("duh").getText()); // Uncomment to test error handling

                sb.append("<tr>");
                    //sb.append("<th scope=\"row\"><a href=\"" + linkNode.getText() + "\">" + titleNode.getText() + "</a></td>");
                    sb.append("<td><a href=\"" + linkNode.getText() + "\">" + titleNode.getText() + "</a></td>");
                    sb.append("<td>" + deptNode.getText() + "</td>");
                    sb.append("<td>" + locationNode.getText() + "</td>");
                    sb.append("<td" 
                                + (deadlineClose ? " style=\"color:#c00; font-weight:bold;\"" : "") 
                                + ">" 
                                    + DATE_FORMAT_OUTPUT.format(deadlineDate) 
                            + "</td>");
                sb.append("</tr>");
            }
            %>
            <table class="odd-even-trable" cellspacing="2" cellpadding="0" summary="<%= LABEL_SUMMARY %>">
                <caption><%= LABEL_CAPTION %></caption>
                <tr>
                    <th scope="col" style="width:50%;"><%= LABEL_TITLE %></th>
                    <th scope="col" style="width:20%;"><%= LABEL_DEPARTMENT %></th>
                    <th scope="col" style="width:15%;"><%= LABEL_WORKPLACE %></th>
                    <th scope="col" style="width:15%;"><%= LABEL_DEADLINE %></th>
                </tr>
                <%= sb.toString() %>
            </table>
            <p class="smallertext pull-right"><%= LABEL_SOURCE_CREDIT %></p>
            <%
        } else {
            %>
            <p><em><%= LABEL_NO_POSITIONS %></em></p>
            <%
        }
        
    } catch (Exception e) {
        out.println(stdErr(cmso, BACKLINK));
    }
    %>
    </section>
    