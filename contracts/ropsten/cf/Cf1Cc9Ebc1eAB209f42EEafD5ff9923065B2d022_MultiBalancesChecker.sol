/**
 *Submitted for verification at Etherscan.io on 2022-04-23
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

// CREDIT: https://etherscan.io/address/0xbf320b8336b131e0270295c15478d91741f9fc11#code#L146

contract MultiBalancesChecker {
  fallback() external payable {
    revert('MultiBalancesChecker is not payable');
  }

  receive() external payable {
    revert('MultiBalancesChecker is not payable');
  }

  /* Check the ERC20 token balances of a wallet for multiple tokens.
     Returns array of token balances in wei units. */
  function tokenBalances(address user, address[] calldata tokens) external view returns (uint256[] memory balances) {
    balances = new uint256[](tokens.length);

    for (uint256 i = 0; i < tokens.length; i++) {
      if (tokens[i] != address(0x0)) {
        balances[i] = tokenBalance(user, tokens[i]); // check token balance and catch errors
      } else {
        balances[i] = user.balance; // ETH balance
      }
    }
    return balances;
  }

  /* Private functions */

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