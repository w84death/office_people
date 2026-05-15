ig.module(
	'game.entities.fridge'
)
.requires(
    'game.entities.item'
)
.defines(function(){

	EntityFridge = EntityItem.extend({
       
		animSheet: new ig.AnimationSheet( 'media/fridge.png', 16, 16 ),	
		size: {x: 8, y: 5},
		offset: {x: 1, y: 11},
        friction: {x:200,y:200},
        can_take: false,
        can_use: true,
        state: 'closed',
        timer: 0,
        
		init: function( x, y, settings ) {
			this.parent( x, y, settings );
			this.addAnim( 'closed', 1, [0] );
			this.addAnim( 'open', 1, [1] );
			this.currentAnim = this.anims[this.state];
		},       			

		use: function( other ){
			if( this.state == 'closed' ){
				this.state = 'open';
				this.timer = 100;
				if(other.player){
					ig.game.score += ig.game.score_for_use;
				}
			}			
		},

		update: function() {			
			this.parent();
			if(this.timer > 0){
				this.timer -= 1;
			}
			if(this.timer < 1 && this.state == 'open'){
				this.state = 'closed';
			}
			this.currentAnim = this.anims[this.state];
		}

    });

});