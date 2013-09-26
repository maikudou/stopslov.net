(function() {
  window.SSN = {};

  window.app = {};

  SSN.App = Backbone.Model.extend({
    defaults: {
      stopWords: window.SSNWords,
      regexp: /(?:)/
    },
    initialize: function() {
      this.form = new SSN.Form();
      this.output = new SSN.Output();
      this.buildRegexp();
      return this.listenTo(this.form, 'change:content', this.processContent);
    },
    buildRegexp: function() {
      var regexp;
      regexp = '(\\s?' + _.map(this.get('stopWords'), function(word) {
        return word.replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/gi, "\\$&");
      }).join('\\s|\\s?') + '\\s)';
      this.set('regexp', new RegExp(regexp, 'gi'));
      return console.log(this.get('regexp'));
    },
    processContent: function(content) {
      content = content.replace(this.get('regexp'), '<span class="bStopWord">$1</span>');
      content = content.replace(/[\f\n\r]/gi, '<br/>');
      return this.output.update(content);
    }
  });

  SSN.Form = Backbone.View.extend({
    initialize: function() {
      this.setElement($('#mainForm')[0]);
      return this.$input = $('#mainInput', this.el);
    },
    events: {
      'keyup #mainInput': 'changeContent'
    },
    changeContent: function() {
      return this.trigger('change:content', this.$input.val());
    }
  });

  SSN.Output = Backbone.View.extend({
    initialize: function() {
      return this.setElement($('.bContent__eOutputText')[0]);
    },
    events: {
      'keyup #mainInput': 'processContent'
    },
    update: function(content) {
      return this.$el.html(content);
    }
  });

  $(function() {
    var app;
    return app = new SSN.App();
  });

}).call(this);
