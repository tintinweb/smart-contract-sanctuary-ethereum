/**
 *Submitted for verification at Etherscan.io on 2022-12-06
*/

pragma solidity ^0.8.0;

contract SomeContract {
    string public a;

    constructor(string memory _a) {
        a = _a;
    }

    function changeMeAString(string memory _a) public {
        a = _a;
    }
}