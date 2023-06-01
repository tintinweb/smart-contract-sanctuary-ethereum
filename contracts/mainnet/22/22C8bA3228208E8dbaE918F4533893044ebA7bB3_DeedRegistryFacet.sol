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

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "../../../diamond/IDiamondFactory.sol";
import "../../../diamond/IDiamondFacet.sol";
import "./IDeedRegistry.sol";
import "./DeedRegistryInternal.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
contract DeedRegistryFacet is IDiamondFacet, IDeedRegistry {

    function getFacetName()
      external pure override returns (string memory) {
        return "deed-registry";
    }

    // CAUTION: Don't forget to update the version when adding new functionality
    function getFacetVersion()
      external pure override returns (string memory) {
        return "1.1.0";
    }

    function getFacetPI()
      external pure override returns (string[] memory) {
        string[] memory pi = new string[](16);
        pi[ 0] = "initializeDeedRegistry(address,address,string,string)";
        pi[ 1] = "balanceOf(address)";
        pi[ 2] = "ownerOf(uint256)";
        pi[ 3] = "getRegistrar()";
        pi[ 4] = "getCatalog()";
        pi[ 5] = "getNrOfDeeds()";
        pi[ 6] = "name()";
        pi[ 7] = "setName(string)";
        pi[ 8] = "symbol()";
        pi[ 9] = "setSymbol(string)";
        pi[10] = "tokenURI(uint256)";
        pi[11] = "setDeedURI(uint256,string)";
        pi[12] = "getDeedAnnexes(uint256)";
        pi[13] = "addDeedAnnex(uint256,string)";
        pi[14] = "setDeedAnnex(uint256,uint256,string)";
        pi[15] = "mintDeed(uint256,string)";
        return pi;
    }

    function getFacetProtectedPI()
      external pure override returns (string[] memory) {
        string[] memory pi = new string[](5);
        pi[ 0] = "setName(string)";
        pi[ 1] = "setSymbol(string)";
        pi[ 2] = "setDeedURI(uint256,string)";
        pi[ 3] = "addDeedAnnex(uint256,string)";
        pi[ 4] = "setDeedAnnex(uint256,uint256,string)";
        return pi;
    }

    function supportsInterface(bytes4 interfaceId)
      external pure override returns (bool) {
        return
            interfaceId == type(IDiamondFacet).interfaceId ||
            interfaceId == type(IDeedRegistry).interfaceId ||
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId;
    }

    function initializeDeedRegistry(
        address registrar,
        address catalog,
        string memory name_,
        string memory symbol_
    ) external override {
        DeedRegistryInternal._initialize(registrar, catalog, name_, symbol_);
    }

    function balanceOf(address owner) external view returns (uint256) {
        return DeedRegistryInternal._balanceOf(owner);
    }

    function ownerOf(uint256 tokenId) external view returns (address) {
        return DeedRegistryInternal._ownerOf(tokenId);
    }

    function getRegistrar() external view returns (address) {
        return DeedRegistryInternal._getRegistrar();
    }

    function getCatalog() external view returns (address) {
        return DeedRegistryInternal._getCatalog();
    }

    function getNrOfDeeds() external view returns (uint256) {
        return DeedRegistryInternal._getNrOfDeeds();
    }

    function name() external view returns (string memory) {
        return DeedRegistryInternal._getName();
    }

    function setName(string memory name_) external {
        DeedRegistryInternal._setName(name_);
    }

    function symbol() external view returns (string memory) {
        return DeedRegistryInternal._getSymbol();
    }

    function setSymbol(string memory symbol_) external {
        DeedRegistryInternal._setSymbol(symbol_);
    }

    function tokenURI(uint256 registereeId) external view returns (string memory) {
        return DeedRegistryInternal._getDeedURI(registereeId);
    }

    function setDeedURI(uint256 registereeId, string memory deedURI) external {
        DeedRegistryInternal._setDeedURI(registereeId, deedURI);
    }

    function getDeedAnnexes(uint256 registereeId) external view returns (string[] memory) {
        return DeedRegistryInternal._getDeedAnnexes(registereeId);
    }

    function addDeedAnnex(uint256 registereeId, string memory annexURI) external {
        DeedRegistryInternal._addDeedAnnex(registereeId, annexURI);
    }

    function setDeedAnnex(
        uint256 registereeId,
        uint256 index,
        string memory annexURI
    ) external {
        DeedRegistryInternal._setDeedAnnex(registereeId, index, annexURI);
    }

    function mintDeed(
        uint256 registereeId,
        string memory deedURI
    ) external override {
        DeedRegistryInternal._mintDeed(registereeId, deedURI);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
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

import "./DeedRegistryStorage.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
library DeedRegistryInternal {

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    function _initialize(
        address registrar,
        address catalog,
        string memory name,
        string memory symbol
    ) internal {
        require(!__s().initialized, "DRI:AI");
        __s().registrar = registrar;
        __s().catalog = catalog;
        __s().name = name;
        __s().symbol = symbol;
        __s().initialized = true;
    }

    function _getRegistrar() internal view returns (address) {
        return __s().registrar;
    }

    function _getCatalog() internal view returns (address) {
        return __s().catalog;
    }

    function _getNrOfDeeds() internal view returns (uint256) {
        return __s().lastRegistereeId;
    }

    function _getName() internal view returns (string memory) {
        return __s().name;
    }

    function _setName(string memory name) internal {
        __s().name = name;
    }

    function _getSymbol() internal view returns (string memory) {
        return __s().symbol;
    }

    function _setSymbol(string memory symbol) internal {
        __s().symbol = symbol;
    }

    function _balanceOf(address owner) internal view returns (uint256) {
        if (owner != __s().registrar) {
            return 0;
        }
        return __s().lastRegistereeId;
    }

    function _exists(uint256 registereeId) internal view returns (bool) {
        return registereeId > 0 && registereeId <= __s().lastRegistereeId;
    }

    function _ownerOf(uint256 registereeId) internal view returns (address) {
        require(_exists(registereeId), "DRI:TNF");
        return __s().registrar;
    }

    function _getDeedURI(uint256 registereeId) internal view returns (string memory) {
        require(_exists(registereeId), "DRI:TNF");
        return __s().deeds[registereeId].uri;
    }

    function _setDeedURI(uint256 registereeId, string memory deedURI) internal {
        require(_exists(registereeId), "DRI:TNF");
        __s().deeds[registereeId].uri = deedURI;
    }

    function _getDeedAnnexes(uint256 registereeId) internal view returns (string[] memory) {
        require(_exists(registereeId), "DRI:TNF");
        return __s().deeds[registereeId].annexes;
    }

    function _addDeedAnnex(uint256 registereeId, string memory annexURI) internal {
        require(_exists(registereeId), "DRI:TNF");
        __s().deeds[registereeId].annexes.push(annexURI);
    }

    function _setDeedAnnex(
        uint256 registereeId,
        uint256 index,
        string memory annexURI
    ) internal {
        require(_exists(registereeId), "DRI:TNF");
        require(index < __s().deeds[registereeId].annexes.length, "DRI:IINX");
        __s().deeds[registereeId].annexes[index] = annexURI;
    }

    function _mintDeed(
        uint256 registereeId,
        string memory deedURI
    ) internal {
        require(__s().initialized, "DRI:NI");
        require(msg.sender == __s().registrar, "DRI:ACCDEN");
        require(__s().deeds[registereeId].registereeId == 0, "DRI:ET");
        __s().deeds[registereeId].registereeId = registereeId;
        __s().deeds[registereeId].uri = deedURI;
        __s().lastRegistereeId = registereeId;
        emit Transfer(address(0), __s().registrar, registereeId);
    }

    function __s() private pure returns (DeedRegistryStorage.Layout storage) {
        return DeedRegistryStorage.layout();
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
/// @notice Use at your own risk. Just got the basic
///         idea from: https://github.com/solidstate-network/solidstate-solidity
library DeedRegistryStorage {

    struct Deed {
        uint256 registereeId;
        string uri;
        string[] annexes;
        // reserved for future usage
        mapping(bytes32 => bytes) extra;
    }

    struct Layout {
        bool initialized;

        address registrar;
        address catalog;

        string name;
        string symbol;

        uint256 lastRegistereeId;
        mapping(uint256 => Deed) deeds;

        // reserved for future usage
        mapping(bytes32 => bytes) extra;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("qomet-tech.contracts.facets.txn.deed-registry.storage");

    function layout() internal pure returns (Layout storage s) {
        bytes32 slot = STORAGE_SLOT;
        /* solhint-disable no-inline-assembly */
        assembly {
            s.slot := slot
        }
        /* solhint-enable no-inline-assembly */
    }
}