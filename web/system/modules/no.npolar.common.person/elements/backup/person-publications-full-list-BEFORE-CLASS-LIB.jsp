<%-- 
    Document   : person-publications-full-list
    Created on : Dec 13, 2013, 11:05:32 AM
    Author     : flakstad
--%><%@page import="java.util.SortedMap,
                 java.util.Arrays,
                 java.util.Collections,
                 java.util.SortedSet,
                 java.util.TreeSet,
                 no.npolar.util.CmsAgent,
                 no.npolar.util.CmsImageProcessor,
                 java.net.*,
                 java.nio.charset.Charset,
                 java.io.*,
                 java.util.Collections,
                 java.util.List,
                 java.util.ArrayList,
                 java.util.Date,
                 java.util.Map,
                 java.util.HashMap,
                 java.util.LinkedHashMap,
                 java.util.Set,
                 java.util.Locale,
                 java.util.Iterator,
                 java.text.SimpleDateFormat,
                 org.opencms.relations.CmsCategoryService,
                 org.opencms.file.CmsObject,
                 org.opencms.file.CmsFile,
                 org.opencms.file.CmsResource,
                 org.opencms.file.CmsResourceFilter,
                 org.opencms.file.collectors.I_CmsResourceCollector,
                 org.opencms.file.types.CmsResourceTypeImage, 
                 org.opencms.file.CmsUser,
                 org.opencms.file.CmsProperty,
                 org.opencms.staticexport.CmsLinkManager,
                 org.opencms.json.*,
                 org.opencms.jsp.I_CmsXmlContentContainer, 
                 org.opencms.main.OpenCms,
                 org.opencms.main.CmsException,
                 org.opencms.loader.CmsImageScaler,
                 org.opencms.staticexport.CmsStaticExportManager,
                 org.opencms.security.CmsRole,
                 org.opencms.relations.CmsCategory,
                 org.opencms.util.CmsHtmlExtractor,
                 org.opencms.util.CmsRequestUtil,
                 org.opencms.util.CmsUriSplitter,
                 org.opencms.xml.content.CmsXmlContent,
                 org.opencms.xml.content.CmsXmlContentFactory,
                 org.opencms.xml.types.I_CmsXmlContentValue" session="true"
%><%!
/**
 * Gets an exception's stack trace as a String.
 */
public String getStackTrace(Exception e) {
    //String trace = "<h3>" + e.toString() + "</h3><h4>" + e.getCause() + ": " + e.getMessage() + "</h4>";
    String trace = "<h4>" + e.toString() + " (" + e.getCause() + ")</h4>";
    StackTraceElement[] ste = e.getStackTrace();
    for (int i = 0; i < ste.length; i++) {
        StackTraceElement stElem = ste[i];
        trace += stElem.toString() + "<br />";
    }
    return trace;
}

/**
 * Class for NPI publications.
 * @ToDo: Move to .jar
 */
public class NPIPublication {
    /** 
     * Helper class for people.
     */
    private class Person {
        private String id = null;
        private String organisation = "";
        private String fName = "";
        private String lName = "";
        private boolean isNPIContributor = false;
        private List<String> roles = null;
        
        /**
         * Constructs a new instance, based on the given JSON object.
         * @param person The JSON object to use when constructing this instance.
         */
        public Person(JSONObject person) {
            try {
                try { id = person.getString(JSON_KEY_ID); } catch (Exception e) { }
                try { organisation = person.getString(JSON_KEY_ORG); } catch (Exception e) { }
                try { 
                    fName = person.getString(JSON_KEY_FNAME); 
                } catch (Exception e) { 
                    fName = "[unknown]"; 
                }
                try { 
                    lName = person.getString(JSON_KEY_LNAME); 
                } catch (Exception e) { 
                    lName = "[unknown]"; 
                }
                
                // Evaluate the person's role(s)
                JSONArray rolesArr = null;
                try {
                    rolesArr = person.getJSONArray(JSON_KEY_ROLES);
                } catch (Exception e) {
                    // No role defined, assume role=author
                    addRole(JSON_VAL_ROLE_AUTHOR);
                }
                if (rolesArr != null) {
                    for (int j = 0; j < rolesArr.length(); j++) {
                        String role = rolesArr.getString(j);
                        addRole(role);
                    }
                }

                // NPI affiliate?
                try { if (person.getString(JSON_KEY_ORG).equalsIgnoreCase(JSON_VAL_ORG_NPI)) isNPIContributor = true; } catch (Exception e) {}
            } catch (Exception e) { }
        }
        
        /**
         * Gets the ID for this person.
         * @return The ID for this person.
         */
        public String getID() { return id; }
        
        /**
         * Gets the first name for this person.
         * @return The first name for this person.
         */
        public String getFirstName() { return fName; }
        
        /**
         * Gets the last name for this person.
         * @return The last name for this person.
         */
        public String getLastName() { return lName; }
        
        /**
         * Determines whether or not this person contributed on behalf of the NPI.
         * @return True if the person contributed on behalf of the NPI, false if not.
         */
        public boolean isNPIContributor() {
            return isNPIContributor;
        }
        
        /**
         * Checks if this person is assigned the given role.
         * @param role The role to check for.
         * @return True if this person is assigned the given role, false if not.
         */
        public boolean hasRole(String role) {
            return roles.contains(role);
        }
        
        /**
         * Checks if this person is assigned only the given role, and no other role.
         * @param role The role to check for.
         * @return True if this person is assigned only the given role, false if not.
         */
        public boolean hasRoleOnly(String role) {
            return roles.size() == 1 && roles.contains(role);
        }
        
        /**
         * Adds the given role for this person. Every role is assigned only once. 
         * If the person was already assigned the given role, no change is made.
         * @param role The role to add.
         * @return The list of roles for this person, after this method has finished modifying it.
         */
        protected List<String> addRole(String role) {
            if (roles == null)
                roles = new ArrayList<String>(1);
            if (!roles.contains(role))
                roles.add(role);
            return roles;
        }
        
        /**
         * Adds the given roles for this person.
         * @see #addRole(String)
         * @param roles A list containing all roles to add.
         * @return The list of roles for this person, after this method has finished modifying it.
         */
        public List<String> addRoles(List<String> roles) {
            Iterator<String> i = roles.iterator();
            while (i.hasNext()) 
                this.addRole(i.next());
            return roles;
        }
        
        /**
         * Gets all roles for this person.
         * @return The list of roles for this person.
         */
        public List<String> getRoles() { return roles; }
        
        /**
         * Gets a string representation of this person.
         * @return The string representation of this person.
         */
        public String toString() {
            return fName + " " + lName + (hasRole(JSON_VAL_ROLE_EDITOR) ? " (ed.)" : "");
        }
        
        /**
         * Gets an HTML representation of this person.
         * @param specifyEditorRole Whether or not to speficy editors with " (ed.)" after the name.
         * @return The string representation of this person.
         */
        public String toHtml(boolean specifyEditorRole) {
            String s = "";
            
            if (isNPIContributor)
                s += "<strong>";
            
            s += fName + " " + lName; 
            
            if (this.hasRole(JSON_VAL_ROLE_EDITOR) && specifyEditorRole)
                s += " (ed.)";
            
            if (isNPIContributor)
                s += "</strong>";
            
            return s;
        }
        
        /**
         * Gets an HTML representation of this person.
         * @return The string representation of this person.
         */
        public String toHtml() {
            return toHtml(true);
        }
    }
    
    /**
     * Helper class.
     */
    private class PersonCollection {
        /** List containing all people currently in this collection. */
        private List<Person> people = null;
        
        /**
         * Creates a new, empty collection.
         */
        public PersonCollection() {
            people = new ArrayList<Person>(0);
        }
        
        /**
         * Creates a new collection from the given JSON array.
         * @param persons A JSON array containing JSON objects, where each object describes a person.
         */
        public PersonCollection(JSONArray persons) {
            people = new ArrayList<Person>(0);
            for (int i = 0; i < persons.length(); i++) {
                try {
                    JSONObject person = persons.getJSONObject(i);
                    add(person);
                } catch (Exception e) {
                    continue;
                }
            }
        }
        
        /**
         * Adds a person to this collection.
         * @param person The JSON object that describes the person object.
         * @return The list of people in this collection, after the given person has been added.
         */
        public List<Person> add(JSONObject person) {
            Person p = new Person(person);
            List<String> roles = p.getRoles();
            Person existing = getByName(p.getFirstName(), p.getLastName());
            if (existing != null) {
                existing.addRoles(roles);
            } else {
                people.add(p);
            }
            return people;
        }
        
        /**
         * Gets all people with the given role currently in this collection.
         * @param role The role to match against.
         * @return All people with the given role currently in this collection, or an empty list if none.
         */
        public List<Person> getByRole(String role) {
            List<Person> temp = new ArrayList<Person>(0);
            Iterator<Person> i = people.iterator();
            while (i.hasNext()) {
                Person p = i.next();
                if (p.hasRole(role))
                    temp.add(p);
            }
            return temp;
        }
        
        /**
         * Gets a person identified by the given name from this collection, if any.
         * @param fName The first name (given name) of the person to get.
         * @param lName The last name (family name) of the person to get.
         * @return The person identified by the given name, or null if none.
         */
        public Person getByName(String fName, String lName) {
            if (fName == null || lName == null || fName.isEmpty() || lName.isEmpty())
                return null;
            
            Iterator<Person> i = people.iterator();
            while (i.hasNext()) {
                Person p = i.next();
                if (p.getFirstName().equals(fName) && p.getLastName().equals(lName))
                    return p;
            }
            return null;
        }
        
        /**
         * Gets a person identified by the given ID from this collection, if any.
         * @param id The ID used to identify the person to get.
         * @return The person identified by the given ID, or null if none.
         */
        public Person getByID(String id) {
            if (id == null || id.isEmpty())
                return null;
            
            Iterator<Person> i = people.iterator();
            while (i.hasNext()) {
                Person p = i.next();
                if (p.getID().equals(id))
                    return p;
            }
            return null;
        }
        
        /**
         * Gets the list people currently in this collection.
         * @return The list people currently in this collection.
         */
        public List<Person> get() { return people; }
        
        /**
         * Checks if all the people in this collection are editors (and editors only).
         * @return True if all the people in this collection are editors, false if not.
         */
        public boolean containsEditorsOnly() {
            Iterator<Person> i = people.iterator();
            while (i.hasNext()) {
                Person p = i.next();
                if (!p.hasRoleOnly(JSON_VAL_ROLE_EDITOR))
                    return false;
            }
            return true;
        }
    }
    
    /**
     * Helper class for mappings.
     */
    private class Mapper {
        /** Holds the mappings. */
        protected Map<String, String> m = null;
        
        /**
         * Creates a new mapper, using the locale contained in the given CmsAgent.
         * @param cms A CmsAgent, used to access .properties files and determine which locale to use.
         */
        public Mapper(CmsAgent cms) {
            m = new HashMap<String, String>();
            mapDefaults(cms);
        }
        
        /**
         * Creates default mappings. Currently that includes mappings of country codes to names (no - Norway).
         * @param cms A CmsAgent, used to access .properties files and determine which locale to use.
         */
        private void mapDefaults(CmsAgent cms) {
            // Country mappings (NO => Norway etc.), read from workplace.properties
            List countries = new ArrayList(Arrays.asList(cms.label("DATA_COUNTRIES_0").split("\\|")));
            Map countryMapping = new HashMap<String, String>();
            Iterator iCountries = countries.iterator();
            while (iCountries.hasNext()) {
                String countryKeyVal = (String)iCountries.next();
                try {
                    String[] countryKeyValSplit = countryKeyVal.split(":");
                    String countryKey = countryKeyValSplit[0];
                    String countryVal = countryKeyValSplit[1];
                    countryMapping.put(countryKey, countryVal);
                } catch (Exception e) {
                    // Ignore ...
                }
            }
            m.putAll(countryMapping);
        }
        
        /**
         * Adds a mapping.
         * @param key The mapping key.
         * @param val The mapping value.
         */
        public void addMapping(String key, String val) {
            m.put(key, val);
        }
        
        /**
         * Gets the mapping identified by the given key.
         * @param key The mapping key.
         * @return The value mapped to the given key. If no such value exists, the given key is returned.
         */
        public String getMapping(String key) {
            String s = (String)m.get(key);
            if (s != null)
                return s;
            return key;
        }
        
        /**
         * Gets the map containing all mappings.
         * @return The map containing all mappings.
         */
        public Map<String, String> get() { return m; }
        
        /**
         * Gets the size of this mapper.
         * @return The size of this mapper.
         */
        public int size() { return m.size(); }
        
        /**
         * Flags whether or not this mapper has a value mapped to the given key.
         * @param key The key to check for.
         * @return True if this mapper has a value mapped to the given key, false if not.
         */
        public boolean hasMappingFor(String key) { return m.containsKey(key) && m.get(key) != null && !m.get(key).isEmpty(); }
    }
    
    /** The JSON object that this instance is built from. */
    private JSONObject o = null;
    
    /** JSON key: Publication title. */
    public static final String JSON_KEY_TITLE         = "title";
    /** JSON key: Links. */
    public static final String JSON_KEY_LINKS         = "links";
    /** JSON key: Links -> rel. */
    public static final String JSON_KEY_LINK_REL      = "rel";
    /** JSON key: Links -> href. */
    public static final String JSON_KEY_LINK_HREF     = "href";
    /** JSON key: Links -> href language. */
    public static final String JSON_KEY_LINK_HREFLANG = "hreflang";
    /** JSON key: Type. */
    public static final String JSON_KEY_LINK_TYPE     = "type";
    /** JSON key: Publish year. */
    public static final String JSON_KEY_PUBYEAR       = "published-year";
    /** JSON key: ID. */
    public static final String JSON_KEY_ID            = "id";
    /** JSON key: Publication type. */
    public static final String JSON_KEY_TYPE          = "publication_type";
    /** JSON key: Comment. */
    public static final String JSON_KEY_COMMENT       = "comment";
    /** JSON key: Volume. */
    public static final String JSON_KEY_VOLUME        = "volume";
    /** JSON key: Issue. */
    public static final String JSON_KEY_ISSUE         = "issue";
    /** JSON key: Journal. */
    public static final String JSON_KEY_JOURNAL       = "journal";
    /** JSON key: Name (generic: journal name, person name etc.). */
    public static final String JSON_KEY_NAME          = "name";
    /** JSON key: NPI series. */
    public static final String JSON_KEY_NPI_SERIES      = "np_series";
    /** JSON key: Series. */
    public static final String JSON_KEY_SERIES          = "series";
    /** JSON key: Series no. */
    public static final String JSON_KEY_SERIES_NO       = "series_no";
    /** JSON key: Pages. */
    public static final String JSON_KEY_PAGES           = "pages";
    /** JSON key: Page count. */
    public static final String JSON_KEY_PAGE_COUNT      = "page_count";
    /** JSON key: People. */
    public static final String JSON_KEY_PEOPLE          = "people";
    /** JSON key: First name. */
    public static final String JSON_KEY_FNAME           = "first_name";
    /** JSON key: Last name. */
    public static final String JSON_KEY_LNAME           = "last_name";
    /** JSON key: Roles. */
    public static final String JSON_KEY_ROLES           = "roles";
    /** JSON key: Organization. */
    public static final String JSON_KEY_ORG             = "organisation";
    /** JSON key: Conference. */
    public static final String JSON_KEY_CONF            = "conference";
    /** JSON key: Conference name. */
    public static final String JSON_KEY_CONF_NAME       = "name";
    /** JSON key: Conference place. */
    public static final String JSON_KEY_CONF_PLACE      = "place";
    /** JSON key: Conference country. */
    public static final String JSON_KEY_CONF_COUNTRY    = "country";
    /** JSON key: Conference dates. */
    public static final String JSON_KEY_CONF_DATES      = "dates";
    //public static final String JSON_KEY_

    /** Pre-defined JSON value for "related". */
    public static final String JSON_VAL_LINK_RELATED  = "related";
    /** Pre-defined JSON value for "DOI". */
    public static final String JSON_VAL_LINK_DOI      = "doi";
    /** Pre-defined JSON value for "DOI". */
    public static final String JSON_VAL_LINK_XREF_DOI = "xref_doi";
    /** Pre-defined JSON value for "author". */
    public static final String JSON_VAL_ROLE_AUTHOR   = "author";
    /** Pre-defined JSON value for "editor". */
    public static final String JSON_VAL_ROLE_EDITOR   = "editor";
    /** Pre-defined JSON value for "NPI (organization)". */
    public static final String JSON_VAL_ORG_NPI       = "npolar.no";
    
    /** The date format used in the JSON. */
    public static final String DATE_FORMAT_JSON         = "yyyy-MM-dd";
    /** The date format used when generating strings meant for viewing (English) */
    public static final String DATE_FORMAT_SCREEN_NO    = "d. MMM yyyy";
    /** The date format used when generating strings meant for viewing (Norwegian). */
    public static final String DATE_FORMAT_SCREEN_EN    = "d MMM yyyy";
    /** The base URL for publication links. */
    public static final String URL_PUBLINK_BASE         = "http://data.npolar.no/publication/";
    /** The base URL for DOI links. */
    public static final String URL_DOI_BASE             = "http://dx.doi.org/";
    /** The default title, used if title is missing. */
    public static final String DEFAULT_TITLE            = "Unknown title";
    /** The default locale to use when generating strings meant for viewing. */
    public static final String DEFAULT_LOCALE_NAME      = "en";
    
    // Class members
    private String title = "";
    private String authors = "";
    private String pubYear = "";
    private String journalName = "";
    private String journalSeries = "";
    private String journalSeriesNo = "";
    //private String journal = "";
    private String volume = "";
    private String issue = "";
    private String pageStart = "";
    private String pageEnd = "";
    private String pageCount = "";
    //private String pages = "";
    private String doi = "";
    private String id = "";
    private String link = "";
    private String type = "";
    private String confName = "";
    private String confPlace = "";
    private String confCountry = "";
    private String confDates = "";
    private Date confStart = null;
    private Date confEnd = null;
    private JSONObject conference = null;
    private JSONArray links = null;
    /** The locale to use when generating strings meant for viewing. (Important especially for date formats etc.) */
    private Locale displayLocale = new Locale(DEFAULT_LOCALE_NAME);
    private CmsAgent cms = null;
    private Map<String, String> countryMappings = null;
    
    /** Collection to hold all people the have contributed to this publication. */
    private PersonCollection personCollection = null;
    
    private Mapper mappings = null;
    
    /**
     * Creates a new instance from the given JSON object.
     * @param pubObject The JSON object to use when constructing this instance.
     * @param cms A reference CmsAgent, containing among other things the locale to use when generating strings for screen view.
     */
    public NPIPublication(JSONObject pubObject, CmsAgent cms) {
        this.o = pubObject;
        this.cms = cms;
        this.displayLocale = cms.getRequestContext().getLocale();
        init();
    }
    
    /**
     * Builds this instance by interpreting the JSON source.
     */
    protected void init() {
        try { mappings = new Mapper(cms); } catch (Exception e) { }
        try { title = o.getString(JSON_KEY_TITLE); } catch (Exception e) { title = DEFAULT_TITLE; }
        try { pubYear = o.getString(JSON_KEY_PUBYEAR); if (pubYear.equalsIgnoreCase("0")) pubYear = ""; } catch (Exception e) { }
        try { id = o.getString(JSON_KEY_ID); } catch (Exception e) { }
        try { type = o.getString(JSON_KEY_TYPE); } catch (Exception e) { }
        try { volume = o.getString(JSON_KEY_VOLUME); } catch (Exception e) { }
        try { issue = o.getString(JSON_KEY_ISSUE); } catch (Exception e) { }
        try { pageCount = o.getString(JSON_KEY_PAGE_COUNT); } catch (Exception e) { }
        try { links = o.getJSONArray(JSON_KEY_LINKS); } catch (Exception e) { }
        
        ////////////////////////////////////////////////////////////////////////
        // People
        if (o.has(JSON_KEY_PEOPLE)) {
            try {
                JSONArray persons = o.getJSONArray(JSON_KEY_PEOPLE);
                personCollection = new PersonCollection(persons);
            } catch (Exception e) { }
        }
        
        ////////////////////////////////////////////////////////////////////////
        // Pages
        JSONArray pagesArr = null;
        try {
            pagesArr = o.getJSONArray(JSON_KEY_PAGES);
            if (pagesArr.length() == 2) {
                pageStart = pagesArr.getString(0).trim();
                pageEnd = pagesArr.getString(1).trim();
            }
        } catch (Exception e) { }
        
        ////////////////////////////////////////////////////////////////////////
        // Journal
        JSONObject journalObj = null;
        try {
            journalObj = o.getJSONObject(JSON_KEY_JOURNAL);
            try { journalName = journalObj.getString(JSON_KEY_NAME).trim(); } catch (Exception e) { }
            if (journalObj.has(JSON_KEY_NPI_SERIES) || journalObj.has(JSON_KEY_SERIES)) {
                try { 
                    journalSeries = journalObj.getString(JSON_KEY_SERIES).trim(); // If there is a "normal" series, use that.
                } catch (Exception e) {
                    try {
                        journalSeries = journalObj.getString(JSON_KEY_NPI_SERIES).trim(); // If not, use the NPI series.
                    } catch (Exception ee) {
                        
                    }
                }
                if (journalObj.has(JSON_KEY_SERIES_NO)) {
                    journalSeriesNo = journalObj.getString(JSON_KEY_SERIES_NO).trim();
                }
            }
            /*if (journalObj.has(JSON_KEY_NPI_SERIES)) {
                journalSeries = journalObj.getString(JSON_KEY_NPI_SERIES).trim();
                if (journalObj.has(JSON_KEY_SERIES_NO)) {
                    journalSeriesNo = journalObj.getString(JSON_KEY_SERIES_NO).trim();
                }
            }*/
        } catch (Exception e) { }
        
        ////////////////////////////////////////////////////////////////////////
        // DOI
        try {
            for (int i = 0; i < links.length(); i++) {
                JSONObject link = links.getJSONObject(i);
                try {
                    if (link.getString(JSON_KEY_LINK_REL).equalsIgnoreCase(JSON_VAL_LINK_DOI)) {
                        doi = link.getString(JSON_KEY_LINK_HREF).replace(URL_DOI_BASE, "");
                        //break;
                    }
                    else if (link.getString(JSON_KEY_LINK_REL).equalsIgnoreCase(JSON_VAL_LINK_XREF_DOI)) {
                        if (doi == null || doi.isEmpty())
                            doi = link.getString(JSON_KEY_LINK_HREF).replace(URL_DOI_BASE, "");
                    }                      
                } catch (Exception doie) { }
            }
        } catch (Exception e) { }
        
        ////////////////////////////////////////////////////////////////////////
        // Conference
        String s = "";
        try { 
            conference = o.getJSONObject(JSON_KEY_CONF);
            try { confName = conference.getString(JSON_KEY_CONF_NAME).trim(); } catch (Exception e) { }
            try { confPlace = conference.getString(JSON_KEY_CONF_PLACE).trim(); } catch (Exception e) { }
            //try { confCountry = getMappedString(conference.getString(JSON_KEY_CONF_COUNTRY).trim()); } catch (Exception e) { }
            try { confCountry = mappings.getMapping(conference.getString(JSON_KEY_CONF_COUNTRY).trim()); } catch (Exception e) { }
            
            if (conference.has(JSON_KEY_CONF_DATES)) {
                try {
                    JSONArray dates = conference.getJSONArray(JSON_KEY_CONF_DATES);
                    if (dates != null) {
                        try {
                            SimpleDateFormat dfSource = new SimpleDateFormat(DATE_FORMAT_JSON);
                            SimpleDateFormat dfScreen = new SimpleDateFormat(displayLocale.toString().equalsIgnoreCase("no") ? DATE_FORMAT_SCREEN_NO : DATE_FORMAT_SCREEN_EN, displayLocale);
                            confStart = dfSource.parse(dates.getString(0));
                            confDates = dfScreen.format(confStart);
                            confEnd = dfSource.parse(dates.getString(1));
                            if (confEnd.after(confStart))
                                confDates += "&nbsp;&ndash;&nbsp;" + dfScreen.format(confEnd);
                        } catch (Exception e) { }
                    }
                } catch (Exception e) { }
            }
        } catch (Exception e) { }
    }
    
    /**
     * Gets the title for this publication.
     * @return The title for this publication.
     */
    public String getTitle() { return title; }
    
    /**
     * Gets the publish year for this publication.
     * @return The publish year for this publication.
     */
    public String getPubYear() { return pubYear; }
    
    /**
     * Gets the ID for this publication.
     * @return The ID for this publication.
     */
    public String getID() { return id; }
    
    /**
     * Gets the type for this publication.
     * @return The type for this publication.
     */
    public String getType() { return type; }
    
    /**
     * Gets the volume for this publication.
     * @return The volume for this publication.
     */
    public String getVolume() { return volume; }
    
    /**
     * Gets the issue for this publication.
     * @return The issue for this publication.
     */
    public String getIssue() { return issue; }
    
    /**
     * Gets the links for this publication.
     * @return The links for this publication.
     */
    public JSONArray getLinks() { return links; }
    
    /**
     * Gets the default link for this publication.
     * @return The default link for this publication.
     */
    public String getPubLink(String baseUrl) {
        return getID().isEmpty() ? "" : baseUrl + getID();
    }
    
    /**
     * Gets the journal name for this publication.
     * @return The journal name for this publication.
     */
    public String getJournalName() { return journalName; }
    
    /**
     * Gets the series for this publication.
     * @return The series for this publication.
     */
    public String getJournalSeries() { return journalSeries; }
    
    /**
     * Gets the series no. for this publication.
     * @return The series no. for this publication.
     */
    public String getJournalSeriesNo() { return journalSeriesNo; }
    
    /**
     * Gets the complete journal string for this publication.
     * @return The complete journal string for this publication.
     */
    public String getJournal() {
        String s = "";
        try {
            s = journalName;
            if (isInSeries()) {
                s += ". " + journalSeries;
                if (hasSeriesNo()) {
                    s += " " + journalSeriesNo;
                }
            }
        } catch (Exception e) { }
        return s;
    }
    
    /**
     * Gets a flag indicating whether or not this publication is of the given type. 
     * The type match is not case sensitive.
     * @return True if this publication is of the given type, false if not.
     */
    public boolean isType(String type) { return !this.type.isEmpty() && this.type.equalsIgnoreCase(type); }
    
    /**
     * Gets a flag indicating whether or not this publication is related to a conference.
     * @return True if this publication is related to a conference, false if not.
     */
    public boolean isConferenceRelated() { return !confName.isEmpty(); }
    
    /**
     * Gets a flag indicating whether or not this publication is part of a series.
     * @return True if this publication is part of a series, false if not.
     */
    public boolean isInSeries() { return !journalSeries.isEmpty(); }
    
    /**
     * Gets a flag indicating whether or not this publication has a series number.
     * @return True if this publication has a sereis number, false if not.
     */
    public boolean hasSeriesNo() { return !journalSeriesNo.isEmpty(); }
    
    /**
     * Gets a flag indicating whether or not this publication has editors only.
     * @return True if this publication has editors only, false if not.
     */
    public boolean hasEditorsOnly() { return personCollection.containsEditorsOnly(); }

    /**
     * Gets the start page number for this publication.
     * @return The start page number for this publication.
     */
    public String getPageStart() { return pageStart; }
    
    /**
     * Gets the end page number for this publication.
     * @return The end page number for this publication.
     */
    public String getPageEnd() { return pageEnd; }
    
    /**
     * Gets the complete pages string for this publication.
     * @return The complete pages string for this publication.
     */
    public String getPages() {
        String s = "";
        if (!pageStart.isEmpty()) {
            s += pageStart + (!pageEnd.isEmpty() ? "&ndash;".concat(pageEnd) : "");
        }
        return s;
    }
    
    /**
     * Gets the page count (total number of pages) for this publication.
     * @return The page count (total number of pages) for this publication.
     */
    public String getPageCount() {
        return pageCount;
    }
    
    /**
     * Gets the DOI for this publication.
     * @return The DOI for this publication.
     */
    public String getDOI() { return doi; }
    
    /**
     * Gets the complete authors string for this publication.
     * @return The complete authors string for this publication.
     */
    public String getAuthors() {
        return getPersonsStringByRole(JSON_VAL_ROLE_AUTHOR);
    }
    
    /**
     * Gets the complete editors string for this publication.
     * @return The complete editors string for this publication.
     */
    public String getEditors() {
        return getPersonsStringByRole(JSON_VAL_ROLE_EDITOR);
    }
    
    /**
     * Gets the complete names (authors and editors) string for this publication.
     * @return The complete names (authors and editors) string for this publication.
     */
    public String getNames() {
        String s = "";
        boolean specifyEditors = !this.hasEditorsOnly();
        if (personCollection != null) {
            List<Person> list = personCollection.get();
            Iterator<Person> i = list.iterator();
            while (i.hasNext()) {
                s += i.next().toHtml(specifyEditors);
                if (i.hasNext())
                    s += ", ";
            }
        }
        return s;
    }
    
    /**
     * Gets the complete names string for all contributors to this publication that
     * are assigned the given role. (E.g. #JSON_VAL_ROLE_AUTHOR.)
     * @param role The role to match against, for example #JSON_VAL_ROLE_AUTHOR.
     * @return The complete names string for all contributors to this publication that are assigned the given role.
     */
    public String getPersonsStringByRole(String role) {
        String s = "";
        if (personCollection != null) {
            List<Person> list = personCollection.getByRole(role);
            Iterator<Person> i = list.iterator();
            while (i.hasNext()) {
                s += i.next().toHtml(false);
                if (i.hasNext())
                    s += ", ";
            }
        }
        return s;
    }
    
    /**
     * Gets the complete conference string for this publication.
     * @return The complete conference string for this publication.
     */
    public String getConference() {
        String s = "";
        if (this.isConferenceRelated()) {
            s += "<em>" + confName + "</em>";
            if (!confPlace.isEmpty())
                s += ", " + confPlace;
            if (!confCountry.isEmpty()) 
                s += ", " + confCountry;
            if (!confDates.isEmpty())
                s += ", " + confDates;
        }
        return s;
    }
    
    /**
     * Gets the string representation for this publication.
     * @return The string representation for this publication.
     */
    public String toString() {
        String s = "";
        
        /*String authors = getAuthors();
        if (!authors.isEmpty())
            s += authors + ".";*/
        String names = getNames();
        if (!names.isEmpty()) {
            s += names; 
            if (hasEditorsOnly()) {
                s += " (ed" + (personCollection.get().size() > 1 ? "s" : "") + ".)";
            }                
            s += ".";
        }
        if (!pubYear.isEmpty())
            s += " " + pubYear + ".";
        s += " <a href=\"" + URL_PUBLINK_BASE + id + "\"><em>" + title + "</em></a>. ";
        
        // Journal
        String journal = getJournalName();
        if (!journal.isEmpty()) {
            s += journal;
        }
        // Volume / series
        if (!volume.isEmpty() || !journalSeries.isEmpty() || !getPages().isEmpty()) {
            if (!journalSeries.isEmpty()) {
                s += (journal.isEmpty() ? "" : ". ") + journalSeries;
                if (!journalSeriesNo.isEmpty())
                    s += "&nbsp;" + journalSeriesNo;
                else if (!volume.isEmpty())
                    s += "&nbsp;" + volume;
            }
            else if (!volume.isEmpty()) {
                s += "&nbsp;" + volume;
                if (!issue.isEmpty()) {
                    s += "(" + issue + ")";
                }
            }
            // Pages
            if (!getPages().isEmpty()) {
                s += ":&nbsp;" + getPages() + ".";
            }
        }
        
        // Conference
        if (!getConference().isEmpty()) {
            s += " " + getConference();
        }
        s += ".";
        
        if (s.endsWith(".."))
            s = s.substring(0, s.length()-1);
        
        if (s.endsWith(". ."))
            s = s.substring(0, s.length()-2);
        
        if (getPages().isEmpty() && !getPageCount().isEmpty()) {
            s += " " + getPageCount() + " pp.";
        }
        
        s += (doi.isEmpty() ? "" : "<br />DOI:<a href=\"" + URL_DOI_BASE + doi + "\">" + doi + "</a>");
        return s;
    }
}

/**
 * Publication collection: A list wrapper, with ordering control and methods to 
 * extract subsets based on type.
 */
public class PublicationCollection {
    //private LinkedHashMap<String, ArrayList<SimplePublication>> pubs = null;
    /** The list container, where all publications in this collection is stored. */
    private LinkedHashMap<String, ArrayList<NPIPublication>> pubs = null;
    /** The pre-defined keyword for identifying peer-reviewed publications */
    public static final String PEER_REVIEWED = "peer-reviewed";
    /** The pre-defined keyword for identifying editorials */
    public static final String EDITORIAL = "editorial";
    /** The pre-defined keyword for identifying reviews */
    public static final String REVIEW = "review";
    /** The pre-defined keyword for identifying corrections */
    public static final String CORRECTION = "correction";
    /** The pre-defined keyword for identifying books */
    public static final String BOOK = "book";
    /** The pre-defined keyword for identifying maps */
    public static final String MAP = "map";
    /** The pre-defined keyword for identifying posters */
    public static final String POSTER = "poster";
    /** The pre-defined keyword for identifying reports */
    public static final String REPORT = "report";
    /** The pre-defined keyword for identifying abstracts */
    public static final String ABSTRACT = "abstract";
    /** The pre-defined keyword for identifying PhD theses */
    public static final String PHD = "phd";
    /** The pre-defined keyword for identifying Master theses */
    public static final String MASTER = "master";
    /** The pre-defined keyword for identifying proceedings */
    public static final String PROCEEDINGS = "proceedings";
    /** The pre-defined keyword for identifying popular science publications */
    public static final String POPULAR = "popular";
    /** The pre-defined keyword for identifying other publications */
    public static final String OTHER = "other";
    
    /** Order definition: Publications will be stored (and printed) in this order */
    String[] order = { 
        PEER_REVIEWED, 
        BOOK, 
        EDITORIAL, 
        REPORT, 
        MAP,
        REVIEW,
        PROCEEDINGS,
        ABSTRACT,
        CORRECTION,
        PHD,
        MASTER,
        POSTER,
        POPULAR,
        OTHER 
    };
    
    /**
     * Creates a new, empty publication collection.
     */
    public PublicationCollection() {
        pubs = new LinkedHashMap<String, ArrayList<NPIPublication>>();
        for (int i = 0; i < order.length; i++) {
            pubs.put(order[i], new ArrayList<NPIPublication>());
        }
    }
    
    /**
     * Creates a new publication collection containing the publications defined in the given JSON array.
     * @param publicationObjects An array of JSON objects, each of which describe a publication.
     * @param cms A reference CmsAgent, containing among other things the locale to use when generating strings for screen view.
     */
    public PublicationCollection(JSONArray publicationObjects, CmsAgent cms) throws InstantiationException {
        this();
        for (int i = 0; i < publicationObjects.length(); i++) {
            try {
                this.add(new NPIPublication(publicationObjects.getJSONObject(i), cms));
            } catch (Exception e) {
                throw new InstantiationException("Error when trying to create publications list: " + e.getMessage());
            }
        }
    }
    
    /**
     * Gets a sub-list of this collection, which will contain only publications 
     * of the given type, or an empty list if no publications of that type are 
     * currently contained in this collection.
     */
    public ArrayList<NPIPublication> getListByType(String pubType) {
        return this.pubs.get(pubType);
    }
    
    /**
     * Adds a publication to this collection.
     */
    public void add(NPIPublication p) {
        if (pubs.get(p.getType()) == null) // Should never happen, but anyway ...
            pubs.put(p.getType(), new ArrayList<NPIPublication>());
        
        pubs.get(p.getType()).add(p);
    }
    
    /**
     * Returns true if this collection is empty, false if not.
     */
    public boolean isEmpty() {
        return this.size() <= 0;
    }
    
    /**
     * Gets the publication types contained in this collection.
     */
    public Set<String> getTypesContained() {
        return pubs.keySet();
    }
    
    /**
     * Gets the total number of publications in this collection.
     */
    public int size() {
        int size = 0;
        Iterator<String> i = pubs.keySet().iterator();
        while (i.hasNext()) {
            size += pubs.get(i.next()).size();
        }
        return size;
    }
}

/**
 * Class for Accessing the NPI publication service.
 */
public class NPIPublicationService {
    /** The protocol to use when accessing the service. */
    protected static final String SERVICE_PROTOCOL = "http";
    /** The domain name to use when accessing the service. */
    protected static final String SERVICE_DOMAIN_NAME = "api.npolar.no";
    /** The port to use when accessing the service. */
    protected static final String SERVICE_PORT = "80";
    /** The path to use when accessing the service. */
    protected static final String SERVICE_PATH = "/publication/";
    /** The base URL (that is, the complete URL before adding parameters) to use when accessing the service. */
    protected static final String SERVICE_BASE_URL = SERVICE_PROTOCOL + "://" + SERVICE_DOMAIN_NAME + ":" + SERVICE_PORT + SERVICE_PATH;

    /*protected static final String HUMAN_PROTOCOL = "https";
    protected static final String HUMAN_DOMAIN_NAME = "data.npolar.no";
    protected static final String HUMAN_PORT = "443";
    protected static final String HUMAN_PATH_LIST = "/publications/";
    protected static final String HUMAN_PATH_DETAIL = "/publication/";
    protected static final String HUMAN_BASE_URL_LIST = HUMAN_PROTOCOL + "://" + HUMAN_DOMAIN_NAME + ":" + HUMAN_PORT + HUMAN_PATH_LIST;
    protected static final String HUMAN_BASE_URL_DETAIL = HUMAN_PROTOCOL + "://" + HUMAN_DOMAIN_NAME + ":" + HUMAN_PORT + HUMAN_PATH_DETAIL;*/
    
    /** CmsAgent, provides access to locale info and .properties files. */
    protected CmsAgent cms = null;
    /** The full URL to the service. Updated on every service request. */
    protected String serviceUrl = null;
    
    //private int totalResults = -1;
    
    /**
     * Creates a new service instance.
     * @param cms A reference CmsAgent, containing among other things the locale to use when generating strings for screen view.
     */
    public NPIPublicationService(CmsAgent cms) {
        this.cms = cms;
    }
    
    /**
     * Builds a query string based on the given parameters.
     * @param params The parameters to build the query string from.
     * @return The query string, containing the given parameters.
     */
    protected String getParameterString(Map<String, String[]> params) 
            throws java.io.UnsupportedEncodingException {
        
        if (params.isEmpty())
            return "";
        String s = "";
        Iterator<String> i = params.keySet().iterator();
        while (i.hasNext()) {
            String key = i.next();
            String[] values = params.get(key);
            for (int j = 0; j < values.length;) {
                s += key + "=" + values[j];
                if (++j == values.length)
                    break;
                else
                    s += "&";
            }
            if (i.hasNext())
                s += "&";
        }
        //return URLEncoder.encode(s, "utf-8");
        return s;
    }
    
    /**
     * Requests the given URL and returns the response as a String.
     * @param url The URL to request.
     * @return The response, as a string.
     */
    protected String httpResponseAsString(String url) 
            throws MalformedURLException, IOException {
        
        BufferedReader in = new BufferedReader(new InputStreamReader(new URL(url).openConnection().getInputStream()));
        StringBuffer contentBuffer = new StringBuffer();
        String inputLine;
        while ((inputLine = in.readLine()) != null) {
            contentBuffer.append(inputLine);
        }
        in.close();

        return contentBuffer.toString();
    }
    
    /**
     * Queries the service using the given parameters and returns all (if any)
     * publications, generated from the service response.
     * @param param The parameters to use in the service request.
     * @return A list of all publications, generated from the service response, or an empty list if no publications matched.
     */
    public PublicationCollection getPublications(Map<String, String[]> params) 
            throws java.io.UnsupportedEncodingException, MalformedURLException, IOException, JSONException, InstantiationException {
        
        // Make sure default parameters are set (like "format=json")
        params = setDefaultParameters(params);
        serviceUrl = SERVICE_BASE_URL + "?" + getParameterString(params);
        // We're expecting a response in JSON format
        String jsonFeed = httpResponseAsString(serviceUrl);
        JSONObject json = new JSONObject(jsonFeed).getJSONObject("feed");
        //try { totalResults = json.getJSONObject("opensearch").getInt("totalResults"); } catch (Exception e) { }
        JSONArray pubs = json.getJSONArray("entries");
        PublicationCollection publications = new PublicationCollection(pubs, cms);
        return publications;
    }
    
    private Map<String, String[]> setDefaultParameters(Map<String, String[]> params) {
        params.put("format", new String[]{ "json" });
        return params;
    }
    
    /**
     * Gets the base URL for the service.
     * @return The base URL for the service.
     */
    public String getServiceBaseURL() { return SERVICE_BASE_URL; }
    
    /**
     * Gets the full URL used in the last service request.
     * @return The full URL used in the last service request, or null if no request has yet been issued.
     */
    public String getLastServiceURL() { return serviceUrl; }
}
%><%
// JSP action element + some commonly used stuff
CmsAgent cms            = new CmsAgent(pageContext, request, response);
CmsObject cmso          = cms.getCmsObject();
String requestFileUri   = cms.getRequestContext().getUri();
String requestFolderUri = cms.getRequestContext().getFolderUri();
Locale locale           = cms.getRequestContext().getLocale();
String loc              = locale.toString();

// Make sure to use the given locale, if present
if (request.getParameter("locale") != null)  {
    loc = request.getParameter("locale");
    locale = new Locale(loc);
    try { cms.getRequestContext().setLocale(locale); } catch (Exception e) {}
}

// E-mail address (required)
String email = cms.getRequest().getParameter("email");
if (email == null || email.isEmpty()) {
    // crash
    out.println("<!-- Missing identifier. An identifier is required in order to view a person's publications. -->");
    return; // IMPORTANT!
}
email = URLEncoder.encode(email, "utf-8");

// Needed to show additional info to logged-in users
final boolean LOGGED_IN_USER = OpenCms.getRoleManager().hasRole(cms.getCmsObject(), CmsRole.WORKPLACE_USER);
// Output "debug" info?
final boolean DEBUG = false;
// Don't fetch more publications than this
final int LIMIT = 9999;

//
// Parameters to use in the request to the service:
//
Map<String, String[]> params = new HashMap<String, String[]>();
params.put("q"                  , new String[]{ "" }); // Catch-all query
params.put("filter-people.email", new String[]{ email }); // Filter by this person's identifier
params.put("sort"               , new String[]{ "-published-year" }); // Sort by publish year, descending
//params.put("format"             , new String[]{ "json" }); // Explicitly request the a response in JSON format
params.put("limit"              , new String[]{ Integer.toString(LIMIT) }); // Limit the results

//
// Fetch publications
//
PublicationCollection publications = null;
try {
    NPIPublicationService pubService = new NPIPublicationService(cms);
    publications = pubService.getPublications(params);
    if (DEBUG) { out.println("Read " + (publications == null ? "null" : publications.size()) + " publications from service URL <a href=\"" + pubService.getLastServiceURL() + "\" target=\"_blank\">" + pubService.getLastServiceURL() + "</a>."); }
} catch (Exception e) {
    out.println("An unexpected error occured while constructing the publications list.");
    if (LOGGED_IN_USER) {
        out.println("<h3>Seeing as you're logged in, here's what happened:</h3>"
                    + "<div class=\"stacktrace\" style=\"overflow: auto; font-size: 0.9em; font-family: monospace; background: #fdd; padding: 1em; border: 1px solid #900;\">"
                        + getStackTrace(e) 
                    + "</div>");
    }
    return; // IMPORTANT!
}


// -----------------------------------------------------------------------------
// HTML output
//------------------------------------------------------------------------------
if (publications != null && !publications.isEmpty()) {
    //out.println("<h2 class=\"toggletrigger\">" + cms.labelUnicode("label.np.publist.heading") + "</h2>");
    %>
    <a class="toggletrigger" href="javascript:void(0);"><%= cms.labelUnicode("label.np.publist.heading") %></a>
    <div class="toggletarget collapsed">
    <%
    // Get types of publications
    Iterator<String> iTypes = publications.getTypesContained().iterator();
    while (iTypes.hasNext()) {
        String listType = iTypes.next();
        Iterator<NPIPublication> iPubs = publications.getListByType(listType).iterator();
        if (iPubs.hasNext()) {
            %>
            <h3><%= cms.labelUnicode("label.np.pubtype." + listType) + " (" + publications.getListByType(listType).size() + ")" %></h3>
            <ul class="fullwidth indent line-items">
            <%
            while (iPubs.hasNext()) {
                %>
                <li><%= iPubs.next().toString() %></li>
                <%
            }
            %>
            </ul>
            <%
        }
    }
    %>
    </div>
    <script type="text/javascript">
        $('.toggleable.collapsed > .toggletarget').slideUp(1);
        $('.toggleable.collapsed > .toggletrigger').append(' <em class="icon-down-open-big"></em>');
        $('.toggleable > .toggletrigger').click(
            function() {
                $(this).next('.toggletarget').slideToggle(500);
                //$(this).children().first().toggleClass('icon-up-open-big').toggleClass('icon-down-open-big');
                $(this).children().first().toggleClass('icon-up-open-big icon-down-open-big');
            });
    </script>
    <%
}
else {
    // No publications found on serviceUrl 
    if (DEBUG) { out.println("No publications. Publications = " + (publications == null ? "null" : publications.size()) + "."); }
}
%>