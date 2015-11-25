<%-- 
    Document   : latest-news
    Created on : Nov 17, 2015, 12:54:48 PM
    Author     : Paul-Inge Flakstad, Norwegian Polar Institute <flakstad at npolar.no>
--%>

<%@page import="no.npolar.util.*,org.opencms.jsp.*,org.opencms.file.CmsObject,java.util.*,java.text.SimpleDateFormat" contentType="text/html" pageEncoding="UTF-8"
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
                                Locale locale) throws ServletException {
        final String DATE_FORMAT    = cms.labelUnicode("label.for.newsbulletin.dateformat");
        final SimpleDateFormat DATE_FORMAT_ISO = new SimpleDateFormat("yyyy-MM-dd", locale);
        String html = "";
        
        
        html += "<a href=\"" + cms.link(fileName) + "\"><h3 class=\"news-title\" style=\"font-size:1em; font-weight:bold;\">" + title + "</h3></a>";
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
    
    I_CmsXmlContentContainer all = cms.contentload("allInSubTreePriorityDateDesc", listFolder.concat("|"+TYPE_ID).concat("|"+limit), EDITABLE);
%>
    <ul class="blocklist">
<%
    while (all.hasMoreResources()) {
%>
        <li class="news"><%= getItemHtml(cms, cms.contentshow(all, "%(opencms.filename)"), cms.contentshow(all, "Title"), cms.contentshow(all, "Published"), locale) %></li>
<%
    }
%>
    </ul>
<%
    out.println(moreLink != null ? moreLink : "");
%>