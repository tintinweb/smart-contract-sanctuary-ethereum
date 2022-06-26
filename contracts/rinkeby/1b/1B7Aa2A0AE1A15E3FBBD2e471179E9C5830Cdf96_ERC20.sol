// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract ERC20 {
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    string public name = "nFactorial Incubator";
    string public symbol = "N17R";
    uint8 public decimals = 18;

    event Transfer(address indexed from, address indexed to, uint256 value);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool)
    {
        require(balanceOf[msg.sender] >= amount, "INSUFFICIENT_FUNDS");
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function mint(uint256 amount) external {
        balanceOf[msg.sender] += amount;
        totalSupply += amount;
        emit Transfer(address(0), msg.sender, amount);
    }

    function burn(uint256 amount) external {
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }
}