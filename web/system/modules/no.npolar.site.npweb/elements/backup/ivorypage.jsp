<%-- 
    Document   : ivorypage.jsp
    Created on : 02.jun.2010, 15:18:49
    Author     : Paul-Inge Flakstad <flakstad at npolar.no>
--%><%@ page import="no.npolar.util.CmsAgent,
                 java.util.Locale,
                 java.util.Date,
                 java.text.SimpleDateFormat,
                 org.opencms.jsp.I_CmsXmlContentContainer,
                 org.opencms.file.CmsObject,
                 org.opencms.file.CmsUser,
                 org.opencms.file.CmsResource,
                 org.opencms.util.CmsUUID" session="true" %><%!
                 
/**
* Gets an exception's stack strace as a string.
*/
public String getStackTrace(Exception e) {
    String trace = "";
    StackTraceElement[] ste = e.getStackTrace();
    for (int i = 0; i < ste.length; i++) {
        StackTraceElement stElem = ste[i];
        trace += stElem.toString() + "<br />";
    }
    return trace;
}
%><%
// Action element and CmsObject
CmsAgent cms                        = new CmsAgent(pageContext, request, response);
CmsObject cmso                      = cms.getCmsObject();
// Commonly used variables
String requestFileUri               = cms.getRequestContext().getUri();
String requestFolderUri             = cms.getRequestContext().getFolderUri();
Locale locale                       = cms.getRequestContext().getLocale();
String loc                          = locale.toString();

// Common page element handlers
final String PARAGRAPH_HANDLER      = "../../no.npolar.common.pageelements/elements/paragraphhandler.jsp";
final String LINKLIST_HANDLER       = "../../no.npolar.common.pageelements/elements/linklisthandler.jsp";
final String ADDITIONAL_NAV_HANDLER = "../../no.npolar.site.npweb/elements/additional-navigation-handler.jsp";
final String SHARE_LINKS            = "../../no.npolar.site.npweb/elements/share-addthis-" + loc + ".txt";

// Direct edit switches
final boolean EDITABLE              = false;
final boolean EDITABLE_TEMPLATE     = false;
// Labels
final String LABEL_BY               = cms.labelUnicode("label.np.by");
final String LABEL_LAST_MODIFIED    = cms.labelUnicode("label.np.lastmodified");
final String PAGE_DATE_FORMAT       = cms.labelUnicode("label.np.dateformat.normal");
// File information variables
String byline                       = null;
String author                       = null;
String authorMail                   = null;
String shareLinksString             = null;
boolean shareLinks                  = false;
// XML content containers
I_CmsXmlContentContainer container  = null;
// String variables for structured content elements
String pageTitle                    = null;
String pageIntro                    = null;
// Include-file variables
String includeFile                  = cms.property("template-include-file");
boolean wrapInclude                 = cms.property("template-include-file-wrap") != null ?
                                            (cms.property("template-include-file-wrap").equalsIgnoreCase("outside") ? false : true) : true;
// Template ("outer" or "master" template)
String template                     = cms.getTemplate();
String[] elements                   = cms.getTemplateIncludeElements();

//
// Include upper part of main template
//
cms.include(template, elements[0], EDITABLE_TEMPLATE);

//
// Get file creation and last modification info
//
CmsResource reqFile = cmso.readResource(requestFileUri);
CmsUser creatorUser = cmso.readUser(reqFile.getUserCreated()); // Get the user who created the file
CmsUser modUser = cmso.readUser(reqFile.getUserLastModified()); // Get the user who modified the file
String creatorName  = creatorUser.getFirstname() + " " + creatorUser.getLastname();
String modifierName = modUser.getFirstname() + " " + modUser.getLastname();
Date modifiedDate = new Date(reqFile.getDateLastModified()); // Create dates (representing the moment in time they are created. These objects are changed below.)
Date createdDate = new Date(reqFile.getDateCreated());
SimpleDateFormat dFormat = new SimpleDateFormat(PAGE_DATE_FORMAT, locale); // Create the desired output format
//out.println("Created by " + creatorName + " at " + dFormat.format(createdDate) + ".");
//out.println("Last modified by " + modifierName + " at " + dFormat.format(modifiedDate) + ".");


// Load the file
container = cms.contentload("singleFile", "%(opencms.uri)", EDITABLE);
// Set the content "direct editable" (or not)
cms.editable(EDITABLE);

//
// Process file contents
//
while (container.hasMoreContent()) {
    //out.println("<div class=\"page\">"); // REMOVED <div class="page">
    
    out.println("<div class=\"twocol\">");
    
    pageTitle = cms.contentshow(container, "PageTitle");
    pageIntro = cms.contentshow(container, "Intro");
    author = cms.contentshow(container, "Author");
    authorMail = cms.contentshow(container, "AuthorMail");
    shareLinksString= cms.contentshow(container, "ShareLinks");
    if (!CmsAgent.elementExists(shareLinksString))
        shareLinksString = "false"; // Default value if this element does not exist in the file (backward compatibility)

    try {
        shareLinks      = Boolean.valueOf(shareLinksString).booleanValue();
    } catch (Exception e) {
        shareLinks = false; // Default value if above line fails (it shouldn't, but just to be safe...)
    }
    
    byline = "<div class=\"byline\"><div class=\"names\">";
    // Author and/or translator names - print them as mailto-links if e-mail addresses are present
    if (CmsAgent.elementExists(author)) {
        author = CmsAgent.removeUsername(author); // I.e. convert "Paul Flakstad (paul)" to "Paul Flakstad"
        byline += LABEL_BY + " ";
        byline += (CmsAgent.elementExists(authorMail) ? ("<a href=\"mailto:" + authorMail + "\">" + author + "</a>") : author);
        //byline += "&nbsp;&ndash;&nbsp;"; // Dash between name(s) and timestamp
    }
    byline += "</div><!-- .names -->";
    if (shareLinks) {
        /*byline += "<!-- AddThis Button BEGIN -->" +
                    "<div class=\"addthis_toolbox addthis_default_style\">" +
                    "<a href=\"http://www.addthis.com/bookmark.php?v=250&amp;username=xa-4c6ead601f06be40\" class=\"addthis_button_compact\">Share</a>" +
                    "<span class=\"addthis_separator\">|</span>" +
                    "<a class=\"addthis_button_facebook\"></a>" +
                    "<a class=\"addthis_button_twitter\"></a>" +
                    "<a class=\"addthis_button_email\"></a>" +
                    "<a class=\"addthis_button_print\"></a>" +
                    "</div>" +
                    "<script type=\"text/javascript\" src=\"http://s7.addthis.com/js/250/addthis_widget.js#username=xa-4c6ead601f06be40\"></script>" +
                    "<!-- AddThis Button END -->";*/
        //byline += cms.getContent(SHARE_LINKS);
        //cms.include(SHARE_LINKS);
    }

    byline += "</div><!-- .byline -->";

    if (CmsAgent.elementExists(authorMail)) {
        byline = CmsAgent.obfuscateEmailAddr(byline, false);
    }
    /*
    if (CmsAgent.elementExists(author)) {
        author = CmsAgent.removeUsername(author);
        byline = "<div class=\"byline\">" + LABEL_BY + " ";
        byline += CmsAgent.elementExists(authorMail) ? ("<a href=\"mailto:" + authorMail + "\">" + author + "</a>") : author;
        //byline += " &ndash; " + LABEL_LAST_MODIFIED.toLowerCase() + " " + dFormat.format(modifiedDate);
        byline += "</div>";
        if (CmsAgent.elementExists(authorMail))
            byline = CmsAgent.obfuscateEmailAddr(byline, false);
    }
    */
    out.println(CmsAgent.elementExists(pageTitle) ? ("<h1>" + pageTitle + "</h1>") : "");
    if (byline != null)
        out.println(byline);
    if (CmsAgent.elementExists(pageIntro))
        out.println("<div class=\"ingress\">" + CmsAgent.stripParagraph(pageIntro) + "</div><!-- .ingress -->");

    //
    // Paragraphs, handled by a separate file
    //
    cms.include(PARAGRAPH_HANDLER);
    
    // Extension
    if (includeFile != null && wrapInclude) {
        out.println("<!-- Extension found (wrap inside): '" + includeFile + "' -->");
        cms.includeAny(includeFile, "resourceUri");
    }
    
    
    if (shareLinks) {
        out.println(cms.getContent(SHARE_LINKS));
    }
    
    
    out.println("</div><!-- .twocol -->");
    out.println("<div class=\"onecol\">");
    
    //
    // Handle additional navigation - used by "big events" (big event = an event with multiple pages)
    //
    //cms.include(ADDITIONAL_NAV_HANDLER);
    String navAddPath = cmso.readPropertyObject(requestFileUri, "menu-file-additional", true).getValue("");
    if (!navAddPath.isEmpty()) {
        cms.includeAny(navAddPath, "resourceUri");
    }
    
    //
    // Pre-defined and generic link lists, handled by a separate file
    //
    cms.include(LINKLIST_HANDLER);
    out.println("</div><!-- .onecol -->");
    
    
    
    
    /* // REMOVED <div class="page">
    // If the include file should NOT be wrapped inside the ivorypage content div
    if (!wrapInclude)
        out.println("</div><!-- .page -->");
    */

    // Include file from property "template-include-file"
    if (includeFile != null && !wrapInclude) {
        out.println("<!-- Extension found (don't wrap inside): '" + includeFile + "' -->");
        cms.includeAny(includeFile, "resourceUri");
    }
    /* // REMOVED <div class="page">
    // If the include should be wrapped inside the ivorypage content div
    if (wrapInclude)
        out.println("</div><!-- .page (or script div) -->");
    */

} // While container.hasMoreContent()


//
// Include lower part of main template
//
cms.include(template, elements[1], EDITABLE_TEMPLATE);
%>