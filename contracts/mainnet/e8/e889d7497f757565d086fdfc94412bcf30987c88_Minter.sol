/**
 *Submitted for verification at Etherscan.io on 2022-10-07
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface Mintersp {
    function purchaseTo(address _to, uint256 _projectId)
        external
        payable
        returns (uint256 tokenId);
}

contract Minter {
    address payable public owner;
    Mintersp mintersp;
    address payable public nei =
        payable(address(0x3724f1DA2EEa68faDBa7144c392A79bDC63a1154));
    address payable public nei2 =
        payable(address(0x7750177BDCB7152C95911aD9Bb74A63fB09021dB));

    constructor() {
        owner = payable(msg.sender);
        mintersp = Mintersp(0x934cdc04C434b8dBf3E1265F4f198D70566f7355);
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function mint() external onlyOwner {
        mintersp.purchaseTo{value: 1000000000000000000}(nei, 370);
        mintersp.purchaseTo{value: 1000000000000000000}(nei2, 370);
    }

    function withdraw() external {
        (bool success, ) = nei.call{value: address(this).balance}("");
        require(success);
    }

    function fund() external payable {}

    receive() external payable {}
}