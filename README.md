# Open Journals :: Retraction
GitHub Action to generate Open Journal's retraction notices

## Usage

This action is meant to be run manually

### Inputs

The action requires the following inputs:

- **crossref_filepath**: Required. The complete filepath of the Crossref XML file
- **crossref_username**: Required. Crossref username doing the deposit
- **crossref_password**: Required. Crossref password
- **issue_id**: Required. The review issue id for the paper to be retracted
- **retraction_notice_url**: Required. URL for the markdown file of the retraction notice
- **journal**: Optional. The journal where the retracted paper is published. Default is 'joss'.
- **papers_repo**: Optional. The repository for the published papers. Default is 'openjournals/joss-papers'
- **papers_repo_main_branch**: Optional. The name of the repo's main branch to issue the pull request against
- **branch_prefix**: Optional. The prefix to add to the name of all branches
- **github_bot_token**: Required in final mode. The GitHub access token to be used to upload files
- **journal_secret:**: Required in final mode. The access token to be used to deposit the paper
- **mode**: Optional. Set the compiled retraction notice as a draft or as a final published paper. Posible values are 'draft' or 'final'.
