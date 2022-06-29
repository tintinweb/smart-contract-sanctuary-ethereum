/**
 *Submitted for verification at Etherscan.io on 2022-06-29
*/

// SPDX-License-Identifier: UNLICENSED
// ⣿⣿⣿⣿⣿⠀⠀⣰⣿⣿⣿⣷⡀⠀⠀⣶⣶⣶⣦⡀⠀⠀⠀⣶⣶⡄⠀⠀⣶⣶⡆⠀⠀⣶⣶⠀⠀⠀⠀⢰⣶⣶⣶⣶⢀⠀⠀⣤⣶⣶⣦⡀⠀⠀⠀⣴⣶⣶⣦⠀
// ⣿⣿⠀⠀⠀⠀⠀⣿⣿⠀⢸⣿⡇⠀⠀⣿⣿⠀⢻⣿⠀⠀⠀⣿⣿⣿⠀⢸⣿⣿⡇⠀⠀⣿⣿⠀⠀⠀⠀⢸⣿⡇⠀⠀⠀⠀⢸⣿⡇⠀⣿⣿⠀⠀⣾⣿⠁⠈⣿⡇
// ⣿⣿⠀⠀⠀⠀⠀⣿⣿⠀⢸⣿⡇⠀⠀⣿⣿⠀⣸⣿⠀⠀⠀⣿⣿⣿⡀⣿⡟⣿⡇⠀⠀⣿⣿⠀⠀⠀⠀⢸⣿⡇⠀⠀⠀⠀⠀⣿⣿⡀⠀⠀⠀⠀⠘⣿⣷⠀⠀⠀
// ⣿⣿⠿⠿⠀⠀⠀⣿⣿⠀⢸⣿⡇⠀⠀⣿⣿⣿⣿⡟⠀⠀⠀⣿⣿⣿⣷⣿⠀⣿⡇⠀⠀⣿⣿⠀⠀⠀⠀⢸⣿⡿⠿⠀⠀⠀⠀⠀⢿⣿⣦⠀⠀⠀⠀⠈⣿⣿⡄⠀
// ⣿⣿⠀⠀⠀⠀⠀⣿⣿⠀⢸⣿⡇⠀⠀⣿⣿⠈⣿⣷⠀⠀⠀⣿⣿⢸⣿⣿⠈⣿⡇⠀⠀⣿⣿⠀⠀⠀⠀⢸⣿⡇⠀⠀⠀⠀⢀⣀⠀⠙⣿⣧⠀⠀⣀⣀⠀⠻⣿⡆
// ⣿⣿⠀⠀⠀⠀⠀⢿⣿⣤⣾⣿⠇⠀⠀⣿⣿⠀⣿⣿⠀⠀⠀⣿⣿⠀⣿⡇⠈⣿⡇⠀⠀⣿⣿⣤⣤⡄⠀⢸⣿⣧⣤⣤⡄⠀⢸⣿⣆⠀⣿⣿⠀⠀⣿⣿⡀⢀⣿⣿
// ⠛⠛⠀⠀⠀⠀⠀⠈⠛⠿⠿⠛⠀⠀⠀⠛⠛⠀⠘⠛⠃⠀⠀⠛⠛⠀⠛⠀⠈⠛⠃⠀⠀⠛⠛⠛⠛⠃⠀⠘⠛⠛⠛⠛⠃⠀⠀⠙⠿⠿⠟⠁⠀⠀⠀⠛⠿⠿⠛⠀
// https://formless.xyz/opportunities
//
pragma solidity >=0.8.0 <0.9.0;


// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)



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


/// @title Contract code verification.
/// @author [email protected]
/// @notice Code verification library for determining the keccak256
/// hash of the runtime bytecode for deployed contracts.
library CodeVerification {
    enum BuildType {
        WALLET, /* 0 */
        SPLIT, /* 1 */
        PFA_UNIT, /* 2 */
        PFA_COLLECTION /* 3 */
    }
    string public constant VERSION = "1.0.0";

    /// @notice Returns the keccak256 hash of the runtime bytecode
    /// stored at the supplied `address_`.
    function readCodeHash(address address_) public view returns (bytes32) {
        bytes32 codeHash;
        assembly {
            codeHash := extcodehash(address_)
        }
        return codeHash;
    }
}

// ⣿⣿⣿⣿⣿⠀⠀⣰⣿⣿⣿⣷⡀⠀⠀⣶⣶⣶⣦⡀⠀⠀⠀⣶⣶⡄⠀⠀⣶⣶⡆⠀⠀⣶⣶⠀⠀⠀⠀⢰⣶⣶⣶⣶⢀⠀⠀⣤⣶⣶⣦⡀⠀⠀⠀⣴⣶⣶⣦⠀
// ⣿⣿⠀⠀⠀⠀⠀⣿⣿⠀⢸⣿⡇⠀⠀⣿⣿⠀⢻⣿⠀⠀⠀⣿⣿⣿⠀⢸⣿⣿⡇⠀⠀⣿⣿⠀⠀⠀⠀⢸⣿⡇⠀⠀⠀⠀⢸⣿⡇⠀⣿⣿⠀⠀⣾⣿⠁⠈⣿⡇
// ⣿⣿⠀⠀⠀⠀⠀⣿⣿⠀⢸⣿⡇⠀⠀⣿⣿⠀⣸⣿⠀⠀⠀⣿⣿⣿⡀⣿⡟⣿⡇⠀⠀⣿⣿⠀⠀⠀⠀⢸⣿⡇⠀⠀⠀⠀⠀⣿⣿⡀⠀⠀⠀⠀⠘⣿⣷⠀⠀⠀
// ⣿⣿⠿⠿⠀⠀⠀⣿⣿⠀⢸⣿⡇⠀⠀⣿⣿⣿⣿⡟⠀⠀⠀⣿⣿⣿⣷⣿⠀⣿⡇⠀⠀⣿⣿⠀⠀⠀⠀⢸⣿⡿⠿⠀⠀⠀⠀⠀⢿⣿⣦⠀⠀⠀⠀⠈⣿⣿⡄⠀
// ⣿⣿⠀⠀⠀⠀⠀⣿⣿⠀⢸⣿⡇⠀⠀⣿⣿⠈⣿⣷⠀⠀⠀⣿⣿⢸⣿⣿⠈⣿⡇⠀⠀⣿⣿⠀⠀⠀⠀⢸⣿⡇⠀⠀⠀⠀⢀⣀⠀⠙⣿⣧⠀⠀⣀⣀⠀⠻⣿⡆
// ⣿⣿⠀⠀⠀⠀⠀⢿⣿⣤⣾⣿⠇⠀⠀⣿⣿⠀⣿⣿⠀⠀⠀⣿⣿⠀⣿⡇⠈⣿⡇⠀⠀⣿⣿⣤⣤⡄⠀⢸⣿⣧⣤⣤⡄⠀⢸⣿⣆⠀⣿⣿⠀⠀⣿⣿⡀⢀⣿⣿
// ⠛⠛⠀⠀⠀⠀⠀⠈⠛⠿⠿⠛⠀⠀⠀⠛⠛⠀⠘⠛⠃⠀⠀⠛⠛⠀⠛⠀⠈⠛⠃⠀⠀⠛⠛⠛⠛⠃⠀⠘⠛⠛⠛⠛⠃⠀⠀⠙⠿⠿⠟⠁⠀⠀⠀⠛⠿⠿⠛⠀
// https://formless.xyz/opportunities
//



// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)




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


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)



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
     * by making the `nonReentrant` function external, and making it call a
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



// ⣿⣿⣿⣿⣿⠀⠀⣰⣿⣿⣿⣷⡀⠀⠀⣶⣶⣶⣦⡀⠀⠀⠀⣶⣶⡄⠀⠀⣶⣶⡆⠀⠀⣶⣶⠀⠀⠀⠀⢰⣶⣶⣶⣶⢀⠀⠀⣤⣶⣶⣦⡀⠀⠀⠀⣴⣶⣶⣦⠀
// ⣿⣿⠀⠀⠀⠀⠀⣿⣿⠀⢸⣿⡇⠀⠀⣿⣿⠀⢻⣿⠀⠀⠀⣿⣿⣿⠀⢸⣿⣿⡇⠀⠀⣿⣿⠀⠀⠀⠀⢸⣿⡇⠀⠀⠀⠀⢸⣿⡇⠀⣿⣿⠀⠀⣾⣿⠁⠈⣿⡇
// ⣿⣿⠀⠀⠀⠀⠀⣿⣿⠀⢸⣿⡇⠀⠀⣿⣿⠀⣸⣿⠀⠀⠀⣿⣿⣿⡀⣿⡟⣿⡇⠀⠀⣿⣿⠀⠀⠀⠀⢸⣿⡇⠀⠀⠀⠀⠀⣿⣿⡀⠀⠀⠀⠀⠘⣿⣷⠀⠀⠀
// ⣿⣿⠿⠿⠀⠀⠀⣿⣿⠀⢸⣿⡇⠀⠀⣿⣿⣿⣿⡟⠀⠀⠀⣿⣿⣿⣷⣿⠀⣿⡇⠀⠀⣿⣿⠀⠀⠀⠀⢸⣿⡿⠿⠀⠀⠀⠀⠀⢿⣿⣦⠀⠀⠀⠀⠈⣿⣿⡄⠀
// ⣿⣿⠀⠀⠀⠀⠀⣿⣿⠀⢸⣿⡇⠀⠀⣿⣿⠈⣿⣷⠀⠀⠀⣿⣿⢸⣿⣿⠈⣿⡇⠀⠀⣿⣿⠀⠀⠀⠀⢸⣿⡇⠀⠀⠀⠀⢀⣀⠀⠙⣿⣧⠀⠀⣀⣀⠀⠻⣿⡆
// ⣿⣿⠀⠀⠀⠀⠀⢿⣿⣤⣾⣿⠇⠀⠀⣿⣿⠀⣿⣿⠀⠀⠀⣿⣿⠀⣿⡇⠈⣿⡇⠀⠀⣿⣿⣤⣤⡄⠀⢸⣿⣧⣤⣤⡄⠀⢸⣿⣆⠀⣿⣿⠀⠀⣿⣿⡀⢀⣿⣿
// ⠛⠛⠀⠀⠀⠀⠀⠈⠛⠿⠿⠛⠀⠀⠀⠛⠛⠀⠘⠛⠃⠀⠀⠛⠛⠀⠛⠀⠈⠛⠃⠀⠀⠛⠛⠛⠛⠃⠀⠘⠛⠛⠛⠛⠃⠀⠀⠙⠿⠿⠟⠁⠀⠀⠀⠛⠿⠿⠛⠀
// https://formless.xyz/opportunities
//⠀


/// @title Standard pay-for-access (PFA) contract interface for SHARE.
/// @author [email protected]
interface IPFA {
    /// @notice Returns the price per access in wei for content backed
    /// by this contract.
    function pricePerAccess() external view returns (uint256);

    /// @notice Sets the price per access in wei for content backed
    /// by this contract.
    function setPricePerAccess(uint256 pricePerAccess_) external;

    /// @notice If called with a value equal to the price per access
    /// of this contract, records a grant timestamp on chain which is
    /// read by decentralized distribution network (DDN) microservices
    /// to decrypt and serve the associated content for the tokenURI.
    function access(uint256 tokenId, address recipient) external payable;

    /// @notice Returns the timestamp in seconds of the award of a
    /// grant recorded on chain for the access of the content
    /// associated with this PFA.
    function grantTimestamp(address recipient_) external view returns (uint256);

    /// @notice Returns the time-to-live (TTL) in seconds of an
    /// awarded access grant for this PFA. Access to the associated
    ///content expires at `grant award timestamp + grant TTL`.
    function grantTTL() external view returns (uint256);

    /// @notice Returns true if this PFA supports licensing, where
    /// licensing is the ability for a separate contract to forward
    /// payment to this PFA in exchange for the ability to perpetually
    /// serve the underlying content on its behalf. For example,
    /// licensing may be used to achieve transaction gated playlisting
    /// of a collection of PFAs.
    function supportsLicensing() external view returns (bool);

    /// @notice Returns the price per license in wei for content
    /// backed by this contract.
    function pricePerLicense() external view returns (uint256);

    /// @notice If called with a `recipient` (licensee) contract which
    /// has proof of inclusion of this PFA (licensor) address in its
    /// payout distribution table, records a license timestamp on
    /// chain which is read by decentralized distribution (DDN)
    /// microservices to decrypt and serve the associated content for
    /// the tokenURI to users who have paid to access the licensee
    /// contract.
    /// @dev Proof of inclusion is in the form of source code
    /// verification of the licensee, as well as the assertion of
    /// immutable state of the licensee contract payout distribution
    /// table. Immutable state is verified using knowledge of the
    /// keccak256 hash of the runtime bytecode of the source code
    /// for approved licensees which implement a write-once
    /// distribution address table.
    function license(address recipient) external payable;

    /// @notice Returns the timestamp in seconds of the award of a
    /// grant recorded on chain for the access of the content
    /// associated with this PFA.
    function licenseTimestamp(address recipient_)
        external
        view
        returns (uint256);
}


/// @title SHARE protocol contract.
/// @author [email protected]
/// @notice A protocol which works in conjunction with SHARE
/// decentralized distribution network (DDN) microservice endpoints
/// to perform content distribtion on blockchain with creator
/// controlled pay-for-access (PFA) micro-transactions.
contract SHARE is Ownable, ReentrancyGuard {
    /// @notice Emitted when a successful access grant is awarded
    /// to a recipient address for a given PFA contract.
    event Grant(
        address indexed recipient,
        address indexed contractAddress,
        uint256 indexed tokenId
    );

    /// @notice Emitted when a successful license grant is awarded
    /// to a recipient (licensee) address for a given PFA (licensor) contract.
    event License(address indexed licensor, address indexed licensee);

    string public constant VERSION = "1.0.0";
    bytes32
        private constant EOA_KECCAK256 = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
    uint256 public _transactionFeeNumerator = 1;
    uint256 public _transactionFeeDenominator = 20;
    uint256 public _transactionCount = 0;
    bool public _codeVerificationEnabled = true;
    uint256 private constant UNIT_TOKEN_INDEX = 0;

    mapping(bytes32 => ApprovedBuild) internal _approvedHashes;
    mapping(address => mapping(address => uint256)) internal _grantTimestamps;
    mapping(address => mapping(address => uint256)) internal _licenseTimestamps;

    struct ApprovedBuild {
        CodeVerification.BuildType buildType;
        string compilerBinaryTarget;
        string compilerVersion;
        address authorAddress;
        bool exists;
    }

    constructor() public {
        addApprovedBuild(
            EOA_KECCAK256,
            CodeVerification.BuildType.WALLET,
            "",
            "",
            msg.sender
        );
    }

    /// @notice Used to set the transaction fee for the protocol.
    /// Calculated using provided _numerator / _denominator. Note that
    /// SHARE PFA contracts can (optionally) be accessed _without_
    /// using the SHARE protocol contract if the URI microservice
    /// endpoint is self-hosted, however the use of SHARE provided
    /// DDN endpoints requires an associated payment to the protocol.
    function setTransactionFee(uint256 numerator_, uint256 denominator_)
        public
        nonReentrant
        onlyOwner
    {
        _transactionFeeNumerator = numerator_;
        _transactionFeeDenominator = denominator_;
    }

    /// @notice Returns the consumer facing gross price to access the
    /// the asset. This price is calculated using `access price` +
    ///`access price` * `transaction fee`.
    function grossPricePerAccess(address contractAddress_, uint256 tokenId_)
        public
        view
        returns (uint256)
    {
        require(tokenId_ == UNIT_TOKEN_INDEX, "SHARE004");
        IPFA asset = IPFA(contractAddress_);
        uint256 pricePerAccess = asset.pricePerAccess();
        // Note that this contract is implemented with Solidity
        // version >=0.8.0 which has built-in overflow checks,
        // therefore using SafeMath is not required.
        uint256 protocolFee = (pricePerAccess * _transactionFeeNumerator) /
            _transactionFeeDenominator;
        return pricePerAccess + protocolFee;
    }

    /// @notice Returns the licensee facing gross price to license the
    /// the asset. This price is calculated using `license price` +
    ///`license price` * `transaction fee`.
    function grossPricePerLicense(address contractAddress_)
        public
        view
        returns (uint256)
    {
        IPFA asset = IPFA(contractAddress_);
        uint256 pricePerLicense = asset.pricePerLicense();
        // Note that this contract is implemented with Solidity
        // version >=0.8.0 which has built-in overflow checks,
        // therefore using SafeMath is not required.
        uint256 protocolFee = (pricePerLicense * _transactionFeeNumerator) /
            _transactionFeeDenominator;
        return pricePerLicense + protocolFee;
    }

    /// @notice Instantiates the creator contract and calls the
    /// access method. If successful, this transaction produces a
    /// grant awarded to the sender with a corresponding TTL.
    function access(address contractAddress_, uint256 tokenId_)
        public
        payable
        nonReentrant
    {
        IPFA asset = IPFA(contractAddress_);
        uint256 grossPrice = grossPricePerAccess(contractAddress_, tokenId_);
        require(msg.value == grossPrice, "SHARE011");
        asset.access{value: asset.pricePerAccess()}(tokenId_, msg.sender);
        _grantTimestamps[contractAddress_][msg.sender] = block.timestamp;
        emit Grant(msg.sender, contractAddress_, tokenId_);
        _transactionCount++;
    }

    /// @notice If called with a `licenseeContract_` contract which
    /// has proof of inclusion of the supplied `licensorContract_`
    /// PFA address in its payout distribution table, records a
    /// license timestamp on chain which is read by decentralized
    /// distribution network (DDN) microservices to decrypt and serve
    /// the associated content for the tokenURI to users who have
    /// paid to access the licensee contract.
    function license(address licensorContract_, address licenseeContract_)
        public
        payable
        nonReentrant
    {
        require(msg.sender == Ownable(licenseeContract_).owner(), "SHARE016");
        uint256 grossPrice = grossPricePerLicense(licensorContract_);
        require(msg.value == grossPrice, "SHARE024");
        IPFA asset = IPFA(licensorContract_);
        asset.license{value: asset.pricePerLicense()}(licenseeContract_);
        _licenseTimestamps[licensorContract_][licenseeContract_] = block
            .timestamp;
        emit License(licensorContract_, licenseeContract_);
    }

    /// @notice Returns the timestamp in seconds of the award of a
    /// grant recorded on chain for the access of the content
    /// associated with the supplied PFA and recipient address.
    function grantTimestamp(address contractAddress_, address recipient_)
        public
        view
        returns (uint256)
    {
        return _grantTimestamps[contractAddress_][recipient_];
    }

    /// @notice Returns the timestamp in seconds of the award of a
    /// grant recorded on chain for the licensing of the content
    /// associated with the supplied PFA and recipient address.
    function licenseTimestamp(
        address licensorAddress_,
        address licenseeAddress_
    ) public view returns (uint256) {
        return _licenseTimestamps[licensorAddress_][licenseeAddress_];
    }

    /// @notice Withdraws contract balance.
    function withdraw() public nonReentrant onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    /// @notice Enables or disables protocol source code verification
    /// for contracts interacting with the protocol.
    function setCodeVerificationEnabled(bool enable)
        public
        nonReentrant
        onlyOwner
    {
        _codeVerificationEnabled = enable;
    }

    /// @notice Adds the keccak256 hash of the runtime bytecode of
    /// an approved source code build for a SHARE protocol
    /// interoperable contract. If source code verification is turned
    /// on, the system will revert upon attempt to send ether to
    /// a contract built from non-approved source code.
    function addApprovedBuild(
        bytes32 codeHash,
        CodeVerification.BuildType buildType_,
        string memory compilerBinaryTarget_,
        string memory compilerVersion_,
        address authorAddress_
    ) public onlyOwner nonReentrant {
        require(
            (buildType_ == CodeVerification.BuildType.WALLET ||
                buildType_ == CodeVerification.BuildType.SPLIT ||
                buildType_ == CodeVerification.BuildType.PFA_UNIT ||
                buildType_ == CodeVerification.BuildType.PFA_COLLECTION),
            "SHARE017"
        );
        _approvedHashes[codeHash] = ApprovedBuild(
            buildType_,
            compilerBinaryTarget_,
            compilerVersion_,
            authorAddress_,
            true
        );
    }

    /// @notice Returns true if the keccak256 hash of the runtime
    /// bytecode stored at the given `address_` corresponds to a build
    /// of approved source code for SHARE protocol interoperability.
    function isApprovedBuild(
        address address_,
        CodeVerification.BuildType buildType_
    ) public view returns (bool) {
        if (!_codeVerificationEnabled) {
            return true;
        } else {
            bytes32 codeHash = CodeVerification.readCodeHash(address_);
            if (_approvedHashes[codeHash].exists) {
                return _approvedHashes[codeHash].buildType == buildType_;
            } else {
                return false;
            }
        }
    }

    /// @notice Returns true if the supplied keccak256
    /// hash corresponds to a build of approved source code for SHARE
    /// protocol interoperability.
    function isApprovedBuildHash(
        bytes32 hash,
        CodeVerification.BuildType buildType_
    ) public view returns (bool) {
        if (!_codeVerificationEnabled) {
            return true;
        } else {
            if (_approvedHashes[hash].exists) {
                return _approvedHashes[hash].buildType == buildType_;
            } else {
                return false;
            }
        }
    }
}