/**
 *Submitted for verification at Etherscan.io on 2022-08-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract Mytoken {
    uint public totalSupply;
    uint256 public unitsOneEthCanBuy;
    string public Name;
    string public Symbol;
    uint256 public decimal;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowances;
    address public Owner;
    constructor (uint256 total,string memory name,string memory symbol,uint256 decimals, uint256 tokenPrice)  {
        totalSupply = total;
        Owner = msg.sender;
        balances[Owner] = totalSupply;
        Name = name;
        Symbol = symbol;
        decimal = decimals;
        unitsOneEthCanBuy = tokenPrice;
    }

    function Balanceof(address tokenOwner) public view returns(uint256){
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint256 value) public returns(bool){
        require(value<= balances[msg.sender]);
        balances[receiver] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, receiver, value);
        return true;
    }
    event Transfer(address indexed from, address indexed to, uint tokens);

    function transferFrom(address sender, address receiver, uint value) public returns(bool){
        require(value<=balances[sender],"Less balance you have");
        balances[receiver]+=value;
        balances[sender] -= value;

        emit Transfer(sender, receiver, value); 
        return true;
    } 
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    function approve(address receiver,uint256 value) public returns(bool){
        allowances[msg.sender][receiver] = value;
        emit Approval(msg.sender,receiver,value);
        return true;
    }

    function allowance(address receiver) public view returns(uint256){
        return allowances[msg.sender][receiver];
    }

    receive() external payable {        
        // msg.value (in Wei) is the ether sent to the 
        // token contract
        // msg.sender is the account that sends the ether to the 
        // token contract
        // amount is the token bought by the sender
        uint256 amount = msg.value * unitsOneEthCanBuy;
        // ensure you have enough tokens to sell
        require(balances[Owner] >= amount, 
            "Not enough tokens");
        // transfer the token to the buyer
         balances[msg.sender] += amount;
        balances[Owner] -= amount;
        // _transfer(Owner, msg.sender, amount);
        // emit an event to inform of the transfer        
        emit Transfer(Owner, msg.sender, amount);
        
        // send the ether earned to the token owner
        payable(msg.sender).transfer(msg.value);
    }

}