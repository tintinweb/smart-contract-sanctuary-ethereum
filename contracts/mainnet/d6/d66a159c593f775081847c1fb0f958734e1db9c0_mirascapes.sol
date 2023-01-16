/**
 *Submitted for verification at Etherscan.io on 2023-01-15
*/

// File: IERC2981Royalties.sol


pragma solidity ^0.8.0;

/// @title IERC2981Royalties
/// @dev Interface for the ERC2981 - Token Royalty standard
interface IERC2981Royalties {
    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _value - the sale price of the NFT asset specified by _tokenId
    /// @return _receiver - address of who should be sent the royalty payment
    /// @return _royaltyAmount - the royalty payment amount for value sale price
    function royaltyInfo(uint256 _tokenId, uint256 _value)
        external
        view
        returns (address _receiver, uint256 _royaltyAmount);
}
// File: IOperatorFilterRegistry.sol


pragma solidity ^0.8.13;

interface IOperatorFilterRegistry {
    function isOperatorAllowed(address registrant, address operator) external view returns (bool);
    function register(address registrant) external;
    function registerAndSubscribe(address registrant, address subscription) external;
    function registerAndCopyEntries(address registrant, address registrantToCopy) external;
    function unregister(address addr) external;
    function updateOperator(address registrant, address operator, bool filtered) external;
    function updateOperators(address registrant, address[] calldata operators, bool filtered) external;
    function updateCodeHash(address registrant, bytes32 codehash, bool filtered) external;
    function updateCodeHashes(address registrant, bytes32[] calldata codeHashes, bool filtered) external;
    function subscribe(address registrant, address registrantToSubscribe) external;
    function unsubscribe(address registrant, bool copyExistingEntries) external;
    function subscriptionOf(address addr) external returns (address registrant);
    function subscribers(address registrant) external returns (address[] memory);
    function subscriberAt(address registrant, uint256 index) external returns (address);
    function copyEntriesOf(address registrant, address registrantToCopy) external;
    function isOperatorFiltered(address registrant, address operator) external returns (bool);
    function isCodeHashOfFiltered(address registrant, address operatorWithCode) external returns (bool);
    function isCodeHashFiltered(address registrant, bytes32 codeHash) external returns (bool);
    function filteredOperators(address addr) external returns (address[] memory);
    function filteredCodeHashes(address addr) external returns (bytes32[] memory);
    function filteredOperatorAt(address registrant, uint256 index) external returns (address);
    function filteredCodeHashAt(address registrant, uint256 index) external returns (bytes32);
    function isRegistered(address addr) external returns (bool);
    function codeHashOf(address addr) external returns (bytes32);
}
// File: OperatorFilterer.sol


pragma solidity ^0.8.13;


/**
 * @title  OperatorFilterer
 * @notice Abstract contract whose constructor automatically registers and optionally subscribes to or copies another
 *         registrant's entries in the OperatorFilterRegistry.
 */
abstract contract OperatorFilterer {
    error OperatorNotAllowed(address operator);

    IOperatorFilterRegistry constant OPERATOR_FILTER_REGISTRY =
        IOperatorFilterRegistry(0x000000000000AAeB6D7670E522A718067333cd4E);

    constructor(address subscriptionOrRegistrantToCopy, bool subscribe) {
        // If an inheriting token contract is deployed to a network without the registry deployed, the modifier
        // will not revert, but the contract will need to be registered with the registry once it is deployed in
        // order for the modifier to filter addresses.
        if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            if (subscribe) {
                OPERATOR_FILTER_REGISTRY.registerAndSubscribe(address(this), subscriptionOrRegistrantToCopy);
            } else {
                if (subscriptionOrRegistrantToCopy != address(0)) {
                    OPERATOR_FILTER_REGISTRY.registerAndCopyEntries(address(this), subscriptionOrRegistrantToCopy);
                } else {
                    OPERATOR_FILTER_REGISTRY.register(address(this));
                }
            }
        }
    }

    modifier onlyAllowedOperator(address from) virtual {
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            // Allow spending tokens from addresses with balance
            // Note that this still allows listings and marketplaces with escrow to transfer tokens if transferred
            // from an EOA.
            if (from == msg.sender) {
                _;
                return;
            }
            if (!OPERATOR_FILTER_REGISTRY.isOperatorAllowed(address(this), msg.sender)) {
                revert OperatorNotAllowed(msg.sender);
            }
        }
        _;
    }

    modifier onlyAllowedOperatorApproval(address operator) virtual {
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            if (!OPERATOR_FILTER_REGISTRY.isOperatorAllowed(address(this), operator)) {
                revert OperatorNotAllowed(operator);
            }
        }
        _;
    }
}
// File: RevokableOperatorFilterer.sol


pragma solidity ^0.8.13;


/**
 * @title  RevokableOperatorFilterer
 * @notice This contract is meant to allow contracts to permanently opt out of the OperatorFilterRegistry. The Registry
 *         itself has an "unregister" function, but if the contract is ownable, the owner can re-register at any point.
 *         As implemented, this abstract contract allows the contract owner to toggle the
 *         isOperatorFilterRegistryRevoked flag in order to permanently bypass the OperatorFilterRegistry checks.
 */
abstract contract RevokableOperatorFilterer is OperatorFilterer {
    error OnlyOwner();
    error AlreadyRevoked();

    bool private _isOperatorFilterRegistryRevoked;

    modifier onlyAllowedOperator(address from) override {
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (!_isOperatorFilterRegistryRevoked && address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            // Allow spending tokens from addresses with balance
            // Note that this still allows listings and marketplaces with escrow to transfer tokens if transferred
            // from an EOA.
            if (from == msg.sender) {
                _;
                return;
            }
            if (!OPERATOR_FILTER_REGISTRY.isOperatorAllowed(address(this), msg.sender)) {
                revert OperatorNotAllowed(msg.sender);
            }
        }
        _;
    }

    modifier onlyAllowedOperatorApproval(address operator) override {
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (!_isOperatorFilterRegistryRevoked && address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            if (!OPERATOR_FILTER_REGISTRY.isOperatorAllowed(address(this), operator)) {
                revert OperatorNotAllowed(operator);
            }
        }
        _;
    }

    /**
     * @notice Disable the isOperatorFilterRegistryRevoked flag. OnlyOwner.
     */
    function revokeOperatorFilterRegistry() external {
        if (msg.sender != owner()) {
            revert OnlyOwner();
        }
        if (_isOperatorFilterRegistryRevoked) {
            revert AlreadyRevoked();
        }
        _isOperatorFilterRegistryRevoked = true;
    }

    function isOperatorFilterRegistryRevoked() public view returns (bool) {
        return _isOperatorFilterRegistryRevoked;
    }

    /**
     * @dev assume the contract has an owner, but leave specific Ownable implementation up to inheriting contract
     */
    function owner() public view virtual returns (address);
}
// File: RevokableDefaultOperatorFilterer.sol


pragma solidity ^0.8.13;



/**
 * @title  RevokableDefaultOperatorFilterer
 * @notice Inherits from RevokableOperatorFilterer and automatically subscribes to the default OpenSea subscription.
 */
abstract contract RevokableDefaultOperatorFilterer is RevokableOperatorFilterer {
    address constant DEFAULT_SUBSCRIPTION = address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6);

    constructor() OperatorFilterer(DEFAULT_SUBSCRIPTION, true) {}
}
// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
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


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
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
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File: ERC2981Base.sol


pragma solidity ^0.8.0;



/// @dev This is a contract used to add ERC2981 support to ERC721 and 1155
abstract contract ERC2981Base is ERC165, IERC2981Royalties {
    struct RoyaltyInfo {
        address recipient;
        uint24 amount;
    }

    /// @inheritdoc	ERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IERC2981Royalties).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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

// File: TinyERC721.sol


pragma solidity ^0.8.0;








error ApprovalCallerNotOwnerNorApproved();
error ApprovalQueryForNonexistentToken();
error ApproveToCaller();
error ApprovalToCurrentOwner();
error BalanceQueryForZeroAddress();
error MintToZeroAddress();
error MintZeroQuantity();
error TokenDataQueryForNonexistentToken();
error OwnerQueryForNonexistentToken();
error OperatorQueryForNonexistentToken();
error TransferCallerNotOwnerNorApproved();
error TransferFromIncorrectOwner();
error TransferToNonERC721ReceiverImplementer();
error TransferToZeroAddress();
error URIQueryForNonexistentToken();

contract TinyERC721 is Context, ERC165, IERC721, IERC721Metadata {
  using Address for address;
  using Strings for uint256;

  struct TokenData {
    address owner;
    bytes12 aux;
  }

  uint256 private immutable _maxBatchSize;

  mapping(uint256 => TokenData) private _tokens;
  uint256 private _mintCounter;

  string private _name;
  string private _symbol;

  mapping(uint256 => address) private _tokenApprovals;
  mapping(address => mapping(address => bool)) private _operatorApprovals;

  constructor(
    string memory name_,
    string memory symbol_,
    uint256 maxBatchSize_
  ) {
    _name = name_;
    _symbol = symbol_;
    _maxBatchSize = maxBatchSize_;
  }

  function totalSupply() public view virtual returns (uint256) {
    return _mintCounter;
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
    return
      interfaceId == type(IERC721).interfaceId ||
      interfaceId == type(IERC721Metadata).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  function name() public view virtual override returns (string memory) {
    return _name;
  }

  function symbol() public view virtual override returns (string memory) {
    return _symbol;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

    string memory baseURI = _baseURI();
    return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';
  }

  function _baseURI() internal view virtual returns (string memory) {
    return '';
  }

  function balanceOf(address owner) public view virtual override returns (uint256) {
    if (owner == address(0)) revert BalanceQueryForZeroAddress();

    uint256 total = totalSupply();
    uint256 count;
    address lastOwner;
    for (uint256 i; i < total; ++i) {
      address tokenOwner = _tokens[i].owner;
      if (tokenOwner != address(0)) lastOwner = tokenOwner;
      if (lastOwner == owner) ++count;
    }

    return count;
  }

  function _tokenData(uint256 tokenId) internal view returns (TokenData storage) {
    if (!_exists(tokenId)) revert TokenDataQueryForNonexistentToken();

    TokenData storage token = _tokens[tokenId];
    uint256 currentIndex = tokenId;
    while (token.owner == address(0)) {
      unchecked {
        --currentIndex;
      }
      token = _tokens[currentIndex];
    }

    return token;
  }

  function ownerOf(uint256 tokenId) public view virtual override returns (address) {
    if (!_exists(tokenId)) revert OwnerQueryForNonexistentToken();
    return _tokenData(tokenId).owner;
  }

  function approve(address to, uint256 tokenId) public virtual override {
    TokenData memory token = _tokenData(tokenId);
    address owner = token.owner;
    if (to == owner) revert ApprovalToCurrentOwner();

    if (_msgSender() != owner && !isApprovedForAll(owner, _msgSender())) {
      revert ApprovalCallerNotOwnerNorApproved();
    }

    _approve(to, tokenId, token);
  }

  function getApproved(uint256 tokenId) public view virtual override returns (address) {
    if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

    return _tokenApprovals[tokenId];
  }

  function setApprovalForAll(address operator, bool approved) public virtual override {
    if (operator == _msgSender()) revert ApproveToCaller();

    _operatorApprovals[_msgSender()][operator] = approved;
    emit ApprovalForAll(_msgSender(), operator, approved);
  }

  function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
    return _operatorApprovals[owner][operator];
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override {
    TokenData memory token = _tokenData(tokenId);
    if (!_isApprovedOrOwner(_msgSender(), tokenId, token)) revert TransferCallerNotOwnerNorApproved();

    _transfer(from, to, tokenId, token);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override {
    safeTransferFrom(from, to, tokenId, '');
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) public virtual override {
    TokenData memory token = _tokenData(tokenId);
    if (!_isApprovedOrOwner(_msgSender(), tokenId, token)) revert TransferCallerNotOwnerNorApproved();

    _safeTransfer(from, to, tokenId, token, _data);
  }

  function _safeTransfer(
    address from,
    address to,
    uint256 tokenId,
    TokenData memory token,
    bytes memory _data
  ) internal virtual {
    _transfer(from, to, tokenId, token);

    if (to.isContract() && !_checkOnERC721Received(from, to, tokenId, _data))
      revert TransferToNonERC721ReceiverImplementer();
  }

  function _exists(uint256 tokenId) internal view virtual returns (bool) {
    return tokenId < _mintCounter;
  }

  function _isApprovedOrOwner(
    address spender,
    uint256 tokenId,
    TokenData memory token
  ) internal view virtual returns (bool) {
    address owner = token.owner;
    return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
  }

  function _safeMint(address to, uint256 quantity) internal virtual {
    _safeMint(to, quantity, '');
  }

  function _safeMint(
    address to,
    uint256 quantity,
    bytes memory _data
  ) internal virtual {
    uint256 startTokenId = _mintCounter;
    _mint(to, quantity);

    if (to.isContract()) {
      unchecked {
        for (uint256 i; i < quantity; ++i) {
          if (!_checkOnERC721Received(address(0), to, startTokenId + i, _data))
            revert TransferToNonERC721ReceiverImplementer();
        }
      }
    }
  }

  function _mint(address to, uint256 quantity) internal virtual {
    if (to == address(0)) revert MintToZeroAddress();
    if (quantity == 0) revert MintZeroQuantity();

    uint256 startTokenId = _mintCounter;
    _beforeTokenTransfers(address(0), to, startTokenId, quantity);

    unchecked {
      for (uint256 i; i < quantity; ++i) {
        if (_maxBatchSize == 0 ? i == 0 : i % _maxBatchSize == 0) {
          TokenData storage token = _tokens[startTokenId + i];
          token.owner = to;
          token.aux = _calculateAux(address(0), to, startTokenId + i, 0);
        }

        emit Transfer(address(0), to, startTokenId + i);
      }
      _mintCounter += quantity;
    }

    _afterTokenTransfers(address(0), to, startTokenId, quantity);
  }

  function _transfer(
    address from,
    address to,
    uint256 tokenId,
    TokenData memory token
  ) internal virtual {
    if (token.owner != from) revert TransferFromIncorrectOwner();
    if (to == address(0)) revert TransferToZeroAddress();

    _beforeTokenTransfers(from, to, tokenId, 1);

    _approve(address(0), tokenId, token);

    unchecked {
      uint256 nextTokenId = tokenId + 1;
      if (_exists(nextTokenId)) {
        TokenData storage nextToken = _tokens[nextTokenId];
        if (nextToken.owner == address(0)) {
          nextToken.owner = token.owner;
          nextToken.aux = token.aux;
        }
      }
    }

    TokenData storage newToken = _tokens[tokenId];
    newToken.owner = to;
    newToken.aux = _calculateAux(from, to, tokenId, token.aux);

    emit Transfer(from, to, tokenId);

    _afterTokenTransfers(from, to, tokenId, 1);
  }

  function _calculateAux(
    address from,
    address to,
    uint256 tokenId,
    bytes12 current
  ) internal view virtual returns (bytes12) {}

  function _approve(
    address to,
    uint256 tokenId,
    TokenData memory token
  ) internal virtual {
    _tokenApprovals[tokenId] = to;
    emit Approval(token.owner, to, tokenId);
  }

  function _checkOnERC721Received(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) private returns (bool) {
    try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
      return retval == IERC721Receiver.onERC721Received.selector;
    } catch (bytes memory reason) {
      if (reason.length == 0) {
        revert TransferToNonERC721ReceiverImplementer();
      } else {
        assembly {
          revert(add(32, reason), mload(reason))
        }
      }
    }
  }

  function _beforeTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 quantity
  ) internal virtual {}

  function _afterTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 quantity
  ) internal virtual {}
}
// File: mirascapes.sol

/*
         ,:.                       ':.                                                                                                                
        'OWd.                     ;0Wo                                                                                                ':'             
        :XMWd.                   ,0MMO.                                                   .dOd:.                                    ,xXWK;            
       .dWMMWd.                 ,0MMMX;                                                    ,kWWXx;                                .oXMMWk'            
       .OMMMMWd.               ,0MMMMWo                                                     .oXMMNk;                             ,kWMMXo.             
       ;XMMMMMWd.             ,0MMMMMMk.                                                      ;ONMMNk,                         .oXMMW0;  ,l'          
       oWWNNMMMWd.           ,0MXKNMMMK,                                                       .;OWMMXd'                      :0WMMNx.  'OWd.         
      .OMXloNMMMWd.         ,0WXc;0MMMNl                                                         .oXMMWKl.                  'xNMMMXl.  .xWMk.         
      ;KM0'.lNMMMNd.       'OWXc .kMMMMx. ..'''''.....                                     ;dd,    'dXMMWk,               .lKWMMW0;   .xWMMO.         
      lWMx. .lNMMMWd.     'OMXc   oWMMM0;c00000KKKXXK0Okxd:.        .c:.      .:c.        :XMMXo.    'dXMMXl.            ;OWMMWXd.   .dWMMM0'         
     .kMWo   .oNMMMNd.   'OWXc  ..cXMMMX:.'......';coOXWMMO.        .lKk'    .x0c.       .xWMMMW0;     ,xNMNx.         .dNMMWKo'    .oNMMMM0'         
     ,KMX:    .oNMMMNd. 'OWXc .:Odc0MMMWo             .c0Wk.          ,O0;..;Ok,         '0MMMMMMK;      :OWWk'       ,OWMMXo.    .:OWMMMMM0'         
     lNM0'     .oNMMMNd:OWXc.'kNM0cxMMMMO.              .kd.           .dK000d.          ;KMMMMNK0:       .oXWO'     cKMMNk,     :0WMMNXWMM0'         
    .xMMx.      .oNMMMWWWXc.,0WMMXcoWMMMK;               ',             cKWWK:           ;XMMMXc..          lNW0;   lXMMKc.     ;KMMMK:'kWMO.         
    ,0MWl        .lXMMMMXc .OMMMM0,;XMMMNl                            .l0d::x0l.         ,KMMWx.    :d;.    .lXWXl.cXMWk'      ;0WMMNo. lWMO.         
    lNMX:          cXMMXc  lNMMMMx..OMMMMO.                          'k0:   .lKx.        '0MMNc     oWNO;     ,OWNKXWKc.     .lXMMMNd.  oWMO.         
 .'c0WWNd,'.        :KKc  .xMMMMMx.'OWWWWNkc,'.                     'xx'      ;kx'       '0MMX;     ;KMMNd.    'xK0Ox,      'xNMMW0:   .xMM0'         
 .,,,,,,,,'.         ..   .kMMMMMx..',;;;;::;;.  .,;clllllll:,.     ..         ..        '0MMX;      lNMMWx.     ..        :0WMMXo.    '0MM0'         
                          .xMMMMM0'               ..:KMMMMWx'.                           .OMMX;      .lNMMNd.            .dNMMMK:      ;XMMK,         
                           cNMMMMNo                 .xMMMMN:                             .OMMK;        cXMMW0:          ;OWMMW0,       ;XMMK,         
                           .kWMMMMX:                .xMMMMX:                             .kMM0'         :KMMMNd.      .dNMMMWO'        'OMM0'         
                            'kWMMMMXl.              .xMMMMX:                             .xMWd.          ,OWMMWk.    ;0WMMWXo.         .kMM0'         
                             .oXMMMMWk;.            .xMMMMX:                              oWX;            'OWMMWk.  cXMMMXo'           .OMMO.         
                               'o0WMMMNOl,.         .xMMMMX:                              ;Kk.             .dNMMWOlxXMMMK:             '0MMk.         
                                 .;oOXWMMNKkdlc:;;;cdXMMWNO,                               '.               .cKMMMMMMMNk,              .kMWd.         
                                     .,:ldxkO00000OOkxdl:,.                                                   ,x0kooOk:.                cXXc          
                                              ...                                                               .                        ..                
*/

// Contract authored by August Rosedale (@augustfr)
// https://miragegallery.ai

// TinyERC721 used (https://github.com/tajigen/tiny-erc721)

pragma solidity ^0.8.17;







contract mirascapes is TinyERC721, RevokableDefaultOperatorFilterer, Ownable, ERC2981Base {
    using Strings for uint256;

    uint256 public maxSupply = 2605;

    string private baseURI = "ipfs://bafybeibfdxxdkgntmzzwr72u6p5ugcdqnogbmblw6l3mj4isgwjdqbs7ee/";

    bool public metadataFrozen;

    RoyaltyInfo private _royalties;    

    constructor(string memory name, string memory symbol, address royaltyReceiver) TinyERC721(name, symbol, 0) {
        _royalties = RoyaltyInfo(royaltyReceiver, uint24(750));
    }

    function updateRoyalties(address recipient, uint256 value) public onlyOwner {
        require(value <= 10000, "ERC2981Royalties: Too high");
        _royalties = RoyaltyInfo(recipient, uint24(value));
    }

    function airdrop(address[] memory addresses, uint256 numberOfTokens) public onlyOwner {
        uint256 totalToMint = addresses.length * numberOfTokens;
        require(totalSupply() + totalToMint <= maxSupply, "Would exceed max supply");
        for(uint256 i = 0; i < addresses.length; i++) {
            _safeMint(addresses[i], numberOfTokens, '');
        }
    }

    function freezeMetadata() public onlyOwner {
        require(!metadataFrozen, "Already frozen");
        metadataFrozen = true;
    }

    function tokenURI(uint256 tokenID) public override view returns (string memory) {
        if (!_exists(tokenID)) revert URIQueryForNonexistentToken();
            return string.concat(baseURI,Strings.toString(tokenID));
    }

    function updateURI(string memory _baseTokenURI) external onlyOwner {
        require(!metadataFrozen, "Metadata is frozen");
        baseURI = _baseTokenURI;
    }

    function royaltyInfo(uint256, uint256 value) external view override returns (address receiver, uint256 royaltyAmount) {
        RoyaltyInfo memory royalties = _royalties;
        receiver = royalties.recipient;
        royaltyAmount = (value * royalties.amount) / 10000;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC2981Base, TinyERC721) returns (bool) { 
        return interfaceId == type(IERC721).interfaceId || interfaceId == type(IERC721Metadata).interfaceId ||
        super.supportsInterface(interfaceId) || interfaceId == type(IERC2981Royalties).interfaceId;
    }

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function owner() public view virtual override (Ownable, RevokableOperatorFilterer) returns (address) {
        return Ownable.owner();
    }
}