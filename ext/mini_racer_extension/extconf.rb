require 'mkmf'
require 'fileutils'

have_library('pthread')
have_library('objc') if RUBY_PLATFORM =~ /darwin/
$CPPFLAGS += " -Wall" unless $CPPFLAGS.split.include? "-Wall"
$CPPFLAGS += " -g" unless $CPPFLAGS.split.include? "-g"
$CPPFLAGS += " -rdynamic" unless $CPPFLAGS.split.include? "-rdynamic"
$CPPFLAGS += " -fPIC" unless $CPPFLAGS.split.include? "-rdynamic" or RUBY_PLATFORM =~ /darwin/
$CPPFLAGS += " -std=c++0x"
$CPPFLAGS += " -fpermissive"
$CPPFLAGS += " -fno-omit-frame-pointer"
$CPPFLAGS += " -Wno-reserved-user-defined-literal" if RUBY_PLATFORM =~ /darwin/

$LDFLAGS.insert 0, " -stdlib=libstdc++ " if RUBY_PLATFORM =~ /darwin/

if ENV['CXX']
  puts "SETTING CXX"
  CONFIG['CXX'] = ENV['CXX']
end

CXX11_TEST = <<EOS
#if __cplusplus <= 199711L
#   error A compiler that supports at least C++11 is required in order to compile this project.
#endif
EOS

`echo "#{CXX11_TEST}" | #{CONFIG['CXX']} -std=c++0x -x c++ -E -`
unless $?.success?
  warn <<EOS


WARNING: C++11 support is required for compiling mini_racer. Please make sure
you are using a compiler that supports at least C++11. Examples of such
compilers are GCC 4.7+ and Clang 3.2+.

If you are using Travis, consider either migrating your build to Ubuntu Trusty or
installing GCC 4.8. See mini_racer's README.md for more information.


EOS
end

CONFIG['LDSHARED'] = '$(CXX) -shared' unless RUBY_PLATFORM =~ /darwin/
if CONFIG['warnflags']
  CONFIG['warnflags'].gsub!('-Wdeclaration-after-statement', '')
  CONFIG['warnflags'].gsub!('-Wimplicit-function-declaration', '')
end

if enable_config('debug')
  CONFIG['debugflags'] << ' -ggdb3 -O0'
end

LIBV8_VERSION = '6.7.288.46.1'
libv8_rb = Dir.glob('**/libv8.rb').first
FileUtils.mkdir_p('gemdir')
unless libv8_rb
  puts "Will try downloading libv8 gem, version #{LIBV8_VERSION}"
  `gem install --version '= #{LIBV8_VERSION}' --install-dir gemdir libv8`
  unless $?.success?
    warn <<EOS

WARNING: Could not download a private copy of the libv8 gem. Please make
sure that you have internet access and that the `gem` binary is available.

EOS
  end

  libv8_rb = Dir.glob('**/libv8.rb').first
  unless libv8_rb
    warn <<EOS

WARNING: Could not find libv8 after the local copy of libv8 having supposedly
been installed.

EOS
  end
end

if libv8_rb
  $:.unshift(File.dirname(libv8_rb) + '/../ext')
  $:.unshift File.dirname(libv8_rb)
end

require 'libv8'
Libv8.configure_makefile
create_makefile 'sq_mini_racer_extension'
