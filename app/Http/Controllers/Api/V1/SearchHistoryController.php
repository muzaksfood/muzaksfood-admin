<?php

namespace App\Http\Controllers\Api\V1;

use App\CentralLogics\Helpers;
use App\Http\Controllers\Controller;
use App\Models\CustomerSearchHistory;
use App\Models\SearchAnalytics;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class SearchHistoryController extends Controller
{
    /**
     * Get customer's personal search history.
     * 
     * GET /api/v1/customer/search-history
     */
    public function getHistory(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'limit' => 'nullable|integer|min:1|max:100',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => Helpers::error_processor($validator),
            ], 422);
        }

        $customerId = auth('api')->user()->id;
        $limit = $request->input('limit', 20);

        $history = CustomerSearchHistory::forCustomer($customerId)
            ->orderByDesc('created_at')
            ->limit($limit)
            ->get()
            ->map(fn($item) => $item->toApiResponse());

        return response()->json([
            'success' => true,
            'data' => $history,
        ], 200);
    }

    /**
     * Save a search query to customer's history.
     * 
     * POST /api/v1/customer/search-history/save
     */
    public function saveSearch(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'query' => 'required|string|min:1|max:255',
            'result_count' => 'nullable|integer|min:0',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => Helpers::error_processor($validator),
            ], 422);
        }

        $query = trim($request->query);

        if (empty($query)) {
            return response()->json([
                'success' => false,
                'message' => 'Search query cannot be empty',
            ], 400);
        }

        $customerId = auth('api')->user()->id;
        $resultCount = $request->input('result_count', 0);

        try {
            $history = CustomerSearchHistory::saveSearch($customerId, $query, $resultCount);

            return response()->json([
                'success' => true,
                'message' => 'Search saved to history',
                'data' => $history->toApiResponse(),
            ], 201);
        } catch (\InvalidArgumentException $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 400);
        }
    }

    /**
     * Clear all search history for the authenticated customer.
     * 
     * DELETE /api/v1/customer/search-history/clear
     */
    public function clearHistory(): JsonResponse
    {
        $customerId = auth('api')->user()->id;

        CustomerSearchHistory::clearHistory($customerId);

        return response()->json([
            'success' => true,
            'message' => 'Search history cleared successfully',
        ], 200);
    }

    /**
     * Get trending search queries across all customers.
     * 
     * GET /api/v1/products/trending-searches
     */
    public function getTrendingSearches(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'limit' => 'nullable|integer|min:1|max:50',
            'days' => 'nullable|integer|min:1|max:365',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => Helpers::error_processor($validator),
            ], 422);
        }

        $limit = $request->input('limit', 10);
        $days = $request->input('days', 7);

        $trendingSearches = SearchAnalytics::getTrendingSearches($limit, $days);

        return response()->json([
            'success' => true,
            'data' => $trendingSearches,
            'period' => "last_{$days}_days",
        ], 200);
    }
}
