# Source Data vs. Analytical Data
Source Data (Raw Layer): Operational state stored exactly as delivered by upstream producers. Contains unparsed strings, bad formats, missing relationships, and historical duplicates. Its purpose is auditability and full replayability.

Analytical Data (Core/Mart Layers): Standardized, cleaned, deduplicated, and modeled (Facts/Dimensions) data formatted for direct querying by business analysts and BI tools.