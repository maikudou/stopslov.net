(function() {
  if (typeof SSN === "undefined" || SSN === null) {
    window.SSN = {};
  }

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
      var regexp, wordForms;
      wordForms = [];
      regexp = '([^а-яА-Я\\-]|\\s|\\r|\\n|\\b)(' + _.map(this.get('stopWords'), function(word) {
        var ending, replaceRegexp, variant, variantIndex, variantIndexSingle, variants, _i, _j, _k, _len, _len1, _len2, _ref, _ref1;
        if (variantIndex = SSN.dictionary[word.toLowerCase()]) {
          _ref = variantIndex.split('');
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            variantIndexSingle = _ref[_i];
            _ref1 = SSN.affixes[variantIndexSingle];
            for (ending in _ref1) {
              variants = _ref1[ending];
              if (ending === '0') {
                for (_j = 0, _len1 = variants.length; _j < _len1; _j++) {
                  variant = variants[_j];
                  regexp = new RegExp(variant[1] + '$', 'gi');
                  if (regexp.test(word)) {
                    wordForms.push(word + variant[0]);
                  }
                }
              } else {
                for (_k = 0, _len2 = variants.length; _k < _len2; _k++) {
                  variant = variants[_k];
                  regexp = new RegExp(variant[1] + '$', 'gi');
                  if (variant[0] !== '0' && regexp.test(word)) {
                    replaceRegexp = new RegExp(ending + '$', 'gi');
                    wordForms.push(word.replace(replaceRegexp, variant[0]));
                  }
                }
              }
            }
          }
        }
        return word.replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/gi, "\\$&");
      }).join('|') + wordForms.join('|') + ')([^а-яА-Я\\-]|\\s)';
      return this.set('regexp', new RegExp(regexp, 'gi'));
    },
    changeWords: function(changeStack) {
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
      content = content.replace(/\s+style=['\"][^'\"]+['\"]/gi, '');
      content = content.replace(/^(\s*)(\S+)(.*)/gi, '$2$3').replace(/(\.*)(\S+)(\s*)$/gi, '$1$2');
      content = content.replace(/(<span class="bStopWord">)([a-я ]*|[^<]*<span id="selectionBoundary[^<]+<\/span>[a-я ]*)(<\/span>)/gi, '$2');
      content = ' ' + content + ' ';
      content = content.replace(/[\f\n\r]/gi, '$& ');
      content = content.replace(this.get('regexp'), '$1<span class="bStopWord">$2</span>$3');
      content = content.replace(/([\f\n\r]) /gi, '$&');
      content = content.replace(/[\f\n\r]/gi, '<br/>');
      return this.output.update(content);
    },
    save: function() {
      return localStorage.setItem('userStopWords', JSON.stringify(this.get('stopWords')));
    },
    getTransitionEventsString: function() {
      if (typeof window.ontransitionend === 'object' && typeof window.onwebkittransitionend === 'object') {
        return 'transitionend oTransitionEnd otransitionend MSTransitionEnd';
      } else {
        return 'transitionend webkitTransitionEnd oTransitionEnd otransitionend MSTransitionEnd';
      }
    }
  });

  SSN.Form = Backbone.View.extend({
    initialize: function() {
      var _ref;
      this.setElement($('.bContent')[0]);
      this.$input = $('#mainInput', this.el);
      this.$menuItems = this.$el.find('.bContent__eMenuItem');
      this.$tabs = this.$el.find('.bContent__eTab');
      this.$listOpener = this.$el.find('#listOpener');
      this.$wordList = this.$el.find('.bContent__eWordsList');
      this.frameDoc = (_ref = this.$input.contentDocument) != null ? _ref : this.$input.document;
      this.listenTo(this.model, 'change:stopWords', this.renderWords);
      return this.listenTo(this.model, 'change:regexp', this.changeContent);
    },
    events: {
      'keyup #mainInput': 'changeContent',
      'click #listOpener': 'toggleWords',
      'click .jsWord': 'removeWord'
    },
    changeContent: function() {
      var selection;
      selection = rangy.saveSelection(selection);
      this.trigger('change:content', this.$input.html());
      return rangy.restoreSelection(selection);
    },
    selectTab: function(tabName) {
      var index;
      index = this.$tabs.closest('#' + tabName).index('.bContent__eTab');
      this.$tabs.removeClass('bContent__eTab__mState_active');
      this.$tabs.closest('#' + tabName).addClass('bContent__eTab__mState_active');
      this.$menuItems.removeClass('bContent__eMenuItem__mState_active');
      return this.$menuItems.eq(index).addClass('bContent__eMenuItem__mState_active');
    },
    toggleWords: function(e) {
      var $target;
      e.preventDefault();
      $target = $(e.currentTarget);
      this.renderWords();
      this.$wordList.toggleClass('bContent__eWordsList__mState_open');
      if (this.$wordList.hasClass('bContent__eWordsList__mState_open')) {
        this.$listOpener.text('Закрыть список стоп-слов');
        SSN.Analytics.trackEvent({
          category: 'UI',
          action: 'open',
          label: 'StopList'
        });
      } else {
        this.$listOpener.text('Открыть список стоп-слов');
        SSN.Analytics.trackEvent({
          category: 'UI',
          action: 'close',
          label: 'StopList'
        });
      }
      return e.preventDefault();
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
      $(e.currentTarget).val('');
      return SSN.Analytics.trackEvent({
        category: 'Words',
        action: 'add',
        value: newWord
      });
    },
    removeWord: function(e) {
      var $target,
        _this = this;
      e.preventDefault();
      $target = $(e.currentTarget);
      $target.addClass('mHide');
      $target.one(this.model.getTransitionEventsString(), function() {
        return _this.trigger('change:stopWords', {
          removed: [$target.text()]
        });
      });
      return SSN.Analytics.trackEvent({
        category: 'Words',
        action: 'remove',
        value: $target.text()
      });
    }
  });

  SSN.Output = Backbone.View.extend({
    initialize: function() {
      return this.setElement($('#mainInput')[0]);
    },
    update: function(content) {
      return this.$el.html(content);
    }
  });

  SSN.Router = Backbone.Router.extend({
    routes: {
      '': 'ssnForm',
      '/': 'ssnForm',
      'about/words/': 'aboutWords',
      'about/service/': 'aboutService'
    },
    ssnForm: function() {
      return app.form.selectTab('ssnForm');
    },
    aboutWords: function() {
      return app.form.selectTab('aboutWords');
    },
    aboutService: function() {
      return app.form.selectTab('aboutService');
    }
  });

  $(function() {
    return $.getJSON('dictionaries/ru_RU.aff.json', function(data) {
      SSN.affixes = data;
      return $.getJSON('dictionaries/ru_RU.dic.json', function(data) {
        SSN.dictionary = data;
        window.app = new SSN.App();
        window.router = new SSN.Router();
        return Backbone.history.start();
      });
    });
  });

}).call(this);
