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

  $.ajax({
    url: '/openeras/projects/'+item.id,
    type: 'delete',
    dataType: 'json'
  }).done( function(json){
    iox.flash.rails(json.flash);
    dataSource = $('#events-grid').data('kendoGrid').dataSource;
    if( json.success ){
      dataSource.remove( dataSource.get( item.id ) );
      iox.switchContent('back');
    }
  }).fail( function(json){
    iox.flash.rails(json.flash);
  });

}

/**
 * publish/unpublish this item
 */
ProjectModel.prototype.publishItem = function publishItem( item, e ){
  $elem = $(e.target).hasClass('publish-button') ? $(e.target) : $(e.target).find('.publish-button');
  publishProject.call( $elem, item, true );
}

ProjectModel.prototype.selectItem = function selectItem( kGrid, $row, item, next ){

  if( item ){
    item = item.toJSON();
    item.id = kGrid.dataItem( $row ).id;
    setupProjectForm( item, $('.iox-content:visible') );
    console.log( $row );
    kGrid.clearSelection();
    kGrid.select( $row );
  }
  else
    if( next )
      iox.flash.notice('Ende erreicht');
    else
      iox.flash.notice('Anfang erreicht');

}
/**
 * loads next item from underlying grid
 */
ProjectModel.prototype.loadNextItem = function loadNextItem( item, e ){
  e.preventDefault();
  var self = this;
  var kGrid = $('#events-grid').data('kendoGrid');
  var $row = kGrid.select().next('tr[role=row]');
  var nextItem = kGrid.dataItem( $row );
  // try loading next page if there are more pages
  if( !nextItem && kGrid.dataSource.page() < kGrid.dataSource.totalPages() ){
    kGrid.dataSource.page( kGrid.dataSource.page()+1);
    kGrid.dataSource.fetch( function(){
      setTimeout( function(){
        $row = $('#events-grid').find('tr[role=row]:first');
        nextItem = kGrid.dataItem( $row );
        self.selectItem( kGrid, $row, nextItem, true)
      }, 50);
    })
  } else
    self.selectItem( kGrid, $row, nextItem, true)
}

/**
 * loads previous item from underlying grid
 */
ProjectModel.prototype.loadPrevItem = function loadPrevItem( item, e ){
  e.preventDefault();
  var self = this;
  var kGrid = $('#events-grid').data('kendoGrid');
  var $row = kGrid.select().prev('tr[role=row]');
  var prevItem = kGrid.dataItem( $row );
  // try loading next page if there are more pages
  if( !prevItem && kGrid.dataSource.page()-1 > 0 ){
    kGrid.dataSource.page( kGrid.dataSource.page()-1);
    kGrid.dataSource.fetch( function(){
      setTimeout( function(){
        $row = $('#events-grid').find('tr[role=row]:last');
        prevItem = kGrid.dataItem( $row );
        self.selectItem( kGrid, $row, prevItem )
      }, 50);
    })
  } else
    self.selectItem( kGrid, $row, prevItem )
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
        setupProjectForm( response.item, $('.iox-content:visible') );
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