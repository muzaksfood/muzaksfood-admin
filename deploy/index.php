<?php
/**
 * Enhanced Deployment Log Viewer & Dashboard
 * Features: Analytics, Search, Filter, Export, Real-time stats
 */

// Configuration
$logFile = __DIR__ . '/deploy-log.txt';
$adminPassword = '2026Amd...@1'; // Change this to something secure
$sessionTimeout = 1800; // 30 minutes

session_start();

// Check session timeout
if (isset($_SESSION['isAdmin']) && isset($_SESSION['lastActivity'])) {
    if (time() - $_SESSION['lastActivity'] > $sessionTimeout) {
        session_unset();
        session_destroy();
        session_start();
        $error = "Session expired. Please login again.";
    }
}
$_SESSION['lastActivity'] = time();

// Handle login
if (isset($_POST['password'])) {
    if ($_POST['password'] === $adminPassword) {
        $_SESSION['isAdmin'] = true;
        $_SESSION['loginTime'] = time();
        header("Location: index.php");
        exit;
    } else {
        $error = "Incorrect password!";
        sleep(2); // Prevent brute force
    }
}

// Handle logout
if (isset($_GET['logout'])) {
    session_destroy();
    header("Location: index.php");
    exit;
}


// Check authentication
$isAdmin = $_SESSION['isAdmin'] ?? false;

// Handle actions (only for authenticated users)
if ($isAdmin) {
    // Clear logs
    if (isset($_POST['clear_logs'])) {
        file_put_contents($logFile, '');
        header("Location: index.php?cleared=1");
        exit;
    }
    
    // Download logs
    if (isset($_GET['download'])) {
        header('Content-Type: text/plain');
        header('Content-Disposition: attachment; filename="deploy-log-' . date('Y-m-d-His') . '.txt"');
        readfile($logFile);
        exit;
    }
    
    // Export as JSON
    if (isset($_GET['export_json'])) {
        $entries = parseLogEntries($logFile);
        header('Content-Type: application/json');
        header('Content-Disposition: attachment; filename="deploy-log-' . date('Y-m-d-His') . '.json"');
        echo json_encode($entries, JSON_PRETTY_PRINT);
        exit;
    }
}

// Parse log entries
function parseLogEntries($file) {
    $entries = [];
    if (!file_exists($file)) return $entries;
    
    $lines = file($file, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    
    foreach ($lines as $line) {
        $entry = [
            'raw' => $line,
            'timestamp' => '',
            'type' => 'INFO',
            'message' => $line
        ];
        
        // Parse structured logs: [YYYY-MM-DD HH:MM:SS] [TYPE] Message
        if (preg_match('/^\[([^\]]+)\]\s*\[([^\]]+)\]\s*(.+)$/', $line, $matches)) {
            $entry['timestamp'] = $matches[1];
            $entry['type'] = $matches[2];
            $entry['message'] = $matches[3];
        }
        
        $entries[] = $entry;
    }
    
    return array_reverse($entries); // Newest first
}

// Calculate statistics
function calculateStats($entries) {
    $stats = [
        'total' => count($entries),
        'errors' => 0,
        'warnings' => 0,
        'success' => 0,
        'info' => 0,
        'deployments' => 0,
        'last_deploy' => null
    ];
    
    foreach ($entries as $entry) {
        $type = $entry['type'];
        
        if ($type === 'ERROR') $stats['errors']++;
        elseif ($type === 'WARN') $stats['warnings']++;
        elseif ($type === 'SUCCESS') $stats['success']++;
        else $stats['info']++;
        
        if (strpos($entry['message'], 'Deployment Completed Successfully') !== false) {
            $stats['deployments']++;
            if (!$stats['last_deploy']) {
                $stats['last_deploy'] = $entry['timestamp'];
            }
        }
    }
    
    return $stats;
}

$entries = parseLogEntries($logFile);
$stats = calculateStats($entries);
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Deploy Dashboard - MuzaksFood</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css" rel="stylesheet">
    <style>
        :root {
            --primary: #0d6efd;
            --success: #28a745;
            --error: #dc3545;
            --warning: #ffc107;
            --info: #17a2b8;
            --dark: #343a40;
        }
        
        body {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
        }
        
        .dashboard-container {
            max-width: 1400px;
            margin: 20px auto;
            padding: 0 15px;
        }
        
        .login-container {
            max-width: 450px;
            margin: 100px auto;
        }
        
        .card {
            border: none;
            border-radius: 15px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.2);
            backdrop-filter: blur(10px);
            background: rgba(255, 255, 255, 0.95);
        }
        
        .card-header {
            background: linear-gradient(135deg, var(--primary), #0056b3);
            color: white;
            border-radius: 15px 15px 0 0 !important;
            padding: 20px;
        }
        
        .stat-card {
            border-radius: 12px;
            padding: 20px;
            margin-bottom: 20px;
            color: white;
            transition: transform 0.2s;
        }
        
        .stat-card:hover {
            transform: translateY(-5px);
        }
        
        .stat-card.info { background: linear-gradient(135deg, var(--info), #138496); }
        .stat-card.success { background: linear-gradient(135deg, var(--success), #1e7e34); }
        .stat-card.error { background: linear-gradient(135deg, var(--error), #bd2130); }
        .stat-card.warning { background: linear-gradient(135deg, var(--warning), #e0a800); }
        
        .stat-value {
            font-size: 2.5rem;
            font-weight: bold;
            margin: 10px 0;
        }
        
        .stat-label {
            font-size: 0.9rem;
            opacity: 0.9;
            text-transform: uppercase;
            letter-spacing: 1px;
        }
        
        .log-entry {
            background: white;
            border-left: 4px solid var(--info);
            padding: 15px 20px;
            margin-bottom: 10px;
            border-radius: 8px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.08);
            transition: all 0.2s;
            font-family: 'Courier New', monospace;
            font-size: 0.9rem;
        }
        
        .log-entry:hover {
            box-shadow: 0 4px 12px rgba(0,0,0,0.15);
            transform: translateX(5px);
        }
        
        .log-entry.ERROR { border-left-color: var(--error); background: #fff5f5; }
        .log-entry.WARN { border-left-color: var(--warning); background: #fffbf0; }
        .log-entry.SUCCESS { border-left-color: var(--success); background: #f0fff4; }
        .log-entry.INFO { border-left-color: var(--info); }
        
        .log-timestamp {
            color: #6c757d;
            font-size: 0.85rem;
            margin-right: 10px;
        }
        
        .log-type {
            display: inline-block;
            padding: 3px 10px;
            border-radius: 20px;
            font-size: 0.75rem;
            font-weight: bold;
            margin-right: 10px;
        }
        
        .log-type.ERROR { background: var(--error); color: white; }
        .log-type.WARN { background: var(--warning); color: #333; }
        .log-type.SUCCESS { background: var(--success); color: white; }
        .log-type.INFO { background: var(--info); color: white; }
        
        .filter-badge {
            cursor: pointer;
            transition: all 0.2s;
        }
        
        .filter-badge:hover {
            transform: scale(1.1);
        }
        
        .filter-badge.active {
            box-shadow: 0 0 10px rgba(0,0,0,0.3);
        }
        
        .search-box {
            border-radius: 25px;
            padding: 12px 20px;
            border: 2px solid #e0e0e0;
        }
        
        .search-box:focus {
            border-color: var(--primary);
            box-shadow: 0 0 15px rgba(13, 110, 253, 0.2);
        }
        
        .action-btn {
            border-radius: 8px;
            padding: 10px 20px;
            font-weight: 500;
            transition: all 0.2s;
        }
        
        .action-btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 5px 15px rgba(0,0,0,0.2);
        }
        
        .empty-state {
            text-align: center;
            padding: 60px 20px;
            color: #6c757d;
        }
        
        .empty-state i {
            font-size: 4rem;
            margin-bottom: 20px;
            opacity: 0.3;
        }
        
        @media (max-width: 768px) {
            .stat-value { font-size: 1.8rem; }
            .dashboard-container { padding: 0 10px; }
        }
    </style>
</head>
<body>

<?php if (!$isAdmin): ?>
    <!-- Login Screen -->
    <div class="login-container">
        <div class="card">
            <div class="card-header text-center">
                <h3 class="mb-0"><i class="fas fa-rocket"></i> MuzaksFood Deploy Dashboard</h3>
                <small>MuzaksFood Deployment Monitor</small>
            </div>
            <div class="card-body p-4">
                <?php if (isset($error)): ?>
                    <div class="alert alert-danger">
                        <i class="fas fa-exclamation-triangle"></i> <?= htmlspecialchars($error) ?>
                    </div>
                <?php endif; ?>
                
                <form method="post">
                    <div class="mb-3">
                        <label class="form-label">Admin Password</label>
                        <div class="position-relative">
                            <input type="password" id="password" name="password" class="form-control search-box pe-5" 
                                   placeholder="Enter password..." required autofocus>
                            <button type="button" class="btn btn-link position-absolute top-50 end-0 translate-middle-y me-2 p-1" 
                                    id="togglePassword" style="border: none; background: none; color: #6c757d;">
                                <i class="fas fa-eye" id="eyeIcon"></i>
                            </button>
                        </div>
                    </div>
                    <button type="submit" class="btn btn-primary w-100 action-btn">
                        <i class="fas fa-sign-in-alt"></i> Login
                    </button>
                </form>
            </div>
        </div>
    </div>

<?php else: ?>
    <!-- Dashboard -->
    <div class="dashboard-container">
        <!-- Header -->
        <div class="d-flex justify-content-between align-items-center mb-4">
            <div>
                <h2 class="text-white mb-0">
                    <i class="fas fa-rocket"></i> MuzaksFood Deployment Monitor
                </h2>
                <small class="text-white-50">Real-time deployment monitoring</small>
            </div>
            <div>
                <a href="?logout=1" class="btn btn-light action-btn">
                    <i class="fas fa-sign-out-alt"></i> Logout
                </a>
            </div>
        </div>

        <!-- Statistics Cards -->
        <div class="row mb-4">
            <div class="col-md-3 col-sm-6">
                <div class="stat-card info">
                    <div class="stat-label"><i class="fas fa-list"></i> Total Logs</div>
                    <div class="stat-value"><?= number_format($stats['total']) ?></div>
                </div>
            </div>
            <div class="col-md-3 col-sm-6">
                <div class="stat-card success">
                    <div class="stat-label"><i class="fas fa-check-circle"></i> Deployments</div>
                    <div class="stat-value"><?= number_format($stats['deployments']) ?></div>
                </div>
            </div>
            <div class="col-md-3 col-sm-6">
                <div class="stat-card error">
                    <div class="stat-label"><i class="fas fa-times-circle"></i> Errors</div>
                    <div class="stat-value"><?= number_format($stats['errors']) ?></div>
                </div>
            </div>
            <div class="col-md-3 col-sm-6">
                <div class="stat-card warning">
                    <div class="stat-label"><i class="fas fa-exclamation-triangle"></i> Warnings</div>
                    <div class="stat-value"><?= number_format($stats['warnings']) ?></div>
                </div>
            </div>
        </div>

        <?php if ($stats['last_deploy']): ?>
        <div class="alert alert-info mb-4">
            <i class="fas fa-clock"></i> <strong>Last Deployment:</strong> <?= htmlspecialchars($stats['last_deploy']) ?>
        </div>
        <?php endif; ?>

        <?php if (isset($_GET['cleared'])): ?>
        <div class="alert alert-success alert-dismissible fade show">
            <i class="fas fa-check"></i> Logs cleared successfully!
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
        <?php endif; ?>

        <!-- Controls -->
        <div class="card mb-4">
            <div class="card-body">
                <div class="row align-items-center">
                    <div class="col-md-6 mb-3 mb-md-0">
                        <input type="text" id="searchBox" class="form-control search-box" 
                               placeholder="🔍 Search logs...">
                    </div>
                    <div class="col-md-6 text-end">
                        <div class="btn-group" role="group">
                            <button class="btn btn-outline-primary filter-badge active" data-filter="ALL">
                                All
                            </button>
                            <button class="btn btn-outline-danger filter-badge" data-filter="ERROR">
                                Errors
                            </button>
                            <button class="btn btn-outline-warning filter-badge" data-filter="WARN">
                                Warnings
                            </button>
                            <button class="btn btn-outline-success filter-badge" data-filter="SUCCESS">
                                Success
                            </button>
                            <button class="btn btn-outline-info filter-badge" data-filter="INFO">
                                Info
                            </button>
                        </div>
                    </div>
                </div>
                
                <div class="row mt-3">
                    <div class="col-12">
                        <a href="?download=1" class="btn btn-success action-btn me-2">
                            <i class="fas fa-download"></i> Download TXT
                        </a>
                        <a href="?export_json=1" class="btn btn-info action-btn me-2">
                            <i class="fas fa-file-code"></i> Export JSON
                        </a>
                        <form method="post" style="display: inline;" onsubmit="return confirm('Are you sure you want to clear all logs?');">
                            <button type="submit" name="clear_logs" class="btn btn-danger action-btn">
                                <i class="fas fa-trash"></i> Clear Logs
                            </button>
                        </form>
                    </div>
                </div>
            </div>
        </div>

        <!-- Log Entries -->
        <div class="card">
            <div class="card-header">
                <h5 class="mb-0"><i class="fas fa-terminal"></i> Log Entries</h5>
            </div>
            <div class="card-body" style="max-height: 800px; overflow-y: auto;">
                <div id="logEntries">
                    <?php if (empty($entries)): ?>
                        <div class="empty-state">
                            <i class="fas fa-inbox"></i>
                            <h4>No logs yet</h4>
                            <p>Deploy logs will appear here once webhooks are triggered.</p>
                        </div>
                    <?php else: ?>
                        <?php foreach ($entries as $entry): ?>
                            <div class="log-entry <?= htmlspecialchars($entry['type']) ?>" 
                                 data-type="<?= htmlspecialchars($entry['type']) ?>">
                                <?php if ($entry['timestamp']): ?>
                                    <span class="log-timestamp">
                                        <i class="far fa-clock"></i> <?= htmlspecialchars($entry['timestamp']) ?>
                                    </span>
                                <?php endif; ?>
                                <span class="log-type <?= htmlspecialchars($entry['type']) ?>">
                                    <?= htmlspecialchars($entry['type']) ?>
                                </span>
                                <div style="margin-top: 5px;">
                                    <?= nl2br(htmlspecialchars($entry['message'])) ?>
                                </div>
                            </div>
                        <?php endforeach; ?>
                    <?php endif; ?>
                </div>
            </div>
        </div>
    </div>
<?php endif; ?>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
<script>
    // Password Toggle Functionality
    document.addEventListener('DOMContentLoaded', function() {
        const togglePassword = document.getElementById('togglePassword');
        const passwordField = document.getElementById('password');
        const eyeIcon = document.getElementById('eyeIcon');
        
        if (togglePassword && passwordField && eyeIcon) {
            togglePassword.addEventListener('click', function() {
                // Toggle password visibility
                const isPassword = passwordField.type === 'password';
                passwordField.type = isPassword ? 'text' : 'password';
                
                // Toggle eye icon
                eyeIcon.className = isPassword ? 'fas fa-eye-slash' : 'fas fa-eye';
                
                // Optional: Change button color when showing password
                togglePassword.style.color = isPassword ? '#0d6efd' : '#6c757d';
                
                // Keep focus on password field
                passwordField.focus();
            });
        }
    });

    // Search functionality
    const searchBox = document.getElementById('searchBox');
    if (searchBox) {
        searchBox.addEventListener('input', function() {
            filterLogs();
        });
    }

    // Filter functionality
    let activeFilter = 'ALL';
    const filterButtons = document.querySelectorAll('.filter-badge');
    
    filterButtons.forEach(button => {
        button.addEventListener('click', function() {
            filterButtons.forEach(btn => btn.classList.remove('active'));
            this.classList.add('active');
            activeFilter = this.dataset.filter;
            filterLogs();
        });
    });

    function filterLogs() {
        const keyword = searchBox ? searchBox.value.toLowerCase() : '';
        const entries = document.querySelectorAll('.log-entry');
        let visibleCount = 0;
        
        entries.forEach(entry => {
            const text = entry.textContent.toLowerCase();
            const type = entry.dataset.type;
            
            const matchesSearch = text.includes(keyword);
            const matchesFilter = activeFilter === 'ALL' || type === activeFilter;
            
            if (matchesSearch && matchesFilter) {
                entry.style.display = '';
                visibleCount++;
            } else {
                entry.style.display = 'none';
            }
        });
        
        // Show/hide empty state
        const logContainer = document.getElementById('logEntries');
        const emptyState = logContainer.querySelector('.empty-state');
        
        if (visibleCount === 0 && !emptyState) {
            logContainer.innerHTML = '<div class="empty-state"><i class="fas fa-search"></i><h4>No matching logs</h4><p>Try adjusting your search or filter.</p></div>';
        }
    }

    // Auto-refresh capability (optional - uncomment to enable)
    // setInterval(function() {
    //     location.reload();
    // }, 30000); // Refresh every 30 seconds
</script>

</body>
</html>