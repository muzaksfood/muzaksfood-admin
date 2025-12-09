<?php

namespace Modules\AI\AIProviders;

use Modules\AI\app\Contracts\AIProviderInterface;
use OpenAI;

class OpenAIProvider implements AIProviderInterface
{
    protected string $apiKey;
    protected ?string $organization;
    protected string $baseUrl = '';
    protected string $model = 'gpt-4o';
    protected array $settings = [];

    public function getName(): string
    {
        return 'OpenAI';
    }

    public function setApiKey($apikey): void
    {
        $this->apiKey = $apikey;
    }

    public function setOrganization($organization): void
    {
        $this->organization = $organization;
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
        $factory = OpenAI::factory()
            ->withApiKey($this->apiKey);

        if ($this->organization) {
            $factory = $factory->withOrganization($this->organization);
        }

        if ($this->baseUrl) {
            $factory = $factory->withBaseUri($this->baseUrl);
        }

        $client = $factory->make();
        $content = [['type' => 'text', 'text' => $prompt]];
        if (!empty($imageUrl)) {
            $content[] = [
                'type' => 'image_url',
                'image_url' => ['url' => $imageUrl],
            ];
        }
        $response = $client->chat()->create([
            'model' => $this->model,
            'messages' => [
                [
                    'role' => 'user',
                    'content' => $content,
                ],
            ],
            'temperature' => 0.3,
        ]);
        return $response->choices[0]->message->content;
    }
}
