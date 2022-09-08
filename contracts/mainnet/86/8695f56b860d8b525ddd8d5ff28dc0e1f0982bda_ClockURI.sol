// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.13;

import './base64.sol';


contract ClockURI{


    bytes[5] private _svgComponents;
    string[] private _uriComponents;

    mapping(string => string) _colorNames;
    mapping(string => string) _opacitiesNames;
    mapping(string => string) _clockOutlinesNames;
    mapping(string => string) _clockFillsNames;
    mapping(string => string) _screenColorsNames;
    mapping(string => string) _ledColorsNames;
    mapping(string => string) _shadowNames;
    mapping(string => string) _shadowValues;

    string [4] _shadows;

     constructor () {
        _uriComponents = [
            'data:application/json;utf8,{"name":"',
            '", "description":"',
            '", "created_by":"Smartcontrart", "image":"data:image/svg+xml;base64,',
            '", "attributes":[',
            ']}'];

        _colorNames['ffd097'] ='Orange'; 
        _colorNames['f8a7a7'] ='Pink'; 
        _colorNames['c3d5fc'] ='Blue'; 
        _colorNames['a0e3a1'] ='Green'; 
        _colorNames['f0eb5b'] = 'Yellow';
        _colorNames['Yellow'] = 'Grey';

        _opacitiesNames['0'] = 'Indoors';
        _opacitiesNames['3'] = 'Cloudy';
        _opacitiesNames['6'] = 'Sunny';

        _clockOutlinesNames['fff'] = 'White';
        _clockOutlinesNames['000'] = 'Black';

        _clockFillsNames['752125'] = 'Brown';
        _clockFillsNames['c90000'] = 'Red';
        _clockFillsNames['00a331'] = 'Green';
        _clockFillsNames['7202b3'] = 'Purple';

        _screenColorsNames['cccccc'] = 'Grey';
        _screenColorsNames['fff'] = 'White';
        _screenColorsNames['1e1e1e'] = 'Black';

        _ledColorsNames['ff000c'] = 'Red';
        _ledColorsNames['008700'] = 'Green';
        _ledColorsNames['0074b8'] = 'Blue';
        _ledColorsNames['ffa200'] = 'Orange';
        
        _shadowValues['0'] = '<polygon class="cls-2" points="873.8 653.64 206.49 426.04 -282.52 915.05 164.93 1362.51 873.8 653.64"/>';
        _shadowValues['1'] = '<polygon class="cls-2" points="206.17 426.36 873.48 653.96 1362.5 164.95 915.04 -282.51 206.17 426.36"/>';
        _shadowValues['2'] = '<polygon class="cls-2" points="873.81 426.35 206.51 653.95 -282.51 164.93 164.95 -282.52 873.81 426.35"/>';
        _shadowValues['3'] = '<polygon class="cls-2" points="206.19 653.62 873.49 426.03 1362.51 915.04 915.05 1362.5 206.19 653.62"/>';

        _shadowNames['0'] = 'Dawn';
        _shadowNames['1'] = 'Afternoon';
        _shadowNames['2'] = 'Morning';
        _shadowNames['3'] = 'Dusk';
    }
    
    function getSVGPart1(
        string calldata wallColor, 
        string calldata opacity,
        string calldata shadow
    ) internal view returns(bytes memory svgPart1) {
        return (
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1080 1080" width="1080" height="1080"> <defs> <style> .cls-8{fill:#fff;font-family:Helvetica;font-size:22.76px} .cls-9{fill:#000;font-family:Verdana;font-size:80px} .cls-2{opacity:.',
                opacity,
                ';}</style> </defs> <path style="fill:#',
                wallColor,
                '" id="background" d="M0 0h1080v1080H0z"/> <g>',
                _shadowValues[shadow]
            )
        );
    }

    function getSVGPart2(        
        string calldata clockFill, 
        string calldata clockFrame, 
        string calldata clockScreen
    ) internal view returns(bytes memory svgPart2){
        return(
            abi.encodePacked(
                '<path x="203" y="422" width="673" height="236" rx="31" ry="31" style="fill:#',
                clockFill,
                '" d="M234 421.82H845.55A31.14 31.14 0 0 1 877 452.96V627.05A31.14 31 0 0 1 845.55 658.19H234.46A31.14 31.14 0 0 1 203.32 627.05V452.96A31.14 31.14 0 0 1 234.46 421.82z"/> <path x="203" y="423" width="674" height="235" rx="26" ry="26" style="stroke-miterlimit:10;fill:none;stroke:#',
                clockFrame,
                ';stroke-width:8.44px" d="M229.48 422.55H850.51A26.39 26.39 0 0 1 876.9 448.94V631.06A26.39 26.39 0 0 1 850.51 657.45H229.48A26.39 26.39 0 0 1 203.09 631.06V448.94A26.39 26.39 0 0 1 229.48 422.55z"/> <path x="250" y="460" width="579" height="127" rx="15" ry="15" style="fill:#',
                clockScreen,
                '" d="M265.54 459.66H814.47A15.17 15.17 0 0 1 829.64 474.83V571.7A15.17 15.17 0 0 1 814.47 586.87H265.54A15.17 15.17 0 0 1 250.37 571.7V474.83A15.17 15.17 0 0 1 265.54 459.66z"/> <text transform="translate(285 555)"> <tspan class="cls-9" style="fill:#',
                keccak256(bytes(_screenColorsNames[clockScreen])) == keccak256('Black')  ? 'a4be44' : '000',
                '" x="0" y="0">'
            )
        );
    }

    function getSVGPart3(        
        string calldata value, 
        string calldata mode,
        string calldata clockScreen,
        string calldata ledColor,
        uint timer
    ) internal view returns(bytes memory svgPart3){
        return(
            abi.encodePacked(
                value,
                keccak256(bytes(mode)) == keccak256('Timer') && block.number >= timer ? abi.encodePacked('<animate attributeName="fill" values="#', keccak256(bytes(_screenColorsNames[clockScreen])) == keccak256('Black')  ? 'a4be44' : '000',';transparent" begin="0s" dur="2s" calcMode="discrete" repeatCount="indefinite"/>') :abi.encodePacked(''),
                '</tspan> </text> <text class="cls-8" transform="translate(278 626)"> <tspan x="0" y="0">Clock</tspan> </text> <circle cx="259" cy="618" r="8.5" fill="#',
                keccak256(bytes(mode)) == keccak256('Clock') ? ledColor : '000'
            )
        );
    }

    function getSVGPart4(        
        string calldata mode,
        string calldata ledColor
    ) internal pure returns(bytes memory svgPart4){
        return(
            abi.encodePacked(
                '" stroke="#dafff4" stroke-width="1.5px"/> <text class="cls-8" transform="translate(425 626)"> <tspan x="0" y="0">Chrono</tspan> </text> <circle cx="408" cy="618" r="8.5" fill="#',
                keccak256(bytes(mode)) == keccak256('Chrono') ? ledColor : '000',
                '" stroke="#dafff4" stroke-width="1.5px"/> <text class="cls-8" transform="translate(590 626)"> <tspan x="0" y="0">Timer</tspan> </text> <circle cx="570" cy="618" r="8.5" fill="#',
                keccak256(bytes(mode)) == keccak256('Timer') ? ledColor : '000'
            )
        );
    }

    function getSVGPart5(        
        string calldata mode,
        string calldata ledColor,
        uint alarm
    ) internal view returns(bytes memory svgPart5){
        return(
            abi.encodePacked(
                '" stroke="#dafff4" stroke-width="1.5px"/> <text class="cls-8" transform="translate(758 626)"> <tspan x="0" y="0">Alarm</tspan> </text> <circle cx="739" cy="618" r="8.5" stroke="#dafff4" stroke-width="1.5px"> <animate attributeName="fill" values="',
                keccak256(bytes(mode)) == keccak256('Alarm') ? block.number >= alarm ? string(abi.encodePacked('#',ledColor,';#000')) : string(abi.encodePacked('#', ledColor,';#', ledColor)) : '#000;#000',
                '" begin="0s" dur="2s" calcMode="discrete" repeatCount="indefinite"/> </circle> </g> </svg>  '
            )
        );
    }

    function buildSVG(
        string [9] calldata clockCustomization,
        uint timer,
        uint alarm
    ) internal view returns(string memory svg){
        svg = assembleSVGComponents(
            getSVGPart1(clockCustomization[2], clockCustomization[3], clockCustomization[8]),
            getSVGPart2(clockCustomization[4], clockCustomization[5], clockCustomization[6]),
            getSVGPart3(clockCustomization[0], clockCustomization[1], clockCustomization[6], clockCustomization[7], timer),
            getSVGPart4(clockCustomization[1], clockCustomization[7]),
            getSVGPart5(clockCustomization[1], clockCustomization[7], alarm)
        );
        return svg;
    }
    
    function assembleSVGComponents(
        bytes memory part1,
        bytes memory part2,
        bytes memory part3,
        bytes memory part4,
        bytes memory part5
    ) internal pure returns(string memory svg){
        return(
            Base64.encode(
                bytes(
                   abi.encodePacked(
                        part1,
                        part2,
                        part3,
                        part4,
                        part5
                   )
                )
            )
        );
    }

    function buildURI( 
        string [9] calldata clockCustomization,
        uint timer,
        uint alarm
    )public view returns (string memory){

        bytes memory byteString = abi.encodePacked(
            abi.encodePacked(_uriComponents[0], "Block Clock"),
            abi.encodePacked(_uriComponents[1], "Ethereum doesn't know time, it knows blocks. This clock represents that. It has 4 modes: clock, chronograph, timer and alarm. A fully onchain project by SmartContrart."),
            abi.encodePacked(_uriComponents[2], buildSVG(
                clockCustomization,
                timer,
                alarm)),
            abi.encodePacked(_uriComponents[3], 
                '{"trait_type": "Wallpaper", "value":"', _colorNames[clockCustomization[2]], '"},',
                '{"trait_type": "Daytime", "value":"', _opacitiesNames[clockCustomization[3]], '"},',
                '{"trait_type": "Frame", "value":"', _clockOutlinesNames[clockCustomization[5]], '"},',
                '{"trait_type": "Clock color", "value":"', _clockFillsNames[clockCustomization[4]], '"},',
                '{"trait_type": "Screen color", "value":"', _screenColorsNames[clockCustomization[6]], '"},',
                '{"trait_type": "Shadow", "value":"', _shadowNames[clockCustomization[8]], '"},',
                '{"trait_type": "LED color", "value":"', _ledColorsNames[clockCustomization[7]], '"}'
            ),
            abi.encodePacked(_uriComponents[4])
        );
        return string(byteString);
    }

}