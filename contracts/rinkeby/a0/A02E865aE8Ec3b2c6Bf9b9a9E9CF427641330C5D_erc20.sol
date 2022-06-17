/**
 *Submitted for verification at Etherscan.io on 2022-06-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract erc20 {
    address private _miner;
    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) allowed;
    string name_ = "Base_Coin";
    string symbol_ = "BCN";
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

    //Mint coin by miner
    function mint(address receiver ,uint256 amount) public returns(bool) {
        require(amount > 0);
        require(msg.sender == _miner, "You are not miner.");
        require(amount < 1e60);
        balances[receiver] += amount;
        totalSupply_ += amount;
        return true;
    }

    // Transfer
    function transfer(address receiver, uint256 amount) public returns(bool) {
        require(amount > 0);
        require(amount <= balances[msg.sender]);
        balances[msg.sender] -= amount;
        balances[receiver] += amount;
        emit Transfer(msg.sender, receiver, amount);
        return true;
    }

    // TransferFrom
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_value > 0);
        require(_value <= balances[_from]);    
        if (msg.sender != _from) {
            if (_value <= allowed[_from][msg.sender])
                allowed[_from][msg.sender] = allowed[_from][msg.sender] - _value;
            else 
                return false;
        }
        balances[_from] = balances[_from] - _value;
        balances[_to] = balances[_to] + _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    // Approve
    function approve(address _spender, uint256 _value) public returns (bool) {
        require(_spender != msg.sender);
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    // Allowance
    function allowance(address _owner, address _spender) public view returns (uint256){
        return allowed[_owner][_spender];
    }

    // Burn
    function burn(uint256 amount) public returns(bool){
        require(amount > 0);
        require(amount <= balances[msg.sender]);
        balances[msg.sender] -= amount;
        totalSupply_ -= amount;
        return true;
    }

    function approve(address _owner, address _spender, uint256 _value) public {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(_spender != address(0), "ERC20: approve to the zero address");
        allowed[_owner][_spender] = _value;
        emit Approval(_owner, _spender, _value);
    }
}