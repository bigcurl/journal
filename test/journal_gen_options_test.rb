require 'minitest/autorun'
require_relative '../journal_gen'

class JournalGenOptionsTest < Minitest::Test
  def new_command(*args)
    cmd = JournalGen.new('journal_gen')
    cmd.parse(args)
    cmd
  end

  def test_default_weeks
    cmd = new_command
    assert_equal 4, cmd.weeks
  end

  def test_weeks_option_sets_value
    cmd = new_command('--weeks', '2')
    assert_equal 2, cmd.weeks
  end

  def test_weeks_must_be_positive
    cmd = JournalGen.new('journal_gen')
    assert_raises(Clamp::UsageError) { cmd.parse(['--weeks', '0']) }
  end

  def test_flags
    cmd = new_command('--skip-weekly', '--skip-monthly', '--start-next-monday', '--dry-run', '--list-sets', '--delete-md')
    assert cmd.skip_weekly?
    assert cmd.skip_monthly?
    assert cmd.start_next_monday?
    assert cmd.dry_run?
    assert cmd.list_sets?
    assert cmd.delete_md?
  end

  def test_string_options
    cmd = new_command('--file', 'my.md', '--output-dir', 'out', '--template-dir', 'templates', '--set', 'work', '--format', 'pdf', '--pandoc', '/usr/bin/pandoc')
    assert_equal 'my.md', cmd.file
    assert_equal 'out', cmd.output_dir
    assert_equal 'templates', cmd.template_dir
    assert_equal 'work', cmd.set
    assert_equal 'pdf', cmd.format
    assert_equal '/usr/bin/pandoc', cmd.pandoc
  end
end
