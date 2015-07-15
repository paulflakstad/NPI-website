<%-- 
    Document   : script-print-jdk-version
    Created on : Dec 22, 2011, 6:55:19 PM
    Author     : flakstad
--%>

<%@page contentType="text/html" pageEncoding="UTF-8" import="org.opencms.main.*"%>
<!DOCTYPE html>
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <title>JSP Page</title>
    </head>
    <body>
        <h1>JDK version</h1>
        <p>java.class.path: <% out.println(System.getProperty("java.class.path"));%></p>
        <p>java.vm.version: <% out.println(System.getProperty("java.vm.version"));%></p>
        <p>java.version: <% out.println(System.getProperty("java.version"));%></p>
        <h1>OpenCms version</h1>
        <p><% out.print(OpenCms.getSystemInfo().getVersionNumber()); %></p>
    </body>
</html>
