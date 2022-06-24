/**
 *Submitted for verification at Etherscan.io on 2022-06-24
*/

pragma solidity ^0.8.7;

contract ACA {
    string name;
    mapping (address => uint) balances;
    
    constructor (string memory _name) {
    name = _name;
    }

    function mint(address _user, uint _amount) public {
    uint balance = balances[_user];
    balances[_user] = balance + _amount;
    }

    function balanceOf( address _user) view public returns(uint) {
        return balances[_user];
    }

    function transfer(address _to, uint _amount) public {
        balances[msg.sender] = balances[msg.sender] - _amount;
        balances[_to] = balances[_to] + _amount;
    }
}