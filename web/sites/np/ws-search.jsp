<%-- 
    Document   : ws-search
    Description: A search that acts like a web service, providing search results
                    as JSON / JSONP. Request with a parameter string like:
                    ?q=myquery&limit=20&index=my_search_index_name&callback=myFunctionName
    Created on : 1 Dec 2014
    Author     : Paul-Inge Flakstad <flakstad at npolar.no>, Norwegian Polar Institute
--%><%@page import="
            java.util.ArrayList,
            java.util.Arrays,
            java.util.Iterator,
            java.util.List,
            java.util.Locale,
            org.opencms.jsp.CmsJspActionElement,
            org.opencms.main.OpenCms,
            org.opencms.search.CmsSearch,
            org.opencms.search.CmsSearchResult,
            org.opencms.flex.CmsFlexController,
            org.opencms.file.CmsObject"
            contentType="text/html" 
            pageEncoding="UTF-8" 
            session="true" 
 %><%!
/**
 * Escapes any double quoutes in the given string.
 * @param escapeMe The string to escape.
 * @return The given string, with any double quotes escaped.
 */ 
public String escapeQuotes(String escapeMe) {
    if (escapeMe == null || escapeMe.isEmpty())
        return escapeMe;
    return escapeMe.replace("\"", "\\\"");
}
%><%
// JSP action element + CMS object instances
CmsJspActionElement cms = new CmsJspActionElement(pageContext, request, response);
CmsObject cmso = cms.getCmsObject();


//
// Begin: Handle parameters
//

// Determine the MIME sub-type by checking if a "callback" parameter exists
String mimeSubType = "json";
String callback = request.getParameter("callback");
if (callback != null && !callback.isEmpty()) {
    mimeSubType = "javascript";
}

// The query
String query = request.getParameter("q");
if (query == null) {
    query = "";
}

// The max. number of results to return
int numResults = 30; // Default
try {
    numResults = Integer.valueOf(request.getParameter("limit"));
} catch (Exception e) {
    // Keep default
}

// The name of the index to use in the search
String indexName = request.getParameter("index");
if (indexName == null) {
    try {
        indexName = cmso.readPropertyObject("/", "search.index", true).getValue(""); // Default - note that the index should be set with more care (this is very unspecific)
    } catch (Exception e) {
        // No index name => will of course result in no hits
    }
}

//
// End: handle parameters
//


// !!! IMPORTANT !!! 
// Set reponse header to one of:
// * "application/json"
// * "application/javascript"
CmsFlexController.getController(request).getTopResponse().setHeader("Content-Type", "application/" + mimeSubType + "; charset=utf-8");


// Set up search
CmsSearch search = new CmsSearch();
search.init(cmso);
search.setMatchesPerPage(numResults);
search.setField(new String[] {
    "title",
    "keywords",
    "description",
    "path"
});
search.setIndex(indexName);
search.setQuery(query);

// Do search
List<CmsSearchResult> hits = new ArrayList<CmsSearchResult>();
try {
    hits = search.getSearchResult();
} catch (java.lang.NullPointerException npe) {
    // Houston we have a problem
}


////////////////////////////////////////////////////////////////////////////////
// Response output
//
if (callback != null && !callback.isEmpty()) {
    out.print(callback + "(");
}
out.print("[");
if (query != null && !query.isEmpty()) {

    try {
        if (search.getSearchResultCount() > 0 && !hits.isEmpty()) {
            String entries = "";
            
            Iterator<CmsSearchResult> i = hits.iterator();
            while (i.hasNext()) {
                CmsSearchResult hit = i.next();
                entries += "{";
                entries += "\"value\": \"" +  hit.getPath() + "\",";
                entries += "\"label\": \"" + escapeQuotes(hit.getTitle()) + "\",";
                entries += "\"description\": \"" + escapeQuotes(hit.getDescription()) + "\"";
                entries += "}";
                if (i.hasNext())
                    entries += ",";
            }
            out.print(entries);
        }
        
    } catch (Exception e) {}
}
out.print("]");
if (callback != null && !callback.isEmpty()) {
    out.print(")");
}
%>