pragma solidity ^0.8.0;
//SPDX-License-Identifier: MIT

library LeavesBackground  {
      function background(string memory backgroundColor) public pure returns(string memory){
        return  string(abi.encodePacked(
            '<rect width="1080" height="1080" '
            ' fill="',backgroundColor,'"',
            ' />',
            '     <g transform="translate(-140,-260)">', 
            '         <path', 
            '             d="M361.609 834.4C113.609 788.8 69.9421 657.733 79.1088 597.9V537.9C79.1088 508.067 111.209 461.4 239.609 513.4C368.009 565.4 374.442 749.067 361.609 834.4Z"', 
            '             fill="#A5F7C6" stroke="white" stroke-width="2" />', 
            '         <path d="M362.5 833.5C334.5 760.167 239.2 605.2 82 572" stroke="white" stroke-width="2" fill-opacity="0" />', 
            '         <path', 
            '             d="M361.534 547.349C110.067 565.995 34.6525 450.245 28.3788 390.04L13.1947 331.993C5.6448 303.131 24.89 249.859 162.27 267.673C299.65 285.486 352.354 461.546 361.534 547.349Z"', 
            '             fill="#A5F7C6" stroke="white" stroke-width="2" />', 
            '         <path d="M362.168 546.253C316.521 482.393 185.106 356.588 24.6216 364.251" stroke="white" stroke-width="2"', 
            '             fill-opacity="0" />', 
            '         <path', 
            '             d="M316.844 414.967C94.9138 295.257 93.7028 157.113 120.839 103.004L139.304 45.9164C148.485 17.531 193.389 -16.9918 299.554 72.0001C405.719 160.992 355.316 337.724 316.844 414.967Z"', 
            '             fill="#A5F7C6" stroke="white" stroke-width="2" />', 
            '         <path d="M317.968 414.384C313.896 335.993 270.913 159.219 131.56 79.251" stroke="white" stroke-width="2"', 
            '             fill-opacity="0" />', 
            '         <path', 
            '             d="M421.931 463.847C292.298 247.563 361.828 128.186 412.797 95.5332L457.834 55.8894C480.228 36.1776 536.467 29.4386 582.272 160.177C628.077 290.915 494.463 417.098 421.931 463.847Z"', 
            '             fill="#A5F7C6" stroke="white" stroke-width="2" />', 
            '         <path d="M423.195 463.921C459.74 394.45 513.094 220.525 434.148 80.5903" stroke="white" stroke-width="2"', 
            '             fill-opacity="0" />', 
            '         <path', 
            '             d="M1097.45 939.763C1337.87 1015.8 1364.93 1151.27 1348.4 1209.5L1340.95 1269.04C1337.25 1298.64 1299.61 1340.96 1178.65 1273.43C1057.7 1205.89 1074.12 1022.84 1097.45 939.763Z"', 
            '             fill="#A5F7C6" stroke="white" stroke-width="2" />', 
            '         <path d="M1096.45 940.545C1115.13 1016.79 1190.46 1182.39 1342.32 1234.84" stroke="white" fill-opacity="0"', 
            '             stroke-width="2" />', 
            '         <path', 
            '             d="M951.379 1117.05C1203.17 1103.52 1276.22 1220.78 1281.27 1281.1L1295.27 1339.45C1302.23 1368.46 1281.9 1421.32 1144.91 1400.72C1007.92 1380.12 958.811 1203.02 951.379 1117.05Z"', 
            '             fill="#A5F7C6" stroke="white" stroke-width="2" />', 
            '         <path d="M950.722 1118.13C995.061 1182.91 1123.89 1311.36 1284.5 1306.96" stroke="white" fill-opacity="0"', 
            '             stroke-width="2" />', 
            '     </g>'
        ));
      }
}