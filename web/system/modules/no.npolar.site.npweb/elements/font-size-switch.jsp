<%-- 
    Document   : font-size-switch
    Created on : 25.mai.2011, 13:19:35
    Author     : Paul-Inge Flakstad <flakstad at npolar.no>
--%><%@ page import="org.opencms.jsp.*,
                 org.opencms.file.CmsObject,
                 org.opencms.util.CmsRequestUtil,
                 java.util.Locale,
                 java.util.List,
                 java.util.Set,
                 java.util.Iterator,
                 java.util.Map,
                 no.npolar.util.CmsAgent" session="true" 
%><%
CmsAgent                cms         = new CmsAgent(pageContext, request, response);
//CmsObject               cmso        = cms.getCmsObject();
String                  resourceUri = cms.getRequestContext().getUri();
//Locale                  locale      = cms.getRequestContext().getLocale();
//String                  loc         = null;
HttpSession             sess        = request.getSession();
    
    
    
// Set up the url, with parameters
String paramUrl = resourceUri; // Initialize the URI as the server-relative path to the request file
Map pm = cms.getRequest().getParameterMap(); // Get Map<String, String[]> of parameters
Iterator iKeys = pm.keySet().iterator(); // Get an iterator for the map's keyset
while (iKeys.hasNext()) { // Loop the keyset
    String key = (String)iKeys.next(); // Get the current key
    if (!key.equals("fs") && !key.startsWith("__")) { // Ignore the font size parameter and any OpenCms parameters
        String[] valArr = (String[])pm.get(key); // Get the corresponding parameter value(s)
        for (int i = 0; i < valArr.length; i++) { // For each value, ...
            String val = valArr[i]; // ... get the string value and ...
            paramUrl = CmsRequestUtil.appendParameter(resourceUri, key, val); // ... append it to the URI string
        }
    }
}

//
// Font-size switch
//
String fs = "";
if (sess.getAttribute("fs") != null) { // If a setting for font size exists in the session, ...
    fs = (String)sess.getAttribute("fs"); // ... get the setting (so we can compare it to the available options and determine which one is currently active)
}

String[] sizes = new String[] {"m", "l", "xl" }; // The available font size options
for (int j = 0; j < sizes.length; j++) { // Loop the options
    boolean current = fs.equalsIgnoreCase(sizes[j]); // Flag indicating if this font size is in fact also the current font size
    if (j == 0 && sess.getAttribute("fs") == null) { // First iteration AND no font-size explicitly set
        current = true;
    }
    // Create the font switch option
    out.print("<a rel=\"nofollow\" id=\"fs-" + sizes[j] + "\" class=\"wai" + (current ? " current-fs" : "") + "\"" + // Unique ID, common class, and (possibly) class for "active"
        " data-tooltip=\"" + cms.label("label.np.textsize.".concat(sizes[j])) + "\"" + // Link title
        (!current ? (" href=\"" + cms.link(CmsRequestUtil.appendParameter(paramUrl, "fs", sizes[j])) + "\"") : "") + // target URI (if not active)
        ">a</a>");
}
%>
