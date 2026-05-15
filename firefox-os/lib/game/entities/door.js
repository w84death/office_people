ig.module(
	'game.entities.door'
)
.requires(
    'impact.entity'
)
.defines(function(){

	EntityDoor = ig.Entity.extend({

        type: ig.Entity.TYPE.B,
        checkAgainst: ig.Entity.TYPE.A,
        collides: ig.Entity.COLLIDES.NONE,
		animSheet: new ig.AnimationSheet( 'media/door.png', 16, 19 ),	
		size: {x: 16, y: 16},
		offset: {x: 0, y: 0	},
        friction: {x:100,y:100},
        open: false, 
        vertical: false,   

		init: function( x, y, settings ) {
			this.parent( x, y, settings );
			this.addAnim( 'closed', 1, [0] );
			this.addAnim( 'open', 1, [1] );
			this.zIndex = this.pos.y;
			this.currentAnim = this.anims.closed;
		},       			

		check: function( other ) {                                   
            this.open = true;
        },

		update: function() {			
			this.parent();
			if(this.open){
				this.currentAnim = this.anims.open;
				this.open = false;
			}else{
				this.currentAnim = this.anims.closed;
			}
		}

    });

});