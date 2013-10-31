(function() {
  window.SSN = {};

  window.app = {};

  SSN.App = Backbone.Model.extend({
    defaults: {
      stopWords: window.SSNWords,
      regexp: /(?:)/
    },
    initialize: function() {
      this.form = new SSN.Form({
        model: this
      });
      this.output = new SSN.Output();
      this.form.model = this;
      if (localStorage.getItem('userStopWords') != null) {
        this.set('stopWords', JSON.parse(localStorage.getItem('userStopWords')));
      }
      this.buildRegexp();
      this.listenTo(this.form, 'change:content', this.processContent);
      this.listenTo(this.form, 'change:stopWords', this.changeWords);
      return this.on('change:stopWords', this.save);
    },
    buildRegexp: function() {
      var regexp;
      regexp = '([^а-яА-Я\\-]|\\s|\\r|\\n|\\b)(' + _.map(this.get('stopWords'), function(word) {
        return word.replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/gi, "\\$&");
      }).join('|') + ')([^а-яА-Я\\-]|\\s)';
      this.set('regexp', new RegExp(regexp, 'gi'));
      return console.log(this.get('regexp'));
    },
    changeWords: function(changeStack) {
      console.log(changeStack);
      if (changeStack.removed != null) {
        this.excludeWords(changeStack.removed);
      }
      if (changeStack.added != null) {
        return this.includeWords(changeStack.added);
      }
    },
    includeWords: function(words) {
      if (_.isString(words) || _.isArray(words)) {
        this.set('stopWords', _.union(this.get('stopWords'), words));
        return this.buildRegexp();
      }
    },
    excludeWords: function(words) {
      if (_.isString(words) || _.isArray(words)) {
        this.set('stopWords', _.difference(this.get('stopWords'), words));
        return this.buildRegexp();
      }
    },
    processContent: function(content) {
      content = ' ' + content + ' ';
      content = content.replace(/[\f\n\r]/gi, '$& ');
      content = content.replace(this.get('regexp'), '$1<span class="bStopWord">$2</span>$3');
      content = content.replace(/([\f\n\r]) /gi, '$&');
      content = content.replace(/[\f\n\r]/gi, '<br/>');
      return this.output.update(content);
    },
    save: function() {
      return localStorage.setItem('userStopWords', JSON.stringify(this.get('stopWords')));
    }
  });

  SSN.Form = Backbone.View.extend({
    initialize: function() {
      this.setElement($('.bContent')[0]);
      this.$input = $('#mainInput', this.el);
      this.$menuItems = this.$el.find('.bContent__eMenuItem');
      this.$tabs = this.$el.find('.bContent__eTab');
      this.$listOpener = this.$el.find('#listOpener');
      this.$wordList = this.$el.find('.bContent__eWordsList');
      this.listenTo(this.model, 'change:stopWords', this.renderWords);
      return this.listenTo(this.model, 'change:regexp', this.changeContent);
    },
    events: {
      'keyup #mainInput': 'changeContent',
      'click .bContent__eMenuItem': 'switchTab',
      'click #listOpener': 'toggleWords',
      'click .jsWord': 'removeWord'
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
      this.renderWords();
      this.$wordList.toggleClass('bContent__eWordsList__mState_open');
      if (this.$wordList.hasClass('bContent__eWordsList__mState_open')) {
        this.$listOpener.text('Закрыть список стоп-слов');
      } else {
        this.$listOpener.text('Открыть список стоп-слов');
      }
      return false;
    },
    renderWords: function() {
      var words;
      words = _.map(this.model.get('stopWords'), function(word) {
        return "<span class=\"bContent__eWordsListItem jsWord\">" + word + "</span>";
      });
      this.$wordList.html(words.join(', ') + '<input type="text" placeholder="+" class="bContent__eWordsListInput jsWordAdd">');
      return $('.jsWordAdd').unbind('change').bind('change', _.bind(this.addWord, this));
    },
    addWord: function(e) {
      var newWord;
      newWord = $(e.currentTarget).val().replace(/^\s\s*/, '').replace(/\s\s*$/, '');
      newWord = newWord.slice(0, 1).toUpperCase() + newWord.slice(1).toLowerCase();
      if (newWord.length > 0) {
        this.trigger('change:stopWords', {
          added: [newWord]
        });
      }
      return $(e.currentTarget).val('');
    },
    removeWord: function(e) {
      var _this = this;
      $(e.currentTarget).css('transform', 'scaleX(0)');
      return setTimeout(function() {
        return _this.trigger('change:stopWords', {
          removed: [$(e.currentTarget).text()]
        });
      }, 500);
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
    return window.app = new SSN.App();
  });

}).call(this);
