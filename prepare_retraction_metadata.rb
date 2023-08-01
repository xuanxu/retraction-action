require "open-uri"
require "theoj"
require "yaml"

# Generate metadata file for the retraction notice
issue_id = ENV["ISSUE_ID"].to_s
journal_alias = ENV["JOURNAL_ALIAS"]

begin
  journal_data = Theoj::JOURNALS_DATA[journal_alias.to_sym]
  raise "  ‼️ Error: Can't find journal #{journal_alias}" if journal_data.nil?

  journal = Theoj::Journal.new(journal_data)
  doi = journal.paper_doi_for_id(journal.paper_id_from_issue(issue_id))
  paper = Theoj::PublishedPaper.new(doi)
  paper_metadata = paper.metadata

  retraction_metadata = {
    title: "Retraction notice for: " + paper_metadata[:title],
    tags: paper_metadata[:tags],
    authors: [{ given_name: journal_alias.upcase,
                last_name: "Editorial Board",
                affiliation: journal_data.name}],
    doi: paper_metadata[:doi] + "R",
    software_repository_url: paper_metadata[:software_repository_url],
    reviewers: [],
    volume: journal.current_volume,
    issue: journal.current_issue,
    year: journal.current_year,
    page: paper_metadata[:page] + "R",
    journal_alias: journal_alias,
    software_review_url: paper_metadata[:software_review_url],
    archive_doi: paper_metadata[:archive_doi],
    editor: {},
    submitted_at: Time.now.strftime("%Y-%m-%d"),
    published_at: Time.now.strftime("%Y-%m-%d")
  }
  retraction_metadata[:citation_string] = "#{journal_alias.upcase} Editorial Board, (#{retraction_metadata[:year]}). #{retraction_metadata[:title]}. #{journal_data.name}, #{retraction_metadata[:volume]}(#{retraction_metadata[:issue]}), #{retraction_metadata[:review_issue_id]}, https://doi.org/#{retraction_metadata[:doi]}"

rescue Theoj::Error => e
  raise "  ‼️ Error: #{e.message}"
end

retraction_metadata.transform_keys!(&:to_s)

metadata_file_path = File.dirname(__FILE__) + "/retraction-notice-metadata.yaml"

File.open(metadata_file_path, "w") do |f|
  f.write retraction_metadata.to_yaml
end

if File.exist?(metadata_file_path)
  system("echo 'Metadata created for retraction paper!'")
else
  raise "   !! ERROR: Retraction metadata file could not be generated"
end

inara_args = "-m #{metadata_file_path} -l -p -o pdf,crossref,jats"
system("echo 'inara_args=#{inara_args}' >> $GITHUB_OUTPUT")


# Download retraction notice file
retraction_notice_url = ENV["RETRACTION_NOTICE_URL"]
retraction_notice_file_path = File.dirname(__FILE__) + "/retraction-notice-paper.md"

retraction_contents = URI.parse(retraction_notice_url).read

File.open(retraction_notice_file_path, "w") do |f|
  f.write retraction_contents
end

system("echo 'retraction_notice_path=#{retraction_notice_file_path}' >> $GITHUB_OUTPUT")
system("echo 'Retraction notice downloaded!'")

