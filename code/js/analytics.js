(function() {
  if (typeof SSN === "undefined" || SSN === null) {
    window.SSN = {};
  }

  SSN.Analytics = {
    settings: {
      yandex: '22464010'
    },
    trackEvent: function(event) {
      var yaCounter, yandexEvent;
      yandexEvent = event.category + '_' + event.action.replace(/\s+/g, '_');
      if (event.label) {
        yandexEvent += '_' + event.label;
      }
      yaCounter = window['yaCounter' + this.settings.yandex];
      return yaCounter.reachGoal(yandexEvent, {
        value: event.value || 0
      });
    }
  };

}).call(this);
