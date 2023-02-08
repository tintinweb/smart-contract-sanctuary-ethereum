// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
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

// SPDX-License-Identifier: GNU GPLv3

pragma solidity ^0.8.0;

import "./IStabl3StakingStruct.sol";
import "./IERC20.sol";

interface IROI is IStabl3StakingStruct {

    function timeWeightedAPR() external view returns (TimeWeightedAPR memory);
    function updateAPRLast() external view returns (uint256);
    function updateTimestampLast() external view returns (uint256);

    function contractCreationTime() external view returns (uint256);

    function getTimeWeightedAPRs(uint256) external view returns (TimeWeightedAPR memory);
    function getAPRs(uint256) external view returns (uint256);

    function permitted(address) external returns (bool);

    function searchTimeWeightedAPR(uint256 _startTimeWeight, uint256 _endTimeWeight) external view returns (TimeWeightedAPR memory);

    function getTotalRewardDistributed() external view returns (uint256);

    function getReserves() external view returns (uint256);

    function getAPR() external view returns (uint256);

    function validatePool(
        IERC20 _token,
        uint256 _amountToken,
        uint8 _stakingType,
        bool _isLending
    ) external view returns (uint256 maxPool, uint256 currentPool);

    function distributeReward(
        address _user,
        IERC20 _rewardToken,
        uint256 _amountRewardToken,
        uint8 _rewardPoolType
    ) external;

    function updateAPR() external;

    function returnFunds(IERC20 _token, uint256 _amountToken) external;
}

// SPDX-License-Identifier: GNU GPLv3

pragma solidity ^0.8.0;

import "./IStabl3StakingStruct.sol";
import "./IROI.sol";

interface IStabl3Staking is IStabl3StakingStruct {

    function lendingStabl3Percentage() external view returns (uint256);
    function lendingStabl3ClaimTime() external view returns (uint256);

    function lockTimes(uint256) external view returns (uint256);

    function dormantROIReserves() external view returns (uint256);
    function withdrawnROIReserves() external view returns (uint256);

    function emergencyState() external view returns (bool);
    function emergencyTime() external view returns (uint256);

    function getStakings(address, uint256) external view returns (Staking memory);

    function getStakers(uint256) external view returns (address);

    function getRecords(address, bool) external view returns (Record memory);

    function allStakersLength() external view returns (uint256);

    function allStakingsLength(address _user) external view returns (uint256);

    function allStakings(
        address _user,
        bool _isRealEstate
    ) external view returns (
        Staking[] memory unlockedLending,
        Staking[] memory lockedLending,
        Staking[] memory unlockedStaking,
        Staking[] memory lockedStaking
    );

    function stake(IERC20 _token, uint256 _amountToken, uint8 _stakingType, bool _isLending) external;

    function accessWithPermit(address _user, Staking memory _staking, uint8 _identifier) external;

    function getAmountRewardSingle(
        address _user,
        uint256 _index,
        bool _isLending,
        bool _isRealEstate,
        uint256 _timestamp
    ) external view returns (uint256);

    function getAmountRewardAll(address _user, bool _isLending, bool _isRealEstate) external view returns (uint256);

    function withdrawAmountRewardAll(bool _isLending) external;

    function getClaimableStabl3LendingSingle(
        address _user,
        uint256 _index,
        uint256 _timestamp
    ) external view returns (uint256);

    function getClaimableStabl3LendingAll(address _user) external view returns (uint256);

    function claimStabl3LendingAll() external;

    function getAmountStakedAll(
        address _user,
        bool _isLending,
        bool _isRealEstate
    ) external view returns (uint256 totalAmountStakedUnlocked, uint256 totalAmountStakedLocked);

    function restakeSingle(uint256 _index, uint256 _amountToUnstake, uint8 _stakingType) external;

    function unstakeSingle(uint256 _index) external;

    function unstakeMultiple(uint256[] memory _indexes) external;
}

// SPDX-License-Identifier: GNU GPLv3

pragma solidity ^0.8.0;

import "./IERC20.sol";

interface IStabl3StakingStruct {

    struct TimeWeightedAPR {
        uint256 APR;
        uint256 timeWeight;
    }

    struct Staking {
        uint256 index;
        address user;
        bool status;
        uint8 stakingType;
        IERC20 token;
        uint256 amountTokenStaked;
        uint256 startTime;
        TimeWeightedAPR timeWeightedAPRLast;
        uint256 rewardWithdrawn;
        uint256 rewardWithdrawTimeLast;
        bool isLending;
        uint256 amountStabl3Lending;
        bool isDormant;
        bool isRealEstate;
    }

    struct Record {
        uint256 totalAmountTokenStaked;
        uint256 totalRewardWithdrawn;
        uint256 totalAmountStabl3Withdrawn;
    }
}

// SPDX-License-Identifier: GNU GPLv3

pragma solidity ^0.8.0;

import "./IERC20.sol";

interface ITreasury {

    function exchangeFee() external view returns (uint256);

    function rateInfo() external view returns (uint256 rate, uint256 totalValueLocked, uint256 stabl3CirculatingSupply);

    function isReservedToken(IERC20) external view returns (bool);

    function allReservedTokens(uint) external view returns (IERC20);

    function getTreasuryPool(uint8, IERC20) external view returns (uint256);
    function getROIPool(uint8, IERC20) external view returns (uint256);
    function getHQPool(uint8, IERC20) external view returns (uint256);

    function permitted(address) external view returns (bool);

    function allReservedTokensLength() external view returns (uint256);

    function allPools(uint8 _type, IERC20 _token) external view returns (uint256, uint256, uint256);

    function sumOfAllPools(uint8 _type, IERC20 _token) external view returns (uint256);

    function getReserves() external view returns (uint256);

    function getTotalValueLocked() external view returns (uint256);

    function reservedTokenSelector() external view returns (IERC20);

    function checkOutputAmount(uint256 _amountStabl3) external view;

    function getRate() external view returns (uint256);

    function getRateImpact(IERC20 _token, uint256 _amountToken) external view returns (uint256);

    function getAmountOut(IERC20 _token, uint256 _amountToken) external view returns (uint256);

    function getAmountIn(uint256 _amountStabl3, IERC20 _token) external view returns (uint256);

    function getExchangeAmountOut(IERC20 _exchangingToken, IERC20 _token, uint256 _amountToken) external view returns (uint256);

    function getExchangeAmountIn(IERC20 _exchangingToken, uint256 _amountExchangingToken, IERC20 _token) external view returns (uint256);

    function updatePool(
        uint8 _type,
        IERC20 _token,
        uint256 _amountTokenTreasury,
        uint256 _amountTokenROI,
        uint256 _amountTokenHQ,
        bool _isIncrease
    ) external;

    function updateStabl3CirculatingSupply(uint256 _amountStabl3, bool _isIncrease) external;

    function updateRate(IERC20 _token, uint256 _amountToken) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "./Context.sol";

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

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "./Address.sol";
import "./IERC20.sol";
import "./IERC20Permit.sol";

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
        if (value > 0) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
        }
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        if (value > 0) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
        }
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }

    /**
     * @dev Returns the current rounding of the division of two numbers.
     *
     * This differs from standard division with `/` in that it can round up and
     * down depending on the floating point.
     */
    function roundDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 result = a * 10 / b;
        if (result % 10 >= 5) {
            result = a / b + (a % b == 0 ? 0 : 1);
        }
        else {
            result = a / b;
        }

        return result;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, without an overflow flag
     */
    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            if (b > a) return 0;
            return a - b;
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, without an overflow flag
     */
    function checkSub(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            if (b > a) return a;
            else return a - b;
        }
    }
}

// SPDX-License-Identifier: GNU GPLv3

pragma solidity 0.8.17;

import "./Stabl3StakingHelper.sol";

import "./Ownable.sol";

import "./SafeMathUpgradeable.sol";
import "./SafeERC20.sol";

import "./IStabl3StakingStruct.sol";
import "./ITreasury.sol";
import "./IROI.sol";

contract Stabl3Staking is Ownable, IStabl3StakingStruct {
    using SafeMathUpgradeable for uint256;

    uint8 private constant BUY_POOL = 0;

    uint8 private constant STAKE_POOL = 2;
    uint8 private constant STAKE_REWARD_POOL = 3;
    uint8 private constant STAKE_FEE_POOL = 4;
    uint8 private constant LEND_POOL = 5;
    uint8 private constant LEND_REWARD_POOL = 6;
    uint8 private constant LEND_FEE_POOL = 7;

    uint8 private constant STAKING_TYPE_POOL = 20;

    uint8 private constant STABL3_RESERVED_POOL = 25;

    // TODO remove
    uint256 private constant oneDayTime = 10;
    uint256 private constant oneYearTime = 3600;
    // uint256 private constant oneDayTime = 86400; // 1 day time in seconds
    // uint256 private constant oneYearTime = 31536000; // 1 year time in seconds

    ITreasury public TREASURY;
    IROI public ROI;
    address public HQ;

    Stabl3StakingHelper private stabl3StakingHelper;

    IERC20 public immutable STABL3;

    uint256[2] public treasuryPercentages;
    uint256[2] public ROIPercentages;
    uint256[2] public HQPercentages;

    uint256 public lendingStabl3Percentage;
    uint256 public lendingStabl3ClaimTime;
    uint256[5] public lockTimes;

    uint256 public dormantROIReserves;
    uint256 public withdrawnROIReserves;

    uint256 public unstakeFeePercentage;

    uint256 public lastProcessedUser;
    uint256 public lastProcessedStaking;

    bool public emergencyState;
    uint256 public emergencyTime;

    bool public stakeState;

    // storage

    /// @dev User stakings
    mapping (address => Staking[]) public getStakings;

    /// @dev All users
    address[] public getStakers;

    /// @dev User's lifetime staking records
    /// @dev No deductions when unstaking
    mapping (address => mapping (bool => Record)) public getRecords;

    /// @dev Contracts with permission to access Stabl33 Staking functions
    mapping (address => bool) public permitted;

    // events

    event UpdatedTreasury(address newTreasury, address oldTreasury);

    event UpdatedROI(address newROI, address oldROI);

    event UpdatedHQ(address newHQ, address oldHQ);

    event UpdatedPermission(address contractAddress, bool state);

    event Stake(
        address indexed user,
        uint256 index,
        bool status,
        uint8 stakingType,
        IERC20 token,
        uint256 amountToken,
        uint256 totalAmountToken,
        uint256 endTime,
        bool isLend,
        uint256 amountStabl3Lending,
        uint256 timestamp
    );

    event WithdrewReward(
        address indexed user,
        uint256 index,
        IERC20 token,
        uint256 rewardWithdrawn,
        uint256 totalRewardWithdrawn,
        bool isLend,
        uint256 timestamp
    );

    event ClaimedLendingStabl3(
        address indexed user,
        uint256 index,
        IERC20 token,
        uint256 amountStabl3Lending,
        uint256 totalAmountStabl3Withdrawn,
        uint256 timestamp
    );

    event Unstake(
        address indexed user,
        uint256 index,
        IERC20 token,
        uint256 amountToken,
        uint256 reward,
        uint8 stakingType,
        bool isLend
    );

    // constructor

    constructor(address _TREASURY, address _ROI) {
        TREASURY = ITreasury(_TREASURY);
        ROI = IROI(_ROI);
        // TODO change
        HQ = 0x294d0487fdf7acecf342ae70AFc5549A6E90f3e0;

        stabl3StakingHelper = new Stabl3StakingHelper(_ROI);

        // TODO change
        STABL3 = IERC20(0xDf9c4990a8973b6cC069738592F27Ea54b27D569);

        treasuryPercentages = [975, 761];
        ROIPercentages = [0, 0];
        HQPercentages = [25, 39];

        lendingStabl3Percentage = 200;
        // TODO remove
        lendingStabl3ClaimTime = 300;
        // lendingStabl3ClaimTime = 2628000; // 1 month time in seconds

        // TODO remove
        lockTimes = [0, 900, 1800, 2700, 3600];
        // lockTimes = [0, 7884000, 15768000, 23652000, 31536000]; // 3, 6, 9 and 12 months time in seconds

        unstakeFeePercentage = 50;
    }

    function updateTreasury(address _TREASURY) external onlyOwner {
        require(address(TREASURY) != _TREASURY, "Stabl3Staking: Treasury is already this address");
        emit UpdatedTreasury(_TREASURY, address(TREASURY));
        TREASURY = ITreasury(_TREASURY);
    }

    function updateROI(address _ROI) external onlyOwner {
        require(address(ROI) != _ROI, "Stabl3Staking: ROI is already this address");
        emit UpdatedROI(_ROI, address(ROI));
        ROI = IROI(_ROI);
    }

    function updateHQ(address _HQ) external onlyOwner {
        require(HQ != _HQ, "Stabl3Staking: HQ is already this address");
        emit UpdatedHQ(_HQ, HQ);
        HQ = _HQ;
    }

    function updateStabl3StakingHelper(address _stabl3StakingHelper) external onlyOwner {
        require(address(stabl3StakingHelper) != _stabl3StakingHelper, "Stabl3Staking: Stabl3 Staking Helper is already this address");
        stabl3StakingHelper = Stabl3StakingHelper(_stabl3StakingHelper);
    }

    function updateDistributionPercentages(
        uint256 _treasuryPercentage,
        uint256 _ROIPercentage,
        uint256 _HQPercentage,
        uint256 _lendingStabl3Percentage,
        bool _isLending
    ) external onlyOwner {
        if (_isLending) {
            require(_treasuryPercentage + _ROIPercentage + _HQPercentage + _lendingStabl3Percentage == 1000,
                "Stabl3Staking: Sum of magnified Lend percentages should equal 1000");

            treasuryPercentages[1] = _treasuryPercentage;
            ROIPercentages[1] = _ROIPercentage;
            HQPercentages[1] = _HQPercentage;
            lendingStabl3Percentage = _lendingStabl3Percentage;
        }
        else {
            require(_treasuryPercentage + _ROIPercentage + _HQPercentage == 1000,
                "Stabl3Staking: Sum of magnified Stake percentages should equal 1000");

            treasuryPercentages[0] = _treasuryPercentage;
            ROIPercentages[0] = _ROIPercentage;
            HQPercentages[0] = _HQPercentage;
        }
    }

    function updateLendingStabl3ClaimTime(uint256 _lendingStabl3ClaimTime) external onlyOwner {
        require(lendingStabl3ClaimTime != _lendingStabl3ClaimTime, "Stabl3Staking: Lending Stabl3 Claim Time is already this value");
        lendingStabl3ClaimTime = _lendingStabl3ClaimTime;
    }

    function updateLockTimes(uint256[5] calldata _lockTimes) external onlyOwner {
        lockTimes = _lockTimes;
    }

    function updateUnstakeFeePercentage(uint256 _unstakeFeePercentage) external onlyOwner {
        require(unstakeFeePercentage != _unstakeFeePercentage, "Stabl3Staking: Unstake Fee is already this value");
        unstakeFeePercentage = _unstakeFeePercentage;
    }

    function updateEmergencyState(bool _emergencyState) external onlyOwner {
        require (emergencyState != _emergencyState, "Stabl3Staking: Emergency State is already this state");
        emergencyTime = _emergencyState ? block.timestamp : 0;
        emergencyState = _emergencyState;
    }

    function updateState(bool _state) external onlyOwner {
        require(stakeState != _state, "Stabl3Staking: Stake State is already this state");
        stakeState = _state;
    }

    function allStakersLength() external view returns (uint256) {
        return getStakers.length;
    }

    function allStakingsLength(address _user) external view returns (uint256) {
        return getStakings[_user].length;
    }

    function allStakings(
        address _user,
        bool _isRealEstate
    ) external view returns (
        Staking[] memory unlockedLending,
        Staking[] memory lockedLending,
        Staking[] memory unlockedStaking,
        Staking[] memory lockedStaking
    ) {
        (unlockedLending, lockedLending, unlockedStaking, lockedStaking) = stabl3StakingHelper.allStakings(_user, _isRealEstate);
    }

    function updatePermission(address _contractAddress, bool _state) public onlyOwner {
        require(permitted[_contractAddress] != _state, "Stabl3Staking: Contract Address is already this state");

        permitted[_contractAddress] = _state;

        emit UpdatedPermission(_contractAddress, _state);
    }

    function updatePermissionMultiple(address[] memory _contractAddresses, bool _state) public onlyOwner {
        for (uint256 i = 0 ; i < _contractAddresses.length ; i++) {
            updatePermission(_contractAddresses[i], _state);
        }
    }

    function stake(
        IERC20 _token,
        uint256 _amountToken,
        uint8 _stakingType,
        bool _isLending
    ) public stakeActive reserved(_token) {
        require(!emergencyState, "Stabl3Staking: Cannot stake right now");
        require(ROI.getAPR() > 0, "Stabl3Staking: No APR to give");
        require(1 <= _stakingType && _stakingType <= 4, "Stabl3Staking: Incorrect staking type");
        require(_amountToken > 4, "Stabl3Staking: Insufficient amount");
        (uint256 maxPool, uint256 currentPool) = ROI.validatePool(_token, _amountToken, _stakingType, _isLending);
        require(currentPool <= maxPool, "Stabl3Staking: Staking pool limit reached. Please try again later or try a different amount");

        uint256 amountStabl3Lending;

        if (_isLending) {
            uint256 amountTreasury = _amountToken.mul(treasuryPercentages[1]).div(1000);
            uint256 amountROI = _amountToken.mul(ROIPercentages[1]).div(1000);
            uint256 amountHQ = _amountToken.mul(HQPercentages[1]).div(1000);
            uint256 amountTokenLending = _amountToken.mul(lendingStabl3Percentage).div(1000);

            amountStabl3Lending = TREASURY.getAmountOut(_token, amountTokenLending);
            TREASURY.checkOutputAmount(amountStabl3Lending);

            uint256 totalAmountDistributed = amountTreasury + amountROI + amountHQ + amountTokenLending;
            if (_amountToken > totalAmountDistributed) {
                amountTreasury += _amountToken - totalAmountDistributed;
            }

            _amountToken -= amountTokenLending;

            SafeERC20.safeTransferFrom(_token, msg.sender, address(TREASURY), amountTreasury);
            SafeERC20.safeTransferFrom(_token, msg.sender, address(ROI), amountROI);
            SafeERC20.safeTransferFrom(_token, msg.sender, HQ, amountHQ);
            SafeERC20.safeTransferFrom(_token, msg.sender, address(ROI), amountTokenLending);

            TREASURY.updatePool(LEND_POOL, _token, amountTreasury + amountHQ, amountROI, amountHQ, true);
            TREASURY.updatePool(BUY_POOL, _token, 0, amountTokenLending, 0, true);
            TREASURY.updatePool(STABL3_RESERVED_POOL, STABL3, amountStabl3Lending, 0, 0, true);

            TREASURY.updateRate(_token, amountTokenLending);
        }
        else {
            uint256 amountTreasury = _amountToken.mul(treasuryPercentages[0]).div(1000);
            uint256 amountROI = _amountToken.mul(ROIPercentages[0]).div(1000);
            uint256 amountHQ = _amountToken.mul(HQPercentages[0]).div(1000);

            uint256 totalAmountDistributed = amountTreasury + amountROI + amountHQ;
            if (_amountToken > totalAmountDistributed) {
                amountTreasury += _amountToken - totalAmountDistributed;
            }

            SafeERC20.safeTransferFrom(_token, msg.sender, address(TREASURY), amountTreasury);
            SafeERC20.safeTransferFrom(_token, msg.sender, address(ROI), amountROI);
            SafeERC20.safeTransferFrom(_token, msg.sender, HQ, amountHQ);

            TREASURY.updatePool(STAKE_POOL, _token, amountTreasury + amountHQ, amountROI, amountHQ, true);
        }

        ROI.updateAPR();

        uint256 timestampToConsider = block.timestamp;

        Staking memory staking;
        staking.index = getStakings[msg.sender].length;
        staking.user = msg.sender;
        staking.status = true;
        staking.stakingType = _stakingType;
        staking.token = _token;
        staking.amountTokenStaked = _amountToken;
        staking.startTime = timestampToConsider;
        staking.timeWeightedAPRLast = ROI.timeWeightedAPR();
        // staking.rewardWithdrawn = 0;
        staking.rewardWithdrawTimeLast = timestampToConsider;
        staking.isLending = _isLending;
        staking.amountStabl3Lending = amountStabl3Lending;
        // staking.isDormant = false;
        // staking.isRealEstate = false;

        getStakings[msg.sender].push(staking);

        if (staking.index == 0) {
            getStakers.push(msg.sender);
        }

        Record storage record = getRecords[msg.sender][_isLending];

        uint256 amountTokenConverted = _token.decimals() < 18 ? _amountToken * (10 ** (18 - _token.decimals())) : _amountToken;

        TREASURY.updatePool(STAKING_TYPE_POOL + _stakingType, IERC20(address(0)), amountTokenConverted, 0, 0, true);
        record.totalAmountTokenStaked += amountTokenConverted;

        emit Stake(
            staking.user,
            staking.index,
            staking.status,
            staking.stakingType,
            staking.token,
            staking.amountTokenStaked,
            record.totalAmountTokenStaked,
            timestampToConsider + lockTimes[staking.stakingType],
            staking.isLending,
            staking.amountStabl3Lending,
            timestampToConsider
        );
    }

    /**
     * @dev This function is only called externally by certain contracts to provide APR on a given value
     * @dev Requires permit
     * @dev Requires external checks, transfers, records, updatePool calls, updateAPR calls and event emissions
     */
    function accessWithPermit(address _user, Staking calldata _staking, uint8 _identifier) external {
        require(!emergencyState, "Stabl3Staking: Cannot stake right now");
        require(permitted[msg.sender] || msg.sender == owner(), "Stabl3Staking: Not permitted");

        if (_identifier == 0) {
            if (_staking.index == 0) {
                getStakers.push(msg.sender);
            }

            getStakings[_user].push(_staking);
        }
        else if (_identifier == 1) {
            getStakings[_user][_staking.index] = _staking;
        }
        // TODO confirm
        // else if (_identifier == 2) {
        //     getStakings[_user][_staking.index] = _staking;

        //     getStakings[_user][_staking.index].status = false;
        // }
    }

    function getAmountRewardSingle(
        address _user,
        uint256 _index,
        bool _isLending,
        bool _isRealEstate,
        uint256 _timestamp
    ) public view returns (uint256) {
        return stabl3StakingHelper.getAmountRewardSingle(_user, _index, _isLending, _isRealEstate, _timestamp);
    }

    function getAmountRewardAll(address _user, bool _isLending, bool _isRealEstate) external view returns (uint256) {
        return stabl3StakingHelper.getAmountRewardAll(_user, _isLending, _isRealEstate);
    }

    function _withdrawAmountRewardSingle(uint256 _index, bool _isLending, uint256 _timestamp) internal {
        Staking storage staking = getStakings[msg.sender][_index];

        uint256 reward = getAmountRewardSingle(msg.sender, _index, _isLending, false, _timestamp);

        if (reward > 0) {
            uint256 endTime = staking.startTime + lockTimes[staking.stakingType];

            Record storage record = getRecords[msg.sender][staking.isLending];

            uint8 rewardPoolType = staking.isLending ? LEND_REWARD_POOL : STAKE_REWARD_POOL;

            ROI.distributeReward(msg.sender, staking.token, reward, rewardPoolType);

            uint256 decimals = staking.token.decimals();

            uint256 rewardConverted = decimals < 18 ? reward * (10 ** (18 - decimals)) : reward;

            if (staking.isDormant) {
                dormantROIReserves = dormantROIReserves.safeSub(rewardConverted);
            }

            if (_timestamp > endTime) {
                uint256 rewardWithdrawnConverted =
                    decimals < 18 ?
                    staking.rewardWithdrawn * (10 ** (18 - decimals)) :
                    staking.rewardWithdrawn;

                withdrawnROIReserves = withdrawnROIReserves.safeSub(rewardWithdrawnConverted);
            }
            else {
                withdrawnROIReserves += rewardConverted;
            }

            ROI.updateAPR();

            staking.timeWeightedAPRLast = ROI.timeWeightedAPR();
            staking.rewardWithdrawn += reward;
            staking.rewardWithdrawTimeLast = _timestamp > endTime ? endTime : _timestamp;

            record.totalRewardWithdrawn += rewardConverted;

            emit WithdrewReward(
                staking.user,
                staking.index,
                staking.token,
                reward,
                record.totalRewardWithdrawn,
                _isLending,
                _timestamp
            );
        }
    }

    function withdrawAmountRewardAll(bool _isLending) external stakeActive {
        uint256 timestampToConsider = block.timestamp;

        for (uint256 i = 0 ; i < getStakings[msg.sender].length ; i++) {
            _withdrawAmountRewardSingle(i, _isLending, timestampToConsider);
        }
    }

    function getClaimableStabl3LendingSingle(
        address _user,
        uint256 _index,
        uint256 _timestamp
    ) public view returns (uint256) {
        return stabl3StakingHelper.getClaimableStabl3LendingSingle(_user, _index, _timestamp);
    }

    function getClaimableStabl3LendingAll(address _user) external view returns (uint256) {
        return stabl3StakingHelper.getClaimableStabl3LendingAll(_user);
    }

    function _claimStabl3LendingSingle(uint256 _index, uint256 _timestamp) internal {
        Staking storage staking = getStakings[msg.sender][_index];

        Record storage record = getRecords[msg.sender][true];

        uint256 amountStabl3Lending = getClaimableStabl3LendingSingle(msg.sender, _index, _timestamp);

        if (amountStabl3Lending > 0) {
            STABL3.transferFrom(address(TREASURY), msg.sender, amountStabl3Lending);

            record.totalAmountStabl3Withdrawn += amountStabl3Lending;

            TREASURY.updatePool(STABL3_RESERVED_POOL, STABL3, amountStabl3Lending, 0, 0, false);
            TREASURY.updateStabl3CirculatingSupply(amountStabl3Lending, true);

            emit ClaimedLendingStabl3(
                staking.user,
                staking.index,
                staking.token,
                staking.amountStabl3Lending,
                record.totalAmountStabl3Withdrawn,
                _timestamp
            );

            staking.amountStabl3Lending = 0;
        }
    }

    function claimStabl3LendingAll() external stakeActive {
        uint256 timestampToConsider = block.timestamp;

        for (uint256 i = 0 ; i < getStakings[msg.sender].length ; i++) {
            _claimStabl3LendingSingle(i, timestampToConsider);
        }
    }

    function getAmountStakedAll(
        address _user,
        bool _isLending,
        bool _isRealEstate
    ) external view returns (uint256 totalAmountStakedUnlocked, uint256 totalAmountStakedLocked) {
        (totalAmountStakedUnlocked, totalAmountStakedLocked) = stabl3StakingHelper.getAmountStakedAll(_user, _isLending, _isRealEstate);
    }

    function _unstakeSingle(uint256 _index, uint256 _amountToUnstake) internal {
        Staking storage staking = getStakings[msg.sender][_index];

        if (staking.amountTokenStaked > staking.token.balanceOf(address(TREASURY))) {
            ROI.returnFunds(staking.token, staking.amountTokenStaked - staking.token.balanceOf(address(TREASURY)));
        }

        staking.status = false;

        uint256 fee = staking.amountTokenStaked.mul(unstakeFeePercentage).div(1000);
        uint256 amountToUnstakeWithFee = staking.amountTokenStaked - fee;

        SafeERC20.safeTransferFrom(staking.token, address(TREASURY), address(ROI), fee);

        SafeERC20.safeTransferFrom(staking.token, address(TREASURY), msg.sender, amountToUnstakeWithFee);

        if (!staking.isDormant) {
            (uint8 poolType, uint8 feeType) = staking.isLending ? (LEND_POOL, LEND_FEE_POOL) : (STAKE_POOL, STAKE_FEE_POOL);

            TREASURY.updatePool(poolType, staking.token, staking.amountTokenStaked, 0, 0, false);
            TREASURY.updatePool(feeType, staking.token, 0, fee, 0, true);

            uint256 amountTokenConverted =
                staking.token.decimals() < 18 ?
                staking.amountTokenStaked * (10 ** (18 - staking.token.decimals())) :
                staking.amountTokenStaked;

            TREASURY.updatePool(STAKING_TYPE_POOL + staking.stakingType, IERC20(address(0)), amountTokenConverted, 0, 0, false);
        }

        ROI.updateAPR();

        emit Unstake(
            staking.user,
            staking.index,
            staking.token,
            _amountToUnstake,
            staking.rewardWithdrawn,
            staking.stakingType,
            staking.isLending
        );
    }

    function restakeSingle(uint256 _index, uint256 _amountToUnstake, uint8 _stakingType) external stakeActive {
        Staking storage staking = getStakings[msg.sender][_index];

        require(staking.status, "Stabl3Staking: Invalid Staking");
        require(!staking.isRealEstate, "Stabl3Staking: Not allowed");
        require(_amountToUnstake < staking.amountTokenStaked, "Stabl3Staking: Incorrect amount for restaking");
        if (!emergencyState) {
            require(block.timestamp > staking.startTime + lockTimes[staking.stakingType], "Stabl3Staking: Cannot unstake before end time");
        }

        uint256 timestampToConsider = block.timestamp;

        if (staking.isLending) {
            _claimStabl3LendingSingle(_index, timestampToConsider);
        }

        _withdrawAmountRewardSingle(_index, staking.isLending, timestampToConsider);

        _unstakeSingle(_index, _amountToUnstake);

        uint256 amountToRestake = staking.amountTokenStaked - _amountToUnstake;

        stake(staking.token, amountToRestake, _stakingType, staking.isLending);
    }

    function unstakeSingle(uint256 _index) public stakeActive {
        Staking storage staking = getStakings[msg.sender][_index];

        require(staking.status, "Stabl3Staking: Invalid Staking");
        require(!staking.isRealEstate, "Stabl3Staking: Not allowed");
        if (!emergencyState) {
            require(block.timestamp > staking.startTime + lockTimes[staking.stakingType], "Stabl3Staking: Cannot unstake before end time");
        }

        uint256 timestampToConsider = block.timestamp;

        if (staking.isLending) {
            _claimStabl3LendingSingle(_index, timestampToConsider);
        }

        _withdrawAmountRewardSingle(_index, staking.isLending, timestampToConsider);

        _unstakeSingle(_index, staking.amountTokenStaked);
    }

    function unstakeMultiple(uint256[] calldata _indexes) external stakeActive {
        for (uint256 i = 0 ; i < _indexes.length ; i++) {
            unstakeSingle(_indexes[i]);
        }
    }

    function excludeDormantStakings(uint256 _gas) external stakeActive {
        require(_gas >= 300000, "Stabl3Staking: Gas sent should be atleast 300,000 Wei/0.0003 Gwei");

        uint256 timestampToConsider = block.timestamp;

    	uint256 newLastProcessedUser = lastProcessedUser;
        uint256 newLastProcessedStaking = lastProcessedStaking;

    	uint256 gasUsed;

    	uint256 gasLeft = gasleft();

        uint256 stakerIterations; // for iterating over all stakers

        while (gasUsed < _gas && stakerIterations < getStakers.length) {
            if (newLastProcessedStaking >= getStakings[getStakers[newLastProcessedUser]].length) {
                newLastProcessedUser++;
                newLastProcessedStaking = 0;

                stakerIterations++;
            }

            if (newLastProcessedUser >= getStakers.length) {
                newLastProcessedUser = 0;
            }

            Staking memory staking = getStakings[getStakers[newLastProcessedUser]][newLastProcessedStaking];

            if (
                staking.status &&
                block.timestamp >= staking.startTime + lockTimes[staking.stakingType] &&
                !staking.isDormant
            ) {
                uint256 decimals = staking.token.decimals();

                // ROI Pool reduction

                uint256 reward = getAmountRewardSingle(staking.user, staking.index, staking.isLending, false, timestampToConsider);

                (uint256 amountTokenConverted, uint256 rewardConverted) =
                    decimals < 18 ?
                    (staking.amountTokenStaked * (10 ** (18 - decimals)), reward * (10 ** (18 - decimals))) :
                    (staking.amountTokenStaked, reward);

                dormantROIReserves += rewardConverted;

                // Current Pool reduction

                uint256 fee = staking.amountTokenStaked.mul(unstakeFeePercentage).div(1000);

                (uint8 poolType, uint8 feeType) = staking.isLending ? (LEND_POOL, LEND_FEE_POOL) : (STAKE_POOL, STAKE_FEE_POOL);

                TREASURY.updatePool(poolType, staking.token, staking.amountTokenStaked, 0, 0, false);
                TREASURY.updatePool(feeType, staking.token, 0, fee, 0, true);

                TREASURY.updatePool(STAKING_TYPE_POOL + staking.stakingType, IERC20(address(0)), amountTokenConverted, 0, 0, false);

                // Designating this stake as Dormant

                getStakings[staking.user][staking.index].isDormant = true;
            }

            uint256 newGasLeft = gasleft();

            if (gasLeft > newGasLeft) {
                gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
            }

            gasLeft = newGasLeft;

            newLastProcessedStaking++;
        }

        lastProcessedUser = newLastProcessedUser;
        lastProcessedStaking = newLastProcessedStaking;
    }

    // modifiers

    modifier stakeActive() {
        _stakeActive();
        _;
    }

    function _stakeActive() internal view {
        require(stakeState, "Stabl3Staking: Stake and Lend not yet started");
    }

    modifier reserved(IERC20 _token) {
        _reserved(_token);
        _;
    }

    function _reserved(IERC20 _token) internal view {
        require(TREASURY.isReservedToken(_token), "Stabl3Staking: Not a reserved token");
    }
}

// SPDX-License-Identifier: GNU GPLv3

pragma solidity 0.8.17;

import "./SafeMathUpgradeable.sol";

import "./IROI.sol";
import "./IStabl3Staking.sol";
import "./IStabl3StakingStruct.sol";

contract Stabl3StakingHelper is IStabl3StakingStruct {
    using SafeMathUpgradeable for uint256;

    // TODO remove
    uint256 private constant oneDayTime = 10;
    uint256 private constant oneYearTime = 3600;
    // uint256 private constant oneDayTime = 86400; // 1 day time in seconds
    // uint256 private constant oneYearTime = 31536000; // 1 year time in seconds

    IROI public ROI;

    IStabl3Staking public stabl3Staking;

    // constructor

    constructor(address _ROI) {
        ROI = IROI(_ROI);

        stabl3Staking = IStabl3Staking(msg.sender);
    }

    function allStakings(
        address _user,
        bool _isRealEstate
    ) public view returns (
        Staking[] memory unlockedLending,
        Staking[] memory lockedLending,
        Staking[] memory unlockedStaking,
        Staking[] memory lockedStaking
    ) {
        uint256 unlockedLendingLength;
        uint256 lockedLendingLength;
        uint256 unlockedStakingLength;
        uint256 lockedStakingLength;

        uint256 allStakingsLength = stabl3Staking.allStakingsLength(_user);

        for (uint256 i = 0 ; i < allStakingsLength ; i++) {
            Staking memory staking = stabl3Staking.getStakings(_user, i);

            if (
                staking.status &&
                staking.isRealEstate == _isRealEstate
            ) {
                if (block.timestamp >= staking.startTime + stabl3Staking.lockTimes(staking.stakingType)) {
                    if (staking.isLending) {
                        unlockedLendingLength++;
                    }
                    else {
                        unlockedStakingLength++;
                    }
                }
                else {
                    if (staking.isLending) {
                        lockedLendingLength++;
                    }
                    else {
                        lockedStakingLength++;
                    }
                }
            }
        }

        if (stabl3Staking.emergencyState()) {
            unlockedLending = new Staking[](unlockedLendingLength + lockedLendingLength);
            lockedLending = new Staking[](0);
            unlockedStaking = new Staking[](unlockedStakingLength + lockedStakingLength);
            lockedStaking = new Staking[](0);
        }
        else {
            unlockedLending = new Staking[](unlockedLendingLength);
            lockedLending = new Staking[](lockedLendingLength);
            unlockedStaking = new Staking[](unlockedStakingLength);
            lockedStaking = new Staking[](lockedStakingLength);
        }

        // unlockedLending = new Staking[](unlockedLendingLength);
        // lockedLending = new Staking[](lockedLendingLength);
        // unlockedStaking = new Staking[](unlockedStakingLength);
        // lockedStaking = new Staking[](lockedStakingLength);

        unlockedLendingLength = 0;
        lockedLendingLength = 0;
        unlockedStakingLength = 0;
        lockedStakingLength = 0;

        for (uint256 i = 0 ; i < allStakingsLength ; i++) {
            Staking memory staking = stabl3Staking.getStakings(_user, i);

            if (
                staking.status &&
                staking.isRealEstate == _isRealEstate
            ) {
                if (block.timestamp >= staking.startTime + stabl3Staking.lockTimes(staking.stakingType)) {
                    if (staking.isLending) {
                        unlockedLending[unlockedLendingLength] = staking;
                        unlockedLendingLength++;
                    }
                    else {
                        unlockedStaking[unlockedStakingLength] = staking;
                        unlockedStakingLength++;
                    }
                }
                else {
                    if (staking.isLending) {
                        if (stabl3Staking.emergencyState()) {
                            unlockedLending[unlockedLendingLength] = staking;
                            unlockedLendingLength++;
                        }
                        else {
                            lockedLending[lockedLendingLength] = staking;
                            lockedLendingLength++;
                        }
                        // lockedLending[lockedLendingLength] = staking;
                        // lockedLendingLength++;
                    }
                    else {
                        if (stabl3Staking.emergencyState()) {
                            unlockedStaking[unlockedStakingLength] = staking;
                            unlockedStakingLength++;
                        }
                        else {
                            lockedStaking[lockedStakingLength] = staking;
                            lockedStakingLength++;
                        }
                        // lockedStaking[lockedStakingLength] = staking;
                        // lockedStakingLength++;
                    }
                }
            }
        }
    }

    function getAmountRewardSingle(
        address _user,
        uint256 _index,
        bool _isLending,
        bool _isRealEstate,
        uint256 _timestamp
    ) public view returns (uint256) {
        uint256 amountReward;

        Staking memory staking = stabl3Staking.getStakings(_user, _index);

        uint256 endTime = staking.startTime + stabl3Staking.lockTimes(staking.stakingType);

        if (
            staking.status &&
            staking.isLending == _isLending &&
            staking.isRealEstate == _isRealEstate &&
            staking.rewardWithdrawTimeLast < endTime
        ) {
            // uint256 timestampToConsider = _timestamp > endTime ? endTime : _timestamp;
            uint256 timestampToConsider =
                stabl3Staking.emergencyState() ?
                stabl3Staking.emergencyTime() :
                    _timestamp > endTime ?
                    endTime :
                    _timestamp;

            // if (stabl3Staking.emergencyState()) {
            //     timestampToConsider = stabl3Staking.emergencyTime();
            // }
            // else {
            //     timestampToConsider = _timestamp > endTime ? endTime : _timestamp;
            // }

            uint256 numberOfDays = (timestampToConsider - staking.rewardWithdrawTimeLast) / oneDayTime;

            if (numberOfDays > 0) {
                uint256 timeWeightToConsider = (timestampToConsider - ROI.contractCreationTime()) / oneDayTime;

                TimeWeightedAPR memory timeWeightedAPR =
                    ROI.searchTimeWeightedAPR(staking.timeWeightedAPRLast.timeWeight, timeWeightToConsider);

                uint256 dAPR = (timeWeightedAPR.APR - staking.timeWeightedAPRLast.APR);
                uint256 dTimeWeight = (timeWeightedAPR.timeWeight - staking.timeWeightedAPRLast.timeWeight);

                uint256 ratio = dAPR / dTimeWeight;

                uint256 rewardTotal = _compoundSingle(staking.amountTokenStaked, ratio);

                amountReward += (rewardTotal * oneDayTime * numberOfDays) / oneYearTime;
            }
        }

        return amountReward;
    }

    function getAmountRewardAll(address _user, bool _isLending, bool _isRealEstate) external view returns (uint256) {
        uint256 totalAmountReward;

        uint256 timestampToConsider = block.timestamp;

        uint256 allStakingsLength = stabl3Staking.allStakingsLength(_user);

        for (uint256 i = 0 ; i < allStakingsLength ; i++) {
            Staking memory staking = stabl3Staking.getStakings(_user, i);

            if (
                staking.isLending == _isLending &&
                staking.isRealEstate == _isRealEstate
            ) {
                uint256 amountReward = getAmountRewardSingle(_user, i, _isLending,_isRealEstate, timestampToConsider);

                if (amountReward > 0) {
                    if (staking.token.decimals() < 18) {
                        amountReward *= (10 ** (18 - staking.token.decimals()));
                    }

                    totalAmountReward += amountReward;
                }
            }
        }

        return totalAmountReward;
    }

    function getClaimableStabl3LendingSingle(
        address _user,
        uint256 _index,
        uint256 _timestamp
    ) public view returns (uint256) {
        uint256 claimableStabl3Lending;

        Staking memory staking = stabl3Staking.getStakings(_user, _index);

        if (
            staking.status &&
            staking.isLending &&
            staking.amountStabl3Lending > 0 &&
            _timestamp > staking.startTime + stabl3Staking.lendingStabl3ClaimTime()
        ) {
            claimableStabl3Lending = staking.amountStabl3Lending;
        }

        return claimableStabl3Lending;
    }

    function getClaimableStabl3LendingAll(address _user) external view returns (uint256) {
        uint256 totalClaimableStabl3Lending;

        uint256 timestampToConsider = block.timestamp;

        uint256 allStakingsLength = stabl3Staking.allStakingsLength(_user);

        for (uint256 i = 0 ; i < allStakingsLength ; i++) {
            uint256 claimableStabl3Lending = getClaimableStabl3LendingSingle(_user, i, timestampToConsider);

            if (claimableStabl3Lending > 0) {
                totalClaimableStabl3Lending += claimableStabl3Lending;
            }
        }

        return totalClaimableStabl3Lending;
    }

    function getAmountStakedAll(
        address _user,
        bool _isLending,
        bool _isRealEstate
    ) external view returns (uint256 totalAmountStakedUnlocked, uint256 totalAmountStakedLocked) {
        Staking[] memory unlocked;
        Staking[] memory locked;

        if (_isLending) {
            (unlocked, locked, , ) = allStakings(_user, _isRealEstate);
        }
        else {
            (, , unlocked, locked) = allStakings(_user, _isRealEstate);
        }

        uint256 maxLength = unlocked.length.max(locked.length);

        for (uint256 i = 0 ; i < maxLength ; i++) {
            if (i < unlocked.length) {
                uint256 amountStakedUnlocked = unlocked[i].amountTokenStaked;

                if (unlocked[i].token.decimals() < 18) {
                    amountStakedUnlocked *= (10 ** (18 - unlocked[i].token.decimals()));
                }

                totalAmountStakedUnlocked += amountStakedUnlocked;
            }

            if (i < locked.length) {
                uint256 amountStakedLocked = locked[i].amountTokenStaked;

                if (locked[i].token.decimals() < 18) {
                    amountStakedLocked *= (10 ** (18 - locked[i].token.decimals()));
                }

                totalAmountStakedLocked += amountStakedLocked;
            }
        }
    }

    function _compoundSingle(uint256 _principal, uint256 _ratio) internal pure returns (uint256) {
        uint256 accruedAmount = _principal.mul(_ratio).div(10 ** 18);

        return accruedAmount;
    }
}