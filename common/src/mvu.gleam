import common
import formal/form.{type Form}
import gleam/dynamic/decode
import gleam/json
import rsvp

pub type Model {
  Login(Form)
  LoggedIn(current_user: common.User, users: List(common.User))
}

pub fn model_to_json(model: Model) -> json.Json {
  case model {
    Login(_) -> json.object([#("type", json.string("login"))])
    LoggedIn(current_user:, users:) ->
      json.object([
        #("type", json.string("logged_in")),
        #("current_user", common.user_to_json(current_user)),
        #("users", common.user_list_to_json(users)),
      ])
  }
}

pub fn model_decoder() -> decode.Decoder(Model) {
  use variant <- decode.field("type", decode.string)
  case variant {
    "login" -> decode.success(Login(form.new()))
    "logged_in" -> {
      use current_user <- decode.field("current_user", common.user_decoder())
      use users <- decode.field("users", common.user_list_decoder())
      decode.success(LoggedIn(current_user:, users:))
    }
    _ -> decode.failure(Login(form.new()), "Model")
  }
}

pub type Msg {
  ServerRegisteredNewUser(Result(String, rsvp.Error))
  ServerReturnedUserList(Result(List(common.User), rsvp.Error))
  ServerReturnedAuthenticationResponse(Result(common.User, rsvp.Error))
  UserClickedRegister(List(#(String, String)))
}
