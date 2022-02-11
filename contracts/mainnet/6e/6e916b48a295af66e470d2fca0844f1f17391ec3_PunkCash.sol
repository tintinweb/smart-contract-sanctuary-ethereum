/**
 *Submitted for verification at Etherscan.io on 2022-02-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

interface iCryptoPunks {
    function balanceOf(address address_) external view returns (uint256);
    function punkIndexToAddress(uint256 tokenId_) external view returns (address);
}

// Completely Trustless PunkCash for CryptoPunks
// Created by 0xInuarashi.dev
// Feel free to use however you want.

contract PunkCash is ERC20I {
    
    // Name and Symbol
    constructor() ERC20I("PunkCash", "CASH") {}

    // CryptoPunks Interface
    iCryptoPunks public CP = iCryptoPunks(0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB);

    // TX Timetamp: 0x0885b9e5184f497595e1ae2652d63dbdb2785de2e498af837d672f5765f28430
    uint256 public constant yieldStartTime = 1498117200; // Jun-22-2017 07:40:00 PM +UTC
    uint256 public constant yieldEndTime = 2129269200; // Jun-22-2037 07:40:00 PM +UTC
    uint256 public constant yieldRate = 1000000 ether; // 1 Million $CASH per day

    // Mapping
    mapping(uint256 => uint256) public punkToTimestamp;

    // Core Functions
    function getPendingTokens(uint256 tokenId_) public view returns (uint256) {
        uint256 _timestamp = punkToTimestamp[tokenId_] == 0 ?
            yieldStartTime : punkToTimestamp[tokenId_] > yieldEndTime ? 
            yieldEndTime : punkToTimestamp[tokenId_];
        uint256 _currentTimeOrEnd = block.timestamp > yieldEndTime ?
            yieldEndTime : block.timestamp;
        uint256 _timeElapsed = _currentTimeOrEnd - _timestamp;

        return (_timeElapsed * yieldRate) / 1 days;
    }
    function getPendingTokensMany(uint256[] memory tokenIds_) public view 
    returns (uint256) {
        uint256 _pendingTokens;
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            _pendingTokens += getPendingTokens(tokenIds_[i]);
        }
        return _pendingTokens;
    }

    function claim(address to_, uint256[] memory tokenIds_) external {
        require(tokenIds_.length > 0, 
            "You must claim at least 1 CryptoPunk!");

        uint256 _pendingTokens = tokenIds_.length > 1 ?
            getPendingTokensMany(tokenIds_) :
            getPendingTokens(tokenIds_[0]);
        
        // Run loop to update timestamp for each punk
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            require(to_ == CP.punkIndexToAddress(tokenIds_[i]),
                "claim(): to_ is not owner of CryptoPunk!");

            punkToTimestamp[tokenIds_[i]] = block.timestamp;
        }
        
        _mint(to_, _pendingTokens);
    }

    // Public View Functions (View Only)
    function getPendingTokensOfAddress(address address_) public view returns (uint256) {
        uint256[] memory _tokensOfAddress = walletOfOwner(address_);
        return getPendingTokensMany(_tokensOfAddress);
    }
    function walletOfOwner(address address_) public view returns (uint256[] memory) {
        uint256 _balance = CP.balanceOf(address_);
        if (_balance == 0) return new uint256[](0);

        uint256[] memory _tokens = new uint256[] (_balance);
        uint256 _index;

        for (uint256 i = 0; i < 10000; i++) {
            if (CP.punkIndexToAddress(i) == address_) {
                _tokens[_index] = i; _index++;
            }
        }
        return _tokens;
    }
}