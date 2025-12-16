<?php

namespace App\Models;

use App\User;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class CustomerSearchHistory extends Model
{
    protected $table = 'customer_search_history';

    protected $fillable = [
        'customer_id',
        'query',
        'result_count',
    ];

    protected $casts = [
        'customer_id' => 'integer',
        'result_count' => 'integer',
    ];

    /**
     * Maximum history entries per customer.
     */
    public const MAX_HISTORY_ENTRIES = 20;

    /**
     * Get the customer that owns this search history entry.
     */
    public function customer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'customer_id');
    }

    /**
     * Scope to get history for a specific customer.
     */
    public function scopeForCustomer($query, $customerId)
    {
        return $query->where('customer_id', $customerId);
    }

    /**
     * Save search and handle deduplication.
     */
    public static function saveSearch(int $customerId, string $searchQuery, int $resultCount = 0): self
    {
        $query = trim($searchQuery);
        
        if (empty($query)) {
            throw new \InvalidArgumentException('Search query cannot be empty');
        }

        // Delete existing identical query for this customer
        self::forCustomer($customerId)
            ->where('query', $query)
            ->delete();

        // Create new entry
        $history = self::create([
            'customer_id' => $customerId,
            'query' => $query,
            'result_count' => $resultCount,
        ]);

        // Keep only last MAX_HISTORY_ENTRIES entries
        self::pruneOldEntries($customerId);

        // Also log to search analytics
        SearchAnalytics::logSearch($query, $customerId, $resultCount);

        return $history;
    }

    /**
     * Remove old entries to keep only MAX_HISTORY_ENTRIES.
     */
    protected static function pruneOldEntries(int $customerId): void
    {
        $entriesToKeep = self::forCustomer($customerId)
            ->orderByDesc('created_at')
            ->take(self::MAX_HISTORY_ENTRIES)
            ->pluck('id');

        self::forCustomer($customerId)
            ->whereNotIn('id', $entriesToKeep)
            ->delete();
    }

    /**
     * Clear all history for a customer.
     */
    public static function clearHistory(int $customerId): int
    {
        return self::forCustomer($customerId)->delete();
    }

    /**
     * Format for API response.
     */
    public function toApiResponse(): array
    {
        return [
            'id' => $this->id,
            'query' => $this->query,
            'result_count' => $this->result_count,
            'timestamp' => $this->created_at->toIso8601String(),
        ];
    }
}
