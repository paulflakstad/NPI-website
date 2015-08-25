<%-- 
    Document   : portal-yr-content
    Created on : 15.mar.2011, 11:29:02
    Author     : Paul-Inge Flakstad <flakstad at npolar.no>
--%><%@page import="org.opencms.jsp.*,
                org.opencms.file.*,
                org.opencms.file.types.*,
                org.opencms.main.*,
                org.opencms.util.CmsStringUtil,
                java.util.*,
                java.io.*,
                java.text.NumberFormat,
                javax.xml.xpath.XPath,
                javax.xml.xpath.XPathFactory,
                javax.xml.xpath.XPathConstants,
                javax.xml.xpath.XPathExpressionException,
                java.net.*,
                org.xml.sax.InputSource,
                no.npolar.util.*" 
        pageEncoding="UTF-8" 
%><%!
/**
* Gets an exception's stack strace as a string.
*/
public String getStackTrace(Exception e) {
    String trace = e.getCause() + ": " + e.getMessage() + "<br />";
    StackTraceElement[] ste = e.getStackTrace();
    for (int i = 0; i < ste.length; i++) {
        StackTraceElement stElem = ste[i];
        trace += stElem.toString() + "<br />";
    }
    return trace;
}
%><%
CmsAgent cms                            = new CmsAgent(pageContext, request, response);
CmsObject cmso                          = cms.getCmsObject();
Locale locale                           = cms.getRequestContext().getLocale();
String loc                              = locale.toString();
String requestFileUri                   = cms.getRequestContext().getUri();
String requestFolderUri                 = cms.getRequestContext().getFolderUri();

List locations = new ArrayList();
////////////////////////////////////////////////////////////////////////////////
//
// Add locations here
//

if (loc.equalsIgnoreCase("no")) { // Norwegian
    locations.add("http://www.yr.no/sted/Norge/Troms/Troms%C3%B8/Troms%C3%B8/varsel.xml|tromso.xml");
    locations.add("http://www.yr.no/sted/Norge/Svalbard/Ny-%C3%85lesund/varsel.xml|ny-alesund.xml");
    locations.add("http://www.yr.no/sted/Norge/Svalbard/Longyearbyen/varsel.xml|longyearbyen.xml");
    locations.add("http://www.yr.no/sted/S%C3%B8r-Afrika/Western_Cape/Cape_Town/varsel.xml|cape-town.xml");
    locations.add("http://www.yr.no/sted/Antarktika/Annet/Troll_Forskningsstasjon/varsel.xml|troll.xml");
}
else if (loc.equalsIgnoreCase("en")) { // English
    locations.add("http://www.yr.no/place/Norway/Troms/Troms%C3%B8/Troms%C3%B8/varsel.xml|tromso.xml");
    locations.add("http://www.yr.no/place/Norway/Svalbard/Ny-%C3%85lesund/varsel.xml|ny-alesund.xml");
    locations.add("http://www.yr.no/place/Norway/Svalbard/Longyearbyen/varsel.xml|longyearbyen.xml");
    locations.add("http://www.yr.no/place/South_Africa/Western_Cape/Cape_Town/varsel.xml|cape-town.xml");
    locations.add("http://www.yr.no/place/Antarctica/Other/Troll_research_station_(Norway)/varsel.xml|troll.xml");
}
////////////////////////////////////////////////////////////////////////////////

final String LABEL_YR_FORECAST          = loc.equalsIgnoreCase("no") ? "Varsel fra yr.no" : "Weather data by yr.no";
final String LABEL_YR_LINK              = "http://www.yr.no/?spr=" + (loc.equalsIgnoreCase("no") ? "nob" : "eng") + "&amp;redir=%2f";

final String YR_SYMBOLS_FOLDER          = "/images/yr/20/";
final String YR_CACHE_FOLDER            = "/" + loc + "/yr/";

// An integer formatter that will always display minimum 2 digits (e.g. 2 -> 02)
NumberFormat nf = NumberFormat.getIntegerInstance();
nf.setMinimumIntegerDigits(2);

XPathFactory xpf = XPathFactory.newInstance();
XPath xPath = xpf.newXPath();

out.println("<div class=\"yr-widget\"><ul>");

Iterator iLocations = locations.iterator();
String yrHtml = "";
try {     
    // Login admin and switch to Offline project
    CmsObject cmsoAdmin = OpenCms.initCmsObject(cmso);
    cmsoAdmin.loginUser("cmsbot", "2p45jgmrxv");
    cmsoAdmin.getRequestContext().setCurrentProject(cmsoAdmin.readProject("Offline"));
    
    while (iLocations.hasNext()) {
        String[] locationFiles = CmsStringUtil.splitAsArray((String)iLocations.next(), "|");
        String onlineFile = locationFiles[0];
        String cachedFile = YR_CACHE_FOLDER + locationFiles[1];
        
        //*// Update cache file
        boolean needsUpdate = true;
        final long CACHE_MAX_AGE_IN_MILLIS = 1000*60*10; // 10 minutes
        
        if (cmsoAdmin.existsResource(cachedFile)) {
            //Date modifiedDate = new Date(cmso.readResource(cms.getRequestContext().getUri()).getDateLastModified());
            long lastMod = cmsoAdmin.readResource(cachedFile).getDateLastModified();
            long cacheAge = new Date().getTime() - lastMod;
            out.println("<!-- Cache age for '" + cachedFile + "': " + cacheAge + " -->");
            
            if (cacheAge > CACHE_MAX_AGE_IN_MILLIS) {
            //if (cacheAge > (1000)) { // 1 second (use for testing)
                out.println("<!-- '" + cachedFile + "' needs update.  -->");
                needsUpdate = true;
            } else {
                out.println("<!-- '" + cachedFile + "' is up to date.  -->");
                needsUpdate = false;
            }
        } else {
            out.println("<!-- '" + cachedFile + "' needs update (file did not exist).  -->");
            needsUpdate = true;
        }
        
        // update the cache file
        if (needsUpdate) {
            cmsoAdmin.lockResource(cachedFile);
            
            // Fetch XML from yr.no: 
            StringBuffer contentBuffer = new StringBuffer(1024);
            URL xmlUrl = new URL(onlineFile);
            URLConnection urlConnection = xmlUrl.openConnection();
            BufferedReader in = new BufferedReader(new InputStreamReader(urlConnection.getInputStream()));
            String inputLine;
            while ((inputLine = in.readLine()) != null) {
                contentBuffer.append(inputLine);
            }
            in.close();
            byte[] raw = contentBuffer.toString().getBytes("utf-8");
            
            CmsFile cmsCacheFile = cmsoAdmin.readFile(cachedFile);
            cmsCacheFile.setContents(raw);
            cmsoAdmin.writeFile(cmsCacheFile);
            cmsoAdmin.unlockResource(cachedFile);
            //OpenCms.getPublishManager().publishResource(cmsoAdmin, cachedFile);
            
        }
        /*
        if (!cms.getRequestContext().currentProject().isOnlineProject()) {
            if (cmso.getRequestContext().currentUser().getName().equalsIgnoreCase("cmsbot"))
                cmso.lo
            cms.getRequestContext().setCurrentProject(cmso.readProject("Online"));
        }
        */
        //*/
        // Done updating cache file
        
        /*// 
        // Alternative 1: Read XML directly from yr.no:
        URL xmlUrl = new URL(onlineFile);
        URLConnection urlConnection = xmlUrl.openConnection();
        InputSource is = new InputSource(urlConnection.getInputStream());
        //*/
        
        
        //*// Alternative 2: Read XML from cache file (new version is fetched above if cache has expired)
        ByteArrayInputStream bis = new ByteArrayInputStream(cmsoAdmin.readFile(cachedFile).getContents());
        InputSource is = new InputSource(bis);
        //*/

        //XPathExpression xpe = xPath.compile("/weatherdata/location/name");
        //String xpResult = xpe.evaluate(is);

        Object locationNode = xPath.compile("/weatherdata").evaluate(is, XPathConstants.NODE);
        String yrLoc = xPath.compile("//location/name").evaluate(locationNode);
        String yrHref = xPath.compile("//links/link[@id='overview']/@url").evaluate(locationNode);
        String yrSymbolName = xPath.compile("//forecast/tabular/time/symbol/@name").evaluate(locationNode);
        String yrSymbolNumber = xPath.compile("//forecast/tabular/time/symbol/@number").evaluate(locationNode);
        String yrTemp = xPath.compile("//forecast/tabular/time/temperature/@value").evaluate(locationNode);
        
        //String yrLoc = xPath.compile("/weatherdata/location/name").evaluate(is);
        //String yrSymbolName = xPath.compile("/weatherdata/forecast/tabular/time/symbol/@name").evaluate(is);
        //String yrTemp = xPath.compile("/weatherdata/forecast/tabular/time/temperature/@value").evaluate(is);
        
        // Modify the location if it is too long
        String yrLocFull = yrLoc;
        if (yrLoc.length() > 20) {
            yrLoc = yrLoc.substring(0, 18).concat("&hellip;");
        }
        
        yrHtml += "<li><a class=\"yr-location\" href=\"" + yrHref + "\" title=\"" + yrLocFull + "\">" + yrLoc + "</a>";
        yrHtml += "<span class=\"yr-temp\">" + yrTemp + " &deg;C</span>";
        yrHtml += "<span class=\"yr-symbol\">" + 
                        "<img src=\"" + cms.link(YR_SYMBOLS_FOLDER + nf.format(Integer.valueOf(yrSymbolNumber))) + ".png\" alt=\"" + yrSymbolName + "\" title=\"" + yrSymbolName + "\" />" + 
                        "</span>";
        yrHtml += "</li>";
    }
    out.println(yrHtml);
} catch (Exception e) {
    if (cms.getRequestContext().currentProject().isOnlineProject()) {
        out.println("<li>" + cms.labelUnicode("label.np.yr.error") + ":</li>");
        iLocations = locations.iterator();
        while (iLocations.hasNext()) {
            String[] locationFiles = CmsStringUtil.splitAsArray((String)iLocations.next(), "|");
            String onlineFile = locationFiles[0].replace("/varsel.xml", "");
            String cachedFile = YR_CACHE_FOLDER + locationFiles[1];
            String cachedFileTitle = cms.property("Title", cachedFile);
            out.println("<li><a class=\"yr-location\" href=\"" + onlineFile + "\">" + cachedFileTitle + "</a></li>");
        }
    }
    else
        out.println(getStackTrace(e));
}
out.println("</ul>");
out.println("<p class=\"yr-credit\"><a target=\"_blank\" href=\"" + LABEL_YR_LINK + "\">" + LABEL_YR_FORECAST + "</a></p>");
out.println("</div><!-- .yr-widget -->");
%>