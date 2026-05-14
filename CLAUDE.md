# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## High-Level Architecture

This is a Next.js application called 9Router that acts as an AI router and token saver. It's a proxy that sits between a user's CLI tool (like Claude Code, Cursor, etc.) and various AI providers.

The core functionality includes:

- **RTK Token Saver**: Compresses tool outputs to save tokens.
- **Smart Fallback**: Automatically routes requests between different AI providers (e.g., from a subscription to a cheaper or free tier) based on availability and user configuration.
- **Quota Tracking**: Monitors token usage for different providers.
- **Format Translation**: Translates requests and responses between different AI model API formats (e.g., OpenAI to Claude).

### Key Directories and Files

- `src/app/`: The Next.js application, including the frontend dashboard and API routes.
  - `src/app/api/`: Contains all the backend API endpoints.
    - `src/app/api/v1/`: The main OpenAI-compatible API endpoint for proxying requests.
  - `src/app/dashboard/`: The frontend for the user dashboard.
- `src/lib/`: Contains shared libraries, utilities, and the local JSON database logic (`localDb.js`, `usageDb.js`).
- `src/mitm/`: Likely contains the core "man-in-the-middle" proxy and routing logic.
- `proxy.js`: A key file for the core proxying functionality.
- `package.json`: Defines scripts and dependencies. The project uses `npm` for package management.

## Common Development Tasks

### Setup

1. Install dependencies:

    ```bash
    npm install
    ```

2. Create a `.env` file from the example:

    ```bash
    cp .env.example .env
    ```

### Running the Application

- **Run the development server:**

    ```bash
    PORT=20128 NEXT_PUBLIC_BASE_URL=http://localhost:20128 npm run dev
    ```

- **Build for production:**

    ```bash
    npm run build
    ```

- **Start in production mode:**

    ```bash
    PORT=20128 HOSTNAME=0.0.0.0 NEXT_PUBLIC_BASE_URL=http://localhost:20128 npm run start
    ```

### Linting

- Run ESLint to check for code quality issues:

    ```bash
    npx eslint .
    ```

There are no dedicated test scripts in `package.json`, so manual testing of the dashboard and API endpoints is likely the primary method of testing.

<!-- SPECKIT START -->
For additional context about technologies to be used, project structure,
shell commands, and other important information, read the current plan
at /Users/quannguyen/workspace/gapowork/9router/specs/001-skip-model-on-disabled-provider/plan.md
<!-- SPECKIT END -->
