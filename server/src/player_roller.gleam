import config
import gleam/dynamic/decode
import gleam/int
import gleam/json
import gleam/result
import lustre
import lustre/component
import lustre/effect.{type Effect}
import lustre/element
import lustre/element/html
import lustre/event
import prng/random

pub type Model {
  Model(roll: Int, generator: random.Generator(Int))
}

pub type Msg {
  UserClickedRoll
}

pub fn component() -> lustre.App(_, Model, Msg) {
  lustre.component(init, update, view, [])
}

fn init(_) -> #(Model, Effect(Msg)) {
  #(Model(1, random.int(1, 6)), effect.none())
}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    UserClickedRoll -> #(
      Model(
        generator: model.generator,
        roll: random.random_sample(model.generator),
      ),
      effect.none(),
    )
  }
}

fn view(model: Model) -> element.Element(Msg) {
  element.fragment([
    html.p([], [html.text(model.roll |> int.to_string)]),
    html.button([event.on_click(UserClickedRoll)], [html.text("Roll")]),
  ])
}
