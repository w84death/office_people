ig.module('plugins.canvas-css3-scaling').requires('impact.input').defines(function() {
    CanvasCSS3Scaling = ig.Class.extend({
        offset: null,
        scale: null,
        init: function() {
            this.element = document.getElementById('game');
            this.canvas = this.element.firstElementChild;
            this.content = [this.canvas.width, this.canvas.height];
            window.addEventListener('resize', this, false);
            window.addEventListener('orientationchange', this, false);
            this.reflow();
            ig.Input.inject({
                mousemove: function(event) {
                    var internalWidth = parseInt(ig.system.canvas.offsetWidth) || ig.system.realWidth;
                    var scale = ig.system.scale * (internalWidth / ig.system.realWidth);
                    var pos = {
                        left: 0,
                        top: 0
                    };
                    if (ig.system.canvas.getBoundingClientRect) {
                        pos = ig.system.canvas.getBoundingClientRect();
                    }
                    var ev = event.touches ? event.touches[0]: event;
                    this.mouse.x = (ev.pageX - ig.CanvasCSS3Scaling.offset[0]) / ig.CanvasCSS3Scaling.scale;
                    this.mouse.y = (ev.pageY - ig.CanvasCSS3Scaling.offset[1]) / ig.CanvasCSS3Scaling.scale;
                }
            });
        },
        reflow: function() {
            var browser = [window.innerWidth, window.innerHeight];
            var scale = this.scale = Math.min(browser[0] / this.content[0], browser[1] / this.content[1]);
            var size = [this.content[0] * scale, this.content[1] * scale];
            var offset = this.offset = [(browser[0] - size[0]) / 2, (browser[1] - size[1]) / 2];
            var rule = "translate(" + offset[0] + "px, " + offset[1] + "px) scale(" + scale + ")";
            this.element.style.transform = rule;
            this.element.style.webkitTransform = rule;
        },
        handleEvent: function(evt) {
            if (evt.type == 'resize' || evt.type == 'orientationchange') {
                this.reflow();
            }
        }
    });
});