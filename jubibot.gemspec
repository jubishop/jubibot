Gem::Specification.new do |spec|
  spec.name          = 'jubibot'
  spec.version       = '1.0'
  spec.summary       = %q(Command bot built on top of discordrb.)
  spec.authors       = ['Justin Bishop']
  spec.email         = ['jubishop@gmail.com']
  spec.homepage      = 'https://github.com/jubishop/jubibot'
  spec.license       = 'MIT'
  spec.files         = Dir['lib/**/*.rb'] + Dir['sig/**/*.rbs']
  spec.require_paths = ['lib']
  spec.bindir        = 'bin'
  spec.executables   = []
  spec.metadata      = {
    'source_code_uri' => 'https://github.com/jubishop/jubibot',
    'steep_types' => 'sig'
  }
  spec.required_ruby_version = Gem::Requirement.new('>= 3.0')
  spec.add_runtime_dependency('core')
  spec.add_runtime_dependency('csv')
  spec.add_runtime_dependency('discordrb')
  spec.add_runtime_dependency('rstruct')
  spec.add_runtime_dependency('yaml')
end
