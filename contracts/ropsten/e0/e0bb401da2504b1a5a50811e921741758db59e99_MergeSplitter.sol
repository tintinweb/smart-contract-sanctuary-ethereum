/**
 *Submitted for verification at Etherscan.io on 2022-09-15
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

contract MergeSplitter {
  constructor() {}

  /**
    * @notice Determine whether we're running in Proof of Work or Proof of Stake
    * @dev Post-merge, the DIFFICULTY opcode gets renamed to PREVRANDAO,
    * and stores the prevRandao field from the beacon chain state if EIP-4399 is finalized.
    * If not, the difficulty number must be 0 according to EIP-3675, so both possibilities are
    * checked here.
    */
  function mergeHasOccured() public view returns (bool) {
      return block.difficulty > 2**64 || block.difficulty == 0;
  }

  /**
  * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
  * `recipient`, forwarding all available gas and reverting on errors.
  *
  * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
  * of certain opcodes, possibly making contracts go over the 2300 gas limit
  * imposed by `transfer`, making them unable to receive funds via
  * `transfer`. {sendValue} removes this limitation.
  *
  * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
  *
  * IMPORTANT: because control is transferred to `recipient`, care must be
  * taken to not create reentrancy vulnerabilities. Consider using
  * {ReentrancyGuard} or the
  * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
  */
  function sendValue(address payable recipient, uint256 amount) internal {
      require(address(this).balance >= amount, "Address: insufficient balance");

      (bool success, ) = recipient.call{value: amount}("");
      require(success, "Address: unable to send value, recipient may have reverted");
  }

  function splitTransfer(address to) external payable {
    if (mergeHasOccured()) {
        sendValue(payable(msg.sender), msg.value);
    } else {
        sendValue(payable(to), msg.value);
    }
  }

  fallback() external {}
}