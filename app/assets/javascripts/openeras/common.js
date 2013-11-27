// common functions for openeras
//
//= require openeras/project_model
//= require openeras/projects
//= require openeras/events
//= require openeras/people
//
//= require 3rdparty/jquery.ui.widget
//= require 3rdparty/jquery.iframe-transport
//= require 3rdparty/jquery.fileupload
//
//= require iox/iox.positionImg


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
    setupPeopleGrid( item, $container );
    setupCKEDITOR( $container.find('.editor') );
    setupFileUpload( item, $container );

    $container.find('#project-age').kendoNumericTextBox({
      format: "# Jahren"
    });

    $container.find('#project-duration').kendoNumericTextBox({
      format: "# Minuten"
    });

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