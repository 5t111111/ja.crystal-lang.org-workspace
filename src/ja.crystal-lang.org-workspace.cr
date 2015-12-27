require "yaml"
require "./ja.crystal-lang.org-workspace/*"

module JaCrystalLangOrg::Workspace
  @@workspace_directory = Dir.current
  @@config_file = File.join(@@workspace_directory, "config.yml")
  @@config = YAML.load(File.read(@@config_file)) as Hash(YAML::Type, YAML::Type)

  def self.pop_workspace_directory
    Dir.cd(@@workspace_directory)
  end

  def self.push_crystal_directory
    Dir.cd(File.join(@@workspace_directory, "crystal"))
  end

  def self.push_ja_crystal_lang_org_directory
    Dir.cd(File.join(@@workspace_directory, "ja.crystal-lang.org"))
  end

  def self.config_file
    @@config_file
  end

  def self.config
    @@config
  end
end
