<%-- 
    Document   : script-count-resources
    Created on : Nov 12, 2013, 3:20:31 PM
    Author     : flakstad
--%><%@page import="org.opencms.flex.CmsFlexController,
                 java.util.*,
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
                 org.opencms.util.CmsStringUtil"
%><%
final CmsAgent cms                      = new CmsAgent(pageContext, request, response);
final CmsObject cmso                    = cms.getCmsObject();

final String FOLDER = "/no/";
    
List rList = cmso.readResources(FOLDER, CmsResourceFilter.ALL, true);
%>
<h3><%= rList.size() %> resources in <%= FOLDER %> </h3>