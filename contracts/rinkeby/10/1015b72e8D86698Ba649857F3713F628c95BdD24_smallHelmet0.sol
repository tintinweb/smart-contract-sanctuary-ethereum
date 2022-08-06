// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

pragma abicoder v2;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";



    /// @title Accessory SVG generator
    contract smallHelmet0 {

        function SH0(
            string memory PRIM,
            string memory SEC
        ) internal pure returns (string memory, string memory)
            {
            return
                ( "1Bun",
                    string(
                    abi.encodePacked(
                       "<defs><linearGradient id='linear-gradient' x1='960.13' y1='511.14' x2='960.13' y2='204.52' gradientUnits='userSpaceOnUse'><stop offset='0' stop-opacity='0.5'/><stop offset='0.14' stop-opacity='0.23'/><stop offset='1' stop-opacity='0'/></linearGradient></defs><g id='_4-HelmetSmall' data-name='4-HelmetSmall'><g id='_1Bun' data-name='1Bun'><path id='GB-03-Solid' d='M857.69,435.71c-56.16-47.18-49.42-140.27,0-188l2-1.92c58.28-54.44,150.84-58.11,209.81,7.25,44.07,48.85,43.72,140-4.26,182.63Z' style='fill:#",
                        PRIM,
                        "'/><path id='GB-04-Solid' d='M1043.28,425c27,11,41.34,30,36.34,55.33-4.37,22.16-23,31.38-42.89,30.73-12.17-.39-35.05-5.83-76.52-5.83s-64.36,5.44-76.52,5.83c-19.93.65-38.53-8.57-42.89-30.73C835.8,455,850.14,436,877.14,425c25.26-10.29,67.12-12.31,83.07-12.31S1018,414.75,1043.28,425Z' style='fill:#",
                        SEC,
                        "'/><path id='Grad' d='M1064.27,436.71c50-45,49.33-134.78,5.26-183.63-59-65.36-151.53-61.69-209.81-7.25l-2,1.92c-49.42,47.69-56.16,140.78,0,188-11.39,7.35-20.06,26.69-16.89,44.66,3.92,22.24,23,31.38,42.89,30.73,12.16-.39,35-5.83,76.52-5.83s64.35,5.44,76.52,5.83c19.93.65,38.31-8.61,42.89-30.73C1083.63,461,1077.63,447.05,1064.27,436.71Z' style='fill:url(#linear-gradient)'/><path id='Shad' d='M1064,437.71c-38-32.21-166.41-32.65-206.35-2-34.73-30.2-42.33-70.23-38.14-110.5-6.74,64.84,98.13,75.35,140.22,75.35,44.69,0,143.16-12.38,140.68-76C1104.64,364.81,1094.6,411,1064,437.71Zm-9.09-7c13.2,8.66,19.31,20.42,15.94,34.8-4.05,17.31-21.28,24.51-39.76,24-11.27-.31-32.48-4.56-70.92-4.56s-59.65,4.25-70.92,4.56c-18.48.5-35.71-6.7-39.76-24-3.37-14.38,2.74-26.14,15.94-34.8-19.33,11.36-28.89,28.23-24.67,49.62,4.36,22.16,23,31.38,42.89,30.73,12.16-.39,35-5.83,76.52-5.83s64.35,5.44,76.52,5.83c19.93.65,38.52-8.57,42.89-30.73C1083.84,459,1074.28,442.11,1055,430.75Z' style='opacity:0.2'/><path id='Hi' d='M900.39,419.89a293.19,293.19,0,0,1,60.78-5.83c11.32.06,36.44,1.66,61.92,6.29,25.22,4.58,18.93,26.6-5.88,21.31-38.34-8.17-76.23-6.6-114.6.48C877.45,446.78,876.35,424.62,900.39,419.89Zm19.76-179.37c4.29,11.21,23,15.2,34.51,15.76,12.89.64,34.23-1.43,42.88-12.47,7.71-9.83.36-19.21-10.17-24.12-11.75-5.47-32.07-6-44.47-3C932.24,219.27,915.16,227.45,920.15,240.52Z' style='fill:#fff;opacity:0.2'/><path id='Outline' d='M1043.28,425c27,11,41.34,30,36.34,55.33-4.37,22.16-23,31.38-42.89,30.73-12.17-.39-35.05-5.83-76.52-5.83s-64.36,5.44-76.52,5.83c-19.93.65-38.53-8.57-42.89-30.73C835.8,455,850.14,436,877.14,425c25.26-10.29,67.12-12.31,83.07-12.31S1018,414.75,1043.28,425ZM857.69,435.71c-56.16-47.18-49.42-140.27,0-188l2-1.92c58.28-54.44,150.84-58.11,209.81,7.25,44.07,48.85,43.72,140-4.26,182.63' style='fill:none;stroke:#000;stroke-linecap:round;stroke-linejoin:round;stroke-width:4px'/></g></g>"
                        )
                        )
                );
            }

        function SH1(
            string memory PRIM,
            string memory SEC
        ) internal pure returns (string memory, string memory)
            {
            return
                ( "2Balls",
                    string(abi.encodePacked(
                      "<defs><linearGradient id='linear-gradient' x1='963.1' y1='533.39' x2='963.1' y2='362.97' gradientUnits='userSpaceOnUse'><stop offset='0' stop-opacity='0.5'/><stop offset='0.14' stop-opacity='0.23'/><stop offset='1' stop-opacity='0'/></linearGradient></defs><g id='_4-HelmetSmall' data-name='4-HelmetSmall'><g id='_2Ball' data-name='2Ball'><path id='GB-03-Solid' d='M797.73,363a78.78,78.78,0,0,1,68.75,44.3c12.61,25.53,12.33,56.86-1.8,81.72-21.39,37.6-72.64,56.61-111.89,35.77-31.35-16.65-49.46-54.6-43.95-89.48a81.12,81.12,0,0,1,17.16-38C743.12,375.92,770.23,362.26,797.73,363Zm271,34.28a81.12,81.12,0,0,0-17.16,38c-5.51,34.88,12.6,72.83,44,89.48,39.24,20.84,90.49,1.83,111.88-35.77,14.13-24.86,14.41-56.19,1.8-81.72a78.78,78.78,0,0,0-68.75-44.3C1113,362.26,1085.84,375.92,1068.72,397.28Z' style='fill:#",
                    PRIM,
                    "'/><path id='Grad' d='M797.73,363a78.78,78.78,0,0,1,68.75,44.3c12.61,25.53,12.33,56.86-1.8,81.72-21.39,37.6-72.64,56.61-111.89,35.77-31.35-16.65-49.46-54.6-43.95-89.48a81.12,81.12,0,0,1,17.16-38C743.12,375.92,770.23,362.26,797.73,363Zm271,34.28a81.12,81.12,0,0,0-17.16,38c-5.51,34.88,12.6,72.83,44,89.48,39.24,20.84,90.49,1.83,111.88-35.77,14.13-24.86,14.41-56.19,1.8-81.72a78.78,78.78,0,0,0-68.75-44.3C1113,362.26,1085.84,375.92,1068.72,397.28Z' style='fill:url(#linear-gradient)'/><path id='Shad' d='M864.08,490c-21.73,36.92-72.4,55.4-111.29,34.75-17.86-9.49-31.42-25.89-38.76-44.7a91.84,91.84,0,0,0,35.41,28.58C787.35,526,834.93,515.73,864.08,490Zm228.08,18.63a91.84,91.84,0,0,1-35.41-28.58c7.35,18.81,20.9,35.21,38.77,44.7,38.88,20.65,89.55,2.17,111.28-34.75C1177.65,515.73,1130.07,526,1092.16,508.67Z' style='opacity:0.2'/><path id='Hi' d='M711,425.92a83,83,0,0,1,15-28.64c17.12-21.36,44.23-35,71.73-34.28a78.78,78.78,0,0,1,68.75,44.3,88.52,88.52,0,0,1,5.4,13.8c-.09-.17-.17-.35-.27-.52-14-26.48-31.87-50.73-77-49.54C728.52,372.77,713.85,420.46,711,425.92Zm118.12-5.56c7.63,9.42,22,13.09,21.72-1.74-.19-9.82-13.68-26.2-23.68-20C819.64,403.29,823.86,413.92,829.07,420.36Zm224.6,5.56a83,83,0,0,1,15-28.64c17.12-21.36,44.23-35,71.73-34.28a78.78,78.78,0,0,1,68.75,44.3,87.54,87.54,0,0,1,5.4,13.8c-.09-.17-.17-.35-.27-.52-14-26.48-31.87-50.73-77-49.54C1071.24,372.77,1056.57,420.46,1053.67,425.92Zm118.12-5.56c7.63,9.42,22,13.09,21.72-1.74-.19-9.82-13.68-26.2-23.68-20C1162.36,403.29,1166.58,413.92,1171.79,420.36Z' style='fill:#fff;opacity:0.2'/><path id='Outline' d='M797.73,363a78.78,78.78,0,0,1,68.75,44.3c12.61,25.53,12.33,56.86-1.8,81.72-21.39,37.6-72.64,56.61-111.89,35.77-31.35-16.65-49.46-54.6-43.95-89.48a81.12,81.12,0,0,1,17.16-38C743.12,375.92,770.23,362.26,797.73,363Zm271,34.28a81.12,81.12,0,0,0-17.16,38c-5.51,34.88,12.6,72.83,44,89.48,39.24,20.84,90.49,1.83,111.88-35.77,14.13-24.86,14.41-56.19,1.8-81.72a78.78,78.78,0,0,0-68.75-44.3C1113,362.26,1085.84,375.92,1068.72,397.28Z' style='fill:none;stroke:#000;stroke-linecap:round;stroke-linejoin:round;stroke-width:4px'/></g></g>"
                            ))
                );
            }

        function SH2(
            string memory PRIM,
            string memory SEC
        ) internal pure returns (string memory, string memory)
            {
            return
                ( "2buns",
                    string(abi.encodePacked(
                  "<defs><linearGradient id='a' x1='960.64' y1='591.21' x2='960.64' y2='261.06' gradientUnits='userSpaceOnUse'><stop offset='0' stop-opacity='.7'/><stop offset='.14' stop-opacity='.33'/><stop offset='1' stop-opacity='0'/></linearGradient></defs><g data-name='4-HelmetSmall'><g data-name='2Buns'><path d='M644.65 527.91C573.9 508.54 541.09 421.18 566 357.19l1-2.59c30.17-73.83 112.7-115.89 193.6-81.19 60.47 25.94 95.62 103 72.54 167.67Zm443.44-86.83c-23.81-62.68 12.06-141.73 72.54-167.67 80.9-34.7 163.43 7.36 193.6 81.19l1 2.59c24.93 64-7.88 151.35-78.63 170.72Z' style='fill:#",
                    PRIM,
                    "'/><path d='M808.76 440.58c29.12-1.31 50.09 9.95 56.15 35.05 5.3 22-7.73 38.11-26.1 45.87-11.21 4.73-34.27 9.36-71.94 26.71s-56.18 31.86-67.06 37.3c-17.84 8.93-38.59 8.33-51.82-10-15.14-20.92-10.07-44.18 9.86-65.46 18.64-19.92 55.82-39.26 70.3-45.93s53.35-22.32 80.61-23.54Zm384.38 23.57c14.48 6.67 51.66 26 70.3 45.93 19.92 21.28 25 44.54 9.86 65.46-13.24 18.3-34 18.9-51.82 10-10.88-5.44-29.39-20-67.06-37.3s-60.73-22-71.94-26.71c-18.37-7.76-31.41-23.91-26.1-45.87 6.06-25.1 27-36.36 56.15-35.05 27.26 1.19 66.12 16.87 80.61 23.54Z' style='fill:#",
                    SEC,
                    "'/><path d='M864.91 475.63c5.09 22-7.73 38.11-26.1 45.87-11.22 4.73-34.27 9.36-71.94 26.71s-56.18 31.86-67.06 37.3c-17.84 8.93-39 8.6-51.82-10-10.4-15-10.61-36.18-3.34-47.63-70.75-19.34-103.56-106.7-78.65-170.69l1-2.59c30.17-73.83 112.7-115.89 193.6-81.19 60.47 25.94 96.62 104 72.05 169 16.51 3.79 27.82 14 32.26 33.22Zm191.47 0c-5.09 22 7.73 38.11 26.1 45.87 11.21 4.73 34.27 9.36 71.94 26.71s56.18 31.86 67.06 37.3c17.84 8.93 39 8.6 51.82-10 10.4-15 10.61-36.18 3.34-47.63 70.75-19.37 103.56-106.73 78.63-170.72l-1-2.59c-30.17-73.83-112.7-115.89-193.6-81.19-60.48 25.94-95.35 99-72.05 169-16.49 3.82-27.8 14.03-32.24 33.25Z' style='opacity:.7000000000000001;fill:url(#a)'/><path d='M832.2 442.74c16.19-36.9 7-82.74-13.55-117.35 11.15 22.71-1.84 54-15.78 72.1-18.6 24.2-45.83 39.22-72.84 52.23-29.51 14.2-61 24.12-93.8 26.55-24.12 1.79-61.3-6.24-72-31.68 12 38.89 40.71 71.66 80.29 83.27-7.81 15.95-6.19 34.89 3.5 47.68 13.63 18 34 18.9 51.82 10 10.88-5.44 29.39-20 67.06-37.3s60.72-22 71.93-26.71c18.38-7.76 30.49-25.1 26.11-45.87-3.79-17.85-16-28.54-32.74-32.92Zm-7.49 61.53c-10.37 4.43-31.41 9.45-66.32 25.53s-52.4 28.81-62.51 33.8c-16.58 8.19-35.24 8.86-46.16-5.17-8.05-10.33-8.46-21.7-2.62-33.7 27.94-43.28 136.63-93.5 183.71-81.6 10.57 3.78 17.63 11.25 20 22.7 3.54 17.42-9.11 31.17-26.1 38.44Zm231.39-28.64c-4.38 20.77 7.73 38.11 26.11 45.87 11.21 4.73 34.27 9.36 71.94 26.71s56.17 31.86 67 37.3c17.84 8.93 38.19 8 51.83-10 9.68-12.79 11.3-31.73 3.49-47.68 39.58-11.61 68.28-44.38 80.29-83.27-10.73 25.44-47.91 33.47-72 31.68-32.78-2.43-64.28-12.35-93.8-26.55-27-13-54.24-28-72.84-52.23-13.94-18.12-26.93-49.39-15.78-72.1-20.52 34.61-29.74 80.45-13.55 117.35-16.72 4.41-28.93 15.1-32.69 32.92Zm14.13-9.8c2.34-11.45 9.4-18.92 20-22.7 47.08-11.9 155.77 38.32 183.71 81.6 5.84 12 5.43 23.37-2.62 33.7-10.92 14-29.58 13.36-46.15 5.17-10.11-5-27.6-17.72-62.52-33.8s-55.95-21.1-66.32-25.53c-17.02-7.27-29.67-21.02-26.1-38.44Z' style='opacity:.2'/><path d='M676.82 495.68A293.49 293.49 0 0 1 729.58 465c10.31-4.68 33.8-13.74 58.88-20.19 24.81-6.39 28.31 16.24 3.57 21.82-38.24 8.62-72 25.89-103.89 48.37-20.92 14.7-31.14-5-11.32-19.32Zm-57.09-171.19c8.58 8.39 27.26 4.18 37.94-.11 12-4.82 30.49-15.63 33.73-29.28 2.89-12.15-7.71-17.59-19.33-17.64-13-.06-31.64 7.94-41.65 15.86-8.6 6.81-20.69 21.39-10.69 31.17ZM1233.15 515c-31.89-22.48-65.65-39.75-103.89-48.37-24.75-5.58-21.25-28.21 3.57-21.82 25.08 6.45 48.57 15.51 58.88 20.19a293.83 293.83 0 0 1 52.76 30.72c19.86 14.28 9.59 33.98-11.32 19.28Zm57.72-221.64c-10-7.92-28.69-15.92-41.65-15.86-11.63.05-22.23 5.49-19.33 17.64 3.24 13.65 21.75 24.46 33.73 29.28 10.68 4.29 29.35 8.5 37.94.11 10-9.82-2.09-24.4-10.69-31.21Z' style='fill:#fff;opacity:.2'/><path d='M808.76 440.58c29.12-1.31 50.82 9.79 56.15 35.05 4.38 20.77-7.73 38.11-26.1 45.87-11.21 4.73-34.27 9.36-71.94 26.71s-56.18 31.86-67.06 37.3c-17.84 8.93-38.68 8.4-51.82-10-13.69-19.12-10.07-44.18 9.86-65.46 18.64-19.92 55.82-39.26 70.3-45.93s53.35-22.32 80.61-23.54Zm-164.11 87.33C573.9 508.54 541.09 421.18 566 357.19l1-2.59c30.17-73.83 112.7-115.89 193.6-81.19 60.47 25.94 95.62 101 72.54 167.67m359.94 23.07c14.48 6.67 51.66 26 70.3 45.93 19.92 21.28 23.86 45.62 9.86 65.46-13 18.46-34 18.9-51.82 10-10.88-5.44-29.39-20-67.06-37.3s-60.73-22-71.94-26.71c-18.37-7.76-29.85-25.12-26.1-45.87 4.46-24.67 26.24-37.25 56.15-35.05 27.27 1.97 66.18 16.87 80.67 23.54Zm-105.05-23.07c-23.81-66.68 12.06-141.73 72.54-167.67 80.9-34.7 163.43 7.36 193.6 81.19l1 2.59c24.93 64-7.88 151.35-78.63 170.72' style='fill:none;stroke:#000;stroke-linecap:round;stroke-linejoin:round;stroke-width:4px'/></g></g>"
                    ))
                );
            }


        function SH3(
            string memory PRIM,
            string memory SEC
        ) internal pure returns (string memory, string memory)
            {
            return
                ( "Ball",
                    string(abi.encodePacked(
                    "<g id='_4-HelmetSmall' data-name='4-HelmetSmall'><g id='BabyHair'><path id='GB-03-Solid' d='M970.12,507.71a2,2,0,0,1-1.5-.67c-.78-.89-19.2-22-17.39-48.32,1.94-28.07,18.43-41.31,42.6-52.56,11.85-5.52,38.05-21.6,25.33-51.74a2,2,0,0,1,3.69-1.56c14.47,34.29-17.27,52.24-27.33,56.93-27.79,12.93-38.71,26.27-40.3,49.21-1.7,24.66,16.22,45.18,16.4,45.38a2,2,0,0,1-.17,2.83A2,2,0,0,1,970.12,507.71Z' style='fill:#",
                    PRIM,
                    "'/><line id='Outline' x1='973.33' y1='505.8' x2='965.68' y2='505.64' style='fill:none;stroke:#000;stroke-linecap:round;stroke-linejoin:round;stroke-width:4px'/></g></g>"
                            )));
            }


        function SH4(
            string memory PRIM,
            string memory SEC
        ) internal pure returns (string memory, string memory)
            {
            return
                ( "BabyHair",
                    string(abi.encodePacked(
                    "<g id='_4-HelmetSmall' data-name='4-HelmetSmall'><g id='BabyHair'><path id='GB-03-Solid' d='M970.12,507.71a2,2,0,0,1-1.5-.67c-.78-.89-19.2-22-17.39-48.32,1.94-28.07,18.43-41.31,42.6-52.56,11.85-5.52,38.05-21.6,25.33-51.74a2,2,0,0,1,3.69-1.56c14.47,34.29-17.27,52.24-27.33,56.93-27.79,12.93-38.71,26.27-40.3,49.21-1.7,24.66,16.22,45.18,16.4,45.38a2,2,0,0,1-.17,2.83A2,2,0,0,1,970.12,507.71Z' style='fill:#",
                    PRIM,
                    "'/><line id='Outline' x1='973.33' y1='505.8' x2='965.68' y2='505.64' style='fill:none;stroke:#000;stroke-linecap:round;stroke-linejoin:round;stroke-width:4px'/></g></g>"
                    ))
                );
            }


        function SH5(
            string memory PRIM,
            string memory SEC
        ) internal pure returns (string memory, string memory)
            {
            return
                ( "Agro",
                    string(abi.encodePacked(
                   "<defs><linearGradient id='a-helmet' x1='960' y1='965.38' x2='960' y2='441.4' gradientUnits='userSpaceOnUse'><stop offset='0' stop-opacity='.7'/><stop offset='1' stop-opacity='0'/></linearGradient><linearGradient id='b-gear' x1='960' y1='1242.91' x2='960' y2='221.38' gradientUnits='userSpaceOnUse'><stop offset='0' stop-opacity='.7'/><stop offset='.14' stop-opacity='.33'/><stop offset='1' stop-opacity='0'/></linearGradient></defs><g data-name='4-HelmetSmall'><path d='M1200 441.4c153 23 269 128 311 194 41.76 65.64 28 100-9 134s-263 196-542 196-505-162-542-196-50.77-68.36-9-134c42-66 158-171 311-194Z' style='fill:#",
                    PRIM,
                    "'/><path d='M841.85 654.13C792.39 593.84 754.51 531.4 728.12 470c-26-60.44 18.38-87.62 71.06-105.16 19.29-6.42 33.37-9.83 49-35.68 13.24-21.89 25.45-39.65 42.31-62.79 21.07-28.93 46.51-45 69.51-45s48.44 16.08 69.51 45c16.86 23.14 29.07 40.9 42.31 62.79 15.63 25.85 29.71 29.26 49 35.68 52.68 17.54 97 44.72 71.06 105.16-26.39 61.38-64.27 123.82-113.73 184.11-34.67 42.26-61.92 71.25-115.92 71.25s-85.71-28.97-120.38-71.23Zm-445.15 92.3c-20 34-72.71 126-50 265 21.85 133.62 103.3 207 161.3 227 45.43 15.66 78.64-10.44 114-66 70-110 104.84-242.85 104.84-242.85C575.21 875.07 460.6 814.74 396.7 746.43Zm796.44 183.14S1228 1062.41 1298 1172.42c35.36 55.57 68.57 81.67 114 66 58-20 139.45-93.38 161.3-227 22.73-139-30-231-50-265-43.69 51.39-131.57 113.24-330.16 183.15Z' style='fill:#",
                    SEC,
                    "'/><path data-name='Grad' d='M1200 441.4c153 23 269 128 311 194 41.76 65.64 28 100-9 134s-263 196-542 196-505-162-542-196-50.77-68.36-9-134c42-66 158-171 311-194Z' style='opacity:.30000000000000004;fill:url(#a-helmet)'/><path data-name='Grad' d='M841.85 654.13C792.39 593.84 754.51 531.4 728.12 470c-26-60.44 18.38-87.62 71.06-105.16 19.29-6.42 33.37-9.83 49-35.68 13.24-21.89 25.45-39.65 42.31-62.79 21.07-28.93 46.51-45 69.51-45s48.44 16.08 69.51 45c16.86 23.14 29.07 40.9 42.31 62.79 15.63 25.85 29.71 29.26 49 35.68 52.68 17.54 97 44.72 71.06 105.16-26.39 61.38-64.27 123.82-113.73 184.11-34.67 42.26-61.92 71.25-115.92 71.25s-85.71-28.97-120.38-71.23Zm-445.15 92.3c-20 34-72.71 126-50 265 21.85 133.62 103.3 207 161.3 227 45.43 15.66 78.64-10.44 114-66 70-110 104.84-242.85 104.84-242.85C575.21 875.07 460.6 814.74 396.7 746.43Zm796.44 183.14S1228 1062.41 1298 1172.42c35.36 55.57 68.57 81.67 114 66 58-20 139.45-93.38 161.3-227 22.73-139-30-231-50-265-43.69 51.39-131.57 113.24-330.16 183.15Z' style='opacity:.7000000000000001;fill:url(#b-gear)'/><path d='M884.28 445.74c22.67-22-18.67-44-1.91-92 9.38-26.83 17.67-48.69 29.38-77.12 14.62-35.53-.19-39.2-21.26-10.27-16.86 23.14-29.07 40.89-42.31 62.79C838.37 345.41 827 356 808.86 362c-22.23 7.31-51.73 16.65-73.91 37.12-17.33 16-14.07 42.18-15.07 42.32L709 443.18c-7.1 38.23 67.42 153 119.52 220.42 36.51 47.24 76.85 82.74 133.72 82.74s93.46-36.75 130-84c52.09-67.39 125.27-180.86 119-219.09l-11.34-1.87c1.09-12.55-2.91-21.92-7.55-30.88 10.46 35.5-64.85 141.18-114.35 194.65-34.67 37.48-61.91 63.19-115.91 63.19s-85.71-25.71-120.38-63.19c-19.36-20.92-37.44-43.13-53-67.07-14.17-21.86-32-49.45-35.79-75.69-3.14-21.69 12.2-40.38 33.43-44.57 10.21-2 20.22 3.54 28.35 9.16 16.7 11.48 49.58 38.18 69.58 18.76Zm638.91 300.69 5 8.58c-15.93 38.54-115.42 136.16-290.87 192.84 17.8 61.46 79.42 258.78 146.46 295.88-28-3.08-44-19.74-44-19.74l-10 12.91c-70-36.81-130.92-198.5-155.4-271.43-63.47 15.18-135.09 24.68-214.6 24.92-80.14.24-151.56-8.65-214.49-23.28C721.67 1041 663 1201.36 590.2 1236.76l-9.35-13.71s-21 19.67-46.61 20c70.79-47.44 126.7-235 143.07-295C510.42 893.5 417 800.07 391.55 755.36l5.05-8.93c-12.42-24-19.26-44.7-4.58-79.52-2.32 26.26 11.53 45.75 34.12 65.11 36.71 31.46 256.93 194.37 533.75 194.37S1456.94 763.48 1493.65 732c22.58-19.36 36.44-38.84 34.12-65.1 14.78 35.1 8.41 59.39-4.58 79.53Z' style='opacity:.2'/><path d='M1575.59 907.11c5.49 38.88-.53 149.68-50.57 228.83-19.53 30.9-38.62 21.69-21.71-10.22 43.61-82.34 48.8-158.7 49-210.6.08-27.47 17.86-46.47 23.28-8.01Zm-1230.75 4.43c-5.68 38.27-.24 147.22 49.32 224.83 19.35 30.29 38.45 21.13 21.73-10.17-43.12-80.77-47.91-155.85-47.83-206.9.04-27.02-17.61-45.61-23.22-7.76Zm749.82-539.24c-35.74-9.05-41.36-28.91-72.37-84.91-13.26-23.94-32.75-17.86-24.51 8.79 15.52 50.21 37.84 89.79 63.52 102.21 31 15 62.6-18.68 33.36-26.09ZM985.6 238.16c-22.76-10.17-19.14 29.32 4.95 26.58 9.65-1.52 9.78-11.64 5-18-4.49-6.1-3.1-5.52-9.95-8.58Z' style='fill:#fff;opacity:.2'/><path d='M841.85 654.13C792.39 593.84 754.51 531.4 728.12 470c-26-60.44 18.38-87.62 71.06-105.16 19.29-6.42 33.37-9.83 49-35.68 13.24-21.89 25.45-39.65 42.31-62.79 21.07-28.93 46.51-45 69.51-45s48.44 16.08 69.51 45c16.86 23.14 29.07 40.9 42.31 62.79 15.63 25.85 29.71 29.26 49 35.68 52.68 17.54 97 44.72 71.06 105.16-26.39 61.38-64.27 123.82-113.73 184.11-34.67 42.26-61.92 71.25-115.92 71.25s-85.71-28.97-120.38-71.23ZM1200 441.4c153 23 269 128 311 194 41.76 65.64 28 100-9 134s-263 196-542 196-505-162-542-196-50.77-68.36-9-134c42-66 158-171 311-194m-323.28 305c-20 34-72.71 126-50 265 21.85 133.62 103.3 207 161.3 227 45.43 15.66 78.64-10.44 114-66 70-110 104.84-242.85 104.84-242.85m466.28 0S1228 1062.41 1298 1172.42c35.36 55.57 68.57 81.67 114 66 58-20 139.45-93.38 161.3-227 22.73-139-30-231-50-265' style='fill:none;stroke:#000;stroke-linecap:round;stroke-linejoin:round;stroke-width:4px'/></g>"
                    ))
                );
            }
        


        function getLibraryCount() public pure returns (uint256 ) {
                return 6;

        }

        function getHelmetSvg(string memory one, string memory two, uint256 rand) public pure returns (string memory, string memory ) {
            if (rand == 5) {
                return SH5(one, two);
            } else if (rand == 4) {
                return SH4(one, two);
            } else if (rand == 3) {
                return SH3(one, two);
            } else if (rand == 2) {
                return SH2(one, two);
            } else if (rand == 1) {
                return SH1(one, two);
            } else {
                return SH0(one, two);
            }

        }
    }

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}