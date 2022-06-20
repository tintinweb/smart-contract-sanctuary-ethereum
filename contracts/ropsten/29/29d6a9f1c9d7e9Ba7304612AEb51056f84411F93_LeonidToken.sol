/**
 *Submitted for verification at Etherscan.io on 2022-06-20
*/

pragma solidity 0.8.7;

// SPDX-License-Identifier: GPL-3.0

contract LeonidToken {
    string public name ; 
    string public symbol ; 
    uint8 public decimals ;

    address owner; 

    uint256 public totalSupply ;
    mapping(address => uint)balances;
    mapping(address => mapping(address => uint256)) allowed ; 

    event Transfer(address from, address to, uint256 value);
    event Approve(address from, address spender, uint256 value);

    modifier HasEnoughTokens(address _address, uint256 value){
        require(_address.balance >= value, "ERC20 : not enough tokens");
        _;
    }

    constructor(){
        owner = msg.sender;
        name = "leonid_token" ; 
        symbol = "letk" ; 
        decimals = 18 ; 
    }

    function mint(address to, uint256 value) external {
        require(msg.sender == owner, "ERC20 : You are not owner");
        balances[to] += value ;
        totalSupply += value ;

        emit Transfer(address(0), to,  value);
    }

    function balanceOf(address to) external view returns(uint256) {
        return balances[to];
    }

    function transfer(address to, uint256 value) external HasEnoughTokens(msg.sender,  value) returns(bool) {
        balances[msg.sender] -= value; 
        balances[to] += value ; 

        emit Transfer(msg.sender, to, value);

        return true; 
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
        ) external HasEnoughTokens(from, value) returns(bool) {

        require(allowed[from][msg.sender] >= value, "ERC20 : no permission to spend");
        balances[from] -= value ; 
        balances[to] += value ;

        allowed[from][msg.sender] -= value;

        emit Transfer(from, to, value); 
        emit Approve(from, msg.sender, allowed[from][msg.sender]);

        return true;
    }

    function approve(address spender, uint256 value) external returns(bool){
        allowed[msg.sender][spender] = value;
        emit Approve(msg.sender, spender, value);
        return true; 
    }

    function allowance(address from, address spender) external view returns(uint256){
        return allowed[from][spender] ; 
    }
}