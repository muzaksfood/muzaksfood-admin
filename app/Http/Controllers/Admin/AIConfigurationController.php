<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Brian2694\Toastr\Facades\Toastr;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\View\View;
use Modules\AI\app\Models\AISetting;

class AIConfigurationController extends Controller
{
    public function index(): View
    {
        $aiSettings = AISetting::all()->keyBy('ai_name');
        $providers = $this->providerList();

        return view('admin-views.business-settings.ai-configuration.index', compact('aiSettings', 'providers'));
    }

    public function store(Request $request)
    {
        $rules = [];
        foreach ($this->providerList() as $providerName) {
            $rules["providers.$providerName.api_key"] = 'nullable|string';
            $rules["providers.$providerName.organization_id"] = 'nullable|string';
            $rules["providers.$providerName.base_url"] = 'nullable|string';
            $rules["providers.$providerName.model"] = 'nullable|string';
            $rules["providers.$providerName.priority"] = 'nullable|integer|min:1';
            $rules["providers.$providerName.status"] = 'nullable|in:on';
        }

        $validated = $request->validate($rules);

        foreach ($this->providerList() as $providerName) {
            $input = $validated['providers'][$providerName] ?? [];
            $isActive = isset($input['status']);

            if ($isActive && empty($input['api_key'])) {
                Toastr::warning(translate($providerName . ' API key is required when enabled.'));
                continue;
            }

            AISetting::updateOrCreate(
                ['ai_name' => $providerName],
                [
                    'api_key' => $input['api_key'] ?? null,
                    'organization_id' => $input['organization_id'] ?? null,
                    'base_url' => $input['base_url'] ?? null,
                    'model' => $input['model'] ?? null,
                    'priority' => $input['priority'] ?? 1,
                    'status' => $isActive ? 1 : 0,
                ]
            );
        }

        Cache::forget('active_ai_providers');

        Toastr::success(translate('Information updated successfully!'));

        return back();
    }

    protected function providerList(): array
    {
        return ['OpenAI', 'DeepSeek', 'Gemini', 'Grok', 'Claude'];
    }
}
