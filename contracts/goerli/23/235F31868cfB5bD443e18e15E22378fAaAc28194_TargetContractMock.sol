/**
 *Submitted for verification at Etherscan.io on 2023-03-23
*/

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.18;


interface LimitOrderManager {

    struct AddLimOrderParam {
        address tokenX;
        address tokenY;
        uint24 fee;
        int24 pt;
        uint128 amount;
        bool sellXEarnY;
        uint256 deadline;
    }

}

contract TargetContractMock {
    function addLiquidity(address tokenA, address to)
        external
        returns (uint256 i)
    {
        return 0;
    }

    function removeLiquidity(address tokenA, address to)
        external
        returns (uint256 i)
    {
        return 0;
    }

    function test1(address value1) external returns (uint256 i) {
        return 0;
    }



    function test2(address[] calldata l1) external returns (uint256 i) {
        return 0;
    }



    function test3(uint256 value2) external returns (uint256 i) {
        return 0;
    }



    function test4(uint256[] calldata l2) external returns (uint256 i) {
        return 0;
    }



    function test5(bool value3) external returns (uint256 i) {
        return 0;
    }



    function test6(bool[] calldata l3) external returns (uint256 i) {
        return 0;
    }



    function test7(string calldata value4) external returns (uint256 i) {
        return 0;
    }

    function test8(string[] calldata l4) external returns (uint256 i) {
        return 0;
    }

    function test9(
        address value1, 
        address[] calldata l1, 
        uint256 value2, 
        uint256[] calldata l2
    ) external returns (uint256 i) {
        return 0;
    }

    function test(
        bool value3, 
        bool[] calldata l3,
        string calldata  value4, 
        string[] calldata l4, 
        LimitOrderManager.AddLimOrderParam calldata value5, 
        LimitOrderManager.AddLimOrderParam[] calldata l5
    ) external returns (uint256 i) {
        return 0;
    }
}