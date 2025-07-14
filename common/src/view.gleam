import common
import formal/form
import lustre/attribute
import lustre/element
import lustre/element/html
import lustre/event
import lustre/server_component
import mvu

pub fn view(model: mvu.Model) -> element.Element(mvu.Msg) {
  let content = case model {
    mvu.LoggedIn(current_user:) -> view_logged_in(current_user)
    mvu.Login(form) -> view_register(form)
  }
  html.div([], [content])
}

fn view_logged_in(local_user: common.User) -> element.Element(mvu.Msg) {
  let local_user = html.h2([], [html.text("Welcome " <> local_user.name)])
  let server_comp =
    server_component.element(
      [
        server_component.route("/ws"),
        // event.on(config.submit_roll_event_name, {
      //   use new_roll_value <- decode.field("detail", decode.int)
      //   mvu.UserSubmittedRoll(new_roll_value)
      //   |> decode.success
      // }),
      ],
      [],
    )
  html.div([], [local_user, server_comp])
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
