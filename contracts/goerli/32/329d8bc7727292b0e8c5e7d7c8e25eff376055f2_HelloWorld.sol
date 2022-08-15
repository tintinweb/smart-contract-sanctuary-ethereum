/**
 *Submitted for verification at Etherscan.io on 2022-08-15
*/

pragma solidity ^0.4.0;

contract HelloWorld {
    string value;

    constructor() public {
        value = "Hello World!";
    }

    function get() public view returns (string memory) {
        return value;
    }

    function set(string memory v) public {
        value = v;
    }
}