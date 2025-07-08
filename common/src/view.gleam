import common
import config
import formal/form
import gleam/dynamic/decode
import gleam/list
import lustre/attribute
import lustre/element
import lustre/element/html
import lustre/event
import lustre/server_component
import mvu

pub fn view(model: mvu.Model) -> element.Element(mvu.Msg) {
  let content = case model {
    mvu.LoggedIn(current_user:, users:) -> view_logged_in(current_user, users)
    mvu.Login(form) -> view_register(form)
  }
  html.div([], [content])
}

fn view_logged_in(
  local_user: common.User,
  userlist: List(common.User),
) -> element.Element(mvu.Msg) {
  let users =
    list.map(userlist, fn(user) { html.li([], [html.text(user.name)]) })
  let users = [
    html.li([], [
      html.strong([], [html.text(local_user.name)]),
      html.text(" (you)"),
    ]),
    ..users
  ]

  let userlist = html.ul([], users)
  let local_user = html.h2([], [html.text("Welcome " <> local_user.name)])
  let server_comp =
    server_component.element([server_component.route("/ws")], [])
  let temp_component_event_handler_script =
    html.script(
      [],
      "
      const counter = document.querySelector('lustre-server-component');

      counter.addEventListener('submitRoll', event => {
        window.alert(`The roll value is now ${event.detail}`);
      })
      ",
    )
  html.div([], [
    local_user,
    userlist,
    server_comp,
    temp_component_event_handler_script,
  ])
}

fn view_register(form: form.Form) -> element.Element(mvu.Msg) {
  html.form([event.on_submit(mvu.UserClickedRegister)], [
    html.h1([], [html.text("Register")]),
    view_input(form, is: "text", name: "username", label: "Username"),
    html.div([], [html.button([], [html.text("Login")])]),
  ])
}

fn view_input(
  form: form.Form,
  is type_: String,
  name name: String,
  label label: String,
) -> element.Element(mvu.Msg) {
  let state = form.field_state(form, name)

  html.div([], [
    html.label([attribute.for(name)], [html.text(label), html.text(": ")]),
    html.input([
      attribute.type_(type_),
      //   case state {
      //     Ok(_) -> attribute.class("focus:outline focus:outline-purple-600")
      //     Error(_) -> attribute.class("outline outline-red-500")
      //   },
      // we use the `id` in the associated `for` attribute on the label.
      attribute.id(name),
      // the `name` attribute is used as the first element of the tuple
      // we receive for this input.
      attribute.name(name),
    ]),
    // formal provides us with a customisable error message for every element
    // in case its validation fails, which we can show right below the input.
    case state {
      Ok(_) -> element.none()
      Error(error_message) -> html.p([], [html.text(error_message)])
    },
  ])
}
