/**
 *Submitted for verification at Etherscan.io on 2022-04-26
*/

pragma solidity 0.5.3;

contract ERC20 {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

library SafeMath {
	function add(uint a, uint b) internal pure returns(uint){
		uint c = a + b;
		require(c >= a, "Sum Overflow!");
		return c;
	}

	function sub(uint a, uint b) internal pure returns(uint){
		require(b <= a, "Sub Underflow!");
		uint c = a - b;
		return c;
	}

	function mul(uint a, uint b) internal pure returns(uint){
		if(a == 0) {
			return 0;
		}
		uint c = a * b;
		require(c / a == b, "Mul Overflow!");
		return c;
	}

	function div(uint a, uint b) internal pure returns(uint){
		uint c = a / b;
		return c;
	}
}

contract Ownable {
	address payable public owner;

	event OwnershipTransfered(address newOwner);

	constructor() public {
		owner = msg.sender;
	}

	modifier onlyOwner() {
		require(msg.sender == owner, "You are not the owner!");
		_;
	}

	function transferOwnsership(address payable newOwner) onlyOwner public{
		owner = newOwner;

		emit OwnershipTransfered(owner);
	}
}

contract BasicToken is Ownable, ERC20{
	using SafeMath for uint;

	uint internal _totalSuply;
	mapping(address => uint) internal _balances;

	//Mapping[address1][address2] => uint
	//address1 allows address2 to spent a certain amount of tokens
	mapping(address => mapping(address => uint)) internal _allowed;

	//ERC20 Stuff----------
	function totalSupply() public view returns (uint){
		return _totalSuply;
	}

	function balanceOf(address tokenOwner) public view returns (uint){
		return _balances[tokenOwner];
	}

	function transfer(address to, uint tokens) public returns (bool){
		require(_balances[msg.sender] >= tokens);
		require(to != address(0));

		_balances[msg.sender] = _balances[msg.sender].sub(tokens);
		_balances[to] = _balances[to].add(tokens);

		emit Transfer(msg.sender, to, tokens);
		return true;
	}

	function approve(address spender, uint tokens) public returns (bool){
		_allowed[msg.sender][spender] = tokens;
		emit Approval(msg.sender, spender, tokens);
		return true;
	}

	function allowance(address tokenOwner, address spender) public view returns (uint){
		return _allowed[tokenOwner][spender];
	}

	function transferFrom(address from, address to, uint tokens) public returns (bool){
		require(_allowed[from][msg.sender] >= tokens);
		require(_balances[from] >= tokens);
		require(to != address(0));

		_balances[from] = _balances[from].sub(tokens);
		_balances[to] = _balances[to].add(tokens);
		_allowed[from][msg.sender] = _allowed[from][msg.sender].sub(tokens);

		emit Transfer(from, to, tokens);
		return true;
	}
}

contract MintableToken is BasicToken{
	
	event Mint(address indexed to, uint tokens);

	function mint(address to, uint tokens) onlyOwner public {
		_balances[to] = _balances[to].add(tokens);
		_totalSuply = _totalSuply.add(tokens);

		emit Mint(to, tokens);
	}
}

contract BassToken is MintableToken {
	string public constant name = "BassToken";
	string public constant symbol = "BST";
	uint8 public constant decimal = 18;
}