/**
 *Submitted for verification at Etherscan.io on 2022-02-17
*/

/**
 *Submitted for verification at Etherscan.io on 2017-07-06
*/

pragma solidity ^0.4.24;


 // 自定义一个安全的加减乘除
contract SafeMath {
  function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b > 0);
    uint256 c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

}
contract DYXTCLCoin is SafeMath{
    string public name;   // 代币名称
    string public symbol;  // 代币简称
    uint8 public decimals;   //
    uint256 public totalSupply;  //总发行量

	address public owner;  // 管理员

    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;  // {地址：金额, ...}
	mapping (address => uint256) public freezeOf;
    mapping (address => mapping (address => uint256)) public allowance;

    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /* This notifies clients about the amount burnt */
    event Burn(address indexed from, uint256 value);
	
	/* This notifies clients about the amount frozen */
    event Freeze(address indexed from, uint256 value);
	
	/* This notifies clients about the amount unfrozen */
    event Unfreeze(address indexed from, uint256 value);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    constructor(
        uint256 _initialSupply,  // 发行数量
        string _tokenName, // token的名称。DYXCoin
        // uint8 _decimalUnits, // 最小分割
        string _tokenSymbol // 简称. DYXC
        ) public {
        balanceOf[msg.sender] = _initialSupply *10**18;              // Give the creator all initial tokens
        totalSupply = _initialSupply *10**18;                        // Update total supply
        name = _tokenName;                                   // Set the name for display purposes
        symbol = _tokenSymbol;                               // Set the symbol for display purposes
        decimals = 18;                            // Amount of decimals for display purposes
		owner = msg.sender;
    }

    /* Send coins */
    // 某个人发费自己的代币
    function transfer(address _to, uint256 _value) public {
        assert (_to != 0x0);                               // Prevent transfer to 0x0 address. Use burn() instead
		    assert (_value > 0); 
        assert (balanceOf[msg.sender] >= _value);           // Check if the sender has enough
        assert (balanceOf[_to] + _value >= balanceOf[_to]); // Check for overflows

        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);                     // Subtract from the sender
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);                            // Add the same to the recipient
        emit Transfer(msg.sender, _to, _value);                   // Notify anyone listening that this transfer took place
    }

    /* Allow another contract to spend some tokens in your behalf */
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        assert (_value>0);
        allowance[msg.sender][_spender] = _value;
        return true;
    }
       

    /* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        assert (_to != 0x0);                                // Prevent transfer to 0x0 address. Use burn() instead
		    assert (_value > 0); 
        assert (balanceOf[_from] >= _value);                 // Check if the sender has enough
        assert (balanceOf[_to] + _value >= balanceOf[_to]);  // Check for overflows
        assert (_value <= allowance[_from][msg.sender]);     // Check allowance
        balanceOf[_from] = SafeMath.safeSub(balanceOf[_from], _value);                           // Subtract from the sender
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);                             // Add the same to the recipient
        allowance[_from][msg.sender] = SafeMath.safeSub(allowance[_from][msg.sender], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function burn(uint256 _value) public returns (bool success) {
        assert (balanceOf[msg.sender] >= _value);            // Check if the sender has enough
		    assert (_value > 0); 
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);                      // Subtract from the sender
        totalSupply = SafeMath.safeSub(totalSupply,_value);                                // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }
	
	function freeze(uint256 _value) public returns (bool success) {
        assert (balanceOf[msg.sender] >= _value);            // Check if the sender has enough
		    assert (_value > 0); 
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);                      // Subtract from the sender
        freezeOf[msg.sender] = SafeMath.safeAdd(freezeOf[msg.sender], _value);                                // Updates totalSupply
        emit Freeze(msg.sender, _value);
        return true;
    }
	
	function unfreeze(uint256 _value) public returns (bool success) {
        assert (freezeOf[msg.sender] >= _value);            // Check if the sender has enough
		    assert (_value > 0); 
        freezeOf[msg.sender] = SafeMath.safeSub(freezeOf[msg.sender], _value);                      // Subtract from the sender
		balanceOf[msg.sender] = SafeMath.safeAdd(balanceOf[msg.sender], _value);
        emit Unfreeze(msg.sender, _value);
        return true;
    }
	
	// transfer balance to owner
	function withdrawEther(uint256 amount) public {
		assert(msg.sender == owner);
		owner.transfer(amount);
	}
	
	// can accept ether
	function() public payable {
    }
}