/**
 *Submitted for verification at Etherscan.io on 2023-02-24
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

contract Vault {

    address owner;
    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not an owner!");
        _;
    }

    function addFunds() external payable onlyOwner {


    }

    function withdrawFunds(address payable _to) external payable onlyOwner  {
        _to.transfer(address(this).balance);
    }

}