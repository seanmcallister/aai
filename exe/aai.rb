#!/usr/bin/env ruby

Signal.trap("PIPE", "EXIT")

require "aai"
require "abort_if"
require "fileutils"
require "trollop"

include AbortIf
include AbortIf::Assert

Aai.extend Aai
Aai.extend Aai::Utils

version_banner =

opts = Trollop.options do
  version Aai::VERSION_BANNER

  banner <<-EOS

#{Aai::VERSION_BANNER}

  Seanie's AAI calculator.

  Each input file is treated as a file of ORFs for a single genome.

  Options:
  EOS

  opt(:infiles, "Input files", type: :strings)
  opt(:outdir, "Output directory", type: :string, default: ".")
  opt(:basename, "Base name for output file", type: :string,
      default: "aai_scores")
end

abort_if opts[:infiles].nil? || opts[:infiles].empty?,
         "No infiles given"

Aai.check_files opts[:infiles]

FileUtils.mkdir_p opts[:outdir]

seq_lengths, clean_fnames = Aai.process_input_seqs! opts[:infiles]

blast_db_basenames = Aai.make_blastdbs! clean_fnames

btabs = Aai.blast_permutations! clean_fnames, blast_db_basenames

best_hits = Aai.get_best_hits btabs, seq_lengths

one_way = Aai.one_way_aai best_hits

two_way = Aai.two_way_aai best_hits

aai_strings = Aai.aai_strings one_way, two_way

outf = File.join opts[:outdir], "#{opts[:basename]}.aai.txt"
File.open(outf, "w") do |f|
  Aai.aai_strings(one_way, two_way).each do |str|
    f.puts str
  end
end
