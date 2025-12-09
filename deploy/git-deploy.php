<?php
// =============================================================
//   MUZAKSFOOD — Laravel Auto Deployment Script
//   Path: /home/muzaasqf/app/deploy/git-deploy.php
// =============================================================

// CONFIGURATION
$config = [
    'secret' => '2026muzaksFoodSuperSecretToken',
    'repo_path' => '/home/muzaasqf/app',
    'branch' => 'main',
    'php_path' => '/usr/local/bin/php',
    'log_file' => __DIR__ . '/deploy-log.txt',
    'max_log_size' => 5 * 1024 * 1024, // 5MB
    'allowed_ips' => [], // Recommended: GitHub webhook IPs for extra security

    'post_deploy_commands' => [
        // Laravel optimization commands
        '{{php}} artisan optimize',
        '{{php}} artisan config:clear',
        '{{php}} artisan config:cache',
        '{{php}} artisan route:cache',
        '{{php}} artisan view:cache',

        // Permissions
        'chmod -R 775 storage bootstrap/cache',

        // Optional: Uncomment if you want auto migrations
        '{{php}} artisan migrate --force',
    ]
];


// =============================================================
// UTILITY FUNCTIONS
// =============================================================
function logDeploy($message, $type = 'INFO')
{
    global $config;
    $timestamp = date('Y-m-d H:i:s');
    $entry = "[$timestamp] [$type] $message\n";

    if (file_exists($config['log_file']) && filesize($config['log_file']) > $config['max_log_size']) {
        rename($config['log_file'], $config['log_file'] . '.' . time() . '.old');
    }

    file_put_contents($config['log_file'], $entry, FILE_APPEND);
}

function respondError($code, $message)
{
    http_response_code($code);
    logDeploy($message, 'ERROR');
    exit(json_encode(['error' => $message, 'timestamp' => time()]));
}


// =============================================================
// 1. SECURITY CHECKS
// =============================================================

// IP whitelist (optional)
if (!empty($config['allowed_ips'])) {
    $clientIP = $_SERVER['REMOTE_ADDR'] ?? '';
    if (!in_array($clientIP, $config['allowed_ips'])) {
        respondError(403, "Forbidden: IP $clientIP not allowed");
    }
}

// Request method must be POST
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    respondError(405, 'Method Not Allowed: Only POST requests accepted');
}

// Retrieve payload
$payload = file_get_contents('php://input');
$signature = $_SERVER['HTTP_X_HUB_SIGNATURE_256'] ?? '';

// Verify GitHub signature
$expectedSig = 'sha256=' . hash_hmac('sha256', $payload, $config['secret']);

if (!hash_equals($expectedSig, $signature)) {
    respondError(403, 'Invalid signature — webhook authentication failed.');
}


// Decode JSON
$data = json_decode($payload, true);
if (!$data) {
    respondError(400, 'Invalid JSON payload');
}


// =============================================================
// 2. EVENT & BRANCH CHECKS
// =============================================================
$event = $_SERVER['HTTP_X_GITHUB_EVENT'] ?? '';
$branch = basename($data['ref'] ?? '');

logDeploy("Webhook received: Event=$event, Branch=$branch");

// Only allow push to the configured branch
if ($event !== 'push') {
    exit(json_encode(['status' => 'ignored', 'reason' => 'Not a push event']));
}

if ($branch !== $config['branch']) {
    exit(json_encode(['status' => 'ignored', 'reason' => "Branch mismatch ($branch)"]));
}


// =============================================================
// 3. BEGIN DEPLOYMENT
// =============================================================
logDeploy("=== Starting Deployment ===");

if (!chdir($config['repo_path'])) {
    respondError(500, "Could not change directory to repo path");
}

// Fetch latest code and reset to remote state
$fetchCmd = "git fetch origin {$config['branch']} 2>&1";
logDeploy("Running: $fetchCmd");

$output = shell_exec($fetchCmd);
logDeploy("Git Fetch Output:\n$output");

$resetCmd = "git reset --hard origin/{$config['branch']} 2>&1";
logDeploy("Running: $resetCmd");

$output .= shell_exec($resetCmd);
logDeploy("Git Reset Output:\n$output");

// Detect Git pull failure
if (stripos($output, 'fatal') !== false || stripos($output, 'error') !== false) {
    respondError(500, "Git pull failed");
}


// =============================================================
// 4. RUN POST-DEPLOY COMMANDS (Laravel)
// =============================================================
logDeploy("=== Running Laravel Post-Deploy Commands ===");

foreach ($config['post_deploy_commands'] as $cmd) {
    $cmd = str_replace('{{php}}', $config['php_path'], $cmd);
    logDeploy("Executing: $cmd");

    $cmdOutput = shell_exec($cmd . ' 2>&1');
    logDeploy("Output:\n$cmdOutput");
}


// =============================================================
// 5. SUCCESS RESPONSE
// =============================================================
logDeploy("=== Deployment Completed Successfully ===", 'SUCCESS');

echo json_encode([
    'status' => 'success',
    'message' => 'Laravel deployment completed successfully',
    'branch' => $branch,
    'timestamp' => time()
]);
?>
