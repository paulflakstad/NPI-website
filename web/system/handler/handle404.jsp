<%-- 
    Document   : handle404
    Created on : 18.mar.2011, 00:56:56
    Author     : Paul-Inge Flakstad <flakstad at npolar.no>
--%><%@ page session="false" isErrorPage="true" contentType="text/html" import="
	org.opencms.jsp.util.*,
        org.opencms.file.CmsObject,
        java.util.*
"%><%

// initialize instance of status bean
CmsJspStatusBean cms = new CmsJspStatusBean(pageContext, request, response, exception);
CmsObject cmso = cms.getCmsObject();
String requestFolderUri = cms.getRequestContext().getFolderUri();
String contentFileUri = requestFolderUri + "contents/content" + cms.getStatusCode() + ".html";
// ToDo: set locale, based on browser setting
final String LANG_DEFAULT = "en";
// Set the default language
String redirectLanguage = LANG_DEFAULT;

// Get the "accept-language" line from the HTTP header
String acceptLanguage   = request.getHeader("Accept-Language");

if (acceptLanguage != null) {
    // Get each separate accepted languages, in prioritized order
    String[] languagePriorities = acceptLanguage.split(",");
    String language             = null;
    
    // Loop over all accepted languages, from highest to lowest priority
    for (int i = 0; i < languagePriorities.length; i++) {
        // Examine only the two first characters (in case of "en-us" / "en-gb" / "no-nb" and so on)
        language = languagePriorities[0].substring(0, 2).toLowerCase();
        
        // Make sure the norwegian language code is recognized as "no"
        if (language.equals("nb") || language.equals("nn")) { 
            language = "no";
        }
        
        // Set the language to Norwegian if possible, or else set to english
        if (language.equals("no")) {
            redirectLanguage = language;
        } else {
            //redirectLanguage = "no"; // ONLY FOR TESTING!
            redirectLanguage = "en";
        }
    }
}
java.util.Locale preferredLocale = new java.util.Locale(redirectLanguage);

// Store the preferred locale
Map params = new HashMap();
params.put("__locale", preferredLocale);
params.put("includeFilePrefix", "/sites/np");

// get the template to use
//String template = cms.property("template", "search", "/system/handler/template/handlertemplate");
//String template = cms.property("template", "search", "/system/modules/no.npolar.mosj.modules/templates/MOSJ");
String template = "/system/modules/no.npolar.site.npweb/templates/npweb.jsp";

// include the template head part
//cms.includeTemplatePart(template, "head");
// Include master template, pass the locale so the error page can display in the user's preferred language
// (The template must take care of setting the correct locale)
cms.includeTemplatePart(template, "header", params);
//cms.include(template, "header");

//
// BELOW: getPageContent includes the named element from the corresponding file inside the /system/handler/content folder
//

%>
<%= cms.getContent(contentFileUri, "head", preferredLocale) %>
<%

//out.println("<p>cms.getRequestContext().getFolderUri() = '" + cms.getRequestContext().getFolderUri() + "'</p>");
%>

<!-- Status error messages start -->
<!--<h4>--><%//= cms.key("error_message_servererror") %><!--</h4>-->
<!--<h3>--><%//= cms.keyStatus("error_message") %><!--</h3>-->

<!--<p>--><%//= cms.keyStatus("error_description") %><!--</p>-->

<% if (cms.showException() && cms.getErrorMessage() != null) {
        cms.keyStatus("error_description");
	// print the error message for developers, if available
	out.print("<p><b>" + cms.getErrorMessage() + "</b></p>");
}

if (cms.showException() && cms.getException() != null) { 
	// print the exception for developers, if available
%>
<p><b><%= cms.getException() %></b></p>
<p><pre>
<% cms.getException().printStackTrace(new java.io.PrintWriter(out)); %>
</pre></p>
<% } 
//
// BELOW: getPageContent includes the named element from the corresponding file inside the /system/handler/content folder
//
%>
<!-- Status error messages end -->
<%= cms.getContent(contentFileUri, "foot", preferredLocale) %>
<%
// Include a search form designed for error pages (this has been replaced by Google widget)
//cms.include("../modules/no.npolar.site.npweb/elements/search404.jsp");
// include the template foot part
//cms.includeTemplatePart(template, "foot");
cms.includeTemplatePart(template, "footer", params);
//cms.include(template, "footer");

// set the original error status code for the returned page
Integer status = cms.getStatusCode();
if (status != null) {
	cms.setStatus(status.intValue());
}
%>