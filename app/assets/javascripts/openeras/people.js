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