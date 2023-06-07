// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./KomonAccessControl.sol";
import { Modifiers } from "./Modifiers.sol";

contract RoleControlFacet203 is KomonAccessControl, Modifiers {
  function updateUsdcManagerAccount(address account) external onlyAdmin {
    _setUsdcManagerAccount(account);
  }
}