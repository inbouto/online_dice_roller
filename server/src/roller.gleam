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
  ParentChangedMaxRollValue(new_max: Int)
  UserClickedSubmitRoll
}

pub fn component() -> lustre.App(_, Model, Msg) {
  lustre.component(init, update, view, [
    component.on_attribute_change("maxroll", fn(max_roll) {
      int.parse(max_roll) |> result.map(ParentChangedMaxRollValue)
    }),
    component.on_property_change("maxroll", {
      decode.int |> decode.map(ParentChangedMaxRollValue)
    }),
  ])
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
    ParentChangedMaxRollValue(new_max:) -> #(
      Model(generator: random.int(1, new_max), roll: 1),
      effect.none(),
    )
    UserClickedSubmitRoll -> #(
      model,
      event.emit(config.submit_roll_event_name, json.int(model.roll)),
    )
  }
}

fn view(model: Model) -> element.Element(Msg) {
  element.fragment([
    html.p([], [html.text(model.roll |> int.to_string)]),
    html.button([event.on_click(UserClickedRoll)], [html.text("Roll")]),
    html.button([event.on_click(UserClickedSubmitRoll)], [
      html.text("Submit Roll"),
    ]),
  ])
}
