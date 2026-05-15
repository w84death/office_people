ig.module(
	'game.entities.item_for_use'
)
.requires(
    'impact.entity'
)
.defines(function(){

	EntityItem_for_use = ig.Entity.extend({

        type: ig.Entity.TYPE.B,
        checkAgainst: ig.Entity.TYPE.A,
        collides: ig.Entity.COLLIDES.FIXED,
        can_use: true,
        state: 'off',

		init: function( x, y, settings ) {
			this.parent( x, y, settings );
			this.zIndex = this.pos.y;
		},       			

		updateZindex: function(){
			if( this.vel.y !== 0 ) {												    			    
			    if(this.owner){
			    	this.zIndex = this.owner.zIndex - 1;
			    }else{
			    	this.zIndex = this.pos.y;
			    }
            	ig.game.sortEntitiesDeferred();
			}
		},

		use: function( other ){
			if( this.state == 'off' ){
				this.state = 'on';
				this.currentAnim = this.anims.on.rewind();
				if(other.player){
					ig.game.score += ig.game.score_for_use;
				}
			}
		},	

		update: function() {
			this.parent();						
			if(this.state == 'on'){
				if(this.currentAnim.loopCount>0){
					this.state = 'off';
					this.currentAnim = this.anims.off;
				}
			}else{
				this.currentAnim = this.anims.off;
			}			
		},

    });

});