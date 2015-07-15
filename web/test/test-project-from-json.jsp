<%-- 
    Document   : project-json
    Created on : May 24, 2013, 9:09:05 AM
    Author     : flakstad
--%><%@ page 
    import=
"java.util.ArrayList,
org.opencms.json.JSONArray,
java.util.Date,
java.text.SimpleDateFormat,
no.npolar.util.CmsAgent,
org.opencms.json.JSONObject,
org.opencms.json.JSONException"

    contentType="text/html" 
    pageEncoding="UTF-8" 
    session="true" 
 %><%!
 public String stringify(JSONArray a, boolean asListItems) {
    try {
        String s = "";
        for (int i = 0; i < a.length(); i++) {
            if (asListItems)
                s += "<li>" + a.getString(i) + "</li>";
            else {
                if (i > 0) 
                    s += ", ";
                s += a.getString(i);
            }
        }
        
        return s;
    } catch (Exception e) {
        return null;
    }
}
 %><%
        CmsAgent cms = new CmsAgent(pageContext, request, response);
        final boolean EDITABLE_TEMPLATE = false;
        
        // Call master template (and output the opening part - hence the [0])
        cms.include(cms.getTemplate(), cms.getTemplateIncludeElements()[0], EDITABLE_TEMPLATE);
        
        
        // Read the JSON string
        String projectJsonStr = cms.getContent("/no/_2013/prosjekt/project.json");
        
        // Create the JSON object from the JSON string
        JSONObject project = new JSONObject(projectJsonStr);
        
        %>
        <!--<h3>Constructed JSON object:</h3>-->
        <%
        //out.println(project.toString());
        %>
        <!--<h3>Project details:</h3>-->
        <%
        SimpleDateFormat dfParse = new SimpleDateFormat("yyyy-dd-MM");
        SimpleDateFormat dfPrint = new SimpleDateFormat("d MMM yyyy");
        Date now = new Date();
        
        String title = null;
        String acronym = null;
        String startDateStr = null;
        String endDateStr = null;
        String summary = null;
        String keywordStr = null;
        
        // Mandatory fields
        title = project.getString("title");
        summary = project.getString("summary");
        startDateStr = project.getString("start_date");
        
        // Optional fields
        //try { acronym = project.getString("acronym"); } catch (JSONException je) { }
        try { endDateStr = project.getString("end_date"); } catch (JSONException je) { }
        
        String status = "";
        Date startDate = null;
        Date endDate = null;
        try {
            while (true) {
                // Case: End date in the past
                if (endDateStr != null) {
                    endDate = dfParse.parse(endDateStr);
                    if (endDate.before(now)) {
                        status = "Completed";
                        break;
                    }
                }
                // Case: End date in the future
                startDate = dfParse.parse(startDateStr);
                if (startDate.after(now)) {
                    status = "Planned";
                    break;
                }
                // Case: None of the above - so start date is before now, and end date is non-existing or after now. That must mean the project is active.
                status = "Active";
                break;
            }
        } catch (Exception e) {
            // Retain empty value for status
        }
        
        %>
        <h1><%= title + (acronym != null ? (" (" + project.getString("acronym") + ")") : "") %></h1>
        <div class="ingress" style="margin-bottom: 1em;"><p><%= summary %></p></div>
        <div class="event-links nofloat" style="font-size:0.7em; padding-bottom:0.6em; margin-top:-2em; margin-bottom:2em;">
            <span class="timespan">Status: <%= status + " (" + (status.equals("Active") && endDateStr == null ? "Since " : "") + dfPrint.format(dfParse.parse(startDateStr)) + (endDateStr != null ? (" &ndash; " + dfPrint.format(dfParse.parse(endDateStr))) : "") + ")" %></span>
            <br />
            <span class="leader"> 
                <%
                JSONArray peopleArr = project.getJSONArray("people");
                if (peopleArr.length() > 1)
                    out.print("Leaders: ");
                else 
                    out.print("Leader: ");
                
                for (int i = 0; i < peopleArr.length(); i++) {
                    JSONObject leader = peopleArr.getJSONObject(i);
                    String leaderName = leader.getString("first_name") + " " + leader.getString("last_name");
                    String leaderEmail = leader.getString("email");
                    String leaderInstitution = leader.getString("institution");

                    if (i > 0)
                        out.print(", ");
                    
                    out.print(leaderName);
                    if (leaderInstitution != null)
                        out.print(" (" + leaderInstitution + ")");
                }
                /*
                JSONArray leadersArr = project.getJSONArray("project_leaders");
                if (leadersArr.length() > 1)
                    out.print("Leaders: ");
                else 
                    out.print("Leader: ");
                
                for (int i = 0; i < leadersArr.length(); i++) {
                    JSONObject leader = leadersArr.getJSONObject(i);
                    String leaderName = leader.getString("first_name") + " " + leader.getString("last_name");
                    String leaderEmail = leader.getString("email");
                    String leaderInstitution = leader.getString("institution");

                    if (i > 0)
                        out.print(", ");
                    
                    out.print(leaderName);
                    if (leaderInstitution != null)
                        out.print(" (" + leaderInstitution + ")");
                }
                //*/
                %>
            </span>
                <%
                try {
                    JSONArray keywordsArr = project.getJSONArray("keywords");
                    keywordStr = stringify(keywordsArr, false);
                } catch (Exception e) {
                    // No keywords present
                }
                if (keywordStr != null && !keywordStr.isEmpty()) {
                    %>
                    <br />
                    <span class="tags">Tags: <%= keywordStr %></span>
                    <%
                }
            %>
        </div>
        
        <div class="paragraph">
        
        <%
        try {
            String partnersList = stringify(project.getJSONArray("contract_partners"), true);
            if (partnersList != null && !partnersList.isEmpty()) {
                %>
                <h4>Partners:</h4>
                <ul class="project-partners"><%= partnersList %></ul>
                <%
            }
        } catch (Exception e) {
            // No partners present
        }
        %>
        </div>
        
        
        
        
        
        
        
        
        <%        
        // Call master template (and output the closing part - hence the [1])
        cms.include(cms.getTemplate(), cms.getTemplateIncludeElements()[1], EDITABLE_TEMPLATE);
        %>
