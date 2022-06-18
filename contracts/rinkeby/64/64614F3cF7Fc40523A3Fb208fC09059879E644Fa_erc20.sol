/**
 *Submitted for verification at Etherscan.io on 2022-06-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract erc20 {
    address private _miner;
    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) allowed;
    string name_ = "Base_Coin";
    string symbol_ = "NTF";
    uint256 totalSupply_;

    constructor(){
        _miner = msg.sender;  
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function name() public view returns(string memory){
        return name_;
    }

    function symbol() public view returns(string memory){
        return symbol_;
    }

    function miner() external view returns(address){
        return _miner;
    }

    function decimals() public pure returns(uint8){
        return 10;
    }

    function totalSupply() public view returns (uint256){
        return totalSupply_;
    }

    function balanceOf(address _owner) public view returns (uint256){
        return balances[_owner];
    }

    function mint(address _receiver ,uint256 _amount) public returns(bool) {
        require(_amount > 0, "ERC20: amount must be unsigned int");
        require(msg.sender == _miner, "ERC20: you are not miner.");
        balances[_receiver] += _amount;
        totalSupply_ += _amount;
        return true;
    }

    function transfer(address _receiver, uint256 _amount) public returns(bool) {
        require(_amount > 0, "ERC20: amount must be unsigned int");
        require(_amount <= balances[msg.sender], "ERC20: you don't have enough money to make a transaction");
        balances[msg.sender] -= _amount;
        balances[_receiver] += _amount;
        emit Transfer(msg.sender, _receiver, _amount);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_value > 0, "ERC20: amount must be unsigned int");
        require(_value <= balances[_from], "ERC20: you don't have enough money to make a transaction");    
        if (msg.sender != _from) {
            require(_value <= allowed[_from][msg.sender], "ERC20: you can't tranfer with amount to be approve");
            allowed[_from][msg.sender] = allowed[_from][msg.sender] - _value;
        }
        balances[_from] = balances[_from] - _value;
        balances[_to] = balances[_to] + _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        require(_spender != msg.sender, "ERC20: you don't need approve of yourself.");
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256){
        return allowed[_owner][_spender];
    }

    function burn(uint256 amount) public returns(bool){
        require(amount > 0, "ERC20: amount must be unsigned int");
        require(amount <= balances[msg.sender], "ERC20: your wallet don't have enough monney to burn.");
        balances[msg.sender] -= amount;
        totalSupply_ -= amount;
        return true;
    }
}