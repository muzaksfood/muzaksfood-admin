<?php

namespace App\Http\Controllers\Api\V1;

use App\CentralLogics\Helpers;
use App\Http\Controllers\Controller;
use App\Models\FilterUsageAnalytics;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Validator;

class FilterAnalyticsController extends Controller
{
    /**
     * Log filter usage analytics (batch endpoint).
     * 
     * POST /api/v1/customer/analytics/filter-usage
     */
    public function logFilterUsage(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'events' => 'required|array|min:1',
            'events.*.filter_type' => 'required|string|in:price_range,rating,combined',
            'events.*.min_price' => 'nullable|numeric|min:0',
            'events.*.max_price' => 'nullable|numeric|min:0',
            'events.*.rating' => 'nullable|numeric|min:0|max:5',
            'events.*.timestamp' => 'nullable|date',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => Helpers::error_processor($validator),
            ], 422);
        }

        $customerId = auth('api')->user()->id;
        $syncedCount = 0;
        $maxTimeDiff = 3600; // 1 hour in seconds

        foreach ($request->events as $event) {
            // Validate timestamp is not too old (within 1 hour)
            $timestamp = isset($event['timestamp']) 
                ? \Carbon\Carbon::parse($event['timestamp']) 
                : now();
            
            if ($timestamp->diffInSeconds(now()) > $maxTimeDiff) {
                $timestamp = now();
            }

            FilterUsageAnalytics::create([
                'customer_id' => $customerId,
                'filter_type' => $event['filter_type'],
                'min_price' => $event['min_price'] ?? null,
                'max_price' => $event['max_price'] ?? null,
                'rating' => $event['rating'] ?? null,
                'created_at' => $timestamp,
                'updated_at' => $timestamp,
            ]);

            $syncedCount++;
        }

        return response()->json([
            'success' => true,
            'message' => 'Filter usage logged',
            'synced_count' => $syncedCount,
        ], 200);
    }

    /**
     * Get popular filters across all customers.
     * 
     * GET /api/v1/customer/analytics/popular-filters
     */
    public function getPopularFilters(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'days' => 'nullable|integer|min:1|max:365',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => Helpers::error_processor($validator),
            ], 422);
        }

        $days = $request->input('days', 7);
        $cacheKey = "popular_filters_{$days}";

        $data = Cache::remember($cacheKey, now()->addHour(), function () use ($days) {
            return [
                'popular_price_ranges' => FilterUsageAnalytics::getPopularPriceRanges($days),
                'popular_ratings' => FilterUsageAnalytics::getPopularRatings($days),
                'period' => "last_{$days}_days",
                'total_filter_events' => FilterUsageAnalytics::getTotalEventsCount($days),
            ];
        });

        return response()->json([
            'success' => true,
            'data' => $data,
        ], 200);
    }
}
