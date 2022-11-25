// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "KomonAccessControl.sol";
import {Modifiers} from "Modifiers.sol";

contract RoleControlFacet102 is KomonAccessControl, Modifiers {
    function updateAssetsToKomonAccount(address account) external onlyKomonWeb {
        _setAssetstoKomonAccount(account);
    }
}