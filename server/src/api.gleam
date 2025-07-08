import common
import config
import gleam/bit_array
import gleam/bytes_tree
import gleam/dynamic/decode
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/json
import gleam/result
import mist.{type Connection, type ResponseData}
import storail
import store

pub fn handle_api_request(
  req: Request(Connection),
  path_segments: List(String),
  storail_collection: storail.Collection(common.User),
) -> Response(ResponseData) {
  case path_segments {
    path if path == config.api_current_users_path ->
      handle_current_users(req, storail_collection)
    path if path == config.api_register_new_user_path ->
      handle_register_new_user(req, storail_collection)
    path if path == config.api_authenticate_path ->
      handle_authenticate_user(req, storail_collection)
    _ -> get_not_found()
  }
  |> response.set_header("Content-Type", "application/json")
}

fn handle_current_users(
  req: Request(Connection),
  storail_collection: storail.Collection(common.User),
) -> Response(ResponseData) {
  let body =
    store.get_users(req, storail_collection)
    |> common.user_list_to_json
    |> json.to_string_tree
    |> bytes_tree.from_string_tree
    |> mist.Bytes
  response.new(200)
  |> response.set_body(body)
}

fn handle_register_new_user(
  req: Request(Connection),
  storail_collection: storail.Collection(common.User),
) -> Response(ResponseData) {
  {
    use body <- result.try(
      mist.read_body(req, 1000) |> result.replace_error(Nil),
    )
    use body_string <- result.try(body.body |> bit_array.to_string)
    use user <- result.map(
      json.parse(body_string, {
        use name <- decode.field("name", decode.string)
        decode.success(common.User(name:, roll: 0))
      })
      |> result.replace_error(Nil),
    )

    case store.write_store_entry(user, storail_collection) {
      Error(_) -> get_error()
      Ok(key_index) -> {
        let response_body =
          user
          |> common.user_to_json
          |> json.to_string_tree
          |> bytes_tree.from_string_tree
          |> mist.Bytes
        response.new(200)
        |> response.set_body(response_body)
        |> response.set_header(
          "Set-Cookie",
          "userId="
            <> key_index
            <> "; Max-Age="
            <> config.user_id_cookie_lifetime
            <> "; Path=/",
        )
      }
    }
  }
  |> result.unwrap(get_not_found())
}

fn handle_authenticate_user(
  req: Request(Connection),
  storail_collection: storail.Collection(common.User),
) -> Response(ResponseData) {
  {
    use user_id <- result.try(store.get_user_id(req))
    use user <- result.map(
      storail.key(storail_collection, user_id)
      |> storail.read
      |> result.replace_error(Nil),
    )
    response.new(200)
    |> response.set_body(
      common.user_to_json(user)
      |> json.to_string_tree
      |> bytes_tree.from_string_tree
      |> mist.Bytes,
    )
  }
  |> result.unwrap(get_unauthenticated())
}

fn get_error() -> Response(ResponseData) {
  let error_body =
    json.string("internal server error")
    |> json.to_string_tree
    |> bytes_tree.from_string_tree
    |> mist.Bytes
  response.new(500)
  |> response.set_body(error_body)
}

fn get_not_found() -> Response(ResponseData) {
  let not_found_body =
    json.string("not found")
    |> json.to_string_tree
    |> bytes_tree.from_string_tree
    |> mist.Bytes
  response.new(404)
  |> response.set_body(not_found_body)
}

fn get_unauthenticated() -> Response(ResponseData) {
  let unauthenticated_body =
    json.string("unauthenticated")
    |> json.to_string_tree
    |> bytes_tree.from_string_tree
    |> mist.Bytes
  response.new(401)
  |> response.set_body(unauthenticated_body)
}
