use rustler::{Atom, NifResult, NifTuple, ListIterator};
//#[macro_use] extern crate lazy_static;

use substring::Substring;

mod atoms {
    rustler::atoms! {
        ok,
        error,
    }
}

#[derive(NifTuple)]
pub struct ModuleResourceResponse {
    status: Atom,
    result: Vec<String>,
}

#[derive(NifTuple)]
pub struct BitMatch {
    start_pos: usize,
    match_length: usize,
}


// Parser.find_matches([{10, 5}, {22, 3}], "the quick hello brown fox jumps")

#[rustler::nif]
fn find_matches(binary_matches: ListIterator, text: String) ->  NifResult<ModuleResourceResponse> {
  let pairs_list: NifResult<Vec<(usize, usize)>> = binary_matches.map(|x| x.decode::<(usize, usize)>()).collect::<NifResult<Vec<(usize, usize)>>>();

  match pairs_list {
    Ok(pairs) => {
        let keyword_matches: Vec<String> = pairs.iter().map( |(start, length)| find_match(*start, *length, &text) ).collect();

        return Ok(ModuleResourceResponse {status: atoms::ok(), result: keyword_matches});
        //println!("{:?}", keyword_matches);
    },
    Err(_e) => {
      return Ok(ModuleResourceResponse {status: atoms::error(), result: [].to_vec()});
    },
  }
}



pub const PERMITTED_CHARS: &'static [char] = &[
  ' ', '.', ',', '!', '?', '#', '$', '%', '^', '&', '@',
  '(', ')', '>', '<', '/', '\\', '|', '[', ']', '{', '}',
  '~', '*', '-', '_', '+', '=', ':', ';', '"', '\'', '`'
];

fn find_match(start_pos: usize, match_length: usize, text: &String) ->  String {
    let string_length = text.chars().count();

    if ((start_pos + match_length) > string_length) || (match_length <= 0) {
      return "".to_string();
      //return Ok(ModuleResourceResponse {status: atoms::error(), result: "".to_string()});
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

    //return Ok(ModuleResourceResponse {status: atoms::error(), result: "".to_string()});
    return "".to_string();
}

fn is_leading_char_valid(start_pos: usize, text: &String) -> bool {
  let leading_char = text.chars().nth(start_pos - 1).unwrap();
  return PERMITTED_CHARS.contains(&leading_char);
}

fn is_trailing_char_valid(end_pos: usize, text: &String) -> bool {
  let trailing_char = text.chars().nth(end_pos).unwrap();
  return PERMITTED_CHARS.contains(&trailing_char);
}

fn get_match(start_pos: usize, end_pos: usize, text: &String) -> String {
  let res = text.substring(start_pos, end_pos).to_string();
  //return Ok(ModuleResourceResponse {status: atoms::ok(), result: res});
  return res;
}

rustler::init!("Elixir.Parser", [find_matches]);
