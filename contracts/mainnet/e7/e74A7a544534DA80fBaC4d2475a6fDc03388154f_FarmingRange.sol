// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
pragma solidity 0.8.17;

// contracts
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// libraries
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// interfaces
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import "./interfaces/IFarmingRange.sol";

/**
 * @title FarmingRange
 * @notice Farming Range allows users to stake LP Tokens to receive various rewards
 * @custom:from Contract taken from the alpaca protocol, adapted to version 0.8.17 and modified with more functions
 * @custom:url https://github.com/alpaca-finance/bsc-alpaca-contract/blob/main/solidity/contracts/6.12/GrazingRange.sol
 */
contract FarmingRange is IFarmingRange, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    mapping(uint256 => RewardInfo[]) public campaignRewardInfo;

    CampaignInfo[] public campaignInfo;
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    uint256 public rewardInfoLimit;
    address public rewardManager;

    constructor(address _rewardManager) {
        rewardInfoLimit = 52;
        rewardManager = _rewardManager;
    }

    /// @inheritdoc IFarmingRange
    function upgradePrecision() external onlyOwner {
        uint256 _length = campaignInfo.length;
        for (uint256 _pid = 0; _pid < _length; ++_pid) {
            campaignInfo[_pid].accRewardPerShare = campaignInfo[_pid].accRewardPerShare * 1e8;
        }
    }

    /// @inheritdoc IFarmingRange
    function setRewardManager(address _rewardManager) external onlyOwner {
        rewardManager = _rewardManager;
        emit SetRewardManager(_rewardManager);
    }

    /// @inheritdoc IFarmingRange
    function setRewardInfoLimit(uint256 _updatedRewardInfoLimit) external onlyOwner {
        rewardInfoLimit = _updatedRewardInfoLimit;
        emit SetRewardInfoLimit(rewardInfoLimit);
    }

    /// @inheritdoc IFarmingRange
    function addCampaignInfo(IERC20 _stakingToken, IERC20 _rewardToken, uint256 _startBlock) external onlyOwner {
        campaignInfo.push(
            CampaignInfo({
                stakingToken: _stakingToken,
                rewardToken: _rewardToken,
                startBlock: _startBlock,
                lastRewardBlock: _startBlock,
                accRewardPerShare: 0,
                totalStaked: 0,
                totalRewards: 0
            })
        );
        emit AddCampaignInfo(campaignInfo.length - 1, _stakingToken, _rewardToken, _startBlock);
    }

    /// @inheritdoc IFarmingRange
    function addRewardInfo(uint256 _campaignID, uint256 _endBlock, uint256 _rewardPerBlock) public onlyOwner {
        RewardInfo[] storage rewardInfo = campaignRewardInfo[_campaignID];
        CampaignInfo storage campaign = campaignInfo[_campaignID];
        require(
            rewardInfo.length < rewardInfoLimit,
            "FarmingRange::addRewardInfo::reward info length exceeds the limit"
        );
        require(
            rewardInfo.length == 0 || rewardInfo[rewardInfo.length - 1].endBlock >= block.number,
            "FarmingRange::addRewardInfo::reward period ended"
        );
        require(
            rewardInfo.length == 0 || rewardInfo[rewardInfo.length - 1].endBlock < _endBlock,
            "FarmingRange::addRewardInfo::bad new endblock"
        );
        uint256 _startBlock = rewardInfo.length == 0 ? campaign.startBlock : rewardInfo[rewardInfo.length - 1].endBlock;
        uint256 _blockRange = _endBlock - _startBlock;
        uint256 _totalRewards = _rewardPerBlock * _blockRange;
        _transferFromWithAllowance(campaign.rewardToken, _totalRewards, _campaignID);
        campaign.totalRewards = campaign.totalRewards + _totalRewards;
        rewardInfo.push(RewardInfo({ endBlock: _endBlock, rewardPerBlock: _rewardPerBlock }));
        emit AddRewardInfo(_campaignID, rewardInfo.length - 1, _endBlock, _rewardPerBlock);
    }

    /// @inheritdoc IFarmingRange
    function addRewardInfoMultiple(
        uint256 _campaignID,
        uint256[] calldata _endBlock,
        uint256[] calldata _rewardPerBlock
    ) external onlyOwner {
        require(_endBlock.length == _rewardPerBlock.length, "FarmingRange::addRewardMultiple::wrong parameters length");
        for (uint256 _i = 0; _i < _endBlock.length; _i++) {
            addRewardInfo(_campaignID, _endBlock[_i], _rewardPerBlock[_i]);
        }
    }

    /// @inheritdoc IFarmingRange
    function updateRewardInfo(
        uint256 _campaignID,
        uint256 _rewardIndex,
        uint256 _endBlock,
        uint256 _rewardPerBlock
    ) public onlyOwner {
        RewardInfo[] storage rewardInfo = campaignRewardInfo[_campaignID];
        CampaignInfo storage campaign = campaignInfo[_campaignID];
        RewardInfo storage selectedRewardInfo = rewardInfo[_rewardIndex];
        uint256 _previousEndBlock = selectedRewardInfo.endBlock;
        _updateCampaign(_campaignID);
        require(_previousEndBlock >= block.number, "FarmingRange::updateRewardInfo::reward period ended");
        if (_rewardIndex != 0) {
            require(
                rewardInfo[_rewardIndex - 1].endBlock < _endBlock,
                "FarmingRange::updateRewardInfo::bad new endblock"
            );
        }
        if (rewardInfo.length > _rewardIndex + 1) {
            require(
                _endBlock < rewardInfo[_rewardIndex + 1].endBlock,
                "FarmingRange::updateRewardInfo::reward period end is in next range"
            );
        }
        (bool _refund, uint256 _diff) = _updateRewardsDiff(
            _rewardIndex,
            _endBlock,
            _rewardPerBlock,
            rewardInfo,
            campaign,
            selectedRewardInfo
        );
        if (!_refund && _diff > 0) {
            _transferFromWithAllowance(campaign.rewardToken, _diff, _campaignID);
        }

        // If _endblock is changed, and if we have another range after the updated one,
        // we need to update rewardPerBlock to distribute on the next new range or we could run out of tokens
        if (_endBlock != _previousEndBlock && rewardInfo.length - 1 > _rewardIndex) {
            RewardInfo storage nextRewardInfo = rewardInfo[_rewardIndex + 1];
            uint256 _nextRewardInfoEndBlock = nextRewardInfo.endBlock;
            uint256 _initialBlockRange = _nextRewardInfoEndBlock - _previousEndBlock;
            uint256 _nextBlockRange = _nextRewardInfoEndBlock - _endBlock;
            uint256 _initialNextTotal = _initialBlockRange * nextRewardInfo.rewardPerBlock;
            nextRewardInfo.rewardPerBlock = (nextRewardInfo.rewardPerBlock * _initialBlockRange) / _nextBlockRange;
            uint256 _nextTotal = _nextBlockRange * nextRewardInfo.rewardPerBlock;
            if (_nextTotal < _initialNextTotal) {
                campaign.rewardToken.safeTransfer(rewardManager, _initialNextTotal - _nextTotal);
            }
        }
        // UPDATE total
        campaign.totalRewards = _refund ? campaign.totalRewards - _diff : campaign.totalRewards + _diff;
        selectedRewardInfo.endBlock = _endBlock;
        selectedRewardInfo.rewardPerBlock = _rewardPerBlock;
        emit UpdateRewardInfo(_campaignID, _rewardIndex, _endBlock, _rewardPerBlock);
    }

    /// @inheritdoc IFarmingRange
    function updateRewardMultiple(
        uint256 _campaignID,
        uint256[] memory _rewardIndex,
        uint256[] memory _endBlock,
        uint256[] memory _rewardPerBlock
    ) public onlyOwner {
        require(
            _rewardIndex.length == _endBlock.length && _rewardIndex.length == _rewardPerBlock.length,
            "FarmingRange::updateRewardMultiple::wrong parameters length"
        );
        for (uint256 _i = 0; _i < _rewardIndex.length; _i++) {
            updateRewardInfo(_campaignID, _rewardIndex[_i], _endBlock[_i], _rewardPerBlock[_i]);
        }
    }

    /// @inheritdoc IFarmingRange
    function updateCampaignsRewards(
        uint256[] calldata _campaignID,
        uint256[][] calldata _rewardIndex,
        uint256[][] calldata _endBlock,
        uint256[][] calldata _rewardPerBlock
    ) external onlyOwner {
        require(
            _campaignID.length == _rewardIndex.length &&
                _rewardIndex.length == _endBlock.length &&
                _rewardIndex.length == _rewardPerBlock.length,
            "FarmingRange::updateCampaignsRewards::wrong rewardInfo length"
        );
        for (uint256 _i = 0; _i < _campaignID.length; _i++) {
            updateRewardMultiple(_campaignID[_i], _rewardIndex[_i], _endBlock[_i], _rewardPerBlock[_i]);
        }
    }

    /// @inheritdoc IFarmingRange
    function removeLastRewardInfo(uint256 _campaignID) external onlyOwner {
        RewardInfo[] storage rewardInfo = campaignRewardInfo[_campaignID];
        CampaignInfo storage campaign = campaignInfo[_campaignID];
        uint256 _rewardInfoLength = rewardInfo.length;
        require(_rewardInfoLength > 0, "FarmingRange::updateCampaignsRewards::no rewardInfoLen");
        RewardInfo storage lastRewardInfo = rewardInfo[_rewardInfoLength - 1];
        uint256 _lastRewardInfoEndBlock = lastRewardInfo.endBlock;
        require(_lastRewardInfoEndBlock > block.number, "FarmingRange::removeLastRewardInfo::reward period ended");
        _updateCampaign(_campaignID);
        if (lastRewardInfo.rewardPerBlock != 0) {
            (bool _refund, uint256 _diff) = _updateRewardsDiff(
                _rewardInfoLength - 1,
                block.number > _lastRewardInfoEndBlock ? block.number : _lastRewardInfoEndBlock,
                0,
                rewardInfo,
                campaign,
                lastRewardInfo
            );
            if (_refund) {
                campaign.totalRewards = campaign.totalRewards - _diff;
            }
        }
        rewardInfo.pop();
        emit RemoveRewardInfo(_campaignID, _rewardInfoLength - 1);
    }

    /// @inheritdoc IFarmingRange
    function rewardInfoLen(uint256 _campaignID) external view returns (uint256) {
        return campaignRewardInfo[_campaignID].length;
    }

    /// @inheritdoc IFarmingRange
    function campaignInfoLen() external view returns (uint256) {
        return campaignInfo.length;
    }

    /// @inheritdoc IFarmingRange
    function currentEndBlock(uint256 _campaignID) external view returns (uint256) {
        return _endBlockOf(_campaignID, block.number);
    }

    /// @inheritdoc IFarmingRange
    function currentRewardPerBlock(uint256 _campaignID) external view returns (uint256) {
        return _rewardPerBlockOf(_campaignID, block.number);
    }

    /// @inheritdoc IFarmingRange
    function getMultiplier(uint256 _from, uint256 _to, uint256 _endBlock) public pure returns (uint256) {
        if ((_from >= _endBlock) || (_from > _to)) {
            return 0;
        }
        if (_to <= _endBlock) {
            return _to - _from;
        }
        return _endBlock - _from;
    }

    /// @inheritdoc IFarmingRange
    function pendingReward(uint256 _campaignID, address _user) external view returns (uint256) {
        return
            _pendingReward(_campaignID, userInfo[_campaignID][_user].amount, userInfo[_campaignID][_user].rewardDebt);
    }

    /// @inheritdoc IFarmingRange
    function updateCampaign(uint256 _campaignID) external nonReentrant {
        _updateCampaign(_campaignID);
    }

    /// @inheritdoc IFarmingRange
    function massUpdateCampaigns() external nonReentrant {
        uint256 _length = campaignInfo.length;
        for (uint256 _pid = 0; _pid < _length; ++_pid) {
            _updateCampaign(_pid);
        }
    }

    /// @inheritdoc IFarmingRange
    function deposit(uint256 _campaignID, uint256 _amount) public nonReentrant {
        CampaignInfo storage campaign = campaignInfo[_campaignID];
        UserInfo storage user = userInfo[_campaignID][msg.sender];
        _updateCampaign(_campaignID);
        if (user.amount > 0) {
            uint256 _pending = (user.amount * campaign.accRewardPerShare) / 1e20 - user.rewardDebt;
            if (_pending > 0) {
                campaign.rewardToken.safeTransfer(address(msg.sender), _pending);
            }
        }
        if (_amount > 0) {
            campaign.stakingToken.safeTransferFrom(msg.sender, address(this), _amount);
            user.amount = user.amount + _amount;
            campaign.totalStaked = campaign.totalStaked + _amount;
        }
        user.rewardDebt = (user.amount * campaign.accRewardPerShare) / (1e20);
        emit Deposit(msg.sender, _amount, _campaignID);
    }

    /// @inheritdoc IFarmingRange
    function depositWithPermit(
        uint256 _campaignID,
        uint256 _amount,
        bool _approveMax,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        SafeERC20.safePermit(
            IERC20Permit(address(campaignInfo[_campaignID].stakingToken)),
            msg.sender,
            address(this),
            _approveMax ? type(uint256).max : _amount,
            _deadline,
            _v,
            _r,
            _s
        );

        deposit(_campaignID, _amount);
    }

    /// @inheritdoc IFarmingRange
    function withdraw(uint256 _campaignID, uint256 _amount) external nonReentrant {
        _withdraw(_campaignID, _amount);
    }

    /// @inheritdoc IFarmingRange
    function harvest(uint256[] calldata _campaignIDs) external nonReentrant {
        for (uint256 _i = 0; _i < _campaignIDs.length; ++_i) {
            _withdraw(_campaignIDs[_i], 0);
        }
    }

    /// @inheritdoc IFarmingRange
    function emergencyWithdraw(uint256 _campaignID) external nonReentrant {
        CampaignInfo storage campaign = campaignInfo[_campaignID];
        UserInfo storage user = userInfo[_campaignID][msg.sender];
        uint256 _amount = user.amount;
        campaign.totalStaked = campaign.totalStaked - _amount;
        user.amount = 0;
        user.rewardDebt = 0;
        campaign.stakingToken.safeTransfer(msg.sender, _amount);
        emit EmergencyWithdraw(msg.sender, _amount, _campaignID);
    }

    /**
     * @notice return the endblock of the phase that contains _blockNumber
     * @param _campaignID the campaign id of the phases to check
     * @param _blockNumber the block number to check
     * @return the endblock of the phase that contains _blockNumber
     */
    function _endBlockOf(uint256 _campaignID, uint256 _blockNumber) internal view returns (uint256) {
        RewardInfo[] memory rewardInfo = campaignRewardInfo[_campaignID];
        uint256 _len = rewardInfo.length;
        if (_len == 0) {
            return 0;
        }
        for (uint256 _i = 0; _i < _len; ++_i) {
            if (_blockNumber <= rewardInfo[_i].endBlock) return rewardInfo[_i].endBlock;
        }
        /// @dev when couldn't find any reward info, it means that _blockNumber exceed endblock
        /// so return the latest reward info.
        return rewardInfo[_len - 1].endBlock;
    }

    /**
     * @notice return the rewardPerBlock of the phase that contains _blockNumber
     * @param _campaignID the campaign id of the phases to check
     * @param _blockNumber the block number to check
     * @return the rewardPerBlock of the phase that contains _blockNumber
     */
    function _rewardPerBlockOf(uint256 _campaignID, uint256 _blockNumber) internal view returns (uint256) {
        RewardInfo[] memory rewardInfo = campaignRewardInfo[_campaignID];
        uint256 _len = rewardInfo.length;
        if (_len == 0) {
            return 0;
        }
        for (uint256 _i = 0; _i < _len; ++_i) {
            if (_blockNumber <= rewardInfo[_i].endBlock) return rewardInfo[_i].rewardPerBlock;
        }
        /// @dev when couldn't find any reward info, it means that timestamp exceed endblock
        /// so return 0
        return 0;
    }

    /**
     * @notice in case of reward update, return reward diff and refund user if needed
     * @param _rewardIndex the number of the phase to update
     * @param _endBlock new endblock of the phase
     * @param _rewardPerBlock new rewardPerBlock of the phase
     * @param rewardInfo pointer on the array of rewardInfo in storage
     * @param campaign pointer on the campaign in storage
     * @param selectedRewardInfo pointer on the selectedRewardInfo in storage
     * @return refund_ boolean, true if user got refund
     * @return diff_ the reward difference
     */
    function _updateRewardsDiff(
        uint256 _rewardIndex,
        uint256 _endBlock,
        uint256 _rewardPerBlock,
        RewardInfo[] storage rewardInfo,
        CampaignInfo storage campaign,
        RewardInfo storage selectedRewardInfo
    ) internal returns (bool refund_, uint256 diff_) {
        uint256 _previousStartBlock = _rewardIndex == 0 ? campaign.startBlock : rewardInfo[_rewardIndex - 1].endBlock;
        uint256 _newStartBlock = block.number > _previousStartBlock ? block.number : _previousStartBlock;
        uint256 _previousBlockRange = selectedRewardInfo.endBlock - _previousStartBlock;
        uint256 _newBlockRange = _endBlock - _newStartBlock;
        uint256 _selectedRewardPerBlock = selectedRewardInfo.rewardPerBlock;
        uint256 _accumulatedRewards = (_newStartBlock - _previousStartBlock) * _selectedRewardPerBlock;
        uint256 _previousTotalRewards = _selectedRewardPerBlock * _previousBlockRange;
        uint256 _totalRewards = _rewardPerBlock * _newBlockRange;
        refund_ = _previousTotalRewards > _totalRewards + _accumulatedRewards;
        diff_ = refund_
            ? _previousTotalRewards - _totalRewards - _accumulatedRewards
            : _totalRewards + _accumulatedRewards - _previousTotalRewards;
        if (refund_) {
            campaign.rewardToken.safeTransfer(rewardManager, diff_);
        }
    }

    /**
     * @notice transfer tokens from rewardManger to this contract.
     * @param _rewardToken to reward token to be transfered from the rewwardmanager to this contract
     * @param _amount qty to be transfered
     * @param _campaignID id of the campaign so the rewardManager can fetch the rewardToken address to transfer
     *
     * @dev in case of fail, not enough allowance is considered to be the reason, so we call resetAllowance(uint256) on
     * the reward manager (which will reset allowance to uint256.max) and we try again to transfer
     */
    function _transferFromWithAllowance(IERC20 _rewardToken, uint256 _amount, uint256 _campaignID) internal {
        try _rewardToken.transferFrom(rewardManager, address(this), _amount) {} catch {
            rewardManager.call(abi.encodeWithSignature("resetAllowance(uint256)", _campaignID));
            _rewardToken.safeTransferFrom(rewardManager, address(this), _amount);
        }
    }

    /**
     * @notice View function to retrieve pending Reward.
     * @param _campaignID pending reward of campaign id
     * @param _amount qty of staked token
     * @param _rewardDebt user info rewardDebt
     * @return pending rewards
     */
    function _pendingReward(uint256 _campaignID, uint256 _amount, uint256 _rewardDebt) internal view returns (uint256) {
        CampaignInfo memory _campaign = campaignInfo[_campaignID];
        RewardInfo[] memory _rewardInfo = campaignRewardInfo[_campaignID];
        uint256 _accRewardPerShare = _campaign.accRewardPerShare;
        if (block.number > _campaign.lastRewardBlock && _campaign.totalStaked != 0) {
            uint256 _cursor = _campaign.lastRewardBlock;
            for (uint256 _i = 0; _i < _rewardInfo.length; ++_i) {
                uint256 _multiplier = getMultiplier(_cursor, block.number, _rewardInfo[_i].endBlock);
                if (_multiplier == 0) continue;
                _cursor = _rewardInfo[_i].endBlock;
                _accRewardPerShare =
                    _accRewardPerShare +
                    ((_multiplier * _rewardInfo[_i].rewardPerBlock * 1e20) / _campaign.totalStaked);
            }
        }
        return ((_amount * _accRewardPerShare) / 1e20) - _rewardDebt;
    }

    /**
     * @notice Update reward variables of the given campaign to be up-to-date.
     * @param _campaignID campaign id
     */
    function _updateCampaign(uint256 _campaignID) internal {
        CampaignInfo storage campaign = campaignInfo[_campaignID];
        RewardInfo[] memory _rewardInfo = campaignRewardInfo[_campaignID];
        if (block.number <= campaign.lastRewardBlock) {
            return;
        }
        if (campaign.totalStaked == 0) {
            // if there is no total supply, return and use the campaign's start block as the last reward block
            // so that ALL reward will be distributed.
            // however, if the first deposit is out of reward period, last reward block will be its block number
            // in order to keep the multiplier = 0
            if (block.number > _endBlockOf(_campaignID, block.number)) {
                campaign.lastRewardBlock = block.number;
            }
            return;
        }
        /// @dev for each reward info
        for (uint256 _i = 0; _i < _rewardInfo.length; ++_i) {
            // @dev get multiplier based on current Block and rewardInfo's end block
            // multiplier will be a range of either (current block - campaign.lastRewardBlock)
            // or (reward info's endblock - campaign.lastRewardBlock) or 0
            uint256 _multiplier = getMultiplier(campaign.lastRewardBlock, block.number, _rewardInfo[_i].endBlock);
            if (_multiplier == 0) continue;
            // @dev if currentBlock exceed end block, use end block as the last reward block
            // so that for the next iteration, previous endBlock will be used as the last reward block
            if (block.number > _rewardInfo[_i].endBlock) {
                campaign.lastRewardBlock = _rewardInfo[_i].endBlock;
            } else {
                campaign.lastRewardBlock = block.number;
            }
            campaign.accRewardPerShare =
                campaign.accRewardPerShare +
                ((_multiplier * _rewardInfo[_i].rewardPerBlock * 1e20) / campaign.totalStaked);
        }
    }

    /**
     * @notice Withdraw staking token in a campaign. Also withdraw the current pending reward
     * @param _campaignID campaign id
     * @param _amount amount to withdraw
     */
    function _withdraw(uint256 _campaignID, uint256 _amount) internal {
        CampaignInfo storage campaign = campaignInfo[_campaignID];
        UserInfo storage user = userInfo[_campaignID][msg.sender];
        require(user.amount >= _amount, "FarmingRange::withdraw::bad withdraw amount");
        _updateCampaign(_campaignID);
        uint256 _pending = (user.amount * campaign.accRewardPerShare) / 1e20 - user.rewardDebt;
        if (_pending > 0) {
            campaign.rewardToken.safeTransfer(msg.sender, _pending);
        }
        if (_amount > 0) {
            user.amount = user.amount - _amount;
            campaign.stakingToken.safeTransfer(msg.sender, _amount);
            campaign.totalStaked = campaign.totalStaked - _amount;
        }
        user.rewardDebt = (user.amount * campaign.accRewardPerShare) / 1e20;

        emit Withdraw(msg.sender, _amount, _campaignID);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// interfaces
import "@openzeppelin/contracts/interfaces/IERC20.sol";

interface IFarmingRange {
    /**
     * @notice Info of each user.
     * @param amount How many Staking tokens the user has provided.
     * @param rewardDebt We do some fancy math here. Basically, any point in time, the amount of reward
     *  entitled to a user but is pending to be distributed is:
     *
     *    pending reward = (user.amount * pool.accRewardPerShare) - user.rewardDebt
     *
     *  Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
     *    1. The pool's `accRewardPerShare` (and `lastRewardBlock`) gets updated.
     *    2. User receives the pending reward sent to his/her address.
     *    3. User's `amount` gets updated.
     *    4. User's `rewardDebt` gets updated.
     *
     * from: https://github.com/jazz-defi/contracts/blob/master/MasterChefV2.sol
     */
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    /**
     * @notice Info of each reward distribution campaign.
     * @param stakingToken address of Staking token contract.
     * @param rewardToken address of Reward token contract
     * @param startBlock start block of the campaign
     * @param lastRewardBlock last block number that Reward Token distribution occurs.
     * @param accRewardPerShare accumulated Reward Token per share, times 1e20.
     * @param totalStaked total staked amount each campaign's stake token, typically,
     * @param totalRewards total amount of reward to be distributed until the end of the last phase
     *
     * @dev each campaign has the same stake token, so no need to track it separetely
     */
    struct CampaignInfo {
        IERC20 stakingToken;
        IERC20 rewardToken;
        uint256 startBlock;
        uint256 lastRewardBlock;
        uint256 accRewardPerShare;
        uint256 totalStaked;
        uint256 totalRewards;
    }

    /**
     * @notice Info about a reward-phase
     * @param endBlock block number of the end of the phase
     * @param rewardPerBlock amount of reward to be distributed per block in this phase
     */
    struct RewardInfo {
        uint256 endBlock;
        uint256 rewardPerBlock;
    }

    /**
     * @notice emitted at each deposit
     * @param user address that deposit its funds
     * @param amount amount deposited
     * @param campaign campaingId on which the user has deposited funds
     */
    event Deposit(address indexed user, uint256 amount, uint256 campaign);

    /**
     * @notice emitted at each withdraw
     * @param user address that withdrawn its funds
     * @param amount amount withdrawn
     * @param campaign campaingId on which the user has withdrawn funds
     */
    event Withdraw(address indexed user, uint256 amount, uint256 campaign);

    /**
     * @notice emitted at each emergency withdraw
     * @param user address that emergency-withdrawn its funds
     * @param amount amount emergency-withdrawn
     * @param campaign campaingId on which the user has emergency-withdrawn funds
     */
    event EmergencyWithdraw(address indexed user, uint256 amount, uint256 campaign);

    /**
     * @notice emitted at each campaign added
     * @param campaignID new campaign id
     * @param stakingToken token address to be staked in this campaign
     * @param rewardToken token address of the rewards in this campaign
     * @param startBlock starting block of this campaign
     */
    event AddCampaignInfo(uint256 indexed campaignID, IERC20 stakingToken, IERC20 rewardToken, uint256 startBlock);

    /**
     * @notice emitted at each phase of reward added
     * @param campaignID campaign id on which rewards were added
     * @param phase number of the new phase added (latest at the moment of add)
     * @param endBlock number of the block that the phase stops (phase starts at the endblock of the previous phase's
     * endblock, and if it's the phase 0, it start at the startBlock of the campaign struct)
     * @param rewardPerBlock amount of reward distributed per block in this phase
     */
    event AddRewardInfo(uint256 indexed campaignID, uint256 indexed phase, uint256 endBlock, uint256 rewardPerBlock);

    /**
     * @notice emitted when a reward phase is updated
     * @param campaignID campaign id on which the rewards-phase is updated
     * @param phase id of phase updated
     * @param endBlock new endblock of the phase
     * @param rewardPerBlock new rewardPerBlock of the phase
     */
    event UpdateRewardInfo(uint256 indexed campaignID, uint256 indexed phase, uint256 endBlock, uint256 rewardPerBlock);

    /**
     * @notice emitted when a reward phase is removed
     * @param campaignID campaign id on which the rewards-phase is removed
     * @param phase id of phase removed (only the latest phase can be removed)
     */
    event RemoveRewardInfo(uint256 indexed campaignID, uint256 indexed phase);

    /**
     * @notice emitted when the rewardInfoLimit is updated
     * @param rewardInfoLimit new max phase amount per campaign
     */
    event SetRewardInfoLimit(uint256 rewardInfoLimit);

    /**
     * @notice emitted when the rewardManager is changed
     * @param rewardManager address of the new rewardManager
     */
    event SetRewardManager(address rewardManager);

    /**
     * @notice increase precision of accRewardPerShare in all campaign
     */
    function upgradePrecision() external;

    /**
     * @notice set the reward manager, responsible for adding rewards
     * @param _rewardManager address of the reward manager
     */
    function setRewardManager(address _rewardManager) external;

    /**
     * @notice set new reward info limit, defining how many phases are allowed
     * @param _updatedRewardInfoLimit new reward info limit
     */
    function setRewardInfoLimit(uint256 _updatedRewardInfoLimit) external;

    /**
     * @notice reward campaign, one campaign represent a pair of staking and reward token,
     * last reward Block and acc reward Per Share
     * @param _stakingToken staking token address
     * @param _rewardToken reward token address
     * @param _startBlock block number when the campaign will start
     */
    function addCampaignInfo(IERC20 _stakingToken, IERC20 _rewardToken, uint256 _startBlock) external;

    /**
     * @notice add a nex reward info, when a new reward info is added, the reward
     * & its end block will be extended by the newly pushed reward info.
     * @param _campaignID id of the campaign
     * @param _endBlock end block of this reward info
     * @param _rewardPerBlock reward per block to distribute until the end
     */
    function addRewardInfo(uint256 _campaignID, uint256 _endBlock, uint256 _rewardPerBlock) external;

    /**
     * @notice add multiple reward Info into a campaign in one tx.
     * @param _campaignID id of the campaign
     * @param _endBlock array of end blocks
     * @param _rewardPerBlock array of reward per block
     */
    function addRewardInfoMultiple(
        uint256 _campaignID,
        uint256[] calldata _endBlock,
        uint256[] calldata _rewardPerBlock
    ) external;

    /**
     * @notice update one campaign reward info for a specified range index.
     * @param _campaignID id of the campaign
     * @param _rewardIndex index of the reward info
     * @param _endBlock end block of this reward info
     * @param _rewardPerBlock reward per block to distribute until the end
     */
    function updateRewardInfo(
        uint256 _campaignID,
        uint256 _rewardIndex,
        uint256 _endBlock,
        uint256 _rewardPerBlock
    ) external;

    /**
     * @notice update multiple campaign rewards info for all range index.
     * @param _campaignID id of the campaign
     * @param _rewardIndex array of reward info index
     * @param _endBlock array of end block
     * @param _rewardPerBlock array of rewardPerBlock
     */
    function updateRewardMultiple(
        uint256 _campaignID,
        uint256[] memory _rewardIndex,
        uint256[] memory _endBlock,
        uint256[] memory _rewardPerBlock
    ) external;

    /**
     * @notice update multiple campaigns and rewards info for all range index.
     * @param _campaignID array of campaign id
     * @param _rewardIndex multi dimensional array of reward info index
     * @param _endBlock multi dimensional array of end block
     * @param _rewardPerBlock multi dimensional array of rewardPerBlock
     */
    function updateCampaignsRewards(
        uint256[] calldata _campaignID,
        uint256[][] calldata _rewardIndex,
        uint256[][] calldata _endBlock,
        uint256[][] calldata _rewardPerBlock
    ) external;

    /**
     * @notice remove last reward info for specified campaign.
     * @param _campaignID campaign id
     */
    function removeLastRewardInfo(uint256 _campaignID) external;

    /**
     * @notice return the entries amount of reward info for one campaign.
     * @param _campaignID campaign id
     * @return reward info quantity
     */
    function rewardInfoLen(uint256 _campaignID) external view returns (uint256);

    /**
     * @notice return the number of campaigns.
     * @return campaign quantity
     */
    function campaignInfoLen() external view returns (uint256);

    /**
     * @notice return the end block of the current reward info for a given campaign.
     * @param _campaignID campaign id
     * @return reward info end block number
     */
    function currentEndBlock(uint256 _campaignID) external view returns (uint256);

    /**
     * @notice return the reward per block of the current reward info for a given campaign.
     * @param _campaignID campaign id
     * @return current reward per block
     */
    function currentRewardPerBlock(uint256 _campaignID) external view returns (uint256);

    /**
     * @notice Return reward multiplier over the given _from to _to block.
     * Reward multiplier is the amount of blocks between from and to
     * @param _from start block number
     * @param _to end block number
     * @param _endBlock end block number of the reward info
     * @return block distance
     */
    function getMultiplier(uint256 _from, uint256 _to, uint256 _endBlock) external returns (uint256);

    /**
     * @notice View function to retrieve pending Reward.
     * @param _campaignID pending reward of campaign id
     * @param _user address to retrieve pending reward
     * @return current pending reward
     */
    function pendingReward(uint256 _campaignID, address _user) external view returns (uint256);

    /**
     * @notice Update reward variables of the given campaign to be up-to-date.
     * @param _campaignID campaign id
     */
    function updateCampaign(uint256 _campaignID) external;

    /**
     * @notice Update reward variables for all campaigns. gas spending is HIGH in this method call, BE CAREFUL.
     */
    function massUpdateCampaigns() external;

    /**
     * @notice Deposit staking token in a campaign.
     * @param _campaignID campaign id
     * @param _amount amount to deposit
     */
    function deposit(uint256 _campaignID, uint256 _amount) external;

    /**
     * @notice Deposit staking token in a campaign with the EIP-2612 signature off chain
     * @param _campaignID campaign id
     * @param _amount amount to deposit
     * @param _approveMax Whether or not the approval amount in the signature is for liquidity or uint(-1).
     * @param _deadline Unix timestamp after which the transaction will revert.
     * @param _v The v component of the permit signature.
     * @param _r The r component of the permit signature.
     * @param _s The s component of the permit signature.
     */
    function depositWithPermit(
        uint256 _campaignID,
        uint256 _amount,
        bool _approveMax,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    /**
     * @notice Withdraw staking token in a campaign. Also withdraw the current pending reward
     * @param _campaignID campaign id
     * @param _amount amount to withdraw
     */
    function withdraw(uint256 _campaignID, uint256 _amount) external;

    /**
     * @notice Harvest campaigns, will claim rewards token of every campaign ids in the array
     * @param _campaignIDs array of campaign id
     */
    function harvest(uint256[] calldata _campaignIDs) external;

    /**
     * @notice Withdraw without caring about rewards. EMERGENCY ONLY.
     * @param _campaignID campaign id
     */
    function emergencyWithdraw(uint256 _campaignID) external;

    /**
     * @notice get Reward info for a campaign ID and index, that is a set of {endBlock, rewardPerBlock}
     *  indexed by campaign ID
     * @param _campaignID campaign id
     * @param _rewardIndex index of the reward info
     * @return endBlock_ end block of this reward info
     * @return rewardPerBlock_ reward per block to distribute
     */
    function campaignRewardInfo(
        uint256 _campaignID,
        uint256 _rewardIndex
    ) external view returns (uint256 endBlock_, uint256 rewardPerBlock_);

    /**
     * @notice get a Campaign Reward info for a campaign ID
     * @param _campaignID campaign id
     * @return all params from CampaignInfo struct
     */
    function campaignInfo(
        uint256 _campaignID
    ) external view returns (IERC20, IERC20, uint256, uint256, uint256, uint256, uint256);

    /**
     * @notice get a User Reward info for a campaign ID and user address
     * @param _campaignID campaign id
     * @param _user user address
     * @return all params from UserInfo struct
     */
    function userInfo(uint256 _campaignID, address _user) external view returns (uint256, uint256);

    /**
     * @notice how many reward phases can be set for a campaign
     * @return rewards phases size limit
     */
    function rewardInfoLimit() external view returns (uint256);

    /**
     * @notice get reward Manager address holding rewards to distribute
     * @return address of reward manager
     */
    function rewardManager() external view returns (address);
}