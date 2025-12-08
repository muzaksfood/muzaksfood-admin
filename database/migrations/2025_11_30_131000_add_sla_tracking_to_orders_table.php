<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            if (!Schema::hasColumn('orders', 'sla_breached')) {
                $table->boolean('sla_breached')->default(0)->after('express_eta');
            }
            if (!Schema::hasColumn('orders', 'compensation_amount')) {
                $table->decimal('compensation_amount', 10, 2)->default(0)->after('sla_breached');
            }
        });
    }

    public function down(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            if (Schema::hasColumn('orders', 'compensation_amount')) {
                $table->dropColumn('compensation_amount');
            }
            if (Schema::hasColumn('orders', 'sla_breached')) {
                $table->dropColumn('sla_breached');
            }
        });
    }
};
