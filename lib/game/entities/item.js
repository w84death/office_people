ig.module(
	'game.entities.item'
)
.requires(
    'impact.entity'
)
.defines(function(){

	EntityItem = ig.Entity.extend({

        type: ig.Entity.TYPE.B,
        checkAgainst: ig.Entity.TYPE.A,
        collides: ig.Entity.COLLIDES.ACTIVE,
        drawLabel: false,  
        weight: 10,
        heavy: true,

		init: function( x, y, settings ) {
			this.parent( x, y, settings );
			this.zIndex = this.pos.y;
		},       			

		updateZindex: function(){
			if( this.vel.y !== 0 ) {												    			    
			    if(this.owner){
			    	this.zIndex = other.zIndex + 1;
			    }else{
			    	this.zIndex = this.pos.y;
			    }
            	ig.game.sortEntitiesDeferred();
			}
		},

		take: function( other ){
			other.inHand = this;
            this.owner = other;
            this.collides = ig.Entity.COLLIDES.NONE;
            if(this.heavy){
            	this.owner.lift = true;
            }

            this.updateZindex();
		},

		drop: function( other ){
			other.inHand = false;

			if(this.owner.lift){
				this.owner.lift = false;
			}
			
			if(other.direction == 'up'){
				this.pos.y -= 4;				
			}
			if(other.direction == 'right'){
				this.pos.x += 6;
				this.pos.y += 10;				
			}
			if(other.direction == 'down'){
				this.pos.y += 20;				
			}
			if(other.direction == 'left'){
				this.pos.x -= 8;
				this.pos.y += 10;			
			}

            this.owner = false;
            this.collides = ig.Entity.COLLIDES.ACTIVE;            
		},

		throw: function( other ){			
			if(other.direction == 'up'){				
				this.vel.y = -(100 - this.weight);				
			}
			if(other.direction == 'right'){
				this.vel.x = 100 - this.weight;				
			}
			if(other.direction == 'down'){
				this.vel.y = 100 - this.weight;				
			}
			if(other.direction == 'left'){
				this.vel.x = -(100 - this.weight);
			}

            this.drop( other );
		},

		check: function( other ) {                          
            if( !other.inHand && ig.input.state('take') ){
                this.take( other );
            }
        },

		update: function() {			
			this.parent();
			this.updateZindex();

			if( this.vel.x !== 0 || this.vel.y !== 0 ) {									
			    this.currentAnim = this.anims.move;
			}else{
			    this.currentAnim = this.anims.idle;
			}

			if(this.owner){	
				this.pos.x = this.owner.pos.x;
				if(this.owner.lift){
					this.pos.y = this.owner.pos.y-10;
				}else{
					this.pos.y = this.owner.pos.y;
				}
			}			
			
		},		

    });

});