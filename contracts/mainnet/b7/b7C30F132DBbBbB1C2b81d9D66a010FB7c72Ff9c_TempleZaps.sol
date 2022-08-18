pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ZapBase.sol";
import "./libs/Swap.sol";
import "./interfaces/ITempleStableRouter.sol";
import "./interfaces/IGenericZaps.sol";
import "./interfaces/IVault.sol";


contract TempleZaps is ZapBase {
  using SafeERC20 for IERC20;

  address public immutable temple;
  ITempleStableRouter public templeRouter;
  IGenericZaps public zaps;

  mapping(address => bool) public supportedStables;

  struct TempleLiquidityParams {
    uint256 amountAMin;
    uint256 amountBMin;
    uint256 lpSwapMinAmountOut;
    address stableToken;
    bool transferResidual;
  }

  event SetZaps(address zaps);
  event SetTempleRouter(address router);
  event ZappedTemplePlusFaithInVault(address indexed sender, address fromToken, uint256 fromAmount, uint112 faithAmount, uint256 boostedAmount);
  event ZappedTempleInVault(address indexed sender, address fromToken, uint256 fromAmount, uint256 templeAmount);
  event TokenRecovered(address token, address to, uint256 amount);
  event ZappedInTempleLP(address indexed recipient, address fromAddress, uint256 fromAmount, uint256 amountA, uint256 amountB);

  constructor(
    address _temple,
    address _templeRouter,
    address _zaps
  ) {
    temple = _temple;
    templeRouter = ITempleStableRouter(_templeRouter);
    zaps = IGenericZaps(_zaps);
  }

  /**
   * set generic zaps contract
   * @param _zaps zaps contract
   */
  function setZaps(address _zaps) external onlyOwner {
    zaps = IGenericZaps(_zaps);

    emit SetZaps(_zaps);
  }

  /**
   * set temple stable router
   * @param _router temple router
   */
  function setTempleRouter(address _router) external onlyOwner {
    templeRouter = ITempleStableRouter(_router);

    emit SetTempleRouter(_router);
  }

  /**
   * set supported stables. by default these are the stable amm supported stable tokens
   * @param _stables stable tokens to permit
   * @param _supported to support or not
   */
  function setSupportedStables(
    address[] calldata _stables,
    bool[] calldata _supported
  ) external onlyOwner {
    uint _length = _stables.length;
    require(_supported.length == _length, "TempleZaps: Invalid Input length");
    for (uint i=0; i<_length; i++) {
      supportedStables[_stables[i]] = _supported[i];
    }
  }

  /**
   * @notice recover token or ETH
   * @param _token token to recover
   * @param _to receiver of recovered token
   * @param _amount amount to recover
   */
  function recoverToken(address _token, address _to, uint256 _amount) external onlyOwner {
    require(_to != address(0), "TempleZaps: Invalid receiver");
    if (_token == address(0)) {
      // this is effectively how OpenZeppelin transfers eth
      require(address(this).balance >= _amount, "TempleZaps: insufficient eth balance");
      (bool success,) = _to.call{value: _amount}(""); 
      require(success, "TempleZaps: unable to send value");
    } else {
      _transferToken(IERC20(_token), _to, _amount);
    }
    
    emit TokenRecovered(_token, _to, _amount);
  }

  /**
   * @notice This function zaps ETH or an ERC20 token to TEMPLE ERC20 token
   * @param _fromToken The token used for entry (address(0) if ether)
   * @param _fromAmount The amount of fromToken to zap
   * @param _minTempleReceived Minimum temple to receive
   * @param _stableToken Supported temple pair stable token
   * @param _minStableReceived Minimum temple pair stable token to receive
   * @param _swapTarget Execution target for the swap
   * @param _swapData DEX data
   */
  function zapInTemple(
    address _fromToken,
    uint256 _fromAmount,
    uint256 _minTempleReceived,
    address _stableToken,
    uint256 _minStableReceived,
    address _swapTarget,
    bytes memory _swapData
  ) external payable whenNotPaused {
    zapInTempleFor(_fromToken, _fromAmount, _minTempleReceived, _stableToken, _minStableReceived, msg.sender, _swapTarget, _swapData);
  }

  /**
   * @notice This function zaps ETH or an ERC20 token to TEMPLE LP token
   * @param _fromAddress The token used for entry (address(0) if ether)
   * @param _fromAmount The amount of fromToken to zap
   * @param _minAmountOut Minimum tokens out after first DEX swap
   * @param _swapTarget Execution target for the swap
   * @param _params Parameters for liquidity addition
   * @param _swapData DEX data
   */
  function zapInTempleLP(
    address _fromAddress,
    uint256 _fromAmount,
    uint256 _minAmountOut,
    address _swapTarget,
    TempleLiquidityParams memory _params,
    bytes memory _swapData
  ) external payable whenNotPaused {
    zapInTempleLPFor(_fromAddress, _fromAmount, _minAmountOut, msg.sender, _swapTarget, _params, _swapData);
  }

  /**
   * @notice This function zaps ETH or an ERC20 token to TEMPLE and stakes in core vault
   * @param _fromToken The token used for entry (address(0) if ether)
   * @param _fromAmount The amount of fromToken to zap
   * @param _minTempleReceived Minimum tokens out after first DEX swap
   * @param _stableToken Supported temple pair stable token
   * @param _minStableReceived Minimum stable token to receive
   * @param _vault Target core vault
   * @param _swapTarget Execution target for the swap
   * @param _swapData DEX data
   */
  function zapInVault(
    address _fromToken,
    uint256 _fromAmount,
    uint256 _minTempleReceived,
    address _stableToken,
    uint256 _minStableReceived,
    address _vault,
    address _swapTarget,
    bytes memory _swapData
  ) external payable whenNotPaused {
    zapInVaultFor(_fromToken, _fromAmount, _minTempleReceived, _stableToken, _minStableReceived, _vault, msg.sender, _swapTarget, _swapData);
  }
  
  /**
   * @notice This function zaps ETH or an ERC20 token to TEMPLE ERC20 token
   * @param _fromToken The token used for entry (address(0) if ether)
   * @param _fromAmount The amount of fromToken to zap
   * @param _minTempleReceived Minimum temple to receive
   * @param _stableToken Supported temple pair stable token
   * @param _minStableReceived Minimum of stable token to receive
   * @param _recipient Recipient of exit tokens
   * @param _swapTarget Execution target for the swap
   * @param _swapData DEX data
   */
  function zapInTempleFor(
    address _fromToken,
    uint256 _fromAmount,
    uint256 _minTempleReceived,
    address _stableToken,
    uint256 _minStableReceived,
    address _recipient,
    address _swapTarget,
    bytes memory _swapData
  ) public payable whenNotPaused {
    require(supportedStables[_stableToken] == true, "TempleZaps: Unsupported stable token");

    uint256 amountOut;
    if (_fromToken != address(0)) {
      SafeERC20.safeTransferFrom(IERC20(_fromToken), msg.sender, address(this), _fromAmount);
      SafeERC20.safeIncreaseAllowance(IERC20(_fromToken), address(zaps), _fromAmount);
      amountOut = zaps.zapIn(_fromToken, _fromAmount, _stableToken, _minStableReceived, _swapTarget, _swapData);
    } else {
      amountOut = Swap.fillQuote(_fromToken, _fromAmount, _stableToken, _swapTarget, _swapData);
      require(amountOut >= _minStableReceived, "TempleZaps: Not enough stable tokens out");
    }

     _enterTemple(_stableToken, _recipient, amountOut, _minTempleReceived);
  }

  /**
   * @notice This function zaps ETH or an ERC20 token to TEMPLE LP token
   * @param _fromAddress The token used for entry (address(0) if ether)
   * @param _fromAmount The amount of fromToken to zap
   * @param _minAmountOut Minimum tokens out after first DEX swap
   * @param _for Recipient of exit LP tokens
   * @param _swapTarget Execution target for the swap
   * @param _params Parameters for liquidity addition
   * @param _swapData DEX data
   */
  function zapInTempleLPFor(
    address _fromAddress,
    uint256 _fromAmount,
    uint256 _minAmountOut,
    address _for,
    address _swapTarget,
    TempleLiquidityParams memory _params,
    bytes memory _swapData
  ) public payable {
    require(supportedStables[_params.stableToken] == true, "TempleZaps: Unsupported stable token");

    _pullTokens(_fromAddress, _fromAmount);

    // get pair tokens supporting stable coin
    address pair = templeRouter.tokenPair(_params.stableToken);
    address token0 = IUniswapV2Pair(pair).token0();
    address token1 = IUniswapV2Pair(pair).token1();

    if (_fromAddress != token0 && _fromAddress != token1) {

      _fromAmount = Swap.fillQuote(
        _fromAddress,
        _fromAmount,
        _params.stableToken,
        _swapTarget,
        _swapData
      );
      require(_fromAmount >= _minAmountOut, "TempleZaps: Insufficient tokens out");

      // After we've swapped from user provided token to stable token
      // The stable token is now the intermediate token.
      // reuse variable
      _fromAddress = _params.stableToken;
    }
    (uint256 amountA, uint256 amountB) = _swapAMMTokens(pair, _params.stableToken, _fromAddress, _fromAmount, _params.lpSwapMinAmountOut);

    // approve tokens and add liquidity
    {
      SafeERC20.safeIncreaseAllowance(IERC20(token0), address(templeRouter), amountA);
      SafeERC20.safeIncreaseAllowance(IERC20(token1), address(templeRouter), amountB);
    }
  
    _addLiquidity(pair, _for, amountA, amountB, _params);

    emit ZappedInTempleLP(_for, _fromAddress, _fromAmount, amountA, amountB);
  }

  /**
   * @notice This function zaps ETH or an ERC20 token to TEMPLE and stakes in core vault
   * @param _fromToken The token used for entry (address(0) if ether)
   * @param _fromAmount The amount of fromToken to zap
   * @param _minTempleReceived Minimum tokens out after first DEX swap
   * @param _stableToken Supported temple pair stable token
   * @param _minStableReceived Minimum stable token to receive
   * @param _vault Target core vault
   * @param _for Staked for
   * @param _swapTarget Execution target for the swap
   * @param _swapData DEX data
   */
  function zapInVaultFor(
    address _fromToken,
    uint256 _fromAmount,
    uint256 _minTempleReceived,
    address _stableToken,
    uint256 _minStableReceived,
    address _vault,
    address _for,
    address _swapTarget,
    bytes memory _swapData
  ) public payable whenNotPaused {
    require(supportedStables[_stableToken] == true, "TempleZaps: Unsupported stable token");

    _pullTokens(_fromToken, _fromAmount);
    
    uint256 receivedTempleAmount;
    if (_fromToken == temple) {
      receivedTempleAmount = _fromAmount;
    } else if (supportedStables[_fromToken]) {
      // if fromToken is supported stable, enter temple directly
      receivedTempleAmount = _enterTemple(_stableToken, address(this), _fromAmount, _minTempleReceived);
    } else {
      if (_fromToken != address(0)) {
        IERC20(_fromToken).safeIncreaseAllowance(address(zaps), _fromAmount);
      }
      
      // after zap in, enter temple from stable token
      uint256 receivedStableAmount = zaps.zapIn{value: msg.value}(
        _fromToken,
        _fromAmount,
        _stableToken,
        _minStableReceived,
        _swapTarget,
        _swapData
      );
      
      receivedTempleAmount = _enterTemple(_stableToken, address(this), receivedStableAmount, _minTempleReceived);
    }

    // approve and deposit for user
    if (receivedTempleAmount > 0) {
      IERC20(temple).safeIncreaseAllowance(_vault, receivedTempleAmount);
      IVault(_vault).depositFor(_for, receivedTempleAmount);
      emit ZappedTempleInVault(_for, _fromToken, _fromAmount, receivedTempleAmount);
    }
  }

  /**
   * @dev Helper function to calculate swap in amount of a token before adding liquidit to uniswap v2 pair
   * @param _token Token to swap in
   * @param _pair Uniswap V2 Pair token
   * @param _amount Amount of token
   * @return uint256 Amount to swap
   */
  function getAmountToSwap(
    address _token,
    address _pair,
    uint256 _amount
  ) public view returns (uint256) {
    return Swap.getAmountToSwap(_token, _pair, _amount);
  }

  function _addLiquidity(
    address _pair,
    address _for,
    uint256 _amountA,
    uint256 _amountB,
    TempleLiquidityParams memory _params
  ) internal {
    (uint256 amountAActual, uint256 amountBActual,) = templeRouter.addLiquidity(
      _amountA,
      _amountB,
      _params.amountAMin,
      _params.amountBMin,
      _params.stableToken,
      _for,
      DEADLINE
    );

    if (_params.transferResidual) {
      if (amountAActual < _amountA) {
        _transferToken(IERC20(IUniswapV2Pair(_pair).token0()), _for, _amountA - amountAActual);
      }

      if(amountBActual < _amountB) {
        _transferToken(IERC20(IUniswapV2Pair(_pair).token1()), _for, _amountB - amountBActual);
      }
    }
  }

  function _swapAMMTokens(
    address _pair,
    address _stableToken,
    address _intermediateToken,
    uint256 _intermediateAmount,
    uint256 _lpSwapMinAmountOut
  ) internal returns (uint256 amountA, uint256 amountB) {
    address token0 = IUniswapV2Pair(_pair).token0();
    uint256 amountToSwap = getAmountToSwap(_intermediateToken, _pair, _intermediateAmount);
    uint256 remainder = _intermediateAmount - amountToSwap;

    uint256 amountOut;
    if (_intermediateToken == temple) {
      SafeERC20.safeIncreaseAllowance(IERC20(temple), address(templeRouter), amountToSwap);

      amountOut = templeRouter.swapExactTempleForStable(amountToSwap, _lpSwapMinAmountOut, _stableToken, address(this), type(uint128).max);
      amountA = token0 == _stableToken ? amountOut : remainder;
      amountB = token0 == _stableToken ? remainder : amountOut;
    } else if (_intermediateToken == _stableToken) {
      SafeERC20.safeIncreaseAllowance(IERC20(_stableToken), address(templeRouter), amountToSwap);

      // There's currently a shadowed declaration in the AMM Router causing amountOut to always be zero.
      // So have to resort to getting the balance before/after.
      uint256 balBefore = IERC20(temple).balanceOf(address(this));
      /*amountOut = */ templeRouter.swapExactStableForTemple(amountToSwap, _lpSwapMinAmountOut, _stableToken, address(this), type(uint128).max);
      amountOut = IERC20(temple).balanceOf(address(this)) - balBefore;

      amountA = token0 == _stableToken ? remainder : amountOut;
      amountB = token0 == _stableToken ? amountOut : remainder;
    } else {
      revert("Unsupported token of liquidity pool");
    }
  }

  /**
   * @notice This function swaps stables for TEMPLE
   * @param _stableToken stable token 
   * @param _amountStable The amount of stable to swap
   * @param _minTempleReceived The minimum acceptable quantity of TEMPLE to receive
   * @return templeAmountReceived Quantity of TEMPLE received
   */
  function _enterTemple(
    address _stableToken,
    address _templeReceiver,
    uint256 _amountStable,
    uint256 _minTempleReceived
  ) internal returns (uint256 templeAmountReceived) {
    uint256 templeBefore = IERC20(temple).balanceOf(address(this));
    SafeERC20.safeIncreaseAllowance(IERC20(_stableToken), address(templeRouter), _amountStable);

    templeRouter
      .swapExactStableForTemple(
        _amountStable,
        _minTempleReceived,
        _stableToken,
        _templeReceiver,
        DEADLINE
      );
    // stableswap amm router has a shadowed declaration and so no value is returned after swapExactStableForTemple
    // using calculation below instead
    if (_templeReceiver == address(this)) {
      templeAmountReceived = IERC20(temple).balanceOf(address(this)) - templeBefore;
      require(templeAmountReceived >= _minTempleReceived, "TempleZaps: Not enough temple tokens received");
    }
  }
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

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IWeth.sol";

abstract contract ZapBase is Ownable {
  using SafeERC20 for IERC20;

  bool public paused;
  address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
  uint256 internal constant DEADLINE = 0xf000000000000000000000000000000000000000000000000000000000000000;

  // fromToken => swapTarget (per curve, univ2 and balancer) approval status
  mapping(address => mapping(address => bool)) public approvedTargets;

  event SetContractState(bool paused);

  receive() external payable {
    require(msg.sender != tx.origin, "ZapBase: Do not send ETH directly");
  }

  /**
    @notice Adds or removes an approved swapTarget
    * swapTargets should be Zaps and must not be tokens!
    @param _tokens An array of tokens
    @param _targets An array of addresses of approved swapTargets
    @param _isApproved An array of booleans if target is approved or not
    */
  function setApprovedTargets(
    address[] calldata _tokens,
    address[] calldata _targets,
    bool[] calldata _isApproved
  ) external onlyOwner {
    uint256 _length = _isApproved.length;
    require(_targets.length == _length && _tokens.length == _length, "ZapBase: Invalid Input length");

    for (uint256 i = 0; i < _length; i++) {
      approvedTargets[_tokens[i]][_targets[i]] = _isApproved[i];
    }
  }

  /**
    @notice Toggles the contract's active state
     */
  function toggleContractActive() external onlyOwner {
    paused = !paused;

    emit SetContractState(paused);
  }

  function _transferToken(IERC20 _token, address _to, uint256 _amount) internal {
    uint256 balance = _token.balanceOf(address(this));
    require(_amount <= balance, "ZapBase: not enough tokens");
    SafeERC20.safeTransfer(_token, _to, _amount);
  }

  /**
   * @notice Transfers tokens from msg.sender to this contract
   * @notice If native token, use msg.value
   * @notice For use with Zap Ins
   * @param token The ERC20 token to transfer to this contract (0 address if ETH)
   * @return Quantity of tokens transferred to this contract
     */
  function _pullTokens(
    address token,
    uint256 amount
  ) internal returns (uint256) {
    if (token == address(0)) {
      require(msg.value > 0, "ZapBase: No ETH sent");
      return msg.value;
    }

    require(amount > 0, "ZapBase: Invalid token amount");
    require(msg.value == 0, "ZapBase: ETH sent with token");

    SafeERC20.safeTransferFrom(
      IERC20(token),
      msg.sender,
      address(this),
      amount
    );

    return amount;
  }

  function _depositEth(
    uint256 _amount
  ) internal {
    require(
      _amount > 0 && msg.value == _amount,
      "ZapBase: Input ETH mismatch"
    );
    IWETH(WETH).deposit{value: _amount}();
  }

  // circuit breaker modifiers
  modifier whenNotPaused() {
    require(!paused, "ZapBase: Paused");
    _;
  }
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IUniswapV2Pair.sol";
import "../interfaces/IWeth.sol";
import "./Executable.sol";
import "./EthConstants.sol";


/// @notice An inlined library for liquidity pool related helper functions.
library Swap {
  
  // @dev calling function should ensure targets are approved 
  function fillQuote(
    address _fromToken,
    uint256 _fromAmount,
    address _toToken,
    address _swapTarget,
    bytes memory _swapData
  ) internal returns (uint256) {
    if (_swapTarget == EthConstants.WETH) {
      require(_fromToken == EthConstants.WETH, "Swap: Invalid from token and WETH target");
      require(
        _fromAmount > 0 && msg.value == _fromAmount,
        "Swap: Input ETH mismatch"
      );
      IWETH(EthConstants.WETH).deposit{value: _fromAmount}();
      return _fromAmount;
    }

    uint256 amountBought;
    uint256 valueToSend;
    if (_fromToken == address(0)) {
      require(
        _fromAmount > 0 && msg.value == _fromAmount,
        "Swap: Input ETH mismatch"
      );
      valueToSend = _fromAmount;
    } else {
      SafeERC20.safeIncreaseAllowance(IERC20(_fromToken), _swapTarget, _fromAmount);
    }

    // to calculate amount received
    uint256 initialBalance = IERC20(_toToken).balanceOf(address(this));

    // we don't need the returndata here
    Executable.execute(_swapTarget, valueToSend, _swapData);
    unchecked {
      amountBought = IERC20(_toToken).balanceOf(address(this)) - initialBalance;
    }

    return amountBought;
  }

  function getAmountToSwap(
    address _token,
    address _pair,
    uint256 _amount
  ) internal view returns (uint256) {
    address token0 = IUniswapV2Pair(_pair).token0();
    (uint112 reserveA, uint112 reserveB,) = IUniswapV2Pair(_pair).getReserves();
    uint256 reserveIn = token0 == _token ? reserveA : reserveB;
    uint256 amountToSwap = calculateSwapInAmount(reserveIn, _amount);
    return amountToSwap;
  }

  function calculateSwapInAmount(
    uint256 reserveIn,
    uint256 userIn
  ) internal pure returns (uint256) {
    return
        (sqrt(
            reserveIn * ((userIn * 3988000) + (reserveIn * 3988009))
        ) - (reserveIn * 1997)) / 1994;
  }

  // borrowed from Uniswap V2 Core Math library https://github.com/Uniswap/v2-core/blob/master/contracts/libraries/Math.sol
  // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
  function sqrt(uint y) internal pure returns (uint z) {
    if (y > 3) {
      z = y;
      uint x = y / 2 + 1;
      while (x < z) {
          z = x;
          x = (y / x + x) / 2;
      }
    } else if (y != 0) {
      z = 1;
    }
  }

  /** 
    * given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    *
    * Direct copy of UniswapV2Library.quote(amountA, reserveA, reserveB) - can't use as directly as it's built off a different version of solidity
    */
  function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
    require(reserveA > 0 && reserveB > 0, "Swap: Insufficient liquidity");
    amountB = (amountA * reserveB) / reserveA;
  }

  function getPairTokens(
    address _pairAddress
  ) internal view returns (address token0, address token1) {
    IUniswapV2Pair pair = IUniswapV2Pair(_pairAddress);
    token0 = pair.token0();
    token1 = pair.token1();
  }

}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later

interface ITempleStableRouter {
  function tokenPair(address token) external view returns (address);
  function swapExactStableForTemple(
    uint amountIn,
    uint amountOutMin,
    address stable,
    address to,
    uint deadline
  ) external returns (uint amountOut);
  function swapExactTempleForStable(
    uint amountIn,
    uint amountOutMin,
    address stable,
    address to,
    uint deadline
  ) external returns (uint);
  function addLiquidity(
    uint amountADesired,
    uint amountBDesired,
    uint amountAMin,
    uint amountBMin,
    address stable,
    address to,
    uint deadline
  ) external returns (uint amountA, uint amountB, uint liquidity);
  function swapExactStableForTempleQuote(address pair, uint amountIn) external view returns (uint amountOut);
  function swapExactTempleForStableQuote(address pair, uint amountIn) external view returns (bool priceBelowIV, uint amountOut);
  function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later

interface IGenericZaps {
  function zapIn(
    address fromToken,
    uint256 fromAmount,
    address toToken,
    uint256 amountOutMin,
    address swapTarget,
    bytes calldata swapData
  ) external payable returns (uint256 amountOut);
  function getSwapInAmount(uint256 reserveIn, uint256 userIn) external pure returns (uint256);
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later

interface IVault {
  function depositFor(address _account, uint256 _amount) external; 
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

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later

interface IWETH {
  function deposit() external payable;
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later

interface IUniswapV2Pair {
  function token0() external view returns (address);
  function token1() external view returns (address);
  function getReserves() external view returns (uint112, uint112, uint32);
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later

/// @notice An inlined library function to add a generic execute() function to contracts.
/// @dev As this is a powerful function, care and consideration needs to be taken when 
///      adding into contracts, and on who can call.
library Executable {

    /// @notice Call a function on another contract, where the msg.sender will be this contract
    /// @param _to The address of the contract to call
    /// @param _value Any eth to send
    /// @param _data The encoded function selector and args.
    /// @dev If the underlying function reverts, this willl revert where the underlying revert message will bubble up.
    function execute(
        address _to,
        uint256 _value,
        bytes memory _data
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
            revert("Execute: Unknown failure");
        }
    }
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later

library EthConstants {
  address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
}