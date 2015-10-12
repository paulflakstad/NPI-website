<%-- 
    Document   : script-get-content-by-xpath
    Created on : Aug 28, 2015
    Author     : Paul-Inge Flakstad, Norwegian Polar Institute <flakstad at npolar.no>
--%><%@ page import="java.util.List,
                java.util.Collections,
                java.util.Locale,
                java.util.Iterator,
                org.opencms.jsp.I_CmsXmlContentContainer,
                org.opencms.jsp.CmsJspActionElement,
                org.opencms.jsp.CmsJspXmlContentBean,
                org.opencms.file.CmsObject,
                org.opencms.file.CmsResource,
                org.opencms.file.CmsFile,
                org.opencms.xml.content.CmsXmlContent,
                org.opencms.xml.content.CmsXmlContentFactory"
%><%
// Action element and CmsObject
CmsJspXmlContentBean cms = new CmsJspXmlContentBean(pageContext, request, response); // For the CmsXmlContent approach, you can use CmsJspActionElement instead
CmsObject cmso = cms.getCmsObject();

final String ELEMENT_PATH = "Paragraph[2]/Text[1]";
final String FILE_PATH = "/no/fakta/iskantsonen.html";
final String LOCALE_STR = "no";
final Locale LOCALE = new Locale(LOCALE_STR); // See also CmsXmlContent#getLocales()

// CmsJspXmlContentBean#contentshow() approach
try {
    I_CmsXmlContentContainer thisFile = cms.contentload("singleFile", FILE_PATH, false);
    if (thisFile.hasMoreResources()) {
        out.println( cms.contentshow(thisFile, ELEMENT_PATH, LOCALE) );
    }
} catch (Exception e) {
    out.println("<pre>");
    e.printStackTrace(new java.io.PrintWriter(out));
    out.println("</pre>");
}

// CmsXmlContent approach (more comprehensive example)
try {
    // Read the file and build the xml content instance
    CmsFile xmlContentFile = cmso.readFile(FILE_PATH);
    CmsXmlContent xmlContent = CmsXmlContentFactory.unmarshal(cmso, xmlContentFile);

    // Get all the element names that are available in the file (for that locale)
    List<String> elementNames = xmlContent.getNames(LOCALE);
    Collections.sort(elementNames);

    Iterator<String> iElementNames = elementNames.iterator();
    if (iElementNames.hasNext()) {
        %>
        <h1>File content by element &ndash; <%= FILE_PATH %></h1>
        <%
        while (iElementNames.hasNext()) {
            String elementName = iElementNames.next();
            %>
            <div class="element" style="margin:0; padding:1em 0; border-bottom:3px solid orange;">
            <h2 style="font-family:monospace; display:inline-block; background:lightyellow; padding:1em; margin:0;"><%= elementName %></h2>
            <%
            try {
                // If the element is a wrapper for nested elements, trying to get the string value will throw an exception
                String elementStringValue = xmlContent.getStringValue(cmso, elementName, LOCALE);
                %>
                <div style="padding:1em; background:#eee;"><%= elementStringValue %></div>
                <%
            } catch (Exception e) {
                %>
                <span style="color:#999;">Skipped. <em><%= e.getMessage() %></em></span>
                <%
            }
            %>
            </div>
            <%
        }
    }
} catch (Exception e) {
    out.println("<pre>");
    e.printStackTrace(new java.io.PrintWriter(out));
    out.println("</pre>");
} 
%>