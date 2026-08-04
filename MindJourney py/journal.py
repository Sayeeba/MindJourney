import sqlite3
import datetime
import os

DB_FILE = 'journal.db'

def init_db():
    """Initialize the SQLite database and create the table if it doesn't exist."""
    with sqlite3.connect(DB_FILE) as conn:
        cursor = conn.cursor()
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS entries (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                timestamp TEXT NOT NULL,
                content TEXT NOT NULL
            )
        ''')
        conn.commit()

def clear_screen():
    """Clears the terminal screen for better readability."""
    os.system('cls' if os.name == 'nt' else 'clear')

def write_entry():
    """Prompt the user to write a new journal entry and save it to the database."""
    print("\n--- Write New Entry ---")
    print("Type your entry below. (Press Enter to finish)")
    content = input("> ")
    
    if not content.strip():
        print("Entry cannot be empty. Discarded.")
        return

    timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    
    with sqlite3.connect(DB_FILE) as conn:
        cursor = conn.cursor()
        cursor.execute("INSERT INTO entries (timestamp, content) VALUES (?, ?)", (timestamp, content))
        conn.commit()
    print("✅ Journal entry saved successfully!")

def view_entries():
    """Display all previous journal entries."""
    print("\n--- Your Journal Entries ---")
    with sqlite3.connect(DB_FILE) as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT id, timestamp, content FROM entries ORDER BY timestamp DESC")
        entries = cursor.fetchall()

    if not entries:
        print("Your journal is empty. Start writing!")
        return False

    for entry in entries:
        entry_id, timestamp, content = entry
        # Show a preview (first 50 characters) if it's a long entry
        preview = content[:50] + "..." if len(content) > 50 else content
        print(f"[{entry_id}] {timestamp} | {preview}")
    
    return True

def read_full_entry():
    """Allow the user to read a full entry by ID."""
    if not view_entries():
        return

    try:
        entry_id = int(input("\nEnter the ID of the entry you want to read (or 0 to cancel): "))
        if entry_id == 0:
            return
            
        with sqlite3.connect(DB_FILE) as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT timestamp, content FROM entries WHERE id = ?", (entry_id,))
            entry = cursor.fetchone()

            if entry:
                print(f"\n--- Entry from {entry[0]} ---")
                print(entry[1])
                print("-" * 30)
            else:
                print("❌ Entry not found.")
    except ValueError:
        print("❌ Invalid input. Please enter a valid number.")

def edit_entry():
    """Allow the user to edit an existing entry."""
    if not view_entries():
        return

    try:
        entry_id = int(input("\nEnter the ID of the entry you want to edit (or 0 to cancel): "))
        if entry_id == 0:
            return

        with sqlite3.connect(DB_FILE) as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT content FROM entries WHERE id = ?", (entry_id,))
            entry = cursor.fetchone()

            if entry:
                print(f"\n[Current Content]: {entry[0]}")
                print("\nType your new content below:")
                new_content = input("> ")

                if new_content.strip():
                    cursor.execute("UPDATE entries SET content = ? WHERE id = ?", (new_content, entry_id))
                    conn.commit()
                    print("✅ Entry updated successfully!")
                else:
                    print("Entry cannot be empty. Update canceled.")
            else:
                print("❌ Entry not found.")
    except ValueError:
        print("❌ Invalid input. Please enter a valid number.")

def main():
    """Main application loop."""
    init_db()
    
    while True:
        print("\n" + "="*30)
        print("      MY PERSONAL JOURNAL      ")
        print("="*30)
        print("1. 📝 Write a new journal entry")
        print("2. 📖 View all previous entries")
        print("3. 🔍 Read full entry")
        print("4. ✏️  Edit an entry")
        print("5. 🚪 Exit")
        print("="*30)
        
        choice = input("Select an option (1-5): ")

        if choice == '1':
            clear_screen()
            write_entry()
        elif choice == '2':
            clear_screen()
            view_entries()
        elif choice == '3':
            clear_screen()
            read_full_entry()
        elif choice == '4':
            clear_screen()
            edit_entry()
        elif choice == '5':
            print("Goodbye! Keep journaling! 👋")
            break
        else:
            print("❌ Invalid choice. Please select a number between 1 and 5.")

if __name__ == "__main__":
    clear_screen()
    main()