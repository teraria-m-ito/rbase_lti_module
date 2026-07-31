# frozen_string_literal: true

require_relative "lib/rbase_lti_module/version"

Gem::Specification.new do |spec|
  spec.name = "rbase_lti_module"
  spec.version = RbaseLtiModule::VERSION
  spec.authors = ["Minoru Ito"]
  spec.email = ["minoru@i-do-inc.jp"]

  spec.summary = ""
  spec.description = ""
  spec.homepage = "https://www.i-do-inc.jp"
  spec.license = "GPLv3"
  spec.required_ruby_version = ">= 2.6.0"

  # spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  # spec.metadata["source_code_uri"] = ""
  # spec.metadata["changelog_uri"] = ""

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

end
