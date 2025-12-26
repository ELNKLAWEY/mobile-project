# E-Commerce Mobile Application Documentation

## Project Overview

This is a comprehensive e-commerce mobile application built with Flutter, providing a complete shopping experience with features including product browsing, cart management, wishlist, order tracking, and user authentication. The application follows clean architecture principles and integrates with a custom backend API and admin dashboard.

### Demo Video

Watch the application demo:

<iframe width="560" height="315" src="https://www.youtube.com/embed/31HGsFuumOs?si=G0Bahj61bGAuiUGm" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>

## Team Members

- **Mohamed Osama Mohamed** - ID: 2305180
- **Mostafa Ali Mostafa** - ID: 2305616
- **Omar Abdel Aal Saad** - ID: 2305165

## Technology Stack

### Frontend (Mobile Application)
- **Framework**: Flutter 3.10.4+
- **Language**: Dart
- **State Management**: Riverpod 2.4.9
- **Routing**: GoRouter 13.0.1
- **HTTP Client**: Dio 5.4.0
- **Authentication**: Firebase Auth 4.16.0, Google Sign-In 6.2.1
- **Local Storage**: Shared Preferences 2.2.2
- **UI Libraries**: Google Fonts 6.1.0, Font Awesome Flutter 10.7.0
- **Additional Features**: Speech to Text 7.0.0

### Backend & Dashboard
- **Custom Admin Dashboard**: React, PHP, SQL
- **Dashboard URL**: https://mobile-dash.mohamed-osama.cloud/
- **API Base URL**: https://api.mohamed-osama.cloud/api/v1

## Architecture

The application follows **Clean Architecture** principles with clear separation of concerns:

```
lib/
├── core/                    # Core functionality shared across features
│   ├── network/            # API client, endpoints, token storage
│   ├── router/             # Navigation and routing configuration
│   ├── theme/              # App theming (light/dark mode)
│   └── widgets/            # Reusable UI components
│
└── features/                # Feature modules (each follows clean architecture)
    ├── auth/               # Authentication feature
    │   ├── data/          # Data layer (models, repositories implementation)
    │   ├── domain/        # Domain layer (repositories interfaces)
    │   └── presentation/  # Presentation layer (screens, providers)
    ├── cart/              # Shopping cart feature
    ├── home/              # Home screen and product browsing
    ├── product/           # Product details
    └── wishlist/          # Wishlist/favorites feature
```

### Architecture Layers

1. **Presentation Layer**: UI components, screens, and state management (Riverpod providers)
2. **Domain Layer**: Business logic interfaces and entities
3. **Data Layer**: API integration, data models, and repository implementations

## Features

### 1. Authentication
- User registration with email, password, name, and phone
- User login with email and password
- Google Sign-In integration
- Password reset via OTP (One-Time Password)
  - Phone number verification
  - OTP verification
  - Password change
- Secure token-based authentication
- Persistent session management

### 2. Home & Product Browsing
- Home screen with featured content
- Product listings with pagination
- Brand browsing and filtering
- New arrivals section
- Product search functionality
- Brand-specific product filtering
- Product details view

### 3. Shopping Cart
- Add/remove products from cart
- Update product quantities
- Cart persistence
- Checkout process
- Order placement

### 4. Wishlist
- Add/remove products to/from wishlist
- View saved favorites
- Wishlist persistence

### 5. Orders
- View order history
- Order details and tracking
- Order status management

### 6. User Interface
- Modern and responsive UI design
- Dark mode support
- Custom app drawer with user profile
- Bottom navigation bar
- Material Design components
- Custom theming with Google Fonts

## API Integration

### Base Configuration
- **Base URL**: `https://api.mohamed-osama.cloud/api/v1`
- **Authentication**: Bearer token in Authorization header
- **Content-Type**: `application/json`

### API Endpoints

#### Authentication
- `POST /auth/login` - User login
- `POST /auth/register` - User registration
- `POST /auth/logout` - User logout
- `GET /auth/me` - Get current user information
- `POST /auth/google` - Google Sign-In
- `POST /auth/reset-password/check-phone` - Check phone and send OTP
- `POST /auth/reset-password/verify-otp` - Verify OTP
- `POST /auth/reset-password/change` - Reset password

#### Products
- `GET /products` - Get products list (with pagination and filters)
- `GET /products/:id` - Get product details

#### Brands
- `GET /brands` - Get all brands

#### Cart
- `GET /cart` - Get user's cart
- `POST /cart` - Add item to cart
- `PUT /cart/:id` - Update cart item
- `DELETE /cart/:id` - Remove item from cart

#### Orders
- `GET /orders` - Get user's orders
- `POST /orders` - Create new order

#### Favorites/Wishlist
- `GET /favorites` - Get user's wishlist
- `POST /favorites` - Add to wishlist
- `DELETE /favorites/:id` - Remove from wishlist

### API Client Features
- Automatic token injection in request headers
- Request/response logging
- Error handling and interceptors
- Token storage and management
- Timeout configuration (10 seconds)

## Admin Dashboard

The application is integrated with a custom admin dashboard built with:
- **Frontend**: React
- **Backend**: PHP
- **Database**: SQL

**Dashboard URL**: https://mobile-dash.mohamed-osama.cloud/

The dashboard allows administrators to:
- Manage products, brands, and categories
- View and manage orders
- Manage users
- Monitor application statistics
- Configure application settings

## Project Structure

```
my_flutter_app/
├── android/                 # Android platform configuration
├── ios/                     # iOS platform configuration
├── lib/                     # Main application code
│   ├── core/               # Core functionality
│   │   ├── network/        # API client, endpoints, token storage
│   │   ├── router/         # Navigation configuration
│   │   ├── theme/          # App theming
│   │   └── widgets/        # Reusable widgets
│   └── features/           # Feature modules
│       ├── auth/           # Authentication
│       ├── cart/           # Shopping cart
│       ├── home/           # Home and browsing
│       ├── product/        # Product details
│       └── wishlist/       # Wishlist
├── test/                   # Unit and widget tests
├── pubspec.yaml            # Dependencies and project configuration
└── README.md               # Project readme
```

## Key Dependencies

### Core Dependencies
```yaml
flutter_riverpod: ^2.4.9      # State management
go_router: ^13.0.1           # Navigation and routing
dio: ^5.4.0                  # HTTP client
shared_preferences: ^2.2.2   # Local storage
```

### UI Dependencies
```yaml
google_fonts: ^6.1.0         # Custom fonts
font_awesome_flutter: ^10.7.0 # Icon library
cupertino_icons: ^1.0.8      # iOS-style icons
```

### Authentication
```yaml
firebase_core: ^2.24.2       # Firebase core
firebase_auth: ^4.16.0       # Firebase authentication
google_sign_in: ^6.2.1       # Google Sign-In
```

### Utilities
```yaml
json_annotation: ^4.8.1      # JSON serialization
intl: ^0.20.2                # Internationalization
speech_to_text: ^7.0.0       # Speech recognition
```

### Development Dependencies
```yaml
build_runner: ^2.4.8         # Code generation
json_serializable: ^6.7.1    # JSON code generation
flutter_lints: ^6.0.0        # Linting rules
```

## Navigation Structure

The application uses GoRouter for navigation with the following routes:

### Authentication Routes
- `/` - Splash screen
- `/auth-choice` - Authentication choice screen
- `/login` - Login screen
- `/register` - Registration screen
- `/forgot-password` - Password reset screen

### Main Routes (Bottom Navigation)
- `/home` - Home screen
- `/wishlist` - Wishlist screen
- `/cart` - Shopping cart screen
- `/orders` - Orders screen

### Additional Routes
- `/search` - Search screen
- `/product-details` - Product details screen
- `/all-brands` - All brands screen
- `/all-new-arrivals` - New arrivals screen
- `/brand-products` - Brand products screen
- `/checkout` - Checkout screen
- `/order-success` - Order success screen

## State Management

The application uses **Riverpod** for state management:

- **AuthProvider**: Manages user authentication state
- **CartProvider**: Manages shopping cart state
- **WishlistProvider**: Manages wishlist state
- **OrderProvider**: Manages order state
- **HomeProviders**: Manages home screen data (brands, new arrivals)
- **BrandProvider**: Manages brand-related state
- **ThemeProvider**: Manages dark/light theme state

## Theme & Styling

- **Light Theme**: Default Material Design light theme
- **Dark Theme**: Custom dark theme with appropriate color schemes
- **Custom Colors**: Defined in `app_colors.dart`
- **Typography**: Google Fonts (Inter font family)
- **Theme Toggle**: Available in app drawer

## Security Features

1. **Token-Based Authentication**: JWT tokens stored securely
2. **Secure Storage**: Tokens stored using SharedPreferences
3. **HTTPS**: All API calls use HTTPS
4. **Input Validation**: Client-side validation for forms
5. **OTP Verification**: Secure password reset flow

## Getting Started

### Prerequisites
- Flutter SDK 3.10.4 or higher
- Dart SDK
- Android Studio / Xcode (for mobile development)
- Git

### Installation Steps

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd my_flutter_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run code generation** (if needed)
   ```bash
   flutter pub run build_runner build
   ```

4. **Configure Firebase** (if using Firebase features)
   - Add `google-services.json` for Android
   - Add `GoogleService-Info.plist` for iOS

5. **Run the application**
   ```bash
   flutter run
   ```

### Build for Production

**Android:**
```bash
flutter build apk --release
# or
flutter build appbundle --release
```

**iOS:**
```bash
flutter build ios --release
```

## Download APK for Testing

You can download the latest release APK for testing directly from Google Drive:

**[Download APK (app-release.apk)](https://drive.google.com/drive/folders/1V7XMwrQ4AHDUQiAC6d7WbuVGtDu9ylUT?usp=sharing)**

**Note**: The APK file is approximately 50.5 MB. Make sure to enable "Install from Unknown Sources" on your Android device before installing the APK.

## Development Guidelines

### Code Organization
- Follow clean architecture principles
- Keep features modular and independent
- Use dependency injection with Riverpod
- Implement repository pattern for data access

### Naming Conventions
- Use descriptive names for classes, functions, and variables
- Follow Dart naming conventions (camelCase for variables, PascalCase for classes)
- Use meaningful file and folder names

### State Management
- Use Riverpod providers for state management
- Keep providers focused and single-responsibility
- Use AsyncValue for async operations

### API Integration
- All API calls should go through ApiClient
- Use repository pattern for data access
- Handle errors appropriately
- Implement proper loading states

## Testing

The project includes a test directory for unit and widget tests. Run tests using:
```bash
flutter test
```

## Future Enhancements

Potential improvements and features:
- Push notifications
- Payment gateway integration
- Product reviews and ratings
- Social sharing
- Advanced search filters
- Product recommendations
- Multi-language support
- Offline mode support

## Support & Contact

For issues, questions, or contributions, please contact the development team:
- Mohamed Osama Mohamed (2305180)
- Mostafa Ali Mostafa (2305616)
- Omar Abdel Aal Saad (2305165)

## License

This project is developed for educational/academic purposes.

---

**Last Updated**: 2024
**Version**: 1.0.0+1

