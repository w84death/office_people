ig.module( 
	'game.main' 
)
.requires(
	// LIB
	'impact.debug.debug',
	'impact.game',
	'impact.font',
	
	// PLUGINS
	'plugins.gui',
	'plugins.impact-storage',

	// LEVELS
	'game.levels.menu',
	'game.levels.level1',
	'game.levels.level2',
	'game.levels.level3',
	'game.levels.end',

	// ENTITIES

	// master classes
	'game.entities.item',
	'game.entities.item_for_use',
	'game.entities.player',
	'game.entities.npc',

	// players
	'game.entities.employee',
	'game.entities.npc_employee',

	// special
	'game.entities.door',
	'game.entities.door_vertical',
	'game.entities.elevator',

	// items
	'game.entities.bookstand',
	'game.entities.chair',
	'game.entities.desk',	
	'game.entities.fridge',
	'game.entities.kitchen_cabinet',
	'game.entities.kitchen_coffee',
	'game.entities.kitchen_sink',
	'game.entities.lack',
	'game.entities.plant',
	'game.entities.water'
)
.defines(function(){

MyGame = ig.Game.extend({

	game_version: 'v0.7',
	logo: new ig.Image( 'media/office_people_logo.png' ),
	sponsor: new ig.Image( 'media/p1x_logo.png' ),
	overlay: new ig.Image( 'media/overlay.png' ),
	hearth: new ig.Image( 'media/hearth.png' ),
	game_over: new ig.Image( 'media/game_over.png' ),
	the_end: new ig.Image( 'media/the_end.png' ),
	level_finished: new ig.Image( 'media/done.png' ),
	font: new ig.Font( 'media/04b03b.font.png' ),	
	sX: 0,
    sY: 0,
    k: 0.9,  	
   	menu_camera_direction: 1,
   	show_sponsor: 35,
   	show_game_over_buttons: 35,
   	show_level_clear_buttons: 35,
   	show_game_briefing: 35,
   	player: null,
   	pause: false,
   	STATE: 'intro',
   	score: 0,
   	show_score: 0,
   	total_score: 0,
   	high_score: 0,
   	score_for_throwing: 500,
   	score_for_trigger: 100,
   	score_for_use: 50,
   	level_clear: false,
   	triggers: { all: 0, done: 0},
   	timer: new ig.Timer(),
   	storage: new ig.Storage(),
   	lastLevel: 0,
   	all_levels: 3,

	init: function() {
		
		ig.input.bind( ig.KEY.MOUSE1, 'touch' );
		
        ig.gui.element.add({
		    name: 'play',
		    group: 'menu',
		    size: { x: 60, y: 16 },
		    pos: { x: (ig.system.width*0.5<<0)-30, y: ig.system.height - 20 },
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

		ig.gui.element.add({
		    name: 'replay',
		    group: 'game_over',
		    size: { x: 46, y: 16 },
		    pos: { x: (ig.system.width*0.5<<0)-14, y: ig.system.height-20 },
		    state: {
		        normal: {
		            image: new ig.Image('media/button_reply_0.png'),
		        },
		        active: {
		            image: new ig.Image('media/button_reply_1.png'),
		        }
		    },
		    click: function() {
		    	ig.gui.element.action('hideGroup', 'game_over');
		        ig.game.startGame();
		    }
		});

		ig.gui.element.add({
		    name: 'back_to_menu',
		    group: 'game_over',
		    size: { x: 16, y: 16 },
		    pos: { x: (ig.system.width*0.5<<0)-32, y: ig.system.height-20 },
		    state: {
		        normal: {
		            image: new ig.Image('media/button_back_0.png'),
		        },
		        active: {
		            image: new ig.Image('media/button_back_1.png'),
		        }
		    },
		    click: function() {
		        ig.game.STATE = 'menu';
		        ig.gui.element.action('hideGroup', 'game_over');
		        ig.gui.element.action('hideGroup', 'level_clear');
		        ig.gui.element.action('showGroup', 'menu');
		        ig.game.loadLevel( LevelMenu );
		    }
		});

		ig.gui.element.add({
		    name: 'back_to_menu',
		    group: 'level_clear',
		    size: { x: 16, y: 16 },
		    pos: { x: (ig.system.width*0.5<<0)-32, y: ig.system.height-20 },
		    state: {
		        normal: {
		            image: new ig.Image('media/button_back_0.png'),
		        },
		        active: {
		            image: new ig.Image('media/button_back_1.png'),
		        }
		    },
		    click: function() {
		        ig.game.STATE = 'menu';
		        ig.gui.element.action('hideGroup', 'game_over');
		        ig.gui.element.action('hideGroup', 'level_clear');
		        ig.gui.element.action('showGroup', 'menu');
		        ig.game.loadLevel( LevelMenu );
		    }
		});

		ig.gui.element.add({
		    name: 'next',
		    group: 'level_clear',
		    size: { x: 46, y: 16 },
		    pos: { x: (ig.system.width*0.5<<0)-14, y: ig.system.height-20 },
		    state: {
		        normal: {
		            image: new ig.Image('media/button_next_0.png'),
		        },
		        active: {
		            image: new ig.Image('media/button_next_1.png'),
		        }
		    },
		    click: function() {
		    	ig.gui.element.action('hideGroup', 'level_clear');		    	
		        ig.game.startGame();		        
		    }
		});

		ig.gui.element.action('hideGroup', 'level_clear');
		ig.gui.element.action('hideGroup', 'game_over');
        ig.gui.element.action('showGroup', 'menu');  

        this.storage.initUnset('highScore', 0);
        this.storage.initUnset('score', 0);
        this.storage.initUnset('lastLevel', 0);

        this.high_score = this.storage.get('highScore');
        this.lastLevel = this.storage.get('lastLevel');
		if (this.lastLevel>0) {
			this.score = this.storage.get('score');	
		};        
	},
	
	startGame: function(){

		this.STATE = 'game';

		this.level_clear = false;
		this.timer.set(0);

		ig.gui.element.action('hideGroup', 'menu');
		ig.gui.element.action('hideGroup', 'game_over');
		ig.gui.element.action('hideGroup', 'level_clear');

		this.loadLatestLevel();		

		//this.wpx = ( this.collisionMap.width - 1 ) * this.collisionMap.tilesize;
        //this.hpx = ( this.collisionMap.height - 1 ) * this.collisionMap.tilesize;

	},

	loadLatestLevel: function(){

		if(this.lastLevel === 0){
			this.loadLevel( LevelLevel1 );
		}else
		if(this.lastLevel === 1){
			this.loadLevel( LevelLevel2 );			
		}else
		if(this.lastLevel === 2){
			this.loadLevel( LevelLevel3 );			
		}else
		if(this.lastLevel >= this.all_levels){
			// the end
			
			this.lastLevel = 0;	
			this.storage.set('lastLevel',0);

			this.loadLevel( LevelEnd );

			if (this.total_score > this.storage.get('highScore')) {
				this.storage.setHighest('highScore',this.score);
			}
			this.STATE = 'end';
			
		}

	},

	levelClear: function(){
		this.STATE = 'level_clear';
		this.player.kill();
		this.calculateScore();
		this.lastLevel += 1;
		this.storage.set('lastLevel',this.lastLevel);
		this.total_score += this.score;	
		this.show_score = 0 + this.score;
		this.score = 0;
	},

	calculateScore: function(){
		this.score = ( this.score / this.timer.delta() ) << 0;				
	},	

	update: function() {
		this.parent();

		if(this.STATE == 'intro'){			
			if(this.show_sponsor > 0){ 
				this.show_sponsor -= 1;
			}else{
				this.STATE = 'menu';
				this.loadLevel( LevelMenu );
			}
		}

		if(this.STATE == 'menu'){
					
			var maxX = this.collisionMap.width * this.collisionMap.tilesize - ig.system.width;
			if(this.screen.x > maxX) { this.menu_camera_direction = -1; }
			if(this.screen.x < 0 ) { this.menu_camera_direction = 1; }

			this.screen.x += 0.1 * this.menu_camera_direction;

		}

		if(this.STATE == 'game'){			
		
			this.triggers.all = 0;
			this.triggers.done = 0;
	    	for (var i = 0; i < this.entities.length; i++) {
	    		if(this.entities[i].player){
	    			this.player = this.entities[i];
	    		}
	    		if(this.entities[i].level_finish_trigger){
					this.triggers.all += 1;
					if(this.entities[i].state == 'on'){
						this.triggers.done += 1;
					}
	    		}
	    	};

			if( this.player ) {

	            this.sX = this.k * this.sX + (1.0 - this.k) * this.player.pos.x;
	            this.sY = this.k * this.sY + (1.0 - this.k) * this.player.pos.y;                           
	                            
			}

			this.screen.x = this.sX - ig.system.width*0.5;
	        this.screen.y = this.sY- ig.system.height*0.5;

	        if(this.player.hearth < 1){
	        	this.STATE = 'game_over';
	        	this.player.kill();
	        	this.calculateScore();
	        	this.lastLevel = 0;
	        	this.storage.set('lastLevel',this.lastLevel); 
	        }

	        if(this.triggers.all === this.triggers.done){
	        	this.level_clear = true;
	        }

	    }

	    if(this.STATE == 'game_over'){

	    	if(this.show_game_over_buttons > 0){ 
				this.show_game_over_buttons -= 1;
			}else{
				this.show_game_over_buttons = 35;
				ig.gui.element.action('showGroup', 'game_over');
			}

	    }	    

	    if(this.STATE == 'level_clear'){

	    	if(this.show_level_clear_buttons > 0){ 
				this.show_level_clear_buttons -= 1;
			}else{
				this.show_level_clear_buttons = 35;
				ig.gui.element.action('showGroup', 'level_clear');
			}

	    }

	    if(this.STATE == 'end'){

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
		
			this.font.draw( 'HIGHSCORE '+this.high_score, ig.system.width*0.5<<0, 8, ig.Font.ALIGN.CENTER );
			this.logo.draw((ig.system.width*0.5<<0)-37, 20);			
			ig.gui.draw();

		
		}

		if(this.STATE == 'game'){
			
			if(this.player){
				
				for (var i = 0; i < 3; i++) {
					var hearth = 1;
					if(this.player.hearth > i){ hearth = 0; }
					this.hearth.drawTile( ig.system.width - 12*i - 16, 6, hearth, 9 );
				};
			}

			/*if(this.show_game_briefing>0){
				this.show_game_briefing -= 1;
				this.showMessage('briefing');
			}*/

			if(this.triggers.done === this.triggers.all){
				this.font.draw( 'Done! Go to elevator.', 8, ig.system.height-8, ig.Font.ALIGN.LEFT );
			}
			if(this.triggers.done === 0){
				this.font.draw( 'Turn on all the computers.', 8, ig.system.height-8, ig.Font.ALIGN.LEFT );
			}
			this.font.draw( this.triggers.done + '/' + this.triggers.all, 8, 8, ig.Font.ALIGN.LEFT );
			this.font.draw( ((this.score / this.timer.delta() ) << 0), (ig.system.width*0.5)<<0, 8, ig.Font.ALIGN.CENTER );
		}

		if(this.STATE == 'game_over'){

			this.game_over.draw((ig.system.width*0.5<<0)-25,8);
			this.font.draw( 'YOU SCORE '+this.total_score, ig.system.width*0.5<<0, (ig.system.height*0.5<<0)+8, ig.Font.ALIGN.CENTER );
			ig.gui.draw();

		}

		if(this.STATE == 'level_clear'){

			this.level_finished.draw((ig.system.width*0.5<<0)-28,(ig.system.height*0.5<<0)-10);
			this.font.draw( 'YOU SCORE ' + this.show_score, ig.system.width*0.5<<0, (ig.system.height*0.5<<0)+8, ig.Font.ALIGN.CENTER );
			ig.gui.draw();

		}

		if(this.STATE == 'end'){

			this.the_end.draw((ig.system.width*0.5<<0)-35,(ig.system.height*0.5<<0)-10);
			this.font.draw( 'YOU TOTAL SCORE ' + this.total_score, ig.system.width*0.5<<0, (ig.system.height*0.5<<0)+8, ig.Font.ALIGN.CENTER );
			
			this.font.draw( 'Idea, code, pixel art', ig.system.width*0.5<<0, (ig.system.height*0.5<<0)+18, ig.Font.ALIGN.CENTER );
			this.font.draw( 'Krzysztof Jankowski', ig.system.width*0.5<<0, (ig.system.height*0.5<<0)+26, ig.Font.ALIGN.CENTER );
		}

		if(this.STATE == 'menu'){
		
			this.font.draw( this.game_version, ig.system.width-16, ig.system.height-8, ig.Font.ALIGN.LEFT );
		
		}

	}
});

	var w = 480,
		h = 320,
		z = 4,
		fps = 30;

	ig.main( '#canvas', MyGame, fps, w/z, h/z, z );     
});


