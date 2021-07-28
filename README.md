# KeywordParser

A keyword parser for extracting words, phrases and simple patterns from strings of text.  

This module allows you to load up multiple keyword patterns for different topics and run those against strings.

```elixir
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
```Keywords.new_pattern(name, keywords_list)```

options include:
- `:case_sensitive` true/false | default = false | toggles whether keyword matches case sensitive.

### parse
#### Extracts keywords from a string
```parse(string, pattern_names, opts)```

options include:
- `:counts` true/false | default = false | toggles counts for individual keyword occurrences in results.
- `:aggregate` true/fale | default = true | toggles grouping by pattern name.

### kill_pattern
#### Kills pattern agent and removes a pattern from registry
```kill_pattern(name)```


## Usage

```elixir
iex> Keywords.new_pattern("stocks", ["TSLA", "XOM", "AMZN", "FB", "LMT", "NVDA"])
{:ok, "stocks"}

iex> Keywords.parse("My favorite picks right now are $NVDA and $AMZN 🚀🚀🚀, but XOM and fb have my attention 🌝", "stocks")
{:ok, ["NVDA", "AMZN", "XOM", "FB"]}

iex> Keywords.kill_pattern("stocks")
{:ok, :stocks}
```