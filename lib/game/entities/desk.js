ig.module(
	'game.entities.desk'
)
.requires(
    'game.entities.item'
)
.defines(function(){

	EntityDesk = EntityItem.extend({
       
		animSheet: new ig.AnimationSheet( 'media/desk.png', 32, 16 ),	
		size: {x: 19, y: 4},
		offset: {x: 7, y: 9	},
        friction: {x:200,y:200},
        weight:50, 
        power:20,
        slow_down: 15,

		init: function( x, y, settings ) {
			this.parent( x, y, settings );
			this.addAnim( 'idle', 1, [0] );
			this.addAnim( 'move', 1, [0] );
		},       			

    });

});