ig.module(
	'game.entities.water'
)
.requires(
    'game.entities.item'
)
.defines(function(){

	EntityWater = EntityItem.extend({

		animSheet: new ig.AnimationSheet( 'media/water.png', 16, 16 ),	
		size: {x: 6, y: 4},
		offset: {x: 5, y: 12},
        friction: {x:100,y:100}, 
        can_take: true,
        weight:40, 
        power:15,
        slow_down:10,

		init: function( x, y, settings ) {
			this.parent( x, y, settings );
			this.addAnim( 'idle', 0.3, [0,0,0,1,2,3] );
			this.addAnim( 'move', 1, [2] );
		},

    });

});