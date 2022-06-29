// SPDX-License-Identifier: MIT
/* Copyright (c) Kohi Art Community, Inc. All rights reserved. */

/*
/*
///////////////////////////////////////////////////////////////////////////////////
//                                                                               //
//     @@@@@@@@@@@@@@                        @@@@                                // 
//               @@@@                        @@@@ @@@@@@@@                       // 
//               @@@@    @@@@@@@@@@@@@@@@    @@@@@@@          @@@@@@@@@@@@@@@@   // 
//               @@@@                        @@@@                                // 
//     @@@@@@@@@@@@@@                        @@@@@@@@@@@@@                       // 
//               @@@@                          @@@@@@@@@@@                       // 
//                                                                               //
///////////////////////////////////////////////////////////////////////////////////
*/

pragma solidity ^0.8.13;

struct SubpixelScale {
    uint32 value;
    uint32 scale;
    uint32 mask;
    uint32 dxLimit;
}

library SubpixelScaleMethods {
    function create(uint32 sampling)
        external
        pure
        returns (SubpixelScale memory ss)
    {
        ss.value = sampling;
        ss.scale = uint32(1) << ss.value;
        ss.mask = ss.scale - 1;
        ss.dxLimit = uint32(16384) << ss.value;
        return ss;
    }
}