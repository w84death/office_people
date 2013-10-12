ig.module(
	'game.entities.rebel'
)
.requires(
    'impact.entity'
)
.defines(function(){

	EntityRebel = ig.Entity.extend({

		name: 'Rebel',
		uid: 0,
		control: false,
        type: ig.Entity.TYPE.A,
        checkAgainst: ig.Entity.TYPE.B,
        collides: ig.Entity.COLLIDES.ACTIVE,
		animSheet: new ig.AnimationSheet( 'media/rebel.png', 16, 16 ),	
		size: {x: 8, y:12},
		offset: {x: 4, y: 3},
		flip: false,
        health: 100,
        speed: 60,
        friction: {x:100,y:100},
        health: 100,
        ammo: 32,
        label: new ig.Font( 'media/04b03.font.png' ),
        simpleAI: {
        	idle:0,
			up:0,
			down:0,
			left:0,
			right:0	
		},
		inHand: false,
		canPickUp: true,

		init: function( x, y, settings ) {
			this.parent( x, y, settings );
			this.control = settings.control;
			this.uid = settings.uid;
			this.addAnim( 'idle_right', 0.2, [0,8,0,0,0,0,0,0,0,0,0] );
			this.addAnim( 'idle_left', 0.2, [4,9,4,4,4,4,4,4,4,4] );
			this.addAnim( 'run_right', 0.1, [1,2,3,0] );
			this.addAnim( 'run_left', 0.1, [5,6,7,4] );
			this.flip = (Math.random()*2)<<0 ? true : false;			
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
        		this.inHand.use();
        	}
        },

        die: function() {
        	if(this.inHand){
        		this.inHand.drop();
        	}
			this.parent();
		},

		update: function() {
			this.parent();

			/*
			* 	Movement
			********************************************************************************/			
			if(this.control){
				if( ig.input.state('left') ) {
	                this.vel.x = -this.speed;
	                this.vel.y = 0;	                  
				}else			
				if( ig.input.state('right')) {
	                this.vel.x = this.speed;
	                this.vel.y = 0;
				}else
				if( ig.input.state('up') ) {
					this.vel.x = 0;
	                this.vel.y = -this.speed;
				}else			
				if( ig.input.state('down')) {
					this.vel.x = 0;
	                this.vel.y = this.speed;
				}else{
					if(this.vel.x > 0) this.vel.x -= 1;
					if(this.vel.x < 0) this.vel.x += 1;
					if(this.vel.y > 0) this.vel.y -= 1;
					if(this.vel.y < 0) this.vel.y += 1;
				}
			}else{
				this.think();

				if( this.simpleAI.up > 0 ) this.simpleAI.up -= 1;
	        	if( this.simpleAI.right > 0 ) this.simpleAI.right -= 1;
	        	if( this.simpleAI.down > 0 ) this.simpleAI.down -= 1;
	        	if( this.simpleAI.left > 0 ) this.simpleAI.left -= 1;
	        	if( this.simpleAI.idle > 0 ) this.simpleAI.idle -= 1;


				if( this.simpleAI.left > 0 ) {
	                this.vel.x = -this.speed;
	                this.vel.y = 0;
				}else			
				if( this.simpleAI.right > 0  ) {
	                this.vel.x = this.speed;
	                this.vel.y = 0;
				}else
				if( this.simpleAI.up > 0 ) {
					this.vel.x = 0;
	                this.vel.y = -this.speed;
				}else			
				if( this.simpleAI.down > 0  ) {
					this.vel.x = 0;
	                this.vel.y = this.speed;
				}else{
					if(this.vel.x > 0) this.vel.x -= 1;
					if(this.vel.x < 0) this.vel.x += 1;
					if(this.vel.y > 0) this.vel.y -= 1;
					if(this.vel.y < 0) this.vel.y += 1;
				}
			}

			/*
			* 	Animations
			********************************************************************************/
			if( this.vel.x == 0 && this.vel.y == 0 ) {
				if(this.flip){						
					this.currentAnim = this.anims.idle_left;
				}else{
					this.currentAnim = this.anims.idle_right;
				}
			}else{								
				if(this.flip){						
					this.currentAnim = this.anims.run_left;
				}else{
					this.currentAnim = this.anims.run_right;
				}
			}        

			if(this.vel.x < 0){
				this.flip = true;
			}
			if(this.vel.x > 0){
				this.flip = false;
			}
            

			/*
			* 	Item
			********************************************************************************/
			
			if(this.inHand && this.control){								

				if( ig.input.state('use') ) {
					this.inHand.use();
				}

				if( ig.input.state('drop') ) {
					this.inHand.drop( this );
				}
			}

		},

		draw: function(){
			this.parent();
			this.label.draw( 'a:'+this.ammo+'\n'+'h:'+this.health, this.pos.x+this.offset.x, this.pos.y-12, ig.Font.ALIGN.CENTER );
		},
    });
});