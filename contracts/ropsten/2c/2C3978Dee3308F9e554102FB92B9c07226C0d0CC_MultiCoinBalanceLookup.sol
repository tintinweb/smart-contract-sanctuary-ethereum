// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

abstract contract Token {
  function balanceOf(address) public view virtual returns (uint256);
}

contract MultiCoinBalanceLookup {
  fallback() external payable {
    revert('MultiCoinBalanceLookup is not payable');
  }

  receive() external payable {
    revert('MultiCoinBalanceLookup is not payable');
  }

  // Multiple coins balance lookup
  function getBalances(address user, address[] calldata tokens) public view returns (uint256[] memory) {
    uint256[] memory balances = new uint256[](tokens.length);
    for (uint256 idx = 0; idx < tokens.length; idx++) {
      if (!isContract({ contractAddress: tokens[idx] })) continue;
      if (tokens[idx] == address(0x0)) {
        balances[idx] = user.balance;
      } else {
        balances[idx] = Token(tokens[idx]).balanceOf(user);
      }
    }
    return balances;
  }

  /* Private functions */
  function isContract(address contractAddress) internal view returns (bool) {
    uint256 codeSize;
    assembly {
      codeSize := extcodesize(contractAddress)
    }
    return codeSize > 0;
  }
}