pragma solidity ^0.8.0;
//SPDX-License-Identifier: MIT

import "hardhat/console.sol";

// GET LISTED ON OPENSEA: https://testnets.opensea.io/get-listed/step-two

// Defining Library
library Background2Library {
    function GetBackgroundShade(uint256 index)
        public
        pure
        returns (string memory)
    {
        string memory background;

        if (index == 0) {
            background = string(
                abi.encodePacked(
                    '<g id="BGs">',
                    '<rect class="cls-cv-1" x="-4.53" y="0.76" width="887.12" height="885.85" />',
                    "<path",
                    '  class="cls-cv-2"',
                    '  d="M789.68,447.13C695.19,344.37,436.78,670,651.47,714.36,773,739.47,994.26,669.62,789.68,447.13Z"',
                    "/>"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "<path",
                    '  class="cls-cv-3"',
                    '  d="M428.14,501.41C514.31,323.52,670.75,178,762.2,310.44c98,142,99.68,52.64,120.39,102.44V.76H-4.53V886.61H882.59V639.89C717.77,676.22,330.6,702.75,428.14,501.41Z"',
                    "/>",
                    "<path",
                    '  class="cls-cv-4"',
                    '  d="M600.86,658.07c-75,7.95-161,33.82-222.29-10.15-56.22-37.86,14.15-73.76-20.24-151.6-26-58.85-2.09-126.2,57.89-169.79,56.1-28.92,65.21,28,89.38-85.61,28.55-79.53,127.95-125.54,204.54-108.61,28.05,6.21,31.87,47.26,56.23,62.49,47,29.38,86,60.65,116.22,96.48V.76H-4.53V886.61H882.59V658.27C804.78,683,686.39,657.68,600.86,658.07Z"',
                    "/>"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "<path",
                    '  class="cls-cv-5"',
                    '  d="M231.15,626.21c-68.37-45.51-92.45-195.23-3-227.93,31.61-11.56,33.24,50.83,56.14,36.94,47.46-56.74,1.46-213,100.79-240.29,81.85,50.75,103.53-95.9,140.69-22.75,44.09,86.38,83.36,75.86,94.7-20.84C634.31,46.86,781.92,23.62,786.12,138.26c3.27,89.36,17.14,127.35,39.23,130.77,28.2,4.37,21.79-65.38,57.24-61V.76H-4.53V886.61H882.59V658.5C666.07,672.87,415,748.6,231.15,626.21Z"',
                    "/>",
                    "<path",
                    '  class="cls-cv-6"',
                    '  d="M550.78,731.09C444.48,706.9,202,868.39,117.55,596.76,75.84,462.61,151.17,366,208.34,318.62c60.49-48.22,7.58-198.34,67.77-258.28,5.68-11.09,38.05-13,45.41-2.49C370.43,99.44,330.06,359.48,384,348c43.67-9.27,36.23-125.09,46.85-168.43,12.29-46.31,48.33-96.51,97.22-106.29,22.66-.44,23.95,24,39.58,31,86.58-3.81,55,99.32,84.56,94.4,42.37-8.16,16.51-86.86,32.34-130.14,14.13-40.76,71.57-66.82,107.58-38.18C823.3,58,799,117.48,829.06,146.3c13.94,13.36,34.43,14.89,53.53,19.63V.76H-4.53V886.61H882.59V714.31C804.13,765.93,689.88,762.74,550.78,731.09Z"',
                    "/>"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "<path",
                    '  class="cls-cv-7"',
                    '  d="M884.2,325.73a29.6,29.6,0,0,0-17.93,6.84c-11.34,9.82-15.38,25.47-18.18,40.2C834,447,836.3,523.24,830.41,598.57s-16,234.95-65.4,214c-22.85-20.13-5.06-57.5-9.35-87.64-1.59-11.18-6.43-21.58-10.55-32.08-25.35-64.55,19.21-214.6-23.13-205.32C683.84,509.23,675.8,560.2,673.41,604c-9.34,170.67-58.36,159.89-74.73,236-7.67,35.7-68.42-6.6-95.9,17.44-7.92,6.93-32.74,20.3-52.47,28.33H884.2Z"',
                    "/>",
                    "<path",
                    '  class="cls-cv-7"',
                    '  d="M368.91,885.83c-.47-.75-.93-1.51-1.35-2.31-7.75-14.73-5.37-34-16-46.88-13.34-16.14-41.42-14.78-52.63-32.48-4.86-7.68-5.28-17.26-5.73-26.34a670.15,670.15,0,0,0-18.31-125.61c-4.06-16.58-16.94-37.36-32.59-30.53-8.07,3.52-11.37,13-13.51,21.56-14.08,56.23-15.5,116.61-42.28,168-8.69,16.7-27.77,34.06-43.88,24.33-7.81-4.71-11.15-14.14-13.87-22.84A1991,1991,0,0,1,75.06,600.28c-3.75-19.22-13.94-43.77-33.35-41.19-14.7,2-21.68,18.77-25.83,33Q5.41,628-5,663.9V885.83Z"',
                    "/>",
                    "</g>"
                )
            );
        } else if (index == 1) {
            background = string(
                abi.encodePacked(
                    '<g id="BGs">',
                    '<rect class="cls-fs-1" x="-3.48" y="-3.75" width="888.05" height="889.99" />',
                    '<path class="cls-fs-1" d="M224.5,764h0Z" />',
                    '<path class="cls-fs-1" d="M266.63,555.75l1-.85c0,.14.09.28.13.42Z" />',
                    '<path class="cls-fs-1" d="M266.63,555.75l1.13-.43c0-.14-.09-.28-.13-.42Z" />'
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "<path",
                    '  class="cls-fs-2"',
                    '  d="M770.91,355.09c10.53-25.4,19.77-84.79,19.77-84.79l1.39.21L805.18-4.64H786.77a3525.15,3525.15,0,0,0-54.92,419.78C745.06,404.59,756.5,389.86,770.91,355.09Z"',
                    "/>",
                    "<path",
                    '  class="cls-fs-2"',
                    '  d="M118.55,288.78l3,4.25Q117,143.9,115.75-4.64H50.9L65.66,186C75.49,218,93.05,252,118.55,288.78Z"',
                    "/>"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "<path",
                    '  class="cls-fs-2"',
                    '  d="M108.59,344c-6.8-9.52-14.5-20.32-22.9-32.43-4.08-5.87-8-11.69-11.67-17.46l5.64,72.81c6.16,79.61,12.54,161.93,10,243.82-.84,26.54-2.61,53.41-4.32,79.4C80.85,757.61,76.63,821.77,87,884.2H152c-12.59-172-22-345.31-28.14-518.57C119.1,358.75,114,351.66,108.59,344Z"',
                    "/>",
                    "<path",
                    '  class="cls-fs-2"',
                    '  d="M631.41,377.71l-2.82.83c-3.69-12.48-14.83-22.55-27.74-34.21-9.58-8.65-20.1-18.17-28.37-30-.46,70.05,5,141.05,10.36,210L610.7,884.2h16.44A3626,3626,0,0,1,631.41,377.71Z"',
                    "/>"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "<path",
                    '  class="cls-fs-2"',
                    '  d="M776.88,589.43l8.32-174.54C768.82,440,753.07,450,735.68,461c-2.28,1.45-4.62,2.93-7,4.47a3520.55,3520.55,0,0,0,1.6,418.77h39.64C767.55,785.27,772.28,685.88,776.88,589.43Z"',
                    "/>",
                    "<path",
                    '  class="cls-fs-3"',
                    '  d="M282.43,355.82c1.13,31.12,2.29,63.3,3,94.78A3638.21,3638.21,0,0,1,269.6,884.2h60.28a3698.18,3698.18,0,0,0,15.56-435c-.74-31.86-1.91-64.24-3.05-95.55-4.29-118.56-8.7-240.88,9.44-358.29H291.15C273.73,115.34,278.15,237.41,282.43,355.82Z"',
                    "/>"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "<path",
                    '  class="cls-fs-4"',
                    '  d="M104.1,690.15c1.72-26,3.49-52.86,4.32-79.4,2.58-81.89-3.8-164.21-10-243.82,0,0-10.33-120.24-14-180.9L69.69-4.64H19.54L48.61,370.79C54.67,449.07,60.93,530,58.45,609.18c-.81,25.67-2.55,52.11-4.24,77.68-4.27,64.81-8.67,131.49,1,197.34h50.59C95.43,821.77,99.65,757.61,104.1,690.15Z"',
                    "/>",
                    "<path",
                    '  class="cls-fs-5"',
                    '  d="M802.07,270.51,786.88,589.43c-4.6,96.45-9.33,195.84-7,294.77h60c-2.4-97.32,2.3-196.08,6.87-291.92L875.25-4.64H815.18Z"',
                    "/>"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "<path",
                    '  class="cls-fs-6"',
                    '  d="M405.18,884.2h80.07A7759,7759,0,0,0,471.74-4.64H391.53A7677.75,7677.75,0,0,1,405.18,884.2Z"',
                    "/>",
                    "<path",
                    '  class="cls-fs-7"',
                    '  d="M215.75-4.64h-100Q117,143.76,121.51,293l-3-4.25C93.05,252,75.49,218,65.66,186c-7.94-25.78-10.86-50.18-8.82-73.49L17,109.06c-5,57,13.71,117.7,57,185.06,3.72,5.77,7.59,11.59,11.67,17.46,8.4,12.11,16.1,22.91,22.9,32.43,5.45,7.65,10.51,14.74,15.3,21.62C130,538.89,139.44,712.25,152,884.2H252.3C230.56,589.59,218.27,290.74,215.75-4.64Z"',
                    "/>"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "<path",
                    '  class="cls-fs-8"',
                    '  d="M582.84,524.36c-5.33-68.94-10.82-139.94-10.36-210q.09-14.24.52-28.4c.81-25.68,4.24-77.68,4.24-77.68l-31-2L527.35,205s-3.49,52.86-4.32,79.4c-2.57,81.89,3.8,164.21,10,243.82l27.56,356H610.7Z"',
                    "/>",
                    "<path",
                    '  class="cls-fs-7"',
                    '  d="M790.68,270.3s-9.24,59.39-19.77,84.79c-14.41,34.77-25.85,49.5-39.06,60.05A3525.15,3525.15,0,0,1,786.77-4.64H682Q651.62,157.9,636.17,322.44c-2.85-2.68-5.71-5.27-8.5-7.79-11.09-10-21.56-19.48-26.65-30.41-3.57-7.67-5-17.13-6.53-27.14l-12.21-80.21-36,29.36,8.65,56.87c1.8,11.78,3.83,25.13,9.81,38a87.34,87.34,0,0,0,7.73,13.25c8.27,11.79,18.79,21.31,28.37,30,12.91,11.66,30.56,33.38,30.56,33.38a3626,3626,0,0,0-4.27,506.49H730.29a3520.55,3520.55,0,0,1-1.6-418.77c2.37-1.54,4.71-3,7-4.47,17.39-11,33.14-21,49.52-46.07,7.36-11.29,14.85-25.62,22.66-44.48,12.43-30,22.39-94.3,22.39-94.3Z"',
                    "/>"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    '<path class="cls-fs-1" d="M266.63,36.06l1.13-.13a1.59,1.59,0,0,0-.13-.13Z" />',
                    '<g class="cls-fs-9">',
                    '  <rect class="cls-fs-1" x="-3.48" y="-3.75" width="888.05" height="889.99" />',
                    '  <path class="cls-fs-1" d="M224.5,764h0Z" />',
                    '  <path class="cls-fs-1" d="M266.63,555.75l1-.85c0,.14.09.28.13.42Z" />',
                    '  <path class="cls-fs-1" d="M266.63,555.75l1.13-.43c0-.14-.09-.28-.13-.42Z" />',
                    "</g>"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "<path",
                    '  class="cls-fs-10"',
                    '  d="M423.34-5l-14.46,69.1,34.68,69.46c11.77,23.59,24.33,48.12,45.73,63.51,33.95,24.42,80.27,19.53,120.29,31.68,35.83,10.88,66,35.34,100.83,49.13C765.26,299.58,826.27,293.22,885,284V-5Z"',
                    "/>",
                    "<path",
                    '  class="cls-fs-11"',
                    '  d="M-6.4,168.18c60.61,9.52,147.57,42.63,196,17.93C223.17,169,252.05,143.22,287,129.19c59.25-23.79,125.88-10.47,189.72-9.55,67.51,1,137.2-13.51,191.8-53.21A211.81,211.81,0,0,0,730.64-5H-6.4Z"',
                    "/>",
                    "</g>"
                )
            );
        } else if (index == 2) {
            background = string(
                abi.encodePacked(
                    '<g id="BGs">',
                    '<rect class="cls-jn-1" x="-3.48" y="-3.75" width="888.05" height="889.99" />',
                    "<path",
                    '  class="cls-jn-2"',
                    '  d="M480.84,209.87C466,315.59,511.37,466.93,644.25,457.52,803.19,446.26,777-76.18,745.81,233.28c-6.36,43.11-15.15,105-31.36,144.77a142.77,142.77,0,0,1-17.66,31c.44.54-15.79,16.8-15.81,16A88,88,0,0,1,661.8,436.3c-21.86,9.15-51.65,8.91-77.07-1.91-16-5.77-39-24.63-49.25-38.95-8.45-10.5-18.54-29.07-22.12-38.08-7.5-17.27-13.22-41.63-15.13-57.31C489.85,286.2,508.78,173.35,480.84,209.87Z"',
                    "/>"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "<path",
                    '  class="cls-jn-2"',
                    '  d="M879.87,283.71c-5.51-30.81-26.3-93-104.64-165.85-19.84-14.88-24.8,19.84-24.8,19.84s72.33,90.42,86.77,151.89c-62.84-34.91-163-52.83-263.22-61.54C566.25,251.24,561.1,259,561.1,259S793,266.7,808.47,338.85s0,324.67,0,324.67h76.1S881.34,281.32,879.87,283.71Z"',
                    "/>",
                    "<path",
                    '  class="cls-jn-3"',
                    '  d="M795,617.11c-8.15-13.36-32.65-37.14-101.46-26.27a25.06,25.06,0,0,1-25.76-12.73c-54.92-98.68-226.41-86.26-276.63-33.91a25.39,25.39,0,0,1-19.27,7.64c-36.23-1.34-76.85,6.39-107.75,47.69A24.83,24.83,0,0,1,231,605.82c-17.67-11.3-45.14-15-64.56-10.67a53.93,53.93,0,0,1-44.88-10.28c-14.67-11.53-37.09-22.29-83.18-34.14a103.23,103.23,0,0,0-39.78-2.14l-2,342.14H757l41.42-259.67A24.63,24.63,0,0,0,795,617.11Z"',
                    "/>"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "<path",
                    '  class="cls-jn-2"',
                    '  d="M159.55-3.75c-11.29,28.67,15.07,63.58-6,94.66-26,38.45-103.34,34-155.91,58.51V418.11C25.4,428.51,56.21,432.55,86,434.24c82.52,3.63,178.19,9.36,221.51-74.88,71-70.29,229.55,19.45,266.48-97.51,4.4-21.81-2.26-47.44,12-64.49,15.21-18.15,43.31-14.35,67-12.94,65.41,9.57,112.64-46.89,170.58-58.68,26.4-5.37,43.78-7.66,61.74-3.78V-3.75Z"',
                    "/>",
                    '<path class="cls-jn-4" d="M224.5,764h0Z" />',
                    '<path class="cls-jn-4" d="M266.63,555.75l1-.85c0,.14.09.28.13.42Z" />',
                    '<path class="cls-jn-4" d="M266.63,555.75l1.13-.43c0-.14-.09-.28-.13-.42Z" />'
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "<path",
                    '  class="cls-jn-5"',
                    '  d="M883.84,889.19v-314c-37.08,6-103.37,23-130,69.17a49.82,49.82,0,0,1-38.27,24.29C674.8,672.85,638.1,696,615.43,717.37a50.46,50.46,0,0,1-63.1,4.93c-32.8-22.43-57.74-31-101.53-29.88a50.74,50.74,0,0,1-24.58-5.55c-65.29-33.8-164.29-28.54-211.69,24.6a51.31,51.31,0,0,1-30.34,16.29C115.6,738.67,37.71,789.25-5.4,857.82v31.37Z"',
                    "/>",
                    "</g>"
                )
            );
        } else if (index == 3) {
            background = string(
                abi.encodePacked(
                    '<g id="BGs">',
                    "<rect",
                    '  class="cls-sk-1"',
                    '  x="-7.52"',
                    '  y="-9.72"',
                    '  width="893.36"',
                    '  height="352.18"',
                    '  transform="translate(878.32 332.73) rotate(-180)"',
                    "/>"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "<polygon",
                    '  class="cls-sk-2"',
                    '  points="-5.04 885.83 885.28 884.74 887.47 324.61 -9.4 243.97 -5.04 885.83"',
                    "/>",
                    "<polygon",
                    '  class="cls-sk-3"',
                    '  points="-8.31 418.33 887.47 494.61 887.47 410.7 -9.4 338.77 -8.31 418.33"',
                    "/>"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "<polygon",
                    '  class="cls-sk-4"',
                    '  points="-8.31 598.14 887.47 674.42 887.47 590.51 -9.4 518.58 -8.31 598.14"',
                    "/>",
                    "<polygon",
                    '  class="cls-sk-5"',
                    '  points="-8.31 777.95 887.47 854.23 887.47 770.32 -9.4 698.39 -8.31 777.95"',
                    "/>"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "<polygon",
                    '  class="cls-sk-6"',
                    '  points="257.59 885.83 882.28 -0.68 883.92 131.45 801.7 253.48 795.72 885.83 739.53 884.63 744.9 334.44 538.05 629.29 532 885.83 475.81 884.63 481.26 710.26 353.49 885.83 257.59 885.83"',
                    "/>"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "<rect",
                    '  class="cls-sk-7"',
                    '  x="-2.86"',
                    '  y="-1.23"',
                    '  width="884.88"',
                    '  height="882.7"',
                    '  transform="translate(879.15 880.24) rotate(-180)"',
                    "/>",
                    "</g>"
                )
            );
        } else {
            background = string(abi.encodePacked());
        }
        return background;
    }

    function GetBackground(uint256 colorIndex)
        public
        pure
        returns (string memory)
    {
        string memory background;

        if (colorIndex == 9) {
            background = string(
                abi.encodePacked(
                    "<defs>",
                    "  <style>",
                    "    .cls-cv-1 {",
                    "      fill: #bfc9d0;",
                    "    }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "    .cls-cv-2 {",
                    "      fill: #e5e9ec;",
                    "    }",
                    "    .cls-cv-3 {",
                    "      fill: #99a9b3;",
                    "    }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "    .cls-cv-4 {",
                    "      fill: #738997;",
                    "    }",
                    "    .cls-cv-5 {",
                    "      fill: #4c687b;",
                    "    }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "    .cls-cv-6 {",
                    "      fill: #26485e;",
                    "    }",
                    "    .cls-cv-7 {",
                    "      fill: #002842;",
                    "    }",
                    "  </style>",
                    "</defs>",
                    GetBackgroundShade(0)
                )
            );
        } else if (colorIndex == 10) {
            background = string(
                abi.encodePacked(
                    "<defs>",
                    "  <style>",
                    "    .cls-cv-1 {",
                    "      fill: #c3c6c7;",
                    "    }",
                    "    .cls-cv-2 {",
                    "      fill: #e7e8e9;",
                    "    }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "    .cls-cv-3 {",
                    "      fill: #9fa4a6;",
                    "    }",
                    "    .cls-cv-4 {",
                    "      fill: #7c8284;",
                    "    }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "    .cls-cv-5 {",
                    "      fill: #586063;",
                    "    }",
                    "    .cls-cv-6 {",
                    "      fill: #343e41;",
                    "    }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "    .cls-cv-7 {",
                    "      fill: #101c20;",
                    "    }",
                    "  </style>",
                    "</defs>",
                    GetBackgroundShade(0)
                )
            );
        } else if (colorIndex == 11) {
            background = string(
                abi.encodePacked(
                    "<defs>",
                    "  <style>",
                    "    .cls-cv-1 {",
                    "      fill: #ccc3cc;",
                    "    }",
                    "    .cls-cv-2 {",
                    "      fill: #ebe7eb;",
                    "    }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "    .cls-cv-3 {",
                    "      fill: #ada0ae;",
                    "    }",
                    "    .cls-cv-4 {",
                    "      fill: #8f7c90;",
                    "    }",
                    "    .cls-cv-5 {",
                    "      fill: #705872;",
                    "    }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "    .cls-cv-6 {",
                    "      fill: #523553;",
                    "    }",
                    "    .cls-cv-7 {",
                    "      fill: #331135;",
                    "    }",
                    "  </style>",
                    "</defs>",
                    GetBackgroundShade(0)
                )
            );
        } else if (colorIndex == 12) {
            background = string(
                abi.encodePacked(
                    "<defs>",
                    "  <style>",
                    "    .cls-fs-1 {",
                    "      fill: #066666;",
                    "    }",
                    "    .cls-fs-2 {",
                    "      fill: none;",
                    "    }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "    .cls-fs-3,",
                    "    .cls-fs-4,",
                    "    .cls-fs-5,",
                    "    .cls-fs-6,",
                    "    .cls-fs-7,",
                    "    .cls-fs-8 {",
                    "      fill: #fff;",
                    "    }",
                    "    .cls-fs-3 {",
                    "      opacity: 0.55;",
                    "    }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "    .cls-fs-4 {",
                    "      opacity: 0.5;",
                    "    }",
                    "    .cls-fs-5 {",
                    "      opacity: 0.6;",
                    "    }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "    .cls-fs-6 {",
                    "      opacity: 0.75;",
                    "    }",
                    "    .cls-fs-7 {",
                    "      opacity: 0.9;",
                    "    }",
                    "    .cls-fs-8 {",
                    "      opacity: 0.4;",
                    "    }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "    .cls-fs-9 {",
                    "      opacity: 0.1;",
                    "    }",
                    "    .cls-fs-10 {",
                    "      fill: #1fccb3;",
                    "    }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "    .cls-fs-11 {",
                    "      fill: #33e5c7;",
                    "    }",
                    "  </style>",
                    "</defs>",
                    GetBackgroundShade(1)
                )
            );
        } else if (colorIndex == 14) {
            background = string(
                abi.encodePacked(
                    "<defs>",
                    "  <style>",
                    "    .cls-fs-1 {",
                    "      fill: #066666;",
                    "    }",
                    "    .cls-fs-2 {",
                    "      fill: #a81349;",
                    "    }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "    .cls-fs-3 {",
                    "      fill: none;",
                    "    }",
                    "    .cls-fs-4,",
                    "    .cls-fs-5,",
                    "    .cls-fs-6,"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "    .cls-fs-7,",
                    "    .cls-fs-8,",
                    "    .cls-fs-9 {",
                    "      fill: #fff;",
                    "    }",
                    "    .cls-fs-4 {",
                    "      opacity: 0.55;",
                    "    }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "    .cls-fs-5 {",
                    "      opacity: 0.5;",
                    "    }",
                    "    .cls-fs-6 {",
                    "      opacity: 0.6;",
                    "    }",
                    "    .cls-fs-7 {",
                    "      opacity: 0.75;",
                    "    }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "    .cls-fs-8 {",
                    "      opacity: 0.9;",
                    "    }",
                    "    .cls-fs-9 {",
                    "      opacity: 0.4;",
                    "    }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "    .cls-fs-10 {",
                    "      fill: #f26489;",
                    "    }",
                    "    .cls-fs-11 {",
                    "      fill: #ff99be;",
                    "    }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "    .cls-fs-12 {",
                    "      opacity: 0.1;",
                    "    }",
                    "  </style>",
                    "</defs>",
                    GetBackgroundShade(1)
                )
            );
        } else if (colorIndex == 14) {
            background = string(
                abi.encodePacked(
                    "<defs>",
                    "  <style>",
                    "    .cls-fs-1 {",
                    "      fill: #d35500;",
                    "    }",
                    "    .cls-fs-2 {",
                    "      fill: none;",
                    "    }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "    .cls-fs-3,",
                    "    .cls-fs-4,",
                    "    .cls-fs-5,",
                    "    .cls-fs-6,",
                    "    .cls-fs-7,",
                    "    .cls-fs-8 {",
                    "      fill: #fff;",
                    "    }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "    .cls-fs-3 {",
                    "      opacity: 0.55;",
                    "    }",
                    "    .cls-fs-4 {",
                    "      opacity: 0.5;",
                    "    }",
                    "    .cls-fs-5 {",
                    "      opacity: 0.6;",
                    "    }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "    .cls-fs-6 {",
                    "      opacity: 0.75;",
                    "    }",
                    "    .cls-fs-7 {",
                    "      opacity: 0.9;",
                    "    }",
                    "    .cls-fs-8 {",
                    "      opacity: 0.4;",
                    "    }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "    .cls-fs-9 {",
                    "      opacity: 0.1;",
                    "    }",
                    "    .cls-fs-10 {",
                    "      fill: #fb913b;",
                    "    }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "    .cls-fs-11 {",
                    "      fill: #fbc26e;",
                    "    }",
                    "  </style>",
                    "</defs>",
                    GetBackgroundShade(1)
                )
            );
        } else if (colorIndex == 15) {
            background = string(
                abi.encodePacked(
                    "<defs>",
                    "  <style>",
                    "    .cls-jn-1 {",
                    "      fill: #c5f9d0;",
                    "    }",
                    "    .cls-jn-2 {",
                    "      fill: #1dcc85;",
                    "    }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "    .cls-jn-3 {",
                    "      fill: #056849;",
                    "    }",
                    "    .cls-jn-4 {",
                    "      fill: #059ca0;",
                    "    }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "    .cls-jn-5 {",
                    "      fill: #1b2b30;",
                    "    }",
                    "  </style>",
                    "</defs>",
                    GetBackgroundShade(2)
                )
            );
        } else if (colorIndex == 16) {
            background = string(
                abi.encodePacked(
                    "<defs>",
                    "  <style>",
                    "    .cls-jn-1 {",
                    "      fill: #ffbf40;",
                    "    }",
                    "    .cls-jn-2 {",
                    "      fill: #ff8948;",
                    "    }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "    .cls-jn-3 {",
                    "      fill: #9e1536;",
                    "    }",
                    "    .cls-jn-4 {",
                    "      fill: #059ca0;",
                    "    }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "    .cls-jn-5 {",
                    "      fill: #720e2d;",
                    "    }",
                    "  </style>",
                    "</defs>",
                    GetBackgroundShade(2)
                )
            );
        } else if (colorIndex == 17) {
            background = string(
                abi.encodePacked(
                    "<defs>",
                    "  <style>",
                    "    .cls-jn-1 {",
                    "      fill: #ccf8f8;",
                    "    }",
                    "    .cls-jn-2 {",
                    "      fill: #7deded;",
                    "    }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "    .cls-jn-3 {",
                    "      fill: #059ca0;",
                    "    }",
                    "    .cls-jn-4,",
                    "    .cls-jn-5 {",
                    "      fill: #056b68;",
                    "    }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "  </style>",
                    "</defs>",
                    GetBackgroundShade(2)
                )
            );
        } else if (colorIndex == 18) {
            background = string(
                abi.encodePacked(
                    "<defs>",
                    "  <style>",
                    "    .cls-sk-1 {",
                    "      fill: url(#linear-gradient);",
                    "    }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "    .cls-sk-2 {",
                    "      fill: #00d8a4;",
                    "    }",
                    "    .cls-sk-3 {",
                    "      fill: url(#linear-gradient-2);",
                    "    }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "    .cls-sk-4 {",
                    "      fill: url(#linear-gradient-3);",
                    "    }",
                    "    .cls-sk-5 {",
                    "      fill: url(#linear-gradient-4);",
                    "    }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "    .cls-sk-6 {",
                    "      fill: url(#linear-gradient-5);",
                    "    }",
                    "    .cls-sk-7 {",
                    "      fill: none;",
                    "    }",
                    "  </style>"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "  <linearGradient",
                    '    id="linear-gradient"',
                    '    x1="448.17"',
                    '    y1="292.63"',
                    '    x2="430.41"',
                    '    y2="18.34"'
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    '    gradientTransform="matrix(1, 0, 0, -1, -0.84, 332.73)"',
                    '    gradientUnits="userSpaceOnUse"',
                    "  >",
                    '    <stop offset="0" stop-color="#ffe136" />',
                    '    <stop offset="0.05" stop-color="#fcd63b" />'
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    '    <stop offset="0.39" stop-color="#e6845c" />',
                    '    <stop offset="0.68" stop-color="#d64875" />',
                    '    <stop offset="0.89" stop-color="#cc2384" />',
                    '    <stop offset="1" stop-color="#c8158a" />',
                    "  </linearGradient>"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "  <linearGradient",
                    '    id="linear-gradient-2"',
                    '    x1="-8.31"',
                    '    y1="416.69"',
                    '    x2="888.55"',
                    '    y2="416.69"'
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    '    gradientTransform="matrix(-1, 0, 0, 1, 879.15, 0)"',
                    '    gradientUnits="userSpaceOnUse"',
                    "  >",
                    '    <stop offset="0" stop-color="#8186ed" />',
                    '    <stop offset="1" stop-color="#00cadb" />',
                    "  </linearGradient>"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "  <linearGradient",
                    '    id="linear-gradient-3"',
                    '    x1="-8.31"',
                    '    y1="596.5"',
                    '    x2="888.55"',
                    '    y2="596.5"',
                    '    xlink:href="#linear-gradient-2"'
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "  />",
                    "  <linearGradient",
                    '    id="linear-gradient-4"',
                    '    x1="-8.31"',
                    '    y1="776.31"',
                    '    x2="888.55"',
                    '    y2="776.31"'
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    '    xlink:href="#linear-gradient-2"',
                    "  />",
                    "  <linearGradient",
                    '    id="linear-gradient-5"',
                    '    x1="-4.77"'
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    '    y1="442.58"',
                    '    x2="621.57"',
                    '    y2="442.58"',
                    '    gradientTransform="matrix(-1, 0, 0, 1, 879.15, 0)"',
                    '    gradientUnits="userSpaceOnUse"',
                    "  >"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    '    <stop offset="0" stop-color="#ff9" />',
                    '    <stop offset="1" stop-color="#ffe300" />',
                    "  </linearGradient>",
                    "</defs>",
                    GetBackgroundShade(3)
                )
            );
        } else if (colorIndex == 19) {
            background = string(
                abi.encodePacked(
                    "<defs>",
                    "  <style>",
                    "    .cls-sk-1 {",
                    "      fill: url(#linear-gradient);",
                    "    }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "    .cls-sk-2 {",
                    "      fill: #fad279;",
                    "    }",
                    "    .cls-sk-3 {",
                    "      fill: url(#linear-gradient-2);",
                    "    }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "    .cls-sk-4 {",
                    "      fill: url(#linear-gradient-3);",
                    "    }",
                    "    .cls-sk-5 {",
                    "      fill: url(#linear-gradient-4);",
                    "    }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "    .cls-sk-6 {",
                    "      fill: url(#linear-gradient-5);",
                    "    }",
                    "    .cls-sk-7 {",
                    "      fill: none;",
                    "    }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "  </style>",
                    "  <linearGradient",
                    '    id="linear-gradient"',
                    '    x1="448.17"',
                    '    y1="292.63"',
                    '    x2="430.41"'
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    '    y2="18.34"',
                    '    gradientTransform="matrix(1, 0, 0, -1, -0.84, 332.73)"',
                    '    gradientUnits="userSpaceOnUse"',
                    "  >",
                    '    <stop offset="0.1" stop-color="#ff56b0" />'
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    '    <stop offset="1" stop-color="#35eded" />',
                    "  </linearGradient>",
                    "  <linearGradient",
                    '    id="linear-gradient-2"',
                    '    x1="-8.31"',
                    '    y1="416.69"'
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    '    x2="888.55"',
                    '    y2="416.69"',
                    '    gradientTransform="matrix(-1, 0, 0, 1, 879.15, 0)"',
                    '    gradientUnits="userSpaceOnUse"',
                    "  >"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    '    <stop offset="0" stop-color="#f7931e" />',
                    '    <stop offset="1" stop-color="#ffbf40" />',
                    "  </linearGradient>",
                    "  <linearGradient",
                    '    id="linear-gradient-3"'
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    '    x1="-8.31"',
                    '    y1="596.5"',
                    '    x2="888.55"',
                    '    y2="596.5"',
                    '    xlink:href="#linear-gradient-2"',
                    "  />",
                    "  <linearGradient",
                    '    id="linear-gradient-4"'
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    '    x1="-8.31"',
                    '    y1="776.31"',
                    '    x2="888.55"',
                    '    y2="776.31"',
                    '    xlink:href="#linear-gradient-2"',
                    "  />",
                    "  <linearGradient"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    '    id="linear-gradient-5"',
                    '    x1="-4.77"',
                    '    y1="442.58"',
                    '    x2="621.57"',
                    '    y2="442.58"'
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    '    gradientTransform="matrix(-1, 0, 0, 1, 879.15, 0)"',
                    '    gradientUnits="userSpaceOnUse"',
                    "  >"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    '    <stop offset="0" stop-color="#91f43b" />',
                    '    <stop offset="1" stop-color="#34d97b" />',
                    "  </linearGradient>",
                    "</defs>",
                    GetBackgroundShade(3)
                )
            );
        } else if (colorIndex == 20) {
            background = string(
                abi.encodePacked(
                    "<defs>",
                    "  <style>",
                    "    .cls-sk-1 {",
                    "      fill: url(#linear-gradient);",
                    "    }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "    .cls-sk-2 {",
                    "      fill: #f0f;",
                    "    }",
                    "    .cls-sk-3 {",
                    "      fill: url(#linear-gradient-2);",
                    "    }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "    .cls-sk-4 {",
                    "      fill: url(#linear-gradient-3);",
                    "    }",
                    "    .cls-sk-5 {",
                    "      fill: url(#linear-gradient-4);",
                    "    }",
                    "    .cls-sk-6 {",
                    "      fill: url(#linear-gradient-5);",
                    "    }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "    .cls-sk-7 {",
                    "      fill: none;",
                    "    }",
                    "  </style>",
                    "  <linearGradient"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    '    id="linear-gradient"',
                    '    x1="448.17"',
                    '    y1="292.63"',
                    '    x2="430.41"',
                    '    y2="18.34"'
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    '    gradientTransform="matrix(1, 0, 0, -1, -0.84, 332.73)"',
                    '    gradientUnits="userSpaceOnUse"',
                    "  >",
                    '    <stop offset="0" stop-color="#b4ff33" />',
                    '    <stop offset="1" stop-color="#35eded" />',
                    "  </linearGradient>"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "  <linearGradient",
                    '    id="linear-gradient-2"',
                    '    x1="-8.31"',
                    '    y1="416.69"',
                    '    x2="888.55"',
                    '    y2="416.69"'
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    '    gradientTransform="matrix(-1, 0, 0, 1, 879.15, 0)"',
                    '    gradientUnits="userSpaceOnUse"',
                    "  >",
                    '    <stop offset="0" stop-color="#9651ff" />',
                    '    <stop offset="1" stop-color="#da00ff" />',
                    "  </linearGradient>"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "  <linearGradient",
                    '    id="linear-gradient-3"',
                    '    x1="-8.31"',
                    '    y1="596.5"',
                    '    x2="888.55"',
                    '    y2="596.5"'
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    '    xlink:href="#linear-gradient-2"',
                    "  />",
                    "  <linearGradient",
                    '    id="linear-gradient-4"',
                    '    x1="-8.31"',
                    '    y1="776.31"',
                    '    x2="888.55"'
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    '    y2="776.31"',
                    '    xlink:href="#linear-gradient-2"',
                    "  />",
                    "  <linearGradient",
                    '    id="linear-gradient-5"',
                    '    x1="-4.77"',
                    '    y1="442.58"'
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    '    x2="621.57"',
                    '    y2="442.58"',
                    '    gradientTransform="matrix(-1, 0, 0, 1, 879.15, 0)"',
                    '    gradientUnits="userSpaceOnUse"',
                    "  >"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    '    <stop offset="0.18" stop-color="#ff0" />',
                    '    <stop offset="1" stop-color="#fb8525" />',
                    "  </linearGradient>",
                    "</defs>",
                    GetBackgroundShade(3)
                )
            );
        } else {
            background = string(abi.encodePacked('<g id="BGs">', "</g>"));
        }
        return background;
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