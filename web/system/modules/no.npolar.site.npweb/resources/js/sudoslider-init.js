// JavaScript Document: sudoslider-init.js
/*
   var oldt = 0;
   var sudoSlider = $("#slider").sudoSlider({ 
	  beforeAniFunc: function(t){ 
		 var substract = $('#slidemenu ul').offset();
		 var posi = $('#slidemenu ul li').eq(t-1).offset();
		 var left =  posi.left - substract.left;
		 var diff = Math.sqrt(Math.abs(oldt-t));
		 var speed = parseInt(diff*800);
		 var text = $('#slidemenu ul li').eq(t-1).text();
		 var width = $('#slidemenu ul li').eq(t-1).width();
		 $('#slidemenu ul li.current-slide-tab-nav').animate({
			left: left
			}, speed).children().animate({
			width: width
			}, speed);
		 oldt = t;
	  },
	  customLink: '.slide-tab-nav', // The class used on the custom nav-elements
	  prevNext: true, // Previous/next buttons generation
	  auto: true, // Autostart
	  pause: '360000' // Time spent on each stable position
	  //fade: true,
	  //countinuous: true,
	  //numeric: true
   });
   */
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
   /*$("#featured").mouseenter(function() {
       $("#featured .info p").slideDown();
   }).mouseleave(function() {
       $("#featured .info p").slideUp();
   });*/
   // With headlines:
   /*
   $("#featured").mouseenter(function() {
		$("#featured .info").animate({"margin-top": -80, height: "80px"});
   }).mouseleave(function() {
	   $("#featured .info").animate({height: "25px", "margin-top": -25});
   });
   $("#featured .info").animate({height: "25px", "margin-top": -25});
   */
   
   // Without headlines:
   // Animation on mouseenter/mouseleave (move text field up / down)
   /*$("#featured").mouseenter(function() {
		$("#featured .info").animate({"margin-top": -80, height: "80px"});
   }).mouseleave(function() {
	   $("#featured .info").animate({height: "1px", "margin-top": 0});
   });
   $("#featured .info").animate({height: "1px", "margin-top": 0});
   
   
   $("#readmore").click(function() {
          $(".paragraph-readmore").slideToggle('fast');
   });
   // Done with animation
   */
   $("#readmore").click(function() {
          $(".paragraph-readmore").slideToggle('fast');
   });
   $(".paragraph-readmore").hide();
   //$(".info").hide();
});