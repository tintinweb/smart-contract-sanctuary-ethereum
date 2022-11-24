/**
 *Submitted for verification at Etherscan.io on 2022-11-23
*/

pragma solidity 0.8.7;

contract Number {
    uint256 number = 0;

    function store(uint256 value) public {
        number = value;
    }
}