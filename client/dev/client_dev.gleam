import gleam/io
import simplifile

const source_dir = "priv/static"

const runtime_source = "build/packages/lustre/priv/static/lustre-server-component.mjs"

const runtime_min_source = "build/packages/lustre/priv/static/lustre-server-component.min.mjs"

const dest_dir = "../server/priv/static"

pub fn main() -> Nil {
  let _ = simplifile.delete(dest_dir)
  io.println("Successfully deleted " <> dest_dir)
  copy(source_dir, dest_dir)
  copy(runtime_source, dest_dir <> "/lustre-server-component.mjs")
  copy(runtime_min_source, dest_dir <> "/lustre-server-component.min.mjs")
}

fn copy(from: String, to: String) -> Nil {
  let assert Ok(_) = simplifile.copy(from, to)
  io.println("Successfully copied " <> from <> " to " <> to)
}
