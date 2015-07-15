<%@ page import="no.npolar.util.*,
                 no.npolar.common.collectors.*,
                 org.opencms.file.CmsObject,
                 org.opencms.file.CmsResource,
                 org.opencms.main.OpenCms,
                 org.opencms.jsp.I_CmsXmlContentContainer,
                 org.opencms.relations.CmsCategory,
                 org.opencms.relations.CmsCategoryService,
                 org.opencms.file.collectors.CmsCategoryResourceCollector,
                 org.opencms.file.collectors.CmsTimeFrameCategoryCollector,
                 java.util.Collections,
                 java.util.ArrayList,
                 java.util.List,
                 java.util.Iterator,
                 java.util.Comparator,
                 java.util.Locale" session="false"
%><%@ taglib prefix="cms" uri="http://www.opencms.org/taglib/cms"
%><%!
    /**
    *Generates HTML code for a wrapped image, where the wrappers make up a frame around the image.
    *
    *@param imageTag String  The normal <img> tag code.
    *@param imageText String  The image description / text.
    *@param imageSource String  The image source or reference.
    *@param small boolean  True if the HTML should create a frame for a small image, with text floating on the right side of it.
    *                      False if the HTML should create a frame for a large image, with text underneath.
    *@return String The generated HTML code.
    */
    public String getImageFrameHTML(String imageTag, String imageText, String imageCredit) {
        String imageFrameHTML = "<div class=\"illustration\">" + imageTag;
        if (imageText != null || imageCredit != null) {
            imageFrameHTML +=       "<span class=\"imagetext highslide-caption\">" +
                                        (imageText != null ? imageText : "") +
                                        (imageCredit != null ? 
                                        (" <span class=\"imagecredit\">" + imageCredit + "</span><!-- .imagecredit -->") : "") + 
                                    "</span><!-- .imagetext -->";
        }
        imageFrameHTML +=       "</div><!-- END illustration -->";
        return imageFrameHTML;
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

    Locale locale                   = cms.getRequestContext().getLocale();
    String loc                      = locale.toString();
    
    String newsFolder               = cms.property("template-search-folder", "search"); // e.g. "/no/om-oss/nyheter/"
    
    String template                 = cms.getTemplate();
    String[] elements               = cms.getTemplateIncludeElements();

    // Common page element handlers
    final String PARAGRAPH_HANDLER      = "../../no.npolar.common.pageelements/elements/paragraphhandler.jsp";
    final String LINKLIST_HANDLER       = "../../no.npolar.common.pageelements/elements/linklisthandler.jsp";
    final String SHARE_LINKS            = "../../no.npolar.site.npweb/elements/share-addthis-" + loc + ".txt";

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

    I_CmsXmlContentContainer newsBulletin; // Containers
    String title, ingress, published, author, authorMail, translator, translatorMail, shareLinksString; // String variables
    boolean shareLinks = true;

    out.println("<div class=\"twocol\">");
    
    try {
        newsBulletin = cms.contentload("singleFile", "%(opencms.uri)", EDITABLE);

        while (newsBulletin.hasMoreContent()) {
            title       = cms.contentshow(newsBulletin, "Title");
            if (!CmsAgent.elementExists(title)) {
                throw new NullPointerException("MISSING CONTENT");
            }
            ingress         = CmsAgent.stripParagraph(cms.contentshow(newsBulletin, "Ingress"));
            //text          = CmsAgent.stripParagraph(cms.contentshow(newsBulletin, "Text"));
            //text          = cms.contentshow(newsBulletin, "Text");
            published       = cms.contentshow(newsBulletin, "Published");
            author          = CmsAgent.removeUsername(cms.contentshow(newsBulletin, "Author"));
            authorMail      = cms.contentshow(newsBulletin, "AuthorMail");
            translator      = cms.contentshow(newsBulletin, "Translator");
            
            translator      = cms.elementExists(translator) ? CmsAgent.removeUsername(translator) : "";
            translatorMail  = cms.contentshow(newsBulletin, "TranslatorMail");
            
            shareLinksString= cms.contentshow(newsBulletin, "ShareLinks");
            if (!CmsAgent.elementExists(shareLinksString))
                shareLinksString = "true"; // Default value if this element does not exist in the news bulletin file (backward compatibility)
            
            try {
                shareLinks      = Boolean.valueOf(shareLinksString).booleanValue();
            } catch (Exception e) {
                shareLinks = true; // Default value if above line fails (it shouldn't, but just to be safe...)
            }



            //
            // HTML OUTPUT
            //
            out.println("<h1>" + title + "</h1>");
            String byline = "<div class=\"byline\"><div class=\"names\">";
            // Author and/or translator names - print them as mailto-links if e-mail addresses are present
            if (CmsAgent.elementExists(author) || CmsAgent.elementExists(translator)) {
                byline += LABEL_BY + " ";
                byline += (CmsAgent.elementExists(authorMail) ? ("<a href=\"mailto:" + authorMail + "\">" + author + "</a>") : author);
                if (!translator.isEmpty()) {
                    if (CmsAgent.elementExists(author))
                        byline += ", " + LABEL_TRANSLATED_BY.toLowerCase() + " ";
                    else
                        byline += LABEL_TRANSLATED_BY + " ";
                    byline += (CmsAgent.elementExists(translatorMail) ? ("<a href=\"mailto:" + translatorMail + "\">" + translator + "</a>") : translator);
                }
                byline += "&nbsp;&ndash;&nbsp;";
            }
            // Print the date
            byline += CmsAgent.formatDate(published, DATEFORMAT, locale);
            byline += "</div><!-- .names -->";
            if (shareLinks) {
                //byline += cms.getContent(SHARE_LINKS);
            }
            
            byline += "</div><!-- .byline -->";
            
            if (CmsAgent.elementExists(authorMail) || CmsAgent.elementExists(translatorMail)) {
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
            
            if (shareLinks) {
                out.println(cms.getContent(SHARE_LINKS));
            }

            //out.println("</div><!-- END news-text -->");

            // Print out the published-info
            /*out.println("<div class=\"description\">" + 
                            PUBLISHED + CmsAgent.formatDate(published, DATEFORMAT, locale) + " " + AUTHOR.toLowerCase() + 
                            (CmsAgent.elementExists(authorMail) ? 
                            ("<a href=\"mailto:" + authorMail + "\">" + author + "</a>") : author) +
                        "</div>");*/
            //out.println("</div><!-- END news -->");
        }

          
        out.println("</div><!-- .twocol -->");
        out.println("<div class=\"onecol\">");

        
        //
        // Pre-defined and generic link lists, handled by a separate file
        //
        cms.include(LINKLIST_HANDLER);

        //
        // Categories
        //
        String categories = "<h4>" + LABEL_SIMILAR_ARTICLES + "</h4>";
        String catId = null;
        // A collection to hold list of news from each category found on this newsbulletin
        List catNewsLists = new ArrayList();
        List assignedCategories = catService.readResourceCategories(cmso, requestFileUri);
        Iterator itr = assignedCategories.iterator();
        if (itr.hasNext()) {
            //out.println("</td><td id=\"rightside\">");
            //out.println("<hr />");
            categories += "<ul>";
            while (itr.hasNext()) {
                CmsCategory cat = (CmsCategory)itr.next();
                if (!hiddenCategories.contains(cat.getRootPath())) {
                    catId = cat.getPath();
                    //categories += "<a href=\"" + cms.link(newsFolder) + "?cat=" + catId + "\">" + cat.getTitle() + "</a>, ";
                    categories += "<li><a href=\"" + cms.link(newsFolder) + "?cat=" + catId + "\">" + cat.getTitle() + "</a></li>";

                    /*CmsCategoryResourceCollector crc = new CmsCategoryResourceCollector();
                    // Get a list of N newsbulletins tagged with this category (possibly including self)
                    // ************* NB: getResults()'s sort argument does not work!!! *****************
                    List newsFromSameCat = crc.getResults(cmso, "allKeyValuePairFiltered", 
                                                            "resource=" + newsFolder + 
                                                            "|resourceType=newsbulletin" + 
                                                            "|categoryTypes=" + catId + 
                                                            "|subTree=true" +
                                                            "|sortBy=date" +
                                                            "|sortAsc=true" +
                                                            "|count=6");
                    
                    // When collecting a fixed number of items,
                    // Sorting after collecting is useless.
                    // NEED TO WRITE ANOTHER COLLECTOR!
                    final Comparator<CmsResource> DATE_ORDER_DESC = new Comparator<CmsResource>() {
                                                                //private CmsAgent cms = new CmsAgent(pageContext, request, response);
                                                                public int compare(CmsResource one, CmsResource another) {
                                                                    String oneDate = "";
                                                                    String anotherDate = "";
                                                                    try {
                                                                        oneDate = CMSO.readPropertyObject(one, "collector.date", false).getValue("1");
                                                                        anotherDate = CMSO.readPropertyObject(another, "collector.date", false).getValue("1");
                                                                    } catch (Exception e) {
                                                                        oneDate = "1";
                                                                        anotherDate = "1";
                                                                    }
                                                                    return anotherDate.compareTo(oneDate);
                                                                }
                                                            };
                    Collections.sort(newsFromSameCat, DATE_ORDER_DESC);
                    */
                    
                    
                    
                    /*
                    // Using custom collector:
                    CmsExtendedCategoryResourceCollector crc = new CmsExtendedCategoryResourceCollector(newsFolder, 
                                                                                                        "newsbulletin", 
                                                                                                        true, 
                                                                                                        catId,  
                                                                                                        "property:collector.date",
                                                                                                        false, 
                                                                                                        6);
                    List newsFromSameCat = crc.getResults(cmso);
                    
                    // Remove self or, if self is not in the list, remove the oldest of those collected
                    if (!newsFromSameCat.remove(cmso.readResource(resourceUri))) {
                        newsFromSameCat.remove(newsFromSameCat.size() - 1);
                    }

                    //out.println("<div class=\"link-group\">");
                    out.println("<h4>" + LABEL_MORE_NEWS_IN_CATEGORY + cat.getTitle().toLowerCase() + "</h4>");
                    // Add the list to the collection of such lists
                    catNewsLists.add(newsFromSameCat);
                    Iterator iCatNews = newsFromSameCat.iterator();
                    if (iCatNews.hasNext()) {
                        //out.println("<ul class=\"linklist\">");
                        out.println("<ul>");
                        while (iCatNews.hasNext()) {
                            CmsResource catNewsArticle = (CmsResource)iCatNews.next();
                            out.println("<li><a href=\"" + cms.link(cmso.getSitePath(catNewsArticle)) + "\">" + 
                                            cms.property("Title", cmso.getSitePath(catNewsArticle)) + 
                                        "</a></li>");
                        }
                        out.println("</ul>");
                    }
                    //out.println("</div><!-- .linklist -->");
                    */
                }
            }
            categories += "</ul>";
            if (categories.equals("<h4>" + LABEL_SIMILAR_ARTICLES + "</h4>")) {
                categories = "";
            } else {
                /*try {
                    categories = categories.substring(0, categories.lastIndexOf(","));
                } catch (Exception stringIndexException) {
                    // Do nothing
                }*/
            }
            // Print categories
            out.println(categories);
        }
        out.println("</div><!-- .onecol -->");
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