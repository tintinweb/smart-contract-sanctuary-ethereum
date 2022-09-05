/**
 *Submitted for verification at Etherscan.io on 2022-09-05
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external;
}


contract TestUsdt{

    constructor(){

    }

    address usdtAddress = 0x111b4E60847bF1642c0B59FF44834bf2447E8597;

    function tranferFrom1() external{
        IERC20(usdtAddress).transferFrom(msg.sender, address(this), 1000000);
    }

}