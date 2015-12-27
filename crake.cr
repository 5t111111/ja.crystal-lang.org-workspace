require "colorize"
require "crake/global"
require "omegatribute"
require "./src/ja.crystal-lang.org-workspace"

task "status" do
  puts "HEAD: #{JaCrystalLangOrg::Workspace.config["head"]}"
  puts "Copied?: #{JaCrystalLangOrg::Workspace.config["copied"]}"
end

namespace "update" do
  # Check if upstream crystal repository is updated
  task "check" do
    Dir.cd(File.join(Dir.current, "crystal"))
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
    JaCrystalLangOrg::Workspace.push_crystal_directory
    `git pull origin gh-pages`
    puts "* New Local HEAD ref ".ljust(80, '*').colorize(:magenta).mode(:bold)
    new_head_ref = `git rev-parse HEAD`[0..6]
    puts new_head_ref.colorize(:blue)
    puts "\n"
    JaCrystalLangOrg::Workspace.pop_workspace_directory
    if JaCrystalLangOrg::Workspace.config["head"] == new_head_ref
      puts "#{File.basename(JaCrystalLangOrg::Workspace.config_file)} has not been updated."
    else
      File.write(JaCrystalLangOrg::Workspace.config_file, "head: #{new_head_ref}\ncopied: false\n")
      puts "#{File.basename(JaCrystalLangOrg::Workspace.config_file)} has been updated."
      puts "#{JaCrystalLangOrg::Workspace.config["head"]} => #{new_head_ref}".colorize(:magenta)
      puts "JaCrystalLangOrg::Workspace.config[\"copied\"] => false".colorize(:magenta)
    end
  end

  # Copy Markdown files in the original Crystal repository to "ja.crystal-lang.org-omegat/source/"
  task "copy" do
    upstream_dir = File.join(
      Dir.current,
      "crystal"
    )
    omegat_source_dir = File.join(
      Dir.current,
      "ja.crystal-lang.org-omegat/source/"
    )
    Omegatribute.copy_from_repo_to_omegat_source(upstream_dir, omegat_source_dir)
    if JaCrystalLangOrg::Workspace.config["copied"] == "false"
      File.write(JaCrystalLangOrg::Workspace.config_file, "head: #{JaCrystalLangOrg::Workspace.config["head"]}\ncopied: true\n")
      puts "#{File.basename(JaCrystalLangOrg::Workspace.config_file)} has been updated."
      puts "JaCrystalLangOrg::Workspace.config[\"copied\"] => true".colorize(:magenta)
    else
      puts "#{File.basename(JaCrystalLangOrg::Workspace.config_file)} has not been updated."
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
      Dir.current,
      "ja.crystal-lang.org-omegat/target/"
    )
    repository_dir = File.join(
      Dir.current,
      "ja.crystal-lang.org"
    )
    Omegatribute.copy_back_from_omegat_target_to_repo(omegat_target_dir, repository_dir)
  end

  task "check" do
    JaCrystalLangOrg::Workspace.push_ja_crystal_lang_org_directory
    puts "* Files to be committed ".ljust(80, '*').colorize(:magenta).mode(:bold)
    puts `git status -s`
    JaCrystalLangOrg::Workspace.pop_workspace_directory
  end

  task "commit", deps: %w(status) do
    JaCrystalLangOrg::Workspace.push_ja_crystal_lang_org_directory
    puts "\n* Branch ".ljust(80, '*').colorize(:magenta).mode(:bold)
    branch = "#{JaCrystalLangOrg::Workspace.config["head"]}-#{Time.now.to_s("%Y-%m-%d")}"
    `git checkout -b #{branch}`
    puts branch.colorize(:yellow)
    result = `git status -s`
    files = result.split("\n").map { |line| line.sub(/^\s*(M|A|D|R|C|U)\s+/, "") }
    commit_message = "Translate #{files.join(", ")} (#{JaCrystalLangOrg::Workspace.config["head"]})"
    puts "\n* Commit message ".ljust(80, '*').colorize(:magenta).mode(:bold)
    puts commit_message

    `git add -A`
    `git commit -m"#{commit_message}"`
    JaCrystalLangOrg::Workspace.pop_workspace_directory
  end
end
