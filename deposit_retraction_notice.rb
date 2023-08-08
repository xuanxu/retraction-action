require "octokit"
require "pathname"

def gh_token
  gh_token_from_env = ENV['BOT_TOKEN'].to_s.strip
  gh_token_from_env = ENV['GH_ACCESS_TOKEN'].to_s.strip if gh_token_from_env.empty?
  raise " ❌ ERROR: Invalid GitHub Token" if gh_token_from_env.empty?
  gh_token_from_env
end

def github_client
  @github_client ||= Octokit::Client.new(access_token: gh_token, auto_paginate: true)
end

def get_main_ref(repo, main_branch)
  main_ref = github_client.refs(repo).select { |r| r[:ref] == "refs/heads/#{main_branch}" }.first
  main_ref.object.sha
end

journal_alias = ENV["JOURNAL_ALIAS"].to_s
issue_id = ENV["ISSUE_ID"].to_s
papers_repo = ENV["PAPERS_REPO"].to_s
papers_repo_main_banch = ENV["PAPERS_REPO_MAIN_BRANCH"] || "main"
branch_prefix = ENV["BRANCH_PREFIX"].to_s

id = "%05d" % issue_id
id += "R"
branch = branch_prefix.empty? ? id.to_s : "#{branch_prefix}.#{id}"
ref = "heads/#{branch}"


# Create branch
begin
  # Check branch existence
  github_client.ref(papers_repo, ref)
  # Delete old branch and create it again
  github_client.delete_ref(papers_repo, ref)
  github_client.create_ref(papers_repo, ref, get_main_ref(papers_repo, papers_repo_main_banch))
rescue Octokit::NotFound
  # Create branch if it doesn't exist
  github_client.create_ref(papers_repo, ref, get_main_ref(papers_repo, papers_repo_main_banch))
end

# Add PDF file
pdf_path = "paper.pdf"
pdf_uploaded_path = "#{branch}/10.21105.#{branch}.pdf"
if !pdf_path.empty? && File.exist?(pdf_path)
  gh_response = github_client.create_contents(papers_repo,
                                              pdf_uploaded_path,
                                              "Creating 10.21105.#{branch}.pdf",
                                              File.open("#{pdf_path.strip}").read,
                                              branch: branch)

  system("echo '📄 PDF file: #{gh_response.content.html_url}'")
else
  raise " ❌ ERROR: Can't find paper.pdf file"
end

# Add Crossref XML file if present
crossref_path = "paper.crossref"
crossref_uploaded_path = "#{branch}/10.21105.#{branch}.crossref.xml"
if !crossref_path.empty? && File.exist?(crossref_path)
  crossref_gh_response = github_client.create_contents(papers_repo,
                                              crossref_uploaded_path,
                                              "Creating 10.21105.#{branch}.crossref.xml",
                                              File.open("#{crossref_path.strip}").read,
                                              branch: branch)

  system("echo '📄 CROSSREF file: #{crossref_gh_response.content.html_url}'")
end

# Add JATS file if present
jats_path = "paper.jats"
jats_uploaded_path = "#{branch}/10.21105.#{branch}.jats"
if !jats_path.empty? && File.exist?(jats_path)
  jats_gh_response = github_client.create_contents(papers_repo,
                                              jats_uploaded_path,
                                              "Creating 10.21105.#{branch}.jats",
                                              File.open("#{jats_path.strip}").read,
                                              branch: branch)

  system("echo '📄 JATS file: #{jats_gh_response.content.html_url}'")

  # Add JATS' media files if present
  media_folder = File.join(File.dirname(jats_path), "media")
  if Dir.exist?(media_folder)
    media_files = Dir[File.join(media_folder, "**/*.*")]
    media_files.each do |media_file|
      media_file_name = Pathname(media_file).relative_path_from(media_folder).to_s
      media_file_uploaded_path = "#{branch}/media/#{media_file_name}"
      github_client.create_contents(papers_repo,
                                    media_file_uploaded_path,
                                    "Adding media file: #{media_file_name}",
                                    File.open(media_file).read,
                                    branch: branch)
    end
  end
end


# Create Pull Request
gh_pr_response = github_client.create_pull_request(papers_repo, papers_repo_main_banch, "#{branch}",
  "Creating pull request for 10.21105.#{branch}", "Retraction notice 10.21105/#{branch}")

# Merge Pull Request
sleep(5)
github_client.merge_pull_request(papers_repo, gh_pr_response.number, "Merging automatically")
github_client.delete_ref(papers_repo, ref)

system("echo '✨ Pull request with all the files: #{gh_pr_response.html_url}'")


# Deposit with Open Journals:

system("echo '🎉 Retraction notice deposited with #{journal_alias.upcase}'")'
