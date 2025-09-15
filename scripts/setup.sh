#!/bin/bash

# 🚀 Room-O-Matic Mobile Flutter Setup Script
# Complete development environment initialization for Phase 1

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Emojis for better UX
ROCKET="🚀"
CHECK="✅"
WARNING="⚠️"
INFO="ℹ️"
GEAR="⚙️"
STAR="⭐"

echo -e "${CYAN}${ROCKET} Room-O-Matic Mobile Flutter Setup${NC}"
echo -e "${CYAN}=====================================${NC}"
echo ""

# Function to print colored output
print_step() {
    echo -e "${BLUE}${GEAR} $1${NC}"
}

print_success() {
    echo -e "${GREEN}${CHECK} $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}${WARNING} $1${NC}"
}

print_info() {
    echo -e "${CYAN}${INFO} $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if we're in the right directory
if [[ ! -f "pubspec.yaml" ]]; then
    print_error "This doesn't appear to be a Flutter project directory!"
    print_info "Please run this script from the root of the Room-O-Matic Mobile project."
    exit 1
fi

# Step 1: Check Flutter Environment
print_step "Checking Flutter environment..."

check_command() {
    if command -v "$1" &> /dev/null; then
        print_success "$1 is installed"
        return 0
    else
        print_warning "$1 is not installed"
        return 1
    fi
}

# Essential tools
MISSING_TOOLS=0

if ! check_command "flutter"; then
    print_error "Flutter is required but not installed. Please install Flutter first."
    ((MISSING_TOOLS++))
fi

if ! check_command "dart"; then
    print_warning "Dart CLI not found. Using Flutter's bundled Dart."
fi

if [[ $MISSING_TOOLS -gt 0 ]]; then
    print_error "Please install missing essential tools before continuing."
    exit 1
fi

# Step 2: Flutter Doctor Check
print_step "Running Flutter doctor..."
flutter doctor

# Step 3: Install/Update Dependencies
print_step "Installing Flutter dependencies..."
flutter pub get

print_success "Flutter dependencies installed"

# Step 4: Code Generation Setup
print_step "Setting up code generation..."

# Install build_runner if not present
flutter pub add --dev build_runner
flutter pub add --dev freezed
flutter pub add --dev json_annotation
flutter pub add --dev json_serializable
flutter pub add --dev riverpod_generator
flutter pub add --dev riverpod_annotation

print_success "Code generation dependencies configured"

# Step 5: Run Initial Code Generation
print_step "Running initial code generation..."
flutter packages pub run build_runner build --delete-conflicting-outputs

print_success "Code generation completed"

# Step 6: Testing Framework Setup
print_step "Setting up testing framework..."

# Install testing dependencies
flutter pub add --dev mockito
flutter pub add --dev golden_toolkit
flutter pub add --dev integration_test

print_success "Testing framework configured"

# Step 7: Additional Dependencies
print_step "Installing additional dependencies..."

# Core dependencies for Room-O-Matic
flutter pub add riverpod_annotation
flutter pub add flutter_riverpod
flutter pub add go_router
flutter pub add freezed_annotation
flutter pub add json_annotation

# Platform dependencies
flutter pub add permission_handler
flutter pub add camera
flutter pub add geolocator
flutter pub add sensors_plus
flutter pub add flutter_sound
flutter pub add path_provider
flutter pub add shared_preferences
flutter pub add flutter_secure_storage
flutter pub add connectivity_plus
flutter pub add share_plus

# Security dependencies
flutter pub add local_auth
flutter pub add crypto
flutter pub add encrypt

# Additional UI dependencies
flutter pub add intl

print_success "Additional dependencies installed"

# Step 8: Platform Channel Setup Validation
print_step "Validating platform channel setup..."

# Check iOS setup
if [[ -d "ios" ]]; then
    print_info "iOS platform detected"
    if [[ -f "ios/Podfile" ]]; then
        print_success "iOS Podfile exists"
    else
        print_warning "iOS Podfile missing - platform channels may not work"
    fi
else
    print_warning "iOS platform not found"
fi

# Check Android setup
if [[ -d "android" ]]; then
    print_info "Android platform detected"
    if [[ -f "android/app/build.gradle" ]]; then
        print_success "Android build.gradle exists"
    else
        print_warning "Android build.gradle missing"
    fi
else
    print_warning "Android platform not found"
fi

# Step 9: Development Environment Validation
print_step "Validating development environment..."

# Check for required directories and files
REQUIRED_DIRS=(
    "lib/domain"
    "lib/application"
    "lib/infrastructure"
    "lib/interface"
    "test"
    "docs"
)

for dir in "${REQUIRED_DIRS[@]}"; do
    if [[ -d "$dir" ]]; then
        print_success "$dir directory exists"
    else
        print_warning "$dir directory missing"
        mkdir -p "$dir"
        print_info "Created $dir directory"
    fi
done

# Check key files
REQUIRED_FILES=(
    "lib/main.dart"
    "pubspec.yaml"
    "analysis_options.yaml"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [[ -f "$file" ]]; then
        print_success "$file exists"
    else
        print_warning "$file is missing"
    fi
done

# Step 10: Analysis Configuration
print_step "Setting up code analysis..."

if [[ ! -f "analysis_options.yaml" ]]; then
    print_step "Creating analysis_options.yaml..."
    cat > analysis_options.yaml << 'EOF'
include: package:very_good_analysis/analysis_options.yaml

analyzer:
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
    - "build/**"
    - "coverage/**"
  strong-mode:
    implicit-casts: false
    implicit-dynamic: false

linter:
  rules:
    # Room-O-Matic specific rules
    prefer_const_constructors: true
    prefer_const_declarations: true
    prefer_const_literals_to_create_immutables: true
    prefer_final_fields: true
    prefer_final_locals: true
    prefer_single_quotes: true

    # Security-focused rules
    avoid_print: true
    avoid_web_libraries_in_flutter: true

    # Performance rules
    avoid_unnecessary_containers: true
    sized_box_for_whitespace: true
    use_key_in_widget_constructors: true
EOF
    print_success "analysis_options.yaml created"
fi

# Step 11: VS Code Configuration
print_step "Configuring VS Code for Flutter development..."

# Ensure .vscode directory exists
mkdir -p .vscode

# Check if VS Code settings are properly configured for Flutter
if [[ -f ".vscode/settings.json" ]]; then
    print_success "VS Code settings.json exists"
else
    print_info "VS Code settings.json will be created by main setup"
fi

# Step 12: Git Hooks for Flutter
print_step "Setting up Flutter-specific Git hooks..."

if [[ -d ".git" ]]; then
    mkdir -p .git/hooks

    # Pre-commit hook for Flutter
    cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
# Flutter-specific pre-commit hook

echo "🔍 Running Flutter pre-commit checks..."

# Flutter analyze
if ! flutter analyze; then
    echo "❌ Flutter analyze failed!"
    exit 1
fi

# Dart format check
if ! dart format --set-exit-if-changed .; then
    echo "⚠️  Code formatting issues found. Run 'dart format .' to fix."
    exit 1
fi

# Check for TODO/FIXME comments
if git diff --cached --name-only | xargs grep -l "TODO\|FIXME\|XXX" 2>/dev/null; then
    echo "⚠️  Found TODO/FIXME comments. Consider resolving before commit."
fi

echo "✅ Flutter pre-commit checks passed"
EOF

    chmod +x .git/hooks/pre-commit
    print_success "Flutter Git hooks configured"
else
    print_info "Git repository not initialized - skipping Git hooks"
fi

# Step 13: Final Validation
print_step "Performing final validation..."

# Test that Flutter can build
print_step "Testing Flutter build..."
if flutter build apk --debug --quiet; then
    print_success "Flutter debug build successful"
else
    print_warning "Flutter debug build failed - check Flutter doctor output"
fi

# Test code generation
print_step "Testing code generation..."
if flutter packages pub run build_runner build --delete-conflicting-outputs; then
    print_success "Code generation successful"
else
    print_warning "Code generation failed - check dependencies"
fi

# Success summary
echo ""
echo -e "${GREEN}${STAR}${STAR}${STAR} FLUTTER SETUP COMPLETE! ${STAR}${STAR}${STAR}${NC}"
echo -e "${CYAN}===========================================${NC}"
echo ""
echo -e "${ROCKET} ${YELLOW}Room-O-Matic Mobile development environment is ready!${NC}"
echo ""
echo -e "${INFO} ${BLUE}Next steps:${NC}"
echo -e "  1. ${CYAN}flutter run${NC} - Start development server"
echo -e "  2. ${CYAN}flutter test${NC} - Run tests"
echo -e "  3. ${CYAN}flutter packages pub run build_runner watch${NC} - Watch for code generation"
echo -e "  4. ${CYAN}flutter analyze${NC} - Check code quality"
echo ""
echo -e "${INFO} ${PURPLE}Available commands:${NC}"
echo -e "  • ${CYAN}flutter doctor${NC} - Check development environment"
echo -e "  • ${CYAN}flutter pub get${NC} - Update dependencies"
echo -e "  • ${CYAN}flutter clean${NC} - Clean build artifacts"
echo -e "  • ${CYAN}flutter pub outdated${NC} - Check for dependency updates"
echo ""
echo -e "${ROCKET} ${GREEN}Happy Flutter development with Room-O-Matic Mobile!${NC}"
echo ""

print_success "Setup completed successfully!"
exit 0
