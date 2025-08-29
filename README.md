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

You can run the CLI with your system Ruby, but using Bundler ensures the right gems are loaded:

```bash
bundle exec ruby journal_gen.rb --help
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
- `diet/` — questions to track meals, calories, hydration, and well-being
- `shared/` (header and separator templates)

---

## Usage

Generate a journal file (uses defaults from `config.yml` when present):

```bash
bundle exec ruby journal_gen.rb
```

### Command reference

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

Notes:

- If `--file` is omitted, a new file named `journal-YYYY-MM-DD.md` is created.
- If `--output-dir` is provided without `--file`, the new file is placed there.
- `--template-dir` can point to a custom templates folder if you add your own set.

---

## Examples

```bash
# Use default set (from config.yml)
bundle exec ruby journal_gen.rb

# Create a work journal
bundle exec ruby journal_gen.rb --set work

# Create a family journal in a specific directory
bundle exec ruby journal_gen.rb --set family --output-dir ~/Documents/Journals

# Generate 8 weeks starting next Monday, skipping monthly summaries
bundle exec ruby journal_gen.rb --weeks 8 --start-next-monday --skip-monthly

# Just see what would be generated
bundle exec ruby journal_gen.rb --dry-run

# List available sets
bundle exec ruby journal_gen.rb --list-sets

# Diet tracking examples
# ----------------------
# Start a new diet journal in ./journals
bundle exec ruby journal_gen.rb --set diet --output-dir ./journals

# Append 2 more weeks to an existing file
bundle exec ruby journal_gen.rb --set diet --weeks 2 \
  --file ./journals/journal-2025-01-01.md
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

Tip for custom sets: the tool tries to auto-resume by detecting the last generated
day in the file. It looks for lines that include a day heading with a date. If you
create custom day templates, ensure the date appears in the heading so auto-resume
keeps working.

---

## How dates are chosen

- Start date: by default, the day after the last generated day in the file; if the
  file does not yet contain entries, today. Use `--start-next-monday` to align to
  the next ISO Monday instead.
- End date: `--weeks N` generates `N * 7` days starting from the start date.
- Weekly summaries: inserted after each ISO Sunday (end of week), unless `--skip-weekly`.
- 4-week summaries: inserted every 28 days of generated content, unless `--skip-monthly`.

Use `--dry-run` to print the plan (dates, set, and target file) without writing anything.

---

## Tests

Run the test suite with Bundler to ensure dependencies like `clamp` are available:

```bash
bundle exec ruby -I test test/journal_gen_options_test.rb
```

---

## Troubleshooting

- clamp not found: run `bundle install`, then use `bundle exec ruby journal_gen.rb`.
- No templates found: pass an explicit `--template-dir /absolute/path/to/templates`.
- Didn’t resume where expected: ensure your daily headings include a date, or pass
  `--file` to target the correct document and `--start-next-monday` to realign.

---

## Commit conventions

- **feat:** new features (e.g. new CLI options)  
- **fix:** bug fixes  
- **docs:** documentation updates  
- **chore:** dependency bumps, maintenance  
- **refactor:** code changes without new features  
