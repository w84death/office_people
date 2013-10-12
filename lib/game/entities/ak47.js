ig.module(
	'game.entities.ak47'
)
.requires(
    'impact.entity'
)
.defines(function(){

	EntityAk47 = ig.Entity.extend({

        type: ig.Entity.TYPE.NONE,
        checkAgainst: ig.Entity.TYPE.A,
        collides: ig.Entity.COLLIDES.LITE,
		animSheet: new ig.AnimationSheet( 'media/ak47.png', 16, 16 ),	
		size: {x: 12, y:4},
		offset: {x: 2, y: 7	},
        friction: {x:100,y:100},
        ammo: 120,
        owner: false,
        shootTimer: new ig.Timer(),
        shootTimerDelay: 0.1,

		init: function( x, y, settings ) {
			this.parent( x, y, settings );

			this.addAnim( 'idle', 1, [0] );
			this.addAnim( 'run', 0.1, [1,0] );
			this.addAnim( 'fire', 0.1, [2,3,0] );			
		},       
		
		take: function( other ){
			other.inHand = this;
            this.owner = other;
            this.collides = ig.Entity.COLLIDES.NONE;
            this.zIndex = other.zIndex + 1;
            ig.game.sortEntitiesDeferred();
		},

		drop: function( other ){
			if(other.flip){
				this.pos.x -= 12;
			}else{
				this.pos.x += 10;
			}
			other.inHand = false;
            this.owner = false;
            this.collides = ig.Entity.COLLIDES.LITE;
            
		},

		use: function(){
			if(this.owner.ammo > 0){
				if(this.shootTimer.delta() > this.shootTimerDelay){
					this.shootTimer.reset();	
					if(this.owner.flip){
						ig.game.spawnEntity( 
							EntityBullet, 
							this.pos.x-10, 
							this.pos.y, 
							{flip:this.owner.flip} 
						);
					}else{
						ig.game.spawnEntity( 
							EntityBullet, 
							this.pos.x+12, 
							this.pos.y, 
							{flip:this.owner.flip} 
						);
					}		
					
					this.owner.ammo -= 1;
				}
			}
		},

		check: function( other ) {                          
            if( other.canPickUp && !other.inHand){
                this.take( other );
            }
        },

		update: function() {			
			this.parent();			
			if(this.owner){
				if( this.owner.vel.x == 0 && this.owner.vel.y == 0 ) {				
					if(this.shootTimer.delta() < this.shootTimerDelay){
					    this.currentAnim = this.anims.fire;
					}else{
					    this.currentAnim = this.anims.idle;
					}
				}else{								
					this.currentAnim = this.anims.run;				
				}

				this.pos.y = this.owner.pos.y + this.owner.offset.y+4;
				if(this.owner.flip){
					this.currentAnim.flip.x = true;
					this.pos.x = this.owner.pos.x + this.owner.offset.x - 6;
				}else{
					this.currentAnim.flip.x = false;
					this.pos.x = this.owner.pos.x + this.owner.offset.x - 4;
				}
			}else{
				this.currentAnim = this.anims.idle;
			}
		}		
    });

});