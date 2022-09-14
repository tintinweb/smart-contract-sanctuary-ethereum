// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Founder{
    
    mapping(address => bool) private isFounder;
    address[] private pushFounders;

    function addFounder(address _ad) public{
        require(msg.sender == _ad,"Connect same wallet to add founder address");
        isFounder[_ad] = true;
        pushFounders.push(_ad);
    }

    function verifyFounder(address _ad) public view returns(bool condition){
        if(isFounder[_ad] == true){
            return true;
        }else{
            return false;
        }
    }

    function getAllFounderAddress() public view returns(address[] memory){
        return pushFounders;
    }    
}