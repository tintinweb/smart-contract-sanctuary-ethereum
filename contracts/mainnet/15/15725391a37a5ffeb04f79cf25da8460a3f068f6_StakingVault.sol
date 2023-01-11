/**
 *Submitted for verification at Etherscan.io on 2023-01-11
*/

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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

interface IERC20 {
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
}

interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

interface IStakingVault {
    /// @notice Represents the stake a user has in the vault.
    struct Stake {
        uint128 amount;
        uint64 lockExpiry;
    }

    // Events.

    /// @notice Emitted every time a user's stake changes.
    event StakeChanged(
        address indexed account,
        uint128 amount,
        uint64 lockExpiry
    );

    /// @notice Emitted when a user boosts either the value or the lock of their stake.
    event BoostHFTStake(
        address indexed account,
        uint128 amount,
        uint64 daysStaked
    );

    /// @notice Emitted when HFT is withdrawn.
    event WithdrawHFT(
        address indexed account,
        uint128 amountWithdrawn,
        uint128 amountRestaked
    );

    /// @notice Emitted when a stake is transferred to a different vault.
    event TransferHFTStake(
        address indexed account,
        address targetVault,
        uint128 amount
    );

    /// @notice Emitted when the max number of staking days is updated.
    event UpdateMaxDaysToStake(uint16 maxDaysToStake);

    /// @notice Emitted when a source vault authorization status changes.
    event UpdateSourceVaultAuthorization(address vault, bool isAuthorized);

    /// @notice Emitted when a target vault authorization status changes.
    event UpdateTargetVaultAuthorization(address vault, bool isAuthorized);

    // Auto-generated functions.

    /// @notice Returns the stake that a user has.
    function stakes(address user) external returns (uint128, uint64);

    /// @notice Returns the authorization status of a vault to receive HFT from.
    /// @param vault The source vault.
    /// @return The authorization status.
    function sourceVaultAuthorization(address vault) external returns (bool);

    /// @notice Returns the authorization status of a vault to send HFT to.
    /// @param vault The source vault.
    /// @return The authorization status.
    function targetVaultAuthorization(address vault) external returns (bool);

    // Functions.

    /// @notice The total (voting) power of a user's stake.
    /// @param user The user to compute the power for.
    /// @return Total stake power.
    function getStakePower(address user) external view returns (uint256);

    /// @notice Increases the amount or the lock of a stake, or both.
    /// @param amount Amount to increase the stake by.
    /// @param daysToStake Days to increase the stake lock by.
    function boostHFTStake(uint128 amount, uint16 daysToStake) external;

    /**
     * @notice Increases the amount or the lock of a stake, or both.
     *
     * Uses an ERC-721 permit for HFT allowance.
     */
    /// @param amount Amount to increase the stake by.
    /// @param daysToStake Days to increase the stake lock by.
    /// @param deadline Deadline of permit.
    /// @param v v-part of the permit signature.
    /// @param r r-part of the permit signature.
    /// @param s s-part of the permit signature.
    /// @param approvalAmount Amount of HFT to spend that the permit approves.
    function boostHFTStakeWithPermit(
        uint128 amount,
        uint16 daysToStake,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 approvalAmount
    ) external;

    /// @notice Increases the HFT amount of a user's stake.
    /// @param user The user to increase the stake for.
    /// @param amount Amount by which the stake needs to be increased.
    /// @dev Can only be called by a contract.
    function increaseHFTStakeAmountFor(address user, uint128 amount) external;

    /// @notice Withdraws HFT to the user.
    /// @param amountToRestake Amount of HFT to re-stake instead of withdrawing.
    /// @param daysToRestake Number of days to lock the re-staked portion.
    function withdrawHFT(
        uint128 amountToRestake,
        uint16 daysToRestake
    ) external;

    /// @notice Transfers a user's stake to another vault.
    /// @param targetVault The address of the target vault.
    function transferHFTStake(address targetVault) external;

    /// @notice Receives a stake transfer that is issued via transferHFTStake.
    /// @param user The user to receive the transfer for.
    /// @param amount Amount of stake to receive.
    /// @param lockExpiry Lock expiry in the source vault.
    function receiveHFTStakeTransfer(
        address user,
        uint128 amount,
        uint64 lockExpiry
    ) external;

    // Admin.

    /// @notice Updates the max staking period, in days.
    /// @param maxDaysToStake The new max number of days a user is allowed to stake.
    function updateMaxDaysToStake(uint16 maxDaysToStake) external;

    /// @notice Updates the authorization status of a source vault, for stake transfer.
    /// @param vault The vault to update the authorization for.
    /// @param isAuthorized The new authorization status.
    function updateSourceVaultAuthorization(
        address vault,
        bool isAuthorized
    ) external;

    /// @notice Updates the authorization status of a target vault, for stake transfer.
    /// @param vault The vault to update the authorization for.
    /// @param isAuthorized The new authorization status.
    function updateTargetVaultAuthorization(
        address vault,
        bool isAuthorized
    ) external;
}

contract StakingVault is IStakingVault, ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;
    using SafeERC20 for IERC20Permit;
    using Address for address;

    address public immutable hft;

    uint16 public maxDaysToStake;

    mapping(address => Stake) public stakes;

    mapping(address => bool) public sourceVaultAuthorization;
    mapping(address => bool) public targetVaultAuthorization;

    constructor(address _hft) {
        require(
            _hft != address(0),
            'StakingVault::constructor HFT is 0 address.'
        );
        hft = _hft;

        // 4 years by default.
        maxDaysToStake = 4 * 365;
    }

    function getStakePower(
        address user
    ) external view override returns (uint256) {
        uint256 timeUntilExpiry = 0;

        Stake memory stake = stakes[user];
        if (stake.lockExpiry > block.timestamp) {
            timeUntilExpiry = uint256(stake.lockExpiry) - block.timestamp;
        }

        /**
         * @dev We give 1 power for every 4 years of HFT collectively locked
         * in the vault by the user.
         */
        return (stake.amount * timeUntilExpiry) / (4 * (365 days));
    }

    function boostHFTStake(
        uint128 amount,
        uint16 daysToStake
    ) external override {
        _boostHFTStake(msg.sender, amount, daysToStake);

        emit BoostHFTStake(msg.sender, amount, daysToStake);

        IERC20(hft).safeTransferFrom(msg.sender, address(this), amount);
    }

    function boostHFTStakeWithPermit(
        uint128 amount,
        uint16 daysToStake,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 approvalAmount
    ) external override {
        _boostHFTStake(msg.sender, amount, daysToStake);

        emit BoostHFTStake(msg.sender, amount, daysToStake);

        IERC20Permit(hft).safePermit(
            msg.sender,
            address(this),
            approvalAmount,
            deadline,
            v,
            r,
            s
        );

        IERC20(hft).safeTransferFrom(msg.sender, address(this), amount);
    }

    function increaseHFTStakeAmountFor(
        address user,
        uint128 amount
    ) external override {
        require(
            msg.sender.isContract(),
            'StakingVault::increaseHFTStakeAmountFor Caller should be contract.'
        );

        _boostHFTStake(user, amount, 0);

        emit BoostHFTStake(user, amount, 0);

        IERC20(hft).safeTransferFrom(msg.sender, address(this), amount);
    }

    function withdrawHFT(
        uint128 amountToRestake,
        uint16 daysToRestake
    ) external override {
        Stake memory currentStake = stakes[msg.sender];

        require(
            currentStake.lockExpiry <= block.timestamp,
            'StakingVault::withdrawHFT HFT is locked.'
        );
        require(
            currentStake.amount > 0,
            'StakingVault::withdrawHFT No HFT staked.'
        );

        uint128 amountToWithdraw = currentStake.amount;

        if (amountToRestake > 0) {
            require(
                daysToRestake > 0,
                'StakingVault::withdrawHFT Time lock not specified.'
            );
            require(
                amountToRestake <= currentStake.amount,
                'StakingVault::withdrawHFT Re-stake amount too high.'
            );

            amountToWithdraw -= amountToRestake;
        }

        currentStake.amount = 0;

        stakes[msg.sender] = currentStake;

        emit StakeChanged(
            msg.sender,
            currentStake.amount,
            currentStake.lockExpiry
        );

        if (amountToRestake > 0) {
            _boostHFTStake(msg.sender, amountToRestake, daysToRestake);
        }

        emit WithdrawHFT(msg.sender, amountToWithdraw, amountToRestake);

        if (amountToWithdraw > 0) {
            IERC20(hft).safeTransfer(msg.sender, amountToWithdraw);
        }
    }

    function transferHFTStake(
        address targetVault
    ) external override nonReentrant {
        require(
            targetVaultAuthorization[targetVault],
            'StakingVault::transferHFTStake Target Vault not authorized.'
        );

        Stake memory currentStake = stakes[msg.sender];

        require(
            currentStake.amount > 0,
            'StakingVault::transferHFTStake No HFT locked.'
        );

        uint128 amountToTransfer = currentStake.amount;
        uint64 lockExpiryToTransfer = currentStake.lockExpiry;

        currentStake.amount = 0;
        currentStake.lockExpiry = 0;

        stakes[msg.sender] = currentStake;

        emit StakeChanged(
            msg.sender,
            currentStake.amount,
            currentStake.lockExpiry
        );

        emit TransferHFTStake(msg.sender, targetVault, amountToTransfer);

        IERC20(hft).safeIncreaseAllowance(
            targetVault,
            uint256(amountToTransfer)
        );

        IStakingVault(targetVault).receiveHFTStakeTransfer(
            msg.sender,
            amountToTransfer,
            lockExpiryToTransfer
        );

        require(
            IERC20(hft).allowance(address(this), targetVault) == 0,
            'StakingVault::transferHFTStake HFT not spent.'
        );
    }

    function receiveHFTStakeTransfer(
        address user,
        uint128 amount,
        uint64 lockExpiry
    ) external override nonReentrant {
        require(
            sourceVaultAuthorization[msg.sender],
            'StakingVault::receiveHFTStakeTransfer Source Vault not authorized.'
        );
        uint64 newExpiry = lockExpiry;

        Stake memory currentStake = stakes[user];

        if (currentStake.lockExpiry > newExpiry) {
            newExpiry = currentStake.lockExpiry;
        }

        require(
            newExpiry <=
                (uint64(block.timestamp) +
                    uint64(maxDaysToStake) *
                    uint64(1 days)),
            'StakingVault::receiveHFTStakeTransfer Time lock too high.'
        );

        currentStake.lockExpiry = newExpiry;

        require(
            type(uint128).max - amount > currentStake.amount,
            'StakingVault::receiveHFTStakeTransfer amount too high.'
        );

        currentStake.amount += amount;

        stakes[user] = currentStake;

        IERC20(hft).safeTransferFrom(msg.sender, address(this), amount);
    }

    // Admin

    function updateMaxDaysToStake(
        uint16 newMaxDaysToStake
    ) external override onlyOwner {
        require(
            newMaxDaysToStake != maxDaysToStake,
            'StakingVault::updateMaxDaysToStake Number has not changed.'
        );
        maxDaysToStake = newMaxDaysToStake;

        emit UpdateMaxDaysToStake(maxDaysToStake);
    }

    function updateSourceVaultAuthorization(
        address vault,
        bool isAuthorized
    ) external override onlyOwner {
        require(
            vault != address(this),
            'StakingVault::updateSourceVaultAuthorization Cannot self-authorize.'
        );
        require(
            sourceVaultAuthorization[vault] != isAuthorized,
            'StakingVault::updateSourceVaultAuthorization No-op.'
        );
        sourceVaultAuthorization[vault] = isAuthorized;

        emit UpdateSourceVaultAuthorization(vault, isAuthorized);
    }

    function updateTargetVaultAuthorization(
        address vault,
        bool isAuthorized
    ) external override onlyOwner {
        require(
            vault != address(this),
            'StakingVault::updateTargetVaultAuthorization Cannot self-authorize.'
        );
        require(
            targetVaultAuthorization[vault] != isAuthorized,
            'StakingVault::updateTargetVaultAuthorization No-op.'
        );
        targetVaultAuthorization[vault] = isAuthorized;

        emit UpdateTargetVaultAuthorization(vault, isAuthorized);
    }

    function renounceOwnership() public view override onlyOwner {
        revert('StakingVault::renounceOwnership Cannot renounce ownership.');
    }

    // Internal functions.

    function _boostHFTStake(
        address user,
        uint128 amount,
        uint16 daysToStake
    ) internal {
        require(
            amount > 0 || daysToStake > 0,
            'StakingVault::_boostHFTStake Amount or days have to be > 0'
        );
        Stake memory currentStake = stakes[user];

        if (daysToStake > 0) {
            uint64 timeUntilExpiry = 0;
            if (currentStake.lockExpiry > block.timestamp) {
                timeUntilExpiry =
                    currentStake.lockExpiry -
                    uint64(block.timestamp);
            }

            uint64 extraLockTime = uint64(daysToStake) * uint64(1 days);

            require(
                extraLockTime + timeUntilExpiry <=
                    uint64(maxDaysToStake) * uint64(1 days),
                'StakingVault::_boostHFTStake Time lock too high'
            );

            if (timeUntilExpiry > 0) {
                currentStake.lockExpiry += extraLockTime;
            } else {
                currentStake.lockExpiry =
                    uint64(block.timestamp) +
                    extraLockTime;
            }
        }

        if (amount > 0) {
            require(
                type(uint128).max - currentStake.amount > amount,
                'StakingVault::_boostHFTStake amount too high.'
            );
            currentStake.amount += amount;
        }

        stakes[user] = currentStake;

        emit StakeChanged(user, currentStake.amount, currentStake.lockExpiry);
    }
}