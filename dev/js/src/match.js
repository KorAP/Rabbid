window.RabbidAPI = window.RabbidAPI || '';

/*
 * Todo: Pangerange doesn't adjust in case of shrinking.
 */

define({
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

      this.pageStart = parseInt(match.getAttribute('data-start-page') || '0');
      this.pageEnd   = parseInt(match.getAttribute('data-end-page')   || '0');
    };

    var that = this;

    // Close the match
    var close = this._element.getElementsByClassName('close');
    close[0].addEventListener('click', function (e) {
      that.close();
      e.halt();
    });

    // Save the snippet
    var store = this._element.getElementsByClassName('store');
    if (store.length > 0) {
      store[0].addEventListener('click', function (e) {
	that.store();
	e.halt();
      });
    };

    var coll = this._element.getElementsByClassName('collapse');
    // Collapse snippet
    for (var i = 0; i < coll.length; i++) {
      coll[i].addEventListener('click', function (e) {
	var element = this;

	// The button object
	var p = element.parentNode;

	// Was extended to the right
	if (this.classList.contains('left')) {
	  var nextObject = p.nextSibling;
	  if (nextObject.nodeType === 1 && nextObject.classList.contains('ext')) {
	    p.parentNode.removeChild(nextObject);
	    that.decrLeftExt();
	  };
	}

	// Was extended to the left
	else {
	  var previousObject = p.previousSibling;
	  if (previousObject.nodeType === 1 && previousObject.classList.contains('ext')) {
	    p.parentNode.removeChild(previousObject);
	    that.decrRightExt();
	  };
	};
      });
    };

    var ext = this._element.getElementsByClassName('extend');

    // Extend snippet
    for (var i = 0; i < ext.length; i++) {
      ext[i].addEventListener('click', function (e) {
	var element = this;
	var para = that.para;
	var before = true;

	if (this.classList.contains('left')) {
	  para -= (that.leftExt + 1);
	} else {
	  para += (that.rightExt + 1);
	  before = false;
	};

	if (para < 0) {
	  alertify.log("Keine weitere Erweiterungen", "note", 3000);
	  return;
	};

	// Retrieve extension from system
	that.getJSON(
	  window.RabbidAPI + '/corpus/' + that.ID + '/' + para,
	  function (obj) {

	    if (before) {
	      that.incrLeftExt();
	    }
	    else {
	      that.incrRightExt();
	    };

	    // Create new extension element
	    var span = document.createElement('span');
	    span.classList.add('ext');
	    if (obj["nobr"] !== undefined) {
	      span.classList.add('nobr');
	    };

	    // Readjust pagerange
	    if (obj["start_page"] !== undefined || obj["end_page"]  !== undefined) {
	      var sp = parseInt(obj["start_page"]);
	      var ep = parseInt(obj["end_page"]);
	      if (before && !that.pageStart || that.pageStart > sp) {
		that.pageStart = sp;
	      }
	      else if (!that.pageEnd || that.pageEnd < ep) {
		that.pageEnd = ep;
	      };
	      that.setPageRange();
	    };

	    // Add text content
	    span.appendChild(
	      document.createTextNode(obj.content)
	    );
	    
	    var p = element.parentNode;

	    // left extension - Prepend snippet
	    if (before) {
	      p.parentNode.insertBefore(
		span,
		p.nextSibling
	      );
	      
	      /*
		Todo: Make obj disabled
		if (obj['previous'] === undefined)
		element.parentNode.removeChild(element);
	      */
	    }

	    // Append snippet
	    else {
	      p.parentNode.insertBefore(
		span,
		p
	      );

	      /*
		Todo: Make obj disable
		if (obj['next'] === undefined)
		element.parentNode.removeChild(element);
	      */
	    }
	  });
      });
    };
    
    return this;
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
  open : function () {
    
    // Add actions unless it's already activated
    var element = this._element;

    // There is no element to open
    if (this._element === undefined || this._element === null)
      return false;
    
    // The element is already opened
    if (element.classList.contains('active'))
      return false;
      
    // Add active class to element
    element.classList.add('active');

    // Add pageRange
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

    return true;
  },

  /**
   * Close the match.
   */
  close : function () {
    this._element.classList.remove('active');
    return true;
    /* if (this._info !== undefined) {
     *   this._info.destroy();
     * };
     */
  },

  store : function () {
    var that = this;
    this.sendJSON(
      window.RabbidAPI + '/corpus/' + this.ID + '/' + this.para,
      {
	"q" : top.query,
	"rightExt" : this.rightExt,
	"leftExt" : this.leftExt,
	"marks" : this.marks
      }, function () {
	alertify.log("Beleg gespeichert","success",3000);
	that.marked = true;
	that._element.classList.add('marked');
      });
  },

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
});
