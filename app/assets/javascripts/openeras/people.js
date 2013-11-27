/**
 * people.js
 */


function setupPeopleGrid( item, $container ){

  var peopleUrl = '/openeras/projects/'+item.id+'/project_people';

  var peopleDataSource = new kendo.data.DataSource({
        transport: {
            read:  function( options ){

              $.ajax({
                url: peopleUrl,
                data: { sort: options.data.sort, filter: options.data.filter },
                dataType: 'json',
                type: 'get'
              }).done( function( response ){
                options.success( response )
              });
            },
            update: function( options ){
              var model = options.data.models[0];
              $.ajax({ 
                url: peopleUrl+'/'+model.id, 
                type: 'patch', 
                dataType: 'json',
                data: { person: options.data.models[0] }
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
                url: peopleUrl+'/'+model.id, 
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
                url: peopleUrl, 
                type: 'post', 
                dataType: 'json',
                data: { person: options.data.models[0] }
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
          total: 'total',
          data: 'items',
          parse: function( response ){
            response.items = response.items.map( function( p ){
              p.name = p.person.name;
              return p;
            });
            return response;
          },
          model: {
            id: 'id',
            fields: {
              'name': { editable: true, validation: { required: true } },
              'function': { editable: true },
              'updated_at': { editable: false }
            }
          }
        },
        serverPaging: true,
        serverFiltering: true,
        serverSorting: true,
        sort: { field: "person", dir: "asc" }
    });


  var kGrid = $("#people-grid").kendoGrid({
    columns: [
      { field: 'name', title: I18n.t('openeras.person.name')
      },
      { field: 'function', title: I18n.t('openeras.person.function')
      },
      { field: 'updated_at',
        title: 'aktualisiert',
        format: '{0:dd.MM.yyyy HH:mm}',
        width: 150,
        attributes: {
          style: 'text-align: right'
        }
      },
      { command:
        [ 'edit', 'destroy' ],
        width: 200
      }
    ],
    dataSource: peopleDataSource,
    height: $(window).height()-260,
    editable: {
      mode: "inline"
    },
    resizable: false,
    navigatable: true,
    sortable: true,
    pageable: {
      refresh: true,
      pageSize: 30,
      pageSizes: [10, 30, 50, 100]
    }
  });

  $container.find('.add-person').on('click', function(){
    kGrid.data('kendoGrid').addRow();
  });

}

function setupEventWin( $win, persistedRecord ){
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
        console.log( $win.find('.keep-open') )
        if( $win.find('.keep-open').is(':checked') )
          $win.unblock();
        else
          iox.Win.closeVisible();
      }
      iox.flash.rails( response.flash );
      iox.flash.urge( 2000 );
    });
  });

  if( persistedRecord )
    setupPricesGrid( $win );

  $win.find('.iox-tabs').ioxTabs({
    activate: function(){
      $win.center();
    }
  });
  $win.center();

}