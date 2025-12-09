<?php

namespace Modules\AI\AIProviders;

use Illuminate\Support\Facades\Http;
use Modules\AI\app\Contracts\AIProviderInterface;

class ClaudeProvider implements AIProviderInterface
{
    protected string $apiKey = '';
    protected string $model = 'claude-3-5-sonnet-20241022';
    protected string $baseUrl = 'https://api.anthropic.com/v1';
    protected array $settings = [];

    public function getName(): string
    {
        return 'Claude';
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
            throw new \RuntimeException('Claude API key is missing');
        }

        $payload = [
            'model' => $this->model,
            'max_tokens' => 400,
            'messages' => [
                [
                    'role' => 'user',
                    'content' => $this->buildContent($prompt, $imageUrl),
                ],
            ],
        ];

        $response = Http::withHeaders([
            'x-api-key' => $this->apiKey,
            'anthropic-version' => '2023-06-01',
        ])->post($this->baseUrl . '/messages', $payload);

        if (!$response->successful()) {
            throw new \RuntimeException('Claude error: ' . $response->body());
        }

        $data = $response->json();
        $content = $data['content'][0]['text'] ?? null;

        if (!$content) {
            throw new \RuntimeException('Claude returned empty response');
        }

        return $content;
    }

    protected function buildContent(string $prompt, ?string $imageUrl = null): string
    {
        if ($imageUrl) {
            return $prompt . "\n\nImage reference: " . $imageUrl;
        }
        return $prompt;
    }
}
