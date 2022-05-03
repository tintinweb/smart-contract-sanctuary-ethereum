/**
 *Submitted for verification at Etherscan.io on 2022-05-03
*/

// File: contracts/IncentiveCompute.sol


pragma solidity =0.7.6;
pragma abicoder v2;
 
struct IncentiveKey {
   address rewardToken;
   address pool;
   uint256 startTime;
   uint256 endTime;
   address refundee;
}
 
contract IncentiveId {
   /// @notice Calculate the key for a staking incentive
   /// @param key The components used to compute the incentive identifier
   /// @return incentiveId The identifier for the incentive
   function compute(IncentiveKey memory key) public pure returns (bytes memory incentiveId) {
       return abi.encode(key);
   }
   function decode(bytes memory data)  public pure returns (IncentiveKey memory incentive) {
       return abi.decode(data, (IncentiveKey));
   }
}