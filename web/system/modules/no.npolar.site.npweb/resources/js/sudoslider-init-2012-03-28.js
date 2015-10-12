function showSlideNav() {
	$(this).animate({"left":0});
}
function hideSlideNav() {
	//alert("slideNavWidth = " + slideNavWidth + ".");
	$(this).animate({"left": -1*slideNavWidth});
}

var slideNavWidth = 0;
$(document).ready(function(){   
	var sudoSlider = $("#slider").sudoSlider({
        customLink: '.slide-tab-nav', // The class used on the custom nav-elements
		prevNext: false, // Previous/next buttons generation
		auto: true, // Autostart
		fade: true,
		//countinuous: true,
		//numeric: true,
		pause: '5000' // Time spent on each stable position
	});
   
	//$("#slidemenu .slide-nav").mouseenter( function () { $(this).animate({"right":0}); } );
	//$("#slidemenu .slide-nav").mouseleave( function () { $(this).animate({"right":-160}); } );
	var slideNavWidthStr = $("#slidemenu .slide-nav").css("width");
	slideNavWidth = parseFloat(slideNavWidthStr.substring(0, slideNavWidthStr.length - 2)) - 20;
	//$("#slidemenu .slide-nav").animate({"left": -1*slideNavWidth});
	$("#slidemenu").animate({"left": -1*slideNavWidth});
	
	var slideNavConfig = {
		over: showSlideNav, // The function to call onMouseOver
		//timeout: 600, // The delay, in milliseconds, before the "out" function is called
		//interval: 150, // The interval between checking mouse position (the soonest "over" function can be called is after a single interval)
        timeout:500,
        interval:100,
		out: hideSlideNav // The function to call onMouseOut
	}

	// Add the "hover listener" by passing the configuration object to hoverIntent
	//$("#slidemenu .slide-nav").hoverIntent(slideNavConfig);
	$("#slidemenu").hoverIntent(slideNavConfig);
});