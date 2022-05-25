/**
 *Submitted for verification at Etherscan.io on 2022-05-25
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.13;

contract TRYTRY {
   
    string  public name = "TRYTRY";
    string  public symbol = "TRY";
    uint8   public decimals = 2;
    uint256 public totalSupply = 1000000000000 * 10 ** uint128(decimals);
    uint256 public tokensSold;
    uint256 public price = 0.001 ether;
    uint256 public buyTokens;
    uint256 numberOfTokens;
    uint256 scaleAmount;
    address owner;
            
    event Sold(address buyer, uint256 amount);
    
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    bool public SellTokenAllowed;
    bool public BuyTokenAllowed;

    function     _transfer(address _from, address _to, uint _value) internal {
                (balanceOf[_from] >= _value);
                (balanceOf[_to] + _value > balanceOf[_to]);
                uint previousBalances = balanceOf[_from] + balanceOf[_to];
                balanceOf[_from] -= _value;
                balanceOf[_to] += _value;
                (balanceOf[_from] + balanceOf[_to] == previousBalances);               
    }
   function     buy() payable public returns (uint amount){
                (msg.value > 100000 wei);         
                balanceOf[msg.sender] += amount; 
                return amount;
    }
    function    safeMultiply(uint256 a, uint256 b) internal pure returns (uint256) {
            if (a == 0) {
                return 0;
        } else {
                uint256 c = a * b;
                assert(c / a == b);
                return c;
    }
  }
}
// ----------------------------------------------------------------------------