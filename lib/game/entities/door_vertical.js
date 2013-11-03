ig.module(
	'game.entities.door_vertical'
)
.requires(
    'game.entities.door'
)
.defines(function(){

	EntityDoor_vertical = EntityDoor.extend({

		animSheet: new ig.AnimationSheet( 'media/door.png', 16, 24 ),	
		size: {x: 8, y: 24},
		offset: {x: 8, y: 0	}, 

		init: function( x, y, settings ) {
			this.parent( x, y, settings );
			this.addAnim( 'closed', 1, [2] );
			this.addAnim( 'open', 1, [3] );
			this.zIndex = this.pos.y;
			this.currentAnim = this.anims.closed;
		},

    });

});