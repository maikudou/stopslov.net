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
      regexp = '([^а-яА-Я\\-]|\\s)(' + _.map(this.get('stopWords'), function(word) {
        return word.replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/gi, "\\$&");
      }).join('|') + ')([^а-яА-Я\\-]|\\s)';
      this.set('regexp', new RegExp(regexp, 'gi'));
      return console.log(this.get('regexp'));
    },
    processContent: function(content) {
      content = content + ' ';
      content = content.replace(this.get('regexp'), '$1<span class="bStopWord">$2</span>$3');
      content = content.replace(/[\f\n\r]/gi, '<br/>');
      return this.output.update(content);
    }
  });

  SSN.Form = Backbone.View.extend({
    initialize: function() {
      this.setElement($('.bContent')[0]);
      this.$input = $('#mainInput', this.el);
      this.$menuItems = this.$el.find('.bContent__eMenuItem');
      this.$tabs = this.$el.find('.bContent__eTab');
      this.$listOpener = this.$el.find('#listOpener');
      return this.$wordList = this.$el.find('.bContent__eWordsList');
    },
    events: {
      'keyup #mainInput': 'changeContent',
      'click .bContent__eMenuItem': 'switchTab',
      'click #listOpener': 'toggleWords'
    },
    changeContent: function() {
      return this.trigger('change:content', this.$input.val());
    },
    switchTab: function(e) {
      var $target, index;
      $target = $(e.currentTarget);
      index = this.$menuItems.index($target);
      if ($target.hasClass('bContent__eMenuItem__mState_active')) {
        return false;
      }
      this.$menuItems.removeClass('bContent__eMenuItem__mState_active');
      $target.addClass('bContent__eMenuItem__mState_active');
      this.$tabs.removeClass('bContent__eTab__mState_active');
      this.$tabs.eq(index).addClass('bContent__eTab__mState_active');
      console.log(index);
      return false;
    },
    toggleWords: function(e) {
      var $target;
      $target = $(e.currentTarget);
      this.$wordList.text(SSNWords.join(', ')).toggleClass('bContent__eWordsList__mState_open');
      if (this.$wordList.hasClass('bContent__eWordsList__mState_open')) {
        this.$listOpener.text('Закрыть список стоп-слов');
      } else {
        this.$listOpener.text('Открыть список стоп-слов');
      }
      return false;
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
