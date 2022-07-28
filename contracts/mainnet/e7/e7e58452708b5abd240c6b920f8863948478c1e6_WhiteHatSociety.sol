/**
 *Submitted for verification at Etherscan.io on 2022-07-28
*/

/*

   _    _ _     _ _         _   _       _
  | |  | | |   (_) |       | | | |     | |
  | |  | | |__  _| |_ ___  | |_| | __ _| |_
  | |/\| | '_ \| | __/ _ \ |  _  |/ _` | __|
  \  /\  / | | | | ||  __/ | | | | (_| | |_
   \/  \/|_| |_|_|\__\___| \_| |_/\__,_|\__|

     _____            _      _
    /  ___|          (_)    | |
    \ `--.  ___   ___ _  ___| |_ _   _
     `--. \/ _ \ / __| |/ _ \ __| | | |
    /\__/ / (_) | (__| |  __/ |_| |_| |
    \____/ \___/ \___|_|\___|\__|\__, |
                                  __/ |
                                 |___/
 */

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

pragma solidity ^0.8.0;

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
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
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
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

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

pragma solidity ^0.8.0;

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
    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

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
        // solhint-disable-next-line no-inline-assembly
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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return _verifyCallResult(success, returndata, errorMessage);
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

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
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

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


pragma solidity ^0.8.0;

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata and Enumerable extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at 0 (e.g. 0, 1, 2, 3..).
 *
 * Assumes the number of issuable tokens (collection size) is capped and fits in a uint128.
 *
 * Does not support burning tokens to address(0).
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

    uint256 private currentIndex = 1; // tokenID starts at 1

    uint256 internal immutable collectionSize;
    uint256 internal immutable maxBatchSize;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned. See ownershipOf implementation for details.
    mapping(uint256 => TokenOwnership) private _ownerships;

    // Mapping owner address to address data
    mapping(address => AddressData) private _addressData;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev
     * `maxBatchSize` refers to how much a minter can mint at a time.
     * `collectionSize_` refers to how many tokens are in the collection.
     */
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 maxBatchSize_,
        uint256 collectionSize_
    ) {
        require(
            collectionSize_ > 0,
            "ERC721A: collection must have a nonzero supply"
        );
        require(maxBatchSize_ > 0, "ERC721A: max batch size must be nonzero");
        _name = name_;
        _symbol = symbol_;
        maxBatchSize = maxBatchSize_;
        collectionSize = collectionSize_;
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
     * This read function is O(collectionSize). If calling from a separate contract, be sure to test gas first.
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
            bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI)) : "";
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
     * - there must be `quantity` tokens remaining unminted in the total collection.
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

        _addressData[from].balance -= 1;
        _addressData[to].balance += 1;
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

    uint256 public nextOwnerToExplicitlySet = 0;

    /**
     * @dev Explicitly set `owners` to eliminate loops in future calls of ownerOf().
     */
    function _setOwnersExplicit(uint256 quantity) internal {
        uint256 oldNextOwnerToSet = nextOwnerToExplicitlySet;
        require(quantity > 0, "quantity must be nonzero");
        uint256 endIndex = oldNextOwnerToSet + quantity - 1;
        if (endIndex > collectionSize - 1) {
            endIndex = collectionSize - 1;
        }
        // We know if the last one in the group exists, all in the group exist, due to serial ordering.
        require(_exists(endIndex), "not enough minted yet for this cleanup");
        for (uint256 i = oldNextOwnerToSet; i <= endIndex; i++) {
            if (_ownerships[i].addr == address(0)) {
                TokenOwnership memory ownership = ownershipOf(i);
                _ownerships[i] = TokenOwnership(
                    ownership.addr,
                    ownership.startTimestamp
                );
            }
        }
        nextOwnerToExplicitlySet = endIndex + 1;
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

// White Hat Society Contract
pragma solidity ^0.8.0;

contract WhiteHatSociety is ERC721A, ReentrancyGuard, Ownable {
    uint256 public whsPrice = 150000000000000000;
    uint256 public whsWhitelistPrice = 0;
    uint256 public maxPurchase = 5;
    uint256 public maxWHSWhitelistPurchase = 1;
    uint256 public whsSupply = 333;
    bool public drop_is_active = false;
    bool public presale_is_active = true;
    string public baseURI =
        "https://ipfs.io/ipfs/QmRsQFraThPwP9LMwKgDNeU9ib7QH3Th1CEsM5yHxvaE21/";
    uint256 public tokensMinted = 0;

    mapping(address => uint256) addressesThatMinted;

    struct Whitelistaddr {
        uint256 presalemints;
        uint256 totalMintable;
    }
    mapping(address => Whitelistaddr) private whitelist;

    constructor() ERC721A("White Hat Society", "WHS", 24, 10000) {
        whitelist[0xE187F9D2abAd356D3Cd84fBb446766CB1dFDe5A4].totalMintable = 1;
        whitelist[0x92Cc17C86eBf30Cb1D80c6c7BA497F002E623647].totalMintable = 1;
        whitelist[0x32E9214342A6e1192ecb7b63f00147bc5768e3fC].totalMintable = 2;
        whitelist[0xCA17d8443b83AE0A68845F07ae2EA0b5424797F3].totalMintable = 1;
        whitelist[0x867Eb0804eACA9FEeda8a0E1d2B9a32eEF58AF8f].totalMintable = 5;
        whitelist[0x29F539c2Fb325e936268d67E17AfcA1281081d11].totalMintable = 1;
        whitelist[0x635F29E0597Fd2DF4697493aB255de1EC1a2Ff15].totalMintable = 1;
        whitelist[0x18416984583f1D6759DbAD170462964cA3869b19].totalMintable = 3;
        whitelist[0x78D3b056BF44600B719c1e43Ef3E0E356D55F6A3].totalMintable = 1;
        whitelist[0x53A30a9da0Fba35ab29C9E4D3568CF21a77bB35A].totalMintable = 1;
        whitelist[0x66E23e601252fb289207cEBf66079ceDE6dc4989].totalMintable = 1;
        whitelist[0x74014A03983DF37C03d713d384a057127DE407ba].totalMintable = 4;
        whitelist[0x5ED2698484c888C5701Bc0Af690ccA67F67Bc000].totalMintable = 3;
        whitelist[0xCB44375C6170e39224Ef6e91108F06019762948f].totalMintable = 1;
        whitelist[0xd82768B9877327bCb07E3CB6fe8fD638D9820EF3].totalMintable = 1;
        whitelist[0xB79bFeDcc95eF943a45f11FDF1D20fF879076519].totalMintable = 1;
        whitelist[0x56ae97EDfdab3b367E8e0DDcdB63A0C4072B96D2].totalMintable = 7;
        whitelist[0x46FADA17B8F2b8c0AD4DD5226205aB2eb0e72412].totalMintable = 1;
        whitelist[0x5814b1Dc4aC6fb5aDEC8F7607eEAE7dE3637A4DB].totalMintable = 2;
        whitelist[0x5f3ca358E464650327AD24DEf75f22494A349a28].totalMintable = 2;
        whitelist[0xDa1a6aF84084eabF1275baB59E9c0512DF882388].totalMintable = 1;
        whitelist[0x22a87d54140Fef7738A3BCD6E69fB5e7B6F13511].totalMintable = 2;
        whitelist[0x3287e54E5e82463b8BD154Eb5e9130A6eC9ff931].totalMintable = 2;
        whitelist[0x67D8a5eD6Da919EF750f1aC594AC30B0A1DDD185].totalMintable = 1;
        whitelist[0xDF965C23cdF6019dd848766e3813aFB915d034a6].totalMintable = 3;
        whitelist[0x2478D69DBD96F3832DA2475b0C0aD661c6D413B8].totalMintable = 1;
        whitelist[0x3c494B014E9e04982BcA7fB00D54c93b759bd17c].totalMintable = 1;
        whitelist[0xB68D316571c20836A9C5573D5A80CfF1c8c8616a].totalMintable = 1;
        whitelist[0xad5e2343950C305B2e942266D2CB8Eb633d9f7aC].totalMintable = 1;
        whitelist[0x0Cb41a27abC87004C89f5899C127302ffECcb1b7].totalMintable = 1;
        whitelist[0x40DF4dC41FC5DD7828B122cd2ad8f34EbDE86FD5].totalMintable = 1;
        whitelist[0xb376c5Fe53d7CfB6345DA5E96064bb54E5dA21E8].totalMintable = 1;
        whitelist[0xfebbB48C8f7A67Dc3DcEE19524A410E078e6A6a1].totalMintable = 2;
        whitelist[0x0dFdaaFac6ce581850EB5528186225DfC062F629].totalMintable = 2;
        whitelist[0xAC26B45B4675611C3e2FeF1D4a386d06E0a38252].totalMintable = 1;
        whitelist[0xeb72434931FaDE345454135e33dbc37C3C859DAf].totalMintable = 5;
        whitelist[0xd3F332cF93Cb42dBF4f39dF4001f157165eaC1E6].totalMintable = 2;
        whitelist[0xF42Bc1A36780275B0B410063546235b8B9B66321].totalMintable = 1;
        whitelist[0x6bB985e8f805b97Fa041bA4Fa187c68b5d24f649].totalMintable = 1;
        whitelist[0xB72eDF2669F2b05571aE4eE0E045D5927982b1a9].totalMintable = 1;
        whitelist[0x968137a1243e99A6D70afb8255F58191b26360a5].totalMintable = 1;
        whitelist[0xf421d973DeE1E7924446a8C7fbac2a86fB745cB7].totalMintable = 2;
        whitelist[0xe6Bd7D30192f63818c77ADD7073706c6d5491c50].totalMintable = 1;
        whitelist[0xe0FCaa3820c6900FfED4A0124fd4fAe95fdad63B].totalMintable = 1;
        whitelist[0x48c724c256C52994427ccDFBbfD7E9b93776acD5].totalMintable = 6;
        whitelist[0x390A7943c9ab9F7eDB64bc774d20C88cB7C52a13].totalMintable = 2;
        whitelist[0xd91fA1d8f18668d8f9E8c7D23FdAbe2b7478d9b9].totalMintable = 1;
        whitelist[0xa9f019ca11bB65Eb6BaC823B40a2d14D18eA5086].totalMintable = 1;
        whitelist[0x00B1bBdaf2cdE8bE977baAFba1e27E7CC624a37e].totalMintable = 7;
        whitelist[0x5BE48Eb33ecC783CE0dBf17Ce0d392bDC3D1C5de].totalMintable = 1;
        whitelist[0xCAa7a0D325c2F3DADB630Ede0e2eA29c63F299dc].totalMintable = 1;
        whitelist[0xf70e17b5aFdF83899f9f4cB7C7f9d56867D138c7].totalMintable = 2;
        whitelist[0x3CF09416ab8c7c65A53B0b892555F1bcf2116D59].totalMintable = 1;
        whitelist[0x873CB2F7b3d32BB61bEF7130F0E8C3730679dF1C].totalMintable = 1;
        whitelist[0xa9B5D98b0237EF498383a7bdeb3648b974BbF792].totalMintable = 1;
        whitelist[0xD5b226Fb75931Fd1C48268d06218dE94477f4570].totalMintable = 1;
        whitelist[0xC169abde4D2B6A1C4100065E5596155355dDE67B].totalMintable = 2;
        whitelist[0xd5d1c5daF1Ef2807b4033c169eCc0F7e1CbCdFf9].totalMintable = 2;
        whitelist[0x18651bC48BC18110C99332f63BB921Cf0592cA53].totalMintable = 2;
        whitelist[0xFBB0B893C32dac49A1Bf000fa3418ba9f6355fEd].totalMintable = 1;
        whitelist[0x5A7dCCed19ba3d4Bfa6A02e99d4Abc9192Cd0E94].totalMintable = 1;
        whitelist[0xF994079cE470990508a7e06A734B3A5424676b96].totalMintable = 1;
        whitelist[0x787E48216f48C007867548CcBA3009e549C134ac].totalMintable = 1;
        whitelist[0x24e90090DeDA09E90BC20d6448799fcC963310b5].totalMintable = 2;
        whitelist[0x045D6dccdf79417BA4DD30B080768d8f936a622b].totalMintable = 1;
        whitelist[0xB3Cc8d3510F16BcAa7F3fa7241Fef86A3e890C97].totalMintable = 1;
        whitelist[0x8f26AfAbeea47b00012c3bdF3E263531A3B6450B].totalMintable = 1;
        whitelist[0x23E887a3A1DA246a9573F5CF6E8f4b990eBD3882].totalMintable = 1;
        whitelist[0x876CcD8F591555950A2Ad84CE929029188521FC2].totalMintable = 1;
        whitelist[0xA3ECcfde47Ef7d7FA9BB63ff2D7A37D65Ed9db74].totalMintable = 1;
        whitelist[0xE8b719642B5568eC494C386f0B1921C0f28a3Da3].totalMintable = 1;
        whitelist[0x786bF31Ea4A20Ef7DDd8d48af9E917619d889c64].totalMintable = 1;
        whitelist[0xf208127D6325DaAa568f031709a31d198b08d0f5].totalMintable = 1;
        whitelist[0x56f322D0DCb001960e62084Cadd8Fa529D577F6D].totalMintable = 1;
        whitelist[0xa613DFE43b8f91596b1030CC45D184d398784D1a].totalMintable = 1;
        whitelist[0xBEd0F8b7916C3b0a49457aEb3E83866f8FF0396c].totalMintable = 1;
        whitelist[0xb0defa27fc5beF2C6Cb1D7b0688AEECD14Aadac6].totalMintable = 1;
        whitelist[0x4CFeaE8Ff622162FB3986fb6b84e98b4345463Ed].totalMintable = 1;
        whitelist[0x5382718773076C66198ee1a4fb82c2Ed47B362ED].totalMintable = 1;
        whitelist[0x1b5cD6c007fc6a3a3987b99ec9fB2da04aDadA37].totalMintable = 1;
        whitelist[0x1d8EDA4549e019947543F837f7AeD281AF8a3f8E].totalMintable = 1;
        whitelist[0xC336dA10207D220d4784f3FaCb472e98228Fc926].totalMintable = 1;
        whitelist[0x3813Ba8de772451B5459559011540F5BFc19432d].totalMintable = 1;
        whitelist[0x00Bd25cD3334becC3186122BD5F667c06035d685].totalMintable = 1;
        whitelist[0xA376012F41E6b4d954CC0e9564FF43efA6585424].totalMintable = 1;
        whitelist[0x5Cdfc54869b36E80b2BFd2a9694c5Fb955B38A57].totalMintable = 1;
        whitelist[0x47E7b362AC1599F8Ab9836dc90c336d7dcE03Ad5].totalMintable = 1;
        whitelist[0x011ea68c15f4a8316Da45C1E7844311CdD0ba149].totalMintable = 2;
        whitelist[0x86A41524CB61edd8B115A72Ad9735F8068996688].totalMintable = 1;
        whitelist[0x94F6FF0240208027cFdD28601Bfa7A852afF1f30].totalMintable = 1;
        whitelist[0x312069034526B68855fe7337688db76F483B1BD1].totalMintable = 1;
        whitelist[0x2F98Ecf871646583331Cd5Bc2610ea670C267E6A].totalMintable = 1;
        whitelist[0x9e189c74307412DC4cCc98D7a18a4C606962a509].totalMintable = 1;
        whitelist[0x9547C19FF5b3902EAF7aEb29A525D994F416A8E3].totalMintable = 3;
        whitelist[0x67122048B0438Dae0f6e3091fA3167b09AEaE429].totalMintable = 1;
        whitelist[0x6F2ADc5a75e69c03D6AceE4b7dF84AE042D028f5].totalMintable = 1;
        whitelist[0xae0FD53Dea8394dfFf614292414cA60139227395].totalMintable = 3;
        whitelist[0x445695072458697CBDA6921790fC21D90C4B3e3b].totalMintable = 1;
        whitelist[0x64b78C860ED090da88159F1Bf1120f322989B6BA].totalMintable = 1;
        whitelist[0x9D895a02D608c7752a2860361CBBaC4E9e381AcF].totalMintable = 1;
        whitelist[0xbf3356C71A7ad67Dc405E7BBb6e8C6203b952163].totalMintable = 1;
        whitelist[0xCbd591BA521a72b0B8769d7dD7Dbdf4d4bFDC0d8].totalMintable = 1;
        whitelist[0x4EA10E61b7F52dF9Bfba87BDa6e612AecA055DD8].totalMintable = 1;
        whitelist[0xAB8782298BB8c647562c8D80c794E6E013852f99].totalMintable = 1;
        whitelist[0xc19453DE69a553005927f1f290ba75CD4f12Fa14].totalMintable = 1;
        whitelist[0xFabD9765dE295A6EE5B554f4d7c5eA34f9Abec40].totalMintable = 2;
        whitelist[0x21BE2E221F72a93d4F1883A6976aDad7aa8fE1e4].totalMintable = 1;
        whitelist[0xC2F5dEF28DD3A7466837b32f5bbe69e048cfdD17].totalMintable = 1;
        whitelist[0x056F798FfFa350c69Ba4b7388Bd1bD3d2cb97e50].totalMintable = 1;
        whitelist[0x7d9999C75c5c33cb0247C4eB76F03Cb74c5Bd9eA].totalMintable = 1;
        whitelist[0x26B25401da77C9203f3f7D3ACB0a279eD8340b68].totalMintable = 1;
        whitelist[0xD5D30906f6CF5bc0682Ef355d970b10B43c752ab].totalMintable = 1;
    }

    function OnWhiteList(address walletaddr) public view returns (uint256) {
        //if (whitelist[msg.sender].totalMintable > 0) {
        return whitelist[walletaddr].totalMintable;
    }

    function addToWhiteList(address[] memory newWalletaddr, uint256 tmint)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < newWalletaddr.length; i++) {
            whitelist[newWalletaddr[i]].totalMintable = tmint;
        }
    }

    function withdraw() public onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    function flipDropState() public onlyOwner {
        drop_is_active = !drop_is_active;
    }

    function flipPresaleSate() public onlyOwner {
        presale_is_active = !presale_is_active;
    }

    function PresaleMint(uint256 numberOfTokens) public payable {
        require(
            presale_is_active,
            "Please wait until the Whitelist has opened!"
        );
        require(
            whitelist[msg.sender].totalMintable > 0,
            "This Wallet is not able mint for whitelist"
        );
        require(
            whitelist[msg.sender].presalemints + numberOfTokens <=
                whitelist[msg.sender].totalMintable,
            "This Wallet has already minted all whitelist nfts"
        );

        require(
            numberOfTokens > 0 && tokensMinted + numberOfTokens <= whsSupply,
            "Purchase would exceed current max whitelist supply"
        );

        require(
            msg.value >= whsWhitelistPrice * numberOfTokens,
            "Not enough ETH for NFTs"
        );
        addressesThatMinted[msg.sender] += numberOfTokens;
        whitelist[msg.sender].presalemints += numberOfTokens;

        _safeMint(msg.sender, numberOfTokens);
    }

    function mintWhiteHatSociety(uint256 numberOfTokens) public payable {
        require(
            drop_is_active,
            "Please wait until the Public sale is active to mint"
        );
        require(numberOfTokens > 0 && numberOfTokens <= maxPurchase);
        require(
            tokensMinted + numberOfTokens <= whsSupply,
            "Purchase would exceed max supply of tokens"
        );
        require(
            msg.value >= whsPrice * numberOfTokens,
            "ETH value sent is too little for this many tokens"
        );
        require(
            ((addressesThatMinted[msg.sender] + numberOfTokens)) <= maxPurchase,
            "this would exceed mint max allowance"
        );

        addressesThatMinted[msg.sender] += numberOfTokens;

        _safeMint(msg.sender, numberOfTokens);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    function changeMintPrice(uint256 newPrice) public onlyOwner {
        // require(newPrice < whsPrice); removing mandate to go lower
        whsPrice = newPrice;
    }

    function changeWlMintPrice(uint256 newWlPrice) public onlyOwner {
        // require(newPrice < whsPrice); removing mandate to go lower
        whsWhitelistPrice = newWlPrice;
    }

    function changeMintSupply(uint256 newSupply) public onlyOwner {
        // require(newSupply < whsSupply); removing mandate to go lower
        require(newSupply > totalSupply());
        whsSupply = newSupply;
    }

    function changemaxPurchase(uint256 newmaxPurchase) public onlyOwner {
        maxPurchase = newmaxPurchase;
    }

    function changemaxWHSWhitelistPurchase(uint256 newmaxWHSWhitelistPurchase)
        public
        onlyOwner
    {
        maxWHSWhitelistPurchase = newmaxWHSWhitelistPurchase;
    }
}