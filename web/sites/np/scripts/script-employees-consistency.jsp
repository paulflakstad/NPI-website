<%-- 
    Document   : script-employees-consistency
    Created on : Feb 4, 2013, 1:14:15 PM
    Author     : flakstad
--%>
<%@ page import="java.util.*,
                 java.text.SimpleDateFormat,
                 no.npolar.util.*,
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
<%
final CmsAgent cms                            = new CmsAgent(pageContext, request, response);
final CmsObject cmso                          = cms.getCmsObject();
Locale locale                           = cms.getRequestContext().getLocale();
String loc                              = locale.toString();
String requestFileUri                   = cms.getRequestContext().getUri();
String requestFolderUri                 = cms.getRequestContext().getFolderUri();

String folder = request.getParameter("folder");
CmsResourceFilter personFilter = CmsResourceFilter.DEFAULT_FILES.addRequireType(OpenCms.getResourceManager().getResourceType("person").getTypeId());

List<CmsResource> employeesEn = cmso.readResources("/en/people/", personFilter, true);
List<CmsResource> employeesNo = cmso.readResources("/no/ansatte/", personFilter, true);

List<String> namesEn = new ArrayList<String>();
List<String> namesNo = new ArrayList<String>();


Iterator<CmsResource> i = employeesEn.iterator();
while (i.hasNext()) {
    namesEn.add(cmso.readPropertyObject(i.next(), "Title", false).getValue("NO TITLE"));
}

i = employeesNo.iterator();
while (i.hasNext()) {
    namesNo.add(cmso.readPropertyObject(i.next(), "Title", false).getValue("NO TITLE"));
}

List namesNoCopy = new ArrayList(namesNo);
namesNo.removeAll(namesEn);
namesEn.removeAll(namesNoCopy);

if (namesNo.isEmpty() && namesEn.isEmpty()) {
    out.println("<h2>Everything is OK!</h2><p>There were no inconsistencies.</p>");
}
else {
    out.println("<h2>Something needs fixing</h2>");
    Iterator<String> iNames = null;
    
    if (!namesNo.isEmpty()) {
        out.println("<h3>" + namesNo.size() + " person(s) exist only in the Norwegian section</h3>");
        iNames = namesNo.iterator();
        while (iNames.hasNext()) {
            out.println(iNames.next() + "<br />");
        }
    }

    if (!namesEn.isEmpty()) {
        out.println("<h3>" + namesEn.size() + " person(s) exist only in the English section</h3>");
        iNames = namesEn.iterator();
        while (iNames.hasNext()) {
            out.println(iNames.next() + "<br />");
        }
    }
}
%>