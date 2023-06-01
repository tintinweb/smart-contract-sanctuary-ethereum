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
import "./IDiamondFactory.sol";
import "./Diamond.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
contract DiamondFactory is IERC165, IDiamondFactory {

    function supportsInterface(
        bytes4 interfaceId
    ) public pure override returns (bool) {
        return interfaceId == type(IDiamondFactory).interfaceId;
    }

    function getDiamondVersion()
    external pure override returns (string memory) {
        return DiamondInfo.VERSION;
    }

    function createDiamond(
        bytes4[] memory defaultSupportingInterfceIds,
        address initializer
    ) external override returns (address) {
        Diamond diamond = new Diamond(
            defaultSupportingInterfceIds,
            initializer
        );
        return address(diamond);
    }

    fallback() external payable {
        revert("DD:FR");
    }

    receive() external payable {
        revert("DF:RR");
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
interface IDiamondFactory {

    function getDiamondVersion()
    external view returns (string memory);

    function createDiamond(
        bytes4[] memory defaultSupportingInterfceIds,
        address initializer
    ) external returns (address);
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

import "../facets/task-executor/TaskExecutorLib.sol";
import "./IAppRegistry.sol";
import "./IAuthz.sol";
import "./IDiamond.sol";
import "./IDiamondInitializer.sol";
import "./IDiamondFacet.sol";
import "./FacetManager.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
library DiamondInfo {
    string public constant VERSION = "3.1.0";
}

contract Diamond is IDiamond, IDiamondInitializer {

    string private _name;
    string private _detailsURI;

    event FreezeAuthz();
    event AppInstall(address appRegistry, string name, string version);
    event AppRegistrySet(address appRegistry);

    struct Authz {
        bool frozen;
        address source;
        string domain;
        uint256[] acceptedResults;
        string hashSalt;
    }
    Authz private _authz;

    bytes4[] private _defaultSupportingInterfceIds;

    address private _appRegistry;

    address private _initializer;
    bool private _initialized;

    modifier mustBeInitialized {
        require(_initialized, "DMND:NI");
        _;
    }

    modifier notFrozenAuthz {
        require(!_authz.frozen, "DMND:AFRZN");
        _;
    }

    modifier mutatorAuthz {
        _authorizeCall(msg.sender, address(this), msg.sig, true);
        _;
    }

    modifier getterAuthz {
        _authorizeCall(msg.sender, address(this), msg.sig, false);
        _;
    }

    constructor(
        bytes4[] memory defaultSupportingInterfceIds,
        address initializer
    ) {
        _initialized = false;
        _authz.hashSalt = "Dwt2wb1d976h";
        _authz.acceptedResults.push(AuthzLib.ACCEPT_ACTION);
        _defaultSupportingInterfceIds = defaultSupportingInterfceIds;
        _initializer = initializer;
    }

    function initialize(
        string memory name,
        address taskManager,
        address appRegistry,
        address authzSource,
        string memory authzDomain,
        string[][2] memory defaultApps, // [0] > names, [1] > versions
        address[] memory defaultFacets,
        string[][2] memory defaultFuncSigsToProtectOrUnprotect, // [0] > protect, [1] > unprotect
        address[] memory defaultFacetsToFreeze,
        bool[3] memory instantLockAndFreezes // [0] > lock, [1] > freeze-authz, [2] > freeze-diamond
    ) external override {
        require(!_initialized, "DMND:AI");
        require(msg.sender == _initializer, "DMND:WI");
        _name = name;
        TaskExecutorLib._initialize(taskManager);
        __setAppRegistry(appRegistry);
        __setAuthzSource(authzSource);
        _authz.domain = authzDomain;
        require(defaultApps[0].length == defaultApps[1].length, "DMND:WL");
        for (uint256 i = 0; i < defaultApps[0].length; i++) {
            __installApp(
                defaultApps[0][i], // name
                defaultApps[1][i], // version
                false // don't delete current facets
            );
        }
        // install default facets
        for (uint256 i = 0; i < defaultFacets.length; i++) {
            FacetManagerLib._addFacet(defaultFacets[i]);
        }
        // protect default functions
        for (uint256 i = 0; i < defaultFuncSigsToProtectOrUnprotect[0].length; i++) {
            FacetManagerLib._protectFuncSig(
                defaultFuncSigsToProtectOrUnprotect[0][i],
                true // protect
            );
        }
        // unprotect default functions
        for (uint256 i = 0; i < defaultFuncSigsToProtectOrUnprotect[1].length; i++) {
            FacetManagerLib._protectFuncSig(
                defaultFuncSigsToProtectOrUnprotect[1][i],
                false // unprotect
            );
        }
        // lock the diamond if asked for
        if (instantLockAndFreezes[0]) {
            FacetManagerLib._setLocked(true);
        }
        // freeze facets
        for (uint256 i = 0; i < defaultFacetsToFreeze.length; i++) {
            FacetManagerLib._freezeFacet(defaultFacetsToFreeze[i]);
        }
        // freeze the authz settings if asked for
        if (instantLockAndFreezes[1]) {
            _authz.frozen = true;
        }
        // freeze the diamond if asked for
        if (instantLockAndFreezes[2]) {
            FacetManagerLib._freezeDiamond();
        }
        _initialized = true;
    }


    function supportsInterface(bytes4 interfaceId)
      public view override getterAuthz virtual returns (bool) {
        // Querying for IDiamond must always return true
        if (
            interfaceId == 0xd4bbd4bb ||
            interfaceId == type(IDiamond).interfaceId
        ) {
            return true;
        }
        // Querying for IDiamondFacet must always return false
        if (interfaceId == type(IDiamondFacet).interfaceId) {
            return false;
        }
        // Always return true
        if (interfaceId == type(IERC165).interfaceId) {
            return true;
        }
        address[] memory facets = FacetManagerLib._getFacets();
        for (uint256 i = 0; i < facets.length; i++) {
            address facet = facets[i];
            if (!FacetManagerLib._isFacetDeleted(facet) &&
                IDiamondFacet(facet).supportsInterface(interfaceId)) {
                return true;
            }
        }
        for (uint256 i = 0; i < _defaultSupportingInterfceIds.length; i++) {
            if (interfaceId == _defaultSupportingInterfceIds[i]) {
                return true;
            }
        }
        return false;
    }

    function isInitialized() external view returns (bool) {
        return _initialized;
    }

    function getDiamondName()
    external view virtual override mustBeInitialized getterAuthz returns (string memory) {
        return _name;
    }

    function getDiamondVersion()
    external view virtual override mustBeInitialized getterAuthz  returns (string memory) {
        return DiamondInfo.VERSION;
    }

    function setDiamondName(string memory name) external mustBeInitialized mutatorAuthz {
        _name = name;
    }

    function getDetailsURI()
    external view mustBeInitialized getterAuthz returns (string memory) {
        return _detailsURI;
    }

    function setDetailsURI(string memory detailsURI) external mustBeInitialized mutatorAuthz {
        _detailsURI = detailsURI;
    }

    function getTaskManager() external view mustBeInitialized getterAuthz returns (address) {
        return TaskExecutorLib._getTaskManager("DEFAULT");
    }

    function getAuthzSource() external view mustBeInitialized getterAuthz returns (address) {
        return _authz.source;
    }

    function setAuthzSource(
        address authzSource
    ) external mustBeInitialized notFrozenAuthz mutatorAuthz {
        __setAuthzSource(authzSource);
    }

    function getAuthzDomain() external view mustBeInitialized getterAuthz returns (string memory) {
        return _authz.domain;
    }

    function setAuthzDomain(
        string memory authzDomain
    ) external mustBeInitialized notFrozenAuthz mutatorAuthz {
        require(bytes(authzDomain).length > 0, "DMND:ED");
        _authz.domain = authzDomain;
    }

    function getAcceptedAuthzResults()
    external view mustBeInitialized getterAuthz returns (uint256[] memory) {
        return _authz.acceptedResults;
    }

    function setAcceptedAuthzResults(
        uint256[] memory acceptedAuthzResults
    ) external mustBeInitialized notFrozenAuthz mutatorAuthz {
        require(acceptedAuthzResults.length > 0, "DMND:EA");
        _authz.acceptedResults = acceptedAuthzResults;
    }

    function getAppRegistry() external view mustBeInitialized getterAuthz returns (address) {
        return _appRegistry;
    }

    function setAppRegistry(address appRegistry) external mustBeInitialized mutatorAuthz {
        __setAppRegistry(appRegistry);
    }

    function isDiamondFrozen() external view mustBeInitialized getterAuthz returns (bool) {
        return FacetManagerLib._isDiamondFrozen();
    }

    function freezeDiamond(
        string memory taskManagerKey,
        uint256 adminTaskId
    ) external mustBeInitialized mutatorAuthz {
        FacetManagerLib._freezeDiamond();
        TaskExecutorLib._executeAdminTask(taskManagerKey, adminTaskId);
    }

    function isFacetFrozen(address facet)
    external view mustBeInitialized getterAuthz returns (bool) {
        return FacetManagerLib._isFacetFrozen(facet);
    }

    function freezeFacet(
        string memory taskManagerKey,
        uint256 adminTaskId,
        address facet
    ) external mustBeInitialized mutatorAuthz {
        FacetManagerLib._freezeFacet(facet);
        TaskExecutorLib._executeAdminTask(taskManagerKey, adminTaskId);
    }

    function isAuthzFrozen() external view mustBeInitialized getterAuthz returns (bool) {
        return _authz.frozen;
    }

    function freezeAuthz(
        string memory taskManagerKey,
        uint256 adminTaskId
    ) external mustBeInitialized notFrozenAuthz mutatorAuthz {
        _authz.frozen = true;
        emit FreezeAuthz();
        TaskExecutorLib._executeAdminTask(taskManagerKey, adminTaskId);
    }

    function isDiamondLocked() external view mustBeInitialized getterAuthz returns (bool) {
        return FacetManagerLib._isDiamondLocked();
    }

    function setLocked(
        string memory taskManagerKey,
        uint256 taskId,
        bool locked
    ) external mustBeInitialized mutatorAuthz {
        FacetManagerLib._setLocked(locked);
        TaskExecutorLib._executeTask(taskManagerKey, taskId);
    }

    function getFacets()
    external view override mustBeInitialized getterAuthz returns (address[] memory) {
        return FacetManagerLib._getFacets();
    }

    function resolve(string[] memory funcSigs)
    external view mustBeInitialized getterAuthz returns (address[] memory) {
        return FacetManagerLib._resolve(funcSigs);
    }

    function areFuncSigsProtected(
        string[] memory funcSigs
    ) external view mustBeInitialized getterAuthz returns (bool[] memory) {
        return FacetManagerLib._areFuncSigsProtected(funcSigs);
    }

    function protectFuncSig(string memory funcSig, bool protect)
    external mustBeInitialized notFrozenAuthz mutatorAuthz {
        FacetManagerLib._protectFuncSig(funcSig, protect);
    }

    function addFacets(address[] memory facets) external mustBeInitialized mutatorAuthz {
        FacetManagerLib._addFacets(facets);
    }

    function deleteFacets(address[] memory facets) external mustBeInitialized mutatorAuthz {
        FacetManagerLib._deleteFacets(facets);
    }

    function replaceFacets(
        address[] memory toBeDeletedFacets,
        address[] memory toBeAddedFacets
    ) external mustBeInitialized mutatorAuthz {
        FacetManagerLib._replaceFacets(toBeDeletedFacets, toBeAddedFacets);
    }

    function deleteAllFacets() external mustBeInitialized mutatorAuthz {
        FacetManagerLib._deleteAllFacets();
    }

    function installApp(
        string memory appName,
        string memory appVersion,
        bool deleteCurrentFacets
    ) external mustBeInitialized mutatorAuthz {
        __installApp(appName, appVersion, deleteCurrentFacets);
    }

    function overrideFuncSigs(
        string[] memory funcSigs,
        address[] memory facets
    ) external mustBeInitialized mutatorAuthz {
        FacetManagerLib._overrideFuncSigs(funcSigs, facets);
    }

    function getOverridenFuncSigs()
    external view mustBeInitialized getterAuthz returns (string[] memory) {
        return FacetManagerLib._getOverridenFuncSigs();
    }

    function tryAuthorizeCall(
        address caller,
        string memory funcSig
    ) external view mustBeInitialized getterAuthz {
        address facet = FacetManagerLib._findFacet(msg.sig);
        bytes4 funcSelector = FacetManagerLib._getSelector(funcSig);
        _authorizeCall(caller, facet, funcSelector, false);
    }

    function _authorizeCall(
        address caller,
        address facet,
        bytes4 funcSelector,
        bool treatAsProtected
    ) internal view {
        if (!treatAsProtected && !FacetManagerLib._isSelectorProtected(funcSelector)) {
            return;
        }
        require(_authz.source != address(0), "DMND:ZA");
        bytes32 domainHash = keccak256(abi.encodePacked(_authz.hashSalt, _authz.domain));
        bytes32 callerHash = keccak256(abi.encodePacked(_authz.hashSalt, caller));
        bytes32[] memory targets = new bytes32[](3);
        targets[0] = keccak256(abi.encodePacked(_authz.hashSalt, address(this)));
        targets[1] = keccak256(abi.encodePacked(_authz.hashSalt, facet));
        targets[2] = keccak256(abi.encodePacked(_authz.hashSalt, funcSelector));
        uint256[] memory ops = new uint256[](1);
        ops[0] = AuthzLib.CALL_OP;
        uint256[] memory results = IAuthz(_authz.source)
            .authorize(
                domainHash,
                callerHash,
                targets,
                ops
            );
        for (uint256 i = 0; i < _authz.acceptedResults.length; i++) {
            for (uint256 j = 0; j < results.length; j++) {
                if (_authz.acceptedResults[i] == results[j]) {
                    return;
                }
            }
        }
        revert("DMND:NAUTH");
    }

    function __setAuthzSource(address authzSource) private {
        require(authzSource != address(0), "DMND:ZA");
        require(
            IERC165(authzSource).supportsInterface(type(IAuthz).interfaceId),
            "DMND:IAS"
        );
        _authz.source = authzSource;
    }

    function __setAppRegistry(address appRegistry) private {
        if (appRegistry != address(0)) {
            require(
                IERC165(appRegistry).supportsInterface(type(IAppRegistry).interfaceId),
                "DMND:IAR"
            );
        }
        _appRegistry = appRegistry;
        emit AppRegistrySet(_appRegistry);
    }

    function __installApp(
        string memory appName,
        string memory appVersion,
        bool deleteCurrentFacets
    ) private {
        require(_appRegistry != address(0), "DMND:ZAR");
        if (deleteCurrentFacets) {
            FacetManagerLib._deleteAllFacets();
        }
        address[] memory appFacets =
            IAppRegistry(_appRegistry).getAppFacets(appName, appVersion);
        for (uint256 i = 0; i < appFacets.length; i++) {
            FacetManagerLib._addFacet(appFacets[i]);
        }
        if (appFacets.length > 0) {
            emit AppInstall(_appRegistry, appName, appVersion);
        }
    }

    /* solhint-disable no-complex-fallback */
    fallback() external payable {
        require(_initialized, "DMND:NI");
        address facet = FacetManagerLib._findFacet(msg.sig);
        _authorizeCall(msg.sender, facet, msg.sig, false);
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
/// @notice Use at your own risk
interface IAppRegistry {

    function getAppFacets(
        string memory appName,
        string memory appVersion
    ) external view returns (address[] memory);
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

    bytes32 constant public GLOBAL_DOMAIN_ID = keccak256(abi.encodePacked("global"));
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

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
interface IDiamondInitializer {

    function initialize(
        string memory name,
        address taskManager,
        address appRegistry,
        address authzSource,
        string memory authzDomain,
        string[][2] memory defaultApps, // [0] > names, [1] > versions
        address[] memory defaultFacets,
        string[][2] memory defaultFuncSigsToProtectOrUnprotect, // [0] > protect, [1] > unprotect
        address[] memory defaultFacetsToFreeze,
        bool[3] memory instantLockAndFreezes // [0] > lock, [1] > freeze-authz, [2] > freeze-diamond
    ) external;
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

import "./IDiamondFacet.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk. Just got the basic
///         idea from: https://github.com/solidstate-network/solidstate-solidity
library FacetManagerStorage {

    struct Layout {
        // true if diamond is frozen meaning it cannot be changed anymore.
        // ATTENTION! once frozen, one WILL NEVER be able to undo that.
        bool diamondFrozen;
        // true if diamond is locked, meaning it cannot be changed anymore.
        // diamonds can be unlocked.
        bool diamondLocked;
        // list of facet addersses
        address[] facets;
        mapping(address => uint256) facetsIndex;
        // facet address > true if marked as deleted
        mapping(address => bool) deletedFacets;
        // function selector > facet address
        mapping(bytes4 => address) selectorToFacetMap;
        // list of overriden function signatures
        string[] overridenFuncSigs;
        mapping(string => uint256) overridenFuncSigsIndex;
        // facet address > true if frozen
        mapping(address => bool) frozenFacets;
        // function signature > true if protected
        mapping(bytes4 => bool) protectedSelectorMap;
        // Extra fields (reserved for future)
        mapping(bytes32 => bytes) extra;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("qomet-tech.contracts.diamond.facet-manager.storage");

    function layout() internal pure returns (Layout storage s) {
        bytes32 slot = STORAGE_SLOT;
        /* solhint-disable no-inline-assembly */
        assembly {
            s.slot := slot
        }
        /* solhint-enable no-inline-assembly */
    }
}

library FacetManagerLib {

    event FacetAdd(address facet);
    event FacetDelete(address facet);
    event FreezeDiamond();
    event SetLocked(bool locked);
    event FuncSigOverride(string funcSig, address facet);
    event ProtectFuncSig(string funcSig, bool protect);

    function _isDiamondFrozen() internal view returns (bool) {
        return __s().diamondFrozen;
    }

    function _freezeDiamond() internal {
        require(!__s().diamondFrozen, "FMLIB:DFRZN");
        __s().diamondFrozen = true;
        emit FreezeDiamond();
    }

    function _isFacetFrozen(address facet) internal view returns (bool) {
        return __s().frozenFacets[facet];
    }

    function _freezeFacet(address facet) internal {
        require(!__s().diamondFrozen, "FMLIB:DFRZN");
        require(facet != address(0), "FMLIB:ZF");
        require(!__s().frozenFacets[facet], "FMLIB:FAF");
        __s().frozenFacets[facet] = true;
    }

    function _isDiamondLocked() internal view returns (bool) {
        return __s().diamondLocked;
    }

    function _setLocked(bool locked) internal {
        require(!__s().diamondFrozen, "FMLIB:DFRZN");
        __s().diamondLocked = locked;
        emit SetLocked(locked);
    }

    function _getFacets() internal view returns (address[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < __s().facets.length; i++) {
            if (!__s().deletedFacets[__s().facets[i]]) {
                count += 1;
            }
        }
        address[] memory facets = new address[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < __s().facets.length; i++) {
            if (!__s().deletedFacets[__s().facets[i]]) {
                facets[index] = __s().facets[i];
                index += 1;
            }
        }
        return facets;
    }

    function _resolve(string[] memory funcSigs) internal view returns (address[] memory) {
        address[] memory facets = new address[](funcSigs.length);
        for (uint256 i = 0; i < funcSigs.length; i++) {
            string memory funcSig = funcSigs[i];
            bytes4 selector = _getSelector(funcSig);
            facets[i] = __s().selectorToFacetMap[selector];
            if (__s().deletedFacets[facets[i]]) {
                facets[i] = address(0);
            }
        }
        return facets;
    }

    function _areFuncSigsProtected(
        string[] memory funcSigs
    ) internal view returns (bool[] memory) {
        bool[] memory results = new bool[](funcSigs.length);
        for (uint256 i = 0; i < funcSigs.length; i++) {
            string memory funcSig = funcSigs[i];
            bytes4 selector = _getSelector(funcSig);
            results[i] = __s().protectedSelectorMap[selector];
        }
        return results;
    }

    function _protectFuncSig(
        string memory funcSig,
        bool protect
    ) internal {
        require(!__s().diamondLocked, "FMLIB:LCKD");
        __protectFuncSig(funcSig, protect);
    }

    function _isSelectorProtected(bytes4 funcSelector) internal view returns (bool) {
        return __s().protectedSelectorMap[funcSelector];
    }

    function _addFacets(address[] memory facets) internal {
        require(!__s().diamondFrozen, "FMLIB:DFRZN");
        require(!__s().diamondLocked, "FMLIB:LCKD");
        require(facets.length > 0, "FMLIB:ZL");
        for (uint256 i = 0; i < facets.length; i++) {
            _addFacet(facets[i]);
        }
    }

    function _deleteFacets(address[] memory facets) internal {
        require(!__s().diamondFrozen, "FMLIB:DFRZN");
        require(!__s().diamondLocked, "FMLIB:LCKD");
        require(facets.length > 0, "FMLIB:ZL");
        for (uint256 i = 0; i < facets.length; i++) {
            __deleteFacet(facets[i]);
        }
    }

    function _replaceFacets(
        address[] memory toBeDeletedFacets,
        address[] memory toBeAddedFacets
    ) internal {
        _deleteFacets(toBeDeletedFacets);
        _addFacets(toBeAddedFacets);
    }

    function _isFacetDeleted(address facet) internal view returns (bool) {
        return __s().deletedFacets[facet];
    }

    function _deleteAllFacets() internal {
        require(!__s().diamondFrozen, "FMLIB:DFRZN");
        require(!__s().diamondLocked, "FMLIB:LCKD");
        for (uint256 i = 0; i < __s().facets.length; i++) {
            __deleteFacet(__s().facets[i]);
        }
    }

    function _overrideFuncSigs(
        string[] memory funcSigs,
        address[] memory facets
    ) internal {
        require(!__s().diamondFrozen, "FMLIB:DFRZN");
        require(!__s().diamondLocked, "FMLIB:LCKD");
        __overrideFuncSigs(funcSigs, facets);
    }

    function _getOverridenFuncSigs() internal view returns (string[] memory) {
        return __s().overridenFuncSigs;
    }

    function _findFacet(bytes4 selector) internal view returns (address) {
        address facet = __s().selectorToFacetMap[selector];
        require(facet != address(0), "FMLIB:FNF");
        require(!__s().deletedFacets[facet], "FMLIB:FREM");
        return facet;
    }

    function _addFacet(address facet) internal {
        require(!__s().diamondFrozen, "FMLIB:DFRZN");
        require(!__s().diamondLocked, "FMLIB:LCKD");
        require(facet != address(0), "FMLIB:ZF");
        require(
            IDiamondFacet(facet).supportsInterface(type(IDiamondFacet).interfaceId),
            "FMLIB:IF"
        );
        string[] memory funcSigs = IDiamondFacet(facet).getFacetPI();
        for (uint256 i = 0; i < funcSigs.length; i++) {
            string memory funcSig = funcSigs[i];
            bytes4 selector = _getSelector(funcSig);
            address currentFacet = __s().selectorToFacetMap[selector];
            if (currentFacet != address(0)) {
                // current facet must not be frozen
                require(!__s().frozenFacets[currentFacet], "FMLIB:FF");
            }
            __s().selectorToFacetMap[selector] = facet;
            __protectFuncSig(funcSig, false);
        }
        string[] memory protectedFuncSigs = IDiamondFacet(facet).getFacetProtectedPI();
        for (uint256 i = 0; i < protectedFuncSigs.length; i++) {
            string memory protectedFuncSig = protectedFuncSigs[i];
            __protectFuncSig(protectedFuncSig, true);
        }
        __s().deletedFacets[facet] = false;
        // update facets array
        if (__s().facetsIndex[facet] == 0) {
            __s().facets.push(facet);
            __s().facetsIndex[facet] = __s().facets.length;
        }
        emit FacetAdd(facet);
    }

    function _getSelector(string memory funcSig) internal pure returns (bytes4) {
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
                revert("FMLIB:IFS");
            }
        }
        return bytes4(keccak256(bytes(funcSig)));
    }

    function __deleteFacet(address facet) private {
        require(facet != address(0), "FMLIB:ZF");
        require(!__s().frozenFacets[facet], "FMLIB:FF");
        __s().deletedFacets[facet] = true;
        emit FacetDelete(facet);
    }

    function __overrideFuncSigs(
        string[] memory funcSigs,
        address[] memory facets
    ) private {
        require(funcSigs.length > 0, "FMLIB:ZL");
        require(funcSigs.length == facets.length, "FMLIB:IL");
        for (uint i = 0; i < funcSigs.length; i++) {
            string memory funcSig = funcSigs[i];
            address facet = facets[i];
            bytes4 selector = _getSelector(funcSig);
            address currentFacet = __s().selectorToFacetMap[selector];
            if (currentFacet != address(0)) {
                // current facet must not be frozen
                require(!__s().frozenFacets[currentFacet], "FMLIB:FF");
            }
            __s().selectorToFacetMap[selector] = facet;
            __s().deletedFacets[facet] = false;
            if (__s().overridenFuncSigsIndex[funcSig] == 0) {
                __s().overridenFuncSigs.push(funcSig);
                __s().overridenFuncSigsIndex[funcSig] = __s().overridenFuncSigs.length;
            }
            emit FuncSigOverride(funcSig, facet);
        }
    }

    function __protectFuncSig(string memory funcSig, bool protect) private {
        bytes4 selector = _getSelector(funcSig);
        bool oldValue = __s().protectedSelectorMap[selector];
        __s().protectedSelectorMap[selector] = protect;
        if (oldValue != protect) {
            emit ProtectFuncSig(funcSig, protect);
        }
    }

    function __s() private pure returns (FacetManagerStorage.Layout storage) {
        return FacetManagerStorage.layout();
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