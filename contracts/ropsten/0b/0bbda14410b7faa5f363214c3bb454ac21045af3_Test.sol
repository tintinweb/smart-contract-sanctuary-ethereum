/**
 *Submitted for verification at Etherscan.io on 2022-02-14
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Test {

    uint test = 0;

    function uslessAdd256(uint256 value) external returns(uint256){
        test++;
        return value + value;
    }

    function uslessMul256(uint256 value) external returns(uint256){
        test++;
        return value << 1;
    }

}