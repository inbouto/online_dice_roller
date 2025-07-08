import gleam/erlang/process.{type Selector}
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/json
import gleam/option.{type Option, Some}
import lustre
import lustre/server_component
import mist.{type Connection, type ResponseData}
import roller

pub type Model {
  Model(
    component: lustre.Runtime(roller.Msg),
    self: process.Subject(server_component.ClientMessage(roller.Msg)),
  )
}

pub fn serve(request: Request(Connection)) -> Response(ResponseData) {
  mist.websocket(request:, on_init: init, handler:, on_close: close)
}

fn init(
  _,
) -> #(Model, Option(Selector(server_component.ClientMessage(roller.Msg)))) {
  let assert Ok(component) =
    roller.component() |> lustre.start_server_component(Nil)

  let self = process.new_subject()
  let selector =
    process.new_selector()
    |> process.select(self)
  server_component.register_subject(self)
  |> lustre.send(to: component)

  #(Model(component:, self:), Some(selector))
}

fn handler(
  state: Model,
  message: mist.WebsocketMessage(server_component.ClientMessage(roller.Msg)),
  conn: mist.WebsocketConnection,
) {
  case message {
    mist.Text(json) -> {
      case json.parse(json, server_component.runtime_message_decoder()) {
        Error(_) -> Nil
        Ok(runtime_message) -> lustre.send(state.component, runtime_message)
      }
      mist.continue(state)
    }
    mist.Custom(client_message) -> {
      let json = server_component.client_message_to_json(client_message)
      let assert Ok(_) = mist.send_text_frame(conn, json.to_string(json))
      mist.continue(state)
    }
    mist.Closed | mist.Shutdown -> {
      close(state)
      mist.stop()
    }
    _ -> mist.continue(state)
  }
}

fn close(state: Model) -> Nil {
  server_component.deregister_subject(state.self)
  |> lustre.send(to: state.component)
}
