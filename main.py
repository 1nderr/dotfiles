from pathlib import Path
from shutil import copyfile

import inquirer
from git import Repo

IGNORED_FILES: list[str] = [
    "pyproject.toml",
    "main.py",
    "pyproject.toml",
    ".python-version",
    "uv.lock",
    "sync",
]


def main():
    repo = Repo()
    _ = repo.remotes.origin.pull()

    remote_paths: list[str] = []

    for file in Path(".").rglob("*"):
        if not file.is_file():
            continue

        file_path = str(file)
        if (
            file_path.startswith(".git/")
            or file_path.startswith(".venv/")
            or file_path in IGNORED_FILES
        ):
            continue

        remote_paths.append(file_path)

    questions = [
        inquirer.List(
            "source",
            message="Where do you want to sync from?",
            choices=["local", "remote"],
        ),
        inquirer.Checkbox(
            "files",
            message="Which files do you want to sync?",
            choices=remote_paths,
        ),
    ]

    answers = inquirer.prompt(questions)
    if answers is None:
        return

    source: str = answers["source"]
    target = "remote" if source == "local" else "local"
    source_path_prefix = "~/" if source == "local" else ""
    target_path_prefix = "" if source == "local" else "~/"
    selected_files: list[str] = answers["files"]

    print(f"File sync summary: {source} -> {target}")
    for file in selected_files:
        print(f"{source_path_prefix}{file:<30} ->", f"{target_path_prefix}{file:<30}")
    print()

    questions = [
        inquirer.Confirm("continue", message="Continue with sync", default=False),
    ]

    answers = inquirer.prompt(questions)
    if answers is None:
        return

    if answers["continue"]:
        for file in selected_files:
            source_path = Path(f"{source_path_prefix}{file}").expanduser()
            target_path = Path(f"{target_path_prefix}{file}").expanduser()
            copyfile(source_path, target_path)
    else:
        print("Sync cancelled")
        return

    print("Dotfiles synced sucessfully")


if __name__ == "__main__":
    main()
