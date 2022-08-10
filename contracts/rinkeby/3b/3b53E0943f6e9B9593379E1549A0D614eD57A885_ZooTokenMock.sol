pragma solidity 0.8.13;

// SPDX-License-Identifier: MIT

contract ZooTokenMock {

	string public name;                                         // Contract name.
	string public symbol;                                       // Contract symbol.
	uint256 public decimals;                                    // Token decimals.
	uint256 public totalSupply;                                 // Token total supply.

	mapping(address => uint256) balances;                       // Records balances.
	mapping(address => mapping(address => uint256)) allowed;    // Records allowances for tokens.

	/// @notice Event records info about transfers.
	/// @param from - address sender.
	/// @param to - address recipient.
	/// @param value - amount of tokens transfered.
	event Transfer(address from, address to, uint256 value);

	/// @notice Event records info about approved tokens.
	/// @param owner - address owner of tokens.
	/// @param spender - address spender of tokens.
	/// @param value - amount of tokens allowed to spend.
	event Approval(address owner, address spender, uint256 value);

	/// @notice Contract constructor.
	/// @param _name - name of token.
	/// @param _symbol - symbol of token.
	/// @param _decimals - token decimals.
	/// @param _totalSupply - total supply amount.
	constructor(
		string memory _name,
		string memory _symbol,
		uint256 _decimals,
		uint256 _totalSupply
	)
	{
		name = _name;
		symbol = _symbol;
		decimals = _decimals;
		totalSupply = _totalSupply;
		balances[msg.sender] = _totalSupply;
		emit Transfer(address(0), msg.sender, _totalSupply);
	}

	/// @notice Function to check the current balance of an address.
	/// @param _owner Address of owner.
	/// @return Balances of owner.
	function balanceOf(address _owner) public view returns (uint256) {
		return balances[_owner];
	}

	/// @notice Function to check the amount of tokens that an owner allowed to a spender.
	/// @param _owner The address which owns the funds.
	/// @param _spender The address which will spend the funds.
	/// @return The amount of tokens available for the spender.
	function allowance(
		address _owner,
		address _spender
	)
		public
		view
		returns (uint256)
	{
		return allowed[_owner][_spender];
	}

	/// @notice Function to approve an address to spend the specified amount of msg.sender's tokens.
	/// @param _spender The address which will spend the tokens.
	/// @param _value The amount of tokens allowed to be spent.
	/// @return Success boolean.
	function approve(address _spender, uint256 _value) public returns (bool) {
		allowed[msg.sender][_spender] = _value;

		emit Approval(msg.sender, _spender, _value);        // Records in Approval event.

		return true;
	}

	/// @param _from - sender of tokens.
	/// @param _to - recipient of tokens.
	/// @param _value - amount of transfer.
	function _transfer(address _from, address _to, uint256 _value) internal {
		require(balances[_from] >= _value, "Insufficient balance"); // Requires balance to be sufficient enough for transfer.
		balances[_from] = balances[_from] - (_value);              // Decreases balances of sender.
		balances[_to] = balances[_to] + (_value);                  // Increases balances of recipient.

		emit Transfer(_from, _to, _value);                          // Records transfer to Transfer event.
	}

	/// @notice Function for burning tokens.
	/// @param amount - amount of tokens to burn.
	function burn(uint256 amount) public 
	{
		burnFrom(msg.sender, amount);
	}

	/// @param from - Address of token owner.
	/// @param amount - Amount of tokens to burn.
	function burnFrom(address from, uint256 amount) internal {
		require(balances[from] >= amount, "ERC20: burn amount exceeds balance"); // Requires balance to be sufficient enough for burn.

		balances[from] = balances[from] - (amount);                             // Decreases balances of owner for burn amount.
		totalSupply = totalSupply - (amount);                                   // Decreases total supply of tokens for amount.

		emit Transfer(from, address(0), amount);                                 // Records to Transfer event.
	}

	/// @notice Function for transfering tokens to a specified address.
	/// @param _to The address of recipient.
	/// @param _value The amount of tokens to be transfered.
	/// @return Success boolean.
	function transfer(address _to, uint256 _value) public returns (bool) {
		_transfer(msg.sender, _to, _value);
		return true;
	}

	/// @notice Function for transfering tokens from one specified address to another.
	/// @param _from The address which you want to send tokens from.
	/// @param _to The address recipient.
	/// @param _value The amount of tokens to be transfered.
	/// @return Success boolean.
	function transferFrom(
		address _from,
		address _to,
		uint256 _value
	)
		public
		returns (bool)
	{
		require(allowed[_from][msg.sender] >= _value, "Insufficient allowance"); // Requires allowance for sufficient amount of tokens to send.
		allowed[_from][msg.sender] = allowed[_from][msg.sender] - (_value);     // Decreases amount of allowed tokens for sended value.

		_transfer(_from, _to, _value);                                           // Calls _transfer function.
		return true;
	}

}