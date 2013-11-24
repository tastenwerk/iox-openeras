function ProjectModel( attrs, _parent ){

  var self = this;

  for( var i in attrs )
    this[i] = attrs[i];

  this.translation = ko.observable( this.translation );

  if( this.files.length > 0 ){
    this.files.forEach( function(file){
      file.description = ko.observable(file.description);
      file.copyright = ko.observable(file.copyright);
      file.thumb_url = ko.observable(file.thumb_url);
    });
  }
  this.files = ko.observableArray( this.files || [] );

  this.locale = ko.observable( this.locale );
  this.locale.subscribe( function( lang ){
    this.saveTranslation( true );
    //this.saveItem();
    lang = lang[0];
    var found = null;
    var last = null;
    this.translations.forEach( function(trans){
      last = trans;
      if( trans.locale === lang )
        found = trans;
    });
    if( found )
      this.translation( found );
    else
      this.translation({ locale: lang, title: last.title,
                        meta_keywords: last.meta_keywords,
                        meta_description: last.meta_description,
                        content: last.content });
    if( this.id && this.id > 0 )
      CKEDITOR.instances['translation[content]'].setData( this.translation().content );
  }, this);

  this._parent = _parent;

  this.author_names = ko.computed( function(){
    if( !this.authors || this.authors.length < 1 )
      return '';
    var names = [];
    this.authors.forEach( function( author ){
      names.push( author.name );
    });
    return names;
  }, this);

}

/**
 * remove an item
 */
ProjectModel.prototype.removeItem = function removeItem( item ){

}

/**
 * save an item or create it
 */
ProjectModel.prototype.saveItem = function saveItem( form ){
  var self = this;

  var url = '/openeras/projects';
  if( this.id && this.id > 0 )
    url += '/'+this.id;
  
  this.saveTranslation();

  var project_json = JSON.parse(ko.toJSON( this ));

  // TODO: labels sould be array of objects. but here it suddenly gets an array
  // of ids
  project_json.label_ids = project_json.labels;

  $.ajax({
    url: url,
    data: { project: project_json },
    type: ((this.id && this.id > 0) ? 'patch' : 'post'),
    dataType: 'json'
  }).done( function( response ){
    iox.flash.rails( response.flash );
    if( response.success ){
      if(!( this.id && this.id > 0 ) )
        setupContainer( response.item, $('.iox-content:visible') );
      $('#events-grid').data('kendoGrid').dataSource.read();
    }

  });

}

/**
 * bug fixes a problem between kendo and knockout js bindings
 *
ProjectModel.prototype.updateMultiselect = function updateMultiselect(){
  var multiSelect = $('#project-labels').data('kendoMultiSelect');
  multiSelect.value().forEach( function( itemId ){
    label_ids
  });
}*/

/**
 * save a translation back to the translations list
 */
ProjectModel.prototype.saveTranslation = function saveTranslation( xhr ){
  var self = this;
  
  if( this.id && this.id > 0 )
    this.translation().content = CKEDITOR.instances['translation[content]'].getData();

  var found
    , trans = {}
    , transJS = ko.toJS(this.translation());

  for( var i in transJS )
    if( typeof(transJS[i]) !== 'function' && i !== '_events' )
      trans[i] = transJS[i];

  this.translations.forEach( function(translation){
    if( translation.locale === trans.locale ){
      found = true;
      for( var i in trans )
        translation[i] = trans[i];
    }
  });

  if( !found )
    this.translations.push( trans );

  console.log(xhr, trans.content );
  if( xhr )
    $.ajax({
      url: '/openeras/projects/'+this.id+'/translation',
      data: { project: { translation: trans } },
      type: 'patch',
      dataType: 'json'
    }).done( function( response ){
      console.log('done');
      if( !response.success )
        iox.flash.rails( response.flash );
    });
}