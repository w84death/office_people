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
        bounciness: 0.1,
        weight: 10,
        slow_down: 5,
        heavy: true,
        owner: false,
        last_owner: null,
        power: 5,
        can_take: false,
        can_use: false,

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
			
		},

		take: function( other ){
			other.in_hand = this;
            this.owner = other;
            this.last_owner = this.owner;
            this.collides = ig.Entity.COLLIDES.NONE;
            if(this.heavy){
            	this.owner.lift = true;
            }

            this.updateZindex();
		},

		drop: function( other ){
			other.in_hand = false;

			if(this.owner.lift){
				this.owner.lift = false;
			}
			
			if(other.direction == 'up'){
				this.pos.y = other.pos.y - this.size.y;				
			}
			if(other.direction == 'right'){
				this.pos.x += other.size.x + this.size.x;
				this.pos.y += 10;				
			}
			if(other.direction == 'down'){
				this.pos.y = other.pos.y + other.size.y + this.size.y;
			}
			if(other.direction == 'left'){
				this.pos.x -= other.size.x + this.size.x;
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
					this.pos.x = this.owner.pos.x + ((this.owner.size.x*0.5)<<0) - ((this.size.x*0.5)<<0);
				}else{
					this.pos.y = this.owner.pos.y;
				}
			}			
			
		},		

    });

});