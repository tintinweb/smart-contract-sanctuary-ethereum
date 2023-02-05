// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.16;

/**
  @title A hash-testing contract.
  @author Tim Clancy
*/
contract HashTester {

  /// Track the value of the last generated flag.
  uint256 public flag;

  /**
    Allow a caller to generate a new flag if their provided `_nonce` can do so.

    @param _nonce A nonce from the caller to attempt to replace the flag.
  */
  function generateFlag (
    uint256 _nonce
  ) external {
    uint256 newFlag = uint256(
      keccak256(abi.encodePacked(flag, _nonce, msg.sender))
    );
    require(newFlag > flag, "The flag must increase");
    flag = newFlag;
  }

  function checkFlag (
    uint256 _nonce,
    address _caller
  ) external view returns (uint256) {
    uint256 newFlag = uint256(
      keccak256(abi.encodePacked(flag, _nonce, _caller))
    );
    return newFlag;
  }
}