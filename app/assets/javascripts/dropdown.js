var dropdown = (function() {
  var dropdownSelector = '.js-Dropdown';
  var toggleClass = 'js-Dropdown-toggle';
  var toggleSelector = '.' + toggleClass;
  var menuSelector = '.js-Dropdown-menu';
  var events = 'click';

  var attachToggleHandler = function(selector, events) {
    $(selector).on(events, function(e) {
      $(e.target).parents(dropdownSelector).toggleClass('js-open');
    });
  };

  var attachWindowClick = function() {
    $(document).click(function(e) {
      if ($(e.target).parents(toggleSelector).length === 0) {
        $(dropdownSelector).removeClass('js-open');
      }
    });
  }

  var detachToggleHandler = function(selector, events) {
    $(selector).off(events);
  };

  return {
    attachEvents: function() {
      attachToggleHandler(toggleSelector, events);
      attachWindowClick();
    },

    detachEvents: function() {
      detachToggleHandler(toggleSelector, events);
    }
  }
})();

$(document).on("ready page:load", function() {
  dropdown.attachEvents();
});
