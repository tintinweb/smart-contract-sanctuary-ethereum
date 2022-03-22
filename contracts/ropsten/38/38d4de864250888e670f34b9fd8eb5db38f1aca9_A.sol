/**
 *Submitted for verification at Etherscan.io on 2022-03-22
*/

pragma solidity ^0.4.24;

contract A {
    string value;
    constructor() public {
        value = "mytestvalue666";
    }


function get() public view returns(string){
    return value ;
}

function set(string _value) public {
    value = _value;
}

}