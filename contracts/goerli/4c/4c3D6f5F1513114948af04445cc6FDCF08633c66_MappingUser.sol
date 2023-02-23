/**
 *Submitted for verification at Etherscan.io on 2023-02-23
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.0 <0.9.0;

interface IERC20 {

}

contract MappingUser {
    uint8 public var1;    
    uint16 public var2;    
    uint24 public var3;    
    uint32 public var4;    
    uint40 public var5;    
    uint48 public var6;    
    uint56 public var7;    
    uint64 public var8;
    uint128 public var9;    
    uint256 public var10;    

    string public str1;
    string public str2;

    bool public bool1;
    bool public bool2;

    address public add1;
    IERC20 public ierc20;

    mapping(address => uint) public map1;
    mapping(uint => uint) public map2;
    mapping (uint8 => uint16) public map3;

    mapping (address => mapping (address => address)) map4;
    mapping (uint => mapping (uint => bool)) map5;

    uint[] public arr1;
    address[] public arr2;

    constructor () {
        var1 = 251;
        var2 = 252;
        var3 = 253;
        var4 = 254;
        var5 = 255;
        var6 = 256;
        var7 = 257;
        var8 = 258;
        var9 = 259;
        var10 = 260;

        str1 = "Abobawbfjawbifawiruawvjrnawiurbawurabrwqrqt13t1ijtaongawngawiugbuaiwfifnwajfbwaufbwajkbfjakwhvlkawlfhahfkawhgwabgawbgawbgiwabgiawubgahbgkfwaofnivuwabfivwabvfouwabovufbwauvfbwaijvbfawbvfawbvfawbvfljwabvjfwbavjkwabvifbwajvbfwabvwanwta";
        str2 = "ABW";

        ierc20 = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
        map1[0xdAC17F958D2ee523a2206206994597C13D831ec7] = 1;
        map1[0x55350f984476a5E9f49c0db4FB5AcE12A4407C09] = 7;
        map2[640] = 41;
        map2[2] = 616;

        map3[5] = 5;

        map4[0xdAC17F958D2ee523a2206206994597C13D831ec7][0xdAC17F958D2ee523a2206206994597C13D831ec7] = 0x55350f984476a5E9f49c0db4FB5AcE12A4407C09;
        map5[6][51] = true;

    }

    function add() external {
        arr2[0] = 0x15e70216BB78FDEe1B6d1208C75f37b5978f8070;
        arr1[0] = 4;
        arr1[615] = 6;
    }
}