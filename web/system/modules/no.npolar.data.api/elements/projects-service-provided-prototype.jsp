<%-- 
    Document   : projects-service-provided-prototype (previously: projects-service-provided and project-index-json)
    Description: Lists projects using the data.npolar.no API.
    Created on : Aug 29, 2013, 9:09:42 AM
    Author     : flakstad
--%><%@page import="java.util.Locale,
            java.net.URLDecoder,
            java.net.URLEncoder,
            org.opencms.main.OpenCms,
            org.opencms.util.CmsStringUtil,
            org.opencms.util.CmsRequestUtil,
            java.io.InputStreamReader,
            java.io.BufferedReader,
            java.net.URLConnection,
            java.net.URL,
            java.net.HttpURLConnection,
            java.util.ArrayList,
            org.opencms.json.JSONArray,
            java.util.Date,
            java.util.Map,
            java.util.Iterator,
            java.text.SimpleDateFormat,
            no.npolar.util.CmsAgent,
            org.opencms.json.JSONObject,
            org.opencms.json.JSONException"
            contentType="text/html" 
            pageEncoding="UTF-8" 
            session="true" 
 %><%!
 public String getFacets(CmsAgent cms, JSONArray facets) throws JSONException {
     String s = "<section class=\"clearfix quadruple layout-row overlay-headings\">";
     s += "<div class=\"boxes\">";
     
     for (int i = 0; i < facets.length(); i++) {
         JSONObject facetSet = facets.getJSONObject(i);
         String facetSetName = facetSet.names().get(0).toString();
         JSONArray facetArray = facetSet.getJSONArray(facetSetName);
         if (facetArray.length() > 0) { 
            s += "<div class=\"span1 featured-box\">";
            s += "<h3>" + capitalize(facetSetName) + "</h3>";
            s += "<ul>";
            for (int j = 0; j < facetArray.length(); j++) {
                JSONObject facet = facetArray.getJSONObject(j);
                String facetLink = getFacetLink(cms, facet);
                s += "<li>" + facetLink + "</li>";
            }
            s += "</ul></div>";
         }
     }
     s += "</div></section>";
     return s;
 }
 
 public String getFacetLink(CmsAgent cms, JSONObject facetDetails) throws JSONException {
     String facetText = facetDetails.get("term").toString();
     String facetCount = facetDetails.get("count").toString();
     String facetUri = cms.getRequestContext().getUri().concat("?").concat(getParameterString(facetDetails.get("uri").toString()));
     return "<a href=\"" + cms.link(facetUri) + "\">" + facetText + " (" + facetCount + ")</a>";
 }
 
 public String stringify(JSONArray a, boolean asListItems) {
    try {
        String s = "";
        for (int i = 0; i < a.length(); i++) {
            if (asListItems)
                s += "<li>" + a.getString(i) + "</li>";
            else {
                if (i > 0) 
                    s += ", ";
                s += a.getString(i);
            }
        }
        
        return s;
    } catch (Exception e) {
        return null;
    }
}
public static String getParameterString(String theURL) {
    try {
        return theURL.split("\\?")[1];
    } catch (ArrayIndexOutOfBoundsException e) {
        return theURL;
    }  
}

/**
 * Requests the given URL and returns the response content payload as a string.
 */
public String getResponseContent(String requestURL) {
    try {
        URLConnection connection = new URL(requestURL).openConnection();
        StringBuffer buffer = new StringBuffer();
        BufferedReader reader = new BufferedReader(new InputStreamReader(connection.getInputStream()));
        String inputLine;
        while ((inputLine = reader.readLine()) != null) {
            buffer.append(inputLine);
        }
        reader.close();
        return buffer.toString();
    } catch (Exception e) {
        // Unable to contact or read the DB service
        return null;
    }
}

public static String getQueryParams(CmsAgent cms, boolean includeStart) {
    String s = "?";
    int i = 0;
    Map<String, String[]> pm = cms.getRequest().getParameterMap();
    
    if (!pm.isEmpty()) {
        Iterator<String> pNames = pm.keySet().iterator();
        while (pNames.hasNext()) {
            String pName = pNames.next();
            if ("start".equals(pName) && !includeStart)
                continue;
            String pValue = "";
            try { pValue = URLEncoder.encode(pm.get(pName)[0], "utf-8"); } catch (Exception e) { pValue = ""; }
            s += (++i > 1 ? "&" : "") + pName + "=" + pValue;
        }
    }
    else {
        String start = cms.getRequest().getParameter("start");

        // Query
        try {
            s += "q=" + URLEncoder.encode(getParameter(cms, "q"), "utf-8");
        } catch (Exception e) {
            s += "q=" + getParameter(cms, "q");
        }

        // Items per page
        s += "&limit=" + getLimit(cms);

        // Start index
        if (includeStart && (start != null && !start.isEmpty()))
            s += "&start=" + start;

        // Format
        s += "&format=json";
    }
    return s;
}

public static String getParameter(CmsAgent cms, String paramName) {
    String param = cms.getRequest().getParameter(paramName);
    return param != null ? param : "";
}

public static String getLimit(CmsAgent cms) {
    return getParameter(cms, "limit").isEmpty() ? "10" : getParameter(cms, "limit");
}

public static String capitalize(String s) {
    try {
        return s.replaceFirst(String.valueOf(s.charAt(0)), String.valueOf(s.charAt(0)).toUpperCase());
    } catch (Exception e) {
        return s;
    }
}

%><%


        CmsAgent cms = new CmsAgent(pageContext, request, response);
        String requestFileUri = cms.getRequestContext().getUri();
        Locale locale = cms.getRequestContext().getLocale();
        String loc = locale.toString();
        
        final String DETAILS_URI = loc.equalsIgnoreCase("no") ? "detaljer" : "details";
        
        final String LABEL_MATCHES_FOR = cms.label("label.np.matches.for");
        final String LABEL_SEARCH_PROJECTS = loc.equalsIgnoreCase("no") ? "Søk i prosjekter" : "Search projects";
        final String LABEL_SEARCH = cms.label("label.np.search");
        final String LABEL_NO_MATCHES = cms.label("label.np.matches.none");
        final String LABEL_MATCHES = cms.label("label.np.matches");
        final String LABEL_FILTERS = cms.label("label.np.filters");
        
        final boolean EDITABLE_TEMPLATE = false;
        
        // Call master template (and output the opening part - hence the [0])
        //cms.include(cms.getTemplate(), cms.getTemplateIncludeElements()[0], EDITABLE_TEMPLATE);
        
        // Construct the URL to the service providing all neccessary data
        //String queryURL = "http://apptest.data.npolar.no:9000/project/" + getQueryParams(cms, true);
        String queryURL = "http://api.npolar.no:80/project/" + getQueryParams(cms, true);
        
        //out.println("<!-- using service URL " + queryURL + " -->");
        
        
        //String queryURL = "http://apptest.data.npolar.no:9666/project/" + getQueryParams(cms, true);
        
        JSONObject json = null;
        try {
            // Read the JSON string
            String jsonStr = getResponseContent(queryURL);

            try {
                // Create the JSON object from the JSON string
                json = new JSONObject(jsonStr).getJSONObject("feed");
            } catch (Exception jsone) {
                %>
                <pre>
                <% jsone.printStackTrace(response.getWriter()); %>
                </pre>    
                <%
                return;
            }

            // Date formats
            //SimpleDateFormat dfParse = new SimpleDateFormat("yyyy-dd-MM");
            SimpleDateFormat dfParse = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'");
            SimpleDateFormat dfPrint = new SimpleDateFormat("d MMM yyyy");

            // Reference date
            Date now = new Date();





            // Project data variables
            String title = null;
            String acronym = null;
            String startDateStr = null;
            String endDateStr = null;
            String summary = null;
            String keywordStr = null;
            String id = null;

            // Various JSON variables
            JSONObject openSearch = json.getJSONObject("opensearch");
            int totalResults = openSearch.getInt("totalResults");
            
            
            
            


            if (totalResults > 0) {
                
                // Query 
                %>
                <div class="searchbox-big">
                    <h2><%= LABEL_SEARCH_PROJECTS %></h2>
                    <form action="<%= cms.link(requestFileUri) %>" method="get">
                        <input name="q" type="search" value="<%= CmsStringUtil.escapeHtml(getParameter(cms, "q")) %>" style="padding: 0.5em; font-size: larger;" />
                        <input name="limit" type="hidden" value="<%= getLimit(cms) %>" />
                        <input name="format" type="hidden" value="json" />
                        <input name="start" type="hidden" value="0" />
                        <input type="submit" value="<%= LABEL_SEARCH %>" />
                    </form>
                    <div id="filters-wrap"> 
                        <a id="filters-toggler" onclick="$('#filters').slideToggle();"><%= LABEL_FILTERS %></a>
                        <div id="filters">
                            <%= getFacets(cms, json.getJSONArray("facets")) %>
                        </div>
                    </div>
                </div>
                <%
                
                
                //
                // facets
                //
                
                
                int itemsPerPage = openSearch.getInt("itemsPerPage");
                int startIndex = openSearch.getInt("startIndex");
                int pageNumber = (startIndex + itemsPerPage) / itemsPerPage;
                int pagesTotal = (int)(Math.ceil((double)(totalResults + itemsPerPage) / itemsPerPage)) - 1;

                JSONObject list = json.getJSONObject("list");
                String next = null;
                try { next = list.getString("next"); } catch (Exception e) {  } ;
                String prev = list.getString("previous");
                //try { prev = list.getString("previous"); } catch (Exception e) {  } ;

                JSONObject search = json.getJSONObject("search");
                //JSONArray facets = json.getJSONArray("facets");





                JSONArray projects = json.getJSONArray("entries");
            
                %>
                <h2 style="color:#999; border-bottom:1px solid #eee;"><%= totalResults %> <%= LABEL_MATCHES.toLowerCase() %>
                    <!--<em><%= CmsStringUtil.escapeHtml(getParameter(cms, "q")) %></em>-->
                </h2>
                <ul class="pagelist" style="margin: 0; padding: 0; display: block;">
                <%
                for (int pCount = 0; pCount < projects.length(); pCount++) {
                    JSONObject project = projects.getJSONObject(pCount);

                    // Mandatory fields

                    title = project.getString("title");
                    //summary = project.getString("summary");
                    startDateStr = project.getString("start_date");
                    id = project.getString("id");

                    // Optional fields
                    //try { acronym = project.getString("acronym"); } catch (JSONException je) { }
                    try { endDateStr = project.getString("end_date"); } catch (JSONException je) { }

                    String status = "";
                    Date startDate = null;
                    Date endDate = null;
                    try {
                        while (true) {
                            // Case: End date in the past
                            if (endDateStr != null) {
                                endDate = dfParse.parse(endDateStr);
                                if (endDate.before(now)) {
                                    status = "Completed";
                                    break;
                                }
                            }
                            // Case: End date in the future
                            startDate = dfParse.parse(startDateStr);
                            if (startDate.after(now)) {
                                status = "Planned";
                                break;
                            }
                            // Case: None of the above - so start date is before now, and end date is non-existing or after now. That must mean the project is active.
                            status = "Active";
                            break;
                        }
                    } catch (Exception e) {
                        // Retain empty value for status
                    }

                    %>
                    <li style="font-size: 1em;">

                        <h3 style="margin: 1em 0 0;">
                            <a href="<%= DETAILS_URI %>?pid=<%= id %>">
                                <%= title + (acronym != null ? (" (" + project.getString("acronym") + ")") : "") %>
                            </a>
                        </h3>
                    <!--<div class="event-links nofloat" style="font-size:0.7em; padding-bottom:0.6em; margin-top:1em; margin-bottom:2em;">-->
                    <span class="smalltext">Status: 
                        <%= status + " (" 
                            + (status.equals("Active") && endDateStr == null ? "Since " : "") 
                                + dfPrint.format(dfParse.parse(startDateStr)) + (endDateStr != null ? (" &ndash; " + dfPrint.format(dfParse.parse(endDateStr))) : "") 
                            + ")" 
                        %>
                    </span>
                </li>






            <%      
            }  
                %>
                </ul>
                
                <nav class="pagination clearfix">
                    <div class="pagePrevWrap">
                        <% 
                        if (prev != null) {
                            if (pageNumber > 1) { // At least one previous page exists
                            %>
                                <a class="prev" href="<%= prev.equals("false") ? "#" : cms.link(requestFileUri + "?" + getParameterString(prev)) %>"><</a>
                            <% 
                            }
                            else { // No previous page
                            %>
                                <a class="prev inactive"><</a>
                            <%
                            }
                        }
                        %>
                    </div>
                    <div class="pageNumWrap">
                        <%
                        for (int pageCounter = 1; pageCounter <= pagesTotal; pageCounter++) {
                            boolean splitNav = pagesTotal >= 8;
                            // if (first page OR last page OR (pages total > 10 AND (this page number > (current page number - 4) AND this page number < (current page number + 4)))
                            // Pseudo: if this is the first page, the last page, or a page close to the current page (± 4)
                            if (!splitNav
                                        || (splitNav && (pageCounter == 1 || pageCounter == pagesTotal))
                                        //|| (pagesTotal > 10 && (pageCounter > (pageNumber-4) && pageCounter < (pageNumber+4)))) {
                                        || (splitNav && (pageCounter > (pageNumber-3) && pageCounter < (pageNumber+3)))) {
                                if (pageCounter != pageNumber) { // Not the current page: print a link
                                %>
                                    <a href="<%= cms.link(requestFileUri + getQueryParams(cms, false) + "&start=" + ((pageCounter-1) * itemsPerPage)) %>"><%= pageCounter %></a>
                                <% 
                                }
                                else { // The current page: no link
                                %>
                                    <span class="currentpage"><%= pageCounter %></span>
                                <%
                                }
                            }
                            // Pseudo: 
                            else if (splitNav && (pageCounter == 2 || pageCounter+1 == pagesTotal)) { 
                            %>
                                <span> &hellip; </span>
                            <%
                            } else {
                                out.println("<!-- page " + pageCounter + " dropped ... -->");
                            }
                        } 
                        %>
                    </div>
                    <div class="pageNextWrap">
                        <!--<span>Page <%= pageNumber %> of <%= pagesTotal %></span>-->
                        

                        <% 
                        if (next != null) { 
                            if (pageNumber < pagesTotal) {
                                %>
                                <a class="next" href="<%= next.equals("false") ? "#" : cms.link(requestFileUri + "?" + getParameterString(next)) %>">></a>
                                <% 
                            }
                            else {
                                %>
                                <a class="next inactive">></a>
                                <%
                            }
                        }
                        %>
                    </div>
                </nav>
                <%
            }
            else {
                out.println("<h2 style=\"color:#999;\">" + LABEL_NO_MATCHES + "</h2>");
            }
        //*  
        } catch (Exception e) {
            out.println("<div class=\"paragraph\"><p>An error occured. Please try a different search or come back later.</p></div>");
            /*
            out.println("<pre>");
            e.printStackTrace(response.getWriter());
            out.println("</pre>");
            //*/ 
        }
        //*/
        
            
        
        %>
        <div style="background: #f5f5f5; padding: 1em; margin: 1em auto; color: #bbb;">
            Raw data at <a style="color: #bbb;" href="<%= queryURL %>"><%= queryURL %></a>
        </div>      
        <script type="text/javascript">$("#filters").hide();</script>
        
        <%
        // Call master template (and output the closing part - hence the [1])
        //cms.include(cms.getTemplate(), cms.getTemplateIncludeElements()[1], EDITABLE_TEMPLATE);
        %>
