/**
 *Submitted for verification at Etherscan.io on 2022-09-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract MyContract_sec2 {
    
    // Single-Line Comment

    /*
        Multiple-Line Comment
    */

    // Variable + access modifier : default private
    // State = Attribute
    string _name;
    uint _balance;

    constructor(string memory n , uint b) {
        require(b >= 100,"Please input balance more than 100!!");
        _name = n;
        _balance = b;
    }

    function getBalance() public view returns(uint b) {
        return _balance;
    }

    function getStaticValuePure() public pure returns(uint x) {
        return 50;
    }

    /*function deposite(uint amount) public {
        _balance = _balance + amount;
    }*/

}