<%-- 
    Document   : sibling-switch.jsp
    Created on : 23.jun.2010, 15:15:15
    Author     : Paul-Inge Flakstad <flakstad at npolar.no>
--%><%@ page import="org.opencms.jsp.*,
                 org.opencms.file.CmsResource,
                 org.opencms.file.CmsResourceFilter,
                 org.opencms.file.CmsProperty,
                 org.opencms.file.CmsObject,
                 org.opencms.util.CmsStringUtil,
                 org.opencms.main.OpenCms,
                 org.opencms.security.CmsRole,
                 java.util.Arrays,
                 java.util.Locale,
                 java.util.List,
                 java.util.ArrayList,
                 java.util.Iterator,
                 java.net.URLEncoder,
                 java.net.URLDecoder,
                 java.util.Map" session="true" 
%><%!
public List getLangSiblings(CmsJspActionElement cms, String resourceUri) throws org.opencms.main.CmsException {
    final boolean LOGGED_IN_USER = OpenCms.getRoleManager().hasRole(cms.getCmsObject(), CmsRole.WORKPLACE_USER);
    CmsObject cmso = cms.getCmsObject();
    final boolean ONLINE = cmso.getRequestContext().currentProject().isOnlineProject();
    // Get the site root
    String siteRoot = cms.getRequestContext().getSiteRoot();
    //CmsResource requestResource = cmso.readResource(resourceUri);
    // Get a list of all siblings
    //List siblings = cmso.readSiblings(resourceUri, CmsResourceFilter.ONLY_VISIBLE_NO_DELETED);
    List siblings = cmso.readSiblings(resourceUri, ONLINE ? CmsResourceFilter.DEFAULT : CmsResourceFilter.ALL);
    Iterator itr = siblings.iterator();
    while (itr.hasNext()) {
        // Get the sibling
        CmsResource sibling = (CmsResource)itr.next();
        // Filter out siblings in other site
        if (!sibling.getRootPath().startsWith(siteRoot)) {
            itr.remove();
            continue;
        }
        // Get the sibling's "locale" property
        String siblingPropertyLocaleStr = cmso.readPropertyObject(cmso.getSitePath(sibling), "locale", true).getValue("en");
        // The sibling's locale is the same as the current locale...
        if (siblingPropertyLocaleStr.equals(cms.getRequestContext().getLocale().toString())) {
            // ... most likely means we've encountered "self" - remove it from the list
            itr.remove();
        }
        /*
        CmsProperty siblingPropertyLocale = cmso.readPropertyObject(cmso.getSitePath(sibling), "locale", true);
        if (siblingPropertyLocale.isNullProperty()) { // Then this is the default locale ("en")
            itr.remove();
        } else {
            // The sibling had a defined locale, but if this locale is the same as the current locale...
            if (siblingPropertyLocale.getValue().equals(cms.getRequestContext().getLocale().toString()))
                // ...remove this sibling from the list
                itr.remove();
        }
        */
    }
    return siblings;
}

public String getSwitchLink(CmsJspActionElement cms, 
                            String altResourcePath, 
                            String queryString, 
                            Locale altLocale, 
                            String switchLabel) {

    String s = "<a"
                + " href=\"" + cms.link(altResourcePath).concat(queryString) + "\""
                + " data-tooltip=\"" + OpenCms.getWorkplaceManager().getMessages(altLocale).key("label.language.switch") + "\""
                + " class=\"language-switch_" + altLocale.toString() + " language-switch language-switch--" + altLocale + "\""
                + ">"
                    + "<span class=\"language-switch-flag language-switch__flag\"></span>";

    if (switchLabel != null && !switchLabel.isEmpty()) {
        s += "<span class=\"language-switch-language language-switch__language\">" +
                        switchLabel.substring(0,1).toUpperCase() + switchLabel.substring(1) +
                        "</span>";
    }
    
    s += "</a>";

    return s;
}
%><%
//CmsAgent                cms         = new CmsAgent(pageContext, request, response);
CmsJspActionElement cms = new CmsJspActionElement(pageContext, request, response);
CmsObject cmso = cms.getCmsObject();
String requestFileUri = cms.getRequestContext().getUri();
// The property "language-switch.exclude" can be used to force a resource to not display any language switch
boolean excluded = Boolean.valueOf(cmso.readPropertyObject(requestFileUri, "language-switch.exclude", true).getValue("false")).booleanValue();

//final String LABEL_SWITCH_LANGUAGE = cms.label("label.language.switch");// cms.getRequestContext().getLocale().toString().equalsIgnoreCase("no") ? "View this page in English" : "Vis denne siden på norsk";

// Settings for whether or not to print the language text
boolean printText = request.getParameter("text") != null ? Boolean.valueOf(request.getParameter("text")).booleanValue() : true;

if (!excluded) {
    final String ENCODING = "utf-8";
    // Handle the query string, so we can add it to the language switch link
    String queryString = cms.getRequest().getQueryString();
    /* // CANNOT DO THIS, IT FU**S UP EVERYTHING WHEN USING CATEGORIES....
    if (queryString != null)
        queryString = URLDecoder.decode(cms.getRequest().getQueryString(), ENCODING);
    queryString = queryString == null ? "" : "?".concat(URLEncoder.encode(queryString, ENCODING));
    // SO WE JUST TAKE CARE OF ANY AMPERSANDS INSTEAD (THE MOST COMMON PROBLEM)
    */
    if (queryString != null)
        queryString = URLDecoder.decode(cms.getRequest().getQueryString(), ENCODING);
    queryString = queryString == null ? "" : "?".concat(queryString.replaceAll("\\&", "&amp;"));
    
    // Handle case: Path to alternate version set as request attribute
    //      This approach is used by e.g. "person", see
    //      /system/modules/no.npolar.common.person/elements/person.jsp
    String altPath = null;
    try {
        altPath = (String)request.getAttribute("alternate_uri");
        Locale altLocale = Locale.forLanguageTag(altPath.split("/")[1]);
        out.println(getSwitchLink(cms, altPath, queryString, altLocale, printText ? altLocale.getDisplayLanguage(altLocale) : null));
    } catch (Exception e) {
        // ignore
    }
    
    if (altPath == null) {
        // No alternate path was set as request attribute => Evaluate sibling(s).
        
        // Get a list of all sibling resources that have a different locale than the current resource
        List languageSiblings = getLangSiblings(cms, requestFileUri);

        if (!languageSiblings.isEmpty()) {
            Iterator itr = languageSiblings.iterator();
            while (itr.hasNext()) {
                CmsResource languageSibling = (CmsResource)itr.next();

                // We don't want to link to any URI that only redirects back to the 
                // current page.
                String languageSiblingRedir = cmso.readPropertyObject(languageSibling, "redirect.permanent", true).getValue("");
                try {
                    if (!languageSiblingRedir.isEmpty() ) {
                        String thisUri = cmso.getSitePath(cmso.readResource(requestFileUri)).replace("index.html", "");
                        String thatUri = cmso.getSitePath(cmso.readResource(languageSiblingRedir)).replace("index.html", "");
                        if (thatUri.equals(thisUri)) {
                            // Sibling redirects to the current page => Ignore it
                            continue;
                        }
                    }
                } catch (Exception ignore) {}

                // Get the URI to the sibling
                String languageSiblingPath = cmso.getSitePath(languageSibling);
                // If necessary, modify the URI, so we don't link to any index.html-file
                if (languageSiblingPath.endsWith("/index.html")) {
                    languageSiblingPath = languageSiblingPath.substring(0, languageSiblingPath.lastIndexOf("index.html"));
                }
                // Get the "locale" property object for the sibling
                CmsProperty localeProperty = cmso.readPropertyObject(languageSibling, "locale", true);
                if (!localeProperty.isNullProperty()) {
                    // Get the sibling's locale
                    Locale languageSiblingLocale = new Locale(localeProperty.getValue());
                    // Get the language name (display language) for the sibling's locale (in the sibling's own language)
                    String switchLabel = languageSiblingLocale.getDisplayLanguage(languageSiblingLocale);
                    // Print the link, capitalize the display language
                    out.print(getSwitchLink(cms, languageSiblingPath, queryString, languageSiblingLocale, printText ? switchLabel : null));
                    /*
                    out.print("<a href=\"" + cms.link(languageSiblingPath).concat(queryString) + "\""
                                    + " data-tooltip=\"" + OpenCms.getWorkplaceManager().getMessages(languageSiblingLocale).key("label.language.switch") + "\""
                                    + " class=\"language-switch_" + localeProperty.getValue() + "\"><span class=\"language-switch-flag\"></span>");
                    if (printText) {
                        out.print("<span class=\"language-switch-language\">" +
                                        switchLabel.substring(0,1).toUpperCase() + switchLabel.substring(1) +
                                        "</span>");
                    }
                    out.println("</a>");
                    //*/
                } else {
                    // Missing locale on language sibling
                    //out.println("<!-- Missing locale on language sibling -->");
                }
            }
        } else {
            // No language siblings
            out.println("<!-- No language siblings -->");
        }
    }
} else {
    // Language switch turned off for this file
    out.println("<!-- Language switch turned off for this file -->");
}


/*
// Version that checks the target file of each language switch link
loc          = locale.toString();
List languageSiblings = getLangSiblings(cms, requestFileUri);
Iterator itr = languageSiblings.iterator();
if (itr.hasNext()) {
    while (itr.hasNext()) {
        CmsResource languageSibling = (CmsResource)itr.next();
        String languageSiblingPath = cmso.getSitePath(languageSibling);
        CmsProperty localeProperty = cmso.readPropertyObject(languageSibling, "locale", true);
        if (!localeProperty.isNullProperty()) {
            boolean excluded = Boolean.valueOf(cmso.readPropertyObject(languageSibling, "language-switch.exclude", true).getValue("false")).booleanValue();
            if (!excluded) {
                Locale languageSiblingLocale = new Locale(localeProperty.getValue());
                String switchLabel = languageSiblingLocale.getDisplayLanguage(new Locale(localeProperty.getValue()));
                out.println("<a href=\"" + cms.link(languageSiblingPath).concat(queryString) + "\"" + 
                                " class=\"language-switch_" + localeProperty.getValue() + "\">" + 
                                switchLabel.substring(0,1).toUpperCase() + switchLabel.substring(1) + // Capitalize
                                "</a>");
            } else {
                // Language switch turned off for this file
            }
        } else {
            // Missing locale on language sibling
        }
    }
} else {
    // No language siblings
}
// END Version that checks the target file of each language switch link
*/
%>