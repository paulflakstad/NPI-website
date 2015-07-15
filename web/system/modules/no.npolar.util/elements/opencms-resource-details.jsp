<%-- 
    Document   : opencms-resource-details
    Created on : Oct 8, 2013, 1:24:40 PM
    Author     : flakstad
--%><%-- 
    Document   : opencms-resource-details
    Created on : Mar 12, 2013, 10:17:23 AM
    Author     : flakstad
--%>
<%@page import="no.npolar.util.*, 
                org.opencms.file.CmsObject, 
                org.opencms.file.CmsResource,
                org.opencms.file.CmsResourceFilter,
                org.opencms.file.CmsUser,
                org.opencms.file.CmsProperty,
                org.opencms.security.CmsRole,
                java.util.Locale, 
                java.util.Date,
                java.util.Random,
                java.util.Map,
                java.util.HashMap,
                java.util.Set,
                java.util.Iterator,
                java.text.SimpleDateFormat,
                org.opencms.db.CmsResourceState,
                org.opencms.util.CmsStringUtil,
                org.opencms.util.CmsHtmlExtractor,
                org.opencms.util.CmsRequestUtil,
                org.opencms.main.OpenCms" contentType="text/html" pageEncoding="UTF-8"
%><%!
public String getPropertyValueOrigin(CmsObject cmso, String propertyName, String propertyValue, String resourceUri) throws org.opencms.main.CmsException {
    while (resourceUri != "/") {
        if (cmso.readPropertyObject(resourceUri, propertyName, false).getValue("").equals(propertyValue))
            return resourceUri;
        if (resourceUri.equals("/"))
            break;
        resourceUri = CmsResource.getParentFolder(resourceUri);
    }
    return null;
}
%>
<%
CmsAgent cms                = new CmsAgent(pageContext, request, response);
CmsObject cmso              = cms.getCmsObject();
String requestFileUri       = cms.getRequestContext().getUri();
String requestFolderUri     = cms.getRequestContext().getFolderUri();
Locale loc                  = cms.getRequestContext().getLocale();
//String locale               = loc.toString();
//String description          = CmsStringUtil.escapeHtml(CmsHtmlExtractor.extractText(cms.property("Description", requestFileUri, ""), "utf-8"));
//String title                = CmsStringUtil.escapeHtml(CmsHtmlExtractor.extractText(cms.property("Title", requestFileUri, ""), "utf-8"));
//String titleAddOn           = cms.property("Title.addon", "search", "");
CmsResourceState state      = cmso.readResource(requestFileUri).getState();
boolean robotsDisallow      = Boolean.valueOf(cmso.readPropertyObject(requestFileUri, "robots.disallow", true).getValue("false")).booleanValue();
String canonical            = null;
boolean loggedInUser        = OpenCms.getRoleManager().hasRole(cms.getCmsObject(), CmsRole.WORKPLACE_USER);
HttpSession sess            = request.getSession();

// Handle case: canonicalization
// - Priority 1: a canonical URI is specified in the "canonical" property
// - Priority 2: the current request URI is an index file
CmsProperty propCanonical = cmso.readPropertyObject(requestFileUri, "canonical", false);
// First examine the "canonical" property
if (!propCanonical.isNullProperty()) {
    canonical = propCanonical.getValue();
    if (canonical.startsWith("/") && !cmso.existsResource(canonical))
        canonical = null;
}
// If no "canonical" property was found, and we're displaying an index file,
// set the canonical URL to the folder (remove the "index.html" part).
if (canonical == null && CmsRequestUtil.getRequestLink(requestFileUri).endsWith("/index.html")) {
    canonical = cms.link(requestFolderUri);
    // Keep any parameters
    if (!request.getParameterMap().isEmpty()) {
        // Copy the parameter map. (Since we may need to remove some parameters.)
        Map requestParams = new HashMap(request.getParameterMap());
        // Remove internal OpenCms parameters (they start with a double underscore) 
        // and any other unwanted ones - e.g. font size parameters
        Set keys = requestParams.keySet();
        Iterator iKeys = keys.iterator();
        while (iKeys.hasNext()) {
            String key = (String)iKeys.next();
            if (key.startsWith("__") || key.equals("fs")) // This is an internal OpenCms parameter or a font-size parameter ...
                iKeys.remove(); // ... so go ahead and remove it.
        }
        if (!requestParams.isEmpty())
            canonical = CmsRequestUtil.appendParameters(canonical, requestParams, true);
    }
}

if (loggedInUser) {
    boolean showInfo = true;
    if (sess.getAttribute("cms_res_info") != null)
        showInfo = Boolean.parseBoolean(sess.getAttribute("cms_res_info").toString());
    //out.println("<!-- cms_res_info was " + sess.getAttribute("cms_res_info").toString() + " -->");
    %>
    <style type="text/css">
        #ocms-page-info { background:#444; color:white; padding:1em; text-align:center; font-size:0.7em; border-bottom:1px solid #aaa; }
        #ocms-page-info span { display:inline-block; padding:0.2em; margin-right:1em; border-radius:3px; box-shadow:1px 1px 3px #333; background:#666; }
        #ocms-page-info span[data-tooltip]:hover { cursor: help; }
        #ocms-page-info span a,
        #ocms-page-info span a:visited { color:#7df; }
        #ocms-page-info span a:hover { background: none; color:#8ef; }
        #ocms-page-info .warn { background:#c75000; }
        #ocms-page-info .ok { background:#0c0; font-style:italic; }
        #ocms-page-info p { margin:0 0 0.5em 0;}
        .qtip p { margin: 0 0 0.4em 0; }
        .qtip { box-shadow: 1px 1px 5px #222; }
        #cms_res_info_toggler { position: absolute; z-index: 999; top: 0; left: 0; display: block; width: 22px; height: 22px; background: transparent url(https://fsweb.no/nomination/resources/gfx/info_16.png) 3px 3px no-repeat; }
        #cms_res_info_toggler:hover { cursor: pointer; }
        /*.page-info-message { font-size:1em; padding:1em; border:1px solid white; border-radius:3px; box-shadow:1px 1px 3px #333; background:rgba(0,0,0,0.8); color:#fff; }*/
    </style>
    <%
    final String PAGE_DATE_FORMAT = "dd MMM yyyy";
    final String[] GREETS = { "Yo", "Hi", "Greetings", "Hi there", "Whaddup", "The one and only", "Howdy", "Top o' the mornin' to ya" };
    String pageInfo = "<div id=\"ocms-page-info\">"
            + "<p>" + GREETS[new Random(System.currentTimeMillis()).nextInt(GREETS.length)] + " " + cms.getRequestContext().currentUser().getFirstname() + "!"
            + " Just a reminder &ndash; this is the "
            + "<strong>" + (cms.getRequestContext().currentProject().isOnlineProject() ? "online" : "offline") + " version</strong> of this page.</p>";
    if (state.isNew() || state.isChanged()) {
        CmsResource reqFile = cmso.readResource(requestFileUri);
        CmsUser creatorUser = cmso.readUser(reqFile.getUserCreated()); // Get the user who created the file
        CmsUser modUser = cmso.readUser(reqFile.getUserLastModified()); // Get the user who modified the file
        String creatorName  = creatorUser.getFirstname() + " " + creatorUser.getLastname();
        String modifierName = modUser.getFirstname() + " " + modUser.getLastname();
        Date modifiedDate = new Date(reqFile.getDateLastModified()); // Create dates (representing the moment in time they are created. These objects are changed below.)
        Date createdDate = new Date(reqFile.getDateCreated());
        SimpleDateFormat dFormat = new SimpleDateFormat(PAGE_DATE_FORMAT, new Locale("en")); // Create the desired output format
        String createdBy = "Created by " + creatorName + " at " + dFormat.format(createdDate) + ".";
        String modBy = "Last modified by " + modifierName + " at " + dFormat.format(modifiedDate) + ".";

        if (state.isNew()) {
            pageInfo += //"<span class=\"warn\" onmouseover=\"return overlib('" + CmsStringUtil.escapeHtml(createdBy) + "');\" onmouseout=\"return nd();\">"
                        "<span class=\"warn\" data-tooltip=\"<p>This page is not visible to the world. " + CmsStringUtil.escapeHtml(createdBy) + "</p>\">"
                            + "The page is <strong>NOT PUBLISHED</strong>."
                        + "</span>";
        } else if (state.isChanged()) {
            pageInfo += //"<span class=\"warn\" onmouseover=\"return overlib('" + CmsStringUtil.escapeHtml(modBy) + "');\" onmouseout=\"return nd();\">"
                        "<span class=\"warn\" data-tooltip=\"<p>What you see here might not be the same as visitors see. " + CmsStringUtil.escapeHtml(modBy) + "</p>\">"
                            + "The page <strong>HAS CHANGED</strong> since it was published."
                        + "</span>";
        }
    } else {
        pageInfo += "<span class=\"ok\" data-tooltip=\"<p>What you see here is what any visitor will see.</p>\">"
                        + "No changes since last publish."
                    + "</span>";
    }

    if (robotsDisallow) {
        String robotsDisallowOrigin = getPropertyValueOrigin(cmso, "robots.disallow", "true", requestFileUri);
        String robotsDisallowMessage = "<p>The restriction is set on the " + (CmsResource.isFolder(robotsDisallowOrigin) ? "folder" : "file") + " <strong>" + robotsDisallowOrigin + "</strong>.</p>";
        //pageInfo += "<span class=\"warn\" onmouseover=\"return overlib('" + CmsStringUtil.escapeHtml(robotsDisallowMessage) + "');\" onmouseout=\"return nd();\">Search engines will <strong>NOT</strong> index this page.</span>";
        pageInfo += "<span class=\"warn\" data-tooltip=\"" + CmsStringUtil.escapeHtml(robotsDisallowMessage) + "\">"
                        + "Search engines will <strong>NOT</strong> index this page."
                    + "</span>";
    } else {
        pageInfo += "<span class=\"ok\" data-tooltip=\"<p>The <strong>online version</strong> of this page will be searchable in Google and other search engines.</p>\">"
                        + "No search engine restrictions for this page."
                    + "</span>";
    }

    if (canonical != null) {
        if (canonical.equals(requestFileUri) || (requestFileUri.endsWith("/index.html") && CmsResource.getParentFolder(requestFileUri).equals(canonical))) {
            pageInfo += "<span data-tooltip=\"<p>You're telling Google and other search engines to index this page using the current address.</p>"
                                            + "<p>That's just fine"
                                            + (cmso.readSiblings(requestFileUri, CmsResourceFilter.DEFAULT_FILES).size() > 1 ? 
                                                ", but you should be extra careful to make sure this canonical URI setting doesn't accidentally exist on any of the sibling(s)."
                                                : ".")
                                            + "</p>\">" ;
        } else {
            pageInfo += "<span class=\"warn\" data-tooltip=\"<p>You are telling Google and other search engines to use this address instead of the current one, "
                                            + " possibly disabling indexing of all the content you see here.</p><p>Please ensure this is correct.</p>\">";
        }

        pageInfo += "The canonical URI is <a href=\"".concat(canonical).concat("\">").concat(canonical).concat("</a>.")
                    + "</span>";
    } else {
        pageInfo += "<span data-tooltip=\"<p>If the content here is also available on other addresses (for example on a sibling page)"
                                        + ", a canonical URI can be used to tell search engines and other crawlers which one of"
                                        + " these addresses you prefer them to associate with the contents of this page.</p>\">" 
                        + "<em>No canonical URI is set.</em>"
                    + "</span>";
    }
    pageInfo += "</div>";
    out.println(pageInfo);
    
    //
    
//}
    %>
    <!--<a id="cms_res_info_toggler" onclick="$('#ocms-page-info').slideToggle()"></a>-->
    <a id="cms_res_info_toggler"></a>
    
    <script type="text/javascript">
        <%
        if (!showInfo) {
        %>
        $("#ocms-page-info").hide();
        <% } %>
        
        $("#cms_res_info_toggler").click(function(e) {
        
        var cssDisplayVal = $("#ocms-page-info").css("display");
        var settingVal = "true";
        if (cssDisplayVal == undefined || cssDisplayVal == "block") {
            $("#ocms-page-info").addClass("hidden")
            $("#ocms-page-info").hide(300);
            settingVal = "false";
        }
        else {
            $("#ocms-page-info").removeClass("hidden");
            $("#ocms-page-info").show(300);
            settingVal = "true";
        }
        
        $.post("/settings", { cms_res_info: settingVal });
    });
    </script>
    <%
    //}
}
%>