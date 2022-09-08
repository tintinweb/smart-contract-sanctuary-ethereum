/**
 *Submitted for verification at Etherscan.io on 2022-09-08
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

contract Test {

    uint256 number;

    constructor(uint256 _number){
        number = _number;
    }

    function setNumber(uint256 _number) public {
        number = _number;
    }

    function getNumber() public view returns(uint256) {
        return number;
    }

}