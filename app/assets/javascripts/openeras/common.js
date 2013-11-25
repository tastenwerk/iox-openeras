// common functions for openeras
//
//= require openeras/project_model
//= require openeras/projects
//= require openeras/events
//
//= require 3rdparty/jquery.ui.widget
//= require 3rdparty/jquery.iframe-transport
//= require 3rdparty/jquery.fileupload


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

/**
 * setup labels
 */
function setupLabelsSelectors( $container ){

  var project = ko.dataFor( $container.get(0) );
  var values = project.labels.map( function(item){
    return { name: item.name, id: item.id };
  });

  $container.find('.project-labels').kendoMultiSelect({
      placeholder: 'Labels hinzufügen',
      dataTextField: 'name',
      dataValueField: 'id',
      autoBind: false,
      minLength: 1,
      dataSource: {
        type: "json",
        serverFiltering: true,
        transport: {
          read: function( options ){
            console.log(options);
            var q = '';
            if( options.data.filter.filters.length > 0 )
              q = options.data.filter.filters[0].value;
            $.getJSON( '/openeras/labels/projects?query='+q, function( response ){
              options.success( response.items );
            });
          }
        }
      },
      value: values,
      change: function( e ){
        var project = ko.dataFor( $container.get(0) );
        e.sender._dataItems.forEach( function( dataItem ){
          project.labels.push( dataItem )
        })
      }
  });


  $container.find('.new-label').on('click', function(e){
    e.preventDefault();
    var multiSelect = $('#project-labels').data('kendoMultiSelect');
    new iox.Win({
      prompt: {
        text: $(this).attr('data-prompt-text'),
        callback: function( name, $container ){
          $.ajax({
            url: '/openeras/labels',
            data: { name: name, type: 'Openeras::ProjectLabel' },
            type: 'post',
            dataType: 'json'
          }).done( function( response ){
            if( response.success ){
              multiSelect.dataSource.add({
                name: response.item.name,
                id: response.item.id
              });
              multiSelect.value( response.item.id );
              $('.labels-list-control [data-tree-role=refresh]').click();
            }
            iox.flash.rails( response.flash );
          });
        }
      }
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
        format: '{0:dd.MM.yyyy}',
        width: 120
      },
      { field: 'starts_at', title: 'von',
        format: '{0:HH:mm}',
        width: 60
      },
      { field: 'ends_at', title: 'bis',
        format: '{0:HH:mm}',
        width: 80
      },
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
          { name: 'editEvent',
            text: '<i class="icon-edit"></i>',
            click: function(e){
              var dataItem = this.dataItem($(e.currentTarget).closest("tr"));
              new iox.Win({
                url: '/openeras/events/'+dataItem.id+'/edit',
                completed: function($win){
                  setupEventWin( $win, true );
                },
                saveFormBtn: true,
                title: 'Termin bearbeiten'
              });
            }
          },
          { name: 'deleteEvent', text: '<i class="icon-remove"></i>',
            click: function(e){
              var dataItem = this.dataItem($(e.currentTarget).closest("tr"));
              $.ajax({
                url: '/openeras/events/'+ dataItem.id,
                type: 'delete',
                dataType: 'json'
              }).done( function(json){
                iox.flash.rails(json.flash);
                if( json.success )
                  kGrid.data('kendoGrid').removeRow( $(e.target).closest('tr') );
              }).fail( function(json){
                iox.flash.rails(json.flash);
              });
            }
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
    height: $(window).height()-240,
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

function setupFileUpload( item, $container ){

  $('#upload').fileupload({
    url: '/openeras/projects/'+item.id+'/files',
    processQueue: {
      action: 'validate',
      acceptFileTypes: /(\.|\/)(gif|jpe?g|png|pdf)$/i
    },
    dataType: 'json',
    formData: {
      "authenticity_token": $('input[name="authenticity_token"]:first').val()
    },
    dragover: function( e ){
      $(this).closest('.upload-container').addClass('drop-here');
    },
    drop: function( e, data ){
      $(this).closest('.upload-container').removeClass('drop-here');
    },
    done: function( e, data ){
      $(this).closest('.upload-container').removeClass('drop-here');
      var response = data._response.result;
      var file = response.item;
      file.description = ko.observable(file.description);
      file.copyright = ko.observable(file.copyright);
      file.thumb_url = ko.observable(file.thumb_url);
      item.files.push( file );
      setTimeout( function(){
        $('#files-progress .bar').css( 'width', 0 );
      }, 500 );
    },
    error: function( response, type, msg ){
      iox.flash.alert( JSON.parse(response.responseText).errors.file[0] );
    },
    progressall: function( e, data ){
      var progress = parseInt(data.loaded / data.total * 100, 10);
      $('#files-progress .bar').css( 'width', progress + '%' );
    }
  });

  $(document).off('click', applyFileSettingsToAll)
             .on('click', '.apply-file-settings-to-all', applyFileSettingsToAll);

}

function applyFileSettingsToAll( e ){
  $.ajax({
    url: '/openeras/projects/'+$(this).attr('data-project-id')+'/apply_file_settings',
    data: $(this).closest('form').serializeArray(),
    dataType: 'json',
    type: 'patch'
  }).done( function( response ){
    if( response.success )
      iox.Win.closeVisible();
    iox.flash.rails( response.flash );
  });
}

function setupProjectForm( response, $container ){
  ko.cleanNode( $container.get(0) );
  var item = new ProjectModel( response );
  ko.applyBindings( item, $container.get(0) );
  $container.find('.iox-tabs').ioxTabs();
  setupLabelsSelectors( $container );
  if( response.id && response.id > 0 ){
    setupPeopleSelectors( $container );
    setupDatesGrid( item, $container );
    setupCKEDITOR( $container.find('.editor') );
    setupFileUpload( item, $container );

    var page = $('#events-grid').data('kendoGrid').dataSource.page();
    var pageSize = $('#events-grid').data('kendoGrid').dataSource.pageSize();
    var total = $('#events-grid').data('kendoGrid').dataSource.total();
    var index = $('#events-grid').data('kendoGrid').dataSource.indexOf( $('#events-grid').data('kendoGrid').dataSource.get( item.id ) );
    $container.find('.item-num').text( (page-1)*pageSize + index + 1 );
    $container.find('.items-total').text( $('#events-grid').data('kendoGrid').dataSource.total() );

  }
  $container.find('input[type=text]:visible:first').focus();
}

function filterProjectsByLabel( item, e ){
  $('#projects-query').val( item.id+'#'+item.name() )
  $('#submit-projects-query').click();
  if( !$('#events-grid').is(':visible') )
    iox.switchContent('back');
  item.markItem( item, e );
}

function filterProjectsByVenue( item, e ){
  $('#projects-query').val( item.id+'@'+item.name() )
  $('#submit-projects-query').click();
  if( !$('#events-grid').is(':visible') )
    iox.switchContent('back');
  item.markItem( item, e );
}