// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MyToken {
    string public name;
    string public symbol;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    function transfer(address _to, uint256 _amount) public {
        require(_amount != 0, "cannot transfer 0 amount");
        require(_amount <= balanceOf[msg.sender], "no enough balance");
        require(_to != address(0), "cannot transfer to 0 address");
        balanceOf[msg.sender] -= _amount;
        balanceOf[_to] += _amount;
    }

    function mint(address _to, uint256 _amount) public {
        require(_amount != 0, "cannot mint 0 amount");
        require(_to != address(0), "cannot mint to 0 address");
        balanceOf[_to] += _amount;
        totalSupply += _amount;
    }
}