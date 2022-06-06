/**
 *Submitted for verification at Etherscan.io on 2022-06-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IToken20 {
    event Transfer(address from, address to, uint amount);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Token20 is IToken20 {
    address owner;

    string public name;
    string public symbol;

    uint8 public decimal = 18;
    uint public totalSupply;

    mapping(address => uint) balances;

    constructor(string memory _name, string memory _symbol) {
        require(bytes(_name).length >0);
        require(bytes(_symbol).length > 2);

        owner = msg.sender;
        name = _name;
        symbol = _symbol;

        _mint(msg.sender, 10 * (10 ** decimal));
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    function balanceOf(address addr) external view returns (uint) {
        return balances[addr];
    } 

    function _mint(address to, uint amount) internal onlyOwner returns (bool) {
        require(to != address(0), "Mint to address 0");
        
        totalSupply += amount;
        balances[to] += amount;

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function burn(address from, uint amount) external onlyOwner returns (bool) {
        require(from != address(0), "Token20: Burn from address 0");
        require(balances[from] >= amount, "Token20: Burn amount exceeds balance");
        
        balances[from] -= amount;
        totalSupply -= amount;

        emit Transfer(from, address(0), amount);
        return true;
    }

    function transfer(address recipient, uint amount) external returns (bool) {
        require(balances[msg.sender] >= amount, "Not enough token to transfer");
        balances[msg.sender] -= amount;
        balances[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }
}