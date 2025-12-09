# Multi-AI Provider Integration

This project now supports **multiple AI providers** with automatic fallback. If one provider fails or runs out of quota, the system automatically tries the next enabled provider.

## Supported Providers

1. **OpenAI** (GPT-4o, GPT-3.5, etc.)
2. **DeepSeek** (deepseek-chat)
3. **Gemini** (Google AI - gemini-1.5-flash-latest)
4. **Grok** (X.AI - grok-beta)
5. **Claude** (Anthropic - claude-3-haiku)

## Configuration

### Admin Panel Setup

1. Navigate to **Admin → Business Settings → AI Configuration**
2. For each provider you want to use:
   - **Enable** the toggle switch
   - Enter **API Key** (required when enabled)
   - Optionally set **Base URL** (for custom endpoints)
   - Optionally set **Model** (defaults shown above)
   - Set **Priority** (1 = first, 2 = second fallback, etc.)

### API Keys

#### OpenAI
- Sign up at https://platform.openai.com
- Create API key at https://platform.openai.com/api-keys
- Optional: Organization ID from https://platform.openai.com/organization/general

#### DeepSeek (FREE)
- Sign up at https://platform.deepseek.com
- Get API key from dashboard
- Base URL: `https://api.deepseek.com`
- Free tier available

#### Gemini (Google - FREE tier available)
- Sign up at https://ai.google.dev
- Create API key at https://aistudio.google.com/apikey
- Base URL: `https://generativelanguage.googleapis.com/v1beta`
- Free quota: 15 requests/minute

#### Grok (X.AI)
- Sign up at https://x.ai
- Request API access
- Base URL: `https://api.x.ai/v1`

#### Claude (Anthropic)
- Sign up at https://console.anthropic.com
- Create API key in settings
- Base URL: `https://api.anthropic.com/v1`

## How Fallback Works

When generating AI content (product names, descriptions, etc.):

1. System loads all **active** providers ordered by **priority**
2. Tries the first provider
3. If it fails (API error, quota exceeded, network issue), automatically tries the next provider
4. Continues until success or all providers exhausted
5. Returns generated content or throws error with details from all attempts

## Example Priority Setup

| Provider | Enabled | Priority | Use Case |
|----------|---------|----------|----------|
| DeepSeek | ✓ | 1 | Primary (free) |
| Gemini | ✓ | 2 | Fallback (free) |
| OpenAI | ✓ | 3 | Premium backup |
| Grok | ✗ | 4 | Disabled |
| Claude | ✗ | 5 | Disabled |

With this setup:
- DeepSeek tries first (free)
- If DeepSeek fails → Gemini tries (free)
- If Gemini fails → OpenAI tries (paid)
- Grok and Claude are disabled

## Database Schema

Migration: `Modules/AI/Database/migrations/2025_12_08_000001_update_ai_settings_add_priority_and_model.php`

### `ai_settings` table
- `ai_name` - Provider name (OpenAI, DeepSeek, etc.)
- `api_key` - API key
- `organization_id` - Optional (OpenAI only)
- `base_url` - Optional custom endpoint
- `model` - Optional model override
- `priority` - Fallback order (1 = first)
- `status` - 1=active, 0=inactive
- `settings` - JSON for future custom settings

## Run Migration

```bash
php artisan migrate
```

## Testing

1. Enable 2+ providers with different priorities
2. Try AI product generation from Admin → Products → Add Product
3. Check logs/responses to see which provider succeeded
4. Intentionally use invalid API key on priority-1 provider to test fallback

## Notes

- **Free providers** (DeepSeek, Gemini) have rate limits
- Set **lower priority** for paid providers to save costs
- Each provider returns text; validators ensure response format
- Errors from all failed attempts are logged and returned
