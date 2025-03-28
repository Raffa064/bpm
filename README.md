# BPM - Bash Package Manager

BPM is a command-line package manager that allows you to install and manage Bash scripts easily, similar to how you would manage packages in Node.js or Java projects.

# How to install

In order to install bpm on your device, you'll need to clne this repository.

```bash
git clone https://github.com/Raffa064/bpm --depth 1
```

After done, open the bpm's directory, and run the `install.sh` script:
```bash
cd bpm 
./install.sh
```

And, it's done! You can use `bpm help` to learn more about bpm.

> [!NOTE]
> The installation script can't be runned as ´sudo´, but it will ask for permission to install dependencies, such as `git`, `curl`, and `zip`.

## Project Structure

Every project created with BPM must adhere to the following structure, which is inspired by Node.js and Java workflows:

- **`package.sh`**: This file defines the project metadata, including the name, main script, version, and dependencies.
- **`src/` directory**: This directory contains all the package scripts, which can be imported by any other BPM package.

## BPM Runtime

With BPM, you can run any package that contains a main script using the command:

```bash
bpm run
```

This command works similarly to `npx` in Node.js. 

When you run a package, the BPM CLI first calls the runner script, which will check for the package dependencies defined in `package.sh`, and then invoke its main function. 

The main function must be defined in the main script and named as `pkg-name/main`. If the main function or the main script cannot be found, execution will be halted.

## Import System

BPM provides an `import` command that manages script dependencies in the global scope, similar to Java’s import mechanism. This allows you to import scripts based on their namespace, as specified by their path in the `src` directory.

**Example:**

```bash
import com.package.name.MainScript  # Imports from src/com/package/name/MainScript
```

**Note:** You can import scripts from any package defined as a dependency.

## Package Conventions (Design Patterns)

While not mandatory, it is encouraged that all BPM packages follow these conventions:

- **Functional Paradigm**: BPM encourages you to encapsulate all your scripts within functions, using the global scope only for defining constants and variables.
- **Modular Scopes**: It is recommended to name all functions using the `module/name` format, which helps prevent name collisions.
