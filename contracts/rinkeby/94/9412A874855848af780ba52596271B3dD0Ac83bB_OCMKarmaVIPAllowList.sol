// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

//   
//    ______     __   __     ______     __  __     ______     __     __   __    
//   /\  __ \   /\ "-.\ \   /\  ___\   /\ \_\ \   /\  __ \   /\ \   /\ "-.\ \   
//   \ \ \/\ \  \ \ \-.  \  \ \ \____  \ \  __ \  \ \  __ \  \ \ \  \ \ \-.  \  
//    \ \_____\  \ \_\\"\_\  \ \_____\  \ \_\ \_\  \ \_\ \_\  \ \_\  \ \_\\"\_\ 
//     \/_____/   \/_/ \/_/   \/_____/   \/_/\/_/   \/_/\/_/   \/_/   \/_/ \/_/ 
//                                                                              
//    __    __     ______     __   __     __  __     ______     __  __          
//   /\ "-./  \   /\  __ \   /\ "-.\ \   /\ \/ /    /\  ___\   /\ \_\ \         
//   \ \ \-./\ \  \ \ \/\ \  \ \ \-.  \  \ \  _"-.  \ \  __\   \ \____ \        
//    \ \_\ \ \_\  \ \_____\  \ \_\\"\_\  \ \_\ \_\  \ \_____\  \/\_____\       
//     \/_/  \/_/   \/_____/   \/_/ \/_/   \/_/\/_/   \/_____/   \/_____/       
//                                                                              
//   
// 
// OnChainMonkey (OCM) Genesis was the first 100% On-Chain PFP collection in 1 transaction 
// (contract: 0x960b7a6BCD451c9968473f7bbFd9Be826EFd549A)
// 
// created by Metagood
//
// OCM Karma VIP Allow List allows the holder to be first in line for a guaranteed spot to mint
// OCM Karma during the initial mint period. The nft will be burned when used.
//

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);
        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)
            for {
                let i := 0
            } lt(i, len) {
            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)
                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)
                mstore(resultPtr, out)
                resultPtr := add(resultPtr, 4)
            }
            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
            mstore(result, encodedLen)
        }
        return string(result);
    }
}

contract OCMKarmaVIPAllowList is ERC1155, Ownable {
    string constant private SVG1 = '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="1960" height="1961" fill="none"><style><![CDATA[.B{fill-rule:evenodd}.C{color-interpolation-filters:sRGB}]]></style><g clip-path="url(#L)"><path fill="#101010" d="M0 .302h1960v1960H0z"/><g filter="url(#D)"><circle cx="986" cy="980.3" r="640" fill="#fff" fill-opacity=".2"/></g><path d="M919.9 352.4c1.878 11.96-5.976 23.24-17.72 25.32l4.485 25.44c26.15-4.611 43.61-29.55 39.0-55.69-.087-.495-.182-.987-.284-1.476l.023-.004-6.652-37.73-18.5 3.261.294 1.666a48.13 48.13 0 0 0-8.152-3.35l7.431 42.15.76.43h-.004zm-68.93 11.75l.38.21-.075-.421.0.21z" fill="#acacac" class="B"/><mask id="A" fill="#fff"><path d="M523.6 342.4c-43.51 7.672-72.57 49.17-64.89 92.68L677.4 1676c7.672 43.51 49.17 72.56 92.68 64.89l729.1-128.6c43.51-7.67 72.56-49.16 64.89-92.67L1345 278.7c-7.68-43.51-49.17-72.57-92.68-64.89L523.6 342.4zm293.8 40.5c-14.98 2.64-24.98 16.92-22.34 31.9s16.92 24.98 31.9 22.34l173.0-30.51c14.98-2.641 24.98-16.92 22.34-31.9s-16.92-24.98-31.9-22.34l-173.0 30.51z" class="B"/></mask><path d="M523.6 342.4c-43.51 7.672-72.57 49.17-64.89 92.68L677.4 1676c7.672 43.51 49.17 72.56 92.68 64.89l729.1-128.6c43.51-7.67 72.56-49.16 64.89-92.67L1345 278.7c-7.68-43.51-49.17-72.57-92.68-64.89L523.6 342.4zm293.8 40.5c-14.98 2.64-24.98 16.92-22.34 31.9s16.92 24.98 31.9 22.34l173.0-30.51c14.98-2.641 24.98-16.92 22.34-31.9s-16.92-24.98-31.9-22.34l-173.0 30.51z" fill="#262626" class="B"/><path d="M770.1 1740l-2.432-13.79 2.432 13.79zm729.1-128.6l2.43 13.79-2.43-13.79zM827.0 437.1l2.431 13.79-2.431-13.79zm173.0-30.51l-2.429-13.79 2.429 13.79zm-527.5 26.02c-6.329-35.9 17.64-70.13 53.54-76.46l-4.862-27.57c-51.13 9.014-85.26 57.77-76.25 108.9l27.57-4.862zM691.2 1673L472.5 432.6l-27.57 4.862L663.7 1678l27.57-4.86zm76.46 53.53c-35.9 6.33-70.13-17.63-76.46-53.53l-27.57 4.86c9.015 51.13 57.77 85.26 108.9 76.25l-4.863-27.58zm729.1-128.6l-729.1 128.6 4.863 27.58 729.1-128.6-4.86-27.58zm53.53-76.45c6.33 35.89-17.64 70.12-53.53 76.45l4.86 27.58c51.12-9.02 85.26-57.77 76.25-108.9l-27.58 4.87zM1332 281.2l218.7 1240 27.58-4.87-218.7-1240-27.57 4.862zm-76.46-53.54c35.9-6.33 70.13 17.64 76.46 53.54l27.57-4.862c-9.01-51.13-57.77-85.26-108.9-76.25l4.86 27.58zm-729.1 128.6l729.1-128.6-4.86-27.58-729.1 128.6 4.862 27.57zm282.8 56.18a13.54 13.54 0 0 1 10.98-15.68l-4.862-27.58c-22.59 3.984-37.67 25.53-33.69 48.12l27.57-4.862zm15.68 10.98a13.54 13.54 0 0 1-15.68-10.98l-27.57 4.862c3.983 22.59 25.53 37.67 48.12 33.69l-4.862-27.57zm173.0-30.51l-173.0 30.51 4.862 27.57 173.0-30.51-4.859-27.57zm10.98-15.68a13.54 13.54 0 0 1-10.98 15.68l4.859 27.57c22.59-3.983 37.68-25.53 33.69-48.12l-27.57 4.862zm-15.68-10.98a13.54 13.54 0 0 1 15.68 10.98l27.57-4.862c-3.98-22.59-25.52-37.67-48.11-33.69l4.862 27.58zm-173.0 30.51l173.0-30.51-4.862-27.58-173.0 30.51 4.862 27.58z" fill="url(#F)" mask="url(#A)"/><mask id="B" maskUnits="userSpaceOnUse" x="457" y="212" width="1109" height="1530" mask-type="alpha"><rect x="444.8" y="356.3" width="900.4" height="1420" rx="80" transform="rotate(350 444.8 356.3)" fill="#262626"/></mask><g mask="url(#B)"><g filter="url(#E)"><path d="M585.7 1155l765.2-845.0 77.42 439.0-765.2 845.0-77.41-439.0z" fill="#fff" fill-opacity=".2"/></g></g><path d="M773.8 1541l5.432 30.81-5.818 1.03-5.432-30.81 5.818-1.03zm18.49-3.26l-9.707 17.2-5.735 8.8-2.033-5.46 3.786-7.24 6.559-12.04 7.13-1.26zm-1.042 31.95l-12.13-12.74 3.504-4.5 15.54 16.02-6.919 1.22zm34.6-33.04l-4.173 27.68-6.157 1.08 6.078-32.83 3.936-.7.316 4.77zm11.95 24.83l-13.43-24.57-1.353-4.58 3.957-.7 17.01 28.76-6.178 1.09zm-2.421-11.37l.81 4.59-16.52 2.91-.81-4.59 16.52-2.91zm23.67-24.14l11.19-1.97c2.341-.41 4.413-.42 6.216-.01s3.278 1.23 4.424 2.45 1.898 2.84 2.254 4.86c.281 1.6.242 3.03-.115 4.3a8.18 8.18 0 0 1-1.873 3.36c-.877.0-1.966 1.8-3.268 2.5l-1.656 1.25-9.881 1.74-.851-4.58 7.384-1.31c1.199-.21 2.156-.59 2.871-1.16.715-.56 1.205-1.25 1.468-2.07.277-.82.33-1.7.162-2.66-.182-1.03-.536-1.89-1.063-2.57a4.03 4.03 0 0 0-2.108-1.43c-.876-.27-1.927-.3-3.155-.08l-5.374.95 4.623 26.21-5.819 1.03-5.432-30.81zm22.82 27.74l-9.563-12.54 6.154-1.1 9.598 12.24.53.3-6.242 1.1zm24.6-36.1l5.036-.89 12.51 21.71 4.311-24.67 5.056-.9-6.014 32.83-4.041.71-16.86-28.79zm-2.538.45l4.929-.87 4.646 21.15 1.675 9.5-5.819 1.02-5.431-30.8zm27.04-4.77l4.951-.87 5.432 30.8-5.818 1.03-1.675-9.5-2.89-21.46zm41.66-2.53l-4.173 27.68-6.157 1.09 6.078-32.84 3.935-.69.32 4.76zm11.95 24.84l-13.43-24.57-1.353-4.59 3.956-.69 17.01 28.76-6.178 1.09zm-2.42-11.38l.81 4.6-16.52 2.91-.809-4.59 16.52-2.92zm64.87-26.57l-4.18 27.67-6.15 1.09 6.07-32.84 3.94-.69.32 4.77zm11.95 24.83l-13.43-24.57-1.36-4.59 3.96-.69 17 28.76-6.17 1.09zm-2.42-11.37l.81 4.59-16.53 2.91-.81-4.59 16.53-2.91zm47.84-1.35l.81 4.57-15.49 2.73-.8-4.57 15.48-2.73zm-18.35-23.82l5.43 30.81-5.82 1.03-5.43-30.81 5.82-1.03zm59.13 16.63l.81 4.57-15.49 2.73-.81-4.57 15.49-2.73zm-18.36-23.82l5.43 30.81-5.81 1.03-5.44-30.81 5.82-1.03zm61.09 4.31l.28 1.59c.41 2.32.47 4.47.17 6.44-.29 1.96-.9 3.69-1.81 5.19s-2.1 2.73-3.56 3.7c-1.45.97-3.15 1.63-5.08 1.97-1.91.33-3.72.3-5.43-.11-1.7-.42-3.25-1.17-4.63-2.26-1.39-1.1-2.56-2.51-3.52-4.25-.96-1.75-1.65-3.79-2.06-6.11l-.28-1.59c-.41-2.34-.47-4.49-.16-6.45s.92-3.69 1.84-5.19c.91-1.51 2.09-2.76 3.55-3.73 1.47-.97 3.16-1.62 5.06-1.96 1.94-.34 3.75-.3 5.46.11 1.7.41 3.23 1.17 4.61 2.28 1.38 1.1 2.55 2.51 3.5 4.25.96 1.74 1.64 3.78 2.06 6.12zm-5.61 2.62l-.28-1.63c-.3-1.67-.71-3.12-1.25-4.34-.53-1.23-1.18-2.22-1.94-2.99s-1.63-1.29-2.59-1.57c-.97-.3-2.01-.35-3.13-.15-1.13.2-2.09.6-2.88 1.21-.79.59-1.4 1.37-1.86 2.35-.45.98-.72 2.14-.82 3.49-.09 1.32.02 2.82.31 4.5l.29 1.63c.29 1.66.71 3.11 1.25 4.34.55 1.22 1.2 2.23 1.97 3.01.77.77 1.64 1.3 2.59 1.59.95.3 1.99.35 3.12.15s2.09-.6 2.89-1.21c.79-.6 1.41-1.39 1.85-2.37.45-1 .71-2.16.8-3.5.08-1.34-.02-2.84-.32-4.51zm37.26 2.4l1.74-25.98 3.32-.59 1.14 5.21-2.05 26.72-3.51.61-.64-5.97zm-8.27-24.22l9.42 23.93 1.05 5.99-3.83.67-12.41-29.57 5.77-1.02zm24.27 21.2l.59-25.58 5.8-1.03-1.55 32.04-3.83.68-1.01-6.11zm-9.35-23.83l10.54 23.91 1.39 5.75-3.51.62-11.05-24.43-.67-5.27 3.3-.58zm89.06 11.35l.8 4.57-15.49 2.73-.8-4.57 15.49-2.73zm-18.36-23.82l5.43 30.81-5.82 1.03-5.43-30.81 5.82-1.03zm41.15-7.25l5.44 30.8-5.82 1.03-5.43-30.81 5.81-1.02zm43.76 15.8c-.1-.59-.28-1.11-.55-1.54-.25-.45-.65-.82-1.18-1.12-.52-.32-1.23-.59-2.13-.81-.88-.23-2.01-.44-3.38-.62-1.52-.2-2.95-.47-4.29-.82-1.34-.34-2.55-.8-3.62-1.38-1.07-.59-1.95-1.32-2.64-2.2-.69-.9-1.16-1.99-1.39-3.29-.22-1.27-.16-2.47.2-3.61a7.99 7.99 0 0 1 1.85-3.1c.87-.94 1.94-1.73 3.22-2.38 1.3-.65 2.77-1.12 4.42-1.41 2.29-.4 4.34-.34 6.15.2 1.82.54 3.32 1.44 4.49 2.7s1.91 2.78 2.22 4.56l-5.8 1.02c-.17-.96-.52-1.77-1.06-2.43-.52-.66-1.23-1.13-2.12-1.41-.88-.28-1.94-.32-3.16-.1-1.19.21-2.14.56-2.87 1.05-.72.49-1.22 1.07-1.5 1.75a3.76 3.76 0 0 0-.22 2.13 3.07 3.07 0 0 0 .67 1.46c.35.39.82.73 1.43 1.03.6.29 1.33.53 2.18.73l2.96.48c1.78.21 3.37.51 4.74.91 1.4.39 2.59.91 3.57 1.55 1 .64 1.8 1.42 2.4 2.33.61.91 1.03 1.99 1.25 3.25.23 1.32.18 2.55-.16 3.69-.34 1.13-.93 2.16-1.77 3.06-.85.91-1.92 1.67-3.22 2.29-1.29.62-2.77 1.08-4.45 1.37-1.49.27-3.01.33-4.55.2-1.52-.16-2.95-.53-4.27-1.13a9.36 9.36 0 0 1-3.38-2.59c-.93-1.13-1.54-2.53-1.84-4.21l5.84-1.03c.17.97.48 1.78.91 2.42a4.63 4.63 0 0 0 1.65 1.43c.66.32 1.41.5 2.24.56a10.68 10.68 0 0 0 2.61-.15c1.18-.21 2.13-.54 2.83-1 .72-.48 1.21-1.05 1.49-1.71.29-.66.37-1.37.23-2.13zm36.86-30.02l5.44 30.81-5.8 1.02-5.43-30.81 5.79-1.02zm9.57-1.68l.81 4.59-24.82 4.37-.81-4.59 24.82-4.37z" fill="url(#G)"/><path transform="rotate(350 754.8 1475)" fill="url(#H)" d="M754.8 1475h677.4v9.615H754.8z"/><path d="M817.7 1273l35.9-6.33c1.158-.2 2.202.08 3.133.84 1.037.61 1.624 1.31 1.76 2.08s.185 1.43.147 1.96l-14.57 129.6c-.409 4.45-2.93 7.08-7.563 7.9l-44.01 7.76c-4.632.82-7.902-.79-9.809-4.84l-58.0-116.8c-.22-.49-.398-1.12-.534-1.89s.114-1.61.75-2.52c.742-1.06 1.692-1.69 2.85-1.9l35.9-6.33c4.633-.82 7.902.8 9.809 4.84l31.0 68.57 5.677-75.04c.409-4.45 2.93-7.08 7.562-7.9zM1096 1363l-39.37 6.94c-1.42.25-2.73-.05-3.94-.9-1.21-.84-1.94-1.98-2.19-3.39l-21.99-124.7c-.25-1.42.05-2.73.9-3.94s1.98-1.94 3.39-2.19l39.38-6.95c1.41-.25 2.73.05 3.94.9s1.94 1.98 2.19 3.4l21.99 124.7c.25 1.41-.05 2.73-.9 3.94s-1.98 1.94-3.4 2.19zm166.1-168.6l57.52-10.14c18.53-3.27 33.71-1.83 45.54 4.31s19.12 17 21.87 32.57c2.74 15.57-.44 28-9.54 37.3-8.98 9.28-22.8 15.57-41.46 18.86l-12.55 2.21 6.5 36.87c.25 1.41-.05 2.73-.89 3.94-.85 1.21-1.98 1.94-3.4 2.19l-39.76 7.01c-1.42.25-2.73-.05-3.94-.9s-1.94-1.98-2.19-3.39l-21.99-124.7c-.25-1.41.05-2.73.9-3.94s1.98-1.94 3.39-2.19zm50.34 28.14l3.78 21.43 13.51-2.38c2.32-.41 4.23-1.61 5.74-3.6 1.48-2.12 1.94-4.79 1.37-8.01-.56-3.21-1.75-5.79-3.55-7.73s-4.25-2.63-7.33-2.09l-13.52 2.38z" fill="url(#I)"/><g class="B"><path d="M902.2 377.7h0l4.485 25.44h0c-26.15 4.611-51.08-12.85-55.7-39.0-.087-.495-.167-.989-.238-1.483l-.23.0-6.653-37.73 18.5-3.261.293 1.666c1.977-2.163 4.156-4.152 6.513-5.933l7.417 42.07.14.08.13.08.63.36.004-.001c2.327 11.89 13.57 19.8 25.31 17.73z" fill="#d9d9d9"/><path d="M697.5-33.13l70.51-32.88 95.97 205.8 19.79-226.2 77.5 6.781-31.54 360.5 7.332 15.72-9.078 4.233-1.583 18.09-31.34-2.741-28.51 13.29-7.676-16.46-9.978-.873 1.512-17.28L697.5-33.13z" fill="#8a8a8a"/></g><mask id="C" maskUnits="userSpaceOnUse" x="697" y="-67" width="241" height="397" mask-type="alpha"><path transform="matrix(-.9063 .422618 .422618 .9063 768.0 -66.01)" fill="#ff00f2" d="M0 0h77.8v400.0H0z"/></mask><g mask="url(#C)"><path transform="rotate(5 875.1 -125.2)" fill="#515151" d="M875.1-125.2h12.4v400.0h-12.4z"/></g><path fill="#fff" d="M821.8 254.3l119.7-21.1 14.12 80.06-119.7 21.1z"/><path transform="rotate(350 603.5 570.8)" stroke="url(#J)" stroke-width="16" d="M 603.5 570.8 L 1266 570.8 L 1266 1233 L 603.5 1233 Z"/><path d="M1185 730.7c-3.92.697-7.77 1.716-11.52 3.049-21.75-38.9-55.08-70.06-95.35-89.18-40.28-19.11-85.51-25.22-129.4-17.48a214.8 214.8 0 0 0-115.6 60.65 214.6 214.6 0 0 0-59.1 116.4c-3.985.033-7.961.393-11.89 1.079a71.59 71.59 0 0 0-46.2 29.42 71.52 71.52 0 0 0-11.86 53.45c3.294 18.68 13.88 35.29 29.43 46.17a71.59 71.59 0 0 0 53.48 11.85 72.53 72.53 0 0 0 11.54-3.038c21.74 38.91 55.05 70.1 95.33 89.22s85.51 25.23 129.4 17.48c43.92-7.73 84.33-28.93 115.6-60.67 31.32-31.73 51.97-72.42 59.09-116.4a72.25 72.25 0 0 0 11.88-1.091 71.6 71.6 0 0 0 46.2-29.42 71.57 71.57 0 0 0 11.86-53.45c-3.3-18.68-13.88-35.29-29.43-46.17s-34.78-15.14-53.48-11.85zM781.4 903.5c-.62.11-1.225.304-1.86.415a28.63 28.63 0 0 1-21.39-4.738c-6.219-4.352-10.45-11.0-11.77-18.47s.389-15.16 4.744-21.38a28.63 28.63 0 0 1 18.48-11.77c.634-.112 1.255-.221 1.892-.232.4 9.528 1.424 19.02 3.077 28.41a215.5 215.5 0 0 0 6.828 27.76zm234.5 104.1a171.8 171.8 0 0 1-128.3-28.43 171.6 171.6 0 0 1-70.63-110.8c-7.907-44.84 2.333-90.99 28.47-128.3s66.02-62.7 110.9-70.61 91.03 2.315 128.3 28.43 62.72 65.97 70.63 110.8c7.9 44.84-2.34 90.99-28.47 128.3s-66.02 62.7-110.9 70.61zm186.6-178.2c-.62.11-1.24.218-1.87.243-.4-9.532-1.44-19.03-3.1-28.42-1.65-9.391-3.93-18.66-6.81-27.75.62-.11 1.23-.318 1.85-.427 7.47-1.318 15.17.386 21.39 4.738a28.61 28.61 0 0 1 11.77 18.47 28.62 28.62 0 0 1-4.75 21.38c-4.35 6.217-11 10.45-18.48 11.77zm-151.6-35.73c-2.62.461-5.31-.135-7.49-1.658a10 10 0 0 1-4.12-6.464l19.74-3.48c.46 2.615-.14 5.307-1.67 7.483a10.01 10.01 0 0 1-6.46 4.119zm-152.6 16.73l19.74-3.48a10.01 10.01 0 0 1-1.661 7.484c-1.524 2.176-3.851 3.657-6.468 4.119a10.02 10.02 0 0 1-7.486-1.659 10.01 10.01 0 0 1-4.12-6.464zm201.5-35.53a38.36 38.36 0 0 1 .59 2.8c2.04 11.58-.6 23.51-7.35 33.14s-17.06 16.2-28.65 18.24a44.37 44.37 0 0 1-51.4-35.97c-.16-.944-.33-1.874-.38-2.838l8.35-1.471a28.57 28.57 0 0 0 11.77 18.47c6.22 4.352 13.91 6.056 21.39 4.738 7.47-1.318 14.12-5.552 18.48-11.77a28.62 28.62 0 0 0 4.74-21.38l22.46-3.959zm-240.4 42.39l20.62-3.637a28.6 28.6 0 0 0 11.77 18.47c6.219 4.353 13.91 6.057 21.39 4.739s14.13-5.552 18.48-11.77 6.062-13.91 4.744-21.38l20.64-3.639c.375 12.04-3.602 23.8-11.2 33.15a50.11 50.11 0 0 1-64.59 11.38c-10.33-6.181-18.09-15.88-21.86-27.31zm94.43-38.44l-105.7 18.64-3.727-21.13 105.7-18.64 3.726 21.13zm52.66-31.08l91.63-16.16 3.73 21.13-91.63 16.16-3.73-21.13zm-12.63 134.4c-65.39 11.53-114.6 42.34-110.0 68.78s61.46 38.56 126.9 27.03c65.4-11.53 114.6-42.32 110.0-68.78-4.67-26.46-61.45-38.56-126.9-27.03zm27.61 8.207c1.87-.33 3.79.096 5.35 1.184a7.17 7.17 0 0 1 2.94 4.617c.33 1.869-.1 3.792-1.19 5.346-1.08 1.554-2.75 2.612-4.62 2.942a7.14 7.14 0 0 1-5.34-1.185c-1.56-1.088-2.62-2.749-2.95-4.617s.1-3.791 1.19-5.345a7.16 7.16 0 0 1 4.62-2.942zm-50.75 8.948a7.16 7.16 0 0 1 5.348 1.184 7.15 7.15 0 0 1 1.756 9.963 7.16 7.16 0 0 1-9.968 1.757 7.15 7.15 0 0 1-1.756-9.962 7.16 7.16 0 0 1 4.62-2.942zm113.6 42.44l-155.1 27.34-.745-4.227 155.1-27.34.75 4.227z" fill="url(#K)"/></g><defs><filter id="D" x="-154" y="-159.7" width="2280" height="2280" filterUnits="userSpaceOnUse" class="C"><feFlood flood-opacity="0"/><feBlend in="SourceGraphic"/><feGaussianBlur stdDeviation="250"/></filter><filter id="E" x="545.7" y="270.1" width="922.7" height="1364" filterUnits="userSpaceOnUse" class="C"><feFlood flood-opacity="0"/><feBlend in="SourceGraphic"/><feGaussianBlur stdDeviation="20"/></filter><linearGradient id="F" x1="888.2" y1="278.1" x2="1135" y2="1676" xlink:href="#M"><stop stop-color="#00f9c0"/><stop offset=".26" stop-color="#00c2ff"/><stop offset=".5" stop-color="#0fedc0"/><stop offset=".755" stop-color="#00c2ff"/><stop offset="1" stop-color="#0fedc0"/></linearGradient><linearGradient id="G" x1="741.5" y1="1463" x2="858.5" y2="1750" xlink:href="#M"><stop offset=".007" stop-color="#0eedc0"/><stop offset=".244" stop-color="#00c2ff"/><stop offset=".438" stop-color="#0eedc0"/><stop offset=".891" stop-color="#00c2ff"/></linearGradient><linearGradient id="H" x1="784.2" y1="1467" x2="785.3" y2="1503" xlink:href="#M"><stop offset=".007" stop-color="#0eedc0"/><stop offset=".244" stop-color="#00c2ff"/><stop offset=".438" stop-color="#0eedc0"/><stop offset=".891" stop-color="#00c2ff"/></linearGradient><linearGradient id="I" x1="967" y1="1131" x2="1159" y2="1429" xlink:href="#M"><stop stop-color="#00c2ff"/><stop offset=".542" stop-color="#00f9c0"/><stop offset="1" stop-color="#00c2ff"/></linearGradient><linearGradient id="J" x1="933.4" y1="564.3" x2="933.4" y2="1243" xlink:href="#M"><stop/><stop offset=".745" stop-color="#898989" stop-opacity="0"/><stop offset="1" stop-color="#fff" stop-opacity=".16"/></linearGradient><linearGradient id="K" x1="817.9" y1="577.7" x2="1232" y2="1069" xlink:href="#M"><stop offset=".073" stop-color="#0fedc0"/><stop offset=".332" stop-color="#00c2ff"/><stop offset=".764" stop-color="#0fedc0"/></linearGradient><clipPath id="L"><path fill="#fff" transform="translate(0 .302)" d="M0 0h1960v1960H0z"/></clipPath><linearGradient id="M" gradientUnits="userSpaceOnUse"/></defs></svg>';

    address public karmaContract; // allowed to eat/burn Desserts

    constructor() ERC1155("OCMKarmaVIPAllowList") {}

    // owner will air drop nfts via this mint function, designed to minimize gas used for multiple mints
    // if ads.length > quantity.length, transaction will fail and no mints will go through
    // if ads.length < quantity.length, the extra values in quantity will be ignored
    function ownerMint(address[] calldata ads, uint256[] calldata quantity) external onlyOwner {
        for (uint256 i=0; i<ads.length; i++) {
          _mint(ads[i], 1, quantity[i], "");
        }
    }

    // owner will air drop nfts via this mint function
    function ownerMint1(address[] calldata ads) external onlyOwner {
        for (uint256 i=0; i<ads.length; i++) {
          _mint(ads[i], 1, 1, "");
        }
    }    

    function setKarmaContractAddress(address karmaContractAddress) external onlyOwner {
        karmaContract = karmaContractAddress;
    }

    function burnAllowListForAddress(address burnTokenAddress) external {
        require(msg.sender == karmaContract, "ad err");
        _burn(burnTokenAddress, 1, 1);
    }

    function uri(uint256 typeId) public view override returns (string memory) {
        require(typeId==1, "type err");
        bytes memory svg;
        svg = bytes(SVG1);
        return string(abi.encodePacked('data:application/json;base64,', Base64.encode(abi.encodePacked(
            '{"name": "Karma VIP Allow List","image": "data:image/svg+xml;base64,', Base64.encode(svg),'"}'))));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}