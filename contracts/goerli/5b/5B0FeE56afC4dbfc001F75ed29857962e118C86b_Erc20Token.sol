/**
 *Submitted for verification at Etherscan.io on 2023-06-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ERC-20 Token Contract
contract Erc20Token {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
  
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => User) public users; // Stores the user's wallet address and token balance

    struct User {
        address walletAddress;
        uint256 tokenBalance;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _totalSupply
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply;
        balanceOf[msg.sender] = _totalSupply;
    }

    function generateWalletAddress() external returns (address) {
        require(users[msg.sender].walletAddress == address(0), "Wallet address already generated");
        bytes32 hash = keccak256(abi.encodePacked(msg.sender));
        address walletAddress = address(uint160(uint256(hash)));
        require(isValidAddress(walletAddress), "Invalid wallet address");
        users[msg.sender].walletAddress = walletAddress;
        return walletAddress;
    }

    function isValidAddress(address _address) internal view returns (bool) {
        return (_address != address(0) && _address != address(this));
    }

    function transfer(address _to, uint256 _value) external returns (bool success) {
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success) {
        require(balanceOf[_from] >= _value, "Insufficient balance");
        require(allowance[_from][msg.sender] >= _value, "Not allowed to spend this amount");
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function getUserTokenBalance() external view returns (uint256) {
        return users[msg.sender].tokenBalance;
    }

    function transferTokens(address _to, uint256 _value) external returns (bool success) {
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function getTokenName() external view returns (string memory) {
        return name;
    }

    function getTokenSymbol() external view returns (string memory) {
        return symbol;
    }

    function getTokenDecimals() external view returns (uint8) {
        return decimals;
    }

    function getTokenTotalSupply() external view returns (uint256) {
        return totalSupply;
    }
}