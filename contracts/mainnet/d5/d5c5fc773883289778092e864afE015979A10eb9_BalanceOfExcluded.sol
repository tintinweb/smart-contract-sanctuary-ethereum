// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

interface IERC20 {
  function balanceOf(address) external view returns (uint256);
}

contract BalanceOfExcluded {
  IERC20 public immutable token;

  mapping(address => bool) public excluded;

  constructor(address _token, address[] memory _excluded) {
    token = IERC20(_token);
    for (uint i; i < _excluded.length; ++i) {
      excluded[_excluded[i]] = true;
    }
  }

  function balanceOf(address user) external view returns (uint256) {
    if (excluded[user]) {
      return 0;
    } else {
      return token.balanceOf(user);
    }
  }
}