/*
 * This file is part of the contracts written for artèQ Investment Fund (https://github.com/arteq-io/contracts).
 * Copyright (c) 2022 artèQ (https://arteq.io)
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

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../../arteq-tech/contracts/vaults/VaultsConfig.sol";
import "../../arteq-tech/contracts/diamond/DiamondV1.sol";
import "./arteQCollectionV2Config.sol";

/// @author Kam Amini <[email protected]> <[email protected]>
///
/// @notice Use at your own risk

/* solhint-disable contract-name-camelcase */
contract arteQCollectionV2 is DiamondV1 {

    string private _detailsURI;

    modifier onlyAdmin {
        RoleManagerLib._checkRole(arteQCollectionV2Config.ROLE_ADMIN);
        _;
    }

    constructor(
        address taskManager,
        string memory detailsURI,
        address[] memory admins,
        address[] memory tokenManagers,
        address[] memory vaultAdmins,
        address[] memory diamondAdmins
    ) DiamondV1(taskManager, diamondAdmins) {

        // Admin role
        for (uint i = 0; i < admins.length; i++) {
            RoleManagerLib._grantRole(admins[i], arteQCollectionV2Config.ROLE_ADMIN);
        }
        // Token Manager role
        for (uint i = 0; i < tokenManagers.length; i++) {
            RoleManagerLib._grantRole(tokenManagers[i],arteQCollectionV2Config.ROLE_TOKEN_MANAGER);
        }
        // Vault Admin role
        for (uint i = 0; i < vaultAdmins.length; i++) {
            RoleManagerLib._grantRole(vaultAdmins[i], VaultsConfig.ROLE_VAULT_ADMIN);
        }

        _detailsURI = detailsURI;
    }

    function supportsInterface(bytes4 interfaceId)
      public view override returns (bool) {
        // We have to return true for OpenSea contract detection and caching mechanism
        if (interfaceId == type(IERC721).interfaceId) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    }

    function getDetailsURI() external view returns (string memory) {
        return _detailsURI;
    }

    function setDetailsURI(string memory newValue) external onlyAdmin {
        _detailsURI = newValue;
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
    receive() external payable {
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
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
library VaultsConfig {

    uint256 public constant ROLE_VAULT_ADMIN = uint256(keccak256(bytes("ROLE_VAULT_ADMIN")));
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
import "../security/task-executor/TaskExecutorFacet.sol";
import "../security/task-executor/TaskExecutorLib.sol";
import "../security/role-manager/RoleManagerFacet.sol";
import "../security/role-manager/RoleManagerLib.sol";
import "./IDiamondFacet.sol";
import "./DiamondV1Config.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
abstract contract DiamondV1 is
  IERC165,
  TaskExecutorFacet,
  RoleManagerFacet
{
    address[] private _facets;
    mapping(address => uint256) private _facetArrayIndex;
    mapping(bytes4 => address) private _selectorToFacetMap;
    mapping(address => string[]) private _facetToFuncSigsMap;
    mapping(address => mapping(bytes4 => bool)) private _removedFuncs;
    mapping(bytes4 => bool) private _suppressedInterfaceIds;

    modifier onlyDiamondAdmin() {
        RoleManagerLib._checkRole(DiamondV1Config.ROLE_DIAMOND_ADMIN);
        _;
    }

    constructor(
        address taskManager,
        address[] memory diamondAdmins
    ) {
        TaskExecutorLib._setTaskManager(taskManager);
        for(uint i = 0; i < diamondAdmins.length; i++) {
            RoleManagerLib._grantRole(diamondAdmins[i], DiamondV1Config.ROLE_DIAMOND_ADMIN);
        }
    }

    function supportsInterface(bytes4 interfaceId)
      public view override virtual returns (bool) {
        // Querying for IDiamondFacet must always return false
        if (interfaceId == type(IDiamondFacet).interfaceId) {
            return false;
        }
        if (_suppressedInterfaceIds[interfaceId]) {
            return false;
        }
        // Always return true
        if (interfaceId == type(IERC165).interfaceId) {
            return true;
        }
        for (uint256 i = 0; i < _facets.length; i++) {
            address facet = _facets[i];
            if (IDiamondFacet(facet).supportsInterface(interfaceId)) {
                return true;
            }
        }
        return false;
    }

    function isInterfaceIdSuppressed(bytes4 interfaceId)
      external view onlyDiamondAdmin returns (bool) {
        return _suppressedInterfaceIds[interfaceId];
    }

    function suppressInterfaceId(bytes4 interfaceId, bool suppress)
      external onlyDiamondAdmin {
        _suppressedInterfaceIds[interfaceId] = suppress;
    }

    function getFuncs()
      external view onlyDiamondAdmin returns (string[] memory, address[] memory) {
        return _getFuncs();
    }

    function getFacetFuncs(address facet)
      external view onlyDiamondAdmin returns (string[] memory) {
        return _getFacetFuncs(facet);
    }

    function addFuncs(
        string[] memory funcSigs,
        address[] memory facets
    ) external onlyDiamondAdmin {
        require(funcSigs.length > 0, "DV1:ZL");
        require(funcSigs.length == facets.length, "DV1:NEQL");
        for (uint256 i = 0; i < funcSigs.length; i++) {
            string memory funcSig = funcSigs[i];
            address facet = facets[i];
            _addFunc(funcSig, facet);
        }
    }

    function removeFuncs(
        string[] memory funcSigs
    ) external onlyDiamondAdmin {
        require(funcSigs.length > 0, "DV1:ZL");
        for (uint256 i = 0; i < funcSigs.length; i++) {
            string memory funcSig = funcSigs[i];
            _removeFunc(funcSig);
        }
    }

    function _getFuncs() internal view returns (string[] memory, address[] memory) {
        uint256 length = 0;
        for (uint256 i = 0; i < _facets.length; i++) {
            address facet = _facets[i];
            string[] memory facetFuncs = _getFacetFuncs(facet);
            for (uint256 j = 0; j < facetFuncs.length; j++) {
                length += 1;
            }
        }
        string[] memory funcSigs = new string[](length);
        address[] memory facets = new address[](length);
        uint256 index = 0;
        for (uint256 i = 0; i < _facets.length; i++) {
            address facet = _facets[i];
            string[] memory facetFuncs = _getFacetFuncs(facet);
            for (uint256 j = 0; j < facetFuncs.length; j++) {
                funcSigs[index] = facetFuncs[j];
                facets[index] = facet;
                index += 1;
            }
        }
        return (funcSigs, facets);
    }

    function _getFacetFuncs(address facet) internal view returns (string[] memory) {
        uint256 length = 0;
        for (uint256 j = 0; j < _facetToFuncSigsMap[facet].length; j++) {
            string memory funcSig = _facetToFuncSigsMap[facet][j];
            bytes4 selector = __getSelector(funcSig);
            if (!_removedFuncs[facet][selector]) {
                length += 1;
            }
        }
        string[] memory funcSigs = new string[](length);
        uint256 index = 0;
        for (uint256 j = 0; j < _facetToFuncSigsMap[facet].length; j++) {
            string memory funcSig = _facetToFuncSigsMap[facet][j];
            bytes4 selector = __getSelector(funcSig);
            if (!_removedFuncs[facet][selector]) {
                funcSigs[index] = funcSig;
                index += 1;
            }
        }
        return funcSigs;
    }

    function _addFunc(
        string memory funcSig,
        address facet
    ) internal {
        require(facet != address(0), "DV1:ZF");
        require(
            IDiamondFacet(facet).supportsInterface(type(IDiamondFacet).interfaceId),
            "DV1:IF"
        );
        bytes4 selector = __getSelector(funcSig);
        address oldFacet = _selectorToFacetMap[selector];

         // overrides the previously set selector
        _selectorToFacetMap[selector] = facet;

        bool found = false;
        for (uint256 i = 0; i < _facetToFuncSigsMap[facet].length; i++) {
            bytes32 s = __getSelector(_facetToFuncSigsMap[facet][i]);
            if (s == selector) {
                found = true;
                break;
            }
        }
        if (!found) {
            _facetToFuncSigsMap[facet].push(funcSig); // add the func-sig to facet's map
        }

        _removedFuncs[facet][selector] = false; // revive the selector if already removed
        if (oldFacet != address(0) && oldFacet != facet) {
            _removedFuncs[oldFacet][selector] = true; // remove from the old facet
        }

        // update facets array
        if (_facetArrayIndex[facet] == 0) {
            _facets.push(facet);
            _facetArrayIndex[facet] = _facets.length;
        }
    }

    function _removeFunc(
        string memory funcSig
    ) internal {
        bytes4 selector = __getSelector(funcSig);
        address facet = _selectorToFacetMap[selector];
        if (facet != address(0)) {
            _removedFuncs[facet][selector] = true;
        }
    }

    function _findFacet(bytes4 selector) internal view returns (address) {
        address facet = _selectorToFacetMap[selector];
        require(facet != address(0), "DV1:FNF");
        require(!_removedFuncs[facet][selector], "DV1:FR");
        return facet;
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
                revert("DV1:IFS");
            }
        }
        return bytes4(keccak256(bytes(funcSig)));
    }
}

/*
 * This file is part of the contracts written for artèQ Investment Fund (https://github.com/arteq-io/contracts).
 * Copyright (c) 2022 artèQ (https://arteq.io)
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

/* solhint-disable contract-name-camelcase */
library arteQCollectionV2Config {

    uint256 constant public ROLE_ADMIN = uint256(keccak256(bytes("ROLE_ADMIN")));

    uint256 constant public ROLE_TOKEN_MANAGER = uint256(keccak256(bytes("ROLE_TOKEN_MANAGER")));
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

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

import "./TaskExecutorInternal.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
contract TaskExecutorFacet {

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

import "../task-executor/TaskExecutorLib.sol";
import "./RoleManagerInternal.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
contract RoleManagerFacet {

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

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
interface IDiamondFacet {

    function getVersion() external view returns (string memory);

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
/// @notice Use at your own risk
library DiamondV1Config {

    uint256 public constant ROLE_DIAMOND_ADMIN = uint256(keccak256(bytes("ROLE_DIAMOND_ADMIN")));
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
import "../../interfaces/ITaskExecutor.sol";
import "./TaskExecutorStorage.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
library TaskExecutorInternal {

    event TaskManagerChanged(address newTaskManager);

    function _getTaskManager() internal view returns (address) {
        return __s().taskManager;
    }

    function _setTaskManager(address newTaskManager) internal {
        require(newTaskManager != address(0), "TE:ZA");
        require(IERC165(newTaskManager).supportsInterface(type(ITaskExecutor).interfaceId),
            "TE:IC");
        __s().taskManager = newTaskManager;
        emit TaskManagerChanged(__s().taskManager);
    }

    function _executeTask(uint256 taskId) internal {
        require(__s().taskManager != address(0), "TE:NTM");
        ITaskExecutor(__s().taskManager).executeTask(msg.sender, taskId);
    }

    function __s() private pure returns (TaskExecutorStorage.Layout storage) {
        return TaskExecutorStorage.layout();
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
interface ITaskExecutor {

    event TaskExecuted(address finalizer, address executor, uint256 taskId);

    function executeTask(address executor, uint256 taskId) external;

    function executeAdminTask(address executor, uint256 taskId) external;
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
library TaskExecutorStorage {

    struct Layout {
        address taskManager;
        mapping(uint256 => uint256) extra;
    }

    // Storage Slot: de1b6f91cd9572e4381a8b8d203bdc268664230f56599f11d2ca9df8d397fb6f
    bytes32 internal constant STORAGE_SLOT =
        keccak256("arteq-tech.contracts.security.task-executor.storage");

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