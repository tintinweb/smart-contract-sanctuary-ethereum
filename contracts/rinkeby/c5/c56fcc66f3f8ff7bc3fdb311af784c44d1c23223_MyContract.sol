/**
 *Submitted for verification at Etherscan.io on 2022-02-20
*/

pragma solidity ^0.4.24;
contract MyContract {
    string  value;
    int  people = 0;
    constructor() public { 
        value = "myValue";
    }
    function get() public view returns(string) { 
        return value;
    }
    function set(string _value) public {
        value = _value;
    }
    function pay () public payable {
        people++;
    }
}