#!/usr/bin/env elixir

# Script to insert test tables and data into DuckDB
# Run with: mix run priv/setup_test_data.exs

alias SqlAgent.DuckDB

defmodule TestDataSetup do
  def run do
    IO.puts("Setting up test tables and data in DuckDB...")
    
    # Create sample tables
    create_customers_table()
    create_orders_table()
    create_products_table()
    create_order_items_table()
    
    # Insert sample data
    insert_customers_data()
    insert_products_data()
    insert_orders_data()
    insert_order_items_data()
    
    IO.puts("Test data setup completed!")
    verify_data()
  end
  
  defp create_customers_table do
    query = """
    CREATE TABLE IF NOT EXISTS customers (
      id INTEGER PRIMARY KEY,
      name VARCHAR(100),
      email VARCHAR(150),
      city VARCHAR(50),
      country VARCHAR(50),
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
    """
    execute_query(query, "Creating customers table")
  end
  
  defp create_products_table do
    query = """
    CREATE TABLE IF NOT EXISTS products (
      id INTEGER PRIMARY KEY,
      name VARCHAR(200),
      category VARCHAR(50),
      price DECIMAL(10,2),
      stock_quantity INTEGER,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
    """
    execute_query(query, "Creating products table")
  end
  
  defp create_orders_table do
    query = """
    CREATE TABLE IF NOT EXISTS orders (
      id INTEGER PRIMARY KEY,
      customer_id INTEGER,
      order_date DATE,
      total_amount DECIMAL(10,2),
      status VARCHAR(20),
      FOREIGN KEY (customer_id) REFERENCES customers(id)
    );
    """
    execute_query(query, "Creating orders table")
  end
  
  defp create_order_items_table do
    query = """
    CREATE TABLE IF NOT EXISTS order_items (
      id INTEGER PRIMARY KEY,
      order_id INTEGER,
      product_id INTEGER,
      quantity INTEGER,
      unit_price DECIMAL(10,2),
      FOREIGN KEY (order_id) REFERENCES orders(id),
      FOREIGN KEY (product_id) REFERENCES products(id)
    );
    """
    execute_query(query, "Creating order_items table")
  end
  
  defp insert_customers_data do
    query = """
    INSERT INTO customers (id, name, email, city, country) VALUES
    (1, 'John Smith', 'john.smith@email.com', 'New York', 'USA'),
    (2, 'Emma Johnson', 'emma.johnson@email.com', 'London', 'UK'),
    (3, 'Carlos Rodriguez', 'carlos.rodriguez@email.com', 'Madrid', 'Spain'),
    (4, 'Yuki Tanaka', 'yuki.tanaka@email.com', 'Tokyo', 'Japan'),
    (5, 'Sophie Müller', 'sophie.mueller@email.com', 'Berlin', 'Germany'),
    (6, 'Michael Brown', 'michael.brown@email.com', 'Sydney', 'Australia'),
    (7, 'Isabella Silva', 'isabella.silva@email.com', 'São Paulo', 'Brazil'),
    (8, 'Ahmed Hassan', 'ahmed.hassan@email.com', 'Cairo', 'Egypt'),
    (9, 'Lisa Anderson', 'lisa.anderson@email.com', 'Toronto', 'Canada'),
    (10, 'Pierre Dubois', 'pierre.dubois@email.com', 'Paris', 'France')
    ON CONFLICT DO NOTHING;
    """
    execute_query(query, "Inserting customers data")
  end
  
  defp insert_products_data do
    query = """
    INSERT INTO products (id, name, category, price, stock_quantity) VALUES
    (1, 'Laptop Pro 15"', 'Electronics', 1299.99, 50),
    (2, 'Wireless Headphones', 'Electronics', 199.99, 150),
    (3, 'Office Chair', 'Furniture', 349.50, 25),
    (4, 'Coffee Mug Set', 'Kitchen', 29.99, 200),
    (5, 'Running Shoes', 'Sports', 89.99, 75),
    (6, 'Bluetooth Speaker', 'Electronics', 79.99, 100),
    (7, 'Desk Lamp', 'Furniture', 45.00, 80),
    (8, 'Water Bottle', 'Sports', 15.99, 300),
    (9, 'Notebook Set', 'Office', 12.50, 150),
    (10, 'Phone Case', 'Electronics', 24.99, 200),
    (11, 'Standing Desk', 'Furniture', 599.00, 15),
    (12, 'Yoga Mat', 'Sports', 35.99, 120)
    ON CONFLICT DO NOTHING;
    """
    execute_query(query, "Inserting products data")
  end
  
  defp insert_orders_data do
    query = """
    INSERT INTO orders (id, customer_id, order_date, total_amount, status) VALUES
    (1, 1, '2024-01-15', 1329.98, 'completed'),
    (2, 2, '2024-01-16', 199.99, 'completed'),
    (3, 3, '2024-01-17', 395.49, 'completed'),
    (4, 4, '2024-01-18', 105.98, 'shipped'),
    (5, 5, '2024-01-19', 79.99, 'completed'),
    (6, 1, '2024-01-20', 644.00, 'processing'),
    (7, 6, '2024-01-21', 89.99, 'completed'),
    (8, 7, '2024-01-22', 60.48, 'shipped'),
    (9, 8, '2024-01-23', 24.99, 'completed'),
    (10, 9, '2024-01-24', 1299.99, 'processing'),
    (11, 10, '2024-01-25', 125.98, 'completed'),
    (12, 2, '2024-01-26', 349.50, 'shipped')
    ON CONFLICT DO NOTHING;
    """
    execute_query(query, "Inserting orders data")
  end
  
  defp insert_order_items_data do
    query = """
    INSERT INTO order_items (id, order_id, product_id, quantity, unit_price) VALUES
    (1, 1, 1, 1, 1299.99),
    (2, 1, 4, 1, 29.99),
    (3, 2, 2, 1, 199.99),
    (4, 3, 3, 1, 349.50),
    (5, 3, 7, 1, 45.00),
    (6, 4, 5, 1, 89.99),
    (7, 4, 8, 1, 15.99),
    (8, 5, 6, 1, 79.99),
    (9, 6, 11, 1, 599.00),
    (10, 6, 7, 1, 45.00),
    (11, 7, 5, 1, 89.99),
    (12, 8, 4, 2, 29.99),
    (13, 9, 10, 1, 24.99),
    (14, 10, 1, 1, 1299.99),
    (15, 11, 2, 1, 199.99),
    (16, 11, 12, 1, 35.99),
    (17, 12, 3, 1, 349.50)
    ON CONFLICT DO NOTHING;
    """
    execute_query(query, "Inserting order items data")
  end
  
  defp execute_query(query, description) do
    IO.puts("#{description}...")
    case DuckDB.execute(query) do
      {:ok, result} -> 
        IO.puts("✓ Success: #{description}")
        result
      {:error, reason} -> 
        IO.puts("✗ Error #{description}: #{reason}")
        {:error, reason}
    end
  end
  
  defp verify_data do
    IO.puts("\nVerifying data...")
    
    queries = [
      {"customers", "SELECT COUNT(*) as customer_count FROM customers"},
      {"products", "SELECT COUNT(*) as product_count FROM products"},
      {"orders", "SELECT COUNT(*) as order_count FROM orders"},
      {"order_items", "SELECT COUNT(*) as order_item_count FROM order_items"}
    ]
    
    Enum.each(queries, fn {table, query} ->
      case DuckDB.execute(query) do
        {:ok, result} -> IO.puts("✓ #{table}: #{String.trim(result)}")
        {:error, reason} -> IO.puts("✗ Error checking #{table}: #{reason}")
      end
    end)
    
    # Show sample data
    IO.puts("\nSample queries you can try:")
    IO.puts("1. SELECT * FROM customers LIMIT 5;")
    IO.puts("2. SELECT p.name, p.price, p.category FROM products p WHERE p.price > 100;")
    IO.puts("3. SELECT c.name, o.order_date, o.total_amount FROM customers c JOIN orders o ON c.id = o.customer_id;")
    IO.puts("4. SELECT p.category, COUNT(*) as product_count, AVG(p.price) as avg_price FROM products p GROUP BY p.category;")
    IO.puts("5. SELECT c.country, COUNT(o.id) as order_count, SUM(o.total_amount) as total_sales FROM customers c LEFT JOIN orders o ON c.id = o.customer_id GROUP BY c.country ORDER BY total_sales DESC;")
  end
end

# Start the application if not already running
unless Process.whereis(SqlAgent.DuckDB) do
  {:ok, _} = Application.ensure_all_started(:sql_agent)
  Process.sleep(1000) # Give DuckDB time to start
end

TestDataSetup.run()