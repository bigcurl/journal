# frozen_string_literal: true
require 'minitest/autorun'

class TestDietTemplates < Minitest::Test
  def setup
    @base = File.expand_path(File.join(__dir__, '..'))
    @diet_dir = File.join(@base, 'templates', 'diet')
  end

  def test_diet_templates_exist
    %w[daily.md.erb weekly.md.erb monthly.md.erb].each do |file|
      path = File.join(@diet_dir, file)
      assert File.exist?(path), "Missing template: #{path}"
      refute_equal 0, File.size(path), "Empty template: #{path}"
    end
  end
end
