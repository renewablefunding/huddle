module PathHelpers
  def spec_path
    File.expand_path('..', File.dirname(__FILE__))
  end

  def fixtures_path
    File.join(spec_path, 'fixtures')
  end

  def fixture_path(file_path)
    File.join(fixtures_path, file_path)
  end

  def fixture(file_path)
    File.read(fixture_path(file_path))
  end
end