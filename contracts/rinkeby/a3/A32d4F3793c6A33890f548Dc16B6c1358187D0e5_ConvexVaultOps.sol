pragma solidity ^0.8.4;
// SPDX-License-Identifier: GPL-3.0-or-later
// STAX (investments/frax-gauge/tranche/ConvexVaultOps.sol)

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../../../interfaces/investments/frax-gauge/tranche/IConvexVaultOps.sol";
import "../../../interfaces/investments/frax-gauge/vefxs/IVeFXSProxy.sol";
import "../../../interfaces/external/convex/IConvexJointVaultManager.sol";

import "../../../common/access/Operators.sol";
import "../../../common/Executable.sol";
import "../../../common/CommonEventsAndErrors.sol";

/**
  * @notice The operations manager for Convex Vault's, serving two primary functions
  * 
  * 1/ STAX is JointOwner of the Convex's "Joint Vault Manager". STAX can:
  *     a/ Propose and accept fees with convex
  *     b/ Set the address where joint owner fees get deposited
  *     c/ Add allowed addresses (which are new stax tranche contracts)
  *        to create new convex vaults under this partnership.
  *
  * 2/ Convex's Booster contract automates flipping from Convex veFXS proxy -> STAX veFXS proxy
  *    To do this, it calls into proxyToggleStaker()
  * 
  * Owner: STAX multisig
  * Operators: STAX tranche registry - to whitelist new tranches able to create convex vaults
  * convexOperator: Convex's Booster contract (which is the operator() for their whitelisted veFXSProxy)
  */
contract ConvexVaultOps is IConvexVaultOps, Ownable, Operators {
    using SafeERC20 for IERC20;

    /// @notice The Convex deployed joint vault manager
    /// @dev STAX is the joint owner (convex is the owner)
    /// Any new convex vault owner/creator needs to be whitelisted on 
    /// the joint vault manager first
    IConvexJointVaultManager public convexJointVaultManager;

    /// @notice The operator of the Convex veFXS proxy (and vaults operator). Aka 'Convex Booster'
    address public convexOperator;

    /// @dev STAX's whitelisted veFXS proxy.
    IVeFXSProxy public immutable veFxsProxy;

    /// @dev The underlying gauge address that the convex vault is using,
    /// in particular when the proxyToggleStaker() callback is invoked from the Convex Booster.
    address public gaugeAddress;

    event ConvexOperatorSet(address convexOperator);
    event ConvexJointVaultManagerSet(address convexJointVaultManager);
    event GaugeSet(address indexed gaugeAddress);

    error OnlyOwnerOrConvexOperator(address caller);

    constructor(address _veFxsProxy, address _gauge) {
        veFxsProxy = IVeFXSProxy(_veFxsProxy);
        gaugeAddress = _gauge;
    }

    function addOperator(address _address) external override onlyOwner {
        _addOperator(_address);
    }

    function removeOperator(address _address) external override onlyOwner {
        _removeOperator(_address);
    }

    /// @notice Set the operator of the Convex veFXS proxy (and vaults operator). Aka 'Convex Booster'
    function setConvexOperator(address _convexOperator) external onlyOwner {
        convexOperator = _convexOperator;
        emit ConvexOperatorSet(_convexOperator);
    }

    /// @notice Set the Convex deployed joint vault manager.
    function setConvexJointVaultManager(address _convexJointVaultManager) external onlyOwner {
        convexJointVaultManager = IConvexJointVaultManager(_convexJointVaultManager);
        emit ConvexJointVaultManagerSet(_convexJointVaultManager);
    }

    /// @notice Set the underlying gauge address that the convex joint vault will be using
    function setGauge(address _gaugeAddress) external onlyOwner {
        gaugeAddress = _gaugeAddress;
        emit GaugeSet(_gaugeAddress);
    }

    /**
      * @notice Propose new fees to be used in the convex joint vault manager.
      * @dev If stax proposes, then convex needs to 'acceptFees()' - and vice versa.
      * FEE_DENOMINATOR = 10000
      */
    function setFees(uint256 _owner, uint256 _coowner, uint256 _booster) external onlyOwner {
        convexJointVaultManager.setFees(_owner, _coowner, _booster);
    }

    /**
      * @notice Accept convex proposed fees in the convex joint vault manager.
      * @dev Check Convex's JointVaultManager for what was proposed before calling:
      *    newOwnerIncentive()
      *    newJointownerIncentive()
      *    newBoosterIncentive()
      */
    function acceptFees() external onlyOwner {
        convexJointVaultManager.acceptFees();
    }

    /**
      * @notice Set the address where STAX's share of convex vault fees will be sent
      * whenever getRewards() is called
      */
    function setJointOwnerDepositAddress(address _deposit) external onlyOwner {
        convexJointVaultManager.setJointOwnerDepositAddress(_deposit);
    }

    /**
      * @notice If Convex has released a Booster that we don't agree with (or shuts it down)
      * then the veFXS proxy can be set to be STAX.
      * 
      * @dev USE WITH CAUTION - once called, this vault cannot be set to use Convex's veFXS boost again.
      */
    function setVaultProxy(address _vault) external onlyOwner {
        convexJointVaultManager.setVaultProxy(_vault);
    }

    /**
      * @notice Give permission to Convex's current booster contract.
      * @dev Only call if absolutely necessary, otherwise we cannot force the switch back to STAXs veFXS proxy
      */
    function allowConvexBooster() external onlyOwner {
        convexJointVaultManager.allowBooster();
    }

    /**
      * @notice Whitelist a new address which has permissions to create a new vault under
      * the joint partnership
      */
    function setAllowedAddress(address _account, bool _allowed) external override onlyOwnerOrOperators {
        convexJointVaultManager.setAllowedAddress(_account, _allowed);
    }

    /**
      * @notice Convex's Booster will call this hook in order to switch the veFXS boost to STAX's veFXS proxy
      *         It toggles the underlying veFxsProxy's allowance of it's veFXS boost, 
      *         for this particular staker (ie convex vault), in this particular gauge instance.
      * @dev gauge.toggleValidVeFXSProxy(address _proxy_addr) needs to be called by Frax Gov first.
      * @param _stakerAddress The address of the contract which will be locking LP
      */
    function proxyToggleStaker(address _stakerAddress) external onlyOwnerOrConvexOperator {
      IVeFXSProxy(veFxsProxy).gaugeProxyToggleStaker(gaugeAddress, _stakerAddress);
    }

    /// @dev Provided in case there are extra functions required to call on the Convex Joint Vault Manager in future
    function execute(address _to, uint256 _value, bytes calldata _data) external onlyOwnerOrOperators returns (bytes memory) {
        return Executable.execute(_to, _value, _data);
    }

    /// @notice Owner can recover tokens
    function recoverToken(address _token, address _to, uint256 _amount) external onlyOwner {
        IERC20(_token).safeTransfer(_to, _amount);
        emit CommonEventsAndErrors.TokenTransferred(address(this), _to, address(_token), _amount);
    }

    modifier onlyOwnerOrOperators() {
        if (msg.sender != owner() && !operators[msg.sender]) revert CommonEventsAndErrors.OnlyOwnerOrOperators(msg.sender);
        _;
    }

    modifier onlyOwnerOrConvexOperator() {
        if (msg.sender != owner() && msg.sender != convexOperator) revert OnlyOwnerOrConvexOperator(msg.sender);
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

pragma solidity ^0.8.4;
// SPDX-License-Identifier: GPL-3.0-or-later
// STAX (interfaces/investments/frax-gauge/tranche/IConvexVaultOps.sol)

interface IConvexVaultOps {
    function setAllowedAddress(address _account, bool _allowed) external;
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (interfaces/investments/frax-gauge/vefxs/IVeFXSProxy.sol)

interface IVeFXSProxy {
    function gaugeProxyToggleStaker(address _gaugeAddress, address _stakerAddress) external;
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: GPL-3.0-or-later
// STAX (interfaces/external/convex/IConvexJointVaultManager.sol)

// ref: https://github.com/convex-eth/frax-cvx-platform/blob/feature/joint_vault/contracts/contracts/JointVaultManager.sol
interface IConvexJointVaultManager {
    function setFees(uint256 _owner, uint256 _jointowner, uint256 _booster) external;
    function acceptFees() external;
    function setJointOwnerDepositAddress(address _deposit) external;
    function setAllowedAddress(address _account, bool _allowed) external;

    function getOwnerFee(uint256 _amount, address _usingProxy) external view returns (uint256 _feeAmount, address _feeDeposit);
    function getJointownerFee(uint256 _amount, address _usingProxy) external view returns(uint256 _feeAmount, address _feeDeposit);
    function isAllowed(address _account) external view returns(bool);
    function allowBooster() external;
    function setVaultProxy(address _vault) external;
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: GPL-3.0-or-later
// STAX (common/access/Operators.sol)

/// @notice Inherit to add an Operator role which multiple addreses can be granted.
/// @dev Derived classes to implement addOperator() and removeOperator()
abstract contract Operators {
    /// @notice A set of addresses which are approved to run operations.
    mapping(address => bool) public operators;

    event AddedOperator(address indexed account);
    event RemovedOperator(address indexed account);

    error OnlyOperators(address caller);

    function _addOperator(address _account) internal {
        operators[_account] = true;
        emit AddedOperator(_account);
    }

    /// @notice Grant `_account` the operator role
    /// @dev Derived classes to implement and add protection on who can call
    function addOperator(address _account) external virtual;

    function _removeOperator(address _account) internal {
        delete operators[_account];
        emit RemovedOperator(_account);
    }

    /// @notice Revoke the operator role from `_account`
    /// @dev Derived classes to implement and add protection on who can call
    function removeOperator(address _account) external virtual;

    modifier onlyOperators() {
        if (!operators[msg.sender]) revert OnlyOperators(msg.sender);
        _;
    }
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: GPL-3.0-or-later
// STAX (common/Executable.sol)

/// @notice An inlined library function to add a generic execute() function to contracts.
/// @dev As this is a powerful funciton, care and consideration needs to be taken when 
///      adding into contracts, and on who can call.
library Executable {
    error UnknownFailure();

    /// @notice Call a function on another contract, where the msg.sender will be this contract
    /// @param _to The address of the contract to call
    /// @param _value Any eth to send
    /// @param _data The encoded function selector and args.
    /// @dev If the underlying function reverts, this willl revert where the underlying revert message will bubble up.
    function execute(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = _to.call{value: _value}(_data);
        
        if (success) {
            return returndata;
        } else if (returndata.length > 0) {
            // Look for revert reason and bubble it up if present
            // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol#L232
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert UnknownFailure();
        }
    }
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: GPL-3.0-or-later
// STAX (common/CommonEventsAndErrors.sol)

/// @notice A collection of common errors thrown within the STAX contracts
library CommonEventsAndErrors {
    event TokenTransferred(address indexed from, address indexed to, address indexed token, uint256 amount);

    error InsufficientTokens(address token, uint256 required, uint256 balance);
    error InvalidToken(address token);
    error InvalidParam();
    error InvalidAddress(address addr);
    error OnlyOwner(address caller);
    error OnlyOwnerOrOperators(address caller);
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