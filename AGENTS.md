# Repository Guidelines

## Project Structure & Module Organization
- `app/` holds CodeIgniter 4 application code (controllers, models, views). `public/` is the document root pointed to by Nginx.  
- `writable/` stores cache, logs, and uploads; keep permissions liberal when running inside Docker.  
- `docker/` contains the PHP-FPM Dockerfile, custom `php.ini`, and Nginx vhost. `docker-compose.yml` orchestrates `php`, `nginx`, and `mysql`.  
- Tests live in `tests/` and mirror the namespace structure under `app/`. Configuration examples are under `env` and `.env`.

## Build, Test, and Development Commands
- `docker compose up -d --build` — builds the PHP 8.4 image (with GD, intl, mysqli, Xdebug) and launches the stack.  
- `docker compose exec php composer install` — installs PHP dependencies inside the container when `vendor/` is absent or outdated.  
- `docker compose exec php php spark serve` is unnecessary; Nginx proxies to PHP-FPM automatically. Use `spark` for framework tasks instead.  
- `docker compose exec php php spark migrate` — runs database migrations using the `.env` credentials.  
- `docker compose exec php php spark test` — executes the PHPUnit suite bundled with CodeIgniter 4.

## Coding Style & Naming Conventions
- Follow PSR-12 and CodeIgniter conventions: four-space indentation, StudlyCaps classes under `App\Controllers`, `App\Models`, etc.  
- Keep controllers thin; use service classes in `app/Services` when logic grows.  
- Route names, migration classes, and seeders should be descriptive English phrases (`AddUsersTable`, `CreateBlogSeeder`).  
- PHPStan/Psalm are not configured; rely on CI4’s coding standard via `composer cs-fix` if added later.

## Testing Guidelines
- PHPUnit is configured via `phpunit.xml.dist`; use `tests/app` for feature tests and `tests/unit` for smaller units.  
- Name test classes with the component suffix (`UserModelTest`, `HomeControllerTest`).  
- Run tests inside the PHP container to ensure extensions (mysqli, intl) match production. Aim to cover new routes, services, and migrations with at least one test per feature.

## Commit & Pull Request Guidelines
- Existing history (`git log --oneline`) uses short imperative Japanese messages; keep the style consistent (e.g., `Xdebug有効化`, `docker関連資材配置`).  
- Each commit should focus on a single logical change: infrastructure, feature, or fix.  
- Pull requests should describe context, testing done (`spark test`, `docker compose up`), and any configuration or documentation updates.  
- Include screenshots or curl logs when altering HTTP responses, and link to tracker issues if applicable.
