$(function(){
  $("#student_range").on("change", function(el){
    $.ajax({
      url: "/status",
      method: "POST",
      data: {value: this.value}
    })
  });

  $("#lost").on("click",function(){
    $("#student_range").val(0).change();
  })
  $("#clear").on("click",function(){
    $("#student_range").val(100).change();
  })
});
