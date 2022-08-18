// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "../openzeppelin/SafeERC20.sol";
import "../openzeppelin/ReentrancyGuard.sol";
import "../interfaces/ITetuLiquidator.sol";
import "../interfaces/IVoter.sol";
import "../interfaces/IVeDistributor.sol";
import "../interfaces/IForwarder.sol";
import "../proxy/ControllableV3.sol";

/// @title This contract should contains a buffer of fees from strategies.
///        Periodically sell rewards and distribute to their destinations.
/// @author belbix
contract ForwarderV3 is ReentrancyGuard, ControllableV3, IForwarder {
  using SafeERC20 for IERC20;

  // *************************************************************
  //                        CONSTANTS
  // *************************************************************

  /// @dev Version of this contract. Adjust manually on each code modification.
  string public constant FORWARDER_VERSION = "3.0.0";
  /// @dev Denominator for different ratios. It is default for the whole platform.
  uint public constant RATIO_DENOMINATOR = 100_000;
  /// @dev If slippage not defined for concrete token will be used 5% tolerance.
  uint public constant DEFAULT_SLIPPAGE = 5_000;

  // *************************************************************
  //                        VARIABLES
  //                Keep names and ordering!
  //                 Add only in the bottom.
  // *************************************************************

  /// @dev We will convert all tokens to TETU and distribute to destinations.
  address public tetu;
  /// @dev Minimum amount of TETU tokens for distribution.
  uint public tetuThreshold;
  /// @dev Specific slippages for volatile tokens.
  mapping(address => uint) public tokenSlippage;
  /// @dev Percent of tokens for Invest Fund
  uint public toInvestFundRatio;
  /// @dev Percent of tokens for gauges.
  uint public toGaugesRatio;

  // *************************************************************
  //                        EVENTS
  // *************************************************************

  event Distributed(
    address sender,
    address token,
    uint balance,
    uint tetuValue,
    uint tetuBalance,
    uint toInvestFund,
    uint toGauges,
    uint toVeTetu
  );
  event InvestFundRatioChanged(uint oldValue, uint newValue);
  event GaugeRatioChanged(uint oldValue, uint newValue);
  event TetuThresholdChanged(uint oldValue, uint newValue);
  event SlippageChanged(address token, uint value);

  // *************************************************************
  //                        INIT
  // *************************************************************

  /// @dev Proxy initialization. Call it after contract deploy.
  function init(address controller_, address _tetu) external initializer {
    __Controllable_init(controller_);
    tetu = _tetu;
    // 10k TETU by default
    tetuThreshold = 10_000 * 1e18;
  }

  // *************************************************************
  //                      GOV ACTIONS
  // *************************************************************

  /// @dev Check that sender is governance.
  function _onlyGov() internal view {
    require(isGovernance(msg.sender), "DENIED");
  }

  /// @dev Set specific token slippage for given token.
  function setSlippage(address token, uint value) external {
    _onlyGov();
    require(value < RATIO_DENOMINATOR, "TOO_HIGH");

    tokenSlippage[token] = value;
    emit SlippageChanged(token, value);
  }

  /// @dev Set TETU threshold for distribution.
  function setTetuThreshold(uint value) external {
    _onlyGov();

    emit TetuThresholdChanged(tetuThreshold, value);
    tetuThreshold = value;
  }

  // *************************************************************
  //                     VOTER ACTIONS
  // *************************************************************

  /// @dev Check that sender is platform voter.
  function _onlyPlatformVoter() internal view {
    require(msg.sender == IController(controller()).platformVoter(), "DENIED");
  }

  /// @dev veTETU holders can change proportion via special voter.
  function setInvestFundRatio(uint value) external override {
    _onlyPlatformVoter();
    require(value <= RATIO_DENOMINATOR, "TOO_HIGH");

    emit InvestFundRatioChanged(toInvestFundRatio, value);
    toInvestFundRatio = value;
  }

  /// @dev veTETU holders can change proportion via special voter.
  function setGaugesRatio(uint value) external override {
    _onlyPlatformVoter();
    require(value <= RATIO_DENOMINATOR, "TOO_HIGH");

    emit GaugeRatioChanged(toGaugesRatio, value);
    toGaugesRatio = value;
  }

  // *************************************************************
  //                      DISTRIBUTE
  // *************************************************************

  /// @dev Try to distribute given token if the TETU value is higher than threshold.
  ///      No strict access.
  ///      We assume that amount will be distributed before accumulate huge value reasonable for arbitrage attack.
  function distribute(address token) external nonReentrant override {
    address _tetu = tetu;
    IController controller_ = IController(controller());
    ITetuLiquidator _liquidator = ITetuLiquidator(controller_.liquidator());

    (ITetuLiquidator.PoolData[] memory route, string memory error)
    = _liquidator.buildRoute(token, _tetu);

    if (route.length == 0) {
      revert(error);
    }

    uint balance = IERC20(token).balanceOf(address(this));

    // calculate balance in tetu value for check threshold
    uint tetuValue = _liquidator.getPriceForRoute(route, balance);

    // if the value higher than threshold distribute to destinations
    if (tetuValue > tetuThreshold) {

      uint slippage = tokenSlippage[token];
      if (slippage == 0) {
        slippage = DEFAULT_SLIPPAGE;
      }

      // we need to approve each time, liquidator address can be changed in controller
      // reset approves not necessary - assume that the all balance will be transferred
      IERC20(token).safeApprove(address(_liquidator), balance);
      _liquidator.liquidateWithRoute(route, balance, slippage);


      uint tetuBalance = IERC20(_tetu).balanceOf(address(this));

      uint toInvestFund = tetuBalance * toInvestFundRatio / RATIO_DENOMINATOR;
      uint toGauges = (tetuBalance - toInvestFund) * toGaugesRatio / RATIO_DENOMINATOR;
      uint toVeTetu = (tetuBalance - toInvestFund) - toGauges;

      if (toInvestFund != 0) {
        IERC20(_tetu).safeTransfer(controller_.investFund(), toInvestFund);
      }

      if (toGauges != 0) {
        address voter = controller_.voter();
        IERC20(_tetu).safeApprove(voter, toGauges);
        IVoter(voter).notifyRewardAmount(toGauges);
      }

      if (toVeTetu != 0) {
        address distributor = controller_.veDistributor();
        IERC20(_tetu).safeTransfer(distributor, toVeTetu);
        IVeDistributor(distributor).checkpoint();
      }

      emit Distributed(
        msg.sender,
        token,
        balance,
        tetuValue,
        tetuBalance,
        toInvestFund,
        toGauges,
        toVeTetu
      );

    }
  }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../interfaces/IERC20.sol";
import "./Address.sol";

/**
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.6/contracts/token/ERC20/utils/SafeERC20.sol
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
    uint value
  ) internal {
    _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
  }

  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint value
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
    uint value
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
    uint value
  ) internal {
    uint newAllowance = token.allowance(address(this), spender) + value;
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
  }

  function safeDecreaseAllowance(
    IERC20 token,
    address spender,
    uint value
  ) internal {
  unchecked {
    uint oldAllowance = token.allowance(address(this), spender);
    require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
    uint newAllowance = oldAllowance - value;
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
   * by making the `nonReentrant` function external, and make it call a
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

pragma solidity 0.8.4;

interface ITetuLiquidator {

  struct PoolData {
    address pool;
    address swapper;
    address tokenIn;
    address tokenOut;
  }

  function getPrice(address tokenIn, address tokenOut, uint amount) external view returns (uint);

  function getPriceForRoute(PoolData[] memory route, uint amount) external view returns (uint);

  function isRouteExist(address tokenIn, address tokenOut) external view returns (bool);

  function buildRoute(
    address tokenIn,
    address tokenOut
  ) external view returns (PoolData[] memory route, string memory errorMessage);

  function liquidate(
    address tokenIn,
    address tokenOut,
    uint amount,
    uint slippage
  ) external;

  function liquidateWithRoute(
    PoolData[] memory route,
    uint amount,
    uint slippage
  ) external;


}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IVoter {

  function ve() external view returns (address);

  function attachTokenToGauge(address stakingToken, uint _tokenId, address account) external;

  function detachTokenFromGauge(address stakingToken, uint _tokenId, address account) external;

  function distribute(address stakingToken) external;

  function notifyRewardAmount(uint amount) external;

  function detachTokenFromAll(uint tokenId, address account) external;

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IVeDistributor {

  function rewardToken() external view returns (address);

  function checkpoint() external;

  function claim(uint _tokenId) external returns (uint);

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IForwarder {

  function distribute(address token) external;

  function setInvestFundRatio(uint value) external;

  function setGaugesRatio(uint value) external;

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "../openzeppelin/Initializable.sol";
import "../interfaces/IControllable.sol";
import "../interfaces/IController.sol";
import "../lib/SlotsLib.sol";

/// @title Implement basic functionality for any contract that require strict control
/// @dev Can be used with upgradeable pattern.
///      Require call __Controllable_init() in any case.
/// @author belbix
abstract contract ControllableV3 is Initializable, IControllable {
  using SlotsLib for bytes32;

  /// @notice Version of the contract
  /// @dev Should be incremented when contract changed
  string public constant CONTROLLABLE_VERSION = "3.0.0";

  bytes32 internal constant _CONTROLLER_SLOT = bytes32(uint256(keccak256("eip1967.controllable.controller")) - 1);
  bytes32 internal constant _CREATED_SLOT = bytes32(uint256(keccak256("eip1967.controllable.created")) - 1);
  bytes32 internal constant _CREATED_BLOCK_SLOT = bytes32(uint256(keccak256("eip1967.controllable.created_block")) - 1);
  bytes32 internal constant _REVISION_SLOT = bytes32(uint256(keccak256("eip1967.controllable.revision")) - 1);
  bytes32 internal constant _PREVIOUS_LOGIC_SLOT = bytes32(uint256(keccak256("eip1967.controllable.prev_logic")) - 1);

  event ContractInitialized(address controller, uint ts, uint block);
  event RevisionIncreased(uint value, address oldLogic);

  /// @notice Initialize contract after setup it as proxy implementation
  ///         Save block.timestamp in the "created" variable
  /// @dev Use it only once after first logic setup
  /// @param controller_ Controller address
  function __Controllable_init(address controller_) internal onlyInitializing {
    require(controller_ != address(0), "Zero controller");
    require(IController(controller_).governance() != address(0), "Zero governance");
    _CONTROLLER_SLOT.set(controller_);
    _CREATED_SLOT.set(block.timestamp);
    _CREATED_BLOCK_SLOT.set(block.number);
    emit ContractInitialized(controller_, block.timestamp, block.number);
  }

  /// @dev Return true if given address is controller
  function isController(address _value) public override view returns (bool) {
    return _value == controller();
  }

  /// @notice Return true if given address is setup as governance in Controller
  function isGovernance(address _value) public override view returns (bool) {
    return IController(controller()).governance() == _value;
  }

  /// @dev Contract upgrade counter
  function revision() external view returns (uint){
    return _REVISION_SLOT.getUint();
  }

  /// @dev Previous logic implementation
  function previousImplementation() external view returns (address){
    return _PREVIOUS_LOGIC_SLOT.getAddress();
  }

  // ************* SETTERS/GETTERS *******************

  /// @notice Return controller address saved in the contract slot
  function controller() public view override returns (address) {
    return _CONTROLLER_SLOT.getAddress();
  }

  /// @notice Return creation timestamp
  /// @return Creation timestamp
  function created() external view override returns (uint256) {
    return _CREATED_SLOT.getUint();
  }

  /// @notice Return creation block number
  /// @return Creation block number
  function createdBlock() external override view returns (uint256) {
    return _CREATED_BLOCK_SLOT.getUint();
  }

  /// @dev Revision should be increased on each contract upgrade
  function increaseRevision(address oldLogic) external override {
    require(msg.sender == address(this), "Increase revision forbidden");
    uint r = _REVISION_SLOT.getUint() + 1;
    _REVISION_SLOT.set(r);
    _PREVIOUS_LOGIC_SLOT.set(oldLogic);
    emit RevisionIncreased(r, oldLogic);
  }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint amount) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address owner, address spender) external view returns (uint);

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
  function approve(address spender, uint amount) external returns (bool);

  /**
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(
    address sender,
    address recipient,
    uint amount
  ) external returns (bool);

  /**
   * @dev Emitted when `value` tokens are moved from one account (`from`) to
   * another (`to`).
   *
   * Note that `value` may be zero.
   */
  event Transfer(address indexed from, address indexed to, uint value);

  /**
   * @dev Emitted when the allowance of a `spender` for an `owner` is set by
   * a call to {approve}. `value` is the new allowance.
   */
  event Approval(address indexed owner, address indexed spender, uint value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/release-v4.6/contracts/utils/AddressUpgradeable.sol
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
  function sendValue(address payable recipient, uint amount) internal {
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
    uint value
  ) internal returns (bytes memory) {
    return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
  }

  /**
   * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
  function functionCallWithValue(
    address target,
    bytes memory data,
    uint value,
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "./Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
  /**
   * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
  uint8 private _initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
     */
  bool private _initializing;

  /**
   * @dev Triggered when the contract has been initialized or reinitialized.
     */
  event Initialized(uint8 version);

  /**
   * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
  modifier initializer() {
    bool isTopLevelCall = _setInitializedVersion(1);
    if (isTopLevelCall) {
      _initializing = true;
    }
    _;
    if (isTopLevelCall) {
      _initializing = false;
      emit Initialized(1);
    }
  }

  /**
   * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
  modifier reinitializer(uint8 version) {
    bool isTopLevelCall = _setInitializedVersion(version);
    if (isTopLevelCall) {
      _initializing = true;
    }
    _;
    if (isTopLevelCall) {
      _initializing = false;
      emit Initialized(version);
    }
  }

  /**
   * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
  modifier onlyInitializing() {
    require(_initializing, "Initializable: contract is not initializing");
    _;
  }

  /**
   * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
  function _disableInitializers() internal virtual {
    _setInitializedVersion(type(uint8).max);
  }

  function _setInitializedVersion(uint8 version) private returns (bool) {
    // If the contract is initializing we ignore whether _initialized is set in order to support multiple
    // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
    // of initializers, because in other contexts the contract may have been reentered.
    if (_initializing) {
      require(
        version == 1 && !Address.isContract(address(this)),
        "Initializable: contract is already initialized"
      );
      return false;
    } else {
      require(_initialized < version, "Initializable: contract is already initialized");
      _initialized = version;
      return true;
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IControllable {

  function isController(address _contract) external view returns (bool);

  function isGovernance(address _contract) external view returns (bool);

  function created() external view returns (uint256);

  function createdBlock() external view returns (uint256);

  function controller() external view returns (address);

  function increaseRevision(address oldLogic) external;

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IController {

  // --- DEPENDENCY ADDRESSES
  function governance() external view returns (address);

  function voter() external view returns (address);

  function liquidator() external view returns (address);

  function forwarder() external view returns (address);

  function investFund() external view returns (address);

  function veDistributor() external view returns (address);

  function platformVoter() external view returns (address);

  // --- VAULTS

  function vaults(uint id) external view returns (address);

  function vaultsList() external view returns (address[] memory);

  function vaultsListLength() external view returns (uint);

  function isValidVault(address _vault) external view returns (bool);

  // --- restrictions

  function isOperator(address _adr) external view returns (bool);


}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

/// @title Library for setting / getting slot variables (used in upgradable proxy contracts)
/// @author bogdoslav
library SlotsLib {

  /// @notice Version of the contract
  /// @dev Should be incremented when contract changed
  string public constant SLOT_LIB_VERSION = "1.0.0";

  // ************* GETTERS *******************

  /// @dev Gets a slot as bytes32
  function getBytes32(bytes32 slot) internal view returns (bytes32 result) {
    assembly {
      result := sload(slot)
    }
  }

  /// @dev Gets a slot as an address
  function getAddress(bytes32 slot) internal view returns (address result) {
    assembly {
      result := sload(slot)
    }
  }

  /// @dev Gets a slot as uint256
  function getUint(bytes32 slot) internal view returns (uint result) {
    assembly {
      result := sload(slot)
    }
  }

  // ************* ARRAY GETTERS *******************

  /// @dev Gets an array length
  function arrayLength(bytes32 slot) internal view returns (uint result) {
    assembly {
      result := sload(slot)
    }
  }

  /// @dev Gets a slot array by index as address
  /// @notice First slot is array length, elements ordered backward in memory
  /// @notice This is unsafe, without checking array length.
  function addressAt(bytes32 slot, uint index) internal view returns (address result) {
    bytes32 pointer = bytes32(uint(slot) - 1 - index);
    assembly {
      result := sload(pointer)
    }
  }

  /// @dev Gets a slot array by index as uint
  /// @notice First slot is array length, elements ordered backward in memory
  /// @notice This is unsafe, without checking array length.
  function uintAt(bytes32 slot, uint index) internal view returns (uint result) {
    bytes32 pointer = bytes32(uint(slot) - 1 - index);
    assembly {
      result := sload(pointer)
    }
  }

  // ************* SETTERS *******************

  /// @dev Sets a slot with bytes32
  /// @notice Check address for 0 at the setter
  function set(bytes32 slot, bytes32 value) internal {
    assembly {
      sstore(slot, value)
    }
  }

  /// @dev Sets a slot with address
  /// @notice Check address for 0 at the setter
  function set(bytes32 slot, address value) internal {
    assembly {
      sstore(slot, value)
    }
  }

  /// @dev Sets a slot with uint
  function set(bytes32 slot, uint value) internal {
    assembly {
      sstore(slot, value)
    }
  }

  // ************* ARRAY SETTERS *******************

  /// @dev Sets a slot array at index with address
  /// @notice First slot is array length, elements ordered backward in memory
  /// @notice This is unsafe, without checking array length.
  function setAt(bytes32 slot, uint index, address value) internal {
    bytes32 pointer = bytes32(uint(slot) - 1 - index);
    assembly {
      sstore(pointer, value)
    }
  }

  /// @dev Sets a slot array at index with uint
  /// @notice First slot is array length, elements ordered backward in memory
  /// @notice This is unsafe, without checking array length.
  function setAt(bytes32 slot, uint index, uint value) internal {
    bytes32 pointer = bytes32(uint(slot) - 1 - index);
    assembly {
      sstore(pointer, value)
    }
  }

  /// @dev Sets an array length
  function setLength(bytes32 slot, uint length) internal {
    assembly {
      sstore(slot, length)
    }
  }

  /// @dev Pushes an address to the array
  function push(bytes32 slot, address value) internal {
    uint length = arrayLength(slot);
    setAt(slot, length, value);
    setLength(slot, length + 1);
  }

}