<?php

namespace App\Models;

use App\User;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Facades\Cache;

class SearchAnalytics extends Model
{
    protected $table = 'search_analytics';

    protected $fillable = [
        'query',
        'customer_id',
        'product_result_count',
    ];

    protected $casts = [
        'customer_id' => 'integer',
        'product_result_count' => 'integer',
    ];

    /**
     * Cache key for trending searches.
     */
    public const TRENDING_CACHE_KEY = 'trending_searches';
    public const CACHE_TTL_MINUTES = 60;

    /**
     * Get the customer (optional).
     */
    public function customer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'customer_id');
    }

    /**
     * Log a search query.
     */
    public static function logSearch(string $query, ?int $customerId = null, int $resultCount = 0): self
    {
        return self::create([
            'query' => trim($query),
            'customer_id' => $customerId,
            'product_result_count' => $resultCount,
        ]);
    }

    /**
     * Get trending searches.
     */
    public static function getTrendingSearches(int $limit = 10, int $days = 7): array
    {
        $cacheKey = self::TRENDING_CACHE_KEY . "_{$days}_{$limit}";

        return Cache::remember($cacheKey, now()->addMinutes(self::CACHE_TTL_MINUTES), function () use ($limit, $days) {
            // Current period
            $currentPeriodStart = now()->subDays($days);
            $currentResults = self::where('created_at', '>=', $currentPeriodStart)
                ->selectRaw('LOWER(query) as normalized_query, COUNT(*) as count')
                ->whereRaw('LENGTH(query) > 1') // Exclude single-character queries
                ->groupBy('normalized_query')
                ->orderByDesc('count')
                ->limit($limit)
                ->get();

            // Previous period for trend calculation
            $previousPeriodStart = now()->subDays($days * 2);
            $previousPeriodEnd = now()->subDays($days);
            $previousResults = self::whereBetween('created_at', [$previousPeriodStart, $previousPeriodEnd])
                ->selectRaw('LOWER(query) as normalized_query, COUNT(*) as count')
                ->groupBy('normalized_query')
                ->pluck('count', 'normalized_query');

            return $currentResults->map(function ($item) use ($previousResults) {
                $previousCount = $previousResults[$item->normalized_query] ?? 0;
                $trend = 'stable';
                $trendPercentage = 0;

                if ($previousCount > 0) {
                    $trendPercentage = round((($item->count - $previousCount) / $previousCount) * 100, 1);
                    
                    if ($trendPercentage > 5) {
                        $trend = 'up';
                    } elseif ($trendPercentage < -5) {
                        $trend = 'down';
                    }
                } elseif ($item->count > 0) {
                    $trend = 'up';
                    $trendPercentage = 100;
                }

                return [
                    'query' => $item->normalized_query,
                    'count' => $item->count,
                    'trend' => $trend,
                    'trend_percentage' => $trendPercentage,
                ];
            })->toArray();
        });
    }

    /**
     * Clear trending searches cache.
     */
    public static function clearTrendingCache(): void
    {
        Cache::forget(self::TRENDING_CACHE_KEY . '_7_10');
    }
}
