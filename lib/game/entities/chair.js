ig.module(
	'game.entities.chair'
)
.requires(
    'game.entities.item'
)
.defines(function(){

	EntityChair = EntityItem.extend({

		animSheet: new ig.AnimationSheet( 'media/chair.png', 16, 16 ),	
		size: {x: 5, y: 4},
		offset: {x: 5, y: 11},
        friction: {x:15,y:15},
        can_take: true,
        direction: false,
        weight:20,
        slow_down:2,   

		init: function( x, y, settings ) {
			this.parent( x, y, settings );
			this.addAnim( 'idle', 1, [0] );
			this.addAnim( 'up', 1, [0] );
			this.addAnim( 'right', 1, [1] );
			this.addAnim( 'down', 1, [2] );
			this.addAnim( 'left', 1, [3] );
			this.currentAnim = this.anims.up;
		},       			

		update: function() {			
			this.parent();

		    if(this.vel.y < 0 ){
		    	this.currentAnim = this.anims.up;
		    	this.direction = 'up';
		    }		    
		    if(this.vel.x > 0 ){
		    	this.currentAnim = this.anims.right;
		    	this.direction = 'right';
		    }
		    if(this.vel.y > 0 ){
		    	this.currentAnim = this.anims.down;
		    	this.direction = 'down';
		    }		    
			if(this.vel.x < 0 ){
		    	this.currentAnim = this.anims.left;
		    	this.direction = 'left';
		    }

		    if(this.vel.y === 0 && this.vel.x === 0){
		    	if(this.direction == 'up'){
		    		this.currentAnim = this.anims.up;
		    	}
		    	if(this.direction == 'right'){
		    		this.currentAnim = this.anims.right;
		    	}
		    	if(this.direction == 'down'){
		    		this.currentAnim = this.anims.down;
		    	}
		    	if(this.direction == 'left'){
		    		this.currentAnim = this.anims.left;
		    	}
		    }
		}

    });

});