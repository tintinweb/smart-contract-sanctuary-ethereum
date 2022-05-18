/**
 *Submitted for verification at Etherscan.io on 2022-05-18
*/

pragma solidity ^0.4.2;

contract DappToken {

	//getters are generated automatically implicitly
	uint256 public totalSupply; //"totalSupply" - ERC20 standard
	mapping(address => uint256) public balanceOf; //"balanceOf" - ERC20 standard
	string public name = "DApp Token"; //"name" - ERC20 standard
	string public symbol = "DAPP"; //"symbol" - ERC20 standard
	string public standard = "DApp Token v1.0";

	//I, account "a", am approving account "b" (or f,g,h...) to spend "c" (uint256) amount of tokens
	mapping(address => mapping(address => uint256)) public allowance; //"allowance" - ERC20 standard

	//"Transfer" - ERC20 standard
	event Transfer(
		address indexed _from, 
		address indexed _to, 
		uint256 _value
	);

	event Approval(
		address indexed _owner, 
		address indexed _spender, 
		uint256 _value
	);

	constructor(uint256 _initialSupply) public {
		balanceOf[msg.sender] = _initialSupply;
		totalSupply = _initialSupply;
	}

	//"transfer" - ERC20 standard - allows token owner to transfer the token to someone else
	function transfer(address _to, uint256 _value) public returns(bool success) {
		require(balanceOf[msg.sender] >= _value);

		//transfer the balance
		balanceOf[msg.sender] -= _value;
		balanceOf[_to] += _value;

		emit Transfer(msg.sender, _to, _value);

		return true;
	}

	//approve allows somebody else to spend tokes on their behalf
	//my account "a" allows account "b" to spend "c" amount of tokens on my behalf
	//account "b" executes "transferFrom" function
	//allowance is amount approved to be transfered

	//I am account "a" and i'm allowing _spender, account "b" to spend "c" _value amount of token
	function approve(address _spender, uint256 _value) public returns(bool success) {
		
		allowance[msg.sender][_spender] = _value;

		emit Approval(msg.sender, _spender, _value);
		return true;
	}

	//Account b calls this function, and it takes _from (account that owns tokens), to, and value
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
		require(_value <= balanceOf[_from]);
		require(_value <= allowance[_from][msg.sender]);

		balanceOf[_from] -= _value;
		balanceOf[_to] += _value;

		allowance[_from][msg.sender] -= _value;

		emit Transfer(_from, _to, _value);

		return true;
	}
}