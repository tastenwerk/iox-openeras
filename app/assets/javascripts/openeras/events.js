function setupProjectFileForm( $win ){
  $win.find('form').on('submit', function(e){
    e.preventDefault();
    $.ajax({
      url: $(this).attr('action'),
      data: $(this).serializeArray(),
      dataType: 'json',
      type: 'patch'
    }).done( function( response ){
      if( response.success ){
        var project = ko.dataFor( $('.iox-content:visible').get(0) );
        project.files().forEach( function(file){
          console.log('file', file);
          if( file.id === response.item.id ){
            file.description( response.item.description );
            file.copyright( response.item.copyright );
            file.thumb_url( response.item.thumb_url );
          }
          console.log( file, file.copyright, file.description );
        });
        $win.data('ioxWin').close();
      }
      iox.flash.rails( response.flash );
    });
  })
}

function removeProjectFile( item, e ){
  $.ajax({
    url: '/openeras/files/'+item.id,
    type: 'delete',
    dataType: 'json'
  }).done( function( response ){
    var project = ko.dataFor( $('.iox-content:visible').get(0) );
    if( response.success )
      project.files.remove( item );
    iox.flash.rails( response.flash );
  });
}

function setupEventWin( $win, persistedRecord ){
  $win.find('.iox-tabs').ioxTabs();
  $win.find('.datetime').kendoDateTimePicker({
    format: 'yyyy-MM-dd HH:mm',
    dateFormat: "dd. MM. yyyy",
    timeFormat: "HH:mm",
    change: function( e ){
      if( this.element.attr('id') === 'event_starts_at' ){
        var endsAt = $win.find('#event_ends_at');
        if( moment( this.value() ) >= moment( endsAt.val() ) )
          endsAt.data('kendoDateTimePicker').value( moment( this.value() ).add('h',2).toDate() );
      } else {
        var startsAt = $win.find('#event_starts_at');
        if( startsAt.data('kendoDateTimePicker').value() >= this.value() )
          this.value( moment( startsAt.data('kendoDateTimePicker').value() ).add('h',2).toDate() );
      }
    }
  }).on('click', function(){
    $(this).data('kendoDateTimePicker').open();
  });

  $win.find('#event_event_type').select2({
    tags: openeras.event_types,
    tokenSeparators: [","]
  });

  $win.find('#event_venue_id').kendoComboBox({
    placeholder: "Spielort wählen",
    dataTextField: "name",
    dataValueField: "id",
    filter: "contains",
    autoBind: false,
    minLength: 1,
    dataSource: {
      type: "json",
      serverFiltering: true,
      transport: {
        read: function( options ){
          $.getJSON( '/openeras/venues', function( response ){
            options.success( response.items );
          });
        }
      }
    }
  });
  $win.find('.new-venue').on('click', function(e){
    e.preventDefault();
    var comboBox = $('#event_venue_id').data('kendoComboBox');
    new iox.Win({
      prompt: {
        text: $(this).attr('data-prompt-text'),
        callback: function( name, $win ){
          $.ajax({
            url: '/openeras/venues',
            data: { venue: { name: name } },
            type: 'post',
            dataType: 'json'
          }).done( function( response ){
            if( response.success ){
              comboBox.dataSource.add({
                name: response.item.name,
                id: response.item.id
              });
              comboBox.select( function( dataItem ){
                return dataItem.id === response.item.id;
              });
              $('.venues-list-control [data-tree-role=refresh]').click();
            }
            iox.flash.rails( response.flash );
          });
        }
      }
    })
  });

  $win.find('#event_available_seats').kendoNumericTextBox({
    format: "# Sitze"
  });

  $win.find('form').on('submit', function(e){
    e.preventDefault();
    $.ajax({
      url: $(this).attr('action'),
      data: $(this).serializeArray(),
      type: $(this).attr('method'),
      dataType: 'json'
    }).done( function( response ){
      if( response.success ){
        $("#dates-grid").data('kendoGrid').dataSource.read();
        if( !$win.find('.keep-open').is('checked') )
          iox.Win.closeVisible();
      }
      iox.flash.rails( response.flash );
    });
  });

  if( persistedRecord )
    setupPricesGrid( $win );

}

function setupPricesGrid( $win ){

  var eventId = $('#prices-grid').attr('data-event-id');

  var pricesUrl = '/openeras/events/'+eventId+'/prices';

  var pricesDataSource = new kendo.data.DataSource({
        transport: {
            read:  function( options ){
              $.getJSON( pricesUrl, function( response ){
                options.success( response.items )
              });
            },
            update: function( options ){
              var model = options.data.models[0];
              $.ajax({ 
                url: pricesUrl+'/'+model.id, 
                type: 'patch', 
                dataType: 'json',
                data: { price: options.data.models[0] }
              }).done( function( response ){
                if( response.success )
                  options.success();
                else
                  options.error();
              });
            },
            destroy: function( options ){
              var model = options.data.models[0];
              $.ajax({ 
                url: pricesUrl+'/'+model.id, 
                type: 'delete', 
                dataType: 'json'
              }).done( function( response ){
                if( response.success )
                  options.success();
                else
                  options.error();
              });
            },
            create: function createCrew( options ){
              var model = options.data.models[0];
              $.ajax({ 
                url: pricesUrl, 
                type: 'post', 
                dataType: 'json',
                data: { price: options.data.models[0] }
              }).done( function( response ){
                if( response.success )
                  options.success();
                else
                  options.error();
              });
            }
        },
        batch: true,
        schema: {
          model: {
            id: 'id',
            fields: {
              'name': { editable: true },
              'note': { editable: true },
              'price': { editable: true, type: 'number' }
            }
          }
        }
    });


  var kGrid = $("#prices-grid").kendoGrid({
    columns: [
      { field: 'name', title: 'Bezeichnung'
      },
      { field: 'price', title: 'Preis',
        format: '{0:c}',
        width: 120
      },
      { field: 'note', title: 'Notiz'
      },
      { command:
        [ 'edit', 'destroy' ],
        width: 200
      }
    ],
    dataSource: pricesDataSource,
    height: 380,
    selectable: "multiple",
    editable: {
      mode: "inline"
    },
    resizable: true,
    navigatable: true,
    sortable: true,
    pageable: {
      refresh: true,
      pageSize: 30,
      pageSizes: [10, 30, 50, 100]
    }
  });

  $win.find('.add-price').on('click', function(){
    kGrid.data('kendoGrid').addRow();
  });

  $win.find('.apply-project').on('click', function(){
    if( confirm('Diese Liste auf alle Termine dieser Veranstaltung anwenden?') ){
      $.ajax({
        url: pricesUrl+'/apply_project',
        dataType: 'json',
        type: 'post'
      }).done( function( response ){
        alert(response.flash[0][1]);
      });
    }
  });

  $win.find('.make-template').on('click', function(){
    if( confirm('Diese Liste wirklich als Vorlage für zukünftige Termine verwenden?') ){
      $.ajax({
        url: pricesUrl+'/make_template',
        dataType: 'json',
        type: 'post'
      }).done( function( response ){
        alert(response.flash[0][1]);
      });
    }
  });

}