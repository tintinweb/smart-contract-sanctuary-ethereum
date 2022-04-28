// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./Ownable.sol";
import "./ERC20.sol";

contract WGMI_V1 is ERC20, Ownable {
  /**
   * @dev Constructor that gives msg.sender all of existing tokens.
   */
  uint256 public constant initialSupply = 10000000 ether; // 10 million

  constructor() ERC20("WGMI Version 1", "WGMI") {
    _mint(msg.sender, initialSupply);
  }

  function mint(address recipient, uint256 amount) external onlyOwner {
    _mint(recipient, amount);
  }
}