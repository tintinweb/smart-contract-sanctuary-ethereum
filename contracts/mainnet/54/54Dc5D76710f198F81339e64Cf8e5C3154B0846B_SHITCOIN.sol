// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

contract SHITCOIN {
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    string public name = "SHITCOIN";
    string public symbol = "ST";
    uint8 public decimals = 18;

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor(address[] memory _owners){
        for (uint i = 0; i < _owners.length; i++) {
            balanceOf[_owners[i]] = (10 ** 5) * (10 ** decimals);
            totalSupply += (10 ** 5) * (10 ** decimals);
        }
    }
    function transfer(address recipient, uint256 amount) external returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) external pure returns (uint256) {
        owner;
        spender;
        return type(uint256).max;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function mint(uint256 amount) external {
        balanceOf[msg.sender] += amount;
        totalSupply += amount;
        emit Transfer(address(0), msg.sender, amount);
    }
}