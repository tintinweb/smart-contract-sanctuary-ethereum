/**
 *Submitted for verification at Etherscan.io on 2022-02-03
*/

pragma solidity 0.4.25;

contract ERC20Basic {
	function totalSupply() public view returns (uint256);
	function balanceOf(address who) public view returns (uint256);
	function transfer(address to, uint256 value) public returns (bool);
	event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
	function allowance(address owner, address spender) public view returns (uint256);
	function transferFrom(address from, address to, uint256 value) public returns (bool);
	function approve(address spender, uint256 value) public returns (bool);
	event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract DetailedERC20 is ERC20 {
	string public name;
	string public symbol;
	uint8 public decimals;
	
	constructor(string _name, string _symbol, uint8 _decimals) public {
		name = _name;
		symbol = _symbol;
		decimals = _decimals;
	}
}

contract BasicToken is ERC20Basic {
	using SafeMath for uint256;
	mapping(address => uint256) balances;

	uint256 _totalSupply;
	function totalSupply() public view returns (uint256) {
		return _totalSupply;
	}

	function transfer(address _to, uint256 _value) public returns (bool) {
		require(_to != address(0), "ERC20: transfer to the zero address");
        balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);
		emit Transfer(msg.sender, _to, _value);
		
		return true;
	}
	
	function balanceOf(address _owner) public view returns (uint256 balance) {
		return balances[_owner];
	}
}
contract ERC20Token is BasicToken, ERC20 {
	using SafeMath for uint256;
	mapping (address => mapping (address => uint256)) public allowed;
	
	function approve(address _spender, uint256 _value) public returns (bool) {
		require(_value == 0 || allowed[msg.sender][_spender] == 0, "ERC20: The amount must not be zero.");
		allowed[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);
		
		return true;
	}
	
	function allowance(address _owner, address _spender) public view returns (uint256) {
		require(_owner != address(0), "ERC20: transfer _owner the zero address");
		return allowed[_owner][_spender];
	}

	function increaseAllowance(address _spender, uint256 _addedValue) public returns (bool) {
		require(_spender != address(0), "ERC20: transfer to the zero address");
		allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		
		return true;
	}
	
	function decreaseAllowance(address _spender, uint256 _subtractedValue) public returns (bool) {
		require(_spender != address(0), "ERC20: transfer to the zero address");
		allowed[msg.sender][_spender] = allowed[msg.sender][_spender].sub(_subtractedValue);
		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		
		return true;
	}
	
}

contract Ownable {

	address public owner;
	mapping (address => bool) admin;
	
	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
	
	constructor() public {
		owner = msg.sender;
	}


	modifier onlyOwner() {
		require(msg.sender == owner, "ERC20: It must be the owner wallet.");
		_;
	}
	
	modifier onlyOwnerOrAdmin() {
		require(msg.sender == owner || admin[msg.sender] == true, "ERC20: It must be the owner's wallet or the ADMIN's wallet.");
		_;
	}
	
	function transferOwnership(address newOwner) onlyOwner public {
		require(newOwner != address(0) && newOwner != owner && admin[newOwner] == true, "ERC20: It must be an admin wallet, not the owner, and not the first wallet.");
		emit OwnershipTransferred(owner, newOwner);
		owner = newOwner;
	}

	function setAdmin(address newAdmin) onlyOwner public {
	    require(newAdmin != address(0), "ERC20: It should not be the first wallet..");
		require(admin[newAdmin] != true && owner != newAdmin, "ERC20: It should not be the owner wallet, not the admin wallet.");
		
		admin[newAdmin] = true;
	}
	
	function unsetAdmin(address Admin) onlyOwner public {
		require(admin[Admin] != false && owner != Admin, "ERC20: It should not be the owner wallet, the admin wallet.");
		admin[Admin] = false;
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


contract PauserRole {
	using Roles for Roles.Role;
	
	event PauserAdded(address indexed account);
	event PauserRemoved(address indexed account);

	Roles.Role private pausers;

	constructor() internal {
		_addPauser(msg.sender);
	}

	modifier onlyPauser() {
		require(isPauser(msg.sender));
		_;
	}

	function isPauser(address account) public view returns (bool) {
		return pausers.has(account);
	}

	function addPauser(address account) public onlyPauser {
		_addPauser(account);
	}

	function renouncePauser() public {
		_removePauser(msg.sender);
	}

	function _addPauser(address account) internal {
		pausers.add(account);
		emit PauserAdded(account);
	}

	function _removePauser(address account) internal {
		pausers.remove(account);
		emit PauserRemoved(account);
	}

}

library SafeMath {
	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		if (a == 0) {
		    return 0;
		}

		uint256 c = a * b;
		require(c / a == b, "SafeMath: multiplication overflow");

		return c;
	    }


	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		require(b > 0,  "SafeMath: division by zero");
        uint256 c = a / b;
        
        return c;
	}
	
	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
	}

	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		require(c >= a, "SafeMath: addition overflow");
		return c;
	}
}



library Roles {
	struct Role {
		mapping (address => bool) bearer;
	}

	function add(Role storage role, address account) internal {
		require(account != address(0), "ERC20: It should not be the first wallet..");
		require(!has(role, account));

		role.bearer[account] = true;
	}

	function remove(Role storage role, address account) internal {
		require(account != address(0), "ERC20: It should not be the first wallet..");
		require(has(role, account));

		role.bearer[account] = false;
	}

	function has(Role storage role, address account) internal view returns (bool){
		require(account != address(0), "ERC20: It should not be the first wallet..");
		return role.bearer[account];
	}
	
}

contract BurnableToken is BasicToken, Ownable {
	

	function burn(uint256 _value) onlyOwner public {
		balances[msg.sender] = balances[msg.sender].sub(_value);
		_totalSupply = _totalSupply.sub(_value);
		emit Transfer(msg.sender, address(0), _value);
	}
}



contract CellBitDataproject is BurnableToken, DetailedERC20, ERC20Token,Pausable{
	using SafeMath for uint256;

	event Approval(address indexed owner, address indexed spender, uint256 value);
	
	
	
	string public constant symbol = "CBD";
 	string public constant name = "CellBitDataproject";
	uint8 public constant decimals = 18;
	
	uint256 public constant TOTAL_SUPPLY = 40*(10**8)*(10**uint256(decimals));

	constructor() DetailedERC20(name, symbol, decimals) public {
		_totalSupply = TOTAL_SUPPLY;
		balances[owner] = _totalSupply;
		emit Transfer(address(0x0), msg.sender, _totalSupply);
	}

	
	function transfer(address _to, uint256 _value)  public whenNotPaused returns (bool){
		return super.transfer(_to, _value);
	}

	function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool){
	    require( _from != address(0) && _to != address(0), "ERC20: It should not be the first wallet..");

		balances[_from] = balances[_from].sub(_value);
		balances[_to] = balances[_to].add(_value);
		allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

		emit Transfer(_from, _to, _value);

		return true;
		
	}
	
	
	
	function() public payable {
		revert();
	}
}