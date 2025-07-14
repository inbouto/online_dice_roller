import common
import formal/form.{type Form}
import lustre/effect
import mvu
import rsvp
import side_effects

pub fn update(
  model: mvu.Model,
  msg: mvu.Msg,
) -> #(mvu.Model, effect.Effect(mvu.Msg)) {
  case msg {
    mvu.ServerRegisteredNewUser(r) -> server_registered_new_user(model, r)
    mvu.ServerReturnedAuthenticationResponse(r) ->
      server_returned_authentication_response(model, r)
    mvu.UserClickedRegister(data) -> user_clicked_register(model, data)
  }
}

fn server_registered_new_user(
  model: mvu.Model,
  local_username_result: Result(common.User, rsvp.Error),
) -> #(mvu.Model, effect.Effect(mvu.Msg)) {
  let form = case model {
    mvu.LoggedIn(_) -> form.new()
    mvu.Login(form) -> form
  }
  case echo local_username_result {
    Error(_) -> #(mvu.Login(form), effect.none())
    Ok(user) -> #(mvu.LoggedIn(user), effect.none())
  }
}

fn server_returned_authentication_response(
  _model: mvu.Model,
  response: Result(common.User, rsvp.Error),
) -> #(mvu.Model, effect.Effect(mvu.Msg)) {
  let model = case echo response {
    Ok(user) -> mvu.LoggedIn(current_user: user)
    _ -> mvu.Login(form.new())
  }
  #(model, effect.none())
}

fn user_clicked_register(
  model: mvu.Model,
  data: List(#(String, String)),
) -> #(mvu.Model, effect.Effect(mvu.Msg)) {
  let model = case model {
    mvu.LoggedIn(_) -> mvu.Login(form.new())
    mvu.Login(_) -> model
  }
  let effect = case decode_registration_data(data) {
    Error(_) -> effect.none()
    Ok(user) -> side_effects.register_user(user)
  }
  #(model, effect)
}

fn decode_registration_data(
  values: List(#(String, String)),
) -> Result(common.User, Form) {
  form.decoding({
    use username <- form.parameter
    common.User(username, roll: 0)
  })
  |> form.with_values(values)
  |> form.field("username", form.string |> form.and(form.must_not_be_empty))
  |> form.finish
}
