ig.module(
	'game.entities.ammo'
)
.requires(
    'impact.entity'
)
.defines(function(){

	EntityAmmo = ig.Entity.extend({

        type: ig.Entity.TYPE.B,
        checkAgainst: ig.Entity.TYPE.A,
        collides: ig.Entity.COLLIDES.LITE,
		animSheet: new ig.AnimationSheet( 'media/ammo.png', 8, 8 ),	
		size: {x: 4, y: 5},
		offset: {x: 0, y: 1	},
        friction: {x:100,y:100},
        bullets: 12,

		init: function( x, y, settings ) {
			this.parent( x, y, settings );
			this.addAnim( 'idle', 0.2, [2,2,2,2,2,2,2,2,2,3] );
		},       			

		check: function( other ) {                                     
            other.ammo += this.bullets;
            this.kill();        
        },		
    });

});