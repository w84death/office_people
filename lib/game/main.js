ig.module( 
	'game.main' 
)
.requires(
	//'impact.debug.debug',
	'plugins.touch-button',
	'impact.game',
	'impact.font',
	'game.levels.office',	
	'game.entities.player',
	'game.entities.employee',
	'game.entities.item',
	'game.entities.plant',
	'game.entities.chair',
	'game.entities.desk',
	'game.entities.door'
)
.defines(function(){

MyGame = ig.Game.extend({

	game_version: '0.1.1 alpha',
	logo: new ig.Image( 'media/office_people_logo.png' ),
	font: new ig.Font( 'media/04b03.font.png' ),
	buttons: [],
	buttonImage: new ig.Image( 'media/buttons.png' ),
	sX: 0,
    sY: 0,
    k: 0.9,
   	uid: (Math.random()*100000)<<0,

	init: function() {
		// Initialize your game here; bind keys etc.
		this.loadLevel( LevelOffice );

		ig.input.bind( ig.KEY.LEFT_ARROW, 'left' );
		ig.input.bind( ig.KEY.RIGHT_ARROW, 'right' );
		ig.input.bind( ig.KEY.UP_ARROW, 'up' );
		ig.input.bind( ig.KEY.DOWN_ARROW, 'down' );
		
		ig.input.bind( ig.KEY.Z, 'take' );
		ig.input.bind( ig.KEY.X, 'drop' );
		ig.input.bind( ig.KEY.C, 'throw' );
		//ig.input.bind( ig.KEY.A, 'use' );
		
		if( ig.ua.mobile ) {
            var pad = {
            	x:24,
            	y:ig.system.height * 0.5,
            	x2:ig.system.width - 24
            }
            this.buttons = [
                new ig.TouchButton( 'left', pad.x-16, pad.y, 16, 16, this.buttonImage, 3 ),
                new ig.TouchButton( 'right', pad.x+16, pad.y, 16, 16, this.buttonImage, 1 ),
                new ig.TouchButton( 'up', pad.x, pad.y-16, 16, 16, this.buttonImage, 0 ),
                new ig.TouchButton( 'down', pad.x, pad.y+16, 16, 16, this.buttonImage, 2 ),

                new ig.TouchButton( 'take', pad.x2, pad.y-16, 16, 16, this.buttonImage, 5 ),
                new ig.TouchButton( 'drop', pad.x2, pad.y+16, 16, 16, this.buttonImage, 5 ),
                new ig.TouchButton( 'throw', pad.x2-32, pad.y-16, 16, 16, this.buttonImage, 5 ),
                //new ig.TouchButton( 'use', pad.x2-32, pad.y+16, 16, 16, this.buttonImage, 4 ),				
            ];
        }



		this.wpx = ( this.collisionMap.width - 1 ) * this.collisionMap.tilesize;
        this.hpx = ( this.collisionMap.height - 1 ) * this.collisionMap.tilesize;

        // drop player

        var new_x = (this.wpx*0.5)<<0,
			new_y = (this.hpx*0.5)<<0;
			ig.game.spawnEntity( EntityEmployee, new_x, new_y, {
				uid: this.uid
			});
	},
	
	update: function() {
		// Update all entities and backgroundMaps
		this.parent();
		if( ig.input.state('add_player') ) {
			var new_x = (Math.random()*this.wpx)<<0,
				new_y = (Math.random()*this.hpx)<<0;
			ig.game.spawnEntity( EntityEmployee, new_x, new_y, {uid:(Math.random()*100)<<0} );
		}
		
		var player = false;//this.getEntitiesByName(Playr);
    
    	for (var i = 0; i < this.entities.length; i++) {
    		if(this.entities[i].uid == this.uid){
    			player = this.entities[i];
    		}
    	};

		if( player ) {

            this.sX = this.k * this.sX + (1.0 - this.k) * player.pos.x;
            this.sY = this.k * this.sY + (1.0 - this.k) * player.pos.y;                           
                            
		}

		this.screen.x = this.sX - ig.system.width*0.5;
        this.screen.y = this.sY- ig.system.height*0.5;
	},
	
	draw: function() {
		// Draw all entities and backgroundMaps
		this.parent();
		
		this.logo.draw(ig.system.width-80, 8);

		if( ig.ua.mobile ) {
    		for( var i = 0; i < this.buttons.length; i++ ) {
                this.buttons[i].draw();
            }				
        }else{
        	this.font.draw( '[Z] take\n[X] put\n[C] throw', 8, 16, ig.Font.ALIGN.LEFT );	
        }

		this.font.draw( 'OFFICE PEOPLE ' + this.game_version, 8, 8, ig.Font.ALIGN.LEFT );	
		
		this.font.draw( 'P1X.in', ig.system.width-8, ig.system.height-8, ig.Font.ALIGN.RIGHT );	
	}
});



    var w = 256,
    	h = 192,
    	z = 4,
    	fps = 60;

    if( ig.ua.iPhone ){
        z = 2;
    }
    
    if( ig.ua.iPad ){
        z = 4;
    }

    var w = (window.innerWidth/4)<<0;
    var h = (window.innerHeight/4)<<0; 

    if( ig.ua.mobile ) {
        ig.Sound.enabled = false;
        fps = 30;
    }
    
	ig.System.scaleMode = ig.System.SCALE.CRISP;

    ig.main( '#canvas', MyGame, fps, w, h, z );
});
