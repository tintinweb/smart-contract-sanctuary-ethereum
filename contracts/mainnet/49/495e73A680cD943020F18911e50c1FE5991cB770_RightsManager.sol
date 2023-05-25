// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;

// Needed to handle structures externally
pragma experimental ABIEncoderV2;

/**
 * @author Desyn Labs
 * @title Manage Configurable Rights for the smart pool
 *                         by default, it is off on initialization and can only be turned on
 *      canWhitelistLPs - can limit liquidity providers to a given set of addresses
 *      canChangeCap - can change the BSP cap (max # of pool tokens)
 *      canChangeFloor - can change the BSP floor for Closure ETF (min # of pool tokens)
 */
library RightsManager {
    // Type declarations

    enum Permissions {
        WHITELIST_LPS,
        TOKEN_WHITELISTS
    }

    struct Rights {
        bool canWhitelistLPs;
        bool canTokenWhiteLists;
    }

    // State variables (can only be constants in a library)
    bool public constant DEFAULT_CAN_WHITELIST_LPS = false;
    bool public constant DEFAULT_CAN_TOKEN_WHITELISTS = false;

    // bool public constant DEFAULT_CAN_CHANGE_CAP = false;
    // bool public constant DEFAULT_CAN_CHANGE_FLOOR = false;

    // Functions

    /**
     * @notice create a struct from an array (or return defaults)
     * @dev If you pass an empty array, it will construct it using the defaults
     * @param a - array input
     * @return Rights struct
     */
    function constructRights(bool[] calldata a) external pure returns (Rights memory) {
        if (a.length < 2) {
            return
                Rights(
                    DEFAULT_CAN_WHITELIST_LPS,
                    DEFAULT_CAN_TOKEN_WHITELISTS
                );
        } else {
            // return Rights(a[0], a[1], a[2], a[3], a[4], a[5], a[6]);
            return Rights(a[0], a[1]);
        }
    }

    /**
     * @notice Convert rights struct to an array (e.g., for events, GUI)
     * @dev avoids multiple calls to hasPermission
     * @param rights - the rights struct to convert
     * @return boolean array containing the rights settings
     */
    function convertRights(Rights calldata rights) external pure returns (bool[] memory) {
        bool[] memory result = new bool[](2);

        result[0] = rights.canWhitelistLPs;
        result[1] = rights.canTokenWhiteLists;

        return result;
    }

    // Though it is actually simple, the number of branches triggers code-complexity
    /* solhint-disable code-complexity */

    /**
     * @notice Externally check permissions using the Enum
     * @param self - Rights struct containing the permissions
     * @param permission - The permission to check
     * @return Boolean true if it has the permission
     */
    function hasPermission(Rights calldata self, Permissions permission) external pure returns (bool) {
        if (Permissions.WHITELIST_LPS == permission) {
            return self.canWhitelistLPs;
        } else if (Permissions.TOKEN_WHITELISTS == permission) {
            return self.canTokenWhiteLists;
        }
    }

    /* solhint-enable code-complexity */
}