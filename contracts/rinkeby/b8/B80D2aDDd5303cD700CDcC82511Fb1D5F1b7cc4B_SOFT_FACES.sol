pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract PriceConsumerV3 {
    AggregatorV3Interface internal priceFeed;

    constructor() {
        priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
    }

    function getLatestPrice() public view returns (int) {
        (
            ,
            /*uint80 roundID*/
            int price, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
            ,
            ,

        ) = priceFeed.latestRoundData();
        return price;
    }
}

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

// File: @openzeppelin/contracts/access/Ownable.sol

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// File: @openzeppelin/contracts/utils/Address.sol

// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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

// File: IERC2981.sol

pragma solidity ^0.8.0;

///
/// @dev Interface for the NFT Royalty Standard
///
interface IERC2981 is IERC165 {
    /// ERC165 bytes to add to interface array - set in parent contract
    /// implementing this standard
    ///
    /// bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
    /// bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    /// _registerInterface(_INTERFACE_ID_ERC2981);

    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _salePrice - the sale price of the NFT asset specified by _tokenId
    /// @return receiver - address of who should be sent the royalty payment
    /// @return royaltyAmount - the royalty payment amount for _salePrice
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
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

// File: @openzeppelin/contracts/token/ERC721/ERC721.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata, PriceConsumerV3 {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    int public _storedEthPrice;

    // Token symbol
    string private _symbol;

    bool public mintingActive;

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
        _storedEthPrice = 0;
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
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            owner != address(0),
            "ERC721: balance query for the zero address"
        );
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        address owner = _owners[tokenId];
        require(
            owner != address(0),
            "ERC721: owner query for nonexistent token"
        );
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
        return "data:application/json;base64,";
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
    function getApproved(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        require(
            _exists(tokenId),
            "ERC721: approved query for nonexistent token"
        );

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        _setApprovalForAll(_msgSender(), operator, approved);
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
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );

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
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
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
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
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
    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        require(
            _exists(tokenId),
            "ERC721: operator query for nonexistent token"
        );
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
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
        require(
            ERC721.ownerOf(tokenId) == from,
            "ERC721: transfer of token that is not own"
        );
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
            try
                IERC721Receiver(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    _data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "ERC721: transfer to non ERC721Receiver implementer"
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

library Base64 {
    string internal constant TABLE_ENCODE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    bytes internal constant TABLE_DECODE =
        hex"0000000000000000000000000000000000000000000000000000000000000000"
        hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
        hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
        hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {

            } lt(dataPtr, endPtr) {

            } {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(18, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1)
                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(12, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1)
                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(6, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {

            } lt(dataPtr, endPtr) {

            } {
                // read 4 characters
                dataPtr := add(dataPtr, 4)
                let input := mload(dataPtr)

                // write 3 bytes
                let output := add(
                    add(
                        shl(
                            18,
                            and(
                                mload(add(tablePtr, and(shr(24, input), 0xFF))),
                                0xFF
                            )
                        ),
                        shl(
                            12,
                            and(
                                mload(add(tablePtr, and(shr(16, input), 0xFF))),
                                0xFF
                            )
                        )
                    ),
                    add(
                        shl(
                            6,
                            and(
                                mload(add(tablePtr, and(shr(8, input), 0xFF))),
                                0xFF
                            )
                        ),
                        and(mload(add(tablePtr, and(input, 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}

import "./makeArt.sol";

// File: @openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _faces;
    mapping(uint256 => string) private _colors;
    mapping(uint256 => string) private _eyeDistance;
    mapping(uint256 => uint256) private _mouthSize;
    mapping(string => bool) private _doesFaceExist;
    mapping(uint256 => uint256) private _speed;
    mapping(uint256 => uint256) private _blur;
    mapping(uint256 => uint256) private _birthday;
    uint256 private pokeDay;
    string private pokeEmotion;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */

    function uint2str(uint _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function concatenate(string memory a, string memory b)
        public
        pure
        returns (string memory)
    {
        return string(abi.encodePacked(a, "", b));
    }

    function toUint256(bytes memory _bytes)
        internal
        pure
        returns (uint256 value)
    {
        assembly {
            value := mload(add(_bytes, 0x20))
        }
    }

    function getSlice(
        uint256 begin,
        uint256 end,
        string memory text
    ) public pure returns (string memory) {
        bytes memory a = new bytes(end - begin + 1);
        for (uint i = 0; i <= end - begin; i++) {
            a[i] = bytes(text)[i + begin - 1];
        }
        return string(a);
    }

    function calcEmotion(uint256 tokenId) public view returns (string memory) {
        //420
        if (getMonth(block.timestamp) == 4 && getDay(block.timestamp) == 20) {
            return ("420");
        }

        //poked emotion
        if (
            (getYear(block.timestamp - pokeDay) == 1970) && (getMonth(block.timestamp - pokeDay) == 1) && (getDay((block.timestamp) - pokeDay) == 1)
        ) {
            return (pokeEmotion);
        }

        //birthday celebration
        bool isTodayBirthday = isBirthday();
        if (isTodayBirthday == true) {
            if (
                getMonth(block.timestamp) == getMonth(_birthday[tokenId]) &&
                getDay(block.timestamp) == getDay(_birthday[tokenId]) &&
                getDay(block.timestamp) == getDay(_birthday[tokenId])
            ) {
                return "celebrating";
            } else {
                return "celebrated";
            }
        }

        int percentChange = comparePrices();
        if (getDay(block.timestamp) == 1 || getDay(block.timestamp) == 15) {
            if (percentChange > 20) {
                return ("superHappy");
            } else if ((percentChange > 0) && (percentChange <= 20)) {
                return ("happy");
            } else if (percentChange == 0) {
                return ("neutral");
            } else if ((percentChange < 0) && (percentChange >= -20)) {
                return ("sad");
            } else {
                return ("superSad");
            }
        }
        return _faces[tokenId];
    }

    Art art = new Art();

    struct _DateTime {
        uint16 year;
        uint8 month;
        uint8 day;
        uint8 hour;
        uint8 minute;
        uint8 second;
        uint8 weekday;
    }

    uint constant DAY_IN_SECONDS = 86400;
    uint constant YEAR_IN_SECONDS = 31536000;
    uint constant LEAP_YEAR_IN_SECONDS = 31622400;

    uint constant HOUR_IN_SECONDS = 3600;
    uint constant MINUTE_IN_SECONDS = 60;

    uint16 constant ORIGIN_YEAR = 1970;

    function leapYearsBefore(uint year) public pure returns (uint) {
        year -= 1;
        return year / 4 - year / 100 + year / 400;
    }

    function getDaysInMonth(uint8 month, uint16 year)
        public
        pure
        returns (uint8)
    {
        if (
            month == 1 ||
            month == 3 ||
            month == 5 ||
            month == 7 ||
            month == 8 ||
            month == 10 ||
            month == 12
        ) {
            return 31;
        } else if (month == 4 || month == 6 || month == 9 || month == 11) {
            return 30;
        } else if (isLeapYear(year)) {
            return 29;
        } else {
            return 28;
        }
    }

    function getHour(uint timestamp) private pure returns (uint8) {
        return uint8((timestamp / 60 / 60) % 24);
    }

    function getMinute(uint timestamp) private pure returns (uint8) {
        return uint8((timestamp / 60) % 60);
    }

    function getSecond(uint timestamp) private pure returns (uint8) {
        return uint8(timestamp % 60);
    }

    function getWeekday(uint timestamp) private pure returns (uint8) {
        return uint8((timestamp / DAY_IN_SECONDS + 4) % 7);
    }

    function parseTimestamp(uint timestamp)
        internal
        pure
        returns (_DateTime memory dt)
    {
        uint secondsAccountedFor = 0;
        uint buf;
        uint8 i;

        // Year
        dt.year = getYear(timestamp);
        buf = leapYearsBefore(dt.year) - leapYearsBefore(ORIGIN_YEAR);

        secondsAccountedFor += LEAP_YEAR_IN_SECONDS * buf;
        secondsAccountedFor += YEAR_IN_SECONDS * (dt.year - ORIGIN_YEAR - buf);

        // Month
        uint secondsInMonth;
        for (i = 1; i <= 12; i++) {
            secondsInMonth = DAY_IN_SECONDS * getDaysInMonth(i, dt.year);
            if (secondsInMonth + secondsAccountedFor > timestamp) {
                dt.month = i;
                break;
            }
            secondsAccountedFor += secondsInMonth;
        }

        // Day
        for (i = 1; i <= getDaysInMonth(dt.month, dt.year); i++) {
            if (DAY_IN_SECONDS + secondsAccountedFor > timestamp) {
                dt.day = i;
                break;
            }
            secondsAccountedFor += DAY_IN_SECONDS;
        }

        // Hour
        dt.hour = getHour(timestamp);

        // Minute
        dt.minute = getMinute(timestamp);

        // Second
        dt.second = getSecond(timestamp);

        // Day of week.
        dt.weekday = getWeekday(timestamp);
    }

    function getYear(uint timestamp) private pure returns (uint16) {
        uint secondsAccountedFor = 0;
        uint16 year;
        uint numLeapYears;

        // Year
        year = uint16(ORIGIN_YEAR + timestamp / YEAR_IN_SECONDS);
        numLeapYears = leapYearsBefore(year) - leapYearsBefore(ORIGIN_YEAR);

        secondsAccountedFor += LEAP_YEAR_IN_SECONDS * numLeapYears;
        secondsAccountedFor +=
            YEAR_IN_SECONDS *
            (year - ORIGIN_YEAR - numLeapYears);

        while (secondsAccountedFor > timestamp) {
            if (isLeapYear(uint16(year - 1))) {
                secondsAccountedFor -= LEAP_YEAR_IN_SECONDS;
            } else {
                secondsAccountedFor -= YEAR_IN_SECONDS;
            }
            year -= 1;
        }
        return year;
    }

    function getMonth(uint timestamp) private pure returns (uint8) {
        return parseTimestamp(timestamp).month;
    }

    function getDay(uint timestamp) private pure returns (uint8) {
        return parseTimestamp(timestamp).day;
    }

    function isLeapYear(uint16 year) private pure returns (bool) {
        if (year % 4 != 0) {
            return false;
        }
        if (year % 100 != 0) {
            return true;
        }
        if (year % 400 != 0) {
            return false;
        }
        return true;
    }

    function timestamp2year(uint timestamp) public pure returns (uint16) {
        uint secondsAccountedFor = 0;
        uint16 year;
        uint numLeapYears;
        year = uint16(ORIGIN_YEAR + timestamp / YEAR_IN_SECONDS);
        numLeapYears = leapYearsBefore(year) - leapYearsBefore(ORIGIN_YEAR);
        secondsAccountedFor += LEAP_YEAR_IN_SECONDS * numLeapYears;
        secondsAccountedFor +=
            YEAR_IN_SECONDS *
            (year - ORIGIN_YEAR - numLeapYears);
        while (secondsAccountedFor > timestamp) {
            if (isLeapYear(uint16(year - 1))) {
                secondsAccountedFor -= LEAP_YEAR_IN_SECONDS;
            } else {
                secondsAccountedFor -= YEAR_IN_SECONDS;
            }
            year -= 1;
        }
        return year;
    }

    function getCurrentYear() private view  returns (uint256) {
        return (timestamp2year(block.timestamp));
    }

    function getTimeStamp() private view returns (uint256) {
        return (block.timestamp);
    }

    function isBirthday() public view returns (bool) {
        for (uint z = 0; z < 77; z++) {
            //require(_exists(z));
            if (
                getMonth(block.timestamp) == getMonth(_birthday[z]) &&
                getDay(block.timestamp) == getDay(_birthday[z])
            ) {
                return true;
            }
        }
        return false;
    }

    function comparePrices() public view  returns (int) {
        int result;
        int newPrice = getLatestPrice();
        int a = newPrice;
        int b = _storedEthPrice;
        result = ((a * 100) - (b * 100)) / b;
        return result;
    }

    function poke(string memory pokeEmo) public {
        pokeDay = block.timestamp;
        pokeEmotion = pokeEmo;
    }

    function st2num(string memory numString) public pure returns (uint) {
        uint val = 0;
        bytes memory stringBytes = bytes(numString);
        for (uint i = 0; i < stringBytes.length; i++) {
            uint exp = stringBytes.length - i;
            bytes1 ival = stringBytes[i];
            uint8 uval = uint8(ival);
            uint jval = uval - uint(0x30);
            val += (uint(jval) * (10**(exp - 1)));
        }
        return val;
    }

    function strIndex2num(string memory numString, uint256 index)
        public
        pure
        returns (uint)
    {
        bytes memory a = new bytes(1);
        a[0] = bytes(numString)[index];
        return st2num(string(a));
    }

    struct JsonInfo {
        string json;
        string artData;
        string colorValues;
        string[8] colorNameArray;
        string[3] speedArrayName;
    }

    function genArt(
        string memory emotion,
        string memory colors,
        string memory eyeDistance,
        uint256 mouthSz,
        uint256 faceSpeed,
        uint256 faceBlur
    ) public view virtual returns (string memory) {
        return
            art.makeArt(
                emotion,
                colors,
                eyeDistance,
                mouthSz,
                faceSpeed,
                faceBlur
            );
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721URIStorage: URI query for nonexistent token"
        );
        // If there is no base URI, return the token URI.

        JsonInfo memory jsonSlot;

        jsonSlot.colorNameArray[0] = "RED";
        jsonSlot.colorNameArray[1] = "ORANGE";
        jsonSlot.colorNameArray[2] = "YELLOW";
        jsonSlot.colorNameArray[3] = "GREEN";
        jsonSlot.colorNameArray[4] = "CYAN";
        jsonSlot.colorNameArray[5] = "BLUE";
        jsonSlot.colorNameArray[6] = "PURPLE";
        jsonSlot.colorNameArray[7] = "PINK";

        jsonSlot.speedArrayName[0] = "Hypo";
        jsonSlot.speedArrayName[1] = "Normal";
        jsonSlot.speedArrayName[2] = "Hyper";

        jsonSlot.colorValues = _colors[tokenId];
        jsonSlot.artData = art.makeArt(
            calcEmotion(tokenId),
            _colors[tokenId],
            _eyeDistance[tokenId],
            _mouthSize[tokenId],
            _speed[tokenId],
            _blur[tokenId]
        );
        jsonSlot.json = concatenate(
            unicode'{"description":"🟢 77 generative Soft Face NFTs that interact with each other on chain 🟣 Project by Damjanski 2022 🟡","external_url":"http://something.xyz", "name": "Soft Faces ◑◑ ',
            uint2str(tokenId)
        );
        jsonSlot.json = concatenate(
            jsonSlot.json,
            '", "image": "data:image/svg+xml;base64,'
        );
        jsonSlot.json = concatenate(
            jsonSlot.json,
            Base64.encode(bytes(jsonSlot.artData))
        );
        jsonSlot.json = concatenate(
            jsonSlot.json,
            '","attributes":[{"trait_type":"Mood","value":"'
        );
        jsonSlot.json = concatenate(jsonSlot.json, _faces[tokenId]);
        jsonSlot.json = concatenate(
            jsonSlot.json,
            '"},{"trait_type":"Color_1","value":"'
        );
        jsonSlot.json = concatenate(
            jsonSlot.json,
            (jsonSlot.colorNameArray[strIndex2num(jsonSlot.colorValues, 0)])
        );
        jsonSlot.json = concatenate(
            jsonSlot.json,
            '"},{"trait_type":"Color_2","value":"'
        );
        jsonSlot.json = concatenate(
            jsonSlot.json,
            (jsonSlot.colorNameArray[strIndex2num(jsonSlot.colorValues, 1)])
        );
        jsonSlot.json = concatenate(
            jsonSlot.json,
            '"},{"trait_type":"Color_3","value":"'
        );
        jsonSlot.json = concatenate(
            jsonSlot.json,
            (jsonSlot.colorNameArray[strIndex2num(jsonSlot.colorValues, 2)])
        );
        jsonSlot.json = concatenate(
            jsonSlot.json,
            '"},{"trait_type":"Color_4","value":"'
        );
        jsonSlot.json = concatenate(
            jsonSlot.json,
            (jsonSlot.colorNameArray[strIndex2num(jsonSlot.colorValues, 3)])
        );
        jsonSlot.json = concatenate(
            jsonSlot.json,
            '"},{"trait_type":"Color_5","value":"'
        );
        jsonSlot.json = concatenate(
            jsonSlot.json,
            (jsonSlot.colorNameArray[strIndex2num(jsonSlot.colorValues, 4)])
        );
        jsonSlot.json = concatenate(
            jsonSlot.json,
            '"},{"trait_type":"Animation","value":"'
        );
        jsonSlot.json = concatenate(
            jsonSlot.json,
            jsonSlot.speedArrayName[_speed[tokenId]]
        );
        jsonSlot.json = concatenate(
            jsonSlot.json,
            '"},{"trait_type":"Blur","value":"Level '
        );
        jsonSlot.json = concatenate(
            jsonSlot.json,
            uint2str(_blur[tokenId] + 1)
        );
        jsonSlot.json = concatenate(jsonSlot.json, '"}]}');

        return
            string(
                abi.encodePacked(
                    _baseURI(),
                    Base64.encode(bytes(string(jsonSlot.json)))
                )
            );
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */

    

    function _setFace(uint256 tokenId, string memory _emotion)
        internal
        virtual
    {
        require(
            _exists(tokenId),
            "ERC721URIStorage: URI set of nonexistent token"
        );
        _faces[tokenId] = _emotion;
    }

    function _setColors(uint256 tokenId, string memory _colorCode)
        internal
        virtual
    {
        require(
            _exists(tokenId),
            "ERC721URIStorage: URI set of nonexistent token"
        );
        _colors[tokenId] = _colorCode;
    }

    function _setEyeDistance(uint256 tokenId, string memory _eyeDis)
        internal
        virtual
    {
        require(
            _exists(tokenId),
            "ERC721URIStorage: URI set of nonexistent token"
        );
        _eyeDistance[tokenId] = _eyeDis;
    }

    function _setMouthSize(uint256 tokenId, uint256 _mouthSz) internal virtual {
        require(
            _exists(tokenId),
            "ERC721URIStorage: URI set of nonexistent token"
        );
        _mouthSize[tokenId] = _mouthSz;
    }

    function _setSpeed(uint256 tokenId, uint256 _faceSpeed) internal virtual {
        require(
            _exists(tokenId),
            "ERC721URIStorage: URI set of nonexistent token"
        );
        _speed[tokenId] = _faceSpeed;
    }

    function _setBlur(uint256 tokenId, uint256 _faceBlur) internal virtual {
        require(
            _exists(tokenId),
            "ERC721URIStorage: URI set of nonexistent token"
        );
        _blur[tokenId] = _faceBlur;
    }

    function _setBirthday(uint256 tokenId) internal virtual {
        require(
            _exists(tokenId),
            "ERC721URIStorage: URI set of nonexistent token"
        );
        _birthday[tokenId] = block.timestamp;
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
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);
    }
}

// File: Token.sol

pragma solidity ^0.8.0;

/**
 * @title Sample NFT contract
 * @dev Extends ERC-721 NFT contract and implements ERC-2981
 */

contract SOFT_FACES is Ownable, ERC721URIStorage {
    // Keep a mapping of token ids and corresponding IPFS hashes
    mapping(string => uint8) hashes;
    // Maximum amounts of mintable tokens
    uint256 public constant MAX_SUPPLY = 77;
    // Address of the royalties recipient
    address private _royaltiesReceiver;
    // Percentage of each sale to pay as royalties
    uint256 public constant royaltiesPercentage = 10;
    string private pokeEmotion;

    mapping(address => uint) public artBalance;

    mapping(address => bool) private greenListMap;

    uint256 private totalSupply;

    // Events
    event Mint(uint256 tokenId, address recipient);

    constructor(address initialRoyaltiesReceiver)
        ERC721("SOFT_FACES", "SFTFCS")
    {
        _royaltiesReceiver = initialRoyaltiesReceiver;
        artBalance[address(this)] = MAX_SUPPLY;
    }

    /** Overrides ERC-721's _baseURI function */
    function _baseURI() internal pure override returns (string memory) {
        return "data:application/json;base64,";
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC721) {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _burn(uint256 tokenId) internal override(ERC721URIStorage) {
        super._burn(tokenId);
    }

    /// @notice Getter function for _royaltiesReceiver
    /// @return the address of the royalties recipient
    function royaltiesReceiver() external view returns (address) {
        return _royaltiesReceiver;
    }

    /// @notice Changes the royalties' recipient address (in case rights are
    ///         transferred for instance)
    /// @param newRoyaltiesReceiver - address of the new royalties recipient
    function setRoyaltiesReceiver(address newRoyaltiesReceiver)
        external
        onlyOwner
    {
        require(newRoyaltiesReceiver != _royaltiesReceiver); // dev: Same address
        _royaltiesReceiver = newRoyaltiesReceiver;
    }

    /// @notice Returns a token's URI
    /// @dev See {IERC721Metadata-tokenURI}.
    /// @param tokenId - the id of the token whose URI to return
    /// @return a string containing an URI pointing to the token's ressource
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    /// @notice Informs callers that this contract supports ERC2981
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// @notice Returns all the tokens owned by an address
    /// @param _owner - the address to query
    /// @return ownerTokens - an array containing the ids of all tokens
    ///         owned by the address

    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _salePrice - sale price of the NFT asset specified by _tokenId
    /// @return receiver - address of who should be sent the royalty payment
    /// @return royaltyAmount - the royalty payment amount for _value sale price
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        uint256 _royalties = (_salePrice * royaltiesPercentage) / 100;
        return (_royaltiesReceiver, _royalties);
    }

    function greenList(address[] memory addresses, uint size) public onlyOwner returns (uint) {
        for (uint i = 0; i < size; i++) {
            greenListMap[addresses[i]] = true;
        }
    }

    function mint(
        string memory emotion,
        string memory faceColors,
        string memory eyeDist,
        uint256 mouthSize,
        uint256 faceSpeed,
        uint256 faceBlur
    ) external payable {
        require(mintingActive || msg.sender == owner(), "Minting is paused");
        if (greenListMap[msg.sender] != true ||  artBalance[msg.sender] != 0) {
            require(
                msg.value >= 20000000000000000 wei,
                "You must pay at least 0.02 Eth per art"
            );
        }
        _safeMint(msg.sender, totalSupply + 1);
        _setFace(totalSupply + 1, emotion);
        _setColors(totalSupply + 1, faceColors);
        _setEyeDistance(totalSupply + 1, eyeDist);
        _setMouthSize(totalSupply + 1, mouthSize);
        _setSpeed(totalSupply + 1, faceSpeed);
        _setBlur(totalSupply + 1, faceBlur);
        _setBirthday(totalSupply + 1);
        totalSupply += 1;
        artBalance[address(this)] -= 1;
        artBalance[msg.sender] += 1;
    }

    function setMintingActive(bool isMintingActive) public onlyOwner {
        mintingActive = isMintingActive;
    }

    function updateEthPrice() public onlyOwner {
        _storedEthPrice = getLatestPrice();
    }

    function withdraw(uint amount) public onlyOwner returns (bool) {
        require(amount <= address(this).balance);
        address someone = msg.sender;
        payable(someone).transfer(amount);
        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

pragma solidity ^0.8.7;

contract Art {
    function uint2str(uint _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function st2num(string memory numString) public pure returns (uint) {
        uint val = 0;
        bytes memory stringBytes = bytes(numString);
        for (uint i = 0; i < stringBytes.length; i++) {
            uint exp = stringBytes.length - i;
            bytes1 ival = stringBytes[i];
            uint8 uval = uint8(ival);
            uint jval = uval - uint(0x30);
            val += (uint(jval) * (10**(exp - 1)));
        }
        return val;
    }

    function strIndex2num(string memory numString, uint256 index)
        public
        pure
        returns (uint)
    {
        bytes memory a = new bytes(1);
        a[0] = bytes(numString)[index];
        return st2num(string(a));
    }

    function concatenate(string memory a, string memory b)
        public
        pure
        returns (string memory)
    {
        return string(abi.encodePacked(a, "", b));
    }

    struct ArtData {
        string text;
        string[9] colorArray;
        string[3] speedArray;
        string[3] speedArrayTrajectory;
        string[7] blurArray;
    }

    function makeArt(
        string memory emotion,
        string memory colors,
        string memory eyeDistance,
        uint256 mouthSz,
        uint256 faceSpeed,
        uint256 faceBlur
    ) public view virtual returns (string memory) {
        ArtData memory artDataSlot;
        artDataSlot.colorArray[0] = "#FF0000";
        artDataSlot.colorArray[1] = "#FF7D00";
        artDataSlot.colorArray[2] = "#FFFF00";
        artDataSlot.colorArray[3] = "#00FF00";
        artDataSlot.colorArray[4] = "#00FFFF";
        artDataSlot.colorArray[5] = "#0000FF";
        artDataSlot.colorArray[6] = "#5A00FF";
        artDataSlot.colorArray[7] = "#FF00FF";
        artDataSlot.colorArray[8] = "#000000";

        artDataSlot.blurArray[0] = "15";
        artDataSlot.blurArray[1] = "20";
        artDataSlot.blurArray[2] = "25";
        artDataSlot.blurArray[3] = "30";
        artDataSlot.blurArray[4] = "35";
        artDataSlot.blurArray[5] = "40";
        artDataSlot.blurArray[6] = "45";

        artDataSlot.speedArray[0] = "6";
        artDataSlot.speedArray[1] = "4";
        artDataSlot.speedArray[2] = "2";

        artDataSlot.speedArrayTrajectory[
                0
            ] = "M 0 0 l 30 -30 z l 0 30 z l -20 -40 z";
        artDataSlot.speedArrayTrajectory[
                1
            ] = "M 0 0 l 40 30 z l 30 0 z l 20 40 z";
        artDataSlot.speedArrayTrajectory[
                2
            ] = "M 40 40 l -40 -20 z l 30 -30 z l 20 -40 z";

        artDataSlot.text = concatenate(
            '<svg height="500" width="500" xmlns="http://www.w3.org/2000/svg"><defs><filter id="f1" x="-40%" y="-60%" width="800%" height="800%"><feGaussianBlur in="SourceGraphic" stdDeviation="',
            artDataSlot.blurArray[faceBlur]
        );
        artDataSlot.text = concatenate(
            artDataSlot.text,
            '" /></filter><filter id="f2" x="-100%" y="-150%" width="800%" height="800%"><feGaussianBlur in="SourceGraphic" stdDeviation="15" /></filter><filter id="f3" x="-100%" y="-90%" width="12000%" height="12000%"><feGaussianBlur in="SourceGraphic" stdDeviation="20" /></filter></defs><rect width="100%" height="100%" fill="'
        );
        artDataSlot.text = concatenate(
            artDataSlot.text,
            artDataSlot.colorArray[strIndex2num(colors, 0)]
        );
        artDataSlot.text = concatenate(
            artDataSlot.text,
            '" /><g><circle cx="250" cy="250" r="230" fill="'
        );
        artDataSlot.text = concatenate(
            artDataSlot.text,
            artDataSlot.colorArray[strIndex2num(colors, 1)]
        );
        artDataSlot.text = concatenate(
            artDataSlot.text,
            '" filter="url(#f1)" /><animateMotion dur="'
        );
        artDataSlot.text = concatenate(
            artDataSlot.text,
            artDataSlot.speedArray[faceSpeed]
        );
        artDataSlot.text = concatenate(
            artDataSlot.text,
            's" repeatCount="indefinite" path="'
        );
        artDataSlot.text = concatenate(
            artDataSlot.text,
            artDataSlot.speedArrayTrajectory[faceSpeed]
        );
        artDataSlot.text = concatenate(artDataSlot.text, '" /></g>');

        if (keccak256(bytes(emotion)) == keccak256(bytes("happy"))) {
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '<g><g transform="translate(-'
            );
            artDataSlot.text = concatenate(artDataSlot.text, eyeDistance);
            artDataSlot.text = concatenate(
                artDataSlot.text,
                ')"><circle cx="180" cy="200" r="35" fill="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 2)]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" filter="url(#f3)" /><circle cx="180" cy="200" r="28" fill="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 3)]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" filter="url(#f2)" /></g><g transform="translate('
            );
            artDataSlot.text = concatenate(artDataSlot.text, eyeDistance);
            artDataSlot.text = concatenate(
                artDataSlot.text,
                ')"><circle cx="320" cy="200" r="35" fill="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 2)]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" filter="url(#f3)" /><circle cx="320" cy="200" r="28" fill="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 3)]
            );

            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" filter="url(#f2)" /></g><path d="M'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                uint2str(160 - mouthSz)
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                ",300 C200,380 300,380 "
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                uint2str(340 + mouthSz)
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                ',300" fill="none" stroke="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 4)]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" stroke-width="40px" stroke-linecap="round" filter="url(#f2)"/><animateMotion dur="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.speedArray[faceSpeed]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '.25s" repeatCount="indefinite" path="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.speedArrayTrajectory[faceSpeed]
            );
            artDataSlot.text = concatenate(artDataSlot.text, '" /></g></svg>');
            return artDataSlot.text;
        } else if (
            keccak256(bytes(emotion)) == keccak256(bytes("superHappy"))
        ) {
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '<g><g transform="translate('
            );
            artDataSlot.text = concatenate(artDataSlot.text, eyeDistance);
            artDataSlot.text = concatenate(
                artDataSlot.text,
                ')"><path d="M330.975 215a9.141 9.141 0 0 1-3.454-.676 9.038 9.038 0 0 1-2.928-1.924 8.89 8.89 0 0 1-1.957-2.881 8.764 8.764 0 0 1-.687-3.398c0-5.14-1.422-9.288-4.108-11.991a11.446 11.446 0 0 0-3.778-2.512 11.594 11.594 0 0 0-4.475-.859c-8.664 0-12.537 7.715-12.537 15.362a8.808 8.808 0 0 1-2.644 6.279 9.1 9.1 0 0 1-6.382 2.6 9.104 9.104 0 0 1-6.382-2.6 8.811 8.811 0 0 1-2.643-6.279c0-12.431 5.076-20.132 9.336-24.39a29.602 29.602 0 0 1 9.727-6.485A30.01 30.01 0 0 1 309.588 173C324.7 173 340 184.366 340 206.121a8.746 8.746 0 0 1-.687 3.398 8.888 8.888 0 0 1-1.956 2.881 9.049 9.049 0 0 1-2.928 1.924 9.141 9.141 0 0 1-3.454.676Z" fill="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 2)]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" filter="url(#f3)" /><path d="M209.975 215a9.141 9.141 0 0 1-3.454-.676 9.038 9.038 0 0 1-2.928-1.924 8.89 8.89 0 0 1-1.957-2.881 8.764 8.764 0 0 1-.687-3.398c0-5.14-1.422-9.288-4.108-11.991a11.446 11.446 0 0 0-3.778-2.512 11.594 11.594 0 0 0-4.475-.859c-8.664 0-12.537 7.715-12.537 15.362a8.808 8.808 0 0 1-2.644 6.279 9.1 9.1 0 0 1-6.382 2.6 9.104 9.104 0 0 1-6.382-2.6 8.811 8.811 0 0 1-2.643-6.279c0-12.431 5.076-20.132 9.336-24.39a29.602 29.602 0 0 1 9.727-6.485A30.01 30.01 0 0 1 188.588 173C203.7 173 219 184.366 219 206.121a8.746 8.746 0 0 1-.687 3.398 8.888 8.888 0 0 1-1.956 2.881 9.049 9.049 0 0 1-2.928 1.924 9.141 9.141 0 0 1-3.454.676Z" fill="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 3)]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" filter="url(#f2)" /></g><g transform="translate(-'
            );
            artDataSlot.text = concatenate(artDataSlot.text, eyeDistance);
            artDataSlot.text = concatenate(
                artDataSlot.text,
                ')"><path d="M209.975 215a9.141 9.141 0 0 1-3.454-.676 9.038 9.038 0 0 1-2.928-1.924 8.89 8.89 0 0 1-1.957-2.881 8.764 8.764 0 0 1-.687-3.398c0-5.14-1.422-9.288-4.108-11.991a11.446 11.446 0 0 0-3.778-2.512 11.594 11.594 0 0 0-4.475-.859c-8.664 0-12.537 7.715-12.537 15.362a8.808 8.808 0 0 1-2.644 6.279 9.1 9.1 0 0 1-6.382 2.6 9.104 9.104 0 0 1-6.382-2.6 8.811 8.811 0 0 1-2.643-6.279c0-12.431 5.076-20.132 9.336-24.39a29.602 29.602 0 0 1 9.727-6.485A30.01 30.01 0 0 1 188.588 173C203.7 173 219 184.366 219 206.121a8.746 8.746 0 0 1-.687 3.398 8.888 8.888 0 0 1-1.956 2.881 9.049 9.049 0 0 1-2.928 1.924 9.141 9.141 0 0 1-3.454.676Z" fill="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 2)]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" filter="url(#f3)" /><path d="M209.975 215a9.141 9.141 0 0 1-3.454-.676 9.038 9.038 0 0 1-2.928-1.924 8.89 8.89 0 0 1-1.957-2.881 8.764 8.764 0 0 1-.687-3.398c0-5.14-1.422-9.288-4.108-11.991a11.446 11.446 0 0 0-3.778-2.512 11.594 11.594 0 0 0-4.475-.859c-8.664 0-12.537 7.715-12.537 15.362a8.808 8.808 0 0 1-2.644 6.279 9.1 9.1 0 0 1-6.382 2.6 9.104 9.104 0 0 1-6.382-2.6 8.811 8.811 0 0 1-2.643-6.279c0-12.431 5.076-20.132 9.336-24.39a29.602 29.602 0 0 1 9.727-6.485A30.01 30.01 0 0 1 188.588 173C203.7 173 219 184.366 219 206.121a8.746 8.746 0 0 1-.687 3.398 8.888 8.888 0 0 1-1.956 2.881 9.049 9.049 0 0 1-2.928 1.924 9.141 9.141 0 0 1-3.454.676Z" fill="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 3)]
            );

            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" filter="url(#f2)" /></g><path d="M'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                uint2str(160 - mouthSz)
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                ",300 C200,380 300,380 "
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                uint2str(340 + mouthSz)
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                ',300" fill="none" stroke="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 4)]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" stroke-width="40px" stroke-linecap="round" filter="url(#f2)"/><animateMotion dur="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.speedArray[faceSpeed]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '.25s" repeatCount="indefinite" path="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.speedArrayTrajectory[faceSpeed]
            );
            artDataSlot.text = concatenate(artDataSlot.text, '" /></g></svg>');
            return artDataSlot.text;
        } else if (keccak256(bytes(emotion)) == keccak256(bytes("sad"))) {
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '<g><g transform="translate(-'
            );
            artDataSlot.text = concatenate(artDataSlot.text, eyeDistance);
            artDataSlot.text = concatenate(
                artDataSlot.text,
                ')"><circle cx="180" cy="200" r="35" fill="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 2)]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" filter="url(#f3)" /><circle cx="180" cy="200" r="28" fill="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 3)]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" filter="url(#f2)" /></g><g transform="translate('
            );
            artDataSlot.text = concatenate(artDataSlot.text, eyeDistance);
            artDataSlot.text = concatenate(
                artDataSlot.text,
                ')"><circle cx="320" cy="200" r="35" fill="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 2)]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" filter="url(#f3)" /><circle cx="320" cy="200" r="28" fill="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 3)]
            );

            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" filter="url(#f2)" /></g><path d="M'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                uint2str(170 - mouthSz)
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                ",350 C200,290 300,290 "
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                uint2str(330 + mouthSz)
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                ',350" fill="none" stroke="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 4)]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" stroke-width="40px" stroke-linecap="round" filter="url(#f2)"/><animateMotion dur="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.speedArray[faceSpeed]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '.25s" repeatCount="indefinite" path="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.speedArrayTrajectory[faceSpeed]
            );
            artDataSlot.text = concatenate(artDataSlot.text, '" /></g></svg>');
            return artDataSlot.text;
        } else if (keccak256(bytes(emotion)) == keccak256(bytes("superSad"))) {
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '<g><g transform="translate('
            );
            artDataSlot.text = concatenate(artDataSlot.text, eyeDistance);
            artDataSlot.text = concatenate(
                artDataSlot.text,
                ')"><path d="M288.025 199c1.185 0 2.359.229 3.454.676a9.038 9.038 0 0 1 2.928 1.924 8.89 8.89 0 0 1 1.957 2.881 8.764 8.764 0 0 1 .687 3.398c0 5.14 1.422 9.288 4.108 11.991a11.446 11.446 0 0 0 3.778 2.512c1.417.579 2.939.871 4.475.859 8.664 0 12.537-7.715 12.537-15.362 0-2.355.951-4.613 2.644-6.279a9.1 9.1 0 0 1 6.382-2.6c2.393 0 4.689.935 6.382 2.6a8.811 8.811 0 0 1 2.643 6.279c0 12.431-5.076 20.132-9.336 24.39a29.602 29.602 0 0 1-9.727 6.485A30.01 30.01 0 0 1 309.412 241C294.3 241 279 229.634 279 207.879c0-1.166.233-2.321.687-3.398a8.888 8.888 0 0 1 1.956-2.881 9.049 9.049 0 0 1 2.928-1.924 9.141 9.141 0 0 1 3.454-.676Z" fill="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 2)]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" filter="url(#f3)" /><path d="M288.025 199c1.185 0 2.359.229 3.454.676a9.038 9.038 0 0 1 2.928 1.924 8.89 8.89 0 0 1 1.957 2.881 8.764 8.764 0 0 1 .687 3.398c0 5.14 1.422 9.288 4.108 11.991a11.446 11.446 0 0 0 3.778 2.512c1.417.579 2.939.871 4.475.859 8.664 0 12.537-7.715 12.537-15.362 0-2.355.951-4.613 2.644-6.279a9.1 9.1 0 0 1 6.382-2.6c2.393 0 4.689.935 6.382 2.6a8.811 8.811 0 0 1 2.643 6.279c0 12.431-5.076 20.132-9.336 24.39a29.602 29.602 0 0 1-9.727 6.485A30.01 30.01 0 0 1 309.412 241C294.3 241 279 229.634 279 207.879c0-1.166.233-2.321.687-3.398a8.888 8.888 0 0 1 1.956-2.881 9.049 9.049 0 0 1 2.928-1.924 9.141 9.141 0 0 1 3.454-.676Z" fill="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 3)]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" filter="url(#f2)" /></g><g transform="translate(-'
            );
            artDataSlot.text = concatenate(artDataSlot.text, eyeDistance);
            artDataSlot.text = concatenate(
                artDataSlot.text,
                ')"><path d="M167.025 199c1.185 0 2.359.229 3.454.676a9.038 9.038 0 0 1 2.928 1.924 8.89 8.89 0 0 1 1.957 2.881 8.764 8.764 0 0 1 .687 3.398c0 5.14 1.422 9.288 4.108 11.991a11.446 11.446 0 0 0 3.778 2.512c1.417.579 2.939.871 4.475.859 8.664 0 12.537-7.715 12.537-15.362 0-2.355.951-4.613 2.644-6.279a9.1 9.1 0 0 1 6.382-2.6c2.393 0 4.689.935 6.382 2.6a8.811 8.811 0 0 1 2.643 6.279c0 12.431-5.076 20.132-9.336 24.39a29.602 29.602 0 0 1-9.727 6.485A30.01 30.01 0 0 1 188.412 241C173.3 241 158 229.634 158 207.879c0-1.166.233-2.321.687-3.398a8.888 8.888 0 0 1 1.956-2.881 9.049 9.049 0 0 1 2.928-1.924 9.141 9.141 0 0 1 3.454-.676Z" fill="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 2)]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" filter="url(#f3)" /><path d="M167.025 199c1.185 0 2.359.229 3.454.676a9.038 9.038 0 0 1 2.928 1.924 8.89 8.89 0 0 1 1.957 2.881 8.764 8.764 0 0 1 .687 3.398c0 5.14 1.422 9.288 4.108 11.991a11.446 11.446 0 0 0 3.778 2.512c1.417.579 2.939.871 4.475.859 8.664 0 12.537-7.715 12.537-15.362 0-2.355.951-4.613 2.644-6.279a9.1 9.1 0 0 1 6.382-2.6c2.393 0 4.689.935 6.382 2.6a8.811 8.811 0 0 1 2.643 6.279c0 12.431-5.076 20.132-9.336 24.39a29.602 29.602 0 0 1-9.727 6.485A30.01 30.01 0 0 1 188.412 241C173.3 241 158 229.634 158 207.879c0-1.166.233-2.321.687-3.398a8.888 8.888 0 0 1 1.956-2.881 9.049 9.049 0 0 1 2.928-1.924 9.141 9.141 0 0 1 3.454-.676Z" fill="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 3)]
            );

            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" filter="url(#f2)" /></g><path d="M'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                uint2str(170 - mouthSz)
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                ",350 C200,290 300,290 "
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                uint2str(330 + mouthSz)
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                ',350" fill="none" stroke="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 4)]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" stroke-width="40px" stroke-linecap="round" filter="url(#f2)"/><animateMotion dur="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.speedArray[faceSpeed]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '.25s" repeatCount="indefinite" path="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.speedArrayTrajectory[faceSpeed]
            );
            artDataSlot.text = concatenate(artDataSlot.text, '" /></g></svg>');
            return artDataSlot.text;
        } else if (keccak256(bytes(emotion)) == keccak256(bytes("angry"))) {
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '<g><g transform="translate('
            );
            artDataSlot.text = concatenate(artDataSlot.text, eyeDistance);
            artDataSlot.text = concatenate(
                artDataSlot.text,
                ')"><path d="m273 277 84-56v56h-84Z" fill="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 2)]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" filter="url(#f3)" /><path d="m273 277 84-56v56h-84Z" fill="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 3)]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" filter="url(#f2)" /></g><g transform="translate(-'
            );
            artDataSlot.text = concatenate(artDataSlot.text, eyeDistance);
            artDataSlot.text = concatenate(
                artDataSlot.text,
                ')"><path d="m227 277-84-56v56h84Z" fill="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 2)]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" filter="url(#f3)" /><path d="m227 277-84-56v56h84Z" fill="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 3)]
            );

            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" filter="url(#f2)" /></g><path d="M'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                uint2str(170 - mouthSz)
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                ",380 C200,320 300,320 "
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                uint2str(330 + mouthSz)
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                ',380" fill="none" stroke="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 4)]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" stroke-width="40px" stroke-linecap="round" filter="url(#f2)"/><animateMotion dur="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.speedArray[faceSpeed]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '.25s" repeatCount="indefinite" path="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.speedArrayTrajectory[faceSpeed]
            );
            artDataSlot.text = concatenate(artDataSlot.text, '" /></g></svg>');
            return artDataSlot.text;
        } else if (keccak256(bytes(emotion)) == keccak256(bytes("fearful"))) {
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '<g><g transform="translate(-'
            );
            artDataSlot.text = concatenate(artDataSlot.text, eyeDistance);
            artDataSlot.text = concatenate(
                artDataSlot.text,
                ')"><ellipse cx="206.5" cy="137" rx="17.5" ry="34" fill="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 2)]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" filter="url(#f3)" /><ellipse cx="206.5" cy="137" rx="17.5" ry="34" fill="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 3)]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" filter="url(#f2)" /></g><g transform="translate('
            );
            artDataSlot.text = concatenate(artDataSlot.text, eyeDistance);
            artDataSlot.text = concatenate(
                artDataSlot.text,
                ')"><ellipse rx="17.5" ry="34" cx="292.5" cy="137" fill="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 2)]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" filter="url(#f3)" /><ellipse rx="17.5" ry="34" cx="292.5" cy="137" fill="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 3)]
            );

            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" filter="url(#f2)" /></g><path d="M252 211c-18.035 0-35.331 16.857-48.083 46.863C191.164 287.869 184 328.565 184 371h136c0-21.011-1.759-41.817-5.176-61.229-3.418-19.412-8.426-37.051-14.741-51.908-6.314-14.857-13.81-26.643-22.061-34.684C269.772 215.138 260.93 211 252 211Z"'
            );
            artDataSlot.text = concatenate(artDataSlot.text, ' fill="');
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 4)]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" filter="url(#f2)"/><animateMotion dur="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.speedArray[faceSpeed]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '.25s" repeatCount="indefinite" path="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.speedArrayTrajectory[faceSpeed]
            );
            artDataSlot.text = concatenate(artDataSlot.text, '" /></g></svg>');
            return artDataSlot.text;
        } else if (keccak256(bytes(emotion)) == keccak256(bytes("confused"))) {
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '<g><g transform="translate(-'
            );
            artDataSlot.text = concatenate(artDataSlot.text, eyeDistance);
            artDataSlot.text = concatenate(
                artDataSlot.text,
                ')"><circle cx="196" cy="122" r="50" fill="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 2)]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" filter="url(#f3)" /><circle cx="196" cy="122" r="50" fill="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 3)]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" filter="url(#f2)" /></g><g transform="translate('
            );
            artDataSlot.text = concatenate(artDataSlot.text, eyeDistance);
            artDataSlot.text = concatenate(
                artDataSlot.text,
                ')"><circle cx="309" cy="129" r="27" fill="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 2)]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" filter="url(#f3)" /><circle cx="309" cy="129" r="27" fill="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 3)]
            );

            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" filter="url(#f2)" /></g><ellipse cx="250" cy="300"  rx="50" ry="91"'
            );
            artDataSlot.text = concatenate(artDataSlot.text, ' fill="');
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 4)]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" filter="url(#f2)"/><animateMotion dur="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.speedArray[faceSpeed]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '.25s" repeatCount="indefinite" path="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.speedArrayTrajectory[faceSpeed]
            );
            artDataSlot.text = concatenate(artDataSlot.text, '" /></g></svg>');
            return artDataSlot.text;
        } else if (
            keccak256(bytes(emotion)) == keccak256(bytes("celebrated"))
        ) {
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '<g><g transform="translate('
            );
            artDataSlot.text = concatenate(artDataSlot.text, eyeDistance);
            artDataSlot.text = concatenate(
                artDataSlot.text,
                ')"><path d="M330.975 215a9.141 9.141 0 0 1-3.454-.676 9.038 9.038 0 0 1-2.928-1.924 8.89 8.89 0 0 1-1.957-2.881 8.764 8.764 0 0 1-.687-3.398c0-5.14-1.422-9.288-4.108-11.991a11.446 11.446 0 0 0-3.778-2.512 11.594 11.594 0 0 0-4.475-.859c-8.664 0-12.537 7.715-12.537 15.362a8.808 8.808 0 0 1-2.644 6.279 9.1 9.1 0 0 1-6.382 2.6 9.104 9.104 0 0 1-6.382-2.6 8.811 8.811 0 0 1-2.643-6.279c0-12.431 5.076-20.132 9.336-24.39a29.602 29.602 0 0 1 9.727-6.485A30.01 30.01 0 0 1 309.588 173C324.7 173 340 184.366 340 206.121a8.746 8.746 0 0 1-.687 3.398 8.888 8.888 0 0 1-1.956 2.881 9.049 9.049 0 0 1-2.928 1.924 9.141 9.141 0 0 1-3.454.676Z" fill="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 2)]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" filter="url(#f3)" /><path d="M330.975 215a9.141 9.141 0 0 1-3.454-.676 9.038 9.038 0 0 1-2.928-1.924 8.89 8.89 0 0 1-1.957-2.881 8.764 8.764 0 0 1-.687-3.398c0-5.14-1.422-9.288-4.108-11.991a11.446 11.446 0 0 0-3.778-2.512 11.594 11.594 0 0 0-4.475-.859c-8.664 0-12.537 7.715-12.537 15.362a8.808 8.808 0 0 1-2.644 6.279 9.1 9.1 0 0 1-6.382 2.6 9.104 9.104 0 0 1-6.382-2.6 8.811 8.811 0 0 1-2.643-6.279c0-12.431 5.076-20.132 9.336-24.39a29.602 29.602 0 0 1 9.727-6.485A30.01 30.01 0 0 1 309.588 173C324.7 173 340 184.366 340 206.121a8.746 8.746 0 0 1-.687 3.398 8.888 8.888 0 0 1-1.956 2.881 9.049 9.049 0 0 1-2.928 1.924 9.141 9.141 0 0 1-3.454.676Z" fill="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 3)]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" filter="url(#f2)" /></g><g transform="translate(-'
            );
            artDataSlot.text = concatenate(artDataSlot.text, eyeDistance);
            artDataSlot.text = concatenate(
                artDataSlot.text,
                ')"><path d="M209.975 215a9.141 9.141 0 0 1-3.454-.676 9.038 9.038 0 0 1-2.928-1.924 8.89 8.89 0 0 1-1.957-2.881 8.764 8.764 0 0 1-.687-3.398c0-5.14-1.422-9.288-4.108-11.991a11.446 11.446 0 0 0-3.778-2.512 11.594 11.594 0 0 0-4.475-.859c-8.664 0-12.537 7.715-12.537 15.362a8.808 8.808 0 0 1-2.644 6.279 9.1 9.1 0 0 1-6.382 2.6 9.104 9.104 0 0 1-6.382-2.6 8.811 8.811 0 0 1-2.643-6.279c0-12.431 5.076-20.132 9.336-24.39a29.602 29.602 0 0 1 9.727-6.485A30.01 30.01 0 0 1 188.588 173C203.7 173 219 184.366 219 206.121a8.746 8.746 0 0 1-.687 3.398 8.888 8.888 0 0 1-1.956 2.881 9.049 9.049 0 0 1-2.928 1.924 9.141 9.141 0 0 1-3.454.676Z" fill="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 2)]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" filter="url(#f3)" /><path d="M209.975 215a9.141 9.141 0 0 1-3.454-.676 9.038 9.038 0 0 1-2.928-1.924 8.89 8.89 0 0 1-1.957-2.881 8.764 8.764 0 0 1-.687-3.398c0-5.14-1.422-9.288-4.108-11.991a11.446 11.446 0 0 0-3.778-2.512 11.594 11.594 0 0 0-4.475-.859c-8.664 0-12.537 7.715-12.537 15.362a8.808 8.808 0 0 1-2.644 6.279 9.1 9.1 0 0 1-6.382 2.6 9.104 9.104 0 0 1-6.382-2.6 8.811 8.811 0 0 1-2.643-6.279c0-12.431 5.076-20.132 9.336-24.39a29.602 29.602 0 0 1 9.727-6.485A30.01 30.01 0 0 1 188.588 173C203.7 173 219 184.366 219 206.121a8.746 8.746 0 0 1-.687 3.398 8.888 8.888 0 0 1-1.956 2.881 9.049 9.049 0 0 1-2.928 1.924 9.141 9.141 0 0 1-3.454.676Z" fill="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 3)]
            );

            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" filter="url(#f2)" /></g><path d="M250 401a140 140 0 0 0 140-140H110a139.997 139.997 0 0 0 140 140Z"'
            );
            artDataSlot.text = concatenate(artDataSlot.text, ' fill="');
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 4)]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" filter="url(#f2)"/><animateMotion dur="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.speedArray[faceSpeed]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '.25s" repeatCount="indefinite" path="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.speedArrayTrajectory[faceSpeed]
            );
            artDataSlot.text = concatenate(artDataSlot.text, '" /></g></svg>');
            return artDataSlot.text;
        } else if (
            keccak256(bytes(emotion)) == keccak256(bytes("celebrating"))
        ) {
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '<g><g transform="translate(-'
            );
            artDataSlot.text = concatenate(artDataSlot.text, eyeDistance);
            artDataSlot.text = concatenate(
                artDataSlot.text,
                ')"><circle cx="180" cy="200" r="35" fill="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 2)]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" filter="url(#f3)" /><circle cx="180" cy="200" r="28" fill="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 3)]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" filter="url(#f2)" /></g><g transform="translate('
            );
            artDataSlot.text = concatenate(artDataSlot.text, eyeDistance);
            artDataSlot.text = concatenate(
                artDataSlot.text,
                ')"><circle cx="320" cy="200" r="35" fill="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 2)]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" filter="url(#f3)" /><circle cx="320" cy="200" r="28" fill="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 3)]
            );

            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" filter="url(#f2)" /></g><path d="M250 401a140 140 0 0 0 140-140H110a139.997 139.997 0 0 0 140 140Z"'
            );
            artDataSlot.text = concatenate(artDataSlot.text, ' fill="');
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 4)]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" filter="url(#f2)"/><animateMotion dur="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.speedArray[faceSpeed]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '.25s" repeatCount="indefinite" path="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.speedArrayTrajectory[faceSpeed]
            );
            artDataSlot.text = concatenate(artDataSlot.text, '" /></g></svg>');
            return artDataSlot.text;
        } else if (keccak256(bytes(emotion)) == keccak256(bytes("420"))) {
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '<g><g transform="translate('
            );
            artDataSlot.text = concatenate(artDataSlot.text, eyeDistance);
            artDataSlot.text = concatenate(
                artDataSlot.text,
                ')"><path d="M278 203.5c0-6.075 4.925-11 11-11h48c6.075 0 11 4.925 11 11s-4.925 11-11 11h-48c-6.075 0-11-4.925-11-11Z" fill="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 2)]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" filter="url(#f3)" /><path d="M278 203.5c0-6.075 4.925-11 11-11h48c6.075 0 11 4.925 11 11s-4.925 11-11 11h-48c-6.075 0-11-4.925-11-11Z" fill="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 3)]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" filter="url(#f2)" /></g><g transform="translate(-'
            );
            artDataSlot.text = concatenate(artDataSlot.text, eyeDistance);
            artDataSlot.text = concatenate(
                artDataSlot.text,
                ')"><path d="M148 203.5c0-6.075 4.925-11 11-11h48c6.075 0 11 4.925 11 11s-4.925 11-11 11h-48c-6.075 0-11-4.925-11-11Z" fill="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 2)]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" filter="url(#f3)" /><d="M148 203.5c0-6.075 4.925-11 11-11h48c6.075 0 11 4.925 11 11s-4.925 11-11 11h-48c-6.075 0-11-4.925-11-11Z" fill="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 3)]
            );

            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" filter="url(#f2)" /></g><path filter="url(#f2)" d="M140 292.5c5.333 13.167 47 39.5 109.5 39.5s103.833-26.333 109-39.5" stroke-linecap="round" stroke-width="27" fill="none" stroke="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 4)]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" /><animateMotion dur="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.speedArray[faceSpeed]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '.25s" repeatCount="indefinite" path="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.speedArrayTrajectory[faceSpeed]
            );
            artDataSlot.text = concatenate(artDataSlot.text, '" /></g></svg>');
            return artDataSlot.text;
        }

        artDataSlot.text = concatenate(
            artDataSlot.text,
            '<g><g transform="translate(-'
        );
        artDataSlot.text = concatenate(artDataSlot.text, eyeDistance);
        artDataSlot.text = concatenate(
            artDataSlot.text,
            ')"><circle cx="180" cy="200" r="35" fill="'
        );
        artDataSlot.text = concatenate(
            artDataSlot.text,
            artDataSlot.colorArray[strIndex2num(colors, 2)]
        );
        artDataSlot.text = concatenate(
            artDataSlot.text,
            '" filter="url(#f3)" /><circle cx="180" cy="200" r="28" fill="'
        );
        artDataSlot.text = concatenate(
            artDataSlot.text,
            artDataSlot.colorArray[strIndex2num(colors, 3)]
        );
        artDataSlot.text = concatenate(
            artDataSlot.text,
            '" filter="url(#f2)" /></g><g transform="translate('
        );
        artDataSlot.text = concatenate(artDataSlot.text, eyeDistance);
        artDataSlot.text = concatenate(
            artDataSlot.text,
            ')"><circle cx="320" cy="200" r="35" fill="'
        );
        artDataSlot.text = concatenate(
            artDataSlot.text,
            artDataSlot.colorArray[strIndex2num(colors, 2)]
        );
        artDataSlot.text = concatenate(
            artDataSlot.text,
            '" filter="url(#f3)" /><circle cx="320" cy="200" r="28" fill="'
        );
        artDataSlot.text = concatenate(
            artDataSlot.text,
            artDataSlot.colorArray[strIndex2num(colors, 3)]
        );

        artDataSlot.text = concatenate(
            artDataSlot.text,
            '" filter="url(#f2)" /></g><rect x="'
        );
        artDataSlot.text = concatenate(
            artDataSlot.text,
            uint2str(190 - mouthSz)
        );
        artDataSlot.text = concatenate(artDataSlot.text, '" y="300" width="');
        artDataSlot.text = concatenate(
            artDataSlot.text,
            uint2str(120 + (mouthSz * 2))
        );
        artDataSlot.text = concatenate(
            artDataSlot.text,
            '" height="40" fill="'
        );
        artDataSlot.text = concatenate(
            artDataSlot.text,
            artDataSlot.colorArray[strIndex2num(colors, 4)]
        );
        artDataSlot.text = concatenate(
            artDataSlot.text,
            '" rx="25" filter="url(#f2)"/><animateMotion dur="'
        );
        artDataSlot.text = concatenate(
            artDataSlot.text,
            artDataSlot.speedArray[faceSpeed]
        );
        artDataSlot.text = concatenate(
            artDataSlot.text,
            '.25s" repeatCount="indefinite" path="'
        );
        artDataSlot.text = concatenate(
            artDataSlot.text,
            artDataSlot.speedArrayTrajectory[faceSpeed]
        );
        artDataSlot.text = concatenate(artDataSlot.text, '" /></g></svg>');
        return artDataSlot.text;
    }
}