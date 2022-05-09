// SPDX-License-Identifier: MIT
/* solhint-disable not-rely-on-time */

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract Exchange is Ownable {
  /**
   * @dev The address of the coin contract.
   */
  IERC20 public immutable coin;

  /**
   * @dev The state of the exchange.
   */
  enum State {
    NOT_ACTIVE,
    BUY_ONLY,
    SELL_ONLY,
    BUY_SELL
  }

  /**
   * @dev When someone buys tokens with eth.
   */
  event Bought(
    address indexed buyer,
    address indexed recipient,
    uint256 indexed timestamp,
    uint256 tokensBought,
    uint256 ethSold,
    uint256 tokenReserve,
    uint256 ethReserve
  );

  /**
   * @dev When someone sell tokens for eth.
   */
  event Sold(
    address indexed seller,
    address indexed recipient,
    uint256 indexed timestamp,
    uint256 tokensSold,
    uint256 ethBought,
    uint256 tokenReserve,
    uint256 ethReserve
  );

  /**
   * @dev When contract receives ether.
   */
  event Deposit(
    address indexed depositer,
    uint256 indexed timestamp,
    uint256 ethAdded,
    uint256 tokenReserve,
    uint256 ethReserve
  );

  /**
   * @dev Sell tax fee, and its denominator makes up sell tax.
   */
  uint256 public sellTaxFee = 2;
  uint256 public sellTaxFeeDenominator = 100;

  /**
   * @dev Liquidity guard takes care of slipage to keep liquidity around.
   */
  uint256 public liqudityGuard = 3;
  uint256 public liqudityGuardDenominator = 1000;

  /**
   * @dev Current state of the exchange.
   * @dev see {Exchange-State}
   */
  State public state = State.BUY_SELL;

  modifier buyEnabled() {
    require(state == State.BUY_ONLY || state == State.BUY_SELL, "exchange is not in buy mode");
    _;
  }

  modifier sellEnabled() {
    require(state == State.SELL_ONLY || state == State.BUY_SELL, "exchange is not in buy mode");
    _;
  }

  /**
   * @dev By default you need to provide ERC20 coin.
   * @dev This is will be Coin contract address.
   */
  constructor(address _coin) payable {
    coin = IERC20(_coin);
  }

  /**
   * @dev Will put exchange to given state.
   * @dev see {Exchange-State}
   */
  function setState(State newState) external onlyOwner {
    state = newState;
  }

  /**
   * @notice Set sell tax fee.
   * @notice For example _fee with _denominator 100 means 1 unit _fee is 1%.
   * @param _fee as amount to tax.
   * @param _denominator division unit.
   */
  function setSellTaxFee(uint256 _fee, uint256 _denominator) public onlyOwner {
    require(_fee < 15, "maximum tax fee is 15%");
    require(_denominator > 0, "denominator must be > 0");

    sellTaxFee = _fee;
    sellTaxFeeDenominator = _denominator;
  }

  /**
   * @notice Set liquidity guard for constant product market maker.
   * @dev This is the percantage making the slippage possible.
   */
  function setLiqudityGuard(uint256 _guard, uint256 _denominator) public onlyOwner {
    require(_denominator > 0, "denominator must be > 0");

    liqudityGuard = _guard;
    liqudityGuardDenominator = _denominator;
  }

  /**
   * @dev This function should be used only for migration.
   * @notice It would be naive to think we will not need to migrate pool (add/remove)
   * @notice functionality. In contrast this is also abusing power.
   * @notice However onlyOwner can be assigned to DAO and let community decide.
   */
  function destruct(address payable receiver) public onlyOwner {
    return selfdestruct(receiver);
  }

  /**
   * @notice Convert ETH to Tokens.
   * @dev This will simply allow the user to convert ETH to tokens without any inputs
   * @dev simply by sending ETH.
   * @return Amount of Tokens bought.
   */
  function ethToTokenSwap() external payable buyEnabled returns (uint256) {
    return ethToTokenInput(msg.value, 0, block.timestamp, msg.sender, msg.sender);
  }

  /**
   * @notice Convert ETH to Tokens.
   * @dev User specifies exact input (msg.value) && minimum output.
   * @param minTokens Minimum Tokens bought.
   * @param deadline Time after which this transaction can no longer be executed.
   * @return Amount of Tokens bought.
   */
  function ethToTokenSwapInput(uint256 minTokens, uint256 deadline) external payable buyEnabled returns (uint256) {
    return ethToTokenInput(msg.value, minTokens, deadline, msg.sender, msg.sender);
  }

  /**
   * @notice Convert ETH to Tokens.
   * @dev User specifies maximum input (msg.value) && exact output.
   * @param tokensBought Amount of tokens bought.
   * @param deadline Time after which this transaction can no longer be executed.
   * @return Amount of ETH sold.
   */
  function ethToTokenSwapOutput(uint256 tokensBought, uint256 deadline) external payable buyEnabled returns (uint256) {
    return ethToTokenOutput(tokensBought, msg.value, deadline, payable(msg.sender), msg.sender);
  }

  /**
   * @notice Convert ETH to Tokens && transfers Tokens to recipient.
   * @dev User specifies exact input (msg.value) && minimum output
   * @param minTokens Minimum Tokens bought.
   * @param deadline Time after which this transaction can no longer be executed.
   * @param recipient The address that receives output Tokens.
   * @return  Amount of Tokens bought.
   */
  function ethToTokenTransferInput(
    uint256 minTokens,
    uint256 deadline,
    address recipient
  ) external payable buyEnabled returns (uint256) {
    require(recipient != address(this) && recipient != address(0), "invalid recipient");
    return ethToTokenInput(msg.value, minTokens, deadline, msg.sender, recipient);
  }

  /**
   * @notice Convert ETH to Tokens && transfers Tokens to recipient.
   * @dev User specifies maximum input (msg.value) && exact output.
   * @param tokensBought Amount of tokens bought.
   * @param deadline Time after which this transaction can no longer be executed.
   * @param recipient The address that receives output Tokens.
   * @return Amount of ETH sold.
   */
  function ethToTokenTransferOutput(
    uint256 tokensBought,
    uint256 deadline,
    address recipient
  ) external payable buyEnabled returns (uint256) {
    require(recipient != address(this) && recipient != address(0), "invalid recipient");
    return ethToTokenOutput(tokensBought, msg.value, deadline, payable(msg.sender), recipient);
  }

  /**
   * @notice Convert Tokens to ETH.
   * @dev This will simply allow the user to convert ETH to tokens without any inputs
   * @dev simply by sending ETH.
   * @return Amount of Tokens bought.
   */
  function tokenToEthSwap(uint256 tokensSold) external sellEnabled returns (uint256) {
    (uint256 ethBought, ) = getInputPriceWithTax(tokensSold, _balance(), address(this).balance);
    return tokenToEthInput(tokensSold, ethBought, block.timestamp, msg.sender, payable(msg.sender));
  }

  /**
   * @notice Convert Tokens to ETH.
   * @dev User specifies exact input && minimum output.
   * @param tokensSold Amount of Tokens sold.
   * @param minEth Minimum ETH purchased.
   * @param deadline Time after which this transaction can no longer be executed.
   * @return Amount of ETH bought.
   */
  function tokenToEthSwapInput(
    uint256 tokensSold,
    uint256 minEth,
    uint256 deadline
  ) external sellEnabled returns (uint256) {
    return tokenToEthInput(tokensSold, minEth, deadline, msg.sender, payable(msg.sender));
  }

  /**
   * @notice Convert Tokens to ETH.
   * @dev User specifies maximum input && exact output.
   * @param ethBought Amount of ETH purchased.
   * @param maxTokens Maximum Tokens sold.
   * @param deadline Time after which this transaction can no longer be executed.
   * @return Amount of Tokens sold.
   */
  function tokenToEthSwapOutput(
    uint256 ethBought,
    uint256 maxTokens,
    uint256 deadline
  ) external sellEnabled returns (uint256) {
    return tokenToEthOutput(ethBought, maxTokens, deadline, msg.sender, payable(msg.sender));
  }

  /**
   * @notice Convert Tokens to ETH && transfers ETH to recipient.
   * @dev User specifies exact input && minimum output.
   * @param tokensSold Amount of Tokens sold.
   * @param minEth Minimum ETH purchased.
   * @param deadline Time after which this transaction can no longer be executed.
   * @param recipient The address that receives output ETH.
   * @return  Amount of ETH bought.
   */
  function tokenToEthTransferInput(
    uint256 tokensSold,
    uint256 minEth,
    uint256 deadline,
    address payable recipient
  ) external sellEnabled returns (uint256) {
    require(recipient != address(this) && recipient != address(0), "invalid recipient");
    return tokenToEthInput(tokensSold, minEth, deadline, msg.sender, recipient);
  }

  /**
   * @notice Convert Tokens to ETH && transfers ETH to recipient.
   * @dev User specifies maximum input && exact output.
   * @param ethBought Amount of ETH purchased.
   * @param maxTokens Maximum Tokens sold.
   * @param deadline Time after which this transaction can no longer be executed.
   * @param recipient The address that receives output ETH.
   * @return Amount of Tokens sold.
   */
  function tokenToEthTransferOutput(
    uint256 ethBought,
    uint256 maxTokens,
    uint256 deadline,
    address payable recipient
  ) external sellEnabled returns (uint256) {
    require(recipient != address(this) && recipient != address(0), "invalid recipient");
    return tokenToEthOutput(ethBought, maxTokens, deadline, msg.sender, recipient);
  }

  /**
   * @notice Public price function for ETH to Token trades with an exact input.
   * @param ethSold Amount of ETH sold.
   * @return Amount of Tokens that can be bought with input ETH.
   */
  function getEthToTokenInputPrice(uint256 ethSold) external view returns (uint256) {
    require(ethSold > 0, "ethSold must be > 0");
    uint256 tokenReserve = _balance();
    return getInputPrice(ethSold, address(this).balance, tokenReserve);
  }

  /**
   * @notice Public price function for ETH to Token trades with an exact output.
   * @param tokensBought Amount of Tokens bought.
   * @return Amount of ETH needed to buy output Tokens.
   */
  function getEthToTokenOutputPrice(uint256 tokensBought) external view returns (uint256) {
    require(tokensBought > 0, "tokensBought must be > 0");
    uint256 tokenReserve = _balance();
    uint256 ethSold = getOutputPrice(tokensBought, address(this).balance, tokenReserve);
    return ethSold;
  }

  /**
   * @notice Public price function for Token to ETH trades with an exact input.
   * @param tokensSold Amount of Tokens sold.
   * @return Amount of ETH that can be bought with input Tokens.
   */
  function getTokenToEthInputPrice(uint256 tokensSold) external view returns (uint256) {
    require(tokensSold > 0, "tokensSold must be > 0");
    uint256 tokenReserve = _balance();
    uint256 ethBought = getInputPrice(tokensSold, tokenReserve, address(this).balance);
    return ethBought;
  }

  /**
   * @notice Public price function for Token to ETH trades with an exact input with fees.
   * @param tokensSold Amount of Tokens sold.
   * @return Amount of ETH that can be bought with input Tokens.
   */
  function getTokenToEthInputPriceWithTax(uint256 tokensSold) external view returns (uint256, uint256) {
    require(tokensSold > 0, "tokensSold must be > 0");
    uint256 tokenReserve = _balance();
    return getInputPriceWithTax(tokensSold, tokenReserve, address(this).balance);
  }

  /**
   * @notice Public price function for Token to ETH trades with an exact output.
   * @param ethBought Amount of output ETH.
   * @return Amount of Tokens needed to buy output ETH.
   */
  function getTokenToEthOutputPrice(uint256 ethBought) external view returns (uint256) {
    require(ethBought > 0, "ethBought must be > 0");
    uint256 tokenReserve = _balance();
    return getOutputPrice(ethBought, tokenReserve, address(this).balance);
  }

  /**
   * @notice Public price function for Token to ETH trades with an exact output and fees.
   * @param ethBought Amount of output ETH.
   * @return Amount of Tokens needed to buy output ETH.
   */
  function getTokenToEthOutputPriceWithTax(uint256 ethBought) external view returns (uint256, uint256) {
    require(ethBought > 0, "ethBought must be > 0");
    uint256 tokenReserve = _balance();
    return getOutputPriceWithTax(ethBought, tokenReserve, address(this).balance);
  }

  /**
   * @notice Returns reserves of the exchange.
   * @return bhc amount of bhc in reserve.
   * @return eth amount of bhc in reserve.
   */
  function reserves() external view returns (uint256, uint256) {
    return (_balance(), address(this).balance);
  }

  /**
   * @notice Convert ETH to Tokens.
   * @dev User specifies exact input (msg.value).
   * @dev User cannot specify minimum output or deadline.
   */
  receive() external payable {
    emit Deposit(_msgSender(), block.timestamp, msg.value, _balance(), address(this).balance);
  }

  /**
   * @dev Pricing function for converting between ETH && Tokens.
   * @param inputAmount Amount of ETH or Tokens being sold.
   * @param inputReserve Amount of ETH or Tokens (input type) in exchange reserves.
   * @param outputReserve Amount of ETH or Tokens (output type) in exchange reserves.
   * @return Amount of ETH or Tokens bought.
   */
  function getInputPrice(
    uint256 inputAmount, // eth sold
    uint256 inputReserve, // balance - eth sold
    uint256 outputReserve // token balance of this
  ) internal view returns (uint256) {
    require(inputReserve > 0 && outputReserve > 0, "not enough liquidity");
    uint256 inputAmountWithFee = inputAmount * (liqudityGuardDenominator - liqudityGuard);
    uint256 numerator = inputAmountWithFee * outputReserve;
    uint256 denominator = inputReserve * (liqudityGuardDenominator + inputAmountWithFee);
    return numerator / denominator;
  }

  /**
   * @dev Pricing function for converting between ETH && Tokens with fees.
   * @param inputAmount Amount of ETH or Tokens being sold.
   * @param inputReserve Amount of ETH or Tokens (input type) in exchange reserves.
   * @param outputReserve Amount of ETH or Tokens (output type) in exchange reserves.
   * @return Amount of ETH or Tokens bought.
   */
  function getInputPriceWithTax(
    uint256 inputAmount, // eth sold
    uint256 inputReserve, // balance - eth sold
    uint256 outputReserve // token balance of this
  ) internal view returns (uint256, uint256) {
    uint256 p = getInputPrice(inputAmount, inputReserve, outputReserve);
    uint256 fee = calculateSellFee(p);
    return (p - fee, fee);
  }

  /**
   * @dev Pricing function for converting between ETH && Tokens.
   * @param outputAmount Amount of ETH or Tokens being bought.
   * @param inputReserve Amount of ETH or Tokens (input type) in exchange reserves.
   * @param outputReserve Amount of ETH or Tokens (output type) in exchange reserves.
   * @return Amount of ETH or Tokens sold.
   */
  function getOutputPrice(
    uint256 outputAmount,
    uint256 inputReserve,
    uint256 outputReserve
  ) internal view returns (uint256) {
    require(inputReserve > 0 && outputReserve > 0, "not enough liquidity");
    uint256 numerator = inputReserve * outputAmount * liqudityGuardDenominator;
    uint256 denominator = (outputReserve - outputAmount) * (liqudityGuardDenominator - liqudityGuard);
    return (numerator / denominator) + 1;
  }

  /**
   * @dev Pricing function for converting between ETH && Tokens With fee.
   * @param outputAmount Amount of ETH or Tokens being bought.
   * @param inputReserve Amount of ETH or Tokens (input type) in exchange reserves.
   * @param outputReserve Amount of ETH or Tokens (output type) in exchange reserves.
   * @return Amount of ETH or Tokens sold.
   */
  function getOutputPriceWithTax(
    uint256 outputAmount,
    uint256 inputReserve,
    uint256 outputReserve
  ) internal view returns (uint256, uint256) {
    uint256 p = getOutputPrice(outputAmount, inputReserve, outputReserve);
    uint256 fee = calculateSellFee(p);
    return (p - fee, fee);
  }

  function ethToTokenInput(
    uint256 ethSold,
    uint256 minTokens,
    uint256 deadline,
    address buyer,
    address recipient
  ) private returns (uint256) {
    require(deadline >= block.timestamp, "deadline crossed");
    require(ethSold > 0, "sold eth must be > 0");
    uint256 tokenReserve = _balance();
    uint256 tokensBought = getInputPrice(ethSold, address(this).balance - ethSold, tokenReserve);
    require(tokensBought >= minTokens, "buy amount not satisfied");
    coin.transferFrom(address(this), recipient, tokensBought);
    emit Bought(buyer, recipient, block.timestamp, tokensBought, ethSold, _balance(), address(this).balance);
    return tokensBought;
  }

  function ethToTokenOutput(
    uint256 tokensBought,
    uint256 maxEth,
    uint256 deadline,
    address buyer,
    address recipient
  ) private returns (uint256) {
    require(deadline >= block.timestamp, "deadline crossed");
    require(tokensBought > 0, "tokens bought must be > 0");
    require(maxEth > 0, "max of eth must be > 0");
    uint256 tokenReserve = _balance();
    uint256 ethSold = getOutputPrice(tokensBought, address(this).balance - maxEth, tokenReserve);
    uint256 ethRefund = maxEth - ethSold;
    if (ethRefund > 0) {
      Address.sendValue(payable(buyer), ethRefund);
    }
    coin.transferFrom(address(this), recipient, tokensBought);
    emit Bought(buyer, recipient, block.timestamp, tokensBought, ethSold, _balance(), address(this).balance);
    return ethSold;
  }

  function tokenToEthInput(
    uint256 tokensSold,
    uint256 minEth,
    uint256 deadline,
    address seller,
    address payable recipient
  ) private returns (uint256) {
    require(deadline >= block.timestamp, "deadline crossed");
    require(tokensSold > 0, "sold tokens must be > 0");
    uint256 tokenReserve = _balance();
    (uint256 ethBought, uint256 tax) = getInputPriceWithTax(tokensSold, tokenReserve, address(this).balance);
    require(ethBought >= minEth, "eth bought must >= min eth");
    Address.sendValue(recipient, ethBought - tax);
    coin.transferFrom(seller, address(this), tokensSold);
    emit Sold(seller, recipient, block.timestamp, tokensSold, ethBought, _balance(), address(this).balance);
    return ethBought;
  }

  function tokenToEthOutput(
    uint256 ethBought,
    uint256 maxTokens,
    uint256 deadline,
    address seller,
    address payable recipient
  ) private returns (uint256) {
    require(deadline >= block.timestamp, "deadline crossed");
    require(ethBought > 0, "bought eth must be > 0");
    require(maxTokens > 0, "max bought tokens must be > 0");
    uint256 tokenReserve = _balance();
    (uint256 tokensSold, uint256 tax) = getOutputPriceWithTax(ethBought, tokenReserve, address(this).balance);
    require(maxTokens >= tokensSold, "max bought tokens >= tokens sold");
    Address.sendValue(recipient, ethBought);
    coin.transferFrom(seller, address(this), tokensSold + tax);
    emit Sold(seller, recipient, block.timestamp, tokensSold, ethBought, _balance(), address(this).balance);
    return tokensSold;
  }

  /**
   * @dev Will simply calulate amount and fee, based on current tax fee
   */
  function calculateSellFee(uint256 amount) internal view returns (uint256 fee) {
    return (amount / sellTaxFeeDenominator) * sellTaxFee;
  }

  /**
   * @dev will return current reserve of tokens.
   */
  function _balance() internal view returns (uint256) {
    return coin.balanceOf(address(this));
  }
}

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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