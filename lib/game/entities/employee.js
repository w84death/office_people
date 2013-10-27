ig.module(
	'game.entities.employee'
)
.requires(
    'game.entities.player'
)
.defines(function(){

	EntityEmployee = EntityPlayer.extend({

		animSheet: new ig.AnimationSheet( 'media/employee.png', 16, 16 ),	
		size: {x: 5, y:7},
		offset: {x: 5, y: 9},
		npc: false,

		init: function( x, y, settings ) {
			this.parent( x, y, settings );
		},

		check: function( other ){
			if(other.vel.x > 15 || other.vel.x > 15 || other.vel.x < -15 || other.vel.x < -15){
				this.knock( other.power );
			}
			if(other.item && !this.inHand && !other.owner){
	            if(ig.input.state('take')){
	                other.take( this );
	            }	            
	            this.interaction = other;
			}
		},

		take: function(){
			if(this.interaction && !this.knocked){
				if(this.interaction.item && !this.inHand && !this.interaction.owner){
					this.interaction.take( this );
				}
			}
		},

		update: function(){	
			this.interaction = null;		
			this.parent();

			/*if(this.interaction){
				if(this.interaction.owner !== this){
					this.interaction = null;
				}
			}*/

			if(!this.knocked){
				if( ig.input.state('left') ) {
	                this.vel.x = -this.movement;
	                this.direction = 'left';                  
				}
				if( ig.input.state('right')) {
	                this.vel.x = this.movement;
	                this.direction = 'right';
				}
				if( ig.input.state('up') ) {
	                this.vel.y = -this.movement;
	                this.direction = 'up';
				}
				if( ig.input.state('down')) {
	                this.vel.y = this.movement;
	                this.direction = 'down';
				}
			}
		},
        
    });
});