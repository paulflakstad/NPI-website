<%-- 
    Document   : employees-search-ws
    Created on : Sep 3, 2014, 12:13:35 PM
    Author     : Paul-Inge Flakstad, Norwegian Polar Institute
--%><%-- 
    Document   : employee-searchbox-for-contact-page
    Created on : May 30, 2013, 10:39:32 AM
    Author     : flakstad
--%><%@ page import="java.util.*,
                 java.text.SimpleDateFormat,
                 no.npolar.util.*,
                 org.opencms.flex.*,
                 org.opencms.file.CmsResource,
                 org.opencms.file.CmsResourceFilter,
                 org.opencms.file.CmsObject,
                 org.opencms.file.collectors.CmsCategoryResourceCollector,
                 org.opencms.jsp.I_CmsXmlContentContainer,
                 org.opencms.jsp.CmsJspActionElement,
                 org.opencms.jsp.util.CmsJspContentAccessBean,
                 org.opencms.xml.A_CmsXmlDocument,
                 org.opencms.xml.content.*,
                 org.opencms.main.OpenCms,
                 org.opencms.relations.CmsCategory,
                 org.opencms.relations.CmsCategoryService,
                 org.opencms.util.CmsUUID,
                 org.opencms.util.CmsStringUtil"  session="true" 
%>
<%!
public String getParameterString(Map params) {
    if (params == null)
        return "";
    Set keys = params.keySet();
    Iterator ki = keys.iterator();
    String key = null;
    String val = null;
    String paramStr = "";
    while (ki.hasNext()) {
        key = (String)ki.next();
        if (params.get(key).getClass().getCanonicalName().equals("java.lang.String[]")) { // Multiple values (standard form)
            for (int i = 0; i < ((String[])params.get(key)).length; i++) {
                val = ((String[])params.get(key))[i];
                if (val.trim().length() > 0) {
                    if (paramStr.length() > 0)
                        paramStr += "&amp;";
                    paramStr += key + "=" + val;
                }
            }
        }
        else if (params.get(key).getClass().getCanonicalName().equals("java.lang.String")) { // Single value
            if (paramStr.length() == 0)
                paramStr += key + "=" + (String)params.get(key);
            else
                paramStr += "&amp;" + key + "=" + (String)params.get(key);
        }
    }
    return paramStr;
}

/**
* Prints the hierarchical category tree under the "category" top node.
* Dependant upon the recursive method printCategorySubTree(...).
* @param cmso An initialized CmsObject
* @param category The root node for the tree
* @param categoryReferencePath The category reference path, used to resolve categories
* @param requestFileUri The URI of the request file, used in construction of links
* @param paramFilterCategories A list of category identifiers present in the request parameters, used to determine "active" links
* @param out The writer to use when generating HTML output
*/
public void printCategoryTree(CmsObject cmso, CmsCategory category, String categoryReferencePath, String requestFileUri, List paramFilterCategories, JspWriter out) 
        throws org.opencms.main.CmsException, java.io.IOException {
    
    // Set the flag indicating if the category's path was given as a request parameter (meaning we're filtering the list by this category)
    boolean categoryInParameter = false;
    if (paramFilterCategories != null) {
        if (paramFilterCategories.contains(category.getPath())) {
            categoryInParameter = true;
        }
    }
    // Start the list of category filter links
    out.println("<ul class=\"category-filter\"><li><a href=\"" + requestFileUri + "?cat=" + category.getPath() + "\"" + 
                            (categoryInParameter ? " style=\"font-weight:bold;\"" : "") + ">" + category.getTitle() + 
                        "</a>");
    // Call the recursive method to print the subtree under this category
    printCategorySubTree(cmso, category, categoryReferencePath, requestFileUri, paramFilterCategories, out);
    // End the list of category filter links
    out.println("</li></ul>");
}
/*
* Recursive method to prints a hierarchical category tree. 
* @param cmso An initialized CmsObject
* @param category The root node for the tree
* @param categoryReferencePath The category reference path, used to resolve categories
* @param requestFileUri The URI of the request file, used in construction of links
* @param paramFilterCategories A list of category identifiers present in the request parameters, used to determine "active" links
* @param out The writer to use when generating HTML output
*/
public void printCategorySubTree(CmsObject cmso, CmsCategory category, String categoryReferencePath, String requestFileUri, List paramFilterCategories, JspWriter out) 
        throws org.opencms.main.CmsException, java.io.IOException {
    
    
    CmsCategoryService cs = CmsCategoryService.getInstance();
    List subCats = cs.readCategories(cmso, category.getPath(), false, categoryReferencePath); // Get the sub-categories of filterCategory
    if (subCats != null) {
        if (!subCats.isEmpty()) {
            Iterator iSub = subCats.iterator();
            out.println("<ul>");
            while (iSub.hasNext()) {
                category = (CmsCategory)iSub.next();
                boolean categoryInParameter = false; // Flag indicating if the category's path was given as a request parameter
                if (paramFilterCategories != null) {
                    if (paramFilterCategories.contains(category.getPath())) {
                        categoryInParameter = true;
                    }
                }
                    
                out.println("<li>" +
                        "<a href=\"" + requestFileUri + "?cat=" + category.getPath() + "\"" + 
                            (categoryInParameter ? " style=\"font-weight:bold;\"" : "") + ">" + category.getTitle() + 
                        "</a>");
                printCategorySubTree(cmso, category, categoryReferencePath, requestFileUri, paramFilterCategories, out);
                out.println("</li>");
            }
            out.println("</ul>");
        }
    }
}


    /**
    * Recursive method to prints a hierarchical category tree. 
    * @param cmso An initialized CmsObject
    * @param category The root node for the tree
    * @param categoryReferencePath The category reference path, used to resolve categories
    * @param hideRootElement If set to true, the topmost (root) element of the tree will not be displayed in the filter tree
    * @param hiddenCategoryPaths A list containing root paths to categories that should not be displayed in the filter tree
    * @param requestFileUri The URI of the request file, used in construction of links
    * @param paramFilterCategories A list of category identifiers (paths) present in the request parameters, used to determine "active" links
    * @param out The writer to use when generating HTML output
    */
    public void printCatFilterTree(CmsJspActionElement cms, //CmsObject cmso, 
                                    CmsCategory category, 
                                    String categoryReferencePath, 
                                    boolean hideRootElement, 
                                    List hiddenCategoryPaths,
                                    String requestFileUri, 
                                    List paramFilterCategories, 
                                    JspWriter out) throws org.opencms.main.CmsException, java.io.IOException {
        // Get the category service instance
        CmsCategoryService cs = CmsCategoryService.getInstance();
        // Determine whether or not the current category was present in the reqest parameters (meaning we're currently filtering by this category)
        boolean categoryInParameter = false;
        if (paramFilterCategories != null) {
            if (paramFilterCategories.contains(category.getPath())) {
                categoryInParameter = true;
            }
        }
        // Start the list, but only if the root element is not hidden
        if (!hideRootElement) {
            out.println("<ul>");
            out.println("<li>" +
                        "<a href=\"" + requestFileUri + "?cat=" + category.getPath() + "\"" + 
                            (categoryInParameter ? " style=\"font-weight:bold;\"" : "") + ">" + category.getTitle() + 
                        "</a>");
        }
        // Get a list of any sub-categories of the category
        List subCats = cs.readCategories(cms.getCmsObject(), category.getPath(), false, categoryReferencePath);
        // For each sub-category, call this method
        if (subCats != null) {
            if (!subCats.isEmpty()) {
                Iterator iSub = subCats.iterator();
                while (iSub.hasNext()) {
                    category = (CmsCategory)iSub.next();
                    //if (!category.getRootPath().equals(hiddenCategoryPath)) {
                    if (!hiddenCategoryPaths.contains(category.getRootPath())) {
                        printCatFilterTree(cms, category, categoryReferencePath, false, hiddenCategoryPaths, requestFileUri, paramFilterCategories, out);
                    }
                }
            }
        }
        // End the list, but only if the root element is not hidden
        if (!hideRootElement) {
            out.println("</li>");
            out.println("</ul>");
        }
    }

    public void printCatFilterList(CmsJspActionElement cms,//CmsObject cmso, 
                                    List categories, // A list of CmsCategory objects
                                    boolean printSubCategories,
                                    String categoryReferencePath, 
                                    List hiddenCategoryPaths,
                                    String requestFileUri, 
                                    List paramFilterCategories, 
                                    JspWriter out) throws org.opencms.main.CmsException, java.io.IOException {
        
        // Get the iterator for the list of categories
        Iterator iCat = categories.iterator();
        
        // Start the list
        out.println("<ul>");
        
        // Print each list item
        while (iCat.hasNext()) {
            CmsCategory category = (CmsCategory)iCat.next();
            // Proceed only if the category is not in the list of "hidden" categories
            if (!hiddenCategoryPaths.contains(category.getRootPath())) {
                // Determine whether or not the current category was present in the reqest parameters (meaning we're currently filtering by this category)
                boolean categoryInParameter = false;
                if (paramFilterCategories != null) {
                    if (paramFilterCategories.contains(category.getPath())) {
                        categoryInParameter = true;
                    }
                }
                
                out.println("<li>");
                if (!printSubCategories) {
                    out.println("<a href=\"" + cms.link(requestFileUri) + "?cat=" + category.getPath() + "\"" + 
                                    (categoryInParameter ? " style=\"font-weight:bold;\"" : "") + ">" + category.getTitle() + 
                                "</a>");
                } else {
                    printCatFilterTree(cms, category, categoryReferencePath,
                                        false, hiddenCategoryPaths,
                                        requestFileUri, paramFilterCategories, out);
                }
                out.println("</li>");
            }
        }
        
        // End the list
        out.println("</ul>");
    }
%>
<%
final boolean DEBUG                     = request.getParameter("debug") == null ? false : true;
//final String AJAX_EVENTS_PROVIDER      = "/system/modules/no.npolar.common.event/elements/events-provider.jsp";
final CmsAgent cms                            = new CmsAgent(pageContext, request, response);
final CmsObject cmso                          = cms.getCmsObject();
Locale locale                           = cms.getRequestContext().getLocale();
String loc                              = locale.toString();
String requestFileUri                   = cms.getRequestContext().getUri();
String requestFolderUri                 = cms.getRequestContext().getFolderUri();



// If this template is included by another file, the parameter resourceUri must be set to contain the path to the config file
String resourceUri = request.getParameter("resourceUri");
if (resourceUri == null) 
    resourceUri = requestFileUri;


// Query submitted?
String query = request.getParameter("q");
if (query != null && !query.isEmpty()) {
    
    String employeeUri = request.getParameter("employeeuri");
    if (employeeUri != null && !employeeUri.isEmpty()) {
        CmsFlexController.getController(request).getTopResponse().sendRedirect("http://www.npolar.no" + employeeUri);
        return;
    }
    
    
}



String fullListUrl = null;
if (loc.equalsIgnoreCase("no"))
    fullListUrl = "http://www.npolar.no/no/ansatte";
else if (loc.equalsIgnoreCase("en"))
    fullListUrl = "http://www.npolar.no/en/people";

final String secondaryCTA = loc.equalsIgnoreCase("no") ? 
                                "Eller <a href=\"" + fullListUrl + "\">vis alle ansatte</a>"
                                :
                                "Or <a href=\"" + fullListUrl + "\">view all employees</a>";
%>
<div class="searchbox-big">
    <h2><%= cms.labelUnicode("label.np.searchemployee") %></h2>
    <form id="employeelookup" method="post" action="<%= fullListUrl %>">
        <input type="search" name="q" size="30" id="q" value="" />
        <input type="hidden" name="employeeuri" id="employeeuri" value="" />
        <input type="hidden" name="start" value="0" />
        <input type="submit" value=" <%= cms.label("label.np.search") %> " />
    </form>
    <p><strong><%= secondaryCTA %></strong></p>
</div>
<%                                                       


// The autocomplete javascript
//if (!result.isEmpty()) {
    %>
    <script type="text/javascript">
        /*<![CDATA[*/
        $(function() {
            //var employees = <% 
            //cms.includeAny("/no/employees-ac.json", null); 
            %>;
            // Mappings for special characters
            /*REMOVEDvar accentMap = {
                                "á": "a",
                                "â": "a",
                                "å": "a",
                                "ç": "c",
                                "é": "e",
                                "è": "e",
                                "ö": "o",
                                "ø": "o",
                                "ü": "u",
                                "æ": "a",
                                "-": " "
                            };*/
            /*REMOVED
            // Used to find stuff using the mappings for special characters
            var normalize = function( term ) {
                var ret = "";
                for ( var i = 0; i < term.length; i++ ) {
                    ret += accentMap[ term.charAt(i) ] || term.charAt(i);
                }
                return ret;
            };
            */
            $("#q").autocomplete({
                minLength: 0
                //,source: employees
                , source: function(request, response) {
                    $.ajax({
                        url: "http://www.npolar.no/ws-employees",
                        dataType: "jsonp",
                        data: {
                            q: request.term,
                            lang: <%= loc %>
                        },
                        success: function( data ) {
                            response( data );
                        }
                    });
                }
                /* REMOVED
                ,source: function( request, response ) {
                    var matcher = new RegExp( $.ui.autocomplete.escapeRegex(request.term), "i" );
                    response( $.grep( employees, function( value ) {
                        value = value.label || value.value || value.description || value;
                        return matcher.test(value) || matcher.test(normalize(value) );
                    }) );
                }*/
                ,focus: function(event, ui) {
                    //$("#q").val(ui.item.label);
                    return false;
                }
                ,select: function(event, ui) {
                    $("#q").val(ui.item.label);
                    $("#employeeuri").val(ui.item.value);
                    $("#employeelookup").submit();
                    return false;
                }
            });/*.data("autocomplete")._renderItem = function( ul, item ) {
                    return $( "<li></li>" )
                            .data( "item.autocomplete", item )
                            .append( "<a>" + item.label + "<br /><em>" + item.descr + "</em></a>" )
                            .appendTo( ul );
                };*/
            if ( $("#q").data() ) {
                var ac = $("#q").data('autocomplete');
                if (ac) {
                   ac._renderItem = function(ul, item) {
                        return $( "<li></li>" )
                            .data( "item.autocomplete", item )
                            .append( "<a>" + item.label + "<br /><em>" + item.description + "</em></a>" )
                            .appendTo( ul );
                    };
                }
            }
        });
        /*]]>*/
    </script>
    <%
//}
%>