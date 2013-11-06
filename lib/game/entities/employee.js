ig.module(
	'game.entities.employee'
)
.requires(
    'game.entities.player'
)
.defines(function(){

	EntityEmployee = EntityPlayer.extend({

		animSheet: new ig.AnimationSheet( 'media/employee.png', 16, 16 ),	
		size: {x: 5, y:3},
		offset: {x: 5, y: 13},
		npc: false,
		zone: 6,
		v_pattern: [200],
		hearth: 3,
		player: true,

		init: function( x, y, settings ) {
			this.parent( x, y, settings );
		},

		knock: function( power ){			
			if('vibrate' in navigator) {
				window.navigator.vibrate(this.v_pattern);
			}
			if(!this.knocked){
				this.hearth -= 1;
			}
			this.parent( power );			
		},

		update: function(){	
			this.interaction = null;		
			this.parent();			

			if(!this.knocked){				

				if(this.in_hand){
					
				}

				if( ig.input.state('touch') ){
					
					var mx = ig.input.mouse.x + ig.game.screen.x;
					var my = ig.input.mouse.y + ig.game.screen.y;

					if(mx > this.pos.x - this.zone && mx < this.pos.x + this.zone && my > this.pos.y - this.zone && my < this.pos.y + this.zone){
						if(this.in_hand && !this.knocked){				
							this.in_hand.throw( this );
						}
					}else{										

						var mouseAngle =  Math.atan2(
						    my - (this.pos.y + this.size.y*0.5),
						    mx - (this.pos.x + this.size.x*0.5)
						);


						// -1.6
						if( mouseAngle > -2 && mouseAngle < -1.2){
							this.vel.y = -this.movement;
	                		this.direction = 'top';
						}

						if(mouseAngle > -1.2 && mouseAngle < -0.4 ){
							this.vel.y = -this.movement*0.5;
	                		this.vel.x = this.movement*0.5;
						}						

						// 0
						if(mouseAngle > -0.4 && mouseAngle < 0.4 ){
							this.vel.x = this.movement;
	                		this.direction = 'right';
						}
						if(mouseAngle > 0.4 && mouseAngle < 1.2 ){
							this.vel.x = this.movement*0.5;
	                		this.vel.y = this.movement*0.5;
						}
						// 1.6
						if(mouseAngle > 1.2 && mouseAngle < 2 ){
							this.vel.y = this.movement;
	                		this.direction = 'down';
						}
						if(mouseAngle > 2 && mouseAngle < 2.74 ){
							this.vel.y = this.movement*0.5;
	                		this.vel.x = -this.movement*0.5;
						}
						// -3.14
						if(mouseAngle > 2.74 || mouseAngle < -2.74 ){
							this.vel.x = -this.movement;
	                		this.direction = 'left';
						}

						if(mouseAngle > -2.74 && mouseAngle < -2 ){
							this.vel.x = -this.movement*0.5;
	                		this.vel.y = -this.movement*0.5;
						}
					}
					
				}

			}
		},
        
    });
});