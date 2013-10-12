ig.module(
	'game.entities.bullet'
)
.requires(
    'impact.entity',
    'impact.entity-pool'
)
.defines(function(){

	EntityBullet = ig.Entity.extend({

        type: ig.Entity.TYPE.NONE,
        checkAgainst: ig.Entity.TYPE.A,
        collides: ig.Entity.COLLIDES.PASSIVE,
		animSheet: new ig.AnimationSheet( 'media/ammo.png', 8, 8 ),	
		size: {x: 2, y:1},
		offset: {x: 0, y: 0	},
        friction: {x:0,y:0},
        speed: 240,

		init: function( x, y, settings ) {
			this.parent( x, y, settings );
			this.addAnim( 'idle', 1, [0] );
			this.currentAnim = this.anims.idle;

			if(settings.flip){
				this.vel.x = -this.speed;
				this.currentAnim.flip.x = true;				
			}else{
				this.vel.x = this.speed;
			}
		},       			
		
		reset: function( x, y, settings ) {
			this.parent( x, y, settings );

			if(settings.flip){
				this.vel.x = -400;
				this.currentAnim.flip.x = true;				
			}else{
				this.vel.x = 400;
			}			
 			
		},

		check: function( other ) {
			other.receiveDamage(33);                                                 
            this.kill();
        },

        update: function() {			
			this.parent();
			if(this.vel.x == 0){
				this.kill();
			}
		}	
    });

	ig.EntityPool.enableFor( EntityBullet );
});