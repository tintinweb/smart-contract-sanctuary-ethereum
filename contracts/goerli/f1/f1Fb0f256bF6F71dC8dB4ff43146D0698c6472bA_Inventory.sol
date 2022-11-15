/**
 *Submitted for verification at Etherscan.io on 2022-11-14
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

    
    //create a function to add a tube to the inventory. Get the sender address, if the sender address and contract address are the same, then add the tube to the inventory
    function addTubes(
        uint256 _id,
        string memory _productType,
        string memory _warehouse,
        uint _yieldStrenght,
        uint _pricePerInch,
        uint _internalCost,
        uint _quantaty)
        public {
            //get the sender address
            address sender = msg.sender;
            //get the contract address
            address contractAddress = address(this);
            //check if the sender address and contract address are the same
            require(sender == contractAddress, "You are not allowed to add tubes to the inventory");
            //add the tubes to the inventory
            for(uint i = 0; i < _quantaty; i++) {
                tubes.push(tube(_id, _productType, _warehouse, _yieldStrenght, _pricePerInch, _internalCost));
            }
    }
    

    //create a funcition to get all tubes
    function getTubes() public view returns (tube[] memory) {
        return tubes;
    }
}