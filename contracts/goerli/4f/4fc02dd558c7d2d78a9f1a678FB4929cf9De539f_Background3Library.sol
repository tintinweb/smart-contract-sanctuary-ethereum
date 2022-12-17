pragma solidity ^0.8.0;
//SPDX-License-Identifier: MIT

import "hardhat/console.sol";

// GET LISTED ON OPENSEA: https://testnets.opensea.io/get-listed/step-two

// Defining Library
library Background3Library {
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
                    ' <rect class="c3-2" x="-9.4" y="-11.86" width="900.14" height="418.2" />',
                    ' <rect class="c3-3" x="-9.4" y="396.53" width="900.14" height="372.7" />',
                    " <path",
                    '  class="c3-4"',
                    '  d="M-9.4,555.56c52.28-3.14,229.72.6,215,24.53-9.46,15.34-24.58,17.15-26.15,28.83-1.64,12.14,12,10.58,198.61,26.56,54.31,4.65,42.19,25.87,9,46.28-70.95,43.6,198.08,55.38,505.91,33.38l2.18,107.48H-1.77Z"',
                    " />"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " <path",
                    '  class="c3-5"',
                    '  d="M894,732.41s-271.18,19-474.31-7.31,114.67-73-122.86-86.19-79.29-45.58-116.31-62.09C155.12,565.5-9.4,563.26-9.4,563.26V888.55H894Z"',
                    " />",
                    " <path",
                    '  class="c3-6"',
                    '  d="M-5.92,782.19C-25.52,554.67,32.85,322.05,151,127.4c3-10.87,19.09-8.45,11.25,3.19-44.58,83.86-75.37,174.9-96,267.4C32.28,552,32.55,733.27,78.14,886.19c-.91.19-68.47,2.91-69.74.73C2.07,854-2.9,815.4-5.92,782.19Z"',
                    " />"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    ' <g class="c3-7">',
                    " <path",
                    '  d="M48.27,505.22,9.68,494.6c.58-3,5.26-25.59,7.13-33.85l35.62,12.94C51.54,479.79,48.79,500.81,48.27,505.22Z"',
                    " />",
                    " <path",
                    '  d="M-2,568.43l44.44,9.86q-.76,17.31-.94,34.61L-6,606.29Q-4.37,587.3-2,568.43Z"',
                    " />",
                    " <path",
                    '  d="M46.57,722.33c1.42,12.9,3.23,28,5.22,40.83,2.21.32-64.42,7.25-59.2.34C-10.91,703.78-18.17,719.26,46.57,722.33Z"',
                    " />"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " <path",
                    '  d="M88.35,312.9l-24.72-6.81c1.13-3,6.54-16.83,8.13-20.77l22.6,8.21C93.1,297.48,89.1,310.39,88.35,312.9Z"',
                    " />",
                    " <path",
                    '  d="M70.88,377.64Q68.45,387.8,66.23,398c0,.15-.07.3-.1.45L35.29,390q3.36-11.4,7-22.72Z"',
                    " />",
                    " <path",
                    '  d="M141.92,171.08q-3.33,7.14-6.52,14.35l-14.87-5.32q4-7.55,8.15-15Z"',
                    " />"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " <path",
                    '  d="M118.33,226.28c-1.91,4.84-3.76,9.69-5.6,14.56l-18.88-6.76c2.4-5.2,4.82-10.39,7.3-15.55Z"',
                    " />",
                    " </g>",
                    " <path",
                    ' class="c3-8"',
                    ' d="M-.34,169.22c50.82-38.66,116.24-48,147-48.88-26.11-10.46-85.77-27.57-157.15-2v59.76A96.54,96.54,0,0,1-.34,169.22Z"',
                    " />",
                    " <path",
                    ' class="c3-8"',
                    ' d="M-10.49-2.31c34-10.89,80.9-17,124.27,7.88C150,26.36,158.5,70.29,160,98.76c1.85-44.43-3.64-81.7-11.18-110.89H-10.49Z"',
                    " />"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " <path",
                    ' class="c3-8"',
                    ' d="M7.79,59.36c69.3-16.85,120.52,29.4,141.41,53C133.63,83.92,82.09,28.69-10.49,19.92V65A157.41,157.41,0,0,1,7.79,59.36Z"',
                    " />",
                    " <path",
                    ' class="c3-9"',
                    ' d="M321.27,131.59C263.46,93.69,200.42,107,172.76,116.67c73.5-50.37,229.48-2.35,229.48-2.35s-41.08-80.92-121.87-78c-56.06,2-90.15,38.37-107.41,64.22,12.48-26.85,27.55-70.77,14.7-112.69H148.81c7.54,29.19,13,66.46,11.18,110.89-1.49-28.47-10-72.4-46.21-93.19C70.41-19.34,23.48-13.2-10.49-2.31V19.92c92.58,8.77,144.12,64,159.69,92.44-20.89-23.6-72.11-69.85-141.41-53A157.41,157.41,0,0,0-10.49,65v53.42c71.38-25.62,131-8.51,157.15,2-30.76.83-96.18,10.22-147,48.88a96.54,96.54,0,0,0-10.15,8.93V286.64C41.29,197.58,129.07,143.13,155.88,128c2.47,11.17,15.73,77.51,24.92,248.79,102-159,29.38-224.74-10.62-247.34C320.25,166.92,338.4,322.69,338.4,322.69S394.26,179.44,321.27,131.59Z"',
                    " />"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " <path",
                    ' class="c3-10"',
                    ' d="M735,737.38s28.2-15.23,38.49-15.82-2,22.31-2,23.3,40.33,7.48,41.73,12.58c1,3.68-16.6,6.54-45.67,10.48,0,0-1,26.41-10.14,28.5s-22.62-23.89-25.79-25c-4.44-1.58-41.12,12.08-50.8,9.32s24.22-23.75,27.24-25.92-19.78-21.68-15.13-24.7C697.22,727.32,726.25,733.83,735,737.38Z"',
                    " />",
                    " <circle",
                    ' class="c3-11"',
                    ' cx="688.04"',
                    ' cy="184.03"',
                    ' r="104.62"',
                    ' transform="translate(71.39 540.42) rotate(-45)"',
                    " />"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " <polygon",
                    ' class="c3-12"',
                    ' points="81.43 729.41 184.14 752.04 336.65 774.76 335.28 762.81 81.43 729.41"',
                    " />",
                    " <ellipse",
                    ' class="c3-13"',
                    ' cx="213.79"',
                    ' cy="765.45"',
                    ' rx="30.95"',
                    ' ry="121.45"',
                    ' transform="matrix(0.08, -1, 1, 0.08, -566.72, 915.17)"',
                    " />"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " <path",
                    ' class="c3-14"',
                    ' d="M307.53,852.88c3.6-.51,17.87-6,21.42-7.71l9.64-74.83-94.34-12.15-10.41,80.86a170,170,0,0,1,22,5.15Z"',
                    " />",
                    " <path",
                    ' class="c3-15"',
                    ' d="M214.62,838.44a165.92,165.92,0,0,1,19.22.61l10.41-80.86L79,736.9q-2.39,18.51-4.76,37c6.08,3.87,11.93,8.16,17.66,12.65C161.74,837.25,204.19,836.66,214.62,838.44Z"',
                    " />",
                    " <path",
                    ' class="c3-16"',
                    ' d="M95.65,757.63l-3.72,28.94c10.65,8.34,20.92,17.35,31.63,25.63,19.35,14.95,41.5,27.94,65.44,28.29,8.57.13,17.08-1.37,25.62-2q4.15-32.21,8.3-64.41Z"',
                    " />"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " <path",
                    ' class="c3-16"',
                    ' d="M307.53,852.88c1-3.84,8.52-66.15,8.52-66.15L264.14,780,256,844A114,114,0,0,0,307.53,852.88Zm-51.66-8.68"',
                    " />",
                    " <polygon",
                    ' class="c3-17"',
                    ' points="261.37 801.49 261.38 801.49 261.38 801.49 261.37 801.49"',
                    " />",
                    ' <path class="c3-18" d="M245.55,750.7c26.51-89,110.13-60.05,93,19.91Z" />'
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    ' <path class="c3-16" d="M272.94,738.14c11-34.27,52.4-21.15,45.78,9.8Z" />',
                    " <path",
                    ' class="c3-19"',
                    ' d="M314.11,699.53c-11.1-6.44-49.45-8.83-67.46,51.17L81.43,729.41c10.57-50.41,37.41-61.17,66-54.79C315.61,694.58,314.73,699.43,314.11,699.53Z"',
                    " />",
                    " <path",
                    ' class="c3-16"',
                    ' d="M146,674.24c45.14,6.12,68.51,8.77,125.25,16.47-20.52,7.13-35,28.55-40.83,39.73l-125-16.1C115.07,688.08,130.69,676.17,146,674.24Z"',
                    " />",
                    "</g>"
                )
            );
        } else if (index == 1) {
            background = string(
                abi.encodePacked(
                    '<g id="BGs">',
                    ' <rect class="c3-2" x="-5.31" y="-3.47" width="891.19" height="676.5" />',
                    ' <rect class="c3-3" x="-4.14" y="699.53" width="888.61" height="184.63" />',
                    ' <g class="c3-4">',
                    " <path",
                    '  class="c3-5"',
                    '  d="M599.92,694.89c-9.81,1.71-21.71,5.4-23.42,15.21-.85,4.82,1.23,9.89-.1,14.59-1.94,6.81-9.74,9.67-16.31,12.28s-13.92,7.77-12.91,14.77c.86,6,7.3,9.19,13,11.23,22.63,8.17,26.49,25.67,50.53,24.78,29.42-1.09,38-17.4,42-21.75,22.89-24.54,69.41-9,92.76-33.07,2.94-3,5.4-6.74,6-10.92,1.08-7.1-3.44-14.13-9.47-18C733.17,698.26,611.52,692.87,599.92,694.89Z"',
                    " />",
                    " </g>"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " <path",
                    ' class="c3-6"',
                    ' d="M81.56,93.73c-50.44,23-70.93,80.1-81.82,130.75-44.81,167,146,212,256.67,125.81C343.45,290,391,141.53,308.05,60.36c-56.27-55-268,2.71-274.67,22.85-8.44,25.65,94.71-11.79,106.88-16.33-1,.36,107.52-30.51,158.64,16.51,26.8,21.09,28,94.62,28.1,93.59,3.6,20.13-20.91,122.16-109.46,170.31s-161.28,4.48-160.46,5c-6.24-4.14-46.87-44.05-39.47-88.69,4.05-91,51.72-134.64,51-134,6.05-5.45,18.2-12.94,17.31-12.48C103.21,111.74,98.39,88.6,81.56,93.73Z"',
                    " />",
                    " <path",
                    ' class="c3-6"',
                    ' d="M15.87,205.39c46.31,5.19,52,5.68,102.23,7,24.61.64,34-18.7-14-22.52-1.08-.08-59.86-6.23-88.63-5.81Z"',
                    " />"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " <path",
                    ' class="c3-6"',
                    ' d="M105.5,130.17C60.34,278.29,93.58,281,97.39,254.32c5.71-40,21.8-94.45,21.49-93.5,2.07-9.82,9.92-19.32,7.89-29.48C123.79,122,109.43,121.07,105.5,130.17Z"',
                    " />",
                    " <path",
                    ' class="c3-6"',
                    ' d="M158.45,137.5c50.18-.13,148.41,4.08,147.38,4,10.32-.58,22,4.2,31.53-.39,8.28-5.25,5.47-19.47-4.33-20.85q-88-6-176.32-5.83C141.88,115.4,143.4,138.65,158.45,137.5Z"',
                    " />"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " <path",
                    ' class="c3-6"',
                    ' d="M284.55,38.52q-26.18,58.8-48.89,119c-3.54,14.56-28.37,55.21,1.72,50.14,12.85-2.16,32.61-85.83,53.41-125.65,4.08-14.08,16.28-27.58,15-42.37C302.78,30.31,288.6,29.43,284.55,38.52Z"',
                    " />",
                    " <path",
                    ' class="c3-6"',
                    ' d="M60.34,397.62c78.47-69.2,235.39-163.42,234.5-163a619.69,619.69,0,0,1,77.29-33.6c39.11-13.76,11.87-44.27-77.09,7.8C7.26,377.3,28.74,417.78,60.34,397.62Z"',
                    " />",
                    ' <path class="c3-7" d="M136.68,386.78A560.38,560.38,0,0,0,135,458.69" />',
                    ' <path class="c3-7" d="M156.45,378.51,154,429.22" />',
                    ' <path class="c3-7" d="M106.38,378.47c-2.79,9-3.68,33-2.81,42.4" />',
                    ' <path class="c3-7" d="M277.2,313.07a727.26,727.26,0,0,0-2.45,81.79" />'
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    ' <path class="c3-7" d="M262.28,327.89,260.13,372" />',
                    ' <g class="c3-4">',
                    " <path",
                    '  class="c3-5"',
                    '  d="M764.32,267.94c8.25-214.49-255.37-164.8-199.4,43.59,7.61,28.33-2.72,89.36,10.88,89.36,25.06,0,18.52-58.85,26.56-54.43,38,20.91-5.88,248.3,10.42,282.55,6.48,47.79,44.75,11.63,42.56-25.43C651.53,539,644.14,369.24,674.25,312c44.48-57.48,14.58,81.17,34.44,87.64,24,7.82,7.69-60.25,21.75-48.48C760.24,376.1,762.14,324.61,764.32,267.94Z"',
                    " />",
                    " </g>",
                    ' <rect class="c3-8" x="-5.04" y="644.2" width="891.42" height="57.31" />',
                    ' <rect class="c3-9" x="-5.04" y="642.82" width="891.42" height="9.66" />'
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    ' <g class="c3-4">',
                    " <path",
                    '  class="c3-5"',
                    '  d="M663.25,652.62c-3-3.27-5.06-7-8.72-9.8H615.35c-.37,2.91-4.91,9.81-4.91,9.81a11.13,11.13,0,0,0,2.13,14.46,13.46,13.46,0,0,0,15.72.63c1.4-1,2.81-2.34,4.56-2.2a4.5,4.5,0,0,1,3.1,2.06c2.39,3.26,3.58,26.15,3.87,34.08,4.16-.37,11,0,15.19-.13,1,0,2-23.71,7.86-33.59C665.42,663.63,663.25,652.62,663.25,652.62Z"',
                    " />",
                    " </g>",
                    " <polyline",
                    ' class="c3-10"',
                    ' points="568.17 -24.11 560.54 94.67 722.91 221.08 831.89 249.41"',
                    " />"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    ' <line class="c3-10" x1="639" y1="157.88" x2="652.08" y2="298.45" />',
                    ' <g class="c3-11">',
                    " <ellipse",
                    '  class="c3-12"',
                    '  cx="747.69"',
                    '  cy="769.66"',
                    '  rx="12.64"',
                    '  ry="77.01"',
                    '  transform="translate(-29.98 1509.02) rotate(-89.38)"',
                    " />",
                    " </g>"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " <path",
                    ' class="c3-13"',
                    ' d="M815.51,725.32c-1.53-6.06-6.63-8.29-10.94-9.32s-45.15-5-45.15-5a11.6,11.6,0,0,1,1.4,1.46h0c1.49,1.84,3.21,5.16.41,8.69C755.79,728,697.72,764.54,717.1,766S796,774.58,802,774.14s8.82-4.73,10.31-11.57S817.05,731.39,815.51,725.32Z"',
                    " />",
                    " <path",
                    ' class="c3-14"',
                    ' d="M761.24,721.13c-4.27,5.24-26,5-31.73,5.14-.24,4.63-16,27.16-41.81,21.34-4.91-1.1-4,7.54-4,7.54s11.1,6.74,32.47,10.75c5.36.12,24.7-.23,32.8-2.26s-.68-25.33-.68-25.33,25.32-2,22.33-20.19c-.33-2-4.81-3.58-9.05-4.68A6.15,6.15,0,0,1,761.24,721.13Z"',
                    " />",
                    ' <g class="c3-11">',
                    ' <ellipse class="c3-15" cx="501.24" cy="801.36" rx="85.6" ry="16" />',
                    " </g>"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " <path",
                    ' class="c3-14"',
                    ' d="M541.11,782.67c-11.1-6.87-4.3-28.78-4.3-28.78s-24.4,4.26-35.84-7c0,0,18.3,37.23,27.3,40.23C535.2,788.66,540.36,786.25,541.11,782.67Z"',
                    " />",
                    " <path",
                    ' class="c3-13"',
                    ' d="M556.49,794c-6.17-5.61-8.62-6.56-11.89-15,0,0-12.59,7.12-13.7,6.84-4.77-3.52-5.56-15.34-4.69-18.82,0,0-20.52-1.64-20.13-25.32-4.21-1.2-23.64,4.25-23.55,23.23L445.82,771s-9.82-1.87-12.24,5.46c-3.32,13.54,6.62,30.73,17.63,20l42.13-6.21C505.55,808.34,545.88,802.2,556.49,794Z"',
                    " />"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " <path",
                    ' class="c3-14"',
                    ' d="M544.73,809.32s-10.86,1.11-16.47,1.17-11.69-.28-11.69-.28a16.46,16.46,0,0,0,9.61,7.41c6.85,2,8.5,3.94,11.88,2.14S544.73,809.32,544.73,809.32Z"',
                    " />",
                    " <path",
                    ' class="c3-14"',
                    ' d="M506.48,814.61a20,20,0,0,0-3.74-1.52,10.41,10.41,0,0,0-5.76.32c-1.34.64-2.36,1.56-.93,2.12s4.2,2,6.92,2.12a14.92,14.92,0,0,0,4.2-.32Z"',
                    " />"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " <path",
                    ' class="c3-16"',
                    ' d="M443.22,785.48c-3.8-12.14-6.32-10.14-6-10-1.62,1.27-2.19,6.7-.46,12.43,1.57,5.22,4.6,8.88,6.59,9.7C443.16,797.71,447,797.61,443.22,785.48Z"',
                    " />",
                    ' <g class="c3-4">',
                    " <path",
                    '  class="c3-5"',
                    '  d="M196.21,883.65c5.27-2.92,9.14-6.8,10.27-12,1.37-6.29-2-12.91.16-19,3.15-8.88,15.84-12.62,26.53-16s22.64-10.13,21-19.26c-1.41-7.77-11.87-12-21.08-14.65C196.28,792,190,769.2,150.89,770.36c-47.86,1.42-61.74,22.69-68.35,28.37C61.2,817.08,27.23,818.24-5,821.81v61.84Z"',
                    " />",
                    " </g>",
                    ' <ellipse class="c3-17" cx="269.4" cy="861.6" rx="34.7" ry="15.51" />',
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

        if (colorIndex == 21) {
            background = string(
                abi.encodePacked(
                    "<defs>",
                    " <style>",
                    " .c3-1 {",
                    "  isolation: isolate;",
                    " }",
                    " .c3-2 {",
                    "  fill: url(#linear-gradient);",
                    " }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " .c3-3 {",
                    "  fill: url(#linear-gradient-2);",
                    " }",
                    " .c3-17,",
                    " .c3-4 {",
                    "  fill: #fff;",
                    " }",
                    " .c3-5 {",
                    "  fill: url(#linear-gradient-3);",
                    " }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " .c3-6 {",
                    "  fill: #f9cc3d;",
                    " }",
                    " .c3-7 {",
                    "  mix-blend-mode: soft-light;",
                    "  opacity: 0.6;",
                    " }",
                    " .c3-8 {",
                    "  fill: none;",
                    " }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " .c3-9 {",
                    "  fill: url(#linear-gradient-4);",
                    " }",
                    " .c3-10 {",
                    "  fill: url(#linear-gradient-5);",
                    " }",
                    " .c3-11 {",
                    "  fill: #fff9c4;",
                    " }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " .c3-12 {",
                    "  fill: #72381e;",
                    " }",
                    " .c3-13 {",
                    "  fill: #fff35c;",
                    " }",
                    " .c3-14 {",
                    "  fill: url(#linear-gradient-6);",
                    " }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " .c3-15 {",
                    "  fill: url(#linear-gradient-7);",
                    " }",
                    " .c3-16 {",
                    "  fill: #9f5731;",
                    " }",
                    " .c3-17 {",
                    "  fill-opacity: 0.1;",
                    " }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " .c3-18 {",
                    "  fill: url(#linear-gradient-8);",
                    " }",
                    " .c3-19 {",
                    "  fill: url(#linear-gradient-9);",
                    " }",
                    " </style>"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " <linearGradient",
                    ' id="linear-gradient"',
                    ' x1="440.67"',
                    ' y1="157.24"',
                    ' x2="440.67"',
                    ' y2="5.3"',
                    ' gradientUnits="userSpaceOnUse"',
                    " >",
                    ' <stop offset="0" stop-color="#dcfbff" />',
                    ' <stop offset="1" stop-color="#7fe0ff" />',
                    " </linearGradient>"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " <linearGradient",
                    ' id="linear-gradient-2"',
                    ' x1="440.67"',
                    ' y1="588.1"',
                    ' x2="440.67"',
                    ' y2="337.51"',
                    ' gradientUnits="userSpaceOnUse"',
                    " >",
                    ' <stop offset="0" stop-color="#71c7c0" />',
                    ' <stop offset="1" stop-color="#2dadce" />',
                    " </linearGradient>"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " <linearGradient",
                    ' id="linear-gradient-3"',
                    ' x1="405.61"',
                    ' y1="670.81"',
                    ' x2="675.67"',
                    ' y2="1297.29"',
                    ' gradientTransform="matrix(-1, 0, 0, 1, 871.66, 0)"',
                    ' gradientUnits="userSpaceOnUse"',
                    " >",
                    ' <stop offset="0" stop-color="#ffe9cf" />',
                    ' <stop offset="1" stop-color="#edb18f" />',
                    " </linearGradient>"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " <linearGradient",
                    ' id="linear-gradient-4"',
                    ' x1="325.25"',
                    ' y1="39.05"',
                    ' x2="74.61"',
                    ' y2="204.69"',
                    ' gradientTransform="translate(27.66 -6.07) rotate(3.83)"',
                    ' gradientUnits="userSpaceOnUse"',
                    " >",
                    ' <stop offset="0" stop-color="#8cc63f" />',
                    ' <stop offset="1" stop-color="#009245" />',
                    " </linearGradient>"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " <linearGradient",
                    ' id="linear-gradient-5"',
                    ' x1="744.3"',
                    ' y1="727.05"',
                    ' x2="747.89"',
                    ' y2="805.97"',
                    ' gradientUnits="userSpaceOnUse"',
                    " >",
                    ' <stop offset="0" stop-color="#f2843d" />',
                    ' <stop offset="1" stop-color="#e95e2e" />',
                    " </linearGradient>"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " <linearGradient",
                    ' id="linear-gradient-6"',
                    ' x1="218.1"',
                    ' y1="798.75"',
                    ' x2="318.86"',
                    ' y2="798.75"',
                    ' gradientTransform="translate(83.58 -11.93) rotate(4.75)"',
                    ' gradientUnits="userSpaceOnUse"',
                    " >",
                    ' <stop offset="0" stop-color="#ffbf40" />',
                    ' <stop offset="1" stop-color="#ffa05b" />',
                    " </linearGradient>"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " <linearGradient",
                    ' id="linear-gradient-7"',
                    ' x1="52.18"',
                    ' y1="791.63"',
                    ' x2="223.84"',
                    ' y2="791.63"',
                    ' href="#linear-gradient-6"',
                    " />"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " <linearGradient",
                    ' id="linear-gradient-8"',
                    ' x1="224.51"',
                    ' y1="723.18"',
                    ' x2="319.73"',
                    ' y2="723.18"',
                    ' href="#linear-gradient-6"',
                    " />"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " <linearGradient",
                    ' id="linear-gradient-9"',
                    ' x1="59.2"',
                    ' y1="712.38"',
                    ' x2="288.67"',
                    ' y2="712.38"',
                    ' href="#linear-gradient-6"',
                    " />",
                    "</defs>"
                )
            );
            background = string(
                abi.encodePacked(background, GetBackgroundShade(0))
            );
        } else if (colorIndex == 22) {
            background = string(
                abi.encodePacked(
                    "<defs>",
                    " <style>",
                    " .c3-1 {",
                    "  isolation: isolate;",
                    " }",
                    " .c3-2 {",
                    "  fill: url(#linear-gradient);",
                    " }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " .c3-3 {",
                    "  fill: #ffdb6e;",
                    " }",
                    " .c3-4 {",
                    "  fill: url(#linear-gradient-2);",
                    " }",
                    " .c3-5 {",
                    "  fill: #ffe49f;",
                    " }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " .c3-6 {",
                    "  fill: url(#linear-gradient-3);",
                    " }",
                    " .c3-7 {",
                    "  fill: url(#linear-gradient-4);",
                    " }",
                    " .c3-8 {",
                    "  mix-blend-mode: soft-light;",
                    "  opacity: 0.6;",
                    " }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " .c3-9 {",
                    "  fill: url(#linear-gradient-5);",
                    " }",
                    " .c3-10 {",
                    "  fill: url(#linear-gradient-6);",
                    " }",
                    " .c3-11 {",
                    "  fill: #72381e;",
                    " }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " .c3-12 {",
                    "  fill: #fff35c;",
                    " }",
                    " .c3-13 {",
                    "  fill: url(#linear-gradient-7);",
                    " }",
                    " .c3-14 {",
                    "  fill: url(#linear-gradient-8);",
                    " }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " .c3-15 {",
                    "  fill: #5e5731;",
                    " }",
                    " .c3-16 {",
                    "  fill: #9f5731;",
                    " }",
                    " .c3-17 {",
                    "  fill: #fff;",
                    "  fill-opacity: 0.1;",
                    " }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " .c3-18 {",
                    "  fill: url(#linear-gradient-9);",
                    " }",
                    " .c3-19 {",
                    "  fill: url(#linear-gradient-10);",
                    " }",
                    " </style>"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " <linearGradient",
                    ' id="linear-gradient"',
                    ' x1="440.03"',
                    ' y1="605.76"',
                    ' x2="440.03"',
                    ' y2="-9.42"',
                    ' gradientUnits="userSpaceOnUse"',
                    " >",
                    ' <stop offset="0" stop-color="#fff4b5" />',
                    ' <stop offset="0.3" stop-color="#ffdb6e" />',
                    ' <stop offset="0.5" stop-color="#ff73a9" />',
                    ' <stop offset="1" stop-color="#4261bd" />',
                    " </linearGradient>"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " <linearGradient",
                    ' id="linear-gradient-2"',
                    ' x1="441.78"',
                    ' y1="798.65"',
                    ' x2="441.78"',
                    ' y2="396.53"',
                    ' gradientUnits="userSpaceOnUse"',
                    " >",
                    ' <stop offset="0" stop-color="#db4b87" />',
                    ' <stop offset="0.6" stop-color="#4a53c9" />',
                    ' <stop offset="1" stop-color="#f7675f" />',
                    " </linearGradient>"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " <linearGradient",
                    ' id="linear-gradient-3"',
                    ' x1="451.63"',
                    ' y1="696.63"',
                    ' x2="358.45"',
                    ' y2="989.23"',
                    ' gradientUnits="userSpaceOnUse"',
                    " >",
                    ' <stop offset="0" stop-color="#ff6990" />',
                    ' <stop offset="0.95" stop-color="#7c1860" />',
                    " </linearGradient>"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " <linearGradient",
                    ' id="linear-gradient-4"',
                    ' x1="-9.65"',
                    ' y1="504.09"',
                    ' x2="164.34"',
                    ' y2="504.09"',
                    ' gradientUnits="userSpaceOnUse"',
                    " >",
                    ' <stop offset="0" stop-color="#9c005d" />',
                    ' <stop offset="0.43" stop-color="#ff73a9" />',
                    ' <stop offset="1" stop-color="#ffc36e" />',
                    " </linearGradient>"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " <linearGradient",
                    ' id="linear-gradient-5"',
                    ' x1="361.61"',
                    ' y1="203.13"',
                    ' x2="-14.35"',
                    ' y2="159"',
                    ' gradientUnits="userSpaceOnUse"',
                    " >",
                    ' <stop offset="0" stop-color="#059ca0" />',
                    ' <stop offset="1" stop-color="#472a4a" />',
                    " </linearGradient>"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " <linearGradient",
                    ' id="linear-gradient-6"',
                    ' x1="720.64"',
                    ' y1="726.16"',
                    ' x2="763.14"',
                    ' y2="796.45"',
                    ' gradientUnits="userSpaceOnUse"',
                    " >",
                    ' <stop offset="0" stop-color="#e95e2e" />',
                    ' <stop offset="1" stop-color="#811c5d" />',
                    " </linearGradient>"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " <linearGradient",
                    ' id="linear-gradient-7"',
                    ' x1="299.79"',
                    ' y1="795.37"',
                    ' x2="400.55"',
                    ' y2="795.37"',
                    ' gradientTransform="translate(1.89 -15.32) rotate(4.75)"',
                    ' gradientUnits="userSpaceOnUse"',
                    " >",
                    ' <stop offset="0" stop-color="#ffbf40" />',
                    ' <stop offset="1" stop-color="#ffa05b" />',
                    " </linearGradient>"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " <linearGradient",
                    ' id="linear-gradient-8"',
                    ' x1="133.87"',
                    ' y1="788.24"',
                    ' x2="305.53"',
                    ' y2="788.24"',
                    ' gradientTransform="translate(1.89 -15.32) rotate(4.75)"',
                    ' gradientUnits="userSpaceOnUse"',
                    " >",
                    ' <stop offset="0" stop-color="#ffa05b" />',
                    ' <stop offset="1" stop-color="#5b8994" />',
                    " </linearGradient>"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " <linearGradient",
                    ' id="linear-gradient-9"',
                    ' x1="306.2"',
                    ' y1="719.79"',
                    ' x2="401.42"',
                    ' y2="719.79"',
                    ' href="#linear-gradient-7"',
                    " />"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " <linearGradient",
                    ' id="linear-gradient-10"',
                    ' x1="140.88"',
                    ' y1="709"',
                    ' x2="370.36"',
                    ' y2="709"',
                    ' href="#linear-gradient-8"',
                    " />",
                    "</defs>"
                )
            );
            background = string(
                abi.encodePacked(background, GetBackgroundShade(0))
            );
        } else if (colorIndex == 23) {
            background = string(
                abi.encodePacked(
                    "<defs>",
                    " <style>",
                    " .c3-1 {",
                    "  isolation: isolate;",
                    " }",
                    " .c3-2 {",
                    "  fill: #ffbdc0;",
                    " }",
                    " .c3-3 {",
                    "  fill: #056b68;",
                    " }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " .c3-10,",
                    " .c3-11,",
                    " .c3-17,",
                    " .c3-4 {",
                    "  mix-blend-mode: multiply;",
                    " }",
                    " .c3-17,",
                    " .c3-4 {",
                    "  opacity: 0.49;",
                    " }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " .c3-17,",
                    " .c3-5 {",
                    "  fill: #a56734;",
                    " }",
                    " .c3-6 {",
                    "  fill: #8cc63f;",
                    " }",
                    " .c3-10,",
                    " .c3-7 {",
                    "  fill: none;",
                    "  stroke-miterlimit: 10;",
                    " }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " .c3-7 {",
                    "  stroke: #8cc63f;",
                    "  stroke-width: 5px;",
                    " }",
                    " .c3-8 {",
                    "  fill: #fff2d4;",
                    " }",
                    " .c3-9 {",
                    "  fill: #efd7a5;",
                    " }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " .c3-10 {",
                    "  stroke: #ddacb0;",
                    "  stroke-width: 4px;",
                    " }",
                    " .c3-12 {",
                    "  fill: #e6e6e8;",
                    " }",
                    " .c3-13 {",
                    "  fill: #78371e;",
                    " }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " .c3-14 {",
                    "  fill: #a04b30;",
                    " }",
                    " .c3-15 {",
                    "  fill: #e6e6e6;",
                    " }",
                    " .c3-16 {",
                    "  fill: #592515;",
                    " }",
                    " </style>",
                    "</defs>"
                )
            );
            background = string(
                abi.encodePacked(background, GetBackgroundShade(1))
            );
        } else if (colorIndex == 24) {
            background = string(
                abi.encodePacked(
                    "<defs>",
                    " <style>",
                    " .c3-1 {",
                    "  isolation: isolate;",
                    " }",
                    " .c3-2 {",
                    "  fill: #9ae4da;",
                    " }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " .c3-3 {",
                    "  fill: #740b00;",
                    " }",
                    " .c3-10,",
                    " .c3-11,",
                    " .c3-17,",
                    " .c3-4 {",
                    "  mix-blend-mode: multiply;",
                    " }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " .c3-17,",
                    " .c3-4 {",
                    "  opacity: 0.49;",
                    " }",
                    " .c3-17,",
                    " .c3-5 {",
                    "  fill: #871f4e;",
                    " }",
                    " .c3-6 {",
                    "  fill: #93278f;",
                    " }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " .c3-10,",
                    " .c3-7 {",
                    "  fill: none;",
                    "  stroke-miterlimit: 10;",
                    " }",
                    " .c3-7 {",
                    "  stroke: #93278f;",
                    "  stroke-width: 5px;",
                    " }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " .c3-8 {",
                    "  fill: #fff2d4;",
                    " }",
                    " .c3-9 {",
                    "  fill: #efd7a5;",
                    " }",
                    " .c3-10 {",
                    "  stroke: #98c7e5;",
                    "  stroke-width: 4px;",
                    " }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " .c3-12 {",
                    "  fill: #e6e6e8;",
                    " }",
                    " .c3-13 {",
                    "  fill: #117f20;",
                    " }",
                    " .c3-14 {",
                    "  fill: #48ba13;",
                    " }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " .c3-15 {",
                    "  fill: #e6e6e6;",
                    " }",
                    " .c3-16 {",
                    "  fill: #0b4f0f;",
                    " }",
                    " </style>",
                    "</defs>"
                )
            );
            background = string(
                abi.encodePacked(background, GetBackgroundShade(1))
            );
        } else {
            background = string(abi.encodePacked());
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