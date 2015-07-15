<%-- 
    Document   : searchresult
    Created on : 17.mar.2011, 16:18:00
    Author     : Paul-Inge Flakstad <flakstad at npolar.no>
--%><%@ page import="org.opencms.main.*, 
            org.opencms.security.CmsRoleManager,
            org.opencms.security.CmsRole,
            org.opencms.search.*, 
            org.opencms.search.fields.*, 
            org.opencms.file.*, 
            org.opencms.jsp.*, 
            java.util.*,
            java.net.*" buffer="none"
%><%@ taglib prefix="cms" uri="http://www.opencms.org/taglib/cms"
%><%    
    // Create a JSP action element
    org.opencms.jsp.CmsJspActionElement cms = new CmsJspActionElement(pageContext, request, response);
    
    // Get the search manager
    CmsSearchManager searchManager = OpenCms.getSearchManager(); 
    String resourceUri = cms.getRequestContext().getUri();
    String folderUri = cms.getRequestContext().getFolderUri();
    Locale locale = cms.getRequestContext().getLocale();
    String loc = locale.toString();
%>
<jsp:useBean id="search" scope="request" class="org.opencms.search.CmsSearch">
    <jsp:setProperty name="search" property="matchesPerPage" param="matchesperpage"/>
    <jsp:setProperty name="search" property="displayPages" param="displaypages"/>
    <jsp:setProperty name="search" property="*"/>
    <% boolean userIsWorkplaceUser = OpenCms.getRoleManager().hasRole(cms.getCmsObject(), CmsRole.WORKPLACE_USER);

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
    %>
</jsp:useBean>

<cms:include property="template" element="header" />


<article class="main-content">
    <h1><cms:property name="Title" /></h1>
<%
    int resultno = 1;
    int pageno = 0;
    if (request.getParameter("searchPage") != null) {		
            pageno = Integer.parseInt(request.getParameter("searchPage")) - 1;
    }
    resultno = (pageno * search.getMatchesPerPage()) + 1;

    //String fields = search.getFields();
    String fields = "title content";
    if (fields == null) {
        fields = request.getParameter("fields");
    }

    List result = null;
    try {
        result = search.getSearchResult();
    }
    catch (java.lang.NullPointerException npe) {
        String errorMessage = loc.equalsIgnoreCase("no") ? 
            "<p>Det ser ut som at du ikke har søkt på noe(?). Bruk søkefeltet for å søke, eller kontakt oss hvis du mener noe har gått galt.</p>" :
            "<p>It seems you did't search for anything(?). Please use the search field to search, or contact us if you think an error occurred.</p>";
            
        out.println(errorMessage);
        /*
        if (!cms.getRequestContext().currentUser().isGuestUser()) {
            out.println("<h3>Script crashed!</h3>A null pointer was encountered while attempting to process the search results." +
                        " The cause may be an invalid or missing search index.<br>&nbsp;<br> Please notify the system administrator.</h3>");
            StackTraceElement[] npeStack = npe.getStackTrace();
            if (npeStack.length > 0) {
                out.println("<h4>Stack trace:</h4>"); //npe.printStackTrace(response.getWriter());
                out.println("<span style=\"display:block; width:auto; overflow:scroll; font-style:italic; color:red; border:1px dotted #555555; background-color:#DEDEDE; padding:5px;\">");
                out.println("java.lang.NullPointerException:<br>");
                for (int i = 0; i < npeStack.length; i++) {
                        out.println(npeStack[i].toString());
                }
                out.println("</span>");
            }
        }
        else {
            if (loc.equalsIgnoreCase("no")) {
                out.println("<h3>Beklager, en feil oppsto.</h3><p>Vennligst prøv igjen senere.</p>");
            } else {
                out.println("<h3>We're sorry, an error occured.</h3><p>Please try again at a later time.</p>");
            }
        }
        */
   }
	// DEBUG:
	/*
	out.println("<h4>Fields: " + fields + "</h4>");
	out.println("<h4>Resultno: " + resultno + "</h4>");
	out.println("<h4>Pageno: " + pageno + "</h4>");
	out.println("<h4>Result (List): " + result + "</h4>");
	*/
	
    if (result == null) {
    %>
    <%
        if (search.getLastException() != null) { 
            out.println("<h3>Error</h3>" + search.getLastException().toString());
        }
    } 
    else {
        ListIterator iterator = result.listIterator();
        %>
        <h3><%= search.getSearchResultCount() %><%= (loc.equalsIgnoreCase("no") ? 
        " resultater for " : " results found for ")%><i><%= search.getQuery()%></i></h3>
        <%
        while (iterator.hasNext()) {
            CmsSearchResult entry = (CmsSearchResult)iterator.next();
            String entryPath = cms.link(cms.getRequestContext().removeSiteRoot(entry.getPath()));
            // Hide pages with title = "null"
            if (entry.getField(CmsSearchField.FIELD_TITLE) != null && !entry.getField(CmsSearchField.FIELD_TITLE).equalsIgnoreCase("null")) {
            %>
                <h3 class="searchHitTitle" style="padding:1em 0 0.2em 0; margin:0;">
                    <a href="<%= entryPath %>"><%= entry.getField(CmsSearchField.FIELD_TITLE) %></a>
                </h3>
                <div class="text">
                    <%= entry.getExcerpt() != null ? entry.getExcerpt() : "" %>
                </div>
                <div class="search-hit-path" style="font-size:0.75em; color:green;">
                    <%= "http://" + request.getServerName() + entryPath %>
                </div>
				
            <%
            }
            resultno++;            
        }
    }
%> 
        <div class="pagination" style="margin-top:2em;">
<%
        
	if (search.getPreviousUrl() != null) {
%>
            <input type="button" value="&lt;&lt; <%= (loc.equalsIgnoreCase("no") ? "forrige" : "previous") %>" 
                onclick="location.href='<%= cms.link(search.getPreviousUrl()) %>&fields=<%= fields %>';">
<%
	}
	Map pageLinks = search.getPageLinks();
	Iterator i =  pageLinks.keySet().iterator();
	while (i.hasNext()) {
            int pageNumber = ((Integer)i.next()).intValue();
            String pageLink = cms.link((String)pageLinks.get(new Integer(pageNumber)));       		
            out.print("&nbsp; &nbsp;");
            if (pageNumber != search.getSearchPage()) {
%>
                <a href="<%= pageLink %>&amp;fields=<%= fields %>"><%= pageNumber %></a>
<%
            } 
            else {
%>
                <span class="currentpage"><%= pageNumber %></span>
<%
            }
	}
	if (search.getNextUrl() != null) {
%>
            &nbsp; &nbsp;
            <input type="button" value="<%= (loc.equalsIgnoreCase("no") ? "neste" : "next") %> &gt;&gt;" 
                onclick="location.href='<%= cms.link(search.getNextUrl()) %>&amp;fields=<%= fields %>';">
<%
	} 
%>  
        </div>
</article>
<cms:include property="template" element="footer" />