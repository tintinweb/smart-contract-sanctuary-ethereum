/**
 *Submitted for verification at Etherscan.io on 2022-07-18
*/

/**
 *Submitted for verification at Etherscan.io on 2022-07-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IEthBalancer
 * @author Amir Shirif, Telcoin, LLC.
 * @notice returns the ETH balance of an address
 */
interface IEthBalancer {
  /**
   * @notice eturns the ETH balance of an address
   * @param location an address[] of wallet and token addresses
   * @return balance uint256 ETH balance of the wallet
   */
  function balanceOf(address location) external view returns (uint256);
}

/**
 * @title TokenBalanceRetriever
 * @author Amir Shirif, Telcoin, LLC.
 * @notice this contract returns a list of balances for various ERC20 tokens
 */
contract EthBalancer is IEthBalancer {
  /**
   * @notice eturns the ETH balance of an address
   * @param location an address[] of wallet and token addresses
   * @return balance uint256 ETH balance of the wallet
   */
  function balanceOf(address location) external view override returns (uint256) {
    return location.balance;
  }
}