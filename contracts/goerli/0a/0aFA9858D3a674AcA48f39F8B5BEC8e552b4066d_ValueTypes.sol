/**
 *Submitted for verification at Etherscan.io on 2023-03-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// Data types - values and references


contract ValueTypes {
    /**
    *
    */
    bool public b = true;   // boolean: true or false
    /**
    * uint (Unsigned int) 系列的型別
    * uinit8 = 8-bit 的 unsigne int, 能儲存的值範圍為： 0 ~ 2^8-1 (因為0也是其中一個，所以要扣1)
    * uint16 = 16-bit 的 unsigne int, 能儲存的值範圍為： 0 ~ 2^16-1
    * uint32 = 32-bit 的 unsigne int, 能儲存的值範圍為： 0 ~ 2^32-1
    * uint64 = 64-bit 的 unsigne int, 能儲存的值範圍為： 0 ~ 2^64-1
    * uint128 = 128-bit 的 unsigne int, 能儲存的值範圍為： 0 ~ 2^128-1
    * uint256 = 256-bit 的 unsigne int, 能儲存的值範圍為： 0 ~ 2^128-1
    */
    uint8 public u8 = 1;
    uint16 public u16 = 2;
    uint32 public u32 = 3;
    uint64 public u64 = 4;
    uint128 public u128 = 5;
    uint256 public u256 = 6;
    /**
    * int = int256, 其範圍為 -2**255 to 2**255 -1
    * ( -1 是因為 0 也是其中一位，另外因為其中一位元拿去存是正or負數，所以只有 255，而非 256)
    */
    /**
    * int 系列的型別
    * init8 = 8-bit 的 int, 能儲存的值範圍為： -2^7 ~ 2^7-1  ( 因為其中一位元拿去存是正or負數，所以只有 7，而非 8)
    * int16 = 16-bit 的 int, 能儲存的值範圍為： -2^15 ~ 2^15-1  
    * int32 = 32-bit 的 int, 能儲存的值範圍為： -2^31 ~ 2^31-1  
    * int64 = 64-bit 的 int, 能儲存的值範圍為：  -2^63 ~ 2^63-1  
    * int128 = 128-bit 的 int, 能儲存的值範圍為： -2^127 ~ 2^127-1  
    * int256 = 256-bit 的 int, 能儲存的值範圍為： -2^255 ~ 2^255-1  
    */
    int8 public i8 = 1;
    int16 public i16 = 2;
    int32 public i32 = 3;
    int64 public i64 = 4;
    int128 public i128 = 5;
    int256 public i256 = 6;
    // 如果記不得該型別的最小、最大值的話，能用 type(xxx).min / type(xxx).max 來看是多少;
    int public mintInt = type(int).min;
    int public maxInt = type(int).max;
    // 地址 型別 20bytes
    address public myAddr = 0x2d075f02ACcA69834aAD01AC0CA905F951aCB6b7;

    // bytes[N] = 宣告 N bytes 的變數 ( N 的範圍為 1 ~ 32 )
    bytes1 public b1 = 0xaa;

}