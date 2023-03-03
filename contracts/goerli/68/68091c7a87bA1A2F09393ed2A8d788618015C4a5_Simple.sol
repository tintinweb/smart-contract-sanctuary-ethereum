/**
 *Submitted for verification at Etherscan.io on 2023-03-03
*/

pragma solidity 0.8.19;

contract Simple {
    int public number;

    constructor(int argument) {
        number = argument;
    }

    function changeNumber(int argument) public {
        number = argument;
    }
}