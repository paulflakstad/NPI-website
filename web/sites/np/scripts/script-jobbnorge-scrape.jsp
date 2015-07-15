<%-- 
    Document   : script-jobbnorge-scrape
    Created on : 28.jul.2011, 13:11:01
    Author     : Paul-Inge Flakstad <flakstad at npolar.no>
--%><%@page import="org.opencms.main.OpenCms,
            org.opencms.staticexport.CmsLinkManager,
            org.apache.commons.mail.EmailException,
            org.opencms.mail.CmsSimpleMail,
            org.opencms.jsp.*, 
            org.opencms.file.CmsPropertyDefinition,
            org.opencms.file.CmsObject,
            java.util.*, 
            java.util.regex.*,
            java.net.*,
            java.io.*,
            no.npolar.util.*" session="true" 
%><%!
public String stdErr(CmsObject cmso, String altUrl) throws EmailException  {
    sendErrorNotification(cmso);
    return "<h3>Whoops, sorry!</h3>"
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
        CmsAgent cms = new CmsAgent(pageContext, request, response);
        CmsObject cmso = cms.getCmsObject();
        Locale locale = cms.getRequestContext().getLocale();
        String loc = locale.toString();
        
        final String BACKLINK = "https://www.jobbnorge.no/" + (loc.equalsIgnoreCase("no") ? "ledige-stillinger/norsk-polarinstitutt" : "en/available-jobs/norwegian-polar-institute");
        
        // The languages
        //List LANG = Arrays.asList(new String[] {"null", "no", "en" }); 
        final String LANG_ID = loc.equals("no") ? "1" : "2";
        // Cookie: language
        String cookieLang = "jobbnorge_languageID=" + LANG_ID;
        
        // Localized labels
        final String LABEL_SUMMARY = loc.equalsIgnoreCase("no") ? "Ledige stillinger hos Norsk Polarinstitutt" : "Available positions at the Norwegian Polar Institute";
        final String LABEL_CAPTION = loc.equalsIgnoreCase("no") ? "Ledige stillinger hos Norsk Polarinstitutt" : "Available positions at the Norwegian Polar Institute";
        final String LABEL_TITLE = loc.equalsIgnoreCase("no") ? "Stilling" : "Job title";
        final String LABEL_MUNICIPALITY = loc.equalsIgnoreCase("no") ? "Kommune" : "Municipality";
        final String LABEL_COUNTY = loc.equalsIgnoreCase("no") ? "Fylke" : "County";
        final String LABEL_DEPARTMENT = loc.equalsIgnoreCase("no") ? "Avdeling" : "Department";
        final String LABEL_DEADLINE = loc.equalsIgnoreCase("no") ? "Søknadsfrist" : "Deadline";
        final String LABEL_WORKPLACE = loc.equalsIgnoreCase("no") ? "Arbeidssted" : "Work place";
        final String LABEL_NO_POSITIONS = loc.equalsIgnoreCase("no") ? "Vi har ingen ledige stillinger utlyst for øyeblikket." : "There are no available positions at this time";
        final String LABEL_SOURCE_CREDIT = "<a href=\"" + BACKLINK + "\">" + (loc.equalsIgnoreCase("no") ? "Liste hentet fra" : "Listing fetched from") + " jobbnorge.no</a>";
        
        final String PROTOCOL = "http://";
        final String HOST = "www.jobbnorge.no";
        final String SERVICE = "/apps/joblist/jobs.aspx?employerid=52";
        //final String SERVICE = "/search.aspx?pageid=99&arbid=52";
        //final String SERVICE = "/search.aspx?pageid=99&empID=52";
        //final String SERVICE = "/search.aspx?pageid=99&employerid=52";
        
        final String START_TOKEN = "<tr";
        final String END_TOKEN = "</table";
        
        //URL u;
        HttpURLConnection uc = null; // HttpURLConnection can be used for both HTTP and HTTPS (HttpsURLConnection extends HttpURLConnection)
        StringBuffer contentBuffer = new StringBuffer(1024);
        String theUrl = PROTOCOL + HOST + SERVICE;
        
        try {
            try {
                uc = (HttpURLConnection)new URL(theUrl).openConnection();
                uc.setRequestProperty("Cookie", cookieLang);
            } catch (Exception ce) {
                out.println("<!-- Unable to connect to '" + theUrl + "' -->");
                out.println(stdErr(cmso, theUrl));
                return;
            }
            // Check for redirects
            /* // This outcommented code is redundant, it's handled by the Java classes.
            int code = uc.getResponseCode();
            if (code == HttpURLConnection.HTTP_OK)
                out.println("<!-- Received HTTP 200 OK from " + uc.getURL() + " -->");
            while (code == HttpURLConnection.HTTP_MOVED_PERM || code == HttpURLConnection.HTTP_MOVED_TEMP) {
                out.println("<!-- 301 or 302 encountered -->");
                theUrl = uc.getHeaderField("Location");
                if (theUrl == null || theUrl.isEmpty())
                    theUrl = uc.getHeaderField("location");
                if (theUrl == null || theUrl.isEmpty()) {
                    out.println("<!-- Bad redirect, unable to continue. -->");
                    out.println(stdErr(cmso, theUrl));
                    return;
                }
                out.println("<!-- 301 or 302 redirect to '" + theUrl + "' -->");
                uc = (HttpURLConnection)new URL(theUrl).openConnection();
            }
            */
            out.println("<!-- Using connection '" + uc.getURL() + "', with language cookie '" + cookieLang + "' -->");
            
            
            try {
                while (uc.getHeaderField("refresh") != null && !uc.getHeaderField("refresh").isEmpty() && uc.getHeaderField("refresh").startsWith("0")) {
                    // Example: [refresh][0;URL=http://www.jobbnorge.no/apps/joblist/jobs.aspx?employerid=52]
                    theUrl = uc.getHeaderField("refresh").split("URL=")[1];
                    out.println("<!-- Header refresh redirect to '" + theUrl + "' -->");
                    uc.getInputStream().close();
                    uc = (HttpURLConnection)new URL(theUrl).openConnection();
                }
            } catch (Exception e) {
                out.println("<!-- Response header contained 'refresh'. Assumed redirect, but failed to resolve. Header was " + uc.getHeaderField("refresh") + ". -->");
                out.println(stdErr(cmso, theUrl));
                return;
                //out.println("<!-- Stack trace\n");
                //e.printStackTrace(response.getWriter());
                //out.println("+n-->");
            }
            
            out.println("<!-- Using connection '" + uc.getURL() + "' -->");
            
            BufferedReader in = new BufferedReader(
                                    new InputStreamReader(
                                    uc.getInputStream()));
            
            String inputLine;
            while ((inputLine = in.readLine()) != null) {
                contentBuffer.append(inputLine + "\n");
            }
            in.close();
            
            String content = contentBuffer.toString();
            
            out.println("<!-- Chewing on " + content.getBytes().length + " bytes of content from " + uc.getURL().toString() + " ... -->");
            //out.println("<!--\n" + content.toString() + "\n-->");

            // Remove everything before the first table row
            content = content.substring(content.indexOf(START_TOKEN));
            // Remove everything after the last table row (starting from "</table")
            content = content.substring(0, content.indexOf(END_TOKEN));
            
            // The content string is now a set of table rows. 
            // Remove the first row.
            content = content.substring(content.indexOf("</tr>") + 5);
            // And the second row too.
            content = content.substring(content.indexOf("</tr>") + 5);
			
			// Remove the generic link to jobbnorge
			content = content.replace("<a href=\"http://www.jobbnorge.no\" target=\"_blank\">www.jobbnorge.no</a>", "");
            
            //out.println("<!-- Content\n\n" + content + "\n\n-->");
            
            //if (content.isEmpty() || !content.contains("href=")) {
            if (content.isEmpty() || !content.contains("href=")) {
            //if (content.isEmpty() || !content.contains("grdJobs")) { // grdJobs is the ID of the table containing available positions
                out.println("<!-- No content or no job links present" + (content.isEmpty() ? " (the URL content was empty)" : "") + " -->");
                // Then there are no available positions at this time
                throw new NullPointerException();
            }
            
            // Replace relative URLs for jobbnorge.no with absolute URLs
            //content = content.replaceAll("href=\"", "href=\"http://www.jobbnorge.no/");
            content = content.replaceAll("href=\"\\.\\./\\.\\.", "href=\"");
            content = content.replaceAll("href=\"", "href=\"".concat(PROTOCOL + HOST));
            
            // Replace
            List jobIds = new ArrayList();
            String pattern = "jobid=([0-9]+)";
            Pattern p = Pattern.compile(pattern);
            Matcher m = p.matcher(content);
            while (m.find()) {
                jobIds.add(content.substring(m.start(), m.end()));
            }
            if (!jobIds.isEmpty()) {
                Iterator itr = jobIds.iterator();
                while (itr.hasNext()) {
                    String jobId = (String)itr.next();
                    content = content.replaceAll(jobId, jobId+"&amp;translateid="+LANG_ID);
                }
            }    
            // Remove attributes from <tr>s
            content = content.replaceAll("<tr[^>]+>", "<tr>");
            // Remove attributes from <td>s
            content = content.replaceAll("<td[^>]+>", "<td>");
            // Remove font elements
            content = content.replaceAll("<font[^>]+>", "");
            content = content.replaceAll("</font>", "");
            
            
            
            out.println("<table class=\"odd-even-table\" cellspacing=\"2\" cellpadding=\"0\" summary=\"" + LABEL_SUMMARY + "\">");
            out.println("<caption>" + LABEL_CAPTION + "</caption>");
            out.println("<tbody>");
            out.println("<tr>" +
                            "<th>" + LABEL_TITLE + "</th>" +
                            "<th>" + LABEL_DEPARTMENT + "</th>" +
                            "<th>" + LABEL_DEADLINE + "</th>" +
                            "<th>" + LABEL_WORKPLACE + "</th>" +
                        "</tr>");
            out.println(content);
            out.println("</tbody>");
            out.println("</table>");
            out.println("<p class=\"smallertext pull-right\">" + LABEL_SOURCE_CREDIT + "</p>");
        } catch (Exception e) {
            out.println("<h4>" + LABEL_NO_POSITIONS + "</h4>");
            //e.printStackTrace(response.getWriter());
        }
        %>