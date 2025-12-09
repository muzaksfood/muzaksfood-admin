<?php

namespace Modules\AI\AIProviders;

use Illuminate\Support\Facades\Http;
use Modules\AI\app\Contracts\AIProviderInterface;

class DeepSeekProvider implements AIProviderInterface
{
    protected string $apiKey = '';
    protected string $baseUrl = 'https://api.deepseek.com';
    protected string $model = 'deepseek-chat';
    protected array $settings = [];

    public function getName(): string
    {
        return 'DeepSeek';
    }

    public function setApiKey($apiKey): void
    {
        $this->apiKey = $apiKey ?? '';
    }

    public function setBaseUrl($baseUrl): void
    {
        if ($baseUrl) {
            $this->baseUrl = rtrim($baseUrl, '/');
        }
    }

    public function setModel($model): void
    {
        if ($model) {
            $this->model = $model;
        }
    }

    public function setSettings($settings): void
    {
        $this->settings = $settings ?? [];
    }

    public function generate(string $prompt, ?string $imageUrl = null, array $options = []): string
    {
        if (empty($this->apiKey)) {
            throw new \RuntimeException('DeepSeek API key is missing');
        }

        $message = $imageUrl ? $prompt . "\n\nImage reference: " . $imageUrl : $prompt;

        // Support OpenRouter.ai endpoint
        $isOpenRouter = strpos($this->baseUrl, 'openrouter.ai') !== false;
        
        if ($isOpenRouter) {
            return $this->generateViaOpenRouter($message);
        }

        $response = Http::withToken($this->apiKey)
            ->acceptJson()
            ->post($this->baseUrl . '/chat/completions', [
                'model' => $this->model,
                'messages' => [
                    [
                        'role' => 'user',
                        'content' => $message,
                    ],
                ],
                'temperature' => 0.3,
            ]);

        if (!$response->successful()) {
            throw new \RuntimeException('DeepSeek error: ' . $response->body());
        }

        $data = $response->json();
        $content = $data['choices'][0]['message']['content'] ?? null;
        if (!$content) {
            throw new \RuntimeException('DeepSeek returned empty response');
        }

        return $content;
    }

    protected function generateViaOpenRouter(string $message): string
    {
        $response = Http::withHeader('Authorization', 'Bearer ' . $this->apiKey)
            ->withHeader('HTTP-Referer', config('app.url'))
            ->withHeader('X-Title', 'MuzaksFood')
            ->acceptJson()
            ->post($this->baseUrl . '/chat/completions', [
                'model' => $this->model,
                'messages' => [
                    [
                        'role' => 'user',
                        'content' => $message,
                    ],
                ],
                'temperature' => 0.3,
            ]);

        if (!$response->successful()) {
            throw new \RuntimeException('DeepSeek error: ' . $response->body());
        }

        $data = $response->json();
        $content = $data['choices'][0]['message']['content'] ?? null;
        if (!$content) {
            throw new \RuntimeException('DeepSeek returned empty response');
        }

        return $content;
    }
}

