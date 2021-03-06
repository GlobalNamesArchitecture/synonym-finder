# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{synonym-finder}
  s.version = "0.2.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = [%q{Dmitry Mozzherin}]
  s.date = %q{2011-08-12}
  s.description = %q{Synonym finder is a biodiversity tool for finding homotypic nomenclatural synonyms in taxonomic hierarchies.}
  s.email = %q{dmozzherin@gmail.com}
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.rdoc"
  ]
  s.files = [
    ".document",
    ".rspec",
    ".rvmrc",
    "Gemfile",
    "Gemfile.lock",
    "LICENSE.txt",
    "README.rdoc",
    "Rakefile",
    "VERSION",
    "features/step_definitions/synonym-finder_steps.rb",
    "features/support/env.rb",
    "features/synonym-finder.feature",
    "lib/synonym-finder.rb",
    "lib/synonym-finder/duplicate_finder.rb",
    "lib/synonym-finder/group_organizer.rb",
    "spec/spec_helper.rb",
    "spec/support/input.rb",
    "spec/synonym-finder_spec.rb",
    "synonym-finder.gemspec"
  ]
  s.homepage = %q{http://github.com/dimus/synonym-finder}
  s.licenses = [%q{MIT}]
  s.require_paths = [%q{lib}]
  s.rubygems_version = %q{1.8.6}
  s.summary = %q{Synonym finder is a biodiversity tool for finding homotypic nomenclatural synonyms in taxonomic hierarchies.}

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<sqlite3>, [">= 0"])
      s.add_runtime_dependency(%q<taxamatch_rb>, [">= 0"])
      s.add_runtime_dependency(%q<biodiversity19>, [">= 0"])
      s.add_runtime_dependency(%q<ruby-stemmer>, [">= 0"])
      s.add_development_dependency(%q<ruby-debug19>, [">= 0"])
      s.add_development_dependency(%q<rspec>, ["~> 2.3.0"])
      s.add_development_dependency(%q<cucumber>, [">= 0"])
      s.add_development_dependency(%q<bundler>, ["~> 1.0.0"])
      s.add_development_dependency(%q<jeweler>, ["~> 1.6.0"])
      s.add_development_dependency(%q<rcov>, [">= 0"])
    else
      s.add_dependency(%q<sqlite3>, [">= 0"])
      s.add_dependency(%q<taxamatch_rb>, [">= 0"])
      s.add_dependency(%q<biodiversity19>, [">= 0"])
      s.add_dependency(%q<ruby-stemmer>, [">= 0"])
      s.add_dependency(%q<ruby-debug19>, [">= 0"])
      s.add_dependency(%q<rspec>, ["~> 2.3.0"])
      s.add_dependency(%q<cucumber>, [">= 0"])
      s.add_dependency(%q<bundler>, ["~> 1.0.0"])
      s.add_dependency(%q<jeweler>, ["~> 1.6.0"])
      s.add_dependency(%q<rcov>, [">= 0"])
    end
  else
    s.add_dependency(%q<sqlite3>, [">= 0"])
    s.add_dependency(%q<taxamatch_rb>, [">= 0"])
    s.add_dependency(%q<biodiversity19>, [">= 0"])
    s.add_dependency(%q<ruby-stemmer>, [">= 0"])
    s.add_dependency(%q<ruby-debug19>, [">= 0"])
    s.add_dependency(%q<rspec>, ["~> 2.3.0"])
    s.add_dependency(%q<cucumber>, [">= 0"])
    s.add_dependency(%q<bundler>, ["~> 1.0.0"])
    s.add_dependency(%q<jeweler>, ["~> 1.6.0"])
    s.add_dependency(%q<rcov>, [">= 0"])
  end
end

