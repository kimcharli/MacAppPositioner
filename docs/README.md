# Documentation Index

## 📚 Core Documentation

### Getting Started
- **[TERMINOLOGY.md](TERMINOLOGY.md)** - Key terms and concepts (Primary vs Main, coordinates, profiles)
- **[QUICK_START.md](QUICK_START.md)** - Basic setup and usage guide
- **[CONFIGURATION.md](CONFIGURATION.md)** - Config.json structure and profile setup

### Architecture & Design  
- **[ARCHITECTURE.md](ARCHITECTURE.md)** - System architecture and component design

### Development Guidelines
- **[DEVELOPMENT_RULES.md](DEVELOPMENT_RULES.md)** - 🚨 **MANDATORY** rules for all developers
- **[COORDINATE_SYSTEM_GUIDE.md](COORDINATE_SYSTEM_GUIDE.md)** - 🚨 **CRITICAL** coordinate system architecture and compliance

## ⚠️ CRITICAL NOTICES

### For All Developers
**READ THESE FIRST** - These documents prevent critical bugs:

1. **[DEVELOPMENT_RULES.md](DEVELOPMENT_RULES.md)** - Mandatory development practices
2. **[COORDINATE_SYSTEM_GUIDE.md](COORDINATE_SYSTEM_GUIDE.md)** - Prevent positioning failures and fix issues

### Common Issues Prevention
- **Coordinate System Problems**: Follow canonical coordinate architecture (see COORDINATE_SYSTEM_GUIDE.md)
- **Primary vs Main Confusion**: Review terminology in TERMINOLOGY.md
- **Positioning Failures**: Use debugging procedures in COORDINATE_SYSTEM_GUIDE.md

## 📋 Documentation Standards

### When to Update Documentation
- **Any coordinate-related changes**: Update COORDINATE_SYSTEM_RULES.md
- **New features**: Update ARCHITECTURE.md and relevant guides
- **Bug fixes**: Update DEBUGGING_GUIDE.md with new diagnostic procedures
- **Configuration changes**: Update CONFIGURATION.md

### Documentation Review Requirements
- All coordinate-related changes must be reviewed against DEVELOPMENT_RULES.md
- New features must include architecture compliance documentation
- Bug fixes must include prevention documentation

## 🎯 Quick Reference

### For New Developers
1. Read [TERMINOLOGY.md](TERMINOLOGY.md) - Understand key concepts
2. Read [DEVELOPMENT_RULES.md](DEVELOPMENT_RULES.md) - **MANDATORY** compliance
3. Read [COORDINATE_SYSTEM_RULES.md](COORDINATE_SYSTEM_RULES.md) - **CRITICAL** for positioning
4. Review [ARCHITECTURE.md](ARCHITECTURE.md) - System understanding

### For Debugging Issues
1. Follow [COORDINATE_SYSTEM_GUIDE.md](COORDINATE_SYSTEM_GUIDE.md) diagnostic procedures
2. Check [COORDINATE_SYSTEM_GUIDE.md](COORDINATE_SYSTEM_GUIDE.md) compliance
3. Review [TERMINOLOGY.md](TERMINOLOGY.md) for concept clarification

### For Adding Features
1. Ensure [DEVELOPMENT_RULES.md](DEVELOPMENT_RULES.md) compliance
2. Follow canonical coordinate system architecture
3. Add coordinate system test coverage
4. Update relevant documentation

## 🚨 Emergency Procedures

### If Positioning is Broken
1. Follow emergency fixes in [COORDINATE_SYSTEM_GUIDE.md](COORDINATE_SYSTEM_GUIDE.md)
2. Revert to canonical coordinate system implementation
3. Test coordinate system integrity
4. Check compliance with [COORDINATE_SYSTEM_GUIDE.md](COORDINATE_SYSTEM_GUIDE.md)

### If Unsure About Implementation
1. Review [DEVELOPMENT_RULES.md](DEVELOPMENT_RULES.md) patterns
2. Follow canonical coordinate system architecture examples
3. Ask for architecture review focusing on coordinate system compliance

---

**The coordinate system architecture documentation exists because positioning issues have occurred multiple times. Following these guidelines prevents those issues from recurring.**