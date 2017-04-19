/**
 * Common javascript funtions, used throughout the site.
 * Dependencies (must/should be loaded before this script):
 *  - jQuery 
 *  - Modernizr (loose dependecy)
 *  
 * Highslide should also be loaded before this script.
 */

//var $, Modernizr, hs, stackBlurCanvasRGBA;

/** Global variable used to detect changes in the viewport width. */
var lastDetectedWidth = $(window).width();

/**
 * Global variable that holds localized Highslide strings / labels. 
 */
var HS_LABELS = {
    no : {
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
    },
    en : {
        loadingText :     'Loading...',
        loadingTitle :    'Click to cancel',
        focusTitle :      'Click to move forwrard',
        fullExpandText :  'Fullsize',
        fullExpandTitle : 'Expand to full size',
        creditsText :     'Powered by <i>Highslide JS</i>',
        creditsTitle :    'Go to the Highslide JS website',
        previousText :    'Previous',
        previousTitle :   'Previous (left arrow)',
        nextText :        'Next',
        nextTitle :       'Next (right arrow)',
        moveText :        'Move',
        moveTitle :       'Move',
        closeText :       'Close',
        closeTitle :      'Close (esc)',
        resizeTitle :     'Change size',
        playText :        'Play',
        playTitle :       'View slideshow (space)',
        pauseText :       'Pause',
        pauseTitle :      'Pause (space)',
        number :          'Image %1 of %2',
        restoreTitle :    'Click to close, click and drag to move. Use arrow keys for next / previous.'
    }
};

/**
 * Global variable that holds localized Highcharts strings / labels.
 */
var HC_LABELS = {
    no: {
        decimalPoint: ',',
        downloadJPEG: 'Last ned som JPG',
        downloadPNG: 'Last ned som PNG',
        downloadPDF: 'Last ned som PDF',
        downloadSVG: 'Last ned som SVG',
        drillUpText: 'Tilbake til {series.name}',
        loading: 'Laster...',
        printChart: 'Skriv ut figur',
        resetZoom: 'Nullstill zoom',
        resetZoomTitle: 'Sett zoomnivået til 1:1',
        thousandsSep: ' '
    },
    en: {
        decimalPoint: '.',
        downloadJPEG: 'Download as JPG',
        downloadPNG: 'Download as PNG',
        downloadPDF: 'Download as PDF',
        downloadSVG: 'Download as SVG',
        drillUpText: 'Back to {series.name}',
        loading: 'Loading...',
        printChart: 'Print chart',
        resetZoom: 'Reset zoom',
        resetZoomTitle: 'Reset zoom level to 1:1',
        thousandsSep: ','
    }
};

/*
 * jQuery hover delay plugin. 
 * http://ronency.github.io/hoverDelay/
 * https://github.com/ronency/hoverDelay
 * Function license: MIT.
 * 
 * The MIT License (MIT)
 * 
 * Copyright (c) 2014 ronency
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy of
 * this software and associated documentation files (the "Software"), to deal in
 * the Software without restriction, including without limitation the rights to
 * use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
 * the Software, and to permit persons to whom the Software is furnished to do so,
 * subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
 * FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
 * COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
 * IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */
$.fn.hoverDelay = function(options) {
    'use strict';
    var defaultOptions = {
        delayIn: 300,
        delayOut: 300,
        handlerIn: function($element){ $element.addClass('intentional-hover'); },
        handlerOut: function($element){ $element.removeClass('intentional-hover'); }
    };
    options = $.extend(defaultOptions, options);
    return this.each(function() {
        var timeoutIn, timeoutOut;
        var $element = $(this);
        $element.hover(
            function() {
                if (timeoutOut){
                    clearTimeout(timeoutOut);
                }
                timeoutIn = setTimeout(function(){options.handlerIn($element);}, options.delayIn);
            },
            function() {
                if (timeoutIn){
                    clearTimeout(timeoutIn);
                }
                timeoutOut = setTimeout(function(){options.handlerOut($element);}, options.delayOut);
            }
        );
    });
};

/**
 * Handle hash (fragment) change
 */
function highlightReference() {
    'use strict';
    setTimeout(
        function() {
            if(document.location.hash) {
                var hash = document.location.hash.substring(1); // Get fragment (without the leading # character)
                try {
                    $(".highlightable").css("background-color", "transparent");
                    $("#" + hash + ".highlightable").css("background-color", "#feff9f");
                    //alert (hash);
                } catch (ignore) {}
            }
            //else {
                //alert("No hash");
            //}
        },
        100
    );
}

/*
function highlightReference() {
    'use strict';
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
 * Example result: 'Firefox 31'
 * See http://stackoverflow.com/questions/5916900/how-can-you-detect-the-version-of-a-browser
 */
navigator.sayswho = (function() {
    'use strict';
    var N = navigator.appName, ua = navigator.userAgent, tem;
    var M = ua.match(/(opera|chrome|safari|firefox|msie)\/?\s*(\.?\d+(\.\d+)*)/i);
    tem = ua.match(/version\/([\.\d]+)/i);
    if (M && tem !== null) { M[2] = tem[1]; }
    M = M ? [M[1], M[2]] : [N, navigator.appVersion, '-?'];

    return M;
})();

/**
 * Calculates the width of the browser's scrollbar
 */
/*function getScrollbarWidth() {
    // Create a small div with a large div inside (will trigger scrollbar)
    var div = $("<div style=\"width:50px;height:50px;overflow:hidden;position:absolute;top:-200px;left:-200px;\"><div style=\"height:100px;\"></div></div>");
    // Append our div, do our calculation and then remove it
    $("body").append(div);
    var w1 = $("div", div).innerWidth();
    div.css("overflow-y", "scroll");
    var w2 = $("div", div).innerWidth();
    $(div).remove();
    return (w1 - w2);
}*/

/**
 * Returns true if the browser is IE8 (or an older IE version)
 */
function nonResIE() {
    'use strict';
    if (navigator.sayswho[0].match('MSIE')) { 
        var version = navigator.sayswho[1];
        version = version.substring(0, version.indexOf('.'));
        //console.log('MSIE version is: "' + version + '"');
        if (version.length > 1) {
            return false;
        } 
        if (version < '9') {
            return true;
        }
    }
	//console.log('User-agent was responsive: "' + navigator.sayswho[1] + '"');
    return false;
}

/**
 * Checks if an element, identified by the given ID, contains any real content.
 * @param id The ID that identifies the element to check
 * @return True if the element is non-existing or the element doesn't contain any real content, false if not
 */
function emptyOrNonExistingElement(id) {
    'use strict';
    var el = document.getElementById(id); // Get the element
    if (!(el === null || el === undefined)) { // Check for non-exising element first
        var html = el.innerHTML; // Get the content inside the element
        if (html !== null) {
            html = html.replace(/(\r\n|\n|\r)/gm, ''); // Remove any and all linebreaks
            html = html.replace(/^\s+|\s+$/g, ''); // Remove empty spaces at front and end
            if (html === '') {
                return true; // The element didn't contain anything (except maybe whitespace and linebreaks)
            }
            return false; // The element contained something
        }
    }
    return true; // The element didn't exist
}
/*
function getVisibleWidth() {
    return $(window).width() + getScrollbarWidth();
}
*/
/**
 * Gets the small-screen breakpoint. Viewport widths equal to or below the 
 * returned value are considered "small screens".
 * @returns {Number} The small-screen breakpoint
 */
function getSmallScreenBreakpoint() {
    'use strict';
    return 800;
}
/**
 * Evaluates whether or not the current viewport is a "small screen" or not.
 * @returns {Boolean} True if the viewport width is < getSmallScreenBreakpoint()
 */
function isSmallScreen() {
    'use strict';
    return !isBigScreen();
    //return getVisibleWidth() <= getSmallScreenBreakpoint();
}
/**
 * Evaluates whether or not the current viewport is a "big screen" or not. 
 * Browsers without media query support will always get true in return.
 * @returns {Boolean|MediaQueryList.matches} True if the viewport width is >= getSmallScreenBreakpoint(), false if not
 */
function isBigScreen() {
    'use strict';
    var big = true;
    try {
        big = window.matchMedia('(min-width: ' + getSmallScreenBreakpoint() + 'px)').matches; // Update value for browsers supporting matchMedia
    } catch (ignore) {
        // No browser support (= likely IE8 or older) - retain default
    }
    return big;
}

/**
 * Initializes "toggleables" - that is, accordion content - on the page.
 * 
 * @returns {undefined}  Nothing.
 */
function initToggleables() {
    'use strict';
        
    // Newer toggler:
    //  container[.expanded]
    //      |- .toggler
    //      |- .toggleable[.expanded]
    // The .expanded class can be set either on the parent container or on the 
    // .toggleable element, to indicate that the toggleable content should 
    // initially be shown. Otherwise, it will initially be hidden.
    
    var handleToggle = function(e, toggler) {
        e.preventDefault();
        // NEW begin 
        var target = getToggleable(toggler);
        var parent = target.parent();
        
        // the breakpoint at 800 and the element whose width is evaluated 
        // should be adjusted to fit the specific site.
        // (E.g. use $('main').width() instead of window.innerWidth)
        if (parent.hasClass('allow-tabs') && window.innerWidth >= getSmallScreenBreakpoint()) {
        //if (parent.hasClass('allow-tabs') && parent.width() >= getSmallScreenBreakpoint()) {
          // tab-style -> 
          // step 1: close all toggleables in the panel
          var togglers = parent.add('.toggler');
          togglers.each(function() {
			  console.log('toggler clicked while using tabs, closing all other tabs...');
            doCloseToggle($(this));
          });
          // step 2: open the toggleable whose trigger was cliced
          doOpenToggle(toggler);
          //doToggle(toggler, false);
        } else {
          doToggle(toggler, true);
        }
        //doToggle(toggler, true);
        /*
        target.toggleClass('expanded');
        parent.toggleClass('expanded');
        target.slideToggle(400);
        if (target.hasClass('expanded')) {
            toggler.attr('aria-expanded', 'true');
            target.attr('aria-hidden', 'false');
        } else {
            toggler.attr('aria-expanded', 'false');
            target.attr('aria-hidden', 'true');
        }
        //*/
        // NEW end
    };
    
    initToggleablesInside( $('body') );
    
    $('body').on('click', '.toggler', function(e) {
        handleToggle(e, $(this));
    });
}

function doToggle(/*jQuery*/toggler, /*boolean*/slide) {
  var target = getToggleable(toggler);
  
  target.toggleClass('expanded');
  target.parent().toggleClass('expanded');
  if (slide) {
    //target.slideToggle(400);
  }
  
  if (target.hasClass('expanded')) {
    doOpenToggle(toggler);
  } else {
    doCloseToggle(toggler);
  }
}
function doCloseToggle(toggler) {
  var target = getToggleable(toggler);
  target.removeClass('expanded');
  toggler.attr('aria-expanded', 'false');
  target.attr('aria-hidden', 'true');
}
function doOpenToggle(toggler) {
  var target = getToggleable(toggler);
  target.addClass('expanded');
  toggler.attr('aria-expanded', 'true');
  target.attr('aria-hidden', 'false');
}

/**
 * Gets the .toggleable that immediately follows the given toggler, or its 
 * parent (if no .toggleable followed the toggler direcly).
 * 
 * @param {jQuery} toggler The toggler.
 * @returns {jQuery|getToggleable.target} The toggler's .toggleable.
 */
function getToggleable(toggler) {
    var target = toggler.next('.toggleable');
    // Handle case: target was inside a wrapper (e.g. a heading tag)
    if (target.length === 0) {
        var togglerWrapper = toggler.parent();
        togglerWrapper.addClass("toggler-wrapper");
        target = togglerWrapper.next('.toggleable');
    }
    //console.log(".toggleable: (" + target.prop("tagName") + ") " + target);
    return target;
}

/**
 * Initializes "toggleables" - that is, accordion content - inside the given 
 * container.
 * 
 * @param {type} container  The container elmenent, which may or may not contain any "toggleables".
 * @returns {undefined}  Nothing.
 */
function initToggleablesInside(/*jQuery*/container) {
    'use strict';
    // works only with new toggler:
    //  [container]
    //      |- [.toggler]       <-- the trigger, clicked to show/hide stuff
    //      |- [.toggleable]    <-- the target, wraps the stuff to show/hide
    //      
    //      OR:
    //  [container]
    //      |- <x>[.toggler]</x>    <-- (max 1 wrapper, pref. w/class "toggler-wrapper")
    //      |- [.toggleable]        <-- must follow immediately after the wrapper
    //      
    // 
    // NOTE: The .toggler element should always be an <a>, and ideally with the 
    // following attributes set:
    //      - href              <-- e.g. href="the-toggleable-ID"
    //      - aria-controls     <-- e.g. aria-controls="the-toggleable-ID"
    //      
    // Conversely, the .toggleable should have its ID attribute set:
    //      - id                <-- e.g. id="the-toggleable-ID"
    //      
    // Using an <a> element makes keyboard navigation work well, and the href 
    // is necessary to trigger "clicks" via the enter key. It is also needed for 
    // stuff to work without javascript, e.g. using the :target rule in CSS. The
    // latter is not possible using f.ex. a button (not without a form).
    var expandedClass = 'expanded';
    
    var toggleTriggers = container.find('.toggler');
    
    toggleTriggers.each( function(index) {
		
        var target = getToggleable($(this));
        var parent = target.parent();
		
		// when dealing with a tab panel UI, make sure the first tab is initially expanded
		if (index === 0) {
			if (parent.hasClass('allow-tabs') && window.innerWidth >= getSmallScreenBreakpoint()) {
				target.addClass(expandedClass);
			}
		}
		
		
        var isExpanded = target.hasClass(expandedClass);// || parent.hasClass(expandedClass);
        //console.log("element " + target.attr('id') + " expanded? " + target.hasClass(expandedClass));
        var targetId = target.attr('id');
        if (typeof targetId === 'undefined' || targetId === false) {
          // missing ID -> construct one and set it
            targetId = 'toggleable-'+index;
            target.attr('id', targetId);
        }        
        target.attr('aria-hidden', isExpanded ? 'false' : 'true');
        
        //console.log('Set ' + $(this).prop('tagName') + ' as trigger in loop iteration ' + index);
        // Add ARIA info + make trigger keyboard accesssible
        $(this).attr({ 
            'aria-controls' : targetId,
            'aria-expanded' : isExpanded ? 'true' : 'false',
            'tabindex' : '0' // in case the trigger is not natively focusable
        });
        // If the trigger is an <a> element, make sure a href attribute exists
        if ($(this).prop('tagName').toUpperCase() === 'A') {
            var href = $(this).attr('href');
            if (typeof href === 'undefined' || href === false) {
                $(this).attr({
                    'href' : '#'+targetId
                });
            }
        }
        
        if (!isExpanded) {
            //target.slideUp(1); // Hide toggleable content
        } else {
            target.addClass(expandedClass);
            parent.addClass(expandedClass);
        }
    });
}



/**
 * Initializes "toggleables" - that is, accordion content - on the page.
 * 
 * @returns {undefined}  Nothing.
 */
/*function initToggleables() {
    'use strict';
    
    // Older toggler:
    //  .toggleable[.collapsed|.open]
    //      |- .toggletrigger
    //      |- .toggletarget
    // Apply the .open class to indicate that the toggleable content should 
    // initially be shown. Otherwise, it will initially be hidden.
    $('.toggletrigger').attr('tabindex', '0');
    $('.toggleable.collapsed > .toggletarget').slideUp(1); // Hide normally-closed ("collapsed") accordion content		
    $('.toggleable.collapsed > .toggletrigger').append(' <em class="icon-down-open-big"></em>'); // Append arrow icon to "show accordion content" triggers
    $('.toggleable.open > .toggletrigger').append(' <em class="icon-up-open-big"></em>'); // Append arrow icon to "hide accordion content" triggers
    $('.toggleable > .toggletrigger').click( // Click handler
        function() {
            $(this).next('.toggletarget').slideToggle(500); // Slide up/down the next toggle target ...
            //$(this).children().first().toggleClass('icon-up-open-big').toggleClass('icon-down-open-big');
            $(this).children().first().toggleClass('icon-up-open-big icon-down-open-big'); // ... and toggle the icon class, so the arrows change corresponding to the slide up/down
        });
        
    // Newer toggler:
    //  container[.expanded]
    //      |- .toggler
    //      |- .toggleable[.expanded]
    // The .expanded class can be set either on the parent container or on the 
    // .toggleable element, to indicate that the toggleable content should 
    // initially be shown. Otherwise, it will initially be hidden.
    
    var handleToggle = function(e, toggler) {
        e.preventDefault();
        var target = getToggleable(toggler);
        target.toggleClass('expanded');
        target.parent().toggleClass('expanded');
        target.slideToggle(400);
        
        if (target.hasClass('expanded')) {
            toggler.attr('aria-expanded', 'true');
            target.attr('aria-hidden', 'false');
        } else {
            toggler.attr('aria-expanded', 'false');
            target.attr('aria-hidden', 'true');
        }
    };
    
    initToggleablesInside( $('body') );
    
    $('body').on('click', '.toggler', function(e) {
        handleToggle(e, $(this));
    });
}
//*/

/**
 * Gets the .toggleable that immediately follows the given toggler, or its 
 * parent (if no .toggleable followed the toggler direcly).
 * 
 * @param {jQuery} toggler The toggler.
 * @returns {jQuery|getToggleable.target} The toggler's .toggleable.
 */
/*function getToggleable(toggler) {
    var target = toggler.next('.toggleable');
    // Handle case: target was inside a wrapper (e.g. a heading tag)
    if (target.length === 0) {
        var togglerWrapper = toggler.parent();
        togglerWrapper.addClass("toggler-wrapper");
        target = togglerWrapper.next('.toggleable');
    }
    //console.log(".toggleable: (" + target.prop("tagName") + ") " + target);
    return target;
}
//*/

/**
 * Initializes "toggleables" - that is, accordion content - inside the given 
 * container.
 * 
 * @param {type} container  The container jQuery element, which may or may not contain any "toggleables".
 * @returns {undefined}  Nothing.
 */
 /*
function initToggleablesInside(container) {
    'use strict';
    // works only with new toggler:
    //  [container]
    //      |- [.toggler]       <-- the trigger, clicked to show/hide stuff
    //      |- [.toggleable]    <-- the target, actual stuff to show/hide
    //      
    //      OR:
    //  [container]
    //      |- <x>[.toggler]</x>    <-- (max 1 wrapper, pref. w/class "toggler-wrapper")
    //      |- [.toggleable]        <-- immediately after the wrapper
    //      
    // 
    // NOTE: The .toggler element should always be an <a>, and ideally with the 
    // following attributes set:
    //      - aria-controls     <-- e.g. "#the-toggleable-ID"
    //      - href              <-- e.g. "#the-toggleable-ID"
    //      
    // Conversely, the .toggleable should have its ID attribute set:
    //      - id                <-- e.g. "the-toggleable-ID"
    //      
    // Using an <a> element makes keyboard navigation work well, and the href 
    // is necessary to trigger "clicks" via the enter key. It is also needed for 
    // stuff to work without javascript, e.g. using the :target rule in CSS.
    var expandedClass = 'expanded';
    
    var toggleTriggers = container.find('.toggler');
    
    toggleTriggers.each( function(index) {
        var target = getToggleable($(this));
        var parent = target.parent();
        var isExpanded = target.hasClass(expandedClass) || parent.hasClass(expandedClass);
        
        var targetId = target.attr('id');
        if (typeof targetId === 'undefined' || targetId === false) {
            targetId = 'toggleable-'+index;
            target.attr('id', targetId);
        }        
        target.attr('aria-hidden', isExpanded ? 'false' : 'true');
        
        //console.log('Set ' + $(this).prop('tagName') + ' as trigger in loop iteration ' + index);
        // Add ARIA info + make trigger keyboard accesssible
        $(this).attr({ 
            'aria-controls' : targetId,
            'aria-expanded' : isExpanded ? 'true' : 'false',
            'tabindex' : '0' // in case the trigger is not natively focusable
        });
        // If the trigger is an <a> element, make sure a href attribute exists
        if ($(this).prop('tagName').toUpperCase() === 'A') {
            var href = $(this).attr('href');
            if (typeof href === 'undefined' || href === false) {
                $(this).attr({
                    'href' : '#'+targetId
                });
            }
        }
        
        if (!isExpanded) {
            target.slideUp(1); // Hide toggleable content
        } else {
            target.addClass(expandedClass);
            parent.addClass(expandedClass);
        }
    });
}
//*/


/*
function showOutlines() {
    'use strict';
    try { 
        document.getElementById("_outlines").innerHTML="a:focus, input:focus, button:focus, select:focus { outline:thin dotted; outline:2px solid orange; }"; 
    } catch (err) { 
        return false; 
    }
    return true;
}
function hideOutlines() {
    'use strict';
    try { 
        document.getElementById("_outlines").innerHTML="a, a:focus, input:focus, select:focus { outline:none !important; } "; 
    } catch (err) { 
        return false; 
    } 
    return true;
}*/

/**
 * @see http://support.addthis.com/customer/portal/articles/1293805-using-addthis-asynchronously#.UxSMJuIkAU8
 */
/*
function loadAddThis() {
    'use strict';
    //var addthisScript = document.createElement('script');
    //addthisScript.setAttribute('src', 'http://s7.addthis.com/js/300/addthis_widget.js#domready=1');
    //addthisScript.setAttribute('type', 'text/javascript');
    //document.body.appendChild(addthisScript);

    // Add the profile ID (pubid)
    var addthis_config = addthis_config||{};
    addthis_config.pubid = 'ra-52b2d01077c3a190';
    addthis.init();
}
*/

/**
 * Creates a blurry background for the hero image, based on the hero image itself.
 * @param {String} jsUriStackBlur The URI to the StackBlur javascript.
 * @returns {Boolean} True if no error is thrown, false if not.
 */
function makeBlurryHeroBackground(jsUriStackBlur) {
    'use strict';
    var iPadClient = false; 
    try { iPadClient = navigator.userAgent.match(/iPad/i) !== null; } catch (ignore) {}

    try {
        //console.log('starting blurry hero background ...');
        //$(function() {
            if (isBigScreen() && !iPadClient) {
				var heroEl = $('.hero .hero__part--media');
				var heroImageEl = heroEl.find('img').first();
                if (!nonResIE()) {
                    if (Modernizr.cssfilters) {
                        // CSS approach
                        //console.log('cssfilter support detected ...');
                        //heroEl.append( heroImageEl.clone() );
						heroEl.append( $('<div id="hero-blur"></div>').css({'background-image' : 'url("'+heroImageEl.attr('src')+'")'}) );
                    } else {
                        //console.log('cssfilter support missing, using canvas ...');
                        // Canvas approach
                        $.getScript(jsUriStackBlur, function() {
                            heroEl.append('<canvas class="article-hero-bg" id="hero-bg" width="480" height="210" data-canvas></canvas>');
                            //$('.article-hero').append('<canvas class="article-hero-bg" id="hero-bg" width="200" height="200" data-canvas></canvas><div id="hero-canvas-overlay"></div>');
                            // Change this value to adjust the amount of blur
                            var BLUR_RADIUS = 16;

                            var canvas = document.getElementById('hero-bg');//querySelector('[data-canvas]');
                            var canvasContext = canvas.getContext('2d');

                            var image = new Image();
                            image.src = heroImageEl.attr('src');// document.querySelector('[data-canvas-image]').src;

                            var drawBlur = function() {
                                var w = canvas.width;
                                var h = canvas.height;
                                canvasContext.drawImage(image, 0, 0, w, h);
                                stackBlurCanvasRGBA('hero-bg', 0, 0, w, h, BLUR_RADIUS);
                            };

                            image.onload = function() {
                                // draw the blurry image using stackblur
                                drawBlur();
                                // add top-to-bottom gradient, use the same color as
                                // the header
								//var linGrad = canvasContext.createLinearGradient(255, 255, 255, 90);
                                var linGrad = canvasContext.createLinearGradient(0, 0, 0, 30);
								linGrad.addColorStop(0, 'rgba(250,250,255,1)');
                                linGrad.addColorStop(1, 'rgba(250,250,255,0)');
                                //linGrad.addColorStop(0, 'rgba(14,19,31,1)');
                                //linGrad.addColorStop(1, 'rgba(14,19,31,0)');
                                canvasContext.fillStyle = linGrad;
                                canvasContext.fillRect(0, 0, canvasContext.canvas.width, canvasContext.canvas.height);
                            };
                        });
                        //console.log('done with blurry hero background ...');
                    }
                } else { // css blur filter (ms-filter)
                    heroEl.append( 
						heroImageEl.clone()
						//$('.article-hero-content > figure > img').clone() 
					);
                }
            }
        //});
    } catch (err) {
        //console.log('error creating blurry hero background: ' + err);
        return false;
    }
    return true;
}

/**
 * Makes tables responsive.
 * @see http://zurb.com/playground/projects/responsive-tables
 * @returns {Boolean} True if no error is thrown, false if not.
 */
function makeResponsiveTables() {
    'use strict';
    
    function splitTable(original) {
        original.wrap("<div class='table-wrapper' />");
        var copy = original.clone();
        copy.find("td:not(:first-child), th:not(:first-child)").css("display","none");
        copy.removeClass("responsive");
        original.closest(".table-wrapper").append(copy);
        copy.wrap("<div class='pinned' />");
        original.wrap("<div class='scrollable' />");
    }
    
    function unsplitTable(original) {
        original.closest(".table-wrapper").find(".pinned").remove();
        original.unwrap();
        original.unwrap();
    }
    
    try {
	var switched=false;
        var updateTables = function() {
            if(($(window).width()<767) && !switched) {
                switched=true;
                $("table.responsive").each(function(i,element) {
                    splitTable($(element));
                });
                return true;
            } 
            if (switched && ($(window).width()>767)) {
                switched=false;
                $("table.responsive").each(function(i,element) {
                    unsplitTable($(element));
                });
            }
        };
        $(window).load(updateTables);
        $(window).bind("resize", updateTables);
    } catch (err) {
        return false;
    }
    return true;
}

/**
 * Makes tabbed content.
 * @returns {Boolean} True if no error is thrown, false if not.
 */
function makeTabs() {
    'use strict';
    try {
        // Set the default active tab (make it the first one)
        var firstTab = $('.tabbed .tab').first();
        var hash = window.location.hash.substring(1);
        if (!(hash === 'refs' || hash === 'links')) {
            firstTab.addClass('active-tab');
        }
        // set the height
        var height = firstTab.outerHeight();
        
        // Process each tabbed section
        $('.tabbed').each(function(e) {
            // calculate a more correct top offset for the tab content boxes
            var tabContentTopOffset =   $(this).children('.tabbed-heading').first().outerHeight() +              $(this).find('.tab-link').first().outerHeight();
            //console.log('heading: ' +   $(this).children('.tabbed-heading').first().outerHeight() + ', tab: ' +  $(this).find('.tab-link').first().outerHeight());
            
            // iterate all the tab content boxes
            $(this).find('.tab-content').each(function(e) {
                // find the tallest one
                var thisTabHeight = $(this).children().first().outerHeight();
                //console.log('tab content height is ' + thisTabHeight + '. new max? ' + (thisTabHeight > height));
                if (thisTabHeight > height) {
                    height = thisTabHeight;
                }
                
                // set the top offset (some browsers, e.g. chrome, need a little less than others, e.g. firefox)
                $(this).css({ top : (tabContentTopOffset-2)+'px' });
            });
            
            // set the height equal to the tallest one's height, plus a little extra (wrapper's padding etc.)
            $(this).css({ height : (height+125)+'px' });
        });
        
	$('.tabbed .tab .tab-link').click(function(e) {
            e.preventDefault();
            $('.tabbed .tab').removeClass('active-tab');
            $(this).parent('.tab').addClass('active-tab');
            
            /*var clone = $(this).next('.tab-content').clone();
            clone.attr('style', 'display:block; position:relative; left:-9999px; top:-9999px;');
            var tabContentHeight = clone.height();
            clone.remove();*/
            
            /*var tabContentHeight = $(this).next('.tab-content').children().first().height();
            console.log('setting tabbed height to ' + (tabContentHeight+90) + 'px');
            $(this).parents('.tabbed').first().attr('style', 'height:'+ (tabContentHeight+90) + 'px');*/
	});
    } catch (err) {
        return false;
    }
    return true;
}
/**
 * Makes tooltips on elements with data-tooltip or data-hoverbox attributes.
 * @param {String} cssUri The URI to the qTip css.
 * @param {String} jsUri The URI to the qTip javascript.
 * @returns {Boolean} True if no error is thrown, false if not.
 */
function makeTooltips(cssUri, jsUri) {
    'use strict';
    try {
        if ($('[data-tooltip]')[0] || $('[data-hoverbox]')[0]) {
            $('head').append('<link rel="stylesheet" href="' + cssUri + '" type="text/css" />');
            $.getScript(jsUri, function() {
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
            });
        }
    } catch (err) {
        return false;
    }
    return true;
}
/**
 * Makes an animated scroll-to effect for on-page links.
 * @returns {Boolean} True if no error is thrown, false if not.
 */
function makeScrollToSmooth() {
    'use strict';
    try {
        //$('a[href*=#]:not([href=#])').click(function() { // Apply to all on-page links
        $('.reflink,.scrollto').click(function() {
            if (location.pathname.replace(/^\//,'') === this.pathname.replace(/^\//,'') || location.hostname === this.hostname) {
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
    } catch (err) {
        return false;
    }
    return true;
}

/**
 * Makes ready Highslide, by injecting the necessary css/js in the HTML head.
 * @param {String} cssUri The URI to the Highslide css.
 * @param {String} jsUri The URI to the Highslide javascript.
 * @param {String} lang The desired language.
 * @returns {Boolean} True if no error is thrown, false if not.
 */
function readyHighslide(cssUri, jsUri, lang) {
    'use strict';
    try {
        if ($(".highslide")[0]) {
            $('head').append('<link rel="stylesheet" type="text/css" href="' + cssUri + '" />');
            $.getScript(jsUri, function() {
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
                hs.lang = getHighslideLabels(lang);
            });
        }
    } catch (err) {
        return false;
    }
    return true;
}

/**
 * Define "keyboard optimized" styles in the style element with 
 * ID "__adaptive-styles".
 */
function keyFriendly() {
    'use strict';
    try { 
        document.getElementById("__adaptive-styles").innerHTML = "a:focus, input:focus, button:focus, select:focus { outline:thick solid #f44; outline-offset:4px; }";
    } catch (ignore) {}
}

/**
 * Define "mouse/touch optimized" styles in the style element with 
 * ID "__adaptive-styles".
 */
function mouseFriendly() {
    'use strict';
    try { 
        document.getElementById("__adaptive-styles").innerHTML = "a, a:focus, input:focus, select:focus { outline:none !important; }";
    } catch (ignore) {}
}

/**
 * Indicates whether or not the small screen global menu is currently visible.
 * @returns {Boolean} True if the small screen menu is visible, false if not.
 */
function smallScreenMenuIsVisible() {
    'use strict';
    return $('html').hasClass('navigating');
}

/**
 * Updates elements like the global search, global menu etc. to fit the current
 * viewport width.
 */
function layItOut() {
    'use strict';
    var menu = $('#nav');
    
    if (isBigScreen()) {
        // Remove class used only on the small-screen menu
        //menu.removeClass('nav-colorscheme-dark');
    } else {
        // Small-screen menu class
        //menu.addClass('nav-colorscheme-dark');
    }
}
/**
 * Opens or closes the small-screen menu.
 * 
 * This method will also manipulate the "tabindex" attribute of all links in
 * the menu, to prevent or enable the menu items from being keyboard (tab) 
 * accessible. (Prevents tabbing users from entering a closed menu.)
 */
function toggleMenuVisibility() {
    'use strict';
    var menu = $('#nav');
    var html = $('html');
    
    if (smallScreenMenuIsVisible()) { // = menu was already open at click time
        // About to open the menu: make its links NOT tab accessible
        menu.find('a').attr('tabindex', '-1');
    } else {
        // About to open the menu: make its links tab accessible
        menu.find('a').removeAttr('tabindex');
    }
    
    // Toggle the class that triggers the actual opening/closing of the 
    // menu.
    html.toggleClass('navigating');
}
/**
 * Initializes the user controls - menu/search (incl. togglers), outline style 
 * optimization, language switch, etc.
 */
function initUserControls() {
    'use strict';
    var menu = $('#nav');
    var html = $('html');
    
    // inject sub-navigation togglers (shows/hides children of a parent menu item)
    menu.find('li.has_sub').not('.inpath').addClass('hidden-sub');
    menu.find('li.has_sub.inpath').addClass('visible-sub');
    menu.find('li.has_sub > a').after('<a class="visible-sub-toggle" href="#"></a>');
    
    // handle click on sub-navigation toggler
    $('.visible-sub-toggle').click(function(e) {
        e.preventDefault();
        $(this).parent('li').toggleClass('visible-sub hidden-sub');
    });

    // handle click on menu toggler
    $('.nav-toggler').click(function(e) {
        e.preventDefault();
        toggleMenuVisibility();
    });

    // handle click somewhere on the page content when small-screen menu was open
    html.click(function(event) { 
        if (smallScreenMenuIsVisible()) {
            if (!($(event.target).closest('#nav').length || $(event.target).closest('#header').length)) {
                toggleMenuVisibility();
            }
        }
    });
    
    // handle focus transition "out from the bottom" of the open small-screen menu
    $('body *').focus(function(event) {
        if (smallScreenMenuIsVisible()) {
            if (!($(event.target).closest('#nav').length || $(event.target).closest('#header').length)) {
                toggleMenuVisibility();
            }
        }
    });

    // bugfix - the #wrap div is sometimes able to receive focus (even tho it has no tabindex)
    $('#wrap').attr('tabindex', '-1');
	
    // toggle "focus" class on menu items when appropriate
    menu.find('a').focus(function() {
        $(this).parents('li').addClass('infocus');
    });
    menu.find('a').blur(function() {
        $(this).parents('li').removeClass('infocus');
    });
    
    // hover delay handling for mouse users (usability bonus)
    if (!Modernizr.touch) {
        menu.find('li').hoverDelay({
            delayIn: 250,
            delayOut: 400,
            handlerIn: function($element)   { $element.addClass('infocus'); },
            handlerOut: function($element)  { $element.removeClass('infocus'); }
        });
        /*
        // use hoverintent to add usability bonus for mouse users
        $('#nav li').hoverIntent({
            over: mouseinMenuItem
            ,out: mouseoutMenuItem
            ,timeout:400
            ,interval:250
        });
        */
    } else {
        // Touch units will typically emulate these mouse events
        menu.find('li').mouseover(function()   { $(this).addClass('infocus'); });
        menu.find('li').mouseout(function()    { $(this).removeClass('infocus'); });
    }
    
    // inject "adaptive styles" (accessibility bonus)
    $('head').append('<style id="__adaptive-styles" />');
    $('body').bind('mousedown', function(e) {
        html.removeClass('tabbing');
        mouseFriendly();
    });
    $('body').bind('keydown', function(e) {
        html.addClass('tabbing');
        if (e.keyCode === 9) {
            keyFriendly();
        }
    });
    
    // handle click on search box toggler
    $('#toggle-search').click(function(e) {
        e.preventDefault();
        html.toggleClass('search-open');
        if (!html.hasClass('tabbing')) { // Don't auto-shift focus if the user is tabbing
            $('#query').focus();
        }
    });
    
    /*
    // Clone the language switch and put it in the menu
    if (!$('.language-switch-menu-item')[0]) { // do it only if necessary
        var clonedLangSwitch = $('.language-switch').clone().attr('class', 'language-switch-menu-item').attr('style', '');
        var liLangSwitch = $('<li/>').attr('style', 'border-top:1px solid orange').attr('class', 'smallscr-only').appendTo($('#nav_topmenu'));
        liLangSwitch.append(clonedLangSwitch.prepend('<i class="icon-cog" style="font-size:1.2em;"></i> '));
    }
    $('.language-switch').addClass('bigscr-only');
    */
	
    // Make sure all links in the small-screen menu are initially NOT keyboard-accessible
    // (because the small-screen menu is initially hidden)
    if (!isBigScreen()) {
        menu.find('a').attr('tabindex', '-1');
    }
}

/**
 * Things to do when the document is ready
 */
$(document).ready( function() {
    'use strict';
	
	// make standouts (temporary solution - this should be handled in the pageelements/paragraph module of OpenCms)
	$('.media.oversize').wrap('<div class="standout standout--alt"></div>');
	
    // responsive tables
    makeResponsiveTables();
    // tabbed content (enhancement - works with pure css but not optimal)
    makeTabs();
	
	//makeBlurryHeroBackground("/website-projects/common/js/stackblur.min.js"); // Local path
	makeBlurryHeroBackground("/system/modules/no.npolar.site.npweb/resources/js/stackblur.min.js");

	$('h1').first().before( $('#nav_breadcrumb_wrap') );
    // qTip tooltips
    //makeTooltips();

    // Animated verical scrolling to on-page locations
    makeScrollToSmooth();

    // Add facebook-necessary attribute to the html element
    $("html").attr('xmlns:fb', 'http://ogp.me/ns/fb#"');

    // Format tables
    //makeNiceTables();

    // Fragment-based highlighting
    $("a").click(function() { highlightReference(); }); // On click (it's not sufficient to track only .reflink clicks - that will cause any previous highlighting to stick "forever")
    highlightReference(); // On page load

    // "Read more"-links
    $(".cta.more").append('<i class="icon-right-open-big"></i>');
	
    // Initialize accordions of type "toggleable"
    initToggleables();
    
    // Setup the user controls (global menu, global search etc.)
    initUserControls();
    
    // Invoke the layout handler
    layItOut();

    // Invoke the layout handler again whenever the viewport width changes
    $(window).resize(function() {
        if ($(this).width() !== lastDetectedWidth) { // True => width changed during resize
            lastDetectedWidth = $(this).width();
            layItOut();
        }
    });
});

/**
 * Swaps the grouping of series name(s) and grouping of a HighCharts chart.
 * 
 * Example (try uncommenting the function code in chart.event.load):
 * http://jsfiddle.net/dcus5fjs/1/
 * 
 * @param {jQuery} chart jQuery object referencing a HighCharts chart, e.g. $('#hc-container').highcharts();
 * @param {json} customSettings a JSON object that holds the custom settings, if any
 * @returns {Boolean} True if all went well, false if not.
 * @see http://jsfiddle.net/srLtL5qd/
 */
function toggleHighChartsGrouping(/*jQuery*/chart, /*jsonObj*/customSettings) {
    'use strict';
    
    try {
        var newLabels = [];
        var newCatagories = [];
        var newData = [];
        //var chart = highChartsChart;//
        var seriez = chart.series;
        $.each(chart.xAxis[0].categories, function (i, name) {
            newLabels.push(name);
        });
        $.each(seriez, function (x, serie) {
            newCatagories.push(serie.name);
            $.each(serie.data, function (z, point) {
                if (newData[z] === undefined) {
                    newData[z] = [];
                }
                if (newData[z][x] === undefined) {
                    newData[z][x] = '';
                }
                newData[z][x] = point.y;
            });
        });
        while (chart.series.length > 0) {
            chart.series[0].remove(true);
        }
        chart.xAxis[0].setCategories(newCatagories, false);
        var i = 0;
        $.each(newData, function (key, newSeriesData) {
            var newSeriesColor = getHighchartsTheme().colors[i];
            var newSeriesLabel = newLabels[key];
            
            // Change colors etc. if custom settings says so
            try {
                $.each(customSettings.series, function(index, customSeriesSettings) {
                    if (customSeriesSettings.id.trim() === newSeriesLabel.trim()) { // E.g. if "2012" === "2012"
                        var customColor = customSeriesSettings.color; // Get the color, e.g. "2" or "#f00"
                        if (customColor.length > 0) {
                            if (customColor.length < 3) { // Assume the value is an int which refers to one of the standard colors, e.g. "2"
                                newSeriesColor = getHighchartsTheme().colors[parseInt(customColor)-1]; // Assume the 
                            } else {
                                newSeriesColor = customColor; // Assume the value is an actual color, e.g. "#f00"
                            }
                        }
                    }
                });
            } catch (ignore) {} // Empty or bad settings
            
            chart.addSeries({
                name: newSeriesLabel,
                data: newSeriesData,
                color: newSeriesColor
            }, false);
            i++;
        });
        chart.redraw();
    } catch (err) {
        console.log('commons.js: Toggle HighCharts grouping failed: ' + err.message);
        return false;
    }
    return true;
}

/**
 * Attempts to populate any empty data arrays for series in the given chart.
 * 
 * @param {type} chart
 * @returns {undefined}
 */
function fillEmptyData(/*Object*/chart) {
    'use strict';
    //console.log('Processing chart "' + chart.title + '" (' + chart.series.length + ' series) ...');
    for (var i = 0; i < chart.series.length; i++) {
        var singleSeries = chart.series[i];
        //console.log('series #' + i + ' has data length ' + singleSeries.data.length);
        if (singleSeries.data.length === 0) {
            //console.log('Requesting async data for series #' + i + " @ " + singleSeries.options.url + ' ...');
            loadTimeSeriesData(singleSeries);
            /*$.ajax({
                url: '/tsdata.jsp',
                data: { id : singleSeries.options.id },
                dataType: 'jsonp',
                timeout: 10000,
                success: function(data) {
                    console.log('Successfully received time series data, updating chart ...');
                    singleSeries.setData(data, false);
                    modifiedSomething = true;
                },
                error: function(data) {
                    console.log('Error loading time series data!');
                    //console.log('Error receiving data: ' + JSON.stringify(data));
                }
            });*/
        }
    }
}

function loadTimeSeriesData(/*Object*/series) {
    'use strict';
    //console.log('loadTimeSeriesData called on series ' + series.options.id);
    $.ajax({
        url:'/tsdata.jsp',
        data: {
            id: series.options.id
        }, 
        dataType: 'jsonp',
        beforeSend: function() {
            //console.log('Getting data for ' + series.options.id);
        },
        success: function(data) {
            series.setData(data, true);
        },
        error: function() {
            console.log('Error loading time series data!');
        }
    });
}


/**
 * Highslide settings
 */
function getHighslideSettings() {
    'use strict';
    try {
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
    } catch (ignore) {
        // Highslide probably undefined
    }
}

/**
 * Gets Highcharts labels localized according to the given language.
 * 
 * @param {type} lang The desired language, e.g. 'en' or 'no'.
 * @returns {Object} Highcharts labels localized according to the given language or, if that language isn't configured, in the default language.
 * @see HC_LABELS
 */
function getHighchartsLables(/*String*/lang) {
    'use strict';
    if (!(lang === 'en' || lang === 'no')) {
        // Non-supported language, fallback to default
        lang = 'en';
    }
    return HC_LABELS[lang];
}

/**
 * Gets Highslide labels localized according to the given language.
 * 
 * @param {type} lang The desired language, e.g. 'en' or 'no'.
 * @returns {Object} Highslide labels localized according to the given language or, if that language isn't configured, in the default language.
 * @see HC_LABELS
 */
function getHighslideLabels(/*String*/lang) {
    'use strict';
    if (!(lang === 'en' || lang === 'no')) {
        // Non-supported language, fallback to default
        lang = 'en';
    }
    return HS_LABELS[lang];
}

function getHighchartsTheme(/*String*/lang) {
    'use strict';
    return {
        colors: [
            '#0277D5',// bright blue
            '#E52418',// bright red
            '#49A801',// bright green
            '#393331',// asphalt
            '#8E1FAC',// bright purple
            '#C74F18',// orange
            '#7D6F42',// earth
            '#78753E',// olive
            '#CD238E',// bright pink
            '#197d86',// teal
            '#054477',// deep blue
            '#4E0C13' // plum
        ],
        chart: {
            backgroundColor: {
                linearGradient: [0, 0, 500, 500],
                stops: [
                    [0, 'rgb(255, 255, 255)']
                ]
            }
        },
        title: {
            style: {
                color: '#000',
                font: '1.5em "Open sans", "Trebuchet MS", Verdana, sans-serif'
            }
        },
        tooltip: {
            backgroundColor: '#fff',
            borderColor: '#666',
            borderRadius: 5,
            borderWidth: 2
        },
        legend: {
            itemStyle: {
                font: '1em "Open sans", Trebuchet MS, Verdana, sans-serif',
                color: '#000'
            },
            itemHiddenStyle:{
                color: '#aaa'
            } ,
            itemHoverStyle:{
                color: '#000',
                font: 'bold'
            }   
        },
        lang: getHighchartsLables(lang)
    };
}

/**
 * Toggle class name on link when it receives focus.
 */
document.getElementsByTagName('a').onfocus = function(e) {
    'use strict';
    toggleClass(e.target, 'has-focus');
};


/**
 * Class toggler (non-jQuery)
 * @type type
 */ 
function toggleClass(/*Element*/element, /*String*/theClass) {
    'use strict';
    var classesStr = element.getAttribute('class');
    if ( classesStr === null || typeof classesStr === 'undefined' ) {
        element.setAttribute('class', theClass);
    } else {
        var classes = classesStr.split(' ');
        var removedClass = false;
        classesStr = '';
        for (var i = 0; i < classes.length; i++) {
            var existingClassName = classes[i].trim();
            if (existingClassName !== theClass) {
                classesStr += existingClassName + ' ';
            } else {
                removedClass = true;
            }
        }
        if (!removedClass) {
            classesStr += theClass;
        }
        element.setAttribute('class', classesStr);
    }
}
/*
function mouseinMenuItem(menuItem) {
    'use strict';
    $(this).addClass('infocus');
}
function mouseoutMenuItem(menuItem) {
    'use strict';
    $(this).removeClass('infocus');
}
*/