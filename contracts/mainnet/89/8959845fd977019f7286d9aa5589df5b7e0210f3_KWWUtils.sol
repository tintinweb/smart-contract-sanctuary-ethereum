/**
 *Submitted for verification at Etherscan.io on 2022-03-20
*/

// File: contracts/KWWUtils.sol


pragma solidity >=0.7.0 <0.9.0;

library KWWUtils{

  uint constant DAY_IN_SECONDS = 86400;
  uint constant HOUR_IN_SECONDS = 3600;
  uint constant WEEK_IN_SECONDS = DAY_IN_SECONDS * 7;

  function pack(uint32 a, uint32 b) external pure returns(uint64) {
        return (uint64(a) << 32) | uint64(b);
  }

  function unpack(uint64 c) external pure returns(uint32 a, uint32 b) {
        a = uint32(c >> 32);
        b = uint32(c);
  }

  function random(uint256 seed) external view returns (uint256) {
    return uint256(keccak256(abi.encodePacked(
        tx.origin,
        blockhash(block.number - 1),
        block.difficulty,
        block.timestamp,
        seed
    )));
  }


  function getWeekday(uint256 timestamp) public pure returns (uint8) {
      //https://github.com/pipermerriam/ethereum-datetime
      return uint8((timestamp / DAY_IN_SECONDS + 4) % 7);
  }
}