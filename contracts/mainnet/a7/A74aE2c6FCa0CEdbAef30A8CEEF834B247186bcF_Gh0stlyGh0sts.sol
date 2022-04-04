// File: contracts/interfaces/ILayerZeroUserApplicationConfig.sol



pragma solidity >=0.5.0;

interface ILayerZeroUserApplicationConfig {
    // @notice set the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _configType - type of configuration. every messaging library has its own convention.
    // @param _config - configuration in the bytes. can encode arbitrary content.
    function setConfig(uint16 _version, uint16 _chainId, uint _configType, bytes calldata _config) external;

    // @notice set the send() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setSendVersion(uint16 _version) external;

    // @notice set the lzReceive() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setReceiveVersion(uint16 _version) external;

    // @notice Only when the UA needs to resume the message flow in blocking mode and clear the stored payload
    // @param _srcChainId - the chainId of the source chain
    // @param _srcAddress - the contract address of the source contract at the source chain
    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external;
}

// File: contracts/interfaces/ILayerZeroEndpoint.sol



pragma solidity >=0.5.0;


interface ILayerZeroEndpoint is ILayerZeroUserApplicationConfig {
    // @notice send a LayerZero message to the specified address at a LayerZero endpoint.
    // @param _dstChainId - the destination chain identifier
    // @param _destination - the address on destination chain (in bytes). address length/format may vary by chains
    // @param _payload - a custom bytes payload to send to the destination contract
    // @param _refundAddress - if the source transaction is cheaper than the amount of value passed, refund the additional amount to this address
    // @param _zroPaymentAddress - the address of the ZRO token holder who would pay for the transaction
    // @param _adapterParams - parameters for custom functionality. e.g. receive airdropped native gas from the relayer on destination
    function send(uint16 _dstChainId, bytes calldata _destination, bytes calldata _payload, address payable _refundAddress, address _zroPaymentAddress, bytes calldata _adapterParams) external payable;

    // @notice used by the messaging library to publish verified payload
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source contract (as bytes) at the source chain
    // @param _dstAddress - the address on destination chain
    // @param _nonce - the unbound message ordering nonce
    // @param _gasLimit - the gas limit for external contract execution
    // @param _payload - verified payload to send to the destination contract
    function receivePayload(uint16 _srcChainId, bytes calldata _srcAddress, address _dstAddress, uint64 _nonce, uint _gasLimit, bytes calldata _payload) external;

    // @notice get the inboundNonce of a receiver from a source chain which could be EVM or non-EVM chain
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function getInboundNonce(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (uint64);

    // @notice get the outboundNonce from this source chain which, consequently, is always an EVM
    // @param _srcAddress - the source chain contract address
    function getOutboundNonce(uint16 _dstChainId, address _srcAddress) external view returns (uint64);

    // @notice gets a quote in source native gas, for the amount that send() requires to pay for message delivery
    // @param _dstChainId - the destination chain identifier
    // @param _userApplication - the user app address on this EVM chain
    // @param _payload - the custom message to send over LayerZero
    // @param _payInZRO - if false, user app pays the protocol fee in native token
    // @param _adapterParam - parameters for the adapter service, e.g. send some dust native token to dstChain
    function estimateFees(uint16 _dstChainId, address _userApplication, bytes calldata _payload, bool _payInZRO, bytes calldata _adapterParam) external view returns (uint nativeFee, uint zroFee);

    // @notice get this Endpoint's immutable source identifier
    function getChainId() external view returns (uint16);

    // @notice the interface to retry failed message on this Endpoint destination
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    // @param _payload - the payload to be retried
    function retryPayload(uint16 _srcChainId, bytes calldata _srcAddress, bytes calldata _payload) external;

    // @notice query if any STORED payload (message blocking) at the endpoint.
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function hasStoredPayload(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (bool);

    // @notice query if the _libraryAddress is valid for sending msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getSendLibraryAddress(address _userApplication) external view returns (address);

    // @notice query if the _libraryAddress is valid for receiving msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getReceiveLibraryAddress(address _userApplication) external view returns (address);

    // @notice query if the non-reentrancy guard for send() is on
    // @return true if the guard is on. false otherwise
    function isSendingPayload() external view returns (bool);

    // @notice query if the non-reentrancy guard for receive() is on
    // @return true if the guard is on. false otherwise
    function isReceivingPayload() external view returns (bool);

    // @notice get the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _userApplication - the contract address of the user application
    // @param _configType - type of configuration. every messaging library has its own convention.
    function getConfig(uint16 _version, uint16 _chainId, address _userApplication, uint _configType) external view returns (bytes memory);

    // @notice get the send() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getSendVersion(address _userApplication) external view returns (uint16);

    // @notice get the lzReceive() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getReceiveVersion(address _userApplication) external view returns (uint16);
}

// File: contracts/interfaces/ILayerZeroReceiver.sol



pragma solidity >=0.5.0;

interface ILayerZeroReceiver {
    // @notice LayerZero endpoint will invoke this function to deliver the message on the destination
    // @param _srcChainId - the source endpoint identifier
    // @param _srcAddress - the source sending contract address from the source chain
    // @param _nonce - the ordered message nonce
    // @param _payload - the signed payload is the UA bytes has encoded to be sent
    function lzReceive(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload) external;
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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
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

// File: @openzeppelin/contracts/token/ERC721/ERC721.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

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
}

// File: contracts/NonblockingReceiver.sol


pragma solidity ^0.8.6;




abstract contract NonblockingReceiver is Ownable, ILayerZeroReceiver {

    ILayerZeroEndpoint internal endpoint;

    struct FailedMessages {
        uint payloadLength;
        bytes32 payloadHash;
    }

    mapping(uint16 => mapping(bytes => mapping(uint => FailedMessages))) public failedMessages;
    mapping(uint16 => bytes) public trustedRemoteLookup;

    event MessageFailed(uint16 _srcChainId, bytes _srcAddress, uint64 _nonce, bytes _payload);

    function lzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) external override {
        require(msg.sender == address(endpoint)); // boilerplate! lzReceive must be called by the endpoint for security
        require(_srcAddress.length == trustedRemoteLookup[_srcChainId].length && keccak256(_srcAddress) == keccak256(trustedRemoteLookup[_srcChainId]), 
            "NonblockingReceiver: invalid source sending contract");

        // try-catch all errors/exceptions
        // having failed messages does not block messages passing
        try this.onLzReceive(_srcChainId, _srcAddress, _nonce, _payload) {
            // do nothing
        } catch {
            // error / exception
            failedMessages[_srcChainId][_srcAddress][_nonce] = FailedMessages(_payload.length, keccak256(_payload));
            emit MessageFailed(_srcChainId, _srcAddress, _nonce, _payload);
        }
    }

    function onLzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) public {
        // only internal transaction
        require(msg.sender == address(this), "NonblockingReceiver: caller must be Bridge.");

        // handle incoming message
        _LzReceive( _srcChainId, _srcAddress, _nonce, _payload);
    }

    // abstract function
    function _LzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) virtual internal;

    function _lzSend(uint16 _dstChainId, bytes memory _payload, address payable _refundAddress, address _zroPaymentAddress, bytes memory _txParam) internal {
        endpoint.send{value: msg.value}(_dstChainId, trustedRemoteLookup[_dstChainId], _payload, _refundAddress, _zroPaymentAddress, _txParam);
    }

    function retryMessage(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes calldata _payload) external payable {
        // assert there is message to retry
        FailedMessages storage failedMsg = failedMessages[_srcChainId][_srcAddress][_nonce];
        require(failedMsg.payloadHash != bytes32(0), "NonblockingReceiver: no stored message");
        require(_payload.length == failedMsg.payloadLength && keccak256(_payload) == failedMsg.payloadHash, "LayerZero: invalid payload");
        // clear the stored message
        failedMsg.payloadLength = 0;
        failedMsg.payloadHash = bytes32(0);
        // execute the message. revert if it fails again
        this.onLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
    }

    function setTrustedRemote(uint16 _chainId, bytes calldata _trustedRemote) external onlyOwner {
        trustedRemoteLookup[_chainId] = _trustedRemote;
    }
}

// File: contracts/GhostlyGhosts.sol



pragma solidity ^0.8.7;


// 0000KKK0000KKKKKKKKKKKKKKKKKKKKKKKKKKK0KKKKKKKKKKKKKK00000KKKKK0K000000000KKKKKKKK0KKK000KKK000KKKK000KKK00000KK0000000000000000KKKKKKKKKKK000KKKKK000
// 00KKK0000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK00000K0xlloxk000000KKKKKKKKKKK00000KK0000KKKK0000KKK0000K000000KK000000000KKKKKKKKKKK0000KKKK000KK
// KKK0000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK00000KOl.   ..l000KKKKKKKKKKKKKK0KKK00000KKKK00KKKKKKKKK000000KKKK0000000KKKKKKKKKKK0000KKKKKKKKK00
// K0000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0KKKKKKKKKKKKKK0x;.... .,xKKKKKKKKKKKKK0klcodddddkO0Okkk0KKKKKKKKK00000KKKKKKKKK000KKKKKKKKKK0000KKKKKKKKKK000
// 0000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0KKKKKKKKKKKKKKK0l.   .. .oKKKKKKKKKKKK0kc'..',,,,,'''....d0KKKKKK0000KKKKKKKKK0000KKKKKKKKKK00000KKKKKKKKK00KKK
// 00KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0l..;,.    :OKKKKKKKKKKKx,'ccldxxxxd;. ....:k0KKKKKKKKKKKKKKK000000KKKKKKKKK0000KKKKKKKKKKKKKKK00
// KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKO, ,o:'''. .'ck0KOxlcclc'.lxxxxxxxxd:';oxdc,';d0KKKKKKKKKKK0000KKKKKKKKKKKK00KKKKKKKKKKK0KKKKK000
// KKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0000KKKKKKKKKKKKKKKKKKKk' ,dl,.:l:,...:c;;:loo:.,dxxxxxxxxxddxxxxxxo,.lkolok0KKK00000KKKKKKKKKKKKKKKKKKKKKKKKK0KKKK00000
// KKKKKKKKKKKKKKKKKKKKKKKKKKKKK000KKKKKKKKKKKKKKKKKKKKKk, ;xdl;':xxdl'  ,dxxxxc.,dxxxxxxxxxxxxxxxxxxl..... .l00000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK00000KK
// KKKKKKKKKKKKKKKKKKKKKKKKKK0000KKKKKKKKKK0KKKKKKKKKKKK0: 'xOxdl,:xOkxc. 'cdxxc.'oxxxxxxxxxxxxxxxxxo,   .,;.'okk0KKKKKKKKKKKKKKKKKKK00KKKKK000KK00000KKK
// KKKKKKKKKKKKKKKKKKKKKKKK00000KKKKKKKKKK0KKKKKKKKKKKKKKo..ckOkkd,,dkxoc'  'coo;.'cdxxxxxxxxxxxxxxo,.   . .....'d0KKKKKKKKKKKKKKKK000KKKK0000000000KKKKK
// KKKKKKKKKKKKKKKKKKKKKKK0000KKKKKKKKK000KKKKKKKKKKKKKKKO: .oOkkOd,'lxxddl,....''...,:ldxxxxxxxxdc..,,.'lc. ,, .oKKKKKKKKKKKKKKKKKKKKKK000KK00000KKKKKK0
// KKKKKKKKKKKKKKKKKKKKK00000KKKKKKKK0000KKKKKKKKKKKKKKKKKk, ,xOkOkx:.;okkOkdlc:,'..    ..,;;::;,.  .';,''. .xk,.dKKKKKKKKKKKKKKKKKKKK0000KK0000KKKKKKK00
// KKKKKKKKKKKKKKKKKKKK0000KKKKKKKKK000KKKKKKKKKKKKKKKKKKKKo. ;xOkkkko,':dkOOOOOkxoc;;'..            .d0Ok;..;;.;kKKKKKKKKKKKKKKKKKKK000KKK000KKKKKKK0000
// KKKKKKKKKKKKKKKKKK0000KKKKKKKKK000KKKKKKKKKKKKKKKKKKKKKKd,..'dOkkkOkl;',:ldxkkkxolc:;;;;:c;,,,'.  .lkkl' ..  .:OKKKKKKKKKKKKKKKKK000KKKKKKKKKKKKK0000K
// K000KKKK0KKKKKKK0000KKKKKKKKK000KKKKKKKKKKKKKKKKKKKKKKKKd;lc..:oxOkkOkxl;'',,,;;;::;,,,'....    .c,....       .oKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK00000KKK
// 0000KK00KKKKKKK0000KKKKKKKK000KKKKKKKKKKKKKKKKKKKKKKKKKKk;,c'   'coxkOOxc;::c;..........   .:dd:...... .::.   .dKKKKKKKKKKKKKKKKKKKKKKKKKKKKK00000KKKK
// 000K000KKKKKK0000KKKKKKKKK00KKKKKKKKKKKKKKKKKKKKKKKKKK0ko,.,cxOd:'..',:cc:clooc;;:;,'..';lkXWMMWKo'... .;:'. .;x0KKKKKKKKKKKKKKKKKKKKKKKKKK00000KKKKKK
// 000000KKKKK00000KKKKKKKK000KKKKKKKKKKKKKKKKKKKKKKKKK0x:',o0NMMMMWNKOxl;'''',,'',,'.';oOXWMMMMMMMMMXk:...;lc....,kKKKKKKKKKKKKKKKKK00KKKKKK0000KKKK00KK
// K000KKKKKK0000KKKKKKKK000KKKKKKKKKKKKKKKKKKKKKKKKKKk:':kNMMMMMMMMMMMMMWNXKKXXXXXXXXNWMMMMMMMMMMMMMMMW0d;',,.',.'xKKKKKKKKKKKKKK0000KKKKKK000KKKKKK00KK
// 000KKKKKK00KKKKKKKKK0000KKKKKKKKKKKKKKKKKKKKKKKKK0o,;OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO:. .:ok0KKKKKKKKKKKKK0000KKKKK0000KKKKKKKKKKK
// 00KKKK00KKKKKKKKKKK000KKKKKKKKKKKKKKKKKKKKKKKKKK0l'oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXo. :OKKKKKKKKKKKKK0000KKKKKK000KKKKKKKKKKKKK
// KKKK000KKKKKKKKKK0000KKKKKKKKKKKKKKKKKKKKKKKKKK0l'oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNd..dKKKKKKKKKKKK000KKKKKKK00KKKKKKKKKKKKKKK
// K00000KKKKKKKKK000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKo'lXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWk',kKKKKKKKKKK00KKKKKKKKKKKKKKKKKKKKKKKKKK
// 00000KKKKKKKKK000KKKKKKKKKKKKKKKKKKKKKKK0OkO00d,cXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWk''x00KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK
// 0000KKKKKKKKK000KKKKKKKKKKKKKKKKKKKKK0Kkc..,''..,ldOKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXl..o0KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK
// 00KKKKKKKKK0000KKKKKKKKKKKKKKKKKKKKKKKO:.'x0kddoc,...;xKNMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNXNNXXXKXNWMMMMWNXKOxlcll.'kKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK
// 0KKKKKKKKK0000KKKKKK00KKKKKKKKKKKK00K0c.:KNkc,,cxkOkdc:;;ckXNWMMMMMMMMMMMWXK0Odoolc:::::::cc:;;,,ckOxoc;,..,:oKWx.;OKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK
// KKKKKKKK0000KKKKKKKKKKKKKKKKKKKK000KKo.;KXc       .:ldkkkdc;',:x0KK00OxdddooooooddxxOO0KKKKK0OOx' .lolodkO0XNN0kx;.:O000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKK
// KKKKKKK0000KKKKKKKKKKKKKKKKKKKK00KKKk,,0Xc             .':k0d:,',,...,cxKXOxdolcccccloodk0NWMWWWx'oXNWMMMWKxc'.;00,.:k00KKKKKKKKKKKKKKKKKKKKKKKKKKKKKK
// KKKKK00000KKKKKKKKKKKKKKKKKKK000KKK0:.oWO'                .OXkxOKO, 'OWNx,.              .'l0NMMXddNMWXkl,..':xXWWk'.cOKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK
// KKK00000KKKKKKKKKKKKKKKKKKKK0KKKKKK0l.:XNo.               .xx. .::. :XNl                    .kWMMKdOKl'.'cd0NMMMMMWk,.cOKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK
// KK0000KKKKKKKKKKKKKKKKKKKKK0KKKKKKKK0l,dWK,               'x:.lkd' ;0Mk.                     :XMMMX0kdx0NMMMMMMMMMMWk..l0KKKKKKKKKKKKKKKKKKKKKKKKKKKK0
// 00000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKc.lK0o,             co.;XW0;.kWMx.                     ,KMMMMNXWMMMMMMMMMMMMMMNo.'xKKKKKKKKKKKKKKKKKKKKKKKKKK000
// 000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0Kd. :0NXOl'.       'dk'.kMMWd.,OWK,                    .oNMMWKol0MMMMMMMMMMMMMMMK: ,kKKKKKKKKKKKKKKKKKKKKKKKK000K
// KKKKKKKK00KKKKKKKKKKKKKKKKKKKKKKKKKK0KO,.',,:ldddxxxddxkOO:.lNMMMXl..dXO,                  .dNMMWk;.lXMMMMMMMMMMMMMMMMk. ;OKKKKKKKKKKKKKKKKKKKKKKKKKKK
// KKKK00000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKd.'0Xxlc;'.,cdl:;'.':kNMMMMWK:  ,kKkolc:;,...  ...,cxKWMMNo..c0WMMMMMMMMMMMMMMMMWd. :OKKKKKKKKKKKKKKKKKKKKKKKKKK
// KK00000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKo.,KMMMMWXOdc,';ldkKNMMMMMMMWXx;..:ONWWWWNX0OOO0KXWWMMMMNo..lOWMMMMMMMMMMMMMMMMMMNc .l0KKKKKKKKKKKKKKKKKKKKKKKKK
// 000000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0l ,KMMMMMMMMMWNWMMMMMMMMMMMMMMMNOo::::ccclc::ccccclooodxocoOXWMMMMMMMMMMMMMMMMMMMNo. 'xKKKKKKKKKKKKKKKKKKKKKKKKK
// 0000KKKKKKKKKKKKKK0Oxollcccodk0KKKKKK0l .OMMMMMMMMMMMMMMMMMMMMMMMMKdd0WMWNK0OOOOkkkkkkkk0KK00O0XMMMMMMMMMMMMMMMMMMMMMMMk'   :OKKKKKKKKKKKKKKKKKKKKKKKK
// 000KKKKKKKKK0Okxdl:;;,;::ccl:;:lxOKKKKo.'0MMMMMMMMMMMMMMMMMMMMWWNKo..'lKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNk;  'xKKKKKKKKKKKKKKKKKKKKKKKK
// 0KKKKKKKKKKk:',,;:coddddoollodo:oOKK00l.,KMMMMMMMMMMMMMMNklcc::;,,,ck0kXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWx.  .,x000KKKKKKKKKKKKKKKKKK00
// KKKKKKKKKKKd.:kkxxdxxddddxO0KKOlo0K00Ko.'0MMMMMMMMMMMMMMW0kkxxkO0KNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNd,.. .lO0KKKKKKKKKKKKKKKKKKK00
// K00KKKKKK0Kk':KWXKKKKKKKKKKKKKkco0K0KKo.,KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOdOKl..co. .,d0KKKK00KKKKKKKKKKKKK0
// 000KKKK0KKKO;,0WXKKKKKKKKKKKKKkloOKKKKo.:XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWX0KO, ':'.'x0:   :0KKK00KKKKKKKKKKKK000
// 00KK00KKKKKKl.dNNKKKKKKKK00OOkl;ckKK0Kx.,0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXKXWMMO,..,..o;...lKd. ;xKKK00KKKKKKKKKKKKK000
// KK0000KKKKKKk,;KNKK0kkOO00Oxc,..,o0KKKx..OW0xdkKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWx'..;oOo..:,..'.  ..xK,.c0K000KKKKKKKKKKKKKKK00
// K000KKKKKKKKKo'dNOolcllccc:ccdkxokKKKKk'.kXl';:co0WMMMMMXdl0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNWMMMMNc ,c:.'l:':,.c:. ,ldKNl ,kK0KKKKKKKKKKKKKKKK000
// 000KKKKKKKK00k,:0xcdkkdoodk0KKKOok0xddo'.dWd,lxdc:oKWMW0;. ;XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0:'cOkloOd.'odc.':. .:XNOkXMMMWx..o0KKKKKKKKKKKKKKKK0000
// 000KK0KKKK0000c,OX00000KKKKKKKKOdxc..',:;d0x;:ddddc:O0l. ,,,kMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX;   ''...ll'',. .. ..'lKMMMMMMM0' .lOKKKKKKKKKKKKK000000
// 0KKK00000000KKx;dXKKKKKKKKKKKKK0xd;.;oodl'....';lo:... .,:,.,OWMMMMMMWX0kx0NWMMMMMMMMMMMMMMWWK; ';. .'';OX0x, .. .'..oWMMMMMMK;  .lKKKKKKKKKKKKK0000O0
// 0KK00000000KK0x,;o:;;::cllllloddlxx;.;cc,  ;dl'...';:;..xXl...:OWMMW0c.. .;lodkNMMXxlodOKklccxx,',.  ..'kWMWO;..':;,lKMMMMMMMWo. .c0KKKKKKKKKKKKKK0000
// K00O000000K0d;,,:l'.,:,'.. .,,;;;xK0xc'.....,,.. ,odxx, .;:,:xo;:kW0'  ......;;cOWk',lc;..cd,'OO,.  .''.:XMMMNOkKXXNWMMMMMMMMWo.  ,kKKKKKKKKKKKKK00000
// 00O000000KOc.c0NO:..:dxOOo,.',';oOKKK0c  ;oooc'  'okd,..,:o;'OWXd;cc. ,oo'  ,od:cX0;,oc' .cl';Kklo'..:l,:KMMMMMMMMMMMMMMMMMMMNo  ..oKK000KKKKKKKK0KKKK
// 00000000K0c.dNMMWOl;'',;;,,,,'.'dO00Kk, ,llc;;,'....  .oo;.  'cxOo..:'.,'.   .'.:KNo....   .,OWxckc,xkod0WMMMMMMMMMMMMMMMMMMMWd. ..dK000KKKKKKKKKKKKKK
// 0000000KKk',KMMMMMMWNXXKKKKXNNOl',oOKx. oWWX000KK:.;:. .ldc.   ..,;.'clc:.   .;,'xWO'......'dWMXxolxNMMMMMMMMMMMMMMMMMMMMMMMMMO'  'xK00KKKKKKKKKKKKKKK
// 00000KKKKO,'0MMMMMMMMMMMMMMMMMMWKl';dd..xMMMMMMMWl'lo:;;:l;.';'.;xx:':ccc;',codooOWNkooxOo;cxO0NWMWWMMMMMMMMMMMMMMMMMMMMMMMMMMNl  .x00KKKKKKKKKKKKKKKK
// 0000KKKKKKl.dWMMMMMMMMMMMMMMMMMMMWO;.,.'0MMMMMMMWo..cKWNXKxcloll0NXX0kxxxkXWWWNNWMMMMMW0c......';lxKWMMMMMMMMMMMMMMMMMMMMMMMMMMK;  ;kKKKKKKKKKKKKKKKKK
// 000KKKKK0KO;'kWMMMMMMMMMMMMMMMMMMMMNx. ,KMMMMMMMWklkNMMMMMMNXXNMMMMMMMMMMMMMMMMMMMMMMWx,:xOO00koc;,;cdONMMMMMMMMMMMMMMMMMMMMMMMW0:  .oOKKKKKKKKKKKKKK0
// 00KKKK0KKK0x,'OMMMMMMMMMMMMMMMMMMMMWO, .xMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWx'oNMMMMMMMMMWKOkddkXWMMMMMMMMMMMMMMMMMMMMMMXd. .l0KKKKKKKKKKKK00
// 0KKK00KKK000x,,OWMMMMMMMMMMMMMMMMMMNo. :KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX:,KMMMMMMMMMMMMMMWKdldKWMMMMMMMMMMMMMMMMMMMMMNk' .oKKKKKKKKKKKKKK
// KKK00KKK000KKk,'xNMMMMMMMMMMMMMMMMWk' .OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK;;XMMMMMMMMMMMMMMMMW0o:dKNWMMMMMMMMMMMMMMMMMMMWd. 'xKKKKKKKKKKKKK
// KK00KK0000KKKKx..kMMMMMMMMMMMMMMMWk' .dWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK,'0MMMMMMMMMMMMMMMMMMWKxddKMMMMMMMMMMMMMMMMMMMMK,  ;OKKKKKKKKKKK0
// KKKKK0000KKKKK0: :XMMMMMMMMMMMMMWk'  oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK;.cxXMMMMMMMMMMMMMMMMMMMMWWMMMMMMMMMMMMMMMMMMMMWd. .l0KKKKKKKKK00
// KKKK0000KKKKKK0: .xWMMMMMMMMMMMWO' .cXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWk,. lNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXc  .dKKKKKKKK000
// KKK00000KKKKKK0:  :NMMMMMMMMMMW0;  cNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0; .kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO'  ;OKKKKK0000K
// KK000000KKKKKK0l  .OMMMMMMMMMMXc  ;KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK, :XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNl  .dKKKK0000KK
// K0000000K00KK0Kx' .xMMMMMMMMMNd. ,0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMx..kMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWx. .oKKK0000KKK
// K000000K000KKKK0l .dMMMMMMMMWO' 'OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX; :XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO'  c0K0000KKKK
// K00000K000KKKK0Kx. lNMMMMMMMK; .xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWo .xMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMk. .lK000KKKKKK
// 00000K000KKKKK0Kx. ;XMMMMMMNo. cNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMd. lWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMk.  c000KKKKKK0
// 000KK000KKKKK00Kx. .OMMMMMM0, '0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMx. ;XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0,  :O0KKKKKK00
// 00K0000KKKKKKKKKx.  oWMMMMNo. lNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMk. ;XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX:  ;OKKKKKKK00
// 0K0000KKKKKK00KKd.  ;XMMMMk. ,0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO. cNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX:  ;OK0KKKK000
// KK000KKKKKK000K0o.  ,KMMMMd .dWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO. oWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWMMMMMMMMMX:  :0KKKKK00O0


contract Gh0stlyGh0sts is Ownable, ERC721, NonblockingReceiver {

    address public _owner;
    string private baseURI;
    uint256 nextTokenId = 0;
    uint256 MAX_MINT_ETHEREUM = 3084;

    uint gasForDestinationLzReceive = 350000;

    constructor(string memory baseURI_, address _layerZeroEndpoint) ERC721("Gh0stlyGh0sts", "gg") { 
        _owner = msg.sender;
        endpoint = ILayerZeroEndpoint(_layerZeroEndpoint);
        baseURI = baseURI_;
    }

    // mint function
    // you can choose to mint 1 or 2
    // mint is free, but payments are accepted
    function mint(uint8 numTokens) external payable {
        require(numTokens < 3, "GG: Max 2 NFTs per transaction");
        require(nextTokenId + numTokens <= MAX_MINT_ETHEREUM, "GG: Mint exceeds supply");
        _safeMint(msg.sender, ++nextTokenId);
        if (numTokens == 2) {
            _safeMint(msg.sender, ++nextTokenId);
        }
    }

    // This function transfers the nft from your address on the 
    // source chain to the same address on the destination chain
    function traverseChains(uint16 _chainId, uint tokenId) public payable {
        require(msg.sender == ownerOf(tokenId), "You must own the token to traverse");
        require(trustedRemoteLookup[_chainId].length > 0, "This chain is currently unavailable for travel");

        // burn NFT, eliminating it from circulation on src chain
        _burn(tokenId);

        // abi.encode() the payload with the values to send
        bytes memory payload = abi.encode(msg.sender, tokenId);

        // encode adapterParams to specify more gas for the destination
        uint16 version = 1;
        bytes memory adapterParams = abi.encodePacked(version, gasForDestinationLzReceive);

        // get the fees we need to pay to LayerZero + Relayer to cover message delivery
        // you will be refunded for extra gas paid
        (uint messageFee, ) = endpoint.estimateFees(_chainId, address(this), payload, false, adapterParams);
        
        require(msg.value >= messageFee, "GG: msg.value not enough to cover messageFee. Send gas for message fees");

        endpoint.send{value: msg.value}(
            _chainId,                           // destination chainId
            trustedRemoteLookup[_chainId],      // destination address of nft contract
            payload,                            // abi.encoded()'ed bytes
            payable(msg.sender),                // refund address
            address(0x0),                       // 'zroPaymentAddress' unused for this
            adapterParams                       // txParameters 
        );
    }  

    function setBaseURI(string memory URI) external onlyOwner {
        baseURI = URI;
    }

    function donate() external payable {
        // thank you
    }

    // This allows the devs to receive kind donations
    function withdraw(uint amt) external onlyOwner {
        (bool sent, ) = payable(_owner).call{value: amt}("");
        require(sent, "GG: Failed to withdraw Ether");
    }

    // just in case this fixed variable limits us from future integrations
    function setGasForDestinationLzReceive(uint newVal) external onlyOwner {
        gasForDestinationLzReceive = newVal;
    }

    // ------------------
    // Internal Functions
    // ------------------

    function _LzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) override internal {
        // decode
        (address toAddr, uint tokenId) = abi.decode(_payload, (address, uint));

        // mint the tokens back into existence on destination chain
        _safeMint(toAddr, tokenId);
    }  

    function _baseURI() override internal view returns (string memory) {
        return baseURI;
    }
}