<%-- 
    Document   : searchresult
    Created on : 17.mar.2011, 16:18:00
    Author     : Paul-Inge Flakstad <flakstad at npolar.no>
--%>
<%@page import="org.opencms.util.CmsStringUtil"%>
<%@page import="no.npolar.util.CmsAgent"%>
<%@page import="org.opencms.main.*"%>
<%@page import="org.opencms.security.CmsRoleManager"%>
<%@page import="org.opencms.security.CmsRole"%>
<%@page import="org.opencms.search.*"%>
<%@page import="org.opencms.search.fields.*"%>
<%@page import="org.opencms.file.*"%>
<%@page import="org.opencms.json.*"%>
<%@page import="org.opencms.jsp.*"%>
<%@page import="java.util.*"%>
<%@page import="java.net.*"%>
<%@page import="no.npolar.data.api.*"%>
<%@page import="no.npolar.util.search.SearchResults"%>
<%@page import="no.npolar.util.search.SearchResultHit"%>
<%@page import="no.npolar.util.search.SearchSource"%>
<%@page trimDirectiveWhitespaces="true" pageEncoding="UTF-8" session="true" buffer="none" %>
<%@taglib prefix="cms" uri="http://www.opencms.org/taglib/cms"%>
<%!
    
    /**Used for notes to the end user; error messages, size trims, etc. */
    public static String note = "";
/*
    public void queryPublications(Locale locale, String query) {
        PublicationService service = new PublicationService(locale);
        service.setAllowDrafts(false).addDefaultFilter(
                Publication.Key.STATE, 
                Publication.Val.STATE_PUBLISHED
        ).addDefaultFilter(
                Publication.Key.ORGS_ID,
                Publication.Val.ORG_NPI_GENERIC
        );
    }
//*/

    /**
     * Adds employee results to the given SERP.
     * <p>
     * ToDo: Use the standard no.npolar.data.api.PersonService instead.
     */
    public static void addEmployeesSerp(CmsJspActionElement cms, String query, SearchResults serp) throws Exception {

        Locale preferredLocale = cms.getRequestContext().getLocale();
        try {
            PersonService service = new PersonService(preferredLocale);

            service.addDefaultParameter(
                    PersonService.Param.FORMAT, 
                    PersonService.ParamVal.FORMAT_JSON
            ).addDefaultParameter(
                    PersonService.Param.FACETS, 
                    PersonService.ParamVal.FACETS_NONE
            ).addDefaultParameter(
                    PersonService.Param.RESULTS_LIMIT, 
                    PersonService.ParamVal.RESULTS_LIMIT_NO_LIMIT
            );
            service.setFreetextQuery(URLEncoder.encode(query, "UTF-8"));

            List<Person> hits = service.getPersonList();

            String sourceName = preferredLocale.toString().equals("no") ? "Ansatte" : "Employees";
            String rootFolder = preferredLocale.toString().equals("no") ? "/no/ansatte/" : "/en/people/";

            for (Person hit : hits) {

                String id = null;
                String title = null;
                String firstName = null;
                String lastName = null;
                String name = null;
                String jobTitle = null;
                String personUrl = null;

                // Mandatory fields
                try {
                    id = hit.getId();
                    firstName = hit.getFirstName();
                    lastName = hit.getLastName();
                    //personFolder = EMPLOYEES_FOLDER + id + "/";
                    personUrl = rootFolder+id;
                    name = firstName + " " + lastName;
                } catch (Exception e) { 
                    // Error on a mandatory field => cannot output this
                    continue; 
                }
                // Optional fields
                try { title = hit.getTitle(); title.length(); } catch (Exception e) { title = ""; }
                try { jobTitle = hit.getPositions().get(0); jobTitle.length(); } catch (Exception e) { jobTitle = ""; }

                int score = 95; // Default score (very high, but not max)

                if (name.toLowerCase().contains(query.toLowerCase())) {
                    score = 100; // Max
                }

                serp.add(new SearchResultHit(name, jobTitle, null, personUrl, personUrl, sourceName, score));
            }
        } catch (Exception e) {
            // Service unavailable?
        }
    }

    public String getEmployeeLinkText(Locale locale, int numHits) {
        return locale.toString().equalsIgnoreCase("no") ?
            ("Vis ytterligere " + numHits + " treff i ansatte") :
            ("Shwo " + numHits + " more hit" + (numHits > 1 ? "s" : "") + " in employees");
    }
%>
<%    
    // Create a JSP action element
    org.opencms.jsp.CmsJspActionElement cms = new CmsJspActionElement(pageContext, request, response);
    CmsObject cmso = cms.getCmsObject();
    
    //OpenCms.getLinkManager().getP
    
    // Get the search manager
    CmsSearchManager searchManager = OpenCms.getSearchManager(); 
    String requestFileUri = cms.getRequestContext().getUri();
    String folderUri = cms.getRequestContext().getFolderUri();
    Locale locale = cms.getRequestContext().getLocale();
    String loc = locale.toString();
    
    final String URI_SEARCH_EMPLOYEES = loc.equalsIgnoreCase("no") ?
            "/no/ansatte/" :
            "/en/people/";
    final String URI_SEARCH_PUBS = loc.equalsIgnoreCase("no") ?
            "/no/publikasjoner/" :
            "/en/publications/";
    final String URI_SEARCH_PROJECTS = loc.equalsIgnoreCase("no") ?
            "/no/prosjekter/" :
            "/en/projects/";
    final String URI_SEARCH_DATASETS = loc.equalsIgnoreCase("no") ?
            "https://data.npolar.no/dataset/" :
            "https://data.npolar.no/dataset/";
    
    final String PARAM_NAME_SEARCHPHRASE_LOCAL = "query";
    final String PARAM_NAME_PREFIX_FILTER = SearchFilter.PARAM_NAME_PREFIX;
    final String PARAM_NAME_SOURCE_FILTER = "filter-source";
    
    final String LABEL_SEARCH = loc.equalsIgnoreCase("no") ? "Søk" : "Search";
    final String LABEL_FILTERS = loc.equalsIgnoreCase("no") ? "Filtre" : "Filters";
    
    final String LABEL_EMPLOYEES = loc.equalsIgnoreCase("no") ? "Ansatte" : "Employees";
    final String LABEL_PROJECTS = loc.equalsIgnoreCase("no") ? "Prosjekter" : "Projects";
    final String LABEL_PUBLICATIONS = loc.equalsIgnoreCase("no") ? "Publikasjoner" : "Publications";
    final String LABEL_DATASETS = loc.equalsIgnoreCase("no") ? "Datasett" : "Data sets";
    
    final String LABEL_SEARCH_PANEL_TITLE = loc.equalsIgnoreCase("no") ?
            "Søk i Polarinstituttets nettsider" :
            "Search the Polar Institute's web pages";
    final String LABEL_SEARCH_PANEL_DESCR = loc.equalsIgnoreCase("no") ?
            "Her kan du søke i alt innhold på dette nettstedet, samt utvalgte tjenester fra <a hreflang=\"en\" href=\"https://data.npolar.no/\">vårt datasenter</a>." :
            "This search covers all the content on this website, plus select services in <a href=\"https://data.npolar.no/\">our Data Centre</a>.";
    
    final Comparator<SearchSource> NUM_HITS_COMP = new Comparator<SearchSource>() {
        public int compare(SearchSource thisOne, SearchSource thatOne) {
            if (thisOne.getNumHits() < thatOne.getNumHits())
                return 1;
            else if (thisOne.getNumHits() > thatOne.getNumHits())
                return -1;
            return 0;
        }
    };
    
    // Hold all hits to display
    SearchResults serp = new SearchResults();
    // The query string
    String q = request.getParameter(PARAM_NAME_SEARCHPHRASE_LOCAL);
    if (q == null) {
        q = "";
    }
    // The selected source (if any)
    String sourceSelected = request.getParameter(PARAM_NAME_SOURCE_FILTER);
    
    
    if (q != null && !q.isEmpty()) {

        try {
            if (sourceSelected == null || sourceSelected.equals("people")) {
                //addEmployeesSerp(cms, q, serp);
            }
        } catch (Exception e) {
            note += "<p>En feil oppsto da vi så etter treff i lista over ansatte.<br />Vi kan derfor ikke vise deg treff fra denne.</p>";
        }
    }
    

%>
<jsp:useBean id="search" scope="request" class="org.opencms.search.CmsSearch">
    <jsp:setProperty name="search" property="matchesPerPage" param="matchesperpage"/>
    <jsp:setProperty name="search" property="displayPages" param="displaypages"/>
    <jsp:setProperty name="search" property="*"/>
    <% 
    boolean userIsWorkplaceUser = OpenCms.getRoleManager().hasRole(cms.getCmsObject(), CmsRole.WORKPLACE_USER);

    // Get the search manager
    //CmsSearchManager searchManager = OpenCms.getSearchManager(); 

    //
    // Set the index
    //

    // Try to retrieve the index name from file property
    String indexName = cms.property("search.index", "search");
    // If the index name was not set as a property, set default value
    if (indexName == null) {
        // default index names (these may not exist -> exception must be caught in SEARCH_RESULT_PAGE)
        //throw new JspException("No search index defined. Use the search.index property to define one.");
        indexName = "npi_no_online";
    }
    // If the user is logged in, use the offline search index
    if (userIsWorkplaceUser) {
        indexName = indexName.replace("_online", "_offline");
    }
    search.setIndex(indexName);
    //search.setQuery(URLDecoder.decode(search.getQuery(), "utf-8"));
    
    search.init(cms.getCmsObject());
    //search.setMatchesPerPage(Integer.MAX_VALUE);
    %>
</jsp:useBean>

<cms:include property="template" element="header" />


<article class="main-content">
    <h1><cms:property name="Title" /></h1>
<%
    int resultno = 1;
    int pageno = 0;
    int pageNum = 1;
    int pagesTotal = 1;
    int resultsPerPage = 20;
    int firstResultIndex = 0;
    int lastResultIndex = 0;
    
    //if (request.getParameter("searchPage") != null) {
    //        pageno = Integer.parseInt(request.getParameter("searchPage")) - 1;
    //}
    try {
        pageNum = Integer.valueOf(request.getParameter("page"));
        if (pageNum < 1) {
            pageNum = 1;
        }
    } catch (Exception e) {
        
    }
    
    try {
        resultsPerPage = Integer.valueOf(request.getParameter("matchesperpage"));
    } catch (Exception e) {
        // not a number
    }
    
    search.setMatchesPerPage(resultsPerPage);
    search.setSearchPage(pageNum);
    List<CmsSearchResult> ocmsResults = search.getSearchResult();
    if (ocmsResults == null) {
        // Prevent null pointer exception
        ocmsResults = new ArrayList<CmsSearchResult>(0);
    }
    int numResults = search.getSearchResultCount();
    
    firstResultIndex = ((pageNum - 1) * resultsPerPage);
    lastResultIndex = firstResultIndex + resultsPerPage - 1;
    
    String navNext = null;
    String navPrev = null;
    
    /*
    //String fields = search.getFields();
    String fields = "title content";
    if (fields == null) {
        fields = request.getParameter("fields");
    }
    //*/
    /*
    List result = null;
    try {
        result = search.getSearchResult();
    } catch (java.lang.NullPointerException npe) {
        
        String errorMessage = loc.equalsIgnoreCase("no") ? 
            "<p>Det ser ut som at du ikke har søkt på noe(?). Bruk søkefeltet for å søke, eller kontakt oss hvis du mener noe har gått galt.</p>" :
            "<p>It seems you did't search for anything(?). Please use the search field to search, or contact us if you think an error occurred.</p>";
            
        out.println(errorMessage);
        
    }
    //*/
    
    StringBuilder siteResults = new StringBuilder(512);
    
    if (sourceSelected == null || sourceSelected.equals("pages")) {
        //List<CmsSearchResult> ocmsResults = search.getSearchResult();
        Iterator<CmsSearchResult> iOcmsResults = ocmsResults.iterator();
        /*while (iOcmsResults.hasNext()) {
            CmsSearchResult ocmsResult = iOcmsResults.next();
            serp.add(new SearchResultHit(
                    ocmsResult.getField(CmsSearchField.FIELD_TITLE)
                    ,ocmsResult.getExcerpt()
                    ,null
                    ,cms.link(cms.getRequestContext().removeSiteRoot(ocmsResult.getPath()))
                    ,OpenCms.getLinkManager().getOnlineLink(cms.getCmsObject(), cms.getRequestContext().removeSiteRoot(ocmsResult.getPath()))
                    ,"pages"
                    ,ocmsResult.getScore())
            );
        }*/
    }
    
    // DEBUG:
    /*
    out.println("<h4>Fields: " + fields + "</h4>");
    out.println("<h4>Resultno: " + resultno + "</h4>");
    out.println("<h4>Pageno: " + pageno + "</h4>");
    out.println("<h4>Result (List): " + result + "</h4>");
    */
	
    /*
    if (result == null) {
        if (search.getLastException() != null) {
            out.println("<h3>Error</h3>" + search.getLastException().toString());
        }
    } 
    else {
    //*/
    //int numResults = serp.size();
    if (lastResultIndex > numResults) {
        lastResultIndex = numResults - 1;
    }
    
    
    pagesTotal = (numResults / resultsPerPage) + (numResults % resultsPerPage > 0 ? 1 : 0);
    
    if (pageNum > 1) {
        // Previous page exists
        navPrev = cms.link(requestFileUri + "?query=" + URLEncoder.encode(q, "UTF-8") + "&amp;page=" + (pageNum-1));
    }
    
    if (pageNum < pagesTotal) {
        // Next page exists
        navNext = cms.link(requestFileUri + "?query=" + URLEncoder.encode(q, "UTF-8") + "&amp;page=" + (pageNum+1));
    }
        /*
        Iterator<SearchResultHit> iterator;
        if (numResults <= resultsPerPage) {
            iterator = serp.iterator();
        } else {
            List<SearchResultHit> pageResults = serp.getHits().subList(firstResultIndex, lastResultIndex);
            iterator = pageResults.iterator();
        }
        
        String filters = "";
        if (sourceSelected != null) {
            // User has opted to display hits from specific source
            filters += "<li>"
                        + "Viser nå kun treff i &laquo;" + sourceSelected + "&raquo;<br />"
                        + "<a class=\"button\" href=\"" + requestFileUri + "?" + PARAM_NAME_SEARCHPHRASE_LOCAL + "=" + q + "\">"
                            + "Vis treff i alle kilder"
                        + "</a></li>";
        } else {
            try {
                
                List<SearchSource> sources = serp.getSources();
                if (sources != null && !sources.isEmpty()) {
                    //Collections.sort(sources, NUM_HITS_COMP); // Only 1 source => no need to sort
                    Iterator<SearchSource> iSources = sources.iterator();
                    while (iSources.hasNext()) {
                        SearchSource source = iSources.next();
                        filters += "<li>"
                                    + "<a class=\"button\""
                                            + " href=\"" + requestFileUri + "?" 
                                                + PARAM_NAME_SEARCHPHRASE_LOCAL + "=" + q 
                                                + "&amp;" + PARAM_NAME_SOURCE_FILTER + "=" + source.getName() 
                                        + "\">" 
                                        + source.getName() + " (" + source.getNumHits() + ")" 
                                    + "</a></li>";
                    }
                }
            } catch (Exception e) {}
        }
        //*/

        %>
        <form class="search-panel" action="<%= cms.link(requestFileUri) %>" method="get">
        
            <h2 class="search-panel__heading"><%= LABEL_SEARCH_PANEL_TITLE %></h2>
            <p class="smalltext"><%= LABEL_SEARCH_PANEL_DESCR %></p>
            
            <div class="search-widget">
                <div class="searchbox">
                    <input name="query" type="search" value="<%= q %>">
                    <input class="search-button" type="submit" value="Søk">
                </div>
            </div>
            <!--
            <div class="search-panel__filters" style="text-align:center;">
                <ul class="filters filters--simple list--inline">
                    <%= ""/*filters*/ %>
                </ul>
            </div>
            -->
            <div id="extras">
                <ul class="list--inline">
                    <li><a class="button" id="search-people" href="<%= URI_SEARCH_EMPLOYEES %>?q=<%= q %>">
                            <i class="icon icon-address-book"></i> <%= LABEL_EMPLOYEES %>
                        </a>
                    </li>
                    <li><a class="button" id="search-pubs" href="<%= URI_SEARCH_PUBS %>?q=<%= q %>">
                            <i class="icon icon-book"></i> <%= LABEL_PUBLICATIONS %>
                        </a>
                    </li>
                    <li><a class="button" id="search-projects" href="<%= URI_SEARCH_PROJECTS %>?q=<%= q %>">
                            <i class="icon icon-users"></i> <%= LABEL_PROJECTS %>
                        </a>
                    </li>
                    <li><a class="button" id="search-datasets" href="<%= URI_SEARCH_DATASETS %>?q=<%= q %>&amp;not-draft=yes">
                            <i class="icon icon-database"></i> <%= LABEL_DATASETS %>
                        </a>
                    </li>
                </ul>
                <ul id="employees" class="layout-group triple clearfix"></ul>
            </div>
        </form>
        
        <% if (!q.isEmpty()) { %>
        <h3><%= numResults %><%= (loc.equalsIgnoreCase("no") ? 
        " resultater for " : " results found for ")%><i><%= q %></i></h3>
        
        <%
        } 
        // Website hits
        Iterator<CmsSearchResult> iterator = ocmsResults.iterator();
        while (iterator.hasNext()) {
            /*
            SearchResultHit hit = iterator.next();
            String snippet = hit.getSnippet();
            String hitPath = hit.getUri();//cms.link(cms.getRequestContext().removeSiteRoot(entry.getPath()));
            //*/
            CmsSearchResult hit = iterator.next();
            String snippet = hit.getExcerpt();
            if (snippet == null) { snippet = ""; }
            String hitPath = cms.link(hit.getPath());
            String displayPath = cmso.getRequestContext().removeSiteRoot(hitPath);
            
            // Hide pages with title = "null"
            //if (entry.getField(CmsSearchField.FIELD_TITLE) != null && !entry.getField(CmsSearchField.FIELD_TITLE).equalsIgnoreCase("null")) {
            %>
                <h3 class="searchHitTitle" style="padding:1em 0 0.2em 0; margin:0;">
                    <a href="<%= hitPath %>"><%= hit.getTitle() %></a>
                </h3>
                <div class="text">
                    <%= snippet != null ? snippet : "" %>
                </div>
                <div class="search-hit-path" style="font-size:0.75em; color:green;">
                    <%= hitPath %>
                </div>
            <%
            //}
            //resultno++;
        }
    //}

    if (numResults > resultsPerPage) {
        String pageInfo = loc.equalsIgnoreCase("no") ?
                    ("Side " + pageNum + " av " + pagesTotal) :
                    ("Page " + pageNum + " of " + pagesTotal);
        %>
        <nav class="pagination clearfix">
            <div class="pagination__page-wrap pagination__page-wrap--prev pagePrevWrap">
                <a class="pagination__page pagination__page--prev prev <%= navPrev == null ? "inactive" : "" %>" href="<%= navPrev == null ? "" : navPrev %>"></a>
            </div>
            <div class="pagination__page-wrap pagination__page-wrap--numbers pageNumWrap">
                <%= pageInfo %>
            </div>
            <div class="pagination__page-wrap pagination__page-wrap--next pageNextWrap">
                <a class="pagination__page pagination__page--next next <%= navNext == null ? "inactive" : "" %>" href="<%= navNext == null ? "" : navNext %>"></a>
            </div>
        </nav>
        <%
    }

%>
</article>
<script>
$(document).ready(function() {
    

// Shared query parameters for all NPDC requests
var baseQuery = {
    'q': '<%= CmsStringUtil.escapeJavaScript(q) %>',
    'not-draft' : 'yes',
    'facets':'false',
    'limit':'0',
    'format':'json'
};
// Will hold specific custom parameters that extend the base parameters
var ajaxQuery;// = JSON.parse(JSON.stringify(baseQuery));
    
$('#extras').css({padding:'0 1em 1em 1em'});
var pageLang = '<%= loc %>';
var employeeHeadings = {
    no: 'Ansatte som matchet',
    en: 'Employee matches'
};

function getEmployeeLink(hits, q) {
    var paths = {
        no : '<%= cms.link("/no/ansatte/") %>',
        en : '<%= cms.link("/en/people/") %>'
    };
    var labels = {
        no : '+ ' + hits + ' treff i ansatte&hellip;',
        en : '+ ' + hits + ' more hit' + (hits > 1 ? 's' : '') + ' in employees&hellip;'
    }
    return '<a class="button" href="' + paths[pageLang] + '?q=' + q + '" style=""><i class="icon icon-address-book"></i> ' + labels[pageLang] + '</a>';
}

// Inject employee hits as cards
var personQueryParams = {
    q: '<%= CmsStringUtil.escapeJavaScript(q) %>', 
    lang: pageLang
}
<%
//if (!q.isEmpty()) {
%>
$.getJSON('/ws-employees', personQueryParams, function(data) {
    var hits = 0;
    var maxItems = 3;
    $.each(data, function(index, item) {
        if (index < maxItems) {
            $('#employees').append(
                $('<li class="layout-box">'
                    + '<a class="card card--h card--symbolic" href="' + item.value +'">'
                        + '<i class="card__icon icon-user"></i>'
                        + '<div class="card__content">'
                            + '<h5 class="card__title">' + item.label + '</h5>'
                            + '<p style="overflow: hidden; text-overflow: ellipsis;">' + item.description + '</p>'
                        + '</div>'
                    + '</a>'
                + '</li>')
            );
        }
        hits++;
    });
    if (hits > 0) {
        $('#employees').before('<h4 style="text-align: left;">' + employeeHeadings[pageLang] + '</h4>');
        $('#search-people').remove();
    } else {
        // Inject hits in employees 
        // ToDo: Fix bug here, probably related to URL-encoding in ws-employees
        //      => it returns 0 hits for "n-ice", whereas the API returns 22 hits
        ajaxQuery = JSON.parse(JSON.stringify(baseQuery));
        ajaxQuery['filter-currently_employed'] = 'true';
        updateSearchLink('search-people', 'https://api.npolar.no/person/', ajaxQuery);
    }
    
    if (hits > maxItems) {
        $('#employees').after($('<div style="text-align: left;"></div>').append( getEmployeeLink(
                    hits-maxItems, 
                    '<%= CmsStringUtil.escapeJavaScript(q) %>'
        )));
    }
    
});
<%
//} else {
%>
/*
// Inject hits in employees 
ajaxQuery = JSON.parse(JSON.stringify(baseQuery));
ajaxQuery['filter-currently_employed'] = 'T';
updateSearchLink('search-people', 'https://api.npolar.no/person/', ajaxQuery);
//*/
<%
//}
%>
        
// Inject hits in publications
ajaxQuery = JSON.parse(JSON.stringify(baseQuery));
ajaxQuery['filter-organisations.id'] = 'npolar.no';
ajaxQuery['filter-state'] = 'accepted|published';
updateSearchLink('search-pubs', 'https://api.npolar.no/publication/', ajaxQuery);

// Inject hits in projects
ajaxQuery = JSON.parse(JSON.stringify(baseQuery));
updateSearchLink('search-projects', 'https://api.npolar.no/project/', ajaxQuery);

// Inject hits in datasets
ajaxQuery = JSON.parse(JSON.stringify(baseQuery));
updateSearchLink('search-datasets', 'https://api.npolar.no/dataset/', ajaxQuery);


/**
 * Updates a link button on this page, like "Publications".
 * @param {type} id The link's ID, like "search-datasets".
 * @param {type} queryUri The query URI, without parameters.
 * @param {type} params The query parameters.
 * @returns {undefined}
 */
function updateSearchLink(id, queryUri, params) {
    $.getJSON(queryUri, params, function(data) {
        var hits = data.feed.opensearch.totalResults;
        console.log("Found " + hits + " matches for " + id + " - " + this.url);
        var link = $('#'+id);
        link.append(' <span>(' + hits + ')</span>');
        if (hits < 1) {
            link.addClass('button--disabled');
            link.removeAttr('href');
        }
    });
}
});
</script>
<cms:include property="template" element="footer" />