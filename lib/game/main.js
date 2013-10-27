ig.module( 
	'game.main' 
)
.requires(
	// LIB
	//'impact.debug.debug',
	'impact.game',
	'impact.font',
	
	// PLUGINS
	'plugins.gui',
	'plugins.canvas-css3-scaling',

	// LEVELS
	'game.levels.office',	

	// ENTITIES
	'game.virtualpad',
	'game.entities.player',
	'game.entities.employee',
	'game.entities.npc',
	'game.entities.npc_employee',
	'game.entities.item',
	'game.entities.plant',
	'game.entities.chair',
	'game.entities.desk',
	'game.entities.door'
)
.defines(function(){

MyGame = ig.Game.extend({

	game_version: 'v0.2a',
	logo: new ig.Image( 'media/office_people_logo.png' ),
	sponsor: new ig.Image( 'media/p1x_logo.png' ),
	overlay: new ig.Image( 'media/overlay.png' ),
	font: new ig.Font( 'media/04b03b.font.png' ),	
	sX: 0,
    sY: 0,
    k: 0.9,
   	uid: (Math.random()*100000)<<0,
   	STATE: 'intro',
   	show_sponsor: 35,
   	player: null,
   	pause: false,

	init: function() {		

		ig.input.bind( ig.KEY.LEFT_ARROW, 'left' );
		ig.input.bind( ig.KEY.RIGHT_ARROW, 'right' );
		ig.input.bind( ig.KEY.UP_ARROW, 'up' );
		ig.input.bind( ig.KEY.DOWN_ARROW, 'down' );

		ig.input.bind( ig.KEY.ENTER, 'start_game' );

		ig.input.bind( ig.KEY.Z, 'take' );
		ig.input.bind( ig.KEY.X, 'drop' );
		ig.input.bind( ig.KEY.C, 'throw' );
		
        ig.gui.element.add({
		    name: 'play',
		    group: 'menu',
		    size: { x: 60, y: 16 },
		    pos: { x: (ig.system.width*0.5<<0)-30, y: ig.system.height*0.6<<0 },
		    state: {
		        normal: {
		            image: new ig.Image('media/button_play_0.png'),
		        },
		        active: {
		            image: new ig.Image('media/button_play_1.png'),
		        }
		    },
		    click: function() {
		        ig.game.startGame();
		    }
		});

		virtualpad();

		ig.gui.element.action('hideGroup', 'pad');
        ig.gui.element.action('showGroup', 'menu');
	},
	
	startGame: function(){

		this.STATE = 'game';

		ig.gui.element.action('hideGroup', 'menu');
		if(ig.ua.mobile){
			ig.gui.element.action('showGroup', 'pad');
		}

		this.loadLevel( LevelOffice );

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

		if(this.STATE == 'intro'){			
			if(this.show_sponsor > 0){ 
				this.show_sponsor -= 1;
			}else{
				this.STATE = 'menu';
			}
		}

		if(this.STATE == 'menu'){
			if(ig.input.state('start_game')){
                this.startGame();
            }
		}

		if(this.STATE == 'game'){			
		
	    	for (var i = 0; i < this.entities.length; i++) {
	    		if(this.entities[i].uid == this.uid){
	    			this.player = this.entities[i];
	    		}
	    	};

			if( this.player ) {

	            this.sX = this.k * this.sX + (1.0 - this.k) * this.player.pos.x;
	            this.sY = this.k * this.sY + (1.0 - this.k) * this.player.pos.y;                           
	                            
			}

			this.screen.x = this.sX - ig.system.width*0.5;
	        this.screen.y = this.sY- ig.system.height*0.5;
	    }
	},		

	draw: function() {
		if(ig.game.pause) return;
		this.parent();
		this.overlay.draw(0,0);

		if(this.STATE == 'intro'){
			this.sponsor.draw((ig.system.width*0.5<<0)-11, (ig.system.height*0.5<<0)-9);
		}

		if(this.STATE == 'menu'){		
			this.logo.draw((ig.system.width*0.5<<0)-37, 8);			
			if(!ig.ua.mobile){
				this.font.draw( 'PRESS ENTER TO PLAY\n'+
					'[ARROWS] move\n'+
					'[Z]take [X]drop [C]throw', ig.system.width*0.5<<0,  ig.system.height-32, ig.Font.ALIGN.CENTER );	
			}else{
				if(ig.gui.show) ig.gui.draw();
			}			
		}

		if(this.STATE == 'game'){
			
			if(ig.ua.mobile){
				if(ig.gui.show) ig.gui.draw();
			}
		}

		if(this.STATE == 'menu' || this.STATE == 'game'){
			this.font.draw( this.game_version, 8, 8, ig.Font.ALIGN.LEFT );							
		}

	}
});


	checkOrientation = function() {

        if (ig.ua.mobile && ( window.orientation == 0 || window.orientation == 180 || screen.mozOrientation === "portrait-primary" || screen.mozOrientation === "portrait-secondary")){
            document.getElementById('portrait').style.display = 'block';
            document.getElementById('game').style.display = 'none';
        } else {
            document.getElementById('portrait').style.display = 'none';
            document.getElementById('game').style.display = 'block';
        }
    }

    if (ig.ua.mobile && ( window.orientation == 0 || window.orientation == 180 || screen.mozOrientation === "portrait-primary" || screen.mozOrientation === "portrait-secondary")){
        document.getElementById('portrait').style.display = 'block';
        document.getElementById('game').style.display = 'none';
    }
	
	
	window.screen.onmozorientationchange = checkOrientation;
    window.addEventListener("orientationchange", checkOrientation);
	//ig.System.scaleMode = ig.System.SCALE.CRISP;

	var w = 480,
		h = 320,
		z = 4,
		fps = 30;


    ig.main( '#canvas', MyGame, fps, w/z, h/z, z );

	ig.CanvasCSS3Scaling = new CanvasCSS3Scaling();
    ig.CanvasCSS3Scaling.init();
	ig.CanvasCSS3Scaling.reflow();
});


