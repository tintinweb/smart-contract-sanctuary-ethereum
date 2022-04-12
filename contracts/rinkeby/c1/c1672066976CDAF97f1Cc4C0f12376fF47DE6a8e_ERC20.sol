// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract ERC20 {
   address private _owner;
   string public name;
   string public symbol;
   uint256 public totalSupply;
   uint8 public decimals;
   
   mapping(address => uint256) private _balances;
   mapping(address => mapping(address => uint256)) private _allowances;

   constructor(
      string memory _name,
      string memory _symbol,
      uint256 _initialSupply,
      uint8 _decimals
   ) {
      _owner = msg.sender;

      name = _name;
      symbol = _symbol;
      totalSupply = _initialSupply;
      decimals = _decimals;

      _balances[_owner] += _initialSupply;
   }

   modifier ownerOnly {
        require (
            msg.sender == _owner, "Permission denied"
        );
        _;
    }

   event Transfer(address indexed _from, address indexed _to, uint256 _value);
   event Approval(address indexed _owner, address indexed _spender, uint256 _value);

   function balanceOf(address _of) public view returns(uint256) {
      return _balances[_of];
   }

   function approve(address _spender, uint256 _value) public returns(bool success) {
      require(_balances[msg.sender] >= _value, "Not enough token");

      _allowances[msg.sender][_spender] = _value;
      emit Approval(msg.sender, _spender, _value);

      success = true;
   }

   // Secure Approve Function
   function safeApprove(
      address _spender,
      uint256 _currentValue,
      uint256 _value
   ) public returns(bool success) {
      require(_balances[msg.sender] >= _value, "Not enough token");
      require(_allowances[msg.sender][_spender] == _currentValue,
         "Old allowance was transfered!");

      _allowances[msg.sender][_spender] = _value;
      emit Approval(msg.sender, _spender, _value);

      success = true;
   }

   function allowance(address _of, address _spender) public view returns(uint256) {
      return _allowances[_of][_spender];
   }

   function transfer(address _to, uint256 _value) public returns(bool success) {
      require(_balances[msg.sender] >= _value, "Not enough token");
      
      _balances[msg.sender] -= _value;
      _balances[_to] += _value;
      emit Transfer(msg.sender, _to, _value);

      success = true;
   }

   function transferFrom(
      address _from,
      address _to,
      uint256 _value
   ) public returns(bool success) {
      require(_allowances[_from][msg.sender] >= _value, "Allowance is not enough");
      require(_balances[_from] >= _value, "Balance is not enough");

      _balances[_from] -= _value;
      _balances[_to] += _value;
      _allowances[_from][msg.sender] -= _value;
      emit Transfer(_from, _to, _value);

      success = true;
   }

   function mint(address _to, uint256 _value) public ownerOnly returns(bool success) {
      _balances[_to] += _value;
      totalSupply += _value;
      
      success = true;
   }

   function burn(address _of, uint256 _value) public ownerOnly returns(bool success) {
      require(_balances[_of] >= _value, "Not enough token");

      _balances[_of] -= _value;
      totalSupply -= _value;

      success = true;
   }
}