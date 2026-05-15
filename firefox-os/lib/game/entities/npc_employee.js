ig.module(
	'game.entities.npc_employee'
)
.requires(
    'game.entities.npc'
)
.defines(function(){

	EntityNpc_employee = EntityNpc.extend({

		animSheet: new ig.AnimationSheet( 'media/npc_employee.png', 16, 16 ),
		size: {x: 5, y:3},
		offset: {x: 5, y: 13},
		npc: true,

		init: function( x, y, settings ) {
			this.parent( x, y, settings );
		},

		update: function(){
			this.parent();
		},
        
    });
});