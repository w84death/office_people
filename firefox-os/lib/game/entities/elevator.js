ig.module(
	'game.entities.elevator'
)
.requires(
    'impact.entity'
)
.defines(function(){

	EntityElevator = ig.Entity.extend({

        type: ig.Entity.TYPE.B,
        checkAgainst: ig.Entity.TYPE.A,
        collides: ig.Entity.COLLIDES.FIXED,
		animSheet: new ig.AnimationSheet( 'media/elevator.png', 16, 16 ),	
		size: {x: 16, y: 16},
        open: false,
        player_inside: false,

		init: function( x, y, settings ) {
			this.parent( x, y, settings );
			this.addAnim( 'closed', 1, [0] );		
			this.addAnim( 'opening', 0.5, [1,2,3] );
			this.addAnim( 'open', 1, [3] );
			this.addAnim( 'closing_width_player', 0.5, [4,5,6,7,8,9,10,11] );
			this.addAnim( 'closed_with_player', 1, [11] );			
			this.zIndex = this.pos.y;
			this.currentAnim = this.anims.closed;
		},       			

		check: function( other ) {
			if(this.open && other.player){
				this.player_inside = true;
				this.currentAnim = this.anims.closing_width_player.rewind();
				ig.game.levelClear();
            }
        },

		update: function() {			
			this.parent();

			if(ig.game.level_clear){
				this.open = true;
			}

			if(this.open){
				if(!this.player_inside){
					this.currentAnim = this.anims.opening;
					if(this.currentAnim.loopCount>0){
						this.currentAnim = this.anims.open;
					}
				}else{
					if(this.currentAnim.loopCount>0){
						this.currentAnim = this.anims.closed_with_player;
					}
				}

			}else{
				this.currentAnim = this.anims.closed;
			}
		}

    });

});