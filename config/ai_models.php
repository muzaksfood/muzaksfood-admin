<?php

/**
 * AI Provider Models Configuration
 * 
 * Defines all available models for each AI provider
 * Add new models as they become available
 */

return [
    'OpenAI' => [
        'default' => 'gpt-4o',
        'models' => [
            'gpt-4o' => 'GPT-4o (Most capable, multimodal)',
            'gpt-4-turbo' => 'GPT-4 Turbo',
            'gpt-3.5-turbo' => 'GPT-3.5 Turbo (Fast, economical)',
        ]
    ],
    'Gemini' => [
        'default' => 'gemini-2.5-flash',
        'models' => [
            'gemini-3-pro-preview' => 'Gemini 3 Pro Preview (Latest, most capable)',
            'gemini-2.5-flash' => 'Gemini 2.5 Flash (Balanced, recommended)',
            'gemini-2.5-flash-lite' => 'Gemini 2.5 Flash-Lite (Fastest, economical)',
            'gemini-2.5-pro' => 'Gemini 2.5 Pro (Advanced reasoning)',
            'gemini-2.0-flash' => 'Gemini 2.0 Flash',
        ]
    ],
    'DeepSeek' => [
        'default' => 'deepseek-chat',
        'models' => [
            'deepseek-chat' => 'DeepSeek Chat (Standard)',
            'deepseek-reasoner' => 'DeepSeek Reasoner (Advanced reasoning)',
        ],
        'openrouter_models' => [
            'deepseek/deepseek-chat' => 'DeepSeek Chat (via OpenRouter)',
            'deepseek/deepseek-reasoner' => 'DeepSeek Reasoner (via OpenRouter)',
        ]
    ],
    'Claude' => [
        'default' => 'claude-3-5-sonnet-20241022',
        'models' => [
            'claude-3-5-sonnet-20241022' => 'Claude 3.5 Sonnet (Recommended)',
            'claude-3-5-haiku-20241022' => 'Claude 3.5 Haiku (Fast, economical)',
            'claude-3-opus-20250219' => 'Claude 3 Opus (Most capable)',
        ]
    ],
    'Grok' => [
        'default' => 'grok-beta',
        'models' => [
            'grok-beta' => 'Grok Beta (Experimental)',
            'grok-vision-beta' => 'Grok Vision Beta (Multimodal)',
        ]
    ],
];
