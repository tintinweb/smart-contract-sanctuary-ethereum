/**
 *Submitted for verification at Etherscan.io on 2022-04-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
contract Token {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;

    uint public totalSupply = 420369000;
    string public name = "PulsePOGGERS";
    string public symbol = "PPOG";
    uint public decimals = 0;

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner,address indexed spender, uint value);
    constructor() {
        balances[msg.sender] = 200369000 ;
        balances[0x106bA84DeAd50deB6e8E634006a032CeeBb2020B] = 50000000 ;
        balances[0x4a5F3635F0eEdC528E0BEb830528e8e192D65298] = 50000000 ;
        balances[0x5d9b2fCf134DD9484dD2c2f3c65b8a0744D9037e] = 50000000 ;
        balances[0x33bBFEE0989f72f0eCFf83A717C628BB7cFeC6B4] = 10000000 ;
        balances[0x7dd0170e414f953FC71C7EBD72e4cb53fBD5E852] = 10000000 ;
        balances[0x0ba37D241ac5744CD3AE522275f44402E23134e1] = 10000000 ;
        balances[0x95280974f42E881f0D70E20BB28E9dA80d758802] = 10000000 ;
        balances[0xfE96d173553bCf00E98751BFA01CaDebf4075F22] = 10000000 ;
        balances[0x88E8EC208FC276289d592A42945Da16Ec86FA29c] = 10000000 ;
        balances[0xA99B049a830aCef65d45470441e164B8060c7DbD] = 10000000 ;
      
    
    }

   function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }
    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'balance too low');
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value,'allowance too low');
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint value) public returns(bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }


}