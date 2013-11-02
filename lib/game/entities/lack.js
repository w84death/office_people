ig.module(
	'game.entities.lack'
)
.requires(
    'game.entities.item'
)
.defines(function(){

	EntityLack = EntityItem.extend({

		animSheet: new ig.AnimationSheet( 'media/lack.png', 16, 16 ),	
		size: {x: 10, y: 7},
		offset: {x: 3, y: 9},
        friction: {x:200,y:200}, 
        can_take: true,
        weight:10, 
        power:8,
        slow_down:6,      

		init: function( x, y, settings ) {
			this.parent( x, y, settings );
			this.addAnim( 'idle', 1, [0] );
			this.addAnim( 'move', 1, [0] );
		},

    });

});