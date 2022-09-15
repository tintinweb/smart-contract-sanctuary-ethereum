/**
 *Submitted for verification at Etherscan.io on 2022-09-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract MyContract {

    // state = attribute
    string _name;
    uint _balance;

    // method
    constructor(string memory n, uint b) {
        require(b >= 100, "Please input balance more than 100!!");
        _name = n;
        _balance = b;
    }

    function getBalance() public view returns (uint b) {
        return _balance;
    }
    function getStablePureValue() public pure returns(uint x) {
        return 50;
    }
    /*function deposite(uint amount) public  {
        _balance = _balance + amount;
    }*/

}