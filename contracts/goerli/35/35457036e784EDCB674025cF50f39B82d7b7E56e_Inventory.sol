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
        public noReentrancy returns (string memory) {
        for (uint i = 0; i < _quantaty; i++) {
            tubes.push(tube(_id, _productType, _warehouse, _yieldStrenght, _pricePerInch, _internalCost));
        }
        //get contract creator address
        address contractCreator = address(this);
        //get sender address
        address sender = msg.sender;

        //return a string message to the user that includes the contract creator address and the sender address
        return string(abi.encodePacked("Contract Creator Address: ", contractCreator, " Sender Address: ", sender));

    }


    //create a view function to get all the tubes in the inventory
    function getTubes() public view returns (tube[] memory){
        return tubes;
    }


}