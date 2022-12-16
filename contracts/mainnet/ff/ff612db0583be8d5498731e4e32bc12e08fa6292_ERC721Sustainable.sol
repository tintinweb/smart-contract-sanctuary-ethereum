/**
 *Submitted for verification at Etherscan.io on 2022-12-16
*/

// SPDX-License-Identifier: MIT
// This contract is the standalone version of ERC-721S - meaning deployment without use of a minproxy
// this version is specific to Mintplex.xyz needs and should not be re-used for generic NFT recycle/subscriptions
// Read more @ https://medium.com/@tcarambat/we-can-finally-kill-royalties-as-an-nft-business-model-36502e4938b4
// Twitter: @mintplexnft
//-------------DEPENDENCIES--------------------------//

// File: @openzeppelin/contracts/utils/Address.sol

// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if account is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, isContract will return false for the following
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
     * You shouldn't rely on isContract to protect against flash loan attacks!
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
     * @dev Replacement for Solidity's transfer: sends amount wei to
     * recipient, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by transfer, making them unable to receive funds via
     * transfer. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to recipient, care must be
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
     * @dev Performs a Solidity function call using a low level call. A
     * plain call is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If target reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[abi.decode].
     *
     * Requirements:
     *
     * - target must be a contract.
     * - calling target with data must not revert.
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[functionCall], but with
     * errorMessage as a fallback revert reason when target reverts.
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[functionCall],
     * but also transferring value wei to target.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least value.
     * - the called Solidity function must be payable.
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
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[functionCallWithValue], but
     * with errorMessage as a fallback revert reason when target reverts.
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[functionCall],
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
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[functionCall],
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[functionCall],
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
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[functionCall],
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
     * @dev Whenever an {IERC721} tokenId token is transferred to this contract via {IERC721-safeTransferFrom}
     * by operator from from, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with IERC721.onERC721Received.selector.
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
     * interfaceId. See the corresponding
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
 * solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 *
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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when tokenId token is transferred from from to to.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    event ReclaimedMint(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when owner enables approved to manage the tokenId token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when owner enables or disables (approved) operator to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    /**
     * @dev Returns the number of tokens in owner's account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the tokenId token.
     *
     * Requirements:
     *
     * - tokenId must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers tokenId token from from to to, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - from cannot be the zero address.
     * - to cannot be the zero address.
     * - tokenId token must exist and be owned by from.
     * - If the caller is not from, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If to refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers tokenId token from from to to.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - from cannot be the zero address.
     * - to cannot be the zero address.
     * - tokenId token must be owned by from.
     * - If the caller is not from, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to to to transfer tokenId token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - tokenId must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for tokenId token.
     *
     * Requirements:
     *
     * - tokenId must exist.
     */
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    /**
     * @dev Approve or remove operator as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The operator cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the operator is allowed to manage all of the assets of owner.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    /**
     * @dev Safely transfers tokenId token from from to to.
     *
     * Requirements:
     *
     * - from cannot be the zero address.
     * - to cannot be the zero address.
     * - tokenId token must exist and be owned by from.
     * - If the caller is not from, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If to refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
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
     * @dev Returns a token ID owned by owner at a given index of its token list.
     * Use along with {balanceOf} to enumerate all of owner's tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256);

    /**
     * @dev Returns a token ID at a given index of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
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
     * @dev Returns the Uniform Resource Identifier (URI) for tokenId token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
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
     * @dev Converts a uint256 to its ASCII string decimal representation.
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
     * @dev Converts a uint256 to its ASCII string hexadecimal representation.
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
     * @dev Converts a uint256 to its ASCII string hexadecimal representation with fixed length.
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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol

// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from ReentrancyGuard will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single nonReentrant guard, functions marked as
 * nonReentrant may not call one another. This can be worked around by making
 * those functions private, and then adding external nonReentrant entry
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
     * Calling a nonReentrant function from another nonReentrant
     * function is not supported. It is possible to prevent this from happening
     * by making the nonReentrant function external, and making it call a
     * private function that does the actual work.
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
 * onlyOwner, which can be applied to your functions to restrict their use to
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
    function _onlyOwner() private view {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * onlyOwner functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (newOwner).
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
     * @dev Transfers ownership of the contract to a new account (newOwner).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File contracts/OperatorFilter/IOperatorFilterRegistry.sol
pragma solidity ^0.8.9;

interface IOperatorFilterRegistry {
    function isOperatorAllowed(address registrant, address operator)
        external
        view
        returns (bool);

    function register(address registrant) external;

    function registerAndSubscribe(address registrant, address subscription)
        external;

    function registerAndCopyEntries(
        address registrant,
        address registrantToCopy
    ) external;

    function updateOperator(
        address registrant,
        address operator,
        bool filtered
    ) external;

    function updateOperators(
        address registrant,
        address[] calldata operators,
        bool filtered
    ) external;

    function updateCodeHash(
        address registrant,
        bytes32 codehash,
        bool filtered
    ) external;

    function updateCodeHashes(
        address registrant,
        bytes32[] calldata codeHashes,
        bool filtered
    ) external;

    function subscribe(address registrant, address registrantToSubscribe)
        external;

    function unsubscribe(address registrant, bool copyExistingEntries) external;

    function subscriptionOf(address addr) external returns (address registrant);

    function subscribers(address registrant)
        external
        returns (address[] memory);

    function subscriberAt(address registrant, uint256 index)
        external
        returns (address);

    function copyEntriesOf(address registrant, address registrantToCopy)
        external;

    function isOperatorFiltered(address registrant, address operator)
        external
        returns (bool);

    function isCodeHashOfFiltered(address registrant, address operatorWithCode)
        external
        returns (bool);

    function isCodeHashFiltered(address registrant, bytes32 codeHash)
        external
        returns (bool);

    function filteredOperators(address addr)
        external
        returns (address[] memory);

    function filteredCodeHashes(address addr)
        external
        returns (bytes32[] memory);

    function filteredOperatorAt(address registrant, uint256 index)
        external
        returns (address);

    function filteredCodeHashAt(address registrant, uint256 index)
        external
        returns (bytes32);

    function isRegistered(address addr) external returns (bool);

    function codeHashOf(address addr) external returns (bytes32);
}

// File contracts/OperatorFilter/OperatorFilterer.sol
pragma solidity ^0.8.9;

abstract contract OperatorFilterer {
    error OperatorNotAllowed(address operator);

    IOperatorFilterRegistry constant operatorFilterRegistry =
        IOperatorFilterRegistry(0x000000000000AAeB6D7670E522A718067333cd4E);

    constructor(address subscriptionOrRegistrantToCopy, bool subscribe) {
        // If an inheriting token contract is deployed to a network without the registry deployed, the modifier
        // will not revert, but the contract will need to be registered with the registry once it is deployed in
        // order for the modifier to filter addresses.
        if (address(operatorFilterRegistry).code.length > 0) {
            if (subscribe) {
                operatorFilterRegistry.registerAndSubscribe(
                    address(this),
                    subscriptionOrRegistrantToCopy
                );
            } else {
                if (subscriptionOrRegistrantToCopy != address(0)) {
                    operatorFilterRegistry.registerAndCopyEntries(
                        address(this),
                        subscriptionOrRegistrantToCopy
                    );
                } else {
                    operatorFilterRegistry.register(address(this));
                }
            }
        }
    }

    function _onlyAllowedOperator(address from) private view {
        if (
            !(operatorFilterRegistry.isOperatorAllowed(
                address(this),
                msg.sender
            ) && operatorFilterRegistry.isOperatorAllowed(address(this), from))
        ) {
            revert OperatorNotAllowed(msg.sender);
        }
    }

    modifier onlyAllowedOperator(address from) virtual {
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (address(operatorFilterRegistry).code.length > 0) {
            // Allow spending tokens from addresses with balance
            // Note that this still allows listings and marketplaces with escrow to transfer tokens if transferred
            // from an EOA.
            if (from == msg.sender) {
                _;
                return;
            }
            _onlyAllowedOperator(from);
        }
        _;
    }

    modifier onlyAllowedOperatorApproval(address operator) virtual {
        _checkFilterOperator(operator);
        _;
    }

    function _checkFilterOperator(address operator) internal view virtual {
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (address(operatorFilterRegistry).code.length > 0) {
            if (
                !operatorFilterRegistry.isOperatorAllowed(
                    address(this),
                    operator
                )
            ) {
                revert OperatorNotAllowed(operator);
            }
        }
    }
}

//-------------END DEPENDENCIES------------------------//

error TransactionCapExceeded();
error ExcessiveOwnedMints();
error MintZeroQuantity();
error InvalidPayment();
error CapExceeded();
error ValueCannotBeZero();
error CannotBeNullAddress();
error NoStateChange();
error TokenDoesNotExist();

error PublicMintClosed();
error AllowlistMintClosed();

error AddressNotAllowlisted();
error ERC20InsufficientBalance();
error ERC721RestrictedApprovalAddressRestricted();
error CannotReclaimNonExpiredToken();
error CannotExtendByThatQty();

// Rampp Contracts v2.1 (Teams.sol)
error InvalidTeamAddress();
error DuplicateTeamAddress();

pragma solidity ^0.8.0;

/**
 * Teams is a contract implementation to extend upon Ownable that allows multiple controllers
 * of a single contract to modify specific mint settings but not have overall ownership of the contract.
 * This will easily allow cross-collaboration via Mintplex.xyz.
 **/
abstract contract Teams is Ownable {
    mapping(address => bool) internal team;

    /**
     * @dev Adds an address to the team. Allows them to execute protected functions
     * @param _address the ETH address to add, cannot be 0x and cannot be in team already
     **/
    function addToTeam(address _address) public onlyOwner {
        if (_address == address(0)) revert InvalidTeamAddress();
        if (inTeam(_address)) revert DuplicateTeamAddress();

        team[_address] = true;
    }

    /**
     * @dev Removes an address to the team.
     * @param _address the ETH address to remove, cannot be 0x and must be in team
     **/
    function removeFromTeam(address _address) public onlyOwner {
        if (_address == address(0)) revert InvalidTeamAddress();
        if (!inTeam(_address)) revert InvalidTeamAddress();

        team[_address] = false;
    }

    function isTeamOrOwner(address _address) internal view returns (bool) {
        bool _isOwner = owner() == _address;
        bool _isTeam = inTeam(_address);
        return _isOwner || _isTeam;
    }

    /**
     * @dev Check if an address is valid and active in the team
     * @param _address ETH address to check for truthiness
     **/
    function inTeam(address _address) public view returns (bool) {
        if (_address == address(0)) revert InvalidTeamAddress();
        return team[_address] == true;
    }

    /**
     * @dev Throws if called by any account other than the owner or team member.
     */
    function _onlyTeamOrOwner() private view {
        bool _isOwner = owner() == _msgSender();
        bool _isTeam = inTeam(_msgSender());
        require(
            _isOwner || _isTeam,
            "Team: caller is not the owner or in Team."
        );
    }

    modifier onlyTeamOrOwner() {
        _onlyTeamOrOwner();
        _;
    }
}

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 */
library MerkleProof {
    /**
     * @dev Returns true if a 'leaf' can be proved to be a part of a Merkle tree
     * defined by 'root'. For this, a 'proof' must be provided, containing
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
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from 'leaf' using 'proof'. A 'proof' is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf)
        internal
        pure
        returns (bytes32)
    {
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

    function _efficientHash(bytes32 a, bytes32 b)
        private
        pure
        returns (bytes32 value)
    {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// File: SingleStateMintStatus.sol

pragma solidity ^0.8.0;

// @dev Controls the entire state of minting to where only one state can be active at the same time.
// so the contract is either in public mint, or allowlist mint, but not both at the same time.
abstract contract SingleStateMintStatus is Teams {
    bytes32 public merkleRoot;
    bool private allowlistOpen = false;
    bool private publicMint = false;

    /**
     * @dev Update merkle root to reflect changes in Allowlist
     * @param _newMerkleRoot new merkle root to reflect most recent Allowlist
     */
    function updateMerkleRoot(bytes32 _newMerkleRoot) public onlyTeamOrOwner {
        if (_newMerkleRoot == merkleRoot) revert NoStateChange();
        merkleRoot = _newMerkleRoot;
    }

    /**
     * @dev Check the proof of an address if valid for merkle root
     * @param _to address to check for proof
     * @param _merkleProof Proof of the address to validate against root and leaf
     */
    function isAllowlisted(address _to, bytes32[] calldata _merkleProof)
        public
        view
        returns (bool)
    {
        if (merkleRoot == 0) revert CannotBeNullAddress();
        bytes32 leaf = keccak256(abi.encodePacked(_to));

        return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    }

    function inAllowlistMint() public view returns (bool) {
        return allowlistOpen == true && publicMint == false;
    }

    function inPublicMint() public view returns (bool) {
        return allowlistOpen == false && publicMint == true;
    }

    function openAllowlistMint() public onlyTeamOrOwner {
        allowlistOpen = true;
        publicMint = false;
    }

    function openPublicMint() public onlyTeamOrOwner {
        allowlistOpen = false;
        publicMint = true;
    }

    function closeMint() public onlyTeamOrOwner {
        allowlistOpen = false;
        publicMint = false;
    }
}

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata and Enumerable extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at _startTokenId() (defaults to 0, e.g. 0, 1, 2, 3..).
 *
 * Assumes the number of issuable tokens (collection size) is capped and fits in a uint128.
 *
 * Does not support burning tokens to address(0).
 * Is Initializable
 * Has added concerns and functions to support subscribable NFTs
 */
abstract contract ERC721A is
    Context,
    ERC165,
    IERC721,
    IERC721Metadata,
    IERC721Enumerable,
    Teams,
    OperatorFilterer,
    SingleStateMintStatus
{
    using Address for address;
    using Strings for uint256;

    struct TokenOwnership {
        address addr;
        uint64 startTimestamp;
        uint256 expiryTimestamp;
    }

    uint256 private currentIndex;

    uint256 public collectionSize;
    uint256 public maxBatchSize;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned. See ownershipOf implementation for details.
    // however given that minting is restricted to single mint actions - this is true until bulk minting is enabled.
    mapping(uint256 => TokenOwnership) internal _ownerships;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping owner address minted count - replaces AddressData
    mapping(address => uint256) internal _numberMinted;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /* @dev Mapping of restricted operator approvals set by contract Owner
     * This serves as an optional addition to ERC-721 so
     * that the contract owner can elect to prevent specific addresses/contracts
     * from being marked as the approver for a token. The reason for this
     * is that some projects may want to retain control of where their tokens can/can not be listed
     * either due to ethics, loyalty, or wanting trades to only occur on their personal marketplace.
     * By default, there are no restrictions. The contract owner must deliberatly block an address
     */
    mapping(address => bool) public restrictedApprovalAddresses;

    /**
     * @dev
     * maxBatchSize refers to how much a minter can mint at a time.
     * collectionSize_ refers to how many tokens are in the collection.
     */
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 maxBatchSize_,
        uint256 collectionSize_
    ) OperatorFilterer(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6, true) {
        if (collectionSize_ == 0) revert ValueCannotBeZero();
        if (maxBatchSize_ == 0) revert ValueCannotBeZero();
        _name = name_;
        _symbol = symbol_;
        maxBatchSize = maxBatchSize_;
        collectionSize = collectionSize_;
        currentIndex = _startTokenId();
    }

    /**
     * To change the starting tokenId, please override this function.
     */
    function _startTokenId() internal view virtual returns (uint256) {
        return 1;
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalMinted();
    }

    function currentTokenId() public view returns (uint256) {
        return _totalMinted();
    }

    function getNextTokenId() public view returns (uint256) {
        return _totalMinted() + 1;
    }

    /**
     * Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view returns (uint256) {
        unchecked {
            return currentIndex - _startTokenId();
        }
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

    function _findExpiredSupplyOrToken() internal view returns (uint256, bool) {
        for (uint256 i = 1; i <= totalSupply(); i++) {
            TokenOwnership memory ownership = _ownerships[i];
            if (ownership.addr != address(0)) {
                // if token was previously owned and expired the token address is not nullified
                if (isExpiredHelper(ownership)) {
                    // check expiry and if expired we know it is mintable, so return its id.
                    return (i, true);
                }
            }
        }
        return (0, false);
    }

    // @dev allows us to work through the minted stack and find the first available token that has been minted
    // but whos ownership is not null (unminted/burned), but is expired!
    // Okay to leave this publically readable so that buyer can know what they are minting. Useful for frontend?
    // See {IERC721Enumerable-tokenOfOwnerByIndex} for O(n) concerns when calling in contract.
    // @return uint256 tokenId available for reclaim.
    function findExpiredTokenId() public view returns (uint256) {
        (
            uint256 tokenId,
            bool expiredSupplyExists
        ) = _findExpiredSupplyOrToken();
        if (expiredSupplyExists) return tokenId;
        revert("ERC721A: No expired tokens found");
    }

    // @dev validation function to check if there is a possible mint available
    // This is a readable function of convenience of minting frontend.
    // @return bool there is at least 1 token in reclaim queue.
    function hasExpiredSupply() public view returns (bool) {
        (, bool expiredSupplyExists) = _findExpiredSupplyOrToken();
        return expiredSupplyExists;
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
        if (owner == address(0)) revert CannotBeNullAddress();
        return _balanceOf(owner);
    }

    // @dev this is a helper function for balanceOf that will return the true balance of an accounts ownership
    // by factoring in their balance with their number minted. This is important because typical token gating
    // applications only read this value.
    // @notice this will iterate of the entire collection so be wary of calling this when n >> 10000 from contracts
    function _balanceOf(address _owner) internal view returns (uint256) {
        uint256 count = 0;
        uint256 curr = currentIndex;
        unchecked {
            TokenOwnership memory ownership;
            while (curr != 0) {
                ownership = _ownerships[curr];
                if (ownership.addr == _owner && !isExpiredHelper(ownership)) {
                    count++;
                }
                curr--;
            }
        }

        return count;
    }

    // @dev Modified function that will revert if the ownership record found is also outside of expiry.
    function ownershipOf(uint256 tokenId)
        internal
        view
        returns (TokenOwnership memory)
    {
        uint256 curr = tokenId;

        unchecked {
            if (_startTokenId() <= curr && curr < currentIndex) {
                TokenOwnership memory ownership = _ownerships[curr];
                if (ownership.addr != address(0)) {
                    if (isExpiredHelper(ownership)) {
                        revert("ERC721A: ownership of token has expired.");
                    }
                    return ownership;
                }

                // Invariant:
                // There will always be an ownership that has an address and is not burned
                // before an ownership that does not have an address and is not burned.
                // Hence, curr will not underflow.
                while (true) {
                    curr--;
                    ownership = _ownerships[curr];
                    if (ownership.addr != address(0)) {
                        if (isExpiredHelper(ownership)) {
                            revert("ERC721A: ownership of token has expired.");
                        }
                        return ownership;
                    }
                }
            }
        }

        revert("ERC721A: unable to determine the owner of token");
    }

    // @dev Internal helper function that will return an ownership EVEN if it is expired.
    // This is needed because normal OwnershipOf should return address(0) if the expiry date has passed
    // so that marketplaces and such do not associate ownership on refresh of item if it has expired.
    function ownershipOfExpiry(uint256 tokenId)
        internal
        view
        returns (TokenOwnership memory)
    {
        uint256 curr = tokenId;

        unchecked {
            if (_startTokenId() <= curr && curr < currentIndex) {
                TokenOwnership memory ownership = _ownerships[curr];
                if (ownership.addr != address(0)) {
                    return ownership;
                }

                // Invariant:
                // There will always be an ownership that has an address and is not burned
                // before an ownership that does not have an address and is not burned.
                // Hence, curr will not underflow.
                while (true) {
                    curr--;
                    ownership = _ownerships[curr];
                    if (ownership.addr != address(0)) {
                        return ownership;
                    }
                }
            }
        }

        revert("ERC721A: unable to determine the owner of token");
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return isExpired(tokenId) ? address(0) : ownershipOf(tokenId).addr;
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
        string memory baseURI = _baseURI();
        string memory baseURIExtension = _baseURIExtension();
        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(
                        baseURI,
                        tokenId.toString(),
                        baseURIExtension
                    )
                )
                : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the baseURI and the tokenId. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    function _baseURIExtension() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev Sets the value for an address to be in the restricted approval address pool.
     * Setting an address to true will disable token owners from being able to mark the address
     * for approval for trading. This would be used in theory to prevent token owners from listing
     * on specific marketplaces or protcols. Only modifible by the contract owner/team.
     * @param _address the marketplace/user to modify restriction status of
     * @param _isRestricted restriction status of the _address to be set. true => Restricted, false => Open
     */
    function setApprovalRestriction(address _address, bool _isRestricted)
        public
        onlyTeamOrOwner
    {
        restrictedApprovalAddresses[_address] = _isRestricted;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId)
        public
        override
        onlyAllowedOperatorApproval(to)
    {
        address owner = ERC721A.ownerOf(tokenId);
        require(to != owner, "ERC721A: approval to current owner");
        if (restrictedApprovalAddresses[to])
            revert ERC721RestrictedApprovalAddressRestricted();
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
        onlyAllowedOperatorApproval(operator)
    {
        require(operator != _msgSender(), "ERC721A: approve to caller");
        if (restrictedApprovalAddresses[operator])
            revert ERC721RestrictedApprovalAddressRestricted();

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
    ) public override onlyAllowedOperator(from) {
        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
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
    ) public override onlyAllowedOperator(from) {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "ERC721A: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Returns whether tokenId exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (_mint),
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _startTokenId() <= tokenId && tokenId < currentIndex;
    }

    function _safeMint(
        address to,
        uint256 timeUnits,
        bool adminMint
    ) internal {
        _safeMint(to, timeUnits, adminMint, "");
    }

    /**
     * @dev Mints quantity tokens and transfers them to to.
     *
     * Requirements:
     *
     * - there must be quantity tokens remaining unminted in the total collection.
     * - to cannot be the zero address.
     * - quantity statically set to 1.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(
        address to,
        uint256 timeUnits,
        bool adminMint,
        bytes memory _data
    ) internal {
        uint256 quantity = 1;
        uint256 startTokenId = currentIndex;
        if (to == address(0)) revert CannotBeNullAddress();
        // We know if the first token in the batch doesn't exist, the other ones don't as well, because of serial ordering.
        require(!_exists(startTokenId), "ERC721A: token already minted");

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // do not count as mint if minted by admin.
        if (adminMint) {
            _numberMinted[to] = _numberMinted[to] + 1;
        }

        _ownerships[startTokenId] = TokenOwnership(
            to,
            uint64(block.timestamp),
            calcExpiry(timeUnits)
        );

        emit Transfer(address(0), to, startTokenId);
        require(
            _checkOnERC721Received(address(0), to, startTokenId, _data),
            "ERC721A: transfer to non ERC721Receiver implementer"
        );

        currentIndex = startTokenId + 1;
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    // @dev Mints a token that has since reached its expiry date and has returned to minting queue.
    // @notice this function is a fallback for _safemint but must be invoked manually. If findExpiredTokenId()
    // cannot find a pending token in the reclaimation stack - it will revert this call.
    // Only one mint at a time can occur during reclaimation.
    // The end result is it looks like a Transfer from the prev owner to the new owner, but without check for approval of prev owner
    // which is not required since the previous owner forefit their explict ownership via expired token.
    // Reclaim mints do not count as _numberMinted and someone can reclaim as many mints as they like.
    // Emits a {ReclaimedMint} event.
    function _reclaimMint(address to, uint256 timeUnits) internal {
        uint256 tokenId = findExpiredTokenId();
        TokenOwnership memory prevOwnership = ownershipOfExpiry(tokenId);

        if (to == address(0)) revert CannotBeNullAddress();
        if (!isExpiredHelper(prevOwnership))
            revert CannotReclaimNonExpiredToken();

        _beforeTokenTransfers(prevOwnership.addr, to, tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, prevOwnership.addr);
        _ownerships[tokenId] = TokenOwnership(
            to,
            uint64(block.timestamp),
            calcExpiry(timeUnits)
        );

        emit ReclaimedMint(prevOwnership.addr, to, tokenId);
        _afterTokenTransfers(prevOwnership.addr, to, tokenId, 1);
    }

    /**
     * @dev Transfers tokenId from from to to.
     *
     * Requirements:
     *
     * - to cannot be the zero address.
     * - tokenId token must be owned by from.
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
        if (to == address(0)) revert CannotBeNullAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, prevOwnership.addr);
        _ownerships[tokenId] = TokenOwnership(
            to,
            uint64(block.timestamp),
            prevOwnership.expiryTimestamp
        );

        // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
        // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
        uint256 nextTokenId = tokenId + 1;
        if (_ownerships[nextTokenId].addr == address(0)) {
            if (_exists(nextTokenId)) {
                _ownerships[nextTokenId] = TokenOwnership(
                    prevOwnership.addr,
                    prevOwnership.startTimestamp,
                    prevOwnership.expiryTimestamp
                );
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev Approve to to operate on tokenId
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
     * @dev Explicitly set owners to eliminate loops in future calls of ownerOf().
     */
    function _setOwnersExplicit(uint256 quantity) internal {
        uint256 oldNextOwnerToSet = nextOwnerToExplicitlySet;
        require(quantity > 0, "quantity must be nonzero");
        if (currentIndex == _startTokenId()) revert("No Tokens Minted Yet");

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
                    ownership.startTimestamp,
                    ownership.expiryTimestamp
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
     * - When from and to are both non-zero, from's tokenId will be
     * transferred to to.
     * - When from is zero, tokenId will be minted for to.
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
     * - when from and to are both non-zero.
     * - from and to are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    // @dev will return the expiry timestamp of a token in seconds
    // @notice this will still return a timestamp even if the token has long since expired.
    // @param tokenId the token in which you are querying for.
    // @return uint256 representation of seconds since Epoch
    function expiryOf(uint256 tokenId) public view returns (uint256) {
        if (!_exists(tokenId)) revert TokenDoesNotExist();
        return ownershipOfExpiry(tokenId).expiryTimestamp;
    }

    // @dev will return boolean of if expiryTimestamp is old
    // @notice this will still return a timestamp even if the token has long since expired.
    // @param tokenId the token in which you are querying for.
    function isExpired(uint256 tokenId) public view returns (bool) {
        if (!_exists(tokenId)) revert TokenDoesNotExist();
        return ownershipOfExpiry(tokenId).expiryTimestamp < block.timestamp;
    }

    // @dev Used internally only to prevent lookup of token repeatedly with OwnershipOf*
    function isExpiredHelper(TokenOwnership memory ownership)
        internal
        view
        returns (bool)
    {
        return ownership.expiryTimestamp < block.timestamp;
    }

    // @dev Allows any address to extend the ownership of anyones token
    // @notice If a token expires you cannot extend it, as it has gone into the reclaimation queue.
    // @notice Team or Owner do not have to pay the applicable fee that would normally be required.
    // @param tokenId the token in which you are querying for.
    // @param _extendByTimeUnits How many "units of time" you are adding. This is a qty that will be multiplied by baseSubscriptionTime
    function extendOwnership(uint256 tokenId, uint256 _extendByTimeUnits)
        public
        payable
    {
        if (!_exists(tokenId)) revert TokenDoesNotExist();
        if (_extendByTimeUnits == 0) revert ValueCannotBeZero();

        // If not Admin/Team we need to enfore the maximum amount of units that can be bought at once
        // and make sure they are not trying to extend beyond maximum window.
        // Admin/Team does not have to pay to extend time window
        if (!isTeamOrOwner(_msgSender())) {
            if (!canMintQty(_extendByTimeUnits)) revert CannotExtendByThatQty();
            if (msg.value != getPrice(1, _extendByTimeUnits))
                revert InvalidPayment();
        }

        uint256 ownershipKey = tokenId;
        TokenOwnership memory ownership = _ownerships[ownershipKey];

        // Calculate new future date for which expiryTimestamp will be
        // set to. New + added time. If extending time of expired token, it will revive the previous owner's claim.
        bool expired = ownership.expiryTimestamp < block.timestamp;
        uint256 remTime = expired
            ? 0
            : ownership.expiryTimestamp - block.timestamp;
        uint256 newFuture = calcExpiry(_extendByTimeUnits);
        _ownerships[ownershipKey].expiryTimestamp = (remTime + newFuture);
    }

    uint256 public baseSubscriptionTime; // time in seconds that will be base unit eg: 1yr => 31_560_000
    uint256 public pricePerTimeUnit; // public pricing
    uint256 public presalePricePerTimeUnit; // pricing in allowlist
    uint256 public maxQtyPerTxn = 10000; // max amount of time units that can be bought at once.

    function setUnitPrice(uint256 _feeInWei) public onlyTeamOrOwner {
        pricePerTimeUnit = _feeInWei;
    }

    function setPresaleUnitPrice(uint256 _feeInWei) public onlyTeamOrOwner {
        presalePricePerTimeUnit = _feeInWei;
    }

    // @dev Allows Team to set base subscription time unit that expiry time is calculated against. eg = 86400 => 1 day
    // @param _secondsPerUnit How many seconds the base unit will represent.
    function setSubscriptionTimeUnit(uint256 _secondsPerUnit)
        public
        onlyTeamOrOwner
    {
        if (_secondsPerUnit == 0) revert ValueCannotBeZero();
        baseSubscriptionTime = _secondsPerUnit;
    }

    /**
     * @dev Check if you can mint x time units in a single txn.
     * @param _amount amount of time units being purchased at once.
     */
    function canMintQty(uint256 _amount) public view returns (bool) {
        if (_amount == 0) revert ValueCannotBeZero();
        return _amount <= maxQtyPerTxn;
    }

    /**
     * @dev Set the max qty of time units available for purchase at once.
     * @param _newTimeUnitMax the new max of time units (in days, months, etc) a wallet can mint in a single tx. Must be >= 1
     */
    function setMaxQtyPerTx(uint256 _newTimeUnitMax) public onlyTeamOrOwner {
        if (_newTimeUnitMax == 0) revert ValueCannotBeZero();
        maxQtyPerTxn = _newTimeUnitMax;
    }

    // @dev Calculate price to be paid for specific qty and time unit. Will automatically return proper price depending
    // on if in allowlist (pre-sale) mode or not.
    // @param _qty the number of independent tokens that are being purchased
    // @param _timeUnits the number of time units being purchased (eg. days) - depends on baseSubscriptionTime setting
    // @return uint256 fee in wei for entire purchase
    function getPrice(uint256 _qty, uint256 _timeUnits)
        public
        view
        returns (uint256)
    {
        if (_qty == 0) revert MintZeroQuantity();
        if (_timeUnits == 0) revert ValueCannotBeZero();
        uint256 feePerUnit = inAllowlistMint()
            ? presalePricePerTimeUnit
            : pricePerTimeUnit;
        return (feePerUnit * _timeUnits) * _qty;
    }

    // @dev Calculate expiry date in future. This will tell you expiry time a proposed purchase would end at.
    // @param _timeUnits the number of time units being purchased (eg. days) - depends on baseSubscriptionTime setting
    // @return uint256 timestamp of seconds since epoch that sub will expire.
    function calcExpiry(uint256 _timeUnits) internal view returns (uint256) {
        if (_timeUnits == 0) revert ValueCannotBeZero();
        return block.timestamp + (baseSubscriptionTime * _timeUnits);
    }
}

interface IERC20 {
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transfer(address _to, uint256 _amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// File: WithdrawableV2
abstract contract WithdrawableV2 is Teams {
    address[] public payableAddresses;
    uint256[] public payableFees;
    uint256 public payableAddressCount;
    address public erc20Payable;

    /**
     * @dev Calculates the true payable balance of the contract
     */
    function withdrawAll() public onlyTeamOrOwner {
        if (address(this).balance == 0) revert ValueCannotBeZero();
        _withdrawAll(address(this).balance);
    }

    function _withdrawAll(uint256 balance) private {
        for (uint256 i = 0; i < payableAddressCount; i++) {
            _widthdraw(payableAddresses[i], (balance * payableFees[i]) / 100);
        }
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    /**
     * @dev Allow contract owner to withdraw ERC-20 balance from contract
     * in the event ERC-20 tokens are paid to the contract for mints.
     * @param _tokenContract contract of ERC-20 token to withdraw
     * @param _amountToWithdraw balance to withdraw according to balanceOf of ERC-20 token in wei
     */
    function withdrawERC20(address _tokenContract, uint256 _amountToWithdraw)
        public
        onlyTeamOrOwner
    {
        if (_amountToWithdraw == 0) revert ValueCannotBeZero();
        IERC20 tokenContract = IERC20(_tokenContract);
        if (tokenContract.balanceOf(address(this)) < _amountToWithdraw)
            revert ERC20InsufficientBalance();
        tokenContract.transfer(erc20Payable, _amountToWithdraw); // Payout ERC-20 tokens to recipient
    }

    /**
     * @dev Set the payout of the ERC-20 token payout to a specific address
     * @param _newErc20Payable new payout addresses of ERC-20 tokens
     */
    function setERC20PayableAddress(address _newErc20Payable)
        public
        onlyTeamOrOwner
    {
        if (_newErc20Payable == address(0)) revert CannotBeNullAddress();
        if (_newErc20Payable == erc20Payable) revert NoStateChange();
        erc20Payable = _newErc20Payable;
    }

    function definePayables(
        address[] memory _newPayables,
        uint256[] memory _newFees
    ) public onlyTeamOrOwner {
        payableAddresses = _newPayables;
        payableFees = _newFees;
        payableAddressCount = _newPayables.length;
    }
}

// @title An implementation of ERC-721 with added benefits of minted tokens that have expiry dates that allow them to be reminted as they expire.
// @author Mintplex.xyz (Mintplex Labs Inc) (Twitter: @MintplexNFT)
// @notice https://medium.com/@tcarambat/we-can-finally-kill-royalties-as-an-nft-business-model-36502e4938b4
// @custom:experimental This is an experimental unaudited contract - Use at your own risk. Mint actions is RESTRICTED to single mints currently.
contract ERC721Sustainable is
    Ownable,
    Teams,
    ERC721A,
    WithdrawableV2,
    ReentrancyGuard
{
    constructor(
        address[] memory _payables,
        uint256[] memory _payouts,
        string memory tokenName,
        string memory tokenSymbol,
        uint256 _collectionSize,
        string memory initTokenUri,
        uint256 initSubTime,
        uint256[2] memory initPricing // public and allowlist pricing.
    ) ERC721A(tokenName, tokenSymbol, 1, _collectionSize) {
        erc20Payable = _msgSender();
        payableAddresses = _payables;
        payableFees = _payouts;
        payableAddressCount = _payables.length;
        _baseTokenURI = initTokenUri;
        baseSubscriptionTime = initSubTime;

        pricePerTimeUnit = initPricing[0];
        presalePricePerTimeUnit = initPricing[1];
    }

    uint256 public maxWalletMints = 1;
    uint8 public immutable CONTRACT_VERSION = 1;
    string public _baseTokenURI;
    string public _tokenExtension = ".json";

    /**
     * @dev Mints a token to an address with time unit multiplier
     * This is owner/team only and allows a fee-free/rule-free drop
     * @param _to address of the future owner of the token
     * @param _timeUnits amount of tokens to drop the owner
     */
    function adminMint(address _to, uint256 _timeUnits) public onlyTeamOrOwner {
        if (currentTokenId() != collectionSize) {
            if (currentTokenId() + 1 > collectionSize) revert CapExceeded();
            _safeMint(_to, _timeUnits, true);
            return;
        }
        _reclaimMint(_to, _timeUnits);
    }

    /**
     * @dev Mints single token to an address.
     * fee may or may not be required
     * @param _to address of the future owner of the token
     * @param _timeUnits time units being paid for (eg. 1 days, 10 mins, 14 months..)
     */
    function mintTo(address _to, uint256 _timeUnits) public payable {
        if (_timeUnits == 0) revert MintZeroQuantity();
        if (!inPublicMint()) revert PublicMintClosed();
        if (msg.value != getPrice(1, _timeUnits)) revert InvalidPayment();
        if (!canMintQty(_timeUnits)) revert TransactionCapExceeded();

        // need to determine if we should be minting from primary supply vs reclaiming an expired token
        if (currentTokenId() != collectionSize) {
            if (currentTokenId() + 1 > collectionSize) revert CapExceeded();
            if (!canMintAmount(_to, 1)) revert ExcessiveOwnedMints();
            _safeMint(_to, _timeUnits, false);
            return;
        }
        _reclaimMint(_to, _timeUnits);
    }

    /**
     * @dev Mints single token to an address using an allowlist.
     * fee may or may not be required
     * @param _to address of the future owner of the token
     * @param _timeUnits time units being paid for (eg. 1 days, 10 mins, 14 months..)
     * @param _merkleProof merkle proof array
     */
    function mintToAL(
        address _to,
        uint256 _timeUnits,
        bytes32[] calldata _merkleProof
    ) public payable {
        if (_timeUnits == 0) revert MintZeroQuantity();
        if (!inAllowlistMint()) revert AllowlistMintClosed();
        if (!isAllowlisted(_to, _merkleProof)) revert AddressNotAllowlisted();
        if (msg.value != getPrice(1, _timeUnits)) revert InvalidPayment();
        if (!canMintQty(_timeUnits)) revert TransactionCapExceeded();

        if (currentTokenId() != collectionSize) {
            if (currentTokenId() + 1 > collectionSize) revert CapExceeded();
            if (!canMintAmount(_to, 1)) revert ExcessiveOwnedMints();
            _safeMint(_to, _timeUnits, false);
            return;
        }
        _reclaimMint(_to, _timeUnits);
    }

    /**
     * @dev Check if wallet over maxWalletMints of tokens ever minted into existence.
     * @param _address address in question to check if minted count exceeds max
     * @notice this check is only ever applied when minting NEW tokens into existence. Otherwise
     * it would fall under a reclaim mint and would therefore not apply, since it is reviving a token.
     */
    function canMintAmount(address _address, uint256 _amount)
        public
        view
        returns (bool)
    {
        if (_amount == 0) revert ValueCannotBeZero();
        return (_numberMinted[_address] + _amount) <= maxWalletMints;
    }

    /**
     * @dev Update the maximum amount of tokens that can be minted by a unique wallet
     * @param _newWalletMax the new max of tokens a wallet can mint. Must be >= 1
     */
    function setWalletMax(uint256 _newWalletMax) public onlyTeamOrOwner {
        if (_newWalletMax == 0) revert ValueCannotBeZero();
        maxWalletMints = _newWalletMax;
    }

    /**
     * @dev Allows owner to set Max mints per tx. Useless currently as mints are limited to single mints.
     * @param _newMaxMint maximum amount of tokens allowed to mint per tx. Must be >= 1
     */
    function setMaxMint(uint256 _newMaxMint) public onlyTeamOrOwner {
        if (_newMaxMint == 0) revert ValueCannotBeZero();
        maxBatchSize = _newMaxMint;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function _baseURIExtension()
        internal
        view
        virtual
        override
        returns (string memory)
    {
        return _tokenExtension;
    }

    function baseTokenURI() public view returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyTeamOrOwner {
        _baseTokenURI = baseURI;
    }

    function setTokenExtension(string calldata newExtension)
        external
        onlyTeamOrOwner
    {
        _tokenExtension = newExtension;
    }

    function getOwnershipData(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return ownershipOf(tokenId);
    }
}