# DATA QUALITY PIPELINE

```text
Source Systems
      │
      ▼
data/00-incoming
      │
      │  File inventory
      │  Format inspection
      │  Encoding inspection
      │  Structural inspection
      ▼
data/01-raw
      │
      │  Immutable source copy
      │  Original files preserved
      ▼
data/02-bronze
      │
      │  Encoding standardization
      │  Delimiter handling
      │  Initial schema
      │  Technical metadata
      ▼
Data Quality Checks
      │
      │  Nulls
      │  Duplicates
      │  Invalid records
      │  Key validation
      │  Business rules
      ├──────────────► data/05-rejected
      │
      ▼
data/03-silver
      │
      │  Clean data types
      │  Standard dates
      │  Normalized values
      │  Validated relationships
      ▼
Data Modeling
      │
      │  Joins
      │  Relationships
      │  Analytical structure
      ▼
Business SQL
      │
      │  Aggregations
      │  Metrics
      │  KPI queries
      ▼
data/04-gold
      │
      │  Business-ready datasets
      │  Dashboard-ready outputs
      ▼
Reports / Analytics
```

## Main tools

```text
File inspection     → Linux / Bash
Raw ingestion       → Bash
Bronze processing   → Bash + DuckDB
Quality checks      → DuckDB SQL
Silver processing   → DuckDB SQL
Data modeling       → DuckDB SQL
Gold and KPIs       → DuckDB SQL
Python              → Only when Bash or DuckDB are not sufficient
```

## Data flow

```text
Incoming
   ↓
Raw
   ↓
Bronze
   ↓
Quality Checks
   ├── Rejected
   ↓
Silver
   ↓
Data Modeling
   ↓
Business SQL
   ↓
Gold
```