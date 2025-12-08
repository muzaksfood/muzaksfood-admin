<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::table('branches', function (Blueprint $table) {
            if (!Schema::hasColumn('branches', 'enable_express')) {
                $table->boolean('enable_express')->default(0)->after('status');
            }
            if (!Schema::hasColumn('branches', 'express_fee')) {
                $table->decimal('express_fee', 10, 2)->nullable()->after('enable_express');
            }
            if (!Schema::hasColumn('branches', 'express_radius_km')) {
                $table->decimal('express_radius_km', 10, 2)->nullable()->after('express_fee');
            }
        });
    }

    public function down(): void
    {
        Schema::table('branches', function (Blueprint $table) {
            if (Schema::hasColumn('branches', 'express_radius_km')) {
                $table->dropColumn('express_radius_km');
            }
            if (Schema::hasColumn('branches', 'express_fee')) {
                $table->dropColumn('express_fee');
            }
            if (Schema::hasColumn('branches', 'enable_express')) {
                $table->dropColumn('enable_express');
            }
        });
    }
};
