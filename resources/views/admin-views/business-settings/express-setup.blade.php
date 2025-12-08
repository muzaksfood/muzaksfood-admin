@extends('layouts.admin.app')

@section('title', translate('Express Delivery'))

@section('content')
<div class="content container-fluid">
    @include('admin-views.business-settings.partial.business-settings-navmenu')

    <div class="card">
        <div class="card-header">
            <h5 class="card-title mb-0 d-flex align-items-center">
            <span class="card-header-icon mr-2">
                <i class="tio-rocket"></i>
            </span>
            {{ translate('Express Delivery Settings') }}
            <span class="badge badge-soft-info ml-2" data-toggle="tooltip" data-placement="top" 
                title="{{ translate('Zepto-style express delivery with ultra-fast SLA (Service Level Agreement) and premium pricing') }}">
                <i class="tio-info-outined"></i>
            </span>
            </h5>
        </div>
        <div class="card-body">
            <div class="d-flex justify-content-between align-items-center border rounded mb-4 px-3 py-2">
                <div>
                    <h6 class="mb-1">{{ translate('Express Delivery Status') }}</h6>
                    <small class="text-muted">{{ translate('Enable or disable express delivery feature globally') }}</small>
                </div>
                <label class="toggle-switch toggle-switch-sm">
                    <input type="checkbox" class="toggle-switch-input" id="express-status-toggle"
                        onclick="toggleExpressStatus()"
                        {{ $status ? 'checked' : '' }}>
                    <span class="toggle-switch-label text mb-0">
                        <span class="toggle-switch-indicator"></span>
                    </span>
                </label>
            </div>

            <form action="{{ route('admin.business-settings.express.update') }}" method="post" class="row g-3">
                @csrf
                <div class="col-md-3">
                    <label class="input-label d-flex align-items-center">
                        {{ translate('Express Fee') }}
                        <i class="tio-info-outined text-body ml-1" data-toggle="tooltip" 
                            data-placement="top"
                            title="{{ translate('Additional charge for express delivery on top of regular delivery fee') }}"></i>
                    </label>
                    <div class="input-group">
                        <input type="number" step="0.01" min="0" name="fee" class="form-control" value="{{ $fee }}" required>
                        <div class="input-group-append">
                            <span class="input-group-text">{{ \App\CentralLogics\Helpers::currency_symbol() }}</span>
                        </div>
                    </div>
                </div>
                <div class="col-md-3">
                    <label class="input-label d-flex align-items-center">
                        {{ translate('SLA Minutes') }}
                        <i class="tio-info-outined text-body ml-1" data-toggle="tooltip" 
                            data-placement="top"
                            title="{{ translate('Delivery time commitment in minutes (e.g., 10 for 10-minute delivery)') }}"></i>
                    </label>
                    <div class="input-group">
                        <input type="number" min="1" max="60" name="sla_minutes" class="form-control" value="{{ $sla }}" required>
                        <div class="input-group-append">
                            <span class="input-group-text">min</span>
                        </div>
                    </div>
                </div>
                <div class="col-md-3">
                    <label class="input-label d-flex align-items-center">
                        {{ translate('Radius') }}
                        <i class="tio-info-outined text-body ml-1" data-toggle="tooltip" 
                            data-placement="top"
                            title="{{ translate('Maximum distance from branch for express delivery availability') }}"></i>
                    </label>
                    <div class="input-group">
                        <input type="number" step="0.1" min="0.1" max="50" name="radius_km" class="form-control" value="{{ $radius }}" required>
                        <div class="input-group-append">
                            <span class="input-group-text">km</span>
                        </div>
                    </div>
                </div>
                <div class="col-md-3">
                    <label class="input-label d-flex align-items-center">
                        {{ translate('Compensation %') }}
                        <i class="tio-info-outined text-body ml-1" data-toggle="tooltip" 
                            data-placement="top"
                            title="{{ translate('Wallet credit percentage if SLA is breached (0 to disable)') }}"></i>
                    </label>
                    <div class="input-group">
                        <input type="number" step="1" min="0" max="100" name="compensation_percentage" 
                            class="form-control" value="{{ $compensationPercentage ?? 10 }}" required>
                        <div class="input-group-append">
                            <span class="input-group-text">%</span>
                        </div>
                    </div>
                </div>
                <div class="col-12">
                    <div class="alert alert-soft-info">
                        <i class="tio-info mr-2"></i>
                        {{ translate('Branch-level overrides: You can configure express settings per branch in the Branch Edit page') }}
                    </div>
                </div>
                <div class="col-12 d-flex justify-content-end">
                    <button type="submit" class="btn btn-primary">
                        <i class="tio-save mr-1"></i>
                        {{ translate('Save Configuration') }}
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>
@endsection

@push('script_2')
<script>
    function toggleExpressStatus() {
        $.ajax({
            url: '{{ route('admin.business-settings.express.status', ['status' => $status ? 0 : 1]) }}',
            type: 'POST',
            data: {
                _token: '{{ csrf_token() }}'
            },
            beforeSend: function () {
                $('#loading').show();
            },
            success: function (data) {
                toastr.success(data.message);
                setTimeout(() => location.reload(), 1000);
            },
            error: function () {
                toastr.error('{{ translate('Failed to update status') }}');
                location.reload();
            },
            complete: function () {
                $('#loading').hide();
            }
        });
    }
</script>
@endpush

