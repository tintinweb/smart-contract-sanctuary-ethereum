// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.9;

import "../interfaces/IUnwrapper.sol";
import "../interfaces/IWETH.sol";

contract Unwrapper is IUnwrapper {
  address public immutable wNative;

  constructor(address _wNative) {
    wNative = _wNative;
  }

  receive() external payable {}

  /**
   * @notice See {IUnwrapper}.
   */
  function withdraw(uint256 amount) external {
    IWETH(wNative).withdraw(amount);
    (bool sent, ) = msg.sender.call{ value: amount }("");
    require(sent, "Failed to send native");
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.9;

interface IUnwrapper {
  /**
   * @notice Convert wrappedNative to native and transfer to msg.sender
   * @param amount amount to withdraw.
   * @dev msg.sender needs to send WrappedNative before calling this withdraw
   */
  function withdraw(uint256 amount) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.9;

interface IWETH {
  function approve(address, uint256) external;

  function deposit() external payable;

  function withdraw(uint256) external;
}