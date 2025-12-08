<?php

namespace App\Console\Commands;

use App\CentralLogics\CustomerLogic;
use App\CentralLogics\Helpers;
use App\Model\Order;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;

class CheckExpressSLA extends Command
{
    protected $signature = 'express:check-sla';
    protected $description = 'Check and compensate breached express delivery SLAs';

    public function handle(): int
    {
        $compensationEnabled = (int)(Helpers::get_business_settings('express_sla_compensation_enabled') ?? 0) === 1;
        
        if (!$compensationEnabled) {
            $this->info('SLA compensation is disabled');
            return 0;
        }

        $compensationPercentage = (float)(Helpers::get_business_settings('express_sla_compensation_percentage') ?? 10);
        
        $breachedOrders = Order::where('is_express', 1)
            ->where('sla_breached', 0)
            ->where('order_status', '!=', 'delivered')
            ->where('order_status', '!=', 'canceled')
            ->where('order_status', '!=', 'returned')
            ->where('order_status', '!=', 'failed')
            ->whereNotNull('express_eta')
            ->where('express_eta', '<', now())
            ->get();

        $count = 0;
        
        foreach ($breachedOrders as $order) {
            DB::beginTransaction();
            try {
                // Calculate compensation amount
                $compensationAmount = ($order->order_amount * $compensationPercentage) / 100;
                
                // Mark as breached
                $order->sla_breached = 1;
                $order->compensation_amount = $compensationAmount;
                $order->save();

                // Credit to customer wallet if not guest
                if (!$order->is_guest && $order->user_id) {
                    CustomerLogic::create_wallet_transaction(
                        $order->user_id,
                        $compensationAmount,
                        'express_sla_compensation',
                        $order->id
                    );
                }

                DB::commit();
                $count++;
                
                $this->info("Order #{$order->id} - SLA breached. Compensated: {$compensationAmount}");
            } catch (\Exception $e) {
                DB::rollBack();
                $this->error("Failed to process order #{$order->id}: " . $e->getMessage());
            }
        }

        $this->info("Processed {$count} breached express orders");
        return 0;
    }
}
