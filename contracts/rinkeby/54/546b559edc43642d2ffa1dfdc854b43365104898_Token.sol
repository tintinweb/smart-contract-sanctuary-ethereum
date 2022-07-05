/**
 *Submitted for verification at Etherscan.io on 2022-07-05
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Token {

    address private owner;
    string private constant name = "Tooken";
    string private constant symbol = "TKN";
    uint8 private constant decimals = 18;

    uint256 totalSupply;

    mapping (address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    constructor(uint256 totalSupply_) {
        owner = msg.sender;
        totalSupply = totalSupply_;
        balances[owner] = totalSupply_;
    }


    function approve(address account, uint256 amount) public returns (bool) {
        allowed[msg.sender][account] = amount;
        emit Approval(msg.sender, account, amount);
        return true;
    }

    function transfer(address from, uint256 amount) public returns (bool) {
        require(amount <= balances[msg.sender], "Insufficient funds to transfer");

        balances[msg.sender] = balances[msg.sender] - amount;
        balances[from] = balances[from] + amount;

        emit Transfer(msg.sender, from, amount);

        return true;
    }

    function transferFrom(address _from, address _to, uint256 amount) public returns (bool success) {
        require(amount <= balances[_from]);
        require(amount <= allowed[_from][msg.sender]);
        balances[_from] -= amount;
        allowed[_from][msg.sender] -= amount;
        balances[_to] += amount;
        emit Transfer(_from, _to, amount);
        return true;
    }

    function balanceOf(address owner_) public view returns (uint256) {
        return balances[owner_];
    }

    function allowance(address owner_, address account) public view returns (uint256) {
        return allowed[owner_][account];
    }

    function getTotalSupply() public view returns (uint256) {
        return totalSupply;
    } 
}