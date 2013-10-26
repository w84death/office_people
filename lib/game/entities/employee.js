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

		init: function( x, y, settings ) {
			this.parent( x, y, settings );
		},
        
    });
});