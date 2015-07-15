<%-- 
    Document   : person-new
    Created on : 02.jun.2011, 20:01:15
    Author     : Paul-Inge Flakstad <flakstad at npolar.no>
--%><%-- 
    Document   : person.jsp
    Created on : 09.jun.2009, 15:52:55
    Author     : Paul-Inge Flakstad
--%>

<%@page import="no.npolar.util.*,
                org.opencms.file.CmsObject,
                org.opencms.file.CmsResource,
                org.opencms.file.CmsResourceFilter,
                org.opencms.jsp.I_CmsXmlContentContainer,
                org.opencms.loader.CmsImageScaler,
                org.opencms.relations.CmsCategoryService,
                org.opencms.relations.CmsCategory,
                org.opencms.main.CmsException,
                org.opencms.util.CmsStringUtil,
                javax.swing.tree.*,
                java.util.Collections,
                java.util.List,
                java.util.ArrayList,
                java.util.Iterator,
                java.util.Enumeration,
                java.util.Locale,
                java.util.HashMap"%><%!
                
static String s = null;
/**
* Checks if a category is identical to or a parent of a reference category.
*/
public boolean categoryIsParentCategoryOrSelf(String category, String referenceCategory) {
    if (category.startsWith(referenceCategory)) 
        return true;
    return false;
}

/**
* Checks if a category is a child of a (potential) parent category.
*/
public boolean isChildCategory(String childPath, String parentPath) {
    if (childPath.length() > parentPath.length() && childPath.startsWith(parentPath)) 
        return true;
    return false;
}

public boolean categoryIsParentCategoryOrSibling(String category, String referenceCategory) {
    if (category.startsWith(referenceCategory)) 
        return true;
    try {
        if (CmsResource.getParentFolder(category).equals(CmsResource.getParentFolder(referenceCategory)))
            return true;
    } catch (Exception e) {
        return false;
    }
    return false;
}

public void printKeyValue(CmsAgent cms, String key, String value, JspWriter out) throws java.io.IOException {
    out.println(CmsAgent.elementExists(value) ? 
            ("<div class=\"detail\"><span class=\"key\">" + key + "</span><span class=\"val\">" + value + "</span></div>") : "");
}

/**
* Creates a tree of (unique) categories, representing parent/child relations between the categories.
* The tree is converted to a string, containing html code (nested unordered lists) that can be used directly.
* Because the string is built recursively, a static string, "s", is employed. (And this method returns "void", not "String".)
* The linkUri argument is used when generating links. Each category will be a link to this URI, with its own category path as the "cat" parameter.
* Usage:
* 1. getCategoryTreeString(...);
* 2. String myHtmlCodeForNestedList = new String(s);
*/
public void buildCategoryTreeString(CmsAgent cms, 
                                    String linkUri) throws CmsException {    
    // Reset the static string
    s = "";
    // Get the cms object and other "standard" objects
    CmsObject cmso = cms.getCmsObject();
    String requestFileUri = cms.getRequestContext().getUri();
    Locale locale = cms.getRequestContext().getLocale();
    
    // The base folder (the folder containing all categories)
    String baseFolder = "/" + locale.toString() + "/_categories/";
    
    // Initialize the tree that will represent the affiliation
    DefaultMutableTreeNode root = new DefaultMutableTreeNode("ROOT");
    DefaultTreeModel tree = new DefaultTreeModel(root);
    
    // Read the "category" property, which is the "base category" set on this resource
    // (Available categories for this resource will be sub-categories of this one)
    String categoryPropValue = cms.property("category", "search");
    CmsCategoryService cs = CmsCategoryService.getInstance();
    
    // Add categories that should not be displayed
    //String baseCategory = "org/np/"; //<-- This should be the same as categoryPropValue
    List ignoredCategories = new ArrayList();
    //ignoredCategories.add("org/np/");
    ignoredCategories.add(categoryPropValue);
    
    // Read all possible categories that could be displayed
    List possibleCategories = cs.readCategories(cmso, categoryPropValue, true, requestFileUri);
    /*Iterator iPoss = possibleCategories.iterator();
    s += "<h4>Categories:</h4>";
    while (iPoss.hasNext()) {
        String possible = ((CmsCategory)iPoss.next()).getRootPath();
        s += "#" + possible + "<br />";
    }*/
    
    
    // Read the collector.categories property
    String assignedCategoriesProp = cms.property("collector.categories", requestFileUri, "");
    // Create the list to hold assigned categories
    List assignedCategories = new ArrayList();
    // Populate the list with any and all assigned categories
    if (!assignedCategoriesProp.isEmpty())
        assignedCategories = CmsStringUtil.splitAsList(assignedCategoriesProp, "|");
    
    // Create a list of categories to display
    List displayCategories = new ArrayList();
    
    Iterator iAssignedCategories = assignedCategories.iterator();
    while (iAssignedCategories.hasNext()) {
        String assignedCategoryRootPath = (String)iAssignedCategories.next();
        //CmsCategory assignedCategory = cs.readCategory(cmso, "org/np/ice/", "/en/_categories/"); //<-- works
        // Get the category path, relative to its "_categories" parent folder
        String catPath = CmsCategory.getCategoryPath(assignedCategoryRootPath, baseFolder); //"/sites/np/no/_categories/org/");
        // Get the category itself
        CmsCategory assignedCategory = cs.readCategory(cmso, catPath, requestFileUri);
        // If this category should be ignored, just continue
        if (ignoredCategories.contains(catPath))
            continue;
        
        // Split the category path into parts
        String[] categoryPathParts = CmsStringUtil.splitAsArray(catPath, "/");
        // "Reset" the category path
        catPath = "";
        
        // For each iteration of assigned categories, ROOT is the initial parent
        DefaultMutableTreeNode parent = root;
        
        for (int i = 0; i < categoryPathParts.length; i++) {
            // Construct the category path
            catPath += categoryPathParts[i] + "/"; // i=0: catPath = org/     i=1: catPath = org/np/     i=2: catPath = org/np/ice/     and so on
            int index = 0;
            try {
                // Read the category, using the constructed category path
                assignedCategory = cs.readCategory(cmso, catPath, requestFileUri);
                // If the category is present in the list of possible categories, we want to display it
                if (possibleCategories.contains(assignedCategory)) {
                    DefaultMutableTreeNode node = null;

                    if (findNode(tree, assignedCategory) != null) { // Node already exists in the tree, use it
                        node = findNode(tree, assignedCategory);
                        //out.println("<br />The node '" + ((CmsCategory)node.getUserObject()).getTitle() + "' already existed in the tree.");
                    } else { // Node does not exist in the tree, add it
                        node = new DefaultMutableTreeNode(assignedCategory);
                        tree.insertNodeInto(node, parent, index);
                        //out.println("<br />Inserted '" + ((CmsCategory)node.getUserObject()).getTitle() + "' as child of '" + ((CmsCategory)parent.getUserObject()).getTitle() + "'");
                    }
                    index++;
                    parent = node;
                }
            } catch (Exception e) {
                continue; // If the category could not be read using the given category path, just continue
            }
        } // for (...)
        
    } // while (iAssignedCategories.hasNext())
    
    
    if (tree.getChild(root, 0) != null) {
        printTree(tree, root, linkUri, cms);
    }
}

/**
* Recursive method for printing a tree of category objects.
*/
public void printTree(DefaultTreeModel tree, DefaultMutableTreeNode node, String linkUri, CmsAgent cms) {
    int numChildNodes = tree.getChildCount(node);
    
    try {
        int nodeDepth = tree.getPathToRoot(node).length;
        
        if (!node.isRoot()) {
            //out.println("<ul><li>" + node);// + " [" + nodeDepth + "]");
            CmsCategory category = (CmsCategory)node.getUserObject();
            /*out.println("<ul><li>" + 
                    "<a href=\"" + cms.link(personIndexUri) + "?cat=" + category.getPath() + "\">" + category.getTitle() + "</a>");*/
            s += "<ul" + (nodeDepth <= 2 ? " class=\"person-affiliation\"" : "") + "><li>" + 
                    "<a href=\"" + cms.link(linkUri) + "?cat=" + category.getPath() + "\">" + category.getTitle() + "</a>";
        }
        for (int i = numChildNodes-1; i >= 0; i--) {
            printTree(tree, (DefaultMutableTreeNode)tree.getChild(node, i), linkUri, cms);
        }
        if (!node.isRoot()) {
            /*out.println("</li></ul>");*/
            s += "</li></ul>";
        }
    } catch (Exception e) {
        throw new NullPointerException(e.getMessage());
    }
}

/**
* Finds a node containing a given userObject in the tree. The first encountered matching node
* (using depth first traversal) is returned, or null if no matching node is found.
*/
public DefaultMutableTreeNode findNode(DefaultTreeModel tree, Object userObject) {
    Enumeration treeNodes = ((DefaultMutableTreeNode)tree.getRoot()).depthFirstEnumeration();
    while (treeNodes.hasMoreElements()) {
        DefaultMutableTreeNode node = (DefaultMutableTreeNode)treeNodes.nextElement();
        if (node.getUserObject().equals(userObject))
            return node;
    }
    return null;
}

public String makeNiceWebsite(String url) {
    if (url.startsWith("http://")) {
        url = url.substring(7);
    }
    if (url.endsWith("/")) {
        url = url.substring(0, url.length()-1);
    }
    return url;
}
%>
<%

// Mandatory + useful stuff
CmsAgent cms = new CmsAgent(pageContext, request, response);
CmsObject cmso = cms.getCmsObject();
Locale locale = cms.getRequestContext().getLocale();
String loc = locale.toString();
String reqFileUri = cms.getRequestContext().getUri();
String reqFolderUri = cms.getRequestContext().getFolderUri();
final int TYPE_ID_PERSON = org.opencms.main.OpenCms.getResourceManager().getResourceType("person").getTypeId();

//
// NB:
// THIS NEEDS CHANGE - MAYBE READ FROM A PROPERTY CALLED "listing", "index" OR SOMETHING?
//
final String PERSON_INDEX_URI = loc.equals("no") ? "/no/ansatte/" : "/en/people/";

final String ICON_FOLDER    = "/images/icons/";
final String ICON_EMAIL     = "person-email.png";
final String ICON_PHONE     = "person-phone.png";
final String ICON_WORKPLACE = "person-workplace.png";
final String ICON_ORG       = "person-org.png";

CmsImageProcessor imageHandle = null;

// Labels
/*final String LABEL_AFFILIATION          = "<img src=\"" + cms.link(ICON_FOLDER.concat(ICON_ORG)) +"\" alt=\"" + cms.labelUnicode("label.Person.Affiliation") + "\" />";
final String LABEL_PHONE                = "<img src=\"" + cms.link(ICON_FOLDER.concat(ICON_PHONE)) +"\" alt=\"" + cms.labelUnicode("label.Person.Phone") + "\" />";
final String LABEL_CELLPHONE            = "<img src=\"" + cms.link(ICON_FOLDER.concat(ICON_PHONE)) +"\" alt=\"" + cms.labelUnicode("label.Person.Cellphone") + "\" />";
final String LABEL_EMAIL                = "<img src=\"" + cms.link(ICON_FOLDER.concat(ICON_EMAIL)) +"\" alt=\"" + cms.labelUnicode("label.Person.Email") + "\" />";
final String LABEL_WORKPLACE            = "<img src=\"" + cms.link(ICON_FOLDER.concat(ICON_WORKPLACE)) +"\" alt=\"" + cms.labelUnicode("label.Person.Workplace") + "\" />";*/
final String LABEL_AFFILIATION          = "<i class=\"icon-flow-tree\"></i>";
final String LABEL_PHONE                = "<i class=\"icon-phone-1\"></i>";
final String LABEL_CELLPHONE            = "<i class=\"icon-mobile-1\"></i>";
final String LABEL_EMAIL                = "<i class=\"icon-mail\"></i>";
final String LABEL_WORKPLACE            = "<i class=\"icon-home\"></i>";
final String LABEL_CAREER               = cms.labelUnicode("label.Person.Career");
final String LABEL_ACTIVITIES           = cms.labelUnicode("label.Person.Activities");
final String LABEL_INTEREST_EXPERTISE   = cms.labelUnicode("label.Person.InterestsExpertise");
final String LABEL_BIBLIOGRAPHY         = cms.labelUnicode("label.Person.Bibliography");
final String LABEL_EMPLOYMENT_TYPE      = cms.labelUnicode("label.Person.EmploymentType");
final String LABEL_ON_LEAVE             = cms.labelUnicode("label.Person.OnLeave");
final String LABEL_CURRENTLY_EMPLOYED   = cms.labelUnicode("lable.Person.CurrentlyEmployed");

// The image size for the profile image
final int IMG_SIZE = Integer.valueOf(cmso.readPropertyObject(reqFileUri, "image.size", true).getValue("150")).intValue();

String fName        = null;
String lName        = null;
String pos          = null;
String employment   = null;
String affil        = null;
String degree       = null;
String nation       = null;
String website      = null;
String workplace    = null;
String email        = null;
String phone        = null;
String cell         = null;
String descr        = null;
String career       = null;
String activities   = null;
String areas        = null;
String references   = null;
I_CmsXmlContentContainer other = null;
String otherString  = null;

boolean currentlyEmployed   = true;
boolean onLeave             = false;

String imageUri     = null;

final boolean EDITABLE = true;

if (cmso.readResource(reqFileUri).getTypeId() == TYPE_ID_PERSON) {
    cms.include(cms.getTemplate(), cms.getTemplateIncludeElements()[0], EDITABLE);
}


I_CmsXmlContentContainer thisFile = cms.contentload("singleFile", reqFileUri, EDITABLE);
while (thisFile.hasMoreContent()) {
    ////////////////////////////////////////////////////////////////////////////
    // Read the file
    //
    lName       = cms.contentshow(thisFile, "Surname");
    fName       = cms.contentshow(thisFile, "GivenName");
    pos         = cms.contentshow(thisFile, "Position");
    employment  = cms.contentshow(thisFile, "EmploymentType");
    imageUri    = cms.contentshow(thisFile, "Image");
    affil       = cms.contentshow(thisFile, "Affiliation");
    onLeave     = CmsAgent.elementExists(cms.contentshow(thisFile, "OnLeave")) ? Boolean.valueOf(cms.contentshow(thisFile, "OnLeave")).booleanValue() : false;
    currentlyEmployed = CmsAgent.elementExists(cms.contentshow(thisFile, "CurrentlyEmployed")) ? Boolean.valueOf(cms.contentshow(thisFile, "CurrentlyEmployed")).booleanValue() : true;
    degree      = cms.contentshow(thisFile, "Degree");
    nation      = cms.contentshow(thisFile, "Nationality");
    website     = cms.contentshow(thisFile, "PersonalWebsite");
    workplace   = cms.contentshow(thisFile, "Workplace");
    email       = cms.contentshow(thisFile, "Email");
    phone       = cms.contentshow(thisFile, "Phone");
    cell        = cms.contentshow(thisFile, "Cellphone");
    descr       = cms.contentshow(thisFile, "Description");
    career      = cms.contentshow(thisFile, "Career");
    activities  = cms.contentshow(thisFile, "Activities");
    areas       = cms.contentshow(thisFile, "InterestsExpertise");
    references  = cms.contentshow(thisFile, "Bibliography");
    other       = cms.contentloop(thisFile, "Other");
    //
    // Done reading the file
    ////////////////////////////////////////////////////////////////////////////
    
    // Build the "other" string (if needed) 
    otherString = "";
    while (other.hasMoreContent()) {
        String heading = cms.contentshow(other, "Heading");
        String text = cms.contentshow(other, "Text");
        if (CmsAgent.elementExists(heading))
            otherString += "<h2>" + heading + "</h2>";
        if (CmsAgent.elementExists(text))
            otherString += text;
    }
    
    // Build the organizational affiliation list (this method is recursive, and will assign a value to the static string "s")
    buildCategoryTreeString(cms, PERSON_INDEX_URI);
    // Copy the value of the the static string "s" (it should now be the list of affiliations)
    String organizational = new String(s);
    
    //
    // Output
    //
    out.println("<article class=\"main-content\">");
    //out.println("<div class=\"twocol\">");
    out.println("<div itemscope itemtype=\"http://schema.org/Person\" class=\"person\">");
    out.println("<h1 itemprop=\"name\">" + (CmsAgent.elementExists(degree) ? ("<span itemprop=\"honorificPrefix\">"+degree + "</span> ") : "") + fName + " " + lName + "</h1>");
    
    out.println("<div class=\"detail\">");
    /*if (employment.equalsIgnoreCase("PhD") || employment.equalsIgnoreCase("Post-doc")) {
        out.println(cms.label("label.for.person.employmenttype.".concat(employment.toLowerCase())));
    }*/
    out.print("<span itemprop=\"jobTitle\">" + pos + "</span>");
    if (onLeave) 
        out.println(" (" + LABEL_ON_LEAVE.toLowerCase() + ")");
    out.println("</div>");
    
    
    if (currentlyEmployed) { // Don't print info about people who are no longer employed
        if (CmsAgent.elementExists(affil) || 
                CmsAgent.elementExists(workplace) ||
                CmsAgent.elementExists(phone) || 
                CmsAgent.elementExists(cell) || 
                CmsAgent.elementExists(email)) {
            out.println("<div class=\"contact-info\">");

            if (CmsAgent.elementExists(imageUri)) {
                // Get an advanced image handle, using the image wrapper class
                imageHandle = new CmsImageProcessor(cmso, cmso.readResource(imageUri));
                String imageAltText = fName + " " + lName;
                String image = "<img itemprop=\"image\" alt=\"" + imageAltText + "\" src=\"";
                if (imageHandle.getWidth() > IMG_SIZE) {
                    // Downscale needed, get a scaler
                    CmsImageScaler downScaler = imageHandle.getReScaler(imageHandle);
                    // Set width, height, type (4 = exact target size) and quality (100 = max)
                    downScaler.setWidth(IMG_SIZE);
                    downScaler.setHeight(imageHandle.getNewHeight(IMG_SIZE, imageHandle.getWidth(), imageHandle.getHeight()));
                    downScaler.setType(4);
                    downScaler.setQuality(100);
                    // Additional image attributes
                    //HashMap imageAttribs = new HashMap();
                    //imageAttribs.put("alt", imageAltText);
                    // Print the image tag
                    //out.println(cms.img(imageUri, downScaler, imageAttribs));
                    image += CmsAgent.getTagAttributesAsMap(cms.img(imageUri, downScaler, null)).get("src") + "\" />";
                } else {
                    // No downscale needed, print image tag directly
                    //out.println("<img src=\"" + cms.link(imageUri) + "\" alt=\"" + imageAltText + "\" />");
                    image += cms.link(imageUri) + "\" />";
                }
                out.println("<span class=\"media pull-right xs\">" + image + "</span>");
            }
            
            out.println("<div class=\"contact-info-text\">");
            //printKeyValue(cms, LABEL_EMAIL, cms.getJavascriptEmail(email, true, null), out);
            //printKeyValue(cms, LABEL_PHONE, phone, out);
            //printKeyValue(cms, LABEL_CELLPHONE, cell, out);
            //printKeyValue(cms, LABEL_WORKPLACE, workplace, out);
            //printKeyValue(cms, LABEL_AFFILIATION, organizational, out);
            
            if (CmsAgent.elementExists(email))
                out.println("<div class=\"detail\" itemprop=\"email\"><span class=\"key\">" + LABEL_EMAIL + "</span><span class=\"val\">" + cms.getJavascriptEmail(email, true, null) + "</span></div>");
            if (CmsAgent.elementExists(phone))
                out.println("<div class=\"detail\" itemprop=\"telephone\"><span class=\"key\">" + LABEL_PHONE + "</span><span class=\"val\">" + phone + "</span></div>");
            if (CmsAgent.elementExists(cell))
                out.println("<div class=\"detail\" itemprop=\"telephone\"><span class=\"key\">" + LABEL_CELLPHONE + "</span><span class=\"val\">" + cell + "</span></div>");
            if (CmsAgent.elementExists(workplace))
                out.println("<div class=\"detail\" itemprop=\"workLocation\"><span class=\"key\">" + LABEL_WORKPLACE + "</span><span class=\"val\">" + workplace + "</span></div>");
            if (CmsAgent.elementExists(organizational))
                out.println("<div class=\"detail\"><span class=\"key\">" + LABEL_AFFILIATION + "</span><div class=\"val\">" + organizational + "</div></div>");
            
            out.println("<span style=\"display:none;\" itemprop=\"affiliation\">" + (loc.equalsIgnoreCase("no") ? "Norsk Polarinstitutt" : "Norwegian Polar Institute") + "</span>");
            
            out.println("</div><!-- .contact-info-text -->");
            out.println("</div><!-- .contact-info -->");
        }
    }
    
    if (CmsAgent.elementExists(website)) {
        out.println("<p>" + cms.label("label.Person.PersonalWebsite") + ": <a href=\"" + website + "\" rel=\"nofollow\">" + makeNiceWebsite(website) + "</a></p>");
    }
    
    if (CmsAgent.elementExists(descr)) {
        out.println(descr);
    }
    
    //out.println("<h4>other.getCollectorResult().isEmpty() = " + other.getCollectorResult().isEmpty() + "</h4>");
    
    if (CmsAgent.elementExists(career) || 
            CmsAgent.elementExists(activities) || 
            CmsAgent.elementExists(areas) || 
            CmsAgent.elementExists(references) ||
            !otherString.isEmpty()) {
        out.println("<div class=\"about\">");
        if (CmsAgent.elementExists(activities)) {
            out.println("<h2>" + LABEL_ACTIVITIES + "</h2>");
            out.println(activities);
        }
        if (CmsAgent.elementExists(career)) {
            out.println("<h2>" + LABEL_CAREER + "</h2>");
            out.println(career);
        }
        if (CmsAgent.elementExists(areas)) {
            out.println("<h2>" + LABEL_INTEREST_EXPERTISE + "</h2>");
            out.println(areas);
        }
        if (CmsAgent.elementExists(references)) {
            out.println("<h2>" + LABEL_BIBLIOGRAPHY + "</h2>");
            out.println(references);
        }
        
        //I_CmsXmlContentContainer other = cms.contentloop(thisFile, "Other");
        /*while (other.hasMoreContent()) {
            String heading = cms.contentshow(other, "Heading");
            String text = cms.contentshow(other, "Text");
            if (CmsAgent.elementExists(heading))
                out.println("<h2>" + heading + "</h2>");
            if (CmsAgent.elementExists(text))
                out.println(text);
        }*/
        if (!otherString.isEmpty()) {
            out.println(otherString);
        }
        out.println("</div><!-- .about -->");
    }
    out.println("</div><!-- .person -->");
    out.println("</article><!-- .main-content -->");
    //out.println("</div><!-- .twocol -->");
    
    out.println("<div id=\"rightside\" class=\"column small\">");
    //out.println("<div class=\"onecol\">");
    // Special menu for personal pages...
    cms.include("/system/modules/no.npolar.site.npweb/elements/personal-menu.jsp");
    out.println("</div><!-- #rightside -->");
    //out.println("</div><!-- .onecol -->");
}

if (cmso.readResource(reqFileUri).getTypeId() == TYPE_ID_PERSON) {
    cms.include(cms.getTemplate(), cms.getTemplateIncludeElements()[1], EDITABLE);
}
%>