---
description: Repository Information Overview
alwaysApply: true
---

# MuzaksFood Repository Information

## Repository Summary
MuzaksFood is a multi-project food delivery platform featuring a Laravel backend API, Flutter mobile applications for delivery personnel and customers, and an AI module for enhanced functionality. The system supports multiple payment gateways (Paystack, Stripe, PayPal, Razorpay, Flutterwave, Xendit, MercadoPago), Firebase integration for messaging, and location-based delivery services.

## Repository Structure
- **Root**: Laravel backend API (PHP/MySQL)
- **muzaksfood-delivery-app/**: Flutter mobile app for delivery personnel
- **muzaksfood-user-app/**: Flutter mobile app for customer/user interface
- **Modules/**: Modular Laravel extensions (AI module, etc.)
- **app/**: Laravel application core (models, controllers, services)
- **resources/**: Frontend assets (JavaScript, SCSS)
- **database/**: Migrations, seeders, factories
- **routes/**: API and web routes (admin, branch, web, install, update)
- **public/**: Static assets and compiled files
- **tests/**: Unit and feature tests

### Main Repository Components
- **Laravel Backend API**: Core application for order management, payment processing, admin panel
- **Delivery App**: Flutter-based app for delivery driver operations with real-time location tracking
- **User App**: Flutter-based customer interface with Firebase auth, shopping features
- **AI Module**: Laravel module for AI-powered features using OpenAI integration
- **Database**: MySQL with 122+ migrations covering orders, products, users, payments, communications

## Projects

### Laravel Backend API
**Configuration File**: `composer.json`, `.env.example`

#### Language & Runtime
**Language**: PHP  
**Version**: ^8.2  
**Framework**: Laravel 12.0  
**Package Manager**: Composer  
**Build System**: Laravel Mix (Webpack) + Node.js

#### Dependencies
**Main Dependencies**:
- laravel/framework (^12.0)
- laravel/passport (^12.0) - OAuth2 authentication
- kreait/firebase-php (^7.15) & laravel-firebase (^6.0) - Firebase integration
- openai-php/laravel (^0.17.1) - AI/OpenAI integration
- stripe/stripe-php (^13.0), razorpay/razorpay (^2.9), paypal/rest-api-sdk-php (^1.6) - Payment gateways
- xendit/xendit-php (^3.0), mercadopago/dx-php (2.4.4) - Additional payment providers
- guzzlehttp/guzzle (^7.9) - HTTP client
- intervention/image (^3.7) - Image manipulation
- maatwebsite/excel (^3.1) - Excel export
- nwidart/laravel-modules - Modular application structure
- barryvdh/laravel-debugbar, laravel-dompdf - Development & PDF generation

**Development Dependencies**:
- phpunit/phpunit (^11.0) - Testing framework
- mockery/mockery (^1.6) - Mocking library
- fakerphp/faker (^1.23) - Fake data generation

#### Build & Installation
```bash
composer install
npm install
php artisan key:generate
php artisan migrate
npm run dev
npm run production
```

#### Testing
**Framework**: PHPUnit 11.0  
**Test Location**: `tests/` directory (Unit and Feature tests)  
**Naming Convention**: `*Test.php` suffix  
**Configuration**: `phpunit.xml`

**Run Commands**:
```bash
php artisan test
vendor/bin/phpunit
```

#### Entry Points
- **Web**: `routes/web.php` (admin panel, installation routes)
- **API**: `routes/admin.php`, `routes/branch.php` (REST endpoints)
- **Artisan**: `artisan` (CLI commands)
- **Public**: `public/index.php` (HTTP entry point)

#### Database
**Type**: MySQL  
**Migrations**: 122+ migration files in `database/migrations/`  
**Key Tables**: Orders, Products, Users, Admins, Transactions, Time Slots, Conversations, Messages, Favorite Products, Admin Roles

### Delivery App (Flutter)
**Configuration File**: `muzaksfood-delivery-app/pubspec.yaml`

#### Language & Runtime
**Language**: Dart/Flutter  
**SDK Version**: ^3.8.1  
**Package Manager**: Pub (Flutter package manager)

#### Key Dependencies
- firebase_core (^4.2.0), firebase_messaging (^16.0.3) - Push notifications
- google_maps_flutter (^2.13.1), geolocator (^14.0.2), geocoding (^4.0.0) - Location services
- provider (^6.1.5+1), get_it (^8.2.0) - State management
- dio (^5.9.0) - HTTP client
- shared_preferences (^2.5.3) - Local storage
- flutter_local_notifications (^19.5.0) - Notifications
- image_picker, photo_view, flutter_svg - Media handling
- permission_handler (^12.0.1) - Permissions

#### Build & Installation
```bash
cd muzaksfood-delivery-app
flutter pub get
flutter build apk
flutter build ios
flutter run
```

#### Testing
**Framework**: Flutter Test  
**Location**: `test/` directory  

**Run Command**:
```bash
flutter test
```

### User App (Flutter)
**Configuration File**: `muzaksfood-user-app/pubspec.yaml`

#### Language & Runtime
**Language**: Dart/Flutter  
**SDK Version**: ^3.8.1  
**Package Manager**: Pub (Flutter package manager)

#### Key Dependencies
- firebase_core (4.2.0), firebase_messaging (16.0.3), firebase_auth (^6.1.1) - Firebase services
- google_maps_flutter (^2.13.1), geolocator (^14.0.2) - Location features
- drift (^2.29.0), drift_flutter (^0.2.7) - Local database
- go_router (16.2.4) - Navigation
- provider (^6.1.5+1), get_it (^8.2.0) - State management
- flutter_facebook_auth (^7.1.2), google_sign_in (^7.2.0), sign_in_with_apple (^7.0.1) - Social login
- carousel_slider, flutter_typeahead, expandable_bottom_sheet - UI components
- cached_network_image, image_picker - Media

#### Build & Installation
```bash
cd muzaksfood-user-app
flutter pub get
flutter build apk
flutter build ios
flutter build web
flutter run
```

#### Testing
**Framework**: Flutter Test + Build Runner (Drift code generation)  

**Run Commands**:
```bash
flutter test
flutter pub run build_runner build
```

### AI Module (Laravel Module)
**Configuration Files**: `Modules/AI/composer.json`, `Modules/AI/package.json`, `Modules/AI/vite.config.js`

#### Language & Runtime
**Languages**: PHP, JavaScript (Vite)  
**Package Managers**: Composer, npm  
**Build System**: Vite 4.0.0  

#### Dependencies
**PHP**: Module uses Laravel framework dependencies (inherited)  
**JavaScript**:
- laravel-vite-plugin (^0.7.5) - Vite plugin for Laravel
- axios (^1.1.2) - HTTP requests
- sass (^1.69.5), postcss (^8.3.7) - Styling

#### Build & Installation
```bash
cd Modules/AI
npm install
npm run dev
npm run build
```

#### Entry Points
- Route files: `Modules/AI/routes/web.php`, `Modules/AI/routes/admin/routes.php`
- Assets: `Modules/AI/resources/assets/` (SCSS, JS)
- Build Output: `public/build-ai/`

#### Structure
- Auto-discovery disabled in parent `composer.json`
- PSR-4 autoload: `Modules\AI\` namespace maps to module root
- Builds to `public/build-ai/` directory

## Build & Deployment

### Frontend Asset Compilation
```bash
npm install
npm run dev      # Development with watch
npm run hot      # Hot module replacement
npm run prod     # Production minified build
```

### Laravel Commands
```bash
php artisan migrate              # Run database migrations
php artisan cache:clear         # Clear application cache
php artisan route:cache         # Cache routes for production
php artisan config:cache        # Cache configuration
```

### Environment Configuration
Copy `.env.example` to `.env` and configure:
- Database credentials (MySQL)
- Firebase API keys
- Payment gateway credentials
- OpenAI API key
- Mail/notification settings

## Key Features & Integrations
- **Multi-currency & Multi-payment**: Stripe, PayPal, Razorpay, Xendit, Paystack, MercadoPago
- **Real-time Features**: Firebase messaging, WebSocket support
- **Location Services**: Google Maps integration with geolocation tracking
- **AI Integration**: OpenAI for intelligent features
- **Mobile Apps**: iOS and Android via Flutter with web support
- **Admin Panel**: Web-based Laravel backend
- **Module System**: Extensible architecture via Laravel Modules

## Testing Coverage
- PHPUnit for backend API tests
- Flutter test framework for mobile apps
- Feature and Unit test suites for Laravel
- Database testing with SQLite in-memory setup