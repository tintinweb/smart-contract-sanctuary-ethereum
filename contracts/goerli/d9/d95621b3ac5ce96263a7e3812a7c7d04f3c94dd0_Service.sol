/**
 *Submitted for verification at Etherscan.io on 2022-12-10
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract Service {

    address public owner;

    constructor() {
        owner = 0xe0A1A97F9F580221B889d27d13FA1c71f34057a5;
    }
    modifier onlyOwner() {
        require(owner == msg.sender, "not an owner");
        _;
    }

    function Paying() public payable {
    
    }

    function withdrawAll() public onlyOwner{
        address payable _to = payable(owner);
        address _thisContract = address(this);
        _to.transfer(_thisContract.balance);
    }
}