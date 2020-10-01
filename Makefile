API_KEY=REDACTED
BASE_ID=REDACTED
TABLE_NAME=REDACTED
ENV=API_KEY=$(API_KEY) \
	BASE_ID=$(BASE_ID) \
	TABLE_NAME=$(TABLE_NAME)

help:
	@echo "options: console, test, test_no_external"

# Run a console with external APIs activated
console:
	@$(ENV) iex -S mix

# Run every damned test we've got
tests:
	@$(ENV) mix test --include external_api

# Run tests without external APIs
tests_no_external:
	@$(ENV) mix test --exclude external_api
