/**
 *Submitted for verification at Etherscan.io on 2022-09-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.4.26;

contract MyContract {
    string value;

    constructor() public {
        value="MyValue";
    }

    function get() public view returns (string){
        return value;
    }

    function set(string _value) public {
        value = _value;


    }


}