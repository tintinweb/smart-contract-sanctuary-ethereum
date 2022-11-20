pragma solidity ^0.8.0;
//SPDX-License-Identifier: MIT

import "hardhat/console.sol";

// GET LISTED ON OPENSEA: https://testnets.opensea.io/get-listed/step-two

// Defining Library
library NeckLibrary {
    function GetNeck(uint256 index) public pure returns (string memory) {
        string memory neck;

        if (index == 1) {
            neck = string(
                abi.encodePacked(
                    "<defs>",
                    "    <style>",
                    "    .cls-neck-neck-7 {",
                    "        stroke: #000;",
                    "        stroke-miterlimit: 10;",
                    "        stroke-width: 4.33px;",
                    "    }"
                )
            );
            neck = string(
                abi.encodePacked(
                    neck,
                    "    .cls-neck-neck-7 {",
                    "        fill: #8cc63f;",
                    "    }",
                    "    </style>",
                    "</defs>"
                )
            );
            neck = string(
                abi.encodePacked(
                    neck,
                    "<path",
                    '    class="cls-neck-neck-7"',
                    '    d="M343.21,288.6s69.5-6.39,85.29-19.86c8.49-7.26,14.37,10.71,5.05,16.4-12.65,7.74-54.6,20.8-83.71,19.83C337.13,298.94,343.21,288.6,343.21,288.6Z"',
                    "/>",
                    "<path",
                    '    class="cls-neck-neck-7"',
                    '    d="M316.57,291.28S297.07,270,289.21,269.6s-7.66,13-7.16,19.35-6.91,13.85-2.41,18.78,25.85,2.72,36.44-5.46S316.57,291.28,316.57,291.28Z"',
                    "/>"
                )
            );
            neck = string(
                abi.encodePacked(
                    neck,
                    "<path",
                    '    class="cls-neck-neck-7"',
                    '    d="M333.88,291.26a13.93,13.93,0,0,0-13.07-6.87c-9.46.36-15.27,7.18-12.48,15.18s9.11,7.48,14.61,7.73S332.82,297.51,333.88,291.26Z"',
                    "/>"
                )
            );
            neck = string(
                abi.encodePacked(
                    neck,
                    "<path",
                    '    class="cls-neck-neck-7"',
                    '    d="M331.63,288.8s39.53-21.84,44.64-12.95-3.12,17.17-2.58,22.7,7.9,16.88.66,20.49-45.74-15.42-45.74-15.42S325.92,293.27,331.63,288.8Z"',
                    "/>"
                )
            );
        } else if (index == 2) {
            neck = string(
                abi.encodePacked(
                    "<defs>",
                    "    <style>",
                    "        .cls-neck-neck-11,",
                    "        .cls-neck-neck-14 {",
                    "            stroke: #000;",
                    "            stroke-miterlimit: 10;",
                    "            stroke-width: 4.33px;",
                    "        }"
                )
            );
            neck = string(
                abi.encodePacked(
                    neck,
                    "        .cls-neck-neck-11 {",
                    "            fill: #1a1a1a;",
                    "        }",
                    "        .cls-neck-neck-14 {",
                    "            fill: #cacaca;",
                    "        }",
                    "    </style>",
                    "</defs>"
                )
            );
            neck = string(
                abi.encodePacked(
                    neck,
                    "<path",
                    '    class="cls-neck-neck-11"',
                    '    d="M439.83,254.87c-19.72,2.55-38.64,3.95-55.74,4.64-10.81,8.06-20.66,8.33-30.5,5.15a43.34,43.34,0,0,1-9.46-4.7l-.84,0c-1.62,4.75-4.8,8.42-7.19,9.38-12.78,5.11-32.46-.63-33-.83-1.2,5-2.47,9.71-3.67,17.3,60.79,17.81,143.07-.53,143.07-.53S443,265.87,439.83,254.87Z"',
                    "/>",
                    "<path",
                    '    class="cls-neck-neck-14"',
                    '    d="M441.76,261l22.36,5.94L442.8,277.75s-6.63-1.75-7.33-8S441.76,261,441.76,261Z"',
                    "/>"
                )
            );
            neck = string(
                abi.encodePacked(
                    neck,
                    "<path",
                    '    class="cls-neck-neck-14"',
                    '    d="M408.22,265.17l15.72,7.34-14.67,9.43s-6.64-1.74-7.34-8S408.22,265.17,408.22,265.17Z"',
                    "/>",
                    "<path",
                    '    class="cls-neck-neck-14"',
                    '    d="M331.66,266.92l-15.72,7.34,14.67,9.43s6.64-1.75,7.34-8S331.66,266.92,331.66,266.92Z"',
                    "/>"
                )
            );
            neck = string(
                abi.encodePacked(
                    neck,
                    "<path",
                    '    class="cls-neck-neck-14"',
                    '    d="M291.89,262.53l-12.59,3.34,21.31,10.83s6.44-1.7,7.29-7.77a44.38,44.38,0,0,1-4.76-1.17A38.19,38.19,0,0,1,291.89,262.53Z"',
                    "/>",
                    '<circle class="cls-neck-neck-14" cx="370.49" cy="276.35" r="8.23" />'
                )
            );
        } else if (index == 3) {
            neck = string(
                abi.encodePacked(
                    "<defs>",
                    "    <style>",
                    "        .cls-neck-neck-14,",
                    "        .cls-neck-neck-15 {",
                    "            stroke: #000;",
                    "            stroke-miterlimit: 10;",
                    "        }"
                )
            );
            neck = string(
                abi.encodePacked(
                    neck,
                    "        .cls-neck-neck-14,",
                    "        .cls-neck-neck-15 {",
                    "            stroke-width: 4.33px;",
                    "        }",
                    "        .cls-neck-neck-14 {",
                    "            fill: #f0f0f0;",
                    "        }",
                    "    </style>",
                    "</defs>"
                )
            );
            neck = string(
                abi.encodePacked(
                    neck,
                    "<path",
                    '    class="cls-neck-neck-14"',
                    '    d="M321.54,280s-15.19,9.43,4.72,13.63a125,125,0,0,0,15.32,2.17,67.88,67.88,0,0,0-1.74-16.19C328.81,280.12,321.54,280,321.54,280Z"',
                    "/>",
                    "<path",
                    '    class="cls-neck-neck-15"',
                    '    d="M360.87,278.2c-7.76.73-15,1.17-21,1.43a67.88,67.88,0,0,1,1.74,16.19,177.48,177.48,0,0,0,19.88.45A41.34,41.34,0,0,0,360.87,278.2Z"',
                    "/>"
                )
            );
            neck = string(
                abi.encodePacked(
                    neck,
                    "<path",
                    '    class="cls-neck-neck-14"',
                    '    d="M385.46,275c-8.37,1.43-16.76,2.45-24.59,3.19a41.34,41.34,0,0,1,.59,18.07,247.3,247.3,0,0,0,25.78-2.2C388.41,287.54,388.34,280.67,385.46,275Z"',
                    "/>",
                    "<path",
                    '    class="cls-neck-neck-15"',
                    '    d="M407.14,270.19A211.24,211.24,0,0,1,385.46,275c2.88,5.66,3,12.53,1.78,19.06,7.82-1.06,15.18-2.4,21.72-3.81C409.05,283.4,409.25,276.59,407.14,270.19Z"',
                    "/>"
                )
            );
            neck = string(
                abi.encodePacked(
                    neck,
                    "<path",
                    '    class="cls-neck-neck-15"',
                    '    d="M433.17,259.06a62.81,62.81,0,0,1-5.95,3.47,63.08,63.08,0,0,1,.54,22.83c4.16-1.33,7-2.49,8-3.24C441.55,277.93,441.55,253.82,433.17,259.06Z"',
                    "/>",
                    "<path",
                    '    class="cls-neck-neck-14"',
                    '    d="M427.22,262.53a109.42,109.42,0,0,1-20.08,7.66c2.11,6.4,1.91,13.21,1.82,20.07,7.61-1.65,14.07-3.39,18.8-4.9A63.08,63.08,0,0,0,427.22,262.53Z"',
                    "/>"
                )
            );
            neck = string(
                abi.encodePacked(
                    neck,
                    "<path",
                    '    class="cls-neck-neck-15"',
                    '    d="M296.39,287.05c-3.86,7.51-6.54,16-9.14,23.78,3.1,2.57,7.9,3.23,16.48,3.25,1.16,0,9-5,15.19-11.41l.24-.26C312.5,296.25,304.61,291.34,296.39,287.05Z"',
                    "/>",
                    "<path",
                    '    class="cls-neck-neck-14"',
                    '    d="M325.62,285.11c-3.08-5.92-9.52-11-15.85-14.17l-.14-.07c-5.76,4-9.93,9.73-13.24,16.18,8.22,4.29,16.11,9.2,22.77,15.36C324.41,296.88,328.34,290.35,325.62,285.11Z"',
                    "/>"
                )
            );
            neck = string(
                abi.encodePacked(
                    neck,
                    "<path",
                    '    class="cls-neck-neck-15"',
                    '    d="M309.63,270.87c-5.82-2.87-11.54-4.08-14.42-2.74-3.22,1.5-7.65,6.72-10.65,13.16,3.95,1.82,7.92,3.72,11.83,5.76C299.7,280.6,303.87,274.86,309.63,270.87Z"',
                    "/>",
                    "<path",
                    '    class="cls-neck-neck-14"',
                    '    d="M296.39,287.05c-3.91-2-7.88-3.94-11.83-5.76-.28.59-.54,1.18-.79,1.79-2.14,5.23-3.23,11.06-1.95,16.29,1.4,5.74,2.81,9.28,5.43,11.46C289.85,303,292.53,294.56,296.39,287.05Z"',
                    "/>"
                )
            );
            neck = string(
                abi.encodePacked(
                    neck,
                    "<path",
                    '    class="cls-neck-neck-15"',
                    '    d="M288.11,305.14l-5.57-3.85a153.57,153.57,0,0,0-20.39,14,39.47,39.47,0,0,1,8.72,6.35A182.68,182.68,0,0,1,288.11,305.14Z"',
                    "/>",
                    "<path",
                    '    class="cls-neck-neck-14"',
                    '    d="M248.67,351.74a169.15,169.15,0,0,1,22.2-30.13,39.47,39.47,0,0,0-8.72-6.35c-9.39,7.52-20.3,17.88-28.84,30.63A51.9,51.9,0,0,1,248.67,351.74Z"',
                    "/>"
                )
            );
            neck = string(
                abi.encodePacked(
                    neck,
                    "<path",
                    '    class="cls-neck-neck-15"',
                    '    d="M205.23,429c-15,13.83-26.08,20.72-26.08,20.72s-12.27,34.48-9.64,35.68c.11.05,3.51-.39,3.75-.33,21.24-9.85,43.38-21.56,54-42.95a183,183,0,0,0-20.54-14.66C206.28,428,205.79,428.47,205.23,429Z"',
                    "/>",
                    "<path",
                    '    class="cls-neck-neck-14"',
                    '    d="M231,432.65c3.47-11.88,3-25,3.62-37.36a110.72,110.72,0,0,1-17.55-9.24c-3.87,19.63-1.09,31.46-10.35,41.39A183,183,0,0,1,227.3,442.1,59.4,59.4,0,0,0,231,432.65Z"',
                    "/>"
                )
            );
            neck = string(
                abi.encodePacked(
                    neck,
                    "<path",
                    '    class="cls-neck-neck-15"',
                    '    d="M234.66,395.29c.44-8.77,1.43-17.17,4.76-24.51a149.09,149.09,0,0,1,9.25-19,51.9,51.9,0,0,0-15.36-5.85,94.79,94.79,0,0,0-8.3,15,121.64,121.64,0,0,0-7.9,25.12A110.72,110.72,0,0,0,234.66,395.29Z"',
                    "/>",
                    "<path",
                    '    class="cls-neck-neck-14"',
                    '    d="M299.26,312.85l-11.15-7.71a182.68,182.68,0,0,0-17.24,16.47,41.49,41.49,0,0,1,9.34,13.63C290.35,322.79,299.26,312.85,299.26,312.85Z"',
                    "/>"
                )
            );
            neck = string(
                abi.encodePacked(
                    neck,
                    "<path",
                    '    class="cls-neck-neck-15"',
                    '    d="M280.21,335.24a41.49,41.49,0,0,0-9.34-13.63,169.15,169.15,0,0,0-22.2,30.13,119.09,119.09,0,0,1,12.7,8.38C266.83,352.09,273.76,343.16,280.21,335.24Z"',
                    "/>",
                    "<path",
                    '    class="cls-neck-neck-14"',
                    '    d="M250.11,402.75c-.63-11.18-.42-21.71,3.81-30.28a110.27,110.27,0,0,1,7.45-12.35,119.09,119.09,0,0,0-12.7-8.38,149.09,149.09,0,0,0-9.25,19c-3.33,7.34-4.32,15.74-4.76,24.51C239.94,397.64,245.21,400,250.11,402.75Z"',
                    "/>"
                )
            );
            neck = string(
                abi.encodePacked(
                    neck,
                    "<path",
                    '    class="cls-neck-neck-14"',
                    '    d="M173.26,485.05c5.7,1.32,46.54,4.55,46.54,4.55s14.64-10.31,24-26.94c-3.62-8-9.57-14.68-16.46-20.56C216.64,463.49,194.5,475.2,173.26,485.05Z"',
                    "/>",
                    "<path",
                    '    class="cls-neck-neck-15"',
                    '    d="M249.64,448.35c3.74-14.26,1.33-30.52.47-45.6-4.9-2.8-10.17-5.11-15.45-7.46-.62,12.37-.15,25.48-3.62,37.36a59.4,59.4,0,0,1-3.74,9.45c6.89,5.88,12.84,12.59,16.46,20.56A60.61,60.61,0,0,0,249.64,448.35Z"',
                    "/>"
                )
            );
        } else if (index == 4) {
            neck = string(
                abi.encodePacked(
                    "<defs>",
                    "    <style>",
                    "        .cls-neck-neck-13,",
                    "        .cls-neck-neck-15 {",
                    "            stroke: #000;",
                    "            stroke-miterlimit: 10;",
                    "        }"
                )
            );
            neck = string(
                abi.encodePacked(
                    neck,
                    "        .cls-neck-neck-13 {",
                    "            stroke-width: 4.33px;",
                    "        }",
                    "        .cls-neck-neck-14 {",
                    "            fill: #ff0;",
                    "        }"
                )
            );
            neck = string(
                abi.encodePacked(
                    neck,
                    "        .cls-neck-neck-12 {",
                    "            fill: url(#radial-gradient-neck);",
                    "        }",
                    "        .cls-neck-neck-13,",
                    "        .cls-neck-neck-15 {",
                    "            fill: none;",
                    "        }",
                    "        .cls-neck-neck-15 {",
                    "            stroke-width: 4px;",
                    "        }"
                )
            );
            neck = string(
                abi.encodePacked(
                    neck,
                    "    </style>",
                    "    <radialGradient",
                    '    id="radial-gradient-neck"',
                    '    cx="274.86"',
                    '    cy="345.03"',
                    '    r="27.38"',
                    '    gradientUnits="userSpaceOnUse"'
                )
            );
            neck = string(
                abi.encodePacked(
                    neck,
                    "    >",
                    '        <stop offset="0.22" stop-color="#ffffea" />',
                    '        <stop offset="0.24" stop-color="#f9feea" />',
                    '        <stop offset="0.27" stop-color="#e7fce9" />',
                    '        <stop offset="0.31" stop-color="#c9f7e7" />',
                    '        <stop offset="0.35" stop-color="#a0f2e4" />',
                    '        <stop offset="0.4" stop-color="#6aeae1" />',
                    '        <stop offset="0.45" stop-color="#2be1de" />',
                    '        <stop offset="0.48" stop-color="#00dbdb" />',
                    '        <stop offset="0.52" stop-color="#09d3dc" />',
                    '        <stop offset="0.59" stop-color="#21bee0" />',
                    '        <stop offset="0.67" stop-color="#499ce5" />',
                    '        <stop offset="0.78" stop-color="#806ded" />',
                    '        <stop offset="0.89" stop-color="#c532f7" />',
                    '        <stop offset="0.97" stop-color="#f0f" />',
                    "    </radialGradient>",
                    "</defs>"
                )
            );
            neck = string(
                abi.encodePacked(
                    neck,
                    '<circle class="cls-neck-neck-12" cx="274.86" cy="345.03" r="27.38" />',
                    '<circle class="cls-neck-neck-13" cx="274.86" cy="345.03" r="27.38" />',
                    '<ellipse class="cls-neck-neck-14" cx="274" cy="319.31" rx="14.62" ry="6.09" />',
                    "<path",
                    '    d="M274,315.21c7,0,12.62,1.84,12.62,4.1S281,323.4,274,323.4s-12.62-1.83-12.62-4.09,5.65-4.1,12.62-4.1m0-4c-8,0-16.62,2.13-16.62,8.1,0,3.91,4.36,8.09,16.62,8.09,8,0,16.62-2.12,16.62-8.09,0-3.91-4.36-8.1-16.62-8.1Z"',
                    "/>"
                )
            );
            neck = string(
                abi.encodePacked(
                    neck,
                    "<path",
                    '    class="cls-neck-neck-14"',
                    '    d="M274,319c-5.38,0-10.8-1.57-10.8-5.07s5.42-5.06,10.8-5.06,10.8,1.56,10.8,5.06S279.37,319,274,319Z"',
                    "/>"
                )
            );
            neck = string(
                abi.encodePacked(
                    neck,
                    "<path",
                    '    d="M274,310.89c4.86,0,8.8,1.37,8.8,3.06S278.86,317,274,317s-8.8-1.37-8.8-3.07,3.94-3.06,8.8-3.06m0-4c-7.9,0-12.8,2.71-12.8,7.06S266.1,321,274,321s12.8-2.71,12.8-7.07-4.91-7.06-12.8-7.06Z"',
                    "/>"
                )
            );
            neck = string(
                abi.encodePacked(
                    neck,
                    "<path",
                    '    class="cls-neck-neck-15"',
                    '    d="M433.78,277.51s11.36-7,21.8,0c16.35,10.89-24.48,27.08-31.6,28.33C381.66,313.29,360,294.49,328.8,289S275,308.75,275,308.75s-3.68-20.44,10.49-26.25c9.17-3.76,12.44-5,20.43-3.9"',
                    "/>"
                )
            );
        } else if (index == 5) {
            neck = string(
                abi.encodePacked(
                    "<defs>",
                    "    <style>",
                    "        .cls-neck-18 {",
                    "            stroke: #000;",
                    "            stroke-miterlimit: 10;",
                    "            stroke-width: 4.33px;",
                    "            fill: #754c24;",
                    "        }"
                )
            );
            neck = string(
                abi.encodePacked(
                    neck,
                    "        .cls-neck-17 {",
                    "            mix-blend-mode: multiply;",
                    "            fill: #bcbcbc;",
                    "        }",
                    "    </style>",
                    "</defs>",
                    "<path",
                    '    class="cls-neck-17"',
                    '    d="M290.28,360.75c.1-.17.73,11.63,4.12,18.91,7.65-2.62,15.7-6.78,20-13.28a132.94,132.94,0,0,0,2.18,20.71s37.87-13.9,41.95-31.06c3.63,8.54,7.9,16.89,7.9,16.89s23.43-36.51,21-49.58a127.79,127.79,0,0,1,9.26,10.35c7.63-5.18,19.85-30.31,17.8-45.77C397.44,294.09,296.27,359.3,290.28,360.75Z"',
                    "/>"
                )
            );
            neck = string(
                abi.encodePacked(
                    neck,
                    "<path",
                    '    class="cls-neck-18"',
                    '    d="M401.44,224.71a38.08,38.08,0,0,1-12,28.52c-22.89,21.79-47.13-4.09-47.13-4.09s.63,3.18-.46,9.72c.73,5.63-13.44,17.8-23.61,9.13-7.54,2.95-20.34-2.23-20.34-2.23s-14.71.55-21.25,19.62,12.19,37.34-2.73,57.75c-10.35,14.17-19.88,18.8-19.88,18.8s31.87-4.36,37.59-16.62C287.28,366.84,275,372.56,275,372.56s28.88-2.73,38.69-17.44a132.94,132.94,0,0,0,2.18,20.71s37.87-13.9,42-31.06c3.63,8.53,7.9,16.89,7.9,16.89s23.43-36.51,21-49.58A128.8,128.8,0,0,1,396,322.43C442.12,291.55,401.44,224.71,401.44,224.71Z"',
                    "/>"
                )
            );
            neck = string(
                abi.encodePacked(
                    neck,
                    "<path",
                    '    class="cls-neck-17"',
                    '    d="M295.55,285.38l.54,9.44L305,293s4,14.16,5.81,17.25c3.46-8,13.26-19.62,13.26-19.62s3.82,12.35,4.18,11.45,5.09-11.63,5.09-11.63Z"',
                    "/>",
                    "<path",
                    '    class="cls-neck-18"',
                    '    d="M332.78,288.65s-7.26,4.36-10.53,9.8a14.81,14.81,0,0,1-4-10.17,54.12,54.12,0,0,0-14.53,18.89c-5.08-11.26,0-23.25,0-23.25a16.84,16.84,0,0,0-9.81,4.73c-.36-6.54,3.45-13.63,3.45-13.63"',
                    "/>"
                )
            );
        } else if (index == 6) {
            neck = string(
                abi.encodePacked(
                    "<defs>",
                    "  <style>",
                    "    .cls-neck-26,",
                    "    .cls-neck-28,",
                    "    .cls-neck-29 {",
                    "      stroke: #000;",
                    "      stroke-miterlimit: 10;",
                    "    }"
                )
            );
            neck = string(
                abi.encodePacked(
                    neck,
                    "    .cls-neck-29 {",
                    "      stroke-width: 4.33px;",
                    "    }",
                    "    .cls-neck-26,",
                    "    .cls-neck-28 {",
                    "      fill: #ffbf40;",
                    "    }"
                )
            );
            neck = string(
                abi.encodePacked(
                    neck,
                    "    .cls-neck-14 {",
                    "      fill: #bde6ff;",
                    "    }",
                    "    .cls-neck-28 {",
                    "      stroke-width: 4px;",
                    "    }"
                )
            );
            neck = string(
                abi.encodePacked(
                    neck,
                    "    .cls-neck-24 {",
                    "      fill: #fff;",
                    "      opacity: 0.42;",
                    "    }",
                    "    .cls-neck-20 {",
                    "      fill: #fb8525;",
                    "    }"
                )
            );
            neck = string(
                abi.encodePacked(
                    neck,
                    "    .cls-neck-25 {",
                    "      opacity: 0.15;",
                    "    }",
                    "    .cls-neck-26 {",
                    "      stroke-width: 3.59px;",
                    "    }"
                )
            );
            neck = string(
                abi.encodePacked(
                    neck,
                    "    .cls-neck-27 {",
                    "      fill: #ffdb9c;",
                    "    }",
                    "    .cls-neck-29 {",
                    "      fill: #0071af;",
                    "    }"
                )
            );
            neck = string(
                abi.encodePacked(
                    neck,
                    "    .cls-neck-30 {",
                    "      fill: #76c4ff;",
                    "    }",
                    "  </style>",
                    "</defs>"
                )
            );
            neck = string(
                abi.encodePacked(
                    neck,
                    "<path",
                    '  class="cls-neck-24"',
                    '  d="M219.47,321.34a81.77,81.77,0,0,1-9.81-12.48l-5.27,5.27a83.09,83.09,0,0,0,9.23,13.07Z"',
                    "/>",
                    "<path",
                    '  class="cls-neck-25"',
                    '  d="M330.42,311.38c-1.92-4.13-13.2-6.7-15.45-4.89-6.64-8.68.71-26.1,4.46-35-27.13,3-10.48,42.37-17,55-2.89,34.17,32.61,31.43,30.6-2.39,20.17-6.64,39-37.37,101.95-45.62C383.63,260.47,332.84,317.36,330.42,311.38Z"',
                    "/>"
                )
            );
            neck = string(
                abi.encodePacked(
                    neck,
                    "<path",
                    '  class="cls-neck-26"',
                    '  d="M433.58,273.84c-80.37,8.81-91.81,53.57-119.87,46.75-18.29-4.45-24.61-27.29-6.36-51.92,2.18.44,5.09,1.76,5.82.36-4.64,11-14.35,32.51,3,38.14,19.06,6.19,23.7-28.88,115.79-40.59C434.4,267.94,435,271.48,433.58,273.84Z"',
                    "/>",
                    "<path",
                    '  class="cls-neck-27"',
                    '  d="M366.31,285.47c.69,3.63-.64,3.62.11,7.29a148,148,0,0,1,25.75-12c-1.53-2.51-1.6-1.11-3.27-3.55A180.2,180.2,0,0,0,366.31,285.47Z"',
                    "/>"
                )
            );
            neck = string(
                abi.encodePacked(
                    neck,
                    '<ellipse class="cls-neck-14" cx="309.62" cy="315.35" rx="2.84" ry="5.72" />',
                    "<path",
                    '  class="cls-neck-20"',
                    '  d="M325.52,308.81a59.42,59.42,0,0,0,7.26-3.82c2.18,6.72,2.36,9.27,2.36,9.27l-7.81,3.81Z"',
                    "/>"
                )
            );
            neck = string(
                abi.encodePacked(
                    neck,
                    "<ellipse",
                    '  class="cls-neck-28"',
                    '  cx="313.17"',
                    '  cy="324.06"',
                    '  rx="24.25"',
                    '  ry="13.62"',
                    '  transform="translate(-47.07 594.83) rotate(-82.91)"',
                    "/>"
                )
            );
            neck = string(
                abi.encodePacked(
                    neck,
                    "<path",
                    '  class="cls-neck-20"',
                    '  d="M299.93,333.64c1.31,7,4.83,12.12,9.51,12.71,6.93.86,13.8-8.44,15.33-20.78.1-.78.17-1.56.22-2.32C317.56,328.6,309,332.64,299.93,333.64Z"',
                    "/>"
                )
            );
            neck = string(
                abi.encodePacked(
                    neck,
                    "<ellipse",
                    '  class="cls-neck-29"',
                    '  cx="307.44"',
                    '  cy="323.79"',
                    '  rx="19.8"',
                    '  ry="11.12"',
                    '  transform="translate(-51.82 588.92) rotate(-82.91)"',
                    "/>"
                )
            );
            neck = string(
                abi.encodePacked(
                    neck,
                    "<ellipse",
                    '  class="cls-neck-30"',
                    '  cx="309.35"',
                    '  cy="318.37"',
                    '  rx="3.99"',
                    '  ry="8.51"',
                    '  transform="translate(-26.59 28.19) rotate(-5)"',
                    "/>"
                )
            );
        } else if (index == 7) {
            neck = string(
                abi.encodePacked(
                    "<defs>",
                    "  <style>",
                    "    .cls-neck-26,",
                    "    .cls-neck-27,",
                    "    .cls-neck-28,"
                )
            );
            neck = string(
                abi.encodePacked(
                    neck,
                    "    .cls-neck-29,",
                    "    .cls-neck-30,",
                    "    .cls-neck-31,",
                    "    .cls-neck-32 {",
                    "      stroke: #000;",
                    "      stroke-miterlimit: 10;"
                )
            );
            neck = string(
                abi.encodePacked(
                    neck,
                    "    }",
                    "    .cls-neck-26,",
                    "    .cls-neck-27,",
                    "    .cls-neck-28,",
                    "    .cls-neck-29,",
                    "    .cls-neck-30 {",
                    "      stroke-width: 3px;"
                )
            );
            neck = string(
                abi.encodePacked(
                    neck,
                    "    }",
                    "    .cls-neck-31 {",
                    "      fill: #ffdc83;",
                    "    }",
                    "    .cls-neck-33 {",
                    "      fill: #fff;"
                )
            );
            neck = string(
                abi.encodePacked(
                    neck,
                    "    }",
                    "    .cls-neck-26 {",
                    "      fill: url(#linear-gradient-2);",
                    "    }",
                    "    .cls-neck-27 {",
                    "      fill: url(#linear-gradient-3);",
                    "    }"
                )
            );
            neck = string(
                abi.encodePacked(
                    neck,
                    "    .cls-neck-28 {",
                    "      fill: url(#linear-gradient-4);",
                    "    }",
                    "    .cls-neck-29 {",
                    "      fill: url(#linear-gradient-5);",
                    "    }"
                )
            );
            neck = string(
                abi.encodePacked(
                    neck,
                    "    .cls-neck-30 {",
                    "      fill: url(#linear-gradient-6);",
                    "    }",
                    "    .cls-neck-31,",
                    "    .cls-neck-32 {",
                    "      stroke-width: 1.52px;",
                    "    }"
                )
            );
            neck = string(
                abi.encodePacked(
                    neck,
                    "    .cls-neck-32 {",
                    "      fill: url(#radial-gradient);",
                    "    }",
                    "    .cls-neck-33 {",
                    "      opacity: 0.49;",
                    "    }",
                    "  </style>"
                )
            );
            neck = string(
                abi.encodePacked(
                    neck,
                    "  <linearGradient",
                    '    id="linear-gradient-2"',
                    '    x1="454.37"',
                    '    y1="240.33"',
                    '    x2="452.56"',
                    '    y2="226.16"',
                    '    gradientUnits="userSpaceOnUse"',
                    "  >"
                )
            );
            neck = string(
                abi.encodePacked(
                    neck,
                    '    <stop offset="0" stop-color="#4f0e00" />',
                    '    <stop offset="0.79" stop-color="#9b0e00" />',
                    "  </linearGradient>",
                    "  <linearGradient"
                )
            );
            neck = string(
                abi.encodePacked(
                    neck,
                    '    id="linear-gradient-3"',
                    '    x1="308.8"',
                    '    y1="270.02"',
                    '    x2="470.54"',
                    '    y2="270.02"',
                    '    xlink:href="#linear-gradient-2"',
                    "  />"
                )
            );
            neck = string(
                abi.encodePacked(
                    neck,
                    "  <linearGradient",
                    '    id="linear-gradient-4"',
                    '    x1="299.34"',
                    '    y1="265.01"',
                    '    x2="298.97"',
                    '    y2="294.44"',
                    '    xlink:href="#linear-gradient-2"',
                    "  />"
                )
            );
            neck = string(
                abi.encodePacked(
                    neck,
                    "  <linearGradient",
                    '    id="linear-gradient-5"',
                    '    x1="324.59"',
                    '    y1="315.35"',
                    '    x2="324.14"',
                    '    y2="352.28"',
                    '    gradientTransform="matrix(0.99, -0.13, 0.13, 0.99, -40.7, 34.55)"',
                    '    xlink:href="#linear-gradient-2"',
                    "  />"
                )
            );
            neck = string(
                abi.encodePacked(
                    neck,
                    "  <linearGradient",
                    '    id="linear-gradient-6"',
                    '    x1="298.58"',
                    '    y1="315.41"',
                    '    x2="298.18"',
                    '    y2="347.03"',
                    '    gradientTransform="translate(-21.71 20.21) rotate(-3.76)"',
                    '    xlink:href="#linear-gradient-2"',
                    "  />"
                )
            );
            neck = string(
                abi.encodePacked(
                    neck,
                    "  <radialGradient",
                    '    id="radial-gradient"',
                    '    cx="308.46"',
                    '    cy="307.22"',
                    '    r="6.3"',
                    '    gradientTransform="translate(15.25 -14.12) rotate(2.61)"'
                )
            );
            neck = string(
                abi.encodePacked(
                    neck,
                    '    gradientUnits="userSpaceOnUse"',
                    "  >",
                    '    <stop offset="0.48" stop-color="#9b0e00" />',
                    '    <stop offset="1" stop-color="#4f0e00" />',
                    "  </radialGradient>",
                    "</defs>"
                )
            );
            neck = string(
                abi.encodePacked(
                    neck,
                    "<path",
                    '  class="cls-neck-26"',
                    '  d="M470.47,236.33c.55-.58-13.37-9.2-30.87-9.66a40.65,40.65,0,0,1-1.84,13.81S462.66,244.61,470.47,236.33Z"',
                    "/>"
                )
            );
            neck = string(
                abi.encodePacked(
                    neck,
                    "<path",
                    '  class="cls-neck-27"',
                    '  d="M444.66,273.75c-7.52,20.48-25.18-13.79-135.85,43-.28.14,7.93-18.33,8.17-18.53,6.76-5.77,31.13-17.4,42.23-25.88,26-19.89,18.52-46,17.72-48.64,39-3.67,42.67,25.39,93.52,13.77C471.91,237.06,455.2,245.06,444.66,273.75Z"',
                    "/>",
                    "<path",
                    '  class="cls-neck-28"',
                    '  d="M299.27,266.67c-.19,4.66-1.15,7.43-2.45,6.54-2.91-2-9.72-13.81-9.72-13.81-2.54,9.9-6.9,20.53,3.18,38.24,4.23,7.42,8.1,14.57,10.22,22.85l7.22-3.24c.9-6.72-10.6-29.93,6.81-47.4C314.31,269.78,304.18,269.58,299.27,266.67Z"',
                    "/>"
                )
            );
            neck = string(
                abi.encodePacked(
                    neck,
                    "<path",
                    '  class="cls-neck-29"',
                    '  d="M307.6,301.32a.3.3,0,0,0-.19.44c.93,1.88-3.73,5.4,7.48,40.26,3.62,11.26,3.56,35.75,4.55,34.89s8.68-12.56,8.8-12.49l13.62,8a.29.29,0,0,0,.43-.32c-1.1-4.35-10.21-28.23-12.85-35.91-2.73-8-10-32.07-10.83-34.91C318.56,301.11,307.6,301.32,307.6,301.32Z"',
                    "/>",
                    "<path",
                    '  class="cls-neck-30"',
                    '  d="M304.59,309.1a.18.18,0,0,0-.12,0c-.63.64-7.12,7.54-10.66,27.5-3.14,17.76-8.29,28.87-9.8,31.88a.21.21,0,0,0,.31.25s12-8.45,12.05-8.32l3.49,14.29a.2.2,0,0,0,.36.06c1.49-2.43,7-16.53,7.44-25.46a219.1,219.1,0,0,1,4.62-33.61C314.09,308.4,305.51,309,304.59,309.1Z"',
                    "/>"
                )
            );
            neck = string(
                abi.encodePacked(
                    neck,
                    "<path",
                    '  d="M300.93,298.51c-3.54-2.72-1-4.29-6.56-4.08l-1,23.11c5.45.79,3.08-1.06,6.84-3.37C300.48,314.73,301,298.42,300.93,298.51Z"',
                    "/>",
                    "<path",
                    '  d="M331.42,294.62c-8-1.27-.72,3.16-5.67,4.75-2.69-4.2-7.33-6.92-.8-10,2.13-2-2.46-1.79-3.45-1.85l-4.31.37c2.42,10.22-6.91,35.44,2.73,39.37,3.19.55,5-.74,3.38-1.49-8.94-3.33,5.6-15.33,3.7-4.69.8-.2,4,.87,4-.7C330.39,319.45,333.34,294.89,331.42,294.62Z"',
                    "/>"
                )
            );
            neck = string(
                abi.encodePacked(
                    neck,
                    "<path",
                    '  class="cls-neck-31"',
                    '  d="M323.81,307.58c-.4,8.73-7.45,15-15.24,14.05-7.28-.87-12.54-7.79-12.19-15.49s6.22-14,13.54-14.14C317.75,291.88,324.21,298.85,323.81,307.58Z"',
                    "/>",
                    "<path",
                    '  class="cls-neck-31"',
                    '  d="M321.58,288.29l-21.32.64a.14.14,0,0,0-.06.25c3,1.53,5.07,6.32,4.81,12,0,.44,9.84.73,9.86.27.27-6,3.06-11.09,6.76-12.93A.14.14,0,0,0,321.58,288.29Z"',
                    "/>"
                )
            );
            neck = string(
                abi.encodePacked(
                    neck,
                    "<path",
                    '  class="cls-neck-31"',
                    '  d="M298.68,323.67l21.16,2.87a.14.14,0,0,0,.07-.26c-3.52-2.22-5.82-7.6-5.55-13.58,0-.46-9.82-1.2-9.84-.76-.26,5.72-2.75,10.27-5.87,11.48A.13.13,0,0,0,298.68,323.67Z"',
                    "/>",
                    "<path",
                    '  class="cls-neck-31"',
                    '  d="M327.21,320.21l1.14-24.85a.15.15,0,0,0-.28-.06c-2,3.86-7.25,6.51-13.06,6.35-.44,0-.94,10.88-.5,10.91,5.8.44,10.81,3.64,12.42,7.68A.14.14,0,0,0,327.21,320.21Z"',
                    "/>"
                )
            );
            neck = string(
                abi.encodePacked(
                    neck,
                    "<path",
                    '  class="cls-neck-31"',
                    '  d="M294.45,295.35l-1,21.32c0,.14.15.2.2.08,1.5-3.23,5.69-5.35,10.71-5,.41,0,.88-10.41.48-10.42-5-.14-9-2.69-10.21-6.06C294.62,295.18,294.46,295.22,294.45,295.35Z"',
                    "/>",
                    "<path",
                    '  class="cls-neck-31"',
                    '  d="M318.89,307.32c-.27,5.78-4.89,10-10.11,9.52-5-.49-8.65-5.18-8.41-10.49s4.33-9.59,9.33-9.56C314.93,296.83,319.15,301.54,318.89,307.32Z"',
                    "/>"
                )
            );
            neck = string(
                abi.encodePacked(
                    neck,
                    "<path",
                    '  class="cls-neck-32"',
                    '  d="M315.44,307.14a6.23,6.23,0,0,1-6.5,6.21,6.39,6.39,0,0,1-5.57-6.84,6.06,6.06,0,1,1,12.07.63Z"',
                    "/>"
                )
            );
            neck = string(
                abi.encodePacked(
                    neck,
                    "<path",
                    '  class="cls-neck-33"',
                    '  d="M312.61,305.45c-.38.85-1.72,1-3,.36s-2-1.82-1.61-2.65,1.67-1,2.94-.39S313,304.61,312.61,305.45Z"',
                    "/>"
                )
            );
        } else {
            neck = string(abi.encodePacked());
        }
        return neck;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}