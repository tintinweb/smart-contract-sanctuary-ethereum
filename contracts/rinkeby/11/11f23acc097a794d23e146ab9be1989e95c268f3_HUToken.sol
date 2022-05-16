/**
 *Submitted for verification at Etherscan.io on 2022-05-15
*/

pragma solidity >=0.4.22 <0.9.0;

contract HUToken {
	mapping(address => uint256) public balances;
	mapping(address => mapping(address => uint256)) public allowances;

	constructor() {
		balances[msg.sender] = totalSupply();
	}

	function name() public view returns (string memory) {
		return "HU Lab Token";
	}

	function symbol() public view returns (string memory) {
		return "HUT";
	}

	function decimals() public view returns (uint8) {
		return 0;
	}

	function totalSupply() public view returns (uint256) {
		return 128;
	}

	function balanceOf(address _owner) public view returns (uint256 balance) {
		return balances[_owner];
	}

	function transfer(address _to, uint256 _value) public returns (bool success) {
		require(balances[msg.sender] >= _value);

		balances[msg.sender] -= _value;
		balances[_to] += _value;

		emit Transfer(msg.sender, _to, _value);

		return true;
	}
	
	function approve(address _spender, uint256 _value) public returns (bool success) {
		allowances[msg.sender][_spender] = _value;

		emit Approval(msg.sender, _spender, _value);

		return true;
	}

	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
		require(balances[_from] >= _value);
		require(allowances[_from][msg.sender] >= _value);

		if(allowances[_from][msg.sender] != type(uint256).max)
			allowances[_from][msg.sender] -= _value;

		balances[_from] -= _value;
		balances[_to] += _value;

		emit Transfer(_to, _to, _value);

		return true;
	}


	function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
		return allowances[_owner][_spender];
	}

	event Transfer(address indexed _from, address indexed _to, uint256 _value);
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}