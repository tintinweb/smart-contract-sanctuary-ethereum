/**
 *Submitted for verification at Etherscan.io on 2023-03-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract JMSToken {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    mapping(address => uint256) balances;
    address owner;
    bool public mintingAllowed = true;
    bool public burningAllowed = true;
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }
    
    constructor() {
        name = "JMS Token";
        symbol = "JMS";
        decimals = 18;
        totalSupply = 100000 * 10 ** uint256(decimals);
        balances[msg.sender] = totalSupply;
        owner = msg.sender;
    }
    
    function balanceOf(address _account) public view returns (uint256) {
        return balances[_account];
    }
    
    function transfer(address _to, uint256 _amount) public returns (bool) {
        require(balances[msg.sender] >= _amount, "Not enough balance");
        balances[msg.sender] -= _amount;
        balances[_to] += _amount;
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool) {
        require(balances[_from] >= _amount, "Not enough balance");
        require(msg.sender == owner, "Only owner can transfer from");
        balances[_from] -= _amount;
        balances[_to] += _amount;
        emit Transfer(_from, _to, _amount);
        return true;
    }
    
    function mint(address _account, uint256 _amount) public onlyOwner {
        require(mintingAllowed, "Minting is not allowed");
        require(_account != address(0), "Cannot mint to zero address");
        totalSupply += _amount;
        balances[_account] += _amount;
        emit Mint(_account, _amount);
    }
    
    function burn(uint256 _amount) public {
        require(burningAllowed, "Burning is not allowed");
        require(balances[msg.sender] >= _amount, "Not enough balance");
        totalSupply -= _amount;
        balances[msg.sender] -= _amount;
        emit Burn(msg.sender, _amount);
    }
    
    function disableMinting() public onlyOwner {
        mintingAllowed = false;
    }
    
    function disableBurning() public onlyOwner {
        burningAllowed = false;
    }
    
    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
    event Mint(address indexed _account, uint256 _amount);
    event Burn(address indexed _account, uint256 _amount);
}