require "crake/global"
require "omegatribute"

task "apply_translation" do
  omegat_target_dir = File.join(
    Dir.working_directory,
    "ja.crystal-lang.org-omegat/target/"
  )
  repository_dir = File.join(
    Dir.working_directory,
    "ja.crystal-lang.org"
  )
  puts omegat_target_dir
  puts repository_dir
  Omegatribute.copy_back_md_to_repo(omegat_target_dir, repository_dir)
end

task "check_update" do
  Dir.cd(File.join(Dir.working_directory, "crystal"))
  puts Dir.working_directory
  `git remote update`
  result = `git rev-list master..origin/master`
  if result.chomp.empty?
    puts "No changes"
  else
    puts result
  end
end

task "copy_source_files" do
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
