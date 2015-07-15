<%-- 
    Document   : script-rewrites-ice
    Created on : Dec 1, 2011, 9:44:59 PM
    Author     : flakstad
--%><%@ page import="org.opencms.file.*, org.opencms.util.*, org.opencms.jsp.*, java.util.*, java.io.*"
%><%
CmsJspActionElement cms = new CmsJspActionElement(pageContext, request, response);
CmsObject cmso = cms.getCmsObject();
CmsResource r = null;

final String PROTOCOL_STR = "http://";
final String NEW_HOST = "www.npolar.no";
//final String FIMBUL_HOST = "http://fimbul.npolar.no/";
final String OLD_HOST = "fimbul.npolar.no";


final String PROJECT = "Offline";
//final String PROJECT = "Online";

final String FOLDER = "/no/om-oss/nyheter/arkiv/2011/";

boolean readTree = true;

Map rewrites = new HashMap();
Map otherSiteRewrites = new HashMap();

if (!cms.getRequestContext().currentProject().getName().equals(PROJECT))
    cms.getRequestContext().setCurrentProject(cmso.readProject(PROJECT));

List allResources = cmso.readResources(FOLDER, CmsResourceFilter.DEFAULT, readTree);

//out.println("<h3>Total resources: " + allResources.size() + "</h3>");

// Read robots.txt file

int j = 0;

/*
CmsFile robots = cmso.readFile("/robots.txt");
ArrayList disallowed = new ArrayList();
ByteArrayInputStream is = new ByteArrayInputStream(robots.getContents());
InputStreamReader isr = new InputStreamReader(is);
BufferedReader reader = new BufferedReader(isr);

String oneLine = null;
String[] keyVal;
String val;
while ((oneLine = reader.readLine()) != null) {
    keyVal = oneLine.split(":");
    if (keyVal.length == 2) {
        if (keyVal[0].trim().equalsIgnoreCase("Disallow")) {
            val = keyVal[1].trim();
            if (val.length() > 0) {
                if (cmso.existsResource(val)) {
                    r = cmso.readResource(val);
                    if (r.isFolder())
                        disallowed.addAll(cmso.readResources(cmso.getSitePath(r), CmsResourceFilter.DEFAULT, readTree));
                    else //if (r.isFile())
                        disallowed.add(r);
                    //out.println("Added disallowed: '" + cmso.getSitePath(r) + "'<br/>");
                    
                }
            }
        }
    }
}
out.println("<h3>Total disallowed resources: " + disallowed.size() + "</h3>");
allResources.removeAll(disallowed);
// Done removing disallowed resources

out.println("<h3>Total allowed resources: " + allResources.size() + " (including folders)</h3>");
*/

Iterator itr = allResources.iterator();

//
// Map rewrites
//
while (itr.hasNext()) {
    r = (CmsResource)itr.next();
    CmsProperty mappingProperty = cmso.readPropertyObject(r, "mapping-url", false);
    if (!mappingProperty.isNullProperty()) {
        String mappingUri = mappingProperty.getValue();
        if (mappingUri != null && !mappingUri.isEmpty()) {
            rewrites.put(mappingUri, cmso.getSitePath(r));
        }
        out.println("Found mapping for <code>" + cmso.getSitePath(r) + "</code><br />");
    }
}
//*
//
// APACHE REWRITE RULES CODE
//
itr = rewrites.keySet().iterator();
while (itr.hasNext()) {
    //r = (CmsResource)itr.next();
    String key = (String)itr.next();
    //String oldUrl = key.length() > REPLACE_THIS.length() ? key.substring(key.indexOf(REPLACE_THIS) + REPLACE_THIS.length()) : key; //key.replace(OLD_HOST, "");
    
    //if (r.isFile()) {
    j++;
    if (key.startsWith(PROTOCOL_STR.concat(OLD_HOST).concat("/"))) {
        String oldUrl = key.replace(PROTOCOL_STR.concat(OLD_HOST).concat("/"), "").replace(".", "\\.");
        String newUrl = (String)rewrites.get(key);
        out.println("RewriteCond %{HTTP_HOST} ^" + OLD_HOST + "$<br />");
        out.println("RewriteCond %{REQUEST_URI} ^/" + oldUrl + "$<br/>");
        out.println("RewriteRule ^(.*) " + PROTOCOL_STR + NEW_HOST + newUrl + " [R=301,L]<br/>");
    } else {
        otherSiteRewrites.put(key, rewrites.get(key));
    }
}
out.println("<h3>Total rewrites: " + j + "</h3>");
out.println("<h3>Other site rewrites found:</h3>");
j = 0;
itr = otherSiteRewrites.keySet().iterator();
while (itr.hasNext()) {
    out.println("" + (++j) + " " + ((String)itr.next()) + "<br />");
}
%>


