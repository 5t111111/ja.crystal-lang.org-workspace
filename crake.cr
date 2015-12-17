require "colorize"
require "yaml"
require "crake/global"
require "omegatribute"

private def config_file
  "./config.yml"
end

task "status" do
  config = YAML.load(File.read(config_file)) as Hash(YAML::Type, YAML::Type)
  puts "HEAD: #{config["head"]}"
  puts "Copied?: #{config["copied"]}"
end

namespace "update" do
  # Check if upstream crystal repository is updated
  task "check" do
    Dir.cd(File.join(Dir.working_directory, "crystal"))
    `git remote update`
    result = `git log --oneline --color --decorate HEAD..origin/gh-pages`
    puts "* Local HEAD ref ".ljust(80, '*').colorize(:magenta).mode(:bold)
    puts `git rev-parse HEAD`[0..6].colorize(:blue)
    puts "\n"
    if result.chomp.empty?
      puts "No changes".colorize(:light_gray)
    else
      puts "* New commmits ".ljust(80, '*').colorize(:magenta).mode(:bold)
      puts result
      result = `git diff --color origin/gh-pages *.md`
      puts "\n"
      puts "* Diffs (Markdown files only) ".ljust(80, '*').colorize(:magenta).mode(:bold)
      puts result
    end
  end

  # Pull the changes from upstream Crystal repository
  task "pull" do
    tmp_current_directory = Dir.working_directory
    Dir.cd(File.join(Dir.working_directory, "crystal"))
    `git pull origin gh-pages`
    puts "* New Local HEAD ref ".ljust(80, '*').colorize(:magenta).mode(:bold)
    new_head_ref = `git rev-parse HEAD`[0..6]
    puts new_head_ref.colorize(:blue)
    puts "\n"
    Dir.cd(tmp_current_directory)
    config = YAML.load(File.read(config_file)) as Hash(YAML::Type, YAML::Type)
    if config["head"] == new_head_ref
      puts "#{config_file} has not been updated."
    else
      File.write(config_file, "head: #{new_head_ref}\ncopied: false\n")
      puts "#{config_file} has been updated."
      puts "#{config["head"]} => #{new_head_ref}".colorize(:magenta)
      puts "config[\"copied\"] => false".colorize(:magenta)
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
    Omegatribute.copy_from_repo_to_omegat_source(upstream_dir, omegat_source_dir)
    config = YAML.load(File.read(config_file)) as Hash(YAML::Type, YAML::Type)
    if config["copied"] == "false"
      File.write(config_file, "head: #{config["head"]}\ncopied: true\n")
      puts "#{config_file} has been updated."
      puts "config[\"copied\"] => true".colorize(:magenta)
    else
      puts "#{config_file} has not been updated."
    end
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
    Omegatribute.copy_back_from_omegat_target_to_repo(omegat_target_dir, repository_dir)
  end

  task "check" do
    tmp_current_directory = Dir.working_directory
    Dir.cd(File.join(Dir.working_directory, "ja.crystal-lang.org"))
    puts "* Files to be committed ".ljust(80, '*').colorize(:magenta).mode(:bold)
    puts `git status -s`
    Dir.cd(tmp_current_directory)
  end

  task "commit", deps: %w(status) do
    config = YAML.load(File.read(config_file)) as Hash(YAML::Type, YAML::Type)
    Dir.cd(File.join(Dir.working_directory, "ja.crystal-lang.org"))
    puts "\n* Branch ".ljust(80, '*').colorize(:magenta).mode(:bold)
    branch = "#{config["head"]}-#{Time.now.to_s("%Y-%m-%d")}"
    `git checkout -b #{branch}`
    puts branch.colorize(:yellow)
    result = `git status -s`
    files = result.split("\n").map { |line| line.sub(/^\s*(M|A|D|R|C|U)\s+/, "") }
    commit_message = "Translate #{files.join(", ")} (#{config["head"]})"
    puts "\n* Commit message ".ljust(80, '*').colorize(:magenta).mode(:bold)
    puts commit_message

    `git add -A`
    `git commit -m"#{commit_message}"`
  end
end
