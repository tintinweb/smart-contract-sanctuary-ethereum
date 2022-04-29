/**
 *Submitted for verification at Etherscan.io on 2022-04-29
*/

/**
 *Submitted for verification at Etherscan.io on 2022-04-29
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}


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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProofUpgradeable {
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

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

interface IMintableERC20 is IERC20Metadata {
    function mint(address _recipient, uint256 _amount) external;

    function burnFrom(address account, uint256 amount) external;

    function lowerHasMinted(uint256 amount) external;
}

library FixedPointMath {
    uint256 public constant DECIMALS = 18;
    uint256 public constant SCALAR = 10**DECIMALS;

    struct FixedDecimal {
        uint256 x;
    }

    function fromU256(uint256 value)
        internal
        pure
        returns (FixedDecimal memory)
    {
        uint256 x;
        require(value == 0 || (x = value * SCALAR) / SCALAR == value);
        return FixedDecimal(x);
    }

    function maximumValue() internal pure returns (FixedDecimal memory) {
        return FixedDecimal(type(uint256).max);
    }

    function add(FixedDecimal memory self, FixedDecimal memory value)
        internal
        pure
        returns (FixedDecimal memory)
    {
        uint256 x;
        require((x = self.x + value.x) >= self.x);
        return FixedDecimal(x);
    }

    function add(FixedDecimal memory self, uint256 value)
        internal
        pure
        returns (FixedDecimal memory)
    {
        return add(self, fromU256(value));
    }

    function sub(FixedDecimal memory self, FixedDecimal memory value)
        internal
        pure
        returns (FixedDecimal memory)
    {
        uint256 x;
        require((x = self.x - value.x) <= self.x);
        return FixedDecimal(x);
    }

    function sub(FixedDecimal memory self, uint256 value)
        internal
        pure
        returns (FixedDecimal memory)
    {
        return sub(self, fromU256(value));
    }

    function mul(FixedDecimal memory self, uint256 value)
        internal
        pure
        returns (FixedDecimal memory)
    {
        uint256 x;
        require(value == 0 || (x = self.x * value) / value == self.x);
        return FixedDecimal(x);
    }

    function div(FixedDecimal memory self, uint256 value)
        internal
        pure
        returns (FixedDecimal memory)
    {
        require(value != 0);
        return FixedDecimal(self.x / value);
    }

    function cmp(FixedDecimal memory self, FixedDecimal memory value)
        internal
        pure
        returns (int256)
    {
        if (self.x < value.x) {
            return -1;
        }

        if (self.x > value.x) {
            return 1;
        }

        return 0;
    }

    function decode(FixedDecimal memory self) internal pure returns (uint256) {
        return self.x / SCALAR;
    }
}

/// @title Pool
///
/// @dev A library which provides the Merkle Pool data struct and associated functions.
library MerklePool {
    using FixedPointMath for FixedPointMath.FixedDecimal;
    using MerklePool for MerklePool.Data;
    using MerklePool for MerklePool.List;

    struct Context {
        uint256 rewardRate;
        uint256 totalRewardWeight;
    }

    struct Data {
        address token;
        uint256 totalDeposited;
        uint256 totalUnclaimedTIC;
        uint256 totalUnclaimedTICInLP;
        uint256 rewardWeight;
        FixedPointMath.FixedDecimal accumulatedRewardWeight;
        uint256 lastUpdatedBlockTimestamp;
    }

    struct List {
        Data[] elements;
    }

    /// @dev Updates the pool.
    ///
    /// @param _ctx the pool context.
    function update(Data storage _data, Context storage _ctx) internal {
        _data.accumulatedRewardWeight = _data.getUpdatedAccumulatedRewardWeight(
            _ctx
        );

        // TODO: make this more gas efficient! we calc it twice!
        _data.totalUnclaimedTIC = _data.getUpdatedTotalUnclaimed(_ctx);
        _data.lastUpdatedBlockTimestamp = block.timestamp;
    }

    /// @dev Gets the rate at which the pool will distribute rewards to stakers.
    ///
    /// @param _ctx the pool context.
    ///
    /// @return the reward rate of the pool in tokens per second.
    function getRewardRate(Data storage _data, Context storage _ctx)
        internal
        view
        returns (uint256)
    {
        if (_ctx.totalRewardWeight == 0) {
            return 0;
        }

        return (_ctx.rewardRate * _data.rewardWeight) / _ctx.totalRewardWeight;
    }

    /// @dev Gets the accumulated reward weight of a pool.
    ///
    /// @param _ctx the pool context.
    ///
    /// @return the accumulated reward weight.
    function getUpdatedAccumulatedRewardWeight(
        Data storage _data,
        Context storage _ctx
    ) internal view returns (FixedPointMath.FixedDecimal memory) {
        if (_data.totalDeposited == 0) {
            return _data.accumulatedRewardWeight;
        }
        uint256 amountToDistribute = _data.getUpdatedAmountToDistribute(_ctx);
        if (amountToDistribute == 0) {
            return _data.accumulatedRewardWeight;
        }

        FixedPointMath.FixedDecimal memory rewardWeight =
            FixedPointMath.fromU256(amountToDistribute).div(
                _data.totalDeposited
            );

        return _data.accumulatedRewardWeight.add(rewardWeight);
    }

    /**
     * @dev get's the total amount to distribute in this pool based on the last updated timestamp.
     * @param _data pool's data
     * @param _ctx the pool context
     */
    function getUpdatedAmountToDistribute(
        Data storage _data,
        Context storage _ctx
    ) internal view returns (uint256) {
        uint256 elapsedTime = block.timestamp - _data.lastUpdatedBlockTimestamp;

        if (elapsedTime == 0) {
            return 0;
        }

        uint256 rewardRate = _data.getRewardRate(_ctx);
        return rewardRate * elapsedTime;
    }

    /**
     * @dev get's the total amount unclaimed in this pool based on the last updated timestamp.
     * @param _data pool's data
     * @param _ctx the pool context
     */
    function getUpdatedTotalUnclaimed(Data storage _data, Context storage _ctx)
        internal
        view
        returns (uint256)
    {
        if (_data.totalDeposited == 0) {
            return _data.totalUnclaimedTIC;
        }
        return
            _data.totalUnclaimedTIC + _data.getUpdatedAmountToDistribute(_ctx);
    }

    /// @dev Adds an element to the list.
    ///
    /// @param _element the element to add.
    function push(List storage _self, Data memory _element) internal {
        _self.elements.push(_element);
    }

    /// @dev Gets an element from the list.
    ///
    /// @param _index the index in the list.
    ///
    /// @return the element at the specified index.
    function get(List storage _self, uint256 _index)
        internal
        view
        returns (Data storage)
    {
        require(_index < _self.elements.length, "MerklePool: INVALID_INDEX");
        return _self.elements[_index];
    }

    /// @dev Gets the last element in the list.
    ///
    /// This function will revert if there are no elements in the list.
    ///ck
    /// @return the last element in the list.
    function last(List storage _self) internal view returns (Data storage) {
        return _self.elements[_self.lastIndex()];
    }

    /// @dev Gets the index of the last element in the list.
    ///
    /// This function will revert if there are no elements in the list.
    ///
    /// @return the index of the last element.
    function lastIndex(List storage _self) internal view returns (uint256) {
        return _self.length() - 1;
    }

    /// @dev Gets the number of elements in the list.
    ///
    /// @return the number of elements.
    function length(List storage _self) internal view returns (uint256) {
        return _self.elements.length;
    }
}

/// @title Stake
///
/// @dev A library which provides the Stake data struct and associated functions.
library MerkleStake {
    using FixedPointMath for FixedPointMath.FixedDecimal;
    using MerklePool for MerklePool.Data;
    using MerkleStake for MerkleStake.Data;

    struct Data {
        uint256 totalDeposited;
        uint256 totalUnrealized;
        uint256 totalRealizedTIC;
        uint256 totalRealizedLP;
        FixedPointMath.FixedDecimal lastAccumulatedWeight;
    }

    function update(
        Data storage _self,
        MerklePool.Data storage _pool,
        MerklePool.Context storage _ctx
    ) internal {
        _self.totalUnrealized = _self.getUpdatedTotalUnclaimed(_pool, _ctx);
        _self.lastAccumulatedWeight = _pool.getUpdatedAccumulatedRewardWeight(
            _ctx
        );
    }

    function getUpdatedTotalUnclaimed(
        Data storage _self,
        MerklePool.Data storage _pool,
        MerklePool.Context storage _ctx
    ) internal view returns (uint256) {
        FixedPointMath.FixedDecimal memory currentAccumulatedWeight =
            _pool.getUpdatedAccumulatedRewardWeight(_ctx);
        FixedPointMath.FixedDecimal memory lastAccumulatedWeight =
            _self.lastAccumulatedWeight;

        if (currentAccumulatedWeight.cmp(lastAccumulatedWeight) == 0) {
            return _self.totalUnrealized;
        }

        uint256 amountToDistribute =
            currentAccumulatedWeight
                .sub(lastAccumulatedWeight)
                .mul(_self.totalDeposited)
                .decode();

        return _self.totalUnrealized + amountToDistribute;
    }
}

/**
 * @dev Represents all storage for our MerklePools contract for easy upgrading later
 */
contract MerklePoolsStorage {
    IMintableERC20 public ticToken; // token which will be minted as a reward for staking.
    uint256 public excessTICFromSlippage; // extra TIC that can be used before next mint

    address public quoteToken; // other half of the LP token (not the reward token)
    address public elasticLPToken; // elastic LP token we create to emit for claimed rewards
    address public governance;
    address public pendingGovernance;
    address public forfeitAddress; // receives all unclaimed TIC when someone exits

    bytes32 public merkleRoot;
    bool public isClaimsEnabled; // disabled flag until first merkle proof is set.

    // Tokens are mapped to their pool identifier plus one. Tokens that do not have an associated pool
    // will return an identifier of zero.
    mapping(address => uint256) public tokenPoolIds;

    MerklePool.Context public poolContext; // The context shared between the pools.
    MerklePool.List internal pools; // A list of all of the pools.

    // mapping of all of the user stakes mapped first by pool and then by address.
    mapping(address => mapping(uint256 => MerkleStake.Data)) public stakes;
}

/**
 * @title MathLib
 * @author ElasticDAO
 */
library MathLib {
    struct InternalBalances {
        // x*y=k - we track these internally to compare to actual balances of the ERC20's
        // in order to calculate the "decay" or the amount of balances that are not
        // participating in the pricing curve and adding additional liquidity to swap.
        uint256 baseTokenReserveQty; // x
        uint256 quoteTokenReserveQty; // y
        uint256 kLast; // as of the last add / rem liquidity event
    }

    // aids in avoiding stack too deep errors.
    struct TokenQtys {
        uint256 baseTokenQty;
        uint256 quoteTokenQty;
        uint256 liquidityTokenQty;
        uint256 liquidityTokenFeeQty;
    }

    uint256 public constant BASIS_POINTS = 10000;
    uint256 public constant WAD = 1e18; // represent a decimal with 18 digits of precision

    /**
     * @dev divides two float values, required since solidity does not handle
     * floating point values.
     *
     * inspiration: https://github.com/dapphub/ds-math/blob/master/src/math.sol
     *
     * NOTE: this rounds to the nearest integer (up or down). For example .666666 would end up
     * rounding to .66667.
     *
     * @return uint256 wad value (decimal with 18 digits of precision)
     */
    function wDiv(uint256 a, uint256 b) public pure returns (uint256) {
        return ((a * WAD) + (b / 2)) / b;
    }

    /**
     * @dev rounds a integer (a) to the nearest n places.
     * IE roundToNearest(123, 10) would round to the nearest 10th place (120).
     */
    function roundToNearest(uint256 a, uint256 n)
        public
        pure
        returns (uint256)
    {
        return ((a + (n / 2)) / n) * n;
    }

    /**
     * @dev multiplies two float values, required since solidity does not handle
     * floating point values
     *
     * inspiration: https://github.com/dapphub/ds-math/blob/master/src/math.sol
     *
     * @return uint256 wad value (decimal with 18 digits of precision)
     */
    function wMul(uint256 a, uint256 b) public pure returns (uint256) {
        return ((a * b) + (WAD / 2)) / WAD;
    }

    /**
     * @dev calculates an absolute diff between two integers. Basically the solidity
     * equivalent of Math.abs(a-b);
     */
    function diff(uint256 a, uint256 b) public pure returns (uint256) {
        if (a >= b) {
            return a - b;
        }
        return b - a;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 x) public pure returns (uint256 y) {
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    /**
     * @dev defines the amount of decay needed in order for us to require a user to handle the
     * decay prior to a double asset entry as the equivalent of 1 unit of quote token
     */
    function isSufficientDecayPresent(
        uint256 _baseTokenReserveQty,
        InternalBalances memory _internalBalances
    ) public pure returns (bool) {
        return (wDiv(
            diff(_baseTokenReserveQty, _internalBalances.baseTokenReserveQty) *
                WAD,
            wDiv(
                _internalBalances.baseTokenReserveQty,
                _internalBalances.quoteTokenReserveQty
            )
        ) >= WAD); // the amount of base token (a) decay is greater than 1 unit of quote token (token b)
    }

    /**
     * @dev used to calculate the qty of token a liquidity provider
     * must add in order to maintain the current reserve ratios
     * @param _tokenAQty base or quote token qty to be supplied by the liquidity provider
     * @param _tokenAReserveQty current reserve qty of the base or quote token (same token as tokenA)
     * @param _tokenBReserveQty current reserve qty of the other base or quote token (not tokenA)
     */
    function calculateQty(
        uint256 _tokenAQty,
        uint256 _tokenAReserveQty,
        uint256 _tokenBReserveQty
    ) public pure returns (uint256 tokenBQty) {
        require(_tokenAQty != 0, "MathLib: INSUFFICIENT_QTY");
        require(
            _tokenAReserveQty != 0 && _tokenBReserveQty != 0,
            "MathLib: INSUFFICIENT_LIQUIDITY"
        );
        tokenBQty = (_tokenAQty * _tokenBReserveQty) / _tokenAReserveQty;
    }

    /**
     * @dev used to calculate the qty of token a trader will receive (less fees)
     * given the qty of token A they are providing
     * @param _tokenASwapQty base or quote token qty to be swapped by the trader
     * @param _tokenAReserveQty current reserve qty of the base or quote token (same token as tokenA)
     * @param _tokenBReserveQty current reserve qty of the other base or quote token (not tokenA)
     * @param _liquidityFeeInBasisPoints fee to liquidity providers represented in basis points
     */
    function calculateQtyToReturnAfterFees(
        uint256 _tokenASwapQty,
        uint256 _tokenAReserveQty,
        uint256 _tokenBReserveQty,
        uint256 _liquidityFeeInBasisPoints
    ) public pure returns (uint256 qtyToReturn) {
        uint256 tokenASwapQtyLessFee =
            _tokenASwapQty * (BASIS_POINTS - _liquidityFeeInBasisPoints);
        qtyToReturn =
            (tokenASwapQtyLessFee * _tokenBReserveQty) /
            ((_tokenAReserveQty * BASIS_POINTS) + tokenASwapQtyLessFee);
    }

    /**
     * @dev used to calculate the qty of liquidity tokens (deltaRo) we will be issued to a supplier
     * of a single asset entry when base token decay is present.
     * @param _baseTokenReserveBalance the total balance (external) of base tokens in our pool (Alpha)
     * @param _totalSupplyOfLiquidityTokens the total supply of our exchange's liquidity tokens (aka Ro)
     * @param _tokenQtyAToAdd the amount of tokens being added by the caller to remove the current decay
     * @param _internalTokenAReserveQty the internal balance (X or Y) of token A as a result of this transaction
     * @param _omega - ratio of internal balances of baseToken and quoteToken: baseToken/quoteToken
     * @return liquidityTokenQty qty of liquidity tokens to be issued in exchange
     */
    function calculateLiquidityTokenQtyForSingleAssetEntryWithBaseTokenDecay(
        uint256 _baseTokenReserveBalance,
        uint256 _totalSupplyOfLiquidityTokens,
        uint256 _tokenQtyAToAdd,
        uint256 _internalTokenAReserveQty,
        uint256 _omega
    ) public pure returns (uint256 liquidityTokenQty) {
        /**
        
        (is the formula in the terms of quoteToken)
                    ΔY 
            = ---------------------                                                    
                Alpha/Omega + Y'


         */
        uint256 wRatio = wDiv(_baseTokenReserveBalance, _omega);
        uint256 denominator = wRatio + _internalTokenAReserveQty;
        uint256 wGamma = wDiv(_tokenQtyAToAdd, denominator);

        liquidityTokenQty =
            wDiv(
                wMul(_totalSupplyOfLiquidityTokens * WAD, wGamma),
                WAD - wGamma
            ) /
            WAD;
    }

    /**
     * @dev used to calculate the qty of liquidity tokens (deltaRo) we will be issued to a supplier
     * of a single asset entry when quote decay is present.
     * @param _baseTokenReserveBalance the total balance (external) of base tokens in our pool (Alpha)
     * @param _totalSupplyOfLiquidityTokens the total supply of our exchange's liquidity tokens (aka Ro)
     * @param _tokenQtyAToAdd the amount of tokens being added by the caller to remove the current decay
     * @param _internalTokenAReserveQty the internal balance (X or Y) of token A as a result of this transaction
     * @return liquidityTokenQty qty of liquidity tokens to be issued in exchange
     */
    function calculateLiquidityTokenQtyForSingleAssetEntryWithQuoteTokenDecay(
        uint256 _baseTokenReserveBalance,
        uint256 _totalSupplyOfLiquidityTokens,
        uint256 _tokenQtyAToAdd,
        uint256 _internalTokenAReserveQty
    ) public pure returns (uint256 liquidityTokenQty) {
        /**
        
               ΔX
        = -------------------  / (denominator may be Alpha' instead of X)
           X + (Alpha + ΔX)

        */

        uint256 denominator =
            _internalTokenAReserveQty +
                _baseTokenReserveBalance +
                _tokenQtyAToAdd;
        uint256 wGamma = wDiv(_tokenQtyAToAdd, denominator);

        liquidityTokenQty =
            wDiv(
                wMul(_totalSupplyOfLiquidityTokens * WAD, wGamma),
                WAD - wGamma
            ) /
            WAD;
    }

    /**
     * @dev used to calculate the qty of liquidity tokens (deltaRo) we will be issued to a supplier
     * of a single asset entry when decay is present.
     * @param _totalSupplyOfLiquidityTokens the total supply of our exchange's liquidity tokens (aka Ro)
     * @param _quoteTokenQty the amount of quote token the user it adding to the pool (deltaB or deltaY)
     * @param _quoteTokenReserveBalance the total balance (external) of quote tokens in our pool (Beta)
     *
     * @return liquidityTokenQty qty of liquidity tokens to be issued in exchange
     */
    function calculateLiquidityTokenQtyForDoubleAssetEntry(
        uint256 _totalSupplyOfLiquidityTokens,
        uint256 _quoteTokenQty,
        uint256 _quoteTokenReserveBalance
    ) public pure returns (uint256 liquidityTokenQty) {
        liquidityTokenQty =
            (_quoteTokenQty * _totalSupplyOfLiquidityTokens) /
            _quoteTokenReserveBalance;
    }

    /**
     * @dev used to calculate the qty of quote token required and liquidity tokens (deltaRo) to be issued
     * in order to add liquidity and remove base token decay.
     * @param _quoteTokenQtyDesired the amount of quote token the user wants to contribute
     * @param _baseTokenReserveQty the external base token reserve qty prior to this transaction
     * @param _totalSupplyOfLiquidityTokens the total supply of our exchange's liquidity tokens (aka Ro)
     * @param _internalBalances internal balances struct from our exchange's internal accounting
     *
     *
     * @return quoteTokenQty qty of quote token the user must supply
     * @return liquidityTokenQty qty of liquidity tokens to be issued in exchange
     */
    function calculateAddQuoteTokenLiquidityQuantities(
        uint256 _quoteTokenQtyDesired,
        uint256 _baseTokenReserveQty,
        uint256 _totalSupplyOfLiquidityTokens,
        InternalBalances storage _internalBalances
    ) public returns (uint256 quoteTokenQty, uint256 liquidityTokenQty) {
        uint256 baseTokenDecay =
            _baseTokenReserveQty - _internalBalances.baseTokenReserveQty;

        // determine max amount of quote token that can be added to offset the current decay
        uint256 wInternalBaseTokenToQuoteTokenRatio =
            wDiv(
                _internalBalances.baseTokenReserveQty,
                _internalBalances.quoteTokenReserveQty
            );

        // alphaDecay / omega (A/B)
        uint256 maxQuoteTokenQty =
            wDiv(baseTokenDecay, wInternalBaseTokenToQuoteTokenRatio);

        if (_quoteTokenQtyDesired > maxQuoteTokenQty) {
            quoteTokenQty = maxQuoteTokenQty;
        } else {
            quoteTokenQty = _quoteTokenQtyDesired;
        }

        uint256 baseTokenQtyDecayChange =
            roundToNearest(
                (quoteTokenQty * wInternalBaseTokenToQuoteTokenRatio),
                WAD
            ) / WAD;

        require(
            baseTokenQtyDecayChange != 0,
            "MathLib: INSUFFICIENT_CHANGE_IN_DECAY"
        );
        //x += alphaDecayChange
        //y += deltaBeta
        _internalBalances.baseTokenReserveQty += baseTokenQtyDecayChange;
        _internalBalances.quoteTokenReserveQty += quoteTokenQty;

        // calculate the number of liquidity tokens to return to user using
        liquidityTokenQty = calculateLiquidityTokenQtyForSingleAssetEntryWithBaseTokenDecay(
            _baseTokenReserveQty,
            _totalSupplyOfLiquidityTokens,
            quoteTokenQty,
            _internalBalances.quoteTokenReserveQty,
            wInternalBaseTokenToQuoteTokenRatio
        );
        return (quoteTokenQty, liquidityTokenQty);
    }

    /**
     * @dev used to calculate the qty of base tokens required and liquidity tokens (deltaRo) to be issued
     * in order to add liquidity and remove base token decay.
     * @param _baseTokenQtyDesired the amount of base token the user wants to contribute
     * @param _baseTokenQtyMin the minimum amount of base token the user wants to contribute (allows for slippage)
     * @param _baseTokenReserveQty the external base token reserve qty prior to this transaction
     * @param _totalSupplyOfLiquidityTokens the total supply of our exchange's liquidity tokens (aka Ro)
     * @param _internalBalances internal balances struct from our exchange's internal accounting
     *
     * @return baseTokenQty qty of base token the user must supply
     * @return liquidityTokenQty qty of liquidity tokens to be issued in exchange
     */
    function calculateAddBaseTokenLiquidityQuantities(
        uint256 _baseTokenQtyDesired,
        uint256 _baseTokenQtyMin,
        uint256 _baseTokenReserveQty,
        uint256 _totalSupplyOfLiquidityTokens,
        InternalBalances memory _internalBalances
    ) public pure returns (uint256 baseTokenQty, uint256 liquidityTokenQty) {
        uint256 maxBaseTokenQty =
            _internalBalances.baseTokenReserveQty - _baseTokenReserveQty;
        require(
            _baseTokenQtyMin <= maxBaseTokenQty,
            "MathLib: INSUFFICIENT_DECAY"
        );

        if (_baseTokenQtyDesired > maxBaseTokenQty) {
            baseTokenQty = maxBaseTokenQty;
        } else {
            baseTokenQty = _baseTokenQtyDesired;
        }

        // determine the quote token qty decay change quoted on our current ratios
        uint256 wInternalQuoteToBaseTokenRatio =
            wDiv(
                _internalBalances.quoteTokenReserveQty,
                _internalBalances.baseTokenReserveQty
            );

        // NOTE we need this function to use the same
        // rounding scheme as wDiv in order to avoid a case
        // in which a user is trying to resolve decay in which
        // quoteTokenQtyDecayChange ends up being 0 and we are stuck in
        // a bad state.
        uint256 quoteTokenQtyDecayChange =
            roundToNearest(
                (baseTokenQty * wInternalQuoteToBaseTokenRatio),
                MathLib.WAD
            ) / WAD;

        require(
            quoteTokenQtyDecayChange != 0,
            "MathLib: INSUFFICIENT_CHANGE_IN_DECAY"
        );

        // we can now calculate the total amount of quote token decay
        uint256 quoteTokenDecay =
            (maxBaseTokenQty * wInternalQuoteToBaseTokenRatio) / WAD;

        // this may be redundant quoted on the above math, but will check to ensure the decay wasn't so small
        // that it was <1 and rounded down to 0 saving the caller some gas
        // also could fix a potential revert due to div by zero.
        require(quoteTokenDecay != 0, "MathLib: NO_QUOTE_DECAY");

        // we are not changing anything about our internal accounting here. We are simply adding tokens
        // to make our internal account "right"...or rather getting the external balances to match our internal
        // quoteTokenReserveQty += quoteTokenQtyDecayChange;
        // baseTokenReserveQty += baseTokenQty;

        // calculate the number of liquidity tokens to return to user using:
        liquidityTokenQty = calculateLiquidityTokenQtyForSingleAssetEntryWithQuoteTokenDecay(
            _baseTokenReserveQty,
            _totalSupplyOfLiquidityTokens,
            baseTokenQty,
            _internalBalances.baseTokenReserveQty
        );
    }

    /**
     * @dev used to calculate the qty of tokens a user will need to contribute and be issued in order to add liquidity
     * @param _baseTokenQtyDesired the amount of base token the user wants to contribute
     * @param _quoteTokenQtyDesired the amount of quote token the user wants to contribute
     * @param _baseTokenQtyMin the minimum amount of base token the user wants to contribute (allows for slippage)
     * @param _quoteTokenQtyMin the minimum amount of quote token the user wants to contribute (allows for slippage)
     * @param _baseTokenReserveQty the external base token reserve qty prior to this transaction
     * @param _totalSupplyOfLiquidityTokens the total supply of our exchange's liquidity tokens (aka Ro)
     * @param _internalBalances internal balances struct from our exchange's internal accounting
     *
     * @return tokenQtys qty of tokens needed to complete transaction
     */
    function calculateAddLiquidityQuantities(
        uint256 _baseTokenQtyDesired,
        uint256 _quoteTokenQtyDesired,
        uint256 _baseTokenQtyMin,
        uint256 _quoteTokenQtyMin,
        uint256 _baseTokenReserveQty,
        uint256 _totalSupplyOfLiquidityTokens,
        InternalBalances storage _internalBalances
    ) public returns (TokenQtys memory tokenQtys) {
        if (_totalSupplyOfLiquidityTokens != 0) {
            // we have outstanding liquidity tokens present and an existing price curve

            tokenQtys.liquidityTokenFeeQty = calculateLiquidityTokenFees(
                _totalSupplyOfLiquidityTokens,
                _internalBalances
            );

            // we need to take this amount (that will be minted) into account for below calculations
            _totalSupplyOfLiquidityTokens += tokenQtys.liquidityTokenFeeQty;

            // confirm that we have no beta or alpha decay present
            // if we do, we need to resolve that first
            if (
                isSufficientDecayPresent(
                    _baseTokenReserveQty,
                    _internalBalances
                )
            ) {
                // decay is present and needs to be dealt with by the caller.

                uint256 baseTokenQtyFromDecay;
                uint256 quoteTokenQtyFromDecay;
                uint256 liquidityTokenQtyFromDecay;

                if (
                    _baseTokenReserveQty > _internalBalances.baseTokenReserveQty
                ) {
                    // we have more base token than expected (base token decay) due to rebase up
                    // we first need to handle this situation by requiring this user
                    // to add quote tokens
                    (
                        quoteTokenQtyFromDecay,
                        liquidityTokenQtyFromDecay
                    ) = calculateAddQuoteTokenLiquidityQuantities(
                        _quoteTokenQtyDesired,
                        _baseTokenReserveQty,
                        _totalSupplyOfLiquidityTokens,
                        _internalBalances
                    );
                } else {
                    // we have less base token than expected (quote token decay) due to a rebase down
                    // we first need to handle this by adding base tokens to offset this.
                    (
                        baseTokenQtyFromDecay,
                        liquidityTokenQtyFromDecay
                    ) = calculateAddBaseTokenLiquidityQuantities(
                        _baseTokenQtyDesired,
                        0, // there is no minimum for this particular call since we may use base tokens later.
                        _baseTokenReserveQty,
                        _totalSupplyOfLiquidityTokens,
                        _internalBalances
                    );
                }

                if (
                    quoteTokenQtyFromDecay < _quoteTokenQtyDesired &&
                    baseTokenQtyFromDecay < _baseTokenQtyDesired
                ) {
                    // the user still has qty that they desire to contribute to the exchange for liquidity
                    (
                        tokenQtys.baseTokenQty,
                        tokenQtys.quoteTokenQty,
                        tokenQtys.liquidityTokenQty
                    ) = calculateAddTokenPairLiquidityQuantities(
                        _baseTokenQtyDesired - baseTokenQtyFromDecay, // safe from underflow quoted on above IF
                        _quoteTokenQtyDesired - quoteTokenQtyFromDecay, // safe from underflow quoted on above IF
                        0, // we will check minimums below
                        0, // we will check minimums below
                        _totalSupplyOfLiquidityTokens +
                            liquidityTokenQtyFromDecay,
                        _internalBalances // NOTE: these balances have already been updated when we did the decay math.
                    );
                }
                tokenQtys.baseTokenQty += baseTokenQtyFromDecay;
                tokenQtys.quoteTokenQty += quoteTokenQtyFromDecay;
                tokenQtys.liquidityTokenQty += liquidityTokenQtyFromDecay;

                require(
                    tokenQtys.baseTokenQty >= _baseTokenQtyMin,
                    "MathLib: INSUFFICIENT_BASE_QTY"
                );

                require(
                    tokenQtys.quoteTokenQty >= _quoteTokenQtyMin,
                    "MathLib: INSUFFICIENT_QUOTE_QTY"
                );
            } else {
                // the user is just doing a simple double asset entry / providing both base and quote.
                (
                    tokenQtys.baseTokenQty,
                    tokenQtys.quoteTokenQty,
                    tokenQtys.liquidityTokenQty
                ) = calculateAddTokenPairLiquidityQuantities(
                    _baseTokenQtyDesired,
                    _quoteTokenQtyDesired,
                    _baseTokenQtyMin,
                    _quoteTokenQtyMin,
                    _totalSupplyOfLiquidityTokens,
                    _internalBalances
                );
            }
        } else {
            // this user will set the initial pricing curve
            require(
                _baseTokenQtyDesired != 0,
                "MathLib: INSUFFICIENT_BASE_QTY_DESIRED"
            );
            require(
                _quoteTokenQtyDesired != 0,
                "MathLib: INSUFFICIENT_QUOTE_QTY_DESIRED"
            );

            tokenQtys.baseTokenQty = _baseTokenQtyDesired;
            tokenQtys.quoteTokenQty = _quoteTokenQtyDesired;
            tokenQtys.liquidityTokenQty = sqrt(
                _baseTokenQtyDesired * _quoteTokenQtyDesired
            );

            _internalBalances.baseTokenReserveQty += tokenQtys.baseTokenQty;
            _internalBalances.quoteTokenReserveQty += tokenQtys.quoteTokenQty;
        }
    }

    /**
     * @dev calculates the qty of base and quote tokens required and liquidity tokens (deltaRo) to be issued
     * in order to add liquidity when no decay is present.
     * @param _baseTokenQtyDesired the amount of base token the user wants to contribute
     * @param _quoteTokenQtyDesired the amount of quote token the user wants to contribute
     * @param _baseTokenQtyMin the minimum amount of base token the user wants to contribute (allows for slippage)
     * @param _quoteTokenQtyMin the minimum amount of quote token the user wants to contribute (allows for slippage)
     * @param _totalSupplyOfLiquidityTokens the total supply of our exchange's liquidity tokens (aka Ro)
     * @param _internalBalances internal balances struct from our exchange's internal accounting
     *
     * @return baseTokenQty qty of base token the user must supply
     * @return quoteTokenQty qty of quote token the user must supply
     * @return liquidityTokenQty qty of liquidity tokens to be issued in exchange
     */
    function calculateAddTokenPairLiquidityQuantities(
        uint256 _baseTokenQtyDesired,
        uint256 _quoteTokenQtyDesired,
        uint256 _baseTokenQtyMin,
        uint256 _quoteTokenQtyMin,
        uint256 _totalSupplyOfLiquidityTokens,
        InternalBalances storage _internalBalances
    )
        public
        returns (
            uint256 baseTokenQty,
            uint256 quoteTokenQty,
            uint256 liquidityTokenQty
        )
    {
        uint256 requiredQuoteTokenQty =
            calculateQty(
                _baseTokenQtyDesired,
                _internalBalances.baseTokenReserveQty,
                _internalBalances.quoteTokenReserveQty
            );

        if (requiredQuoteTokenQty <= _quoteTokenQtyDesired) {
            // user has to provide less than their desired amount
            require(
                requiredQuoteTokenQty >= _quoteTokenQtyMin,
                "MathLib: INSUFFICIENT_QUOTE_QTY"
            );
            baseTokenQty = _baseTokenQtyDesired;
            quoteTokenQty = requiredQuoteTokenQty;
        } else {
            // we need to check the opposite way.
            uint256 requiredBaseTokenQty =
                calculateQty(
                    _quoteTokenQtyDesired,
                    _internalBalances.quoteTokenReserveQty,
                    _internalBalances.baseTokenReserveQty
                );

            require(
                requiredBaseTokenQty >= _baseTokenQtyMin,
                "MathLib: INSUFFICIENT_BASE_QTY"
            );
            baseTokenQty = requiredBaseTokenQty;
            quoteTokenQty = _quoteTokenQtyDesired;
        }

        liquidityTokenQty = calculateLiquidityTokenQtyForDoubleAssetEntry(
            _totalSupplyOfLiquidityTokens,
            quoteTokenQty,
            _internalBalances.quoteTokenReserveQty
        );

        _internalBalances.baseTokenReserveQty += baseTokenQty;
        _internalBalances.quoteTokenReserveQty += quoteTokenQty;
    }

    /**
     * @dev calculates the qty of base tokens a user will receive for swapping their quote tokens (less fees)
     * @param _quoteTokenQty the amount of quote tokens the user wants to swap
     * @param _baseTokenQtyMin the minimum about of base tokens they are willing to receive in return (slippage)
     * @param _baseTokenReserveQty the external base token reserve qty prior to this transaction
     * @param _liquidityFeeInBasisPoints the current total liquidity fee represented as an integer of basis points
     * @param _internalBalances internal balances struct from our exchange's internal accounting
     *
     * @return baseTokenQty qty of base token the user will receive back
     */
    function calculateBaseTokenQty(
        uint256 _quoteTokenQty,
        uint256 _baseTokenQtyMin,
        uint256 _baseTokenReserveQty,
        uint256 _liquidityFeeInBasisPoints,
        InternalBalances storage _internalBalances
    ) public returns (uint256 baseTokenQty) {
        require(
            _baseTokenReserveQty != 0 &&
                _internalBalances.baseTokenReserveQty != 0,
            "MathLib: INSUFFICIENT_BASE_TOKEN_QTY"
        );

        // check to see if we have experience quote token decay / a rebase down event
        if (_baseTokenReserveQty < _internalBalances.baseTokenReserveQty) {
            // we have less reserves than our current price curve will expect, we need to adjust the curve
            uint256 wPricingRatio =
                wDiv(
                    _internalBalances.baseTokenReserveQty,
                    _internalBalances.quoteTokenReserveQty
                ); // omega

            uint256 impliedQuoteTokenQty =
                wDiv(_baseTokenReserveQty, wPricingRatio); // no need to divide by WAD, wPricingRatio is already a WAD.

            baseTokenQty = calculateQtyToReturnAfterFees(
                _quoteTokenQty,
                impliedQuoteTokenQty,
                _baseTokenReserveQty, // use the actual balance here since we adjusted the quote token to match ratio!
                _liquidityFeeInBasisPoints
            );
        } else {
            // we have the same or more reserves, no need to alter the curve.
            baseTokenQty = calculateQtyToReturnAfterFees(
                _quoteTokenQty,
                _internalBalances.quoteTokenReserveQty,
                _internalBalances.baseTokenReserveQty,
                _liquidityFeeInBasisPoints
            );
        }

        require(
            baseTokenQty >= _baseTokenQtyMin,
            "MathLib: INSUFFICIENT_BASE_TOKEN_QTY"
        );

        _internalBalances.baseTokenReserveQty -= baseTokenQty;
        _internalBalances.quoteTokenReserveQty += _quoteTokenQty;
    }

    /**
     * @dev calculates the qty of quote tokens a user will receive for swapping their base tokens (less fees)
     * @param _baseTokenQty the amount of bases tokens the user wants to swap
     * @param _quoteTokenQtyMin the minimum about of quote tokens they are willing to receive in return (slippage)
     * @param _liquidityFeeInBasisPoints the current total liquidity fee represented as an integer of basis points
     * @param _internalBalances internal balances struct from our exchange's internal accounting
     *
     * @return quoteTokenQty qty of quote token the user will receive back
     */
    function calculateQuoteTokenQty(
        uint256 _baseTokenQty,
        uint256 _quoteTokenQtyMin,
        uint256 _liquidityFeeInBasisPoints,
        InternalBalances storage _internalBalances
    ) public returns (uint256 quoteTokenQty) {
        require(
            _baseTokenQty != 0 && _quoteTokenQtyMin != 0,
            "MathLib: INSUFFICIENT_TOKEN_QTY"
        );

        quoteTokenQty = calculateQtyToReturnAfterFees(
            _baseTokenQty,
            _internalBalances.baseTokenReserveQty,
            _internalBalances.quoteTokenReserveQty,
            _liquidityFeeInBasisPoints
        );

        require(
            quoteTokenQty >= _quoteTokenQtyMin,
            "MathLib: INSUFFICIENT_QUOTE_TOKEN_QTY"
        );

        _internalBalances.baseTokenReserveQty += _baseTokenQty;
        _internalBalances.quoteTokenReserveQty -= quoteTokenQty;
    }

    /**
     * @dev calculates the qty of liquidity tokens that should be sent to the DAO due to the growth in K from trading.
     * The DAO takes 1/6 of the total fees (30BP total fee, 25 BP to lps and 5 BP to the DAO)
     * @param _totalSupplyOfLiquidityTokens the total supply of our exchange's liquidity tokens (aka Ro)
     * @param _internalBalances internal balances struct from our exchange's internal accounting
     *
     * @return liquidityTokenFeeQty qty of tokens to be minted to the fee address for the growth in K
     */
    function calculateLiquidityTokenFees(
        uint256 _totalSupplyOfLiquidityTokens,
        InternalBalances memory _internalBalances
    ) public pure returns (uint256 liquidityTokenFeeQty) {
        uint256 rootK =
            sqrt(
                _internalBalances.baseTokenReserveQty *
                    _internalBalances.quoteTokenReserveQty
            );
        uint256 rootKLast = sqrt(_internalBalances.kLast);
        if (rootK > rootKLast) {
            uint256 numerator =
                _totalSupplyOfLiquidityTokens * (rootK - rootKLast);
            uint256 denominator = (rootK * 5) + rootKLast;
            liquidityTokenFeeQty = numerator / denominator;
        }
    }
}

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
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

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

interface IExchangeFactory {
    function feeAddress() external view returns (address);
}


/**
 * @title Exchange contract for Elastic Swap representing a single ERC20 pair of tokens to be swapped.
 * @author Elastic DAO
 * @notice This contract provides all of the needed functionality for a liquidity provider to supply/withdraw ERC20
 * tokens and traders to swap tokens for one another.
 */
contract Exchange is ERC20, ReentrancyGuard {
    using MathLib for uint256;
    using SafeERC20 for IERC20;

    address public immutable baseToken; // address of ERC20 base token (elastic or fixed supply)
    address public immutable quoteToken; // address of ERC20 quote token (WETH or a stable coin w/ fixed supply)
    address public immutable exchangeFactoryAddress;

    uint256 public constant TOTAL_LIQUIDITY_FEE = 30; // fee provided to liquidity providers + DAO in basis points
    uint256 public constant MINIMUM_LIQUIDITY = 1e3;

    MathLib.InternalBalances public internalBalances;

    event AddLiquidity(
        address indexed liquidityProvider,
        uint256 baseTokenQtyAdded,
        uint256 quoteTokenQtyAdded
    );
    event RemoveLiquidity(
        address indexed liquidityProvider,
        uint256 baseTokenQtyRemoved,
        uint256 quoteTokenQtyRemoved
    );
    event Swap(
        address indexed sender,
        uint256 baseTokenQtyIn,
        uint256 quoteTokenQtyIn,
        uint256 baseTokenQtyOut,
        uint256 quoteTokenQtyOut
    );

    /**
     * @dev Called to check timestamps from users for expiration of their calls.
     */
    modifier isNotExpired(uint256 _expirationTimeStamp) {
        require(_expirationTimeStamp >= block.timestamp, "Exchange: EXPIRED");
        _;
    }

    /**
     * @notice called by the exchange factory to create a new erc20 token swap pair (do not call this directly!)
     * @param _name The human readable name of this pair (also used for the liquidity token name)
     * @param _symbol Shortened symbol for trading pair (also used for the liquidity token symbol)
     * @param _baseToken address of the ERC20 base token in the pair. This token can have a fixed or elastic supply
     * @param _quoteToken address of the ERC20 quote token in the pair. This token is assumed to have a fixed supply.
     * @param _exchangeFactoryAddress address of the exchange factory
     */
    constructor(
        string memory _name,
        string memory _symbol,
        address _baseToken,
        address _quoteToken,
        address _exchangeFactoryAddress
    ) ERC20(_name, _symbol) {
        baseToken = _baseToken;
        quoteToken = _quoteToken;
        exchangeFactoryAddress = _exchangeFactoryAddress;
    }

    /**
     * @notice primary entry point for a liquidity provider to add new liquidity (base and quote tokens) to the exchange
     * and receive liquidity tokens in return.
     * Requires approvals to be granted to this exchange for both base and quote tokens.
     * @param _baseTokenQtyDesired qty of baseTokens that you would like to add to the exchange
     * @param _quoteTokenQtyDesired qty of quoteTokens that you would like to add to the exchange
     * @param _baseTokenQtyMin minimum acceptable qty of baseTokens that will be added (or transaction will revert)
     * @param _quoteTokenQtyMin minimum acceptable qty of quoteTokens that will be added (or transaction will revert)
     * @param _liquidityTokenRecipient address for the exchange to issue the resulting liquidity tokens from
     * this transaction to
     * @param _expirationTimestamp timestamp that this transaction must occur before (or transaction will revert)
     */
    function addLiquidity(
        uint256 _baseTokenQtyDesired,
        uint256 _quoteTokenQtyDesired,
        uint256 _baseTokenQtyMin,
        uint256 _quoteTokenQtyMin,
        address _liquidityTokenRecipient,
        uint256 _expirationTimestamp
    ) external nonReentrant() isNotExpired(_expirationTimestamp) {
        uint256 totalSupply = this.totalSupply();
        MathLib.TokenQtys memory tokenQtys =
            MathLib.calculateAddLiquidityQuantities(
                _baseTokenQtyDesired,
                _quoteTokenQtyDesired,
                _baseTokenQtyMin,
                _quoteTokenQtyMin,
                IERC20(baseToken).balanceOf(address(this)),
                totalSupply,
                internalBalances
            );

        internalBalances.kLast =
            internalBalances.baseTokenReserveQty *
            internalBalances.quoteTokenReserveQty;

        if (tokenQtys.liquidityTokenFeeQty != 0) {
            // mint liquidity tokens to fee address for k growth.
            _mint(
                IExchangeFactory(exchangeFactoryAddress).feeAddress(),
                tokenQtys.liquidityTokenFeeQty
            );
        }

        bool isExchangeEmpty = totalSupply == 0;
        if (isExchangeEmpty) {
            // check if this the first LP provider, if so, we need to lock some minimum dust liquidity.
            require(
                tokenQtys.liquidityTokenQty > MINIMUM_LIQUIDITY,
                "Exchange: INITIAL_DEPOSIT_MIN"
            );
            unchecked {
                tokenQtys.liquidityTokenQty -= MINIMUM_LIQUIDITY;
            }
            _mint(address(this), MINIMUM_LIQUIDITY); // mint to this address, total supply will never be 0 again
        }

        _mint(_liquidityTokenRecipient, tokenQtys.liquidityTokenQty); // mint liquidity tokens to recipient

        if (tokenQtys.baseTokenQty != 0) {
            // transfer base tokens to Exchange
            IERC20(baseToken).safeTransferFrom(
                msg.sender,
                address(this),
                tokenQtys.baseTokenQty
            );

            if (isExchangeEmpty) {
                require(
                    IERC20(baseToken).balanceOf(address(this)) ==
                        tokenQtys.baseTokenQty,
                    "Exchange: FEE_ON_TRANSFER_NOT_SUPPORTED"
                );
            }
        }

        if (tokenQtys.quoteTokenQty != 0) {
            // transfer quote tokens to Exchange
            IERC20(quoteToken).safeTransferFrom(
                msg.sender,
                address(this),
                tokenQtys.quoteTokenQty
            );
        }

        emit AddLiquidity(
            msg.sender,
            tokenQtys.baseTokenQty,
            tokenQtys.quoteTokenQty
        );
    }

    /**
     * @notice called by a liquidity provider to redeem liquidity tokens from the exchange and receive back
     * base and quote tokens. Required approvals to be granted to this exchange for the liquidity token
     * @param _liquidityTokenQty qty of liquidity tokens that you would like to redeem
     * @param _baseTokenQtyMin minimum acceptable qty of base tokens to receive back (or transaction will revert)
     * @param _quoteTokenQtyMin minimum acceptable qty of quote tokens to receive back (or transaction will revert)
     * @param _tokenRecipient address for the exchange to issue the resulting base and
     * quote tokens from this transaction to
     * @param _expirationTimestamp timestamp that this transaction must occur before (or transaction will revert)
     */
    function removeLiquidity(
        uint256 _liquidityTokenQty,
        uint256 _baseTokenQtyMin,
        uint256 _quoteTokenQtyMin,
        address _tokenRecipient,
        uint256 _expirationTimestamp
    ) external nonReentrant() isNotExpired(_expirationTimestamp) {
        require(this.totalSupply() != 0, "Exchange: INSUFFICIENT_LIQUIDITY");
        require(
            _baseTokenQtyMin != 0 && _quoteTokenQtyMin != 0,
            "Exchange: MINS_MUST_BE_GREATER_THAN_ZERO"
        );

        uint256 baseTokenReserveQty =
            IERC20(baseToken).balanceOf(address(this));
        uint256 quoteTokenReserveQty =
            IERC20(quoteToken).balanceOf(address(this));

        uint256 totalSupplyOfLiquidityTokens = this.totalSupply();
        // calculate any DAO fees here.
        uint256 liquidityTokenFeeQty =
            MathLib.calculateLiquidityTokenFees(
                totalSupplyOfLiquidityTokens,
                internalBalances
            );

        // we need to factor this quantity in to any total supply before redemption
        totalSupplyOfLiquidityTokens += liquidityTokenFeeQty;

        uint256 baseTokenQtyToReturn =
            (_liquidityTokenQty * baseTokenReserveQty) /
                totalSupplyOfLiquidityTokens;
        uint256 quoteTokenQtyToReturn =
            (_liquidityTokenQty * quoteTokenReserveQty) /
                totalSupplyOfLiquidityTokens;

        require(
            baseTokenQtyToReturn >= _baseTokenQtyMin,
            "Exchange: INSUFFICIENT_BASE_QTY"
        );

        require(
            quoteTokenQtyToReturn >= _quoteTokenQtyMin,
            "Exchange: INSUFFICIENT_QUOTE_QTY"
        );

        // this ensures that we are removing the equivalent amount of decay
        // when this person exits.
        {
            //scoping to avoid stack too deep errors
            uint256 internalBaseTokenReserveQty =
                internalBalances.baseTokenReserveQty;
            uint256 baseTokenQtyToRemoveFromInternalAccounting =
                (_liquidityTokenQty * internalBaseTokenReserveQty) /
                    totalSupplyOfLiquidityTokens;

            internalBalances.baseTokenReserveQty = internalBaseTokenReserveQty =
                internalBaseTokenReserveQty -
                baseTokenQtyToRemoveFromInternalAccounting;

            // We should ensure no possible overflow here.
            uint256 internalQuoteTokenReserveQty =
                internalBalances.quoteTokenReserveQty;
            if (quoteTokenQtyToReturn > internalQuoteTokenReserveQty) {
                internalBalances
                    .quoteTokenReserveQty = internalQuoteTokenReserveQty = 0;
            } else {
                internalBalances
                    .quoteTokenReserveQty = internalQuoteTokenReserveQty =
                    internalQuoteTokenReserveQty -
                    quoteTokenQtyToReturn;
            }

            internalBalances.kLast =
                internalBaseTokenReserveQty *
                internalQuoteTokenReserveQty;
        }

        if (liquidityTokenFeeQty != 0) {
            _mint(
                IExchangeFactory(exchangeFactoryAddress).feeAddress(),
                liquidityTokenFeeQty
            );
        }

        _burn(msg.sender, _liquidityTokenQty);
        IERC20(baseToken).safeTransfer(_tokenRecipient, baseTokenQtyToReturn);
        IERC20(quoteToken).safeTransfer(_tokenRecipient, quoteTokenQtyToReturn);
        emit RemoveLiquidity(
            msg.sender,
            baseTokenQtyToReturn,
            quoteTokenQtyToReturn
        );
    }

    /**
     * @notice swaps base tokens for a minimum amount of quote tokens.  Fees are included in all transactions.
     * The exchange must be granted approvals for the base token by the caller.
     * @param _baseTokenQty qty of base tokens to swap
     * @param _minQuoteTokenQty minimum qty of quote tokens to receive in exchange for
     * your base tokens (or the transaction will revert)
     * @param _expirationTimestamp timestamp that this transaction must occur before (or transaction will revert)
     */
    function swapBaseTokenForQuoteToken(
        uint256 _baseTokenQty,
        uint256 _minQuoteTokenQty,
        uint256 _expirationTimestamp
    ) external nonReentrant() isNotExpired(_expirationTimestamp) {
        require(
            _baseTokenQty != 0 && _minQuoteTokenQty != 0,
            "Exchange: INSUFFICIENT_TOKEN_QTY"
        );

        uint256 quoteTokenQty =
            MathLib.calculateQuoteTokenQty(
                _baseTokenQty,
                _minQuoteTokenQty,
                TOTAL_LIQUIDITY_FEE,
                internalBalances
            );

        IERC20(baseToken).safeTransferFrom(
            msg.sender,
            address(this),
            _baseTokenQty
        );

        IERC20(quoteToken).safeTransfer(msg.sender, quoteTokenQty);
        emit Swap(msg.sender, _baseTokenQty, 0, 0, quoteTokenQty);
    }

    /**
     * @notice swaps quote tokens for a minimum amount of base tokens.  Fees are included in all transactions.
     * The exchange must be granted approvals for the quote token by the caller.
     * @param _quoteTokenQty qty of quote tokens to swap
     * @param _minBaseTokenQty minimum qty of base tokens to receive in exchange for
     * your quote tokens (or the transaction will revert)
     * @param _expirationTimestamp timestamp that this transaction must occur before (or transaction will revert)
     */
    function swapQuoteTokenForBaseToken(
        uint256 _quoteTokenQty,
        uint256 _minBaseTokenQty,
        uint256 _expirationTimestamp
    ) external nonReentrant() isNotExpired(_expirationTimestamp) {
        require(
            _quoteTokenQty != 0 && _minBaseTokenQty != 0,
            "Exchange: INSUFFICIENT_TOKEN_QTY"
        );

        uint256 baseTokenQty =
            MathLib.calculateBaseTokenQty(
                _quoteTokenQty,
                _minBaseTokenQty,
                IERC20(baseToken).balanceOf(address(this)),
                TOTAL_LIQUIDITY_FEE,
                internalBalances
            );

        IERC20(quoteToken).safeTransferFrom(
            msg.sender,
            address(this),
            _quoteTokenQty
        );

        IERC20(baseToken).safeTransfer(msg.sender, baseTokenQty);
        emit Swap(msg.sender, 0, _quoteTokenQty, baseTokenQty, 0);
    }
}

/// @title MerklePools
/// @notice A contract which allows users to stake to farm tokens that are "realized" once
/// profits enter the system and can be claimed via a merkle proof.
contract MerklePools is MerklePoolsStorage, ReentrancyGuardUpgradeable {
    using FixedPointMath for FixedPointMath.FixedDecimal;
    using MerklePool for MerklePool.Data;
    using MerklePool for MerklePool.List;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using MerkleStake for MerkleStake.Data;

    event PendingGovernanceUpdated(address pendingGovernance);

    event GovernanceUpdated(address governance);

    event ForfeitAddressUpdated(address governance);

    event RewardRateUpdated(uint256 rewardRate);

    event PoolRewardWeightUpdated(uint256 indexed poolId, uint256 rewardWeight);

    event PoolCreated(uint256 indexed poolId, address indexed token);

    event TokensDeposited(
        address indexed user,
        uint256 indexed poolId,
        uint256 amount
    );

    event TokensWithdrawn(
        address indexed user,
        uint256 indexed poolId,
        uint256 amount
    );

    event TokensClaimed(
        address indexed user,
        uint256 index,
        uint256 indexed poolId,
        uint256 lpTokenAmountClaimed,
        uint256 ticTokenAmountClaimed
    );

    event MerkleRootUpdated(bytes32 merkleRoot);
    event LPTokensGenerated(
        uint256 lpAmountCreated,
        uint256 ticConsumed,
        uint256 quoteTokenConsumed
    );

    constructor() {}

    function initialize(
        IMintableERC20 _ticToken,
        address _quoteToken,
        address _elasticLPToken,
        address _governance,
        address _forfeitAddress
    ) external initializer {
        require(_governance != address(0), "MerklePools: INVALID_ADDRESS");
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        ticToken = _ticToken;
        governance = _governance;
        elasticLPToken = _elasticLPToken;
        quoteToken = _quoteToken;
        forfeitAddress = _forfeitAddress;

        if (address(_ticToken) != address(0)) {
            // grant approval to exchange so we can mint
            _ticToken.approve(address(_elasticLPToken), type(uint256).max);
        }
        if (_elasticLPToken != address(0)) {
            IERC20Upgradeable(_quoteToken).approve(
                address(_elasticLPToken),
                type(uint256).max
            );
        }
    }

    /**
     * @dev A modifier which reverts when the caller is not the governance.
     */
    modifier onlyGovernance() {
        require(msg.sender == governance, "MerklePools: ONLY_GOVERNANCE");
        _;
    }

    /**
     * @dev Sets the governance. This function can only called by the current governance.
     * @param _pendingGovernance the new pending governance.
     */
    function setPendingGovernance(address _pendingGovernance)
        external
        onlyGovernance
    {
        require(
            _pendingGovernance != address(0),
            "MerklePools: INVALID_ADDRESS"
        );
        pendingGovernance = _pendingGovernance;

        emit PendingGovernanceUpdated(_pendingGovernance);
    }

    function acceptGovernance() external {
        require(msg.sender == pendingGovernance, "MerklePools: ONLY_PENDING");

        address pendingGovernance_ = msg.sender;
        governance = pendingGovernance_;

        emit GovernanceUpdated(pendingGovernance_);
    }

    /**
     * @dev Sets the distribution reward rate. This will update all of the pools.
     * @param _rewardRate The number of tokens to distribute per second.
     */
    function setRewardRate(uint256 _rewardRate) external onlyGovernance {
        _updatePools();

        poolContext.rewardRate = _rewardRate;

        emit RewardRateUpdated(_rewardRate);
    }

    /**
     * @dev Sets the address rewards are forfeited to when a staker exits prior to realizing
     * their rewards.
     * @param _forfeitAddress address to set.
     */
    function setForfeitAddress(address _forfeitAddress)
        external
        onlyGovernance
    {
        require(_forfeitAddress != forfeitAddress, "MerklePools: SAME_ADDRESS");
        forfeitAddress = _forfeitAddress;
        emit ForfeitAddressUpdated(_forfeitAddress);
    }

    /**
     * Allows the governance to set the tic token address in the case
     * that it wasn't set during the initialize (due to bridge partner)
     * @param _ticToken address
     */
    function setTicTokenAddress(IMintableERC20 _ticToken)
        external
        onlyGovernance
    {
        require(
            address(ticToken) == address(0),
            "MerklePools: TIC_ALREADY_SET"
        );
        require(
            address(_ticToken) != address(0),
            "MerklePools: INVALID_ADDRESS"
        );
        require(elasticLPToken != address(0), "MerklePools: ELP_NOT_SET");

        ticToken = _ticToken;
        _ticToken.approve(address(elasticLPToken), type(uint256).max);
    }

    /**
     * Allows the governance to set the Elastic LP token address in the case
     * that it wasn't set during the initialize due to waiting on the ELP to be
     * created once the token is bridged
     * @param _elasticLPToken address
     */
    function setElasticLPTokenAddress(address _elasticLPToken)
        external
        onlyGovernance
    {
        require(elasticLPToken == address(0), "MerklePools: ELP_ALREADY_SET");
        require(_elasticLPToken != address(0), "MerklePools: INVALID_ADDRESS");

        elasticLPToken = _elasticLPToken;
        IERC20Upgradeable(quoteToken).approve(
            address(_elasticLPToken),
            type(uint256).max
        );
    }

    /**
     * @dev Creates a new pool. The created pool will need to have its reward weight
     * initialized before it begins generating rewards.
     * @param _token The token the pool will accept for staking.
     * @return the identifier for the newly created pool.
     */
    function createPool(address _token)
        external
        onlyGovernance
        returns (uint256)
    {
        require(tokenPoolIds[_token] == 0, "MerklePools: ALREADY_CREATED");

        uint256 poolId = pools.length();

        pools.push(
            MerklePool.Data({
                token: _token,
                totalDeposited: 0,
                totalUnclaimedTIC: 0,
                totalUnclaimedTICInLP: 0,
                rewardWeight: 0,
                accumulatedRewardWeight: FixedPointMath.FixedDecimal(0),
                lastUpdatedBlockTimestamp: block.timestamp
            })
        );

        tokenPoolIds[_token] = poolId + 1;

        emit PoolCreated(poolId, _token);

        return poolId;
    }

    /**
     * @dev Sets the reward weights of all of the pools.
     * @param _rewardWeights The reward weights of all of the pools.
     */
    function setRewardWeights(uint256[] calldata _rewardWeights)
        external
        onlyGovernance
    {
        uint256 poolsLength = pools.length();
        require(
            _rewardWeights.length == poolsLength,
            "MerklePools: LENGTH_MISMATCH"
        );

        _updatePools();
        uint256 totalRewardWeight_ = poolContext.totalRewardWeight;
        for (uint256 _poolId = 0; _poolId < poolsLength; _poolId++) {
            MerklePool.Data storage _pool = pools.get(_poolId);

            uint256 _currentRewardWeight = _pool.rewardWeight;
            if (_currentRewardWeight == _rewardWeights[_poolId]) {
                continue;
            }

            totalRewardWeight_ =
                totalRewardWeight_ -
                _currentRewardWeight +
                _rewardWeights[_poolId];
            _pool.rewardWeight = _rewardWeights[_poolId];

            emit PoolRewardWeightUpdated(_poolId, _rewardWeights[_poolId]);
        }
        poolContext.totalRewardWeight = totalRewardWeight_;
    }

    /**
     * @dev Stakes tokens into a pool.
     * @param _poolId        the pool to deposit tokens into.
     * @param _depositAmount the amount of tokens to deposit.
     */
    function deposit(uint256 _poolId, uint256 _depositAmount)
        external
        nonReentrant
    {
        require(msg.sender != forfeitAddress, "MerklePools: UNUSABLE_ADDRESS");
        MerklePool.Data storage pool = pools.get(_poolId);
        pool.update(poolContext);

        MerkleStake.Data storage stake = stakes[msg.sender][_poolId];
        stake.update(pool, poolContext);

        pool.totalDeposited = pool.totalDeposited + _depositAmount;
        stake.totalDeposited = stake.totalDeposited + _depositAmount;

        IERC20Upgradeable(pool.token).safeTransferFrom(
            msg.sender,
            address(this),
            _depositAmount
        );
        emit TokensDeposited(msg.sender, _poolId, _depositAmount);
    }

    /**
     * @dev exits and returns all staked tokens from a pool and forfeit's any outstanding rewards
     * @param _poolId the pool to exit from.
     */
    function exit(uint256 _poolId) external nonReentrant {
        require(msg.sender != forfeitAddress, "MerklePools: UNUSABLE_ADDRESS");
        MerklePool.Data storage pool = pools.get(_poolId);
        pool.update(poolContext);

        MerkleStake.Data storage stake = stakes[msg.sender][_poolId];
        stake.update(pool, poolContext);

        uint256 withdrawAmount = stake.totalDeposited;
        pool.totalDeposited = pool.totalDeposited - withdrawAmount;
        stake.totalDeposited = 0;

        // unclaimed rewards are transferred to the forfeit address
        MerkleStake.Data storage forfeitStake = stakes[forfeitAddress][_poolId];
        forfeitStake.update(pool, poolContext);

        forfeitStake.totalUnrealized += stake.totalUnrealized;

        // we need to zero our their total unrealized and also ensure that they are unable to just
        // re-enter and then claim using a stale merkle proof as their unrealized increments again
        // over time.  By adding their unrealized to their totalRealized, we ensure that any
        // existing merkle claim is now un-claimable by them until we generate a new merkle claim
        // that accounts for these values.  This means that the sum of all stakes.totalRealizedTIC
        // is not accurate in terms of tic claimed
        // and that we also need to check in the UI to not end up with negative
        // claimable values.  The off chain accounting needs to consider this as well if a
        // user does re-enter wit the same address in the future.
        stake.totalRealizedTIC += stake.totalUnrealized;
        stake.totalUnrealized = 0;

        IERC20Upgradeable(pool.token).safeTransfer(msg.sender, withdrawAmount);
        emit TokensWithdrawn(msg.sender, _poolId, withdrawAmount);
    }

    /**
     * @notice Allows a caller to generate LP tokens to distribute to stakers.  The quote token
     * is taken from the caller and paired with freshly minted TIC token to create new LP tokens.
     * @param _poolId id of the pool these LP Tokens are associated with.
     * @param _ticTokenQty qty of ticTokens that you would like to add
     * @param _quoteTokenQty qty of quoteTokens that you would like to add (USDC)
     * @param _ticTokenQtyMin minimum acceptable qty of ticToken that will be added (or transaction will revert)
     * @param _quoteTokenQtyMin minimum acceptable qty of quoteTokens that will be added (or transaction will revert)
     * @param _expirationTimestamp timestamp that this transaction must occur before (or transaction will revert)
     */
    function generateLPTokens(
        uint256 _poolId,
        uint256 _ticTokenQty,
        uint256 _quoteTokenQty,
        uint256 _ticTokenQtyMin,
        uint256 _quoteTokenQtyMin,
        uint256 _expirationTimestamp
    ) external virtual onlyGovernance {
        require(address(ticToken) != address(0), "MerklePools: TIC_NOT_SET");
        require(elasticLPToken != address(0), "MerklePools: ELP_NOT_SET");

        MerklePool.Data storage _pool = pools.get(_poolId);
        _pool.update(poolContext); // update pool first!
        uint256 maxMintAmount =
            _pool.totalUnclaimedTIC - _pool.totalUnclaimedTICInLP;
        require(maxMintAmount >= _ticTokenQty, "MerklePools: NSF_UNCLAIMED");

        // check to make sure we don't have some "Excess" tic we can use.
        uint256 ticBalanceToBeMinted = _ticTokenQty - excessTICFromSlippage;

        ticToken.mint(address(this), ticBalanceToBeMinted);
        IERC20Upgradeable(quoteToken).safeTransferFrom(
            msg.sender,
            address(this),
            _quoteTokenQty
        );

        uint256 lpBalanceBefore =
            IERC20Upgradeable(elasticLPToken).balanceOf(address(this));
        uint256 ticBalanceBefore = ticToken.balanceOf(address(this));
        uint256 quoteTokenBalanceBefore =
            IERC20Upgradeable(quoteToken).balanceOf(address(this));

        Exchange(address(elasticLPToken)).addLiquidity(
            _ticTokenQty,
            _quoteTokenQty,
            _ticTokenQtyMin,
            _quoteTokenQtyMin,
            address(this),
            _expirationTimestamp
        );

        uint256 lpBalanceCreated =
            IERC20Upgradeable(elasticLPToken).balanceOf(address(this)) -
                lpBalanceBefore;
        require(lpBalanceCreated != 0, "MerklePools: NO_LP_CREATED");

        uint256 ticBalanceConsumed =
            ticBalanceBefore - ticToken.balanceOf(address(this));
        excessTICFromSlippage = _ticTokenQty - ticBalanceConsumed; //save for next time

        _pool.totalUnclaimedTICInLP += ticBalanceConsumed;
        uint256 quoteTokenConsumed =
            quoteTokenBalanceBefore -
                IERC20Upgradeable(quoteToken).balanceOf(address(this));
        if (quoteTokenConsumed < _quoteTokenQty) {
            // refund the rest to the caller
            IERC20Upgradeable(quoteToken).safeTransfer(
                msg.sender,
                _quoteTokenQty - quoteTokenConsumed
            );
        }

        emit LPTokensGenerated(
            lpBalanceCreated,
            ticBalanceConsumed,
            quoteTokenConsumed
        );
    }

    /**
     * @notice Allows a new merkle root to be set by the contracts owner (the DAO)
     * @param _merkleRoot the merkle root to be set
     */
    function setMerkleRoot(bytes32 _merkleRoot) public onlyGovernance {
        require(merkleRoot != _merkleRoot, "MerklePools: DUPLICATE_ROOT");
        require(address(ticToken) != address(0), "MerklePools: TIC_NOT_SET");
        require(elasticLPToken != address(0), "MerklePools: ELP_NOT_SET");
        isClaimsEnabled = true;
        merkleRoot = _merkleRoot;
        emit MerkleRootUpdated(_merkleRoot);
    }

    /**
     * @notice Allows for a staker to claim LP tokens based on the merkle proof provided.
     * @param _index the index of the merkle claim
     * @param _poolId the pool id these rewards are associated with.
     * @param _totalLPTokenAmount the total LP token amount in the tree
     * @param _totalTICAmount the total TIC amount to be consumed in the tree
     * @param _merkleProof bytes32[] proof for the claim
     */
    function claim(
        uint256 _index,
        uint256 _poolId,
        uint256 _totalLPTokenAmount,
        uint256 _totalTICAmount,
        bytes32[] calldata _merkleProof
    ) external nonReentrant {
        require(isClaimsEnabled, "MerklePools: CLAIMS_DISABLED");

        // Verify the merkle proof.
        bytes32 node =
            keccak256(
                abi.encodePacked(
                    _index,
                    msg.sender,
                    _poolId,
                    _totalLPTokenAmount,
                    _totalTICAmount
                )
            );

        require(
            MerkleProofUpgradeable.verify(_merkleProof, merkleRoot, node),
            "MerklePools: INVALID_PROOF"
        );

        MerkleStake.Data storage stake = stakes[msg.sender][_poolId];
        uint256 alreadyClaimedLPAmount = stake.totalRealizedLP;
        uint256 alreadyClaimedTICAmount = stake.totalRealizedTIC;

        require(
            _totalLPTokenAmount > alreadyClaimedLPAmount &&
                _totalTICAmount > alreadyClaimedTICAmount,
            "MerklePools: INVALID_CLAIM_AMOUNT"
        );

        MerklePool.Data storage pool = pools.get(_poolId);
        pool.update(poolContext);
        stake.update(pool, poolContext);

        // determine the amounts of the new claim
        uint256 lpTokenAmountToBeClaimed;
        uint256 ticTokenAmountToBeClaimed;

        unchecked {
            lpTokenAmountToBeClaimed =
                _totalLPTokenAmount -
                alreadyClaimedLPAmount;
            ticTokenAmountToBeClaimed =
                _totalTICAmount -
                alreadyClaimedTICAmount;
        }

        require(
            ticTokenAmountToBeClaimed <= stake.totalUnrealized,
            "MerklePools: INVALID_UNCLAIMED_AMOUNT"
        );

        stake.totalRealizedLP = _totalLPTokenAmount;
        stake.totalRealizedTIC = _totalTICAmount;

        unchecked {
            stake.totalUnrealized -= ticTokenAmountToBeClaimed;
        }
        pool.totalUnclaimedTIC -= ticTokenAmountToBeClaimed;
        pool.totalUnclaimedTICInLP -= ticTokenAmountToBeClaimed;

        IERC20Upgradeable(elasticLPToken).safeTransfer(
            msg.sender,
            lpTokenAmountToBeClaimed
        );
        emit TokensClaimed(
            msg.sender,
            _index,
            _poolId,
            lpTokenAmountToBeClaimed,
            ticTokenAmountToBeClaimed
        );
    }

    /**
     * @dev Gets the rate at which tokens are minted to stakers for all pools.
     * @return the reward rate.
     */
    function rewardRate() external view returns (uint256) {
        return poolContext.rewardRate;
    }

    /**
     * @dev Gets the total reward weight between all the pools.
     * @return the total reward weight.
     */
    function totalRewardWeight() external view returns (uint256) {
        return poolContext.totalRewardWeight;
    }

    /**
     * @dev Gets the number of pools that exist.
     * @return the pool count.
     */
    function poolCount() external view returns (uint256) {
        return pools.length();
    }

    /**
     * @dev Gets the token a pool accepts.
     * @param _poolId the identifier of the pool.
     * @return the token.
     */
    function getPoolToken(uint256 _poolId) external view returns (address) {
        MerklePool.Data storage pool = pools.get(_poolId);
        return pool.token;
    }

    /**
     * @dev Gets the pool data struct
     * @param _poolId the identifier of the pool.
     * @return the Pool.Data (memory, not storage!).
     */
    function getPool(uint256 _poolId)
        external
        view
        returns (MerklePool.Data memory)
    {
        return pools.get(_poolId);
    }

    /**
     * @dev Gets the total amount of funds staked in a pool.
     * @param _poolId the identifier of the pool.
     * @return the total amount of staked or deposited tokens.
     */
    function getPoolTotalDeposited(uint256 _poolId)
        external
        view
        returns (uint256)
    {
        MerklePool.Data storage pool = pools.get(_poolId);
        return pool.totalDeposited;
    }

    /**
     * @dev Gets the total amount of token unclaimed from a pool
     * @param _poolId the identifier of the pool.
     * @return the total amount of unclaimed / un-minted tokens from a pool
     */
    function getPoolTotalUnclaimed(uint256 _poolId)
        external
        view
        returns (uint256)
    {
        MerklePool.Data storage pool = pools.get(_poolId);
        return pool.getUpdatedTotalUnclaimed(poolContext);
    }

    /**
     * @dev Gets the total amount of tokens unclaimed from a pool that are not yet "realized" in
     * the form of LP tokens
     * @param _poolId the identifier of the pool.
     * @return the total amount of unclaimed and un-minted tokens from a pool that are not in LP tokens
     */
    function getPoolTotalUnclaimedNotInLP(uint256 _poolId)
        external
        view
        returns (uint256)
    {
        MerklePool.Data storage pool = pools.get(_poolId);
        return
            pool.getUpdatedTotalUnclaimed(poolContext) -
            pool.totalUnclaimedTICInLP;
    }

    /**
     * @dev Gets the reward weight of a pool which determines
     * how much of the total rewards it receives per second.
     * @param _poolId the identifier of the pool.
     * @return the pool reward weight.
     */
    function getPoolRewardWeight(uint256 _poolId)
        external
        view
        returns (uint256)
    {
        MerklePool.Data storage pool = pools.get(_poolId);
        return pool.rewardWeight;
    }

    /**
     * @dev Gets the amount of tokens per second being distributed to stakers for a pool.
     * @param _poolId the identifier of the pool.
     * @return the pool reward rate.
     */
    function getPoolRewardRate(uint256 _poolId)
        external
        view
        returns (uint256)
    {
        MerklePool.Data storage pool = pools.get(_poolId);
        return pool.getRewardRate(poolContext);
    }

    /**
     * @dev Gets the number of tokens a user has staked into a pool.
     * @param _account The account to query.
     * @param _poolId  the identifier of the pool.
     * @return the amount of deposited tokens.
     */
    function getStakeTotalDeposited(address _account, uint256 _poolId)
        external
        view
        returns (uint256)
    {
        MerkleStake.Data storage stake = stakes[_account][_poolId];
        return stake.totalDeposited;
    }

    /**
     * @dev Gets the number of unclaimed reward tokens a user can claim from a pool.
     * @param _account The account to get the unclaimed balance of.
     * @param _poolId  The pool to check for unclaimed rewards.
     * @return the amount of unclaimed reward tokens a user has in a pool.
     */
    function getStakeTotalUnclaimed(address _account, uint256 _poolId)
        external
        view
        returns (uint256)
    {
        MerkleStake.Data storage stake = stakes[_account][_poolId];
        return stake.getUpdatedTotalUnclaimed(pools.get(_poolId), poolContext);
    }

    /**
     * @dev Updates all of the pools.
     */
    function _updatePools() internal {
        uint256 poolsLength = pools.length();
        for (uint256 poolId = 0; poolId < poolsLength; poolId++) {
            MerklePool.Data storage pool = pools.get(poolId);
            pool.update(poolContext);
        }
    }
}

/**
 * MerklePoolsForeign allows for us to enable our MerklePools staking on a chain that has bridged
 * TIC.  Instead of minting during the `generateLPTokens` call, TIC is transferred in from
 * the caller (onlyGovernance) to be used to mint LP tokens.
 */
contract MerklePoolsForeign is MerklePools {
    using MerklePool for MerklePool.List;
    using MerklePool for MerklePool.Data;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /**
     * @notice Allows a caller to generate LP tokens to distribute to stakers.  The quote token
     * is taken from the caller and paired with freshly minted TIC token to create new LP tokens.
     * @param _poolId id of the pool these LP Tokens are associated with.
     * @param _ticTokenQty qty of ticTokens that you would like to add
     * @param _quoteTokenQty qty of quoteTokens that you would like to add (USDC)
     * @param _ticTokenQtyMin minimum acceptable qty of ticToken that will be added (or transaction will revert)
     * @param _quoteTokenQtyMin minimum acceptable qty of quoteTokens that will be added (or transaction will revert)
     * @param _expirationTimestamp timestamp that this transaction must occur before (or transaction will revert)
     */
    function generateLPTokens(
        uint256 _poolId,
        uint256 _ticTokenQty,
        uint256 _quoteTokenQty,
        uint256 _ticTokenQtyMin,
        uint256 _quoteTokenQtyMin,
        uint256 _expirationTimestamp
    ) external override onlyGovernance {
        require(address(ticToken) != address(0), "MerklePools: TIC_NOT_SET");
        require(elasticLPToken != address(0), "MerklePools: ELP_NOT_SET");

        MerklePool.Data storage _pool = pools.get(_poolId);
        _pool.update(poolContext); // update pool first!
        uint256 maxMintAmount =
            _pool.totalUnclaimedTIC - _pool.totalUnclaimedTICInLP;
        require(maxMintAmount >= _ticTokenQty, "MerklePools: NSF_UNCLAIMED");

        ticToken.transferFrom(msg.sender, address(this), _ticTokenQty);
        IERC20Upgradeable(quoteToken).safeTransferFrom(
            msg.sender,
            address(this),
            _quoteTokenQty
        );

        uint256 lpBalanceBefore =
            IERC20Upgradeable(elasticLPToken).balanceOf(address(this));
        uint256 ticBalanceBefore = ticToken.balanceOf(address(this));
        uint256 quoteTokenBalanceBefore =
            IERC20Upgradeable(quoteToken).balanceOf(address(this));

        Exchange(address(elasticLPToken)).addLiquidity(
            _ticTokenQty,
            _quoteTokenQty,
            _ticTokenQtyMin,
            _quoteTokenQtyMin,
            address(this),
            _expirationTimestamp
        );

        uint256 lpBalanceCreated =
            IERC20Upgradeable(elasticLPToken).balanceOf(address(this)) -
                lpBalanceBefore;
        require(lpBalanceCreated != 0, "MerklePools: NO_LP_CREATED");

        uint256 ticBalanceConsumed =
            ticBalanceBefore - ticToken.balanceOf(address(this));
        _pool.totalUnclaimedTICInLP += ticBalanceConsumed;

        if (ticBalanceConsumed < _ticTokenQty) {
            // refund the rest to caller.
            ticToken.transfer(msg.sender, _ticTokenQty - ticBalanceConsumed);
        }

        uint256 quoteTokenConsumed =
            quoteTokenBalanceBefore -
                IERC20Upgradeable(quoteToken).balanceOf(address(this));

        if (quoteTokenConsumed < _quoteTokenQty) {
            // refund the rest to the caller
            IERC20Upgradeable(quoteToken).safeTransfer(
                msg.sender,
                _quoteTokenQty - quoteTokenConsumed
            );
        }

        emit LPTokensGenerated(
            lpBalanceCreated,
            ticBalanceConsumed,
            quoteTokenConsumed
        );
    }
}