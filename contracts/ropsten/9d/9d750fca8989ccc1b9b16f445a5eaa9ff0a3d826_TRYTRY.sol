/**
 *Submitted for verification at Etherscan.io on 2022-04-03
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

contract TRYTRY {
   
    string  public name = "TRYTRY";
    string  public symbol = "TRY";
    uint8   public decimals = 2;
    uint256 public totalSupply = 1000000000 ;
    uint256 transfer;
    address owner;
    uint256 balance;
    uint256 getBalance;
                
    mapping (address => uint256) public balanceOf;
    
    function    buy() payable public returns (uint amount){
                balanceOf[msg.sender] += amount; 
                return amount;
    }
    function    burn(uint amount) public {
                balanceOf[msg.sender] -= amount;
                totalSupply -= amount;
    }
    function    externalTransfer(uint amount, address recipient) public {
                payable(recipient).transfer(amount);
    }
    modifier    onlyOwner () {
                require(msg.sender == owner, "This can only be called by the contract owner!");
                 _;
    }
    function withdrawAmount(uint256 amount) onlyOwner payable public {
         require(msg.value == amount);
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