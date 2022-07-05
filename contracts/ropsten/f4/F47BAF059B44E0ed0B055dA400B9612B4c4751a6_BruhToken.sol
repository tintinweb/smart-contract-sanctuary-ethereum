/**
 *Submitted for verification at Etherscan.io on 2022-07-04
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;

contract BruhToken {

    uint256 public totalSupply;
    string public name;
    string public symbol;
    uint8  public immutable decimals;
    address public staking;
    address immutable owner;
    mapping(address=>uint) balances;
    mapping(address => mapping(address => uint256)) allowed;

    constructor() {
        owner = msg.sender;
        totalSupply = 0;
        decimals = 5;
        symbol = "TOD";
        name = "DAOToken";
    }

    event Transfer(address indexed from,address indexed to, uint value);
    event Approval(address indexed from,address indexed spender, uint value);

    function mint(address to, uint value) external {
        require(msg.sender == owner || msg.sender == staking, "ERC20: You are not owner");
        balances[to] += value;
        totalSupply +=value;
        emit Transfer(address(0),to,value);
    }

    function balanceOf(address to) external view returns(uint){
        return balances[to];
    }

    function transfer(address to, uint256 value) external returns(bool) {
        require(balances[msg.sender] >= value, "ERC20: not enough BRUH");
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender,to,value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external returns(bool) {
        require(balances[from] >= value, "ERC20: not enough BRUH");
        require(msg.sender != from, "ERC20: use 'transfer' function to send BRUH from your address");
        require(allowed[from][msg.sender] >= value, "ERC20: no permission to spend");
        balances[to] += value;
        balances[from] -= value;
        allowed[from][msg.sender] -= value;
        emit Transfer(from,to,value);
        emit Approval(from,msg.sender,allowed[from][msg.sender]);
        return true;
    }

    function approve(address spender, uint256 value) external returns(bool) {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender,spender,value);
        return true;
    }

    function allowance(address from, address spender) external view returns (uint256) {
        return allowed[from][spender];
    }

    function setStaking(address _staking) external {
        require(msg.sender == owner, "ERC20: You are not owner");
        staking = _staking;
    }
}