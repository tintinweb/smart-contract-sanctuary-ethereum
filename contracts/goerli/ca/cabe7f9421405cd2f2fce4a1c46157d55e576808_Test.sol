/**
 *Submitted for verification at Etherscan.io on 2022-12-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Test {

    string public name;
    string public symbol;
    uint8 public decimals;
    address public owner;
    uint256 public totalSupply;

    mapping (address => uint256) public balances;

    event Transfer(address indexed from, address indexed to, uint256 amt);

    modifier onlyOwner {
        require(msg.sender == owner, "Unauthorised function call.");
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _supply
    ){
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        owner = msg.sender;
        totalSupply = _supply;
        balances[owner] = totalSupply;
    }

    function transfer(address to, uint256 amt) public {
        require(balances[msg.sender] >= amt, "Not enough funds.");

        balances[msg.sender] = balances[msg.sender] - amt;
        balances[to] = balances[to] + amt;

        emit Transfer(msg.sender, to, amt);
    }

    function mint(uint256 amt) external onlyOwner {
        require(totalSupply + amt > totalSupply, "Adding this amount will cause an Overflow");
        totalSupply = totalSupply + amt;
        balances[owner] = balances[owner] + amt;
    }

    function burn(uint256 amt) external {
        require(balances[msg.sender] >= amt, "Not enough funds.");
        balances[msg.sender] = balances[msg.sender] - amt;
        totalSupply = totalSupply - amt;
    }

}