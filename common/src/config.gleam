import gleam/list
import gleam/string

pub const api_base_path = "api"

pub const api_current_users_path = ["users", "current"]

pub const api_register_new_user_path = ["users", "register"]

pub const api_authenticate_path = ["users", "auth"]

pub const user_id_cookie_lifetime = "3600"

pub fn get_api_url(subpath: List(String)) -> String {
  api_base_path <> "/" <> { list.intersperse(subpath, "/") |> string.concat }
}
