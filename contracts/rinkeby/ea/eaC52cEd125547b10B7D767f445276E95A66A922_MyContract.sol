/**
 *Submitted for verification at Etherscan.io on 2022-05-05
*/

pragma solidity ^0.5.0;

contract MyContract {
    string value;

    constructor() public {
        value = "myValue";
    }

    function get() public view returns(string memory) {
        return value;
    }

    function set(string memory _value) public {
        value = _value;
    }
}