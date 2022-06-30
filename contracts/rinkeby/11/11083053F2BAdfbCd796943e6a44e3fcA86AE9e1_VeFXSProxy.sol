pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IveFXS {
    struct LockedBalance {
        int128 amount;
        uint256 end;
    }
    function create_lock(uint256 _value, uint256 _unlock_time) external;
    function increase_amount(uint256 _value) external;
    function increase_unlock_time(uint256 _unlock_time) external;
    function withdraw() external;
    function balanceOf(address addr, uint256 _t) external view returns (uint256);
    function totalSupply(uint256 t) external view returns (uint256);
    function totalFXSSupply() external  view returns (uint256);
    function locked(address addr) external view returns (LockedBalance memory);
    function token() external view returns (address);
}

interface IGaugeController {
    function vote_for_gauge_weights(address _gauge_addr, uint256 _user_weight) external;
}

interface IUnifiedFarm {
    function proxyToggleStaker(address staker_address) external;
}

interface IYieldDistributor {
   function checkpoint() external;
   function getYield() external;
}

contract VeFXSProxy is Ownable {
    using SafeERC20 for IERC20;

    /// @dev The underlying veFXS contract which STAX is locking into.
    IveFXS public immutable veFXS;

    /// @dev The underlying token being locked.
    IERC20 public immutable fxsToken;

    /// @dev Ability to vote for a gauge using STAX's veFXS balance
    IGaugeController public gaugeController;

    /// @dev Checkpoint and claim veFXS yield
    IYieldDistributor public yieldDistributor;

    /// @dev A set of addresses which are approved to create/update/withdraw the STAX veFXS holdings.
    mapping(address => bool) public opsManagers;

    event GaugeControllerSet(address gaugeController);
    event YieldDistributorSet(address yieldDistributor);
    event ApprovedOpsManager(address opsManager, bool approved);
    event TokenRecovered(address user, uint256 amount);
    event WithdrawnTo(address to, uint256 amount);
    event GaugeProxyToggledStaker(address gaugeAddress, address stakerAddress);
    event YieldClaimed(address user, uint256 yield, address token_address);

    constructor(address _veFXS, address _gaugeController, address _yieldDistributor) {
        veFXS = IveFXS(_veFXS);
        fxsToken = IERC20(IveFXS(_veFXS).token());
        gaugeController = IGaugeController(_gaugeController);
        yieldDistributor = IYieldDistributor(_yieldDistributor);
    }

    /** 
      * @dev The FRAX gauge controller is upgraded from time to time.
      */
    function setGaugeController(address _gaugeController) external onlyOwner {
        require(_gaugeController != address(0), "!address");
        gaugeController = IGaugeController(_gaugeController);
        emit GaugeControllerSet(_gaugeController);
    }

    /** 
      * @dev The FRAX veFXS yield distributor contract - and is upgraded from time to time.
      */
    function setYieldDistributor(address _yieldDistributor) external onlyOwner {
        require(_yieldDistributor != address(0), "!address");
        yieldDistributor = IYieldDistributor(_yieldDistributor);
        emit YieldDistributorSet(_yieldDistributor);
    }

    /** 
      * @notice Approve/Unapprove an address as being an operations manager.
      *         The ops Manager is permissioned to add/extend/withdraw the veFXS locks
      *         on STAX behalf.
      * @param _opsManager The address to approve
      * @param _approved Whether to approve/unapprove the address.s
      */
    function approveOpsManager(
        address _opsManager,
        bool _approved
    ) external onlyOwner {
        opsManagers[_opsManager] = _approved;
        emit ApprovedOpsManager(_opsManager, _approved);
    }

    /** 
      * @notice Deposit `_value` tokens for STAX and lock until `_unlock_time`
      *         without modifying the unlock time
      * @param _value Amount to deposit
      * @param _unlock_time Epoch time when tokens unlock, rounded down to whole weeks
      */
    function createLock(uint256 _value, uint256 _unlock_time) external onlyOwnerOrOpsManager {
        // Pull FXS
        fxsToken.safeTransferFrom(msg.sender, address(this), _value);

        // Increase allowance then create lock
        fxsToken.safeIncreaseAllowance(address(veFXS), _value);
        veFXS.create_lock(_value, _unlock_time);
    }

    /** 
      * @notice Deposit `_value` additional tokens for STAX
      *         without modifying the unlock time
      */
    function increaseAmount(uint256 _value) external onlyOwnerOrOpsManager {
        // Pull FXS
        fxsToken.safeTransferFrom(msg.sender, address(this), _value);

        // Increase allowance then increase the lock amount
        fxsToken.safeIncreaseAllowance(address(veFXS), _value);
        veFXS.increase_amount(_value);
    }

    /** 
      * @notice Extend the unlock time for STAX to `_unlock_time`
      * @param _unlock_time New epoch time for unlocking
      */
    function increaseUnlockTime(uint256 _unlock_time) external onlyOwnerOrOpsManager {
        veFXS.increase_unlock_time(_unlock_time);
    }

    /**
      * @notice Allocate voting power for changing pool weights, using STAX's veFXS balance. 
      * @dev _gauges and _weights must be the same size.
      * @param _gauges Set of gauges that STAX votes for.
      * @param _weights Weights for gauges in bps (units of 0.01%). Minimal is 0.01%. Ignored if 0
      */
    function voteGaugeWeights(address[] calldata _gauges, uint256[] calldata _weights) external onlyOwnerOrOpsManager {
        require(_gauges.length == _weights.length, "!gauge weights");
        for (uint256 i = 0; i < _gauges.length;) {
            gaugeController.vote_for_gauge_weights(_gauges[i], _weights[i]);
            unchecked{ ++i; }
        }
    }

    /** 
      * @notice Withdraw all tokens for STAX and send to recipient
      * @dev Only possible if the lock has expired
      */
    function withdrawTo(address _to) external onlyOwnerOrOpsManager {
        // Pull the lock amount (and convert to uint256)
        uint256 lockedAmount = uint128(veFXS.locked(address(this)).amount);

        // Withdraw the FXS, and transfer.
        veFXS.withdraw();
        _transferToken(fxsToken, _to, lockedAmount);

        // An extra event here to also report the account it's sent to.
        emit WithdrawnTo(_to, lockedAmount);
    }

    /**
      * @notice Checkpoint for the veFXS yield
      */
    function checkpointYield() external {
        yieldDistributor.checkpoint();
    }

    /**
      * @notice Claim the yield from the veFXS yield distributor, and disburse to a given address.
      * @return the amount of _token cliamed.
      */
    function claimYield(address _yieldToken, address _claimTo) external onlyOwnerOrOpsManager returns (uint256) {
        yieldDistributor.getYield();
        uint256 _balance = IERC20(_yieldToken).balanceOf(address(this));
        if (_balance > 0) {
          IERC20(_yieldToken).safeTransfer(_claimTo, _balance);
          emit YieldClaimed(_claimTo, _balance, _yieldToken);
        }
        return _balance;
    }

    /** 
      * @notice Get the current voting power for STAX, as of now.
      * @return User voting power
      */
    function veFXSBalance() external view returns (uint256) {
        return veFXS.balanceOf(address(this), block.timestamp);
    }

    /** 
      * @notice Calculate total veFXS voting power, as of now.
      * @return Total voting power
      */
    function totalVeFXSSupply() external view returns (uint256) {
        return veFXS.totalSupply(block.timestamp);
    }

    /** 
      * @notice Calculate FXS supply within veFXS
      * @return Total FXS supply
      */
    function totalFXSSupply() external view returns (uint256) {
        return veFXS.totalFXSSupply();
    }

    /** 
      * @notice STAX's current lock
      * @dev Will revert if no lock has been added yet.
      * @return LockedBalance
      */
    function locked() external view returns (IveFXS.LockedBalance memory) {
        return veFXS.locked(address(this));
    }

    // recover tokens
    function recoverToken(address _token, address _to, uint256 _amount) external onlyOwner {
        _transferToken(IERC20(_token), _to, _amount);
        emit TokenRecovered(_to, _amount);
    }

    function _transferToken(IERC20 _token, address _to, uint256 _amount) internal {
        uint256 balance = _token.balanceOf(address(this));
        require(_amount <= balance, "not enough tokens");
        _token.safeTransfer(_to, _amount);
    }

    /**
      * @dev Allow STAX's veFXS balance in this contract to be used for the gauge boost
      *      of STAX's liquidity ops contract managing the gauge locks.
      * @notice gauge.toggleValidVeFXSProxy(address _proxy_addr) needs to be called by Frax Gov first.
      * @param _gaugeAddress The address of the gauge to whitelist this as a valid proxy
      * @param _stakerAddress The address of the gauge staking contract (STAX's liquidity ops)
      */
    function gaugeProxyToggleStaker(address _gaugeAddress, address _stakerAddress) external onlyOwnerOrOpsManager {
      IUnifiedFarm(_gaugeAddress).proxyToggleStaker(_stakerAddress);
      emit GaugeProxyToggledStaker(_gaugeAddress, _stakerAddress);
    }

    /**
      * @notice execute arbitrary functions
      * @dev OpsManagers are allowed to execute, as FRAX may add extra features/contracts in the future which
      *      requires intraction from this whitelisted contract.
      */
    function execute(address _to, uint256 _value, bytes calldata _data) external onlyOwnerOrOpsManager returns (bytes memory) {
      (bool success, bytes memory returndata) = _to.call{value: _value}(_data);
      require(success, "Execution failed");
      return returndata;
    }

    modifier onlyOwnerOrOpsManager() {
        require(msg.sender == owner() || opsManagers[msg.sender] == true, "not owner or ops manager");
        _;
    }
}

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