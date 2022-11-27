/**
 *Submitted for verification at Etherscan.io on 2022-11-27
*/

/**
 *Submitted for verification at Etherscan.io on 2022-10-25
*/

/**
 *Submitted for verification at BscScan.com on 2022-09-30
*/

pragma solidity ^0.4.16;

interface tokenRecipient { 
  function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; 
  }


contract TokenERC20 {
	

    string public name;
    string public symbol;
    uint8 public decimals = 18;   
    uint256 public totalSupply;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address indexed from, uint256 value);
		address private owner;
	  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  	address public HoleAddr = 0x000000000000000000000000000000000000dEaD;
	
	  mapping(address =>bool) public isLpAddr;
    	

    function setLpAddr(address _addr, bool _bool) external {
        isLpAddr[_addr] = _bool;
    }
	
    function TokenERC20(uint256 initialSupply, string tokenName, string tokenSymbol) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
        name = tokenName;
        symbol = tokenSymbol;
        owner = msg.sender;
    }

    function _transfer(address _from, address _to, uint _value) internal {
		
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        
		uint toVal=_value;
		uint toHoleVal=0;
		if (isLpAddr[_from]){
			toHoleVal=_value * (100) / (10000);
			Transfer(_from, HoleAddr, toHoleVal);
			toVal=_value - (toHoleVal);
					  
		}
		if (isLpAddr[_to]){
			toHoleVal=_value * (150) / (10000);
			Transfer(_from, HoleAddr, toHoleVal);
			toVal=_value - (toHoleVal);

		}
 
 
        balanceOf[_from] -= _value;
        balanceOf[_to] += toVal;
        Transfer(_from, _to, toVal);
 
    }
    
    function transfer(address _to, uint256 _value) public returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }
    
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        Burn(msg.sender, _value);
        return true;
    }
    
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);
        require(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] -= _value;
        allowance[_from][msg.sender] -= _value;
        totalSupply -= _value;
        Burn(_from, _value);
        return true;
    }
}