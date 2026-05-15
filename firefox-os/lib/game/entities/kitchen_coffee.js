ig.module(
	'game.entities.kitchen_coffee'
)
.requires(
    'game.entities.item'
)
.defines(function(){

	EntityKitchen_coffee = EntityItem.extend({
       
       	collides: ig.Entity.COLLIDES.FIXED,
		animSheet: new ig.AnimationSheet( 'media/kitchen.png', 16, 16 ),	
		size: {x: 16, y: 3},
		offset: {x: 0, y: 13},
        can_use: true,
        state: 'stopped',
        timer: 0,
        
		init: function( x, y, settings ) {
			this.parent( x, y, settings );
			this.addAnim( 'stopped', 0.5, [0,1,2,3] );
			this.addAnim( 'runing', 2, [4,5,6] );
			this.currentAnim = this.anims[this.state];
		},       			

		use: function( other ){
			if( this.state == 'stopped' ){
				this.state = 'runing';
				this.timer = 400;
				if(other.player){
					ig.game.score += ig.game.score_for_use*2;
				}
			}			
		},

		update: function() {			
			this.parent();
			if(this.timer > 0){
				this.timer -= 1;
			}
			if(this.timer < 1 && this.state == 'runing'){
				this.state = 'stopped';
			}
			this.currentAnim = this.anims[this.state];
		}

    });

});