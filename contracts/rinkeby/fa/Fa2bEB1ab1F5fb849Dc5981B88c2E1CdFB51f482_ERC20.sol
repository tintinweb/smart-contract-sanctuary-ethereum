// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title ERC20 token contract with EIP20 compatibility
/// @author Omur Kubanychbekov
/// @notice You can use this contract for make your own ERC20 token
/// @dev All functions tested successfully and have no errors

contract ERC20 {
   address private _owner;
   address private _comissionReciever;
   string public name;
   string public symbol;
   uint256 public totalSupply;
   uint256 private _comission;
   uint8 public decimals;
   
   mapping(address => bool) private _isDex;
   mapping(address => uint256) private _balances;
   mapping(address => mapping(address => uint256)) private _allowances;

   /// @notice Deploys the contract with the initial parameters(name, symbol, initial supply, decimals)
   /// @dev Constructor should be used when deploying contract,
   /// owner is the address that deploys the contract
   /// @param _name Name of the token
   /// @param _symbol Symbol of the token
   /// @param _initialSupply Initial supply of the token,
   /// may be changed later with `mint` or 'burn' function
   /// @param _decimals The number of decimals used by the token
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

   /// @dev Modifier for functions 'mint' and 'burn',
   /// that can only be called by the owner of the contract
   modifier ownerOnly {
        require (
            msg.sender == _owner, "Permission denied"
        );
        _;
    }

   /// @notice Event that notices about transfer operations
   event Transfer(address indexed _from, address indexed _to, uint256 _value);

   /// @notice Event that notices about approval operations
   event Approval(address indexed _owner, address indexed _spender, uint256 _value);


   /// @notice Function that returns token balance in exact address
   /// @param _of Address of the token holder
   /// @return amount of the token in numbers
   function balanceOf(address _of) external view returns(uint256) {
      return _balances[_of];
   }

   /// @notice Function that allows to transfer tokens from one address to another
   /// @param _spender Address who can spend the tokens
   /// @param _value Amount of tokens to allow
   /// @return true if transaction is successful
   function approve(address _spender, uint256 _value) external returns(bool) {
      require(_balances[msg.sender] >= _value, "Not enough token");

      _allowances[msg.sender][_spender] = _value;
      emit Approval(msg.sender, _spender, _value);

      return true;
   }

   /// @notice Function that allows to transfer tokens from one address to another
   /// Secure version of the function, that checks the current allowance of the spender
   /// @param _spender Address who can spend the tokens
   /// @param _currentValue Current allowance of the spender
   /// @param _value Amount of new tokens to allow
   /// @return true if transaction is successful
   function safeApprove(
      address _spender,
      uint256 _currentValue,
      uint256 _value
   ) external returns(bool) {
      require(_balances[msg.sender] >= _value, "Not enough token");
      require(_allowances[msg.sender][_spender] == _currentValue,
         "Old allowance was transfered!");

      _allowances[msg.sender][_spender] = _value;
      emit Approval(msg.sender, _spender, _value);

      return true;
   }

   /// @notice Function that returns the amount of tokens,
   /// that are allowed to be spent by the spender from _of address
   /// @param _of Address of the token allower
   /// @param _spender Address who can spend the tokens
   /// @return amount of the tokens allowed to spend
   function allowance(address _of, address _spender) external view returns(uint256) {
      return _allowances[_of][_spender];
   }

   /// @notice Function that transfers tokens from caller to another address
   /// If _to is a Dex address, it takes _comission and sends amount to _comissionReciever
   /// @param _to Address of the reciever
   /// @param _value Amount of tokens to transfer
   /// @return true if transaction is successful
   function transfer(address _to, uint256 _value) external returns(bool) {
      require(_balances[msg.sender] >= _value, "Not enough token");
    
      _balances[msg.sender] -= _value;

      if (_isDex[_to]) {
          uint256 comission = (_value / 100) * _comission;
          _balances[_to] += _value - comission;
          _balances[_comissionReciever] += comission;
          emit Transfer(msg.sender, _to, _value - comission);
      } else {
          _balances[_to] += _value;
          emit Transfer(msg.sender, _to, _value);
      }

      return true;
   }

   /// @notice Function that transfers tokens from one address to another
   /// Caller must have allowance to spend the tokens from _from address
   /// If _to is a Dex address, it takes _comission and sends amount to _comissionReciever
   /// @param _from Address spend the tokens from
   /// @param _to Address of the reciever
   /// @param _value Amount of tokens to transfer
   /// @return true if transaction is successful
   function transferFrom(
      address _from,
      address _to,
      uint256 _value
   ) external returns(bool) {
      require(_allowances[_from][msg.sender] >= _value, "Allowance is not enough");
      require(_balances[_from] >= _value, "Balance is not enough");

      _balances[_from] -= _value;
      _allowances[_from][msg.sender] -= _value;

      if (_isDex[_to]) {
          uint256 comission = (_value / 100) * _comission;
          _balances[_to] += _value - comission;
          _balances[_comissionReciever] += comission;
          emit Transfer(_from, _to, _value - comission);
      } else {
          _balances[_to] += _value;
          emit Transfer(_from, _to, _value);
      }

      return true;
   }

   /// @notice Function that adds new tokens to _to address
   /// @dev totalSupply is increased by _value
   /// @param _to Address of the reciever
   /// @param _value Amount of tokens to mint
   /// @return true if transaction is successful
   function mint(address _to, uint256 _value) external ownerOnly returns(bool) {
      _balances[_to] += _value;
      totalSupply += _value;
      emit Transfer(address(0), _to, _value);
      
      return true;
   }

   /// @notice Function that burns tokens from _of address
   /// @dev totalSupply is decreased by _value
   /// @param _of Address of the spender
   /// @param _value Amount of tokens to burn
   /// @return true if transaction is successful
   function burn(address _of, uint256 _value) external ownerOnly returns(bool) {
      require(_balances[_of] >= _value, "Not enough token");

      _balances[_of] -= _value;
      totalSupply -= _value;
      emit Transfer(_of, address(0), _value);

      return true;
   }

   /// @notice Function that sets Treasury Reciever address
   /// @param _reciever Address of the comission reciever
   /// @return true if transaction is successful
   function setReciever(address _reciever) external ownerOnly returns(bool) {
       _comissionReciever = _reciever;

       return true;
   }

   /// @notice Function that sets percent amount of comission
   /// @param _value Percent amount between 1 and 99
   /// @return true if transaction is successful
   function setComission(uint256 _value) external ownerOnly returns(bool) {
       require(_value > 0 && _value < 100, "Enter right percent");

       _comission = _value;

       return true;
   }

   /// @notice Function that adds address of new Dex
   /// @param _dex Address of the Dex
   /// @return true if transaction is successful 
   function addDex(address _dex) external ownerOnly returns(bool) {
       require(_dex != address(0), "Zero address cant be added");

       _isDex[_dex] = true;

       return true;
   }

   /// @notice Function that removes added address of Dex
   /// @param _dex Address of the Dex
   /// @return true if transaction is successful  
   function removeDex(address _dex) external ownerOnly returns(bool) {
       _isDex[_dex] = false;

       return true;
   }
}