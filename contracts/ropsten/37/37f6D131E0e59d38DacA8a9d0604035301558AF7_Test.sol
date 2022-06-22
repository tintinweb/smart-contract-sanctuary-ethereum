/**
 *Submitted for verification at Etherscan.io on 2022-06-22
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.7;

contract Test{
    uint256 public totalSupply = 0;
    address owner;
    string public name;
    string public symbol;
    uint8  public  decimals;
    address public staking;

    mapping(address => mapping(address => uint256)) allowed;
    mapping(address => uint256) balances;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed from, address indexed spender, uint256 value); 
    
    constructor() {
        owner = msg.sender;
        name = "TokenB";
        symbol = "B";
        decimals = 21;
    }

    function setStacking(address _staking) public {
        require(msg.sender == owner, "ERC20: You are not owner");
        staking = _staking;
    }

    function approve(address from, uint256 value) public returns(bool) {
        allowed[from][msg.sender] = value;
        emit Approval(from, msg.sender, value);
        return true;
    }
    
    function allownce(address from, address spender) public view returns(uint256) {
        return allowed[from][spender];
    }

    function mint(address to, uint256 value) public {
        require((msg.sender == owner) || (msg.sender == staking), "ERC20: You are not owner");
        
        totalSupply += value;
        balances[to] += value;
        emit Transfer(address(0), to, value);
    }

    function transfer(address to, uint256 value) public returns(bool) {
        require(balances[msg.sender] >= value, "ERC20: not enough tokens");
        balances[msg.sender] -= value;
        balances[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 value) public returns(bool) {
        require(balances[from] >= value, "ERC20: not enough tokens");
        require(allownce(from, msg.sender) >= value, "ERC20: no permission to spend");
        balances[from] -= value;
        balances[to] += value;
        allowed[msg.sender][from] -= value;
        emit Transfer(from, to, value);
        emit Approval(from, msg.sender, allowed[msg.sender][from]);
        return true;
    }
    
    function balanceOf(address to) public view returns(uint256){
        return balances[to];
    }
}