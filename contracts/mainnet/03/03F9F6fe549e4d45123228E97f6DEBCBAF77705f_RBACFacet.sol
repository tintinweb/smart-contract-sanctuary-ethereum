/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
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

import "../../diamond/IDiamondFacet.sol";
import "./RBACInternal.sol";

contract RBACFacet is IDiamondFacet {

    function getFacetName()
      external pure override returns (string memory) {
        return "rbac";
    }

    // CAUTION: Don't forget to update the version when adding new functionality
    function getFacetVersion()
      external pure override returns (string memory) {
        return "1.0.0";
    }

    function getFacetPI()
      external pure override returns (string[] memory) {
        string[] memory pi = new string[](3);
        pi[ 0] = "hasRole(address,uint256)";
        pi[ 1] = "grantRole(uint256,string,address,uint256)";
        pi[ 2] = "revokeRole(uint256,string,address,uint256)";
        return pi;
    }

    function getFacetProtectedPI()
      external pure override returns (string[] memory) {
        string[] memory pi = new string[](2);
        pi[ 0] = "grantRole(uint256,string,address,uint256)";
        pi[ 1] = "revokeRole(uint256,string,address,uint256)";
        return pi;
    }

    function supportsInterface(bytes4 interfaceId)
      external pure override returns (bool) {
        return interfaceId == type(IDiamondFacet).interfaceId;
    }

    function hasRole(
        address account,
        uint256 role
    ) external view returns (bool) {
        return RBACInternal._hasRole(account, role);
    }

    function grantRole(
        uint256 taskId,
        string memory taskManagerKey,
        address account,
        uint256 role
    ) external {
        RBACInternal._grantRole(taskId, taskManagerKey, account, role);
    }

    function revokeRole(
        uint256 taskId,
        string memory taskManagerKey,
        address account,
        uint256 role
    ) external {
        RBACInternal._revokeRole(taskId, taskManagerKey, account, role);
    }
}

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
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

    // NOTE: The override MUST remain 'pure'.
    function getFacetProtectedPI() external pure returns (string[] memory);
}

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
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

import "../task-executor/TaskExecutorLib.sol";
import "./RBACStorage.sol";

library RBACInternal {

    event RoleGrant(uint256 role, address account);
    event RoleRevoke(uint256 role, address account);

    function _hasRole(
        address account,
        uint256 role
    ) internal view returns (bool) {
        return __s().roles[role][account];
    }

    // ATTENTION! this function MUST NEVER get exposed via a facet
    function _unsafeGrantRole(
        address account,
        uint256 role
    ) internal {
        require(!__s().roles[role][account], "RBACI:AHR");
        __s().roles[role][account] = true;
        emit RoleGrant(role, account);
    }

    function _grantRole(
        uint256 taskId,
        string memory taskManagerKey,
        address account,
        uint256 role
    ) internal {
        _unsafeGrantRole(account, role);
        TaskExecutorLib._executeTask(taskManagerKey, taskId);
    }

    function _revokeRole(
        uint256 taskId,
        string memory taskManagerKey,
        address account,
        uint256 role
    ) internal {
        require(__s().roles[role][account], "RBACI:DHR");
        __s().roles[role][account] = false;
        emit RoleRevoke(role, account);
        TaskExecutorLib._executeTask(taskManagerKey, taskId);
    }

    function __s() private pure returns (RBACStorage.Layout storage) {
        return RBACStorage.layout();
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
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
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

import "./TaskExecutorInternal.sol";

library TaskExecutorLib {

    function _initialize(
        address newTaskManager
    ) internal {
        TaskExecutorInternal._initialize(newTaskManager);
    }

    function _getTaskManager(
        string memory taskManagerKey
    ) internal view returns (address) {
        return TaskExecutorInternal._getTaskManager(taskManagerKey);
    }

    function _executeTask(
        string memory key,
        uint256 taskId
    ) internal {
        TaskExecutorInternal._executeTask(key, taskId);
    }

    function _executeAdminTask(
        string memory key,
        uint256 adminTaskId
    ) internal {
        TaskExecutorInternal._executeAdminTask(key, adminTaskId);
    }
}

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
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
library RBACStorage {

    struct Layout {
        // role > address > true if granted
        mapping (uint256 => mapping(address => bool)) roles;
        mapping(bytes32 => bytes) extra;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("qomet-tech.contracts.facets.rbac.storage");

    function layout() internal pure returns (Layout storage s) {
        bytes32 slot = STORAGE_SLOT;
        /* solhint-disable no-inline-assembly */
        assembly {
            s.slot := slot
        }
        /* solhint-enable no-inline-assembly */
    }
}

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
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
import "../hasher/HasherLib.sol";
import "./ITaskExecutor.sol";
import "./TaskExecutorStorage.sol";

library TaskExecutorInternal {

    event TaskManagerSet (
        string key,
        address taskManager
    );

    function _initialize(
        address newTaskManager
    ) internal {
        require(!__s().initialized, "TFI:AI");
        __setTaskManager("DEFAULT", newTaskManager);
        __s().initialized = true;
    }

    function _getTaskManagerKeys() internal view returns (string[] memory) {
        return __s().keys;
    }

    function _getTaskManager(string memory key) internal view returns (address) {
        bytes32 keyHash = HasherLib._hashStr(key);
        require(__s().keysIndex[keyHash] > 0, "TFI:KNF");
        return __s().taskManagers[keyHash];
    }

    function _setTaskManager(
        uint256 adminTaskId,
        string memory key,
        address newTaskManager
    ) internal {
        require(__s().initialized, "TFI:NI");
        bytes32 keyHash = HasherLib._hashStr(key);
        address oldTaskManager = __s().taskManagers[keyHash];
        __setTaskManager(key, newTaskManager);
        if (oldTaskManager != address(0)) {
            ITaskExecutor(oldTaskManager).executeAdminTask(msg.sender, adminTaskId);
        } else {
            address defaultTaskManager = _getTaskManager("DEFAULT");
            require(defaultTaskManager != address(0), "TFI:ZDTM");
            ITaskExecutor(defaultTaskManager).executeAdminTask(msg.sender, adminTaskId);
        }
    }

    function _executeTask(
        string memory key,
        uint256 taskId
    ) internal {
        require(__s().initialized, "TFI:NI");
        address taskManager = _getTaskManager(key);
        require(taskManager != address(0), "TFI:ZTM");
        ITaskExecutor(taskManager).executeTask(msg.sender, taskId);
    }

    function _executeAdminTask(
        string memory key,
        uint256 adminTaskId
    ) internal {
        require(__s().initialized, "TFI:NI");
        address taskManager = _getTaskManager(key);
        require(taskManager != address(0), "TFI:ZTM");
        ITaskExecutor(taskManager).executeAdminTask(msg.sender, adminTaskId);
    }

    function __setTaskManager(
        string memory key,
        address newTaskManager
    ) internal {
        require(newTaskManager != address(0), "TFI:ZA");
        require(IERC165(newTaskManager).supportsInterface(type(ITaskExecutor).interfaceId),
            "TFI:IC");
        bytes32 keyHash = HasherLib._hashStr(key);
        if (__s().keysIndex[keyHash] == 0) {
            __s().keys.push(key);
            __s().keysIndex[keyHash] = __s().keys.length;
        }
        __s().taskManagers[keyHash] = newTaskManager;
        emit TaskManagerSet(key, newTaskManager);
    }

    function __s() private pure returns (TaskExecutorStorage.Layout storage) {
        return TaskExecutorStorage.layout();
    }
}

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
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

library HasherLib {

    function _hashAddress(address addr) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(addr));
    }

    function _hashStr(string memory str) internal pure returns (bytes32) {
        return keccak256(bytes(str));
    }

    function _hashInt(uint256 num) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("INT", num));
    }

    function _hashAccount(address account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("ACCOUNT", account));
    }

    function _hashVault(address vault) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("VAULT", vault));
    }

    function _hashReserveId(uint256 reserveId) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("RESERVEID", reserveId));
    }

    function _hashContract(address contractAddr) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("CONTRACT", contractAddr));
    }

    function _hashTokenId(uint256 tokenId) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("TOKENID", tokenId));
    }

    function _hashRole(string memory roleName) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("ROLE", roleName));
    }

    function _hashLedgerId(uint256 ledgerId) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("LEDGERID", ledgerId));
    }

    function _mixHash2(
        bytes32 d1,
        bytes32 d2
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("MIX2_", d1, d2));
    }

    function _mixHash3(
        bytes32 d1,
        bytes32 d2,
        bytes32 d3
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("MIX3_", d1, d2, d3));
    }

    function _mixHash4(
        bytes32 d1,
        bytes32 d2,
        bytes32 d3,
        bytes32 d4
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("MIX4_", d1, d2, d3, d4));
    }
}

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
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
interface ITaskExecutor {

    event TaskExecuted(address finalizer, address executor, uint256 taskId);

    function executeTask(address executor, uint256 taskId) external;

    function executeAdminTask(address executor, uint256 taskId) external;
}

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
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
library TaskExecutorStorage {

    struct Layout {
        // list of the keys
        string[] keys;
        mapping(bytes32 => uint256) keysIndex;
        // keccak256(key) > task manager address
        mapping(bytes32 => address) taskManagers;
        // true if default task manager has been set
        bool initialized;
        mapping(bytes32 => bytes) extra;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("qomet-tech.contracts.facets.task-finalizer.storage");

    function layout() internal pure returns (Layout storage s) {
        bytes32 slot = STORAGE_SLOT;
        /* solhint-disable no-inline-assembly */
        assembly {
            s.slot := slot
        }
        /* solhint-enable no-inline-assembly */
    }
}