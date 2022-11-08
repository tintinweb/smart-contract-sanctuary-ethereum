// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "KomonAccessControl.sol";
import {Modifiers} from "Modifiers.sol";

contract RoleControlFacet is KomonAccessControl, Modifiers {
    function isAdmin(address account) external view virtual returns (bool) {
        return hasAdminRole(account);
    }

    function isKomonWeb(address account) external view virtual returns (bool) {
        return hasKomonWebRole(account);
    }

    function isCreator(address account) external view virtual returns (bool) {
        return hasCreatorRole(account);
    }

    function setRoleAdmin(bytes32 role, bytes32 adminRole) external onlyAdmin {
        _setRoleAdmin(role, adminRole);
    }

    function updateKomonExchangeWallet(address exchangeWallet)
        external
        onlyAdmin
    {
        _setExchangeWallet(exchangeWallet);
    }
}