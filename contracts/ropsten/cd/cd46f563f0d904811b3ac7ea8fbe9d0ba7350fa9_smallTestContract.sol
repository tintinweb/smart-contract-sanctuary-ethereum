/**
 *Submitted for verification at Etherscan.io on 2022-09-15
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

contract smallTestContract{
    address public contractOwner;
    address public contractAddress = address(this);
    
    constructor () payable {
        contractOwner = msg.sender;
    }


    modifier onlyOwner (){
        require(msg.sender == contractOwner, "Only the contract owner can execute.");
        _;
    }

    function endContract (address payable addr) public onlyOwner {
        selfdestruct(addr);
    }

}