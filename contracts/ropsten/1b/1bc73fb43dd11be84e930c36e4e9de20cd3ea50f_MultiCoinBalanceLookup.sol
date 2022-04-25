/**
 *Submitted for verification at Etherscan.io on 2022-04-23
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

struct Balance {
  uint256 balance;
  string name;
  string symbol;
  uint8 decimals;
}

contract MultiCoinBalanceLookup {
  fallback() external payable {
    revert('MultiCoinBalanceLookup is not payable');
  }

  receive() external payable {
    revert('MultiCoinBalanceLookup is not payable');
  }

  string _name = 'name()';
  string _symbol = 'symbol()';
  string _decimals = 'decimals()';

  function getBalances(address user, address[] calldata tokens) public view returns (Balance[] memory balances) {
    balances = new Balance[](tokens.length);
    for (uint256 i = 0; i < tokens.length; i++) {
      if (tokens[i] != address(0x0)) {
        balances[i].balance = tokenBalance(user, tokens[i]);
        balances[i].name = contractName(tokens[i]);
        balances[i].symbol = contractSymbol(tokens[i]);
        balances[i].decimals = contractDecimals(tokens[i]);
      } else {
        balances[i].balance = user.balance;
        balances[i].name = 'Ether';
        balances[i].symbol = 'ETH';
        balances[i].decimals = 18;
      }
    }
    return balances;
  }

  /* Private functions */
  function execTokenMethod(string storage method, address contractAddress)
    internal
    view
    returns (bool success, bytes memory result)
  {
    bytes memory call = abi.encodeWithSignature(method, contractAddress);
    return contractAddress.staticcall(call);
  }

  function contractName(address contractAddress) internal view returns (string memory name) {
    (bool success, bytes memory result) = execTokenMethod(_name, contractAddress);
    if (!success) {
      return '';
    }
    return abi.decode(result, (string));
  }

  function contractSymbol(address contractAddress) internal view returns (string memory symbol) {
    (bool success, bytes memory result) = execTokenMethod(_symbol, contractAddress);
    if (!success) {
      return '';
    }
    return abi.decode(result, (string));
  }

  function contractDecimals(address contractAddress) internal view returns (uint8 decimals) {
    (bool success, bytes memory result) = execTokenMethod(_decimals, contractAddress);
    if (!success) {
      return 0;
    }
    return abi.decode(result, (uint8));
  }

  /* Check the token balance of a wallet in a token contract.
    Returns 0 on a bad token contract   */
  function tokenBalance(address user, address token) internal view returns (uint256) {
    // token.balanceOf(user), selector 0x70a08231
    return getNumberOneArg(token, 0x70a08231, user);
  }

  /* Generic private functions */

  // Get a token or exchange value that requires 1 address argument (most likely arg1 == user).
  // selector is the hashed function signature (see top comments)
  function getNumberOneArg(
    address contractAddr,
    bytes4 selector,
    address arg1
  ) internal view returns (uint256) {
    if (isAContract(contractAddr)) {
      (bool success, bytes memory result) = contractAddr.staticcall(abi.encodeWithSelector(selector, arg1));
      // if the contract call succeeded & the result looks good to parse
      if (success && result.length == 32) {
        return abi.decode(result, (uint256)); // return the result as uint
      } else {
        return 0; // function call failed, return 0
      }
    } else {
      return 0; // not a valid contract, return 0 instead of error
    }
  }

  // check if contract (token, exchange) is actually a smart contract and not a 'regular' address
  function isAContract(address contractAddr) internal view returns (bool) {
    uint256 codeSize;
    assembly {
      codeSize := extcodesize(contractAddr)
    } // contract code size
    return codeSize > 0;
    // Might not be 100% foolproof, but reliable enough for an early return in 'view' functions
  }
}