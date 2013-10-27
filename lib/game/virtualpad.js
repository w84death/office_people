ig.module('game.virtualpad')
.requires(
	'impact.game'
)
.defines(function() {
	virtualpad = function() {
				
		ig.gui.element.add({
			name: 'up',
			group: 'pad',
			size: { x: 16, y: 16 },
			pos: { x: 12, y: 0 },
			state: {
				normal: {
					image: new ig.Image('media/virtualpad.png'),
					tile: 0,
					tileSize: 16
				},
				active: {
					image: new ig.Image('media/virtualpad.png'),
					tile: 8,
					tileSize: 16
				}
			},
			mouseDown: function() {
				if(!this.knocked){
					ig.game.player.vel.y = -ig.game.player.movement;
	                ig.game.player.direction = 'top';
				}
			}
		})

		ig.gui.element.add({
			name: 'right',
			group: 'pad',
			size: { x: 16, y: 16 },
			pos: { x: 24, y: 16 },
			state: {
				normal: {
					image: new ig.Image('media/virtualpad.png'),
					tile: 1,
					tileSize: 16
				},
				active: {
					image: new ig.Image('media/virtualpad.png'),
					tile: 9,
					tileSize: 16
				}
			},
			mouseDown: function() {
				if(!this.knocked){
					ig.game.player.vel.x = ig.game.player.movement;
	                ig.game.player.direction = 'right';
				}
			}
		})

		ig.gui.element.add({
			name: 'down',
			group: 'pad',
			size: { x: 16, y: 16 },
			pos: { x: 12, y: 32 },
			state: {
				normal: {
					image: new ig.Image('media/virtualpad.png'),
					tile: 2,
					tileSize: 16
				},
				active: {
					image: new ig.Image('media/virtualpad.png'),
					tile: 10,
					tileSize: 16
				}
			},
			mouseDown: function() {
				if(!this.knocked){
					ig.game.player.vel.y = ig.game.player.movement;
	                ig.game.player.direction = 'down';
				}
			}
		})

		ig.gui.element.add({
			name: 'left',
			group: 'pad',
			size: { x: 16, y: 16 },
			pos: { x: 0, y: 16 },
			state: {
				normal: {
					image: new ig.Image('media/virtualpad.png'),
					tile: 3,
					tileSize: 16
				},
				active: {
					image: new ig.Image('media/virtualpad.png'),
					tile: 11,
					tileSize: 16
				}
			},
			mouseDown: function() {
				if(!this.knocked){
					ig.game.player.vel.x = -ig.game.player.movement;
	                ig.game.player.direction = 'left';
				}
			}
		})

		ig.gui.element.add({
			name: 'a',
			group: 'pad',
			size: { x: 16, y: 16 },
			pos: { x: ig.system.width - 16, y: 0 },
			state: {
				normal: {
					image: new ig.Image('media/virtualpad.png'),
					tile: 4,
					tileSize: 16
				},
				active: {
					image: new ig.Image('media/virtualpad.png'),
					tile: 12,
					tileSize: 16
				}
			},
			mouseDown: function() {
				ig.game.player.take();
			}
		})

		ig.gui.element.add({
			name: 'b',
			group: 'pad',
			size: { x: 16, y: 16 },
			pos: { x: ig.system.width - 16, y: 18 },
			state: {
				normal: {
					image: new ig.Image('media/virtualpad.png'),
					tile: 5,
					tileSize: 16
				},
				active: {
					image: new ig.Image('media/virtualpad.png'),
					tile: 13,
					tileSize: 16
				}
			},
			mouseDown: function() {
				if(ig.game.player.inHand){
					ig.game.player.inHand.throw( ig.game.player );
				}
			}
		})

		ig.gui.element.add({
			name: 'c',
			group: 'pad',
			size: { x: 16, y: 16 },
			pos: { x: ig.system.width - 16, y: 36 },
			state: {
				normal: {
					image: new ig.Image('media/virtualpad.png'),
					tile: 6,
					tileSize: 16
				},
				active: {
					image: new ig.Image('media/virtualpad.png'),
					tile: 14,
					tileSize: 16
				}
			},
			mouseDown: function() {
				if(ig.game.player.inHand){
					ig.game.player.inHand.drop( ig.game.player );
				}
			}
		})

		ig.gui.element.add({
			name: 'd',
			group: 'pad',
			size: { x: 16, y: 16 },
			pos: { x: ig.system.width - 16, y: 54 },
			state: {
				normal: {
					image: new ig.Image('media/virtualpad.png'),
					tile: 7,
					tileSize: 16
				},
				active: {
					image: new ig.Image('media/virtualpad.png'),
					tile: 15,
					tileSize: 16
				}
			},
			mouseDown: function() {
				
			}
		})	

		
	}
})