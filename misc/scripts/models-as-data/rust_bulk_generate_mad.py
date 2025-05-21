"""
Experimental script for bulk generation of MaD models based on a list of projects.

Currently the script only targets Rust.
"""

import os.path
import subprocess
import sys
from typing import NotRequired, TypedDict, List
from concurrent.futures import ThreadPoolExecutor, as_completed
import time

import generate_mad as mad

gitroot = (
    subprocess.check_output(["git", "rev-parse", "--show-toplevel"])
    .decode("utf-8")
    .strip()
)
build_dir = os.path.join(gitroot, "mad-generation-build")


def path_to_mad_directory(language: str, name: str) -> str:
    return os.path.join(gitroot, f"{language}/ql/lib/ext/generated/{name}")


# A project to generate models for
class Project(TypedDict):
    """
    Type definition for Rust projects to model.

    Attributes:
        name: The name of the project
        git_repo: URL to the git repository
        git_tag: Optional Git tag to check out
    """

    name: str
    git_repo: str
    git_tag: NotRequired[str]


# List of Rust projects to generate models for.
projects: List[Project] = [
    {
        "name": "libc",
        "git_repo": "https://github.com/rust-lang/libc",
        "git_tag": "0.2.172",
    },
    {
        "name": "log",
        "git_repo": "https://github.com/rust-lang/log",
        "git_tag": "0.4.27",
    },
    {
        "name": "memchr",
        "git_repo": "https://github.com/BurntSushi/memchr",
        "git_tag": "2.7.4",
    },
    {
        "name": "once_cell",
        "git_repo": "https://github.com/matklad/once_cell",
        "git_tag": "v1.21.3",
    },
    {
        "name": "rand",
        "git_repo": "https://github.com/rust-random/rand",
        "git_tag": "0.9.1",
    },
    {
        "name": "smallvec",
        "git_repo": "https://github.com/servo/rust-smallvec",
        "git_tag": "v1.15.0",
    },
    {
        "name": "serde",
        "git_repo": "https://github.com/serde-rs/serde",
        "git_tag": "v1.0.219",
    },
    {
        "name": "tokio",
        "git_repo": "https://github.com/tokio-rs/tokio",
        "git_tag": "tokio-1.45.0",
    },
    {
        "name": "reqwest",
        "git_repo": "https://github.com/seanmonstar/reqwest",
        "git_tag": "v0.12.15",
    },
    {
        "name": "rocket",
        "git_repo": "https://github.com/SergioBenitez/Rocket",
        "git_tag": "v0.5.1",
    },
    {
        "name": "actix-web",
        "git_repo": "https://github.com/actix/actix-web",
        "git_tag": "web-v4.11.0",
    },
    {
        "name": "hyper",
        "git_repo": "https://github.com/hyperium/hyper",
        "git_tag": "v1.6.0",
    },
    {
        "name": "clap",
        "git_repo": "https://github.com/clap-rs/clap",
        "git_tag": "v4.5.38",
    },
]


def clone_project(project: Project) -> str:
    """
    Shallow clone a project into the build directory.

    Args:
        project: A dictionary containing project information with 'name', 'git_repo', and optional 'git_tag' keys.

    Returns:
        The path to the cloned project directory.
    """
    name = project["name"]
    repo_url = project["git_repo"]
    git_tag = project.get("git_tag")

    # Determine target directory
    target_dir = os.path.join(build_dir, name)

    # Clone only if directory doesn't already exist
    if not os.path.exists(target_dir):
        if git_tag:
            print(f"Cloning {name} from {repo_url} at tag {git_tag}")
        else:
            print(f"Cloning {name} from {repo_url}")

        subprocess.check_call(
            [
                "git",
                "clone",
                "--quiet",
                "--depth",
                "1",  # Shallow clone
                *(
                    ["--branch", git_tag] if git_tag else []
                ),  # Add branch if tag is provided
                repo_url,
                target_dir,
            ]
        )
        print(f"Completed cloning {name}")
    else:
        print(f"Skipping cloning {name} as it already exists at {target_dir}")

    return target_dir


def clone_projects(projects: List[Project]) -> List[tuple[Project, str]]:
    """
    Clone all projects in parallel.

    Args:
        projects: List of projects to clone

    Returns:
        List of (project, project_dir) pairs in the same order as the input projects
    """
    start_time = time.time()
    max_workers = min(8, len(projects))  # Use at most 8 threads
    project_dirs_map = {}  # Map to store results by project name

    with ThreadPoolExecutor(max_workers=max_workers) as executor:
        # Start cloning tasks and keep track of them
        future_to_project = {
            executor.submit(clone_project, project): project for project in projects
        }

        # Process results as they complete
        for future in as_completed(future_to_project):
            project = future_to_project[future]
            try:
                project_dir = future.result()
                project_dirs_map[project["name"]] = (project, project_dir)
            except Exception as e:
                print(f"ERROR: Failed to clone {project['name']}: {e}")

    if len(project_dirs_map) != len(projects):
        failed_projects = [
            project["name"]
            for project in projects
            if project["name"] not in project_dirs_map
        ]
        print(
            f"ERROR: Only {len(project_dirs_map)} out of {len(projects)} projects were cloned successfully. Failed projects: {', '.join(failed_projects)}"
        )
        sys.exit(1)

    project_dirs = [project_dirs_map[project["name"]] for project in projects]

    clone_time = time.time() - start_time
    print(f"Cloning completed in {clone_time:.2f} seconds")
    return project_dirs


def build_database(project: Project, project_dir: str) -> str | None:
    """
    Build a CodeQL database for a project.

    Args:
        project: A dictionary containing project information with 'name' and 'git_repo' keys.
        project_dir: The directory containing the project source code.

    Returns:
        The path to the created database directory.
    """
    name = project["name"]

    # Create database directory path
    database_dir = os.path.join(build_dir, f"{name}-db")

    # Only build the database if it doesn't already exist
    if not os.path.exists(database_dir):
        print(f"Building CodeQL database for {name}...")
        try:
            subprocess.check_call(
                [
                    "codeql",
                    "database",
                    "create",
                    "--language=rust",
                    "--source-root=" + project_dir,
                    "--overwrite",
                    "-O",
                    "cargo_features='*'",
                    "--",
                    database_dir,
                ]
            )
            print(f"Successfully created database at {database_dir}")
        except subprocess.CalledProcessError as e:
            print(f"Failed to create database for {name}: {e}")
            return None
    else:
        print(
            f"Skipping database creation for {name} as it already exists at {database_dir}"
        )

    return database_dir


def generate_models(project: Project, database_dir: str) -> None:
    """
    Generate models for a project.

    Args:
        project: A dictionary containing project information with 'name' and 'git_repo' keys.
        project_dir: The directory containing the project source code.
    """
    name = project["name"]

    generator = mad.Generator("rust")
    generator.generateSinks = True
    generator.generateSources = True
    generator.generateSummaries = True
    generator.setenvironment(database=database_dir, folder=name)
    generator.run()


def main() -> None:
    """
    Process all projects in three distinct phases:
    1. Clone projects (in parallel)
    2. Build databases for projects
    3. Generate models for successful database builds
    """

    # Create build directory if it doesn't exist
    if not os.path.exists(build_dir):
        os.makedirs(build_dir)

    # Check if any of the MaD directories contain working directory changes in git
    for project in projects:
        mad_dir = path_to_mad_directory("rust", project["name"])
        if os.path.exists(mad_dir):
            git_status_output = subprocess.check_output(
                ["git", "status", "-s", mad_dir], text=True
            ).strip()
            if git_status_output:
                print(
                    f"""ERROR: Working directory changes detected in {mad_dir}.

Before generating new models, the existing models are deleted.

To avoid loss of data, please commit your changes."""
                )
                sys.exit(1)

    # Phase 1: Clone projects in parallel
    print("=== Phase 1: Cloning projects ===")
    project_dirs = clone_projects(projects)

    # Phase 2: Build databases for all projects
    print("\n=== Phase 2: Building databases ===")
    database_results = [
        (project, build_database(project, project_dir))
        for project, project_dir in project_dirs
    ]

    # Phase 3: Generate models for all projects
    print("\n=== Phase 3: Generating models ===")

    failed_builds = [
        project["name"] for project, db_dir in database_results if db_dir is None
    ]
    if failed_builds:
        print(
            f"ERROR: {len(failed_builds)} database builds failed: {', '.join(failed_builds)}"
        )
        sys.exit(1)

    # Delete the MaD directory for each project
    for project, database_dir in database_results:
        mad_dir = path_to_mad_directory("rust", project["name"])
        if os.path.exists(mad_dir):
            print(f"Deleting existing MaD directory at {mad_dir}")
            subprocess.check_call(["rm", "-rf", mad_dir])

    for project, database_dir in database_results:
        if database_dir is not None:
            generate_models(project, database_dir)


if __name__ == "__main__":
    main()
