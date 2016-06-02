<%@page import="org.opencms.jsp.CmsJspActionElement, java.util.Locale"
%><% 
CmsJspActionElement cms = new CmsJspActionElement(pageContext, request, response);
String requestFileUri   = cms.getRequestContext().getUri();
Locale locale = null;
String loc = null;

// Make sure that the 
try {
    locale = new Locale(request.getParameter("locale"));
} catch (NullPointerException npe) {
    locale = new Locale("en");
}

loc = locale.toString();
%>

/**
 * Common javascript funtions, used throughout the site.
 * Dependency: jQuery (must be loaded before this script)
 * Dependency: Highslide (must be loaded before this script)
 */
  
/**
 * Function for altering table rows by class insertion.
 */
function makeNiceTables() {
    // Get all tables on the page
    var tables = document.getElementsByTagName("table");

    //alert("Found " + tables.length + " tables on this page.");

    // Loop over all tables
    for (i = 0; i < tables.length; i++) {
        var table = tables[i]; // Current table

        //alert("Processing table #" + i + "...");

        // Require a specific class name
        if (table.className == "odd-even-table") {
            //alert("This table was of required class.");
            var tableRows = table.getElementsByTagName("tr");

            // Check if the first row contains no th's
            if (tableRows[0].getElementsByTagName("th").length == 0) { 
                    tableRows[0].className = "even";
            }

            //alert("Found " + tableRows.length + " table rows in this table.");
            for (j = 1; j < tableRows.length; j++) { // Start at index 1 (skip first row, which we've processed already)
                var tableRow = tableRows[j];
                if ((j+2) % 2 == 0) {
                    tableRow.className = "even";
                }
                else {
                    tableRow.className = "odd";
                }
            }
        } else {
            //alert("This table was not of required class.");
        }
    }
}

/**
 * Handle hash (fragment) change
 */
function highlightReference() {
    setTimeout(
        function() {
            if(document.location.hash) {
                var hash = document.location.hash.substring(1); // Get fragment (without the leading # character)
                try {
                    $(".highlightable").css("background-color", "transparent");
                    $("#" + hash + ".highlightable").css("background-color", "#feff9f");
                    //alert (hash);
                } catch (jsErr) {}
            }
            else {
                //alert("No hash");
            }
        },
        100
    );
}

/*
function highlightReference() {
    if(document.location.hash) {
        var hash = document.location.hash.substring(1); // Get fragment (without the leading # character)
        try {
            document.getElementsByClassName("highlightable")
            document.getElementById(hash).style.backgroundColor = "#eef6fc";
            //alert (hash);
        } catch (jsErr) {}
    }
}
*/
/*
if ("onhashchange" in window) { // event supported?
    window.onhashchange = function () {
        hashChanged(window.location.hash);
    }
}
else { // event not supported:
    var storedHash = window.location.hash;
    window.setInterval(function () {
        if (window.location.hash != storedHash) {
            storedHash = window.location.hash;
            hashChanged(storedHash);
        }
    }, 100);
}
*/

/**
 * Helper function for browser sniffing
 */
navigator.sayswho= (function(){
    var N= navigator.appName, ua= navigator.userAgent, tem;
    var M= ua.match(/(opera|chrome|safari|firefox|msie)\/?\s*(\.?\d+(\.\d+)*)/i);
    if(M && (tem= ua.match(/version\/([\.\d]+)/i))!= null) M[2]= tem[1];
    M= M? [M[1], M[2]]: [N, navigator.appVersion, '-?'];

    return M;
})();

/**
 * Calculates the width of the browser's scrollbar
 */
function getScrollbarWidth() {
    // Create a small div with a large div inside (will trigger scrollbar)
    var div = $("<div style=\"width:50px;height:50px;overflow:hidden;position:absolute;top:-200px;left:-200px;\"><div style=\"height:100px;\"></div></div>");
    // Append our div, do our calculation and then remove it
    $("body").append(div);
    var w1 = $("div", div).innerWidth();
    div.css("overflow-y", "scroll");
    var w2 = $("div", div).innerWidth();
    $(div).remove();
    return (w1 - w2);
}

/**
 * Returns true if the browser is IE8 (or an older IE version)
 */
function nonResIE() {
    if (navigator.sayswho[0].match('MSIE') && navigator.sayswho[1].substring(0,1) < '9') {
        return true;
    }
    return false;
}

/**
 * Checks if an element, identified by the given ID, contains any real content.
 * @param id The ID that identifies the element to check
 * @return True if the element is non-existing or the element doesn't contain any real content, false if not
 */
function emptyOrNonExistingElement(id) {
    var el = document.getElementById(id); // Get the element
    if (!(el == null || el == undefined)) { // Check for non-exising element first
        var html = el.innerHTML; // Get the content inside the element
        if (html != null) {
            html = html.replace(/(\r\n|\n|\r)/gm, ''); // Remove any and all linebreaks
            html = html.replace(/^\s+|\s+$/g, ''); // Remove empty spaces at front and end
            if (html == '')
                return true; // The element didn't contain anything (except maybe whitespace and linebreaks)
            return false; // The element contained something
        }
    }
    return true; // The element didn't exist
}

function getVisibleWidth() {
    return $(window).width() + getScrollbarWidth();
}

function getSmallScreenBreakpoint() {
    return 800; // Viewport widths equal to or below this value are considered "small screens"
}

function isSmallScreen() {
    return getVisibleWidth() <= getSmallScreenBreakpoint();
}

function initToggleable(/*jQuery*/ el) {
    var trigger = el.find('.toggletrigger').first();
    var target = el.find('.toggletarget').first();
    if (el.hasClass('collapsed')) {
        target.slideUp(1); // Hide normally-closed ("collapsed") accordion content		
        //trigger.append(' <em class="icon-down-open-big"></em>'); // Append arrow icon to "show accordion content" triggers
    } else if (el.hasClass('open')) {
        //trigger.append(' <em class="icon-up-open-big"></em>'); // Append arrow icon to "hide accordion content" triggers
    }
    var triggerIconClass = 'icon-' + (el.hasClass('collapsed') ? 'down' : 'up') + '-open-big';
    if (!trigger.hasClass('inactive')) {
        // Append up/down arrow icon to indicate "show/hide accordion content"
        trigger.append(' <em class="' + triggerIconClass + '"></em>');
        // Add click handler
        trigger.click( function() {
            $(this).next('.toggletarget').slideToggle(500); // Slide up/down the next toggle target ...
            //$(this).children().first().toggleClass('icon-up-open-big').toggleClass('icon-down-open-big');
            $(this).children().first().toggleClass('icon-up-open-big icon-down-open-big'); // ... and toggle the icon class, so the arrows change corresponding to the slide up/down
        });
    }
}

function initToggleables() {
    $('.toggleable.collapsed > .toggletarget').slideUp(1); // Hide normally-closed ("collapsed") accordion content		
    $('.toggleable.collapsed > .toggletrigger').append(' <em class="icon-down-open-big"></em>'); // Append arrow icon to "show accordion content" triggers
    $('.toggleable.open > .toggletrigger').append(' <em class="icon-up-open-big"></em>'); // Append arrow icon to "hide accordion content" triggers
    $('.toggleable > .toggletrigger').click( // Click handler
        function() {
            $(this).next('.toggletarget').slideToggle(500); // Slide up/down the next toggle target ...
            //$(this).children().first().toggleClass('icon-up-open-big').toggleClass('icon-down-open-big');
            $(this).children().first().toggleClass('icon-up-open-big icon-down-open-big'); // ... and toggle the icon class, so the arrows change corresponding to the slide up/down
        });
}

function showOutlines() {
    try { document.getElementById("_outlines").innerHTML="a:focus, input:focus, button:focus, select:focus { outline:thin dotted; outline:2px solid orange; }"; } catch (err) {}
}
function hideOutlines() {
    try { document.getElementById("_outlines").innerHTML="a, a:focus, input:focus, select:focus { outline:none !important; } /*a:focus { border:none !important; }*/"; } catch (err) {}
}

/**
 * @see http://support.addthis.com/customer/portal/articles/1293805-using-addthis-asynchronously#.UxSMJuIkAU8
 */
function loadAddThis() {
    /*var addthisScript = document.createElement('script');
    addthisScript.setAttribute('src', 'http://s7.addthis.com/js/300/addthis_widget.js#domready=1');
    addthisScript.setAttribute('type', 'text/javascript');
    document.body.appendChild(addthisScript);*/
    try {
        // Add the profile ID (pubid)
        var addthis_config = addthis_config||{};
        addthis_config.pubid = 'ra-52b2d01077c3a190';
        addthis.init();
    } catch (err) {}
}

function initCarousel(/*int*/slideWidth, /*int*/slideHeight) {
	$("#slides").carouFredSel({
            width: "" + slideWidth + "%",
            height: "" + slideHeight + "%",
            //height: "59%",
            direction: "left",
            circular: true,
            responsive: true,
            auto: 8000,
            items: {
                visible: 1,
                width: "90",
                height: "variable"
            },
            scroll: {
                fx: "crossfade",
                duration: 750,
                pauseOnHover: true
            },
            prev: {
                button: "#featured-prev",
                key: "left"
            },
            next: {
                button: "#featured-next",
                key: "right"
            },
            pagination: "#featured .pagination"
	});
	// Bind a click event to the navigation controls to stop the carousel if a 
	// user does something manually
	$("#featured .pagination, #featured-prev, #featured-next").click(function() {
            $("#slides").trigger("configuration", { auto: false });
	});
}

/**
 * Things to do when the document is ready
 */
$(document).ready( function() {
	// Add style definition for links: No outlines for mouse navigation, dotted outlines for keyboard navigation
	$('head').append('<style id="_outlines" />');
	$('body').attr('onmousedown', 'hideOutlines()');
	//$('body').attr('onkeydown', 'showOutlines()');
	//$('body').bind('keypress', function(e) {
	$('body').bind('keydown', function(e) {
            if (e.keyCode == 9) {
                showOutlines();
            }
	});
	
	var fmsg = false;
	
	// Hide small screen navigation if necessary & show big screen navigation if necessary
    if (!nonResIE()) { // IE versions that cannot chew media queries will get a non-responsive version, so those should always have the big screen navigation available
        var ssNavBreakpoint = getSmallScreenBreakpoint(); // Viewport widths equal to or below this value will use small screen navigation
        var slideDuration = 200; // Animation time (milliseconds): Toggle small screen navigation
        var scrollWidth = getScrollbarWidth();
        var visibleWidth = getVisibleWidth();//$(window).width() + scrollWidth;

        if (visibleWidth <= ssNavBreakpoint) {// && ("#nav_sticky").css("display") == "block") {
            $("#nav_sticky").hide();
        }

        $("#nav_toggle").click(function() {
            $("#nav_sticky").slideToggle(slideDuration);
        });
		
        $(window).resize(function() {
            visibleWidth = getVisibleWidth();//$(window).width() + scrollWidth; // NB refresh value on resize
            var searchBoxFocus = $("#query").is(":focus");
            //if (visibleWidth > ssNavBreakpoint && $("#nav_sticky").css("display") != "block") { // original
            //if (visibleWidth > getSmallScreenBreakpoint() && $("#nav_sticky").css("display") != "block") {
            if (!isSmallScreen() && $("#nav_sticky").css("display") != "block") {
                $("#nav_sticky").show();
            }
            //else if (visibleWidth <= ssNavBreakpoint && $("#nav_sticky").css("display") == "block") { // original
            //else if (visibleWidth <= getSmallScreenBreakpoint() && $("#nav_sticky").css("display") == "block") {
            else if (isSmallScreen() && $("#nav_sticky").css("display") == "block" && !searchBoxFocus) {
                $("#nav_sticky").hide();
            }
        });
		
        /*
        $("#query").focusin(function() {
            if (isSmallScreen()) {
                $("#nav_sticky").show();
                if (!fmsg) {
                    //alert("showing nav");
                    fmsg = true;
                }
            }
        });
        $("#query").focusout(function() {
            if (isSmallScreen()) {
                $("#nav_sticky").show();
                if (!fmsg) {
                    //alert("showing nav");
                    fmsg = true;
                }
            }
        });
        */
    }
    
    /*
    // "Hide" the left column when it doesn't contain anything
    if (document.getElementById("leftside")) {
        if ($("#leftside").html()) {
            if ($.trim($("#leftside").html()) == '') {
                //if (!$("#leftside").html().trim()) {
                    $("#leftside").css("width", "0");
                    $("#content").css("width", "100%");
                //}
            }
        }
    }*/
    var isHomePage = $("body").attr("id") === "homepage" || $("body").hasClass("homepage");
    
    if (!isHomePage) {
        $("#nav_toggler").click(function () {
            //var contentWidth = $("#content").css("width"); // Store the CSS-defined width, complete with unit, e.g. "75%"
            //alert(contentWidth);

            if ($("#leftside").css("display") == "none") { // Show navigation
                $("#nav_top_wrap").slideToggle(300);
                //$("#nav_top_wrap").slideToggle(300, function() { $("#sm-links-top").fadeIn(); });
                $("#leftside").css({"display" : "block"});
                if (!emptyOrNonExistingElement("leftside")) {
                    $("#leftside").animate({
                            marginLeft: "0"
                        }, 250, function(){});
                    $("#content").animate({
                            width: "78%"
                            //width: contentWidth
                        }, 250, function(){ });
                }
                $(this).addClass("pinned"); // Toggle the class
                $.post("/settings", { pinned_nav: "true" }); // Store the navbar visibility state in the user session
            } 

            else { // Hide navigation
                $("#nav_top_wrap").slideToggle(300);
                //$("#sm-links-top").fadeOut(50, function() { $("#nav_top_wrap").slideToggle(300); });
                $("#leftside").css({"display" : "none"});
                if (!emptyOrNonExistingElement("leftside")) {
                    $("#leftside").animate({
                            marginLeft: "-500px"
                        }, 250, function(){});
                    $("#content").animate({
                            width: "100%"
                        }, 250, function(){  });
                }
                $(this).removeClass("pinned"); // Toggle the class
                $.post("/settings", { pinned_nav: "false" }); // Store the navbar visibility state in the user session
            }
        });
    } else {
        // Always show top-level menu on home page (and hence no toggler needed)
        $("#nav_top_wrap").attr("style", "display:block;")
        $("#nav_toggler_wrapper").hide();
    }
	
	// Make menu togglers keyboard accessible
	$(document).keyup(function(e){
            if (e.keyCode == 13 && $(document.activeElement).attr("id") == "nav_toggler") {
                $("#nav_toggler").click();
            } else if (e.keyCode == 13 && $(document.activeElement).attr("id") == "nav_toggle") {
                $("#nav_toggle").click();
            }
	});
	
	// Expand the main content to the left when the left column is empty or missing
	if (emptyOrNonExistingElement('leftside')) {
        //alert("Empty or non-existing #leftside, hiding it.");
        $("#leftside").css("width", "0");
        $("#leftside").css("height", "0");
        $("#content").css("width", "100%");
    }
	// Expand the main content to the right when the right column is empty or missing
    if (emptyOrNonExistingElement('rightside')) {
        //alert("Empty or non-existing #rightside, hiding it.");
        $(".main-content").css("width", "100%");
        $("#rightside").css("width", "0");
        $("#rightside").css("height", "0");
    }
	// Expand the main content area vertically, so the footer will be normal-sized even on very short pages
	//if (!($("body").height() > $(window).height()) && !isSmallScreen()) { // if not vertical scrollbar
	if (!($(document).height() > $(window).height()) && !isSmallScreen()) { // if not vertical scrollbar & not smallscreen
            //var extraHeight = 64;
            //var extraHeight = 50;
            var extraHeight = 45;
            var mainContentHeight = $(window).height() - $("#header").height() - $("#footer").height() - extraHeight; // [viewport height] - [header height] - [footer height] - [value found by trial-and-error]
            //$("#docwrap").animate({height: mainContentHeight+"px"}, 600);
            //$("#docwrap").height(mainContentHeight);
            $("#docwrap").css("min-height", mainContentHeight+"px");
	}
	
	if (emptyOrNonExistingElement('portalpage-first')) {
            $("#portalpage-first").hide();
	}
	
	// qTip tooltips
	$('[data-tooltip]').each(function() { 
            $(this).qtip({ 
                content: $(this).attr('data-tooltip'), 
                style: {
                    classes:'qtip-tipsy qtip-shadow'
                },
                position: {
                    my:'bottom center',
                    at:'top center',
                    viewport: $(window)
                }
            }); 
	});
	$('[data-hoverbox]').each(function() {
            var showDelay = $(this).hasClass('featured-link') ? 1000 : 250; // Long delay on "card links" in portal pages, short delay on the rest
            $(this).qtip({
                content: $(this).attr('data-hoverbox'), 
                title: $(this).attr('data-hoverbox-title'),
                style: {
                    classes:'qtip-light qtip-shadow'
                },
                position: {
                    my: 'bottom center',
                    at: 'top center',
                    viewport: $(window)
                },
                show: {
                    event: 'focus mouseenter',
                    delay: showDelay,
                    effect: function() {
                        $(this).fadeTo(400, 1);
                    }
                },
                hide: {
                    event: 'blur mouseleave',
                    fixed: true,
                    delay: 400,
                    effect: function() {
                        $(this).fadeTo(400, 0);
                    }
                }
            });
	});
	// Animated verical scrolling to on-page locations
	//$('a[href*=#]:not([href=#])').click(function() { // Apply to all on-page links
	$('.reflink,.scrollto').click(function() {
            if (location.pathname.replace(/^\//,'') == this.pathname.replace(/^\//,'') || location.hostname == this.hostname) {
                var hashStr = this.hash.slice(1);
                var target = $(this.hash);
                target = target.length ? target : $('[name=' + hashStr +']');

                if (target.length) {
                    $('html,body').animate({ scrollTop: target.offset().top - 20}, 500);
                    window.location.hash = hashStr;
                    return false;
                }
            }
	});
	
	// Add facebook-necessary attribute to the html element
	$("html").attr('xmlns:fb', 'http://ogp.me/ns/fb#"');
	
	// Format tables
	makeNiceTables();
	
	// Make service list (large icon row) full width
	try {
            $("#service-list").parent(".box-text").css( {"padding" : 0} );
	} catch (err) {}
	
	// Fragment-based highlighting
	//$(".reflink").click(function() { highlightReference(); }); // On click 
	$("a").click(function() { highlightReference(); }); // On click (it's not sufficient to track only .reflink clicks - that will cause any previous highlighting to stick "forever")
	highlightReference(); // On page load
	
	// "Read more"-links
	$(".cta.more").append('<i class="icon-right-open-big"></i>');
	
	// Initialize toggleable content
        initToggleables();
        
        // BEGIN search filters
        var filtersToggler = $("#filters-toggler");
        var filters = $("#filters");
        var filterHeadings = $("#filters h3");
        
        filters.hide();
        filterHeadings.addClass("filters-heading");
        
        if (filterHeadings.length > 0) {
            filtersToggler.append("<div class=\"filter-hints\"></div>");
            
            filterHeadings.each(function(i) {
                var filterHeading = $(this).clone();
                filterHeading.find(".filter__num-matches").remove();
                
                var filterHints = (i > 0 ? ( ", " + (i === 2 ? "..." : filterHeading.text().toLowerCase()) ) : filterHeading.text() );
                
                $("#filters-toggler .filter-hints").append(filterHints);
                
                if (i === 2) {
                    return false;
                }
            });
        }
        
        
        filtersToggler.addClass("cta cta--filters-toggle").removeAttr("onclick");
        filtersToggler.click(function(e) {
            e.preventDefault();
            filters.slideToggle();
        }); 
        $("#filters li a .remove-filter").closest("a").addClass("filter--active");
        
        // Create a separate overview of the active filters
        var activeFilters = filters.find(".filter--active");
        if (activeFilters.length > 0) {
        
            if ( $("#filters-details").length === 0 ) {
                filters.closest(".searchbox-big").next("h2").after("<div id=\"filters-details\"></div>");
            }
            $("#filters-details").append("<ul class=\"filters--active blocklist\">");
            activeFilters.each(function() {
                $(this).closest("li").prependTo( $(this).closest("ul") );
                $(".filters--active").append( $("<li>").append( $(this).clone() ) );
            });
        }
        // END search filters
        
        $(".searchbox-big form").find("input[type=submit]").addClass("cta cta--search-submit");
	
	// Social sharers
	$("#share_button_top").attr('displayText','<%= loc.equalsIgnoreCase("no") ? "Del denne siden" : "Share this" %>');
        $("#share_button_facebook").attr('displayText','Facebook');
        $("#share_button_twitter").attr('displayText','Twitter');
        $("#share_button_gplus").attr('displayText','Google+');
        $("#share_button_email").attr('displayText','<%= loc.equalsIgnoreCase("no") ? "E-post" : "E-mail" %>');
        $("#share_button_bottom").attr('displayText','<%= loc.equalsIgnoreCase("no") ? "Mer" : "More" %> ...');
	
	// Overlay logos (if necessary)
	$('<span class="overlay-logo"><img src="/images/logos/logo-fram-f-20.png" /></span>').insertAfter('.featured-box.logo-fram img');
	$('<span class="overlay-logo"><img src="/images/logos/logo-ice-20.png" /></span>').insertAfter('.featured-box.logo-ice img');
	
	
	try {
            if (!emptyOrNonExistingElement("slides")) {
                var slideHeight = 59;
                var minSlideHeight = 45; // Fallback
                try {
                    var firstSlide = document.getElementById('slides').getElementsByTagName('img').item(0);
                    console.log('Got first slide image, h:' + firstSlide.naturalHeight + ', w:' + firstSlide.naturalWidth);
                    slideHeight = parseFloat((firstSlide.naturalHeight / firstSlide.naturalWidth) * 100).toFixed(3);
                    if (slideHeight < minSlideHeight)
                        slideHeight = minSlideHeight; // Assume an error ? set minimum height.
                    console.log('Slide height set to ' + slideHeight + '%');
                } catch (err) {
                    console.log(err);
                }
                // Carousel setup
                initCarousel(100, slideHeight);
                // Delay the carousel setup slightly (possible fix for height calculation issue?)
                //setTimeout(function() { initCarousel(100, slideHeight); }, 100);
            }
	} catch (err) {}
	
	try {
            // Make image maps responsive
            $('img[usemap]').rwdImageMaps(); // Scale image maps (note: this should be the LAST call in $(document).ready(...))
	} catch (err) {}
		
	
	// AddThis
	loadAddThis();
});

$(document).ajaxComplete(function() {
    // Initialize toggleable content
    //initToggleables();
});


/**
 * Highslide settings
 */
//hs.align = 'center';
//hs.marginBottom = 10;
//hs.marginTop = 10;
hs.marginBottom = 50; // Make room for the "Share" widget
hs.marginTop = 50; // Make room for the thumbstrip
hs.marginLeft = 50;
hs.marginRight = 50; 
//hs.maxHeight = 600;
//hs.outlineType = 'rounded-white';
hs.outlineType = 'drop-shadow';
<% if (loc.equalsIgnoreCase("no")) { %>
hs.lang = {
    loadingText :     'Laster...',
    loadingTitle :    'Klikk for å avbryte',
    focusTitle :      'Klikk for å flytte fram',
    fullExpandText :  'Full størrelse',
    fullExpandTitle : 'Utvid til full størrelse',
    creditsText :     'Drevet av <i>Highslide JS</i>',
    creditsTitle :    'Gå til hjemmesiden til Highslide JS',
    previousText :    'Forrige',
    previousTitle :   'Forrige (pil venstre)',
    nextText :        'Neste',
    nextTitle :       'Neste (pil høyre)',
    moveText :        'Flytt',
    moveTitle :       'Flytt',
    closeText :       'Lukk',
    closeTitle :      'Lukk (esc)',
    resizeTitle :     'Endre størrelse',
    playText :        'Spill av',
    playTitle :       'Vis bildeserie (mellomrom)',
    pauseText :       'Pause',
    pauseTitle :      'Pause (mellomrom)',
    number :          'Bilde %1 av %2',
    restoreTitle :    'Klikk for å lukke bildet, klikk og dra for å flytte. Bruk piltastene for forrige og neste.'
};
<% } else { %>
hs.lang = {
    cssDirection:     'ltr',
    loadingText :     'Loading...',
    loadingTitle :    'Click to cancel',
    focusTitle :      'Click to bring to front',
    fullExpandTitle : 'Expand to actual size (f)',
    fullExpandText :  'Full size',
    creditsText :     'Powered by <i>Highslide JS</i>',
    creditsTitle :    'Go to the Highslide JS homepage',
    previousText :    'Previous',
    previousTitle :   'Previous (arrow left)',
    nextText :        'Next',
    nextTitle :       'Next (arrow right)',
    moveTitle :       'Move',
    moveText :        'Move',
    closeText :       'Close',
    closeTitle :      'Close (esc)',
    resizeTitle :     'Resize',
    playText :        'Play',
    playTitle :       'Play slideshow (spacebar)',
    pauseText :       'Pause',
    pauseTitle :      'Pause slideshow (spacebar)',   
    number :          'Image %1 of %2',
    restoreTitle :    'Click to close image, click and drag to move. Use arrow keys for next and previous.'
};
<% } %>