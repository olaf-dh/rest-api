<?php

use App\Kernel;

require_once dirname(__DIR__).'/vendor/autoload_runtime.php';

return function (array $context) {
    if (!isset($context['APP_ENV']) || !is_scalar($context['APP_ENV'])) {
        throw new \RuntimeException('Missing or invalid APP_ENV.');
    }

    $appEnv = (string) $context['APP_ENV'];
    $appDebug = isset($context['APP_DEBUG']) && (bool)$context['APP_DEBUG'];

    return new Kernel($appEnv, $appDebug);
};
