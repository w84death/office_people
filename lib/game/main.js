ig.module( 
	'game.main' 
)
.requires(
	'impact.debug.debug',
	'impact.game',
	'impact.font',
	'game.levels.demo',
	'game.entities.rebel',
	'game.entities.ammo',
	'game.entities.bullet'
)
.defines(function(){

MyGame = ig.Game.extend({
	
	// Load a font
	font: new ig.Font( 'media/04b03.font.png' ),
	
	init: function() {
		// Initialize your game here; bind keys etc.
		this.loadLevel( LevelDemo );

		ig.input.bind( ig.KEY.LEFT_ARROW, 'left' );
		ig.input.bind( ig.KEY.RIGHT_ARROW, 'right' );
		ig.input.bind( ig.KEY.UP_ARROW, 'up' );
		ig.input.bind( ig.KEY.DOWN_ARROW, 'down' );
		ig.input.bind( ig.KEY.R, 'drop_rebel' );
		ig.input.bind( ig.KEY.Z, 'drop' );
		ig.input.bind( ig.KEY.X, 'use' );

		this.wpx = ( this.collisionMap.width - 1 ) * this.collisionMap.tilesize;
        this.hpx = ( this.collisionMap.height - 1 ) * this.collisionMap.tilesize;

        // drop player

        var new_x = (this.wpx*0.5)<<0,
			new_y = (this.hpx*0.5)<<0;
			ig.game.spawnEntity( EntityRebel, new_x, new_y, {control:true,uid:(Math.random()*100)<<0} );
	},
	
	update: function() {
		// Update all entities and backgroundMaps
		this.parent();
		if( ig.input.state('drop_rebel') ) {
			var new_x = (Math.random()*this.wpx)<<0,
				new_y = (Math.random()*this.hpx)<<0;
			ig.game.spawnEntity( EntityRebel, new_x, new_y, {uid:(Math.random()*100)<<0} );
		}
		
		// Add your own, additional update code here
	},
	
	draw: function() {
		// Draw all entities and backgroundMaps
		this.parent();
		
		

	}
});


// Start the Game with 60fps, a resolution of 320x240, scaled
// up by a factor of 2
ig.main( '#canvas', MyGame, 60, 480, 224, 2 );

});
