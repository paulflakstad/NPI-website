<%-- 
    Document   : script-list-employees
    Created on : Sep 2, 2013, 3:54:31 PM
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
%><%!
/*
public String normalize(String s) {
    Map<String, String> m = new HashMap<String, String>();
    m.put("ä", "a");
    m.put("á", "a");
    m.put("à", "a");
    m.put("â", "a");
    m.put("æ", "a");
    m.put("å", "a");
    
    m.put("ë", "e");
    m.put("é", "e");
    m.put("è", "e");
    m.put("ê", "e");
    //s = s.replaceAll("", string1)
    return "";
}
*/

public String normalizePhoneNumber(String phoneNumber) {
    String s = new String(phoneNumber);
    if (s.startsWith("+47"))
        s = s.replace("+47", "").trim();
    s = s.replaceAll("\\s", "");
    if (isNumeric(s)) {
        if (!s.startsWith("+"))
            s = "+47".concat(s);
        return s;
    }
    return phoneNumber;
}

public boolean isNumeric(String s) {
    try {
        Double.valueOf(s);
        return true;
    } catch (Exception e) {
        return false;
    }
}
%><%

CmsFlexController.getController(request).getTopResponse().setHeader("Content-Type", "application/json; charset=utf-8");

final boolean DEBUG                     = request.getParameter("debug") == null ? false : true;
final CmsAgent cms                      = new CmsAgent(pageContext, request, response);
final CmsObject cmso                    = cms.getCmsObject();
    


// Get the resource type ID for the resource type "person"
int resourceTypeId = OpenCms.getResourceManager().getResourceType("person").getTypeId();

// Collect resources
String param = "/en/people/" + "|" + resourceTypeId;
I_CmsXmlContentContainer listItems = cms.contentload("allInSubTreePriorityTitleDesc", param, false);

// Get the resulting list of resources (= all "person" files in the given folder)
List result = listItems.getCollectorResult();
int listItemsCount = result.size();

// Sort resources by title
final Comparator<CmsResource> TITLE_IGNORE_CASE_ORDER = new Comparator<CmsResource>() {
                                                    public int compare(CmsResource one, CmsResource another) {
                                                        String oneTitle = cms.property("Title", cmso.getSitePath(one), "").toLowerCase();
                                                        String anotherTitle = cms.property("Title", cmso.getSitePath(another), "").toLowerCase();
                                                        return oneTitle.compareTo(anotherTitle);
                                                    }
                                                };
Collections.sort(result, TITLE_IGNORE_CASE_ORDER);
// Done sorting


// Print .json
if (listItemsCount > 0) {
    int printed = 0;
    out.println("{");
    out.println("\"results\": " + listItemsCount + ",");
    out.println("\"self\": \"" + OpenCms.getLinkManager().getOnlineLink(cmso, cms.getRequestContext().getUri()) + "\",");
    out.println("\"employees\":[");
    while (listItems.hasMoreContent()) {
        String itemPath = cms.contentshow(listItems, "%(opencms.filename)");
        String itemId = CmsResource.getParentFolder(itemPath).replace("/en/people/", "").replace("/", "");
                
        String itemEmail = cms.contentshow(listItems, "Email");
        String itemFname = cms.contentshow(listItems, "GivenName");
        String itemLname = cms.contentshow(listItems, "Surname");
        String itemImageUri = cms.contentshow(listItems, "Image");
        String itemPhone = cms.contentshow(listItems, "Phone");
        String itemMobile = cms.contentshow(listItems, "Cellphone");
        String itemEmploymentType = cms.contentshow(listItems, "EmploymentType");
        String itemPosition = cms.contentshow(listItems, "Position");
        String itemPosition_no = cms.contentshow(listItems, "Position", new Locale("no"));
        String itemWorkplace = cms.contentshow(listItems, "Workplace");
        String itemCurrentlyEmployed = cms.contentshow(listItems, "CurrentlyEmployed");
        String itemOnLeave = cms.contentshow(listItems, "OnLeave");
        List<String> itemOrgs = cmso.readPropertyObject(itemPath, "collector.categories", false).getValueList(new ArrayList<String>());
        
        out.println("{");
        out.println("\"id\": \"" + itemId + "\",");
        out.println("\"fname\": \"" + itemFname + "\",");
        out.println("\"lname\": \"" + itemLname + "\",");
        if (CmsAgent.elementExists(itemImageUri)) 
            out.println("\"image\": \"" + OpenCms.getLinkManager().getOnlineLink(cmso, itemImageUri) + "\",");
        if (CmsAgent.elementExists(itemPosition) || CmsAgent.elementExists(itemPosition_no)) {
            out.println("\"position\": {");
            out.println("\"en\": " + (CmsAgent.elementExists(itemPosition) ? "\"".concat(itemPosition).concat("\"") : "null") + ",");
            out.println("\"no\": " + (CmsAgent.elementExists(itemPosition_no) ? "\"" + itemPosition_no + "\"" : "null"));
            out.println("},");
        }
        if (CmsAgent.elementExists(itemWorkplace))
            out.println("\"workplace\": \"" + itemWorkplace + "\",");
        if (CmsAgent.elementExists(itemEmploymentType))
            out.println("\"employment\": \"" + itemEmploymentType.replace("Post-doc", "Postdoc") + "\",");
        if (CmsAgent.elementExists(itemCurrentlyEmployed))
            out.println("\"currently_employed\": " + itemCurrentlyEmployed + ",");
        if (CmsAgent.elementExists(itemCurrentlyEmployed))
            out.println("\"on_leave\": " + itemOnLeave + ",");
        
        if (!itemOrgs.isEmpty()) {
            out.println("\"org_units\": [");
            Iterator<String> i = itemOrgs.iterator();
            while (i.hasNext()) {
                String itemOrg = i.next();
                if (!itemOrg.isEmpty())
                    out.println("{\n\"unit\":" + "\"" + itemOrg.replace("/sites/np/no/_categories/org/np", "").replace("/sites/np/en/_categories/org/np", "") + "\"\n}" + (i.hasNext() ? "," : ""));
            }
            out.println("],");
        }
        if (CmsAgent.elementExists(itemPhone)) {
            out.println("\"phone\": \"" + normalizePhoneNumber(itemPhone) + "\",");
        }
        if (CmsAgent.elementExists(itemMobile))
            out.println("\"mobile\": \"" + normalizePhoneNumber(itemMobile) + "\",");
        out.println("\"email\": \"" + itemEmail + "\"");
        
        out.print("}");
        if (++printed < listItemsCount)
            out.println(",");
    }
    out.println("]");
    out.println("}");
}
%>