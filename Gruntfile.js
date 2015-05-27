/**
 * Grunt build file for Rabbid.
 * @author Nils Diewald
 */
module.exports = function(grunt) {
  grunt.initConfig({
    pkg: grunt.file.readJSON('package.json'),
    requirejs: [{
      options: {
	// optimize: "uglify",
	baseUrl: 'dev/js/src',
	paths : {
	  'lib': '../lib'
	},
	wrap:true,
	// dir : 'public/js',
	name: 'lib/almond',
	include : ['app'],
	out: 'public/js/rabbid-<%= pkg.version %>.js'
      }
    }],
    imagemin: {
      dynamic: {
	files: [{
	  expand: true,
	  cwd: 'dev/img/',
	  src: ['*.{png,gif,jpg}'],
	  dest: 'public/img/'
	}]
      }
    },
    sass: {
      dist: {
        options: {
          style: 'compressed'
        },
        files: {
          'public/css/rabbid-<%= pkg.version %>.css' : 'dev/scss/rabbid.scss'
        }
      }
    },
    // see https://github.com/gruntjs/grunt-contrib-copy/issues/64
    // for copying binary files
    copy : {
      options: {
	process:false
      },
      main: {
	files:[
	  {
	    expand: true,
	    cwd: 'dev/font/',
	    src: '**',
	    dest: 'public/font/',
	    filter: 'isFile',
	    nonull: true,
	    timestamp: true
	  },
	  {
	    expand: true,
	    cwd: 'dev/img/',
	    src: 'favicon.ico',
	    dest: 'public/',
	    filter: 'isFile',
	    nonull: true,
	    timestamp: true
	  },
	  {
	    expand: true,
	    cwd: 'dev/img/',
	    src: '*.svg',
	    dest: 'public/img/',
	    filter: 'isFile',
	    nonull:true,
	    timestamp:true
	  }
	]
      }
    },
    watch: {
      css: {
	files: ['dev/scss/rabbid.scss'],
	tasks: ['sass'],
	options: {
	  spawn: false
	}
      }
    }
  });

  grunt.loadNpmTasks('grunt-contrib-imagemin');
  grunt.loadNpmTasks('grunt-contrib-watch');
  grunt.loadNpmTasks('grunt-contrib-sass');
  grunt.loadNpmTasks('grunt-contrib-jasmine');
  grunt.loadNpmTasks('grunt-contrib-copy');
  grunt.loadNpmTasks('grunt-contrib-requirejs');

  grunt.registerTask('default', ['requirejs']);
  grunt.registerTask('img', ['imagemin','copy']);
  grunt.registerTask('css', ['sass']);
  grunt.registerTask(
    'default',
    ['requirejs', 'imagemin', 'copy', 'sass']
  );
};
