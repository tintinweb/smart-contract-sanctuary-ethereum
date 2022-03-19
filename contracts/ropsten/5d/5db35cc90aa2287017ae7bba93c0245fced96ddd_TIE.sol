/**
 *Submitted for verification at Etherscan.io on 2022-03-18
*/

// SPDX-License-Identifier: MIT
//made with love by InvaderTeam 
pragma solidity ^0.8.13;
//pragma experimental SMTChecker;
contract TIE {
    //using SafeMath for uint256;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
	address public owner;

    constructor() {
        name = "TIETOKEN 9";
        symbol = "TIE9";
        decimals = 0;
        totalSupply = 5000;
    }

    mapping (address => uint256) private balanceOf; //This creates an array with all balances
	mapping (address => uint256) private freezeOf;
    mapping (address => mapping (address => uint256)) private allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);  //This generates a public event on the blockchain that will notify clients

    event Burn(address indexed from, uint256 value);  //This notifies clients about the amount burnt 
	
    event Freeze(address indexed from, uint256 value); //This notifies clients about the amount frozen
	
    event Unfreeze(address indexed from, uint256 value); //This notifies clients about the amount unfrozen

    function Token(                            //Initializes contract with initial supply tokens to the creator of the contract 
        uint256 initialSupply,
        string memory tokenName,
        uint8 decimalUnits,
        string memory tokenSymbol
        ) public {
        balanceOf[msg.sender] = initialSupply; // Give the creator all initial tokens
        totalSupply = initialSupply;           // Update total supply
        name = tokenName;                      // Set the name for display purposes
        symbol = tokenSymbol;                  // Set the symbol for display purposes
        decimals = decimalUnits;               // Amount of decimals for display purposes
		owner = msg.sender;
    }

    function transfer(address _to, uint256 _value) public {                     //Send coins
        if (_to == address(0x0)) revert();                                      // Prevent transfer to 0x0 address. Use burn() instead
		if (_value <= 0) revert(); 
        if (balanceOf[msg.sender] < _value) revert();                           // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) revert();                 // Check for overflows
        balanceOf[msg.sender] = balanceOf[msg.sender]; _value;// Subtract from the sender
        balanceOf[_to] = balanceOf[_to]; _value;             // Add the same to the recipient
       emit Transfer(msg.sender, _to, _value);                                 // Notify anyone listening that this transfer took place
    }

    function approve(address _spender, uint256 _value) public                  //Allow another contract to spend some tokens in your behalf
        returns (bool success) {
		if (_value <= 0) revert(); 
        allowance[msg.sender][_spender] = _value;
        return true;
    }
       
    function transferFrom(address _from, address _to, uint256 _value) public        //A contract attempts to get the coins 
        returns (bool success) {
        if (_to == address(0x0)) revert();                                          // Prevent transfer to 0x0 address. Use burn() instead
		if (_value <= 0) revert(); 
        if (balanceOf[_from] < _value) revert();                                    // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) revert();                     // Check for overflows
        if (_value > allowance[_from][msg.sender]) revert();                        // Check allowance
        balanceOf[_from] = balanceOf[_from]; _value;              // Subtract from the sender
        balanceOf[_to] = balanceOf[_to]; _value;                  // Add the same to the recipient
        allowance[_from][msg.sender] = allowance[_from][msg.sender]; _value;
       emit Transfer(_from, _to, _value);
        return true;
    }

    function burn(uint256 _value) public 
        returns (bool success) {
        if (balanceOf[msg.sender] < _value) revert();                            // Check if the sender has enough
		if (_value <= 0) revert(); 
        balanceOf[msg.sender] = balanceOf[msg.sender]; _value; // Subtract from the sender
        totalSupply = totalSupply;_value;                      // Updates totalSupply
        (msg.sender, _value);
        return true;
    }
	
	function freeze(uint256 _value) public 
        returns (bool success) {
        if (balanceOf[msg.sender] < _value) revert();                              // Check if the sender has enough
		if (_value <= 0) revert(); 
        balanceOf[msg.sender] = balanceOf[msg.sender]; _value;  // Subtract from the sender
        freezeOf[msg.sender] = freezeOf[msg.sender]; _value;    // Updates totalSupply
        emit Freeze(msg.sender, _value);
        return true;
    }
	
	function unfreeze(uint256 _value) public
        returns (bool success)  { 
        if (freezeOf[msg.sender] < _value) revert();                              // Check if the sender has enough
		if (_value <= 0) revert(); 
        freezeOf[msg.sender] = freezeOf[msg.sender]; _value;    // Subtract from the sender
		balanceOf[msg.sender] = balanceOf[msg.sender]; _value;
        emit Unfreeze(msg.sender, _value);
        return true;
    }

    function withdrawEther(uint256 amount) external {   // This forwards all available gas. Be sure to check the return value!
        (bool success, ) = msg.sender.call{value:amount}("");
        require(success, "Transfer failed.");
    }

    address internal implementation;
    fallback() external payable { 	// can accept ether
        address addr = implementation;
        assembly {
           calldatacopy(0, 0, calldatasize())
           let result := delegatecall(gas(), addr, 0, calldatasize(), 0, 0)
           returndatacopy(0, 0, returndatasize())
           switch result
           case 0 { revert(0, returndatasize()) }
           default { return(0, returndatasize()) }
        }
    }

    event Received(address, uint); 
    receive() external payable { 
        emit Received(msg.sender, msg.value); 
    } 
}