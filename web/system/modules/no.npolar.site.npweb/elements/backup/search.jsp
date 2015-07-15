<%-- 
    Document   : search
    Created on : 17.mar.2011, 16:22:08
    Author     : Paul-Inge Flakstad <flakstad at npolar.no>
--%><%@ page import="org.opencms.main.*, 
                 org.opencms.security.CmsRoleManager,
                 org.opencms.security.CmsRole,
                 org.opencms.search.*, 
                 org.opencms.file.*, 
                 org.opencms.jsp.*, 
                 java.util.*, 
                 java.util.Locale" buffer="none" pageEncoding="utf-8"
%><%   
    // Create a JSP action element
    org.opencms.jsp.CmsJspActionElement cms = new CmsJspActionElement(pageContext, request, response);
    String resourceUri = cms.getRequestContext().getUri();
    String folderUri = cms.getRequestContext().getFolderUri();
    Locale locale = cms.getRequestContext().getLocale();
    String loc = locale.toString();
    
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
    
    // The target of the search form (the page that the form calls on submit)
    String serp = loc.equals("no") ? "/no/sok.html" : "/en/search.html";
    /*if (cms.getRequestContext().getSiteRoot().startsWith("/system"))
        serp = "/sites/np" + serp;
    */
    /*
    // This file must exist so give the user an error page if it hasn't yet been created
    if (!cms.getCmsObject().existsResource(serp)) {
        throw new NullPointerException("The search result page '" + serp + "' does not exist." + 
                " It needs to be created in order for search to work." +
                "");
    }*/
    String defaultSearchText = (loc.equalsIgnoreCase("no") ? "Søk" : "Search") + "...";
%>

<jsp:useBean id="search" scope="request" class="org.opencms.search.CmsSearch">
    <jsp:setProperty name="search" property="*"/>
        <% search.init(cms.getCmsObject()); %>
</jsp:useBean>

                        <form method="get" action="<%= cms.link(serp) %>">
                        <!--  query and index are mandatory fields -->
                            <div id="query-wrapper"><!-- needed to prevent the ol' IE scrolling the background -->
                                <input type="text" class="query" name="query" id="query" />
                            </div>
                            <!--<input type="hidden" name="index" value="<%= indexName %>" />-->
                            <input type="submit" class="submit" value="" />
                        </form>
                        <!-- the following javascript function requires jQuery with the autofill plugin -->
                        <script type="text/javascript">
                            $(document).ready(function(){
                                //$("#query").DefaultValue("<%= defaultSearchText %>");
                                //$("#query").autofill({value: '<%= defaultSearchText %>', defaultTextColor: '#666', activeTextColor: '#333'});
				$("#query").autofill({value: '<%= defaultSearchText %>'});
                            });
                        </script>