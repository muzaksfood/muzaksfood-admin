<?php

namespace App\Models;

use App\User;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class FilterUsageAnalytics extends Model
{
    protected $table = 'filter_usage_analytics';

    protected $fillable = [
        'customer_id',
        'filter_type',
        'min_price',
        'max_price',
        'rating',
    ];

    protected $casts = [
        'customer_id' => 'integer',
        'min_price' => 'decimal:2',
        'max_price' => 'decimal:2',
        'rating' => 'decimal:1',
    ];

    /**
     * Valid filter types.
     */
    public const FILTER_TYPE_PRICE_RANGE = 'price_range';
    public const FILTER_TYPE_RATING = 'rating';
    public const FILTER_TYPE_COMBINED = 'combined';

    /**
     * Get the customer that performed the filter action.
     */
    public function customer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'customer_id');
    }

    /**
     * Scope to filter by filter type.
     */
    public function scopeOfType($query, string $type)
    {
        return $query->where('filter_type', $type);
    }

    /**
     * Scope to filter by date range.
     */
    public function scopeInDateRange($query, $days = 7)
    {
        return $query->where('created_at', '>=', now()->subDays($days));
    }

    /**
     * Get popular price ranges.
     */
    public static function getPopularPriceRanges(int $days = 7, int $limit = 10): array
    {
        $results = self::inDateRange($days)
            ->whereNotNull('min_price')
            ->whereNotNull('max_price')
            ->selectRaw('min_price, max_price, COUNT(*) as count')
            ->groupBy('min_price', 'max_price')
            ->orderByDesc('count')
            ->limit($limit)
            ->get();

        $total = $results->sum('count');

        return $results->map(function ($item) use ($total) {
            return [
                'min' => (float) $item->min_price,
                'max' => (float) $item->max_price,
                'count' => $item->count,
                'percentage' => $total > 0 ? round(($item->count / $total) * 100, 1) : 0,
            ];
        })->toArray();
    }

    /**
     * Get popular ratings.
     */
    public static function getPopularRatings(int $days = 7, int $limit = 10): array
    {
        $results = self::inDateRange($days)
            ->whereNotNull('rating')
            ->selectRaw('ROUND(rating * 2) / 2 as rounded_rating, COUNT(*) as count')
            ->groupBy('rounded_rating')
            ->orderByDesc('count')
            ->limit($limit)
            ->get();

        $total = $results->sum('count');

        return $results->map(function ($item) use ($total) {
            return [
                'rating' => (float) $item->rounded_rating,
                'count' => $item->count,
                'percentage' => $total > 0 ? round(($item->count / $total) * 100, 1) : 0,
            ];
        })->toArray();
    }

    /**
     * Get total filter events count.
     */
    public static function getTotalEventsCount(int $days = 7): int
    {
        return self::inDateRange($days)->count();
    }
}
