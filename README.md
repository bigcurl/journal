# Journal CLI (Markdown + ERB + Clamp)

This CLI appends daily journal blocks to a single Markdown file, adds **weekly summaries after each ISO Sunday**, and a **monthly summary after every 4 weeks**.

Supports **question sets** under `templates/` (convention over configuration):
- `personal` (default)
- `work`
- `family`

Shared templates in `templates/shared`.

## Config
Set default in `config.yml`:
```yaml
default_set: personal
```

## Usage
```bash
bundle install
ruby journal_gen.rb
ruby journal_gen.rb --list-sets
ruby journal_gen.rb --set work
ruby journal_gen.rb --set family
```
