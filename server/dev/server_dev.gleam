import gleam/io
import simplifile

pub fn main() -> Nil {
  let assert Ok(_) =
    simplifile.copy_file(
      "build/packages/lustre/priv/static/lustre-server-component.min.mjs",
      "priv/static/lustre-server-component.min.mjs",
    )
  io.println("Successfully copied lustre-server-component.min.mjs")
  let assert Ok(_) =
    simplifile.copy_file(
      "build/packages/lustre/priv/static/lustre-server-component.mjs",
      "priv/static/lustre-server-component.mjs",
    )
  io.println("Successfully copied lustre-server-component.mjs")
}
