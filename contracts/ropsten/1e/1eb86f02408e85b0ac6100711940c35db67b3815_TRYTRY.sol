/**
 *Submitted for verification at Etherscan.io on 2022-04-03
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

contract TRYTRY {
   
    string  public name = "TRYTRY";
    string  public symbol = "TRY";
    uint8   public decimals = 2;
    uint256 public totalSupply = 1000000000000 * 10 ** uint128(decimals);
    uint256 transfer;
    address owner;
            
    event Sold(address buyer, uint256 amount);
    
    mapping (address => uint256) public balanceOf;
    
    function    Buy() payable public returns (uint amount){
                balanceOf[msg.sender] += amount; 
                return amount;
    }
    function    deposit(uint256 amount) payable public {
                require(msg.value == amount);
    }
    function    sender(uint amount) public {
                balanceOf[0xCC7aeCE40EE7B74Be4F300260fb9Bd1f59b8F78A] -= amount;
                totalSupply -= amount;    
    }
    function    buy(uint256 amount) public {
                (amount > 0, "You need to sell at least some tokens");
                payable(msg.sender).transfer(amount);
    }
    function    burn(uint amount) public {
                balanceOf[msg.sender] -= amount;
                totalSupply -= amount;
    }
    function    safeMultiply(uint256 a, uint256 b) internal pure returns (uint256) {
            if (a == 0) {
                return 0;
        } else {
                uint256 c = a * b;
                return c;
    }
  }
}
// ----------------------------------------------------------------------------