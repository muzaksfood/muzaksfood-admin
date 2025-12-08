<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            if (!Schema::hasColumn('orders', 'is_express')) {
                $table->boolean('is_express')->default(0)->after('order_type');
            }
            if (!Schema::hasColumn('orders', 'express_fee')) {
                $table->decimal('express_fee', 10, 2)->default(0)->after('delivery_charge');
            }
            if (!Schema::hasColumn('orders', 'promised_minutes')) {
                $table->integer('promised_minutes')->nullable()->after('express_fee');
            }
            if (!Schema::hasColumn('orders', 'express_eta')) {
                $table->dateTime('express_eta')->nullable()->after('promised_minutes');
            }
        });
    }

    public function down(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            if (Schema::hasColumn('orders', 'express_eta')) {
                $table->dropColumn('express_eta');
            }
            if (Schema::hasColumn('orders', 'promised_minutes')) {
                $table->dropColumn('promised_minutes');
            }
            if (Schema::hasColumn('orders', 'express_fee')) {
                $table->dropColumn('express_fee');
            }
            if (Schema::hasColumn('orders', 'is_express')) {
                $table->dropColumn('is_express');
            }
        });
    }
};
