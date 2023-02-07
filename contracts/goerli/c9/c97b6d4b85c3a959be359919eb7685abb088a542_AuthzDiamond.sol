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

import "../security/task-executor/TaskExecutorBase.sol";
import "../security/task-executor/TaskExecutorLib.sol";
import "../security/role-manager/RoleManagerBase.sol";
import "../security/role-manager/RoleManagerLib.sol";
import "../diamond/IDiamond.sol";
import "../diamond/IDiamondFacet.sol";
import "./IAuthz.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
contract AuthzDiamond is
  IDiamond,
  TaskExecutorBase,
  RoleManagerBase
{
    event FacetAdd(address facet);
    event FacetDelete(address facet);
    event FreezeDiamond();
    event FuncSigOverride(string funcSig, address facet);

    string private _name;
    string private _detailsURI;
    bool private _diamondFrozen;
    address[] internal _facets;
    mapping(address => uint256) private _facetArrayIndex;
    mapping(address => bool) private _deletedFacets;
    mapping(bytes4 => address) private _selectorToFacetMap;

    string[] private _overridenFuncSigs;
    mapping(string => uint256) private _overridenFuncSigsIndex;

    modifier notFrozenDiamond {
        require(!_diamondFrozen, "DMND:DFRZN");
        _;
    }

    modifier onlyAuthzDiamondAdmin() {
        RoleManagerLib._checkRole(AuthzLib.ROLE_AUTHZ_DIAMOND_ADMIN);
        _;
    }

    constructor(
        string memory name,
        address taskManager,
        address[] memory authzAdmins,
        address[] memory authzDiamondAdmins
    ) {
        _name = name;
        _diamondFrozen = false;
        TaskExecutorLib._setTaskManager(taskManager);
        for(uint i = 0; i < authzDiamondAdmins.length; i++) {
            RoleManagerLib._grantRole(
                authzDiamondAdmins[i],
                AuthzLib.ROLE_AUTHZ_DIAMOND_ADMIN);
        }
        for(uint i = 0; i < authzAdmins.length; i++) {
            RoleManagerLib._grantRole(authzAdmins[i], AuthzLib.ROLE_AUTHZ_ADMIN);
        }
    }

    function supportsInterface(bytes4 interfaceId)
      public view override virtual returns (bool) {
        // Querying for IDiamondFacet must always return false
        if (interfaceId == type(IDiamondFacet).interfaceId) {
            return false;
        }
        // Always return true
        if (interfaceId == type(IERC165).interfaceId) {
            return true;
        }
        for (uint256 i = 0; i < _facets.length; i++) {
            address facet = _facets[i];
            if (!_deletedFacets[facet] &&
                IDiamondFacet(facet).supportsInterface(interfaceId)) {
                return true;
            }
        }
        return false;
    }

    function getDiamondName() external view virtual override returns (string memory) {
        return _name;
    }

    function getDiamondVersion() external view virtual override returns (string memory) {
        return "1.0.0";
    }

    function setDiamondName(string memory name) external onlyAuthzDiamondAdmin {
        _name = name;
    }

    function getDetailsURI() external view returns (string memory) {
        return _detailsURI;
    }

    function setDetailsURI(string memory detailsURI) external onlyAuthzDiamondAdmin {
        _detailsURI = detailsURI;
    }

    function isDiamondFrozen() external view returns (bool) {
        return _diamondFrozen;
    }

    function freezeDiamond() external notFrozenDiamond onlyAuthzDiamondAdmin {
        _diamondFrozen = true;
        emit FreezeDiamond();
    }

    function getFacets() external view override returns (address[] memory) {
        return __getFacets();
    }

    function resolve(string[] memory funcSigs) external view returns (address[] memory) {
        return __resolve(funcSigs);
    }

    function addFacets(
        address[] memory facets
    ) external notFrozenDiamond onlyAuthzDiamondAdmin {
        require(facets.length > 0, "ADMND:ZL");
        for (uint256 i = 0; i < facets.length; i++) {
            __addFacet(facets[i]);
        }
    }

    function deleteFacets(
        address[] memory facets
    ) external notFrozenDiamond onlyAuthzDiamondAdmin {
        require(facets.length > 0, "ADMND:ZL");
        for (uint256 i = 0; i < facets.length; i++) {
            __deleteFacet(facets[i]);
        }
    }

    function deleteAllFacets() external notFrozenDiamond onlyAuthzDiamondAdmin {
        for (uint256 i = 0; i < _facets.length; i++) {
            __deleteFacet(_facets[i]);
        }
    }

    // WARN: Never use this function directly. The proper way is to add a facet
    //       as a whole.
    function overrideFuncSigs(
        string[] memory funcSigs,
        address[] memory facets
    ) external notFrozenDiamond onlyAuthzDiamondAdmin {
        __overrideFuncSigs(funcSigs, facets);
    }

    function getOverridenFuncSigs() external view returns (string[] memory) {
        return _overridenFuncSigs;
    }

    function _findFacet(bytes4 selector) internal view returns (address) {
        address facet = _selectorToFacetMap[selector];
        require(facet != address(0), "ADMND:FNF");
        require(!_deletedFacets[facet], "ADMND:FREM");
        return facet;
    }

    function __getFacets() private view returns (address[] memory) {
        uint256 count = 0;
        {
            for (uint256 i = 0; i < _facets.length; i++) {
                if (!_deletedFacets[_facets[i]]) {
                    count += 1;
                }
            }
        }
        address[] memory facets = new address[](count);
        {
            uint256 index = 0;
            for (uint256 i = 0; i < _facets.length; i++) {
                if (!_deletedFacets[_facets[i]]) {
                    facets[index] = _facets[i];
                    index += 1;
                }
            }
        }
        return facets;
    }

    function __resolve(string[] memory funcSigs) private view returns (address[] memory) {
        address[] memory facets = new address[](funcSigs.length);
        for (uint256 i = 0; i < funcSigs.length; i++) {
            string memory funcSig = funcSigs[i];
            bytes4 selector = __getSelector(funcSig);
            facets[i] = _selectorToFacetMap[selector];
            if (_deletedFacets[facets[i]]) {
                facets[i] = address(0);
            }
        }
        return facets;
    }

    function __addFacet(address facet) private {
        require(facet != address(0), "ADMND:ZF");
        require(
            IDiamondFacet(facet).supportsInterface(type(IDiamondFacet).interfaceId),
            "ADMND:IF"
        );
        string[] memory funcSigs = IDiamondFacet(facet).getFacetPI();
        for (uint256 i = 0; i < funcSigs.length; i++) {
            string memory funcSig = funcSigs[i];
            bytes4 selector = __getSelector(funcSig);
            _selectorToFacetMap[selector] = facet;
        }
        _deletedFacets[facet] = false;
        // update facets array
        if (_facetArrayIndex[facet] == 0) {
            _facets.push(facet);
            _facetArrayIndex[facet] = _facets.length;
        }
        emit FacetAdd(facet);
    }

    function __deleteFacet(address facet) private {
        require(facet != address(0), "ADMND:ZF");
        _deletedFacets[facet] = true;
        emit FacetDelete(facet);
    }

    function __overrideFuncSigs(
        string[] memory funcSigs,
        address[] memory facets
    ) private {
        require(funcSigs.length > 0, "ADMND:ZL");
        require(funcSigs.length == facets.length, "ADMND:IL");
        for (uint i = 0; i < funcSigs.length; i++) {
            string memory funcSig = funcSigs[i];
            address facet = facets[i];
            bytes4 selector = __getSelector(funcSig);
            _selectorToFacetMap[selector] = facet;
            _deletedFacets[facet] = false;
            if (_overridenFuncSigsIndex[funcSig] == 0) {
                _overridenFuncSigs.push(funcSig);
                _overridenFuncSigsIndex[funcSig] = _overridenFuncSigs.length;
            }
            emit FuncSigOverride(funcSig, facet);
        }
    }

    function __getSelector(string memory funcSig) private pure returns (bytes4) {
        bytes memory funcSigBytes = bytes(funcSig);
        for (uint256 i = 0; i < funcSigBytes.length; i++) {
            bytes1 b = funcSigBytes[i];
            if (
                !(b >= 0x30 && b <= 0x39) && // [0-9]
                !(b >= 0x41 && b <= 0x5a) && // [A-Z]
                !(b >= 0x61 && b <= 0x7a) && // [a-z]
                 b != 0x24 && // $
                 b != 0x5f && // _
                 b != 0x2c && // ,
                 b != 0x28 && // (
                 b != 0x29 && // )
                 b != 0x5b && // [
                 b != 0x5d    // ]
            ) {
                revert("ADMND:IFS");
            }
        }
        return bytes4(keccak256(bytes(funcSig)));
    }

    /* solhint-disable no-complex-fallback */
    fallback() external payable {
        address facet = _findFacet(msg.sig);
        /* solhint-disable no-inline-assembly */
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
                case 0 {
                    revert(0, returndatasize())
                }
                default {
                    return(0, returndatasize())
                }
        }
        /* solhint-enable no-inline-assembly */
    }

    /* solhint-disable no-empty-blocks */
    receive() external payable {}
    /* solhint-enable no-empty-blocks */
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

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
contract TaskExecutorBase {

    function getTaskManager() external view returns (address) {
        return TaskExecutorInternal._getTaskManager();
    }

    function setTaskManager(
        uint256 adminTaskId,
        address newTaskManager
    ) external {
        address oldTaskManager = TaskExecutorInternal._getTaskManager();
        TaskExecutorInternal._setTaskManager(newTaskManager);
        if (oldTaskManager != address(0)) {
            ITaskExecutor(oldTaskManager).executeAdminTask(msg.sender, adminTaskId);
        }
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

import "./TaskExecutorInternal.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
library TaskExecutorLib {

    function _setTaskManager(address newTaskManager) internal {
        TaskExecutorInternal._setTaskManager(newTaskManager);
    }

    function _executeTask(uint256 taskId) internal {
        TaskExecutorInternal._executeTask(taskId);
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

import "../task-executor/TaskExecutorLib.sol";
import "./RoleManagerInternal.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
abstract contract RoleManagerBase {

    function hasRole(
        address account,
        uint256 role
    ) external view returns (bool) {
        return RoleManagerInternal._hasRole2(account, role);
    }

    function grantRole(
        uint256 taskId,
        address account,
        uint256 role
    ) external {
        RoleManagerInternal._grantRole(account, role);
        TaskExecutorLib._executeTask(taskId);
    }

    function revokeRole(
        uint256 taskId,
        address account,
        uint256 role
    ) external {
        RoleManagerInternal._revokeRole(account, role);
        TaskExecutorLib._executeTask(taskId);
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

library DiamondLib {
    uint256 public constant ROLE_DIAMOND_ADMIN = uint256(keccak256(bytes("ROLE_DIAMOND_ADMIN")));
}

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
interface IDiamond is IERC165 {

    function getDiamondName() external view returns (string memory);

    function getDiamondVersion() external view returns (string memory);

    function getFacets() external view returns (address[] memory);
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

library AuthzLib {

    uint256 public constant ROLE_AUTHZ_DIAMOND_ADMIN = uint256(keccak256(bytes("ROLE_AUTHZ_DIAMOND_ADMIN")));
    uint256 public constant ROLE_AUTHZ_ADMIN = uint256(keccak256(bytes("ROLE_AUTHZ_ADMIN")));

    bytes32 constant public GLOBAL_DOMAIN_HASH = keccak256(abi.encodePacked("global"));
    bytes32 constant public MATCH_ALL_WILDCARD_HASH = keccak256(abi.encodePacked("*"));

    // operations
    uint256 constant public CALL_OP = 5000;
    uint256 constant public MATCH_ALL_WILDCARD_OP = 9999;

    // actions
    uint256 constant public ACCEPT_ACTION = 1;
    uint256 constant public REJECT_ACTION = 100;
}

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
interface IAuthz {

    function authorize(
        bytes32 domainHash,
        bytes32 identityHash,
        bytes32[] memory targets,
        uint256[] memory ops
    ) external view returns (uint256[] memory);
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
import "../../interfaces/ITaskExecutor.sol";
import "./TaskExecutorStorage.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
library TaskExecutorInternal {

    event TaskManagerSet(address newTaskManager);

    function _getTaskManager() internal view returns (address) {
        return __s().taskManager;
    }

    function _setTaskManager(address newTaskManager) internal {
        require(newTaskManager != address(0), "TE:ZA");
        require(IERC165(newTaskManager).supportsInterface(type(ITaskExecutor).interfaceId),
            "TE:IC");
        __s().taskManager = newTaskManager;
        emit TaskManagerSet(__s().taskManager);
    }

    function _executeTask(uint256 taskId) internal {
        require(__s().taskManager != address(0), "TE:NTM");
        ITaskExecutor(__s().taskManager).executeTask(msg.sender, taskId);
    }

    function __s() private pure returns (TaskExecutorStorage.Layout storage) {
        return TaskExecutorStorage.layout();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

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
        address taskManager;
        mapping(bytes32 => bytes) extra;
    }

    // Storage Slot: 54cdf809daf65fac7b2e9ad284be56f754e1ff6de381c3edd22082e07d35e189
    bytes32 internal constant STORAGE_SLOT =
        keccak256("qomet-tech.contracts.security.task-executor.storage");

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
library RoleManagerStorage {

    struct Layout {
        mapping (uint256 => mapping(address => bool)) roles;
        mapping(bytes32 => bytes) extra;
    }

    // Storage Slot: 9b619562bf8defbac41c4a498cbbe285d53fd8b4eb62fb517e0dd4f7762b527a
    bytes32 internal constant STORAGE_SLOT =
        keccak256("qomet-tech.contracts.security.role-manager.storage");

    function layout() internal pure returns (Layout storage s) {
        bytes32 slot = STORAGE_SLOT;
        /* solhint-disable no-inline-assembly */
        assembly {
            s.slot := slot
        }
        /* solhint-enable no-inline-assembly */
    }
}