# SqlAgent

SqlAgent is an AI-powered SQL assistant that provides an interactive chat interface for querying databases. Built with Phoenix LiveView and Elixir, it combines the power of OpenAI's language models with DuckDB for fast analytical queries. Users can have natural language conversations with the AI assistant, which can execute SQL queries and provide intelligent responses about data.

## Features

- **Interactive Chat Interface**: Real-time chat powered by Phoenix LiveView
- **AI-Powered SQL Assistant**: Uses OpenAI's GPT models through LangChain
- **DuckDB Integration**: Fast analytical database for querying data
- **User Authentication**: Secure user registration and login system
- **Real-time Updates**: Live message updates and query execution status
- **Background Job Processing**: Async message processing with Oban
- **Tool Integration**: AI can execute SQL queries as function tools

## Prerequisites

Before running SqlAgent, ensure you have:

- **Elixir 1.15+** and **Erlang/OTP 24+**
- **PostgreSQL** (for user data and chat history)
- **Node.js** (for asset compilation)
- **OpenAI API Key** (for AI functionality)

## Environment Variables

SqlAgent requires the following environment variables:

### Required for Development

```bash
# OpenAI API Key (required for AI functionality)
export OPENAI_API_KEY="your_openai_api_key_here"
```

### Optional for Development

```bash
# Database port (defaults to 4000)
export PORT=4000
```

### Required for Production

```bash
# Database connection URL
export DATABASE_URL="ecto://username:password@hostname/database_name"

# Secret key base for signing sessions and cookies
export SECRET_KEY_BASE="your_secret_key_base_here"

# Application host
export PHX_HOST="yourdomain.com"

# Application port
export PORT=4000

# OpenAI API Key
export OPENAI_API_KEY="your_openai_api_key_here"

# Enable Phoenix server (for releases)
export PHX_SERVER=true
```

### Optional for Production

```bash
# Database pool size (defaults to 10)
export POOL_SIZE=10

# Enable IPv6 (set to "true" or "1")
export ECTO_IPV6=false

# DNS cluster query for distributed deployments
export DNS_CLUSTER_QUERY="your_app_name.local"
```

## Setup Instructions

### 1. Clone and Install Dependencies

```bash
git clone <repository_url>
cd sql_agent
mix setup
```

The `mix setup` command will:
- Install Elixir dependencies (`mix deps.get`)
- Create and migrate the database (`mix ecto.setup`)
- Install and build frontend assets (`mix assets.setup && mix assets.build`)

### 2. Set Environment Variables

Create a `.env` file in the project root (optional, for convenience):

```bash
# .env
export OPENAI_API_KEY="your_openai_api_key_here"
export PORT=4000
```

Then source it:
```bash
source .env
```

Or set the variables directly in your shell:
```bash
export OPENAI_API_KEY="your_openai_api_key_here"
```

### 3. Database Setup

The application uses PostgreSQL for storing user data and chat history, plus DuckDB for analytical queries.

#### PostgreSQL Configuration (Development)
The default development configuration expects:
- **Host**: localhost
- **Port**: 5432 (default)
- **Username**: postgres
- **Password**: postgres
- **Database**: sql_agent_dev

Make sure PostgreSQL is running and accessible with these credentials, or update `config/dev.exs` with your settings.

#### DuckDB
DuckDB is embedded and will automatically create a database file at `priv/duckdb/sql_agent.db`.

### 4. Start the Application

```bash
# Start with interactive Elixir shell (recommended for development)
iex -S mix phx.server

# Or start as a daemon
mix phx.server
```

### 5. Access the Application

Open your browser and visit:
- **Development**: [http://localhost:4000](http://localhost:4000)
- **Production**: Your configured domain

## How to Use SqlAgent

1. **Register/Login**: Create an account or log in to access the chat interface
2. **Start Chatting**: Type natural language questions about data or SQL queries
3. **AI Assistance**: The AI assistant will:
   - Answer questions about SQL and databases
   - Execute SQL queries against the DuckDB database
   - Provide explanations and insights about query results
   - Help with data analysis tasks

### Example Interactions

```
User: "Show me all tables in the database"
AI: I'll check what tables are available in the database.
[AI executes: SHOW TABLES]

User: "Create a simple sales table with sample data"
AI: I'll create a sales table with some sample data for you.
[AI executes SQL to create table and insert sample data]

User: "What were the top 5 sales by amount last month?"
AI: I'll query the sales data to find the top 5 sales by amount.
[AI executes appropriate SELECT query with ORDER BY and LIMIT]
```

## Development Commands

```bash
# Setup project (run once)
mix setup

# Start development server
mix phx.server

# Start with interactive shell
iex -S mix phx.server

# Run tests
mix test

# Reset database
mix ecto.reset

# Install new dependencies
mix deps.get

# Compile assets
mix assets.build

# Deploy assets (minified)
mix assets.deploy

# Format code
mix format

# Run pre-commit checks
mix precommit
```

## Production Deployment

### Generate Secret Key Base

```bash
mix phx.gen.secret
```

Use this value for the `SECRET_KEY_BASE` environment variable.

### Database Migration

```bash
# In production environment
mix ecto.create
mix ecto.migrate
```

### Asset Compilation

```bash
mix assets.deploy
```

### Release Build

```bash
# Build release
mix release

# Run release
PHX_SERVER=true bin/sql_agent start
```

## Architecture

- **Frontend**: Phoenix LiveView for real-time UI
- **Backend**: Elixir/Phoenix application
- **AI Integration**: LangChain + OpenAI GPT models
- **Primary Database**: PostgreSQL (user data, chat history)
- **Analytics Database**: DuckDB (SQL query execution)
- **Background Jobs**: Oban for async message processing
- **Authentication**: Phoenix-generated user auth system

## Troubleshooting

### Common Issues

1. **OpenAI API Key Missing**
   ```
   Error: environment variable OPENAI_API_KEY is missing
   ```
   **Solution**: Set the OPENAI_API_KEY environment variable

2. **Database Connection Error**
   ```
   Error: could not connect to database
   ```
   **Solution**: Ensure PostgreSQL is running and credentials in `config/dev.exs` are correct

3. **Asset Compilation Fails**
   ```
   Error: node/npm not found
   ```
   **Solution**: Install Node.js and run `mix assets.setup`

4. **Port Already in Use**
   ```
   Error: port 4000 already in use
   ```
   **Solution**: Set `PORT` environment variable to a different port

### Getting Help

For issues specific to SqlAgent, check:
1. The application logs for detailed error messages
2. Ensure all environment variables are properly set
3. Verify database connections and permissions

## Learn More

### Phoenix Framework
* Official website: https://www.phoenixframework.org/
* Guides: https://hexdocs.pm/phoenix/overview.html
* Docs: https://hexdocs.pm/phoenix
* Forum: https://elixirforum.com/c/phoenix-forum
* Source: https://github.com/phoenixframework/phoenix

### Technologies Used
* **Phoenix LiveView**: https://hexdocs.pm/phoenix_live_view
* **LangChain**: https://hexdocs.pm/langchain
* **DuckDB**: https://duckdb.org/
* **Oban**: https://hexdocs.pm/oban
