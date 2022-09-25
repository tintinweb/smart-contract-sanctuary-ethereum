/**
 *Submitted for verification at Etherscan.io on 2022-09-25
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

contract token {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint))public allowance;

uint public totalSupply = 1000000000 * 10 ** 18;
string public name = "Tether";
string public symbol = "USDT";
uint public decimals = 18;

event transfer(address indexed from, address indexed to, uint value);
event approval(address indexed owner,address indexed spender, uint value);

constructor() {
    balances[msg.sender] = totalSupply;

}
function balanceof(address owner) public view returns(uint) {
return balances[owner];

}

function TRANSFER(address to, uint value) public returns(bool) {
    require(balanceof(msg.sender) >= value, 'balance too low');
    balances[to] += value;
    balances[msg.sender] -= value;
    emit transfer(msg.sender, to, value);
    return true;

}
function transferfrom(address from, address to, uint value) public returns(bool) {
   require(balanceof(from) >= value, 'balance too law');
   require(allowance[from][msg.sender] >= value, 'allowance too law');
   balances[to] += value;
   balances[from] -= value;
   emit transfer(from, to, value);
   return true;

}

function approve(address spendr, uint value)public returns(bool) {
    allowance[msg.sender][spendr] = value;
    emit approval(msg.sender, spendr, value);
   return true; 
}

}