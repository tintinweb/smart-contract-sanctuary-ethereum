/**
 *Submitted for verification at Etherscan.io on 2022-01-30
*/

pragma solidity ^0.4.18;
 
/**
 * Math operations with safety checks
 */
contract SafeMath {
    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    require(c / a == b);
    return c;
    }
 
    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);
    uint256 c = a / b;
    require(a == b * c + a % b);
    return c;
    }
 
    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    return a - b;
    }
 
    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c>=a && c>=b);
    return c;
    } 
}
 
contract Token is SafeMath{
 
    function balanceOf(address _owner) public constant returns (uint256 balance);
	
    function transfer(address _to, uint256 _value) public returns (bool success);
	
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
 
    function approve(address _spender, uint256 _value) public returns (bool success);
 
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
 
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
	
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
 
contract TokenTEST is Token {
    uint256 public totalSupply;				
    string  public name;                   	
    uint8   public decimals;               
    string  public symbol;               	
    address public owner;                   
	
    /* This creates an array with all balances */
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
 
    constructor(uint256 initialAmount, string tokenName, uint8 decimalUnits, string tokenSymbol) public {
        totalSupply = SafeMath.safeMul(initialAmount , 10 ** uint256(decimalUnits));  
        balances[msg.sender] = totalSupply; 						
        emit Transfer(address(0), msg.sender, totalSupply);                         
		 
        name = tokenName;                   
        decimals = decimalUnits;          
        symbol = tokenSymbol;
        owner = msg.sender;
    }
 
    /* Send tokens */
    function transfer(address _to, uint256 _value) public returns (bool success) {
    	require(_to != address(0));
    	require(_to != msg.sender);
    	require(_value >= 0);
    	require(balances[msg.sender] >= _value);
    	require(balances[_to] + _value >= balances[_to]);
        
    	balances[msg.sender] = SafeMath.safeSub(balances[msg.sender], _value);   // Subtract from the sender
    	balances[_to] = SafeMath.safeAdd(balances[_to], _value);                 
    	emit Transfer(msg.sender, _to, _value);		                                 
    	return true;
    }
 
    /* A contract attempts to get the tokens */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
    	require(_to != address(0));
    	require(_to != _from);
    	require(_value >= 0);
    	require(_value <= balances[_from]);                  // Check if the sender has enough
    	require(_value <= allowed[_from][msg.sender]);       // Check allowance
    	require(balances[_to] + _value >= balances[_to]);    // Check for overflows
		
    	balances[_from] = SafeMath.safeSub(balances[_from], _value);                           // Subtract from the sender
    	balances[_to] = SafeMath.safeAdd(balances[_to], _value);    // Add the same to the recipient
    	allowed[_from][msg.sender] = SafeMath.safeSub(allowed[_from][msg.sender], _value);
    	emit Transfer(_from, _to, _value);			             
    	return true;
    }
	
    function balanceOf(address _owner) public constant returns (uint256 balance) {
    	return balances[_owner];
    }
 
    /* Allow another contract to spend some tokens in your behalf */	
    function approve(address _spender, uint256 _value) public returns (bool success) { 
        //require((_value == 0) || (allowed[msg.sender][_spender] == 0)); 
    	allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
 
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];		
    }
	
    // only owner can kill
    function  kill() public{ 
        require(msg.sender == owner);
        selfdestruct(owner);             
    }
 
}