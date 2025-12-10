<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>MuzaksFood | 10-minute groceries</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <style>
        :root {
            --primary: #8B50A5;
            --success: #00B383;
            --badge: #FF6B00;
            --text: #1A1A1A;
            --muted: #6b7280;
            --card: #ffffff;
            --bg: #f8f9fb;
        }
        body { font-family: 'Inter', sans-serif; background: var(--bg); color: var(--text); }
        .pill-nav { gap: 8px; overflow-x: auto; padding: 8px 16px; }
        .pill { border: 1px solid rgba(139,80,165,0.25); color: var(--text); }
        .pill:hover { border-color: var(--primary); color: var(--primary); }
        .product-card { border: 1px solid rgba(0,0,0,0.06); box-shadow: 0 6px 18px rgba(0,0,0,0.06); }
        .product-img { background: #fff; }
        .add-btn { background: var(--success); border: none; }
        .add-btn:hover { background: #00a173; }
        .badge-discount { background: #d93d3d; }
        .price { font-weight: 700; }
        .old-price { text-decoration: line-through; color: var(--muted); font-size: 0.9rem; }
        .category-section { scroll-margin-top: 96px; }
        .sticky-top-light { backdrop-filter: blur(12px); background: rgba(255,255,255,0.9); }
        .card-compact { border-radius: 12px; }
        .mini-badge { background: var(--badge); }
        .footer-links a { color: var(--muted); text-decoration: none; }
    </style>
</head>
<body>
<header class="sticky-top sticky-top-light shadow-sm">
    <div class="container-fluid py-3 px-3 px-md-4">
        <div class="d-flex align-items-center justify-content-between flex-wrap gap-2">
            <div class="d-flex align-items-center gap-3">
                <a href="/landing" class="text-decoration-none text-dark fw-bold fs-4">MuzaksFood</a>
                <span class="badge bg-success text-white">10-min delivery</span>
            </div>
            <div class="flex-grow-1 d-none d-md-flex">
                <input class="form-control" type="search" placeholder="Search for products" aria-label="Search">
            </div>
            <div class="d-flex align-items-center gap-3">
                <button class="btn btn-outline-secondary btn-sm">Login</button>
                <button class="btn btn-primary" style="background: var(--primary); border-color: var(--primary);">Download App</button>
            </div>
        </div>
        <div class="d-flex pill-nav mt-3">
            @foreach($categories as $category)
                <a class="btn btn-light pill py-2 px-3" href="#cat-{{ $category->id }}">{{ $category->name }}</a>
            @endforeach
        </div>
    </div>
</header>

<main class="container-fluid px-3 px-md-4 py-4">
    <div class="row g-4">
        @foreach($categories as $category)
            <div class="col-12 category-section" id="cat-{{ $category->id }}">
                <div class="d-flex justify-content-between align-items-center mb-3">
                    <h2 class="h5 mb-0">{{ $category->name }}</h2>
                    <a class="text-decoration-none" href="#">See All</a>
                </div>
                <div class="row g-3">
                    @foreach($category->home_products as $product)
                        <div class="col-6 col-md-4 col-lg-2">
                            <div class="card product-card card-compact h-100">
                                <div class="position-relative">
                                    @php
                                        $img = $product->image;
                                        if (is_array($img)) { $img = $img[0] ?? ''; }
                                        $imgUrl = $img ? asset('storage/app/public/product/' . $img) : asset('public/assets/admin/img/placeholder.png');
                                    @endphp
                                    <div class="ratio ratio-1x1 product-img p-2">
                                        <img src="{{ $imgUrl }}" class="w-100 h-100 object-fit-contain" alt="{{ $product->name }}">
                                    </div>
                                    @if(($product->price ?? 0) > ($product->discount ?? $product->price ?? 0))
                                        <span class="badge badge-discount position-absolute top-0 start-0 m-2">{{ $product->discount_type === 'percent' ? '-' . ($product->discount ?? 0) . '%' : 'SAVE' }}</span>
                                    @endif
                                </div>
                                <div class="card-body d-flex flex-column gap-2">
                                    <button class="btn add-btn text-white w-100 quick-add" data-product-id="{{ $product->id }}">ADD</button>
                                    <div class="d-flex align-items-center gap-2">
                                        <span class="price">₹{{ number_format(($product->discount ?? $product->price ?? 0), 2) }}</span>
                                        @if(($product->price ?? 0) > ($product->discount ?? $product->price ?? 0))
                                            <span class="old-price">₹{{ number_format($product->price, 2) }}</span>
                                        @endif
                                    </div>
                                    <div>
                                        <p class="mb-1 fw-semibold" style="min-height: 42px;">{{ $product->name }}</p>
                                        <p class="text-muted small mb-1">{{ $product->capacity }} {{ $product->unit }}</p>
                                        @if($product->rating && count($product->rating) > 0)
                                            <span class="badge text-bg-light">★ {{ number_format($product->rating[0]['average'] ?? 0, 1) }}</span>
                                        @endif
                                    </div>
                                </div>
                            </div>
                        </div>
                    @endforeach
                </div>
            </div>
        @endforeach
    </div>
</main>

<footer class="py-4 mt-5 border-top">
    <div class="container-fluid px-3 px-md-4">
        <div class="d-flex flex-wrap justify-content-between align-items-center gap-3">
            <span class="fw-semibold">MuzaksFood</span>
            <div class="footer-links d-flex gap-3 small">
                <a href="#">Privacy</a>
                <a href="#">Terms</a>
                <a href="#">Support</a>
            </div>
        </div>
    </div>
</footer>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
<script>
    document.addEventListener('DOMContentLoaded', function() {
        const buttons = document.querySelectorAll('.quick-add');
        const toast = (msg) => {
            const el = document.createElement('div');
            el.className = 'toast align-items-center text-bg-dark border-0 position-fixed bottom-0 end-0 m-3 show';
            el.role = 'alert';
            el.innerHTML = `<div class="d-flex"><div class="toast-body">${msg}</div><button type="button" class="btn-close btn-close-white me-2 m-auto" data-bs-dismiss="toast"></button></div>`;
            document.body.appendChild(el);
            setTimeout(() => el.remove(), 2500);
        };

        buttons.forEach(btn => {
            btn.addEventListener('click', function(e) {
                e.preventDefault();
                const productId = this.dataset.productId;
                this.disabled = true;
                this.innerText = 'ADDING...';

                fetch('/api/v1/cart/quick-add', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'Accept': 'application/json'
                    },
                    body: JSON.stringify({ product_id: productId, quantity: 1 })
                }).then(r => r.json()).then(data => {
                    if (data.success) {
                        toast('Added to cart');
                        this.innerText = 'IN CART';
                    } else {
                        toast(data.message || 'Could not add');
                        this.innerText = 'ADD';
                        this.disabled = false;
                    }
                }).catch(() => {
                    toast('Network error');
                    this.innerText = 'ADD';
                    this.disabled = false;
                });
            });
        });
    });
</script>
</body>
</html>
