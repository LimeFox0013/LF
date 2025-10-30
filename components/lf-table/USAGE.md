# LFTable Usage Guide

## Overview

LFTable is a flexible table component system for Godot that allows you to define table structure once and populate it with data dynamically.

## Components

- **LFTable**: Main table container
- **LFTableDef**: Table definition container (holds cell definitions)
- **LFTableCellDef**: Individual cell definition with name and size constraints
- **LFTableRow**: Row container (automatically created)
- **LFTableCell**: Individual cell (automatically created)

## Setup

### 1. Scene Structure

Create a scene with the following structure:
```
LFTable
└── LFTableDef
    ├── LFTableCellDef (cellName: "id")
    ├── LFTableCellDef (cellName: "name")
    ├── LFTableCellDef (cellName: "age")
    └── LFTableCellDef (cellName: "email")
```

### 2. Configure Cell Definitions

For each `LFTableCellDef`, set the following properties in the Inspector:

- **cellName**: Unique identifier for the cell (e.g., "id", "name", "age")
- **maxX**: Maximum width (int or "auto")
- **maxY**: Maximum height (int or "auto")

Example:
```
LFTableCellDef:
  cellName: "id"
  maxX: 50
  maxY: "auto"

LFTableCellDef:
  cellName: "name"
  maxX: 150
  maxY: "auto"

LFTableCellDef:
  cellName: "age"
  maxX: 80
  maxY: "auto"

LFTableCellDef:
  cellName: "email"
  maxX: 200
  maxY: "auto"
```

### 3. Populate with Data

In your script, get a reference to the table and populate it with data:

```gdscript
extends Node

@onready var table = $LFTable

func _ready():
	var data = [
		{"id": 1, "name": "John Doe", "age": 30, "email": "john@example.com"},
		{"id": 2, "name": "Jane Smith", "age": 25, "email": "jane@example.com"},
		{"id": 3, "name": "Bob Johnson", "age": 35, "email": "bob@example.com"}
	]
	
	table.setTableData(data)
```

## API Reference

### LFTable

#### Methods

- `setTableData(data: Array)` - Set all table data at once
  - `data`: Array of Dictionaries, each with keys matching cellName properties

- `addRow(rowData: Dictionary)` - Add a single row to the table
  - `rowData`: Dictionary with keys matching cellName properties

- `clearRows()` - Remove all rows from the table

#### Example

```gdscript
# Set all data at once
table.setTableData([
	{"id": 1, "name": "Alice"},
	{"id": 2, "name": "Bob"}
])

# Add individual rows
table.addRow({"id": 3, "name": "Charlie"})

# Clear all rows
table.clearRows()
```

### LFTableCellDef

#### Properties

- `cellName: String` - Unique identifier for this cell (required)
- `maxX: Variant` - Maximum width ("auto" or int value)
- `maxY: Variant` - Maximum height ("auto" or int value)

## Notes

- Cell names must be unique within a table definition
- Data dictionaries should have keys matching the cellName properties
- Missing keys in data dictionaries will result in empty cells
- The table automatically creates rows and cells based on the definition
- Cell sizes are set as custom_minimum_size based on maxX/maxY values
