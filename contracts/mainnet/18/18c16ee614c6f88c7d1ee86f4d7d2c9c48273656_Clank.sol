// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "SafeMath.sol";

abstract contract ERC20Basic {
	function totalSupply() public view virtual returns (uint256);
	function balanceOf(address who) public view virtual returns (uint256);
	function transfer(address to, uint256 value) public virtual returns (bool);
	event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BasicToken is ERC20Basic {
	using SafeMath for uint256;
	mapping(address => uint256) balances;
	uint256 totalSupply_;

	function totalSupply() public view override returns (uint256) {
		return totalSupply_;
	}

	function transfer(address _to, uint256 _value) public override virtual returns (bool) {
		require(_to != address(0), "Clank:transfer: _to == address(0)");
		require(_value <= balances[msg.sender], "Clank:transfer: _value > balances[msg.sender]");
		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);
		emit Transfer(msg.sender, _to, _value);
		return true;
	}

	function balanceOf(address _owner) public view override returns (uint256) {
		return balances[_owner];
	}
}

abstract contract ERC20 is ERC20Basic {
	function allowance(address owner, address spender) public view virtual returns (uint256);
	function transferFrom(address from, address to, uint256 value) public virtual returns (bool);
	function approve(address spender, uint256 value) public virtual returns (bool);

	event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StandardToken is ERC20, BasicToken {
	using SafeMath for uint256;		
	mapping (address => mapping (address => uint256)) internal allowed;

	function transferFrom(address _from, address _to, uint256 _value) public override virtual returns (bool)
	{
		require(_to != address(0), "Clank:transferFrom: _to == address(0)");
		require(_value <= balances[_from], "Clank:transferFrom: _value > balances[_from]");
		require(_value <= allowed[_from][msg.sender], "Clank:transferFrom: _value > allowed[_from][msg.sender]");

		balances[_from] = balances[_from].sub(_value);
		balances[_to] = balances[_to].add(_value);
		allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
		emit Transfer(_from, _to, _value);
		return true;
	}

	function approve(address _spender, uint256 _value) public override virtual returns (bool) {
		allowed[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);
		return true;
	}

	function allowance(address _owner, address _spender) public view override virtual returns (uint256) {
		return allowed[_owner][_spender];
	}

	function increaseApproval(address _spender, uint _addedValue) public	returns (bool) {
		allowed[msg.sender][_spender] = (
			allowed[msg.sender][_spender].add(_addedValue));
		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}

	function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
		uint oldValue = allowed[msg.sender][_spender];
		if (_subtractedValue > oldValue) {
			allowed[msg.sender][_spender] = 0;
		} else {
			allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
		}
		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}
}

contract MultiOwnable {
	mapping (address => bool) owners;
	address unremovableOwner;
	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
	event OwnershipExtended(address indexed host, address indexed guest);
	event OwnershipRemoved(address indexed removedOwner);
	
	modifier onlyOwner() {
		require(owners[msg.sender], "Clank:onlyOwner: not in owners[msg.sender]");
		_;
	}
	
	constructor() {
		owners[msg.sender] = true;
		unremovableOwner = msg.sender;
	}
	
	function addOwner(address guest) onlyOwner public {
		require(guest != address(0), "Clank:addOwner: guest == address(0)");
		owners[guest] = true;
		emit OwnershipExtended(msg.sender, guest);
	}
	
	function removeOwner(address removedOwner) onlyOwner public {
		require(removedOwner != address(0), "Clank:removeOwner: removedOwner == address(0)");
		require(unremovableOwner != removedOwner, "Clank:removeOwner: unremovableOwner != removedOwner");
		delete owners[removedOwner];
		emit OwnershipRemoved(removedOwner);
	}

	function transferOwnership(address newOwner) onlyOwner public {
		require(newOwner != address(0), "Clank:transferOwnership: newOwner == address(0)");
		require(unremovableOwner != msg.sender, "Clank:transferOwnership: unremovableOwner != msg.sender");
		owners[newOwner] = true;
		delete owners[msg.sender];
		emit OwnershipTransferred(msg.sender, newOwner);
	}

	function isOwner(address addr) public view returns(bool){
		return owners[addr];
	}
}

contract Clank is StandardToken, MultiOwnable {
	using SafeMath for uint256;
	
	uint256 public constant TOTAL_CAP = 1000000000;
	string public constant name = "Clank";
	string public constant symbol = "CLNK";
	uint256 public constant decimals = 18;

	event Mint(address indexed _to, uint256 _amount);
	event Burn(address indexed _from, uint256 _amount);

	constructor() {
		totalSupply_ = TOTAL_CAP.mul(10 ** decimals);
		balances[msg.sender] = totalSupply_;
		emit Transfer(address(0), msg.sender, balances[msg.sender]);
	}

	function transferFrom(address _from, address _to, uint256 _value) public override returns (bool) {
		return super.transferFrom(_from, _to, _value);
	}

	function transfer(address _to, uint256 _value) public override returns (bool) {
		return super.transfer(_to, _value);
	}
 
	function mint(address _to, uint256 _amount) onlyOwner public returns (bool) {
		require(_to != address(0), "Clank:mint: _to == address(0)");
		totalSupply_ = totalSupply_.add(_amount);
		balances[_to] = balances[_to].add(_amount);
		emit Mint(_to, _amount);
		emit Transfer(address(0), _to, _amount);
		return true;
	}
 
	function burn(uint256 _amount) onlyOwner public {
		require(_amount <= balances[msg.sender], "Clank:burn: _amount > balances[msg.sender]");
		totalSupply_ = totalSupply_.sub(_amount);
		balances[msg.sender] = balances[msg.sender].sub(_amount);
		emit Burn(msg.sender, _amount);
		emit Transfer(msg.sender, address(0), _amount);
	}
}