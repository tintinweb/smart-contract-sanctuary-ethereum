// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol"; // TODO: use roles instead
import "./base/Allowlist.sol";
import "./base/Sale.sol";

/**
 * @title AllowlistedSale
 * @dev Sale in which only allowlisted users can contribute.
 */
contract AllowlistedSale is Ownable, Sale, Allowlist {
    /// @notice Deposits exceeds allowed limit
    /// @param deposit requested amount to transfer
    /// @param limit deposit limit for user
    error DepositLimitExceeded(uint256 deposit, uint256 limit);

    constructor(
        uint256 _duration,
        address _beneficiary,
        address _rewardToken
    ) Sale(_duration, _beneficiary, _rewardToken) {} // solhint-disable-line no-empty-blocks

    /**
     * @notice Restrict sale to allowlisted addresses
     * @dev Extends #deposit() from "./base/Sale.sol". Adds allowlist functionality.
     * @param proof Merkle proof for Allowlist
     */
    function deposit2(bytes32[] calldata proof) public payable {
        uint256 allowedAmount = getAllowedAmount(msg.sender, proof);

        if (deposits[msg.sender] + msg.value > allowedAmount) {
            revert DepositLimitExceeded(msg.value, allowedAmount - deposits[msg.sender]);
        }
        _deposit();
    }

    function deposit() public payable override {
        revert Unauthorized();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
 * @title Allowlist
 * @notice Allowlist using MerkleProof.
 * @dev Use to generate root and proof https://github.com/miguelmota/merkletreejs
 */
contract Allowlist is Ownable {
    /// @notice small deposit limit to check for in Merkle proof
    uint256 public constant SMALL_AMOUNT = 1 ether;
    /// @notice large deposit limit to check for in Merkle proof
    uint256 public constant LARGE_AMOUNT = 2 ether;

    /// @notice Allowlist inclusion root
    bytes32 public merkleRoot;

    /**
     * @notice Set merkleRoot
     * @param _root new merkle root
     */
    function setMerkleRoot(bytes32 _root) external onlyOwner {
        merkleRoot = _root;
    }

    /// @notice Verifies the Merkle proof and returns the max deposit amount for the given address.
    /// Creates 2 leaves, using 2 different deposit limits, and returns the valid limit, or zero if
    /// both leaves are invalid.
    /// @dev We make 2 leaves, since the user will not input their deposit limit.
    /// The original leaves in the Merkle Tree should contain an address and deposit limit in wei.
    /// @param _address address to check
    /// @param proof merkle proof verify
    function getAllowedAmount(address _address, bytes32[] calldata proof)
        public
        view
        returns (uint256)
    {
        bytes32 smallLeaf = keccak256(abi.encodePacked(_address, SMALL_AMOUNT));
        bytes32 largeLeaf = keccak256(abi.encodePacked(_address, LARGE_AMOUNT));

        if (MerkleProof.verify(proof, merkleRoot, smallLeaf)) {
            return SMALL_AMOUNT;
        } else if (MerkleProof.verify(proof, merkleRoot, largeLeaf)) {
            return LARGE_AMOUNT;
        }

        revert("Allowlist: invalid proof");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title Sale
 * @notice Sale where users deposit ether, and after a vesting period can claim the reward token.
 */
contract Sale is ReentrancyGuard, Pausable, Ownable {
    using SafeERC20 for IERC20;

    /// @notice Duration of sale
    uint256 public immutable DURATION;

    /// @notice address deposited funds are withdrawn to
    address public immutable BENEFICIARY;

    /// @notice token to swap for ether
    IERC20 public immutable REWARD_TOKEN;

    /// @notice IBCO finalization indicator
    bool public finalized = false;

    /// @notice timestamp that the sale begins
    uint256 public startTime = 99999999999;

    /// @notice accumalated deopsits in wei
    uint256 public depositsRaised;

    /// @notice accumalated REWARD_TOKENs claimed in wei
    uint256 public rewardsClaimed;

    /// @notice exchange rate of REWARD_TOKEN to ether
    /// Example:
    ///   let rate=1000, let deposit=2 ether;
    ///   rate*deposit = REWARD_TOKEN_quantity == 1000*2 = 2000 REWARD_TOKENs.
    uint256 public rate;

    /// @notice how much ETH in wei each wallet has deposited
    mapping(address => uint256) public deposits;

    /// @notice how much REWARD_TOKENs in wei each wallet has withdrawn
    mapping(address => uint256) private claimed;

    /// @notice watchdog for startTime
    bool private startTimeLock = false;

    /// @notice timestamp to start allowing claiming
    uint256 private claimTime = 99999999999;

    /**
     * @notice Indicates a deposit was made
     * @param account who deposited
     * @param amount amount deposited
     */
    event Deposit(address indexed account, uint256 amount);

    /**
     * @notice Indicates a claim was made
     * @param account who claimed
     * @param amount reward token amount claimed
     */
    event Claim(address indexed account, uint256 amount);

    /**
     * @notice Event for IBCO finalization
     * @dev Will only be called once
     * @param rate_ final reward token rate in REWARD_TOKEN to ether
     * @param time timestamp sale was finalized
     */
    event Finalize(uint256 rate_, uint256 time);

    /**
     * @notice Indicates a deposit was withdrawn
     * @param account who withdrawn their deposit
     * @param amount amount of eth withdrawn
     */
    event WithdrawDeposit(address indexed account, uint256 amount);

    // Errors
    error Unauthorized();

    /// @notice Provided address is invalid
    /// @param _address the invalid address
    error InvalidAddress(address _address);

    /// @notice Provided amount is invalid
    /// @param amount the invalid amount
    error InvalidAmount(uint256 amount);

    /// @notice Call is locked by watchdog
    error Locked();

    /// @notice Sale is not ended
    error NotEnded();

    /// @notice Sale is not started
    error NotStarted();

    /// @notice Claim time is not reached
    error NotClaimTime();

    /// @notice Sale is ended
    error Ended();

    /// @notice Transfer of ether or token has failed
    /// @param amount requested amount to transfer.
    error TransferFailure(uint256 amount);

    /// @notice Insufficient balance for transfer
    error InsufficientBalance();

    /// @notice IBCO not finalized
    error NotFinalized();

    /// @notice IBCO finalized
    error Finalized();

    constructor(
        uint256 _duration,
        address _beneficiary,
        address _rewardToken
    ) {
        DURATION = _duration;
        BENEFICIARY = _beneficiary;
        REWARD_TOKEN = IERC20(_rewardToken);
    }

    /*******************************************/
    /* external                                */
    /*******************************************/
    /**
     * @notice Public wrapper for #_deposit()
     */
    function deposit() external payable virtual {
        _deposit();
    }

    /**
     * @notice Withdraw eth you previously deposited
     * @param amount amount to withdraw from your deposits
     * This function has a non-reentrancy guard, so it shouldn't be called by
     * another `nonReentrant` function.
     */
    function withdrawDeposit(uint256 amount) external nonReentrant {
        _preValidateWithdrawDeposit(msg.sender, amount);
        _updateWithdrawDepositState(msg.sender, amount);

        // Send eth to msg.sender
        // This forwards all available gas
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = msg.sender.call{value: amount}("");
        if (!success) revert TransferFailure(amount);

        emit WithdrawDeposit(msg.sender, amount);
    }

    /**
     * @dev This function has a non-reentrancy guard, so it shouldn't be called by
     * another `nonReentrant` function.
     * @notice Send the claimableRewardBalanceOf(msg.sender) to msg.sender
     */
    function claim() external nonReentrant {
        uint256 claimableBalance = claimableRewardBalanceOf(msg.sender);

        _preValidateClaim(msg.sender, claimableBalance);

        _updateClaimState(msg.sender, claimableBalance);

        // Transfer reward tokens
        REWARD_TOKEN.safeTransfer(msg.sender, claimableBalance);

        emit Claim(msg.sender, claimableBalance);
    }

    /**
     * @notice Computes the current amount of unclaimable tokens for a given user.
     * @param wallet Wallet address to check balance of
     * @return Number of tokens the supplied address cannot currently withdraw
     */
    function unclaimableRewardBalanceOf(address wallet) external view virtual returns (uint256) {
        if (block.timestamp > claimTime) {
            return 0;
        }

        return (deposits[wallet] * rate) - claimed[wallet];
    }

    /**
     * @notice Finalize IBCO. Can only be called once, and can be called by anyone.
     */
    function finalize() external {
        if (finalized) revert Locked();
        if (block.timestamp < startTime + DURATION) revert NotEnded();

        /// @notice Calculate the final token rate in REWARD_TOKEN to ether
        rate = REWARD_TOKEN.balanceOf(address(this)) / depositsRaised;

        // Set finalization lock
        finalized = true;

        emit Finalize(rate, block.timestamp);
    }

    /*******************************************/
    /* external onlyOwner                      */
    /*******************************************/
    /**
     * @notice Set startTime
     * @param _timestamp timestamp to start sale at
     */
    function setStartTime(uint256 _timestamp) external onlyOwner {
        if (startTimeLock) revert Locked();
        startTime = _timestamp;
    }

    /**
     * @notice Lock startTime from being changed
     */
    function lockStartTime() external onlyOwner {
        if (startTimeLock) revert Locked();
        startTimeLock = true;
    }

    /**
     * @notice Set claimTime
     * @param _timestamp timestamp to start allowing claiming
     */
    function setClaimTime(uint256 _timestamp) external onlyOwner {
        claimTime = _timestamp;
    }

    /**
     * @notice Withdraw funds to BENEFICIARY
     */
    function withdraw() external onlyOwner {
        if (!finalized) revert NotFinalized();

        uint256 bal = address(this).balance;
        if (bal <= 0) revert InsufficientBalance();

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = payable(BENEFICIARY).call{value: bal}("");
        if (!success) revert TransferFailure(bal);
    }

    /**
     * @notice Withdraw the reward tokens that are unclaimed 45 days after `claimTime`.
     */
    // TODO: maybe remove, or make more than 45 days
    function withdrawUnclaimedRewardTokens() external onlyOwner {
        uint256 rewardBalance = REWARD_TOKEN.balanceOf(address(this));

        if (block.timestamp <= claimTime + 45 days) revert Unauthorized();
        if (rewardBalance <= 0) revert InsufficientBalance();

        REWARD_TOKEN.safeTransfer(BENEFICIARY, rewardBalance);
    }

    /**
     * @dev Pause vital functions. To be used in an emergency.
     * Used in _preValidateDeposit and _preValidateClaim.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpause vital functions.
     * Used in _preValidateDeposit and _preValidateClaim.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /*******************************************/
    /* public                                  */
    /*******************************************/
    /**
     * @notice Computes the current amount of claimable tokens for a given user.
     * Returns 0 if the sale is not yet claimTime.
     * Else, returns (deposits[wallet] * rate) - claimed[wallet].
     * @param wallet Wallet address to check balance of
     * @return Number of tokens the supplied address can currently withdraw
     */
    function claimableRewardBalanceOf(address wallet) public view virtual returns (uint256) {
        if (block.timestamp <= claimTime) {
            return 0;
        }

        return (deposits[wallet] * rate) - claimed[wallet];
    }

    /*******************************************/
    /* internal                                */
    /*******************************************/
    /**
     * @notice Deposit eth into the IBCO
     * @dev Must be wrapped by and public/external function.
     * This function has a non-reentrancy guard, so it shouldn't be called by
     * another `nonReentrant` function.
     */
    function _deposit() internal virtual nonReentrant {
        _preValidateDeposit(msg.sender, msg.value);

        _updateDepositState(msg.sender, msg.value);

        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @dev Validate incoming deposit.
     * @param _depositor Address performing the deposit
     * @param _depositAmount Value in wei involved in the deposit
     */
    function _preValidateDeposit(address _depositor, uint256 _depositAmount)
        internal
        view
        virtual
        whenNotPaused
    {
        if (_depositor == address(0)) revert InvalidAddress(_depositor);
        if (_depositAmount <= 0) revert InvalidAmount(_depositAmount);
        if (block.timestamp < startTime) revert NotStarted();
        if (block.timestamp > startTime + DURATION) revert Ended();

        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    }

    /**
     * @dev State updates for an incoming deposit.
     * @param _depositor Address depositing ether
     * @param _depositAmount Value in wei involved in the deposit
     */
    function _updateDepositState(address _depositor, uint256 _depositAmount) internal {
        depositsRaised = depositsRaised + _depositAmount;
        deposits[_depositor] = deposits[_depositor] + _depositAmount;
    }

    /**
     * @dev Validate incoming withdrawal of deposits.
     * @param _withdrawer Address performing the withdrawDeposit
     * @param _withdrawAmount Value in wei involved in the withdrawDeposit
     */
    function _preValidateWithdrawDeposit(address _withdrawer, uint256 _withdrawAmount)
        internal
        view
        virtual
        whenNotPaused
    {
        if (_withdrawer == address(0)) revert InvalidAddress(_withdrawer);
        if (_withdrawAmount <= 0) revert InvalidAmount(_withdrawAmount);
        if (finalized) revert Finalized();
        if (block.timestamp < startTime) revert NotStarted();
        if (block.timestamp > startTime + DURATION) revert Ended();
        if (address(this).balance == 0) revert InsufficientBalance();
        if (_withdrawAmount > deposits[_withdrawer]) revert InsufficientBalance();

        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    }

    /**
     * @dev State updates for a withdrawal of deposits.
     * @param _depositor Address performing the withdrawDeposit
     * @param _withdrawAmount Value in wei involved in the withdrawDeposit
     */
    function _updateWithdrawDepositState(address _depositor, uint256 _withdrawAmount) internal {
        depositsRaised = depositsRaised - _withdrawAmount;
        deposits[_depositor] = deposits[_depositor] - _withdrawAmount;
    }

    /**
     * @dev Validate incoming claim.
     * @param claimer Address performing the claim
     * @param claimAmount Value in wei involved in the claim
     */
    function _preValidateClaim(address claimer, uint256 claimAmount)
        internal
        view
        virtual
        whenNotPaused
    {
        if (!finalized) revert NotFinalized();
        if (claimer == address(0)) revert InvalidAddress(claimer);
        if (block.timestamp < claimTime) revert NotClaimTime();
        if (claimAmount <= 0) revert InsufficientBalance();

        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    }

    /**
     * @dev State updates for an incoming claim.
     * @param claimer Address claiming
     * @param claimAmount Value in wei involved in the deposit
     */
    function _updateClaimState(address claimer, uint256 claimAmount) internal {
        // Add to rewardsClaimed total tracker
        rewardsClaimed = rewardsClaimed + claimAmount;

        // Update claimed amount for claimer
        claimed[claimer] = claimed[claimer] + claimAmount;
    }
}