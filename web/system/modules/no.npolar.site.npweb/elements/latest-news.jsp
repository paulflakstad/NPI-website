<%-- 
    Document   : latest-news
    Created on : Nov 17, 2015, 12:54:48 PM
    Author     : Paul-Inge Flakstad, Norwegian Polar Institute <flakstad at npolar.no>
--%>
<%@page import="no.npolar.util.*,org.opencms.jsp.*,org.opencms.file.CmsObject,org.opencms.file.CmsResource,java.util.*,java.text.SimpleDateFormat" 
        contentType="text/html" 
        pageEncoding="UTF-8"
%><%!
    public String getItemHtml(CmsAgent cms, 
                                String fileName,
                                String title,
                                //String teaser,
                                //String imageLink,
                                String published,
                                //String dateFormat,
                                //boolean displayDescription, 
                                //boolean displayTimestamp,
                                boolean isFeatured,
                                String featuredFolderUri,
                                Locale locale) throws ServletException {
        final String DATE_FORMAT    = cms.labelUnicode("label.for.newsbulletin.dateformat");
        final SimpleDateFormat DATE_FORMAT_ISO = new SimpleDateFormat("yyyy-MM-dd", locale);
        String html = "";
        
        
        html += "<a href=\"" + cms.link(fileName) + "\"><h3 class=\"news-title\" style=\"font-size:1em; font-weight:bold;\">" + title + "</h3></a>";
        if (isFeatured) {
            html += "<a class=\"tag\" href=\"" + cms.link(featuredFolderUri) + "\" style=\"text-decoration: none;\">" 
                    + (locale.toString().equalsIgnoreCase("no") ? "Kronikk" : "Featured").toUpperCase() 
                    + "</a> ";
        }
        html += "<time class=\"timestamp\" datetime=\"" + DATE_FORMAT_ISO.format(new Date(Long.valueOf(published).longValue())) + "\">" 
                    + CmsAgent.formatDate(published, DATE_FORMAT, locale) 
                + "</time>";
        
        return html;
    }
%><%
    CmsAgent cms                = new CmsAgent(pageContext, request, response);
    CmsObject cmso              = cms.getCmsObject();
    Locale locale               = cms.getRequestContext().getLocale();
    
    final boolean EDITABLE      = false;
    final String DEFAULT_FOLDER = "/";
    final int TYPE_ID           = org.opencms.main.OpenCms.getResourceManager().getResourceType("newsbulletin").getTypeId();
    final int DEFAULT_LIMIT     = 4;
    
    String listFolder = cms.getRequest().getParameter("folder");
    if (listFolder == null || !cmso.existsResource(listFolder)) {
        listFolder = DEFAULT_FOLDER;
    }
    String limit = cms.getRequest().getParameter("limit");
    if (limit == null) {
        limit = ""+DEFAULT_LIMIT;
    }
    String moreText = cms.getRequest().getParameter("moretext");
    String moreLink = null;
    if (moreText != null) {
        moreLink = "<a class=\"cta more\" href=\"" + cms.link(listFolder) + "\">" + moreText + "</a>";
    }
    
    // Featured article (Norwegian: "kronikk")
    String featuredFolderUri = null;
    int featuredLimit = 0;
    String featuredLimitStr = cms.getRequest().getParameter("featuredLimit");
    if (featuredLimitStr != null && !featuredLimitStr.trim().isEmpty()) {
        try {
            featuredLimit = Integer.valueOf(featuredLimitStr);
        } catch (NumberFormatException nfe) {
            // Not an integer
        }
    }
    if (featuredLimit > 0) {
        featuredFolderUri = cms.getRequest().getParameter("featuredFolder");
    }
    
    I_CmsXmlContentContainer all = cms.contentload("allInSubTreePriorityDateDesc", listFolder.concat("|"+TYPE_ID).concat("|"+limit), EDITABLE);
    
    List<CmsResource> allResources = all.getCollectorResult();
    List<CmsResource> featuredResources = new ArrayList<CmsResource>(0);
    
    if (featuredLimit > 0 && featuredFolderUri != null && !featuredFolderUri.trim().isEmpty()) {
        allResources = allResources.subList(0, allResources.size()-(featuredLimit));
        I_CmsXmlContentContainer featuredContainer = cms.contentload("allInSubTreePriorityDateDesc", featuredFolderUri.concat("|"+TYPE_ID).concat("|" + featuredLimit), EDITABLE);
        featuredResources = featuredContainer.getCollectorResult();
        allResources.addAll(1, featuredResources);
    }
%>
    <ul class="blocklist">
<%
    for (CmsResource r : allResources) {
%>
        <li class="news"><%= getItemHtml(cms, 
                cmso.getSitePath(r), 
                cmso.readPropertyObject(r, "Title", false).getValue("[NO TITLE]"), 
                cmso.readPropertyObject(r, "collector.date", false).getValue("0"), 
                featuredResources.contains(r),
                featuredFolderUri,
                locale) %></li>
<%
    }
%>
    </ul>
<%
    out.println(moreLink != null ? moreLink : "");
%>