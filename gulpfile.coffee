gulp = require 'gulp'
connect = require 'gulp-connect'
coffee = require 'gulp-coffee'
jade = require 'gulp-jade'
stylus = require 'gulp-stylus'

gulp.task 'coffee', ->
  gulp.src './src/*.coffee'
    .pipe coffee bare: true
    .on 'error', (error) -> console.log error
    .pipe gulp.dest './public/'

gulp.task 'jade', ->
  gulp.src './src/*.jade'
    .pipe jade()
    .pipe gulp.dest './public/'

gulp.task 'stylus', ->
  gulp.src './src/*.styl'
    .pipe stylus()
    .pipe gulp.dest './public/'

gulp.task 'copy', ->
  gulp.src './static/**/*'
    .pipe gulp.dest './public/'

gulp.task 'connect', ->
  connect.server
    root: './public'
    port: 9002

gulp.task 'watch', ['connect'], ->
  gulp.watch './src/*.coffee', ['coffee']
  gulp.watch './src/*.jade', ['jade']
  gulp.watch './src/*.styl', ['stylus']
  gulp.watch './static/**/*', ['copy']

gulp.task 'default', ['coffee', 'jade', 'stylus', 'copy']
