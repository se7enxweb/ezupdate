<?php
/**
 * @package eZUpdate
 * @author  7x <info@se7enx.com>
 * @date    2 Nov 2024
 **/

/**
 * Convert ANSI color codes to HTML with CSS styling
 * 
 * @param string $text Text with ANSI codes
 * @return string HTML formatted text
 */
function ansiToHtml($text) {
    // ANSI color map to CSS colors
    $ansiColors = array(
        '0'  => '',                                          // Reset (close any open span)
        '1'  => 'font-weight:bold',                         // Bold
        '30' => 'color:#000',                               // Black
        '31' => 'color:#c00',                               // Red
        '32' => 'color:#0a0',                               // Green
        '33' => 'color:#a50',                               // Yellow
        '34' => 'color:#00a',                               // Blue
        '35' => 'color:#a0a',                               // Magenta
        '36' => 'color:#0aa',                               // Cyan
        '37' => 'color:#aaa',                               // White
        '90' => 'color:#555',                               // Bright Black (Gray)
        '91' => 'color:#f55',                               // Bright Red
        '92' => 'color:#5f5',                               // Bright Green
        '93' => 'color:#ff5',                               // Bright Yellow
        '94' => 'color:#55f',                               // Bright Blue
        '95' => 'color:#f5f',                               // Bright Magenta
        '96' => 'color:#5ff',                               // Bright Cyan
        '97' => 'color:#fff',                               // Bright White
    );
    
    $currentStyles = array();
    $result = '';
    $inSpan = false;
    
    // Match ANSI escape codes: ESC[XXm where ESC can be \033 or \e or just missing
    // The regex handles: \033[31m, \e[31m, [31m (when ESC is stripped), or ESC[31m as literal text
    $text = preg_replace_callback(
        '/(?:\033\[|\\e\[|\[)(\d+(?:;\d+)*)m/',
        function($matches) use ($ansiColors, &$currentStyles, &$inSpan) {
            $codes = explode(';', $matches[1]);
            $html = '';
            
            foreach ($codes as $code) {
                if ($code === '0' || $code === '') {
                    // Reset - close span if open
                    if ($inSpan) {
                        $html .= '</span>';
                        $inSpan = false;
                    }
                    $currentStyles = array();
                } elseif (isset($ansiColors[$code])) {
                    // Close previous span if open
                    if ($inSpan) {
                        $html .= '</span>';
                    }
                    // Add or update style
                    $styleType = (strpos($ansiColors[$code], 'font-weight') !== false) ? 'font-weight' : 'color';
                    $currentStyles[$styleType] = $ansiColors[$code];
                    // Open new span with current styles
                    $html .= '<span style="' . implode(';', $currentStyles) . '">';
                    $inSpan = true;
                }
            }
            
            return $html;
        },
        $text
    );
    
    // Close any remaining open span
    if ($inSpan) {
        $text .= '</span>';
    }
    
    // Now escape HTML entities in the text content (but not our span tags)
    $text = preg_replace_callback(
        '/(<span[^>]*>)|(<\/span>)|([^<]+)/',
        function($matches) {
            if (!empty($matches[1]) || !empty($matches[2])) {
                // It's a tag, keep as-is
                return $matches[0];
            } else {
                // It's text content, escape it
                return htmlspecialchars($matches[3], ENT_QUOTES, 'UTF-8');
            }
        },
        $text
    );
    
    return $text;
}

$http    = eZHTTPTool::instance();
$module  = $Params['Module'];
$composer     = eZUpdateManager::getInstance();
$error   = null;
$message = null;
$output  = null;

if( $module->isCurrentAction( 'CheckoutUpdateComposerPackage' ) ) {
        $rawOutput = $composer->updatePackages();
        $output = ansiToHtml($rawOutput);
}

$tpl = eZTemplate::factory();
$tpl->setVariable( 'composer_manager', $composer );
$tpl->setVariable( 'error', $error );
$tpl->setVariable( 'message', $message );
$tpl->setVariable( 'output',  $output );

$Result = array();
$Result['content'] = $tpl->fetch( 'design:ezupdate/dashboard.tpl' );
$Result['path']    = array(
	array(
		'text' => ezpI18n::tr( 'extension/ezupdate', 'Update' ),
		'url'  => false
	)
);