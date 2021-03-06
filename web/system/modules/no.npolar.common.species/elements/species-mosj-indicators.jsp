<%-- 
    Document   : species-mosj-indicators
    Description: Custom script for species pages.
                    Based on a given locale and one or more keyword(s)/phrase(s), this script will look up
                    matching MOSJ indicators. The indicator overview is read as XML from MOSJ (not the 
                    indicator API). This is to avoid mathces on indicators that are not yet visible on 
                    the MOSJ website. Also, this approach is much faster than using the API.
                    Required parameter: keyword. One or multiple occurences.
                    Recommended parameter: locale. Should always be set, but will default to English if not set.
    Created on : May 10, 2013, 12:39:51 PM
    Author     : flakstad

--%><%@ page import="org.opencms.jsp.*,
                 org.opencms.main.OpenCms,
                 org.opencms.file.*,
                 org.opencms.json.*,
                 java.util.*,
                 java.io.*,
                 java.net.*,
                 java.util.regex.*,
                 no.npolar.util.*,
                 javax.xml.transform.*,
                 javax.xml.transform.stream.*,
                 javax.xml.parsers.*,
                 javax.xml.xpath.*,
                 org.xml.sax.helpers.*,
                 org.xml.sax.*,
                 org.w3c.dom.*,
                 org.opencms.security.CmsRole,
                 org.opencms.i18n.CmsEncoder,
                 org.opencms.xml.content.CmsXmlContent,
                 org.opencms.xml.content.CmsXmlContentFactory,
                 no.npolar.common.menu.*" session="true"
%><%@ taglib prefix="cms" uri="http://www.opencms.org/taglib/cms" 
%><%!
    public void showError(CmsAgent cmsa, JspWriter out, String errMsg) {
        try {
            out.println("<div class=\"error\">" + "<h2>Error</h2>" + errMsg + "</div>");
            //out.println("</div> <!-- .page -->");
            //cmsa.include(cmsa.getTemplate(), cmsa.getTemplateIncludeElements()[1], false);
        } catch (Exception e) {
            throw new NullPointerException("An error occurred when attempting to include the master template.");
        }
        return;
    }
    public void showInfo(CmsAgent cmsa, JspWriter out, String errMsg) {
        try {
            out.println("<div class=\"error\">" + "<h2>Information</h2>" + errMsg + "</div>");
            //out.println("</div> <!-- .page -->");
            //cmsa.include(cmsa.getTemplate(), cmsa.getTemplateIncludeElements()[1], false);
        } catch (Exception e) {
            throw new NullPointerException("An error occurred when attempting to include the master template.");
        }
        return;
    }
    /**
     * Requests the given URL and returns the response as a String.
     * 
     * @param url The URL to request.
     * @return The response, as a string.
     * @throws MalformedURLException
     * @throws IOException
     */
    public static String httpResponseAsString(String url) 
            throws MalformedURLException, IOException {
        
        BufferedReader in = new BufferedReader(new InputStreamReader(new URL(url).openConnection().getInputStream(), "UTF-8"));
        StringBuilder s = new StringBuilder();
        String oneLine;
        while ((oneLine = in.readLine()) != null) {
            s.append(oneLine);
        }
        in.close();

        return s.toString();
    }
%><%
/*
        String url = "http://mosj.npolar.no/no/inddb-search.html?"
                        + "q=fjellrev"
                        + "&start=0"
                        + "&indent=on"
                        + "&hl.fl=body"
                        + "&facet=true"
                        + "&facet.field=location_exact"
                        + "&facet.field=theme_exact"
                        + "&facet.field=subtheme_exact"
                        + "&fq=language_code%3Anb"
                        + "&facet.mincount=1"
                        + "&version=2.2"
                        + "&f.location_exact.facet.sort=true"
                        + "&f.location_exact.facet.limit=25";
*/
CmsAgent cms = new CmsAgent(pageContext, request, response);
//CmsObject cmso = cms.getCmsObject();
// Get the URI of the requesting file
//String requestResourceUri = cms.getRequestContext().getUri();
//String requestFolderUri = cms.getRequestContext().getFolderUri();
Locale locale = cms.getRequestContext().getLocale();
String loc = locale.toString();
session = request.getSession(true);
List<String> keywords = null;

String indLocale = request.getParameter("locale").toLowerCase();
if (indLocale == null)
    indLocale = loc;

cms.getRequestContext().setLocale(new Locale(indLocale));

try {
    keywords = new ArrayList<String>(Arrays.asList(request.getParameterValues("keyword")));
} catch (Exception e) {
    out.println("<p>Critical error: Cannot determine keyword(s).</p>");
    return;
}
String keyword = null;

try {
    //keyword = request.getParameter("keyword").toLowerCase();
    if (keywords == null || keywords.isEmpty())
        throw new Exception();
} catch (Exception e) {
    out.println("<p>Critical error: Missing keyword(s).</p>");
    return;
}

boolean loggedInUser = OpenCms.getRoleManager().hasRole(cms.getCmsObject(), CmsRole.WORKPLACE_USER);

final boolean COMMENTS = false;

//String xmlPath      = "http://indapi.data.npolar.no/indicators.xml"; // The search URL, without parameters. (Replace "select" with "admin" and open in a browser to get a full UI.);
String servicePath = "http://www.mosj.no/indicators.json"; // The search URL, without parameters. (Replace "select" with "admin" and open in a browser to get a full UI.);
servicePath = servicePath.concat("?locale=" + indLocale);
if (COMMENTS) {
    out.println("<!-- Constructed URL to indicators list: " + servicePath + " -->");
}
    
try {    
    JSONObject indicatorsObj = null; 
    try {
        indicatorsObj = new JSONObject(httpResponseAsString(servicePath));
    } catch (Exception e){
        // Cannot connect to the MOSJ service
        showError(cms, out, "Unable to connect to MOSJ.".concat(loggedInUser ? " Error was: ".concat(e.getMessage()) : ""));
        return;
    }
    
    JSONArray indicatorsArr = indicatorsObj.getJSONArray("indicators");
        
    String indTitle             = null;
    String indId                = null;
    String indUrl               = null;        
        
    //xmlPath = xmlPath.concat("?lang=" + (loc.equals("no") ? "nb" : loc));

    List<JSONObject> indicatorObjects = new ArrayList<JSONObject>();

    // Put all indicators in a sortable list, and sort them
    
    
    for (int i = 0; i < indicatorsArr.length(); i++) {
        try {
            JSONObject indicatorObj = (JSONObject)indicatorsArr.get(i);
            String indicatorTitle = indicatorObj.getString("title");
            Iterator<String> iKeywords = keywords.iterator();
            //List<String> iTitleWords = Arrays.asList(indicatorTitle.toLowerCase().split("\\s"));
            while (iKeywords.hasNext()) {
                keyword = iKeywords.next().toLowerCase();
                String regex = ("(^|\\W)(") + keyword.replaceAll("\\s", "\\\\s") + ")($|\\W)";
                if (COMMENTS) out.println("<!-- Using regex: " + regex + " -->");
                Pattern p = Pattern.compile(regex);
                Matcher m = p.matcher(indicatorTitle.toLowerCase());

                if (m.find())
                    indicatorObjects.add(indicatorObj); // Match on keyword: add this indicator
                else {
                    if (COMMENTS) out.println("<!-- indicatorTitle " + indicatorTitle + " did not match keyword(s) -->");
                }
            }
        } catch (Exception e) {
            
        }
    }

    final Comparator<JSONObject> IND_TITLE_COMPARATOR = new Comparator<JSONObject>() {
        public int compare(JSONObject e1, JSONObject e2) {
            if (e1 instanceof JSONObject && e2 instanceof JSONObject) {
                try {
                    String thisStr = ((JSONObject)e1).getString("title");
                    String thatStr = ((JSONObject)e2).getString("title");
                    return thisStr.compareTo(thatStr);
                } catch (Exception e) {
                    return 0;
                }
            }
            return 0;
        }
    };
    Collections.sort(indicatorObjects, IND_TITLE_COMPARATOR);

    List<String> listed = new ArrayList<String>(); // Keep track of which indicators are already listed
    
    Iterator<JSONObject> itr = indicatorObjects.iterator();
    if (itr.hasNext()) {
        out.println("<ul>");
        while (itr.hasNext()) {
            JSONObject ind = itr.next();

            try {
                indId = ind.getString("id"); // Get the indicator's ID
                
                if (listed.contains(indId))
                    continue;
                else
                    listed.add(indId);
                    
                indTitle = ind.getString("title"); // Get the indicator's title
                indUrl = ind.getString("url"); // Get the indicator's title
            } catch (NullPointerException npe) {
                // Avoid NPE
                continue;
            }
            //out.println("<li><a href=\"http://mosj.npolar.no/i?id=" + indId + "&amp;locale=" + loc + "\">" + "<span>" + indTitle + "</span>" + "</a></li>");
            out.println("<li><a href=\"" + indUrl + "\">" + "<span>" + indTitle + "</span>" + "</a></li>");
        }
        out.println("</ul>");
    } else {
        out.println("<p>" + cms.labelUnicode("label.species.mosjindicators.none") + ".</p>");
    }
}
catch (Exception e) {
    showError(cms, out, "Unable to list MOSJ indicators.".concat(loggedInUser ? " Error was: ".concat(e.getMessage()) : ""));
}
%>