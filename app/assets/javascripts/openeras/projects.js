function publishProject( node, reload ){
  var $elem = $(this);
  node.published = !node.published;
  $.ajax({ url: '/openeras/projects/'+node.id+'/publish?publish='+(node.published ? 'true' : 'false'),
           type: 'patch',
           dataType: 'json',
           data: { publish: $(this).hasClass('on') },
           success: function( data ){
             iox.flash.rails( data.flash );
             if( data.success )
              if( data.item.published ){
                $elem.addClass('icon-ok-sign').removeClass('icon-ban-circle');
                if( reload )
                  $('#events-grid').data('kendoGrid').dataSource.read();
              }
              else
                $elem.removeClass('icon-ok-sign').addClass('icon-ban-circle');
           }
  });
}

function setupProjectsList( $kGrid ){

  function queryResults(e){
    e.preventDefault();
    $filter = new Array();
    $x = $('.query').val();
    if( lastSearch === $x )
      return;
    if($x)
      $filter.push({ field:"x", operator:"contains", value:$x});
    lastSearch = $x;
    $kGrid.data('kendoGrid').dataSource.filter($filter);
    if( $x.length > 0 )
      $('.iox-grid-header .clear-query').fadeIn();
    else
      $('.iox-grid-header .clear-query').fadeOut();
  }

  $(document).on('click', '.k-grid-content .publish-button', function( e ){
    var node = $kGrid.data('kendoGrid').dataItem( $(this).closest('tr').get(0) );
    publishProject.call( this, node );
  });

  /**
   * show new form above current grid
   *
   */
  $('.new-project.btn').on('click', function(e){
    e.preventDefault();
    iox.switchContent( 'next', function( $container ){
      $container.block();
      $.getJSON( '/openeras/projects/new?init_label_id='+selectedLabelId(),
        function( response ){
          setupProjectForm( response, $container );
          $container.unblock();
      });
    });
  })

  var newValue = 0;
  var lastSearch = '';
  
  $('#projects-query').on('keyup', function(e){
    if( e.keyCode === 27 ){
      $(this).val('');
      return queryResults(e);
    }
    newValue = (new Date()).getTime();
    setTimeout( function(){
      if( newValue > (new Date()).getTime()-510 )
        queryResults(e);
    }, 500);
  });

  $('#submit-projects-query').on('click', queryResults );

  $('.iox-grid-header .clear-query').on('click', function(e){
    $(this).hide();
    $('.query').val('').focus();
    queryResults(e);
  });

  $('.query').val('');

}

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
        });
        $win.data('ioxWin').close();
      }
      iox.flash.rails( response.flash );
    });
  });

  $win.find('.apply-file-settings-to-all').on('click', applyFileSettingsToAll);

  $win.find('.iox-tabs').ioxTabs({
    activate: function(){ $win.center(); }
  });

  $win.find('.crop-img').ioxPositionImg();

  $win.center();

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
