ig.module(
	'game.entities.kitchen_cabinet'
)
.requires(
    'game.entities.item'
)
.defines(function(){

	EntityKitchen_cabinet = EntityItem.extend({
       
       	collides: ig.Entity.COLLIDES.FIXED,
		animSheet: new ig.AnimationSheet( 'media/kitchen.png', 16, 16 ),	
		size: {x: 16, y: 3},
		offset: {x: 0, y: 13},
        
		init: function( x, y, settings ) {
			this.parent( x, y, settings );
			this.addAnim( 'idle', 1, [12] );
		}		

    });

});