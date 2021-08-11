use rustler::{Atom, Encoder, Env, NifResult, NifTuple, Term};
#[macro_use] extern crate lazy_static;

use substring::Substring;

mod atoms {
    rustler::atoms! {
        ok,
        error,
    }
}

#[derive(NifTuple)]
pub struct ModuleResourceResponse {
    status: rustler::Atom,
    result: String,
}

// NifResult<Atom>
#[rustler::nif]
fn return_atom() -> NifResult<ModuleResourceResponse> {
  return Ok(ModuleResourceResponse {status: atoms::ok(), result: "Success".to_string()});
}

pub const PERMITTED_CHARS: &'static [char] = &[
  ' ', '.', ',', '!', '?', '#', '$', '%', '^', '&', '@',
  '(', ')', '>', '<', '/', '\\', '|', '[', ']', '{', '}',
  '~', '*', '-', '_', '+', '=', ':', ';', '"', '\'', '`'
];

// pattern = :binary.compile_pattern(["the", "hello", "fox"])
// :binary.matches("the quick hello brown fox jumps", pattern)
// [{10, 5}, {22, 3}]
// Parser.find_matches(10, 5, "the quick hello brown fox jumps")
// Parser.find_matches(22, 3, "the quick hello brown fox jumps")
//  Parser.find_matches(0, 3, "the quick hello brown fox jumps")

#[rustler::nif]
fn find_matches(start_pos: usize, match_length: usize, text: String) ->  NifResult<ModuleResourceResponse> {
    let string_length = text.chars().count();

    // println!("{:?}", atoms::ok());

    if ((start_pos + match_length) > string_length) || (match_length <= 0) {
      return Ok(ModuleResourceResponse {status: atoms::error(), result: "".to_string()});
    };

    let end_pos = start_pos + match_length;

    if start_pos == 0 && end_pos == string_length {
      return get_match(start_pos, end_pos, &text);

    } else if start_pos == 0 {
      if is_trailing_char_valid(end_pos, &text) {
        return get_match(start_pos, end_pos, &text);
      }

    } else if end_pos == string_length {
      if is_leading_char_valid(start_pos, &text) {
        return get_match(start_pos, end_pos, &text);
      }

    } else {
      if is_leading_char_valid(start_pos, &text) && is_trailing_char_valid(end_pos, &text) {
        return get_match(start_pos, end_pos, &text);
      }
    };

    return Ok(ModuleResourceResponse {status: atoms::error(), result: "".to_string()});
}

fn is_leading_char_valid(start_pos: usize, text: &String) -> bool {
  let leading_char = text.chars().nth(start_pos - 1).unwrap();
  return PERMITTED_CHARS.contains(&leading_char);
}

fn is_trailing_char_valid(end_pos: usize, text: &String) -> bool {
  let trailing_char = text.chars().nth(end_pos).unwrap();
  return PERMITTED_CHARS.contains(&trailing_char);
}

fn get_match(start_pos: usize, end_pos: usize, text: &String) ->  NifResult<ModuleResourceResponse> {
  let res = text.substring(start_pos, end_pos).to_string();
  return Ok(ModuleResourceResponse {status: atoms::ok(), result: res});
}

rustler::init!("Elixir.Parser", [find_matches, return_atom]);
