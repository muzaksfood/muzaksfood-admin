<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('ai_settings', function (Blueprint $table) {
            $table->unsignedInteger('priority')->default(1)->after('status');
            $table->string('model')->nullable()->after('priority');
            $table->json('settings')->nullable()->after('model');
        });
    }

    public function down(): void
    {
        Schema::table('ai_settings', function (Blueprint $table) {
            $table->dropColumn(['priority', 'model', 'settings']);
        });
    }
};
