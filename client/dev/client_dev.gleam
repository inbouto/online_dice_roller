import gleam/io
import simplifile

const source_dir = "priv"

const dest_dir = "../server/priv"

pub fn main() -> Nil {
  let assert Ok(_) = simplifile.delete(dest_dir)
  io.println("Successfully deleted " <> dest_dir)
  let assert Ok(_) = simplifile.copy_directory(source_dir, dest_dir)
  io.println("Successfully copied " <> source_dir <> " to " <> dest_dir)
}
