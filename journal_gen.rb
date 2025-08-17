#!/usr/bin/env ruby
# frozen_string_literal: true

require 'date'
require 'erb'
require 'yaml'
require 'clamp'
require 'fileutils'
require 'open3'

WEEKDAY = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday].freeze

def to_date(obj)
  return obj if obj.is_a?(Date)
  return Date.parse(obj) if obj.is_a?(String)

  Date.parse(obj.to_s)
rescue ArgumentError
  raise ArgumentError, "Could not coerce #{obj.inspect} to Date"
end

def render_template(path, locals = {})
  erb = ERB.new(File.read(path), trim_mode: '-')
  context = Object.new
  locals.each { |k, v| context.instance_variable_set(:"@#{k}", v) }
  context.define_singleton_method(:get_binding) { binding }
  erb.result(context.get_binding)
end

def ensure_file_header(file_path, header_template, sep_template)
  return if File.exist?(file_path) && File.size?(file_path)

  File.open(file_path, 'a:utf-8') do |f|
    f.write render_template(header_template, {})
    f.write render_template(sep_template, {})
  end
end

def extract_last_date_in_file(path)
  return nil unless File.exist?(path)

  last_date = nil
  re = /##\s*🗓️\s*(\d{4}-\d{2}-\d{2})/
  File.foreach(path, encoding: 'utf-8') do |line|
    next unless (m = line.match(re))

    begin
      d = Date.parse(m[1])
      last_date = d if last_date.nil? || d > last_date
    rescue ArgumentError
    end
  end
  last_date
end

def iso_week_range_for(date_like)
  date = to_date(date_like)
  monday = date - (date.cwday - 1)
  sunday = monday + 6
  [monday, sunday]
end

def append(content, path)
  File.open(path, 'a:utf-8') { |f| f.write(content) }
end

def load_config(config_path)
  return {} unless File.exist?(config_path)

  YAML.safe_load(File.read(config_path)) || {}
rescue StandardError
  {}
end

def list_sets(templates_dir)
  Dir.children(templates_dir)
     .select { |n| File.directory?(File.join(templates_dir, n)) && n != 'shared' }
     .sort
end

def which(cmd)
  exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
  ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
    exts.each do |ext|
      exe = File.join(path, "#{cmd}#{ext}")
      return exe if File.executable?(exe) && !File.directory?(exe)
    end
  end
  nil
end

def run!(argv, chdir: nil)
  stdout, stderr, status = Open3.capture3(*argv, chdir: chdir)
  [status.success?, stdout, stderr, status.exitstatus]
end

class JournalGen < Clamp::Command
  option ['-f', '--file'], 'FILE', 'Markdown journal file to create or extend'
  option ['-o', '--output-dir'], 'DIR', 'Directory for new journal file (used only if --file is not given)'
  option ['-w', '--weeks'], 'N', 'Number of weeks to generate (default: 4)', default: 4 do |s|
    i = Integer(s)
    raise ArgumentError, 'weeks must be >= 1' if i < 1

    i
  end
  option ['-t', '--template-dir'], 'DIR', 'Directory with ERB templates (default: ./templates)'
  option ['-s', '--set'], 'NAME', 'Question set (folder in templates/, default from config or "personal")'
  option ['--skip-weekly'], :flag, 'Skip weekly summary blocks'
  option ['--skip-monthly'], :flag, 'Skip 4-week “monthly” summary blocks'
  option ['--start-next-monday'], :flag, 'Start generation on the next Monday (instead of the day after last entry)'
  option ['--dry-run'], :flag, 'Print planned dates, do not write'
  option ['--list-sets'], :flag, 'List available sets and exit'

  option ['--export', '--format'], 'FORMAT', 'Output format: md or pdf (default: md)', default: 'md',
                                                                                       attribute_name: :format
  option ['--delete-md'], :flag, 'When --export pdf is used, delete the intermediate .md file (default: keep)'
  option ['--pandoc'], 'PATH', 'Path to pandoc executable (default: search PATH)'

  def execute
    tdir = template_dir || File.join(__dir__, 'templates')
    config_path = File.join(__dir__, 'config.yml')
    cfg = load_config(config_path)

    if format.downcase == 'pdf' && (file.nil? || file.strip.empty?)
      abort 'Error: --file is required when using --export pdf'
    end

    if list_sets?
      puts "Available sets in #{tdir}:"
      puts(list_sets(tdir).map { |n| "- #{n}" })
      return
    end

    chosen_set = set || cfg['default_set'] || 'personal'
    available = list_sets(tdir)
    unless available.include?(chosen_set)
      warn "Warning: set '#{chosen_set}' not found in #{tdir}. Available: #{available.join(', ')}"
      chosen_set = 'personal'
    end

    header_template  = File.join(tdir, 'shared', 'header.md.erb')
    sep_template     = File.join(tdir, 'shared', 'separator.md.erb')
    day_template     = File.join(tdir, chosen_set, 'day.md.erb')
    weekly_template  = File.join(tdir, chosen_set, 'weekly.md.erb')
    monthly_template = File.join(tdir, chosen_set, 'monthly.md.erb')
    [header_template, sep_template, day_template, weekly_template, monthly_template].each do |p|
      abort "Missing template: #{p}" unless File.exist?(p)
    end

    md_target =
      if file && !file.strip.empty?
        file
      else
        fname = "journal-#{Date.today}.md"
        if output_dir && !output_dir.strip.empty?
          FileUtils.mkdir_p(output_dir)
          File.join(output_dir, fname)
        else
          fname
        end
      end

    md_target = md_target.sub(/\.pdf\z/i, '.md') if File.extname(md_target).downcase == '.pdf'

    ensure_file_header(md_target, header_template, sep_template)

    last = extract_last_date_in_file(md_target)
    base_start = to_date(last ? (last + 1) : Date.today)
    start_date = start_next_monday? ? (base_start + ((8 - base_start.cwday) % 7)) : base_start
    start_date = to_date(start_date)
    total_days = Integer(weeks) * 7
    end_date   = start_date + (total_days - 1)

    if dry_run?
      puts "Would write to: #{md_target}"
      puts "Set: #{chosen_set} (templates from #{tdir})"
      puts "Range: #{start_date} .. #{end_date} (#{weeks} week#{weeks == 1 ? '' : 's'})"
      puts "Weekly summaries: #{skip_weekly? ? 'skipped' : 'included after ISO Sunday'}"
      puts "Monthly summaries: #{skip_monthly? ? 'skipped' : 'included'}"
      puts "Format: #{format}"
      return
    end

    current = start_date
    days_written = 0

    while current <= end_date
      append(render_template(day_template, { date: current, weekday: WEEKDAY[current.wday] }), md_target)
      append(render_template(sep_template, {}), md_target)

      if !skip_weekly? && current.wday.zero?
        monday, sunday = iso_week_range_for(current)
        append(
          render_template(weekly_template,
                          { kw: current.cweek, cwy: current.cwyear, monday: monday, sunday: sunday }), md_target
        )
        append(render_template(sep_template, {}), md_target)
      end

      current = to_date(current) + 1
      days_written += 1

      next unless !skip_monthly? && (days_written % 28).zero?

      block_start = to_date(current) - 28
      block_end   = to_date(current) - 1
      append(render_template(monthly_template, { start_date: block_start, end_date: block_end }), md_target)
      append(render_template(sep_template, {}), md_target)
    end

    if format.downcase == 'pdf'
      pdf_target = md_target.sub(/\.md\z/i, '.pdf')
      pandoc_bin = pandoc && !pandoc.strip.empty? ? pandoc : which('pandoc')
      abort 'Error: pandoc not found. Install pandoc or pass --pandoc /path/to/pandoc.' unless pandoc_bin

      ok, _out, err, code = run!([pandoc_bin, md_target, '-o', pdf_target])
      abort "pandoc failed (exit #{code}).\n#{err}" unless ok

      if delete_md?
        FileUtils.rm_f(md_target)
        puts "PDF written: #{pdf_target} (deleted markdown)"
      else
        puts "PDF written: #{pdf_target} (markdown kept: #{md_target})"
      end
    else
      puts "Markdown written: #{md_target}"
    end

    puts "Set: #{chosen_set}"
    puts "Added days: #{start_date} .. #{end_date}"
    puts "Weekly summaries: #{skip_weekly? ? 'skipped' : 'included after ISO Sunday'}"
    puts "Monthly summaries: #{skip_monthly? ? 'skipped' : 'included'}"
  end
end

JournalGen.run if $PROGRAM_NAME == __FILE__
