/**
 *Submitted for verification at Etherscan.io on 2022-07-29
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256 wad) external payable;

    function balanceOf(address) external returns (uint256);

    function approve(address guy, uint256 wad) external returns (bool);

    function totalSupply() external returns (uint256);

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) external;
}

//"0xc721bf7a3539abdf8040b10c0908f33f88f97a79" buyback
// 0xc778417e063141139fce010982780140aa0cd5ab weth

contract SeaGoldTrade {
    IWETH public wNative;

    function saleToken(address payable buyback, uint256 amount) public payable {
        (bool sent, ) = buyback.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

    receive() external payable {}

    function AcceptBId(address ethAddr, uint256 amount) public {
        wNative = IWETH(ethAddr);
        wNative.transferFrom(msg.sender, address(this), amount);
        wNative.withdraw(amount);
    }
}