//SPDX-License-Identifier:MIT

pragma solidity 0.8.17;

contract Variable {

    address owner;
    uint256 number;

    constructor(uint256 _num){
        owner = msg.sender;
        number = _num;
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
}