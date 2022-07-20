/**
 *Submitted for verification at Etherscan.io on 2022-07-20
*/

pragma solidity >= 0.5.0 < 0.7.0;
contract Metacoin {
    mapping (address => uint) balances;
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    constructor() public 
    {
               balances[msg.sender] = 10000;
    }

    function sendCoin(address receiver, uint amount) public returns(bool sufficient) 
    {
        if (balances[msg.sender] < amount) return false;
        balances[msg.sender] -= amount;
        balances[receiver] += amount;
        emit Transfer(msg.sender, receiver, amount);
        return true; 
    }
    function getBalance(address addr) public view returns(uint) 
    {
        return balances[addr];
    }
}