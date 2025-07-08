import common
import config
import lustre/effect
import mvu
import rsvp

pub fn register_user(user: common.User) -> effect.Effect(mvu.Msg) {
  let body = common.user_to_json(user)
  let url = "/" <> config.get_api_url(config.api_register_new_user_path)
  rsvp.post(
    url,
    body,
    rsvp.expect_json(common.user_decoder(), mvu.ServerRegisteredNewUser),
  )
}

pub fn fetch_current_users() -> effect.Effect(mvu.Msg) {
  let url = "/" <> config.get_api_url(config.api_current_users_path)
  rsvp.get(
    url,
    rsvp.expect_json(common.user_list_decoder(), mvu.ServerReturnedUserList),
  )
}

pub fn authenticate() -> effect.Effect(mvu.Msg) {
  let url = "/" <> config.get_api_url(config.api_authenticate_path)
  rsvp.get(
    url,
    rsvp.expect_json(
      common.user_decoder(),
      mvu.ServerReturnedAuthenticationResponse,
    ),
  )
}
