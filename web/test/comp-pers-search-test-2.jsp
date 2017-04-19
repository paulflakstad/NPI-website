<%-- 
    Document   : comp-pers-search-test
    Created on : Sep 25, 2014, 1:38:46 PM
    Author     : Paul-Inge Flakstad, Norwegian Polar Institute
--%>
<%@page contentType="text/html" 
        pageEncoding="UTF-8" 
        import="java.io.StringReader, 
        java.net.*,
        org.dom4j.Document,
        org.dom4j.Node,
        org.dom4j.io.SAXReader,
        java.util.ArrayList,
        java.util.List,
        java.util.Iterator,
        org.apache.commons.httpclient.*,
        org.apache.commons.httpclient.cookie.CookiePolicy,
        org.apache.commons.httpclient.cookie.CookieSpec,
        org.apache.commons.httpclient.methods.*"
%><%@include file="compendia-personal-credentials.jsp" 
%><%!
public static String getCompendiaPersonalSerp(String usr, String pwd, String query) throws Exception {
    String xmlStr = null; 
    String s = "";
    
    String LOGON_SITE = "www.compendiapersonal.no";
    int    LOGON_PORT = 80;
    
    HttpClient httpclient = new HttpClient();
    httpclient.getParams().setCookiePolicy(CookiePolicy.BROWSER_COMPATIBILITY);
    httpclient.getHostConfiguration().setHost(LOGON_SITE, LOGON_PORT, "http");
    
    GetMethod authget = new GetMethod("/names.nsf");
	
    httpclient.executeMethod(authget);
    System.out.println("Login form get: " + authget.getStatusLine().toString()); 
    // release any connection resources used by the method
    authget.releaseConnection();
    // See if we got any cookies
    CookieSpec cookiespec = CookiePolicy.getDefaultSpec();
    org.apache.commons.httpclient.Cookie[] initcookies = cookiespec.match(
        LOGON_SITE, LOGON_PORT, "/", false, httpclient.getState().getCookies());
    /*
    System.out.println("Initial set of cookies:");    
    if (initcookies.length == 0) {
        System.out.println("None");    
    } else {
        for (int i = 0; i < initcookies.length; i++) {
            System.out.println("- " + initcookies[i].toString());    
        }
    }
    //*/
    PostMethod authpost = new PostMethod("/names.nsf?Login");
    // Prepare login parameters
    NameValuePair[] loginParams = new NameValuePair[] {
        new NameValuePair("%%ModDate", "0000000000000000"),
        new NameValuePair("Username", usr),
        new NameValuePair("Password", pwd),
        new NameValuePair("RedirectTo", "/kunder/npolar/sokemoto.nsf/sokemotorxml?OpenAgent&search=" + query),
        new NameValuePair("reason_type", "0")
                   };
    //NameValuePair url      = new NameValuePair("url", "/index.html");
    //NameValuePair userid   = new NameValuePair("UserId", "userid");
    //NameValuePair password = new NameValuePair("Password", "password");
    //authpost.setRequestBody( 
    //  new NameValuePair[] {action, url, userid, password});
    
    authpost.setRequestBody(loginParams);

    httpclient.executeMethod(authpost);
    String authPostResponseString = "[" + authpost.getStatusCode() + "]\n" + authpost.getResponseBodyAsString();
    //System.out.println("Login form post: " + authpost.getStatusLine().toString()); 
    // release any connection resources used by the method
    authpost.releaseConnection();
    
    //return authPostResponseString;
    
    
    //*
    GetMethod xmlGet = new GetMethod("/kunder/npolar/sokemoto.nsf/sokemotorxml?OpenAgent&search=" + query);
	
    httpclient.executeMethod(xmlGet);
    
    xmlStr = xmlGet.getResponseBodyAsString();
    
    xmlGet.releaseConnection();
    
    
    //return xmlStr;
    //*/
    /*
    BasicCookieStore cookieStore = new BasicCookieStore();

    CloseableHttpClient httpclient = HttpClients.custom()
            .setDefaultCookieStore(cookieStore)
            .build();

    try {
        HttpGet httpget = new HttpGet("http://www.compendiapersonal.no/names.nsf");

        //HttpResponse response = httpclient.execute(httpget);
        CloseableHttpResponse response = httpclient.execute((HttpUriRequest)httpget);
        
        HttpEntity entity = response.getEntity();
        
        if (entity != null) {
            //EntityUtils.consume(entity);
            entity.consume();
        }
        
        HttpPost httpost = new HttpPost("http://www.compendiapersonal.no/names.nsf?Login"); //("http://www.facebook.com/login.php");
        
        

        List <NameValuePair> nvps = new ArrayList<BasicNameValuePair>();
        nvps.add(new BasicNameValuePair("%%ModDate", "0000000000000000"));
        nvps.add(new BasicNameValuePair("Username", usr));
        nvps.add(new BasicNameValuePair("Password", pwd));
        nvps.add(new BasicNameValuePair("RedirectTo", "/kunder/npolar/sokemoto.nsf/sokemotorxml?OpenAgent&search=" + query));
        nvps.add(new BasicNameValuePair("reason_type", "0"));

        httpost.setEntity(new UrlEncodedFormEntity(nvps, "UTF-8"));

        response = httpclient.execute(httpost);
        entity = response.getEntity();
        if (entity != null) {
            EntityUtils.consume(entity);
        }

        //System.out.println("\n\n################# Logged in, getting search results ######################\n\n");
        httpget = new HttpGet("http://www.compendiapersonal.no/kunder/npolar/sokemoto.nsf/sokemotorxml?OpenAgent&search=" + query);

        response = httpclient.execute(httpget);
        entity = response.getEntity();

        //System.out.println("GET returned [" + response.getStatusLine() + "], content:\n" + EntityUtils.toString(entity));

        xmlStr = EntityUtils.toString(entity);

        if (entity != null) {
            EntityUtils.consume(entity);
            //entity.consumeContent();
        }
        System.out.println("Get cookies (after login):");
        cookies = cookieStore.getCookies();
        if (cookies.isEmpty()) {
            System.out.println("None");
        } else {
            for (int i = 0; i < cookies.size(); i++) {
                System.out.println("- " + cookies.get(i).toString());
            }
        }
    } catch (Exception e) {
        e.printStackTrace();
    } finally {
        httpclient.close();
    }
    //*/
    
    //*
    try {
        
        //final URL xmlUrl = new URL("http://www.compendiapersonal.no/names.nsf?login&username="+usr+"&password="+pwd+"&redirectto=/kunder/npolar/sokemoto.nsf/sokemotorxml%3FOpenAgent%26search=ferie");
        //SAXReader reader = new SAXReader();
        //Document doc = reader.read(xmlUrl);
        
        SAXReader reader = new SAXReader();
        StringReader sr = new StringReader(xmlStr);
        Document doc = reader.read(sr);

        List items = doc.selectNodes("//compendiasok/database/document");///title");

        if (!items.isEmpty()) {           
            s += "<ul id=\"comp-pers-serp\">";
            Iterator i = items.iterator();
            while (i.hasNext()) {
                Node itemNode   = (Node)i.next();

                Node srcNode    = null;
                Node titleNode  = null;
                Node descrNode  = null;

                try { srcNode    = itemNode.selectSingleNode("unid"); } catch (Exception e) {}
                try { titleNode  = itemNode.selectSingleNode("name"); } catch (Exception e) {}
                try { descrNode  = itemNode.selectSingleNode("category"); } catch (Exception e) {}

                s += "<li>";
                s += "<a href=\"http://www.compendiapersonal.no/kunder/npolar/ph.nsf/unique/" + srcNode.getText() + "\">" + titleNode.getText() + "</a>";
                s += "<br />" + descrNode.getText();
                s += "</li>";
            }
            s += "</ul>";

        }
    } catch (Exception e) {
        //e.printStackTrace();
        return e.getMessage();
    }

    return s;
    //*/
}
	
public class CustomAuthenticator extends Authenticator {

    // Called when password authorization is needed
    protected PasswordAuthentication getPasswordAuthentication() {
        // Get information about the request
        String prompt = getRequestingPrompt();
        String hostname = getRequestingHost();
        InetAddress ipaddr = getRequestingSite();
        int port = getRequestingPort();
        
        String username = "myuser";
        String password = "mypass";

        // Return the information (a data holder that is used by Authenticator)
        return new PasswordAuthentication(username, password.toCharArray());
    }

}


%>
<%
/*
try {
			
    // Sets the authenticator that will be used by the networking code
    // when a proxy or an HTTP server asks for authentication.
    Authenticator.setDefault(new CustomAuthenticator());

    //URL url = new URL("http://www.secure-site-example.com:80/");
    URL url = new URL("http://www.compendiapersonal.no/names.nsf?login&username=myuser&password=mypass&redirectto=/kunder/npolar/ph.nsf/search?readform&q=reise");
			
    // read text returned by server
    BufferedReader in = new BufferedReader(new InputStreamReader(url.openStream()));

    String line;
    while ((line = in.readLine()) != null) {
        out.println(line);
    }
    in.close();
		    
}
catch (MalformedURLException e) {
    out.println("Malformed URL: " + e.getMessage());
}
catch (IOException e) {
    out.println("I/O Error: " + e.getMessage());
}
//*/

%>
<!DOCTYPE html>
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <title>Test søk i Compendia Personal</title>
    </head>
    <body>
        <h1>Treff i Compendia Personal</h1>
        <div><%
            // Username / passwords must be set as request attributes in the included file xxx-credentials.jsp
            String usr = (String)pageContext.getAttribute("cp_username");
            String pwd = (String)pageContext.getAttribute("cp_password");
            out.println(getCompendiaPersonalSerp(usr, pwd, "ferie"));
        %></div>
    </body>
</html>
