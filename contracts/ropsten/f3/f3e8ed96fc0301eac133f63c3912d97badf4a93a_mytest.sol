/**
 *Submitted for verification at Etherscan.io on 2022-03-21
*/

pragma solidity ^0.4.24;

contract mytest {
    string value;
    constructor() public {
        value = "myvalue789" ;
    }

    function get() public view returns(string) {
        return value ;
    }

    function set(string _value) public {
        value = _value;
    }
}