<?php

namespace App\Http\Controllers\Api\V1;

use App\CentralLogics\Helpers;
use App\Http\Controllers\Controller;
use App\Models\SavedPaymentMethod;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;

class PaymentMethodController extends Controller
{
    /**
     * Get all saved payment methods for the authenticated customer.
     * 
     * GET /api/v1/customer/payment-methods
     */
    public function index(Request $request): JsonResponse
    {
        $customerId = auth('api')->user()->id;

        $paymentMethods = SavedPaymentMethod::active()
            ->forCustomer($customerId)
            ->orderByDesc('is_default')
            ->orderByDesc('created_at')
            ->get()
            ->map(fn($method) => $method->toApiResponse());

        return response()->json([
            'success' => true,
            'data' => $paymentMethods,
        ], 200);
    }

    /**
     * Add a new payment method.
     * 
     * POST /api/v1/customer/payment-methods/add
     */
    public function store(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'card_holder_name' => 'required|string|max:255',
            'card_number' => 'required|string|min:13|max:19',
            'expiry_month' => 'required|integer|min:1|max:12',
            'expiry_year' => 'required|integer|min:' . date('Y'),
            'cvv' => 'required|string|min:3|max:4', // CVV is validated but NOT stored
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => Helpers::error_processor($validator),
            ], 422);
        }

        $cardNumber = preg_replace('/\D/', '', $request->card_number);

        // Validate card number using Luhn algorithm
        if (!SavedPaymentMethod::validateCardNumber($cardNumber)) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => [['code' => 'card_number', 'message' => 'Invalid card number']],
            ], 422);
        }

        // Check if card has expired
        $expiryDate = \Carbon\Carbon::createFromDate(
            $request->expiry_year,
            $request->expiry_month,
            1
        )->endOfMonth();

        if (now()->greaterThan($expiryDate)) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => [['code' => 'expiry_year', 'message' => 'Card has expired']],
            ], 422);
        }

        $customerId = auth('api')->user()->id;

        // Check if this is the first payment method
        $isFirstMethod = SavedPaymentMethod::active()
            ->forCustomer($customerId)
            ->count() === 0;

        $paymentMethod = new SavedPaymentMethod();
        $paymentMethod->customer_id = $customerId;
        $paymentMethod->card_holder_name = $request->card_holder_name;
        $paymentMethod->card_number = $cardNumber; // This triggers the mutator
        $paymentMethod->expiry_month = $request->expiry_month;
        $paymentMethod->expiry_year = $request->expiry_year;
        $paymentMethod->is_default = $isFirstMethod;
        $paymentMethod->save();

        // CVV is intentionally NOT stored (PCI compliance)

        return response()->json([
            'success' => true,
            'message' => 'Payment method added successfully',
            'data' => $paymentMethod->toApiResponse(),
        ], 201);
    }

    /**
     * Update an existing payment method (non-sensitive fields only).
     * 
     * PUT /api/v1/customer/payment-methods/update
     */
    public function update(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'payment_method_id' => 'required|integer',
            'card_holder_name' => 'sometimes|string|max:255',
            'expiry_month' => 'sometimes|integer|min:1|max:12',
            'expiry_year' => 'sometimes|integer|min:' . date('Y'),
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => Helpers::error_processor($validator),
            ], 422);
        }

        $customerId = auth('api')->user()->id;

        $paymentMethod = SavedPaymentMethod::active()
            ->forCustomer($customerId)
            ->find($request->payment_method_id);

        if (!$paymentMethod) {
            return response()->json([
                'success' => false,
                'message' => 'Payment method not found',
            ], 404);
        }

        // Validate new expiry date if provided
        $expiryMonth = $request->expiry_month ?? $paymentMethod->expiry_month;
        $expiryYear = $request->expiry_year ?? $paymentMethod->expiry_year;

        $expiryDate = \Carbon\Carbon::createFromDate($expiryYear, $expiryMonth, 1)->endOfMonth();

        if (now()->greaterThan($expiryDate)) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => [['code' => 'expiry_year', 'message' => 'Card expiry date is in the past']],
            ], 422);
        }

        // Update only allowed fields
        if ($request->has('card_holder_name')) {
            $paymentMethod->card_holder_name = $request->card_holder_name;
        }
        if ($request->has('expiry_month')) {
            $paymentMethod->expiry_month = $request->expiry_month;
        }
        if ($request->has('expiry_year')) {
            $paymentMethod->expiry_year = $request->expiry_year;
        }

        $paymentMethod->save();

        return response()->json([
            'success' => true,
            'message' => 'Payment method updated successfully',
            'data' => $paymentMethod->toApiResponse(),
        ], 200);
    }

    /**
     * Delete a saved payment method.
     * 
     * DELETE /api/v1/customer/payment-methods/delete/{id}
     */
    public function destroy($id): JsonResponse
    {
        $customerId = auth('api')->user()->id;

        $paymentMethod = SavedPaymentMethod::active()
            ->forCustomer($customerId)
            ->find($id);

        if (!$paymentMethod) {
            return response()->json([
                'success' => false,
                'message' => 'Payment method not found or unauthorized',
            ], 404);
        }

        // Check if this is the only payment method
        $totalMethods = SavedPaymentMethod::active()
            ->forCustomer($customerId)
            ->count();

        if ($totalMethods <= 1) {
            return response()->json([
                'success' => false,
                'message' => 'Cannot delete the only payment method. Add another payment method first.',
            ], 400);
        }

        $wasDefault = $paymentMethod->is_default;

        // Soft delete
        $paymentMethod->is_deleted = true;
        $paymentMethod->is_default = false;
        $paymentMethod->save();

        // If this was the default, set the oldest remaining as default
        if ($wasDefault) {
            $oldestMethod = SavedPaymentMethod::active()
                ->forCustomer($customerId)
                ->orderBy('created_at')
                ->first();

            if ($oldestMethod) {
                $oldestMethod->is_default = true;
                $oldestMethod->save();
            }
        }

        return response()->json([
            'success' => true,
            'message' => 'Payment method deleted successfully',
        ], 200);
    }

    /**
     * Set a payment method as the default.
     * 
     * POST /api/v1/customer/payment-methods/set-default
     */
    public function setDefault(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'payment_method_id' => 'required|integer',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => Helpers::error_processor($validator),
            ], 422);
        }

        $customerId = auth('api')->user()->id;

        $paymentMethod = SavedPaymentMethod::active()
            ->forCustomer($customerId)
            ->find($request->payment_method_id);

        if (!$paymentMethod) {
            return response()->json([
                'success' => false,
                'message' => 'Payment method not found or unauthorized',
            ], 404);
        }

        DB::transaction(function () use ($customerId, $paymentMethod) {
            // Remove default from all other payment methods
            SavedPaymentMethod::active()
                ->forCustomer($customerId)
                ->where('id', '!=', $paymentMethod->id)
                ->update(['is_default' => false]);

            // Set this one as default
            $paymentMethod->is_default = true;
            $paymentMethod->save();
        });

        return response()->json([
            'success' => true,
            'message' => 'Default payment method updated',
            'data' => $paymentMethod->fresh()->toApiResponse(),
        ], 200);
    }
}
