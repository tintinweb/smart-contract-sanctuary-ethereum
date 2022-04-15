/**
 *Submitted for verification at Etherscan.io on 2022-04-14
*/

pragma solidity ^0.4.24;

contract test {
   string value;
    constructor() public { value = "IbrahimAbdulwahab";
}

function get() public view returns(string) { 
    return value;
     }

function set(string _value) public{ 
    value = _value;
}
   }