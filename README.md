# KeywordParser

A keyword parser for extracting words, phrases and simple patterns from strings of text.  

This module allows you to load up multiple keyword patterns for different topics and run those against strings to extract pattern matches.
When creating a pattern using `new_pattern/2` or `new_pattern/3` a list of keywords/phrases is given along with a name used for identification. 
When parsing strings of text, pattern names can be given as a list (or one individually) to specify which patterns you want to use when parsing the string.
The atom `:all` can be passed in as an individual pattern_name argument to invoke the use of all available patterns.
Once created all patterns get stored as processes and will exist until killed individually (`kill_pattern/1`) or the application is killed as a whole.

```elixir
iex> Keywords.new_pattern("clothing_brands", ["converse", "nike", "adidas", "paige", "hanes"])
{:ok, "clothing_brands"}

iex> Keywords.new_pattern("retail_companies", ["amazon", "walmart", "home depot"])
{:ok, "retail_companies"}

iex> string = """
Been wearing converse low tops for the past 20 years. Purchased these maroon Chuck Taylor low tops recently, and I wasn’t thrilled..

Beyond the fit, there are videos online showing how to tell if Chuck Taylor converse are counterfeit or real.. I purchased a shoe with the “o” in converse having a star in the center. That is how to tell if they’re legitimate sneakers made by converse. What I received by amazon are sneakers with a plain old “o” , no star, see photos..

It’s increasingly frustrating to pay for prime membership, but feel like your just another shopper. I don’t feel like it’s my job to dig through countless sellers on amazon to determine which are selling legitimate products, and which are selling knock off nike and converse shoes.
Amazon should be doing a better job at that.
"""

iex> Keywords.parse(string, ["clothing_brands", "retail_companies"])
{:ok, ["converse", "amazon", "nike"]}

iex> Keywords.parse(string, ["clothing_brands", "retail_companies"], counts: true)
{:ok, [{"converse", 4}, {"amazon", 2}, {"nike", 1}]}

iex> Keywords.parse(string, ["clothing_brands", "retail_companies"], aggreagte: false)
{:ok, ["clothing_brands": ["converse", "nike"], "retail_companies": ["amazon"]]}
```

## Docs

#### HexDocs: [https://hexdocs.pm/keywords](https://hexdocs.pm/keywords)

## Installation

When [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `keywords` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    #{:keywords, "~> 0.1.0"}
  ]
end
```

## Functions

### new_pattern
#### Creates a new keyword pattern from a list of keywords
```elixir
new_pattern(name, keywords_list, opts)
```

options include:
- `:case_sensitive` | default = `false` | toggles whether keyword matches case sensitive.

### parse
#### Extracts keywords from a string
```elixir
parse(string, pattern_names, opts)
```

options include:
- `case_sensitive:` | default = `false` | toggles whether keywords are case sensitive.

Usage:
```elixir
iex> Keywords.new_pattern("stocks", ["TSLA", "XOM", "AMZN", "FB", "LMT", "NVDA"])
{:ok, "stocks"}

iex> Keywords.new_pattern("stocks", ["TSLA", "XOM", "AMZN", "FB", "LMT", "NVDA"], case_sensitive: true)
{:ok, "stocks"}
```

options include:
- `:counts` | default = `false` | toggles counts for individual keyword occurrences in results.
- `:aggregate` | default = `true` | toggles grouping by pattern name.

Usage:
```elixir
iex> Keywords.parse("My favorite picks right now are $NVDA and $AMZN 🚀🚀🚀, but XOM and fb have my attention 🌝", "stocks")
{:ok, ["NVDA", "AMZN", "XOM", "FB"]}

iex> Keywords.parse("How dare you @^%##! %&^?!?! *****!", "cartoon_profanity")
{:ok, ["@^%##!", "%&^?!?!", "*****"]}

iex> Keywords.parse("How dare you @^%##! %&^?!?! ***** *****!", "cartoon_profanity", counts: true)
{:ok, [{"@^%##!", 1}, {"%&^?!?!", 1}, {"*****", 2}]}

iex> Keywords.parse("How dare you put pineapple on a pizza you @^%##! %&^?!?! ***** *****!", ["cartoon_profanity", "illegal_pizza_toppings"], counts: true, aggregate: false)
{
  :ok, 
  [
    { "cartoon_profanity", [{"@^%##!", 1}, {"%&^?!?!", 1}, {"*****", 2}] }, 
    { "illegal_pizza_toppings", [{"pineapple", 1}] }
  ]
}
```

### kill_pattern
#### Kills pattern agent and removes a pattern from registry
```elixir
kill_pattern(name)
```
Usage:
```elixir
iex> Keywords.kill_pattern("common_lyrics")
{:ok, "common_lyrics"}
```
