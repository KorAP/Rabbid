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
	snippet === undefined ||
	snippet["in_doc_id"] === undefined ||
	snippet["para"] === undefined) {
      throw new Error("Missing parameters");
    };
    
    this.pageStart = parseInt(snippet["start_page"] || 0);
    this.pageEnd   = parseInt(snippet["end_page"] || 0);
    this.noBR      = snippet["nobr"] || undefined;
    this.content   = snippet["content"] || "";
    this.inDocID   = parseInt(snippet["in_doc_id"]);
    this.para      = parseInt(snippet["para"]);
    this.previous  = parseInt(snippet["previous"]);
    this.next      = parseInt(snippet["next"]);

    return this;
  },

  // Create extension object
  element : function () {
    if (this._element === undefined) {
    
      // Create new extension element
      var span = document.createElement('span');
      span.classList.add('ext');
      if (this.noBR !== undefined) {
	span.classList.add('nobr');
      };

      // Add text content
      span.appendChild(
	document.createTextNode(this.content)
      );

      this._element = span;
    };
    
    return this._element;
  }
});
