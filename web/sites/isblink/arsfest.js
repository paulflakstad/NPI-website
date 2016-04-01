function toggleVisibility(jqTarget) {
    jqTarget.attr("style", ($(window).width() > 1200) ? "" : "display:none");
}

$(document).ready( function() {
    $('head').append('<link rel="stylesheet" href="/arsfest.css" type="text/css" />');
    var link = $('<a>').appendTo('body');
    link.attr({
        'id':'party',
        'href':'http://thomas.npolar.no/party/'
    }).append('<img src="/partyposter.jpg" alt="">');
    toggleVisibility(link);
    $(window).resize( function() {
        toggleVisibility(link);
    });
    $('#party').hover(function() { $(this).addClass('revealed') });
});