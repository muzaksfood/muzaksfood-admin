<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Model\Product;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class CartQuickController extends Controller
{
    /**
     * Lightweight quick-add endpoint for landing page carts (session-based).
     */
    public function quickAdd(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'product_id' => 'required|exists:products,id',
            'quantity' => 'nullable|integer|min:1|max:10',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $quantity = $request->input('quantity', 1);
        $product = Product::find($request->product_id);

        if (($product->total_stock ?? 0) < $quantity) {
            return response()->json([
                'success' => false,
                'message' => 'Insufficient stock',
            ], 400);
        }

        $cart = session()->get('landing_cart', []);
        $existingQty = $cart[$product->id]['quantity'] ?? 0;
        $cart[$product->id] = [
            'product_id' => $product->id,
            'name' => $product->name,
            'image' => $product->image,
            'price' => $product->price,
            'quantity' => min($existingQty + $quantity, 10),
        ];

        session()->put('landing_cart', $cart);

        $count = collect($cart)->sum('quantity');

        return response()->json([
            'success' => true,
            'cart_count' => $count,
        ]);
    }
}
