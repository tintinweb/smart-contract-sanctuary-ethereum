/**
 *Submitted for verification at Etherscan.io on 2022-08-11
*/

pragma solidity ^0.8.14;
// SPDX-License-Identifier: FDF
// Network       : Polygon Mumbai Testnet
// Symbol        : DEAL Token
// Name          : DEALv2
// Total supply  : variable
// Initial Supply: 0
// Decimals      : 8
// Developer Account: 0xFAB1AC017553E7dB4B0fE6723dC51CFf6069a77e
// Creation Date : 2022

interface standard20int {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 tokens) external returns (bool);
    function transferFrom(address from, address to, uint256 tokens) external returns (bool);
 
    event Transfer(address indexed from, address indexed to, uint256 tokens);
}

abstract contract newToken is standard20int {
    string public name;
    string public symbol;
    uint256 public decimals;
    uint256 public totalSupply;
    address payable public owner;
    
    mapping(address => uint256) private balances;
    
    event OwnerSet (address indexed oldOwner, address indexed newOwner);
    
    constructor (string memory _name, string memory _symbol, uint256 _decimals, uint256 _totalSupply) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply;
        owner = payable(msg.sender);
    }
	
    modifier isOwner() {
        require(msg.sender == owner, "Error: Permission Denied");
        _;
    }
    
    function changeOwner (address newOwner) public isOwner {
        require (newOwner != address(0), "Can't transfer property to zero address");
        emit OwnerSet(owner, newOwner);
        owner = payable(newOwner);
    }
    
    function balanceOf (address sender) public view returns (uint256) {
        return balances[sender];
    }
 
    function transfer (address to, uint256 tokens) public returns (bool) {
        require(tokens <= balances[msg.sender], "Error: Not enough balance");
        require(to != address(0));
        
        balances[msg.sender] -= tokens;
        balances[to] += tokens;
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
    
    function transferFrom (address from, address to, uint256 tokens) public returns (bool) {
        require(from != address(0), "Error: Can't use zero address");
        require(to != address(0), "Error: Can't use zero address");
        require(tokens <= balances[from], "Error: Not enough balance");
        
        balances[from] -= tokens;
        balances[to] += tokens;        
        emit Transfer(from, to, tokens);
        return true;
    }

    function mint (address to, uint256 tokens) public isOwner returns (bool) {
        require(to != address(0), "Error: Can't use zero address");
        
        balances[to] += tokens;
        totalSupply += tokens;
        emit Transfer(address(0), to, tokens);
        return true;
    }

    function burn (address from, uint256 tokens) public isOwner returns (bool) {
        require(from != address(0), "Error: Can't use zero address");
        balances[from] -= tokens;
        totalSupply -= tokens;
        emit Transfer(from, address(0), tokens);
        return true;
    }
}

contract DEALv2 is newToken ("DEAL Token", "DEALv2", 6, 100000000) {
    // Function to handle BNB in contract, msg.data must be empty
    receive () external payable {
        address _to = owner;
        uint256 amount = address(this).balance;
        (bool success, ) = _to.call{value: amount}("");
        require(success, "Failed to send BNB");
    }

    // Fallback function is called when msg.data is not empty
    fallback () external payable {
        address _to = owner;
        uint256 amount = address(this).balance;
        (bool success, ) = _to.call{value: amount}("");
        require(success, "Failed to send BNB");
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
// EOF