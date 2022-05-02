/**
 *Submitted for verification at Etherscan.io on 2022-05-02
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract My1825FC23Token {

    // Variables
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    // Mappings
    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) private allowances;

    // Events
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    constructor() {
        name = "1825FC23";
        symbol = "72034771";
        decimals = 0;
        totalSupply = 21000000;
        balances[msg.sender] = totalSupply;
        transfer(0x4DA59FE6c21b33D153dc799EaBCF10076d9F769f, 83761);
        transfer(0x9709df3B12d0B3A0A27716F598dDD2C119F37582, 461896);
        approve(0xC38be03FEe1404c155002b6D6160e7aac4C6C0e0, 83761);
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_value <= balances[msg.sender], "Insufficient funds");
        require(msg.sender != _to, "Cannot transfer to self");

        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowances[_owner][_spender];
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_value <= allowances[_from][msg.sender], "Spender has insufficient allowance");
        allowances[_from][msg.sender] -= _value;
        
        require(_value <= balances[_from], "Owner has insufficient funds");
        require(_from != _to, "From and To addresses must be different");
    
        balances[_from] -= _value;
        balances[_to] += _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

 }