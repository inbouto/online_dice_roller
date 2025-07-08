import common
import gleam/bit_array
import gleam/crypto
import gleam/dict
import gleam/http/request.{type Request}
import gleam/list
import gleam/result
import gleam/string
import mist
import storail

pub fn write_store_entry(
  user: item,
  collection: storail.Collection(item),
) -> Result(String, storail.StorailError) {
  let key_index =
    crypto.strong_random_bytes(28) |> bit_array.base64_url_encode(False)
  let key = storail.key(collection, key_index)
  storail.write(key, user)
  |> result.replace(key_index)
}

pub fn get_user_id(req: Request(mist.Connection)) -> Result(String, Nil) {
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

pub fn get_user(
  req: Request(mist.Connection),
  user_store: storail.Collection(common.User),
) -> Result(common.User, Nil) {
  use user_id <- result.try(get_user_id(req))
  let key = storail.key(user_store, user_id)
  storail.read(key) |> result.replace_error(Nil)
}

pub fn get_users(
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
