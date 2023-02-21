/**
 *Submitted for verification at Etherscan.io on 2023-02-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Import Solidity Modules

// Note: Unaudited - 2023-02-21

contract ERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    string public name; 
    string public symbol;

    constructor(string memory name_, string memory symbol_) {
        name = name_;
        symbol = symbol_;
    }

    uint256 public totalSupply;
    uint256 public constant decimals = 18;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    function _mint(address to_, uint256 amount_) internal virtual {
        balanceOf[to_] += amount_;
        totalSupply += amount_;
        emit Transfer(address(0), to_, amount_);
    }

    function _burn(address from_, uint256 amount_) internal virtual {
        balanceOf[from_] -= amount_;
        totalSupply -= amount_;
        emit Transfer(from_, address(0), amount_);
    }

    function approve(address spender_, uint256 amount_) public virtual returns (bool) {
        allowance[msg.sender][spender_] = amount_;
        emit Approval(msg.sender, spender_, amount_);
        return true;
    }

    function transfer(address to_, uint256 amount_) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount_;
        balanceOf[to_] += amount_;
        emit Transfer(msg.sender, to_, amount_);
        return true;
    }

    function transferFrom(address from_, address to_, uint256 amount_)
    public virtual returns (bool) {
        if (allowance[from_][msg.sender] != type(uint256).max) {
            allowance[from_][msg.sender] -= amount_; }
        balanceOf[from_] -= amount_;
        balanceOf[to_] += amount_;
        emit Transfer(from_, to_, amount_);
        return true;
    }
}

// MockERC20 Product
contract MockERC20 is ERC20 {
    
    constructor(string memory name_, string memory symbol) ERC20(name_, symbol) {}

    function mint(address to_, uint256 amount_) external {
        _mint(to_, amount_);
    }
}