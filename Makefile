API_KEY=REDACTED
BASE_ID=REDACTED
TABLE_NAME=REDACTED
ENV=env API_KEY=$(API_KEY) \
	BASE_ID=$(BASE_ID) \
	TABLE_NAME=$(TABLE_NAME)

help:
	@echo "options: console, test, test_no_external"

# Run a console with external APIs activated
console:
	@$(ENV) iex -S mix

# Run every damned test we've got, except the mutations
tests:
	@$(ENV) mix test --include external_api --exclude external_mutation

# Run tests without external APIs
tests_no_external:
	@$(ENV) mix test --exclude external_api --exclude external_mutation

# Run tests that mutate data in the external table
tests_mutation:
	@$(ENV) mix test --include external_mutation 
