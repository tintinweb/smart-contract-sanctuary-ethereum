// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

import "./types/WeedWarsERC721.sol";

contract SynthERC721 is WeedWarsERC721 {

    constructor() WeedWarsERC721("Synthicants", "SYNTH") {}
}

// SPDX-License-Identifier: AGPL-3.0

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

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

import "./IERC165.sol";

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

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

import "./IERC721.sol";

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

// SPDX-License-Identifier: AGPL-3.0

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

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

interface IWeedERC20 {
    function mint(address _address, uint256 _amount) external;
    function burn(address _address, uint256 _amount) external;
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: AGPL-3.0

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

// SPDX-License-Identifier: AGPL-3.0

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

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

import "../interfaces/IERC165.sol";

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

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

import "./Context.sol";
import "./ERC165.sol";
import "../interfaces/IERC721.sol";
import "../interfaces/IERC721Metadata.sol";
import "../interfaces/IERC721Receiver.sol";
import "../libraries/Address.sol";
import "../libraries/Strings.sol";

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
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
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
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
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
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

import "./Context.sol";
import "./ERC721.sol";

/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be irreversibly burned (destroyed).
 */
abstract contract ERC721Burnable is Context, ERC721 {
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

import "./Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: AGPL-3.0

import "../types/Ownable.sol";

pragma solidity ^0.8.0;

contract OwnerOrAdmin is Ownable {

    mapping(address => bool) public admins;

    function _isOwnerOrAdmin() private view {
        require(
            owner() == msg.sender || admins[msg.sender],
            "OwnerOrAdmin: unauthorized"
        );
    }

    modifier onlyOwnerOrAdmin() {
        _isOwnerOrAdmin();
        _;
    }

    function setAdmin(address _address, bool _hasAccess) external onlyOwner {
        admins[_address] = _hasAccess;
    }

}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

import "../types/ERC721Burnable.sol";
import "../types/OwnerOrAdmin.sol";
import "../libraries/Counters.sol";
import "../interfaces/IWeedERC20.sol";

abstract contract WeedWarsERC721 is ERC721Burnable, OwnerOrAdmin {
    using Counters for Counters.Counter;

    constructor(string memory name, string memory symbol) ERC721(name, symbol) Ownable() {
        genesisTokenIdCounter._value = 556; // accounting for reserve
        genesisReserveTokenIdCounter._value = 0;
    }

    struct WeedWarsNft {
        uint16 face; // 0
        uint16 hat; // 1
        uint16 trousers; // 2
        uint16 tshirt; // 3
        uint16 boots; // 4
        uint16 jacket; // 5
        uint16 weapon; // 6
        uint16 background; // 7
        uint16 mergeCount; // 8
    }

    event Merge(
        address indexed _address,
        uint256 indexed _generation,
        uint256 _tokenId1,
        uint256 _tokenId2
    );

    event Resurrection(
        uint256 indexed _tokenId,
        address indexed _address,
        uint256 indexed _generation
    );

    Counters.Counter public generationCounter;
    Counters.Counter public genesisTokenIdCounter;
    Counters.Counter public genesisReserveTokenIdCounter;

    uint256 public constant GENESIS_MAX_SUPPLY = 4444;
    uint256 public constant RESERVE_QTY = 556;
    bool public IS_MERGE_ON;

    string public preRevealUrl;
    string public apiUrl;
    address public weedContractAddress;
    address public saleContractAddress;
    address public stakingContractAddress;

    // When warriors are minted for the first time this contract generates a random looking DNA mapped to a tokenID.
    // The actual uint16 properties of the warrior are later derived by decoding it with the
    // information that's inside of the generationRanges and generationRarities mappings.
    // Each generation of warriors will have its own set of rarities and property ranges
    // with a provenance hash uploaded ahead of time.
    // It gurantees that the actual property distribution is hidden during the pre-reveal phase since decoding depends on
    // the unknown information.
    // Property ranges are stored inside of a uint16[6] array per each property.
    // These 6 numbers are interpreted as buckets of traits. Traits are just sequential numbers.
    // For example [1, 100, 200, 300, 400, 500] value inside of generationRanges for the face property will be interpreted as:
    // - Common: 1-99
    // - Unusual: 100-199
    // - Rare: 200 - 299
    // - Super Rare: 300 - 399
    // - Legendary: 400 - 599
    //
    // The last two pieces of data are located inside of generationRarities mapping which holds uint16[4] arrays of rarities.
    // For example, if our rarities were defined as [40, 25, 20, 10], combined with buckets from above they will result in:
    // - Common: 1-99 [40% chance]
    // - Unusual: 100-199 [25% chance]
    // - Rare: 200 - 299 [20% chance]
    // - Super Rare: 300 - 399 [10% chance]
    // - Legendary: 400 - 599 [5% chance]
    //
    // This framework helps us to keep our trait generation random and hidden while still allowing for
    // clearly defined rarity categories.
    mapping(uint256 => mapping(uint256 => uint16[6])) public generationRanges;
    mapping(uint256 => uint16[4]) public generationRarities;
    mapping(uint256 => bool) public isGenerationRevealed;
    mapping(uint256 => uint256) public generationSeed;
    mapping(uint256 => uint256) public generationResurrectionChance;
    mapping(address => mapping(uint256 => uint256)) public resurrectionTickets;
    mapping(uint256 => uint256) private tokenIdToNft;
    mapping(uint256 => bool) public locked;

    // This mapping is going to be used to connect our ww store implementation and potential future
    // mechanics that will enhance this collection.
    mapping(address => bool) public authorizedToEquip;
    // Kill switch for the mapping above, if community decides that it's too dangerous to have this
    // list extendable we can prevent it from being modified.
    bool public isAuthorizedToEquipLocked;

    function _isTokenOwner(uint256 _tokenId) private view {
        require(
            ownerOf(_tokenId) == msg.sender,
            "WW: you don't own this token"
        );
    }

    modifier onlyTokenOwner(uint256 _tokenId) {
        _isTokenOwner(_tokenId);
        _;
    }

    modifier onlyAuthorizedToEquip() {
        require(authorizedToEquip[msg.sender], "WW: unauthorized");
        _;
    }

    modifier onlySaleContract() {
        require(saleContractAddress == msg.sender, "WW: only sale contract");
        _;
    }

    modifier onlyStakeContract() {
        require(stakingContractAddress == msg.sender, "WW: only staking contract");
        _;
    }

    function setAuthorizedToEquip(address _address, bool _isAuthorized) external onlyOwnerOrAdmin {
        require(!isAuthorizedToEquipLocked);
        authorizedToEquip[_address] = _isAuthorized;
    }

    function lockAuthorizedToEquip() external onlyOwnerOrAdmin {
        isAuthorizedToEquipLocked = true;
    }

    function setApiUrl(string calldata _apiUrl) external onlyOwnerOrAdmin {
        apiUrl = _apiUrl;
    }

    function setPreRevealUrl(string calldata _preRevealUrl) external onlyOwnerOrAdmin {
        preRevealUrl = _preRevealUrl;
    }

    function setWeedContractAddress(address _address) external onlyOwner {
        weedContractAddress = _address;
    }

    function setSaleContractAddress(address _address) external onlyOwner {
        saleContractAddress = _address;
    }

    function setStakingContractAddress(address _address) external onlyOwner {
        stakingContractAddress = _address;
    }

    function setIsMergeOn(bool _isMergeOn) external onlyOwnerOrAdmin {
        IS_MERGE_ON = _isMergeOn;
    }

    function setIsGenerationRevealed(uint256 _gen, bool _isGenerationRevealed) external onlyOwnerOrAdmin {
        require(!isGenerationRevealed[_gen]);
        isGenerationRevealed[_gen] = _isGenerationRevealed;
    }

    function setGenerationRanges(
        uint256 _gen,
        uint16[6] calldata _face,
        uint16[6] calldata _hat,
        uint16[6] calldata _trousers,
        uint16[6] calldata _tshirt,
        uint16[6] calldata _boots,
        uint16[6] calldata _jacket,
        uint16[6] calldata _weapon,
        uint16[6] calldata _background
    ) external onlyOwnerOrAdmin {
        require(!isGenerationRevealed[_gen]);

        generationRanges[_gen][0] = _face;
        generationRanges[_gen][1] = _hat;
        generationRanges[_gen][2] = _trousers;
        generationRanges[_gen][3] = _tshirt;
        generationRanges[_gen][4] = _boots;
        generationRanges[_gen][5] = _jacket;
        generationRanges[_gen][6] = _weapon;
        generationRanges[_gen][7] = _background;
    }

    function setGenerationRarities(
        uint256 _gen,
        uint16 _common,
        uint16 _unusual,
        uint16 _rare,
        uint16 _superRare
    ) external onlyOwnerOrAdmin {
        require(!isGenerationRevealed[_gen]);
        generationRarities[_gen] = [_common, _unusual, _rare, _superRare];
    }

    function startNextGenerationResurrection(uint256 _resurrectionChance) external onlyOwnerOrAdmin {
        require(!IS_MERGE_ON);
        generationCounter.increment();
        uint256 gen = generationCounter.current();
        generationSeed[gen] = _getSeed();
        generationResurrectionChance[gen] = _resurrectionChance;
    }

    function mintReserveBulk(address[] memory _addresses, uint256[] memory _claimQty) external onlyOwner {

        require(
            _addresses.length == _claimQty.length
        );

        for (uint256 i = 0; i < _addresses.length; i++) {
            mintReserve(_addresses[i], _claimQty[i]);
        }
    }

    function mintReserve(address _address, uint256 _claimQty) public onlyOwner {

        require(
            genesisReserveTokenIdCounter.current() + _claimQty <= RESERVE_QTY
        );

        for (uint256 i = 0; i < _claimQty; i++) {
            genesisReserveTokenIdCounter.increment();
            _mint(_address, genesisReserveTokenIdCounter.current(), 0);
        }
    }

    function mint(uint256 _claimQty, address _reciever) external onlySaleContract {
        require(
            genesisTokenIdCounter.current() + _claimQty <= GENESIS_MAX_SUPPLY,
            "WW: exceeds max warriors supply"
        );

        for (uint256 i = 0; i < _claimQty; i++) {
            genesisTokenIdCounter.increment();
            _mint(_reciever, genesisTokenIdCounter.current(), 0);
        }
    }

    function _mint(
        address _address,
        uint256 _tokenId,
        uint256 _gen
    ) private {
        uint256 dna = uint256(
            keccak256(abi.encodePacked(_address, _tokenId, _getSeed()))
        );

        // When warriors are generated for the first time
        // the last 9 bits of their DNA will be used to store the generation number (8 bit)
        // and a flag that indicates whether the dna is in its encoded
        // or decoded state (1 bit).

        // Generation number will help to properly decode properties based on
        // property ranges that are unknown during minting.

        // ((dna >> 9) << 9) clears the last 9 bits.
        // _gen * 2 moves generation information one bit to the left and sets the last bit to 0.
        dna = ((dna >> 9) << 9) | (uint8(_gen) * 2);
        tokenIdToNft[_tokenId] = dna;
        _safeMint(_address, _tokenId);
    }

    function canResurrect(address _address, uint256 _tokenId) public view returns (bool) {
        // Check if resurrection ticket was submitted
        uint256 currentGen = generationCounter.current();
        uint256 resurrectionGen = resurrectionTickets[_address][_tokenId];
        if (resurrectionGen == 0 || resurrectionGen != currentGen) {
            return false;
        }

        // Check if current generation was seeded
        uint256 seed = generationSeed[currentGen];
        if (seed == 0) {
            return false;
        }

        // Check if this token is lucky to be reborn
        if (
            (uint256(keccak256(abi.encodePacked(_tokenId, seed))) % 100) >
            generationResurrectionChance[currentGen]
        ) {
            return false;
        }

        return true;
    }

    function resurrect(uint256 _tokenId) external {
        require(canResurrect(msg.sender, _tokenId), "WW: cannot be resurrected");

        delete resurrectionTickets[msg.sender][_tokenId];

        uint256 gen = generationCounter.current();
        _mint(msg.sender, _tokenId, gen);
        emit Resurrection(_tokenId, msg.sender, gen);
    }

    function setLock(uint256 _tokenId, address _owner, bool _isLocked) external onlyStakeContract {
        require(ownerOf(_tokenId) == _owner, "WW: not own NFT");
        locked[_tokenId] = _isLocked;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal view override {
        require(locked[tokenId] == false, "WW: token is locked");
    }

    function merge(
        uint256 _tokenId1,
        uint256 _tokenId2,
        uint16[8] calldata _w
    ) external onlyTokenOwner(_tokenId1) onlyTokenOwner(_tokenId2) {
        require(
            weedContractAddress != address(0) && IS_MERGE_ON,
            "WW: merge is not active"
        );
        require(locked[_tokenId1] == false, "WW: token is locked");
        require(locked[_tokenId2] == false, "WW: token is locked");

        WeedWarsNft memory w1 = get(_tokenId1);
        WeedWarsNft memory w2 = get(_tokenId2);

        require(
            (_w[0] == w1.face || _w[0] == w2.face) &&
                (_w[1] == w1.hat || _w[1] == w2.hat) &&
                (_w[2] == w1.trousers || _w[2] == w2.trousers) &&
                (_w[3] == w1.tshirt || _w[3] == w2.tshirt) &&
                (_w[4] == w1.boots || _w[4] == w2.boots) &&
                (_w[5] == w1.jacket || _w[5] == w2.jacket) &&
                (_w[6] == w1.weapon || _w[6] == w2.weapon) &&
                (_w[7] == w1.background || _w[7] == w2.background),
            "WW: invalid property transfer"
        );

        _burn(_tokenId2);

        // Once any composability mechanic is used warrior traits become fully decoded
        // for the ease of future trait transfers between generations.
        tokenIdToNft[_tokenId1] = _generateDecodedDna(
            WeedWarsNft(
                _w[0],
                _w[1],
                _w[2],
                _w[3],
                _w[4],
                _w[5],
                _w[6],
                _w[7],
                w1.mergeCount + w2.mergeCount + 1
            )
        );

        uint256 gen = generationCounter.current();

        // Burned token has a chance of resurrection during the next generation.
        resurrectionTickets[msg.sender][_tokenId2] = gen + 1;
        emit Merge(msg.sender, gen, _tokenId1, _tokenId2);
    }

    function equipProperties(
        address _originalCaller,
        uint256 _tokenId,
        uint16[8] calldata _w
    ) external onlyAuthorizedToEquip {
        require(
            ownerOf(_tokenId) == _originalCaller,
            "WW: you don't own this token"
        );
        require(locked[_tokenId] == false, "WW: token is locked");

        WeedWarsNft memory w = get(_tokenId);

        w.face = _w[0] == 0 ? w.face : _w[0];
        w.hat = _w[1] == 0 ? w.hat : _w[1];
        w.trousers = _w[2] == 0 ? w.trousers : _w[2];
        w.tshirt = _w[3] == 0 ? w.tshirt : _w[3];
        w.boots = _w[4] == 0 ? w.boots : _w[4];
        w.jacket = _w[5] == 0 ? w.jacket : _w[5];
        w.weapon = _w[6] == 0 ? w.weapon : _w[6];
        w.background = _w[7] == 0 ? w.background : _w[7];

        tokenIdToNft[_tokenId] = _generateDecodedDna(w);
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "WW: warrior doesn't exist");


        if (bytes(apiUrl).length == 0 || !_isDnaRevealed(tokenIdToNft[_tokenId])) {
            return string(
                abi.encodePacked(
                    preRevealUrl,
                    _toString(_tokenId)
                ));
        }

        WeedWarsNft memory w = get(_tokenId);
        string memory separator = "-";
        return
            string(
                abi.encodePacked(
                    apiUrl,
                    abi.encodePacked(
                        _toString(_tokenId),
                        separator,
                        _toString(w.face),
                        separator,
                        _toString(w.hat),
                        separator,
                        _toString(w.trousers)
                    ),
                    abi.encodePacked(
                        separator,
                        _toString(w.tshirt),
                        separator,
                        _toString(w.boots),
                        separator,
                        _toString(w.jacket)
                    ),
                    abi.encodePacked(
                        separator,
                        _toString(w.weapon),
                        separator,
                        _toString(w.background),
                        separator,
                        _toString(w.mergeCount)
                    )
                )
            );
    }

    function _getSeed() private view returns (uint256) {
        return uint256(blockhash(block.number - 1));
    }

    function _generateDecodedDna(WeedWarsNft memory _w) private pure returns (uint256) {
        uint256 dna = _w.mergeCount; // 8
        dna = (dna << 16) | _w.background; // 7
        dna = (dna << 16) | _w.weapon; // 6
        dna = (dna << 16) | _w.jacket; // 5
        dna = (dna << 16) | _w.boots; // 4
        dna = (dna << 16) | _w.tshirt; // 3
        dna = (dna << 16) | _w.trousers; // 2
        dna = (dna << 16) | _w.hat; // 1
        dna = (dna << 16) | _w.face; // 0
        dna = (dna << 1) | 1; // flag indicating whether this dna was decoded
        // Decoded DNA won't have a generation number anymore.
        // These traits will permanently look decoded and no further manipulation will be needed
        // apart from just extracting it with a bitshift.

        return dna;
    }

    function _isDnaRevealed(uint256 _dna) private view returns (bool) {
        // Check the last bit to see if dna is decoded.
        if (_dna & 1 == 1) {
            return true;
        }

        // If dna wasn't decoded we wanna look up whether the generation it belongs to was revealed.
        return isGenerationRevealed[(_dna >> 1) & 0xFF];
    }

    function get(uint256 _tokenId) public view returns (WeedWarsNft memory) {
        uint256 dna = tokenIdToNft[_tokenId];
        require(_isDnaRevealed(dna), "WW: warrior is not revealed yet");

        WeedWarsNft memory w;
        w.face = getProperty(dna, 0);
        w.hat = getProperty(dna, 1);
        w.trousers = getProperty(dna, 2);
        w.tshirt = getProperty(dna, 3);
        w.boots = getProperty(dna, 4);
        w.jacket = getProperty(dna, 5);
        w.weapon = getProperty(dna, 6);
        w.background = getProperty(dna, 7);
        w.mergeCount = getProperty(dna, 8);

        return w;
    }

    function getMergeCount(uint256 _tokenId) public view returns (uint) {
        uint256 dna = tokenIdToNft[_tokenId];
        return getProperty(dna, 8);
    }

    function getProperty(uint256 _dna, uint256 _propertyId) private view returns (uint16) {
        // Property right offset in bits.
        uint256 bitShift = _propertyId * 16;

        // Last bit shows whether the dna was already decoded.
        // If it was we can safely return the stored value after bitshifting and applying a mask.
        // Decoded values don't have a generation number, so only need to shift by one bit to account for the flag.
        if (_dna & 1 == 1) {
            return uint16(((_dna >> 1) >> bitShift) & 0xFFFF);
        }

        // Every time warriors get merged their DNA will be decoded.
        // If we got here it means that it wasn't decoded and we can safely assume that their mergeCount counter is 0.
        if (_propertyId == 8) {
            return 0;
        }

        // Minted generation number is stored inside of 8 bits after the encoded/decoded flag.
        uint256 gen = (_dna >> 1) & 0xFF;

        // Rarity and range values to decode the property (specific to generation)
        uint16[4] storage _rarity = generationRarities[gen];
        uint16[6] storage _range = generationRanges[gen][_propertyId];

        // Extracting the encoded (raw) property (also shifting by 9bits first to account for generation metadata and a flag).
        // This property is just a raw value, it will get decoded with _rarity and _range information from above.
        uint256 encodedProp = (((_dna >> 9) >> bitShift) & 0xFFFF);

        // A value that will dictate from which pool of properties we should pull (common, uncommon, rare)
        uint256 rarityDecider = (uint256(
            keccak256(abi.encodePacked(_propertyId, _dna, _range))
        ) % 100) + 1;

        uint256 rangeStart;
        uint256 rangeEnd;

        // There is an opportunity to optimize for SLOAD operations here by byte packing all
        // rarity/range information and loading it in get before this function
        // is called to minimize state access.
        if (rarityDecider <= _rarity[0]) {
            // common
            rangeStart = _range[0];
            rangeEnd = _range[1];
        } else if (rarityDecider <= _rarity[1] + _rarity[0]) {
            // unusual
            rangeStart = _range[1];
            rangeEnd = _range[2];
        } else if (rarityDecider <= _rarity[2] + _rarity[1] + _rarity[0]) {
            // rare
            rangeStart = _range[2];
            rangeEnd = _range[3];
        } else if (rarityDecider <= _rarity[3] + _rarity[2] + _rarity[1] + _rarity[0]) {
            // super rare
            rangeStart = _range[3];
            rangeEnd = _range[4];
        } else {
            // legendary
            rangeStart = _range[4];
            rangeEnd = _range[5];
        }

        // Returns a decoded property that will fall within one of the rarity buckets.
        return uint16((encodedProp % (rangeEnd - rangeStart)) + rangeStart);
    }

    function _toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
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
}