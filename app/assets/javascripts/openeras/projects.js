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

  $(document).on('click', '.publish-button', function(){
    var $elem = $(this);
    var node = kGrid.data('kendoGrid').dataItem( $(this).closest('tr').get(0) );
    node.published = !node.published;
    $.ajax({ url: '/openeras/projects/'+node.id+'/publish?publish='+(node.published ? 'true' : 'false'),
             type: 'put',
             dataType: 'json',
             data: { publish: $(this).hasClass('on') },
             success: function( data ){
               iox.flash.rails( data.flash );
               if( data.success )
                if( data.item.published )
                  $elem.addClass('icon-ok-sign').removeClass('icon-ban-circle');
                else
                  $elem.removeClass('icon-ok-sign').addClass('icon-ban-circle');
             }
    });
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
          setupContainer( response, $container );
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