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
                data: { person: model }
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
              console.log(model);
              $.ajax({ 
                url: peopleUrl, 
                type: 'post', 
                dataType: 'json',
                data: { person: model }
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
              'name': { editable: true },
              'function': { editable: true },
              'position': { type: 'integer', editable: false },
              'updated_at': { editable: false, type: 'date' }
            }
          }
        },
        serverPaging: true,
        serverFiltering: true,
        serverSorting: true,
        sort: { field: "position", dir: "asc" }
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
      mode: "popup"
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


    kGrid.kendoDraggable({
        filter: "tbody > tr",
        group: "gridGroup",
        hint: function(e) {
            return $('<div class="k-grid k-widget"><table><tbody><tr>' + e.html() + '</tr></tbody></table></div>');
        }
    });
    
    kGrid.kendoDropTarget({
        group: "gridGroup",
        drop: function(e) {
          var target;
          if( $(e.draggable.currentTarget).is('tr') )
            target = peopleDataSource.getByUid($(e.draggable.currentTarget).attr('data-uid'));
          else
            target = peopleDataSource.getByUid($(e.draggable.currentTarget).closest('tr').attr('data-uid'));

          e.draggable.hint.hide();
          var dest = $(document.elementFromPoint(e.clientX, e.clientY));
          
          if( dest.is('th') )
            return;

          if( dest.is('tr') )
            dest = peopleDataSource.getByUid( dest.attr('data-uid') );
          else
            dest = peopleDataSource.getByUid( dest.closest('tr').attr('data-uid') );

          reorderIds = [];
          kGrid.find('tr[role=row]').each( function(){
            var id = peopleDataSource.getByUid( $(this).attr('data-uid') ).id;
            if( id === dest.get('id') ){
              reorderIds.push( target.get('id') );
              reorderIds.push( dest.get('id') );
            }
            if( id !== target.get('id') && id !== dest.get('id') )
              reorderIds.push( id );
          });

          $.ajax({
            url: '/openeras/project_people/reorder',
            data: { pp_ids: reorderIds },
            type: 'post',
            dataType: 'json'
          }).done( function( response ){
            iox.flash.rails(response.flash);
            peopleDataSource.sort({ field: "position", dir: "asc" });
          });

        }
    });


}
