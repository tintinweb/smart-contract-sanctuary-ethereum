// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Test{
    uint256 number;

    constructor () {
        number=10;
    }
    function getNumber() public view returns(uint) {
        return number;
    }
    function updateNumber(uint256 _number ) public {
        number=_number;
    }
    function resetNumber()public{
        number=10;
    }
}