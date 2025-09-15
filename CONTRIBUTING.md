# Contributing to Room-O-Matic Mobile 🚀

First off, thank you for considering contributing to Room-O-Matic Mobile! This project is a security-first Flutter mobile application for room measurement and spatial data collection using native sensors, and community contributions are essential to achieving that goal.

## 🎯 How You Can Contribute

### 🐛 Report Bugs & Issues
- Use GitHub issues to report bugs
- Include detailed reproduction steps
- Specify your environment (OS, VS Code version, extensions)
- Check existing issues before creating new ones

### 💡 Suggest Features & Enhancements
- Open a GitHub issue with the "enhancement" label
- Describe the use case and expected behavior
- Explain how it improves room measurement capabilities or user experience
- Consider mobile platform compatibility (iOS/Android)

### 📚 Improve Documentation
- Fix typos, grammar, or unclear instructions
- Add examples and use cases
- Improve setup guides and troubleshooting
- Update AI instruction patterns

### 🔧 Submit Code Changes
- Bug fixes and performance improvements
- New sensor integration patterns
- Mobile platform optimizations (iOS/Android)
- Enhanced security implementations
- Flutter widget and platform channel improvements

## 🚀 Getting Started

### Development Setup

1. **Fork and Clone**
   ```bash
   git clone https://github.com/sosh-ncampbell/room-o-matic-mobile.git
   cd room-o-matic-mobile
   ```

2. **Setup Development Environment**
   ```bash
   # Verify Flutter installation
   flutter doctor

   # Run the setup script
   ./scripts/quick-install.sh

   # Or manual setup
   chmod +x scripts/*.sh
   flutter pub get
   ```

3. **Create Feature Branch**
   ```bash
   git checkout -b feature/your-feature-name
   # or
   git checkout -b fix/issue-description
   ```

### Development Guidelines

#### Code Style & Standards
- Follow existing code formatting and style
- Use meaningful commit messages (see [📝 Commit Guidelines](#-commit-guidelines))
- Test your changes thoroughly
- Update documentation as needed

#### Flutter/Mobile Development Contributions
When contributing to Flutter code or mobile platform integration:
- Follow Dart/Flutter conventions (camelCase, PascalCase)
- Include platform channel implementations for both iOS and Android
- Test with real devices and various sensor configurations
- Ensure security-first patterns (biometric auth, encrypted storage)
- Follow Clean Architecture + DDD patterns

#### VS Code Configuration Changes
- Test with multiple VS Code versions
- Consider impact on performance and user experience
- Document new settings and their purposes
- Ensure compatibility with different project types

## 📝 Commit Guidelines

We follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

```
type(scope): description

[optional body]

[optional footer]
```

### Commit Types
- **feat**: New feature or enhancement
- **fix**: Bug fix
- **docs**: Documentation changes
- **style**: Code style/formatting (no functional changes)
- **refactor**: Code refactoring
- **test**: Adding or updating tests
- **chore**: Maintenance tasks, build changes

### Examples
```
feat(sensors): add LiDAR integration for iOS platform

fix(auth): resolve biometric authentication on Android 12+

docs(setup): update Flutter development environment guide

style(dart): fix formatting in sensor service classes

refactor(platform-channels): improve error handling in native modules

test(integration): add platform channel communication tests

chore(deps): update Flutter and platform dependencies
```

## 🔍 Pull Request Process

### Before Submitting
1. **Test Your Changes**
   - Test on both iOS and Android devices
   - Verify sensor integration with real hardware
   - Test in various room environments and lighting conditions
   - Validate security implementations (biometric auth, encryption)
   - Run Flutter widget and integration tests

2. **Update Documentation**
   - Update README.md if needed
   - Add/update relevant documentation
   - Include examples for new features

3. **Check Quality**
   - Run any available linters
   - Fix markdown formatting issues
   - Ensure scripts are executable and tested

### Pull Request Template

When creating a pull request, please include:

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Refactoring
- [ ] Other (please describe)

## Testing
- [ ] Tested on iOS devices (physical and simulator)
- [ ] Tested on Android devices (physical and emulator)
- [ ] Sensor integration validated with real hardware
- [ ] Security features tested (biometric auth, encryption)
- [ ] Flutter tests passing (unit, widget, integration)

## Checklist
- [ ] Code follows project style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] No breaking changes (or documented)
```

### Review Process
1. **Automated Checks**: All CI/CD checks must pass
2. **Maintainer Review**: At least one maintainer approval required
3. **Community Feedback**: Community input is welcomed and valued
4. **Final Testing**: Additional testing may be requested

## 🎨 Design Principles

When contributing, please keep these principles in mind:

### 📱 Mobile-First Development
- Optimize for mobile performance and battery life
- Prioritize security in all sensor data handling
- Follow platform-specific design guidelines (iOS/Android)
- Consider device capabilities and graceful degradation

### 🚀 Universal Compatibility
- Support multiple programming languages
- Work across different project types and sizes
- Maintain backward compatibility when possible
- Consider different development environments

### 🔒 Security by Design
- Security should be the default
- Include security patterns and examples
- Validate all AI-generated security code
- Follow industry best practices

### ⚡ Performance Focused
- Optimize VS Code performance
- Minimize resource usage
- Efficient task and workflow design
- Fast setup and initialization

## 🏷️ Issue Labels

We use the following labels to categorize issues and PRs:

- **bug**: Something isn't working
- **enhancement**: New feature or improvement
- **documentation**: Documentation related
- **good first issue**: Good for newcomers
- **help wanted**: Extra attention needed
- **platform-ios**: iOS-specific implementations
- **platform-android**: Android-specific implementations
- **sensors**: Sensor integration improvements
- **security**: Security and privacy enhancements
- **security**: Security-related changes
- **performance**: Performance improvements

## 🌟 Recognition

Contributors are recognized in several ways:

### Hall of Fame
Significant contributors are featured in our [CONTRIBUTORS.md](./CONTRIBUTORS.md) file.

### Release Notes
Contributors are credited in release notes and changelog entries.

### Badges & Achievements
- First-time contributor badge
- Language specialist badges
- Security contributor recognition
- Documentation contributor badges

## 💬 Community & Communication

### GitHub Discussions
- **Ideas & Feature Requests**: Discuss new concepts
- **Q&A**: Get help and provide assistance
- **Show & Tell**: Share your implementations
- **General**: Open discussion about the project

### Code of Conduct
We are committed to providing a welcoming and inspiring community for all. Please read and follow our [Code of Conduct](CODE_OF_CONDUCT.md).

## 📊 Project Roadmap

### Current Focus Areas
- Platform channel implementation (iOS/Android)
- Sensor fusion and data processing
- Security infrastructure (biometric auth, encryption)
- Real-time room scanning and measurement

### Future Goals
- Advanced sensor fusion algorithms
- Cloud backup and synchronization
- Enterprise room data management
- Machine learning for measurement accuracy

## 🆘 Getting Help

Need help contributing? Here are your options:

1. **GitHub Discussions**: Best for open questions and ideas
2. **GitHub Issues**: For specific bugs or feature requests
3. **Documentation**: Check existing docs and examples
4. **Community**: Connect with other contributors

## 🏆 Maintainers

This project is maintained by:
- [List of maintainers with GitHub usernames]

## 📄 License

By contributing to this project, you agree that your contributions will be licensed under the [MIT License](LICENSE).

---

**Thank you for helping make Room-O-Matic Mobile even better!** 🚀

Every contribution, no matter how small, helps create a more accurate, secure, and user-friendly room measurement application.
