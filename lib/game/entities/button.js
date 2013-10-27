ig.module(
	'game.entities.button'
)
.requires(
    'impact.entity'
)
.defines(function(){

	EntityButton = ig.Entity.extend({
	
		init: function(x, y, settings) {
	        this.addAnim('idle', 0.1, [0]);
	        this.parent(x, y, settings);
	    },

		inFocus: function() {
	        return ((this.pos.x <= (ig.input.mouse.x + ig.game.screen.x)) && ((ig.input.mouse.x + ig.game.screen.x) <= this.pos.x + this.size.x) && (this.pos.y <= (ig.input.mouse.y + ig.game.screen.y)) && ((ig.input.mouse.y + ig.game.screen.y) <= this.pos.y + this.size.y));
	    }

    });

});