/**
 *Submitted for verification at Etherscan.io on 2023-02-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract KinnzStorage {
    string private _name;
    uint storedData;
    address storedAddress;

    constructor () {
        _name = "Kinnz Storage";
    }


    function set(uint256 x) public {
        storedData += x;
    }

    function setAddress(address account) public {
        storedAddress = account;
    }

    function get() public view returns (uint256){
        return storedData;
    }
    
    function getAddress() public view returns(address){
        return msg.sender;
    }

    function nama() public view returns(string memory){
        return _name;
    }
    
    function getBlockTime() public view returns(uint256){
        return block.timestamp;
    }

}