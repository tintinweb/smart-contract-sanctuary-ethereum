/**
 *Submitted for verification at Etherscan.io on 2022-07-14
*/

pragma solidity >=0.7.0 <0.9.0;
 
//Safe Math Interface
 
contract SafeMath {
 
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
 
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
 
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
 
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}
 
 
//ERC Token Standard #20 Interface
 
abstract contract  ERC20Interface {
    function  totalSupply() virtual  external view returns (uint ta);
    function balanceOf(address tokenOwner) virtual  external view returns (uint balance);
    function allowance(address tokenOwner, address spender) virtual  external view returns (uint remaining);
    function transfer(address to, uint tokens) virtual  public returns (bool success);
    function approve(address spender, uint tokens) virtual  public returns (bool success);
    function transferFrom(address from, address to, uint tokens) virtual  public returns (bool success);
 
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}
 
 
//Contract function to receive approval and execute function in one call
 
abstract contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token,  bytes memory data) virtual public;
}
 
//Actual token contract

// Creating a Contract
contract MunnaToken is ERC20Interface, SafeMath
{
    string public constant name = "MunnaToken";
    string public constant symbol = "MKS";
    uint8 public constant decimals = 18;  
// Table to map addresses
// to their balance
mapping(address => uint256) balances;

// Mapping owner address to
// those who are allowed to
// use the contract
mapping(address => mapping (
		address => uint256)) allowed;

// totalSupply
uint256 _totalSupply = 500000;

// owner address
address public owner;

constructor() {
    owner = 0xbB51f31D15aB6C3856E07fb1Dc82aFFF8f8DfB86;
}

// totalSupply function
 function totalSupply() override
		public view returns (
		uint256 theTotalSupply)
{
theTotalSupply = _totalSupply;
return theTotalSupply;
}

// balanceOf function
function balanceOf(address _owner) override
		public view returns (
		uint256 balance)
{
return balances[_owner];
}

// function approve
function approve(address _spender,
				uint256 _amount) override
				public returns (bool success) 
{
	// If the address is allowed
	// to spend from this contract
allowed[msg.sender][_spender] = _amount;
	
// Fire the event "Approval"
// to execute any logic that
// was listening to it
emit Approval(msg.sender,
				_spender, _amount);
return true;
}

// transfer function
function transfer(address _to,
				uint256 _amount) override
				public returns (bool success)
{
	// transfers the value if
	// balance of sender is
	// greater than the amount
	if (balances[msg.sender] >= _amount)
	{
		balances[msg.sender] = safeSub(balances[msg.sender],_amount);
        balances[_to] = safeAdd(balances[_to],_amount);
		// balances[_to] += _amount;
		
		// Fire a transfer event for
		// any logic that is listening
		emit Transfer(msg.sender,
					_to, _amount);
			return true;
	}
	else
	{
		return false;
	}
}


/* The transferFrom method is used for
a withdraw workflow, allowing
contracts to send tokens on
your behalf, for example to
"deposit" to a contract address
and/or to charge fees in sub-currencies;*/
function transferFrom(address _from,
					address _to,
					uint256 _amount) override
					public returns (bool success)
{
if (balances[_from] >= _amount &&
	allowed[_from][msg.sender] >=
	_amount && _amount > 0 &&
	balances[_to] + _amount > balances[_to])
{
		balances[_from] -= _amount;
		balances[_to] += _amount;
		
		// Fire a Transfer event for
		// any logic that is listening
		emit Transfer(_from, _to, _amount);
	return true;

}
else
{
	return false;
}
}

// Check if address is allowed
// to spend on the owner's behalf
function allowance(address _owner,
				address _spender) override
				public view returns (uint256 remaining)
{
return allowed[_owner][_spender];
}
}