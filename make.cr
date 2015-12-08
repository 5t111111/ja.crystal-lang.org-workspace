require "colorize"
require "yaml"
require "crake/global"
require "omegatribute"

private def config_file
  "./config.yml"
end

namespace "update" do
  # Check if upstream crystal repository is updated
  task "check" do
    Dir.cd(File.join(Dir.working_directory, "crystal"))
    `git remote update`
    result = `git log --oneline --color --decorate gh-pages..origin/gh-pages`
    puts "* Local HEAD ref ".ljust(80, '*').colorize(:magenta).mode(:bold)
    puts `git rev-parse HEAD`[0..6].colorize(:blue)
    puts "\n"
    if result.chomp.empty?
      puts "No changes".colorize(:light_gray)
    else
      puts "* New commmits ".ljust(80, '*').colorize(:magenta).mode(:bold)
      puts result
      result = `git diff --color origin/gh-pages`
      puts "\n"
      puts "* Diffs ".ljust(80, '*').colorize(:magenta).mode(:bold)
      puts result
    end
  end

  # Pull the changes from upstream Crystal repository
  task "pull" do
    tmp_current_directory = Dir.working_directory
    Dir.cd(File.join(Dir.working_directory, "crystal"))
    # TODO
    # `git pull origin gh-pages`
    puts "* New Local HEAD ref ".ljust(80, '*').colorize(:magenta).mode(:bold)
    new_head_ref = `git rev-parse HEAD`[0..6]
    puts new_head_ref.colorize(:blue)
    puts "\n"
    Dir.cd(tmp_current_directory)
    config = YAML.load(File.read(config_file)) as Hash(YAML::Type, YAML::Type)
    if config["head"] == new_head_ref
      puts "#{config_file} has not been updated."
    else
      File.write(config_file, "head: #{new_head_ref}\n")
      puts "#{config_file} has been updated."
      puts "#{config["head"]} => #{new_head_ref}".colorize(:magenta)
    end
  end

  # Copy Markdown files in the original Crystal repository to "ja.crystal-lang.org-omegat/source/"
  task "copy" do
    upstream_dir = File.join(
      Dir.working_directory,
      "crystal"
    )
    omegat_source_dir = File.join(
      Dir.working_directory,
      "ja.crystal-lang.org-omegat/source/"
    )
    Omegatribute.copy_to_omegat_source_directory(upstream_dir, omegat_source_dir)
  end
end

namespace "release" do
  # Apply translated files in OmegaT to "ja.crystal-lang.org" repository
  #
  # By invoking this, all files in "ja.crystal-lang.org-omegat/target/" will be
  # Copied to the corresponding directory of "ja.crystal-lang.org" repository.
  task "copy" do
    omegat_target_dir = File.join(
      Dir.working_directory,
      "ja.crystal-lang.org-omegat/target/"
    )
    repository_dir = File.join(
      Dir.working_directory,
      "ja.crystal-lang.org"
    )
    Omegatribute.copy_back_md_to_repo(omegat_target_dir, repository_dir)
  end
end
