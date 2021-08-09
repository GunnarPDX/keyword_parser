use substring::Substring;

// Parser.find_matches(1, 2, "hello")
#[rustler::nif]
fn find_matches(a: usize, b: usize, text: String) -> String {
    println!("{:?}", text);

    let res = text.substring(a, b);

    println!("{:?}", res);

    res.to_string()
}


rustler::init!("Elixir.Parser", [find_matches]);
