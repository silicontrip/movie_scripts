<?php
$aContext = array(
    'http' => array(
        'proxy' => 'tcp://210.15.240.205:3128',
        'request_fulluri' => true,
    ),
);
$cxContext = stream_context_create($aContext);
?>
