function setBackground(value){
  $("#instructor_main h1").html(value);
  var red = Math.round(((100 - value) / 100) * 255);
  var green = Math.round((value / 100) * 255);
  $("body").css("background", "rgb(" + red + ", " + green + ", 0)");
}

$(function(){
  var socket = new WebSocket("ws://localhost:4567/socket");
  socket.onmessage = function(message){
    setBackground(message.data);
  };
});
