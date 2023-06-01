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

import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import "../../../diamond/IDiamondFacet.sol";
import "./ICatalog.sol";
import "./CatalogInternal.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
contract CatalogFacet is IDiamondFacet, IERC1155MetadataURI, ICatalog {

    function getFacetName()
      external pure override returns (string memory) {
        return "catalog";
    }

    // CAUTION: Don't forget to update the version when adding new functionality
    function getFacetVersion()
      external pure override returns (string memory) {
        return "1.4.1";
    }

    function getFacetPI()
      external pure override returns (string[] memory) {
        string[] memory pi = new string[](13);
        pi[ 0] = "initializeCatalog(address,address)";
        pi[ 1] = "getRegistrar()";
        pi[ 2] = "getDeedRegistry()";
        pi[ 3] = "addDeed(uint256,address,address)";
        pi[ 4] = "submitTransfer(uint256,address,address,uint256)";
        pi[ 5] = "balanceOf(address,uint256)";
        pi[ 6] = "balanceOfBatch(address[],uint256[])";
        pi[ 7] = "setApprovalForAll(address,bool)";
        pi[ 8] = "isApprovedForAll(address,address)";
        pi[ 9] = "safeTransferFrom(address,address,uint256,uint256,bytes)";
        pi[10] = "safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)";
        pi[11] = "uri(uint256)";
        pi[12] = "xMint(address,address,uint256,uint256)";
        return pi;
    }

    function getFacetProtectedPI()
      external pure override returns (string[] memory) {
        string[] memory pi = new string[](0);
        return pi;
    }

    function supportsInterface(bytes4 interfaceId)
      external pure override returns (bool) {
        return
            interfaceId == type(IDiamondFacet).interfaceId ||
            interfaceId == type(ICatalog).interfaceId ||
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId;
    }

    function initializeCatalog(
        address registrar,
        address deedRegistry
    ) external override {
        CatalogInternal._initialize(registrar, deedRegistry);

    }

    function getRegistrar() external view returns (address) {
        return CatalogInternal._getRegistrar();
    }

    function getDeedRegistry() external view returns (address) {
        return CatalogInternal._getDeedRegistry();
    }

    function addDeed(
        uint256 registereeId,
        address grantToken,
        address council
    ) external override {
        CatalogInternal._addDeed(registereeId, grantToken, council);
    }

    function submitTransfer(
        uint256 registereeId,
        address from,
        address to,
        uint256 amount
    ) external override {
        address caller = msg.sender;
        CatalogInternal._submitTransfer(
            caller, registereeId, from, to, amount);
    }

    function balanceOf(
        address account,
        uint256 registereeId
    ) external view override returns (uint256) {
        return CatalogInternal._balanceOf(account, registereeId);
    }

    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata registereeIds
    ) external view override returns (uint256[] memory) {
        return CatalogInternal._balanceOfBatch(accounts, registereeIds);
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) external override {
        CatalogInternal._setApprovalForAll(operator, approved);
    }

    function isApprovedForAll(
        address account,
        address operator
    ) external view override returns (bool) {
        return CatalogInternal._isApprovedForAll(account, operator);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 registereeId,
        uint256 amount,
        bytes calldata data
    ) external override {
        CatalogInternal._safeTransferFrom(
            from, to, registereeId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata registereeIds,
        uint256[] calldata amounts,
        bytes calldata data
    ) external pure override {
        CatalogInternal._safeBatchTransferFrom(
            from, to, registereeIds, amounts, data);
    }

    function uri(uint256 registereeId)
    external view override returns (string memory) {
        return CatalogInternal._uri(registereeId);
    }

    function xMint(
        address to,
        address origTo,
        uint256 registereeId,
        uint256 nrOfTokens
    ) external payable {
        CatalogInternal._xMint(origTo, registereeId, nrOfTokens);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
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

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "../council/ICouncil.sol";
import "./CatalogStorage.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
library CatalogInternal {

    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 registereeId,
        uint256 value
    );
    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );
    event URI(
        string value,
        uint256 indexed registereeId
    );

    function _initialize(
        address registrar,
        address deedRegistry
    ) internal {
        require(!__s().initialized, "CI:AI");
        __s().registrar = registrar;
        __s().deedRegistry = deedRegistry;
        __s().initialized = true;
    }

    function _getRegistrar() internal view returns (address) {
        return __s().registrar;
    }

    function _getDeedRegistry() internal view returns (address) {
        return __s().deedRegistry;
    }

    function _addDeed(
        uint256 registereeId,
        address grantToken,
        address council
    ) internal {
        require(msg.sender == __s().registrar, "CATI:NREG");
        require(!__exists(registereeId), "CATI:EXT");
        require(__s().deeds[registereeId].registereeId == 0, "CATI:EXT2");
        __s().deeds[registereeId].registereeId = registereeId;
        __s().deeds[registereeId].grantToken = grantToken;
        __s().deeds[registereeId].council = council;
        __s().lastRegistereeId = registereeId;
        emit TransferSingle(
            __s().registrar, address(0), council, registereeId,
                IERC20(grantToken).totalSupply());
    }

    function _submitTransfer(
        address caller,
        uint256 registereeId,
        address from,
        address to,
        uint256 amount
    ) internal {
        require(__exists(registereeId), "CATI:TNF");
        require(msg.sender == __s().deeds[registereeId].grantToken, "CATI:NST");
        emit TransferSingle(caller, from, to, registereeId, amount);
    }

    function _balanceOf(
        address account,
        uint256 registereeId
    ) internal view returns (uint256) {
        require(__exists(registereeId), "CATI:TNF");
        return IERC20(__s().deeds[registereeId].grantToken).balanceOf(account);
    }

    function _balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata registereeIds
    ) internal view returns (uint256[] memory) {
        require(accounts.length == registereeIds.length, "CATI:ILS");
        require(accounts.length > 0, "CATI:ZL");
        uint256[] memory balances = new uint256[](accounts.length);
        for (uint256 i = 1; i <= registereeIds.length; i++) {
            require(__exists(registereeIds[i]), "CATI:TNF");
            balances[i] = IERC20(__s().deeds[registereeIds[i]].grantToken).balanceOf(accounts[i]);
        }
        return balances;
    }

    function _setApprovalForAll(
        address operator,
        bool approved
    ) internal {
        __s().approvals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function _isApprovedForAll(
        address account,
        address operator
    ) internal view returns (bool) {
        return __s().approvals[account][operator];
    }

    function _safeTransferFrom(
        address from,
        address to,
        uint256 registereeId,
        uint256 amount,
        bytes calldata /* data */
    ) internal {
        require(from == msg.sender || _isApprovedForAll(from, msg.sender), "CATI:NAPPR");
        require(__exists(registereeId), "CATI:TNF");
        IERC20(__s().deeds[registereeId].grantToken)
            .transferFrom(from, to, amount);
    }

    function _safeBatchTransferFrom(
        address /* from */,
        address /* to */,
        uint256[] calldata /* registereeIds */,
        uint256[] calldata /* amounts */,
        bytes calldata /* data */
    ) internal pure {
        revert("batch transfer is not supported");
    }

    function _uri(uint256 registereeId)
    internal view returns (string memory) {
        require(__exists(registereeId), "CATI:TNF");
        return IERC721Metadata(__s().deedRegistry).tokenURI(registereeId);
    }

    function _xMint(
        address to,
        uint256 registereeId,
        uint256 nrOfTokens
    ) internal {
        require(__exists(registereeId), "CATI:TNF");
        ICouncil council = ICouncil(__s().deeds[registereeId].council);
        council.icoTransferTokensFromCouncil{ value: msg.value }(
            address(0), // payErc20
            msg.sender, // payer
            to,
            nrOfTokens
        );
    }

    function __exists(uint256 registereeId) internal view returns (bool) {
        return registereeId >= 0 && registereeId <= __s().lastRegistereeId;
    }

    function __s() private pure returns (CatalogStorage.Layout storage) {
        return CatalogStorage.layout();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
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
interface ICouncil {

    function initializeCouncil(
        uint256 registereeId,
        address grantToken,
        address feeCollectionAccount,
        address icoCollectionAccount,
        uint256 proposalCreationFeeMicroUSD,
        uint256 adminProposalCreationFeeMicroUSD,
        uint256 icoTokenPriceMicroUSD,
        uint256 icoFeeMicroUSD
    ) external;

    function getAccountProposals(
        address account,
        bool onlyPending
    ) external view returns (uint256[] memory);

    function executeProposal(
        address executor,
        uint256 proposalId
    ) external;

    function executeAdminProposal(
        address executor,
        uint256 adminProposalId
    ) external;

    function icoTransferTokensFromCouncil(
        address payErc20,
        address payer,
        address to,
        uint256 nrOfTokens
    ) external payable;
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
library CatalogStorage {

    struct Deed {
        uint256 registereeId;
        address grantToken;
        address council;

        // reserved for future usage
        mapping(bytes32 => bytes) extra;
    }

    struct Layout {
        bool initialized;

        address registrar;
        address deedRegistry;

        uint256 lastRegistereeId;
        mapping(uint256 => Deed) deeds;

        mapping(address => mapping(address => bool)) approvals;

        // reserved for future usage
        mapping(bytes32 => bytes) extra;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("qomet-tech.contracts.facets.txn.catalog.storage");

    function layout() internal pure returns (Layout storage s) {
        bytes32 slot = STORAGE_SLOT;
        /* solhint-disable no-inline-assembly */
        assembly {
            s.slot := slot
        }
        /* solhint-enable no-inline-assembly */
    }
}