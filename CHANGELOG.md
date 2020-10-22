# CHANGELOG

- 0.2.5
  - Make `Table.list_async` overrideable in situations where you want to change the default table listing parameters.
  - Clean up `params` for `Table.list` and `Table.list_async` to use Keyword lists in both places (instead of a map in one and a keyword list in the other)
- 0.2.4
  - Add `to_schema()` methods, to make it easier to define a conversion between Airtable field names and in-app field names. Realistically, this will likely be used most in apps that use Ecto schemas internally to validate Airtable data. See `ExAirtable.Table.to_schema` and `ExAirtable.Airtable.Record.to_schema` for more details.
- 0.2.3
  - More fixing of bugs around table naming. Everything is picky about weird table names!
- 0.2.2
  - Fixed a bug that prevented starting a supervisor with multiple tables.
  - Fixed a bug in URI encoding that prevented tables with crazy characters in their names (like "/") from being queried.
- 0.2.1
  - Upgraded to Elixir 1.11.1, and fixed some bugs that came with that. Added ASDF `.tool-versions` to the repo to help with developers who want to pitch in.
- 0.2.0
  - [Removed](https://github.com/exploration/ex_airtable/commit/c6dcdae10762dbdbeff102b226ab18e02678fae2) the `:delete_on_refresh` startup option. The new solution takes inspiration from the hashing approach taken [here](http://codeloveandboards.com/blog/2020/07/27/headless-cms-fun-with-phoenix-liveview-and-airtable-pt-4/), and removes any need to worry about the cache staying up to date. It's relatively performant, and will only churn the whole cache if the Airtable result and the local cache are different.
  - [Converted](https://github.com/exploration/ex_airtable/commit/cb507f5de596fc6e9b63638b254a163ad0e7195e) the `RateLimiter` from two `GenStage` modules to a single `GenServer` module. This is conceptually simpler, and also runs much faster! To be clear, the problem was my misunderstanding and mis-application of `GenStage`, not any inherent problem with `GenStage`.
- 0.1.0 - Initial commit. The thing works!
