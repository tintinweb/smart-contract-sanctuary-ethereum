/**
 *Submitted for verification at Etherscan.io on 2022-09-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


contract GalaxyCoder {

    address public owner; 
    mapping (address => uint) public payments; 

    constructor() {
        owner = msg.sender;
    }

    function payForNFT() public payable {
        payments[msg.sender] = msg.value;
    }

    function withdrawAll() public {
        address payable _to = payable(owner);
        address _thisContract = address(this);
        _to.transfer(_thisContract.balance);
    }
}