/**
 *Submitted for verification at Etherscan.io on 2022-04-16
*/

// SPDX-License-Identifier: None
    // All rights reserved. @2022
    
    /*
 __          ___     _ _        _____      _          _               
 \ \        / / |   (_) |      / ____|    | |        | |              
  \ \  /\  / /| |__  _| |_ ___| |    _   _| |__   ___| | ___  ___ ___ 
   \ \/  \/ / | '_ \| | __/ _ \ |   | | | | '_ \ / _ \ |/ _ \/ __/ __|
    \  /\  /  | | | | | ||  __/ |___| |_| | |_) |  __/ |  __/\__ \__ \
     \/  \/   |_| |_|_|\__\___|\_____\__,_|_.__/ \___|_|\___||___/___/
                                                                      
    */

    // File: @openzeppelin/contracts/utils/cryptography/MerkleProof.sol


    // OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/MerkleProof.sol)

    pragma solidity ^0.8.0;


    /**
    * @dev These functions deal with verification of Merkle Trees proofs.
    *
    * The proofs can be generated using the JavaScript library
    * https://github.com/miguelmota/merkletreejs[merkletreejs].
    * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
    *
    * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
    */
    library MerkleProof {
        /**
        * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
        * defined by `root`. For this, a `proof` must be provided, containing
        * sibling hashes on the branch from the leaf to the root of the tree. Each
        * pair of leaves and each pair of pre-images are assumed to be sorted.
        */
        function verify(
            bytes32[] memory proof,
            bytes32 root,
            bytes32 leaf
        ) internal pure returns (bool) {
            return processProof(proof, leaf) == root;
        }

        /**
        * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
        * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
        * hash matches the root of the tree. When processing the proof, the pairs
        * of leafs & pre-images are assumed to be sorted.
        *
        * _Available since v4.4._
        */
        function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
            bytes32 computedHash = leaf;
            for (uint256 i = 0; i < proof.length; i++) {
                bytes32 proofElement = proof[i];
                if (computedHash <= proofElement) {
                    // Hash(current computed hash + current element of the proof)
                    computedHash = _efficientHash(computedHash, proofElement);
                } else {
                    // Hash(current element of the proof + current computed hash)
                    computedHash = _efficientHash(proofElement, computedHash);
                }
            }
            return computedHash;
        }

        function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
            assembly {
                mstore(0x00, a)
                mstore(0x20, b)
                value := keccak256(0x00, 0x40)
            }
        }
    }

    // File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

    // File: @openzeppelin/contracts/interfaces/IERC165.sol


    // OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

    pragma solidity ^0.8.0;


    // File: @openzeppelin/contracts/interfaces/IERC2981.sol


    // OpenZeppelin Contracts (last updated v4.5.0) (interfaces/IERC2981.sol)

    pragma solidity ^0.8.0;


    /**
    * @dev Interface for the NFT Royalty Standard.
    *
    * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
    * support for royalty payments across all NFT marketplaces and ecosystem participants.
    *
    * _Available since v4.5._
    */
    interface IERC2981 is IERC165 {
        /**
        * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
        * exchange. The royalty amount is denominated and should be payed in that same unit of exchange.
        */
        function royaltyInfo(uint256 tokenId, uint256 salePrice)
            external
            view
            returns (address receiver, uint256 royaltyAmount);
    }

    // File: @openzeppelin/contracts/token/ERC721/IERC721.sol


    // OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

    pragma solidity ^0.8.0;


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

    // File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol


    // OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

    pragma solidity ^0.8.0;


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

    // File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol


    // OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

    pragma solidity ^0.8.0;


    /**
    * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
    * @dev See https://eips.ethereum.org/EIPS/eip-721
    */
    interface IERC721Enumerable is IERC721 {
        /**
        * @dev Returns the total amount of tokens stored by the contract.
        */
        function totalSupply() external view returns (uint256);

        /**
        * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
        * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
        */
        function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

        /**
        * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
        * Use along with {totalSupply} to enumerate all tokens.
        */
        function tokenByIndex(uint256 index) external view returns (uint256);
    }

    // File: @openzeppelin/contracts/utils/introspection/ERC165.sol


    // OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

    pragma solidity ^0.8.0;


    /**
    * @dev Implementation of the {IERC165} interface.
    *
    * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
    * for the additional interface id that will be supported. For example:
    *
    * ```solidity
    * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
    * }
    * ```
    *
    * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
    */
    abstract contract ERC165 is IERC165 {
        /**
        * @dev See {IERC165-supportsInterface}.
        */
        function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
            return interfaceId == type(IERC165).interfaceId;
        }
    }

    // File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


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

    // File: @openzeppelin/contracts/utils/Context.sol


    // OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

    pragma solidity ^0.8.0;

    /**
    * @dev Provides information about the current execution context, including the
    * sender of the transaction and its data. While these are generally available
    * via msg.sender and msg.data, they should not be accessed in such a direct
    * manner, since when dealing with meta-transactions the account sending and
    * paying for execution may not be the actual sender (as far as an application
    * is concerned).
    *
    * This contract is only required for intermediate, library-like contracts.
    */
    abstract contract Context {
        function _msgSender() internal view virtual returns (address) {
            return msg.sender;
        }

        function _msgData() internal view virtual returns (bytes calldata) {
            return msg.data;
        }
    }

    // File: @openzeppelin/contracts/utils/Strings.sol


    // OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

    pragma solidity ^0.8.0;

    /**
    * @dev String operations.
    */
    library Strings {
        bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

        /**
        * @dev Converts a `uint256` to its ASCII `string` decimal representation.
        */
        function toString(uint256 value) internal pure returns (string memory) {
            // Inspired by OraclizeAPI's implementation - MIT licence
            // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

            if (value == 0) {
                return "0";
            }
            uint256 temp = value;
            uint256 digits;
            while (temp != 0) {
                digits++;
                temp /= 10;
            }
            bytes memory buffer = new bytes(digits);
            while (value != 0) {
                digits -= 1;
                buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
                value /= 10;
            }
            return string(buffer);
        }

        /**
        * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
        */
        function toHexString(uint256 value) internal pure returns (string memory) {
            if (value == 0) {
                return "0x00";
            }
            uint256 temp = value;
            uint256 length = 0;
            while (temp != 0) {
                length++;
                temp >>= 8;
            }
            return toHexString(value, length);
        }

        /**
        * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
        */
        function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
            bytes memory buffer = new bytes(2 * length + 2);
            buffer[0] = "0";
            buffer[1] = "x";
            for (uint256 i = 2 * length + 1; i > 1; --i) {
                buffer[i] = _HEX_SYMBOLS[value & 0xf];
                value >>= 4;
            }
            require(value == 0, "Strings: hex length insufficient");
            return string(buffer);
        }
    }

    // File: @openzeppelin/contracts/utils/Address.sol


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

    // File: @openzeppelin/contracts/token/ERC721/ERC721.sol


    // OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/ERC721.sol)

    pragma solidity ^0.8.0;








    /**
    * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
    * the Metadata extension, but not including the Enumerable extension, which is available separately as
    * {ERC721Enumerable}.
    */
    contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
        using Address for address;
        using Strings for uint256;

        // Token name
        string private _name;

        // Token symbol
        string private _symbol;

        // Mapping from token ID to owner address
        mapping(uint256 => address) private _owners;

        // Mapping owner address to token count
        mapping(address => uint256) private _balances;

        // Mapping from token ID to approved address
        mapping(uint256 => address) private _tokenApprovals;

        // Mapping from owner to operator approvals
        mapping(address => mapping(address => bool)) private _operatorApprovals;

        /**
        * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
        */
        constructor(string memory name_, string memory symbol_) {
            _name = name_;
            _symbol = symbol_;
        }

        /**
        * @dev See {IERC165-supportsInterface}.
        */
        function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
            return
                interfaceId == type(IERC721).interfaceId ||
                interfaceId == type(IERC721Metadata).interfaceId ||
                super.supportsInterface(interfaceId);
        }

        /**
        * @dev See {IERC721-balanceOf}.
        */
        function balanceOf(address owner) public view virtual override returns (uint256) {
            require(owner != address(0), "ERC721: balance query for the zero address");
            return _balances[owner];
        }

        /**
        * @dev See {IERC721-ownerOf}.
        */
        function ownerOf(uint256 tokenId) public view virtual override returns (address) {
            address owner = _owners[tokenId];
            require(owner != address(0), "ERC721: owner query for nonexistent token");
            return owner;
        }

        /**
        * @dev See {IERC721Metadata-name}.
        */
        function name() public view virtual override returns (string memory) {
            return _name;
        }

        /**
        * @dev See {IERC721Metadata-symbol}.
        */
        function symbol() public view virtual override returns (string memory) {
            return _symbol;
        }

        /**
        * @dev See {IERC721Metadata-tokenURI}.
        */
        function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
            require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

            string memory baseURI = _baseURI();
            return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
        }

        /**
        * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
        * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
        * by default, can be overriden in child contracts.
        */
        function _baseURI() internal view virtual returns (string memory) {
            return "";
        }

        /**
        * @dev See {IERC721-approve}.
        */
        function approve(address to, uint256 tokenId) public virtual override {
            address owner = ERC721.ownerOf(tokenId);
            require(to != owner, "ERC721: approval to current owner");

            require(
                _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
                "ERC721: approve caller is not owner nor approved for all"
            );

            _approve(to, tokenId);
        }

        /**
        * @dev See {IERC721-getApproved}.
        */
        function getApproved(uint256 tokenId) public view virtual override returns (address) {
            require(_exists(tokenId), "ERC721: approved query for nonexistent token");

            return _tokenApprovals[tokenId];
        }

        /**
        * @dev See {IERC721-setApprovalForAll}.
        */
        function setApprovalForAll(address operator, bool approved) public virtual override {
            _setApprovalForAll(_msgSender(), operator, approved);
        }

        /**
        * @dev See {IERC721-isApprovedForAll}.
        */
        function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
            return _operatorApprovals[owner][operator];
        }

        /**
        * @dev See {IERC721-transferFrom}.
        */
        function transferFrom(
            address from,
            address to,
            uint256 tokenId
        ) public virtual override {
            //solhint-disable-next-line max-line-length
            require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

            _transfer(from, to, tokenId);
        }

        /**
        * @dev See {IERC721-safeTransferFrom}.
        */
        function safeTransferFrom(
            address from,
            address to,
            uint256 tokenId
        ) public virtual override {
            safeTransferFrom(from, to, tokenId, "");
        }

        /**
        * @dev See {IERC721-safeTransferFrom}.
        */
        function safeTransferFrom(
            address from,
            address to,
            uint256 tokenId,
            bytes memory _data
        ) public virtual override {
            require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
            _safeTransfer(from, to, tokenId, _data);
        }

        /**
        * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
        * are aware of the ERC721 protocol to prevent tokens from being forever locked.
        *
        * `_data` is additional data, it has no specified format and it is sent in call to `to`.
        *
        * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
        * implement alternative mechanisms to perform token transfer, such as signature-based.
        *
        * Requirements:
        *
        * - `from` cannot be the zero address.
        * - `to` cannot be the zero address.
        * - `tokenId` token must exist and be owned by `from`.
        * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
        *
        * Emits a {Transfer} event.
        */
        function _safeTransfer(
            address from,
            address to,
            uint256 tokenId,
            bytes memory _data
        ) internal virtual {
            _transfer(from, to, tokenId);
            require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
        }

        /**
        * @dev Returns whether `tokenId` exists.
        *
        * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
        *
        * Tokens start existing when they are minted (`_mint`),
        * and stop existing when they are burned (`_burn`).
        */
        function _exists(uint256 tokenId) internal view virtual returns (bool) {
            return _owners[tokenId] != address(0);
        }

        /**
        * @dev Returns whether `spender` is allowed to manage `tokenId`.
        *
        * Requirements:
        *
        * - `tokenId` must exist.
        */
        function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
            require(_exists(tokenId), "ERC721: operator query for nonexistent token");
            address owner = ERC721.ownerOf(tokenId);
            return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
        }

        /**
        * @dev Safely mints `tokenId` and transfers it to `to`.
        *
        * Requirements:
        *
        * - `tokenId` must not exist.
        * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
        *
        * Emits a {Transfer} event.
        */
        function _safeMint(address to, uint256 tokenId) internal virtual {
            _safeMint(to, tokenId, "");
        }

        /**
        * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
        * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
        */
        function _safeMint(
            address to,
            uint256 tokenId,
            bytes memory _data
        ) internal virtual {
            _mint(to, tokenId);
            require(
                _checkOnERC721Received(address(0), to, tokenId, _data),
                "ERC721: transfer to non ERC721Receiver implementer"
            );
        }

        /**
        * @dev Mints `tokenId` and transfers it to `to`.
        *
        * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
        *
        * Requirements:
        *
        * - `tokenId` must not exist.
        * - `to` cannot be the zero address.
        *
        * Emits a {Transfer} event.
        */
        function _mint(address to, uint256 tokenId) internal virtual {
            require(to != address(0), "ERC721: mint to the zero address");
            require(!_exists(tokenId), "ERC721: token already minted");

            _beforeTokenTransfer(address(0), to, tokenId);

            _balances[to] += 1;
            _owners[tokenId] = to;

            emit Transfer(address(0), to, tokenId);

            _afterTokenTransfer(address(0), to, tokenId);
        }

        /**
        * @dev Destroys `tokenId`.
        * The approval is cleared when the token is burned.
        *
        * Requirements:
        *
        * - `tokenId` must exist.
        *
        * Emits a {Transfer} event.
        */
        function _burn(uint256 tokenId) internal virtual {
            address owner = ERC721.ownerOf(tokenId);

            _beforeTokenTransfer(owner, address(0), tokenId);

            // Clear approvals
            _approve(address(0), tokenId);

            _balances[owner] -= 1;
            delete _owners[tokenId];

            emit Transfer(owner, address(0), tokenId);

            _afterTokenTransfer(owner, address(0), tokenId);
        }

        /**
        * @dev Transfers `tokenId` from `from` to `to`.
        *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
        *
        * Requirements:
        *
        * - `to` cannot be the zero address.
        * - `tokenId` token must be owned by `from`.
        *
        * Emits a {Transfer} event.
        */
        function _transfer(
            address from,
            address to,
            uint256 tokenId
        ) internal virtual {
            require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
            require(to != address(0), "ERC721: transfer to the zero address");

            _beforeTokenTransfer(from, to, tokenId);

            // Clear approvals from the previous owner
            _approve(address(0), tokenId);

            _balances[from] -= 1;
            _balances[to] += 1;
            _owners[tokenId] = to;

            emit Transfer(from, to, tokenId);

            _afterTokenTransfer(from, to, tokenId);
        }

        /**
        * @dev Approve `to` to operate on `tokenId`
        *
        * Emits a {Approval} event.
        */
        function _approve(address to, uint256 tokenId) internal virtual {
            _tokenApprovals[tokenId] = to;
            emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
        }

        /**
        * @dev Approve `operator` to operate on all of `owner` tokens
        *
        * Emits a {ApprovalForAll} event.
        */
        function _setApprovalForAll(
            address owner,
            address operator,
            bool approved
        ) internal virtual {
            require(owner != operator, "ERC721: approve to caller");
            _operatorApprovals[owner][operator] = approved;
            emit ApprovalForAll(owner, operator, approved);
        }

        /**
        * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
        * The call is not executed if the target address is not a contract.
        *
        * @param from address representing the previous owner of the given token ID
        * @param to target address that will receive the tokens
        * @param tokenId uint256 ID of the token to be transferred
        * @param _data bytes optional data to send along with the call
        * @return bool whether the call correctly returned the expected magic value
        */
        function _checkOnERC721Received(
            address from,
            address to,
            uint256 tokenId,
            bytes memory _data
        ) private returns (bool) {
            if (to.isContract()) {
                try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                    return retval == IERC721Receiver.onERC721Received.selector;
                } catch (bytes memory reason) {
                    if (reason.length == 0) {
                        revert("ERC721: transfer to non ERC721Receiver implementer");
                    } else {
                        assembly {
                            revert(add(32, reason), mload(reason))
                        }
                    }
                }
            } else {
                return true;
            }
        }

        /**
        * @dev Hook that is called before any token transfer. This includes minting
        * and burning.
        *
        * Calling conditions:
        *
        * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
        * transferred to `to`.
        * - When `from` is zero, `tokenId` will be minted for `to`.
        * - When `to` is zero, ``from``'s `tokenId` will be burned.
        * - `from` and `to` are never both zero.
        *
        * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
        */
        function _beforeTokenTransfer(
            address from,
            address to,
            uint256 tokenId
        ) internal virtual {}

        /**
        * @dev Hook that is called after any transfer of tokens. This includes
        * minting and burning.
        *
        * Calling conditions:
        *
        * - when `from` and `to` are both non-zero.
        * - `from` and `to` are never both zero.
        *
        * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
        */
        function _afterTokenTransfer(
            address from,
            address to,
            uint256 tokenId
        ) internal virtual {}
    }

    // File: @openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol


    // OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

    pragma solidity ^0.8.0;



    /**
    * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
    * enumerability of all the token ids in the contract as well as all token ids owned by each
    * account.
    */
    abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
        // Mapping from owner to list of owned token IDs
        mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

        // Mapping from token ID to index of the owner tokens list
        mapping(uint256 => uint256) private _ownedTokensIndex;

        // Array with all token ids, used for enumeration
        uint256[] private _allTokens;

        // Mapping from token id to position in the allTokens array
        mapping(uint256 => uint256) private _allTokensIndex;

        /**
        * @dev See {IERC165-supportsInterface}.
        */
        function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
            return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
        }

        /**
        * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
        */
        function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
            require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
            return _ownedTokens[owner][index];
        }

        /**
        * @dev See {IERC721Enumerable-totalSupply}.
        */
        function totalSupply() public view virtual override returns (uint256) {
            return _allTokens.length;
        }

        /**
        * @dev See {IERC721Enumerable-tokenByIndex}.
        */
        function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
            require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
            return _allTokens[index];
        }

        /**
        * @dev Hook that is called before any token transfer. This includes minting
        * and burning.
        *
        * Calling conditions:
        *
        * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
        * transferred to `to`.
        * - When `from` is zero, `tokenId` will be minted for `to`.
        * - When `to` is zero, ``from``'s `tokenId` will be burned.
        * - `from` cannot be the zero address.
        * - `to` cannot be the zero address.
        *
        * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
        */
        function _beforeTokenTransfer(
            address from,
            address to,
            uint256 tokenId
        ) internal virtual override {
            super._beforeTokenTransfer(from, to, tokenId);

            if (from == address(0)) {
                _addTokenToAllTokensEnumeration(tokenId);
            } else if (from != to) {
                _removeTokenFromOwnerEnumeration(from, tokenId);
            }
            if (to == address(0)) {
                _removeTokenFromAllTokensEnumeration(tokenId);
            } else if (to != from) {
                _addTokenToOwnerEnumeration(to, tokenId);
            }
        }

        /**
        * @dev Private function to add a token to this extension's ownership-tracking data structures.
        * @param to address representing the new owner of the given token ID
        * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
        */
        function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
            uint256 length = ERC721.balanceOf(to);
            _ownedTokens[to][length] = tokenId;
            _ownedTokensIndex[tokenId] = length;
        }

        /**
        * @dev Private function to add a token to this extension's token tracking data structures.
        * @param tokenId uint256 ID of the token to be added to the tokens list
        */
        function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
            _allTokensIndex[tokenId] = _allTokens.length;
            _allTokens.push(tokenId);
        }

        /**
        * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
        * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
        * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
        * This has O(1) time complexity, but alters the order of the _ownedTokens array.
        * @param from address representing the previous owner of the given token ID
        * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
        */
        function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
            // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
            // then delete the last slot (swap and pop).

            uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
            uint256 tokenIndex = _ownedTokensIndex[tokenId];

            // When the token to delete is the last token, the swap operation is unnecessary
            if (tokenIndex != lastTokenIndex) {
                uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

                _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
                _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
            }

            // This also deletes the contents at the last position of the array
            delete _ownedTokensIndex[tokenId];
            delete _ownedTokens[from][lastTokenIndex];
        }

        /**
        * @dev Private function to remove a token from this extension's token tracking data structures.
        * This has O(1) time complexity, but alters the order of the _allTokens array.
        * @param tokenId uint256 ID of the token to be removed from the tokens list
        */
        function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
            // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
            // then delete the last slot (swap and pop).

            uint256 lastTokenIndex = _allTokens.length - 1;
            uint256 tokenIndex = _allTokensIndex[tokenId];

            // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
            // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
            // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
            uint256 lastTokenId = _allTokens[lastTokenIndex];

            _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

            // This also deletes the contents at the last position of the array
            delete _allTokensIndex[tokenId];
            _allTokens.pop();
        }
    }
    // File: contracts/Cubeless.sol


    pragma solidity ^0.8.7;


    abstract contract ERC2981Collection is IERC2981 {

    // ERC165
    // _setRoyalties(address,uint256) => 0x40a04a5a
    // royaltyInfo(uint256,uint256) => 0x2a55205a
    // ERC2981Collection => 0x6af56a00

    address private royaltyAddress;
    uint256 private royaltyPercent;

    // Set to be internal function _setRoyalties
    // _setRoyalties(address,uint256) => 0x40a04a5a
    function _setRoyalties(address _receiver, uint256 _percentage) internal {
        royaltyAddress = _receiver;
        royaltyPercent = _percentage;
    }

    // Override for royaltyInfo(uint256, uint256)
    // royaltyInfo(uint256,uint256) => 0x2a55205a
    /*
    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view override(IERC2981) virtual returns (
        address receiver,
        uint256 royaltyAmount
    ) {
        receiver = royaltyAddress;

        // This sets percentages by price * percentage / 100
        royaltyAmount = _salePrice * royaltyPercent / 100;
    }
    */
    }






    /// owner:    𝗪𝗛𝗜𝗧𝗘𝗖𝗨𝗕𝗘𝗟𝗘𝗦𝗦 - 𝗦𝗬𝗗𝗡𝗘𝗬 - 𝗔𝗨𝗦𝗧𝗥𝗔𝗟𝗜𝗔
    /// author:   pamuk.eth
    /// White Cubeless Pty Ltd is a blockchain technology company registered in Australia. All rights reserved by White Cubeless Pty Ltd. @2022    
    /// Live Version -
    
    
    /**
    * @dev Heavily customized ERC721 supporting,
    *
    * - Multiple drop management
    * - Contingent transactions
    * - Reservation
    * - Owner mint 
    * - URI recycling
    * - Merkletree Presale
    * - Drop-Wise Royalties
    * - PublicSale
    * - 3 Way Balance of Powers
    */

    contract WhiteCubeless is ERC721Enumerable,ERC2981Collection  {
        
        //𝗩𝗔𝗥𝗜𝗔𝗕𝗟𝗘 𝗗𝗘𝗖𝗟𝗔𝗥𝗔𝗧𝗜𝗢𝗡𝗦:
        

        //𝗘𝗩𝗘𝗡𝗧𝗦

        /// @dev emitted after mint
        event Mint(address indexed _to, uint256 indexed _tokenId, uint256 indexed _artworkId);

        /// @dev emitted after burn
        event Burn( uint256 indexed _tokenId, uint256 indexed _artworkId);

        /// @dev freezes metadata for marketplaces
        event PermanentURI( string _value, uint256 indexed _id);

        /// @dev emitted after artwork adeed
        event ArtworkAdded( string uri, uint256  _ArtworkId,uint256  _Limit);

        //𝗚𝗟𝗢𝗕𝗔𝗟
        
        uint256 constant public ONE_MILLION = 1_000_000;
        

        //𝗩𝗘𝗥𝗦𝗜𝗢𝗡𝗜𝗡𝗚
        
        /// @dev this is to make sure any tokenID generated by WhiteCubeless is unique even the contract is different.
        uint256 constant public WhiteCubelessGalleryVersion  = 1;
        
        /// @dev assign first ID
        uint256  public nextartworkId = WhiteCubelessGalleryVersion*ONE_MILLION;

        
        //𝗚𝗔𝗟𝗟𝗘𝗥𝗬 𝗘𝗗𝗜𝗧𝗜𝗢𝗡𝗦
        
        /// @dev drop struct
        struct Artwork {
            string artworkBaseIpfsURI; // 'ipfs://CID/'
            address royaltyReceiver;   // default assigned in init
            uint256 minted;            // already minted + reserved
            uint256 count;             // minted + reserved + burned
            uint256 artworkLimit;      // max limit 
            uint256 royaltiesInBP;     // default assigned in init
            uint256 artworkPrice;      // init assignment, can change later
            uint256 reserved;          // count of reserved
            bool locked;               // once locked nobody can change royalty, URI and other ctirical info, locking is irreversible
            bool paused;               // pause for minting
            bool presale;              // init assignment
            uint256[] available_list;  // generated in init for URI recycling [1,2,3] - [0,2,3]
        }

        
        mapping(uint256 => Artwork) internal artworks; 
        mapping(uint256 => bool) internal artworkCheck;
        mapping(uint256 => uint256) internal tokenIdToArtworkId;
        mapping(uint256 => uint256) internal tokenIdToIpfsHash;
        mapping(uint256 => uint256[]) internal artworkIdToTokenIds;
        
        mapping (bytes32 => uint256) internal whiteListLimits;
        
        mapping (uint256 => bool) public paidWithCard;
        mapping (uint256 => uint256) public paidDate;
        mapping (uint256 => bool) public burnDisabled;
        mapping (uint256 => bool) public isBurned;

        //𝗣𝗥𝗜𝗩𝗜𝗟𝗘𝗚𝗘𝗦


        mapping(address => bool) public isOperator;
        mapping(address => bool) public isGalleryReserver;

        address public admin;
        address public gateKeeperOne;
        address public gateKeeperTwo;
        address public defaultRoyaltyReceiver;
        bytes32 public root;

        bool public gateKeeperOneAllowMinting=false;
        bool public gateKeeperTwoAllowMinting=false;
        bool public gateKeeperOneAppointed=false;
        bool public gateKeeperTwoAppointed=false;
        bool public gateKeeperOneChangeAdmin=false;
        bool public gateKeeperTwoChangeAdmin=false;
        
        //𝗥𝗢𝗬𝗔𝗟𝗧𝗜𝗘𝗦

        
        uint256 public defaultRoyaltiesInBP = 800;      // 8%
        uint256 public MINT_HARD_LIMIT=10;             // cannot mint more than 10
        uint256 public WHITELIST_PER_ACCOUNT_LIMIT=5;  // each whitelisted account can get 5 pieces before the whitelist reset
        uint256 public currentMappingVersion;          // resettable mapping
        uint256 public DAY_LIMIT=90;                   // cannot burn a credit card sale after this limit
        
        //𝗠𝗢𝗗𝗜𝗙𝗜𝗘𝗥𝗦

        /// @dev checks if the tokenId exists 
        modifier onlyValidTokenId(uint256 _tokenId) 
        {
            
            require(_exists(_tokenId));
            _;
        }

        /// @dev checks if transaction is direct or from a contract
        modifier onlyAccounts () {
            require(msg.sender == tx.origin);
            _;
        }
        
        /// @dev checks the lock status of the artwork
        modifier onlyUnlocked(uint256 _artworkId) 
        {
            

            require(!artworks[_artworkId].locked);
            _;
        }

        /// @dev checks if the minting is paused or not
        modifier onlyUnPaused(uint256 _artworkId) 
        {

            require(!artworks[_artworkId].paused);
            _;
        }

        /// @dev only called by admin
        modifier onlyAdmin() 
        {

            require(msg.sender == admin);
            _;
        }

        /// @dev only called by admin and operator
        modifier onlyOperator() 
        {
            
            require(isOperator[msg.sender] || msg.sender==admin );
            _;
        }

        /// @dev only called by admin and operator and reserver
        modifier onlyGalleryReserver() 
        {
            // checks if the msg sender is reserver or not
            
            require((isGalleryReserver[msg.sender]) || (isOperator[msg.sender]) || (msg.sender==admin));
            _;
        }
        
        /// @dev only called by GateKeeperOne
        modifier onlyGateKeeperOne() 
        {
            require(gateKeeperOneAppointed);

            
            require(msg.sender == gateKeeperOne);
            _;
        }

        /// @dev only called by GateKeeperTwo
        modifier onlyGateKeeperTwo() 
        {
            
            require(gateKeeperTwoAppointed);

            require(msg.sender == gateKeeperTwo);
            _;
        }

        /// @dev only called by GateKeeperTwo and GateKeeperOne, makes sure they are appointed as well. 
        modifier onlyGateKeeper() 
        {
            // checks if the msg sender is gatekeeper or not
            require((msg.sender == gateKeeperOne) || (msg.sender == gateKeeperTwo));
            require(gateKeeperTwoAppointed);
            require(gateKeeperOneAppointed);

            _;
        }

        constructor(string memory _tokenName, string memory _tokenSymbol, bytes32 merkleroot) ERC721(_tokenName, _tokenSymbol)  
        {
            admin = msg.sender;
            
            
            root = merkleroot;

            //gatekeepers are  admin in the initial deployment
            gateKeeperOne=msg.sender;
            gateKeeperTwo=msg.sender;

            //minting is toggled to true
            gateKeeperOneAllowMinting=true;
            gateKeeperTwoAllowMinting=true;

            //gatekeepers can change admin if they have unanymous decision
            gateKeeperOneChangeAdmin=false;
            gateKeeperTwoChangeAdmin=false;
            
            defaultRoyaltyReceiver=msg.sender;
            
            //𝗔𝗙𝗧𝗘𝗥 𝗗𝗘𝗣𝗟𝗢𝗬 𝗧𝗢𝗗𝗢:
            // 1- Appoint GateKeeper - Keep in Mind Admin Can Only Appoint a GateKeeper Once

        }


        // 𝗔𝗗𝗠𝗜𝗡 𝗣𝗥𝗜𝗩𝗜𝗟𝗔𝗚𝗘𝗦

        /// @dev change admin to a new account
        function changeAdmin(address _address)  onlyAdmin public
        {

            admin = _address;
            

        }
        
        /// @dev adds Operator which can carry daily hot wallet duties - admin only
        function addOperator(address _address)  onlyAdmin public
        {
            isOperator[_address] = true;
        }

        /// @dev remove privilages - Admin only
        function removeOperator(address _address)  onlyAdmin public
        {
            isOperator[_address] = false;
        }

        /// @dev add Gallery Reserver can only reserve artwork - Operator        
        function addGalleryReserver(address _address)  onlyOperator public
        {
            isGalleryReserver[_address] = true;
        }

        /// @dev remove privilages - Operator 
        function removeGalleryReserver(address _address)  onlyOperator public
        {
            isGalleryReserver[_address] = false;
        }

        /// @dev GAtekeepers can stop minting, minting is on by default, has to be appointed before first minting
        function appointGateKeeperOne(address _address)  onlyAdmin public
        {
            require (gateKeeperOneAppointed== false);
            gateKeeperOne= _address;
            gateKeeperOneAppointed=true;

        }

        /// @dev GAtekeepers can stop minting, minting is on by default, has to be appointed before first minting
        function appointGateKeeperTwo(address _address)  onlyAdmin public
        {

            require (gateKeeperTwoAppointed== false);
            gateKeeperTwo= _address;
            gateKeeperTwoAppointed=true;
        }

        /// @dev Admin can withdraw ETH to admin account
        function withdrawAll() public onlyAdmin 
        {
            uint256 balance = address(this).balance;
            require(balance > 0);

            _withdraw(admin, balance);
            
        }

        /// @dev withdraw function
        function _withdraw(address _address, uint256 _amount) private 
        {
            (bool success, ) = _address.call{value: _amount}("");
            require(success);
        }

        //𝗚𝗔𝗧𝗘𝗞𝗘𝗘𝗣𝗘𝗥 𝗣𝗥𝗜𝗩𝗜𝗟𝗘𝗚𝗘𝗦

        /// @dev Start/Stop Minting, On by default
        function gateKeeperOneToggleMinting(bool toggle_bool)  onlyGateKeeperOne public
        {
            gateKeeperOneAllowMinting= toggle_bool;
        
        }

        /// @dev Start/Stop Minting, On by default
        function gateKeeperTwoToggleMinting(bool toggle_bool)  onlyGateKeeperTwo public
        {
            gateKeeperTwoAllowMinting= toggle_bool;
        
        }

        /// @dev only Gatekeeper  can change itself 
        function gateKeeperOneChangeAddress(address _address)  onlyGateKeeperOne public
        {
            gateKeeperOne= _address;


        }
        
        /// @dev only Gatekeeper  can change itself
        function gateKeeperTwoChangeAddress(address _address)  onlyGateKeeperTwo public
        {
            gateKeeperTwo= _address;

        }

        /// @dev initiate admin recovery, true to vote to change admin
        function gateKeeperOneToggleAdminChange(bool toggle_bool)  onlyGateKeeperOne public
        {
            gateKeeperOneChangeAdmin= toggle_bool;
        
        }

        /// @dev initiate admin recovery, true to vote to change admin
        function gateKeeperTwoToggleAdminChange(bool toggle_bool)  onlyGateKeeperTwo public
        {
            gateKeeperTwoChangeAdmin= toggle_bool;
        
        }

        /// @dev if both admin change votes are true, this funtion assigns a new admin
        function gateKeeperAdminOverride(address _address)  onlyGateKeeper public
        {
            //gatekeepers can change admin if they agree to do so
            require(gateKeeperTwoChangeAdmin,"1");
            require(gateKeeperOneChangeAdmin,"2");

            gateKeeperTwoChangeAdmin=false;
            gateKeeperOneChangeAdmin=false;

            admin = _address;
            
        }

        //𝗢𝗣𝗘𝗥𝗔𝗧𝗜𝗢𝗡𝗔𝗟 𝗪𝗛𝗜𝗧𝗘𝗟𝗜𝗦𝗧𝗘𝗗 𝗙𝗨𝗡𝗖𝗧𝗜𝗢𝗡𝗦

        /// @dev change multiple mint per artwork
        function updateMintHardLimit(uint256 _hardlimit) onlyOperator public 
        {
            MINT_HARD_LIMIT = _hardlimit;
        }
        
        /// @dev freeze metadata of the multiple tokens if neccesary, contact [email protected] if you need  Frozen badge in marketplaces 
        function freezeMetadataList(uint256[] memory _tokenIds)  onlyOperator  public
        {

            require (_tokenIds.length < 20, "1");
            
            for (uint i; i<_tokenIds.length;) 
            {
                uint256 tokenId=_tokenIds[i];
                require(_exists(tokenId), "2");
                emit PermanentURI(tokenURI(tokenId),tokenId);
                unchecked { ++i ;}

            }

        }
        /// @dev changes the royalty receiver, only applicable for new artworks
        function changeDefaultRoyaltyReceiver(address _address)  onlyOperator public
        {
            defaultRoyaltyReceiver = _address;
        }
        
        /// @dev merkleroot for presales, only one root at a time
        function setMerkleRoot(bytes32 merkleroot)  onlyOperator  public 
        {
            root = merkleroot;
        }

        /// @dev max tokens a whitelisted account can mint
        function setWhitelistPerAccount(uint256 maximum_per_account)  onlyOperator  public 
        {
            WHITELIST_PER_ACCOUNT_LIMIT = maximum_per_account;
        }

        /// @dev after day_limit, contract can't burn transferred tokens
        function setCCDayLimit(uint256 day_limit)  onlyOperator  public 
        {
            require(day_limit<=90);
            DAY_LIMIT = day_limit;
        }

        /// @dev multiple disables remote burning for tokens, immediately, triggered manually when payment is cleared
        function disableMultipleCreditCardBurn(uint256[] memory _tokenIds, uint256 check_len) onlyOperator public
        {
            uint256 q1=_tokenIds.length;
            
            require(q1==check_len);

            for (uint i; i < check_len;) 
            {
                disableCreditCardBurn(_tokenIds[i]);
                unchecked { ++i ;}

            }
        }

        /// @dev  disables remote burning for tokens, immediately, triggered when payment is cleared, contact [email protected] to secure your token if purchased via traditional methods
        function disableCreditCardBurn(uint _tokenId)   onlyOperator public 
        {
            burnDisabled[_tokenId]=true;
        }
        
        /// @dev add multiple artworks
        function addMultipleArtwork(uint256[] memory _artworkLimits,uint256[] memory _prices,string[] calldata _artworkBaseIpfsURIs,bool[] memory _presales,uint256 len_check) onlyOperator public
        {

            uint256 q2=_artworkLimits.length;
            uint256 q3=_prices.length;
            uint256 q4=_artworkBaseIpfsURIs.length;
            uint256 q5=_presales.length;

            require(q2==len_check,"2");
            require(q3==len_check,"3");
            require(q4==len_check,"4");
            require(q5==len_check,"5");


            for (uint i; i < len_check;) 
            {
                addArtwork( _artworkLimits[i],_prices[i], _artworkBaseIpfsURIs[i],_presales[i]);
                unchecked { ++i ;}

            }

        }

        /// @dev add artwork , once added cannot be undone
        function addArtwork(uint256 _artworkLimit,uint256 _price, string calldata _artworkBaseIpfsURI,bool presale)  onlyOperator public
        {
            uint256 artworkId = nextartworkId;
            require(artworkCheck[artworkId]==false,"1");

            artworks[artworkId].artworkLimit = _artworkLimit;
            artworks[artworkId].artworkPrice=_price;
            artworkCheck[artworkId]=true;
            //
            artworks[artworkId].royaltyReceiver=defaultRoyaltyReceiver;
            artworks[artworkId].royaltiesInBP=defaultRoyaltiesInBP;
            artworks[artworkId].presale=presale;

            artworks[artworkId].minted=0;
            artworks[artworkId].locked=false;
            artworks[artworkId].artworkBaseIpfsURI = _artworkBaseIpfsURI;
            artworks[artworkId].available_list=new uint[](_artworkLimit);
            for (uint i; i < _artworkLimit;)
            {
                artworks[artworkId].available_list[i]=i+1;
                unchecked { ++i ;}

            } 

            emit ArtworkAdded( _artworkBaseIpfsURI, artworkId,_artworkLimit);
            nextartworkId = nextartworkId+1; 
            
        }

        /// @dev locks an artwork for editing, manually triggered after edition is sold out
        function updateArtworkLock(uint256 _artworkId,bool lock_bool)  onlyOperator   onlyUnlocked(_artworkId) public
        {
            //when locked, nobody can unlock therefore the whole structure is frozen
            artworks[_artworkId].locked = lock_bool;
        }


        /// @dev pauses artwork for minting
        function updateArtworkPause(uint256 _artworkId,bool pause_bool)  onlyOperator  public
        {
            //when locked, nobody can unlock therefore the whole structure is frozen
            artworks[_artworkId].paused = pause_bool;
        }

        /// @dev multiple IPFS change in case there is a problem with the IPFS supplied in init, cannot be used after locking
        function updateMultipleArtworkBaseIpfsURI(uint256[] calldata _artworkIds,string[] calldata _artworkBaseIpfsURIs, uint256 check_len) onlyOperator public
        {
            uint256 q1=_artworkBaseIpfsURIs.length;
            uint256 q2=_artworkIds.length;
            
            require(q1==check_len,"1");
            require(q2==check_len,"2");

            for (uint i; i < check_len;) 
            {
                updateArtworkBaseIpfsURI(_artworkIds[i], _artworkBaseIpfsURIs[i]);
                unchecked { ++i ;}

            }
        }

        /// @dev IPFS change in case there is a problem with the IPFS supplied in init, cannot be used after locking
        function updateArtworkBaseIpfsURI(uint256 _artworkId, string calldata _artworkBaseIpfsURI) onlyOperator onlyUnlocked(_artworkId) public 
        {
            artworks[_artworkId].artworkBaseIpfsURI = _artworkBaseIpfsURI;

        }
        
        /// @dev multiple price change in case there is a problem with the price supplied in init, cannot be used after locking
        function updateMultipleArtworkPrice(uint256[] calldata _artworkIds,uint256[] calldata _prices, uint256 check_len) onlyOperator public
        {
            uint256 q1=_prices.length;
            uint256 q2=_artworkIds.length;
            
            require(q1==check_len,"1");
            require(q2==check_len,"2");

            for (uint i ; i < check_len; ) 
            {
                updateArtworkPrice(_artworkIds[i], _prices[i]);
                unchecked { ++i ;}

            }
        }
        
        /// @dev  price change in case there is a problem with the price supplied in init, cannot be used after locking
        function updateArtworkPrice(uint256 _artworkId, uint256 _price) onlyOperator onlyUnlocked(_artworkId) public 
        {
            artworks[_artworkId].artworkPrice = _price;

        }

        /// @dev enable presale for an artwork on the fly
        function updateArtworkPresale(uint256 _artworkId, bool _presaleBool) onlyOperator onlyUnlocked(_artworkId) public 
        {
            artworks[_artworkId].presale = _presaleBool;
            
        }
        
        /// @dev  multiple change URI extension that comes after ipfs://{CID}/, last resort if there is a sequencing problem after recycling, cannot be done after lock
        function overrideMultipleTokenIPFSHash(uint256[] calldata _newHashs , uint256[] calldata _tokenIds, uint256 check_len) onlyOperator public
        {
            uint256 q1=_newHashs.length;
            uint256 q2=_tokenIds.length;
            
            require(q1==check_len,"1");
            require(q2==check_len,"2");

            for (uint i ; i < check_len; ) 
            {
                overrideTokenIPFSHash(_newHashs[i], _tokenIds[i]);
                unchecked { ++i ;}

            }
        }
        
        /// @dev  change URI extension that comes after ipfs://{CID}/, last resort if there is a sequencing problem after recycling, cannot be done after lock
        function overrideTokenIPFSHash(uint256 _newHash , uint256 _tokenId) onlyOperator public 
        {
            //check if artwork is locked
            require(_exists(_tokenId), "1");
            require(!artworks[tokenIdToArtworkId[_tokenId]].locked,"2");
            
            tokenIdToIpfsHash[_tokenId]=_newHash;

        }

        /// @dev  change available to mint array if there is a problem in sequencing, this applies for future mints
        function overrideAvailableArray(uint256 _artworkId,uint256[] calldata available_array  ) onlyOperator onlyUnlocked(_artworkId) public 
        {
            // jus tin case if available array mixes up
            require(available_array.length == artworks[_artworkId].available_list.length,"1");
            require(artworkCheck[_artworkId],"2");

            for (uint i; i < artworks[_artworkId].available_list.length;) 
            {
                artworks[_artworkId].available_list[i]=available_array[i];
                unchecked { ++i ;}

            }
        }
        
        /// @dev  royalty percentage  change for existing artworks
        function changeArtworkRoyaltiesInBP(uint256 _artworkId,uint256 _royaltiesInBP)  onlyOperator onlyUnlocked(_artworkId) public
        {
            artworks[_artworkId].royaltiesInBP = _royaltiesInBP;

        }

        /// @dev  royalty address  change for existing artworks
        function changeArtworkRoyaltyReceiver(uint256 _artworkId,address _royaltyReceiver)  onlyOperator onlyUnlocked(_artworkId) public
        {
            artworks[_artworkId].royaltyReceiver = _royaltyReceiver;

        }


        //𝗠𝗜𝗡𝗧𝗜𝗡𝗚

        /**
        * @dev mints a token for the gallery.
        *
        * Requirements:
        *
        * - `artwork` should be Unpaused.
        * - only operator can call
        *
        * Functionality:
        * - can mint reserved tokens 
        * - can mint credit card tokens where gallery can burn in 90 days if the payment is fraudulent
        * - can mint tokens for other OTC deals
        */
        function galleryMint(address _to, uint256 _artworkId, bool _freeze,uint256 quantity,bool credit_card_sale,bool reserved) onlyOperator onlyUnPaused(_artworkId) external returns (uint256[] memory) 
        {
            // if the sale is done via credit card, we reserve right to burn for 90days

            require(artworkCheck[_artworkId],"1");
            
            require(quantity<=MINT_HARD_LIMIT, "3");
            require(!artworks[_artworkId].locked , "4");
            require(gateKeeperOneAllowMinting , "5");
            require(gateKeeperOneAppointed, "6");
            require(gateKeeperTwoAllowMinting, "7");
            require(gateKeeperTwoAppointed, "8");
            
            if (reserved==false)
            {
                require(artworks[_artworkId].minted + quantity <= artworks[_artworkId].artworkLimit, "2");
            }
            
            if (reserved)
            {
                //in the mint we will increment minted 
                // we need to deduct from reserved and minted before hand so that minted will come to the correct quantuty
                require(artworks[_artworkId].reserved - quantity >= 0, "9"); //make sure it as actually reserved
                require(artworks[_artworkId].minted - quantity >= 0, "10"); //something wrong

            }
            
            uint[]    memory tokenIds =  new uint[](quantity);

            for (uint i ; i < quantity; ) 
            {
                if (reserved)
                {
                    artworks[_artworkId].reserved=artworks[_artworkId].reserved-1; // unreserve the minted
                    artworks[_artworkId].minted=artworks[_artworkId].minted-1; // unreserve the minted
                }
                
                uint tokenId=_mintToken(_to, _artworkId,_freeze);
                tokenIds[i]=tokenId;
                paidWithCard[tokenId]=credit_card_sale;
                paidDate[tokenId]=block.timestamp;
                unchecked { ++i ;}


            }
            return tokenIds;
        }
        
        /// @dev  reserves a token for future sale
        function galleryReserve( uint256 _artworkId,uint256 quantity) onlyGalleryReserver  external 
        {
            
            // can reserve while paused
            require(artworkCheck[_artworkId],"1");
            require(artworks[_artworkId].minted+quantity <= artworks[_artworkId].artworkLimit, "2");
            require(quantity<=MINT_HARD_LIMIT, "3");
            require(!artworks[_artworkId].locked , "4");
            require(gateKeeperOneAllowMinting , "5");
            require(gateKeeperOneAppointed, "6");
            require(gateKeeperTwoAllowMinting, "7");
            require(gateKeeperTwoAppointed, "8");

            //add the reserved and minted
            artworks[_artworkId].minted=artworks[_artworkId].minted+quantity;
            artworks[_artworkId].reserved=artworks[_artworkId].reserved+quantity;
            

        }

        /// @dev  unreserves a token for future sale
        function galleryUnReserve( uint256 _artworkId,uint256 quantity) onlyGalleryReserver external 
        {
            // if the sale is done via credit card, we reserve right to burn for 90days
            // can reserve while paused
            require(artworkCheck[_artworkId],"1");
            require(artworks[_artworkId].minted-quantity >= 0, "2");
            require(artworks[_artworkId].reserved-quantity >= 0, "3");
            require(quantity<=MINT_HARD_LIMIT, "4");
            require(!artworks[_artworkId].locked , "5");
            require(gateKeeperOneAllowMinting , "6");
            require(gateKeeperOneAppointed, "7");
            require(gateKeeperTwoAllowMinting, "8");
            require(gateKeeperTwoAppointed, "9");

            //sub the reserved and minted
            artworks[_artworkId].minted=artworks[_artworkId].minted-quantity;
            artworks[_artworkId].reserved=artworks[_artworkId].reserved-quantity;
            

        }

        /// @dev  public mint function where ETH is expected for delivery
        function publicSaleMint(uint256 _artworkId, bool _freeze,  uint256 quantity) public payable onlyAccounts onlyUnPaused(_artworkId)  returns (uint256[] memory) 
        {
            require(artworkCheck[_artworkId],"1");
            require(msg.value >=  artworks[_artworkId].artworkPrice*quantity, "2");
            require(artworks[_artworkId].artworkPrice>0, "3");
            require(quantity<=MINT_HARD_LIMIT, "4");
            require(artworks[_artworkId].minted+quantity <= artworks[_artworkId].artworkLimit, "5");
            require(!artworks[_artworkId].locked , "6");
            require(gateKeeperOneAllowMinting, "7");
            require(gateKeeperTwoAllowMinting, "8");
            require(gateKeeperOneAppointed, "9");
            require(gateKeeperTwoAppointed, "10");
            require(artworks[_artworkId].presale==false, "11");

            uint[]    memory tokenIds =  new uint[](quantity);
            
            for (uint i; i < quantity;) 
            {
                tokenIds[i]=_mintToken(msg.sender, _artworkId,_freeze);
                unchecked { ++i ;}

            }
            return tokenIds;
            

        }

        /// @dev  public presale mint function where ETH and whitelisting is expected for delivery
        function preSaleMint(uint256 _artworkId, bool _freeze, uint256 quantity, bytes32[] calldata proof) public payable onlyAccounts  onlyUnPaused(_artworkId) returns (uint256[] memory) 
        {
            require(artworkCheck[_artworkId],"1");
            require(msg.value >=  artworks[_artworkId].artworkPrice * quantity, "2");
            require(artworks[_artworkId].artworkPrice>0, "3");
            require(quantity<=MINT_HARD_LIMIT, "4");
            require(artworks[_artworkId].minted+quantity <= artworks[_artworkId].artworkLimit, "5");
            require(!artworks[_artworkId].locked , "6");
            require(gateKeeperOneAllowMinting, "7");
            require(gateKeeperTwoAllowMinting, "8");
            require(gateKeeperOneAppointed, "9");
            require(gateKeeperTwoAppointed, "10");
            require(artworks[_artworkId].presale==true, "11");

            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            require(MerkleProof.verify(proof, root, leaf),"12");
            uint256 limit=getWhiteListedLimit(msg.sender);
            uint256 new_limit=limit + quantity;
            require(new_limit<=WHITELIST_PER_ACCOUNT_LIMIT,"13");
            
            uint[]    memory tokenIds =  new uint[](quantity);
            
            _setLimit(msg.sender,new_limit);

            for (uint i ; i < quantity;) 
            {
                tokenIds[i]=_mintToken(msg.sender, _artworkId,_freeze);
                unchecked { ++i ;}

            }
            return tokenIds;
            

        }

        /// @dev seach for a non 0, unassigned ID and add it as extension, used for recycling the IPFS link
        function getNextAvailableExtId(uint256 _artworkId) internal  returns (bool found,uint256 ext_id) 
        {
            //loop the avialble
            //if it is not 0, break and return 
            // if 0
            ext_id=0;
            uint256[] storage avails=artworks[_artworkId].available_list;
            found=false;
            for (uint i ; i < avails.length;) 
            {
                uint256 val=artworks[_artworkId].available_list[i];
                if (val!=0)
                {
                    artworks[_artworkId].available_list[i]=0;
                    ext_id=val;
                    found=true;
                    break;
                }
                unchecked { ++i ;}

            }
            return (found,ext_id);

        }

        /// @dev all mint functions call this function
        function _mintToken(address _to, uint256 _artworkId, bool _freeze) internal returns (uint256 _tokenId) 
        {

            artworks[_artworkId].minted = artworks[_artworkId].minted + 1;
            artworks[_artworkId].count = artworks[_artworkId].count + 1;

            uint256 tokenIdToBe = (_artworkId * ONE_MILLION) + artworks[_artworkId].count;
            require(artworks[_artworkId].count<ONE_MILLION,"1");
            
            (bool found_,uint256 ext_id_)=getNextAvailableExtId(_artworkId);
            require(found_,"2");

            _mint(_to, tokenIdToBe);

            tokenIdToArtworkId[tokenIdToBe] = _artworkId;
            artworkIdToTokenIds[_artworkId].push(tokenIdToBe);
            tokenIdToIpfsHash[tokenIdToBe]=ext_id_;

            emit Mint(_to, tokenIdToBe, _artworkId);

            if (_freeze)
            {
                emit PermanentURI(tokenURI(tokenIdToBe),tokenIdToBe);
                //freeze it, OpenSea convention
        
            }
            
            return tokenIdToBe;
        }
        
        /// @dev string concetanation
        function append(string memory a, string memory  b) internal pure returns (string memory) 
        {

            return string(abi.encodePacked(a, b));

        }


        /// @dev overrided URI function where URI based on Artwork is returned
        function tokenURI(uint256 _tokenId) public view onlyValidTokenId(_tokenId) override returns (string memory) 
        {
            uint256 ipfsHash= tokenIdToIpfsHash[_tokenId];
            return append(artworks[tokenIdToArtworkId[_tokenId]].artworkBaseIpfsURI, Strings.toString(ipfsHash));
        }

        //BURNING

        /// @dev internal burn, deletes URI, reduces supply and sends the token to the 0x0. 
        /// If the token is sold via CC, can remote burn
        // If token is sold via ETH, only burn if Operator holds the token
        function burnTokens(uint256[] calldata _tokenIds, uint256 check_len) external  onlyOperator 
        {
            require(gateKeeperOneAllowMinting, "1");
            require(gateKeeperTwoAllowMinting, "2");
            require(gateKeeperOneAppointed, "3");
            require(gateKeeperTwoAppointed, "4");
            uint256 q1=_tokenIds.length;
            
            require(q1==check_len,"5");
            for (uint i ; i < q1;) 
            {
                if (paidWithCard[_tokenIds[i]])
                {
                    _creditCardBurn(_tokenIds[i]);
                }
                else
                {
                    _burnToken(_tokenIds[i],msg.sender);
                }
                unchecked { ++i ;}

            }
        }


        /// @dev burn function  resets the states
        function _burnToken(uint256 _tokenId,address msg_sender) internal 
        {
            require(_exists(_tokenId), "1");
            address token_owner = ERC721.ownerOf(_tokenId);
            require(msg_sender==token_owner ,"2");
            uint256 _artworkId=tokenIdToArtworkId[_tokenId];
            require(_artworkId!=0,"3");

            //get the hash of the token and equate it to a value other than 0
            uint256 ipfsHash=tokenIdToIpfsHash[_tokenId];
            artworks[_artworkId].minted = artworks[_artworkId].minted - 1;
            tokenIdToArtworkId[_tokenId] = 0;
            tokenIdToIpfsHash[_tokenId]=0;
            artworks[_artworkId].available_list[ipfsHash-1]=ipfsHash; //burned ID is available for recycling
            isBurned[_tokenId]=true;
            _burn(_tokenId);

            emit Burn(_tokenId,_artworkId);

        } 

        /// @dev burn function  that doesn't check ownership
        function _creditCardBurn(uint256 _tokenId) internal 
        {
            //function to burn the token if it is bought via credit card
            // this functionality is only valid for 90 days after mint and will be used a last resort against fraud
            // Please contact us via [email protected] if you to want to disable that earlier, you might be subject to KYC depending on the situation.

            //Note that this function is only callable if paidWithCard is true.
            // The only scenerio where this can happen is publicGalleryMint

            require(_exists(_tokenId), "1");
            require(paidWithCard[_tokenId], "2");
            require(block.timestamp-paidDate[_tokenId]<=DAY_LIMIT * 86400,"3");
            require(burnDisabled[_tokenId]==false,"4");
            uint256 ipfsHash=tokenIdToIpfsHash[_tokenId];

            uint256 _artworkId=tokenIdToArtworkId[_tokenId];
            require(_artworkId!=0,"5");

            artworks[_artworkId].minted = artworks[_artworkId].minted-1;
            tokenIdToArtworkId[_tokenId] = 0;
            tokenIdToIpfsHash[_tokenId]=0;
            artworks[_artworkId].available_list[ipfsHash-1]=ipfsHash; //burned ID is available for recycling
            isBurned[_tokenId]=true;

            _burn(_tokenId);

            emit Burn(_tokenId,_artworkId);

        } 





        //𝗥𝗢𝗬𝗔𝗟𝗧𝗜𝗘𝗦

        /// @dev EIP-2981 royalty override 
        function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view override returns (address receiver, uint256 royaltyAmount) 
        {
            address _royaltiesReceiver = artworks[tokenIdToArtworkId[_tokenId]].royaltyReceiver;
            uint256 _royaltiesinBPartwork = artworks[tokenIdToArtworkId[_tokenId]].royaltiesInBP;

            uint256 _royalties = _salePrice*_royaltiesinBPartwork/10000;
            return (_royaltiesReceiver, _royalties);
        }


        /// @notice Informs callers that this contract supports ERC2981
        /// this is for future usage, hope marketplaces can see our royalty declarations
        function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable,IERC165) returns (bool) 
        {
            return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
        }





        //𝗩𝗜𝗘𝗪 𝗙𝗨𝗡𝗖𝗧𝗜𝗢𝗡𝗦


        /// @dev gives artwork information
        function artworkTokenInfo(uint256 _artworkId) view public returns (uint256 minted, uint256 artworkLimit ,  bool locked,uint256 price,uint256 count,string memory artworkBaseIpfsURI,uint256 reserved) 
        {
            minted = artworks[_artworkId].minted;
            //minted includes both reserved and minted

            reserved = artworks[_artworkId].reserved;
            //to keep track of reserved, only deduct if reserve minted or unreserved
            artworkLimit = artworks[_artworkId].artworkLimit;
            locked=artworks[_artworkId].locked;
            price=artworks[_artworkId].artworkPrice;
            count=artworks[_artworkId].count;
            artworkBaseIpfsURI = artworks[_artworkId].artworkBaseIpfsURI;
        }

        /// @dev all tokens, burned ones are shown as 0 in the result
        function artworkShowAllTokens(uint256 _artworkId) public view returns (uint256[] memory)
        {

            uint256[] memory tokens=artworkIdToTokenIds[_artworkId];
            uint len=tokens.length;

            for (uint i ; i < len;) 
            {
                uint256 val=tokens[i];
                if (isBurned[val])
                {
                    tokens[i]=0;
                }
                unchecked { ++i ;}

            }
            return tokens;
        }

        /// @dev tokenId to ArtworkID
        function showArtworkOfToken(uint256 _tokenId) public view returns (uint256)
        {
            return tokenIdToArtworkId[_tokenId];
        }
        
        /// @dev artwork to IPFS CID
        function showIpfsHash(uint256 _artworkId) public view returns (uint256)
        {
            return tokenIdToIpfsHash[_artworkId];
        }
        
        /// @dev remaining time to remotely burn a credit card token
        function showCCSecondsRemaining(uint256 _tokenId) public view returns (uint)
        {
            return (DAY_LIMIT * 86400)-(block.timestamp-paidDate[_tokenId]);
        }

        /// @dev returns if user cna reserve a quantity at the moment
        function isReservable(uint quantity,uint _artworkId) public view returns (bool)
        {
            
            if ((artworks[_artworkId].minted+quantity <= artworks[_artworkId].artworkLimit) && (artworkCheck[_artworkId])) 
            {
                return true;
            }
            
            return false;
            
            
        }
        

        /// @dev available array display
        function showAvailableArray(uint256 _artworkId) public view returns (uint256[] memory)
        {
            return artworks[_artworkId].available_list;
        }

        
        //RESETTABLE MAPPING
        /**
        * @dev A resettable mapping implementation using clever hashing
        *
        * 
        *
        * Functionality:
        *
        * - Resets the whitelisted addresses for the next drop.
        * 
        */        
        
        /// @dev how much a whitelisted user minted
        function getWhiteListedLimit(address  whitelistedAddress) public view returns(uint256) 
        {
            bytes32 key = keccak256(abi.encodePacked(currentMappingVersion, whitelistedAddress));
            return whiteListLimits[key];
        }

        /// @dev set the number of mints a whitelisted user called
        function _setLimit(address whitelistedAddress, uint256 newLimit) internal 
        {
            bytes32 key = keccak256(abi.encodePacked(currentMappingVersion, whitelistedAddress));
            whiteListLimits[key] = newLimit;
        }
        
        /// @dev reset the whitelisted limits
        function resetWhiteListedMapping() external onlyOperator 
        {
            currentMappingVersion++;
        }

        /// @dev a way to delete entries from the mapping,
        function recoverGas(uint256 _version, address whitelistedAddress) external onlyOperator 
        {
            require(_version < currentMappingVersion);
            bytes32 key = keccak256(abi.encodePacked(_version, whitelistedAddress));
            delete(whiteListLimits[key]);
        }
        
    }