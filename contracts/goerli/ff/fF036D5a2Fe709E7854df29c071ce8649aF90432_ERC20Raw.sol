/**
 *Submitted for verification at Etherscan.io on 2022-08-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract ERC20Raw {

    address public owner;

    string public name;

    string public symbol;

    mapping(address => uint256) public balances;

    uint256 public totalSupply;

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not owner");
        _;
    }

    constructor(string memory _name, string memory _symbol, uint256 _initSupply) {
        owner = msg.sender;
        name = _name;
        symbol = _symbol;
        totalSupply += _initSupply;
        balances[msg.sender] += _initSupply;
    }

    function balanceOf(address _account) public view returns (uint256) {
        require(_account != address(0), "Input account can not be zero address");
        return balances[_account];
    }

    function tranfer(address _to, uint256 _amount) public {
        require(_to != address(0), "_to can not be zero address");
        require(balanceOf(msg.sender) >= _amount, "Not enough token");
        balances[msg.sender] -= _amount;
        balances[_to] += _amount;
    }

    function mint(uint256 _amount) public onlyOwner {
        balances[msg.sender] += _amount;
        totalSupply += _amount;
    }

    function burn(uint256 _amount) public onlyOwner {
        balances[msg.sender] -= _amount;
        totalSupply -= _amount;
    }
}