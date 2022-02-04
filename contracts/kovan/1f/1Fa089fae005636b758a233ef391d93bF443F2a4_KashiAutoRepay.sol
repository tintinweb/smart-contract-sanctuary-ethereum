// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../libraries/Boring.sol";
import "../interfaces/IKashiPairMediumRiskV1.sol";
import "../interfaces/IUniswapV2Router02.sol";
import "../interfaces/IUniswapV2Factory.sol";

interface IWETH {
  function deposit() external payable;
  function withdraw(uint256) external;
}

contract KashiAutoRepay is Ownable {
  using RebaseLibrary for Rebase;
  using SafeERC20 for IERC20;

  /// @notice internal settings of Medium Risk KashiPair
  uint256 private constant CLOSED_COLLATERIZATION_RATE = 75000; // 75%

  uint256 private constant COLLATERIZATION_RATE_PRECISION = 1e5; // Must be less than EXCHANGE_RATE_PRECISION (due to optimization in math)
  uint256 private constant EXCHANGE_RATE_PRECISION = 1e18;

  uint256 private constant MAX_UINT = type(uint256).max;
  uint256 public constant DEADLINE = 2429913600;

  enum SolvencyStatus {YES, NO, REPAID}

  address payable public immutable registry;
  address public immutable userVeriForwarder;
  address public immutable userFeeVeriForwarder;
  FeeInfo private _defaultFeeInfo;
  address public immutable WETH;
  address public immutable AUTO;

  constructor(
    address payable registry_,
    address userVeriForwarder_,
    address userFeeVeriForwarder_,
    FeeInfo memory defaultFeeInfo_,
    address WETH_,
    address AUTO_
  ) Ownable()
  {
    registry = registry_;
    userVeriForwarder = userVeriForwarder_;
    userFeeVeriForwarder = userFeeVeriForwarder_;
    _defaultFeeInfo = defaultFeeInfo_;

    // if defaultFeeInfo.isAUTO
    // _defaultFeeInfo.path[0] = 0;
    // _defaultFeeInfo.path[1] = AUTO;

    // if !defaultFeeInfo.isAUTO
    // _defaultFeeInfo.path[0] = 0;
    // _defaultFeeInfo.path[1] = WETH;

    WETH = WETH_;
    AUTO = AUTO_;
  }

  struct FeeInfo {
    // Need a known instance of UniV2 that is guaranteed to have the token
    // that the default fee is paid in, along with enough liquidity, since
    // an arbitrary instance of UniV2 is passed to fcns in this contract
    IUniswapV2Router02 uni;
    address[] path;
    // Whether or not the fee token is AUTO, because that needs to
    // get sent to the user, since `transferFrom` is used from them directly
    // in the Registry to charge the fee
    bool isAUTO;
  }

  // Hold arguments for calling Kashi to avoid stack to deep errors
  struct KashiArgs {
    IKashiPairMediumRiskV1 pair;  // kashi lending pair's position address, e.g. WETH / USDT
    uint256 expectedParts;        // share of asset user wants to repay
    IERC20[] alternatives;        // array of tokens, used to liquidate the loan, can include the borrowed asset itself
    uint256 bufferLimit;          // liquidation margin percentage
  }

  // internal calculation only, to avoid the stack-too-deep issue
  struct AmountOf {
    uint256 neededAsset;          // totally needed asset amount while repaying
    uint256 realAsset;            // actual asset amount
    uint256 tokenBalance;         // alternative token's balance
    uint256 transferred;           // transferred asset amount
  }

  function selfLiquidate(
    address user,
    KashiArgs calldata kashiArgs
  ) external userVerified returns (uint256 actualParts) {
    return _selfLiquidatePaySpecific(
      user,
      0,
      _defaultFeeInfo,
      kashiArgs
    );
  }

  function selfLiquidatePayDefault(
    address user,
    uint256 feeAmount,
    KashiArgs calldata kashiArgs
  ) external userFeeVerified returns (uint256 actualParts) {
    FeeInfo memory feeInfo = _defaultFeeInfo;

    return _selfLiquidatePaySpecific(
      user,
      feeAmount,
      feeInfo,
      kashiArgs
    );
  }

  function selfLiquidatePaySpecific(
    address user,
    uint256 feeAmount,
    KashiArgs calldata kashiArgs,
    FeeInfo calldata feeInfo
  ) external userFeeVerified returns (uint256 actualParts) {
    return _selfLiquidatePaySpecific(
      user,
      feeAmount,
      feeInfo,
      kashiArgs
    );
  }

  /// @notice Repay the user's borrowedPart, in order to prevent auto-liquidation, charging 12% additional fee
  ///     In the registry, users can request selfLiquidating with array of tokens.
  ///     So first it checks if there is AUTO or WETH for registry fee while iterating the array of tokens, 
  ///       then it will take that if enough amount for fee, and trying to trade all left tokens into asset token, and self-liquidate in Kashi pair.
  ///     If there is not AUTO or WETH in the array of tokens, then it will trade all tokens into asset,
  ///       and swap some of them into AUTO or WETH again for registry fee, and then self-liquidate all left asset into Kashi.
  /// @param user Address of the user this repayment should go.
  /// @param feeAmount registry fee amount
  /// @param feeInfo FeeInfo structure
  /// @param kashiArgs kashi's arguments
  /// @return actualRepayParts share of asset that was actually repaid.
  function _selfLiquidatePaySpecific(
    address user,
    uint256 feeAmount,
    FeeInfo memory feeInfo,
    KashiArgs memory kashiArgs
  ) private returns (uint256 actualRepayParts) {
    AmountOf memory _amountOf;
    IERC20 asset = kashiArgs.pair.asset();
    IBentoBoxV1 _bentoBox = kashiArgs.pair.bentoBox();
    address[] memory routePath = new address[](3);

    SolvencyStatus _solvencyStatus = solvency(kashiArgs.pair, user, kashiArgs.bufferLimit);
    // If REPAID already, then remove the request from registry
    require (_solvencyStatus != SolvencyStatus.REPAID, "Invalid job");
    // if still solvent status, then reject the job.
    require (_solvencyStatus == SolvencyStatus.NO, "Repay later");
    require (kashiArgs.alternatives.length > 0, "Invalid alternatives");

    // get actual repay amount, from the share
    uint256 _borrowPart = kashiArgs.pair.userBorrowPart(user);
    actualRepayParts = kashiArgs.expectedParts >= _borrowPart ? _borrowPart : kashiArgs.expectedParts;

    // calculate totally needed asset amount
    _amountOf.neededAsset = kashiArgs.pair.totalBorrow().toElastic(actualRepayParts, true);
    if (feeAmount > 0) {
      _amountOf.neededAsset += _estimateAssetAmountForFee(address(asset), feeAmount, feeInfo, routePath);
    }
    // add margin for rounding difference
    _amountOf.neededAsset = _amountOf.neededAsset * 1000000000 / 999999999;

    // iterate all alternative tokens, and swap into asset token
    for (uint256 i = 0; i < kashiArgs.alternatives.length; i ++) {
      _amountOf.tokenBalance = kashiArgs.alternatives[i].balanceOf(user);
      if (_amountOf.tokenBalance == 0) {
        continue;
      }

      if (kashiArgs.alternatives[i] == asset) {
        // if alternative token is same with asset, then move only.
        _amountOf.transferred = _amountOf.tokenBalance > _amountOf.neededAsset ? _amountOf.neededAsset : _amountOf.tokenBalance;
        asset.transferFrom(user, address(this), _amountOf.transferred);
      } else {
        // if the alternative is not borrowed asset, then swap into asset
        _amountOf.transferred = transferAndSwap(
          user,
          feeInfo.uni,
          address(kashiArgs.alternatives[i]),
          address(asset),
          _amountOf.tokenBalance,
          _amountOf.neededAsset,
          routePath
        );
      }

      _amountOf.realAsset += _amountOf.transferred;
      // ideally estimated transferred amount is lte neededAmount
      // but sometimes actual transferred amount can be gt neededAmount.
      _amountOf.neededAsset = _amountOf.neededAsset > _amountOf.transferred ? _amountOf.neededAsset - _amountOf.transferred : 0;
      if (_amountOf.neededAsset == 0) { break; }
    }

    /**
     * finished to trade all alternative tokens into asset by uni, and moved into this.
     * approve the asset for BentoBox to transfer.
     */
    approveUnapproved(address(_bentoBox), address(asset), _amountOf.realAsset);

    // if feeAmount is 0, that means registry charged fee already
    if (feeAmount > 0) {
      _amountOf.realAsset -= _processFee(
        user,
        address(asset),
        _amountOf.realAsset,
        feeAmount,
        feeInfo,
        routePath
      );
    }

    // Calculate repaying parts again, after deduct fee
    actualRepayParts = kashiArgs.pair.totalBorrow().toBase(_amountOf.realAsset * 999999999 / 1000000000, false);   // deduct 0.0001% for overflow by roundUp
    if (actualRepayParts > _borrowPart) {
      actualRepayParts = _borrowPart;
    }
    // Repay asset to Kashi pair in BentoBox
    uint256 _assetShare = _bentoBox.toShare(asset, _amountOf.realAsset, false);
    _bentoBox.deposit(asset, address(this), address(this), _amountOf.realAsset, 0);
    _bentoBox.transfer(asset, address(this), address(kashiArgs.pair), _assetShare);
    
    // Skim repaid asset amount, and remove borrowed record
    kashiArgs.pair.repay(user, true, actualRepayParts);
  }

  function transferAndSwap(
    address user,
    IUniswapV2Router02 uni,
    address input,
    address output,
    uint256 maxInputAmount,
    uint256 maxOutputAmount,
    address[] memory routePath
  ) private returns (uint256 outputAmount) {
    uint256[] memory _inAmounts;
    uint256[] memory _outAmounts;

    // swap alternative into asset
    if (address(input) == WETH || address(output) == WETH) {
      routePath[0] = address(input);
      routePath[1] = address(output);
      routePath[2] = address(0);
    } else {
      routePath[0] = address(input);
      routePath[1] = WETH;
      routePath[2] = address(output);
    }
  
    // estimate input amount
    _inAmounts = uni.getAmountsIn(maxOutputAmount, routePath);
    // transfer balance into this, and approve for uni
    transferApproveUnapproved(
      address(uni), 
      input, 
      _inAmounts[0] > maxInputAmount ? maxInputAmount : _inAmounts[0], 
      user
    );
    // swap into asset
    _outAmounts = uni.swapExactTokensForTokens(
      _inAmounts[0] > maxInputAmount ? maxInputAmount : _inAmounts[0],
      0,
      routePath,
      address(this),
      DEADLINE
    );

    outputAmount = _outAmounts[_outAmounts.length-1];
  }

  /// @notice it estimates the required asset amount, to swap registry fee amount
  function _estimateAssetAmountForFee(
    address assetAddr,
    uint256 feeAmount,
    FeeInfo memory feeInfo,
    address[] memory routePath
  ) private view returns (uint256 requiredAssetAmount) {
    if (feeInfo.isAUTO) {
      if (assetAddr == WETH) {
        // swap WETH => AUTO
        routePath[0] = WETH;
        routePath[1] = AUTO;
        routePath[2] = address(0);
      } else {
        // swap asset => WETH => AUTO
        routePath[0] = assetAddr;
        routePath[1] = WETH;
        routePath[2] = AUTO;
      }
    } else {
      // fee by ETH
      if (assetAddr == WETH) {
        return feeAmount;
      } else {
        // swap asset => ETH
        routePath[0] = assetAddr;
        routePath[1] = WETH;
        routePath[2] = address(0);
      }
    }

    uint256[] memory amounts = feeInfo.uni.getAmountsIn(feeAmount, routePath);
    return amounts[0];
  }

  // separate function, processing fee to prevent stack deep errors
  function _processFee(
    address user,
    address assetAddr,
    uint256 assetAmount,
    uint256 feeAmount,
    FeeInfo memory feeInfo,
    address[] memory routePath
  ) private returns (uint256) {
    feeInfo.path[0] = assetAddr;
    // approve asset to uni
    approveUnapproved(address(feeInfo.uni), assetAddr, assetAmount);

    if (feeInfo.isAUTO) {
      if (assetAddr == WETH) {
        // feeInfo.path[1] = AUTO;
        // swap WETH to AUTO
        return feeInfo.uni.swapTokensForExactTokens(feeAmount, assetAmount, feeInfo.path, user, DEADLINE)[0];
      } else {
        // if asset is general token, swap asset into AUTO through WETH
        routePath[0] = assetAddr;
        routePath[1] = WETH;
        routePath[2] = AUTO;
        return feeInfo.uni.swapTokensForExactTokens(feeAmount, assetAmount, routePath, user, DEADLINE)[0];
      }
    } else {
      if (assetAddr == WETH) {
        IWETH(WETH).withdraw(feeAmount);
        registry.transfer(feeAmount);
        return feeAmount;
      } else {
        // feeInfo.path[1] = WETH;
        return feeInfo.uni.swapTokensForExactETH(feeAmount, assetAmount, feeInfo.path, registry, DEADLINE)[0];
      }
    }
  }

  /// @notice Check if user's collateral < user's repayAmount * (100 + bufferLimit)%
  /// Please refer to _isSolvent() in KashiPairMediumRiskV1 contract
  /// @return SolvencyStatus
  /// if SolvencyStatus.YES, it means no need to repay immediately
  /// if SolvencyStatus.NO, it means should repay asap
  /// if SolvencyStatus.REPAID, it means users borrowed amount is zero, so no need repay
  function solvency(
    IKashiPairMediumRiskV1 kashiPair,
    address user,
    uint256 bufferLimit
  ) public view returns (SolvencyStatus) {
    IBentoBoxV1 bentoBox = kashiPair.bentoBox();
    IERC20 _collateral = kashiPair.collateral();

    uint256 borrowPart = kashiPair.userBorrowPart(user);
    if (borrowPart == 0) return SolvencyStatus.REPAID;

    uint256 collateralShare = kashiPair.userCollateralShare(user);
    if (collateralShare == 0) return SolvencyStatus.NO;

    Rebase memory _totalBorrow = kashiPair.totalBorrow();
    // borrowAmount: actual asset amount that user should repay
    uint256 borrowAmount = borrowPart * _totalBorrow.elastic / _totalBorrow.base;

    return 
      bentoBox.toAmount(
        _collateral,
        collateralShare * EXCHANGE_RATE_PRECISION / COLLATERIZATION_RATE_PRECISION * CLOSED_COLLATERIZATION_RATE,
        false // no roundUp
      ) <=
      borrowAmount * kashiPair.exchangeRate() * (100 + bufferLimit) / 100 ?
      SolvencyStatus.NO :
      SolvencyStatus.YES;
  }

  //////////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////////
  ////                                                          ////
  ////-------------------------Helpers--------------------------////
  ////                                                          ////
  //////////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////////

  function approveUnapproved(address target, address tokenAddr, uint amount) private returns (IERC20 token) {
    token = IERC20(tokenAddr);
    uint256 currentAllowance = token.allowance(address(this), target);
    if (currentAllowance == 0) {
      token.safeApprove(target, MAX_UINT);
    } else if (token.allowance(address(this), target) < amount) {
      token.safeIncreaseAllowance(target, MAX_UINT - currentAllowance);
    }
  }

  function transferApproveUnapproved(address target, address tokenAddr, uint amount, address user) private {
    IERC20 token = approveUnapproved(target, tokenAddr, amount);
    token.safeTransferFrom(user, address(this), amount);
  }

  function setDefaultFeeInfo(FeeInfo calldata newDefaultFee) external onlyOwner {
    _defaultFeeInfo = newDefaultFee;
  }

  function getDefaultFeeInfo() external view returns (FeeInfo memory) {
    return _defaultFeeInfo;
  }

  modifier userVerified() {
    require(msg.sender == userVeriForwarder, "selfLiquidate: not userForw");
    _;
  }

  modifier userFeeVerified() {
    require(msg.sender == userFeeVeriForwarder, "selfLiquidate: not userFeeForw");
    _;
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Rebase.sol";

interface IBentoBoxV1 {
    function balanceOf(IERC20, address) external view returns (uint256);

    function deposit(
        IERC20 token_,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external payable returns (uint256 amountOut, uint256 shareOut);

    function toAmount(
        IERC20 token,
        uint256 share,
        bool roundUp
    ) external view returns (uint256 amount);

    function toShare(
        IERC20 token,
        uint256 amount,
        bool roundUp
    ) external view returns (uint256 share);

    function totals(IERC20) external view returns (Rebase memory totals_);

    function transfer(
        IERC20 token,
        address from,
        address to,
        uint256 share
    ) external;

    function transferMultiple(
        IERC20 token,
        address from,
        address[] calldata tos,
        uint256[] calldata shares
    ) external;

    function withdraw(
        IERC20 token_,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external returns (uint256 amountOut, uint256 shareOut);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Rebase.sol";
import "./IBentoBoxV1.sol";


struct AccrueInfo {
  uint64 interestPerSecond;
  uint64 lastAccrued;
  uint128 feesEarnedFraction;
}

interface IKashiPairMediumRiskV1 {
  function bentoBox() external view returns (IBentoBoxV1);

  function collateral() external view returns (IERC20);
  function asset() external view returns (IERC20);
  function oracleData() external view returns (bytes memory);
  function oracle() external view returns (address);
  
  function totalCollateralShare() external view returns (uint256);
  function totalAsset() external view returns (Rebase memory); // elastic = BentoBox shares held by the KashiPair, base = Total fractions held by asset suppliers
  function totalBorrow() external view returns (Rebase memory); // elastic = Total token amount to be repayed by borrowers, base = Total parts of the debt held by borrowers

  // User balances
  function userCollateralShare(address) external view returns (uint256);
  // userAssetFraction is called balanceOf for ERC20 compatibility (it's in ERC20.sol)
  function userBorrowPart(address) external view returns (uint256);

  function exchangeRate() external view returns (uint256);
  function accrueInfo() external view returns (AccrueInfo memory);

  function accrue() external;

  /// @notice Gets the exchange rate. I.e how much collateral to buy 1e18 asset.
  /// This function is supposed to be invoked if needed because Oracle queries can be expensive.
  /// @return updated True if `exchangeRate` was updated.
  /// @return rate The new exchange rate.
  function updateExchangeRate() external returns (bool updated, uint256 rate);

  /// @notice Adds `collateral` from msg.sender to the account `to`.
  /// @param to The receiver of the tokens.
  /// @param skim True if the amount should be skimmed from the deposit balance of msg.sender.
  /// False if tokens from msg.sender in `bentoBox` should be transferred.
  /// @param share The amount of shares to add for `to`.
  function addCollateral(address to, bool skim, uint256 share) external;

  /// @notice Removes `share` amount of collateral and transfers it to `to`.
  /// @param to The receiver of the shares.
  /// @param share Amount of shares to remove.
  function removeCollateral(address to, uint256 share) external;

  /// @notice Adds assets to the lending pair.
  /// @param to The address of the user to receive the assets.
  /// @param skim True if the amount should be skimmed from the deposit balance of msg.sender.
  /// False if tokens from msg.sender in `bentoBox` should be transferred.
  /// @param share The amount of shares to add.
  /// @return fraction Total fractions added.
  function addAsset(address to, bool skim, uint256 share) external returns (uint256 fraction);

  /// @notice Removes an asset from msg.sender and transfers it to `to`.
  /// @param to The user that receives the removed assets.
  /// @param fraction The amount/fraction of assets held to remove.
  /// @return share The amount of shares transferred to `to`.
  function removeAsset(address to, uint256 fraction) external returns (uint256 share);

  /// @notice Sender borrows `amount` and transfers it to `to`.
  /// @return part Total part of the debt held by borrowers.
  /// @return share Total amount in shares borrowed.
  function borrow(address to, uint256 amount) external returns (uint256 part, uint256 share);

  /// @notice Repays a loan.
  /// @param to Address of the user this payment should go.
  /// @param skim True if the amount should be skimmed from the deposit balance of msg.sender.
  /// False if tokens from msg.sender in `bentoBox` should be transferred.
  /// @param part The amount to repay. See `userBorrowPart`.
  /// @return amount The total amount repayed.
  function repay(address to, bool skim, uint256 part) external returns (uint256 amount);

  struct CookStatus {
    bool needsSolvencyCheck;
    bool hasAccrued;
  }

  /// @notice Executes a set of actions and allows composability (contract calls) to other contracts.
  /// @param actions An array with a sequence of actions to execute (see ACTION_ declarations).
  /// @param values A one-to-one mapped array to `actions`. ETH amounts to send along with the actions.
  /// Only applicable to `ACTION_CALL`, `ACTION_BENTO_DEPOSIT`.
  /// @param datas A one-to-one mapped array to `actions`. Contains abi encoded data of function arguments.
  /// @return value1 May contain the first positioned return value of the last executed action (if applicable).
  /// @return value2 May contain the second positioned return value of the last executed action which returns 2 values (if applicable).
  function cook(
    uint8[] calldata actions,
    uint256[] calldata values,
    bytes[] calldata datas
  ) external payable returns (uint256 value1, uint256 value2);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;

struct Rebase {
  uint128 elastic;
  uint128 base;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;

import "../interfaces/Rebase.sol";

/// @notice A rebasing library using overflow-/underflow-safe math.
library RebaseLibrary {
    /// @notice Calculates the base value in relationship to `elastic` and `total`.
    function toBase(
        Rebase memory total,
        uint256 elastic,
        bool roundUp
    ) internal pure returns (uint256 base) {
        if (total.elastic == 0) {
            base = elastic;
        } else {
            base = elastic * total.base / total.elastic;
            if (roundUp && base * total.elastic / total.base < elastic) {
                base = base + 1;
            }
        }
    }

    /// @notice Calculates the elastic value in relationship to `base` and `total`.
    function toElastic(
        Rebase memory total,
        uint256 base,
        bool roundUp
    ) internal pure returns (uint256 elastic) {
        if (total.base == 0) {
            elastic = base;
        } else {
            elastic = base * total.elastic / total.base;
            if (roundUp && elastic * total.base / total.elastic < base) {
                elastic = elastic + 1;
            }
        }
    }

    /// @notice Add `elastic` to `total` and doubles `total.base`.
    /// @return (Rebase) The new total.
    /// @return base in relationship to `elastic`.
    function add(
        Rebase memory total,
        uint256 elastic,
        bool roundUp
    ) internal pure returns (Rebase memory, uint256 base) {
        base = toBase(total, elastic, roundUp);
        total.elastic = total.elastic + uint128(elastic);
        total.base = total.base + uint128(base);
        return (total, base);
    }

    /// @notice Sub `base` from `total` and update `total.elastic`.
    /// @return (Rebase) The new total.
    /// @return elastic in relationship to `base`.
    function sub(
        Rebase memory total,
        uint256 base,
        bool roundUp
    ) internal pure returns (Rebase memory, uint256 elastic) {
        elastic = toElastic(total, base, roundUp);
        total.elastic = total.elastic - uint128(elastic);
        total.base = total.base - uint128(base);
        return (total, elastic);
    }

    /// @notice Add `elastic` and `base` to `total`.
    function add(
        Rebase memory total,
        uint256 elastic,
        uint256 base
    ) internal pure returns (Rebase memory) {
        total.elastic = total.elastic + uint128(elastic);
        total.base = total.base + uint128(base);
        return total;
    }

    /// @notice Subtract `elastic` and `base` to `total`.
    function sub(
        Rebase memory total,
        uint256 elastic,
        uint256 base
    ) internal pure returns (Rebase memory) {
        total.elastic = total.elastic - uint128(elastic);
        total.base = total.base - uint128(base);
        return total;
    }
}