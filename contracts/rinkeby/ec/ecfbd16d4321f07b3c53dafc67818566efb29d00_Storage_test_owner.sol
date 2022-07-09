/**
 *Submitted for verification at Etherscan.io on 2022-07-09
*/

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.8;

contract Storage_test_owner{
    uint256 number;

    address public owner;

    constructor(){
        owner = msg.sender;
    }
    
    function store(uint256 _number) public onlyOwner{
        number = _number;
    }
     function getNumber() public view returns(uint256){
         return number;
    }

    modifier onlyOwner {
        (msg.sender == owner, "Only the contract's owner can call this function");
        _;
    }
}