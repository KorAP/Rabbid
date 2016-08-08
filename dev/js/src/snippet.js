define({
  create : function (snippet) {
    return Object.create(this)._init(snippet);
  },

  /**
   * Initialize Snippet.
   */
  _init : function (snippet) {

    // No valid snippet
    if (arguments.length < 1 ||
				snippet === null ||
				snippet === undefined) {
      throw new Error("Missing parameters");
    };

    if (snippet instanceof Node) {
      this._element = snippet;
      this.pageStart = parseInt(snippet.getAttribute('data-start-page') || 0);
			this.pageEnd = parseInt(snippet.getAttribute('data-end-page') || 0);
      this.noBR = snippet.classList.contains('nobr');
    }

    // Passed as object
    else {
      if (snippet["in_doc_id"] === undefined ||
					snippet["para"] === undefined) {
				throw new Error("Missing parameters");
      };
      this.pageStart = parseInt(snippet["start_page"] || 0);
      this.pageEnd   = parseInt(snippet["end_page"] || 0);
      this.noBR      = !!snippet["nobr"] ? true : false;

      // These may not be relevant unless there is a "nomore" flag for ext
      this.content   = snippet["content"] || "";
      this.inDocID   = parseInt(snippet["in_doc_id"]);
      this.para      = parseInt(snippet["para"]);
      this.previous  = parseInt(snippet["previous"]);
      this.next      = parseInt(snippet["next"]);
    };

		this._pbRE = /^\[\[PB=(\d+)\]\]$/;
    return this;
  },

	// Create extension object
  element : function () {
    if (this._element === undefined) {
			
      // Create new extension element
      var span = document.createElement('span');
      span.classList.add('ext');
      if (this.noBR === true) {
				span.classList.add('nobr');
      };

			var htmlArray = this._parseSnippet(this.content);
			
      // Add text content
			for (var i in htmlArray) {
				span.appendChild(
					htmlArray[i]
				);
			};

      this._element = span;
    };
    
    return this._element;
  },
	
	_parseSnippet : function (string) {
		var strArray = string.split(/(\[\[PB=\d+\]\])/);
		var nodeArray = [];
		var match;
		for (var i in strArray) {
			match = this._pbRE.exec(strArray[i]);
			if (match) {
				var pb = document.createElement('span');
				pb.setAttribute('class', 'pb');
				pb.setAttribute('data-after', match[1]);
				nodeArray.push(pb);
			}
			else {
				nodeArray.push(document.createTextNode(strArray[i]));
			};
		};
		return nodeArray;
	}
});

