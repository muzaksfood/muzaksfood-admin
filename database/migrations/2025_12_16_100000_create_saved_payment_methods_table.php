<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('saved_payment_methods', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('customer_id');
            $table->string('card_holder_name', 255);
            $table->longText('card_number_encrypted'); // Encrypted full card number
            $table->char('card_number_last_four', 4);  // Last 4 digits for display
            $table->unsignedTinyInteger('expiry_month'); // 1-12
            $table->unsignedSmallInteger('expiry_year'); // 2025+
            $table->boolean('is_default')->default(false);
            $table->boolean('is_deleted')->default(false); // Soft delete
            $table->timestamps();

            $table->foreign('customer_id')->references('id')->on('users')->onDelete('cascade');
            $table->index(['customer_id', 'is_default'], 'idx_customer_is_default');
            $table->index(['customer_id', 'created_at'], 'idx_customer_created');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('saved_payment_methods');
    }
};
