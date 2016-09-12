<%@ page import="no.npolar.util.*,
                 no.npolar.common.collectors.*,
                 org.opencms.file.CmsFile,
                 org.opencms.file.CmsObject,
                 org.opencms.file.CmsResource,
                 org.opencms.i18n.CmsLocaleManager,
                 org.opencms.main.OpenCms,
                 org.opencms.jsp.I_CmsXmlContentContainer,
                 org.opencms.relations.CmsCategory,
                 org.opencms.relations.CmsCategoryService,
                 org.opencms.file.collectors.CmsCategoryResourceCollector,
                 org.opencms.file.collectors.CmsTimeFrameCategoryCollector,
                 org.opencms.xml.I_CmsXmlDocument,
                 org.opencms.xml.content.CmsXmlContent,
                 org.opencms.xml.content.CmsXmlContentFactory,
                 java.text.SimpleDateFormat,
                 java.util.Collections,
                 java.util.Date,
                 java.util.ArrayList,
                 java.util.List,
                 java.util.Iterator,
                 java.util.Comparator,
                 java.util.TimeZone,
                 java.util.Locale" session="false" pageEncoding="UTF-8"
%><%@ taglib prefix="cms" uri="http://www.opencms.org/taglib/cms"
%><%!
public boolean isEmailAddress(String s) {
    if (s == null || s.trim().isEmpty() || !CmsAgent.elementExists(s))
        return false;
    return s.matches("^" + CmsAgent.EMAIL_REGEX_PATTERN + "$");
}
%><%
    // If a category should not be listed, add it here
    //
    //
    List hiddenCategories = new ArrayList();
    hiddenCategories.add("/sites/np/no/_categories/theme/");
    hiddenCategories.add("/sites/np/en/_categories/theme/");
    // Done with hidden categories
    
    
    // Create a JSP action element, and get the URI of the requesting file
    CmsAgent cms                    = new CmsAgent(pageContext, request, response);
    CmsObject cmso                  = cms.getCmsObject();
    final CmsObject CMSO            = OpenCms.initCmsObject(cmso);
    String requestFileUri           = cms.getRequestContext().getUri();
    CmsCategoryService catService   = CmsCategoryService.getInstance();
    
    String resourceUri              = cms.getRequestContext().getUri();
    String folderUri                = cms.getRequestContext().getFolderUri();
    HttpSession sess                = cms.getRequest().getSession(true);

    Locale locale                   = cms.getRequestContext().getLocale();
    String loc                      = locale.toString();
    
    String newsFolder               = cms.property("template-search-folder", "search"); // e.g. "/no/om-oss/nyheter/"
    
    String template                 = cms.getTemplate();
    String[] elements               = cms.getTemplateIncludeElements();

    // Common page element handlers
    final String PARAGRAPH_HANDLER      = "../../no.npolar.common.pageelements/elements/paragraphhandler.jsp";
    final String LINKLIST_HANDLER       = "../../no.npolar.common.pageelements/elements/linklisthandler.jsp";
    //final String SHARE_LINKS            = "../../no.npolar.site.npweb/elements/share-addthis-" + loc + ".txt";
    //final String SHARE_LINK_MIN         = "../../no.npolar.site.npweb/elements/share-link-min-" + loc + ".txt";

    final boolean EDITABLE          = false;
    final boolean EDITABLE_TEMPLATE = false;
    final int TYPE_ID_NEWSBULL      = OpenCms.getResourceManager().getResourceType("newsbulletin").getTypeId();
    
    //
    // Include upper part of outer ("master") template
    //
    cms.include(template, elements[0], EDITABLE_TEMPLATE);
    // Set the content "direct editable" (or not)
    cms.editable(EDITABLE);
    
    final String LABEL_MORE_NEWS_IN_CATEGORY = loc.equalsIgnoreCase("no") ? "Nyheter om " : "News about ";
    final String LABEL_BY   = cms.labelUnicode("label.for.newsbulletin.by");
    final String LABEL_TRANSLATED_BY = cms.labelUnicode("label.for.newsbulletin.translatedby");
    final String DATEFORMAT = cms.labelUnicode("label.for.newsbulletin.dateformat.normal");
    final String LABEL_SIMILAR_ARTICLES = cms.labelUnicode("label.np.similararticles");
    //final String PUBLISHED  = cms.labelUnicode("label.for.newsbulletin.published").concat(" ");
    //final String AUTHOR     = cms.labelUnicode("label.for.newsbulletin.by").concat(" ");
    //final String DATEFORMAT = cms.labelUnicode("label.for.newsbulletin.dateformat");
    
    final SimpleDateFormat DATE_FORMAT_ISO = new SimpleDateFormat("yyyy-MM-dd", locale);

    I_CmsXmlContentContainer newsBulletin; // Containers
    String title, ingress, published, author, authorLink, translator, translatorLink; // String variables
    // String shareLinksString;
    //boolean shareLinks = true;
    
    // Check if we are outputting in the actual language
    // (if not, we need to set the lang attribute, for WCAG2.0 compliancy)
    Locale contentLocale = new Locale(locale.getLanguage());
    try {
        
        //contentLocale = newsBulletin.getXmlDocument().getBestMatchingLocale(locale);
        //I_CmsXmlDocument contentXml = newsBulletin.getXmlDocument(); // Always returns NULL
        CmsFile requestFile = cmso.readFile(requestFileUri);
        // build up the xml content instance
        CmsXmlContent xmlContent = CmsXmlContentFactory.unmarshal(cmso, requestFile);
        //if (!xmlContent.hasLocale(loc)) {
        
        out.println("<!-- INFO: Missing content in requested language, attempting fallback -->");
        if (!xmlContent.hasLocale(locale)) {
            CmsLocaleManager lm = OpenCms.getLocaleManager();
            out.println("<!-- This page has no content in " + locale.getDisplayLanguage(new Locale("en")) + " -->");
            contentLocale = lm.getBestMatchingLocale(locale, lm.getDefaultLocales(), xmlContent.getLocales());
            out.println("<!--   Available languages: " + xmlContent.getLocales().toString() + " -->");
            out.println("<!--   Best fallback (using this one): " + contentLocale.getDisplayLanguage() + " -->");
        }
    } catch (Exception e) {
        out.println("<!-- ERROR reading content locale: " + e.getMessage() + "  -->");
    }
    
    //out.println("<div class=\"twocol\">");
    out.println("<article"
            + " class=\"main-content\"" 
            + (contentLocale.getLanguage().equals(locale.getLanguage()) ? "" : " lang=\"".concat(contentLocale.getLanguage()).concat("\""))
            + ">");
    
    try {
        newsBulletin = cms.contentload("singleFile", "%(opencms.uri)", EDITABLE);
        while (newsBulletin.hasMoreContent()) {
            title       = cms.contentshow(newsBulletin, "Title");
            if (!CmsAgent.elementExists(title)) {
                throw new NullPointerException("MISSING CONTENT");
            }
            ingress         = cms.contentshow(newsBulletin, "Ingress");
            //text          = CmsAgent.stripParagraph(cms.contentshow(newsBulletin, "Text"));
            //text          = cms.contentshow(newsBulletin, "Text");
            published       = cms.contentshow(newsBulletin, "Published");
            author          = CmsAgent.removeUsername(cms.contentshow(newsBulletin, "Author"));
            authorLink      = cms.contentshow(newsBulletin, "AuthorMail");
            translator      = cms.contentshow(newsBulletin, "Translator");

            translator      = cms.elementExists(translator) ? CmsAgent.removeUsername(translator) : "";
            translatorLink  = cms.contentshow(newsBulletin, "TranslatorMail");

            if (isEmailAddress(authorLink))
                authorLink = "mailto:" + authorLink;
            if (isEmailAddress(translatorLink))
                translatorLink = "mailto:" + translatorLink;

            /*shareLinksString= cms.contentshow(newsBulletin, "ShareLinks");
            if (!CmsAgent.elementExists(shareLinksString))
                shareLinksString = "true"; // Default value if this element does not exist in the news bulletin file (backward compatibility)

            try {
                shareLinks      = Boolean.valueOf(shareLinksString).booleanValue();
            } catch (Exception e) {
                shareLinks = true; // Default value if above line fails (it shouldn't, but just to be safe...)
            }*/



            //
            // HTML OUTPUT
            //
            out.println("<h1>" + title + "</h1>");
            String byline = "<div class=\"byline\"><div class=\"names\">";
            // Author and/or translator names - print them as mailto-links if e-mail addresses are present
            if (CmsAgent.elementExists(author) || CmsAgent.elementExists(translator)) {
                byline += LABEL_BY + " ";
                byline += (CmsAgent.elementExists(authorLink) ? ("<a href=\"" + authorLink + "\">" + author + "</a>") : author);
                if (!translator.isEmpty()) {
                    if (CmsAgent.elementExists(author))
                        byline += ", " + LABEL_TRANSLATED_BY.toLowerCase() + " ";
                    else
                        byline += LABEL_TRANSLATED_BY + " ";
                    byline += (CmsAgent.elementExists(translatorLink) ? ("<a href=\"" + translatorLink + "\">" + translator + "</a>") : translator);
                }
                byline += "&nbsp;&ndash;&nbsp;";
            }
            // Print the date
            byline += "<time datetime=\"" + DATE_FORMAT_ISO.format(new Date(Long.valueOf(published).longValue())) + "\">" + CmsAgent.formatDate(published, DATEFORMAT, locale) + "</time>";
            byline += "</div><!-- .names -->";
            /*if (shareLinks) {
                byline += cms.getContent(SHARE_LINK_MIN);
            }*/

            byline += "</div><!-- .byline -->";

            if (CmsAgent.elementExists(authorLink) || CmsAgent.elementExists(translatorLink)) {
                byline = CmsAgent.obfuscateEmailAddr(byline, false);
            }
            out.print(byline);
            //out.println("<div class=\"news\">");
            //out.println("<div class=\"news-text\">");
            if (CmsAgent.elementExists(ingress)) 
                out.println("<div class=\"ingress\">" + ingress + "</div><!-- END ingress -->");

            //
            // Paragraphs, handled by a separate file
            //
            cms.include(PARAGRAPH_HANDLER);

            //
            // Categories
            //
            String categoriesLabel = "<h5 class=\"cat-tag-label\">" + LABEL_SIMILAR_ARTICLES + "</h5>";
            String categories = "";
            String catId = null;
            // A collection to hold list of news from each category found on this newsbulletin
            List catNewsLists = new ArrayList();
            List assignedCategories = catService.readResourceCategories(cmso, requestFileUri);
            Iterator itr = assignedCategories.iterator();
            if (itr.hasNext()) {
                //categories += "<ul>";
                while (itr.hasNext()) {
                    CmsCategory cat = (CmsCategory)itr.next();
                    if (!hiddenCategories.contains(cat.getRootPath())) {
                        catId = cat.getPath();
                        categories += "<a href=\"" + cms.link(newsFolder) + "?cat=" + catId + "\">" + cat.getTitle() + "</a>" + (itr.hasNext() ? ", " : "");
                        //categories += "<li><a href=\"" + cms.link(newsFolder) + "?cat=" + catId + "\">" + cat.getTitle() + "</a></li>";
                    }
                }
                //categories += "</ul>";
            }

            if (!categories.isEmpty()) {
                // Print categories
                out.println("<aside class=\"similar-articles\">" + categoriesLabel + categories + "</aside>");
            }

            /*if (shareLinks) {
                out.println(cms.getContent(SHARE_LINKS));
                //request.setAttribute("share", "true");
                sess.setAttribute("share", "true");
            }*/
        }


        out.println("</article><!-- .main-content -->");
        out.println("<div id=\"rightside\" class=\"column small\">");
        //out.println("</div><!-- .twocol -->");
        //out.println("<div class=\"onecol\">");


        //
        // Pre-defined and generic link lists, handled by a separate file
        //
        cms.include(LINKLIST_HANDLER);


        out.println("</div><!-- #rightside -->");
        //out.println("<div class=\"description\">" + categories + "</div>");
    } catch (NullPointerException npe) {
        if (npe.getMessage().indexOf("MISSING CONTENT") > -1) {
            out.println("<h1>We're sorry</h1>" + 
                        "<p>The requested file is not yet available in " + locale.getDisplayLanguage() + ".</p>" +
                        "<p>Please check back at a later time.</p>");
        }
    }
    
    //
    // Include lower part of outer ("master") template
    //
    cms.include(template, elements[1], EDITABLE_TEMPLATE);
%>