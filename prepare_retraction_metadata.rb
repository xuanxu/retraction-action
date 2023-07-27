require "theoj"
require "yaml"

issue_id = ENV["ISSUE_ID"]
journal_alias = ENV["JOURNAL_ALIAS"]

journal = Theoj::Journal.new(Theoj::JOURNALS_DATA[journal_alias.to_sym])
issue = Theoj::ReviewIssue.new(journal.data[:reviews_repository], issue_id)
