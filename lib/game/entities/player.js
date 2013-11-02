ig.module(
	'game.entities.player'
)
.requires(
    'impact.entity'
)
.defines(function(){

	EntityPlayer = ig.Entity.extend({

		message: null,
		uid: 0,
        type: ig.Entity.TYPE.A,
        checkAgainst: ig.Entity.TYPE.B,
        collides: ig.Entity.COLLIDES.ACTIVE,
        label: new ig.Font( 'media/04b03.font.png' ),        
		speed: 30,
		movement: 30,
		in_hand: false,
		is_using: false,
		lift: false,
		direction: null,
		pushing: false,
		knocked: false,
		npc: false,

		init: function( x, y, settings ) {
			this.parent( x, y, settings );
			this.zIndex = this.pos.y;

			this.uid = settings.uid;

			this.addAnim( 'idle_up', 1, [0] );
			this.addAnim( 'idle_right', 1, [8] );
			this.addAnim( 'idle_down', 1, [16] );
			this.addAnim( 'idle_left', 1, [24] );

			this.addAnim( 'idle_lift_up', 1, [4] );
			this.addAnim( 'idle_lift_right', 1, [12] );
			this.addAnim( 'idle_lift_down', 1, [20] );
			this.addAnim( 'idle_lift_left', 1, [28] );

			this.addAnim( 'move_up', 0.2, [1,2,3] );
			this.addAnim( 'move_right', 0.2, [9,10,11] );
			this.addAnim( 'move_down', 0.2, [17,18,19] );
			this.addAnim( 'move_left', 0.2, [25,26,27] );

			this.addAnim( 'move_lift_up', 0.2, [5,6,7] );
			this.addAnim( 'move_lift_right', 0.2, [13,14,15] );
			this.addAnim( 'move_lift_down', 0.2, [21,22,23] );
			this.addAnim( 'move_lift_left', 0.2, [29,30,31] );

			this.addAnim( 'kick_up_right', 1, [0] );
			this.addAnim( 'kick_up_left', 1, [0] );
			this.addAnim( 'kick_down_right', 0.2, [0] );
			this.addAnim( 'kick_down_left', 0.2, [0] );

			this.addAnim( 'punch_up_right', 1, [0] );
			this.addAnim( 'punch_up_left', 1, [0] );
			this.addAnim( 'punch_down_right', 0.2, [0] );
			this.addAnim( 'punch_down_left', 0.2, [0] );

			this.addAnim( 'block_up_right', 1, [0] );
			this.addAnim( 'block_up_left', 1, [0] );
			this.addAnim( 'block_down_right', 0.2, [0] );
			this.addAnim( 'block_down_left', 0.2, [0] );

			this.addAnim( 'knocked_left', 0.1, [48,49,50] );
			this.addAnim( 'knocked_right', 0.1, [51,52,53] );


			this.direction = 'down';

		},

		updateZindex: function(){
			if( this.vel.y !== 0 ) {												    			    
			    this.zIndex = this.pos.y;
            	ig.game.sortEntitiesDeferred();
			}
		},

		check: function( other ){
			if(other.last_owner != this){
				if(other.vel.x > 15 || other.vel.x < -15 || other.vel.y > 15 || other.vel.y < -15){
					this.knock( other.power );
					
					if(other.last_owner){
						if(other.last_owner.player){
							ig.game.score += ig.game.score_for_throwing;
						}
					}
				}
			}
			if(other.can_take && !this.in_hand && !other.owner){
	            other.take( this );
			}else
			if(other.can_use && !this.in_hand && !other.owner){
				other.use( this );
			}
		},

		knock: function( power ){
			this.knocked = power;
			if(this.in_hand){
				this.in_hand.drop( this );
			}
		},

        die: function() {
        	if(this.in_hand){
        		this.in_hand.drop( this );
        	}
			this.parent();
		},

		update: function() {
			this.parent();
			this.updateZindex();

			if(this.in_hand){
				this.movement = this.speed - this.in_hand.slow_down;
			}else{
				this.movement = this.speed;
			}

			if(this.vel.x > 0) this.vel.x -= 1;
			if(this.vel.x < 0) this.vel.x += 1;
			if(this.vel.y > 0) this.vel.y -= 1;
			if(this.vel.y < 0) this.vel.y += 1;	

			if(this.vel.x <= 1 && this.vel.x >= 0) this.vel.x = 0;
			if(this.vel.y <= 1 && this.vel.y >= 0) this.vel.y = 0;

			if(this.knocked > 0){
				this.knocked -= 0.1;
			}else{
				this.knocked = false;
			}	            			

			// player dont move
			if( this.vel.x == 0 && this.vel.y == 0 ) {				
				if(this.direction == 'up'){
					if(this.lift){					
						this.currentAnim = this.anims.idle_lift_up;
					}else{
						this.currentAnim = this.anims.idle_up;
					}
				}
				if(this.direction == 'right'){	
					if(this.lift){				
						this.currentAnim = this.anims.idle_lift_right;
					}else{
						this.currentAnim = this.anims.idle_right;
					}
				}
				if(this.direction == 'down'){
					if(this.lift){					
						this.currentAnim = this.anims.idle_lift_down;
					}else{
						this.currentAnim = this.anims.idle_down;
					}
				}
				if(this.direction == 'left'){	
					if(this.lift){				
						this.currentAnim = this.anims.idle_lift_left;
					}else{
						this.currentAnim = this.anims.idle_left;
					}
				}

			// player moves
			}else{
				
				if(this.vel.y < 0 && Math.abs(this.vel.y) >= Math.abs(this.vel.x)){
					if(this.lift){
						this.currentAnim = this.anims.move_lift_up;
					}else{
						this.currentAnim = this.anims.move_up;
					}
					this.direction = 'up';
				}
				if(this.vel.x > 0  && Math.abs(this.vel.x) >= Math.abs(this.vel.y)){
					if(this.lift){
						this.currentAnim = this.anims.move_lift_right;
					}else{
						this.currentAnim = this.anims.move_right;
					}
					this.direction = 'right';
				}
				if(this.vel.y > 0 && Math.abs(this.vel.y) >= Math.abs(this.vel.x)){
					if(this.lift){
						this.currentAnim = this.anims.move_lift_down;
					}else{
						this.currentAnim = this.anims.move_down;
					}
					this.direction = 'down';
				}
				if(this.vel.x < 0  && Math.abs(this.vel.x) >= Math.abs(this.vel.y)){
					if(this.lift){
						this.currentAnim = this.anims.move_lift_left;
					}else{
						this.currentAnim = this.anims.move_left;
					}
					this.direction = 'left';
				}

			}

			if(this.knocked){
				if(this.direction == 'right'){
					this.currentAnim = this.anims.knocked_right;
				}else{
					this.currentAnim = this.anims.knocked_left;
				}
			}

			if(this.in_hand && !this.npc){												
				if( ig.input.state('drop')) {
					this.in_hand.drop( this );
				}

				if( ig.input.state('throw') ) {
					this.in_hand.throw( this );
				}
			}

		},

		draw: function(){
			this.parent();
			if(this.message){
				this.label.draw( this.name, this.pos.x, this.pos.y, ig.Font.ALIGN.CENTER );
			}
		},
    });
});