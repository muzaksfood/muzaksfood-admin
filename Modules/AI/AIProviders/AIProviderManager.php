<?php

namespace Modules\AI\AIProviders;

use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Request;
use Modules\AI\app\Exceptions\AIProviderException;
use Modules\AI\app\Exceptions\ImageValidationException;
use Modules\AI\app\Exceptions\UsageLimitException;
use Modules\AI\app\Exceptions\ValidationException;
use Modules\AI\app\Models\AISetting;
use Modules\AI\app\Services\AIResponseValidatorService;
use Modules\AI\app\Traits\AIModuleManager;

class AIProviderManager
{
    use AIModuleManager;
    protected array $providers;

    public function __construct(array $providers = [])
    {
        $this->providers = $providers;
    }

    protected function getProviderMap(): array
    {
        $map = [];
        foreach ($this->providers as $provider) {
            $map[$provider->getName()] = $provider;
        }
        return $map;
    }

    /**
     * @throws AIProviderException
     */
    public function getActiveAIProviders()
    {
        $providers = $this->getActiveAIProviderConfig();
        if (!$providers || $providers->isEmpty()) {
            throw new AIProviderException('No active AI provider available at this moment.');
        }
        return $providers;
    }

    protected function configureProvider($provider, AISetting $config): void
    {
        if (method_exists($provider, 'setApiKey')) {
            $provider->setApiKey($config->api_key);
        }
        if (method_exists($provider, 'setOrganization')) {
            $provider->setOrganization($config->organization_id);
        }
        if (method_exists($provider, 'setBaseUrl') && $config->base_url) {
            $provider->setBaseUrl($config->base_url);
        }
        if (method_exists($provider, 'setModel') && $config->model) {
            $provider->setModel($config->model);
        }
        if (method_exists($provider, 'setSettings') && $config->settings) {
            $provider->setSettings($config->settings ?? []);
        }
    }

    /**
     * @throws ImageValidationException
     * @throws AIProviderException
     * @throws ValidationException
     * @throws UsageLimitException
     */
    public function generate(string $prompt, ?string $imageUrl = null, array $options = []): string
    {
        $activeProviders = $this->getActiveAIProviders();
        $providerMap = $this->getProviderMap();
        $aiValidator = new AIResponseValidatorService();
        $appMode = env('APP_MODE');
        $section = $options['section'] ?? '';
        $errors = [];

        if ($appMode === 'demo') {
            $ip = request()->header('x-forwarded-for');
            $cacheKey = 'demo_ip_usage_' . $ip;
            $count = Cache::get($cacheKey, 0);
            if ($count >= 10) {
                throw new ValidationException("Demo limit reached: You can only generate 10 times.");
            }
            Cache::forever($cacheKey, $count + 1);
        }

        foreach ($activeProviders as $config) {
            if (!isset($providerMap[$config->ai_name])) {
                $errors[] = $config->ai_name . ': provider not registered';
                continue;
            }

            $provider = $providerMap[$config->ai_name];
            $this->configureProvider($provider, $config);

            try {
                $response = $provider->generate($prompt, $imageUrl, $options);

                $validatorMap = [
                    'product_name' => 'validateProductTitle',
                    'product_description' => 'validateProductDescription',
                    'generate_product_title_suggestion' => 'validateProductKeyword',
                    'pricing_and_others' => 'validateProductPricingAndOthers',
                    'generate_title_from_image' => 'validateImageResponse',
                    'category_setup' => 'validateProductCategorySetup',
                    'variation_tag_setup' => 'validateProductVariationTagSetup'

                ];

                if ($section && isset($validatorMap[$section])) {
                    $aiValidator->{$validatorMap[$section]}($response, $options['context'] ?? null);
                }

                return $response;
            } catch (\Throwable $e) {
                $errors[] = $config->ai_name . ': ' . $e->getMessage();
                continue;
            }
        }

        throw new AIProviderException('All AI providers failed: ' . implode(' | ', $errors));
    }

}
