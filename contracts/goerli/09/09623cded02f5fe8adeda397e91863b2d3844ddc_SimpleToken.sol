/**
 *Submitted for verification at Etherscan.io on 2022-09-30
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

contract SimpleToken {
    mapping(address => uint256) public balanceOf;
    uint256 public totalSupply;
    address public owner;

    constructor(uint256 _initialSupply) {
        totalSupply = _initialSupply;
        balanceOf[msg.sender] = _initialSupply;
        owner = msg.sender;
    }

    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }

    function transfer(address _to, uint256 _amount) public {
        require(balanceOf[msg.sender] >= _amount, "Not enough tokens");
        balanceOf[msg.sender] = balanceOf[msg.sender] - _amount;
        balanceOf[_to] = balanceOf[_to] + _amount;
    }

    function mint(uint256 amount) external onlyOwner {
        totalSupply = totalSupply + amount;
        balanceOf[owner] = balanceOf[owner] + amount;
    }
}