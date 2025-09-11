# Auto-Documentation Framework

A reusable system for maintaining self-updating project documentation through AI-assisted automation.

## Framework Overview

This framework implements a **hybrid documentation approach** with **auto-triggered maintenance** to prevent documentation drift and reduce recurring issues across projects.

### Core Concept

**Problem**: Documentation becomes outdated, deployment processes break, and the same mistakes happen repeatedly.

**Solution**: Create a self-maintaining documentation system that:
1. **Auto-detects** when documentation needs updates
2. **Intelligently routes** updates to appropriate documentation levels
3. **Maintains consistency** across multiple documentation files
4. **Learns from issues** to prevent recurring problems

## Framework Architecture

### Two-Tier Documentation Structure

```
Project Root/
├── CLAUDE.md                    # Quick reference for AI assistant
│   ├── Commands & paths         
│   ├── Common mistakes         
│   ├── Quick checklists        
│   └── Cross-references        
└── docs/
    └── DEVELOPMENT.md           # Comprehensive documentation
        ├── Complete workflows   
        ├── Troubleshooting guides
        ├── Architecture details
        └── Cross-references
```

**Tier 1: CLAUDE.md (Quick Reference)**
- **Purpose**: Immediate problem prevention for AI assistant
- **Scope**: Commands, paths, common mistakes, quick checklists
- **Audience**: AI assistant during active development
- **Update Frequency**: High (immediate fixes)

**Tier 2: DEVELOPMENT.md (Comprehensive)**  
- **Purpose**: Complete understanding and troubleshooting
- **Scope**: Full workflows, detailed explanations, architecture
- **Audience**: All developers, future maintainers  
- **Update Frequency**: Medium (systematic updates)

### Auto-Activation System

#### Trigger Pattern Structure

```yaml
documentation_triggers:
  primary_patterns:
    - "[domain] docs need updating"
    - "documentation maintenance needed"
    - "add this to troubleshooting guide"
    - "[domain] process broken"
    - "[domain] issue"
    - "docs are outdated"
  
  technical_patterns:
    - "[specific technology] issue"
    - "wrong [configuration] in [location]"  
    - "permission denied [operation]"
    - "cached [artifact] problem"
    - "[feature] still broken"
```

#### Command Structure

```bash
# Comprehensive review and sync
/task "Review and update [domain] documentation consistency" --agent document-reviewer

# Add specific issue  
/task "Add [issue description] to [domain] troubleshooting guide" --agent document-reviewer

# Sync documentation files
/task "Synchronize [domain] docs between CLAUDE.md and [DOCS].md" --agent document-reviewer
```

## Implementation Guide

### Step 1: Prerequisites and Setup

#### Required Claude Code Configuration

**Global Configuration** (applies to all projects):
```bash
# Location: ~/.claude/
# No special agent configuration required - uses built-in agents:
# - document-reviewer (built-in)
# - Task tool with agent selection
```

**Project-Local Configuration** (optional, for project-specific triggers):
```bash
# Location: /project-root/.claude/
# Create project-specific trigger patterns or agent configurations
```

#### Built-in Agent Dependencies

This framework uses **existing Claude Code agents** - no custom configuration needed:

- **`document-reviewer`**: Built-in agent for comprehensive document analysis
- **`Task` tool**: Built-in with `--agent` parameter for specialized routing
- **Auto-activation patterns**: Uses Claude Code's existing pattern recognition

#### Verification Setup is Working

Test the system is ready:
```bash
# Test 1: Verify document-reviewer agent is available
/task "Test documentation review capability" --agent document-reviewer

# Test 2: Verify Task tool routing works  
/task "Simple test task for agent verification" --agent general-purpose

# Test 3: Test auto-activation (should trigger automatically)
# Just say: "documentation maintenance needed"
```

### Step 2: Initial Documentation Structure

1. **Create Documentation Files**
   ```bash
   # In your project root:
   touch CLAUDE.md
   mkdir -p docs
   touch docs/DEVELOPMENT.md  # or PROJECT_NAME_GUIDE.md
   ```

2. **Define Project-Specific Domains**
   ```yaml
   # Examples for different project types:
   web_app_domains: [deployment, database, authentication, api]
   mobile_domains: [build, signing, store_submission, testing]
   desktop_domains: [packaging, distribution, updates, permissions]
   ```

### Step 3: No Additional Agent Setup Required

**Key Insight**: This framework leverages **existing Claude Code capabilities**:

✅ **Uses built-in agents** (document-reviewer, general-purpose)  
✅ **Uses built-in Task tool** with agent routing  
✅ **Uses built-in pattern recognition** for auto-activation  
✅ **No custom agent configuration needed**  
✅ **No special folder structures required**

**Optional Enhancements** (advanced users):
- Custom trigger patterns in project `.claude/` folder
- Project-specific agent preferences  
- Custom slash commands (if supported)

## Practical Deployment Steps

### Quick Start (5 minutes)

1. **Copy templates to your project**:
   ```bash
   # Create files from templates below
   cp template-CLAUDE.md ./CLAUDE.md
   cp template-DEVELOPMENT.md ./docs/DEVELOPMENT.md
   ```

2. **Customize for your project**:
   - Replace `[Project Name]` with your actual project name
   - Replace `[domain]` with your main domain (e.g., "deployment", "build", "api")
   - Update paths in CLAUDE.md to match your project structure
   - Add your common mistakes and build commands

3. **Test the system**:
   ```bash
   # Say this phrase to test auto-activation:
   "documentation maintenance needed"
   
   # Or use manual command:
   /task "Review and update deployment documentation consistency" --agent document-reviewer
   ```

4. **Start using**:
   - When you encounter issues, use trigger phrases naturally
   - The system will automatically maintain your documentation
   - Both files will stay synchronized

### Step-by-Step Setup Example

**For a typical web application**:

```bash
# 1. Create structure
mkdir -p docs
touch CLAUDE.md docs/DEVELOPMENT.md

# 2. Add to CLAUDE.md:
echo "# MyApp - Claude Code Reference
### ⚠️ **Deployment Quick Checklist**
1. npm run build
2. npm run test  
3. npm run deploy
4. Check app status

**Triggers**: deployment docs need updating, build process broken" > CLAUDE.md

# 3. Test auto-activation
# Just say: "deployment docs need updating" in next conversation
```

### Step 4: CLAUDE.md Template

```markdown
# [Project Name] - Claude Code Reference

## Quick Reference for Claude Code

### Project Structure
- **Binaries**: `./dist/[app-name]`
- **Scripts**: `./scripts/[build-scripts]`
- **Config**: `~/.config/[app-name]/config.json`

### ⚠️ **[Domain] Quick Checklist**

**After [domain] changes - ALWAYS follow this sequence:**
```bash
1. ./scripts/build.sh                    # Build first
2. ./test-[domain]                       # Test locally
3. [deployment-command]                  # Deploy if needed  
4. [verification-step]                   # Verify success
```

**⚠️ Common Mistakes I Make:**
- ❌ [Common mistake 1]
- ❌ [Common mistake 2]
- ❌ [Common mistake 3]

📋 **Full [domain] process:** See `docs/DEVELOPMENT.md`

### 🤖 **Auto-Documentation System**

**Auto-Activation Triggers:**
```yaml
Primary Triggers:
  - "[domain] docs need updating"
  - "documentation maintenance needed"
  - "add this to troubleshooting guide"
  - "[domain] process broken"

Technical Triggers:
  - "[technology] issue"
  - "wrong [config] in [location]"
  - "[error-pattern]"
```

**Manual Commands:**
```bash
/task "Review and update [domain] documentation consistency" --agent document-reviewer
/task "Add [issue] to [domain] troubleshooting" --agent document-reviewer  
/task "Sync [project] docs between CLAUDE.md and DEVELOPMENT.md" --agent document-reviewer
```
```

### Step 3: DEVELOPMENT.md Template

```markdown
# [Project Name] Development Guide

## [Domain] Workflow

### Development Workflow

#### 1. After Making [Domain] Changes

Always follow this exact sequence:

```bash
# Step 1: Build/prepare
./scripts/build.sh

# Step 2: Test locally  
[test-command]

# Step 3: Deploy/apply
[deployment-command]

# Step 4: Verify
[verification-command]
```

### Common [Domain] Issues

#### Issue 1: [Problem Name]
**Symptom**: [What user sees]
**Cause**: [Root cause]
**Solution**: [Step-by-step fix]

### Documentation Maintenance System

#### Auto-Triggered Updates

**Triggers:** [List project-specific trigger phrases]

#### Manual Commands

[List project-specific documentation commands]

#### Adding New Issues

When encountering new [domain] issues:
1. Document symptoms, cause, solution
2. Use trigger phrase: "add this to troubleshooting guide"
3. Provide error messages and context
4. Test the documented solution
```

### Step 4: Project-Specific Customization

#### For Web Applications
```yaml
domains: [deployment, database, api, authentication, frontend]
common_issues: [cors, database_migration, env_config, build_failures]
trigger_examples:
  - "deployment pipeline broken"  
  - "database migration issue"
  - "API authentication failing"
```

#### For Mobile Applications  
```yaml
domains: [build, signing, store_submission, device_testing]
common_issues: [signing_certificates, provisioning_profiles, store_rejection]
trigger_examples:
  - "iOS build failing"
  - "Android signing issue" 
  - "store submission problem"
```

#### For Desktop Applications
```yaml
domains: [packaging, distribution, auto_updates, permissions]  
common_issues: [code_signing, installer_creation, permission_escalation]
trigger_examples:
  - "code signing failed"
  - "installer broken"
  - "permission denied issue"
```

## Usage Patterns

### During Development
```bash
# When encountering issues, use natural trigger phrases:
"The deployment process is broken again"
"Add this database migration issue to troubleshooting guide" 
"Documentation maintenance needed for the new authentication flow"
```

### Periodic Maintenance
```bash
# Monthly or after major changes:
/task "Review and update [project] documentation consistency" --agent document-reviewer
```

### Adding New Domains
```bash
# When expanding to new areas:
/task "Create documentation framework for [new-domain]" --agent document-reviewer
```

## Benefits

### For Individual Projects
- **Prevents Recurring Issues**: Same mistakes don't happen twice
- **Reduces Context Switching**: Quick reference prevents deep-dive research  
- **Maintains Currency**: Documentation stays aligned with actual processes
- **Improves Handoff**: Comprehensive guides for team members

### For Multiple Projects
- **Consistent Structure**: Same documentation pattern across projects
- **Transferable Knowledge**: Common troubleshooting patterns apply
- **Reduced Setup Time**: Template-based rapid documentation setup
- **Cross-Project Learning**: Issues in one project inform others

## Customization Examples

### For MacAppPositioner (Current Implementation)
```yaml
domains: [gui_deployment, coordinate_system, profile_management]
technologies: [NSScreen, Cocoa, Swift, Xcode]
common_patterns: [build_gui, test_coordinates, apply_profile]
```

### For Web API Project
```yaml  
domains: [deployment, database, authentication, monitoring]
technologies: [Docker, PostgreSQL, JWT, Prometheus]
common_patterns: [migrate_db, deploy_api, test_endpoints]
```

### For React Native App
```yaml
domains: [ios_build, android_build, store_submission, testing]
technologies: [Xcode, Gradle, TestFlight, Play_Console] 
common_patterns: [build_ios, sign_android, submit_store]
```

## Evolution and Learning

### Feedback Loop
1. **Issue Occurs** → Trigger phrase used → Documentation updated
2. **Pattern Recognition** → Similar issues across projects → Framework improvement  
3. **Template Refinement** → Better trigger patterns → Easier implementation

### Framework Improvements
- **New Trigger Patterns**: Learn from common issues across projects
- **Better Templates**: Refine based on what works well
- **Domain Extensions**: Add new domains as they emerge
- **Tool Integration**: Enhance with project-specific tooling

## Implementation Checklist

- [ ] Create two-tier documentation structure
- [ ] Define project-specific domains and trigger patterns  
- [ ] Customize CLAUDE.md with project commands and mistakes
- [ ] Set up DEVELOPMENT.md with comprehensive workflows
- [ ] Test auto-activation with sample trigger phrases
- [ ] Document project-specific troubleshooting patterns
- [ ] Establish cross-references between documentation tiers
- [ ] Create periodic review process for documentation maintenance

## Success Metrics

- **Reduced repeat issues**: Same problems don't recur
- **Faster problem resolution**: Issues resolve quicker with better docs  
- **Improved onboarding**: New developers get up to speed faster
- **Documentation currency**: Docs stay aligned with actual processes
- **Knowledge retention**: Project knowledge persists across team changes

---

*This framework scales from single-developer projects to enterprise applications, adapting to any domain or technology stack.*