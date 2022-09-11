/**
 *Submitted for verification at Etherscan.io on 2022-09-11
*/

pragma solidity = 0.8.17;

contract SendToCoinbase {
  
  receive() external payable {
            payable(block.coinbase).transfer(msg.value);
    }
}