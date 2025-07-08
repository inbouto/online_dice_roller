import api
import common
import formal/form
import gleam/bytes_tree
import gleam/erlang/process
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/json
import gleam/option.{None}
import lustre/attribute
import lustre/element
import lustre/element/html
import mist.{type Connection, type ResponseData}
import mvu
import simplifile
import storail
import store
import view
import ws

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
        ["ws"] -> ws.serve(req)
        ["priv", ..] -> {
          case mist.send_file("." <> req.path, 0, None) {
            Error(_) -> not_found
            Ok(data) ->
              response.new(200)
              |> response.set_body(data)
              |> response.set_header("Content-Type", "text/javascript")
          }
        }
        ["api", ..rest] -> api.handle_api_request(req, rest, users)
        _ -> not_found
      }
    }
    |> mist.new
    |> mist.port(3000)
    |> mist.start

  process.sleep_forever()
}

fn serve(
  req: Request(mist.Connection),
  user_store: storail.Collection(common.User),
) -> Response(ResponseData) {
  let res = response.new(200)
  let model = case store.get_user(req, user_store) {
    Error(_) -> mvu.Login(form.new())
    Ok(user) ->
      mvu.LoggedIn(current_user: user, users: store.get_users(req, user_store))
  }
  let model_string = mvu.model_to_json(model) |> json.to_string
  let rendered_page = html.div([attribute.id("app")], [view.view(model)])

  // let server_component =
  //   element.element("lustre-server-component", [server_component.route("/ws")], [
  //     html.p([], [html.text("My counter is here")]),
  //   ])

  let html =
    html.html([], [
      html.head([], [
        html.script(
          [attribute.src("/priv/static/client.mjs"), attribute.type_("module")],
          "",
        ),
        html.script(
          [
            attribute.src("/priv/static/lustre-server-component.mjs"),
            attribute.type_("module"),
          ],
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
