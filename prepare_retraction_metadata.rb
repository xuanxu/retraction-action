require "open-uri"
require "theoj"
require "yaml"

# Generate metadata file for the retraction notice
issue_id = ENV["ISSUE_ID"].to_s
journal_alias = ENV["JOURNAL_ALIAS"]

begin
  journal_data = Theoj::JOURNALS_DATA[journal_alias.to_sym]
  raise " ❌ Error: Can't find journal #{journal_alias}" if journal_data.nil?

  journal = Theoj::Journal.new(journal_data)
  doi = journal.paper_doi_for_id(journal.paper_id_from_issue(issue_id))
  retraction_notice = Theoj::RetractionNotice.new(doi, journal_alias)
  retraction_metadata = retraction_notice.metadata
  retraction_metadata[:citation_string] = retraction_notice.citation_string

rescue Theoj::Error => e
  raise " ❌ Error: #{e.message}"
end

retraction_metadata[:editor].transform_keys!(&:to_s)
retraction_metadata[:authors].each {|author| author.transform_keys!(&:to_s) }
retraction_metadata.transform_keys!(&:to_s)

metadata_file_path = "./retraction-notice-metadata.yaml"

File.open(metadata_file_path, "w") do |f|
  f.write retraction_metadata.to_yaml
end

if File.exist?(metadata_file_path)
  system("echo '✅ Metadata created for retraction paper!: #{metadata_file_path}'")
else
  raise " ❌ ERROR: Retraction metadata file could not be generated"
end

inara_args = "-m #{metadata_file_path} -p -r -o pdf,crossref,jats"
system("echo 'inara_args=#{inara_args}' >> $GITHUB_OUTPUT")


# Download retraction notice file
retraction_notice_url = ENV["RETRACTION_NOTICE_URL"]
retraction_notice_file_path = "./retraction-notice-paper.md"

retraction_contents = URI.parse(retraction_notice_url).read

File.open(retraction_notice_file_path, "w") do |f|
  f.write retraction_contents
end

system("echo 'retraction_notice_path=#{retraction_notice_file_path}' >> $GITHUB_OUTPUT")
system("echo '✅ Retraction notice downloaded!'")

