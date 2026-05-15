ig.module(
	'game.entities.bookstand'
)
.requires(
    'game.entities.item'
)
.defines(function(){

	EntityBookstand = EntityItem.extend({

		animSheet: new ig.AnimationSheet( 'media/bookstand.png', 16, 16 ),	
		size: {x: 16, y: 3},
		offset: {x: 0, y: 14},
        friction: {x:400,y:400},   

		init: function( x, y, settings ) {
			this.parent( x, y, settings );
			this.addAnim( 'idle', 1, [0] );
			this.addAnim( 'move', 1, [0] );
		},

    });

});