<?php

namespace Modules\AI\AIProviders;

use Illuminate\Support\Facades\Http;
use Modules\AI\app\Contracts\AIProviderInterface;

class GeminiProvider implements AIProviderInterface
{
    protected string $apiKey = '';
    protected string $baseUrl = 'https://generativelanguage.googleapis.com/v1beta';
    protected string $model = 'gemini-1.5-flash';
    protected array $settings = [];

    public function getName(): string
    {
        return 'Gemini';
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
            throw new \RuntimeException('Gemini API key is missing');
        }

        $parts = [['text' => $prompt]];
        if ($imageUrl) {
            $parts[] = ['text' => "Image reference: " . $imageUrl];
        }

        $endpoint = $this->baseUrl . '/models/' . $this->model . ':generateContent?key=' . $this->apiKey;
        $response = Http::acceptJson()->post($endpoint, [
            'contents' => [
                ['parts' => $parts],
            ],
        ]);

        if (!$response->successful()) {
            throw new \RuntimeException('Gemini error: ' . $response->body());
        }

        $data = $response->json();
        $content = $data['candidates'][0]['content']['parts'][0]['text'] ?? null;
        if (!$content) {
            throw new \RuntimeException('Gemini returned empty response');
        }

        return $content;
    }
}
