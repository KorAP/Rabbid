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
    }

    // Match defined as a node
    else if (match instanceof Node) {
      this._element  = match;
      
      // Circular reference !!
      match["_match"] = this;
      
      this.ID       = parseInt(match.getAttribute('data-id')),
      this.para     = parseInt(match.getAttribute('data-para'));
      this.marks    = match.getAttribute('data-marks');

      this.marked   = match.classList.contains('marked');
      this.leftExt  = parseInt(match.getAttribute('data-left-ext')  || '0');
      this.rightExt = parseInt(match.getAttribute('data-right-ext') || '0');
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

    var ext = this._element.getElementsByClassName('extend');
    // Extend snippet
    for (var i = 0; i < ext.length; i++) {
      ext[i].addEventListener('click', function (e) {
	var element = this;
	var para = that.para;
	var before = true;
	if (this.classList.contains('left')) {
	  that.incrLeftExt();
	  para -= that.leftExt;
	}
	else {
	  that.incrRightExt();
	  para += that.rightExt;
	  before = false;
	};

	// Retrieve extension from system
	that.getJSON('/corpus/' + that.ID + '/' + para, function (obj) {

	  var span = document.createElement('span');
	  span.classList.add('ext');
	  if (obj["nobr"] !== undefined) {
	    span.classList.add('nobr');
	  };

	  span.appendChild(
	    document.createTextNode(obj.content)
	  );

	  // Prepend snippet
	  if (before) {
	    element.parentNode.insertBefore(
	      span,
	      element.nextSibling
	    );

	    if (obj['previous'] === undefined)
	      element.parentNode.removeChild(element);
	  }

	  // Append snippet
	  else {
	    element.parentNode.insertBefore(
	      span,
	      element
	    );

	    if (obj['next'] === undefined)
	      element.parentNode.removeChild(element);
	  }
	});
      });
    };
    
    return this;
  },

  incrLeftExt : function () {
    this.leftExt++;
    this._element.setAttribute('data-left-ext', this.leftExt);
  },

  incrRightExt : function () {
    this.rightExt++;
    this._element.setAttribute('data-right-ext', this.rightExt);
  },

  decrLeftExt : function () {
    this.leftExt--;
    this._element.setAttribute('data-left-ext', this.leftExt);
  },

  decrRightExt : function () {
    this.rightExt--;
    this._element.setAttribute('data-right-ext', this.rightExt);
  },

  open : function () {
    
    // Add actions unless it's already activated
    var element = this._element;

    // There is an element to open
    if (this._element === undefined || this._element === null)
      return false;
    
    // The element is already opened
    if (element.classList.contains('active'))
      return false;
      
    // Add active class to element
    element.classList.add('active');

    return true;
  },

  close : function () {
    this._element.classList.remove('active');
    /* if (this._info !== undefined) {
     *   this._info.destroy();
     * };
     */
  },

  store : function () {
    var that = this;
    this.sendJSON(
      '/corpus/' + this.ID + '/' + this.para,
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
	  console.log(this.status, this.statusText);
      }
    };
    req.ontimeout = function () {
      console.log('Request Timeout');
    };
    req.send();
  }
});
