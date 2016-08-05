#!/usr/bin/env ruby
require 'paru/pandoc'
require 'paru/filter'

# Treat first argument as input file and second as output file
markdown = File.read(ARGV.first)

json = Paru::Pandoc.new do
    from 'markdown'
    to 'json'
    standalone
    toc
    # filter "examples/simple_filter.rb"
    # add any pandoc option you like
end << markdown

# output = File.open(ARGV.last, "w"){ |output| output.puts html }
# puts html


Paru::Filter.run(:in => StringIO.new(json), :out => StringIO.new) do |doc|
  with "Div.example > Header" do |header|
    PP.pp [header.inner_markdown], $stderr
  end
  with "Para > Link" do |str|
    PP.pp [:LINK, str.target], $stderr
  end
  with "Para" do |para|
    PP.pp [:PARA, para.inner_markdown]
  end
  with "Para > Str" do |str|
    PP.pp [:PARA_STR, str.ast_contents], $stderr
  end
  with "Header.class > Str" do |str|
    PP.pp [:HEADER_STR, str.ast_contents], $stderr
  end
end
