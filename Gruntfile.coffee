module.exports = (grunt) ->
  path = require 'path'

  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-less'
  grunt.loadNpmTasks 'grunt-contrib-clean'
  grunt.loadNpmTasks 'grunt-contrib-jshint'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-nexus-artifact'
  grunt.loadNpmTasks 'grunt-regex-check'
  grunt.loadNpmTasks 'grunt-contrib-copy'

  grunt.loadNpmTasks 'grunt-express'
  grunt.loadNpmTasks 'grunt-contrib-jasmine'
  grunt.loadNpmTasks 'grunt-webdriver-jasmine-runner'
  grunt.loadNpmTasks 'grunt-text-replace'

  grunt.loadTasks 'grunt/tasks'

  grunt.registerTask 'default', ['build']
  grunt.registerTask 'css', ['less', 'copy:images', 'replace:imagepaths']
  grunt.registerTask 'build', 'Builds the catalog', ['clean:build', 'clean:src', 'nexus:deps', 'regex-check', 'jshint', 'css', 'sencha', 'assemble', 'copy:apphtml', 'manifest']

  grunt.registerTask 'nexus:__createartifact__', 'Internal task to create and publish the nexus artifact', ['version', 'clean:src', 'nexus:push:publish', 'clean:target']
  grunt.registerTask 'nexus:deploy', 'Deploys to nexus', ['build', 'nexus:__createartifact__']

  grunt.registerTask 'check', 'Run convention tests on all files', ['regex-check']
  grunt.registerTask 'ci', 'Does a full build, runs tests and deploys to nexus', ['build', 'test:conf', 'express:inline', 'webdriver_jasmine_runner:chrome', 'webdriver_jasmine_runner:firefox', 'nexus:__createartifact__']

  grunt.registerTask 'test:__buildjasmineconf__', 'Internal task to build and alter the jasmine conf', ['jasmine:apps:build', 'replace:jasmine']
  grunt.registerTask 'test:conf', 'Fetches the deps, compiles coffee and css files, runs jshint and builds the jasmine test config', ['nexus:deps', 'clean:test', 'coffee', 'css', 'test:__buildjasmineconf__']
  grunt.registerTask 'test', 'Sets up and runs the tests in the default browser. Use --browser=<other> to run in a different browser.', ['test:conf', 'express:inline', 'webdriver_jasmine_runner:apps']
  grunt.registerTask 'test:chrome', 'Sets up and runs the tests in Chrome', ['test:conf', 'express:inline', 'webdriver_jasmine_runner:chrome']
  grunt.registerTask 'test:firefox', 'Sets up and runs the tests in Firefox', ['test:conf', 'express:inline', 'webdriver_jasmine_runner:firefox']
  grunt.registerTask 'test:server', 'Starts a Jasmine server at localhost:8890', ['express:server', 'express-keepalive']

  spec = (grunt.option('spec') || grunt.option('jsspec') || '*').replace(/(Spec|Test)$/, '')
  debug = grunt.option 'verbose' || false
  version = grunt.option 'version' || 'dev'
  appsdk_src_version = process.env.APPSDK_SRC_VERSION || '253-6005bbf'

  appFiles = 'src/apps/**/*.js'
  specFiles = 'test/spec/**/*Spec.coffee'

  grunt.initConfig
    pkg: grunt.file.readJSON 'package.json'

    buildVersion: version

    clean:
      src: ['src/apps/**/*.html']
      build: ['build/']
      test: ['test/gen', '_SpecRunner.html', '.webdriver']
      dependencies: ['lib/', 'bin/sencha/']
      target: ['target/']

    jshint:
      files: ['grunt/**/*.js', 'src/apps/**/*.js']
      options:
        bitwise: true
        curly: true
        eqeqeq: true
        forin: true
        immed: true
        latedef: true
        noarg: true
        noempty: true
        nonew: true
        trailing: true
        browser: true
        unused: 'vars'
        es3: true
        laxbreak: true

    "regex-check":
      x4:
        src: [appFiles, specFiles]
        options:
          pattern: /x4-/g
      almglobals:
        src: [appFiles, specFiles]
        options:
          pattern: /Rally\.context|Rally\.getScope|Rally\.alm|Rally\.getContextPath/g
      sandboxing:
        src: [appFiles, specFiles]
        options:
          pattern: /Ext4\./g

    express:
      options:
        bases: [
          path.resolve(__dirname)
        ]
        server: path.resolve(__dirname, 'test', 'server.js')
        debug: debug
      server:
        options:
          port: grunt.option('port') || 8890
      inline:
        options:
          port: grunt.option('port') || 8891

    webdriver_jasmine_runner:
      options:
        seleniumServerArgs: ['-Xmx256M']
        testServerPort: 8891
      apps: {}
      chrome:
        options:
          browser: 'chrome'
      firefox:
        options:
          browser: 'firefox'

    jasmine:
      apps:
        options:
          specs: [
            "test/gen/**/#{spec}Spec.js"
          ]
          helpers: [
            'lib/sdk/test/javascripts/helpers/**/*.js'
          ]
          vendor: [
            'lib/sdk/builds/sdk-debug.js'
            'lib/sdk/builds/lib/analytics/analytics-all.js'
            'lib/sdk/builds/lib/closure/closure-all.js'

            # Enable Ext Loader
            'test/support/ExtLoader.js'

            # 3rd party libraries & customizations
            'lib/sdk/test/support/sinon/sinon-1.6.0.js'
            'lib/sdk/test/support/sinon/jasmine-sinon.js'
            'lib/sdk/test/support/sinon/rally-sinon-config.js'

            # Setup
            'lib/webdriver/webdriver.js'
            'lib/sdk/test/support/webdriver/error.js'

            # Asserts
            'lib/sdk/test/support/helpers/asserts/rally-asserts.js'
            'lib/sdk/test/support/helpers/asserts/rally-custom-asserts.js'

            # Mocks and helpers
            'lib/sdk/test/support/helpers/helpers.js'
            'lib/sdk/test/support/helpers/ext4-mocking.js'
            'lib/sdk/test/support/helpers/ext4-sinon.js'

            'lib/sdk/test/javascripts/support/helpers/CardBoard.js'
            'lib/sdk/test/javascripts/support/helpers/DetailController.js'

            # 'btid' CSS classes for Testing
            'lib/sdk/browsertest/Test.js'
            'lib/sdk/browsertest/Overrides.js'

            # Jasmine overrides
            'lib/sdk/test/support/jasmine/jasmine-html-overrides.js'
          ]
          styles: [
            'lib/sdk/test/support/jasmine/rally-jasmine.css'
            'lib/sdk/builds/rui/resources/css/rui.css'
            'lib/sdk/builds/rui/resources/css/rui-fonts.css'
            'lib/sdk/builds/lib/closure/closure-20130117-r2446.css'
            'lib/sdk/builds/rui/resources/css/lib-closure.css'
            'build/resources/css/catalog-all.css'
          ]
          host: 'http://127.0.0.1:8891/'

    replace:
      jasmine:
        src: ['_SpecRunner.html']
        overwrite: true
        replacements: [
          from: '<script src=".grunt/grunt-contrib-jasmine/reporter.js"></script>'
          to: '<!--script src=".grunt/grunt-contrib-jasmine/reporter.js"></script> removed because its slow and not used-->'
        ]
      imagepaths:
        src: ['build/resources/css/catalog-all.css']
        overwrite: true
        replacements: [
          from: 'url(\''
          to: 'url(\'../images/'
        ]

    less:
      options:
        yuicompress: true
      build:
        files:
          'build/resources/css/catalog-all.css': ['src/apps/**/*.css']

    copy:
      images:
        files: [
          { expand: true, src: ['src/apps/**/*.png', 'src/apps/**/*.gif', 'src/apps/**/*.jpg'], flatten: true, dest: 'build/resources/images/' }
        ]
      apphtml:
        files: [
          { expand: true, src: ['apps/**/deploy/*.html'], cwd: 'src', dest: 'build/html/', rename: (dest, src) -> "#{dest}#{src.replace('deploy/', '').replace('apps/', '')}" }
          { expand: true, src: ['legacy/**/*.html', 'legacy/**/*.png'], cwd: 'src', dest: 'build/html/' }
        ]

    coffee:
      test:
        expand: true
        cwd: 'test/spec'
        src: ['**/*.coffee']
        dest: 'test/gen'
        ext: '.js'

    watch:
      test:
        files: 'test/spec/**/*.coffee'
        tasks: ['coffee']
        options:
          spawn: false
      src:
        files: 'src/apps/**/*.js'
        tasks: ['jshint']
      styles:
        files: 'src/apps/**/*.css'
        tasks: ['css']

    nexus:
      options:
        url: 'http://alm-build.f4tech.com:8080'
        repository: 'thirdparty'
      deps:
        options:
          fetch: [
            { id: 'com.rallydev.sencha:sencha-cmd:tgz:3.0.0.250', path: 'bin/sencha' }
            { id: 'com.rallydev.js:ext:tgz:4.1.1a', path: 'lib/ext/4.1.1a' }
            { id: 'com.rallydev.js:webdriver:tgz:2.35.0-rally', path: 'lib/webdriver' }
            { id: 'com.rallydev.js:appsdk-src:tgz:' + appsdk_src_version, path: 'lib/sdk' }
          ]
      push:
        files: [
          { expand: true, src: ['build/**/*'] }
          { expand: true, src: ['src/apps/**/*'] }
        ]
        options:
          publish: [{ id: 'com.rallydev.js:app-catalog:tgz', version: '<%= buildVersion %>', path: 'target/' }]

    sencha:
      cmd: "bin/sencha/#{if process.platform is 'darwin' then 'mac' else 'linux'}/sencha"
      args: [
        if debug then '-d' else ''
        '-s lib/ext/4.1.1a'
        'compile'
        '-classpath=lib/sdk/builds/sdk-dependencies-debug.js,lib/sdk/src,src/apps'
        'exclude -all and'
        'include -file src/apps and'
        'concat build/catalog-all-debug.js and'
        'concat -compress build/catalog-all.js'
      ]

    assemble:
      options:
        apps: 'src/apps/**/config.json'

    manifest:
      options:
        dest: 'build/catalog-all.json'
        apps:
          files: 'src/apps/**/config.json'
          srcRoot: 'build/html'
        legacy:
          srcRoot: 'build/html/legacy'
          files: 'src/legacy/**/config.json'        
          
  # Only recompile changed coffee files
  changedFiles = Object.create null

  onChange = grunt.util._.debounce ->
    grunt.config ['coffee', 'test'],
      expand: true
      cwd: 'test/spec'
      src: grunt.util._.map(Object.keys(changedFiles), (filepath) -> filepath.replace('test/spec/', ''))
      dest: 'test/gen'
      ext: '.js'
    changedFiles = Object.create null
  , 200

  grunt.event.on 'watch', (action, filepath) ->
    changedFiles[filepath] = action
    onChange()