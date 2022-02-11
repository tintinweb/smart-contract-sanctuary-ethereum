/**
 *Submitted for verification at Etherscan.io on 2022-02-11
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.4;

contract ValidatorSet {
  address[] public currentValidatorSet;

  function setValidators(address[] memory _validatorSet) external  {
    delete currentValidatorSet;

      for (uint256 i = 0; i < _validatorSet.length; i++) {
          currentValidatorSet.push(_validatorSet[i]);
      }
  }

  function getValidators()external view returns(address[] memory) {
    uint n = currentValidatorSet.length;

    address[] memory consensusAddrs = new address[](n);
    for (uint i = 0;i<n;i++) {
        consensusAddrs[i] = currentValidatorSet[i];
    }
    return consensusAddrs;
  }
}