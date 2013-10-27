ig.module(
	'game.entities.plant'
)
.requires(
    'game.entities.item'
)
.defines(function(){

	EntityPlant = EntityItem.extend({

		animSheet: new ig.AnimationSheet( 'media/plant.png', 16, 16 ),	
		size: {x: 7, y: 8},
		offset: {x: 5, y: 8	},
        friction: {x:100,y:100}, 
        weight:20, 
        power:10,
        slow_down:7,      

		init: function( x, y, settings ) {
			this.parent( x, y, settings );
			this.addAnim( 'idle', 1, [0] );
			this.addAnim( 'move', 0.2, [0,1] );
		},

    });

});