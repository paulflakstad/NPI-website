<%-- 
    Document   : language-switch.jsp - Looks at siblings
    Created on : 26.mar.2009, 13:18:00
    Author     : flakstad
--%>

<%@ page import="org.opencms.jsp.*,
                 org.opencms.file.CmsResource,
                 org.opencms.file.CmsResourceFilter,
                 org.opencms.file.CmsProperty,
                 org.opencms.file.CmsObject,
                 java.util.Arrays,
                 java.util.Locale,
                 java.util.List,
                 java.util.Iterator,
                 java.net.URLEncoder,
                 java.net.URLDecoder,
                 java.util.Map,
                 no.npolar.util.CmsAgent" session="true" 
%><%!
public List getLangSiblings(CmsAgent cms, String resourceUri) throws org.opencms.main.CmsException {
    
    CmsObject cmso = cms.getCmsObject();
    CmsResource requestResource = cmso.readResource(resourceUri);
    List siblings = cmso.readSiblings(resourceUri, CmsResourceFilter.ONLY_VISIBLE_NO_DELETED);
    Iterator itr = siblings.iterator();
    while (itr.hasNext()) {
        CmsResource sibling = (CmsResource)itr.next();
        CmsProperty siblingPropertyLocale = cmso.readPropertyObject(cmso.getSitePath(sibling), "locale", true);
        if (siblingPropertyLocale.isNullProperty()) {
            itr.remove();
        } else {
            if (siblingPropertyLocale.getValue().equals(cms.getRequestContext().getLocale().toString()))
                itr.remove();
        }
    }
    return siblings;
}
%><%
CmsAgent                cms         = new CmsAgent(pageContext, request, response);
CmsObject               cmso        = cms.getCmsObject();
String                  resourceUri = cms.getRequestContext().getUri();
Locale                  locale      = cms.getRequestContext().getLocale();
String                  loc         = null;
final String            ENCODING    = "utf-8";
String                  queryString = cms.getRequest().getQueryString();
// List of files where we NEVER want to display the language switch
List                    excluded    = Arrays.asList("/en/searchresult.html",
                                                    "/no/searchresult.html");

if (queryString != null)
    queryString = URLDecoder.decode(cms.getRequest().getQueryString(), ENCODING);
queryString = queryString == null ? "" : "?".concat(URLEncoder.encode(queryString, ENCODING));

//
// Language switch 
//
if (!excluded.contains(resourceUri)) {
    loc          = locale.toString();
    List languageSiblings = getLangSiblings(cms, resourceUri);
    Iterator itr = languageSiblings.iterator();
    if (itr.hasNext()) {
        while (itr.hasNext()) {
            CmsResource languageSibling = (CmsResource)itr.next();
            String languageSiblingPath = cmso.getSitePath(languageSibling);
            if (languageSiblingPath.endsWith("/index.html")) {
                languageSiblingPath = languageSiblingPath.substring(0, languageSiblingPath.lastIndexOf("index.html"));
            }
            CmsProperty localeProperty = cmso.readPropertyObject(languageSibling, "locale", true);
            if (!localeProperty.isNullProperty()) {
                Locale languageSiblingLocale = new Locale(localeProperty.getValue());
                String switchLabel = languageSiblingLocale.getDisplayLanguage(new Locale(localeProperty.getValue()));
                out.println("<a href=\"" + cms.link(languageSiblingPath).concat(queryString) + "\"" + 
                                " class=\"language-switch_" + localeProperty.getValue() + "\">" + 
                                switchLabel.substring(0,1).toUpperCase() + switchLabel.substring(1) + // Capitalize
                                "</a>");
            } else {
                //out.println("<h5>Missing locale on language sibling '" + languageSiblingPath + "'</h5>");
            }
        }
    } else {
        //out.println("<h5>No language siblings</h5>");
    }
} else {
    //out.println("<h5>Language switch turned off</h5>");
}
%>
