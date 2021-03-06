pragma solidity ^0.4.24;

contract ERC20 {
	uint256 public totalSupply;
	function balanceOf(address _owner) public view returns (uint256);
	function transfer(address _to, uint256 _value) public returns (bool);
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
	function approve(address _spender, uint256 _value) public returns (bool);
	function allowance(address _owner, address _spender) public view returns (uint256 remaining);
	event Transfer(address indexed _from, address indexed _to, uint256 _value);
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


contract TokenRecipient {
	function receiveApproval(address _from, uint256 _value, address _token, bytes _data) public;
	function tokenFallback(address _from, uint256 _value, bytes _data) public;
}


contract T is ERC20 {
	mapping (address => uint256) balances;
	mapping (address => mapping (address => uint256)) allowed;
	uint8 public decimals;
	string public name;
	string public symbol;
	
	bool public running;
	address public owner;
	address public ownerTemp;
	
	
	
	modifier isOwner {
		require(owner == msg.sender);
		_;
	}
	
	modifier isRunning {
		require(running);
		_;
	}
	
	function isContract(address _addr) private view returns (bool) {
		uint length;
		assembly {
			length := extcodesize(_addr)
		}
		return length > 0;
	}
	
	constructor() public {
		running = true;
		owner = msg.sender;
		decimals = 18;
		totalSupply = 2 * uint(10)**(decimals + 9);
		balances[owner] = totalSupply;
		name = "Token";
		symbol = "TKN";
		emit Transfer(0x0, owner, totalSupply);
	}
	
	
	
	function transfer(address _to, uint256 _value) public isRunning returns (bool) {
		require(balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]);
		balances[msg.sender] -= _value;
		balances[_to] += _value;
		if (isContract(_to)) {
			bytes memory empty;
			TokenRecipient(_to).tokenFallback(msg.sender, _value, empty);
		}
		emit Transfer(msg.sender, _to, _value);
		return true;
	}
	
	function transfer(address _to, uint256 _value, bytes _data) public isRunning returns (bool) {
		require(balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]);
		balances[msg.sender] -= _value;
		balances[_to] += _value;
		if (isContract(_to)) {
			TokenRecipient(_to).tokenFallback(msg.sender, _value, _data);
		}
		emit Transfer(msg.sender, _to, _value);
		return true;
	}
	
	function transfer(address _to, uint256 _value, bytes _data, string _callback) public isRunning returns (bool) {
		require(balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]);
		balances[msg.sender] -= _value;
		balances[_to] += _value;
		if (isContract(_to)) {
			assert(_to.call.value(0)(bytes4(keccak256(_callback)), msg.sender, _value, _data));
		}
		emit Transfer(msg.sender, _to, _value);
		return true;
	}
	
	function transfer(address[] _tos, uint256[] _values) public isRunning returns (bool) {
		uint cnt = _tos.length;
		require(cnt > 0 && cnt <= 1000 && cnt == _values.length);
		bytes memory empty;
		uint256 totalAmount = 0;
		uint256 val;
		address to;
		
		for (uint i = 0; i < cnt; i++) {
			val = _values[i];
			to = _tos[i];
			
			require(balances[to] + val >= balances[to] && totalAmount + val >= totalAmount);
			balances[to] += val;
			totalAmount += val;
			if (isContract(to)) {
				TokenRecipient(to).tokenFallback(msg.sender, val, empty);
			}
			emit Transfer(msg.sender, to, val);
		}
		
		require(balances[msg.sender] >= totalAmount);
		balances[msg.sender] -= totalAmount;
		return true;
	}
	
	
	
	
	
	
	function balanceOf(address _owner) public view returns (uint256) {
		return balances[_owner];
	}
	
	function transferFrom(address _from, address _to, uint256 _value) public isRunning returns (bool) {
		require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]);
		balances[_to] += _value;
		balances[_from] -= _value;
		allowed[_from][msg.sender] -= _value;
		emit Transfer(_from, _to, _value);
		return true;
	}

	function approve(address _spender, uint256 _value) public isRunning returns (bool) {
		allowed[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);
		return true;
	}
	
	function approve(address _spender, uint256 _value, uint256 _check) public isRunning returns (bool) {
		require(allowed[msg.sender][_spender] == _check);
		return approve(_spender, _value);
	}

	function allowance(address _owner, address _spender) public view returns (uint256) {
	  return allowed[_owner][_spender];
	}
	
	function approveAndCall(address _spender, uint256 _value, bytes _data) public isRunning returns (bool) {
		if (approve(_spender, _value)) {
			TokenRecipient(_spender).receiveApproval(msg.sender, _value, this, _data);
			return true;
		}
	}
	
	function approveAndCall(address _spender, uint256 _value, bytes _data, string _callback) public isRunning returns (bool) {
		if (approve(_spender, _value)) {
			assert(_spender.call.value(0)(bytes4(keccak256(_callback)), msg.sender, _value, _data));
			return true;
		}
	}



	function setName(string _name) public isOwner {
		name = _name;
	}
	
	function setSymbol(string _symbol) public isOwner {
		symbol = _symbol;
	}
	
	function setRunning(bool _run) public isOwner {
		running = _run;
	}
	
	function transferOwnership(address _owner) public isOwner {
		ownerTemp = _owner;
	}
	
	function acceptOwnership() public {
		require(msg.sender == ownerTemp);
		owner = ownerTemp;
		ownerTemp = 0x0;
	}
	
	function collectERC20(ERC20 _token, uint _amount) public isRunning isOwner returns (bool success) {
		return _token.transfer(owner, _amount);
	}
}