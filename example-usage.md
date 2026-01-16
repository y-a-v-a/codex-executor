# Codex Agent Usage Examples

This document provides examples of how Claude Code can delegate tasks to the Codex agent.

> **Reference**: For CLI flags, configuration options, and troubleshooting, see [QUICKREF.md](./QUICKREF.md)

## Automatic Delegation

Claude Code will automatically use the codex-executor agent when you request coding tasks that would benefit from Codex's capabilities.

### Example Interactions

#### 1. Simple Code Generation
```
User: "Create a function to parse CSV files with error handling"
Claude: [Automatically delegates to codex-executor agent]
```

#### 2. Refactoring Request
```
User: "Refactor the authentication module to use modern async patterns"
Claude: [Delegates to codex-executor which runs Codex CLI]
```

#### 3. Code Analysis
```
User: "Analyze the codebase for potential performance bottlenecks"
Claude: [Delegates to codex-executor for analysis]
```

## Explicit Delegation

You can explicitly request the codex-executor agent:

```
User: "Use the codex-executor agent to implement a REST API for user management"
```

```
User: "Have the codex-executor analyze this module for security issues"
```

## What the Agent Does

When a task is delegated to codex-executor:

1. **Analyzes** the task requirements
2. **Gathers** necessary context from the codebase
3. **Formulates** an appropriate Codex CLI command
4. **Executes** the command with suitable flags
5. **Monitors** the execution
6. **Verifies** the results
7. **Reports** back with a clear summary

## Agent Benefits

✅ **Specialized expertise** - Focused on Codex CLI interaction
✅ **Proper safety** - Uses appropriate sandbox settings
✅ **Clear reporting** - Summarizes results effectively
✅ **Error handling** - Retries with adjusted parameters if needed
✅ **Context-aware** - Gathers relevant code before delegating to Codex

## Task Types Suitable for Codex Agent

- **Code generation** - Creating new functions, classes, modules
- **Refactoring** - Modernizing code, improving structure
- **Bug fixing** - Debugging and fixing issues
- **Code analysis** - Security, performance, quality reviews
- **Documentation** - Generating code comments and docs
- **Testing** - Creating test cases
- **API implementation** - Building endpoints and handlers

## Viewing Available Agents

Use the `/agents` command in Claude Code to view all available agents.

## Background Execution

For long-running tasks, request background execution or press **Ctrl+B** during execution:

```
User: "Run this in the background: use codex-executor to refactor the entire data layer"
```

---

> **Customization**: See [QUICKREF.md](./QUICKREF.md) for configuration options, CLI flags, hooks, and troubleshooting
