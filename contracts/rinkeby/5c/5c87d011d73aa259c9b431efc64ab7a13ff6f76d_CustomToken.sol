/**
 *Submitted for verification at Etherscan.io on 2022-02-26
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 < 0.9.0;

/// @title A custom token based on the ERC20 standard with burn mechanism

// Referencing the following:
// ERC20 Standard - https://ethereum.org/en/developers/docs/standards/tokens/erc-20/
// OpenZeppelin ERC20 Implementation - 
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.5.0/contracts/token/ERC20/ERC20.sol

// ERC stands for "Ethereum request for comment". Basically, a way for the Ethereum
// foundation to comment on technical notes and requirements to developers.
// The 20 represents the improvement proposal #20 that ended up becoming an official ERC

contract CustomToken {
    // The underscore is a naming convention taken from Python and other languages
    // Indicates a private member variable of the Contract / Class
    string private _tokenName;
    string private _tokenSymbol;
    uint private _totalSupply;
    uint private _burnRate;
    address private _contractOwner;
    // Mapping an address to a balance -- similar to a dictionary (key<>value) in Python
    mapping(address => uint) _balance;

    // Memory is used to store the variable in memory only -- not be stored on the 
    // blockchain
    constructor(string memory tokenName_, string memory tokenSymbol_, 
        uint totalSupply_, uint burnRate_) {
        _tokenName = tokenName_;
        _tokenSymbol = tokenSymbol_;
        _totalSupply = totalSupply_;
        _burnRate = burnRate_;
        // The address that initiated the creation of the contract (or the "sender")
        // will become the owner of the token's total supply
        _contractOwner = msg.sender;
        _balance[_contractOwner] = _totalSupply;
    }

    function name() public view returns (string memory) {
        return _tokenName;
    }

    function symbol() public view returns (string memory) {
        return _tokenSymbol;
    }

    // The decimals determine how divisible a token can be
    // 18 is the default for ERC20
    function decimals() public view returns (uint8) {
        return 18;
    }

    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }

    // Given an account address -> return a balance
    function balanceOf(address account) public view returns (uint) {
        return _balance[account];
    }

    // @TODO 
    /*
    function transfer() public{}
    function transferFrom() public{}
    function approve() public{}
    function allowance() public{}
    // Not part of the ERC20 standard
    function burn() public{}
    */
}