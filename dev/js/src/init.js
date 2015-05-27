/*
  return {

    /**
     * Open match
     */
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

      // Already there
      if (element.classList.contains('action'))
	return true;

      // Create action buttons
      var ul = document.createElement('ul');
      ul.classList.add('action', 'right');

      element.appendChild(ul);
      element.classList.add('action');

      // Todo: Open in new frame

      // Add close button
      var close = document.createElement('li');
      close.appendChild(document.createElement('span'))
	.appendChild(document.createTextNode(loc.CLOSE));
      close.classList.add('close');
      close.setAttribute('title', loc.CLOSE);
      
      // Add info button
      var info = document.createElement('li');
      info.appendChild(document.createElement('span'))
	.appendChild(document.createTextNode(loc.SHOWINFO));
      info.classList.add('info');
      info.setAttribute('title', loc.SHOWINFO);

      var that = this;

      // Close match
      close.addEventListener('click', function (e) {
	e.halt();
	that.close()
      });

      // Add information, unless it already exists
      info.addEventListener('click', function (e) {
	e.halt();
	that.info().toggle();
      });

      ul.appendChild(close);
      ul.appendChild(info);

      return true;
    },


    /**
     * Close info view
     */
    close : function () {
      this._element.classList.remove('active');
      /* if (this._info !== undefined) {
       *   this._info.destroy();
       * };
       */
    },

    /**
     * Get match element.
     */
    element : function () {
      return this._element; // May be null
    }
  };
	*/
