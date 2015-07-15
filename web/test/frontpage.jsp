<%-- 
    Document   : frontpage
    Created on : 15.mar.2011, 12:11:40
    Author     : Paul-Inge Flakstad <flakstad at npolar.no>
--%><%@page import="org.opencms.jsp.*,
                org.opencms.file.*,
                org.opencms.file.types.*,
                org.opencms.main.*,
                java.util.*,
                java.io.IOException,
                no.npolar.util.*" 
        contentType="text/html" 
        pageEncoding="UTF-8" 
%><%
CmsAgent cms                            = new CmsAgent(pageContext, request, response);
CmsObject cmso                          = cms.getCmsObject();
Locale locale                           = cms.getRequestContext().getLocale();
String requestFileUri                   = cms.getRequestContext().getUri();
String requestFolderUri                 = cms.getRequestContext().getFolderUri();

cms.include(cms.property("template", "search"), "header");
%>


<div class="fourcol-equal quadruple">
<div class="fourcol-equal double left">
    
    <h1>Norsk Polarinstitutt</h1>
    
    <div class="ingress">
        Norsk Polarinstitutt driver naturvitenskapelig forskning, kartlegging og miljøovervåkning, 
        og er faglig og strategisk rådgiver for staten i polarspørsmål. 
        I norsk del av Antarktis har instituttet forvaltningsmyndighet. 
        Det betyr at alle som planlegger aktivitet her skal kontakte Norsk Polarinstitutt på forhånd.
    </div><!-- .ingress -->
    

    <div id="featured" class="portal-box">

        <div style="" id="slidemenu">
            <ul class="slide-nav">
                <li class="slide-tab-nav" rel="1"><a href="javascript:void(0);">1</a></li>
                <li class="slide-tab-nav" rel="2"><a href="javascript:void(0);">2</a></li>
                <li class="slide-tab-nav" rel="3"><a href="javascript:void(0);">3</a></li>
                <li class="slide-tab-nav" rel="4"><a href="javascript:void(0);">4</a></li>
            </ul>
        </div>

        <div class="slidecontainer slider" id="slider">
            <ul class="sliding-content"> 
                <li>
                    <div class="content">
                        <a href="#1"><img alt="" src="/images/portal-pages/research/biologisk_mangfold.jpg" /></a>
                        <div class="info">
                        <p>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nulla tincidunt condimentum lacus. Pellentesque ut diam....</p>
                        </div>
                    </div>
                </li>
                <li>
                    <div class="content">
                        <a href="#2"><img alt="" src="/images/portal-pages/research/geologi.jpg" /></a>
                        <div class="info">
                            <p>Vestibulum leo quam, accumsan nec porttitor a, euismod ac tortor. Sed ipsum lorem, sagittis non egestas id, accumsan nec porttitor a, euismod ac tortor.....</p>
                        </div>
                    </div>
                </li>
                <li>
                    <div class="content">
                        <a href="#3"><img alt="" src="/images/portal-pages/research/miljogifter.jpg" /></a>
                        <div class="info">
                            <p>liquam erat volutpat. Proin id volutpat nisi. Nulla facilisi. Curabitur facilisis sollicitudin ornare....</p>
                        </div>
                    </div>
                </li>
                <li>
                    <div class="content">
                        <a href="#4"><img alt="" src="/images/portal-pages/research/havis.jpg" /></a>
                        <div class="info">
                            <p>Quisque sed orci ut lacus viverra interdum ornare sed est. Donec porta, erat eu pretium luctus, leo augue sodales....</p>
                        </div>
                    </div>
                </li>
            </ul>
        </div><!-- #slider.slidecontainer.slider -->

    </div><!-- #featured.portal-box -->



    <div class="portal-box">
        <h2 class="big-heading">Forskningstema</h2>
        <span style="width: 225px;" class="illustration right">
            <img width="217" height="146" alt="" src="/images/arktis/NP022170.jpg" class="illustration-image" />
            <span class="imagetext highslide-caption">En ev. bildetekst kommer i dette tekstfeltet.
                <span class="imagecredit"> Foto: Norsk Polarinstitutt</span>
            </span>                     
        </span>
        <p>Forsking og overvåking i polarområdene er viktige ledd for å forstå globale endringer i miljøet og effektene av disse.</p>
        <ul>
            <li><a href="#">Klima</a></li>
            <li><a href="#">Biologisk mangfold</a></li>
            <li><a href="#">Miljøgifter</a></li>
            <li><a href="#">Havis</a></li>
            <li><a href="#">Vis flere</a></li>
        </ul>
    </div><!-- .portal-box -->

</div><!-- .fourcol-equal.double.left -->


<div class="fourcol-equal double right">
    <div class="portal-box">
        <div class="fourcol-equal single left">
            <% cms.includeAny("/no/portal-news-list.jsp", null); %>
            <!--
            <h3>ICE &ndash; Norsk Polarinstitutts senter for is, klima og økosystemer</h3>
            <a href="http://ice.npolar.no/"><img width="225" alt="ICE" src="/images/logos/ice-225.png" /></a>
            -->
        </div>
        <div class="fourcol-equal single right">
            <div id="events-month-list">
                <% cms.includeAny("/no/portal-event-calendar.html", "resourceUri"); %>
            </div><!-- #events-month-list -->
        </div><!-- .fourcol-equal single right -->
    </div><!-- portal-box -->
    
    <div class="portal-box">
    	<div class="fourcol-equal single left">
    		<h3>ICE &ndash; Norsk Polarinstitutts senter for is, klima og økosystemer</h3>
        	<a href="http://ice.npolar.no/"><img width="225" alt="ICE" src="/images/logos/ice-225.png" /></a>
        </div>
        <div class="fourcol-equal single right">
            <h3>Reise til Antarktis?</h3>
            <p>
                For deg som planlegger reise til Antarktis – <a href="#">oversikt over forskrifter, regler og meldeplikt.</a>
            </p>
        </div><!-- .fourcol-equal single right -->
    </div>
    
    <div class="portal-box">
        <div class="fourcol-equal single left">
            <span style="width: 225px;" class="illustration">                     	
                <img width="217" alt="Polare operasjoner" src="/images/portal-pages/antarctic/polare-operasjoner-antarktis-NP035533.jpg" class="illustration-image" />
            </span>
            <h3>Polare operasjoner</h3>
            <ul>
                <li><a href="#">Operasjoner i Arktis</a></li>
                <li><a href="#">Operasjoner i Antarktis</a></li>
                <li><a href="#">Stasjoner og fartøy</a></li>
                <li><a href="#">Kontaktpunkter</a></li>
            </ul>
        </div><!-- .fourcol-equal single left -->
        <div class="fourcol-equal single right">
            <span style="width: 225px;" class="illustration">
                <img width="217" alt="" src="/images/portal-pages/frontpage/klima.jpg" class="illustration-image" />
            </span>
            <h3>Klima</h3>
            <ul>
                <li><a href="/no/forskning/tema/klima.html">Forskning på klima</a></li>
                <li><a href="/no/arktis/miljo-og-klima/">Miljø og klima i Arktis</a></li>
                <li><a href="/no/antarktis/miljo-og-klima.html">Miljø og klima i Antarktis</a></li>
            </ul>
        </div><!-- .fourcol-equal single right -->
    </div>

    <div class="portal-box">
        <div class="fourcol-equal single left">
            <h3>Svalbardkartet</h3>
            <p>
                Svalbardkartet er eit interaktivt temaatlas over Svalbard.
            </p>
        </div><!-- .fourcol-equal single left -->
        <div class="fourcol-equal single right">
            <h3>Polarinstituttet i verden</h3>
            <% cms.includeAny("/no/portal-yr-content.jsp", null); %>
            <p class="yr-credit">
                <a target="_blank" href="http://www.yr.no/">Varsel fra yr.no</a>
            </p>
        </div><!-- .fourcol-equal single right -->

    </div>
</div><!-- .fourcol-equal double right -->
</div><!-- .fourcol-equal.quadruple -->

<%
cms.include(cms.property("template", "search"), "footer");
%>