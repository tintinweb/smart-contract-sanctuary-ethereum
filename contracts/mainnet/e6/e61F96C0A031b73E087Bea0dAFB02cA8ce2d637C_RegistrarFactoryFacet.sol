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

import "../../../diamond/IDiamondFacet.sol";
import "./RegistrarFactoryInternal.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
contract RegistrarFactoryFacet is IDiamondFacet {

    function getFacetName()
      external pure override returns (string memory) {
        return "registrar-factory";
    }

    // CAUTION: Don't forget to update the version when adding new functionality
    function getFacetVersion()
      external pure override returns (string memory) {
        return "2.0.0";
    }

    function getFacetPI()
      external pure override returns (string[] memory) {
        string[] memory pi = new string[](5);
        pi[ 0] = "getContractKeys()";
        pi[ 1] = "getContract(string)";
        pi[ 2] = "setContract(string,address)";
        pi[ 3] = "getRegistrars()";
        pi[ 4] = "createRegistrar(address,address,string,string,string,string)";
        return pi;
    }

    function getFacetProtectedPI()
      external pure override returns (string[] memory) {
        string[] memory pi = new string[](2);
        pi[ 0] = "setContract(string,address)";
        pi[ 1] = "createRegistrar(address,address,string,string,string,string)";
        return pi;
    }

    function supportsInterface(bytes4 interfaceId)
      external pure override returns (bool) {
        return interfaceId == type(IDiamondFacet).interfaceId;
    }

    function getContractKeys() external view returns (string[] memory) {
        return RegistrarFactoryInternal._getContractKeys();
    }

    function getContract(string memory key) external view returns (address) {
        return RegistrarFactoryInternal._getContract(key);
    }

    function setContract(string memory key, address contractAddr) external {
        RegistrarFactoryInternal._setContract(key, contractAddr);
    }

    function getRegistrars() external view returns (address[] memory) {
        return RegistrarFactoryInternal._getRegistrars();
    }

    function createRegistrar(
        address taskManager,
        address authzSource,
        string memory registrarName,
        string memory registrarURI,
        string memory deedRegistryName,
        string memory deedRegistrySymbol
    ) external {
        RegistrarFactoryInternal._createRegistrar(
            taskManager,
            authzSource,
            registrarName,
            registrarURI,
            deedRegistryName,
            deedRegistrySymbol
        );
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

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "../DiamondHelper.sol";
import "../registrar/IRegistrar.sol";
import "../deed-registry/IDeedRegistry.sol";
import "../catalog/ICatalog.sol";
import "./RegistrarFactoryStorage.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
library RegistrarFactoryInternal {

    event RegistrarCreate(
        address indexed registrar
    );

    function _getContractKeys() internal view returns (string[] memory) {
        return __s().contractKeys;
    }

    function _getContract(string memory key) internal view returns (address) {
        return __getContract(key);
    }

    function _setContract(string memory key, address facet) internal {
        __addContractKey(key);
        __s().contracts[key] = facet;
    }

    function _getRegistrars() internal view returns (address[] memory) {
        return __s().registrars;
    }

    function _createRegistrar(
        address taskManager,
        address authzSource,
        string memory registrarName,
        string memory registrarURI,
        string memory deedRegistryName,
        string memory deedRegistrySymbol
    ) internal {
        // deploy the registrar contract
        address registrar = __createRegistrar(
            taskManager, authzSource, registrarName);
        // deploy the deed-registry contract
        address deedRegistry = __createDeedRegistry(
            taskManager, authzSource, registrarName);
        // deploy the catalog contract
        address catalog = __createCatalog(
            taskManager, authzSource, registrarName);
        // initialize the registrar contract
        IRegistrar(registrar).initializeRegistrar(
            deedRegistry,
            catalog,
            registrarName,
            registrarURI,
            taskManager,
            authzSource
        );
        // initialize the deed-registry contract
        IDeedRegistry(deedRegistry).initializeDeedRegistry(
            registrar, catalog, deedRegistryName, deedRegistrySymbol);
        // initialize the catalog contract
        ICatalog(catalog).initializeCatalog(
            registrar, deedRegistry);
        __s().registrars.push(registrar);
        emit RegistrarCreate(registrar);
    }

    function __addContractKey(string memory key) private {
        if (__s().contractKeysIndex[key] == 0) {
            __s().contractKeys.push(key);
            __s().contractKeysIndex[key] = __s().contractKeys.length;
        }
    }

    function __getContract(string memory key) private view returns (address) {
        address c = __s().contracts[key];
        require(c != address(0), string(abi.encodePacked("RFI:ZA-", key)));
        return c;
    }

    function __createRegistrar(
        address taskManager,
        address authzSource,
        string memory registrarName
    ) private returns (address) {
        return DiamondHelper._createDiamond(
            __getContract("diamond-factory"),
            taskManager,
            authzSource,
            string(abi.encodePacked(registrarName, "-registrar")),
            DiamondHelper._singleItemAddressArray(__getContract("registrar-facet"))
        );
    }

    function __createDeedRegistry(
        address taskManager,
        address authzSource,
        string memory registrarName
    ) private returns (address) {
        return DiamondHelper._createDiamond(
            __getContract("diamond-factory"),
            taskManager,
            authzSource,
            string(abi.encodePacked(registrarName, "-deed-registry")),
            DiamondHelper._singleItemAddressArray(__getContract("deed-registry-facet"))
        );
    }

    function __createCatalog(
        address taskManager,
        address authzSource,
        string memory registrarName
    ) private returns (address) {
        return DiamondHelper._createDiamond(
            __getContract("diamond-factory"),
            taskManager,
            authzSource,
            string(abi.encodePacked(registrarName, "-catalog")),
            DiamondHelper._singleItemAddressArray(__getContract("catalog-facet"))
        );
    }

    function __s() private pure returns (RegistrarFactoryStorage.Layout storage) {
        return RegistrarFactoryStorage.layout();
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
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

import "../../diamond/IDiamondFactory.sol";
import "../../diamond/IDiamondInitializer.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
library DiamondHelper {

    function _singleItemAddressArray(address addr) internal pure returns (address[] memory) {
        address[] memory arr = new address[](1);
        arr[0] = addr;
        return arr;
    }

    function _twoItemsAddressArray(
        address addr1,
        address addr2
    ) internal pure returns (address[] memory) {
        address[] memory arr = new address[](2);
        arr[0] = addr1;
        arr[1] = addr2;
        return arr;
    }

    function _threeItemsAddressArray(
        address addr1,
        address addr2,
        address addr3
    ) internal pure returns (address[] memory) {
        address[] memory arr = new address[](3);
        arr[0] = addr1;
        arr[1] = addr2;
        arr[2] = addr3;
        return arr;
    }

    function _fourItemsAddressArray(
        address addr1,
        address addr2,
        address addr3,
        address addr4
    ) internal pure returns (address[] memory) {
        address[] memory arr = new address[](4);
        arr[0] = addr1;
        arr[1] = addr2;
        arr[2] = addr3;
        arr[3] = addr4;
        return arr;
    }

    function _fiveItemsAddressArray(
        address addr1,
        address addr2,
        address addr3,
        address addr4,
        address addr5
    ) internal pure returns (address[] memory) {
        address[] memory arr = new address[](5);
        arr[0] = addr1;
        arr[1] = addr2;
        arr[2] = addr3;
        arr[3] = addr4;
        arr[4] = addr5;
        return arr;
    }

    function _createDiamond(
        address diamondFactory,
        address taskManager,
        address authzSource,
        string memory name,
        address[] memory defaultFacets
    ) internal returns (address) {
        address diamond = IDiamondFactory(diamondFactory).createDiamond(
            __emptySupporintgInterfaceIds(),
            address(this)
        );
        // intialize the diamond
        IDiamondInitializer(diamond).initialize(
            name,
            taskManager,
            address(0), // app-registry
            authzSource,
            "diamonds",
            __emptyApps(),
            defaultFacets,
            __emptyFuncSigsToProtectOrUnprotect(),
            __emptyFacetsToFreeze(),
            __noLockNoFreeze()
        );
        return diamond;
    }

    function __emptySupporintgInterfaceIds() private pure returns (bytes4[] memory) {
        return new bytes4[](0);
    }

    function __emptyApps() private pure returns (string[][2] memory) {
        string[][2] memory apps;
        apps[0] = new string[](0);
        apps[1] = new string[](0);
        return apps;
    }

    function __emptyFuncSigsToProtectOrUnprotect() private pure returns (string[][2] memory) {
        string[][2] memory funcSigsToProtectOrUnprotect;
        funcSigsToProtectOrUnprotect[0] = new string[](0);
        funcSigsToProtectOrUnprotect[1] = new string[](0);
        return funcSigsToProtectOrUnprotect;
    }

    function __emptyFacetsToFreeze() private pure returns (address[] memory) {
        return new address[](0);
    }

    function __noLockNoFreeze() private pure returns (bool[3] memory) {
        return [ false, false, false ];
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
interface IRegistrar {

    function initializeRegistrar(
        address deedRegistry,
        address catalog,
        string memory registrarName,
        string memory registrarURI,
        address defaultTaskManager,
        address defaultAuthzSource
    ) external;

    function getDeedRegistry() external view returns (address);

    function getCatalog() external view returns (address);
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
interface IDeedRegistry {

    function initializeDeedRegistry(
        address registrar,
        address catalog,
        string memory name,
        string memory symbol
    ) external;

    function mintDeed(
        uint256 registereeId,
        string memory deedURI
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

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
interface ICatalog {

    function initializeCatalog(
        address registrar,
        address deedRegistry
    ) external;

    function addDeed(
        uint256 registreeId,
        address grantToken,
        address council
    ) external;

    function submitTransfer(
        uint256 registereeId,
        address from,
        address to,
        uint256 amount
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

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk. Just got the basic
///         idea from: https://github.com/solidstate-network/solidstate-solidity
library RegistrarFactoryStorage {

    struct Layout {
        string[] contractKeys;
        mapping(string => uint256) contractKeysIndex;
        mapping(string => address) contracts;
        address[] registrars;
        // reserved for future usage
        mapping(bytes32 => bytes) extra;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("qomet-tech.contracts.facets.txn.registrar-factory.storage");

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