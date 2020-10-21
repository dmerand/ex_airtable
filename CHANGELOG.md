# CHANGELOG

- 0.2.1
  - Upgraded to Elixir 1.11.1, and fixed some bugs that came with that. Added ASDF `.tool-versions` to the repo to help with developers who want to pitch in.
- 0.2.0
  - [Removed](https://github.com/exploration/ex_airtable/commit/c6dcdae10762dbdbeff102b226ab18e02678fae2) the `:delete_on_refresh` startup option. The new solution takes inspiration from the hashing approach taken [here](http://codeloveandboards.com/blog/2020/07/27/headless-cms-fun-with-phoenix-liveview-and-airtable-pt-4/), and removes any need to worry about the cache staying up to date. It's relatively performant, and will only churn the whole cache if the Airtable result and the local cache are different.
  - [Converted](https://github.com/exploration/ex_airtable/commit/cb507f5de596fc6e9b63638b254a163ad0e7195e) the `RateLimiter` from two `GenStage` modules to a single `GenServer` module. This is conceptually simpler, and also runs much faster! To be clear, the problem was my misunderstanding and mis-application of `GenStage`, not any inherent problem with `GenStage`.
- 0.1.0 - Initial commit. The thing works!
