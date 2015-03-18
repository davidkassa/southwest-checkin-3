var notice = (function() {
  var timeoutID = null;
  var delay = 10000;

  return {
    removeNoticesAfterDelay: function() {
      if (timeoutID) {
        window.clearTimeout(timeoutID);
      }

      timeoutID = window.setTimeout(function() {
        $('.js-notice').css('max-height', '0');
      }, delay)
    }
  }
})();

$(document).on("ready page:load", function() {
  notice.removeNoticesAfterDelay();
});
