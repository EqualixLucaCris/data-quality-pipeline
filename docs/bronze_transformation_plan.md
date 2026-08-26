File	        Convert UTF-8	                Standardize Delimiter	        Output Bronze
campaigns.json	    No (is UTF-8)	                    N/A	                        JSON UTF-8
customers.csv       Yes	                                ; → ,	                    CSV UTF-8
order_items.csv	    No (US-ASCII comp with UTF-8)	    ` → ,`
orders.csv	        No (is UTF-8)	                    No need                 	CSV UTF-8
products.csv	    Yes (UTF-16LE → UTF-8)	            TAB → ,	                    CSV UTF-8
stores.xml	        Yes (ISO-8859-1 → UTF-8)	        N/A	                        XML UTF-8

### products.csv — Delimiter decision

**Source format**
- Encoding: UTF-16LE
- Delimiter: TAB
- Decimal separator: comma (`,`)

**Initial transformation**
- UTF-16LE → UTF-8
- TAB → comma

**Issue detected**
The comma delimiter conflicts with the decimal separator used in
`unit_cost` and `unit_price`, producing an inconsistent number of fields.

Expected fields: 6  
Detected fields: 7–8

**Decision**
- Encoding: UTF-8
- Delimiter: semicolon (`;`)
- Decimal separator: comma (`,`)
- Preserve decimal values until Silver type conversion.

**Status:** Bronze transformation rule corrected.