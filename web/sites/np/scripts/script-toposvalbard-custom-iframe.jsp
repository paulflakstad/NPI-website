<%-- 
    Document   : script-toposvalbard-custom-iframe
    Created on : Feb 26, 2013, 4:22:21 PM
    Author     : flakstad
--%><%@ page import="org.opencms.jsp.*, 
                 org.opencms.file.CmsPropertyDefinition,
                 java.util.*, 
                 java.util.regex.*,
                 java.net.*,
                 java.io.*,
                 no.npolar.util.*" session="true" 
%><%
        CmsAgent cms = new CmsAgent(pageContext, request, response);
        Locale locale = cms.getRequestContext().getLocale();
        String loc = locale.toString();
        
        // The URL
//        final String MAP_URL = "http://toposvalbard.npolar.no/iframe.html";
        final String MAP_URL = "http://toposvalbard.npolar.no/iframe.html?lat=79.4560&long=13.2722&zoom=8";
        
        final String MAP_PARAMS = String.format("lat=%s&long=%s&zoom=%s", 
                                                URLEncoder.encode("79.4560", "UTF-8"),
                                                URLEncoder.encode("13.2722", "UTF-8"),
                                                URLEncoder.encode("5", "UTF-8"));
        
        URLConnection uc = null;
        StringBuffer contentBuffer = new StringBuffer(1024);
        
        try {
            //uc = new URL(MAP_URL + "?" + MAP_PARAMS).openConnection();
            uc = new URL(MAP_URL).openConnection();
            uc.setRequestProperty("Accept-Charset", "UTF-8");
            BufferedReader in = new BufferedReader(new InputStreamReader(uc.getInputStream()));
            String inputLine;
            while ((inputLine = in.readLine()) != null) {
                contentBuffer.append(inputLine + "\n");
            }
            in.close();
            String content = contentBuffer.toString();
            
            if (content.isEmpty()) {
                throw new NullPointerException();
            }
            
            String injectionTop = "\n<base href=\"http://toposvalbard.npolar.no/\" />"
                               + "\n<style type=\"text/css\">#dijit_layout_BorderContainer_0 { width:100% !important; height:500px !important; }</style>"
                               ;
            String injectionBottom = ""
                                    //+ "<script type=\"text/javascript\"> map.centerAndZoom(new esri.geometry.Point(IFupos.x,IFupos.y),IFurlzoom); </script>"
                                    ;
            
            //content = content.replace("map.centerAndZoom(new esri.geometry.Point(IFupos.x,IFupos.y),IFurlzoom);", "");
            content = content.replace("</title>", "</title>".concat(injectionTop));
            content = content.replace("</head>", injectionBottom.concat("\n</head>"));
            content = content.replace("var djConfig = {parseOnLoad: true};", "var djConfig = {parseOnLoad: true};");
            content = content.replace("width: 480px;", "width: 100% !important;");
            //content = content.replaceAll("src=\"", "src=\"");
            //content = content.replaceAll("width=\"480\"", "width=\"780\"");
            //out.println("<p class=\"smallertext\">This is the result</p>");
            out.println(content);
        } catch (Exception e) {
            out.println("<h4>Error:</h4>");
            e.printStackTrace(response.getWriter());
        }
        %>
        <!-- http://toposvalbard.npolar.no/iframe.html?lat=79.4561,long=13.2816,zoom=5 -->
