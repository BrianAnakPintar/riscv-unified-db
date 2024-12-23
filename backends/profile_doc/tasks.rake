# frozen_string_literal: true

rule %r{#{$root}/gen/profile_doc/adoc/.*\.adoc} => proc { |tname|
  profile_release_name = Pathname.new(tname).basename(".adoc")

  [
    "#{$root}/.stamps/arch-gen.stamp",
    __FILE__,
    "#{$root}/lib/arch_obj_models/profile.rb",
    "#{$root}/backends/profile_doc/templates/profile.adoc.erb"
  ] + Dir.glob("#{$root}/arch/profile_release/**/*.yaml")
} do |t|
  profile_release_name = Pathname.new(t.name).basename(".adoc").to_s

  profile_release = arch_def_for("_64").profile_release(profile_release_name)
  raise ArgumentError, "No profile release named '#{profile_release_name}'" if profile_release.nil?
  profile_class = profile_release.profile_class

  template_path = Pathname.new "#{$root}/backends/profile_doc/templates/profile.adoc.erb"
  erb = ERB.new(template_path.read, trim_mode: "-")
  erb.filename = template_path.to_s

  arch_def = arch_def_for("_64")

  # XXX - Add call to to_arch_def() in portfolio instance class.
  # But somehow have to merge the multiple portofolios in one profile release to one since
  # to_arch_def used to provide coloring of fields in CSRs in appendices that apply to all profiles in a release.

  FileUtils.mkdir_p File.dirname(t.name)
  File.write t.name, AsciidocUtils.resolve_links(arch_def.find_replace_links(erb.result(binding)))
  puts "Generated adoc source at #{t.name}"
end

rule %r{#{$root}/gen/profile_doc/pdf/.*\.pdf} => proc { |tname|
  profile_release_name = Pathname.new(tname).basename(".pdf")
  [__FILE__, "#{$root}/gen/profile_doc/adoc/#{profile_release_name}.adoc"]
} do |t|
  profile_release_name = Pathname.new(t.name).basename(".pdf")

  adoc_filename = "#{$root}/gen/profile_doc/adoc/#{profile_release_name}.adoc"

  FileUtils.mkdir_p File.dirname(t.name)
  sh [
    "asciidoctor-pdf",
    "-w",
    "-v",
    "-a toc",
    "-a compress",
    "-a pdf-theme=#{$root}/ext/docs-resources/themes/riscv-pdf.yml",
    "-a pdf-fontsdir=#{$root}/ext/docs-resources/fonts",
    "-a imagesdir=#{$root}/ext/docs-resources/images",
    "-r asciidoctor-diagram",
    "-r #{$root}/backends/ext_pdf_doc/idl_lexer",
    "-o #{t.name}",
    adoc_filename
  ].join(" ")

  puts
  puts "SUCCESS! File written to #{t.name}"
end

rule %r{#{$root}/gen/profile_doc/html/.*\.html} => proc { |tname|
  profile_release_name = Pathname.new(tname).basename(".html")
  [__FILE__, "#{$root}/gen/profile_doc/adoc/#{profile_release_name}.adoc"]
} do |t|
  profile_release_name = Pathname.new(t.name).basename(".html")

  adoc_filename = "#{$root}/gen/profile_doc/adoc/#{profile_release_name}.adoc"

  FileUtils.mkdir_p File.dirname(t.name)
  sh [
    "asciidoctor",
    "-w",
    "-v",
    "-a toc",
    "-a imagesdir=#{$root}/ext/docs-resources/images",
    "-r asciidoctor-diagram",
    "-r #{$root}/backends/ext_pdf_doc/idl_lexer",
    "-o #{t.name}",
    adoc_filename
  ].join(" ")

  puts
  puts "SUCCESS! File written to #{t.name}"
end

namespace :gen do
  desc "Create a specification PDF for +profile_release+"
  task :profile, [:profile_release] => ["#{$root}/.stamps/arch-gen-_64.stamp"] do |_t, args|
    profile_release_name = args[:profile_release]
    raise ArgumentError, "Missing required option +profile_release+" if profile_release_name.nil?

    profile_release = arch_def_for("_64").profile_release(profile_release_name)
    raise ArgumentError, "No profile release named '#{profile_release_name}'" if profile_release.nil?

    Rake::Task["#{$root}/gen/profile_doc/pdf/#{profile_release_name}.pdf"].invoke
  end

  desc "Create a specification HTML for +profile_release+"
  task :profile_html, [:profile_release] => ["#{$root}/.stamps/arch-gen-_64.stamp"] do |_t, args|
    profile_release_name = args[:profile_release]
    raise ArgumentError, "Missing required option +profile_release+" if profile_release_name.nil?

    profile_release = arch_def_for("_64").profile_release(profile_release_name)
    raise ArgumentError, "No profile release named '#{profile_release_name}" if profile_release.nil?

    Rake::Task["#{$root}/gen/profile_doc/html/#{profile_release_name}.html"].invoke
  end
end
