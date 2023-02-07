/**
 *Submitted for verification at Etherscan.io on 2023-02-07
*/

//SPDX-License-Identifier:MIT

pragma solidity 0.8.17;

contract Variable {

    address owner;
    uint256 number;

    constructor(){
        owner = msg.sender;
    }

    function add(uint256 num) public {
        number = number + num;
    }

    function reduce(uint256 num) public {
        number = number - num;
    }

    function set (uint256 num) public {
        require(msg.sender == owner,"PermissionERROR: You are not allowed to set a variable.");
        number = num;
    } 

    function retrieve() public view returns (uint256){
        return number; 
    }

    function owneris() public view returns (bool){
        if(msg.sender == owner)
            return true;
        else
            return false;
    }

    function ownerAddress() public view returns (address){
        return owner;
    }
}