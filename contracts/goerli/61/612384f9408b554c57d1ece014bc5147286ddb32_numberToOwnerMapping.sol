/**
 *Submitted for verification at Etherscan.io on 2022-11-22
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;

contract numberToOwnerMapping{
    mapping(address => uint256) private numberToOwner;

    //number getter for provided address
    function getNumberForAddress(address _address) public view returns (uint256){
        return numberToOwner[_address];
    }
    
    //number setter for msg.sender
    function setNumberForSender(uint256 _number) public{
        numberToOwner[msg.sender] = _number;
    }

    //Additional function - number getter for msg.sender
    //In this case - no address providing needed
    function getNumberForSender() public view returns (uint256){
        return numberToOwner[msg.sender];
    }

    //Additional function - number setter for provided address (with address ownership validation)
    //In this case - everybody can try to set number for provided address
    function setNumberForAddress(address _address, uint256 _number) public{
        require(_address == msg.sender, "You are not the owner of provided address!");
        numberToOwner[_address] = _number;
    }

    //Additional function - reset mapped value for msg.sender
    function reset() public{
        delete numberToOwner[msg.sender];
    }
}