/**
 *Submitted for verification at Etherscan.io on 2022-04-01
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

contract TRYTRY {
   
    string public name = "TRYTRY";
    string public symbol = "TRY";
    uint8 public decimals = 2;
    uint256 public totalSupply = 1000000000000 * 10 ** uint128(decimals);
    uint128 public TokenPerETHSell = 100000;  /// 1 TOKEN = 0.01 ETH
    
    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    
    bool public SellTokenAllowed;
    bool public BuyTokenAllowed;


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
   function sell() payable public returns (uint amount){
          (msg.value > 0);         
          balanceOf[msg.sender] += amount; 
          return amount;
    }
    
    modifier onlyPayloadSize(uint size) {
    (msg.data.length >= size + 4) ;
     _;
  }

}
// ----------------------------------------------------------------------------