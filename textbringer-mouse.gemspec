# frozen_string_literal: true

require_relative "lib/textbringer/mouse/version"

Gem::Specification.new do |spec|
  spec.name = "textbringer-mouse"
  spec.version = Textbringer::Mouse::VERSION
  spec.authors = ["Shinta Koyanagi"]
  spec.email = ["yancya@upec.jp"]

  spec.summary = "Mouse mode for Textbringer"
  spec.description = "A Textbringer plugin that provides mouse mode support with syntax highlighting."
  spec.homepage = "https://github.com/yancya/textbringer-mouse"
  spec.license = "WTFPL"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/yancya/textbringer-mouse"

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore .rspec spec/ .github/])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "textbringer", ">= 1.0"
end
