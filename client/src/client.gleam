import formal/form
import gleam/json
import gleam/result
import lustre
import lustre/effect
import mvu
import plinth/browser/document
import plinth/browser/element as browser_element
import update
import view

pub fn main() -> Nil {
  let assert Ok(json_string) =
    document.query_selector("#model") |> result.map(browser_element.inner_text)
  let initial_model =
    json.parse(json_string, mvu.model_decoder())
    |> result.unwrap(mvu.Login(form.new()))
  let app =
    lustre.application(
      fn(_args) { #(initial_model, effect.none()) },
      update.update,
      view.view,
    )
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}
