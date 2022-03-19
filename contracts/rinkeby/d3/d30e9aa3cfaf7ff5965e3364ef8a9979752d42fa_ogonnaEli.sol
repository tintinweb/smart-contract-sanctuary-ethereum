/**
 *Submitted for verification at Etherscan.io on 2022-03-19
*/

// SPDX-License-Identifier: MIT

// pragma solidity 0.8.0;
// pragma solidity ^0.8.0;

// pragma solidity >=0.4.22 <0.9.0;

pragma solidity 0.8.10;
contract ogonnaEli{
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

    string public constant name = "Ogonna Eli";
    string public constant symbol = "OE";
    uint8 public constant decimals = 18;

    //address is the key, uint256 is the value
    mapping(address => uint256) balances;
    mapping (address => mapping(address => uint256)) allowed;

    //declare total supply
    uint256 totalSupply_;
    constructor(uint256 total) {
        totalSupply_ = total;
        balances[msg.sender] = totalSupply_;
    }
    //get balance of owner
    function balanceOf(address tokenOwner) public view returns(uint){
        return balances[tokenOwner];
    }
    //transfer token to an account
    function transfer(address receiver, uint numTokens) public returns(bool) {
        require(numTokens <= balances[msg.sender]); // make sure that the account being transferred is greater tyan the owners balance
        balances[msg.sender] -= numTokens; //minus token from owners balances
        balances[msg.sender] += numTokens; // adds token to recievers balances
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }
    //approve a token transfer
    function approve(address delegate, uint numTokens) public returns(bool){
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }
    //get allowance status of an account
    function allowance(address owner, address delegate) public view returns (uint){
        return allowed[owner][delegate];
    }
    //
    function transferFrom(address owner, address buyer, uint numTokens)
  public returns(bool){
        require (numTokens <= balances[owner]);
        require(numTokens <= allowed[owner][msg.sender]);
        balances[owner] -= numTokens;
        allowed[owner][msg.sender] -= numTokens;
        balances[buyer] += numTokens;
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
event Received(uint value);

    function deposit() public payable {
        emit Received(msg.value);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    fallback() external payable {
        emit Received(msg.value);
    }

    receive() external payable {
        emit Received(msg.value);
    }


}