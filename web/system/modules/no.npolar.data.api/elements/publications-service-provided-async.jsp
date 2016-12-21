<%-- 
    Document   : publications-service-provided-async-filtering
    Description: Lists publications using the data.npolar.no API.
    Created on : Apr 27, 2016, 10:25:48 AM
    Author     : Paul-Inge Flakstad, Norwegian Polar Institute <flakstad at npolar.no>
--%>
<%@page import="no.npolar.data.api.*" %>
<%@page import="no.npolar.data.api.util.APIUtil" %>
<%@page import="no.npolar.util.CmsAgent" %>
<%@page import="no.npolar.util.SystemMessenger" %>
<%@page import="org.apache.commons.lang.StringUtils" %>
<%@page import="org.apache.commons.lang.StringEscapeUtils" %>
<%@page import="org.markdown4j.Markdown4jProcessor" %>
<%@page import="java.util.Set" %>
<%@page import="java.io.PrintWriter" %>
<%@page import="org.opencms.jsp.CmsJspActionElement" %>
<%@page import="java.io.IOException" %>
<%@page import="java.util.Locale" %>
<%@page import="java.net.URLDecoder" %>
<%@page import="java.net.URLEncoder" %>
<%@page import="org.opencms.main.OpenCms" %>
<%@page import="org.opencms.util.CmsStringUtil" %>
<%@page import="org.opencms.util.CmsRequestUtil" %>
<%@page import="java.io.InputStreamReader" %>
<%@page import="java.io.BufferedReader" %>
<%@page import="java.net.URLConnection" %>
<%@page import="java.net.URL" %>
<%@page import="java.net.HttpURLConnection" %>
<%@page import="java.util.ArrayList" %>
<%@page import="java.util.Arrays" %>
<%@page import="java.util.GregorianCalendar" %>
<%@page import="java.util.Calendar" %>
<%@page import="java.util.List" %>
<%@page import="java.util.Date" %>
<%@page import="java.util.Map" %>
<%@page import="java.util.HashMap" %>
<%@page import="java.util.Iterator" %>
<%@page import="java.util.ResourceBundle" %>
<%@page import="java.text.SimpleDateFormat" %>
<%@page import="org.opencms.file.CmsObject" %>
<%@page import="org.opencms.file.CmsProject" %>
<%@page import="org.opencms.file.CmsResource" %>
<%@page import="org.opencms.json.JSONArray" %>
<%@page import="org.opencms.json.JSONObject" %>
<%@page import="org.opencms.json.JSONException" %>
<%@page import="org.opencms.mail.CmsSimpleMail" %>
<%@page contentType="text/html" 
        pageEncoding="UTF-8" 
        session="true" 
        trimDirectiveWhitespaces="true" %>
<%!
/*
public static String getContributorsShort(List<PublicationContributor> contribs, String suffixSingular, String suffixPlural) {
    String s = "";
    if (!contribs.isEmpty()) {
        
        boolean trimmed = false;
        int numContribs = contribs.size();
        String suffix = numContribs > 1 ? suffixPlural : suffixSingular;
        if (numContribs > 3) {
            contribs = contribs.subList(0, 1);
            trimmed = true;
            numContribs = contribs.size();
        }

        Iterator<PublicationContributor> iContribs = contribs.iterator();
        int contribNo = 0;
        while (iContribs.hasNext()) {
            PublicationContributor contrib = iContribs.next();
            s += contrib.getLastName();
            if (numContribs == 1 && trimmed) {
                s += " et al.";
            } else if (iContribs.hasNext()) { 
                s += ++contribNo == (numContribs-1) ? " &amp; " : ", ";
            }
        }
        if (suffix != null) {
            s += " " + suffix;
        }
    }
    return s;
}

public static boolean isInteger(String s) {
    if (s == null || s.isEmpty())
        return false;
    try { Integer.parseInt(s); } catch(NumberFormatException e) { return false; }
    return true;
}

public static String normalizeTimestampFilterValue(int yearLo, int yearHi) {
    String yearRangeFilterVal = "";
    try {
        if (yearLo > -1) {
            yearRangeFilterVal += yearLo + "-01-01T00:00:00Z" + (yearHi > -1 ? ".." : ""); 
        }
        if (yearHi > -1) {
            yearRangeFilterVal += (yearLo < 0 ? yearHi + "-01-01T00:00:00Z.." : "") + yearHi + "-12-31T23:59:59Z";
        }
    } catch (Exception e) {}
    return yearRangeFilterVal;
}

public static Map<String, String[]> getFilterParams(Map<String, String[]> parameters) {
    Map<String, String[]> params = new HashMap<String, String[]>(parameters);
    List<String> keysToRemove = new ArrayList<String>();
    for (String key : params.keySet()) {
        if (!key.startsWith(PublicationService.Param.MOD_FILTER)) {
            keysToRemove.add(key);
        }
    }
    for (String key : keysToRemove) {
        params.remove(key);
    }
    return params;
}
//*/
%><%
CmsAgent cms = new CmsAgent(pageContext, request, response);
//CmsObject cmso = cms.getCmsObject();
String requestFileUri = cms.getRequestContext().getUri();
Locale locale = cms.getRequestContext().getLocale();
String loc = locale.toString();
//final String SEARCH_PROVIDER = "/system/modules/no.npolar.data.api/elements/publications-loader-async-2.jsp";
final String SEARCH_PROVIDER = "/system/modules/no.npolar.data.api/elements/publications-loader-async.jsp";

Map<String, String[]> defaultParams = new HashMap<String, String[]>();
defaultParams.put("base", new String[] { requestFileUri });
defaultParams.put("locale", new String[] { loc });
defaultParams.put("expandedfilters", new String[] { "false" });

%>
<div id="pub-search">
<%
    // this div will be asynchronously updated upon filtering etc.
    
    // include the dynamic loader - pass default parameters for stuff which
    // cannot be deduced from the URL query string or otherwise
    // (in subsequent async updates of this div, these parameters are included
    // dynamically)
    cms.include(SEARCH_PROVIDER, null, defaultParams);
%>
</div><!-- #pub-search -->

<script type="text/javascript">
    // Define the search provider
    var provider = '<%= cms.link(SEARCH_PROVIDER) %>';
    
    $('#pub-search').on('click', '.filter', function(event) {
        event.preventDefault();
        var filterTarget = $(this).attr('href');
        $(this).toggleClass('filter--active');
        
        var queryString = getQueryString(filterTarget);
        queryString += '&base=<%= requestFileUri %>';
        // ToDo: Switch to using the ID of the toggleable filters section, which 
        //       also has a class "expanded" applied or removed.
        //       (Needed also for "aria-controls".)
        //       E.g.: $('.search-panel__filters').first()  =>  $('#filters')
        queryString += '&expandedfilters=' + $('.search-panel__filters').first().hasClass('expanded');
        queryString += '&locale=<%= loc %>';
        
        console.log("Pushing state with URL " + filterTarget);
        
        window.history.pushState(document.getElementById('pub-search').innerHTML, "", filterTarget);
        updateAsync.call(undefined, provider, queryString);
    });
    
    var updateAsync = function(provider, queryString) {
        // kept for reference...
        //queryString = queryString.replace(/%2C/g, ",");
        //queryString = decodeURIComponent(queryString);
        
        console.log("Loading URL: " + provider + "?" + queryString);
        
        $('body').append('<div class="overlay overlay--fullscreen overlay--loading" id="fullscreen-overlay"></div>');
        $('#pub-search').load(provider+'?'+queryString, function(/*String*/responseText, /*String*/textStatus, /*jqXHR*/jqXHR) {
            $('#fullscreen-overlay').remove();
        });
    };
    
    window.onpopstate = function(e) {
        updateAsyncFromUrl(null);
        //updateAsync.call(undefined, provider, getQueryString(document.location.href));
    };
    function getPath(url) {
        if (url.indexOf("?") < 0) {
            return url;
        } else {
            return url.substring(0, url.indexOf("?"));
        }
    }
    function getQueryString(url) {
        var queryString = "";
        try {
            queryString = url.substring(url.indexOf("?")+1);
        } catch (ignore) {}
        return queryString;
    }
    // Handle form submit (year selection)
    $('#pub-search').on('click', '#submit-time-range', function(event) {
        event.preventDefault();
        submitAsync( $(event.target).closest('form').attr('id') );
        //submitAsync('pub-search-form');
    });
    $('#pub-search').on('submit', '#pub-search-form', function(event) {
        event.preventDefault();
        submitAsync( $(event.target).closest('form').attr('id') );
        //submitAsync('pub-search-form');
        return false;
    });
    
    function submitAsync(id) {
        // kept for reference...
        //var queryString = $('#'+id).serialize().replace(/%2C/g, ",");
        //var queryString = decodeURIComponent( $('#'+id).serialize() );
        var queryString = $('#'+id).serialize();
        
        window.history.pushState(queryString, "", getPath(document.location.href)+"?"+queryString);
        updateAsyncFromUrl(queryString);
    }
    
    function updateAsyncFromUrl(url) {
        if (url === 'undefined' || url === null) {
            url = document.location.href;
        }
        var queryString = getQueryString(url);
        queryString += (queryString.length > 0 ? "&" : "?") 
                + 'base=<%= requestFileUri %>' // Re-add the "base" parameter, avoids filters targeting THIS file after a popstate event
                + '&expandedfilters=' + $('.search-panel__filters').first().hasClass('expanded')
                + '&locale=<%= loc %>';
        updateAsync.call(undefined, provider, queryString);
    }
</script>