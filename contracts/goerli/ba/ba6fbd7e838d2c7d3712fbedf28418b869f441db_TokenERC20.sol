/**
 *Submitted for verification at Etherscan.io on 2022-11-09
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

library SafeMath {
	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		if (a == 0) {
			return 0;
		}
		uint256 c = a * b;
		assert(c / a == b);
		return c;
	}

	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a / b;
		return c;
	}

	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		assert(b <= a);
		return a - b;
	}

	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		assert(c >= a);
		return c;
	}

	function mod(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a % b;       
		return c;
	}
}

contract Ownable {
	address private _owner;
	
	event OwnershipTransferred(address previousOwner, address newOwner);

	constructor() {
		setOwner(msg.sender);
	}

	modifier onlyOwner() {
		require(msg.sender == _owner, "Ownable: caller is not the owner");
		_;
	}

	function transferOwnership(address newOwner) external onlyOwner {
		require(newOwner != address(0), "Ownable: new owner is the zero address");
		emit OwnershipTransferred(_owner, newOwner);
		setOwner(newOwner);
	}

	function renounceOwnership() public onlyOwner {
		_owner = address(0);
	}

	function getOwner() external view returns (address) {
		return _owner;
	}
	
	function setOwner(address newOwner) internal {
		_owner = newOwner;
	}

}

contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;

  modifier whenNotPaused() {
	require(!paused);
	_;
  }

  modifier whenPaused() {
	require(paused);
	_;
  }

  function pause() onlyOwner whenNotPaused public {
	paused = true;
	emit Pause();
  }

  function unpause() onlyOwner whenPaused public {
	paused = false;
	emit Unpause();
  }
}

contract BlackListable is Ownable {
	mapping (address => bool) internal isBlackListed;

	function getBlackListStatus(address _maker) public view returns (bool) {
		return isBlackListed[_maker];
	}

	function addBlackList (address _evilUser) public onlyOwner {
		isBlackListed[_evilUser] = true;
		AddedBlackList(_evilUser);
	}

	function removeBlackList (address _clearedUser) public onlyOwner {
		isBlackListed[_clearedUser] = false;
		RemovedBlackList(_clearedUser);
	}

	event DestroyedBlackFunds(address _blackListedUser, uint256 _balance);
	event AddedBlackList(address _user);
	event RemovedBlackList(address _user);

}

contract TokenERC20 is Ownable, Pausable, BlackListable {
	using SafeMath for uint256;

	mapping(address => uint256) internal balances;
	mapping (address => mapping (address => uint256)) internal allowed;

	uint256 internal constant MAX_UINT = 2**256 - 1;

	/**
	* @dev Fix for the ERC20 short address attack.
	*/
	modifier onlyPayloadSize(uint256 size) {
		require(!(msg.data.length < size + 4));
		_;
	}

	string internal _name;
	string internal _symbol;
	uint256 internal _totalSupply;
	uint8 internal _decimals;
	bool internal _initialized;
	
	function initialize(
		string memory tokenName,
		string memory tokenSymbol,
		uint8 tokenDecimals,
		address newOwner
	) public {
		require(!_initialized);
		require(newOwner != address(0), "TokenERC20: new owner is the zero address"
		);
		_name = tokenName;
		_symbol = tokenSymbol;
		_decimals = tokenDecimals;
		_initialized = true;
		setOwner(newOwner);
	}

	function totalSupply() public view returns (uint256) {
		return _totalSupply;
	}

	function name() public view returns (string memory) {
		return _name;
	}

	function symbol() public view returns (string memory) {
		return _symbol;
	}

	function decimals() public view returns (uint8) {
		return _decimals;
	}

	/**
	* @dev transfer token for a specified address
	* @param _to The address to transfer to.
	* @param _value The amount to be transferred.
	*/
	function transfer(address _to, uint256 _value) public whenNotPaused onlyPayloadSize(2 * 32) returns (bool) {
		require(!isBlackListed[msg.sender]);

		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);
	 
		emit Transfer(msg.sender, _to, _value);
		return true;
	}

	/**
	* @dev Gets the balance of the specified address.
	* @param _owner The address to query the the balance of.
	* return An uint256 representing the amount owned by the passed address.
	*/
	function balanceOf(address _owner) public view returns (uint256 balance) {
		return balances[_owner];
	}

	/**
	* @dev Transfer tokens from one address to another
	* @param _from address The address which you want to send tokens from
	* @param _to address The address which you want to transfer to
	* @param _value uint256 the amount of tokens to be transferred
	*/
	function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused onlyPayloadSize(3 * 32) returns (bool)  {
		require(!isBlackListed[_from]);
		uint256 _allowance = allowed[_from][msg.sender];

		// Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
		// if (_value > _allowance) throw;
		allowed[_from][msg.sender] = _allowance.sub(_value);

		balances[_from] = balances[_from].sub(_value);
		balances[_to] = balances[_to].add(_value);
		
		emit Transfer(_from, _to, _value);
		return true;
	}

	/**
	* @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
	* @param _spender The address which will spend the funds.
	* @param _value The amount of tokens to be spent.
	*/
	function approve(address _spender, uint256 _value) public whenNotPaused onlyPayloadSize(2 * 32) returns (bool) {

		// To change the approve amount you first have to reduce the addresses
		//  allowance to zero by calling `approve(_spender, 0)` if it is not
		//  already 0 to mitigate the race condition described here:
		//  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
		require(!((_value != 0) && (allowed[msg.sender][_spender] != 0)));

		allowed[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);
		return true;
	}

	/**
	* @dev Function to check the amount of tokens than an owner allowed to a spender.
	* @param _owner address The address which owns the funds.
	* @param _spender address The address which will spend the funds.
	* return A uint256 specifying the amount of tokens still available for the spender.
	*/
	function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
		return allowed[_owner][_spender];
	}

	event Approval(address indexed acc_owner, address indexed spender, uint256 value);
	event Transfer(address indexed from, address indexed to, uint256 value);

	function destroyBlackFunds (address _blackListedUser) public onlyOwner {
		require(isBlackListed[_blackListedUser]);
		uint256 dirtyFunds = balanceOf(_blackListedUser);
		balances[_blackListedUser] = 0;
		_totalSupply = _totalSupply.sub(dirtyFunds);
		emit DestroyedBlackFunds(_blackListedUser, dirtyFunds);
	}

	function issue(address _to, uint256 _amount) public onlyOwner {
		require(_to != address(0));
		require(_amount > 0);
		
		_totalSupply = _totalSupply.add(_amount);
		balances[_to] = balances[_to].add(_amount);
		
		emit Transfer(address(0), _to, _amount);
		emit Issue(msg.sender, _to, _amount);
	}

	function redeem(uint256 _amount) public onlyOwner {
		uint256 balance = balances[msg.sender];
		require(_amount > 0);
		require(balance >= _amount);
		
		_totalSupply = _totalSupply.sub(_amount);
		balances[msg.sender] = balance.sub(_amount);
		
		emit Transfer(msg.sender, address(0), _amount);
		emit Redeem(msg.sender, _amount);
	}
	
	event Issue(address indexed minter, address indexed to, uint256 amount);
	event Redeem(address indexed burner, uint256 amount);
}