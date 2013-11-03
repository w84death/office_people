ig.module(
	'game.entities.kitchen_sink'
)
.requires(
    'game.entities.item_for_use'
)
.defines(function(){

	EntityKitchen_sink = EntityItem_for_use.extend({
       
		animSheet: new ig.AnimationSheet( 'media/kitchen.png', 16, 16 ),	
		size: {x: 16, y: 3},
		offset: {x: 0, y: 13},
        
		init: function( x, y, settings ) {
			this.parent( x, y, settings );
			this.addAnim( 'off', 1, [7] );
			this.addAnim( 'on', 0.5, [8,9,10,10,10,11,11] );
			this.currentAnim = this.anims.off;
		},

    });

});