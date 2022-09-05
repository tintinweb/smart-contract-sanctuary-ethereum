// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.16;

import "./Ownable.sol";
import "./ERC20.sol";
import "./Context.sol";

contract POWAA is Context, Ownable, ERC20("POWAA token", "POWAA") {
  /// @dev Custom Errors
  error POWAA_MaxTotalSupplyExceeded();

  /// @dev Variables
  uint256 private immutable _maxTotalSupply;

  constructor(uint256 maxTotalSupply_) {
    _maxTotalSupply = maxTotalSupply_;
  }

  function maxTotalSupply() external view virtual returns (uint256) {
    return _maxTotalSupply;
  }

  function mint(address to, uint256 amount) external onlyOwner returns (bool) {
    if (ERC20.totalSupply() + amount > _maxTotalSupply) {
      revert POWAA_MaxTotalSupplyExceeded();
    }
    _mint(to, amount);
    return true;
  }
}