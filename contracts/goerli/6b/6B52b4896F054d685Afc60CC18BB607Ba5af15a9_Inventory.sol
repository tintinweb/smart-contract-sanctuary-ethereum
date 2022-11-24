/**
 *Submitted for verification at Etherscan.io on 2022-11-23
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


contract Inventory {

    struct tube {
        uint256 id;
        string productType;
        string warehouse;
        uint yieldStrenght;
        uint pricePerInch;
        uint internalCost;
    }

    tube[] private tubes;



    // This modifier will prevent the function from being executed if the caller is not the owner
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    // This modifier will prevent reentrancy attacks. It will not allow the caller to call the function again until it has finished executing. 
    bool public locked;
    modifier noReentrancy() {
        require(!locked, "Reentrant call.");
        locked = true;
        _;
        locked = false;
    }




    
    //create a function to add a tube to the inventory. Get the sender address, if the sender address and contract address are the same, then add the tube to the inventory
    function addTubes(
        uint256 _id,
        string memory _productType,
        string memory _warehouse,
        uint _yieldStrenght,
        uint _pricePerInch,
        uint _internalCost,
        uint _quantaty)
        public onlyOwner noReentrancy {
        for (uint i = 0; i < _quantaty; i++) {
            tubes.push(tube(_id, _productType, _warehouse, _yieldStrenght, _pricePerInch, _internalCost));
        }
    }


    //create a view function to get all the tubes in the inventory
    function getTubes() public view onlyOwner returns (tube[] memory){
        return tubes;
    }


}