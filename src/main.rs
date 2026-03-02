use std::env;
use std::io::Write;
use std::process::{Command as ProcessCommand, Stdio};

const VERSION: &str = "v0.1.0";

/// Represents a CLI subcommand with its name, description, and handler function.
struct Command {
    name: &'static str,
    comments: &'static [&'static str],
    handler: fn(&[String]),
}

/// Registry of all available commands, mirroring the structure of cli.sh
/// where each function is defined with preceding comments.
const COMMANDS: &[Command] = &[
    Command {
        name: "help",
        comments: &["display help information for all available commands."],
        handler: cmd_help,
    },
    Command {
        name: "version",
        comments: &["display the current version of this command."],
        handler: cmd_version,
    },
    Command {
        name: "fzf",
        comments: &["select and execute a subcommand interactively with fzf."],
        handler: cmd_fzf,
    },
    Command {
        name: "hello_world",
        comments: &[
            "Example 1:",
            "Display a greeting on the screen",
            "",
            "This function displays the message \"Hello, World!\"",
        ],
        handler: cmd_hello_world,
    },
    Command {
        name: "show_date",
        comments: &[
            "Example 2:",
            "Display the current date and time",
            "This function displays the current date and time.",
        ],
        handler: cmd_show_date,
    },
];

// ANSI color codes
const PURPLE: &str = "\x1b[35m";
const CYAN: &str = "\x1b[36m";
const GREEN: &str = "\x1b[32m";
const BRIGHT_GREEN: &str = "\x1b[92m";
const RESET: &str = "\x1b[0m";

/// display help information for all available commands.
fn cmd_help(_args: &[String]) {
    let cmd = env::current_exe()
        .ok()
        .and_then(|p| p.file_stem().map(|s| s.to_string_lossy().into_owned()))
        .unwrap_or_else(|| "cli-rs".to_string());

    let exe = env::args().next().unwrap_or_else(|| cmd.clone());

    println!(
        "{PURPLE}{cmd}{RESET} ({CYAN}{VERSION}{RESET})\n\nUsage: {PURPLE}{exe}{RESET} [{BRIGHT_GREEN}arguments{RESET}]\""
    );

    for command in COMMANDS {
        println!("\n{GREEN}{}{RESET}:", command.name);
        for line in command.comments {
            println!("  {}", line);
        }
    }
    println!();
}

/// display the current version of this command.
fn cmd_version(_args: &[String]) {
    println!("{}", VERSION);
}

/// select and execute a subcommand interactively with fzf.
fn cmd_fzf(args: &[String]) {
    let func_names: Vec<&str> = COMMANDS.iter().map(|c| c.name).collect();
    let input = func_names.join("\n");

    let fzf_result = ProcessCommand::new("fzf")
        .arg("--prompt=Select command: ")
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .spawn();

    match fzf_result {
        Ok(mut child) => {
            if let Some(ref mut stdin) = child.stdin {
                let _ = stdin.write_all(input.as_bytes());
            }

            let output = child.wait_with_output();
            match output {
                Ok(out) => {
                    let selected = String::from_utf8_lossy(&out.stdout).trim().to_string();
                    if !selected.is_empty() {
                        dispatch(&selected, args);
                    }
                }
                Err(e) => eprintln!("fzf error: {}", e),
            }
        }
        Err(e) => eprintln!("Failed to start fzf: {}", e),
    }
}

/// Example 1:
/// Display a greeting on the screen
///
/// This function displays the message "Hello, World!"
fn cmd_hello_world(_args: &[String]) {
    println!("Hello, World!");
}

/// Example 2:
/// Display the current date and time
/// This function displays the current date and time.
fn cmd_show_date(_args: &[String]) {
    let output = ProcessCommand::new("date")
        .output()
        .expect("failed to execute date command");
    let date_str = String::from_utf8_lossy(&output.stdout);
    print!("Current date and time: {}", date_str);
}

/// Find a command by name from the registry.
fn find_command(name: &str) -> Option<&'static Command> {
    COMMANDS.iter().find(|c| c.name == name)
}

/// Dispatch a command by name, mirroring the case statement in cli.sh.
fn dispatch(cmd: &str, args: &[String]) {
    match find_command(cmd) {
        Some(command) => (command.handler)(args),
        None => cmd_help(&[]),
    }
}

fn main() {
    let args: Vec<String> = env::args().collect();

    if args.len() < 2 {
        // No command specified: show help (same as the * case in cli.sh)
        cmd_help(&[]);
        return;
    }

    let cmd = &args[1];
    let rest: Vec<String> = args[2..].to_vec();

    dispatch(cmd, &rest);
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_version_constant() {
        assert_eq!(VERSION, "v0.1.0");
    }

    #[test]
    fn test_commands_registry_has_all_commands() {
        let expected = ["help", "version", "fzf", "hello_world", "show_date"];
        let names: Vec<&str> = COMMANDS.iter().map(|c| c.name).collect();
        assert_eq!(names, expected);
    }

    #[test]
    fn test_find_command_existing() {
        assert!(find_command("help").is_some());
        assert!(find_command("version").is_some());
        assert!(find_command("fzf").is_some());
        assert!(find_command("hello_world").is_some());
        assert!(find_command("show_date").is_some());
    }

    #[test]
    fn test_find_command_unknown() {
        assert!(find_command("nonexistent").is_none());
        assert!(find_command("").is_none());
    }

    #[test]
    fn test_commands_have_comments() {
        for cmd in COMMANDS {
            assert!(
                !cmd.comments.is_empty(),
                "Command '{}' should have comments",
                cmd.name
            );
        }
    }

    #[test]
    fn test_hello_world_comments() {
        let cmd = find_command("hello_world").unwrap();
        assert_eq!(cmd.comments[0], "Example 1:");
    }

    #[test]
    fn test_show_date_comments() {
        let cmd = find_command("show_date").unwrap();
        assert_eq!(cmd.comments[0], "Example 2:");
    }

    #[test]
    fn test_ansi_color_codes() {
        assert_eq!(PURPLE, "\x1b[35m");
        assert_eq!(CYAN, "\x1b[36m");
        assert_eq!(GREEN, "\x1b[32m");
        assert_eq!(BRIGHT_GREEN, "\x1b[92m");
        assert_eq!(RESET, "\x1b[0m");
    }
}
