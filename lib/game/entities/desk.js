ig.module(
	'game.entities.desk'
)
.requires(
    'game.entities.item'
)
.defines(function(){

	EntityDesk = EntityItem.extend({
       
       	collides: ig.Entity.COLLIDES.FIXED,
		animSheet: new ig.AnimationSheet( 'media/desk.png', 32, 16 ),	
		size: {x: 19, y: 4},
		offset: {x: 7, y: 9	},
        friction: {x:200,y:200},
        can_take: false,
        can_use: true,
        state: 'off',
        timer: 0,
        level_finish_trigger: true,
		
		init: function( x, y, settings ) {
			this.parent( x, y, settings );
			this.addAnim( 'off', 1, [0] );
			this.addAnim( 'on', 1, [1] );
			this.currentAnim = this.anims[this.state];
		},

		use: function( other ){
			if( other.player && this.state == 'off' ){
				this.state = 'on';
				ig.game.score += ig.game.score_for_trigger;			
			}			
		},

		update: function() {			
			this.parent();			
			this.currentAnim = this.anims[this.state];
		} 			

    });

});