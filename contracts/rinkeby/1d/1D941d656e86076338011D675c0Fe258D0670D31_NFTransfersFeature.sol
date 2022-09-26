// SPDX-License-Identifier: Apache-2.0
/*

  CopyrightCopyright 2022 Element.Market Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "../interfaces/INFTransfersFeature.sol";

contract NFTransfersFeature is INFTransfersFeature {

    using Address for address;

    function transferItems(address to, TransferItem[] calldata items) external override {
        transferItemsEx(to, items, false);
    }

    function transferERC721s(address to, address[] calldata tokens, uint256[][] calldata tokenIds) external override {
        transferERC721sEx(to, tokens, tokenIds, false);
    }

    function transferItemsEx(address to, TransferItem[] calldata items, bool revertIfIncomplete) public override {
        unchecked {
            bool someSuccess;
            if (to.isContract()) {
                for (uint256 i = 0; i < items.length; ++i) {
                    TransferItem calldata item = items[i];
                    if (item.itemType == ItemType.ERC721) {
                        require(item.amounts.length == 0, "require(item.amounts.length==0)");
                        address token = item.token;
                        uint256[] calldata ids = item.ids;
                        uint256 lengthIds = ids.length;
                        for (uint256 j = 0; j < lengthIds; ++j) {
                            if (_safeTransferERC721(token, to, ids[j])) {
                                someSuccess = true;
                            } else {
                                if (revertIfIncomplete) {
                                    revert("_safeTransferERC721/TRANSFER_FAILED");
                                }
                            }
                        }
                    } else if (item.itemType == ItemType.ERC1155) {
                        try IERC1155(item.token).safeBatchTransferFrom(msg.sender, to, item.ids, item.amounts, "") {
                            someSuccess = true;
                        } catch {
                            if (revertIfIncomplete) {
                                revert("_safeBatchTransferERC1155/TRANSFER_FAILED");
                            }
                        }
                    } else {
                        revert("INVALID_ITEM_TYPE");
                    }
                }
            } else {
                for (uint256 i = 0; i < items.length; ++i) {
                    TransferItem calldata item = items[i];
                    if (item.itemType == ItemType.ERC721) {
                        require(item.amounts.length == 0, "require(item.amounts.length==0)");
                        address token = item.token;
                        uint256[] calldata ids = item.ids;
                        uint256 lengthIds = ids.length;
                        for (uint256 j = 0; j < lengthIds; ++j) {
                            if (_transferERC721(token, to, ids[j])) {
                                someSuccess = true;
                            } else {
                                if (revertIfIncomplete) {
                                    revert("_transferERC721/TRANSFER_FAILED");
                                }
                            }
                        }
                    } else if (item.itemType == ItemType.ERC1155) {
                        try IERC1155(item.token).safeBatchTransferFrom(msg.sender, to, item.ids, item.amounts, "") {
                            someSuccess = true;
                        } catch {
                            if (revertIfIncomplete) {
                                revert("_safeBatchTransferERC1155/TRANSFER_FAILED");
                            }
                        }
                    } else {
                        revert("INVALID_ITEM_TYPE");
                    }
                }
            }
            require(someSuccess, "transferERC721sEx failed.");
        }
    }

    function transferERC721sEx(address to, address[] calldata tokens, uint256[][] calldata tokenIds, bool revertIfIncomplete) public override {
        require(tokens.length == tokenIds.length, "transferERC721sEx/ARRAY_LENGTH_MISMATCH");

        unchecked {
            bool someSuccess;
            if (to.isContract()) {
                for (uint256 i = 0; i < tokens.length; ++i) {
                    address token = tokens[i];
                    uint256[] calldata ids = tokenIds[i];
                    uint256 lengthIds = ids.length;
                    for (uint256 j = 0; j < lengthIds; ++j) {
                        if (_safeTransferERC721(token, to, ids[j])) {
                            someSuccess = true;
                        } else {
                            if (revertIfIncomplete) {
                                revert("_safeTransferERC721/TRANSFER_FAILED");
                            }
                        }
                    }
                }
            } else {
                for (uint256 i = 0; i < tokens.length; ++i) {
                    address token = tokens[i];
                    uint256[] calldata ids = tokenIds[i];
                    uint256 lengthIds = ids.length;
                    for (uint256 j = 0; j < lengthIds; ++j) {
                        if (_transferERC721(token, to, ids[j])) {
                            someSuccess = true;
                        } else {
                            if (revertIfIncomplete) {
                                revert("_transferERC721/TRANSFER_FAILED");
                            }
                        }
                    }
                }
            }
            require(someSuccess, "transferERC721sEx failed.");
        }
    }

    function _transferERC721(address token, address to, uint256 tokenId) internal returns (bool success) {
        assembly {
            let ptr := mload(0x40) // free memory pointer

            // selector for transferFrom(address,address,uint256)
            mstore(ptr, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(ptr, 0x04), caller())
            mstore(add(ptr, 0x24), to)
            mstore(add(ptr, 0x44), tokenId)

            success := call(gas(), token, 0, ptr, 0x64, 0, 0)
        }
    }

    function _safeTransferERC721(address token, address to, uint256 tokenId) internal returns (bool success)  {
        assembly {
            let ptr := mload(0x40) // free memory pointer

            // selector for safeTransferFrom(address,address,uint256)
            mstore(ptr, 0x42842e0e00000000000000000000000000000000000000000000000000000000)
            mstore(add(ptr, 0x04), caller())
            mstore(add(ptr, 0x24), to)
            mstore(add(ptr, 0x44), tokenId)

            success := call(gas(), token, 0, ptr, 0x64, 0, 0)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

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
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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

// SPDX-License-Identifier: Apache-2.0
/*

  CopyrightCopyright 2022 Element.Market Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.8.13;

interface INFTransfersFeature {

    enum ItemType {
        ERC721,
        ERC1155
    }

    struct TransferItem {
        ItemType itemType;
        address token;
        uint256[] ids;
        uint256[] amounts;
    }

    function transferItems(address to, TransferItem[] calldata items) external;

    function transferERC721s(address to, address[] calldata tokens, uint256[][] calldata tokenIds) external;

    function transferItemsEx(address to, TransferItem[] calldata items, bool revertIfIncomplete) external;

    function transferERC721sEx(address to, address[] calldata tokens, uint256[][] calldata tokenIds, bool revertIfIncomplete) external;
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