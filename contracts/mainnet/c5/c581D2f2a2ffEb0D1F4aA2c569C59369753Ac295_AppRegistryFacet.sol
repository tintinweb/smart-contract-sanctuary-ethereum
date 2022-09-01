/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "../../security/role-manager/RoleManagerLib.sol";
import "../../diamond/IDiamondFacet.sol";
import "../IAppRegistry.sol";
import "./AppRegistryInternal.sol";
import "./AppRegistryConfig.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
contract AppRegistryFacet is IDiamondFacet, IAppRegistry {

    modifier onlyAppRegistryAdmin() {
        RoleManagerLib._checkRole(AppRegistryConfig.ROLE_APP_REGISTRY_ADMIN);
        _;
    }

    function getFacetName() external pure override returns (string memory) {
        return "app-registry";
    }

    function getFacetVersion() external pure override returns (string memory) {
        return "0.0.1";
    }

    function getFacetPI() external pure override returns (string[] memory) {
        string[] memory pi = new string[](6);
        pi[0] = "getAllApps()";
        pi[1] = "getEnabledApps()";
        pi[2] = "isAppEnabled(string,string)";
        pi[3] = "addApp(string,string,address[],bool)";
        pi[4] = "enableApp(string,string,bool)";
        pi[5] = "getAppFacets(string,string)";
        return pi;
    }

    function supportsInterface(bytes4 interfaceId)
      external view override virtual returns (bool) {
        return interfaceId == type(IDiamondFacet).interfaceId ||
               interfaceId == type(IAppRegistry).interfaceId;
    }

    function getAllApps() external view onlyAppRegistryAdmin returns (string[] memory) {
        return AppRegistryInternal._getAllApps();
    }

    function getEnabledApps() external view onlyAppRegistryAdmin returns (string[] memory) {
        return AppRegistryInternal._getEnabledApps();
    }

    function isAppEnabled(
        string memory name,
        string memory version
    ) external view onlyAppRegistryAdmin returns (bool) {
        return AppRegistryInternal._isAppEnabled(name, version);
    }

    function addApp(
        string memory name,
        string memory version,
        address[] memory facets,
        bool enabled
    ) external onlyAppRegistryAdmin {
        return AppRegistryInternal._addApp(name, version , facets, enabled);
    }

    // NOTE: This is the only mutator for the app entries
    function enableApp(
        string memory name,
        string memory version,
        bool enabled
    ) external onlyAppRegistryAdmin {
        return AppRegistryInternal._enableApp(name, version, enabled);
    }

    function getAppFacets(
        string memory name,
        string memory version
    ) external view override returns (address[] memory) {
        return AppRegistryInternal._getAppFacets(name, version);
    }
}

/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "./RoleManagerInternal.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
library RoleManagerLib {

    function _checkRole(uint256 role) internal view {
        RoleManagerInternal._checkRole(role);
    }

    function _hasRole(uint256 role) internal view returns (bool) {
        return RoleManagerInternal._hasRole(role);
    }

    function _grantRole(
        address account,
        uint256 role
    ) internal {
        RoleManagerInternal._grantRole(account, role);
    }
}

/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "@openzeppelin/contracts/interfaces/IERC165.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
interface IDiamondFacet is IERC165 {

    // NOTE: The override MUST remain 'pure'.
    function getFacetName() external pure returns (string memory);

    // NOTE: The override MUST remain 'pure'.
    function getFacetVersion() external pure returns (string memory);

    // NOTE: The override MUST remain 'pure'.
    function getFacetPI() external pure returns (string[] memory);
}

/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

// import "../task-executor/TaskExecutorLib.sol";
// import "./RoleManagerInternal.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
interface IAppRegistry {

    function getAppFacets(
        string memory appName,
        string memory appVersion
    ) external view returns (address[] memory);
}

/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "./AppRegistryStorage.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
library AppRegistryInternal {

    function _appExists(string memory name, string memory version) internal view returns (bool) {
        bytes32 nvh = __getNameVersionHash(name, version);
        return __getStrLen(__s().apps[nvh].name) > 0 &&
               __getStrLen(__s().apps[nvh].version) > 0;
    }

    function _getAllApps() internal view returns (string[] memory) {
        string[] memory apps = new string[](__s().appsArray.length);
        uint256 index = 0;
        for (uint256 i = 0; i < __s().appsArray.length; i++) {
            (string memory name, string memory version) = __deconAppArrayEntry(i);
            bytes32 nvh = __getNameVersionHash(name, version);
            if (__s().apps[nvh].enabled) {
                apps[index] = string(abi.encode("E:", name, ":", version));
            } else {
                apps[index] = string(abi.encode("D:", name, ":", version));
            }
            index += 1;
        }
        return apps;
    }

    function _getEnabledApps() internal view returns (string[] memory) {
        uint256 count = 0;
        {
            for (uint256 i = 0; i < __s().appsArray.length; i++) {
                (string memory name, string memory version) = __deconAppArrayEntry(i);
                bytes32 nvh = __getNameVersionHash(name, version);
                if (__s().apps[nvh].enabled) {
                    count += 1;
                }
            }
        }
        string[] memory apps = new string[](count);
        {
            uint256 index = 0;
            for (uint256 i = 0; i < __s().appsArray.length; i++) {
                (string memory name, string memory version) = __deconAppArrayEntry(i);
                bytes32 nvh = __getNameVersionHash(name, version);
                if (__s().apps[nvh].enabled) {
                    apps[index] = string(abi.encode(name, ":", version));
                    index += 1;
                }
            }
        }
        return apps;
    }

    function _isAppEnabled(
        string memory name,
        string memory version
    ) internal view returns (bool) {
        require(_appExists(name, version), "AREG:ANF");
        bytes32 nvh = __getNameVersionHash(name, version);
        return (__s().apps[nvh].enabled);
    }

    function _addApp(
        string memory name,
        string memory version,
        address[] memory facets,
        bool enabled
    ) internal {
        require(facets.length > 0, "AREG:ZLEN");
        require(!_appExists(name, version), "AREG:AEX");

        __validateString(name);
        __validateString(version);

        // update apps entry
        bytes32 nvh = __getNameVersionHash(name, version);
        __s().apps[nvh].name = name;
        __s().apps[nvh].version = version;
        __s().apps[nvh].enabled = enabled;
        for (uint256 i = 0; i < facets.length; i++) {
            address facet = facets[i];
            __s().apps[nvh].facets.push(facet);
        }

        // update apps array
        bytes memory toAdd = abi.encode([name], [version]);
        __s().appsArray.push(toAdd);
    }

    // NOTE: This is the only mutator for the app entries
    function _enableApp(string memory name, string memory version, bool enabled) internal {
        require(_appExists(name, version), "AREG:ANF");
        bytes32 nvh = __getNameVersionHash(name, version);
        __s().apps[nvh].enabled = enabled;
    }

    function _getAppFacets(
        string memory appName,
        string memory appVersion
    ) internal view returns (address[] memory) {
        require(_appExists(appName, appVersion), "AREG:ANF");
        bytes32 nvh = __getNameVersionHash(appName, appVersion);
        return __s().apps[nvh].facets;
    }

    function __validateString(string memory str) private pure {
        bytes memory strBytes = bytes(str);
        for (uint256 i = 0; i < strBytes.length; i++) {
            bytes1 b = strBytes[i];
            if (
                !(b >= 0x30 && b <= 0x39) && // [0-9]
                !(b >= 0x41 && b <= 0x5a) && // [A-Z]
                !(b >= 0x61 && b <= 0x7a) && // [a-z]
                 b != 0x21 && // !
                 b != 0x23 && // #
                 b != 0x24 && // $
                 b != 0x25 && // %
                 b != 0x26 && // &
                 b != 0x28 && // (
                 b != 0x29 && // )
                 b != 0x2a && // *
                 b != 0x2b && // +
                 b != 0x2c && // ,
                 b != 0x2d && // -
                 b != 0x2e && // .
                 b != 0x3a && // =
                 b != 0x3d && // =
                 b != 0x3f && // ?
                 b != 0x3b && // ;
                 b != 0x40 && // @
                 b != 0x5e && // ^
                 b != 0x5f && // _
                 b != 0x5b && // [
                 b != 0x5d && // ]
                 b != 0x7b && // {
                 b != 0x7d && // }
                 b != 0x7e    // ~
            ) {
                revert("AREG:ISTR");
            }
        }
    }

    function __getStrLen(string memory str) private pure returns (uint256) {
        return bytes(str).length;
    }

    function __deconAppArrayEntry(uint256 index) private view returns (string memory, string memory) {
        (string[] memory names, string[] memory versions) =
            abi.decode(__s().appsArray[index], (string[], string[]));
        string memory name = names[0];
        string memory version = versions[0];
        return (name, version);
    }

    function __getNameVersionHash(string memory name, string memory version) private pure returns (bytes32) {
        return bytes32(keccak256(abi.encode(name, ":", version)));
    }

    function __s() private pure returns (AppRegistryStorage.Layout storage) {
        return AppRegistryStorage.layout();
    }
}

/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
library AppRegistryConfig {

    uint256 constant public ROLE_APP_REGISTRY_ADMIN = uint256(keccak256(bytes("ROLE_REGISTRY_APP_ADMIN")));
}

/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "./RoleManagerStorage.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
library RoleManagerInternal {

    event RoleGrant(uint256 role, address account);
    event RoleRevoke(uint256 role, address account);

    function _checkRole(uint256 role) internal view {
        require(__s().roles[role][msg.sender], "RM:MR");
    }

    function _hasRole(uint256 role) internal view returns (bool) {
        return __s().roles[role][msg.sender];
    }

    function _hasRole2(
        address account,
        uint256 role
    ) internal view returns (bool) {
        return __s().roles[role][account];
    }

    function _grantRole(
        address account,
        uint256 role
    ) internal {
        require(!__s().roles[role][account], "RM:AHR");
        __s().roles[role][account] = true;
        emit RoleGrant(role, account);
    }

    function _revokeRole(
        address account,
        uint256 role
    ) internal {
        require(__s().roles[role][account], "RM:DNHR");
        __s().roles[role][account] = false;
        emit RoleRevoke(role, account);
    }

    function __s() private pure returns (RoleManagerStorage.Layout storage) {
        return RoleManagerStorage.layout();
    }
}

/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk. Just got the basic
///         idea from: https://github.com/solidstate-network/solidstate-solidity
library RoleManagerStorage {

    struct Layout {
        mapping (uint256 => mapping(address => bool)) roles;
        mapping(uint256 => uint256) extra;
    }

    // Storage Slot: d6cfccebecf684bbc10a5019ad1aed91fbc4f7461f5cd03e8c71240be4ca6bea
    bytes32 internal constant STORAGE_SLOT =
        keccak256("arteq-tech.contracts.security.role-manager.storage");

    function layout() internal pure returns (Layout storage s) {
        bytes32 slot = STORAGE_SLOT;
        /* solhint-disable no-inline-assembly */
        assembly {
            s.slot := slot
        }
        /* solhint-enable no-inline-assembly */
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk. Just got the basic
///         idea from: https://github.com/solidstate-network/solidstate-solidity
library AppRegistryStorage {

    struct AppEntry {
        string name;
        string version;
        bool enabled;
        address[] facets;
    }

    struct Layout {
        bytes[] appsArray;
        mapping(bytes32 => AppEntry) apps;
        mapping(uint256 => uint256) extra;
    }

    // Storage Slot: 67a6ead130f0dfb923ec9a2a7be97c6bf664f01dabfb954c97d300adcbd7528d
    bytes32 internal constant STORAGE_SLOT =
        keccak256("arteq-tech.contracts.app-registry.storage");

    function layout() internal pure returns (Layout storage s) {
        bytes32 slot = STORAGE_SLOT;
        /* solhint-disable no-inline-assembly */
        assembly {
            s.slot := slot
        }
        /* solhint-enable no-inline-assembly */
    }
}