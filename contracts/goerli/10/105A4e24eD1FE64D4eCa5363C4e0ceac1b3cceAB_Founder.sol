// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
contract Founder {
    
    mapping(address => bool) private isFounder;
    address[] private pushFounders;

    function addFounder(address _ad) external{
        require(msg.sender == _ad,"Connect same wallet to add founder address");
        isFounder[_ad] = true;
        pushFounders.push(_ad);
    }

    function verifyFounder(address _ad) external view returns(bool condition){
        if(isFounder[_ad]){
            return true;
        }else{
            return false;
        }
    }

    function getAllFounderAddress() external view returns(address[] memory){
        return pushFounders;
    }    
}