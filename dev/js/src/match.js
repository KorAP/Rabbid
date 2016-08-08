window.RabbidAPI = window.RabbidAPI || '';

/*
 * Todo: Pangerange doesn't adjust in case of shrinking.
 */

define(["snippet"], function (snippetClass) {
  return {
    create : function (match) {
      return Object.create(this)._init(match);
    },

    /**
     * Initialize match.
     */
    _init : function (match) {
      this._element = null;
      
      // No match defined
      if (arguments.length < 1 ||
	  match === null ||
	  match === undefined) {
	throw new Error('Missing parameters');
      };

      this._leftExt = new Array();
      this._rightExt = new Array();

      // Match defined as a node
      if (match instanceof Node) {
	this._element  = match;

	// Circular reference !!
	match["_match"] = this;

	// Parse data information
	this.ID       = parseInt(match.getAttribute('data-id')),
	this.para     = parseInt(match.getAttribute('data-para'));
	this.marks    = match.getAttribute('data-marks');

	this.marked   = match.classList.contains('marked');
	this.leftExt  = parseInt(match.getAttribute('data-left-ext')  || '0');
	this.rightExt = parseInt(match.getAttribute('data-right-ext') || '0');

	this._leftContext = this._element.getElementsByClassName('context-left')[0];
	this._rightContext = this._element.getElementsByClassName('context-right')[0];
	this._ref = this._element.getElementsByClassName('ref')[0];

	this.pageStart = parseInt(match.getAttribute('data-start-page') || '0');
	this.pageEnd   = parseInt(match.getAttribute('data-end-page')   || '0');
      };

      return this;
    },

    getLeftSnippet : function (idx) {
      return this._leftExt[idx];
    },

    getRightSnippet : function (idx) {
      return this._rightExt[idx];
    },
    
    createLeftButtons : function () {
      var button = document.createElement('span');
      button.classList.add('buttons');

      // Extend button
      var extend = button.appendChild(document.createElement('span'));
      extend.classList.add('extend', 'left');
      extend.addEventListener('click', this.extendLeft.bind(this));

      // Collapse button
      var collapse = button.appendChild(document.createElement('span'));
      collapse.classList.add('collapse', 'left');
      collapse.addEventListener('click', this.collapseLeft.bind(this));

      return button;
    },
    
    createRightButtons : function () {
      var button = document.createElement('span');
      button.classList.add('buttons');

      // Collapse button
      var collapse = button.appendChild(document.createElement('span'));
      collapse.classList.add('collapse', 'right');
      collapse.addEventListener('click', this.collapseRight.bind(this));

      // Extend button
      var extend = button.appendChild(document.createElement('span'));
      extend.classList.add('extend', 'right');
      extend.addEventListener('click', this.extendRight.bind(this));

      return button;
    },

    createActionButtons : function () {
      var button = document.createElement('span');
      button.classList.add('buttons');

      // Store button
      var store = button.appendChild(document.createElement('span'));
      store.classList.add('store');
      store.setAttribute('title', 'Speichern');
      store.appendChild(document.createElement('span')).appendChild(
	document.createTextNode('Speichern')
      );
      store.addEventListener('click', this.store.bind(this));

      // Close button
      var closeB = button.appendChild(document.createElement('span'));
      closeB.classList.add('close');
      closeB.setAttribute('title', 'Schließen');
      closeB.appendChild(document.createElement('span')).appendChild(
	document.createTextNode('Schließen')
      );
      closeB.addEventListener('click', this.close.bind(this));

      return button;
    },

    createPageRange : function () {
      var pageRange = document.createElement('span');
      pageRange.classList.add('pageRange');
      return pageRange;
    },

    /**
     * Get a specific paragraph from the API.
     */
    getSnippet : function (para, cb) {
      this.getJSON(
	window.RabbidAPI + '/corpus/' + this.ID + '/' + para,
	function (obj) {
	  if (obj !== null)
	    cb(snippetClass.create(obj));
	}
      )
    },

    /**
     * Extend the current match to the left.
     */
    extendLeft : function () {

      // Get a para some positions before the current one
      var para = this.para;
      para -= this.leftExt + 1;

      // If the para is out of the range, throw an error
      if (para < 0) {
	alertify.log("Keine weitere Erweiterungen", "note", 3000);
	return;
      };
      
      // Get the paragraph object
      this.getSnippet(para, function (snippet) {
	this.prependExtension(snippet);
	// Increment the left extension
	this.incrLeftExt();
      }.bind(this));

      return true;
    },

    /**
     * Extend the current match to the left.
     */
    extendRight : function () {
      // Get a para some positions before the current one
      var para = this.para;
      para += this.rightExt + 1;

      // Get the paragraph object
      this.getSnippet(para, function (snippet) {
	this.appendExtension(snippet);

	// Increment the left extension
	this.incrRightExt();
      }.bind(this));

      return true;
    },

    collapseLeft : function () {
      if (this._leftExt.length < 1)
	return false;

      var toRemove = this._leftExt.pop().element();

      toRemove.parentNode.removeChild(toRemove);
      this.decrLeftExt();
      return true;
      // this.updatePageRange()
    },

    collapseRight : function () {
      if (this._rightExt.length < 1)
	return false;

      var toRemove = this._rightExt.pop().element();

      toRemove.parentNode.removeChild(toRemove);
      this.decrRightExt();
      return true;
      // this.updatePageRange()
    },
    
    
    // Prepend extension
    prependExtension : function (ext) {
      this.open();
      
      var before;
      if (this._leftExt.length > 0)
	before = this._leftExt[this._leftExt.length-1].element();
      else
	before = this._leftExtButtons.nextSibling;
      
      this._leftExt.push(ext);

      // Prepend to the leftest extension
      before.parentNode.insertBefore(
	ext.element(),
	before
      );
    },

    // Prepend extension
    appendExtension : function (ext) {
      this.open();
      
      this._rightExt.push(ext);

      // Append to the rightest extension
      this._rightExtButtons.parentNode.insertBefore(
	ext.element(),
	this._rightExtButtons
      );
    },

    // Update page range
    updatePageRange : function () {
      var start, end;
      if (this._leftExt.length > 0)
	start = this._leftExt[this._leftExt.length-1].pageStart;
      else
	start = this.pageStart;

      if (this._rightExt.length > 0)
	end = this._rightExt[this._rightExt.length-1].pageEnd;
      else
	end = this.pageEnd;
    },
        
    incrLeftExt : function () {
      this.leftExt++;
      //    this._element.setAttribute('data-left-ext', this.leftExt);
    },

    incrRightExt : function () {
      this.rightExt++;
      //    this._element.setAttribute('data-right-ext', this.rightExt);
    },

    decrLeftExt : function () {
      this.leftExt--;
      //    this._element.setAttribute('data-left-ext', this.leftExt);
    },

    decrRightExt : function () {
      this.rightExt--;
      //    this._element.setAttribute('data-right-ext', this.rightExt);
    },

    /**
     * Set pagerange in reference view.
     */
    setPageRange : function () {

      if (this.pageStart !== 0 && this.pageEnd !== 0) {
	console.log('Set Pagerange to ' + this.pageStart + ' - ' + this.pageEnd);
	var data = '';
	if (this.pageStart === this.pageEnd) {
	  data = this.pageStart;
	}
	else {
	  data = this.pageStart + '-' + this.pageEnd;
	};

	this._pageRange.textContent = ' (S. ' + data + ') ';
	this._pageRange.style.display = 'inline';
      }
      else {
	this._pageRange.display = 'none';
      }
    },


    /**
     * Open the match.
     */
    open : function (e) {
      if (e !== undefined) e.halt();

      // Add actions unless it's already activated
      // There is no element to open
      if (this._element === undefined || this._element === null)
	return false;


      // The element is already opened
      if (this._element.classList.contains('active'))
	return false;
      
      // Add active class to element
      this._element.classList.add('active');

      // Add pageRange
      /*
      if (this._pageRange === undefined) {
	this._pageRange = document.createElement('span');
	this._pageRange.style.display = 'none';
	var ref = this._element.getElementsByClassName('ref');
	if (ref !== null && ref[0] !== null) {

	  // Insert into match view
	  ref[0].insertBefore(
	    this._pageRange,
	    ref[0].getElementsByTagName('span')[0]
	  );
	};

	// View page range possibly
	this.setPageRange();
      };
      */

      // Initialize match view, unless it is already initialized
      if (this._initialized === undefined) {

	var i;
	var leftExtSnippets = this._leftContext.getElementsByClassName("ext");
	var rightExtSnippets = this._rightContext.getElementsByClassName("ext");

	// Create snippet from snippetClass
	for (i = leftExtSnippets.length -1; i >= 0; i--) {
	  this._leftExt.push(
	    snippetClass.create(leftExtSnippets[i])
	  );
	};
	
	for (i = 0; i < rightExtSnippets.length; i++) {
	  this._rightExt.push(
	    snippetClass.create(rightExtSnippets[i])
	  );
	};
	
	// Add buttons
	this._leftExtButtons = this.createLeftButtons();
	this._leftContext.insertBefore(
	  this._leftExtButtons,
	  this._leftContext.firstChild
	);
	this._rightExtButtons = this._rightContext.appendChild(
	  this.createRightButtons()
	);
	var action = this._ref.appendChild(
	  this.createActionButtons()
	);
	
	// Add page range
	this._pageRangeElement = this._ref.insertBefore(
	  this.createPageRange(),
	  action
	);

	// The view is initialized
	this._initialized = true;
      };

      return true;
    },

    
    /**
     * Close the match.
     */
    close : function (e) {
      if (e !== undefined) e.halt();

      this._element.classList.remove('active');
      return true;
    },

    /**
     * Store the match.
     */
    store : function (e) {
      if (e !== undefined) e.halt();

      this.sendJSON(
	window.RabbidAPI + '/corpus/' + this.ID + '/' + this.para,
	{
	  "q" : top.query,
	  "rightExt" : this.rightExt,
	  "leftExt" : this.leftExt,
	  "marks" : this.marks
	}, function () {
	  alertify.log("Beleg gespeichert","success", 3000);
	  this.marked = true;
	  this._element.classList.add('marked');
	}.bind(this));
    },

    /**
     * Send a json object to endpoint.
     */
    sendJSON : function (url, obj, onload) {
      var str = JSON.stringify(obj);

      var req = new XMLHttpRequest();
      req.open("POST", url, true);
      req.setRequestHeader("Accept", "application/json");
      req.setRequestHeader('X-Requested-With', 'XMLHttpRequest'); 
      req.setRequestHeader("Connection", "close");
      req.setRequestHeader("Content-type", "application/json");
      req.setRequestHeader("Content-length", str.length);
      req.onreadystatechange = function () {
	if (this.readyState == 4) {
	  if (this.status === 200)
	    onload(JSON.parse(this.responseText));
	  else
	    console.log(this.status, this.statusText);
	}
      };
      req.ontimeout = function () {
	console.log('Request Timeout');
      };
      req.send(str);
    },

    /**
     * Get a json response from endpoint.
     */
    getJSON : function (url, onload) {
      var req = new XMLHttpRequest();

      req.open("GET", url, true);
      req.setRequestHeader("Accept", "application/json");
      req.setRequestHeader('X-Requested-With', 'XMLHttpRequest'); 
      req.onreadystatechange = function () {
	/*
	  States:
	  0 - unsent (prior to open)
	  1 - opened (prior to send)
	  2 - headers received
	  3 - loading (responseText has partial data)
	  4 - done
	*/
	if (this.readyState == 4) {
	  if (this.status === 200)
	    onload(JSON.parse(this.responseText));
	  else
	    alertify.log("Keine weitere Erweiterungen", "note", 3000);
	}
      };
      req.ontimeout = function () {
	console.log('Request Timeout');
      };
      req.send();
    }
  }
});