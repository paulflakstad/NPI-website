<%-- 
    Document   : isblink-latest-publications
    Created on : Feb 11, 2016, 7:00:58 PM
    Author     : Paul-Inge Flakstad, Norwegian Polar Institute <flakstad at npolar.no>
--%><%@page import="no.npolar.util.*,
            no.npolar.data.api.*,
            java.util.*,
            org.opencms.jsp.*,
            org.opencms.file.*"
    contentType="text/html" pageEncoding="UTF-8"
%><%
CmsAgent cms = new CmsAgent(pageContext, request, response);
Locale locale = cms.getRequestContext().getLocale();
try {
    PublicationService s = new PublicationService(locale);
    // Set new defaults (hidden / not overrideable parameters), overriding the standard defaults
    Map<String, String[]> defaultParams = new HashMap<String, String[]>();
    defaultParams.put("not-draft", new String[]{ "yes" }); // Don't include drafts
    defaultParams.put("filter-state", new String[]{ Publication.JSON_VAL_STATE_PUBLISHED + "|" + Publication.JSON_VAL_STATE_ACCEPTED }); // Require state: published or accepted
    defaultParams.put("facets", new String[]{ "false" });
    defaultParams.put("size-facet", new String[]{ "0" }); // Get all possible filters
    defaultParams.put("filter-organisations.id", new String[] { Publication.JSON_VAL_ORG_NPI }); // Filter on checked "Yes, publication is affiliated to NP activity" (require this box was checked)
    s.setDefaultParameters(defaultParams);

    Map<String, String[]> params = new HashMap<String, String[]>();
    params.put("sort", new String[]{ "-published_sort" });
    params.put("limit", new String[]{ "3" });

    List<Publication> pubList =  s.getPublicationList(params);
    if (!pubList.isEmpty()) {
        %>
        <ul>
        <%
        for (Publication p : pubList) {
            %>
            <li><a href="<%= p.getPubLink(Publication.URL_PUBLINK_BASE) %>"><strong><%= p.getTitle() %></strong></a></li>
            <%
        }
        %>
        </ul>
        <%
    }
} catch (Exception e) {
    out.println("Cannot display any publications right now.");
}
%>