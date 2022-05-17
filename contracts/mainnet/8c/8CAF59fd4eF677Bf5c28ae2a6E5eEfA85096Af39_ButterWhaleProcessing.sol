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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
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
}

// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../../utils/ContractRegistryAccess.sol";
import "../../utils/ACLAuth.sol";
import "../../../externals/interfaces/YearnVault.sol";
import "../../../externals/interfaces/BasicIssuanceModule.sol";
import "../../../externals/interfaces/ISetToken.sol";
import "../../../externals/interfaces/CurveContracts.sol";
import "../../../externals/interfaces/Curve3Pool.sol";
import "../../interfaces/IStaking.sol";

/*
 * @notice This contract allows users to mint and redeem Butter for using 3CRV, DAI, USDC, USDT
 * The Butter is created from several different yTokens which in turn need each a deposit of a crvLPToken.
 */
contract ButterWhaleProcessing is Pausable, ReentrancyGuard, ACLAuth, ContractRegistryAccess {
  using SafeERC20 for YearnVault;
  using SafeERC20 for ISetToken;
  using SafeERC20 for IERC20;

  /**
   * @param curveMetaPool A CurveMetaPool for trading an exotic stablecoin against 3CRV
   * @param crvLPToken The LP-Token of the CurveMetapool
   */
  struct CurvePoolTokenPair {
    CurveMetapool curveMetaPool;
    IERC20 crvLPToken;
  }

  /* ========== STATE VARIABLES ========== */

  bytes32 public immutable contractName = "ButterWhaleProcessing";

  IContractRegistry public contractRegistry;
  IStaking public staking;
  ISetToken public setToken;
  IERC20 public threeCrv;
  Curve3Pool private threePool;
  BasicIssuanceModule public setBasicIssuanceModule;
  mapping(address => CurvePoolTokenPair) public curvePoolTokenPairs;
  uint256 public redemptionFees;
  uint256 public redemptionFeeRate;
  address public feeRecipient;

  mapping(address => bool) public sweethearts;

  /* ========== EVENTS ========== */
  event Minted(address account, uint256 amount, uint256 butterAmount);
  event Redeemed(address account, uint256 amount, uint256 claimableTokenBalance);
  event ZapMinted(address account, uint256 mintAmount, uint256 butterAmount);
  event ZapRedeemed(address account, uint256 redeemAmount, uint256 claimableTokenBalance);
  event CurveTokenPairsUpdated(address[] yTokenAddresses, CurvePoolTokenPair[] curveTokenPairs);
  event RedemptionFeeUpdated(uint256 newRedemptionFee, address newFeeRecipient);
  event SweetheartUpdated(address sweetheart, bool isSweeheart);
  event StakingUpdated(address beforeAddress, address afterAddress);

  /* ========== CONSTRUCTOR ========== */

  constructor(
    IContractRegistry _contractRegistry,
    IStaking _staking,
    ISetToken _setToken,
    IERC20 _threeCrv,
    Curve3Pool _threePool,
    BasicIssuanceModule _basicIssuanceModule,
    address[] memory _yTokenAddresses,
    CurvePoolTokenPair[] memory _curvePoolTokenPairs
  ) ContractRegistryAccess(_contractRegistry) {
    contractRegistry = _contractRegistry;
    staking = _staking;
    setToken = _setToken;
    threeCrv = _threeCrv;
    threePool = _threePool;
    setBasicIssuanceModule = _basicIssuanceModule;

    _setCurvePoolTokenPairs(_yTokenAddresses, _curvePoolTokenPairs);
  }

  /* ========== MUTATIVE FUNCTIONS ========== */

  /**
   * @notice Mint Butter token with deposited 3CRV. This function goes through all the steps necessary to mint an optimal amount of Butter
   * @param _amount Amount of 3cr3CRV to use for minting
   * @param _slippage The accepted slippage in basis points.
   * @param _stake Do you want to stake your minted Butter?
   * @dev This function deposits 3CRV in the underlying Metapool and deposits these LP token to get yToken which in turn are used to mint Butter
   */
  function mint(
    uint256 _amount,
    uint256 _slippage,
    bool _stake
  ) external whenNotPaused {
    require(threeCrv.balanceOf(msg.sender) >= _amount, "insufficent balance");
    threeCrv.transferFrom(msg.sender, address(this), _amount);
    uint256 butterAmount = _mint(_amount, _slippage, _stake);
    emit Minted(msg.sender, _amount, butterAmount);
  }

  /**
   * @notice Redeems Butter for 3CRV. This function goes through all the steps necessary to get 3CRV
   * @param _amount amount of Butter to be redeemed
   * @param _slippage The accepted slippage in basis points.
   * @dev This function reedeems Butter for the underlying yToken and deposits these yToken in curve Metapools for 3CRV
   */
  function redeem(uint256 _amount, uint256 _slippage) external whenNotPaused {
    uint256 claimableTokenBalance = _redeem(_amount, _slippage);
    threeCrv.safeTransfer(msg.sender, claimableTokenBalance);
    emit Redeemed(msg.sender, _amount, claimableTokenBalance);
  }

  /**
   * @notice zapMint allows a user to mint Butter directly with stablecoins
   * @param _amounts An array of amounts in stablecoins the user wants to deposit
   * @param _min_3crv_amount The min amount of 3CRV which should be minted by the curve three-pool (slippage control)
   * @param _slippage The accepted slippage in basis points.
   * @param _stake Do you want to stake your minted butter?
   * @dev The amounts in _amounts must align with their index in the curve three-pool
   */
  function zapMint(
    uint256[3] memory _amounts,
    uint256 _min_3crv_amount,
    uint256 _slippage,
    bool _stake
  ) external whenNotPaused {
    for (uint256 i; i < _amounts.length; i++) {
      if (_amounts[i] > 0) {
        //Deposit Stables
        IERC20(threePool.coins(uint256(i))).safeTransferFrom(msg.sender, address(this), _amounts[i]);
      }
    }
    //Deposit stables to receive 3CRV
    threePool.add_liquidity(_amounts, _min_3crv_amount);

    //Check the amount of returned 3CRV
    /*
    While curves metapools return the amount of minted 3CRV this is not possible with the three-pool which is why we simply have to check our balance after depositing our stables.
    If a user sends 3CRV to this contract by accident (Which cant be retrieved anyway) they will be used aswell.
    */
    uint256 threeCrvAmount = threeCrv.balanceOf(address(this));
    uint256 butterAmount = _mint(threeCrvAmount, _slippage, _stake);
    emit ZapMinted(msg.sender, threeCrvAmount, butterAmount);
  }

  /**
   * @notice zapRedeem allows a user to claim their processed 3CRV from a redeemBatch and directly receive stablecoins
   * @param _amount amount of Butter to be redeemed
   * @param _stableCoinIndex Defines which stablecoin the user wants to receive
   * @param _min_stable_amount The min amount of stables which should be returned by the curve three-pool (slippage control)
   * @param _slippage The accepted slippage in basis points.
   * @dev The _stableCoinIndex must align with the index in the curve three-pool
   */
  function zapRedeem(
    uint256 _amount,
    uint256 _stableCoinIndex,
    uint256 _min_stable_amount,
    uint256 _slippage
  ) external whenNotPaused {
    uint256 claimableTokenBalance = _redeem(_amount, _slippage);
    _swapAndTransfer3Crv(claimableTokenBalance, _stableCoinIndex, _min_stable_amount);
    emit ZapRedeemed(msg.sender, _amount, claimableTokenBalance);
  }

  /**
   * @notice sets approval for contracts that require access to assets held by this contract
   */
  function setApprovals() external {
    (address[] memory tokenAddresses, ) = setBasicIssuanceModule.getRequiredComponentUnitsForIssue(setToken, 1e18);

    for (uint256 i; i < tokenAddresses.length; i++) {
      IERC20 curveLpToken = curvePoolTokenPairs[tokenAddresses[i]].crvLPToken;
      CurveMetapool curveMetapool = curvePoolTokenPairs[tokenAddresses[i]].curveMetaPool;
      YearnVault yearnVault = YearnVault(tokenAddresses[i]);

      _maxApprove(threeCrv, address(curveMetapool));
      _maxApprove(curveLpToken, address(yearnVault));
      _maxApprove(curveLpToken, address(curveMetapool));
    }
    for (uint128 i; i < 3; i++) {
      _maxApprove(IERC20(threePool.coins(i)), address(threePool));
    }
    _maxApprove(threeCrv, address(threePool));
    _maxApprove(setToken, address(staking));
  }

  function getMinAmountToMint(
    uint256 _valueOfBatch,
    uint256 _valueOfComponentsPerUnit,
    uint256 _slippage
  ) public pure returns (uint256) {
    uint256 _mintAmount = (_valueOfBatch * 1e18) / _valueOfComponentsPerUnit;
    uint256 _delta = (_mintAmount * _slippage) / 10_000;
    return _mintAmount - _delta;
  }

  function getMinAmount3CrvFromRedeem(uint256 _valueOfComponents, uint256 _slippage) public view returns (uint256) {
    uint256 _threeCrvToReceive = (_valueOfComponents * 1e18) / threePool.get_virtual_price();
    uint256 _delta = (_threeCrvToReceive * _slippage) / 10_000;
    return _threeCrvToReceive - _delta;
  }

  function valueOfComponents(address[] memory _tokenAddresses, uint256[] memory _quantities)
    public
    view
    returns (uint256)
  {
    uint256 value;
    for (uint256 i = 0; i < _tokenAddresses.length; i++) {
      value +=
        (((YearnVault(_tokenAddresses[i]).pricePerShare() *
          curvePoolTokenPairs[_tokenAddresses[i]].curveMetaPool.get_virtual_price()) / 1e18) * _quantities[i]) /
        1e18;
    }
    return value;
  }

  function valueOf3Crv(uint256 _units) public view returns (uint256) {
    return (_units * threePool.get_virtual_price()) / 1e18;
  }

  /* ========== RESTRICTED FUNCTIONS ========== */

  function _mint(
    uint256 _amount,
    uint256 _slippage,
    bool _stake
  ) internal returns (uint256) {
    //Get the quantities of yToken needed to mint 1 BTR (This should be an equal amount per Token)
    (address[] memory tokenAddresses, uint256[] memory quantities) = setBasicIssuanceModule
      .getRequiredComponentUnitsForIssue(setToken, 1e18);

    //The value of 1 BTR in virtual Price (`quantities` * `virtualPrice`)
    uint256 setValue = valueOfComponents(tokenAddresses, quantities);

    uint256 threeCrvValue = threePool.get_virtual_price();

    //Had to add this to combat a weird "stack to deep" issue when just passing _amount in _getPoolAllocationAndRatio
    uint256 batchValue = valueOf3Crv(_amount);

    //Remaining amount of 3CRV in this batch which hasnt been allocated yet
    uint256 remainingBatchBalanceValue = batchValue;

    //Temporary allocation of 3CRV to be deployed in curveMetapools
    uint256[] memory poolAllocations = new uint256[](quantities.length);

    //Ratio of 3CRV needed to mint 1 BTR
    uint256[] memory ratios = new uint256[](quantities.length);

    for (uint256 i; i < tokenAddresses.length; i++) {
      // prettier-ignore
      (uint256 allocation, uint256 ratio) = _getPoolAllocationAndRatio(tokenAddresses[i], quantities[i], batchValue, setValue);
      poolAllocations[i] = allocation;
      ratios[i] = ratio;
      remainingBatchBalanceValue -= allocation;
    }

    for (uint256 i; i < tokenAddresses.length; i++) {
      uint256 poolAllocation;

      //RemainingLeftovers should only be 0 if there were no yToken leftover from previous batches
      //since the first iteration of poolAllocation uses all 3CRV. Therefore we can only have `remainingBatchBalanceValue` from subtracted leftovers
      if (remainingBatchBalanceValue > 0) {
        poolAllocation = _getPoolAllocation(remainingBatchBalanceValue, ratios[i]);
      }

      //Pool 3CRV to get crvLPToken
      _sendToCurve(
        ((poolAllocation + poolAllocations[i]) * 1e18) / threeCrvValue,
        curvePoolTokenPairs[tokenAddresses[i]].curveMetaPool
      );

      //Deposit crvLPToken to get yToken
      _sendToYearn(
        curvePoolTokenPairs[tokenAddresses[i]].crvLPToken.balanceOf(address(this)),
        YearnVault(tokenAddresses[i])
      );

      //Approve yToken for minting
      YearnVault(tokenAddresses[i]).safeIncreaseAllowance(
        address(setBasicIssuanceModule),
        YearnVault(tokenAddresses[i]).balanceOf(address(this))
      );
    }

    //Get the minimum amount of butter that we can mint with our balances of yToken
    uint256 butterAmount = (YearnVault(tokenAddresses[0]).balanceOf(address(this)) * 1e18) / quantities[0];

    for (uint256 i = 1; i < tokenAddresses.length; i++) {
      butterAmount = Math.min(
        butterAmount,
        (YearnVault(tokenAddresses[i]).balanceOf(address(this)) * 1e18) / quantities[i]
      );
    }

    require(butterAmount >= getMinAmountToMint(batchValue, setValue, _slippage), "slippage too high");

    //Mint Butter
    if (_stake) {
      setBasicIssuanceModule.issue(setToken, butterAmount, address(this));
      staking.stakeFor(butterAmount, msg.sender);
    } else {
      setBasicIssuanceModule.issue(setToken, butterAmount, msg.sender);
    }

    return butterAmount;
  }

  function _redeem(uint256 _amount, uint256 _slippage) internal returns (uint256) {
    require(setToken.balanceOf(msg.sender) >= _amount, "insufficient balance");
    setToken.transferFrom(msg.sender, address(this), _amount);

    //Get tokenAddresses for mapping of underlying
    (address[] memory tokenAddresses, uint256[] memory quantities) = setBasicIssuanceModule
      .getRequiredComponentUnitsForIssue(setToken, _amount);

    //Allow setBasicIssuanceModule to use Butter
    _setBasicIssuanceModuleAllowance(_amount);

    //Redeem Butter for yToken
    setBasicIssuanceModule.redeem(setToken, _amount, address(this));

    //Check our balance of 3CRV since we could have some still around from previous batches
    uint256 oldBalance = threeCrv.balanceOf(address(this));

    for (uint256 i; i < tokenAddresses.length; i++) {
      //Deposit yToken to receive crvLPToken
      _withdrawFromYearn(YearnVault(tokenAddresses[i]).balanceOf(address(this)), YearnVault(tokenAddresses[i]));

      uint256 crvLPTokenBalance = curvePoolTokenPairs[tokenAddresses[i]].crvLPToken.balanceOf(address(this));

      //Deposit crvLPToken to receive 3CRV
      _withdrawFromCurve(crvLPTokenBalance, curvePoolTokenPairs[tokenAddresses[i]].curveMetaPool);
    }

    //Save the redeemed amount of 3CRV as claimable token for the batch
    uint256 claimableTokenBalance = threeCrv.balanceOf(address(this)) - oldBalance;

    require(
      claimableTokenBalance >= getMinAmount3CrvFromRedeem(valueOfComponents(tokenAddresses, quantities), _slippage),
      "slippage too high"
    );
    if (!sweethearts[msg.sender]) {
      //Fee is deducted from threeCrv -- This allows it to work with the Zapper
      //Fes are denominated in BasisPoints
      uint256 fee = (claimableTokenBalance * redemptionFeeRate) / 10_000;
      redemptionFees = redemptionFees + fee;
      claimableTokenBalance = claimableTokenBalance - fee;
    }
    return claimableTokenBalance;
  }

  /**
   * @notice sets max allowance given a token and a spender
   * @param _token the token which gets approved to be spend
   * @param _spender the spender which gets a max allowance to spend `_token`
   */
  function _maxApprove(IERC20 _token, address _spender) internal {
    _token.safeApprove(_spender, 0);
    _token.safeApprove(_spender, type(uint256).max);
  }

  /**
   * @notice sets allowance for basic issuance module
   * @param _amount amount to approve
   */
  function _setBasicIssuanceModuleAllowance(uint256 _amount) internal {
    setToken.safeApprove(address(setBasicIssuanceModule), 0);
    setToken.safeApprove(address(setBasicIssuanceModule), _amount);
  }

  function _getPoolAllocationAndRatio(
    address _component,
    uint256 _quantity,
    uint256 _batchValue,
    uint256 _setValue
  ) internal view returns (uint256 poolAllocation, uint256 ratio) {
    //Calculate the virtualPrice of one yToken
    uint256 componentValuePerShare = (YearnVault(_component).pricePerShare() *
      curvePoolTokenPairs[_component].curveMetaPool.get_virtual_price()) / 1e18;

    //Calculate the value of quantity (of yToken) in virtualPrice
    uint256 componentValuePerSet = (_quantity * componentValuePerShare) / 1e18;

    //Calculate the value of leftover yToken in virtualPrice
    uint256 componentValueHeldByContract = (YearnVault(_component).balanceOf(address(this)) * componentValuePerShare) /
      1e18;

    ratio = (componentValuePerSet * 1e18) / _setValue;

    poolAllocation = _getPoolAllocation(_batchValue, ratio) - componentValueHeldByContract;

    return (poolAllocation, ratio);
  }

  /**
   * @notice returns the amount of 3CRV that should be allocated for a curveMetapool
   * @param _balance the max amount of 3CRV that is available in this iteration
   * @param _ratio the ratio of 3CRV needed to get enough yToken to mint butter
   */
  function _getPoolAllocation(uint256 _balance, uint256 _ratio) internal pure returns (uint256) {
    return ((_balance * _ratio) / 1e18);
  }

  /**
   * @notice _swapAndTransfer3Crv burns 3CRV and sends the returned stables to the user
   * @param _threeCurveAmount How many 3CRV shall be burned
   * @param _stableCoinIndex Defines which stablecoin the user wants to receive
   * @param _min_amount The min amount of stables which should be returned by the curve three-pool (slippage control)
   * @dev The stableCoinIndex_ must align with the index in the curve three-pool
   */
  function _swapAndTransfer3Crv(
    uint256 _threeCurveAmount,
    uint256 _stableCoinIndex,
    uint256 _min_amount
  ) internal {
    //Burn 3CRV to receive stables
    threePool.remove_liquidity_one_coin(_threeCurveAmount, int128(uint128(_stableCoinIndex)), _min_amount);

    //Check the amount of returned stables
    /*
    If a user sends Stables to this contract by accident (Which cant be retrieved anyway) they will be used aswell.
    */
    uint256 stableBalance = IERC20(threePool.coins(_stableCoinIndex)).balanceOf(address(this));

    //Transfer stables to user
    IERC20(threePool.coins(_stableCoinIndex)).safeTransfer(msg.sender, stableBalance);
  }

  /**
   * @notice Deposit 3CRV in a curve metapool for its LP-Token
   * @param _amount The amount of 3CRV that gets deposited
   * @param _curveMetapool The metapool where we want to provide liquidity
   */
  function _sendToCurve(uint256 _amount, CurveMetapool _curveMetapool) internal {
    //Takes 3CRV and sends lpToken to this contract
    //Metapools take an array of amounts with the exoctic stablecoin at the first spot and 3CRV at the second.
    //The second variable determines the min amount of LP-Token we want to receive (slippage control)
    _curveMetapool.add_liquidity([0, _amount], 0);
  }

  /**
   * @notice Withdraws 3CRV for deposited crvLPToken
   * @param _amount The amount of crvLPToken that get deposited
   * @param _curveMetapool The metapool where we want to provide liquidity
   */
  function _withdrawFromCurve(uint256 _amount, CurveMetapool _curveMetapool) internal {
    //Takes lp Token and sends 3CRV to this contract
    //The second variable is the index for the token we want to receive (0 = exotic stablecoin, 1 = 3CRV)
    //The third variable determines min amount of token we want to receive (slippage control)
    _curveMetapool.remove_liquidity_one_coin(_amount, 1, 0);
  }

  /**
   * @notice Deposits crvLPToken for yToken
   * @param _amount The amount of crvLPToken that get deposited
   * @param _yearnVault The yearn Vault in which we deposit
   */
  function _sendToYearn(uint256 _amount, YearnVault _yearnVault) internal {
    //Mints yToken and sends them to msg.sender (this contract)
    _yearnVault.deposit(_amount);
  }

  /**
   * @notice Withdraw crvLPToken from yearn
   * @param _amount The amount of crvLPToken which we deposit
   * @param _yearnVault The yearn Vault in which we deposit
   */
  function _withdrawFromYearn(uint256 _amount, YearnVault _yearnVault) internal {
    //Takes yToken and sends crvLPToken to this contract
    _yearnVault.withdraw(_amount);
  }

  /* ========== ADMIN ========== */

  /**
   * @notice This function allows the owner to change the composition of underlying token of the Butter
   * @param _yTokenAddresses An array of addresses for the yToken needed to mint Butter
   * @param _curvePoolTokenPairs An array structs describing underlying yToken, crvToken and curve metapool
   */
  function setCurvePoolTokenPairs(address[] memory _yTokenAddresses, CurvePoolTokenPair[] calldata _curvePoolTokenPairs)
    public
    onlyRole(DAO_ROLE)
  {
    _setCurvePoolTokenPairs(_yTokenAddresses, _curvePoolTokenPairs);
  }

  /**
   * @notice This function defines which underlying token and pools are needed to mint a butter token
   * @param _yTokenAddresses An array of addresses for the yToken needed to mint Butter
   * @param _curvePoolTokenPairs An array structs describing underlying yToken, crvToken and curve metapool
   * @dev since our calculations for minting just iterate through the index and match it with the quantities given by Set
   * @dev we must make sure to align them correctly by index, otherwise our whole calculation breaks down
   */
  function _setCurvePoolTokenPairs(address[] memory _yTokenAddresses, CurvePoolTokenPair[] memory _curvePoolTokenPairs)
    internal
  {
    emit CurveTokenPairsUpdated(_yTokenAddresses, _curvePoolTokenPairs);
    for (uint256 i; i < _yTokenAddresses.length; i++) {
      curvePoolTokenPairs[_yTokenAddresses[i]] = _curvePoolTokenPairs[i];
    }
  }

  /**
   * @notice Changes the redemption fee rate and the fee recipient
   * @param _feeRate Redemption fee rate in basis points
   * @param _recipient The recipient which receives these fees (Should be DAO treasury)
   * @dev Per default both of these values are not set. Therefore a fee has to be explicitly be set with this function
   */
  function setRedemptionFee(uint256 _feeRate, address _recipient) external onlyRole(DAO_ROLE) {
    require(_feeRate <= 100, "dont get greedy");
    redemptionFeeRate = _feeRate;
    feeRecipient = _recipient;
    emit RedemptionFeeUpdated(_feeRate, _recipient);
  }

  /**
   * @notice Claims all accumulated redemption fees in 3CRV
   */
  function claimRedemptionFee() external {
    threeCrv.safeTransfer(feeRecipient, redemptionFees);
    redemptionFees = 0;
  }

  /**
   * @notice Allows the DAO to recover leftover yToken that have accumulated between pages and cant be used effectively in upcoming batches
   * @dev This should only be used if there is a clear trend that a certain amount of yToken leftover wont be used in the minting process
   * @param _yTokenAddress address of the yToken that should be recovered
   * @param _amount amount of yToken that should recovered
   */
  function recoverLeftover(address _yTokenAddress, uint256 _amount) external onlyRole(DAO_ROLE) {
    require(address(curvePoolTokenPairs[_yTokenAddress].curveMetaPool) != address(0), "yToken doesnt exist");
    IERC20(_yTokenAddress).safeTransfer(_getContract(keccak256("Treasury")), _amount);
  }

  /**
   * @notice Toggles an address as Sweetheart (partner addresses that don't pay a redemption fee)
   * @param _sweetheart The address that shall become/lose their sweetheart status
   */
  function updateSweetheart(address _sweetheart, bool _enabled) external onlyRole(DAO_ROLE) {
    sweethearts[_sweetheart] = _enabled;
    emit SweetheartUpdated(_sweetheart, _enabled);
  }

  function setStaking(address _staking) external onlyRole(DAO_ROLE) {
    emit StakingUpdated(address(staking), _staking);
    staking = IStaking(_staking);
  }

  /**
   * @notice Pauses the contract.
   * @dev All function with the modifer `whenNotPaused` cant be called anymore. Namly deposits and mint/redeem
   */
  function pause() external onlyRole(DAO_ROLE) {
    _pause();
  }

  /**
   * @notice Unpauses the contract.
   * @dev All function with the modifer `whenNotPaused` cant be called anymore. Namly deposits and mint/redeem
   */
  function unpause() external onlyRole(DAO_ROLE) {
    _unpause();
  }

  function _getContract(bytes32 _name) internal view override(ACLAuth, ContractRegistryAccess) returns (address) {
    return super._getContract(_name);
  }
}

// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.0

pragma solidity >0.6.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IACLRegistry {
  /**
   * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
   *
   * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
   * {RoleAdminChanged} not being emitted signaling this.
   *
   * _Available since v3.1._
   */
  event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

  /**
   * @dev Emitted when `account` is granted `role`.
   *
   * `sender` is the account that originated the contract call, an admin role
   * bearer except when using {AccessControl-_setupRole}.
   */
  event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

  /**
   * @dev Emitted when `account` is revoked `role`.
   *
   * `sender` is the account that originated the contract call:
   *   - if using `revokeRole`, it is the admin role bearer
   *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
   */
  event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

  /**
   * @dev Returns `true` if `account` has been granted `role`.
   */
  function hasRole(bytes32 role, address account) external view returns (bool);

  /**
   * @dev Returns `true` if `account` has been granted `permission`.
   */
  function hasPermission(bytes32 permission, address account) external view returns (bool);

  /**
   * @dev Returns the admin role that controls `role`. See {grantRole} and
   * {revokeRole}.
   *
   * To change a role's admin, use {AccessControl-_setRoleAdmin}.
   */
  function getRoleAdmin(bytes32 role) external view returns (bytes32);

  /**
   * @dev Grants `role` to `account`.
   *
   * If `account` had not been already granted `role`, emits a {RoleGranted}
   * event.
   *
   * Requirements:
   *
   * - the caller must have ``role``'s admin role.
   */
  function grantRole(bytes32 role, address account) external;

  /**
   * @dev Revokes `role` from `account`.
   *
   * If `account` had been granted `role`, emits a {RoleRevoked} event.
   *
   * Requirements:
   *
   * - the caller must have ``role``'s admin role.
   */
  function revokeRole(bytes32 role, address account) external;

  /**
   * @dev Revokes `role` from the calling account.
   *
   * Roles are often managed via {grantRole} and {revokeRole}: this function's
   * purpose is to provide a mechanism for accounts to lose their privileges
   * if they are compromised (such as when a trusted device is misplaced).
   *
   * If the calling account had been granted `role`, emits a {RoleRevoked}
   * event.
   *
   * Requirements:
   *
   * - the caller must be `account`.
   */
  function renounceRole(bytes32 role, address account) external;

  function setRoleAdmin(bytes32 role, bytes32 adminRole) external;

  function grantPermission(bytes32 permission, address account) external;

  function revokePermission(bytes32 permission) external;

  function requireApprovedContractOrEOA(address account) external view;

  function requireRole(bytes32 role, address account) external view;

  function requirePermission(bytes32 permission, address account) external view;

  function isRoleAdmin(bytes32 role, address account) external view;
}

// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.0

pragma solidity >0.6.0;

/**
 * @dev External interface of ContractRegistry.
 */
interface IContractRegistry {
  function getContract(bytes32 _name) external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.0

pragma solidity ^0.8.0;

interface IStaking {
  function balanceOf(address account) external view returns (uint256);

  function stake(uint256 amount) external;

  function stakeFor(uint256 amount, address account) external;

  function withdraw(uint256 amount) external;

  function notifyRewardAmount(uint256 reward) external;
}

// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.0

pragma solidity ^0.8.0;

import "../interfaces/IACLRegistry.sol";

/**
 *  @notice Provides modifiers and internal functions for interacting with the `ACLRegistry`
 *  @dev Derived contracts using `ACLAuth` must also inherit `ContractRegistryAccess`
 *   and override `_getContract`.
 */
abstract contract ACLAuth {
  /**
   *  @dev Equal to keccak256("Keeper")
   */
  bytes32 internal constant KEEPER_ROLE = 0x4f78afe9dfc9a0cb0441c27b9405070cd2a48b490636a7bdd09f355e33a5d7de;

  /**
   *  @dev Equal to keccak256("DAO")
   */
  bytes32 internal constant DAO_ROLE = 0xd0a4ad96d49edb1c33461cebc6fb2609190f32c904e3c3f5877edb4488dee91e;

  /**
   *  @dev Equal to keccak256("ApprovedContract")
   */
  bytes32 internal constant APPROVED_CONTRACT_ROLE = 0xfb639edf4b4a4724b8b9fb42a839b712c82108c1edf1beb051bcebce8e689dc4;

  /**
   *  @dev Equal to keccak256("ACLRegistry")
   */
  bytes32 internal constant ACL_REGISTRY_ID = 0x15fa0125f52e5705da1148bfcf00974823c4381bee4314203ede255f9477b73e;

  /**
   *  @notice Require that `msg.sender` has given role
   *  @param role bytes32 role ID
   */
  modifier onlyRole(bytes32 role) {
    _requireRole(role);
    _;
  }

  /**
   *  @notice Require that `msg.sender` has given permission
   *  @param role bytes32 permission ID
   */
  modifier onlyPermission(bytes32 role) {
    _requirePermission(role);
    _;
  }

  /**
   *  @notice Require that `msg.sender` has the `ApprovedContract` role or is an EOA
   *  @dev This EOA check requires that `tx.origin == msg.sender` if caller does not have the `ApprovedContract` role.
   *  This limits compatibility with contract-based wallets for functions protected with this modifier.
   */
  modifier onlyApprovedContractOrEOA() {
    _requireApprovedContractOrEOA(msg.sender);
    _;
  }

  /**
   *  @notice Check whether a given account has been granted this bytes32 role
   *  @param role bytes32 role ID
   *  @param account address of account to check for role
   *  @return Whether account has been granted specified role.
   */
  function _hasRole(bytes32 role, address account) internal view returns (bool) {
    return _aclRegistry().hasRole(role, account);
  }

  /**
   *  @notice Require that `msg.sender` has given role
   *  @param role bytes32 role ID
   */
  function _requireRole(bytes32 role) internal view {
    _requireRole(role, msg.sender);
  }

  /**
   *  @notice Require that given account has specified role
   *  @param role bytes32 role ID
   *  @param account address of account to check for role
   */
  function _requireRole(bytes32 role, address account) internal view {
    _aclRegistry().requireRole(role, account);
  }

  /**
   *  @notice Check whether a given account has been granted this bytes32 permission
   *  @param permission bytes32 permission ID
   *  @param account address of account to check for permission
   *  @return Whether account has been granted specified permission.
   */
  function _hasPermission(bytes32 permission, address account) internal view returns (bool) {
    return _aclRegistry().hasPermission(permission, account);
  }

  /**
   *  @notice Require that `msg.sender` has specified permission
   *  @param permission bytes32 permission ID
   */
  function _requirePermission(bytes32 permission) internal view {
    _requirePermission(permission, msg.sender);
  }

  /**
   *  @notice Require that given account has specified permission
   *  @param permission bytes32 permission ID
   *  @param account address of account to check for permission
   */
  function _requirePermission(bytes32 permission, address account) internal view {
    _aclRegistry().requirePermission(permission, account);
  }

  /**
   *  @notice Require that `msg.sender` has the `ApprovedContract` role or is an EOA
   *  @dev This EOA check requires that `tx.origin == msg.sender` if caller does not have the `ApprovedContract` role.
   *  This limits compatibility with contract-based wallets for functions protected with this modifier.
   */
  function _requireApprovedContractOrEOA() internal view {
    _requireApprovedContractOrEOA(msg.sender);
  }

  /**
   *  @notice Require that `account` has the `ApprovedContract` role or is an EOA
   *  @param account address of account to check for role/EOA
   *  @dev This EOA check requires that `tx.origin == msg.sender` if caller does not have the `ApprovedContract` role.
   *  This limits compatibility with contract-based wallets for functions protected with this modifier.
   */
  function _requireApprovedContractOrEOA(address account) internal view {
    _aclRegistry().requireApprovedContractOrEOA(account);
  }

  /**
   *  @notice Return an IACLRegistry interface to the registered ACLRegistry contract
   *  @return IACLRegistry interface to ACLRegistry contract
   */
  function _aclRegistry() internal view returns (IACLRegistry) {
    return IACLRegistry(_getContract(ACL_REGISTRY_ID));
  }

  /**
   *  @notice Get a contract address by name from the contract registry
   *  @param _name bytes32 contract name
   *  @return contract address
   *  @dev Users of this abstract contract should also inherit from `ContractRegistryAccess`
   *   and override `_getContract` in their implementation.
   */
  function _getContract(bytes32 _name) internal view virtual returns (address);
}

// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.0

pragma solidity ^0.8.0;

import "../interfaces/IContractRegistry.sol";

/**
 *  @notice Provides an internal `_getContract` helper function to access the `ContractRegistry`
 */
abstract contract ContractRegistryAccess {
  IContractRegistry internal _contractRegistry;

  constructor(IContractRegistry contractRegistry_) {
    _contractRegistry = contractRegistry_;
  }

  /**
   *  @notice Get a contract address by bytes32 name
   *  @param _name bytes32 contract name
   *  @dev contract name should be a keccak256 hash of the name string, e.g. `keccak256("ContractName")`
   *  @return contract address
   */
  function _getContract(bytes32 _name) internal view virtual returns (address) {
    return _contractRegistry.getContract(_name);
  }
}

// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.0

pragma solidity ^0.8.0;

import "./ISetToken.sol";

interface BasicIssuanceModule {
  function getRequiredComponentUnitsForIssue(ISetToken _setToken, uint256 _quantity)
    external
    view
    returns (address[] memory, uint256[] memory);

  function issue(
    ISetToken _setToken,
    uint256 _quantity,
    address _to
  ) external;

  function redeem(
    ISetToken _setToken,
    uint256 _quantity,
    address _to
  ) external;
}

// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.0

pragma solidity ^0.8.0;

interface Curve3Pool {
  function add_liquidity(uint256[3] calldata amounts, uint256 min_mint_amounts) external;

  function remove_liquidity_one_coin(
    uint256 burn_amount,
    int128 i,
    uint256 min_amount
  ) external;

  function get_virtual_price() external view returns (uint256);

  function calc_withdraw_one_coin(uint256 _token_amount, int128 i) external view returns (uint256);

  function coins(uint256 i) external view returns (address);

  function calc_token_amount(uint256[3] calldata amounts, bool deposit) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface CurveAddressProvider {
  function get_registry() external view returns (address);
}

interface CurveRegistry {
  function get_pool_from_lp_token(address lp_token) external view returns (address);
}

interface CurveMetapool {
  function get_virtual_price() external view returns (uint256);

  function add_liquidity(uint256[2] calldata amounts, uint256 min_mint_amounts) external returns (uint256);

  function add_liquidity(
    uint256[2] calldata _amounts,
    uint256 _min_mint_amounts,
    address _receiver
  ) external returns (uint256);

  function remove_liquidity_one_coin(
    uint256 amount,
    int128 i,
    uint256 min_underlying_amount
  ) external returns (uint256);

  function calc_withdraw_one_coin(uint256 _token_amount, int128 i) external view returns (uint256);
}

interface ThreeCrv is IERC20 {}

interface CrvLPToken is IERC20 {}

// SPDX-License-Identifier: Apache-2.0
// Docgen-SOLC: 0.8.0

/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title ISetToken
 * @author Set Protocol
 *
 * Interface for operating with SetTokens.
 */
interface ISetToken is IERC20 {
  /* ============ Enums ============ */

  enum ModuleState {
    NONE,
    PENDING,
    INITIALIZED
  }

  /* ============ Structs ============ */
  /**
   * The base definition of a SetToken Position
   *
   * @param component           Address of token in the Position
   * @param module              If not in default state, the address of associated module
   * @param unit                Each unit is the # of components per 10^18 of a SetToken
   * @param positionState       Position ENUM. Default is 0; External is 1
   * @param data                Arbitrary data
   */
  struct Position {
    address component;
    address module;
    int256 unit;
    uint8 positionState;
    bytes data;
  }

  /**
   * A struct that stores a component's cash position details and external positions
   * This data structure allows O(1) access to a component's cash position units and
   * virtual units.
   *
   * @param virtualUnit               Virtual value of a component's DEFAULT position. Stored as virtual for efficiency
   *                                  updating all units at once via the position multiplier. Virtual units are achieved
   *                                  by dividing a "real" value by the "positionMultiplier"
   * @param componentIndex
   * @param externalPositionModules   List of external modules attached to each external position. Each module
   *                                  maps to an external position
   * @param externalPositions         Mapping of module => ExternalPosition struct for a given component
   */
  struct ComponentPosition {
    int256 virtualUnit;
    address[] externalPositionModules;
    mapping(address => ExternalPosition) externalPositions;
  }

  /**
   * A struct that stores a component's external position details including virtual unit and any
   * auxiliary data.
   *
   * @param virtualUnit       Virtual value of a component's EXTERNAL position.
   * @param data              Arbitrary data
   */
  struct ExternalPosition {
    int256 virtualUnit;
    bytes data;
  }

  /* ============ Functions ============ */

  function addComponent(address _component) external;

  function removeComponent(address _component) external;

  function editDefaultPositionUnit(address _component, int256 _realUnit) external;

  function addExternalPositionModule(address _component, address _positionModule) external;

  function removeExternalPositionModule(address _component, address _positionModule) external;

  function editExternalPositionUnit(
    address _component,
    address _positionModule,
    int256 _realUnit
  ) external;

  function editExternalPositionData(
    address _component,
    address _positionModule,
    bytes calldata _data
  ) external;

  function invoke(
    address _target,
    uint256 _value,
    bytes calldata _data
  ) external returns (bytes memory);

  function editPositionMultiplier(int256 _newMultiplier) external;

  function mint(address _account, uint256 _quantity) external;

  function burn(address _account, uint256 _quantity) external;

  function lock() external;

  function unlock() external;

  function addModule(address _module) external;

  function removeModule(address _module) external;

  function initializeModule() external;

  function setManager(address _manager) external;

  function manager() external view returns (address);

  function moduleStates(address _module) external view returns (ModuleState);

  function getModules() external view returns (address[] memory);

  function getDefaultPositionRealUnit(address _component) external view returns (int256);

  function getExternalPositionRealUnit(address _component, address _positionModule) external view returns (int256);

  function getComponents() external view returns (address[] memory);

  function getExternalPositionModules(address _component) external view returns (address[] memory);

  function getExternalPositionData(address _component, address _positionModule) external view returns (bytes memory);

  function isExternalPositionModule(address _component, address _module) external view returns (bool);

  function isComponent(address _component) external view returns (bool);

  function positionMultiplier() external view returns (int256);

  function getPositions() external view returns (Position[] memory);

  function getTotalComponentRealUnits(address _component) external view returns (int256);

  function isInitializedModule(address _module) external view returns (bool);

  function isPendingModule(address _module) external view returns (bool);

  function isLocked() external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.6.0

pragma solidity >=0.6.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface YearnVault is IERC20 {
  function token() external view returns (address);

  function deposit(uint256 amount) external;

  function withdraw(uint256 amount) external;

  function pricePerShare() external view returns (uint256);
}