/**
 *Submitted for verification at Etherscan.io on 2022-07-03
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract Storage {

    mapping(string => uint) public coins;
    event Sent(string symbol, uint amount,uint time);
   function set(string memory symbol,uint amount) public {
       if(calculate(amount, coins[symbol])> 2*coins[symbol]/100){
           coins[symbol] = amount;
           emit Sent(symbol,amount,block.timestamp);
       } else{
           revert("Price similar to contract price");
       }
   }
   function calculate(uint x,uint y) private pure returns (uint) {
    return x >= y ? x - y : y-x;
}
}