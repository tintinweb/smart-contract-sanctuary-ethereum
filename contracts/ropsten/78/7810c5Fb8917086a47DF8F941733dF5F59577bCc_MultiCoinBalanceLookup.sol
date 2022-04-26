// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

abstract contract Token {
  function balanceOf(address) public view virtual returns (uint256);

  function name() public view virtual returns (string memory);

  function symbol() public view virtual returns (string memory);

  function decimals() public view virtual returns (uint256);

  function totalSupply() public view virtual returns (uint256);
}

contract MultiCoinBalanceLookup {
  fallback() external payable {
    revert('MultiCoinBalanceLookup is not payable');
  }

  receive() external payable {
    revert('MultiCoinBalanceLookup is not payable');
  }

  struct Balance {
    address contractAddress;
    uint256 balance;
    string name;
    string symbol;
    uint256 decimals;
  }

  // Multiple coins balance lookup
  function getBalances(address user, address[] calldata tokens) public view returns (Balance[] memory balances) {
    balances = new Balance[](tokens.length);
    for (uint256 idx = 0; idx < tokens.length; idx++) {
      if (!isContract(tokens[idx])) continue;
      balances[idx] = getBalance(user, tokens[idx]);
    }
    return balances;
  }

  // Single coin balance lookup
  function getBalance(address user, address token) public view returns (Balance memory balance) {
    if (token != address(0x0)) {
      return
        Balance({
          contractAddress: token,
          balance: Token(token).balanceOf(user),
          name: Token(token).name(),
          symbol: Token(token).symbol(),
          decimals: Token(token).decimals()
        });
    }
    return Balance({ contractAddress: token, balance: user.balance, name: 'Ether', symbol: 'ETH', decimals: 18 });
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