require(['lib/domReady', 'match'], function (domReady, matchClass) {

  // Don't let events bubble up
  if (Event.halt === undefined) {
    // Don't let events bubble up
    Event.prototype.halt = function () {
      this.stopPropagation();
      this.preventDefault();
    };
  };

  // Add toggleClass method similar to jquery
  HTMLElement.prototype.toggleClass = function (c1, c2) {
    var cl = this.classList;
    if (cl.contains(c1)) {
      cl.add(c2);
      cl.remove(c1);
    }
    else {
      cl.remove(c2);
      cl.add(c1);
    };
  };


  domReady(function () {
    var inactiveLi = document.querySelectorAll(
      '#search > ol > li:not(.active)'
    );
    var i = 0;
    for (i = 0; i < inactiveLi.length; i++) {
      inactiveLi[i].addEventListener('click', function (e) {
	if (this._match !== undefined) {
	  if (this._match.open())
	    e.halt();
	}
	else {
	  matchClass.create(this).open();
	};
      });
    };
  });
});
