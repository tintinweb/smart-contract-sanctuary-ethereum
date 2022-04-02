/**
 *Submitted for verification at Etherscan.io on 2022-04-02
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

contract TRYTRY {
   
    string  public name = "TRYTRY";
    string  public symbol = "TRY";
    uint8   public decimals = 2;
    uint256 private totalSupply = 1000000000000 * 10 ** uint128(decimals);
    //uint256 public TokenPerETHSell = 100000;  /// 1 TOKEN = 0.01 ETH
    uint256 numberOfTokens;
    uint256 scaleAmount;
    address owner;
            
    event Sold(address buyer, uint256 amount);
    
    mapping (address => uint256) public balanceOf;
    
    function    buy() payable public returns (uint amount){
                (msg.value > 100000 wei);         
                balanceOf[msg.sender] += amount; 
                return amount;
    }
    function    Buy() payable public returns (uint amount){
                (msg.value > 1000000000 wei);         
                balanceOf[msg.sender] += amount; 
                return amount;
    }
    function    mint(uint amount) external {
                balanceOf[msg.sender] += amount;
                totalSupply += amount;
                
    
    }

    function sell(uint256 amount) public {

    require(amount > 0, "You need to sell at least some tokens");

    payable(msg.sender).transfer(amount);
    
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