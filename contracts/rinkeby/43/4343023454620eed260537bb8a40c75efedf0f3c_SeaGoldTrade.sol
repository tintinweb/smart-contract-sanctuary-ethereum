/**
 *Submitted for verification at Etherscan.io on 2022-07-29
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface WETH9 {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

//"0xc721bf7a3539abdf8040b10c0908f33f88f97a79" buyback
// 0xc778417e063141139fce010982780140aa0cd5ab weth

contract SeaGoldTrade {
    function saleToken(address payable buyback) public payable {
        buyback.transfer(msg.value);
    }

    function AcceptBId(address ethAddr, uint256 amount) public {
        WETH9 convertToken = WETH9(ethAddr);
        convertToken.withdraw(amount);
        // buyback.transfer(amount);
    }
}