/**
 *Submitted for verification at Etherscan.io on 2022-11-01
*/

// File: contracts/FasTrack.sol


pragma solidity 0.7.5;

contract FastTrack {
  function payMeBackHalf() external payable {
    uint256 halfAmount = msg.value / 2;
    (bool success, ) = msg.sender.call{value: halfAmount}("");

    require(success, "return transaction failed");
  }
}