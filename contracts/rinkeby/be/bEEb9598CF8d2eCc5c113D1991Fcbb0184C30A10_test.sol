/**
 *Submitted for verification at Etherscan.io on 2022-06-22
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract test {

    address public owner;
    uint public a;
    address public dicky;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renderMS() external pure returns(bytes4) {
        return bytes4(keccak256("adjust(uint256)"));
    }

    function adjust(uint256 _num) external {
        a = _num;
        dicky = msg.sender;
    }

    function adjust2(uint256 _num) external onlyOwner {
        a = _num;
        dicky = msg.sender;
    }
}