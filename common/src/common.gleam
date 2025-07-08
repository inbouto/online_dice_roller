import gleam/dynamic/decode
import gleam/json

pub type User {
  User(name: String, roll: Int)
}

pub fn user_to_json(user: User) -> json.Json {
  let User(name:, roll:) = user
  json.object([#("name", json.string(name)), #("roll", json.int(roll))])
}

pub fn user_decoder() -> decode.Decoder(User) {
  use name <- decode.field("name", decode.string)
  use roll <- decode.field("roll", decode.int)
  decode.success(User(name:, roll:))
}

pub fn user_list_to_json(users: List(User)) -> json.Json {
  json.array(users, user_to_json)
}

pub fn user_list_decoder() -> decode.Decoder(List(User)) {
  decode.list(user_decoder())
}
