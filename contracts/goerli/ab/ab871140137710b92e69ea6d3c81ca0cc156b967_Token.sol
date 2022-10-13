/**
 *Submitted for verification at Etherscan.io on 2022-10-13
*/

// SPDX-License-Identifier: MIT
      pragma solidity ^0.8.15;
  
      contract Token {
      
        string  internal _name = "Gretchen Cline";
        string  internal _symbol = "GC";
        string  internal _supply_type = "fixed";
        uint8   internal _decimals = 6;
        uint256 internal _totalSupply = 820000 * (10 ** uint256(_decimals));
        
        bool public isFreeze = false;
        
  
        address public owner = 0x4e20450A0873bDF560BAEf8009A32aDF097751aA;
        
        mapping (address => uint256) balances;
        mapping (address => mapping (address => uint256)) allowed;
      
        constructor() {
          balances[msg.sender] = _totalSupply;
          emit Transfer(address (0),msg.sender, _totalSupply);
        }
        function name() public view virtual returns (string memory) {
          return _name;
        }
        
        function symbol() public view virtual returns (string memory) {
          return _symbol;
        }

        function supplyType() public view virtual returns (string memory) {
          return _supply_type;
        }
        
        function decimals() public view virtual returns (uint8 decimal) {
          return _decimals;
        }
        
        function totalSupply() public view virtual returns (uint256 total_Supply) {
          return _totalSupply;
        }
      
        function transfer(address _to, uint256 _value) public returns (bool success) {require(isFreeze == false,'The token transfer is frozen. Please contract with the token owner.');
          require(balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]);
          require(_to != address (0));
          balances[msg.sender] -= _value;
          balances[_to] += _value;
          emit Transfer(msg.sender, _to, _value);
          return true;
        }
      
        function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {require(isFreeze == false,'The token transfer is frozen. Please contract with the token owner.');  
          require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value);
          balances[_to] += _value;
          balances[_from] -= _value;
          allowed[_from][msg.sender] -= _value;
          emit Transfer(_from, _to, _value);
          return true;
        }
  
        function balanceOf(address _owner) public view virtual returns (uint256 balance) {
          return balances[_owner];
        }
  
        function approve(address _spender, uint256 _value) public returns (bool success) {
          allowed[msg.sender][_spender] = _value;
          emit Approval(msg.sender, _spender, _value);
          return true;
        }
      
        function allowance(address _owner, address _spender) public view virtual returns (uint256 remaining) {
          return allowed[_owner][_spender];
        }
        function _add(uint256 a, uint256 b) internal pure returns (uint256) {
          uint256 c = a + b;
          require(c >= a, "SafeMath: addition overflow");
          return c;
        }
        function freeze() public returns (bool success) {
          require(msg.sender==owner && isFreeze == false);
          isFreeze = true;
          emit Freeze ();
          return true;
          
        }
        function unfreeze() public returns (bool success) {
            require(msg.sender==owner && isFreeze == true);
            isFreeze = false;
            emit Unfreeze ();
            return true;
            
        }
        
      event Transfer(address indexed _from, address indexed _to, uint256 _value);
      event Approval(address indexed _owner, address indexed _spender, uint256 _value);
      
        event Freeze ();
        event Unfreeze ();
        }