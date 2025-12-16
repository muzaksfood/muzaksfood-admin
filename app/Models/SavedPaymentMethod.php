<?php

namespace App\Models;

use App\User;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Facades\Crypt;

class SavedPaymentMethod extends Model
{
    protected $table = 'saved_payment_methods';

    protected $fillable = [
        'customer_id',
        'card_holder_name',
        'card_number_encrypted',
        'card_number_last_four',
        'expiry_month',
        'expiry_year',
        'is_default',
        'is_deleted',
    ];

    protected $hidden = [
        'card_number_encrypted',
    ];

    protected $casts = [
        'customer_id' => 'integer',
        'expiry_month' => 'integer',
        'expiry_year' => 'integer',
        'is_default' => 'boolean',
        'is_deleted' => 'boolean',
    ];

    /**
     * Get the customer that owns the payment method.
     */
    public function customer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'customer_id');
    }

    /**
     * Set the card number (encrypts before storing).
     */
    public function setCardNumberAttribute($value): void
    {
        $this->attributes['card_number_encrypted'] = Crypt::encryptString($value);
        $this->attributes['card_number_last_four'] = substr($value, -4);
    }

    /**
     * Get the masked card number for display.
     */
    public function getMaskedCardNumberAttribute(): string
    {
        return '****' . $this->card_number_last_four;
    }

    /**
     * Scope to get only non-deleted payment methods.
     */
    public function scopeActive($query)
    {
        return $query->where('is_deleted', false);
    }

    /**
     * Scope to get payment methods for a specific customer.
     */
    public function scopeForCustomer($query, $customerId)
    {
        return $query->where('customer_id', $customerId);
    }

    /**
     * Validate card number using Luhn algorithm.
     */
    public static function validateCardNumber(string $cardNumber): bool
    {
        $cardNumber = preg_replace('/\D/', '', $cardNumber);
        
        if (strlen($cardNumber) < 13 || strlen($cardNumber) > 19) {
            return false;
        }

        $sum = 0;
        $length = strlen($cardNumber);
        $parity = $length % 2;

        for ($i = 0; $i < $length; $i++) {
            $digit = (int) $cardNumber[$i];
            
            if ($i % 2 === $parity) {
                $digit *= 2;
                if ($digit > 9) {
                    $digit -= 9;
                }
            }
            
            $sum += $digit;
        }

        return $sum % 10 === 0;
    }

    /**
     * Check if the card is expired.
     */
    public function isExpired(): bool
    {
        $now = now();
        $expiryDate = \Carbon\Carbon::createFromDate($this->expiry_year, $this->expiry_month, 1)->endOfMonth();
        
        return $now->greaterThan($expiryDate);
    }

    /**
     * Format for API response.
     */
    public function toApiResponse(): array
    {
        return [
            'id' => $this->id,
            'customer_id' => $this->customer_id,
            'card_holder_name' => $this->card_holder_name,
            'card_number' => $this->masked_card_number,
            'expiry_month' => $this->expiry_month,
            'expiry_year' => $this->expiry_year,
            'is_default' => $this->is_default,
            'created_at' => $this->created_at->toIso8601String(),
        ];
    }
}
