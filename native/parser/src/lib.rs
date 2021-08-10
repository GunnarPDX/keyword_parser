use substring::Substring;

// pattern = :binary.compile_pattern(["the", "hello", "fox"])
// :binary.matches("the quick hello brown fox jumps", pattern)
// [{10, 5}, {22, 3}]
// Parser.find_matches(10, 5, "the quick hello brown fox jumps")
// Parser.find_matches(22, 3, "the quick hello brown fox jumps")
#[rustler::nif]
fn find_matches(start_pos: usize, match_length: usize, text: String) -> (bool, String) {
    let string_length = text.chars().count();

    if ((start_pos + match_length) > string_length) || (match_length <= 0) {
      return (false, "".to_string());
    };

    let end_pos = start_pos + match_length;

    const PERMITTED_CHARS: [char; 32] = [' ', '.', ',', '!', '?', '#', '$', '%', '^', '&', '@', '(', ')', '>', '<', '/', '\\', '|', '[', ']', '{', '}', '~', '*', '-', '+', '=', ':', ';', '"', '\'', '`'];

    if start_pos == 0 && end_pos != string_length {
      println!("{:?}", "here");
      let res = text.substring(start_pos, end_pos);
      let trailing_char = text.chars().nth(0).unwrap();

      if PERMITTED_CHARS.contains(&trailing_char) {
        return (true, res.to_string());
      };

    };

    let res = text.substring(start_pos, end_pos);

    println!("{:?}", text);
    println!("{:?}", string_length);
    println!("{:?}", res);

    (false, res.to_string())
}


rustler::init!("Elixir.Parser", [find_matches]);
