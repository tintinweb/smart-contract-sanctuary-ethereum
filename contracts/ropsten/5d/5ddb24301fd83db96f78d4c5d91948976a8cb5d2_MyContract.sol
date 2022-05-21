/**
 *Submitted for verification at Etherscan.io on 2022-05-21
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MyContract
{

    //This is Attribute State Parameter (Smart Contract Storage)
    string _Name;
    int _Balance;
    
    constructor(string memory strName,int intBalance)
    {
        require(intBalance>0,"Balance should be more than '0'");
        _Name = strName;
        _Balance = intBalance;
    }

    function GetBalance() view public returns(int retBalance)
    {
        return _Balance;
    }


}