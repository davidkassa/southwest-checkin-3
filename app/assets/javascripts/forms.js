var forms = (function() {
  var selector = '.js-FieldGroup input';
  var focusClass = 'field--focus';

  return {
    /**
      Check if we are already focused
      on page load
    */
    checkCurrentElement: function() {
      if ($(document.activeElement).parents('.js-FieldGroup').addClass(focusClass)) {
        $(document.activeElement).parent().addClass(focusClass);
      }
    },

    highlightFormInput: function() {
      $(selector).focusin(function(event) {
        $(event.target).parent().addClass(focusClass);
      });

      $(selector).focusout(function(event) {
        $(event.target).parent().removeClass(focusClass);
      });
    }
  }
})();

$(document).on("ready page:load", function() {
  forms.checkCurrentElement();
  forms.highlightFormInput();
});
