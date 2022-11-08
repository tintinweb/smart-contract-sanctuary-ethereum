/**
 *Submitted for verification at Etherscan.io on 2022-11-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/*
    ERC20I (ERC20 0xInuarashi Edition)
    Minified and Gas Optimized
    Contributors: 0xInuarashi (Message to Martians, Anonymice), 0xBasset (Ether Orcs)
*/

contract ERC20I {
    // Token Params
    string public name;
    string public symbol;
    constructor(string memory name_, string memory symbol_) {
        name = name_;
        symbol = symbol_;
    }

    // Decimals
    uint8 public constant decimals = 18;

    // Supply
    uint256 public totalSupply;
    
    // Mappings of Balances
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    // Events
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // Internal Functions
    function _mint(address to_, uint256 amount_) internal virtual {
        totalSupply += amount_;
        balanceOf[to_] += amount_;
        emit Transfer(address(0x0), to_, amount_);
    }
    function _burn(address from_, uint256 amount_) internal virtual {
        balanceOf[from_] -= amount_;
        totalSupply -= amount_;
        emit Transfer(from_, address(0x0), amount_);
    }
    function _approve(address owner_, address spender_, uint256 amount_) internal virtual {
        allowance[owner_][spender_] = amount_;
        emit Approval(owner_, spender_, amount_);
    }

    // Public Functions
    function approve(address spender_, uint256 amount_) public virtual returns (bool) {
        _approve(msg.sender, spender_, amount_);
        return true;
    }
    function transfer(address to_, uint256 amount_) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount_;
        balanceOf[to_] += amount_;
        emit Transfer(msg.sender, to_, amount_);
        return true;
    }
    function transferFrom(address from_, address to_, uint256 amount_) public virtual returns (bool) {
        if (allowance[from_][msg.sender] != type(uint256).max) {
            allowance[from_][msg.sender] -= amount_; }
        balanceOf[from_] -= amount_;
        balanceOf[to_] += amount_;
        emit Transfer(from_, to_, amount_);
        return true;
    }

    // 0xInuarashi Custom Functions
    function multiTransfer(address[] memory to_, uint256[] memory amounts_) public virtual {
        require(to_.length == amounts_.length, "ERC20I: To and Amounts length Mismatch!");
        for (uint256 i = 0; i < to_.length; i++) {
            transfer(to_[i], amounts_[i]);
        }
    }
    function multiTransferFrom(address[] memory from_, address[] memory to_, uint256[] memory amounts_) public virtual {
        require(from_.length == to_.length && from_.length == amounts_.length, "ERC20I: From, To, and Amounts length Mismatch!");
        for (uint256 i = 0; i < from_.length; i++) {
            transferFrom(from_[i], to_[i], amounts_[i]);
        }
    }
}

contract MockERC20 is ERC20I {
    constructor(string memory name_, string memory symbol_) 
    ERC20I(name_, symbol_) {}
    function mint(address to_, uint256 amount_) external {
        _mint(to_, amount_);
    }
    function mintAsController(address to_, uint256 amount_) external {
        _mint(to_, amount_);
    }
}

contract MockERC20Factory {
    mapping(address => MockERC20[]) public addressToDeployments;
    function getDeployments(address address_) external view returns (MockERC20[] memory) {
        return addressToDeployments[address_];
    }
    function createMockERC20(string calldata name_, string calldata symbol_) public {
        MockERC20 _MockERC20 = new MockERC20(name_, symbol_);
        addressToDeployments[msg.sender].push(_MockERC20);

        // Mint the tokens to trigger the address 
        _MockERC20.mint(msg.sender, 1000000 ether);
    }
    function createMockERC20Batch(string[] calldata names_, string[] calldata symbols_) external {
        require(names_.length == symbols_.length, "length mismatch");
        uint256 l = names_.length;
        uint256 i; unchecked { do {
            createMockERC20(names_[i], symbols_[i]);
        } while(++i < l); }
    }
}