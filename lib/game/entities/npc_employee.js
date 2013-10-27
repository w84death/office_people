ig.module(
	'game.entities.npc_employee'
)
.requires(
    'game.entities.npc'
)
.defines(function(){

	EntityNpc_employee = EntityNpc.extend({

		animSheet: new ig.AnimationSheet( 'media/npc_employee.png', 16, 16 ),
		size: {x: 5, y:7},
		offset: {x: 5, y: 9},

		init: function( x, y, settings ) {
			this.parent( x, y, settings );
		},

		update: function(){
			this.parent();
		},
        
    });
});