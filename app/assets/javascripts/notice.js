var noticeModule = (function() {
  return {
    delay: 4000,

    removeNoticesAfterDelay: function() {
      window.setTimeout(function() {
        $('.js-notice').css('max-height', '0');
      }, this.delay)
    }
  }
})();

noticeModule.removeNoticesAfterDelay();
