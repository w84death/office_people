ig.module(
	'game.entities.npc'
)
.requires(
    'game.entities.player'
)
.defines(function(){	

	EntityNpc = EntityPlayer.extend({

		npc: true,			
		simpleAI: {
	    	idle:0,
			up:0,
			down:0,
			left:0,
			right:0,
			use:0,
			throw: 0	
		},

		init: function( x, y, settings ) {
			this.parent( x, y, settings );
		},

		check: function( other ) { 			
			if(other.vel.x > 15 || other.vel.x > 15 || other.vel.x < -15 || other.vel.x < -15){
				this.knock( other.power );
			}else
            if(other.item && !this.inHand && !other.owner){
                if((Math.random()*200)<<0 < 50){
                	other.take( this );
            	}
            }            		
        },        

		think: function(){
        	var random = (Math.random()*200)<<0;

        	if( this.simpleAI.up + this.simpleAI.right + this.simpleAI.down + this.simpleAI.left + this.simpleAI.idle < 1){
	        	if( random < 25 ){
	        		this.simpleAI.up += (Math.random()*50)<<0;
	        	}else
	        	if( random < 50 ){
					this.simpleAI.right += (Math.random()*50)<<0;
	        	}else
	        	if( random < 75 ){
	        		this.simpleAI.down += (Math.random()*50)<<0;
	        	}else
	        	if( random < 100 ){
	        		this.simpleAI.left += (Math.random()*50)<<0;
	        	}else{	        	
	        		this.simpleAI.idle += (Math.random()*150)<<0;
	        	}
        	}

        	if(this.inHand){
        		this.simpleAI.throw += (Math.random()*150)<<0;
        	}
        	
        },

		update: function(){
			this.parent();
			
			this.think();

			if( this.simpleAI.up > 0 ) this.simpleAI.up -= 1;
        	if( this.simpleAI.right > 0 ) this.simpleAI.right -= 1;
        	if( this.simpleAI.down > 0 ) this.simpleAI.down -= 1;
        	if( this.simpleAI.left > 0 ) this.simpleAI.left -= 1;
        	if( this.simpleAI.idle > 0 ) this.simpleAI.idle -= 1;


        	if(!this.knocked){
				if( this.simpleAI.left > 0 ) {
	                this.vel.x = -this.movement;
	                //this.vel.y = 0;
				}			
				if( this.simpleAI.right > 0  ) {
	                this.vel.x = this.movement;
	                //this.vel.y = 0;
				}
				if( this.simpleAI.up > 0 ) {
					//this.vel.x = 0;
	                this.vel.y = -this.movement;
				}			
				if( this.simpleAI.down > 0  ) {
					//this.vel.x = 0;
	                this.vel.y = this.movement;
				}else{
					if(this.vel.x > 0) this.vel.x -= 1;
					if(this.vel.x < 0) this.vel.x += 1;
					if(this.vel.y > 0) this.vel.y -= 1;
					if(this.vel.y < 0) this.vel.y += 1;
				}

				if( this.inHand && this.simpleAI.throw > 10000 ){
					this.inHand.throw( this );
					this.simpleAI.throw = 0;
				}
			}
		},
        
    });
});