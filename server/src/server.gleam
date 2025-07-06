import common
import config
import formal/form
import gleam/bit_array
import gleam/bytes_tree
import gleam/crypto
import gleam/dict
import gleam/erlang/process
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/json
import gleam/list
import gleam/option.{None}
import gleam/result
import gleam/string
import lustre/attribute
import lustre/element
import lustre/element/html
import mist.{type Connection, type ResponseData}
import mvu
import simplifile
import storail
import view

const storage_path = "tmp/storage"

pub fn main() {
  let storail_config = storail.Config(storage_path)
  let _ = simplifile.delete(storage_path)
  let users =
    storail.Collection(
      name: "users",
      to_json: common.user_to_json,
      decoder: common.user_decoder(),
      config: storail_config,
    )

  // let assert Ok(_) = write_store_entry(common.User("titi"), users)
  // let assert Ok(_) = write_store_entry(common.User("tata"), users)
  // let assert Ok(_) = write_store_entry(common.User("tutu"), users)

  let empty_body = mist.Bytes(bytes_tree.new())
  let not_found = response.set_body(response.new(404), empty_body)

  let assert Ok(_) =
    fn(req: Request(Connection)) -> Response(ResponseData) {
      case request.path_segments(req) {
        [] -> serve(req, users)
        ["priv", ..] -> {
          case mist.send_file("." <> req.path, 0, None) {
            Error(_) -> not_found
            Ok(data) ->
              response.new(200)
              |> response.set_body(data)
              |> response.set_header("Content-Type", "text/javascript")
          }
        }
        ["api", ..rest] -> handle_api_request(req, rest, users)
        _ -> not_found
      }
    }
    |> mist.new
    |> mist.port(3000)
    |> mist.start

  process.sleep_forever()
}

fn handle_api_request(
  req: Request(Connection),
  path_segments: List(String),
  storail_collection: storail.Collection(common.User),
) -> Response(ResponseData) {
  let not_found_body =
    json.string("not found")
    |> json.to_string_tree
    |> bytes_tree.from_string_tree
    |> mist.Bytes
  let not_found =
    response.new(404)
    |> response.set_body(not_found_body)
  let error_body =
    json.string("internal server error")
    |> json.to_string_tree
    |> bytes_tree.from_string_tree
    |> mist.Bytes
  let error =
    response.new(500)
    |> response.set_body(error_body)

  case path_segments {
    path if path == config.api_current_users_path -> {
      let body =
        get_users(req, storail_collection)
        |> common.user_list_to_json
        |> json.to_string_tree
        |> bytes_tree.from_string_tree
        |> mist.Bytes
      response.new(200)
      |> response.set_body(body)
    }
    path if path == config.api_register_new_user_path -> {
      {
        use body <- result.try(
          mist.read_body(req, 1000) |> result.replace_error(Nil),
        )
        use body_string <- result.try(body.body |> bit_array.to_string)
        use user <- result.map(
          json.parse(body_string, common.user_decoder())
          |> result.replace_error(Nil),
        )

        case write_store_entry(user, storail_collection) {
          Error(_) -> error
          Ok(key_index) -> {
            let response_body =
              user.name
              |> json.string
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
      |> result.unwrap(not_found)
    }
    path if path == config.api_authenticate_path ->
      {
        use user_id <- result.try(get_user_id(req))
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
      |> result.unwrap(
        response.new(401) |> response.set_body(bytes_tree.new() |> mist.Bytes),
      )
    _ -> not_found
  }
  |> response.set_header("Content-Type", "application/json")
}

fn get_users(
  req: Request(mist.Connection),
  storail_collection: storail.Collection(common.User),
) -> List(common.User) {
  let exclude =
    get_user_id(req)
    |> result.unwrap("")
  storail.read_namespace(storail_collection, [])
  |> result.unwrap(dict.new())
  |> dict.filter(fn(key, _user) { key != exclude })
  |> dict.values
}

fn get_user_id(req: Request(mist.Connection)) -> Result(String, Nil) {
  list.filter_map(req.headers, fn(header_entry) {
    let #(key, value) = header_entry
    case key == "cookie" {
      False -> Error(Nil)
      True ->
        result.try(string.split_once(value, "="), fn(split_cookie) {
          case split_cookie {
            #("userId", value) -> value |> Ok
            _ -> Error(Nil)
          }
        })
    }
  })
  |> list.first
}

fn get_user(
  req: Request(mist.Connection),
  user_store: storail.Collection(common.User),
) -> Result(common.User, Nil) {
  use user_id <- result.try(get_user_id(req))
  let key = storail.key(user_store, user_id)
  storail.read(key) |> result.replace_error(Nil)
}

fn write_store_entry(
  user: item,
  collection: storail.Collection(item),
) -> Result(String, storail.StorailError) {
  let key_index =
    crypto.strong_random_bytes(28) |> bit_array.base64_url_encode(False)
  let key = storail.key(collection, key_index)
  storail.write(key, user)
  |> result.replace(key_index)
}

fn serve(
  req: Request(mist.Connection),
  user_store: storail.Collection(common.User),
) -> Response(ResponseData) {
  let res = response.new(200)
  let model = case get_user(req, user_store) {
    Error(_) -> mvu.Login(form.new())
    Ok(user) ->
      mvu.LoggedIn(current_user: user, users: get_users(req, user_store))
  }
  let model_string = mvu.model_to_json(model) |> json.to_string
  let rendered_page = html.div([attribute.id("app")], [view.view(model)])

  let html =
    html.html([], [
      html.head([], [
        html.script(
          [attribute.src("/priv/static/client.mjs"), attribute.type_("module")],
          "",
        ),
        html.script(
          [attribute.type_("application/json"), attribute.id("model")],
          model_string,
        ),
      ]),
      html.body([], [rendered_page]),
    ])

  response.set_body(
    res,
    html
      |> element.to_document_string
      |> bytes_tree.from_string
      |> mist.Bytes,
  )
}
