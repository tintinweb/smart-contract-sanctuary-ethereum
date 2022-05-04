// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IRestrictedSwap} from "./interfaces/IRestrictedSwap.sol";
import {IERC1404} from "./interfaces/IERC1404.sol";
import "./Dividends.sol"; //

contract RestrictedSwap is Dividends, IRestrictedSwap {

  using SafeERC20 for IERC20;

  /// @dev swap number
  uint256 public swapNumber = 0;

  /// @dev swap number => swap
  mapping(uint256 => Swap) private _swap;

  modifier onlyValidSwap(uint256 swapNumber) {
    Swap storage swap = _swap[swapNumber];
    require(swap.status != SwapStatus.Canceled, "Already canceled");
    require(swap.status != SwapStatus.Complete, "Already completed");
    _;
  }

  constructor(
    address transferRules_,
    address contractAdmin_,
    address tokenReserveAdmin_,
    string memory symbol_,
    string memory name_,
    uint8 decimals_,
    uint256 totalSupply_,
    uint256 maxTotalSupply_,
    uint _minTimelockAmount,
    uint _maxReleaseDelay
  ) Dividends (
    transferRules_,
    contractAdmin_,
    tokenReserveAdmin_,
    symbol_,
    name_,
    decimals_,
    totalSupply_,
    maxTotalSupply_,
    _minTimelockAmount,
    _maxReleaseDelay
  ) {}

  /**
   * @dev Configures swap and emits an event. This function does not fund tokens. Only for swap configuration.
   * @param restrictedTokenSender restricted token sender
   * @param quoteTokenSender quote token sender
   * @param quoteToken quote token
   * @param restrictedTokenAmount restricted token amount
   * @param quoteTokenAmount quote token amount
   */
  function _configureSwap(
    address restrictedTokenSender,
    address quoteTokenSender,
    address quoteToken,
    uint256 restrictedTokenAmount,
    uint256 quoteTokenAmount,
    SwapStatus configuror
  ) private {
    require(restrictedTokenAmount > 0, "Invalid restricted token amount");
    require(quoteTokenAmount > 0, "Invalid quote token amount");
    require(quoteToken != address(0), "Invalid quote token address");

    uint8 code = detectTransferRestriction(
      restrictedTokenSender,
      quoteTokenSender,
      restrictedTokenAmount);
    string memory message = messageForTransferRestriction(code);
    require(code == 0, message);
    // 0 == success

    bytes memory data = abi.encodeWithSelector(
      IERC1404(quoteToken).detectTransferRestriction.selector,
      quoteTokenSender,
      restrictedTokenSender,
      quoteTokenAmount);
    (bool isErc1404, bytes memory returnData) = quoteToken.call(data);

    if (isErc1404) {
      code = abi.decode(returnData, (uint8));
      message = IERC1404(quoteToken).messageForTransferRestriction(code);
      require(code == 0, message);
      // 0 == success
    }

    swapNumber += 1;

    Swap storage swap = _swap[swapNumber];
    swap.restrictedTokenSender = restrictedTokenSender;
    swap.restrictedTokenAmount = restrictedTokenAmount;
    swap.quoteTokenSender = quoteTokenSender;
    swap.quoteTokenAmount = quoteTokenAmount;
    swap.quoteToken = quoteToken;
    swap.status = configuror;

    emit SwapConfigured(
      swapNumber,
      restrictedTokenSender,
      restrictedTokenAmount,
      quoteToken,
      quoteTokenSender,
      quoteTokenAmount
    );
  }

  /**
   *  @dev Configure swap and emit an event with new swap number
   *  @param restrictedTokenAmount the required amount for the erc1404Sender to send
   *  @param quoteToken the address of an erc1404 or erc20 that will be swapped
   *  @param quoteTokenSender the address that is approved to fund quoteToken
   *  @param quoteTokenAmount the required amount of quoteToken to swap
   */
  function configureSell(
    uint256 restrictedTokenAmount,
    address quoteToken,
    address quoteTokenSender,
    uint256 quoteTokenAmount
  ) external override {
    require(quoteTokenSender != address(0), "Invalid quote token sender");
    require(balanceOf(msg.sender) >= restrictedTokenAmount, "Insufficient restricted token amount");


    _configureSwap(
      msg.sender,
      quoteTokenSender,
      quoteToken,
      restrictedTokenAmount,
      quoteTokenAmount,
      SwapStatus.SellConfigured
    );

    // fund caller's restricted token into swap
    _transfer(msg.sender, address(this), restrictedTokenAmount);
  }

  /**
   *  @dev Configure swap and emit an event with new swap number
   *  @param restrictedTokenAmount the required amount for the erc1404Sender to send
   *  @param restrictedTokenSender restricted token sender
   *  @param quoteToken the address of an erc1404 or erc20 that will be swapped
   *  @param quoteTokenAmount the required amount of quoteToken to swap
   */
  function configureBuy(
    uint256 restrictedTokenAmount,
    address restrictedTokenSender,
    address quoteToken,
    uint256 quoteTokenAmount
  ) external override {
    require(restrictedTokenSender != address(0), "Invalid restricted token sender");

    _configureSwap(
      restrictedTokenSender,
      msg.sender,
      quoteToken,
      restrictedTokenAmount,
      quoteTokenAmount,
      SwapStatus.BuyConfigured
    );

    // fund caller's quote token into swap
    IERC20(quoteToken).safeTransferFrom(msg.sender, address(this), quoteTokenAmount);
  }

  /**
   *  @dev Complete swap with quote token
   *  @param swapNumber swap number
   */
  function completeSwapWithPaymentToken(uint256 swapNumber)
  external
  override
  onlyValidSwap(swapNumber)
  {
    Swap storage swap = _swap[swapNumber];

    require(swap.quoteTokenSender == msg.sender, "You are not appropriate token sender for this swap");

    uint256 balanceBefore = IERC20(swap.quoteToken).balanceOf(swap.restrictedTokenSender);
    IERC20(swap.quoteToken).safeTransferFrom(msg.sender, swap.restrictedTokenSender, swap.quoteTokenAmount);
    uint256 balanceAfter = IERC20(swap.quoteToken).balanceOf(swap.restrictedTokenSender);

    require(balanceBefore + swap.quoteTokenAmount == balanceAfter, "Deposit reverted for incorrect result of deposited amount");

    swap.status = SwapStatus.Complete;

    _transfer(address(this), swap.quoteTokenSender, swap.restrictedTokenAmount);

    emit SwapComplete(
      swapNumber,
      swap.restrictedTokenSender,
      swap.restrictedTokenAmount,
      swap.quoteTokenSender,
      swap.quoteToken,
      swap.quoteTokenAmount
    );
  }

  /**
   *  @dev Complete swap with restricted token
   *  @param swapNumber swap number
   */
  function completeSwapWithRestrictedToken(uint256 swapNumber)
  external
  override
  onlyValidSwap(swapNumber)
  {
    Swap storage swap = _swap[swapNumber];

    require(swap.restrictedTokenSender == msg.sender, "You are not appropriate token sender for this swap");

    uint256 balanceBefore = IERC20(swap.quoteToken).balanceOf(swap.restrictedTokenSender);
    IERC20(swap.quoteToken).safeTransfer(msg.sender, swap.quoteTokenAmount);
    uint256 balanceAfter = IERC20(swap.quoteToken).balanceOf(swap.restrictedTokenSender);

    require(balanceBefore + swap.quoteTokenAmount == balanceAfter, "Deposit reverted for incorrect result of deposited amount");

    swap.status = SwapStatus.Complete;

    _transfer(msg.sender, swap.quoteTokenSender, swap.restrictedTokenAmount);

    emit SwapComplete(
      swapNumber,
      swap.restrictedTokenSender,
      swap.restrictedTokenAmount,
      swap.quoteTokenSender,
      swap.quoteToken,
      swap.quoteTokenAmount
    );
  }

  /**
   *  @dev cancel swap
   *  @param swapNumber swap number
   */
  function cancelSell(uint256 swapNumber)
  external
  override
  onlyValidSwap(swapNumber)
  {
    Swap storage swap = _swap[swapNumber];

    require(swap.restrictedTokenSender != address(0), "This swap is not configured");
    require(swap.quoteTokenSender != address(0), "This swap is not configured");

    if (swap.status == SwapStatus.SellConfigured) {
      require(msg.sender == swap.restrictedTokenSender, "Only swap configurator can cancel the swap");
      _transfer(address(this), swap.restrictedTokenSender, swap.restrictedTokenAmount);
    } else if (swap.status == SwapStatus.BuyConfigured) {
      require(msg.sender == swap.quoteTokenSender, "Only swap configurator can cancel the swap");
      IERC20(swap.quoteToken).safeTransfer(swap.quoteTokenSender, swap.quoteTokenAmount);
    }

    swap.status = SwapStatus.Canceled;

    emit SwapCanceled(msg.sender, swapNumber);
  }

  /**
   * @dev Returns the swap status if exists
   * @param swapNumber swap number
   * @return SwapStatus status of the swap record
   */
  function swapStatus(uint256 swapNumber)
  external
  override
  view
    /*onlyWalletsAdminOrReserveAdmin*/
  returns
  (SwapStatus)
  {
    require(_swap[swapNumber].restrictedTokenSender != address(0), "Swap record not exists");
    return _swap[swapNumber].status;
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

pragma solidity 0.8.4;

interface IRestrictedSwap {  

  /************************
   * Data Structures
   ************************/
  
  enum SwapStatus {
    SellConfigured,
    BuyConfigured,
    Complete,
    Canceled
  }

  struct Swap {
    address restrictedTokenSender;
    address quoteTokenSender;
    address quoteToken;
    uint256 restrictedTokenAmount;
    uint256 quoteTokenAmount;
    SwapStatus status;
  }

  /************************
   * Functions
   ************************/

  /**
   *  @dev Configure swap and emit an event with new swap number
   *  @param restrictedTokenAmount the required amount for the erc1404Sender to send
   *  @param quoteToken the address of an erc1404 or erc20 that will be swapped
   *  @param token2Address the address that is approved to fund quoteToken
   *  @param quoteTokenAmount the required amount of quoteToken to swap
   */
  function configureSell(
    uint restrictedTokenAmount,
    address quoteToken,
    address token2Address,
    uint quoteTokenAmount
  ) external;

  /**
   *  @dev Configure swap and emit an event with new swap number
   *  @param restrictedTokenAmount the required amount for the erc1404Sender to send
   *  @param restrictedTokenSender restricted token sender
   *  @param quoteToken the address of an erc1404 or erc20 that will be swapped
   *  @param quoteTokenAmount the required amount of quoteToken to swap
   */
  function configureBuy(
    uint256 restrictedTokenAmount,
    address restrictedTokenSender,
    address quoteToken,
    uint256 quoteTokenAmount
  ) external;

  /**
   *  @dev Complete swap with quote token
   *  @param swapNumber swap number
   */
  function completeSwapWithPaymentToken(uint swapNumber) external;

  /**
   *  @dev Complete swap with restricted token
   *  @param swapNumber swap number
   */
  function completeSwapWithRestrictedToken(uint swapNumber) external;

  /**
   *  @dev cancel swap
   *  @param swapNumber swap number
   */
  function cancelSell(uint swapNumber) external;

  /**
   * @dev Returns the swap status if exists
   * @param swapNumber swap number
   * @return SwapStatus status of the swap record
   */
  function swapStatus(uint256 swapNumber) external view returns (SwapStatus);

  /****************************
   * Events
   ****************************/

  event SwapCanceled(address sender, uint256 swapNumber);

  event SwapConfigured(
    uint256 swapNumber,
    address restrictedTokenSender,
    uint256 restrictedTokenAmount,
    address quoteToken,
    address quoteTokenSender,
    uint256 quoteTokenAmount
  );

  event SwapComplete(
    uint256 swapNumber,
    address restrictedTokenSender,
    uint256 restrictedTokenAmount,
    address quoteTokenSender,
    address quoteToken,
    uint256 quoteTokenAmount
  );
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC1404 is IERC20 {
  function detectTransferRestriction(
    address from,
    address to,
    uint256 value
  ) external view returns(uint8);

  function messageForTransferRestriction(
    uint8 restrictionCode
  ) external view returns(string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/IDividends.sol";
import "./RestrictedLockupToken.sol"; //

contract Dividends is IDividends, RestrictedLockupToken {

  using SafeERC20 for IERC20;

  struct TokensFunded {
    uint256 total;
    uint256 unused;
  }

  /// @dev snapshotID => funderAddress => token => getAmount;
  mapping(uint256 => mapping(address => mapping(address => uint256))) claimedTokens;

  /// @dev snapshotID => token => totalAmount of token
  mapping(uint256 => mapping(address => TokensFunded)) tokensFunded;

  /// @dev Accuracy of division
  uint256 public constant tokenPrecisionDivider = 10000;

  /**
   * @dev Contract constructor
   */
  constructor(
    address transferRules_,
    address contractAdmin_,
    address tokenReserveAdmin_,
    string memory symbol_,
    string memory name_,
    uint8 decimals_,
    uint256 totalSupply_,
    uint256 maxTotalSupply_,
    uint _minTimelockAmount,
    uint _maxReleaseDelay
  ) RestrictedLockupToken (
    transferRules_,
    contractAdmin_,
    tokenReserveAdmin_,
    symbol_,
    name_,
    decimals_,
    totalSupply_,
    maxTotalSupply_,
    _minTimelockAmount,
    _maxReleaseDelay
  ) { }

  /// @dev Withdrawal remains of unused ERC-20 tokens at snapshot
  /// @param token ERC-20 token address
  /// @param snapshotId Snapshot ID
  function withdrawalRemains(address token, uint256 snapshotId) override public onlyContractAdmin nonReentrant {
    require(token != address(0), "BAD TOKEN ADDRESS");

    uint256 amount = tokensAt(token, snapshotId);

    IERC20(token).safeTransfer(msg.sender, amount);

    tokensFunded[snapshotId][token].unused -= amount;

    emit Withdrawn(msg.sender, token, amount, snapshotId);
  }

  /**
   * @dev Fund any ERC-20 tokens into current contract
   * Tokens can be claimed by holders of RestrictedSwap Token uses claimDividends method
   * @param token ERC-20 token address
   * @param amount amount of tokens to fund
   * @param snapshotId snapshot ID of RestrictedSwap Token
   */
  function fundDividend(address token, uint256 amount, uint256 snapshotId) override public {
    require(token != address(0), "BAD TOKEN ADDRESS");

    IERC20 paymentToken = IERC20(token);

    paymentToken.safeTransferFrom(msg.sender, address(this), amount);

    tokensFunded[snapshotId][token].total += amount;
    tokensFunded[snapshotId][token].unused += amount;

    emit Funded(msg.sender, token, amount, snapshotId);
  }

  /// @dev Get unused ERC-20 tokens on snapshot
  /// @param token ERC-20 token address
  /// @param snapshotId Snapshot ID
  /// @return amount of ERC-20 tokens
  function tokensAt(address token, uint256 snapshotId) override public view returns (uint256) {
    uint256 amount = tokensFunded[snapshotId][token].unused;
    if ( amount > 0 ) return amount;
    return 0;
  }

  /**
   * @dev Get balance of ERC-20 tokens funded at snapshot
   * @param token ERC-20 token address
   * @param snapshotId snapshot ID of RestrictedSwap Token
   * @return amount of ERC-20 tokens
   */
  function fundsAt(address token, uint256 snapshotId) override public view returns (uint256) {
    return tokensFunded[snapshotId][token].total;
  }

  /**
   * @dev Amount of ERC-20 tokens distributed to the holder of RestrictedSwap Token at snapshot
   * @param token ERC-20 token address
   * @param receiver RestrictedSwap Token's holder address
   * @param snapshotId snapshot ID of RestrictedSwap Token
   * @return amount of total ERC-20 tokens distributed to the receiver
   */
  function totalAwardedBalanceAt(address token, address receiver, uint256 snapshotId) override public view returns (uint256) {
    uint256 secTokenBalance = this.balanceOfAt(receiver, snapshotId);
    uint256 totalSupply = this.totalSupplyAt(snapshotId);
    uint256 share = (secTokenBalance * tokenPrecisionDivider) / totalSupply;
    return (tokensFunded[snapshotId][token].total * share) / tokenPrecisionDivider;
  }

  /**
   * @dev Amount of ERC-20 tokens claimed by the holder of RestrictedSwap Token at snapshot
   * @param token ERC-20 token address
   * @param receiver RestrictedSwap Token's holder address
   * @param snapshotId snapshot ID of RestrictedSwap Token
   * @return amount of claimed ERC-20 tokens
   */
  function claimedBalanceAt(address token, address receiver, uint256 snapshotId) override public view returns (uint256) {
    return claimedTokens[snapshotId][token][receiver];
  }

  /**
   * @dev Amount of ERC-20 tokens that can be claimed by the holder of RestrictedSwap Token at snapshot
   * @param token ERC-20 token address
   * @param receiver RestrictedSwap Token's holder address
   * @param snapshotId snapshot ID of RestrictedSwap Token
   * @return amount of can be claimed ERC-20 tokens
   */
  function unclaimedBalanceAt(address token, address receiver, uint256 snapshotId) override public view returns (uint256) {
    return totalAwardedBalanceAt(token, receiver, snapshotId) - claimedBalanceAt(token, receiver, snapshotId);
  }

  /**
   * @dev Claim ERC-20 tokens (dividends) by RestrictedSwap Tokens holder
   * Tokens can be claimed when its allowed by unclaimedBalanceAt
   * @param token ERC-20 token address
   * @param snapshotId snapshot ID of RestrictedSwap Token
   */
  function claimDividend(address token, uint256 snapshotId) override public nonReentrant {
    uint256 unclaimedBalance = unclaimedBalanceAt(token, msg.sender, snapshotId);

    require(unclaimedBalance > 0, "YOU CAN`T RECEIVE MORE TOKENS");

    IERC20(token).safeTransfer(msg.sender, unclaimedBalance);

    claimedTokens[snapshotId][token][msg.sender] += unclaimedBalance;

    tokensFunded[snapshotId][token].unused -= unclaimedBalance;

    emit Claimed(msg.sender, token, unclaimedBalance, snapshotId);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/ERC20Snapshot.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Arrays.sol";
import "../../../utils/Counters.sol";

/**
 * @dev This contract extends an ERC20 token with a snapshot mechanism. When a snapshot is created, the balances and
 * total supply at the time are recorded for later access.
 *
 * This can be used to safely create mechanisms based on token balances such as trustless dividends or weighted voting.
 * In naive implementations it's possible to perform a "double spend" attack by reusing the same balance from different
 * accounts. By using snapshots to calculate dividends or voting power, those attacks no longer apply. It can also be
 * used to create an efficient ERC20 forking mechanism.
 *
 * Snapshots are created by the internal {_snapshot} function, which will emit the {Snapshot} event and return a
 * snapshot id. To get the total supply at the time of a snapshot, call the function {totalSupplyAt} with the snapshot
 * id. To get the balance of an account at the time of a snapshot, call the {balanceOfAt} function with the snapshot id
 * and the account address.
 *
 * NOTE: Snapshot policy can be customized by overriding the {_getCurrentSnapshotId} method. For example, having it
 * return `block.number` will trigger the creation of snapshot at the begining of each new block. When overridding this
 * function, be careful about the monotonicity of its result. Non-monotonic snapshot ids will break the contract.
 *
 * Implementing snapshots for every block using this method will incur significant gas costs. For a gas-efficient
 * alternative consider {ERC20Votes}.
 *
 * ==== Gas Costs
 *
 * Snapshots are efficient. Snapshot creation is _O(1)_. Retrieval of balances or total supply from a snapshot is _O(log
 * n)_ in the number of snapshots that have been created, although _n_ for a specific account will generally be much
 * smaller since identical balances in subsequent snapshots are stored as a single entry.
 *
 * There is a constant overhead for normal ERC20 transfers due to the additional snapshot bookkeeping. This overhead is
 * only significant for the first transfer that immediately follows a snapshot for a particular account. Subsequent
 * transfers will have normal cost until the next snapshot, and so on.
 */

abstract contract ERC20Snapshot is ERC20 {
    // Inspired by Jordi Baylina's MiniMeToken to record historical balances:
    // https://github.com/Giveth/minimd/blob/ea04d950eea153a04c51fa510b068b9dded390cb/contracts/MiniMeToken.sol

    using Arrays for uint256[];
    using Counters for Counters.Counter;

    // Snapshotted values have arrays of ids and the value corresponding to that id. These could be an array of a
    // Snapshot struct, but that would impede usage of functions that work on an array.
    struct Snapshots {
        uint256[] ids;
        uint256[] values;
    }

    mapping(address => Snapshots) private _accountBalanceSnapshots;
    Snapshots private _totalSupplySnapshots;

    // Snapshot ids increase monotonically, with the first value being 1. An id of 0 is invalid.
    Counters.Counter private _currentSnapshotId;

    /**
     * @dev Emitted by {_snapshot} when a snapshot identified by `id` is created.
     */
    event Snapshot(uint256 id);

    /**
     * @dev Creates a new snapshot and returns its snapshot id.
     *
     * Emits a {Snapshot} event that contains the same id.
     *
     * {_snapshot} is `internal` and you have to decide how to expose it externally. Its usage may be restricted to a
     * set of accounts, for example using {AccessControl}, or it may be open to the public.
     *
     * [WARNING]
     * ====
     * While an open way of calling {_snapshot} is required for certain trust minimization mechanisms such as forking,
     * you must consider that it can potentially be used by attackers in two ways.
     *
     * First, it can be used to increase the cost of retrieval of values from snapshots, although it will grow
     * logarithmically thus rendering this attack ineffective in the long term. Second, it can be used to target
     * specific accounts and increase the cost of ERC20 transfers for them, in the ways specified in the Gas Costs
     * section above.
     *
     * We haven't measured the actual numbers; if this is something you're interested in please reach out to us.
     * ====
     */
    function _snapshot() internal virtual returns (uint256) {
        _currentSnapshotId.increment();

        uint256 currentId = _getCurrentSnapshotId();
        emit Snapshot(currentId);
        return currentId;
    }

    /**
     * @dev Get the current snapshotId
     */
    function _getCurrentSnapshotId() internal view virtual returns (uint256) {
        return _currentSnapshotId.current();
    }

    /**
     * @dev Retrieves the balance of `account` at the time `snapshotId` was created.
     */
    function balanceOfAt(address account, uint256 snapshotId) public view virtual returns (uint256) {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _accountBalanceSnapshots[account]);

        return snapshotted ? value : balanceOf(account);
    }

    /**
     * @dev Retrieves the total supply at the time `snapshotId` was created.
     */
    function totalSupplyAt(uint256 snapshotId) public view virtual returns (uint256) {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _totalSupplySnapshots);

        return snapshotted ? value : totalSupply();
    }

    // Update balance and/or total supply snapshots before the values are modified. This is implemented
    // in the _beforeTokenTransfer hook, which is executed for _mint, _burn, and _transfer operations.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        if (from == address(0)) {
            // mint
            _updateAccountSnapshot(to);
            _updateTotalSupplySnapshot();
        } else if (to == address(0)) {
            // burn
            _updateAccountSnapshot(from);
            _updateTotalSupplySnapshot();
        } else {
            // transfer
            _updateAccountSnapshot(from);
            _updateAccountSnapshot(to);
        }
    }

    function _valueAt(uint256 snapshotId, Snapshots storage snapshots) private view returns (bool, uint256) {
        require(snapshotId > 0, "ERC20Snapshot: id is 0");
        require(snapshotId <= _getCurrentSnapshotId(), "ERC20Snapshot: nonexistent id");

        // When a valid snapshot is queried, there are three possibilities:
        //  a) The queried value was not modified after the snapshot was taken. Therefore, a snapshot entry was never
        //  created for this id, and all stored snapshot ids are smaller than the requested one. The value that corresponds
        //  to this id is the current one.
        //  b) The queried value was modified after the snapshot was taken. Therefore, there will be an entry with the
        //  requested id, and its value is the one to return.
        //  c) More snapshots were created after the requested one, and the queried value was later modified. There will be
        //  no entry for the requested id: the value that corresponds to it is that of the smallest snapshot id that is
        //  larger than the requested one.
        //
        // In summary, we need to find an element in an array, returning the index of the smallest value that is larger if
        // it is not found, unless said value doesn't exist (e.g. when all values are smaller). Arrays.findUpperBound does
        // exactly this.

        uint256 index = snapshots.ids.findUpperBound(snapshotId);

        if (index == snapshots.ids.length) {
            return (false, 0);
        } else {
            return (true, snapshots.values[index]);
        }
    }

    function _updateAccountSnapshot(address account) private {
        _updateSnapshot(_accountBalanceSnapshots[account], balanceOf(account));
    }

    function _updateTotalSupplySnapshot() private {
        _updateSnapshot(_totalSupplySnapshots, totalSupply());
    }

    function _updateSnapshot(Snapshots storage snapshots, uint256 currentValue) private {
        uint256 currentId = _getCurrentSnapshotId();
        if (_lastSnapshotId(snapshots.ids) < currentId) {
            snapshots.ids.push(currentId);
            snapshots.values.push(currentValue);
        }
    }

    function _lastSnapshotId(uint256[] storage ids) private view returns (uint256) {
        if (ids.length == 0) {
            return 0;
        } else {
            return ids[ids.length - 1];
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

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
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;



interface IDividends  {

  /************************
   * Functions
   ************************/

  /// @dev Get unused ERC-20 tokens on snapshot
  /// @param token ERC-20 token address
  /// @param snapshotId Snapshot ID
  /// @return amount of ERC-20 tokens
  function tokensAt(address token, uint256 snapshotId) external view returns (uint256);

  /// @dev Withdrawal remains of unused ERC-20 tokens at snapshot
  /// @param token ERC-20 token address
  /// @param snapshotId Snapshot ID
  function withdrawalRemains(address token, uint256 snapshotId) external;

  /**
   * @dev Fund any ERC-20 tokens into current contract
   * Tokens can be claimed by holders of RestrictedSwap Token uses claimDividends method
   * @param token ERC-20 token address
   * @param amount amount of tokens to fund
   * @param snapshotId snapshot ID of RestrictedSwap Token
   */
  function fundDividend(address token, uint256 amount, uint256 snapshotId) external;

  /**
   * @dev Get balance of ERC-20 tokens funded at snapshot
   * @param token ERC-20 token address
   * @param snapshotId snapshot ID of RestrictedSwap Token
   * @return amount of ERC-20 tokens
   */
  function fundsAt(address token, uint256 snapshotId) external view returns (uint256);

  /**
   * @dev Amount of ERC-20 tokens distributed to the holder of RestrictedSwap Token at snapshot
   * @param token ERC-20 token address
   * @param receiver RestrictedSwap Token's holder address
   * @param snapshotId snapshot ID of RestrictedSwap Token
   * @return amount of total ERC-20 tokens distributed to the receiver
   */
  function totalAwardedBalanceAt(address token, address receiver, uint256 snapshotId) external view returns (uint256);

  /**
   * @dev Amount of ERC-20 tokens claimed by the holder of RestrictedSwap Token at snapshot
   * @param token ERC-20 token address
   * @param receiver RestrictedSwap Token's holder address
   * @param snapshotId snapshot ID of RestrictedSwap Token
   * @return amount of claimed ERC-20 tokens
   */
  function claimedBalanceAt(address token, address receiver, uint256 snapshotId) external view returns (uint256);

  /**
   * @dev Amount of ERC-20 tokens that can be claimed by the holder of RestrictedSwap Token at snapshot
   * @param token ERC-20 token address
   * @param receiver RestrictedSwap Token's holder address
   * @param snapshotId snapshot ID of RestrictedSwap Token
   * @return amount of can be claimed ERC-20 tokens
   */
  function unclaimedBalanceAt(address token, address receiver, uint256 snapshotId) external view returns (uint256);

  /**
   * @dev Claim ERC-20 tokens (dividends) by RestrictedSwap Tokens holder
   * Tokens can be claimed when its allowed by unclaimedBalanceAt
   * @param token ERC-20 token address
   * @param snapshotId snapshot ID of RestrictedSwap Token
   */
  function claimDividend(address token, uint256 snapshotId) external;

  /****************************
   * Events
   ****************************/

  event Funded (address indexed payer, address indexed token, uint256 amount, uint256 indexed snapshotId);
  event Claimed (address indexed payee, address indexed token, uint256 amount, uint256 indexed snapshotId);
  event Withdrawn (address indexed payee, address indexed token, uint256 amount, uint256 indexed snapshotId);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/ITransferRules.sol";
import "./EasyAccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
  @title A smart contract for unlocking tokens based on a release schedule
  @author By CoMakery, Inc., Upside, Republic
  @dev When deployed the contract is as a proxy for a single token that it creates release schedules for
      it implements the ERC20 token interface to integrate with wallets but it is not an independent token.
      The token must implement a burn function.
*/
contract RestrictedLockupToken is ERC20Snapshot, EasyAccessControl, ReentrancyGuard {

  using SafeERC20 for IERC20;

  struct ReleaseSchedule {
    uint releaseCount;
    uint delayUntilFirstReleaseInSeconds;
    uint initialReleasePortionInBips;
    uint periodBetweenReleasesInSeconds;
  }

  struct Timelock {
    uint scheduleId;
    uint commencementTimestamp;
    uint tokensTransferred;
    uint totalAmount;
    address[] cancelableBy; // not cancelable unless set at the time of funding
  }

  ReleaseSchedule[] public releaseSchedules;
  uint immutable public minTimelockAmount;
  uint immutable public maxReleaseDelay;
  uint private constant BIPS_PRECISION = 10000;

  mapping(address => Timelock[]) public timelocks;
  mapping(address => uint) internal _totalTokensUnlocked;

  event ScheduleCreated(address indexed from, uint indexed scheduleId);

  event ScheduleFunded(
    address indexed from,
    address indexed to,
    uint indexed scheduleId,
    uint amount,
    uint commencementTimestamp,
    uint timelockId,
    address[] cancelableBy
  );

  event TimelockCanceled(
    address indexed canceledBy,
    address indexed target,
    uint indexed timelockIndex,
    address relaimTokenTo,
    uint canceledAmount,
    uint paidAmount
  );

  uint8 public _decimals;

  ITransferRules public transferRules;

  uint256 public maxTotalSupply;

  // Transfer restriction "eternal storage" mappings that can be used by future TransferRules contract upgrades
  // They are accessed through getter and setter methods
  mapping(address => uint256) private _maxBalances;
  mapping(address => uint256) private _transferGroups; // restricted groups like Reg D Accredited US, Reg CF Unaccredited US and Reg S Foreign

  mapping(uint256 => mapping(uint256 => uint256)) private _allowGroupTransfers; // approve transfers between groups: from => to => TimeLockUntil

  mapping(address => bool) private _frozenAddresses;

  bool public isPaused = false;

  event AddressMaxBalance(address indexed admin, address indexed addr, uint256 indexed value);

  event AddressTransferGroup(address indexed admin, address indexed addr, uint256 indexed value);
  event AddressFrozen(address indexed admin, address indexed addr, bool indexed status);
  event AllowGroupTransfer(address indexed admin, uint256 indexed fromGroup, uint256 indexed toGroup, uint256 lockedUntil);

  event Pause(address admin, bool status);
  event Upgrade(address admin, address oldRules, address newRules);

  /**
    @dev Configure deployment for a specific token with release schedule security parameters
    @dev The symbol should end with " Unlock" & be less than 11 characters for MetaMask "custom token" compatibility
  */
  constructor (
    address transferRules_,
    address contractAdmin_,
    address tokenReserveAdmin_,
    string memory symbol_,
    string memory name_,
    uint8 decimals_,
    uint256 totalSupply_,
    uint256 maxTotalSupply_,
    uint _minTimelockAmount,
    uint _maxReleaseDelay
  ) ERC20(name_, symbol_) ReentrancyGuard() {
    // Restricted Token
    require(transferRules_ != address(0), "Transfer rules address cannot be 0x0");
    require(contractAdmin_ != address(0), "Token owner address cannot be 0x0");
    require(tokenReserveAdmin_ != address(0), "Token reserve admin address cannot be 0x0");

    // Transfer rules can be swapped out for a new contract inheriting from the ITransferRules interface
    // The "eternal storage" for rule data stays in this RestrictedToken contract for use by TransferRules contract upgrades
    transferRules = ITransferRules(transferRules_);
    _decimals = decimals_;
    maxTotalSupply = maxTotalSupply_;

    admins[contractAdmin_] = CONTRACT_ADMIN_ROLE;
    contractAdminCount = 1;

    admins[tokenReserveAdmin_] |= RESERVE_ADMIN_ROLE;

    _mint(tokenReserveAdmin_, totalSupply_);

    // Token Lockup

    // Setup minimal fund payment for timelock
    if ( _minTimelockAmount == 0 ) {
      _minTimelockAmount = 100 * (10 ** _decimals); // 100 tokens
    }

    minTimelockAmount = _minTimelockAmount;
    maxReleaseDelay = _maxReleaseDelay;
  }

  modifier onlyWalletsAdminOrReserveAdmin() {
    require((hasRole(msg.sender, WALLETS_ADMIN_ROLE) || hasRole(msg.sender, RESERVE_ADMIN_ROLE)),
      "DOES NOT HAVE WALLETS ADMIN OR RESERVE ADMIN ROLE");
    _;
  }

  function decimals() public view virtual override returns (uint8) {
    return _decimals;
  }

  // Create new snapshot
  function snapshot() external onlyContractAdmin returns (uint256)  {
    return _snapshot();
  }

  // Get current snapshot ID
  function getCurrentSnapshotId() view external returns (uint256) {
    return _getCurrentSnapshotId();
  }

  /// @dev Sets the maximum number of tokens an address will be allowed to hold.
  /// Addresses can hold 0 tokens by default.
  /// @param addr The address to restrict
  /// @param updatedValue the maximum number of tokens the address can hold
  function setMaxBalance(address addr, uint256 updatedValue) public validAddress(addr) onlyWalletsAdmin {
    _maxBalances[addr] = updatedValue;
    emit AddressMaxBalance(msg.sender, addr, updatedValue);
  }

  /// @dev Gets the maximum number of tokens an address is allowed to hold
  /// @param addr The address to check restrictions for
  function getMaxBalance(address addr) external view returns (uint256) {
    return _maxBalances[addr];
  }

  /**
    @notice Create a release schedule template that can be used to generate many token timelocks
    @param releaseCount Total number of releases including any initial "cliff'
    @param delayUntilFirstReleaseInSeconds "cliff" or 0 for immediate release
    @param initialReleasePortionInBips Portion to release in 100ths of 1% (10000 BIPS per 100%)
    @param periodBetweenReleasesInSeconds After the delay and initial release
        the remaining tokens will be distributed evenly across the remaining number of releases (releaseCount - 1)
    @return unlockScheduleId The id used to refer to the release schedule at the time of funding the schedule
  */
  function createReleaseSchedule(
    uint releaseCount,
    uint delayUntilFirstReleaseInSeconds,
    uint initialReleasePortionInBips,
    uint periodBetweenReleasesInSeconds
  ) external returns (uint unlockScheduleId) {
    require(delayUntilFirstReleaseInSeconds <= maxReleaseDelay, "first release > max");
    require(releaseCount >= 1, "< 1 release");
    require(initialReleasePortionInBips <= BIPS_PRECISION, "release > 100%");

    if (releaseCount > 1) {
      require(periodBetweenReleasesInSeconds > 0, "period = 0");
    } else if (releaseCount == 1) {
      require(initialReleasePortionInBips == BIPS_PRECISION, "released < 100%");
    }

    releaseSchedules.push(ReleaseSchedule(
        releaseCount,
        delayUntilFirstReleaseInSeconds,
        initialReleasePortionInBips,
        periodBetweenReleasesInSeconds
      ));

    unlockScheduleId = releaseSchedules.length - 1;
    emit ScheduleCreated(msg.sender, unlockScheduleId);

    return unlockScheduleId;
  }

  /**
    @notice Fund the programmatic release of tokens to a recipient.
        WARNING: this function IS CANCELABLE by cancelableBy.
        If canceled the tokens that are locked at the time of the cancellation will be returned to the funder
        and unlocked tokens will be transferred to the recipient.
    @param to recipient address that will have tokens unlocked on a release schedule
    @param amount of tokens to transfer in base units (the smallest unit without the decimal point)
    @param commencementTimestamp the time the release schedule will start
    @param scheduleId the id of the release schedule that will be used to release the tokens
    @param cancelableBy array of canceler addresses
    @return success Always returns true on completion so that a function calling it can revert if the required call did not succeed
  */
  function fundReleaseSchedule(
    address to,
    uint amount,
    uint commencementTimestamp, // unix timestamp
    uint scheduleId,
    address[] memory cancelableBy
  ) public nonReentrant returns (bool success) {
    require(cancelableBy.length <= 10, "max 10 cancelableBy addressees");

    uint timelockId = _fund(to, amount, commencementTimestamp, scheduleId);

    if (cancelableBy.length > 0) {
      timelocks[to][timelockId].cancelableBy = cancelableBy;
    }

    emit ScheduleFunded(msg.sender, to, scheduleId, amount, commencementTimestamp, timelockId, cancelableBy);
    return true;
  }


  function _fund(
    address to,
    uint amount,
    uint commencementTimestamp, // unix timestamp
    uint scheduleId)
  internal returns (uint) {
    require(amount >= minTimelockAmount, "amount < min funding");
    require(to != address(0), "to 0 address");
    require(scheduleId < releaseSchedules.length, "bad scheduleId");
    require(amount >= releaseSchedules[scheduleId].releaseCount, "< 1 token per release");

    _transfer(address(this), amount);

    require(
      commencementTimestamp + releaseSchedules[scheduleId].delayUntilFirstReleaseInSeconds <=
      block.timestamp + maxReleaseDelay
    , "initial release out of range");

    Timelock memory timelock;
    timelock.scheduleId = scheduleId;
    timelock.commencementTimestamp = commencementTimestamp;
    timelock.totalAmount = amount;

    timelocks[to].push(timelock);
    return timelockCountOf(to) - 1;
  }

  /**
    @notice Cancel a cancelable timelock created by the fundReleaseSchedule function.
        WARNING: this function cannot cancel a release schedule created by fundReleaseSchedule
        If canceled the tokens that are locked at the time of the cancellation will be returned to the funder
        and unlocked tokens will be transferred to the recipient.
    @param target The address that would receive the tokens when released from the timelock.
    @param timelockIndex timelock index
    @param target The address that would receive the tokens when released from the timelock
    @param scheduleId require it matches expected
    @param commencementTimestamp require it matches expected
    @param totalAmount require it matches expected
    @param reclaimTokenTo reclaim token to
    @return success Always returns true on completion so that a function calling it can revert if the required call did not succeed
  */
  function cancelTimelock(
    address target,
    uint timelockIndex,
    uint scheduleId,
    uint commencementTimestamp,
    uint totalAmount,
    address reclaimTokenTo
  ) public returns (bool success) {
    require(timelockCountOf(target) > timelockIndex, "invalid timelock");
    require(reclaimTokenTo != address(0), "Invalid reclaimTokenTo");

    Timelock storage timelock = timelocks[target][timelockIndex];

    require(_canBeCanceled(timelock), "You are not allowed to cancel this timelock");
    require(timelock.scheduleId == scheduleId, "Expected scheduleId does not match");
    require(timelock.commencementTimestamp == commencementTimestamp, "Expected commencementTimestamp does not match");
    require(timelock.totalAmount == totalAmount, "Expected totalAmount does not match");

    uint canceledAmount = lockedAmountOfTimelock(target, timelockIndex);

    require(canceledAmount > 0, "Timelock has no value left");

    uint paidAmount = unlockedAmountOfTimelock(target, timelockIndex);

    IERC20(this).safeTransfer(reclaimTokenTo, canceledAmount);
    IERC20(this).safeTransfer(target, paidAmount);

    emit TimelockCanceled(msg.sender, target, timelockIndex, reclaimTokenTo, canceledAmount, paidAmount);

    timelock.tokensTransferred = timelock.totalAmount;
    return true;
  }

  /**
   *  @notice Check if timelock can be cancelable by msg.sender
   */
  function _canBeCanceled(Timelock storage timelock) view private returns (bool){
    for (uint i = 0; i < timelock.cancelableBy.length; i++) {
      if (msg.sender == timelock.cancelableBy[i]) {
        return true;
      }
    }
    return false;
  }

  /**
   *  @notice Batch version of fund cancelable release schedule
   *  @param to An array of recipient address that will have tokens unlocked on a release schedule
   *  @param amounts An array of amount of tokens to transfer in base units (the smallest unit without the decimal point)
   *  @param commencementTimestamps An array of the time the release schedule will start
   *  @param scheduleIds An array of the id of the release schedule that will be used to release the tokens
   *  @param cancelableBy An array of cancelables
   *  @return success Always returns true on completion so that a function calling it can revert if the required call did not succeed
   */
  function batchFundReleaseSchedule(
    address[] calldata to,
    uint[] calldata amounts,
    uint[] calldata commencementTimestamps,
    uint[] calldata scheduleIds,
    address[] calldata cancelableBy
  ) external returns (bool success) {
    require(to.length == amounts.length, "mismatched array length");
    require(to.length == commencementTimestamps.length, "mismatched array length");
    require(to.length == scheduleIds.length, "mismatched array length");

    for (uint i = 0; i < to.length; i++) {
      require(fundReleaseSchedule(
          to[i],
          amounts[i],
          commencementTimestamps[i],
          scheduleIds[i],
          cancelableBy
        ));
    }

    return true;
  }
  /**
    @notice Get The locked balance for a specific address and specific timelock
    @param who The address to check
    @param timelockIndex Specific timelock belonging to the who address
    @return locked Balance of the timelock
    lockedBalanceOfTimelock
  */
  function lockedAmountOfTimelock(address who, uint timelockIndex) public view returns (uint locked) {
    Timelock memory timelock = timelockOf(who, timelockIndex);
    if (timelock.totalAmount <= timelock.tokensTransferred) {
      return 0;
    } else {
      return timelock.totalAmount - totalUnlockedToDateOfTimelock(who, timelockIndex);
    }
  }

  /**
    @notice Get the unlocked balance for a specific address and specific timelock
    @param who the address to check
    @param timelockIndex for a specific timelock belonging to the who address
    @return unlocked balance of the timelock
    unlockedBalanceOfTimelock
  */
  function unlockedAmountOfTimelock(address who, uint timelockIndex) public view returns (uint unlocked) {
    Timelock memory timelock = timelockOf(who, timelockIndex);
    if (timelock.totalAmount <= timelock.tokensTransferred) {
      return 0;
    } else {
      return totalUnlockedToDateOfTimelock(who, timelockIndex) - timelock.tokensTransferred;
    }
  }

  /**
    @notice Check the total remaining balance of a timelock including the locked and unlocked portions
    @param who the address to check
    @param timelockIndex  Specific timelock belonging to the who address
    @return total remaining balance of a timelock
  */
  function balanceOfTimelock(address who, uint timelockIndex) external view returns (uint) {
    Timelock memory timelock = timelockOf(who, timelockIndex);
    if (timelock.totalAmount <= timelock.tokensTransferred) {
      return 0;
    } else {
      return timelock.totalAmount - timelock.tokensTransferred;
    }
  }

  /**
    @notice Gets the total locked and unlocked balance of a specific address's timelocks
    @param who The address to check
    @param timelockIndex The index of the timelock for the who address
    @return total Locked and unlocked amount for the specified timelock
  */
  function totalUnlockedToDateOfTimelock(address who, uint timelockIndex) public view returns (uint total) {
    Timelock memory _timelock = timelockOf(who, timelockIndex);

    return calculateUnlocked(
      _timelock.commencementTimestamp,
      block.timestamp,
      _timelock.totalAmount,
      _timelock.scheduleId
    );
  }

  /**
    @notice ERC20 standard interface function
          Provide controls of Restricted and Lockup tokens
          Can transfer simple ERC-20 tokens and unlocked tokens at the same time
          First will transfer unlocked tokens and then simple ERC-20
    @param recipient of transfer
    @param amount of tokens to transfer
    @return true On success / Reverted on error
  */
  function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
    require(recipient != address(0), "Address cannot be 0x0");
    enforceTransferRestrictions(msg.sender, recipient, amount);
    return _transfer(recipient, amount);
  }

  function _transfer(address recipient, uint256 amount) private returns (bool) {
    uint256[2] memory values = validateTransfer(msg.sender, recipient, amount);
    require(values[0] + values[1] >= amount, "Insufficent tokens");
    if (values[0] > 0) {// unlocked tokens
      super._transfer(address(this), recipient, values[0]);
    }
    if (values[1] > 0) {// simple tokens
      super._transfer(msg.sender, recipient, values[1]);
    }
    return true;
  }

  /**
    @notice ERC20 standard interface function
          Provide controls of Restricted and Lockup tokens
          Can transfer simple ERC-20 tokens and unlocked tokens at the same time
          First will transfer unlocked tokens and then simple ERC-20
    @param sender of transfer
    @param recipient of transfer
    @param amount of tokens to transfer
    @return true On success / Reverted on error
  */
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public virtual override returns (bool) {
    require(recipient != address(0) && sender != address(0), "Address cannot be 0x0");

    uint256 currentAllowance = allowance(sender, msg.sender);

    require(amount <= currentAllowance, "The approved allowance is lower than the transfer amount");
    enforceTransferRestrictions(sender, recipient, amount);

    uint256[2] memory values = validateTransfer(sender, recipient, amount);
    require(values[0] + values[1] >= amount, "Insufficent tokens");

    if (values[0] > 0) { // unlocked tokens
      super._transfer(address(this), recipient, values[0]);

      // Decrease allowance
      unchecked {
        _approve(sender, msg.sender, currentAllowance - values[0]);
      }
    }

    if (values[1] > 0) { // simple tokens
      super.transferFrom(sender, recipient, values[1]);
    }
    return true;
  }

  /**
    @notice Balance of simple ERC20 tokens without any timelocks
    @param who Address to calculate
    @return amount The amount of simple ERC-20 tokens available
    token.balanceOf
  **/
  function tokensBalanceOf(address who) public view returns (uint256) {
    return super.balanceOf(who);
  }

  /**
    @notice Get The total available to transfer balance exclude timelocked
    @param who Address to calculate
    @return amount The total available amount
    no have original
  **/
  function unlockedBalanceOf(address who) public view returns (uint256) {
    return tokensBalanceOf(who) + unlockedAmountOf(who);
  }

  /**
    @notice Get The total balance of tokens (simple + locked + unlocked)
    @param who Address to calculate
    @return amount The total account balance amount
    no have original
  **/
  function balanceOf(address who) public view override returns (uint256) {
    return tokensBalanceOf(who) + unlockedAmountOf(who) + lockedAmountOf(who);
  }

  /**
    @notice Get The total locked balance of an address for all timelocks
    @param who Address to calculate
    @return amount The total locked amount of tokens for all of the who address's timelocks
    lockedBalanceOf
  */
  function lockedAmountOf(address who) public view returns (uint amount) {
    for (uint i = 0; i < timelockCountOf(who); i++) {
      amount += lockedAmountOfTimelock(who, i);
    }
    return amount;
  }

  /**
    @notice Get The total unlocked balance of an address for all timelocks
    @param who Address to calculate
    @return amount The total unlocked amount of tokens for all of the who address's timelocks
    unlockedBalanceOf
  */
  function unlockedAmountOf(address who) public view returns (uint amount) {
    for (uint i = 0; i < timelockCountOf(who); i++) {
      amount += unlockedAmountOfTimelock(who, i);
    }
    return amount;
  }

  /**
    @notice Get timelocked balance - used only in tests
    @param who Address to calculate
    @return Amount of the tokens used in timelocks (locked+unlocked)
    balanceOf
  **/
  function timelockBalanceOf(address who) public view returns (uint) {
    return unlockedAmountOf(who) + lockedAmountOf(who);
  }

  /**
    @notice Check and calculate the availability to transfer tokens between accounts from simple and timelock balances
    @param from Address from
    @param to Address to
    @param value Amount of tokens
    @return values Array of uint256[2] contains unlocked tokens at index 0, and simple ERC-20 at index 1 that can be used for transfer
  **/
  function validateTransfer(address from, address to, uint256 value) internal returns (uint256[2] memory values) {
    uint256 balance = tokensBalanceOf(from);
    uint256 unlockedBalance = unlockedAmountOf(from);

    require(balance + unlockedBalance >= value, "amount > unlocked");

    uint remainingTransfer = value;

    // transfer from unlocked tokens
    for (uint i = 0; i < timelockCountOf(from); i++) {
      // if the timelock has no value left
      if (timelocks[from][i].tokensTransferred == timelocks[from][i].totalAmount) {
        continue;
      } else if (remainingTransfer > unlockedAmountOfTimelock(from, i)) {
        // if the remainingTransfer is more than the unlocked balance use it all
        remainingTransfer -= unlockedAmountOfTimelock(from, i);
        timelocks[from][i].tokensTransferred += unlockedAmountOfTimelock(from, i);
      } else {
        // if the remainingTransfer is less than or equal to the unlocked balance
        // use part or all and exit the loop
        timelocks[from][i].tokensTransferred += remainingTransfer;
        remainingTransfer = 0;
        break;
      }
    }

    values[0] = value - remainingTransfer; // from unlockedValue
    values[1] = remainingTransfer; // from balanceOf
  }

  /**
    @notice transfers the unlocked token from an address's specific timelock
        It is typically more convenient to call transfer. But if the account has many timelocks the cost of gas
        for calling transfer may be too high. Calling transferTimelock from a specific timelock limits the transfer cost.
    @param to the address that the tokens will be transferred to
    @param value the number of token base units to me transferred to the to address
    @param timelockId the specific timelock of the function caller to transfer unlocked tokens from
    @return bool always true when completed
  */
  function transferTimelock(address to, uint value, uint timelockId) public returns (bool) {
    require(unlockedAmountOfTimelock(msg.sender, timelockId) >= value, "amount > unlocked");
    timelocks[msg.sender][timelockId].tokensTransferred += value;
    IERC20(this).safeTransfer(to, value);
    return true;
  }

  /**
    @notice calculates how many tokens would be released at a specified time for a scheduleId.
        This is independent of any specific address or address's timelock.

    @param commencedTimestamp the commencement time to use in the calculation for the scheduled
    @param currentTimestamp the timestamp to calculate unlocked tokens for
    @param amount the amount of tokens
    @param scheduleId the schedule id used to calculate the unlocked amount
    @return unlocked the total amount unlocked for the schedule given the other parameters
  */
  function calculateUnlocked(
    uint commencedTimestamp,
    uint currentTimestamp,
    uint amount,
    uint scheduleId
  ) public view returns (uint unlocked) {
    return calculateUnlocked(commencedTimestamp, currentTimestamp, amount, releaseSchedules[scheduleId]);
  }

  // @notice the total number of schedules that have been created
  function scheduleCount() external view returns (uint count) {
    return releaseSchedules.length;
  }

  /**
    @notice Get the struct details for an address's specific timelock
    @param who Address to check
    @param index The index of the timelock for the who address
    @return timelock Struct with the attributes of the timelock
  */
  function timelockOf(address who, uint index) public view returns (Timelock memory timelock) {
    return timelocks[who][index];
  }

  // @notice returns the total count of timelocks for a specific address
  function timelockCountOf(address who) public view returns (uint) {
    return timelocks[who].length;
  }

  /**
    @notice calculates how many tokens would be released at a specified time for a ReleaseSchedule struct.
            This is independent of any specific address or address's timelock.

    @param commencedTimestamp the commencement time to use in the calculation for the scheduled
    @param currentTimestamp the timestamp to calculate unlocked tokens for
    @param amount the amount of tokens
    @param releaseSchedule a ReleaseSchedule struct used to calculate the unlocked amount
    @return unlocked the total amount unlocked for the schedule given the other parameters
  */
  function calculateUnlocked(
    uint commencedTimestamp,
    uint currentTimestamp,
    uint amount,
    ReleaseSchedule memory releaseSchedule)
  public pure returns (uint unlocked) {
    return calculateUnlocked(
      commencedTimestamp,
      currentTimestamp,
      amount,
      releaseSchedule.releaseCount,
      releaseSchedule.delayUntilFirstReleaseInSeconds,
      releaseSchedule.initialReleasePortionInBips,
      releaseSchedule.periodBetweenReleasesInSeconds
    );
  }

  /**
    @notice The same functionality as above function with spread format of `releaseSchedule` arg
    @param commencedTimestamp the commencement time to use in the calculation for the scheduled
    @param currentTimestamp the timestamp to calculate unlocked tokens for
    @param amount the amount of tokens
    @param releaseCount Total number of releases including any initial "cliff'
    @param delayUntilFirstReleaseInSeconds "cliff" or 0 for immediate release
    @param initialReleasePortionInBips Portion to release in 100ths of 1% (10000 BIPS per 100%)
    @param periodBetweenReleasesInSeconds After the delay and initial release
    @return unlocked the total amount unlocked for the schedule given the other parameters
  */
  function calculateUnlocked(
    uint commencedTimestamp,
    uint currentTimestamp,
    uint amount,
    uint releaseCount,
    uint delayUntilFirstReleaseInSeconds,
    uint initialReleasePortionInBips,
    uint periodBetweenReleasesInSeconds
  ) public pure returns (uint unlocked) {
    if (commencedTimestamp > currentTimestamp) {
      return 0;
    }
    uint secondsElapsed = currentTimestamp - commencedTimestamp;

    // return the full amount if the total lockup period has expired
    // unlocked amounts in each period are truncated and round down remainders smaller than the smallest unit
    // unlocking the full amount unlocks any remainder amounts in the final unlock period
    // this is done first to reduce computation
    if (
      secondsElapsed >= delayUntilFirstReleaseInSeconds +
    (periodBetweenReleasesInSeconds * (releaseCount - 1))
    ) {
      return amount;
    }

    // unlock the initial release if the delay has elapsed
    if (secondsElapsed >= delayUntilFirstReleaseInSeconds) {
      unlocked = (amount * initialReleasePortionInBips) / BIPS_PRECISION;

      // if at least one period after the delay has passed
      if (secondsElapsed - delayUntilFirstReleaseInSeconds >= periodBetweenReleasesInSeconds) {

        // calculate the number of additional periods that have passed (not including the initial release)
        // this discards any remainders (ie it truncates / rounds down)
        uint additionalUnlockedPeriods = (secondsElapsed - delayUntilFirstReleaseInSeconds) / periodBetweenReleasesInSeconds;

        // calculate the amount of unlocked tokens for the additionalUnlockedPeriods
        // multiplication is applied before division to delay truncating to the smallest unit
        // this distributes unlocked tokens more evenly across unlock periods
        // than truncated division followed by multiplication
        unlocked += ((amount - unlocked) * additionalUnlockedPeriods) / (releaseCount - 1);
      }
    }

    return unlocked;
  }

  /// @dev Enforces transfer restrictions managed using the ERC-1404 standard functions.
  /// The TransferRules contract defines what the rules are. The data inputs to those rules remains in the RestrictedToken contract.
  /// TransferRules is a separate contract so its logic can be upgraded.
  /// @param from The address the tokens are transferred from
  /// @param to The address the tokens would be transferred to
  /// @param value the quantity of tokens to be transferred
  function enforceTransferRestrictions(address from, address to, uint256 value) public view {/*private*/
    uint8 restrictionCode = detectTransferRestriction(from, to, value);
    require(transferRules.checkSuccess(restrictionCode), messageForTransferRestriction(restrictionCode));
  }

  /// @dev Calls the TransferRules detectTransferRetriction function to determine if tokens can be transferred.
  /// detectTransferRestriction returns a status code.
  /// @param from The address the tokens are transferred from
  /// @param to The address the tokens would be transferred to
  /// @param value The quantity of tokens to be transferred
  function detectTransferRestriction(address from, address to, uint256 value) public view returns (uint8) {
    return transferRules.detectTransferRestriction(address(this), from, to, value);
  }

  /// @dev Calls TransferRules to lookup a human readable error message that goes with an error code.
  /// @param restrictionCode is an error code to lookup an error code for
  function messageForTransferRestriction(uint8 restrictionCode) public view returns (string memory) {
    return transferRules.messageForTransferRestriction(restrictionCode);
  }

  /// @dev Set the one group that the address belongs to, such as a US Reg CF investor group.
  /// @param addr The address to set the group for.
  /// @param groupID The uint256 numeric ID of the group.
  function setTransferGroup(address addr, uint256 groupID) public validAddress(addr) onlyWalletsAdmin {
    _transferGroups[addr] = groupID;
    emit AddressTransferGroup(msg.sender, addr, groupID);
  }

  /// @dev Gets the transfer group the address belongs to. The default group is 0.
  /// @param addr The address to check.
  /// @return groupID The group id of the address.
  function getTransferGroup(address addr) external view returns (uint256 groupID) {
    return _transferGroups[addr];
  }

  /// @dev Freezes or unfreezes an address.
  /// Tokens in a frozen address cannot be transferred from until the address is unfrozen.
  /// @param addr The address to be frozen.
  /// @param status The frozenAddress status of the address. True means frozen false means not frozen.
  function freeze(address addr, bool status) public validAddress(addr) onlyWalletsAdminOrReserveAdmin {
    _frozenAddresses[addr] = status;
    emit AddressFrozen(msg.sender, addr, status);
  }

  /// @dev Checks the status of an address to see if its frozen
  /// @param addr The address to check
  /// @return status Returns true if the address is frozen and false if its not frozen.
  function getFrozenStatus(address addr) external view returns (bool status) {
    return _frozenAddresses[addr];
  }

  /// @dev A convenience method for updating the transfer group, lock until, max balance, and freeze status.
  /// The convenience method also helps to reduce gas costs.
  /// @notice This function has different parameters count from original
  /// @param addr The address to set permissions for.
  /// @param groupID The ID of the address
  /// @param lockedBalanceUntil The amount of tokens to be reserved until the timelock expires. Reservation is exclusive.
  /// @param maxBalance Is the maximum number of tokens the account can hold.
  /// @param status The frozenAddress status of the address. True means frozen false means not frozen.
  function setAddressPermissions(address addr, uint256 groupID, uint256 lockedBalanceUntil,
    uint256 maxBalance, bool status) public validAddress(addr) onlyWalletsAdmin {
    setTransferGroup(addr, groupID);
    setMaxBalance(addr, maxBalance);
    freeze(addr, status);
  }

  /// @dev Sets an allowed transfer from a group to another group beginning at a specific time.
  /// There is only one definitive rule per from and to group.
  /// @param from The group the transfer is coming from.
  /// @param to The group the transfer is going to.
  /// @param lockedUntil The unix timestamp that the transfer is locked until. 0 is a special number. 0 means the transfer is not allowed.
  /// This is because in the smart contract mapping all pairs are implicitly defined with a default lockedUntil value of 0.
  /// But no transfers should be authorized until explicitly allowed. Thus 0 must mean no transfer is allowed.
  function setAllowGroupTransfer(uint256 from, uint256 to, uint256 lockedUntil) external onlyTransferAdmin {
    _allowGroupTransfers[from][to] = lockedUntil;
    emit AllowGroupTransfer(msg.sender, from, to, lockedUntil);
  }

  /// @dev Checks to see when a transfer between two addresses would be allowed.
  /// @param from The address the transfer is coming from
  /// @param to The address the transfer is going to
  /// @return timestamp The Unix timestamp of the time the transfer would be allowed. A 0 means never.
  /// The format is the number of seconds since the Unix epoch of 00:00:00 UTC on 1 January 1970.
  function getAllowTransferTime(address from, address to) external view returns (uint timestamp) {
    return _allowGroupTransfers[_transferGroups[from]][_transferGroups[to]];
  }

  /// @dev Checks to see when a transfer between two groups would be allowed.
  /// @param from The group id the transfer is coming from
  /// @param to The group id the transfer is going to
  /// @return timestamp The Unix timestamp of the time the transfer would be allowed. A 0 means never.
  /// The format is the number of seconds since the Unix epoch of 00:00:00 UTC on 1 January 1970.
  function getAllowGroupTransferTime(uint from, uint to) external view returns (uint timestamp) {
    return _allowGroupTransfers[from][to];
  }

  /// @dev Destroys tokens and removes them from the total supply. Can only be called by an address with a Reserve Admin role.
  /// @param from The address to destroy the tokens from.
  /// @param value The number of tokens to destroy from the address.
  function burn(address from, uint256 value) external validAddress(from) onlyReserveAdmin {
    require(value <= balanceOf(from), "Insufficent tokens to burn");
    _burn(from, value);
  }

  /// @dev Allows the reserve admin to create new tokens in a specified address.
  /// The total number of tokens cannot exceed the maxTotalSupply (the "Hard Cap").
  /// @param to The addres to mint tokens into.
  /// @param value The number of tokens to mint.
  function mint(address to, uint256 value) external validAddress(to) onlyReserveAdmin {
    require(totalSupply() + value <= maxTotalSupply, "Cannot mint more than the max total supply");
    _mint(to, value);
  }

  /// @dev Allows the contract admin to pause transfers.
  function pause() external onlyContractAdmin() {
    isPaused = true;
    emit Pause(msg.sender, true);
  }

  /// @dev Allows the contract admin to unpause transfers.
  function unpause() external onlyContractAdmin() {
    isPaused = false;
    emit Pause(msg.sender, false);
  }

  /// @dev Allows the contrac admin to upgrade the transfer rules.
  /// The upgraded transfer rules must implement the ITransferRules interface which conforms to the ERC-1404 token standard.
  /// @param newTransferRules The address of the deployed TransferRules contract.
  function upgradeTransferRules(ITransferRules newTransferRules) external onlyTransferAdmin {
    require(address(newTransferRules) != address(0x0), "Address cannot be 0x0");
    address oldRules = address(transferRules);
    transferRules = newTransferRules;
    emit Upgrade(msg.sender, oldRules, address(newTransferRules));
  }


  // @dev can delete, used only at tests
  function safeApprove(address spender, uint256 value) public {
    // safeApprove should only be called when setting an initial allowance,
    // or when resetting it to zero. To increase and decrease it, use
    // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
    require((value == 0) || (allowance(address(msg.sender), spender) == 0),
      "Cannot approve from non-zero to non-zero allowance"
    );
    approve(spender, value);
  }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
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
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Arrays.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev Collection of functions related to array types.
 */
library Arrays {
    /**
     * @dev Searches a sorted `array` and returns the first index that contains
     * a value greater or equal to `element`. If no such index exists (i.e. all
     * values in the array are strictly less than `element`), the array length is
     * returned. Time complexity O(log n).
     *
     * `array` is expected to be sorted in ascending order, and to contain no
     * repeated elements.
     */
    function findUpperBound(uint256[] storage array, uint256 element) internal view returns (uint256) {
        if (array.length == 0) {
            return 0;
        }

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = Math.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds down (it does integer division with truncation).
            if (array[mid] > element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
        if (low > 0 && array[low - 1] == element) {
            return low - 1;
        } else {
            return low;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface ITransferRules {
    /// @notice Detects if a transfer will be reverted and if so returns an appropriate reference code
    /// @param from Sending address
    /// @param to Receiving address
    /// @param value Amount of tokens being transferred
    /// @return Code by which to reference message for rejection reasoning
    function detectTransferRestriction(
        address token,
        address from,
        address to,
        uint256 value
    ) external view returns (uint8);

    /// @notice Returns a human-readable message for a given restriction code
    /// @param restrictionCode Identifier for looking up a message
    /// @return Text showing the restriction's reasoning
    function messageForTransferRestriction(uint8 restrictionCode)
        external
        view
        returns (string memory);

    function checkSuccess(uint8 restrictionCode) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

/**
  @title Binary Access control
  @author By CoMakery, Inc., Upside, Republic
  @dev Binary equivalent to OpenZeppelin/AccessControl
       Uses bits for storing user roles, minify gas cost and contact size
*/
contract EasyAccessControl {

  uint8 constant CONTRACT_ADMIN_ROLE = 1; // 0001
  uint8 constant RESERVE_ADMIN_ROLE = 2;  // 0010
  uint8 constant WALLETS_ADMIN_ROLE = 4;  // 0100
  uint8 constant TRANSFER_ADMIN_ROLE = 8; // 1000

  event RoleChange(address indexed grantor, address indexed grantee, uint8 role, bool indexed status);

  mapping (address => uint8) admins; // address => binary roles

  uint8 public contractAdminCount; // counter of contract admins to keep at least one

  modifier validAddress(address addr) {
    require(addr != address(0), "Address cannot be 0x0");
    _;
  }

  modifier validRole(uint8 role) {
    require( role > 0 && role | 15 == 15, "DOES NOT HAVE VALID ROLE");
    _;
  }

  modifier onlyContractAdmin() {
    require(hasRole(msg.sender, CONTRACT_ADMIN_ROLE), "DOES NOT HAVE CONTRACT ADMIN ROLE");
    _;
  }

  modifier onlyTransferAdmin() {
    require(hasRole(msg.sender, TRANSFER_ADMIN_ROLE), "DOES NOT HAVE TRANSFER ADMIN ROLE");
    _;
  }

  modifier onlyWalletsAdmin() {
    require(hasRole(msg.sender, WALLETS_ADMIN_ROLE), "DOES NOT HAVE WALLETS ADMIN ROLE");
    _;
  }

  modifier onlyReserveAdmin() {
    require(hasRole(msg.sender, RESERVE_ADMIN_ROLE), "DOES NOT HAVE RESERVE ADMIN ROLE");
    _;
  }

  /**
    @notice Grant role/roles to address use role bitmask
    @param addr to grant role
    @param role bitmask of role/roles to grant
  **/
  function grantRole(address addr, uint8 role) public validRole(role) validAddress(addr) onlyContractAdmin  {
    if ( admins[addr] & CONTRACT_ADMIN_ROLE == 0 && role & CONTRACT_ADMIN_ROLE > 0 ) contractAdminCount++;
    admins[addr] |= role;
    emit RoleChange(msg.sender, addr, role, true);
  }

  /**
    @notice Revoke role/roles from address use role bitmask
    @param addr to revoke role
    @param role bitmask of role/roles to revoke
  **/
  function revokeRole(address addr, uint8 role) public validRole(role) validAddress(addr) onlyContractAdmin  {
    require(hasRole(addr, role), "CAN NOT REVOKE ROLE");
    if ( role & CONTRACT_ADMIN_ROLE > 0 ) {
      require( contractAdminCount > 1, "Must have at least one contract admin" );
      contractAdminCount--;
    }
    admins[addr] ^= role;
    emit RoleChange(msg.sender, addr, role, false);
  }

  /**
    @notice Check role/roles availability at address
    @param addr to revoke role
    @param role bitmask of role/roles to revoke
    @return bool true or false
  **/
  function hasRole(address addr, uint8 role) public view validRole(role) validAddress(addr) returns (bool) {
    return admins[addr] & role > 0;
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