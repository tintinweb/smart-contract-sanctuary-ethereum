/**
 *Submitted for verification at Etherscan.io on 2022-03-31
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;


 
contract TRYTRY {
   
    bytes32 public name = "TRYTRY";
    bytes32 public symbol = "TRY";
    uint8 public decimals = 2;
    uint256 public _totalSupply = 2500000000;
    uint256 public TokenPerETHBuy = 100;  /// 1 TOKEN = 0.01 ETH
    

       // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);

    // Constructor function Initializes contract with initial supply tokens to the creator of the contract

    constructor () {

    }
        //Internal transfer, only can be called by this contract
   
    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        // Check if the sender has enough
        (balanceOf[_from] >= _value);
        // Check for overflows
        (balanceOf[_to] + _value > balanceOf[_to]);
        // Save this for an assertion in the future
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        // Subtract from the sender
        balanceOf[_from] -= _value;
        // Add the same to the recipient
        balanceOf[_to] += _value;
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        (balanceOf[_from] + balanceOf[_to] == previousBalances);
    }
    function buyTokens(address _receiver) public payable {
    uint256 _amount = msg.value;
    (_receiver != address(0));
    (_amount > 0);
    }
    // Transfer tokens

    // Transfer tokens from other address


    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }
    modifier onlyPayloadSize(uint size) {
    (msg.data.length >= size + 4) ;
     _;
  }
// ----------------------------------------------------------------------------
     //* Destroy tokens
     //* Remove `_value` tokens from the system irreversibly
     //* @param _value the amount of money to burn

    function burn(uint256 _value) public returns (bool success) {
        (balanceOf[msg.sender] >= _value);   // Check if the sender has enough
        balanceOf[msg.sender] -= _value;            // Subtract from the sender
        emit Burn(msg.sender, _value);
        
        return true;
        
    }
     

}
// ----------------------------------------------------------------------------