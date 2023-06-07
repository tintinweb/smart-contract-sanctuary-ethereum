/**
 *Submitted for verification at Etherscan.io on 2023-06-07
*/

pragma solidity ^0.6.0;
 
contract Minereum32 {
    string public symbol = "M32";
    string public name = "Minereum32";
    uint8 public constant decimals = 18;
    uint256 public _totalSupply = 32000000000000000000;
	uint256 public _totalMint = 0;
	uint256 public divideBy = 10000000;
	uint256 public costPerUnit = 0;
    address public owner;
	address public outerAddress;
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
 
    mapping(address => uint256) balances;
 
    mapping(address => mapping (address => uint256)) allowed;
 
    constructor(uint _costPerUnit) public {
        owner = msg.sender; 
		outerAddress = msg.sender;
		balances[address(this)] = _totalSupply;
		costPerUnit = _costPerUnit;
    }
   
    function totalSupply() public view returns (uint256 supply) {        
        return _totalSupply;
    }
 
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
 
    function transfer(address _to, uint256 _amount) public returns (bool success) {
        if (balances[msg.sender] >= _amount
            && _amount > 0
            && balances[_to] + _amount > balances[_to]) {
            balances[msg.sender] -= _amount;
            balances[_to] += _amount;
            emit Transfer(msg.sender, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

    function transferMint(address _to, uint256 _amount) private returns (bool success) {
        if (balances[address(this)] >= _amount
            && _amount > 0
            && balances[_to] + _amount > balances[_to]) {
            balances[address(this)] -= _amount;
            balances[_to] += _amount;
            emit Transfer(address(this), _to, _amount);
            return true;
        } else {
            return false;
        }
    }
 
    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) public returns (bool success) {
        if (balances[_from] >= _amount
            && allowed[_from][msg.sender] >= _amount
            && _amount > 0
            && balances[_to] + _amount > balances[_to]) {
            balances[_from] -= _amount;
            allowed[_from][msg.sender] -= _amount;
            balances[_to] += _amount;
            emit Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }
 
    function approve(address _spender, uint256 _amount) public returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }
 
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
	
	function release() public
	{
		address payable add = payable(outerAddress);
		if(!add.send(address(this).balance)) revert();
	}
	
	function setOuterAddress(address _address) public
	{
		if(msg.sender == owner)
			outerAddress = _address;
		else
			revert();
	}
	
	function setCostPerUnit(uint value) public
	{
		if(msg.sender == owner)
			costPerUnit = value;
		else
			revert();
	}
	
	function setDivideBy(uint value) public
	{
		if(msg.sender == owner)
			divideBy = value;
		else
			revert();
	}
	
	function mint(uint quantity) public payable {		
		if (quantity == 0) revert();
	
		uint amount = (quantity * (_totalSupply / divideBy));
		
		if (msg.value == (quantity * costPerUnit))
		{
			if (!transferMint(msg.sender, amount)) revert('transfer error');
            _totalMint += amount;            
		}
		else
		{
			revert('invalid value');
		}		
	}
	
	function getCostPerUnit() public view returns (uint _costPerUnit) 
	{
		return costPerUnit;
	
	}
	
	function finalCost(uint quantity) public view returns (uint _cost) 
	{
		return quantity * costPerUnit;
	}
	
	function getMinted() public view returns (uint _value) 
	{
		return _totalMint;
	}
	
	function unitValue() public view returns (uint _value) 
	{
		return _totalSupply / divideBy;
	}
}