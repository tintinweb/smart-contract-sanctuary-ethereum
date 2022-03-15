// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../interfaces/IWETH.sol";

contract WETHUnwrapper {
  address constant weth = 0xDf032Bc4B9dC2782Bb09352007D4C57B75160B15;

  receive() external payable {}

  /**
   * @notice Convert WETH to ETH and transfer to msg.sender
   * @dev msg.sender needs to send WETH before calling this withdraw
   * @param _amount amount to withdraw.
   */
  function withdraw(uint256 _amount) external {
    IWETH(weth).withdraw(_amount);
    (bool sent, ) = msg.sender.call{ value: _amount }("");
    require(sent, "Failed to send ETH");
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWETH {
  function approve(address, uint256) external;

  function deposit() external payable;

  function withdraw(uint256) external;
}