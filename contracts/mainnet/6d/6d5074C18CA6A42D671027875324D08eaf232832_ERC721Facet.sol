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

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "../../../arteq-tech/contracts/diamond/IDiamondFacet.sol";
import "../../../arteq-tech/contracts/security/role-manager/RoleManagerLib.sol";
import "../arteQCollectionV2Config.sol";
import "../token-store/TokenStoreLib.sol";
import "./ERC721Internal.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
contract ERC721Facet is IDiamondFacet {

    using Address for address;

    modifier onlyAdmin() {
        RoleManagerLib._checkRole(arteQCollectionV2Config.ROLE_ADMIN);
        _;
    }

    // CAUTION: Don't forget to update the version when adding new functionality
    function getVersion()
      external pure override returns (string memory) {
        return "0.0.1";
    }

    function supportsInterface(bytes4 interfaceId)
      external pure override returns (bool) {
        return
            interfaceId == type(IDiamondFacet).interfaceId ||
            interfaceId == type(IERC721).interfaceId;
    }

    function setERC721Settings(
        string memory name_,
        string memory symbol_
    ) external onlyAdmin {
        ERC721Internal._setERC721Settings(name_, symbol_);
    }

    // Most of the code is copied from:
    //   https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol

    function balanceOf(address owner) external view returns (uint256) {
        return ERC721Internal._balanceOf(owner);
    }

    function ownerOf(uint256 tokenId) external view returns (address) {
        return ERC721Internal._ownerOf(tokenId);
    }

    function name() external view returns (string memory) {
        return ERC721Internal._getName();
    }

    function setName(string memory name_) external onlyAdmin {
        ERC721Internal._setName(name_);
    }

    function symbol() external view returns (string memory) {
        return ERC721Internal._getSymbol();
    }

    function setSymbol(string memory symbol_) external onlyAdmin {
        ERC721Internal._setSymbol(symbol_);
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(ERC721Internal._exists(tokenId), "ERC721F:NET");
        return TokenStoreLib._getTokenURI(tokenId);
    }

    function approve(address to, uint256 tokenId) external {
        address owner = ERC721Internal._ownerOf(tokenId);
        require(to != owner, "ERC721F:ATC");
        require(
            msg.sender == owner || ERC721Internal._isApprovedForAll(owner, msg.sender),
            "ERC721F:NO"
        );
        ERC721Internal._approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) external view returns (address) {
        return ERC721Internal._getApproved(tokenId);
    }

    function setApprovalForAll(address operator, bool approved) external {
        ERC721Internal._setApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) external view returns (bool) {
        return ERC721Internal._isApprovedForAll(owner, operator);
    }

    function transferFromMe(
        address to,
        uint256 tokenId
    ) external onlyAdmin {
        ERC721Internal._transferFromMe(to, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external {
        require(ERC721Internal._isApprovedOrOwner(msg.sender, tokenId),
                "ERC721F:NO");
        ERC721Internal._transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public {
        require(ERC721Internal._isApprovedOrOwner(msg.sender, tokenId),
                "ERC721F:NO");
        _safeTransfer(from, to, tokenId, data);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal {
        ERC721Internal._transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721F:BADTO");
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721F:BADTO");
                } else {
                    /* solhint-disable no-inline-assembly */
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                    /* solhint-enable no-inline-assembly */
                }
            }
        } else {
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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

import "./TokenStoreInternal.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
library TokenStoreLib {

    function _getTokenURI(uint256 tokenId)
      internal view returns (string memory) {
        return TokenStoreInternal._getTokenURI(tokenId);
    }

    function _setTokenURI(
        uint256 tokenId,
        string memory tokenURI_
    ) internal {
        TokenStoreInternal._setTokenURI(tokenId, tokenURI_);
    }

    function _setTokenData(uint256 tokenId, string memory data) internal {
        TokenStoreInternal._setTokenData(tokenId, data);
    }

    function _addToRelatedTokens(address account, uint256 tokenId) internal {
        TokenStoreInternal._addToRelatedTokens(account, tokenId);
    }

    function _deleteTokenInfo(
        uint256 tokenId
    ) internal {
        TokenStoreInternal._deleteTokenInfo(tokenId);
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

import "../token-store/TokenStoreLib.sol";
import "../minter/MinterLib.sol";
import "../reserve-manager/ReserveManagerLib.sol";
import "./ERC721Storage.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
library ERC721Internal {

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function _setERC721Settings(
        string memory name_,
        string memory symbol_
    ) internal {
        _setName(name_);
        _setSymbol(symbol_);
        if (!_exists(0)) {
            MinterLib._justMintTo(address(this));
            ReserveManagerLib._initReserveManager();
        }
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
        require(owner != address(0), "ERC721I:ZA");
        return __s().balances[owner];
    }

    function _ownerOf(uint256 tokenId) internal view returns (address) {
        address owner = __s().owners[tokenId];
        require(owner != address(0), "ERC721I:NET");
        return owner;
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return __s().owners[tokenId] != address(0);
    }

    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "ERC721I:MZA");
        require(!_exists(tokenId), "ERC721I:TAM");
        __s().balances[to] += 1;
        __s().owners[tokenId] = to;
        emit Transfer(address(0), to, tokenId);
        TokenStoreLib._addToRelatedTokens(to, tokenId);
    }

    function _burn(uint256 tokenId) internal {
        address owner = _ownerOf(tokenId);
        // Clear approvals
        delete __s().tokenApprovals[tokenId];
        __s().balances[owner] -= 1;
        delete __s().owners[tokenId];
        emit Transfer(owner, address(0), tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        require(_ownerOf(tokenId) == from, "ERC721I:IO");
        require(to != address(0), "ERC721I:ZA");
        _unsafeTransfer(from, to, tokenId);
    }

    function _transferFromMe(
        address to,
        uint256 tokenId
    ) internal {
        require(_ownerOf(tokenId) == address(this), "ERC721I:IO");
        require(to != address(0), "ERC721I:ZA");
        _unsafeTransfer(address(this), to, tokenId);
    }

    function _unsafeTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        // Clear approvals from the previous owner
        delete __s().tokenApprovals[tokenId];
        __s().balances[from] -= 1;
        __s().balances[to] += 1;
        __s().owners[tokenId] = to;
        emit Transfer(from, to, tokenId);
        TokenStoreLib._addToRelatedTokens(to, tokenId);
    }

    function _getApproved(uint256 tokenId) internal view returns (address) {
        require(_ownerOf(tokenId) != address(0), "ERC721I:NET");
        return __s().tokenApprovals[tokenId];
    }

    function _isApprovedForAll(address owner, address operator) internal view returns (bool) {
        return __s().operatorApprovals[owner][operator];
    }

    function _isApprovedOrOwner(
        address spender,
        uint256 tokenId
    ) internal view returns (bool) {
        address owner = _ownerOf(tokenId);
        return (
            spender == owner ||
            __s().operatorApprovals[owner][spender] ||
            __s().tokenApprovals[tokenId] == spender
        );
    }

    function _approve(address to, uint256 tokenId) internal {
        __s().tokenApprovals[tokenId] = to;
        emit Approval(_ownerOf(tokenId), to, tokenId);
    }

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal {
        require(owner != operator, "ERC721I:ATC");
        __s().operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function __s() private pure returns (ERC721Storage.Layout storage) {
        return ERC721Storage.layout();
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

import "../erc721/ERC721Lib.sol";
import "./TokenStoreStorage.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
library TokenStoreInternal {

    event TokenURIChange(uint256 tokenId, string tokenURI);
    event TokenDataChange(uint256 tokenId, string data);

    // TODO(kam): allow transfer of token id #0

    function _getTokenStoreSettings() internal view returns (string memory, string memory) {
        return (__s().baseTokenURI, __s().defaultTokenURI);
    }

    function _setTokenStoreSettings(
        string memory baseTokenURI,
        string memory defaultTokenURI
    ) internal {
        __s().baseTokenURI = baseTokenURI;
        __s().defaultTokenURI = defaultTokenURI;
    }

    function _getTokenURI(uint256 tokenId)
      internal view returns (string memory) {
        require(ERC721Lib._exists(tokenId), "TSI:NET");
        string memory vTokenURI = __s().tokenInfos[tokenId].uri;
        if (bytes(vTokenURI).length == 0) {
            return __s().defaultTokenURI;
        }
        if (bytes(__s().baseTokenURI).length == 0) {
            return vTokenURI;
        }
        return string(abi.encodePacked(__s().baseTokenURI, vTokenURI));
    }

    function _setTokenURI(
        uint256 tokenId,
        string memory tokenURI_
    ) internal {
        require(ERC721Lib._exists(tokenId), "TSI:NET");
        __s().tokenInfos[tokenId].uri = tokenURI_;
        emit TokenURIChange(tokenId, tokenURI_);
    }

    function _getTokenData(uint256 tokenId)
      internal view returns (string memory) {
        require(ERC721Lib._exists(tokenId), "TSI:NET");
        return __s().tokenInfos[tokenId].data;
    }

    function _setTokenData(
        uint256 tokenId,
        string memory data
    ) internal {
        require(ERC721Lib._exists(tokenId), "TSF:NET");
        __s().tokenInfos[tokenId].data = data;
        emit TokenDataChange(tokenId, data);
    }

    function _getRelatedTokens(address account) internal view returns (uint256[] memory) {
        return __s().relatedTokens[account];
    }

    function _addToRelatedTokens(address account, uint256 tokenId) internal {
        __s().relatedTokens[account].push(tokenId);
    }

    function _ownedTokens(address account)
      internal view returns (uint256[] memory) {
        uint256 length = 0;
        if (account != address(0)) {
            for (uint256 i = 0; i < _getRelatedTokens(account).length; i++) {
                uint256 tokenId = _getRelatedTokens(account)[i];
                if (ERC721Lib._exists(tokenId) && ERC721Lib._ownerOf(tokenId) == account) {
                    length += 1;
                }
            }
        }
        uint256[] memory tokens = new uint256[](length);
        if (account != address(0)) {
            uint256 index = 0;
            for (uint256 i = 0; i < _getRelatedTokens(account).length; i++) {
                uint256 tokenId = _getRelatedTokens(account)[i];
                if (ERC721Lib._exists(tokenId) && ERC721Lib._ownerOf(tokenId) == account) {
                    tokens[index] = tokenId;
                    index += 1;
                }
            }
        }
        return tokens;
    }

    function _deleteTokenInfo(
        uint256 tokenId
    ) internal {
        if (bytes(__s().tokenInfos[tokenId].uri).length != 0) {
            delete __s().tokenInfos[tokenId];
        }
    }

    function __s() private pure returns (TokenStoreStorage.Layout storage) {
        return TokenStoreStorage.layout();
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

import "./ERC721Internal.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
library ERC721Lib {

    function _setName(string memory name) internal {
        ERC721Internal._setName(name);
    }

    function _setSymbol(string memory symbol) internal {
        ERC721Internal._setSymbol(symbol);
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return ERC721Internal._exists(tokenId);
    }

    function _ownerOf(uint256 tokenId) internal view returns (address) {
        return ERC721Internal._ownerOf(tokenId);
    }

    function _burn(uint256 tokenId) internal {
        ERC721Internal._burn(tokenId);
    }

    function _safeMint(address account, uint256 tokenId) internal {
        // TODO(kam): We don't have any safe mint in ERC721Internal
        ERC721Internal._mint(account, tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) internal {
        ERC721Internal._transfer(from, to, tokenId);
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
/// @notice Use at your own risk. Just got the basic
///         idea from: https://github.com/solidstate-network/solidstate-solidity
library TokenStoreStorage {

    struct TokenInfo {
        string uri;
        string data;
    }

    struct Layout {
        string baseTokenURI;
        string defaultTokenURI;
        mapping(uint256 => TokenInfo) tokenInfos;
        mapping(address => uint256[]) relatedTokens;
        mapping(uint256 => uint256) extra;
    }

    // Storage Slot: d48663c606213181d5dca65ab84ecc64807614baa9429ee057d88699409df195
    bytes32 internal constant STORAGE_SLOT =
        keccak256("arteq-io.collections.v2.token-store.storage");

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

import "./MinterInternal.sol";

library MinterLib {

    function _justMintTo(
        address owner
    ) internal returns (uint256) {
        return MinterInternal._justMintTo(owner);
    }

    function _getTokenIdCounter() internal view returns (uint256) {
        return MinterInternal._getTokenIdCounter();
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

import "./ReserveManagerInternal.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
library ReserveManagerLib {

    function _initReserveManager() internal {
        ReserveManagerInternal._initReserveManager();
    }

    function _reserveForAccount(
        address account,
        uint256 nrOfTokens,
        string memory paymentMethodName
    ) internal {
        ReserveManagerInternal._reserveForAccount(
            account,
            nrOfTokens,
            paymentMethodName
        );
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
/// @notice Use at your own risk. Just got the basic
///         idea from: https://github.com/solidstate-network/solidstate-solidity
library ERC721Storage {

    // Members are copied from:
    //   https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol
    struct Layout {
        // Token name
        string name;
        // Token symbol
        string symbol;
        // Mapping from token ID to owner address
        mapping(uint256 => address) owners;
        // Mapping owner address to token count
        mapping(address => uint256) balances;
        // Mapping from token ID to approved address
        mapping(uint256 => address) tokenApprovals;
        // Mapping from owner to operator approvals
        mapping(address => mapping(address => bool)) operatorApprovals;
    }

    // Storage Slot: 388c7adf3256757f43699890c2802d6747128681a3873e143cc5c0e8e176c131
    bytes32 internal constant STORAGE_SLOT =
        keccak256("arteq-io.collections.v2.erc721.storage");

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

import "../token-store/TokenStoreLib.sol";
import "../royalty-manager/RoyaltyManagerLib.sol";
import "../payment-handler/PaymentHandlerLib.sol";
import "./MinterStorage.sol";

library MinterInternal {

    event PreMint(uint256 nrOfTokens);

    function _getMintSettings()
      internal view returns (bool, bool, uint256, uint256, uint256) {
        return (
            __s().publicMinting,
            __s().directMintingAllowed,
            __s().mintFeeWei,
            __s().mintPriceWeiPerToken,
            __s().maxTokenId
        );
    }

    function _setMintSettings(
        bool publicMinting,
        bool directMintingAllowed,
        uint256 mintFeeWei,
        uint256 mintPriceWeiPerToken,
        uint256 maxTokenId
    ) internal {
        __s().publicMinting = publicMinting;
        __s().directMintingAllowed = directMintingAllowed;
        __s().mintFeeWei = mintFeeWei;
        __s().mintPriceWeiPerToken = mintPriceWeiPerToken;
        __s().maxTokenId = maxTokenId;
    }

    function _burn(uint256 tokenId) internal {
        ERC721Lib._burn(tokenId);
        TokenStoreLib._deleteTokenInfo(tokenId);
    }

    function _getTokenIdCounter() internal view returns (uint256) {
        return __s().tokenIdCounter;
    }

    function _justMintTo(
        address owner
    ) internal returns (uint256) {
        uint256 tokenId = __s().tokenIdCounter;
        require(__s().maxTokenId == 0 ||
                tokenId <= __s().maxTokenId, "M:MAX");
        __s().tokenIdCounter += 1;
        if (owner == address(this)) {
            ERC721Lib._safeMint(msg.sender, tokenId);
            ERC721Lib._transfer(msg.sender, address(this), tokenId);
        } else {
            ERC721Lib._safeMint(address(this), tokenId);
            ERC721Lib._transfer(address(this), owner, tokenId);
        }
        return tokenId;
    }

    function _preMint(uint256 nrOfTokens) internal {
        require(nrOfTokens > 0, "M:ZT");
        for (uint256 i = 0; i < nrOfTokens; i++) {
            _justMintTo(address(this));
        }
        emit PreMint(nrOfTokens);
    }

    function _mint(
        address owner,
        string[] memory uris,
        string[] memory datas,
        address[] memory royaltyWallets,
        uint256[] memory royaltyPercentages,
        bool handlePayment,
        string memory paymentMethodName
    ) internal {
        require(__s().directMintingAllowed, "M:DMNA");
        require(uris.length > 0, "M:NTM");
        require(datas.length == 0 ||
                uris.length == datas.length, "M:IL");
        require(royaltyWallets.length == 0 ||
                uris.length == royaltyWallets.length, "M:IL2");
        require(royaltyPercentages.length == 0 ||
                uris.length == royaltyPercentages.length, "M:IL3");
        if (handlePayment) {
            PaymentHandlerLib._handlePayment(
                1, __s().mintFeeWei,
                uris.length, __s().mintPriceWeiPerToken,
                paymentMethodName
            );
        }
        for (uint256 i = 0; i < uris.length; i++) {
            uint256 tokenId = _mintTo(owner, uris[i]);
            // Both royalty wallet and percentage must have sane values otherwise
            // the operator can always call other methods to set them.
            if (
                royaltyWallets.length > 0 &&
                royaltyPercentages.length > 0 &&
                royaltyWallets[i] != address(0) &&
                royaltyPercentages[i] > 0
            ) {
                RoyaltyManagerLib._setTokenRoyaltyInfo(tokenId, royaltyWallets[i], royaltyPercentages[i]);
            }
            if (datas.length > 0) {
                TokenStoreLib._setTokenData(tokenId, datas[i]);
            }
        }
    }

    function _updateTokens(
        uint256[] memory tokenIds,
        string[] memory uris,
        string[] memory datas
    ) internal {
        require(tokenIds.length > 0, "M:NTU");
        require(tokenIds.length == uris.length, "M:IL");
        require(tokenIds.length == datas.length, "M:IL2");
        for (uint256 i = 0; i < uris.length; i++) {
            TokenStoreLib._setTokenURI(tokenIds[i], uris[i]);
            TokenStoreLib._setTokenData(tokenIds[i], datas[i]);
        }
    }

    function _mintTo(
        address owner,
        string memory uri
    ) private returns (uint256) {
        uint256 tokenId = _justMintTo(owner);
        TokenStoreLib._setTokenURI(tokenId, uri);
        return tokenId;
    }

    function __s() private pure returns (MinterStorage.Layout storage) {
        return MinterStorage.layout();
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

import "./RoyaltyManagerInternal.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
library RoyaltyManagerLib {

    function _setTokenRoyaltyInfo(
        uint256 tokenId,
        address royaltyWallet,
        uint256 royaltyPercentage
    ) internal {
        RoyaltyManagerInternal._setTokenRoyaltyInfo(
            tokenId,
            royaltyWallet,
            royaltyPercentage
        );
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

import "./PaymentHandlerInternal.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
library PaymentHandlerLib {

    function _handlePayment(
        uint256 nrOfItems1, uint256 priceWeiPerItem1,
        uint256 nrOfItems2, uint256 priceWeiPerItem2,
        string memory paymentMethodName
    ) internal {
        PaymentHandlerInternal._handlePayment(
            nrOfItems1, priceWeiPerItem1,
            nrOfItems2, priceWeiPerItem2,
            paymentMethodName
        );
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
/// @notice Use at your own risk. Just got the basic
///         idea from: https://github.com/solidstate-network/solidstate-solidity
library MinterStorage {

    struct Layout {
        uint256 tokenIdCounter;
        bool publicMinting;
        bool directMintingAllowed;
        uint256 mintFeeWei;
        uint256 mintPriceWeiPerToken;
        uint256 maxTokenId;
        mapping(uint256 => uint256) extra;
    }

    // Storage Slot: 8605f7831093df2f7c7aac3d3c42e7477f4c86459f3bd04a98f554d64335de2a
    bytes32 internal constant STORAGE_SLOT =
        keccak256("arteq-io.collections.v2.minter.storage");

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

import "../erc721/ERC721Lib.sol";
import "./RoyaltyManagerStorage.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
library RoyaltyManagerInternal {

    event TokenRoyaltyInfoChanged(uint256 tokenId, address royaltyWallet, uint256 royaltyPercentage);
    event TokenRoyaltyExempt(uint256 tokenId, bool exempt);

    function _getDefaultRoyaltySettings() internal view returns (address, uint256) {
        return (__s().defaultRoyaltyWallet, __s().defaultRoyaltyPercentage);
    }

    // Either set address to zero or set percentage to zero to disable
    // default royalties. Still, royalties set per token work.
    function _setDefaultRoyaltySettings(
        address newDefaultRoyaltyWallet,
        uint256 newDefaultRoyaltyPercentage
    ) internal {
        __s().defaultRoyaltyWallet = newDefaultRoyaltyWallet;
        require(
            newDefaultRoyaltyPercentage >= 0 &&
            newDefaultRoyaltyPercentage <= 100,
            "ROMI:WP"
        );
        __s().defaultRoyaltyPercentage = newDefaultRoyaltyPercentage;
    }

    function _getTokenRoyaltyInfo(uint256 tokenId)
      internal view returns (address, uint256, bool) {
        require(ERC721Lib._exists(tokenId), "ROMI:NET");
        return (
            __s().tokenRoyalties[tokenId].royaltyWallet,
            __s().tokenRoyalties[tokenId].royaltyPercentage,
            __s().tokenRoyalties[tokenId].exempt
        );
    }

    function _setTokenRoyaltyInfo(
        uint256 tokenId,
        address royaltyWallet,
        uint256 royaltyPercentage
    ) internal {
        require(ERC721Lib._exists(tokenId), "ROMI:NET");
        require(royaltyPercentage >= 0 && royaltyPercentage <= 100, "ROMI:WP");
        __s().tokenRoyalties[tokenId].royaltyWallet = royaltyWallet;
        __s().tokenRoyalties[tokenId].royaltyPercentage = royaltyPercentage;
        __s().tokenRoyalties[tokenId].exempt = false;
        emit TokenRoyaltyInfoChanged(tokenId, royaltyWallet, royaltyPercentage);
    }

    function _exemptTokenRoyalty(uint256 tokenId, bool exempt) internal {
        require(ERC721Lib._exists(tokenId), "ROMI:NET");
        __s().tokenRoyalties[tokenId].exempt = exempt;
        emit TokenRoyaltyExempt(tokenId, exempt);
    }

    function _getRoyaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) internal view returns (address, uint256) {
        require(ERC721Lib._exists(tokenId), "ROMI:NET");
        RoyaltyManagerStorage.TokenRoyaltyInfo memory tokenRoyaltyInfo = __s().tokenRoyalties[tokenId];
        if (tokenRoyaltyInfo.exempt) {
            return (address(0), 0);
        }
        address royaltyWallet = tokenRoyaltyInfo.royaltyWallet;
        uint256 royaltyPercentage = tokenRoyaltyInfo.royaltyPercentage;
        if (royaltyWallet == address(0) || royaltyPercentage == 0) {
            royaltyWallet = __s().defaultRoyaltyWallet;
            royaltyPercentage = __s().defaultRoyaltyPercentage;
        }
        if (royaltyWallet == address(0) || royaltyPercentage == 0) {
            return (address(0), 0);
        }
        uint256 royalty = (salePrice * royaltyPercentage) / 100;
        return (royaltyWallet, royalty);
    }

    function __s() private pure returns (RoyaltyManagerStorage.Layout storage) {
        return RoyaltyManagerStorage.layout();
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
/// @notice Use at your own risk. Just got the basic
///         idea from: https://github.com/solidstate-network/solidstate-solidity
library RoyaltyManagerStorage {

    struct TokenRoyaltyInfo {
        address royaltyWallet;
        uint256 royaltyPercentage;
        bool exempt;
    }

    struct Layout {
        address defaultRoyaltyWallet;
        uint256 defaultRoyaltyPercentage;
        mapping(uint256 => TokenRoyaltyInfo) tokenRoyalties;
        mapping(uint256 => uint256) extra;
    }

    // Storage Slot: cfc77a8f0fe178bdc896b1d39fdc8403e4b8e4f59b0dc5da020d715bf2b8e0cd
    bytes32 internal constant STORAGE_SLOT =
        keccak256("arteq-io.collections.v2.royalty-manager.storage");

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

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "../IUniswapV2Pair.sol";
import "./PaymentHandlerStorage.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
library PaymentHandlerInternal {

    bytes32 constant public WEI_PAYMENT_METHOD_HASH = keccak256(abi.encode("WEI"));

    event WeiPayment(address payer, address dest, uint256 amountWei);
    event ERC20Payment(
        string paymentMethodName,
        address payer,
        address dest,
        uint256 amountWei,
        uint256 amountTokens
    );
    event TransferTo(address to, uint256 amount, string data);
    event TransferETH20To(string paymentMethodName, address to, uint256 amount, string data);

    function _getPaymentSettings() internal view returns (address, address) {
        return (__s().payoutAddress, __s().wethAddress);
    }

    function _setPaymentSettings(
        address payoutAddress,
        address wethAddress
    ) internal {
        __s().payoutAddress = payoutAddress;
        __s().wethAddress = wethAddress;
    }

    function _getERC20PaymentMethods() internal view returns (string[] memory) {
        return __s().erc20PaymentMethodNames;
    }

    function _getERC20PaymentMethodInfo(
        string memory paymentMethodName
    ) internal view returns (address, address, bool) {
        bytes32 nameHash = keccak256(abi.encode(paymentMethodName));
        require(_paymentMethodExists(nameHash), "PH:NEM");
        return (
            __s().erc20PaymentMethods[nameHash].addr,
            __s().erc20PaymentMethods[nameHash].wethPair,
            __s().erc20PaymentMethods[nameHash].enabled
        );
    }

    function _addOrUpdateERC20PaymentMethod(
        string memory paymentMethodName,
        address addr,
        address wethPair
    ) internal {
        bytes32 nameHash = keccak256(abi.encode(paymentMethodName));
        __s().erc20PaymentMethods[nameHash].addr = addr;
        __s().erc20PaymentMethods[nameHash].wethPair = wethPair;
        address token0 = IUniswapV2Pair(wethPair).token0();
        address token1 = IUniswapV2Pair(wethPair).token1();
        require(token0 == __s().wethAddress || token1 == __s().wethAddress, "PH:IPC");
        bool reverseIndices = (token1 == __s().wethAddress);
        __s().erc20PaymentMethods[nameHash].reverseIndices = reverseIndices;
        __s().erc20PaymentMethodNames.push(paymentMethodName);
    }

    function _enableERC20TokenPayment(
        string memory paymentMethodName,
        bool enabled
    ) internal {
        bytes32 nameHash = keccak256(abi.encode(paymentMethodName));
        require(_paymentMethodExists(nameHash), "PH:NEM");
        __s().erc20PaymentMethods[nameHash].enabled = enabled;
    }

    function _transferTo(
        string memory paymentMethodName,
        address to,
        uint256 amount,
        string memory data
    ) internal {
        require(to != address(0), "PH:TTZ");
        require(amount > 0, "PH:ZAM");
        bytes32 nameHash = keccak256(abi.encode(paymentMethodName));
        require(nameHash == WEI_PAYMENT_METHOD_HASH || _paymentMethodExists(nameHash), "PH:MNS");
        if (nameHash == WEI_PAYMENT_METHOD_HASH) {
            require(amount <= address(this).balance, "PH:MTB");
            /* solhint-disable avoid-low-level-calls */
            (bool success, ) = to.call{value: amount}(new bytes(0));
            /* solhint-enable avoid-low-level-calls */
            require(success, "PH:TF");
            emit TransferTo(to, amount, data);
        } else {
            PaymentHandlerStorage.ERC20PaymentMethodInfo memory paymentMethod =
                __s().erc20PaymentMethods[nameHash];
            require(
                amount <= IERC20(paymentMethod.addr).balanceOf(address(this)),
                "PH:MTB"
            );
            IERC20(paymentMethod.addr).transfer(to, amount);
            emit TransferETH20To(paymentMethodName, to, amount, data);
        }
    }

    function _handlePayment(
        uint256 nrOfItems1, uint256 priceWeiPerItem1,
        uint256 nrOfItems2, uint256 priceWeiPerItem2,
        string memory paymentMethodName
    ) internal {
        uint256 totalWei =
            nrOfItems1 * priceWeiPerItem1 +
            nrOfItems2 * priceWeiPerItem2;
        if (totalWei == 0) {
            return;
        }
        bytes32 nameHash = keccak256(abi.encode(paymentMethodName));
        require(nameHash == WEI_PAYMENT_METHOD_HASH ||
                _paymentMethodExists(nameHash), "PH:MNS");
        if (nameHash == WEI_PAYMENT_METHOD_HASH) {
            _handleWeiPayment(totalWei);
        } else {
            _handleERC20Payment(totalWei, paymentMethodName);
        }
    }

    function _paymentMethodExists(bytes32 paymentMethodNameHash) private view returns (bool) {
        return __s().erc20PaymentMethods[paymentMethodNameHash].addr != address(0) &&
               __s().erc20PaymentMethods[paymentMethodNameHash].wethPair != address(0) &&
               __s().erc20PaymentMethods[paymentMethodNameHash].enabled;
    }

    function _handleWeiPayment(
        uint256 priceWeiToPay
    ) private {
        require(msg.value >= priceWeiToPay, "PH:IF");
        uint256 remainder = msg.value - priceWeiToPay;
        if (__s().payoutAddress != address(0)) {
            /* solhint-disable avoid-low-level-calls */
            (bool success, ) = __s().payoutAddress.call{value: priceWeiToPay}(new bytes(0));
            /* solhint-enable avoid-low-level-calls */
            require(success, "PH:TF");
            emit WeiPayment(msg.sender, __s().payoutAddress, priceWeiToPay);
        } else {
            emit WeiPayment(msg.sender, address(this), priceWeiToPay);
        }
        if (remainder > 0) {
            /* solhint-disable avoid-low-level-calls */
            (bool success, ) = msg.sender.call{value: remainder}(new bytes(0));
            /* solhint-enable avoid-low-level-calls */
            require(success, "PH:RTF");
        }
    }

    function _handleERC20Payment(
        uint256 priceWeiToPay,
        string memory paymentMethodName
    ) private {
        bytes32 nameHash = keccak256(abi.encode(paymentMethodName));
        PaymentHandlerStorage.ERC20PaymentMethodInfo memory paymentMethod =
            __s().erc20PaymentMethods[nameHash];
        (uint112 amount0, uint112 amount1,) = IUniswapV2Pair(paymentMethod.wethPair).getReserves();
        uint256 reserveWei = amount0;
        uint256 reserveTokens = amount1;
        if (paymentMethod.reverseIndices) {
            reserveWei = amount1;
            reserveTokens = amount0;
        }
        require(reserveWei > 0, "PH:NWR");
        uint256 amountTokens = (priceWeiToPay * reserveTokens) / reserveWei;
        address dest = address(this);
        if (__s().payoutAddress != address(0)) {
            dest = __s().payoutAddress;
        }
        // this contract must have already been approved by the msg.sender
        IERC20(paymentMethod.addr).transferFrom(msg.sender, dest, amountTokens);
        emit ERC20Payment(paymentMethodName, msg.sender, dest, priceWeiToPay, amountTokens);
    }

    function __s() private pure returns (PaymentHandlerStorage.Layout storage) {
        return PaymentHandlerStorage.layout();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

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

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
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
/// @notice Use at your own risk. Just got the basic
///         idea from: https://github.com/solidstate-network/solidstate-solidity
library PaymentHandlerStorage {

    struct ERC20PaymentMethodInfo {
        address addr;
        // Uniswap V2 Pair
        address wethPair;
        bool reverseIndices;
        bool enabled;
    }

    struct Layout {
        address payoutAddress;
        address wethAddress;
        string[] erc20PaymentMethodNames;
        mapping(bytes32 => ERC20PaymentMethodInfo) erc20PaymentMethods;
        mapping(uint256 => uint256) extra;
    }

    // Storage Slot: a0efacd423120980dd05e5b29c20ccdcbe1b82d6c1e2453fa01907429f24d423
    bytes32 internal constant STORAGE_SLOT =
        keccak256("arteq-io.collections.v2.payment-handler.storage");

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

import "../erc721/ERC721Lib.sol";
import "../minter/MinterLib.sol";
import "../whitelist-manager/WhitelistManagerLib.sol";
import "../payment-handler/PaymentHandlerLib.sol";
import "./ReserveManagerStorage.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
library ReserveManagerInternal {

    event ReserveToken(address account, uint256 tokenId);

    function _initReserveManager() internal {
        // We always keep the token #0 reserved for the contract
        __s().reservedTokenIdCounter = 1;
    }

    function _getReservationSettings()
      internal view returns (bool, bool, uint256, uint256) {
        return (
            __s().reservationAllowed,
            __s().reservationAllowedWithoutWhitelisting,
            __s().reservationFeeWei,
            __s().reservePriceWeiPerToken
        );
    }

    function _setReservationAllowed(
        bool reservationAllowed,
        bool reservationAllowedWithoutWhitelisting,
        uint256 reservationFeeWei,
        uint256 reservePriceWeiPerToken
    ) internal {
        __s().reservationAllowed = reservationAllowed;
        __s().reservationAllowedWithoutWhitelisting = reservationAllowedWithoutWhitelisting;
        __s().reservationFeeWei = reservationFeeWei;
        __s().reservePriceWeiPerToken = reservePriceWeiPerToken;
    }

    function _reserveForAccount(
        address account,
        uint256 nrOfTokens,
        string memory paymentMethodName
    ) internal {
        require(__s().reservationAllowed, "RM:NA");
        if (!__s().reservationAllowedWithoutWhitelisting) {
            uint256 nrOfWhitelistedTokens = WhitelistManagerLib._getWhitelistEntry(account);
            uint256 nrOfReservedTokens = __s().nrOfReservedTokens[account];
            require(nrOfReservedTokens < nrOfWhitelistedTokens, "RM:EMAX");
            require(nrOfTokens <= (nrOfWhitelistedTokens - nrOfReservedTokens), "RM:EMAX2");
        }
        PaymentHandlerLib._handlePayment(
            1, __s().reservationFeeWei,
            nrOfTokens, __s().reservePriceWeiPerToken,
            paymentMethodName
        );
        _reserve(account, nrOfTokens);
    }

    // NOTE: This is always allowed
    function _reserveForAccounts(
        address[] memory accounts,
        uint256[] memory nrOfTokensArray
    ) internal {
        require(accounts.length == nrOfTokensArray.length, "RM:II");
        for (uint256 i = 0; i < accounts.length; i++) {
            _reserve(accounts[i], nrOfTokensArray[i]);
        }
    }

    function _reserve(
        address account,
        uint256 nrOfTokens
    ) private {
        require(account != address(this), "RM:IA");
        for (uint256 i = 0; i < nrOfTokens; i++) {
            bool found = false;
            while (__s().reservedTokenIdCounter < MinterLib._getTokenIdCounter()) {
                if (ERC721Lib._ownerOf(__s().reservedTokenIdCounter) == address(this)) {
                    found = true;
                    break;
                }
                __s().reservedTokenIdCounter += 1;
            }
            if (found) {
                ERC721Lib._transfer(address(this), account, __s().reservedTokenIdCounter);
                emit ReserveToken(account, __s().reservedTokenIdCounter);
            } else {
                MinterLib._justMintTo(account);
                emit ReserveToken(account, MinterLib._getTokenIdCounter() - 1);
            }
            __s().reservedTokenIdCounter += 1;
        }
        __s().nrOfReservedTokens[account] += nrOfTokens;
    }

    function __s() private pure returns (ReserveManagerStorage.Layout storage) {
        return ReserveManagerStorage.layout();
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

import "./WhitelistManagerInternal.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
library WhitelistManagerLib {

    function _getWhitelistEntry(address account) internal view returns (uint256) {
        return WhitelistManagerInternal._getWhitelistEntry(account);
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
/// @notice Use at your own risk. Just got the basic
///         idea from: https://github.com/solidstate-network/solidstate-solidity
library ReserveManagerStorage {

    struct Layout {
        bool reservationAllowed;
        bool reservationAllowedWithoutWhitelisting;
        uint256 reservationFeeWei;
        uint256 reservePriceWeiPerToken;
        uint256 reservedTokenIdCounter;
        mapping(address => uint256) nrOfReservedTokens;
        mapping(uint256 => uint256) extra;
    }

    // Storage Slot: 3aad2c382efb31a6bafea258059f50695b79a079bf36fa54252ddf5a4f956c74
    bytes32 internal constant STORAGE_SLOT =
        keccak256("arteq-io.collections.v2.reserve-manager.storage");

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

import "../payment-handler/PaymentHandlerLib.sol";
import "./WhitelistManagerStorage.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
library WhitelistManagerInternal {

    event Whitelist(address account, uint256 nrOfTokens);

    function _getWhitelistingSettings()
      internal view returns (bool, uint256, uint256, uint256) {
        return (
            __s().whitelistingAllowed,
            __s().whitelistingFeeWei,
            __s().whitelistingPriceWeiPerToken,
            __s().maxNrOfWhitelistedTokensPerAccount
        );
    }

    function _setWhitelistingSettings(
        bool whitelistingAllowed,
        uint256 whitelistingFeeWei,
        uint256 whitelistingPriceWeiPerToken,
        uint256 maxNrOfWhitelistedTokensPerAccount
    ) internal {
        __s().whitelistingAllowed = whitelistingAllowed;
        __s().whitelistingFeeWei = whitelistingFeeWei;
        __s().whitelistingPriceWeiPerToken = whitelistingPriceWeiPerToken;
        __s().maxNrOfWhitelistedTokensPerAccount = maxNrOfWhitelistedTokensPerAccount;
    }

    // Send 0 for nrOfTokens to de-list the address
    function _whitelistMe(
        uint256 nrOfTokens,
        string memory paymentMethodName
    ) internal {
        require(__s().whitelistingAllowed, "WM:NA");
        PaymentHandlerLib._handlePayment(
            1, __s().whitelistingFeeWei,
            nrOfTokens, __s().whitelistingPriceWeiPerToken,
            paymentMethodName
        );
        _whitelist(msg.sender, nrOfTokens);
    }

    // Send 0 for nrOfTokens to de-list an address
    function _whitelistAccounts(
        address[] memory accounts,
        uint256[] memory nrOfTokensArray
    ) internal {
        require(__s().whitelistingAllowed, "WM:NA");
        require(accounts.length == nrOfTokensArray.length, "WM:IL");
        for (uint256 i = 0; i < accounts.length; i++) {
            _whitelist(accounts[i], nrOfTokensArray[i]);
        }
    }

    function _getWhitelistEntry(address account) internal view returns (uint256) {
        return __s().whitelistEntries[account];
    }

    function _whitelist(
        address account,
        uint256 nrOfTokens
    ) private {
        require(__s().maxNrOfWhitelistedTokensPerAccount == 0 ||
                nrOfTokens <= __s().maxNrOfWhitelistedTokensPerAccount,
                "WM:EMAX");
        __s().whitelistEntries[account] = nrOfTokens;
        emit Whitelist(account, nrOfTokens);
    }

    function __s() private pure returns (WhitelistManagerStorage.Layout storage) {
        return WhitelistManagerStorage.layout();
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
/// @notice Use at your own risk. Just got the basic
///         idea from: https://github.com/solidstate-network/solidstate-solidity
library WhitelistManagerStorage {

    struct Layout {
        bool whitelistingAllowed;
        uint256 whitelistingFeeWei;
        uint256 whitelistingPriceWeiPerToken;
        uint256 maxNrOfWhitelistedTokensPerAccount;
        mapping(address => uint256) whitelistEntries;
    }

    // Storage Slot: 71e0208316fc901686daf4f3337ab9e0c066ba9c3c2727e9209867af42765c4e
    bytes32 internal constant STORAGE_SLOT =
        keccak256("arteq-io.collections.v2.whitelist-manager.storage");

    function layout() internal pure returns (Layout storage s) {
        bytes32 slot = STORAGE_SLOT;
        /* solhint-disable no-inline-assembly */
        assembly {
            s.slot := slot
        }
        /* solhint-enable no-inline-assembly */
    }
}