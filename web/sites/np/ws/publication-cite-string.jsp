<%-- 
    Document   : publication-cite-string
    Created on : Mar 20, 2014, 9:36:17 AM
    Author     : Paul-Inge Flakstad, Norwegian Polar Institute
--%><%@page 
    import="no.npolar.data.api.*,
            no.npolar.data.api.util.APIUtil,
            org.apache.commons.lang.StringUtils,
            java.util.Set,
            java.io.PrintWriter,
            org.opencms.jsp.CmsJspActionElement,
            java.io.IOException,
            java.util.Locale,
            java.util.ResourceBundle,
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
            java.util.Arrays,
            org.opencms.json.JSONArray,
            java.util.List,
            java.util.Date,
            java.util.Map,
            java.util.HashMap,
            java.util.Iterator,
            java.text.SimpleDateFormat,
            no.npolar.util.CmsAgent,
            org.opencms.json.JSONObject,
            org.opencms.json.JSONException,
            org.opencms.file.CmsObject"
            contentType="text/html" 
            pageEncoding="UTF-8" 
            session="true" 
 %><%
CmsAgent cms = new CmsAgent(pageContext, request, response);
CmsObject cmso = cms.getCmsObject();
String requestFileUri = cms.getRequestContext().getUri();
Locale locale = cms.getRequestContext().getLocale();
String loc = locale.toString();

String id = cms.getRequest().getParameter("id");
if (id == null || id.isEmpty()) {
    out.print("<!-- No ID was provided, aborting -->");
    return;
}

final boolean ONLINE = cmso.getRequestContext().currentProject().isOnlineProject();

try {
    Map<String, String[]> defaultParams = new HashMap<String, String[]>();
    //defaultParams.put("not-draft", new String[]{ "yes" });
    defaultParams.put("facets", new String[]{ "false" });
    defaultParams.put("sort", new String[]{ "-published_sort" });
    
    ResourceBundle labels = ResourceBundle.getBundle(Labels.getBundleName(), locale);
    PublicationService pubService = new PublicationService(locale);
    pubService.setDefaultParameters(defaultParams);
    Publication pub = pubService.getPublication(id);

    out.print(pub.toString());
} catch (Exception e) {
    out.print("<!-- An error occured while fetching cite string for publication with ID " + id + " -->");
}%>