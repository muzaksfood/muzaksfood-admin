@php
    $modelConfig = config('ai_models');
    $providerModels = $modelConfig[$providerName]['models'] ?? [];
    $defaultModel = $modelConfig[$providerName]['default'] ?? '';
@endphp

@if($providerName === 'DeepSeek')
    {{-- Special handling for DeepSeek with OpenRouter option --}}
    <div class="col-md-6">
        <label class="text-capitalize">{{ translate('Base_URL') }}</label>
        <select class="form-control deepseek-base-url-select" 
                name="providers[{{ $providerName }}][base_url_preset]"
                onchange="updateDeepSeekBaseUrl(this)">
            <option value="">{{ translate('select_base_url') }}</option>
            <option value="https://api.deepseek.com" @selected($setting?->base_url === 'https://api.deepseek.com')>
                {{ translate('DeepSeek_Official') }} (https://api.deepseek.com)
            </option>
            <option value="https://openrouter.ai/api/v1" @selected($setting?->base_url === 'https://openrouter.ai/api/v1')>
                {{ translate('OpenRouter_AI') }} (https://openrouter.ai/api/v1) - {{ translate('Free') }}
            </option>
        </select>
        <input type="hidden" name="providers[{{ $providerName }}][base_url]" value="{{ $setting?->base_url }}">
    </div>

    <div class="col-md-3">
        <label class="text-capitalize">{{ translate('Model') }}</label>
        <select class="form-control" name="providers[{{ $providerName }}][model]">
            <option value="">{{ translate('select_model_optional') }}</option>
            @foreach($modelConfig[$providerName]['models'] ?? [] as $modelKey => $modelLabel)
                <option value="{{ $modelKey }}" @selected($setting?->model === $modelKey || (!$setting?->model && $modelKey === $defaultModel))>
                    {{ $modelLabel }}
                </option>
            @endforeach
            @if($setting?->base_url === 'https://openrouter.ai/api/v1')
                @foreach($modelConfig[$providerName]['openrouter_models'] ?? [] as $modelKey => $modelLabel)
                    <option value="{{ $modelKey }}" @selected($setting?->model === $modelKey)>
                        {{ $modelLabel }}
                    </option>
                @endforeach
            @endif
        </select>
    </div>
@else
    {{-- Standard Base URL input (optional) --}}
    <div class="col-md-6">
        <label class="text-capitalize">{{ translate('Base_URL_(optional)') }}</label>
        <input type="text" class="form-control" name="providers[{{ $providerName }}][base_url]" 
               placeholder="https://..." value="{{ $setting?->base_url }}">
    </div>

    {{-- Model dropdown --}}
    <div class="col-md-3">
        <label class="text-capitalize">{{ translate('Model') }}</label>
        <select class="form-control" name="providers[{{ $providerName }}][model]">
            <option value="">{{ translate('select_model_optional') }}</option>
            @forelse($providerModels as $modelKey => $modelLabel)
                <option value="{{ $modelKey }}" @selected($setting?->model === $modelKey || (!$setting?->model && $modelKey === $defaultModel))>
                    {{ $modelLabel }}
                </option>
            @empty
                <option value="">{{ translate('no_models_available') }}</option>
            @endforelse
        </select>
    </div>
@endif
