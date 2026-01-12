# BenchmarX Configuration

## AI Assistance Policy

This project uses AI tools (such as GitHub Copilot, LLMs) **exclusively as productivity and support mechanisms**.

### AI Tools MAY:
- ✅ Generate code based on human-provided specifications
- ✅ Suggest improvements and optimizations
- ✅ Help with documentation and explanations
- ✅ Provide debugging assistance
- ✅ Generate boilerplate code
- ✅ Assist with refactoring

### AI Tools MUST NEVER:
- ❌ Define or alter core scoring logic autonomously
- ❌ Set context weights or business rules
- ❌ Make autonomous decisions
- ❌ Be part of the core decision engine
- ❌ Alter business logic without explicit human approval
- ❌ Act as a source of truth
- ❌ Modify production data without validation

### Human Authority

**All core business logic, scoring rules, and architectural decisions are made by humans.**

AI assistance is **strictly advisory and non-binding**. Every AI-generated suggestion requires:
1. Human review and validation
2. Explicit approval before implementation
3. Testing and verification
4. Documentation of rationale

### Advisory Recommendations

Any AI-generated recommendations or insights are:
- **Non-binding** and clearly marked as advisory
- **Separated** from core authoritative logic
- **Subject to human validation** before any action
- **Never automatically applied** to production systems

### Architectural Evolution

The platform is designed to evolve under human governance:
- All structural changes are human-defined
- All modifications are versioned and auditable
- All extensions are subject to human validation
- Adaptability is a core requirement, controlled by humans

## Code of Conduct

### Scoring Philosophy

Scoring within BenchmarX follows these principles:
- **Rule-based**: Explicit, documented rules only
- **Deterministic**: Same inputs always produce same outputs
- **Transparent**: All calculations visible and traceable
- **Simple over complex**: Clarity over sophistication

**The scoring logic is NOT designed to be mathematically optimal or predictive.**

Purpose of scoring:
- Make trade-offs explicit
- Enable human review
- Support reasoning and discussion
- Provide context-aware insights

**Auditability and explainability are prioritized over algorithmic complexity.**

### Human-Defined Logic
- All scoring algorithms must be deterministic
- All business rules must be documented
- All context weights must have rationale
- No black-box decision-making

### Transparency
- Every score must be explainable
- Every calculation must be auditable
- Every change must be logged

### Governance
- Humans define the rules
- Machines execute the rules
- Humans interpret the results

## Architecture Decision Records

All significant architectural decisions are documented in `docs/architecture.md`.

Key decisions:
1. Single Source of Truth: PostgreSQL (Neon)
2. No AI in core scoring logic
3. Human-defined context weights with rationale
4. Materialized scoring results for auditability
5. Read-only BI layer (Metabase)

## Development Guidelines

### SQL
- Use parameterized queries (prevent SQL injection)
- Add comments for complex logic
- Include function documentation
- Version all schema changes

### Python
- Follow PEP 8 style guide
- Add type hints where applicable
- Document all functions with docstrings
- Use meaningful variable names

### Git
- Use conventional commits format
- Write clear commit messages
- Reference issues in commits
- Keep commits focused and atomic

## Security

### Database
- Use read-only users for BI tools
- Enable SSL for all connections
- Rotate credentials regularly
- Audit database access logs

### Application
- Validate all user inputs
- Use environment variables for secrets
- Never commit credentials
- Follow principle of least privilege

## Testing

All code should be tested:
- SQL: Test scoring functions with known inputs
- Python: Unit tests for core logic
- Integration: End-to-end workflow tests
- Performance: Load testing for large datasets

## Support

For questions or issues:
1. Check documentation in `docs/`
2. Search existing GitHub issues
3. Open a new issue with details
4. Provide reproducible examples
