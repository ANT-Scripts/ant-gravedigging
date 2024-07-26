


CloseUi = function() {
    $("body").css({
        "display" : "none"
    });
}

window.addEventListener('message', function(event) {
    if (event.data.action == "ghostattack"){    
      $("body").css({
        "display" : "block"
      });    
      $(".background").css({
        'background-image': `url('img/${event.data.rand}.png')`,
      });   
      setTimeout(function() {
        CloseUi();     
        $.post(`https://${GetParentResourceName()}/close`);
      }, 4000);
    }
});

$(document).keydown(function (e) {
    if (e.keyCode == 27) { 
        CloseUi();     
        $.post(`https://${GetParentResourceName()}/close`);
    }
});