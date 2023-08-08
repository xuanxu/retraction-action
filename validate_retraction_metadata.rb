require "ojxv"

# print errors in the workflow console
def print_errors(errors, schema, filepath)
  system("echo '!! Invalid #{schema} in #{filepath}. Errors: #{errors.size}. '")
  errors.each do |error|
    system("echo '  - #{error}'")
  end
  raise " ❌ ERROR: Invalid #{schema} file"
end

jats_path = "paper.jats"
crossref_path = "paper.crossref"

# Validate Crossref XML file if present
if File.exist?(crossref_path)
  crossref_file = OJXV::CrossrefMetadataFile.new(crossref_path)

  if crossref_file.valid_crossref?("5.3.1")
    system("echo '✅ [Crossref metadata] Validation successful! The file #{crossref_path} contains valid Crossref XML v5.3.1'")
  else
    print_errors(crossref_file.errors, "Crossref XML v5.3.1", crossref_path)
  end
else
  system("echo '👀❗️ [Crossref metadata] File was not be generated!'")
end

# Validate JATS file if present
if File.exist?(jats_path)
  jats_file = OJXV::JatsFile.new(jats_path)

  if jats_file.valid_jats?("1.3")
    system("echo '✅ [JATS metadata] Validation successful! The file #{jats_path} contains valid JATS v1.3'")
  else
    print_errors(jats_file.errors, "JATS v1.3", jats_path)
  end
else
  system("echo '👀❗️ [JATS metadata] File was not be generated!'")
end

system("echo '🎉 Retraction metadata processed!'")
