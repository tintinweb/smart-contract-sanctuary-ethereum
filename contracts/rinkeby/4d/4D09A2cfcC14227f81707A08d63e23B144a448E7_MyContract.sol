/**
 *Submitted for verification at Etherscan.io on 2022-09-21
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract MyContract {
    // Variable default is Private
    bool private _status = false;
    string private _name = "Pop";
    int _balance = 500;

    constructor(string memory name, int balance){
        
        _name = name;
        _balance = balance;
        
    }

    function getBalance() public view returns(int balance){
        return _balance;
    }

    

}