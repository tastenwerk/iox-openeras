// common functions for openeras

function ProjectModel( attrs, _parent ){

  for( var i in attrs )
    this[i] = attrs[i];

  this._parent = _parent;
  
}

/**
 * remove an item
 */
ProjectModel.prototype.removeItem = function removeItem( item ){
  _parent.remove( item );
}

/**
 * save an item or create it
 */
ProjectModel.prototype.saveItem = function saveItem( form ){
  
}