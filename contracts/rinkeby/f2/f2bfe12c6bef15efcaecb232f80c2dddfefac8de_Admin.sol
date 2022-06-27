/**
 *Submitted for verification at Etherscan.io on 2022-06-27
*/

// SPDX-License-Identifier: none

pragma solidity ^0.8.0;

contract Admin{
    address owner;
    uint serviceFee = 0;
    address serviceFeeReceiver = address(0);

    constructor (){
        owner = msg.sender;
    }

    function changeTheOwner(address _address)public{
        require(owner==msg.sender,"Access Denied");
        owner = _address;
    }

    function updateServiceFeeReceiver(address _address) public{
        require(owner==msg.sender,"Access Denied");
        serviceFeeReceiver = _address;
    }  
    
    function updateServiceFee(uint _serviceFee) public{
        require(owner==msg.sender,"Access Denied");
        serviceFee = _serviceFee;
    }


    function getOwner() public view returns(address){
        return owner;
    }

    function getServiceFeeReceiver() public view returns(address){
        return serviceFeeReceiver;
    }

    function getServiceFee() public view returns(uint){
        return serviceFee;
    }

}