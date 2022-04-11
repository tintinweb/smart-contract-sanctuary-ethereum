// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

// .-"""""""---,.               n,                                      ..--------..
// \-          ,,'''-..      n   '\.                ,.n           ..--''           )
//  \-     . .,;))     ''-,   \     ''.. .'"'. .,-''    .n   ..-''   (( o         _/
//   \- ' ''''':'          ''-.'"|'--_  '     '  ,.--'''..-''         ' ' ' - .  _/
//    \-                       ''->.  \'  ,--. '/' >..''                        _/
//     \                     (,       /  /.  .\ \ ''    ,)                     ./
//      ''.    .  ..         ')          \ .. /         ('          ..       ./
//         ''-... . ._ .__         .''.  //..\\  ,'.            __ _ _,__.--'
//             /' ((    ..'' ' ' '-'  6  \/__\/  ' '- - -' ' ',''   - '\
//            '(.  6,    '..          /.   ''  .'          ,,'     ) )  )
//             '\  \'C_,_   ==,      / '_      _|\       ,'', ,,_.;-' _/
//               '._ ,   ')   E     /'|_ ')()('_' \     C  ,I'''  _.-'
//                  ''''''\ (('   ,/  ''  (()) ''  '-._ _ __---'''
//                         '' '' '    '==='()'=='
//                                    '(       )'
//                                    '6        '     JM 10/28
//                                     \       /
//                                     '       '
//          Silk Road                  '       '
//             by                       '      '
// Ezra Miller and Steve Klebanoff       '    '
//         silkroad.art                   '..'

// ERC721A Creator: Chiru Labs
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)
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

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

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
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

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
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

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

// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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

// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

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

// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

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
    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
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

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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
    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
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

// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

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
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IERC165).interfaceId;
    }
}

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata and Enumerable extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at 0 (e.g. 0, 1, 2, 3..).
 *
 * Does not support burning tokens to address(0).
 *
 * Assumes that an owner cannot have more than the 2**128 (max value of uint128) of supply
 */
contract ERC721A is
    Context,
    ERC165,
    IERC721,
    IERC721Metadata,
    IERC721Enumerable
{
    using Address for address;
    using Strings for uint256;

    struct TokenOwnership {
        address addr;
        uint64 startTimestamp;
    }

    struct AddressData {
        uint128 balance;
        uint128 numberMinted;
    }

    uint256 internal currentIndex = 0;

    uint256 internal immutable maxBatchSize;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned. See ownershipOf implementation for details.
    mapping(uint256 => TokenOwnership) internal _ownerships;

    // Mapping owner address to address data
    mapping(address => AddressData) private _addressData;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev
     * `maxBatchSize` refers to how much a minter can mint at a time.
     */
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 maxBatchSize_
    ) {
        require(maxBatchSize_ > 0, "ERC721A: max batch size must be nonzero");
        _name = name_;
        _symbol = symbol_;
        maxBatchSize = maxBatchSize_;
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return currentIndex;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index)
        public
        view
        override
        returns (uint256)
    {
        require(index < totalSupply(), "ERC721A: global index out of bounds");
        return index;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     * This read function is O(totalSupply). If calling from a separate contract, be sure to test gas first.
     * It may also degrade with extremely large collection sizes (e.g >> 10000), test for your use case.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        override
        returns (uint256)
    {
        require(index < balanceOf(owner), "ERC721A: owner index out of bounds");
        uint256 numMintedSoFar = totalSupply();
        uint256 tokenIdsIdx = 0;
        address currOwnershipAddr = address(0);
        for (uint256 i = 0; i < numMintedSoFar; i++) {
            TokenOwnership memory ownership = _ownerships[i];
            if (ownership.addr != address(0)) {
                currOwnershipAddr = ownership.addr;
            }
            if (currOwnershipAddr == owner) {
                if (tokenIdsIdx == index) {
                    return i;
                }
                tokenIdsIdx++;
            }
        }
        revert("ERC721A: unable to get token of owner by index");
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC721Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        require(
            owner != address(0),
            "ERC721A: balance query for the zero address"
        );
        return uint256(_addressData[owner].balance);
    }

    function _numberMinted(address owner) internal view returns (uint256) {
        require(
            owner != address(0),
            "ERC721A: number minted query for the zero address"
        );
        return uint256(_addressData[owner].numberMinted);
    }

    function ownershipOf(uint256 tokenId)
        internal
        view
        returns (TokenOwnership memory)
    {
        require(_exists(tokenId), "ERC721A: owner query for nonexistent token");

        uint256 lowestTokenToCheck;
        if (tokenId >= maxBatchSize) {
            lowestTokenToCheck = tokenId - maxBatchSize + 1;
        }

        for (uint256 curr = tokenId; curr >= lowestTokenToCheck; curr--) {
            TokenOwnership memory ownership = _ownerships[curr];
            if (ownership.addr != address(0)) {
                return ownership;
            }
        }

        revert("ERC721A: unable to determine the owner of token");
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return ownershipOf(tokenId).addr;
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
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
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
    function approve(address to, uint256 tokenId) public override {
        address owner = ERC721A.ownerOf(tokenId);
        require(to != owner, "ERC721A: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721A: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId, owner);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId)
        public
        view
        override
        returns (address)
    {
        require(
            _exists(tokenId),
            "ERC721A: approved query for nonexistent token"
        );

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        override
    {
        require(operator != _msgSender(), "ERC721A: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
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
    ) public override {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "ERC721A: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return tokenId < currentIndex;
    }

    function _safeMint(address to, uint256 quantity) internal {
        _safeMint(to, quantity, "");
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` cannot be larger than the max batch size.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal {
        uint256 startTokenId = currentIndex;
        require(to != address(0), "ERC721A: mint to the zero address");
        // We know if the first token in the batch doesn't exist, the other ones don't as well, because of serial ordering.
        require(!_exists(startTokenId), "ERC721A: token already minted");
        require(quantity <= maxBatchSize, "ERC721A: quantity to mint too high");

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        AddressData memory addressData = _addressData[to];
        _addressData[to] = AddressData(
            addressData.balance + uint128(quantity),
            addressData.numberMinted + uint128(quantity)
        );
        _ownerships[startTokenId] = TokenOwnership(to, uint64(block.timestamp));

        uint256 updatedIndex = startTokenId;

        for (uint256 i = 0; i < quantity; i++) {
            emit Transfer(address(0), to, updatedIndex);
            require(
                _checkOnERC721Received(address(0), to, updatedIndex, _data),
                "ERC721A: transfer to non ERC721Receiver implementer"
            );
            updatedIndex++;
        }

        currentIndex = updatedIndex;
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
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
    ) private {
        TokenOwnership memory prevOwnership = ownershipOf(tokenId);

        bool isApprovedOrOwner = (_msgSender() == prevOwnership.addr ||
            getApproved(tokenId) == _msgSender() ||
            isApprovedForAll(prevOwnership.addr, _msgSender()));

        require(
            isApprovedOrOwner,
            "ERC721A: transfer caller is not owner nor approved"
        );

        require(
            prevOwnership.addr == from,
            "ERC721A: transfer from incorrect owner"
        );
        require(to != address(0), "ERC721A: transfer to the zero address");

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, prevOwnership.addr);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _addressData[from].balance -= 1;
            _addressData[to].balance += 1;
        }

        _ownerships[tokenId] = TokenOwnership(to, uint64(block.timestamp));

        // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
        // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
        uint256 nextTokenId = tokenId + 1;
        if (_ownerships[nextTokenId].addr == address(0)) {
            if (_exists(nextTokenId)) {
                _ownerships[nextTokenId] = TokenOwnership(
                    prevOwnership.addr,
                    prevOwnership.startTimestamp
                );
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(
        address to,
        uint256 tokenId,
        address owner
    ) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
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
            try
                IERC721Receiver(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    _data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "ERC721A: transfer to non ERC721Receiver implementer"
                    );
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
     * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes
     * minting.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}
}

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// OpenZeppelin Contracts v4.4.1 (interfaces/IERC2981.sol)

// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

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

/*
 * String shenanigans
 * Author: Zac Williamson, AZTEC
 * Licensed under the Unlicense
 */

contract StringUtils {
    /**
     * Convert an integer into an ASCII encoded base10 string
     * @param input integer
     * @return result base10-encoded string
     */
    function toString(uint256 input)
        public
        pure
        returns (string memory result)
    {
        if (input < 10) {
            assembly {
                result := mload(0x40)
                mstore(result, 0x01)
                mstore8(add(result, 0x20), add(input, 0x30))
                mstore(0x40, add(result, 0x40))
            }
            return result;
        }
        assembly {
            result := mload(0x40)
            let mptr := add(result, 0x80)
            let table := add(result, 0xe0)

            // Store lookup table that maps an integer from 0 to 99 into a 2-byte ASCII equivalent
            mstore(
                table,
                0x0000000000000000000000000000000000000000000000000000000000003030
            )
            mstore(
                add(table, 0x20),
                0x3031303230333034303530363037303830393130313131323133313431353136
            )
            mstore(
                add(table, 0x40),
                0x3137313831393230323132323233323432353236323732383239333033313332
            )
            mstore(
                add(table, 0x60),
                0x3333333433353336333733383339343034313432343334343435343634373438
            )
            mstore(
                add(table, 0x80),
                0x3439353035313532353335343535353635373538353936303631363236333634
            )
            mstore(
                add(table, 0xa0),
                0x3635363636373638363937303731373237333734373537363737373837393830
            )
            mstore(
                add(table, 0xc0),
                0x3831383238333834383538363837383838393930393139323933393439353936
            )
            mstore(
                add(table, 0xe0),
                0x3937393839390000000000000000000000000000000000000000000000000000
            )

            /**
             * Convert `input` into ASCII.
             *
             * Slice 2 base-10  digits off of the input, use to index the ASCII lookup table.
             *
             * We start from the least significant digits, write results into mem backwards,
             * this prevents us from overwriting memory despite the fact that each mload
             * only contains 2 byteso f useful data.
             **/
            {
                let v := input
                mstore(0x1e, mload(add(table, shl(1, mod(v, 100)))))
                mstore(0x1c, mload(add(table, shl(1, mod(div(v, 100), 100)))))
                mstore(0x1a, mload(add(table, shl(1, mod(div(v, 10000), 100)))))
                mstore(
                    0x18,
                    mload(add(table, shl(1, mod(div(v, 1000000), 100))))
                )
                mstore(
                    0x16,
                    mload(add(table, shl(1, mod(div(v, 100000000), 100))))
                )
                mstore(
                    0x14,
                    mload(add(table, shl(1, mod(div(v, 10000000000), 100))))
                )
                mstore(
                    0x12,
                    mload(add(table, shl(1, mod(div(v, 1000000000000), 100))))
                )
                mstore(
                    0x10,
                    mload(add(table, shl(1, mod(div(v, 100000000000000), 100))))
                )
                mstore(
                    0x0e,
                    mload(
                        add(table, shl(1, mod(div(v, 10000000000000000), 100)))
                    )
                )
                mstore(
                    0x0c,
                    mload(
                        add(
                            table,
                            shl(1, mod(div(v, 1000000000000000000), 100))
                        )
                    )
                )
                mstore(
                    0x0a,
                    mload(
                        add(
                            table,
                            shl(1, mod(div(v, 100000000000000000000), 100))
                        )
                    )
                )
                mstore(
                    0x08,
                    mload(
                        add(
                            table,
                            shl(1, mod(div(v, 10000000000000000000000), 100))
                        )
                    )
                )
                mstore(
                    0x06,
                    mload(
                        add(
                            table,
                            shl(1, mod(div(v, 1000000000000000000000000), 100))
                        )
                    )
                )
                mstore(
                    0x04,
                    mload(
                        add(
                            table,
                            shl(
                                1,
                                mod(div(v, 100000000000000000000000000), 100)
                            )
                        )
                    )
                )
                mstore(
                    0x02,
                    mload(
                        add(
                            table,
                            shl(
                                1,
                                mod(div(v, 10000000000000000000000000000), 100)
                            )
                        )
                    )
                )
                mstore(
                    0x00,
                    mload(
                        add(
                            table,
                            shl(
                                1,
                                mod(
                                    div(v, 1000000000000000000000000000000),
                                    100
                                )
                            )
                        )
                    )
                )

                mstore(add(mptr, 0x40), mload(0x1e))

                v := div(v, 100000000000000000000000000000000)
                if v {
                    mstore(0x1e, mload(add(table, shl(1, mod(v, 100)))))
                    mstore(
                        0x1c,
                        mload(add(table, shl(1, mod(div(v, 100), 100))))
                    )
                    mstore(
                        0x1a,
                        mload(add(table, shl(1, mod(div(v, 10000), 100))))
                    )
                    mstore(
                        0x18,
                        mload(add(table, shl(1, mod(div(v, 1000000), 100))))
                    )
                    mstore(
                        0x16,
                        mload(add(table, shl(1, mod(div(v, 100000000), 100))))
                    )
                    mstore(
                        0x14,
                        mload(add(table, shl(1, mod(div(v, 10000000000), 100))))
                    )
                    mstore(
                        0x12,
                        mload(
                            add(table, shl(1, mod(div(v, 1000000000000), 100)))
                        )
                    )
                    mstore(
                        0x10,
                        mload(
                            add(
                                table,
                                shl(1, mod(div(v, 100000000000000), 100))
                            )
                        )
                    )
                    mstore(
                        0x0e,
                        mload(
                            add(
                                table,
                                shl(1, mod(div(v, 10000000000000000), 100))
                            )
                        )
                    )
                    mstore(
                        0x0c,
                        mload(
                            add(
                                table,
                                shl(1, mod(div(v, 1000000000000000000), 100))
                            )
                        )
                    )
                    mstore(
                        0x0a,
                        mload(
                            add(
                                table,
                                shl(1, mod(div(v, 100000000000000000000), 100))
                            )
                        )
                    )
                    mstore(
                        0x08,
                        mload(
                            add(
                                table,
                                shl(
                                    1,
                                    mod(div(v, 10000000000000000000000), 100)
                                )
                            )
                        )
                    )
                    mstore(
                        0x06,
                        mload(
                            add(
                                table,
                                shl(
                                    1,
                                    mod(div(v, 1000000000000000000000000), 100)
                                )
                            )
                        )
                    )
                    mstore(
                        0x04,
                        mload(
                            add(
                                table,
                                shl(
                                    1,
                                    mod(
                                        div(v, 100000000000000000000000000),
                                        100
                                    )
                                )
                            )
                        )
                    )
                    mstore(
                        0x02,
                        mload(
                            add(
                                table,
                                shl(
                                    1,
                                    mod(
                                        div(v, 10000000000000000000000000000),
                                        100
                                    )
                                )
                            )
                        )
                    )
                    mstore(
                        0x00,
                        mload(
                            add(
                                table,
                                shl(
                                    1,
                                    mod(
                                        div(v, 1000000000000000000000000000000),
                                        100
                                    )
                                )
                            )
                        )
                    )

                    mstore(add(mptr, 0x20), mload(0x1e))
                }
                v := div(v, 100000000000000000000000000000000)
                if v {
                    mstore(0x1e, mload(add(table, shl(1, mod(v, 100)))))
                    mstore(
                        0x1c,
                        mload(add(table, shl(1, mod(div(v, 100), 100))))
                    )
                    mstore(
                        0x1a,
                        mload(add(table, shl(1, mod(div(v, 10000), 100))))
                    )
                    mstore(
                        0x18,
                        mload(add(table, shl(1, mod(div(v, 1000000), 100))))
                    )
                    mstore(
                        0x16,
                        mload(add(table, shl(1, mod(div(v, 100000000), 100))))
                    )
                    mstore(
                        0x14,
                        mload(add(table, shl(1, mod(div(v, 10000000000), 100))))
                    )
                    mstore(
                        0x12,
                        mload(
                            add(table, shl(1, mod(div(v, 1000000000000), 100)))
                        )
                    )

                    mstore(mptr, mload(0x1e))
                }
            }

            // get the length of the input
            let len := 1
            {
                if gt(input, 999999999999999999999999999999999999999) {
                    len := add(len, 39)
                    input := div(
                        input,
                        1000000000000000000000000000000000000000
                    )
                }
                if gt(input, 99999999999999999999) {
                    len := add(len, 20)
                    input := div(input, 100000000000000000000)
                }
                if gt(input, 9999999999) {
                    len := add(len, 10)
                    input := div(input, 10000000000)
                }
                if gt(input, 99999) {
                    len := add(len, 5)
                    input := div(input, 100000)
                }
                if gt(input, 999) {
                    len := add(len, 3)
                    input := div(input, 1000)
                }
                if gt(input, 99) {
                    len := add(len, 2)
                    input := div(input, 100)
                }
                len := add(len, gt(input, 9))
            }

            let offset := sub(96, len)
            mstore(result, len)
            mstore(add(result, 0x20), mload(add(mptr, offset)))
            mstore(add(result, 0x40), mload(add(add(mptr, 0x20), offset)))
            mstore(add(result, 0x60), mload(add(add(mptr, 0x40), offset)))

            // clear the junk off at the end of the string. Probs not neccessary but might confuse some debuggers
            mstore(add(result, add(0x20, len)), 0x00)
            mstore(0x40, add(result, 0x80))
        }
    }

    /**
     * Convert a bytes32 into an ASCII encoded hex string
     * @param input bytes32 variable
     * @return result hex-encoded string
     */
    function toHexString(bytes32 input)
        public
        pure
        returns (string memory result)
    {
        if (uint256(input) == 0x00) {
            assembly {
                result := mload(0x40)
                mstore(result, 0x40)
                mstore(
                    add(result, 0x20),
                    0x3030303030303030303030303030303030303030303030303030303030303030
                )
                mstore(
                    add(result, 0x40),
                    0x3030303030303030303030303030303030303030303030303030303030303030
                )
                mstore(0x40, add(result, 0x60))
            }
            return result;
        }
        assembly {
            result := mload(0x40)
            let table := add(result, 0x60)

            // Store lookup table that maps an integer from 0 to 99 into a 2-byte ASCII equivalent
            // Store lookup table that maps an integer from 0 to ff into a 2-byte ASCII equivalent
            mstore(
                add(table, 0x1e),
                0x3030303130323033303430353036303730383039306130623063306430653066
            )
            mstore(
                add(table, 0x3e),
                0x3130313131323133313431353136313731383139316131623163316431653166
            )
            mstore(
                add(table, 0x5e),
                0x3230323132323233323432353236323732383239326132623263326432653266
            )
            mstore(
                add(table, 0x7e),
                0x3330333133323333333433353336333733383339336133623363336433653366
            )
            mstore(
                add(table, 0x9e),
                0x3430343134323433343434353436343734383439346134623463346434653466
            )
            mstore(
                add(table, 0xbe),
                0x3530353135323533353435353536353735383539356135623563356435653566
            )
            mstore(
                add(table, 0xde),
                0x3630363136323633363436353636363736383639366136623663366436653666
            )
            mstore(
                add(table, 0xfe),
                0x3730373137323733373437353736373737383739376137623763376437653766
            )
            mstore(
                add(table, 0x11e),
                0x3830383138323833383438353836383738383839386138623863386438653866
            )
            mstore(
                add(table, 0x13e),
                0x3930393139323933393439353936393739383939396139623963396439653966
            )
            mstore(
                add(table, 0x15e),
                0x6130613161326133613461356136613761386139616161626163616461656166
            )
            mstore(
                add(table, 0x17e),
                0x6230623162326233623462356236623762386239626162626263626462656266
            )
            mstore(
                add(table, 0x19e),
                0x6330633163326333633463356336633763386339636163626363636463656366
            )
            mstore(
                add(table, 0x1be),
                0x6430643164326433643464356436643764386439646164626463646464656466
            )
            mstore(
                add(table, 0x1de),
                0x6530653165326533653465356536653765386539656165626563656465656566
            )
            mstore(
                add(table, 0x1fe),
                0x6630663166326633663466356636663766386639666166626663666466656666
            )
            /**
             * Convert `input` into ASCII.
             *
             * Slice 2 base-10  digits off of the input, use to index the ASCII lookup table.
             *
             * We start from the least significant digits, write results into mem backwards,
             * this prevents us from overwriting memory despite the fact that each mload
             * only contains 2 byteso f useful data.
             **/

            let base := input
            function slice(v, tableptr) {
                mstore(0x1e, mload(add(tableptr, shl(1, and(v, 0xff)))))
                mstore(0x1c, mload(add(tableptr, shl(1, and(shr(8, v), 0xff)))))
                mstore(
                    0x1a,
                    mload(add(tableptr, shl(1, and(shr(16, v), 0xff))))
                )
                mstore(
                    0x18,
                    mload(add(tableptr, shl(1, and(shr(24, v), 0xff))))
                )
                mstore(
                    0x16,
                    mload(add(tableptr, shl(1, and(shr(32, v), 0xff))))
                )
                mstore(
                    0x14,
                    mload(add(tableptr, shl(1, and(shr(40, v), 0xff))))
                )
                mstore(
                    0x12,
                    mload(add(tableptr, shl(1, and(shr(48, v), 0xff))))
                )
                mstore(
                    0x10,
                    mload(add(tableptr, shl(1, and(shr(56, v), 0xff))))
                )
                mstore(
                    0x0e,
                    mload(add(tableptr, shl(1, and(shr(64, v), 0xff))))
                )
                mstore(
                    0x0c,
                    mload(add(tableptr, shl(1, and(shr(72, v), 0xff))))
                )
                mstore(
                    0x0a,
                    mload(add(tableptr, shl(1, and(shr(80, v), 0xff))))
                )
                mstore(
                    0x08,
                    mload(add(tableptr, shl(1, and(shr(88, v), 0xff))))
                )
                mstore(
                    0x06,
                    mload(add(tableptr, shl(1, and(shr(96, v), 0xff))))
                )
                mstore(
                    0x04,
                    mload(add(tableptr, shl(1, and(shr(104, v), 0xff))))
                )
                mstore(
                    0x02,
                    mload(add(tableptr, shl(1, and(shr(112, v), 0xff))))
                )
                mstore(
                    0x00,
                    mload(add(tableptr, shl(1, and(shr(120, v), 0xff))))
                )
            }

            mstore(result, 0x40)
            slice(base, table)
            mstore(add(result, 0x40), mload(0x1e))
            base := shr(128, base)
            slice(base, table)
            mstore(add(result, 0x20), mload(0x1e))
            mstore(0x40, add(result, 0x60))
        }
    }
}

interface IHashGenerator {
    function generateHash(uint256 i) external returns (bytes32);
}

interface IRonin {
    function mint() external;
}

contract SilkRoad is ERC721A, IERC2981, Ownable, StringUtils {
    uint256 public constant MAX_MINTS_PER_PRESALE = 2;
    uint256 public constant MAX_MINTS_PER_PUBLIC_SALE = 5;
    uint256 public constant NUM_ARTIST_PROOFS = 28;

    address public presaleAuthorizer;
    address payable public withdrawalAddress;

    bool public artLocked;

    IHashGenerator public hashGenerator;

    mapping(address => uint256) public presalesUsed;
    mapping(uint256 => bytes32) public tokenIdToHash;

    string public arweaveId;
    string public baseUri;
    string public artLicense;

    uint256 public immutable maxSupply;
    uint256 public presaleStartTime;
    uint256 public immutable pricePerPiece;
    uint256 public publicStartTime;
    uint256 public royaltyFeeBp = 750;

    event ArtCreated(address sentTo, uint256 amount, uint256 startIndex);

    constructor(
        string memory _baseUri,
        string memory _arweaveId,
        uint256 _pricePerPiece,
        uint256 _maxSupply,
        address payable _withdrawalAddress,
        address _presaleAuthorizer,
        IHashGenerator _hashGenerator,
        uint256 _presaleStartTime,
        uint256 _publicStartTime
    ) ERC721A("Silk Road by Ezra Miller", "SILK", NUM_ARTIST_PROOFS) {
        require(
            _presaleStartTime < _publicStartTime,
            "presale must be before public sale"
        );
        require(
            _presaleStartTime > block.timestamp,
            "presale must be in future"
        );

        baseUri = _baseUri;
        arweaveId = _arweaveId;
        pricePerPiece = _pricePerPiece;
        maxSupply = _maxSupply;
        withdrawalAddress = _withdrawalAddress;
        hashGenerator = _hashGenerator;
        presaleAuthorizer = _presaleAuthorizer;
        presaleStartTime = _presaleStartTime;
        publicStartTime = _publicStartTime;
    }

    function presale(
        uint256 numPieces,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) public payable {
        require(presaleActive(), "presale not active");
        require(msg.sender == tx.origin, "can not mint via contract");
        require(
            (getSigner(msg.sender, r, s, v) == presaleAuthorizer),
            "signature must match"
        );
        require(
            (presalesUsed[msg.sender] + numPieces) <= MAX_MINTS_PER_PRESALE,
            "already minted max amout of presales"
        );
        presalesUsed[msg.sender] += numPieces;
        _makeArt(numPieces, msg.sender, true);
    }

    function publicSale(uint256 numPieces) public payable {
        require(
            publicSaleActive() || msg.sender == owner(),
            "sale must be active"
        );
        require(
            numPieces <= MAX_MINTS_PER_PUBLIC_SALE,
            "cant mint that many at once"
        );
        require(msg.sender == tx.origin, "can not mint via contract");
        _makeArt(numPieces, msg.sender, true);
    }

    function amountLeft() public view returns (uint256) {
        return maxSupply - currentIndex;
    }

    function arweaveURI(uint256 tokenId) public view returns (string memory) {
        bytes32 seed = tokenIdToHash[tokenId];
        require(!(seed == bytes32(0)), "no hash found");
        return
            string(
                abi.encodePacked(
                    "ar://",
                    arweaveId,
                    "/?seed=0x",
                    toHexString(seed)
                )
            );
    }

    function withdrawEth() public {
        (bool sent, ) = withdrawalAddress.call{value: address(this).balance}(
            ""
        );
        require(sent, "send failed");
    }

    function tokenInfo(uint256 tokenId) public view returns (address, bytes32) {
        return (ownerOf(tokenId), tokenIdToHash[tokenId]);
    }

    function getOwners(uint256 start, uint256 end)
        public
        view
        returns (address[] memory)
    {
        address[] memory re = new address[](end - start);
        for (uint256 i = start; i < end; i++) {
            re[i - start] = ownerOf(i);
        }
        return re;
    }

    function getTokenHashes(uint256 start, uint256 end)
        public
        view
        returns (bytes32[] memory)
    {
        bytes32[] memory re = new bytes32[](end - start);
        for (uint256 i = start; i < end; i++) {
            re[i - start] = tokenIdToHash[i];
        }
        return re;
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(tokenId), "Nonexistent token");
        return (withdrawalAddress, (salePrice * royaltyFeeBp) / 10000);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function getSigner(
        address aCustomAddress,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) public pure returns (address) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 hash = keccak256(abi.encodePacked(aCustomAddress));
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, hash));
        return ecrecover(prefixedHash, v, r, s);
    }

    function presaleActive() public view returns (bool) {
        return block.timestamp >= presaleStartTime;
    }

    function publicSaleActive() public view returns (bool) {
        return block.timestamp >= publicStartTime;
    }

    // admin functions
    function setPresaleAuthorizer(address newAddress) public onlyOwner {
        presaleAuthorizer = newAddress;
    }

    function mintArtistProofs(address roninAddress) public onlyOwner {
        if (roninAddress != address(0)) {
            IRonin(roninAddress).mint();
        }
        require(totalSupply() == 0, "cant mint proofs more than once");
        _makeArt(NUM_ARTIST_PROOFS, msg.sender, false);
    }

    function setWithdrawalAddress(address payable givenWithdrawalAddress)
        public
        onlyOwner
    {
        withdrawalAddress = givenWithdrawalAddress;
    }

    function setArtLicense(string memory _artLicense) public onlyOwner {
        artLicense = _artLicense;
    }

    function setBaseUri(string memory newBaseUri) public onlyOwner {
        require(!artLocked, "metadata locked");
        baseUri = newBaseUri;
    }

    function setPresaleStartTime(uint256 _presaleStartTime) public onlyOwner {
        presaleStartTime = _presaleStartTime;
    }

    function setPublicStartTime(uint256 _publicStartTime) public onlyOwner {
        publicStartTime = _publicStartTime;
    }

    function setArweaveId(string memory newArweaveId) public onlyOwner {
        require(!artLocked, "metadata locked");
        arweaveId = newArweaveId;
    }

    function lockArt() public onlyOwner {
        artLocked = true;
    }

    function setRoyaltyFeeBp(uint256 _royaltyFeeBp) public onlyOwner {
        royaltyFeeBp = _royaltyFeeBp;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    function _makeArt(
        uint256 numPieces,
        address mintTo,
        bool requirePayment
    ) private {
        require(amountLeft() >= numPieces, "sold out");
        if (requirePayment) {
            require(
                msg.value == numPieces * pricePerPiece,
                "must send in correct amount"
            );
        }

        uint256 startIndex = currentIndex;
        uint256 endIndex = startIndex + numPieces;
        _safeMint(mintTo, numPieces);
        _assignPsuedoRandomHashes(startIndex, endIndex);
        emit ArtCreated(mintTo, numPieces, startIndex);
    }

    function _assignPsuedoRandomHashes(uint256 startIndex, uint256 endIndex)
        private
    {
        for (uint256 i = startIndex; i < endIndex; i++) {
            tokenIdToHash[i] = hashGenerator.generateHash(i);
        }
    }
}