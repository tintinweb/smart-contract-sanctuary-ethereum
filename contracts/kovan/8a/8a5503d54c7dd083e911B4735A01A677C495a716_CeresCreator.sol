// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AggregatorInterface.sol";
import "./AggregatorV3Interface.sol";

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/extensions/IERC20Metadata.sol)

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";

abstract contract Ownable is Context {
    
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor(address _owner_) {
        _setOwner(_owner_);
    }
    
    function owner() public view virtual returns (address) {
        return _owner;
    }
    
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Only Owner!");
        _;
    }
    
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interface/ICeresCreator.sol";
import "../interface/IStakingCreator.sol";
import "../common/Ownable.sol";
import "../oracle/OracleAverage.sol";

interface ISwapRouter {

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

}

contract CeresCreator is ICeresCreator, Ownable {

    address public asc;
    address public crs;
    address public swapRouter;
    address public swapFactory;
    address public override quoteToken;
    address public priceFeed;
    uint256 public deadlineGap;
    address public ceresFactory;
    IStakingCreator public stakingCreator;

    modifier onlyFactory {
        require(msg.sender == ceresFactory, "Only CeresFactory!");
        _;
    }

    constructor(address _owner, address _asc, address _crs, address _swapFactory, address _quoteToken,
        address _priceFeed) Ownable(_owner) {
        asc = _asc;
        crs = _crs;
        swapFactory = _swapFactory;
        quoteToken = _quoteToken;
        priceFeed = _priceFeed;
    }

    /* ---------- Functions ---------- */
    function createStaking(address token) external override onlyFactory returns (address){
        return stakingCreator.createStaking(ceresFactory, asc, crs, token);
    }

    function createOracle(address token) external override onlyFactory returns (address){
        return address(new OracleAverage(swapFactory, token, quoteToken, priceFeed));
    }

    function addLiquidity(address token, uint256 tokenAmount, uint256 quoteAmount, address account) external override onlyFactory {
        IERC20(token).approve(swapRouter, tokenAmount);
        IERC20(quoteToken).approve(swapRouter, quoteAmount);

        ISwapRouter(swapRouter).addLiquidity(token, quoteToken, tokenAmount, quoteAmount,
            0, 0, account, block.timestamp + deadlineGap);
    }

    /* ---------- Settings ---------- */
    function setSwapFactory(address _swapFactory) external onlyOwner {
        swapFactory = _swapFactory;
    }

    function setSwapRouter(address _swapRouter) external onlyOwner {
        swapRouter = _swapRouter;
    }

    function setQuoteToken(address _quoteToken) external onlyOwner {
        quoteToken = _quoteToken;
    }

    function setPriceFeed(address _priceFeed) external onlyOwner {
        priceFeed = _priceFeed;
    }

    function setCeresFactory(address _ceresFactory) external onlyOwner {
        ceresFactory = _ceresFactory;
    }

    function setDeadlineGap(uint256 _deadlineGap) external onlyOwner {
        deadlineGap = _deadlineGap;
    }

    function setStakingCreator(address _stakingCreator) external onlyOwner {
        stakingCreator = IStakingCreator(_stakingCreator);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ICeresCreator {
    
    /* ---------- Views ---------- */
    function quoteToken() external view returns (address);

    /* ---------- Functions ---------- */
    function createStaking(address token) external returns (address);
    function createOracle(address token) external returns (address);
    function addLiquidity(address token, uint256 tokenAmount, uint256 quoteAmount, address account) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IOracle {

    /* ---------- Views ---------- */
    function token() external view returns (address);
    function getPrice() external view returns (uint256);
    function updatable() external view returns (bool);

    /* ---------- Functions ---------- */
    function update() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IStakingCreator {

    /* ---------- Functions ---------- */
    function createStaking(address ceresFactory, address asc, address crs, address token) external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol';
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./interface/ISwapPair.sol";
import "./interface/ISwapFactory.sol";
import "./library/FixedPoint.sol";
import "../interface/IOracle.sol";

contract OracleAverage is IOracle {
    
    using FixedPoint for *;
    AggregatorV2V3Interface internal priceFeed;
    address public override token;
    uint256 public constant PERIOD = 1 seconds;  // TODO test-value
    ISwapPair immutable pair;
    address public immutable token0;
    address public immutable token1;
    uint    public price0CumulativeLast;
    uint    public price1CumulativeLast;
    uint32  public blockTimestampLast;
    FixedPoint.uq112x112 public price0Average;
    FixedPoint.uq112x112 public price1Average;
    
    constructor(address _swapFactory, address _token, address _quoteToken, address _priceFeed) {
        address pairAddr = ISwapFactory(_swapFactory).getPair(_token, _quoteToken);
        require(pairAddr != address(0), 'No pair!');

        ISwapPair _pair = ISwapPair(pairAddr);
        pair = _pair;
        token0 = _pair.token0();
        token1 = _pair.token1();
        price0CumulativeLast = _pair.price0CumulativeLast();
        price1CumulativeLast = _pair.price1CumulativeLast();
        uint112 reserve0;
        uint112 reserve1;
        (reserve0, reserve1, blockTimestampLast) = _pair.getReserves();
        require(reserve0 != 0 && reserve1 != 0, 'No Reserves!');

        token = _token;
        priceFeed = AggregatorV2V3Interface(_priceFeed);
    }

    /* ---------- Views ---------- */
    function getPrice() external view override returns (uint256){
        (,int256 quotePrice,,,) = priceFeed.latestRoundData();
        uint256 _consultAmount = 1e6 * 10 ** _missingDecimals();
        return uint256(consult(token, _consultAmount)) * uint256(quotePrice) / 10 ** priceFeed.decimals();
    }

    function consult(address _token, uint amountIn) public view returns (uint amountOut) {
        if (_token == token0) {
            amountOut = price0Average.mul(amountIn).decode144();
        } else {
            require(_token == token1, 'INVALID_TOKEN');
            amountOut = price1Average.mul(amountIn).decode144();
        }
    }

    function _missingDecimals() internal view returns (uint256){
        if (token == token0)
            return 18 - IERC20Metadata(token1).decimals();
        else
            return 18 - IERC20Metadata(token0).decimals();
    }

    function currentCumulativePrices(address _pair) internal view returns (uint price0Cumulative, uint price1Cumulative, uint32 blockTimestamp) {
        blockTimestamp = uint32(block.timestamp % 2 ** 32);
        price0Cumulative = ISwapPair(_pair).price0CumulativeLast();
        price1Cumulative = ISwapPair(_pair).price1CumulativeLast();

        (uint112 reserve0, uint112 reserve1, uint32 _blockTimestampLast) = ISwapPair(_pair).getReserves();
        if (_blockTimestampLast != blockTimestamp) {
            uint32 timeElapsed = blockTimestamp - _blockTimestampLast;
            price0Cumulative += uint(FixedPoint.fraction(reserve1, reserve0)._x) * timeElapsed;
            price1Cumulative += uint(FixedPoint.fraction(reserve0, reserve1)._x) * timeElapsed;
        }
    }

    function updatable() external view override returns (bool) {
        return uint32(block.timestamp % 2 ** 32) - blockTimestampLast >= PERIOD;
    }

    /* ---------- Functions ---------- */
    function update() override external {
        (uint price0Cumulative, uint price1Cumulative, uint32 blockTimestamp) = currentCumulativePrices(address(pair));

        uint32 timeElapsed = blockTimestamp - blockTimestampLast;
        require(timeElapsed >= PERIOD, 'Oracle: PERIOD_NOT_ELAPSED');

        price0Average = FixedPoint.uq112x112(uint224((price0Cumulative - price0CumulativeLast) / timeElapsed));
        price1Average = FixedPoint.uq112x112(uint224((price1Cumulative - price1CumulativeLast) / timeElapsed));

        price0CumulativeLast = price0Cumulative;
        price1CumulativeLast = price1Cumulative;
        blockTimestampLast = blockTimestamp;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ISwapFactory {
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ISwapPair {
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
pragma solidity ^0.8.4;

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))
library FixedPoint {
    // range: [0, 2**112 - 1]
    // resolution: 1 / 2**112
    struct uq112x112 {
        uint224 _x;
    }

    // range: [0, 2**144 - 1]
    // resolution: 1 / 2**112
    struct uq144x112 {
        uint _x;
    }

    uint8 private constant RESOLUTION = 112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 x) internal pure returns (uq112x112 memory) {
        return uq112x112(uint224(x) << RESOLUTION);
    }

    // encodes a uint144 as a UQ144x112
    function encode144(uint144 x) internal pure returns (uq144x112 memory) {
        return uq144x112(uint256(x) << RESOLUTION);
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function div(uq112x112 memory self, uint112 x) internal pure returns (uq112x112 memory) {
        require(x != 0, 'FixedPoint: DIV_BY_ZERO');
        return uq112x112(self._x / uint224(x));
    }

    // multiply a UQ112x112 by a uint, returning a UQ144x112
    // reverts on overflow
    function mul(uq112x112 memory self, uint y) internal pure returns (uq144x112 memory) {
        uint z;
        require(y == 0 || (z = uint(self._x) * y) / y == uint(self._x), "FixedPoint: MULTIPLICATION_OVERFLOW");
        return uq144x112(z);
    }

    // returns a UQ112x112 which represents the ratio of the numerator to the denominator
    // equivalent to encode(numerator).div(denominator)
    function fraction(uint112 numerator, uint112 denominator) internal pure returns (uq112x112 memory) {
        require(denominator > 0, "FixedPoint: DIV_BY_ZERO");
        return uq112x112((uint224(numerator) << RESOLUTION) / denominator);
    }

    // decode a UQ112x112 into a uint112 by truncating after the radix point
    function decode(uq112x112 memory self) internal pure returns (uint112) {
        return uint112(self._x >> RESOLUTION);
    }

    // decode a UQ144x112 into a uint144 by truncating after the radix point
    function decode144(uq144x112 memory self) internal pure returns (uint144) {
        return uint144(self._x >> RESOLUTION);
    }
}