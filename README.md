# 📓 Journal CLI

A Ruby command-line tool to generate structured Markdown journals.  
It uses ERB templates for different sets of questions (personal, work, family),  
and inserts daily, weekly, and monthly summary sections.

---

## Installation

Clone the repository and install dependencies:

```bash
bundle install
```

---

## Configuration

The default question set can be configured in `config.yml`:

```yaml
default_set: personal
```

Available sets are located in `templates/`:

- `personal/`
- `work/`
- `family/`
- `sport/`
- `diet/` — questions to track meals, calories, hydration, and well‑being
- `shared/` (header and separator templates)

---

## Usage

Generate a journal file:

```bash
ruby journal_gen.rb
```

### Options

```
-f, --file FILE           Markdown journal file to create or extend
-o, --output-dir DIR      Directory for new journal file (used only if --file is not given)
-w, --weeks N             Number of weeks to generate (default: 4)
-t, --template-dir DIR    Directory with ERB templates (default: ./templates)
-s, --set NAME            Question set (folder in templates/, default from config or "personal")
    --skip-weekly         Skip weekly summary blocks
    --skip-monthly        Skip 4-week “monthly” summary blocks
    --start-next-monday   Start generation on the next Monday (instead of the day after last entry)
    --dry-run             Print planned dates, do not write
    --list-sets           List available sets and exit
-h, --help                Print help
```

---

## Examples

```bash
# Use default set (from config.yml)
ruby journal_gen.rb

# Create a work journal
ruby journal_gen.rb --set work

# Create a family journal in a specific directory
ruby journal_gen.rb --set family --output-dir ~/Documents/Journals

# Generate 8 weeks starting next Monday, skipping monthly summaries
ruby journal_gen.rb --weeks 8 --start-next-monday --skip-monthly

# Just see what would be generated
ruby journal_gen.rb --dry-run

# List available sets
ruby journal_gen.rb --list-sets
```

---

## Templates

All templates live under `templates/`.  
Each set (`personal`, `work`, `family`) contains:

- `day.md.erb` – daily questions  
- `weekly.md.erb` – weekly summary  
- `monthly.md.erb` – 4-week summary  

Shared templates:

- `shared/header.md.erb` – file header  
- `shared/separator.md.erb` – divider between entries  

You can create your own sets by adding a new folder inside `templates/`
(e.g. `templates/fitness/`) with the same three ERB files.

---

## Tests

Run the test suite with Bundler to ensure dependencies like `clamp` are available:

```bash
bundle exec ruby -I test test/journal_gen_options_test.rb
```

---

## Commit conventions

- **feat:** new features (e.g. new CLI options)  
- **fix:** bug fixes  
- **docs:** documentation updates  
- **chore:** dependency bumps, maintenance  
- **refactor:** code changes without new features  
