// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GNaira {
    address public owner;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => bool) public isBlacklisted;

    constructor() {
        owner = msg.sender;
        name = "G Naira";
        symbol = "gNGN";
        decimals = 18;
        totalSupply = 1000000000 * 10**decimals;
        balanceOf[msg.sender] = totalSupply;
    }

    modifier Governor(){
         require(msg.sender == owner, "Only Governor has permission");
        _; 
    }
  //For blacklisted users
    function isBlacklistedUser(address _acccount) public Governor{
        isBlacklisted[_acccount] = true;
       
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(isBlacklisted[_to] == false, "Your account is blacklisted, Contact the governor");
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(isBlacklisted[_to] == false, "Your account is blacklisted, Contact the governor");
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
//For Minting
     function mint(address to, uint256 amount) public Governor {
        balanceOf[to] += amount;
        totalSupply += amount;
    }
//For Burning
    function burn(uint256 amount) public Governor{
        totalSupply -= amount;
        balanceOf[msg.sender] -= amount;
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}