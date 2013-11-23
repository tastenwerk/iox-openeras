// common functions for openeras

function ProjectModel( attrs, _parent ){

  var self = this;

  for( var i in attrs )
    this[i] = attrs[i];

  this.translation = ko.observable( this.translation );

  this.locale = ko.observable( this.locale );
  this.locale.subscribe( function( lang ){
    this.saveTranslation();
    this.saveItem();
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

  this.translation().content = CKEDITOR.instances['translation[content]'].getData();
  
  this.saveTranslation();

  $.ajax({ 
    url: url,
    data: { project: JSON.parse(ko.toJSON( this )) },
    type: ((this.id && this.id > 0) ? 'patch' : 'post'),
    dataType: 'json'
  }).done( function( response ){
    iox.flash.rails( response.flash );
    if( response.success ){
      if( this.id && this.id > 0 )
        ;
      else {
        self.id = response.item.id;
        $('.openeras-project-tabs:visible').find(' > ul > li.disabled').removeClass('disabled');
      }
    }

  });

}


/**
 * save a translation back to the translations list
 */
ProjectModel.prototype.saveTranslation = function saveTranslation( form ){
  var self = this;
  var found;
  this.translations.forEach( function(translation){
    if( translation.locale === self.translation().locale ){
      found = true;
      for( var i in self.translation() )
        translation[i] = self.translation()[i];
    }
  });

  if( !found )
    this.translations.push( ko.toJS( this.translation() ) );
}

/**
 * setup people selector
 */
function setupPeopleSelectors( $container ){

  var people = [];
  $container.find('.project-authors').select2({
    tags: people,
    tokenSeparators: [","]
  });

  $.getJSON( '/openeras/people', function( response ){
    response.items.forEach( function(item){
      people.push({ id: item.id, text: item.name });
    });
  });

}

function setupCKEDITOR( $elem ){

  var editor = CKEDITOR.replace( $elem.get(0), {
    removePlugins: 'elementspath',
    toolbar: [
      [ 'Cut', 'Copy', 'Paste', 'PasteText', 'PasteFromWord', '-', 'Undo', 'Redo' ],
      [ 'Bold', 'Italic', 'OrderedList', 'UnorderedList'],
      ['Source' ]
    ]
  });
 
}

function setupDatesGrid( item, $container ){
  var kGrid = $("#dates-grid").kendoGrid({
    columns: [
      { field: 'starts_at', title: 'von',
        format: '{0:dd.MM.yyyy HH:mm}',
        width: 120
      },
      { field: 'ends_at', title: 'bis',
        format: '{0:HH:mm}',
        width: 80 },
      { field: "venue_name",
        title: 'Spielort',
        sortable: false
      },
      { field: 'updated_at',
        title: 'aktualisiert',
        format: '{0:dd.MM.yyyy HH:mm}',
        width: 120,
        attributes: {
          style: 'text-align: right'
        }
      },
      { command:
        [
          { name: 'edit'
          },
          { name: 'delete'
          }
        ],
        width: 140
      }
    ],
    dataSource: {
      type: "json",
      transport: {
        read: {
          url: '/openeras/projects/'+item.id+'/events',
          dataType: 'json',
          data: function(){
            return {  };
          }
        }
      },
      schema: {
        total: 'total',
        data: function(response) {
          return response.items;
        },
        model: {
          fields: {
            id: { type: 'number' },
            published: { type: 'boolean' },
            title: { type: 'string' },
            venue_name: { type: 'string' },
            starts_at: { type: 'date' },
            ends_at: { type: 'date' },
            updater_name: { type: 'string' },
            updated_at: { type: 'date', width: 110 }
          }
        }
      },
      serverPaging: true,
      serverFiltering: true,
      serverSorting: true,
      sort: { field: "updated_at", dir: "desc" }
    },
    height: $(window).height()-200,
    selectable: "multiple",
    resizable: true,
    navigatable: true,
    sortable: true,
    pageable: {
      refresh: true,
      pageSize: 30,
      pageSizes: [10, 30, 50, 100]
    }
  });

}

function setupContainer( response, $container ){
  ko.cleanNode( $container.get(0) );
  var item = new ProjectModel( response );
  ko.applyBindings( item, $container.get(0) );
  $container.find('.iox-tabs').ioxTabs();
  setupPeopleSelectors( $container );
  setupDatesGrid( item, $container );
  setupCKEDITOR( $container.find('.editor') );
  $container.find('input[type=text]:visible:first').focus();
}