// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "../ownable.sol";

contract tesn is Ownable {
    uint message = 100;

    function reading() view public returns(uint){
        return message;
    }

    function writing(uint _num1, uint _num2) public onlyOwner {
        message = _num1 + _num2;
    }
}