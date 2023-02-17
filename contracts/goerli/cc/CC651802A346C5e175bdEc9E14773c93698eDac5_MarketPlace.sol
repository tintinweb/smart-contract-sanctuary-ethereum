// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.9;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IUniswapV2Factory} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Pair} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {ICILStaking} from "./interfaces/ICILStaking.sol";



/**
 * @title Cilistia P2P MarketPlace
 * @notice cilistia MarketPlace contract
 * price decimals 8
 * percent decimals 2
 */
contract MarketPlace is Ownable {
  using SafeERC20 for IERC20;

  struct PositionCreateParam {
    uint128 price;
    uint128 amount;
    uint128 minAmount;
    uint128 maxAmount;
    bool priceType; // 0 => fixed, 1 => percent
    uint8 paymentMethod; // 0 => BankTransfer, 1 => Other
    address token;
  }

  struct Position {
    uint128 price;
    uint128 amount;
    uint128 minAmount;
    uint128 maxAmount;
    uint128 offeredAmount;
    bool priceType; // 0 => fixed, 1 => percent
    uint8 paymentMethod; // 0 => BankTransfer, 1 => Other
    address token;
    address creator;
  }

  struct Offer {
    bytes32 positionKey;
    uint128 amount;
    address creator;
    bool released;
    bool canceled;
  }

  /// @notice multi sign wallet address of team
  address public immutable multiSig;

  /// @notice cil address
  address public immutable cil;
  /// @notice uniswap router address
  address public cilPair;
  /// @notice cil staking address
  address public cilStaking;
  /// @notice chainlink pricefeeds (address => address)
  mapping(address => address) public pricefeeds;

  /// @notice positions (bytes32 => Position)
  mapping(bytes32 => Position) public positions;
  /// @notice offers (bytes32 => Offer)
  mapping(bytes32 => Offer) public offers;
  /// @notice fee decimals 2
  uint256 public feePoint = 100;

  /// @notice blocked address
  mapping(address => bool) public isBlocked;

  /// @notice fires when create position
  event PositionCreated(
    bytes32 key,
    uint128 price,
    uint128 amount,
    uint128 minAmount,
    uint128 maxAmount,
    bool priceType,
    uint8 paymentMethod,
    address indexed token,
    address indexed creator,
    string terms
  );

  /// @notice fires when update position
  event PositionUpdated(bytes32 indexed key, uint128 amount, uint128 offeredAmount);

  /// @notice fires when position state change
  event OfferCreated(
    bytes32 offerKey,
    bytes32 indexed positionKey,
    address indexed creator,
    uint128 amount,
    string terms
  );

  /// @notice fires when cancel offer
  event OfferCanceled(bytes32 indexed key);

  /// @notice fires when release offer
  event OfferReleased(bytes32 indexed key);

  /// @notice fires when block account
  event AccountBlocked(address account);

  /**
   * @param cil_ cilistia token address
   * @param multiSig_ multi sign wallet address
   */
  constructor(address cil_, address multiSig_) {
    cil = cil_;
    multiSig = multiSig_;
  }

  modifier initialized() {
    require(cilStaking != address(0), "MarketPlace: not initialized yet");
    _;
  }

  modifier whitelisted(address token) {
    if (token != cil) {
      require(pricefeeds[token] != address(0), "MarketPlace: token not whitelisted");
    }
    _;
  }

  modifier noBlocked() {
    require(!isBlocked[msg.sender], "MarketPlace: blocked address");
    _;
  }

  /// @dev calcualate key of position
  function getPositionKey(
    uint8 paymentMethod,
    uint128 price,
    address token,
    address creator,
    uint256 amount,
    uint128 minAmount,
    uint128 maxAmount,
    uint256 timestamp
  ) public pure returns (bytes32) {
    return
      keccak256(
        abi.encodePacked(
          paymentMethod,
          price,
          token,
          amount,
          minAmount,
          maxAmount,
          creator,
          timestamp
        )
      );
  }

  /// @dev calcualate key of position
  function getOfferKey(
    bytes32 positionKey,
    uint256 amount,
    address creator,
    uint256 timestamp
  ) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(positionKey, amount, creator, timestamp));
  }

  /**
   * @dev get token price
   * @param token address of token
   * @return price price of token
   */
  function getTokenPrice(address token) public view returns (uint256) {
    if (token == cil) {
      return getCilPrice();
    }

    require(pricefeeds[token] != address(0), "MarketPlace: token not whitelisted");

    (, int256 answer, , , ) = AggregatorV3Interface(pricefeeds[token]).latestRoundData();

    return uint256(answer);
  }

  /**
   * @dev get cil token price from uniswap
   * @return price price of cil token
   */
  function getCilPrice() public view returns (uint256) {
    bool isFirst = IUniswapV2Pair(cilPair).token0() == cil;
    (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(cilPair).getReserves();

    uint256 ethPrice = getTokenPrice(address(0));
    uint256 price = isFirst
      ? ((ethPrice * reserve1) / reserve0)
      : ((ethPrice * reserve0) / reserve1);

    return price;
  }

  /**
   * @dev get staking amount with eth
   * @param user wallet address
   * @return totalAmount amount of staked cil with usd
   */
  function getStakedCil(address user) public view returns (uint256 totalAmount) {
    uint256 cilPrice = getCilPrice();
    totalAmount = (ICILStaking(cilStaking).lockableCil(user) * cilPrice) / 1e18;
  }

  /**
   * @dev create position
   * @param params position create params
   * @param terms terms of position
   */
  function createPosition(PositionCreateParam memory params, string memory terms)
    external
    payable
    initialized
    whitelisted(params.token)
    noBlocked
  {
    bytes32 key = getPositionKey(
      params.paymentMethod,
      params.price,
      params.token,
      msg.sender,
      params.amount,
      params.minAmount,
      params.maxAmount,
      block.timestamp
    );

    positions[key] = Position(
      params.price,
      params.amount,
      params.minAmount,
      params.maxAmount,
      0,
      params.priceType,
      params.paymentMethod,
      params.token,
      msg.sender
    );

    if (params.token == address(0)) {
      require(params.amount == msg.value, "MarketPlace: invalid eth amount");
    } else {
      IERC20(params.token).transferFrom(msg.sender, address(this), params.amount);
    }

    emit PositionCreated(
      key,
      params.price,
      params.amount,
      params.minAmount,
      params.maxAmount,
      params.priceType,
      params.paymentMethod,
      params.token,
      msg.sender,
      terms
    );
  }

  /**
   * @dev increate position amount
   * @param key key of position
   * @param amount amount to increase
   */
  function increasePosition(bytes32 key, uint128 amount) external payable initialized noBlocked {
    require(positions[key].creator != address(0), "MarketPlace: not exist such position");
    require(positions[key].creator == msg.sender, "MarketPlace: not owner of this position");

    positions[key].amount += amount;

    if (positions[key].token == address(0)) {
      require(amount == msg.value, "MarketPlace: invalid eth amount");
    } else {
      IERC20(positions[key].token).transferFrom(msg.sender, address(this), amount);
    }

    emit PositionUpdated(key, positions[key].amount, positions[key].offeredAmount);
  }

  /**
   * @dev decrease position amount
   * @param key key of position
   * @param amount amount to increase
   */
  function decreasePosition(bytes32 key, uint128 amount) external initialized noBlocked {
    require(positions[key].creator != address(0), "MarketPlace: not exist such position");
    require(positions[key].creator == msg.sender, "MarketPlace: not owner of this position");
    require(
      positions[key].amount >= positions[key].offeredAmount + amount,
      "MarketPlace: insufficient amount"
    );

    positions[key].amount -= amount;

    if (positions[key].token == address(0)) {
      payable(msg.sender).transfer(amount);
    } else {
      IERC20(positions[key].token).transfer(msg.sender, amount);
    }

    emit PositionUpdated(key, positions[key].amount, positions[key].offeredAmount);
  }

  /**
   * @dev create offer
   * @param positionKey key of position
   * @param amount amount to offer
   * @param terms terms of position
   */
  function createOffer(
    bytes32 positionKey,
    uint128 amount,
    string memory terms
  ) external initialized noBlocked {
    require(positions[positionKey].creator != address(0), "MarketPlace: such position don't exist");

    require(positions[positionKey].minAmount <= amount, "MarketPlace: amount less than min");
    require(positions[positionKey].maxAmount >= amount, "MarketPlace: amount exceed max");

    uint256 lockableCil = getStakedCil(positions[positionKey].creator);
    require(lockableCil > amount, "MarketPlace: insufficient staking amount for offer");

    uint256 decimals = 18;
    uint256 price = positions[positionKey].price;

    if (positions[positionKey].token != address(0)) {
      decimals = IERC20Metadata(positions[positionKey].token).decimals();
    }

    if (positions[positionKey].priceType) {
      if (positions[positionKey].token == cil) {
        price = (getCilPrice() * positions[positionKey].price) / 10000;
      } else {
        price =
          (getTokenPrice(positions[positionKey].token) * positions[positionKey].price) /
          10000;
      }
    }

    uint256 tokenAmount = (amount * 10**decimals) / price;
    uint256 cilAmount = (amount * 1e18) / getCilPrice();

    ICILStaking(cilStaking).lock(
      positions[positionKey].creator,
      ICILStaking(cilStaking).lockedCil(positions[positionKey].creator) + cilAmount
    );

    bytes32 key = getOfferKey(positionKey, amount, msg.sender, block.timestamp);

    positions[positionKey].offeredAmount += uint128(tokenAmount);
    offers[key] = Offer(positionKey, uint128(tokenAmount), msg.sender, false, false);

    emit OfferCreated(key, positionKey, msg.sender, amount, terms);
    emit PositionUpdated(key, positions[key].amount, positions[key].offeredAmount);
  }

  /**
   * @dev cancel offer
   * @param key key of offer
   */
  function cancelOffer(bytes32 key) external noBlocked {
    require(offers[key].creator == msg.sender, "MarketPlace: you aren't creator of this offer");
    require(!offers[key].released && !offers[key].canceled, "MarketPlace: offer already finished");

    offers[key].canceled = true;
    positions[offers[key].positionKey].offeredAmount -= offers[key].amount;

    emit PositionUpdated(key, positions[key].amount, positions[key].offeredAmount);
    emit OfferCanceled(key);
  }

  /**
   * @dev release offer
   * @param key key of offer
   */
  function releaseOffer(bytes32 key) external noBlocked {
    bytes32 positionKey = offers[key].positionKey;
    require(
      positions[positionKey].creator == msg.sender,
      "MarketPlace: you aren't creator of this position"
    );
    require(!offers[key].released && !offers[key].canceled, "MarketPlace: offer already finished");

    offers[key].released = true;
    positions[positionKey].amount -= offers[key].amount;
    positions[positionKey].offeredAmount -= offers[key].amount;

    uint256 fee = (offers[key].amount * feePoint) / 10000;
    if (positions[positionKey].token == address(0)) {
      payable(offers[key].creator).transfer(offers[key].amount - fee);
      payable(multiSig).transfer(fee);
    } else {
      IERC20(positions[positionKey].token).transfer(offers[key].creator, offers[key].amount - fee);
      IERC20(positions[positionKey].token).transfer(multiSig, fee);
    }

    emit PositionUpdated(key, positions[key].amount, positions[key].offeredAmount);
    emit OfferReleased(key);
  }

  /**
   * @dev set staking contract address
   * @param cilStaking_ staking contract address
   * @param cilPair_ address of cil/eth pair
   * @param ethPricefeed_ weth pricefeed contract address
   */
  function init(
    address cilStaking_,
    address cilPair_,
    address ethPricefeed_
  ) external onlyOwner {
    cilStaking = cilStaking_;
    cilPair = cilPair_;

    bool isFirst = IUniswapV2Pair(cilPair).token0() == cil;
    pricefeeds[address(0)] = ethPricefeed_;
    pricefeeds[
      isFirst ? IUniswapV2Pair(cilPair).token1() : IUniswapV2Pair(cilPair).token0()
    ] = ethPricefeed_;
  }

  /**
   * @dev set token price feed
   * @param token address of token
   * @param pricefeed address of chainlink aggregator
   */
  function setPriceFeed(address token, address pricefeed) external onlyOwner {
    pricefeeds[token] = pricefeed;
  }

  /**
   * @dev force cancel offer
   * @param key key of offer
   */
  function forceCancelOffer(bytes32 key) external onlyOwner {
    require(!offers[key].released && !offers[key].canceled, "MarketPlace: offer already finished");

    offers[key].canceled = true;
    positions[offers[key].positionKey].offeredAmount -= offers[key].amount;

    emit OfferCanceled(key);
  }

  /**
   * @dev force remove position
   * @param key key of position
   */
  function forceRemovePosition(bytes32 key) external onlyOwner {
    uint256 positionAmount = positions[key].amount;
    isBlocked[positions[key].creator] = true;
    positions[key].amount = 0;
    ICILStaking(cilStaking).remove(positions[key].creator);

    if (positions[key].token == address(0)) {
      payable(multiSig).transfer(positionAmount);
    } else {
      IERC20(positions[key].token).transfer(multiSig, positionAmount);
    }

    emit PositionUpdated(key, positions[key].amount, positions[key].offeredAmount);
    emit AccountBlocked(positions[key].creator);
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.9;

/// @notice cilistia staking contract interface
interface ICILStaking {
  /// @notice fires when stake state changes
  event StakeUpdated(address user, uint256 stakedAmount, uint256 lockedAmount);

  /// @notice fires when unstake token
  event UnStaked(address user, uint256 rewardAmount);

  /// @dev unstake staked token
  function lock(address user, uint256 amount) external;

  /// @dev remove staking data
  function remove(address user) external;

  /// @dev return colleted token amount
  function collectedToken(address user) external view returns (uint256);

  /// @dev return lockable token amount
  function lockableCil(address user) external view returns (uint256);

  /// @dev return locked token amount
  function lockedCil(address user) external view returns (uint256);
}

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

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

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
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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