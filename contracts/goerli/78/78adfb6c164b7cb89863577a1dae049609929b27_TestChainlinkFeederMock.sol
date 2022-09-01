// SPDX-License-Identifier: GPL
pragma solidity >=0.7.0 < 0.9.0;

import "../ChainlinkMarket.sol";

contract TestChainlinkFeederMock is IChainlinkAggregator {
    int private currentPrice;
    uint8 private decimal;

    constructor(uint8 _decimal) {
        decimal = _decimal;
    }

    function setPrice(int newPrice) public {
        currentPrice = newPrice;
    }

    function latestRoundData() external view returns (uint80, int, uint, uint, uint80) {
        return (0, currentPrice * int(10 ** decimal), 0, 0, 0);
    }

    function decimals() public view returns (uint8) {
        return decimal;
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import "./library/LibMath.sol";
import "./library/LibTypes.sol";
import "./interface/IUnderlying.sol";

interface IChainlinkAggregator {
    function decimals() external view returns (uint8);

    function latestRoundData() external view returns (
        uint80 roundId, int answer, uint startedAt, uint updatedAt, uint80 answeredInRound);
}

contract ChainlinkMarket is Ownable, Initializable {
    using LibMathUnsigned for uint;
    using SafeCast for int;
    using SafeCast for uint;

    bytes4 private constant _DECIMAL_SELECTOR = bytes4(keccak256(bytes("decimals()")));
    bytes4 private constant _SYMBOL_SELECTOR = bytes4(keccak256(bytes("symbol()")));
    string public constant marketType = "CHAINLINK";

    uint16 public maxInitialDailyBasis = 3;
    uint16 public maxMarkChangeRatioPerSecond = 2;

    mapping(address => Types.QuoteParam) public quotes;    // quote address => quote parameter
    mapping(address => UnderlyingInfo) public underlyingsInfo;  // underlying address => underlying info

    // to assist the calculation of twap price for perpetual pair during SETTLING
    mapping(address => AccumulateState) public perpetualAccStates;
    // to assist the calculation of twap price for quarterly pair during SETTLING
    mapping(address => AccumulateState) public quarterlyAccStates;
    mapping(address => MarkState) public markStates; // to assist the calculation of mark price during TRADING

    event SetQuoteParam(address quote, Types.QuoteParam param);
    event SetUnderlyingInfo(address underlying, UnderlyingInfo info);
    event SetMaxInitialDailyBasis(uint maxInitialDailyBasis);
    event SetMaxMarkChangeRatioPerSecond(uint maxMarkChangeRatioPerSecond);
    event NewUnderlying(string base, address quote, address underlying);
    event UpdateMarkState(address indexed underlying, uint spotPrice, MarkState state);
    event UpdateAccumulateState(address indexed underlying, uint indexed expiry, AccumulateState state);

    struct Feeder {
        uint56 scaler0;                   // share a slot, 10**(18 - aggregator0.decimals())
        IChainlinkAggregator aggregator0; // share a slot, ASSET/USD or ASSET/TOKEN

        // the following fields shares 1 slot & are optional, where aggregator1 must be STABLECOIN/USD
        // this is to support indirect price, e.g. BTC/USD & MIM/USD => BTC/MIM, set with caution
        uint64 scaler1;                   // share a slot, 10**(18 - aggregator1.decimals())
        IChainlinkAggregator aggregator1; // share a slot, STABLECOIN/USD
    }

    struct UnderlyingInfo {
        // 0 for base/quote both stableCoin, 1 for neither base/quote are stableCoin,
        // 2 for quote is stableCoin & base is not, 3 for base is stableCoin & quote is not
        uint8 underlyingType;
        Feeder feeder;
    }

    struct AccumulateState {
        uint112 lastPrice;  // slot0
        uint112 accPrice;   // slot0, accPrice += lastPrice * (currTime - lastTime)
        uint32 initTime;    // slot0, timestamp of the moment entering SETTLING
    }

    struct MarkState {
        uint32 lastTime;
        uint112 lastMarkPrice0;
        uint112 lastMarkPrice1;
    }

    function initialize(
        address _admin,
        address[] memory _quotes, Types.QuoteParam[] memory _quoteParams,
        address[] memory _underlyings, UnderlyingInfo[] memory _underlyingsInfo,
        uint _maxInitialDailyBasis, uint _maxMarkChangeRatioPerSecond
    ) public initializer {
        require(_quotes.length == _quoteParams.length && _underlyings.length == _underlyingsInfo.length,
            "length mismatch");

        for (uint i = 0; i < _quotes.length; i = i + 1) {
            quotes[_quotes[i]] = _quoteParams[i];
            emit SetQuoteParam(_quotes[i], _quoteParams[i]);
        }

        for (uint i = 0; i < _underlyings.length; i = i + 1) {
            _setUnderlyingInfo(_underlyings[i], _underlyingsInfo[i]);
        }

        _setMaxInitialDailyBasis(_maxInitialDailyBasis);
        _setMaxMarkChangeRatioPerSecond(_maxMarkChangeRatioPerSecond);

        _transferOwnership(_admin);
    }

    function spotPrice(address underlying) public view returns (uint) {
        Feeder memory feeder = underlyingsInfo[underlying].feeder;
        require(address(feeder.aggregator0) != address(0), "missing feeder");

        (,int answer0,,,) = IChainlinkAggregator(feeder.aggregator0).latestRoundData();
        uint price0 = answer0.toUint256() * uint(feeder.scaler0);

        if (address(feeder.aggregator1) != address(0)) {// indirect price feeder, e.g. BTC/USD, MIM/USD => BTC/MIM
            (,int answer1,,,) = IChainlinkAggregator(feeder.aggregator1).latestRoundData();
            uint price1 = answer1.toUint256() * uint(feeder.scaler1);
            return price0.wdiv(price1);
        }

        return price0;
    }

    function benchmarkPrice(address underlying, uint expiry) public view returns (uint) {
        uint _spotPrice = spotPrice(underlying);
        if (expiry == 0) return _spotPrice;
        uint daysLeft = block.timestamp >= expiry ? 0 : (expiry - block.timestamp - 1) / 1 days + 1;
        return _calcBenchmarkPrice(_spotPrice, underlyingsInfo[underlying].underlyingType, daysLeft);
    }

    function marketPrices(Types.ActivePairs memory activePairs) public returns (uint[3] memory markPrices) {
        address underlying = msg.sender;
        uint _spotPrice = spotPrice(underlying);

        MarkState memory state = markStates[underlying];
        uint lastTime = state.lastTime;
        _calcMarkPrice(state, activePairs, _spotPrice, underlyingsInfo[underlying].underlyingType);
        // for perpetual pair, to use spot price as markprice directly
        markPrices[0] = _spotPrice;
        for (uint i = 0; i < 2; i++) {
            markPrices[i + 1] = _getLastMarkPrice(state, i);
        }

        // if perpetual enters SETTLING or ends SETTLING
        Types.Status perpetualStatus = activePairs.perpetualStatus;
        if (perpetualStatus == Types.Status.SETTLING || perpetualStatus == Types.Status.SETTLED) {
            AccumulateState memory accState = perpetualAccStates[underlying];
            uint twapPrice = _calcTwapPrice(accState, _spotPrice, lastTime);
            // if perpetual pair ends SETTLING, clear accState for perpetual pair & use twapPrice as markPrice
            if (perpetualStatus == Types.Status.SETTLED) {
                markPrices[0] = twapPrice;
                accState = AccumulateState(0, 0, 0);
            }
            perpetualAccStates[underlying] = accState;
            emit UpdateAccumulateState(underlying, 0, accState);
        }

        // if quarterly pair enters SETTLING or SETTLED
        Types.Status currQuarterStatus = activePairs.quarterlyPairs[0].status;
        if (currQuarterStatus == Types.Status.SETTLING || currQuarterStatus == Types.Status.SETTLED) {
            // there is no need to calculate TWAP for dormant pair
            bool dormantPair = activePairs.quarterlyPairs[0].dormantPair;
            if (!dormantPair) {
                AccumulateState memory accState = quarterlyAccStates[underlying];
                uint twapPrice = _calcTwapPrice(accState, _spotPrice, lastTime);
                markPrices[1] = twapPrice;

                if (currQuarterStatus == Types.Status.SETTLED) {
                    // if quarterly pair enters SETTLED, clear accState for perpetual pair
                    accState = AccumulateState(0, 0, 0);
                }
                quarterlyAccStates[underlying] = accState;
                emit UpdateAccumulateState(underlying, activePairs.quarterlyPairs[0].expiry, accState);
            }

            if (currQuarterStatus == Types.Status.SETTLED) {
                // swap lastMarkPrice of the next quarter to the current position
                // to keep markPrice of current quarter at 0 index
                state.lastMarkPrice0 = state.lastMarkPrice1;
                state.lastMarkPrice1 = 0;
            }
        }

        markStates[underlying] = state;
        emit UpdateMarkState(underlying, _spotPrice, state);
    }

    function setMaxInitialDailyBasis(uint _maxInitialDailyBasis) public onlyOwner {
        _setMaxInitialDailyBasis(_maxInitialDailyBasis);
    }

    function setMaxMarkChangeRatioPerSecond(uint _maxMarkChangeRatioPerSecond) public onlyOwner {
        _setMaxMarkChangeRatioPerSecond(_maxMarkChangeRatioPerSecond);
    }

    function _setMaxInitialDailyBasis(uint _maxInitialDailyBasis) internal {
        maxInitialDailyBasis = uint16(_maxInitialDailyBasis);
        emit SetMaxInitialDailyBasis(_maxInitialDailyBasis);
    }

    function _setMaxMarkChangeRatioPerSecond(uint _maxMarkChangeRatioPerSecond) internal {
        maxMarkChangeRatioPerSecond = uint16(_maxMarkChangeRatioPerSecond);
        emit SetMaxMarkChangeRatioPerSecond(_maxMarkChangeRatioPerSecond);
    }

    function _getLastMarkPrice(MarkState memory state, uint index) internal pure returns (uint) {
        assert(index <= 1);
        return index == 0 ? state.lastMarkPrice0 : state.lastMarkPrice1;
    }

    function _setLastMarkPrice(MarkState memory state, uint index, uint price) internal pure {
        assert(index <= 1);
        if (index == 0) {
            state.lastMarkPrice0 = uint112(price);
        } else {
            state.lastMarkPrice1 = uint112(price);
        }
    }

    function _calcTwapPrice(
        AccumulateState memory accState, uint _spotPrice, uint lastTime
    ) internal view returns (uint) {
        if (accState.initTime == 0) {
            accState.initTime = uint32(block.timestamp);
            accState.lastPrice = uint112(_spotPrice);
            return _spotPrice;
        }

        if (block.timestamp == accState.initTime) return _spotPrice;

        accState.accPrice += uint112((block.timestamp - lastTime) * accState.lastPrice);
        accState.lastPrice = uint112(_spotPrice);
        return accState.accPrice / (block.timestamp - accState.initTime);
    }

    function _calcMarkPrice(
        MarkState memory state, Types.ActivePairs memory activePairs, uint _spotPrice, uint underlyingType
    ) internal view {
        for (uint i = 0; i < 2; i++) {
            // skip the markprice calculation if not in TRADING status
            if (activePairs.quarterlyPairs[i].status != Types.Status.TRADING) continue;
            uint fairPrice = activePairs.quarterlyPairs[i].fairPrice;
            uint lastMarkPrice = _getLastMarkPrice(state, i);
            if (lastMarkPrice == 0) {
                // pair is changed from DORMANT => TRADING status
                _setLastMarkPrice(state, i, fairPrice);
                continue;
            }
            uint newMarkPrice = lastMarkPrice;
            uint maxMarkChange = lastMarkPrice.wmul(_c2w(maxMarkChangeRatioPerSecond)) * (block.timestamp - state.lastTime);
            if (fairPrice > lastMarkPrice) {
                // calculate markprice's upper limit according to last markprice & maxMarkChangeRatioPerBlock
                newMarkPrice = lastMarkPrice + maxMarkChange;
                newMarkPrice = newMarkPrice > fairPrice ? fairPrice : newMarkPrice;
            } else if (fairPrice < lastMarkPrice) {
                // calculate markprice's lower limit according to last markprice & maxMarkChangeRatioPerBlock
                newMarkPrice = lastMarkPrice > maxMarkChange ? lastMarkPrice - maxMarkChange : 0 ;
                newMarkPrice = newMarkPrice < fairPrice ? fairPrice : newMarkPrice;
            }

            _setLastMarkPrice(state, i, newMarkPrice);

            uint daysLeft = block.timestamp >= activePairs.quarterlyPairs[i].expiry ? 0
                : (activePairs.quarterlyPairs[i].expiry - block.timestamp - 1) / 1 days + 1;
            uint _benchmarkPrice = _calcBenchmarkPrice(_spotPrice, underlyingType, daysLeft);
            uint benchmarkRange = _benchmarkPrice.wmul(_c2w(maxInitialDailyBasis)) * daysLeft;
            uint upperBenchmark = _benchmarkPrice + benchmarkRange;
            uint lowerBenchmark = _benchmarkPrice > benchmarkRange ? _benchmarkPrice - benchmarkRange : 0;

            if (newMarkPrice < lowerBenchmark) _setLastMarkPrice(state, i, lowerBenchmark);
            if (newMarkPrice > upperBenchmark) _setLastMarkPrice(state, i, upperBenchmark);
        }

        state.lastTime = uint32(block.timestamp);
    }

    function _calcBenchmarkPrice(uint _spotPrice, uint underlyingType, uint daysLeft) internal view returns (uint) {
        uint price;
        if (underlyingType == 0 || underlyingType == 1) price =  _spotPrice;
        else if (underlyingType == 2) {
            price = _spotPrice + _spotPrice.wmul(_c2w(maxInitialDailyBasis)) * daysLeft;
        } else if (underlyingType == 3) {
            // priceChange is extremely unlikely to be greater than spot price
            uint priceChange = _spotPrice.wmul(_c2w(maxInitialDailyBasis)) * daysLeft;
            price = _spotPrice > priceChange ? _spotPrice - priceChange : 0 ;
        }
        return price;
    }

    function currentMarketPrices(address underlying) public view returns (uint[3] memory markPrices) {
        uint _spotPrice = spotPrice(underlying);

        MarkState memory state = markStates[underlying];
        Types.ActivePairs memory activePairs = IUnderlying(underlying).getActivePairs();
        uint lastTime = state.lastTime;
        _calcMarkPrice(state, activePairs, _spotPrice, underlyingsInfo[underlying].underlyingType);
        // for perpetual pair, to use spot price as markprice directly
        markPrices[0] = _spotPrice;
        for (uint i = 0; i < 2; i++) {
            markPrices[i + 1] = _getLastMarkPrice(state, i);
        }

        // if quarterly pair enters SETTLING or SETTLED
        Types.Status currQuarterStatus = activePairs.quarterlyPairs[0].status;
        if (currQuarterStatus == Types.Status.SETTLING || currQuarterStatus == Types.Status.SETTLED) {
            AccumulateState memory accState = quarterlyAccStates[underlying];
            uint twapPrice = _calcTwapPrice(accState, _spotPrice, lastTime);
            markPrices[1] = twapPrice;
        }
    }

    function setQuoteParam(address _quote, Types.QuoteParam calldata _param) public onlyOwner {
        quotes[_quote] = _param;
        emit SetQuoteParam(_quote, _param);
    }

    function setUnderlyingInfo(address _underlying, UnderlyingInfo calldata _info) public onlyOwner {
       _setUnderlyingInfo(_underlying, _info);
    }

    function _setUnderlyingInfo(address _underlying, UnderlyingInfo memory _info) internal {
        require(_info.underlyingType <= 3, "unsupported underlyingType");
        require(address(_info.feeder.aggregator0) != address(0), "invalid feeder");
        underlyingsInfo[_underlying] = _info;
        emit SetUnderlyingInfo(_underlying, _info);
    }

    function feederExists(address _underlying) public view returns (bool) {
        return address(underlyingsInfo[_underlying].feeder.aggregator0) != address(0);
    }

    function newUnderlying(
        bytes calldata data
    ) public returns (bytes memory, bytes32, address) {
        (string memory base, address quote, address underlying) = abi.decode(data,
            (string, address, address));
        require(feederExists(underlying), "missing feeder");
        require(quote != address(0) && quotes[quote].quoteType != 0, "unsupported quote");

        uint decimals = _getDecimals(quote);
        uint scaler = 10 ** (18 - decimals);

        string memory symbol = _getUnderlyingSymbol(base, quote);
        // 这里 signature 是 prototype 的意思
        bytes memory parameters = abi.encodeWithSignature(
            "initialize(string,address,address,uint56)", symbol, address(this), quote, uint56(scaler));
        bytes32 index = indexForUnderlying(base, quote);
        emit NewUnderlying(base, quote, underlying);
        return (parameters, index, underlying);
    }

    function indexForUnderlying(string memory base, address quote) public pure returns (bytes32) {
        return keccak256(abi.encode(base, quote, marketType));
    }

    function _getUnderlyingSymbol(
        string memory baseSymbol, address quote
    ) internal returns (string memory) {
        string memory quoteSymbol = _getSymbol(quote);
        return string(abi.encodePacked(baseSymbol, "-", quoteSymbol, "-LINK"));
    }

    function _getSymbol(address token) internal returns (string memory) {
        (, bytes memory data) = token.call(abi.encodeWithSelector(_SYMBOL_SELECTOR));
        return abi.decode(data, (string));
    }

    function _getDecimals(address token) internal returns (uint8) {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(_DECIMAL_SELECTOR));
        require(success, "invalid decimal");
        return abi.decode(data, (uint8));
    }

    function getUnderlyingType(address underlying) public view returns (uint8) {
        return underlyingsInfo[underlying].underlyingType;
    }

    function getBase(address underlying) public view returns (Types.Base memory) {
        Types.Base memory base;
        string memory underlyingSymbol = IUnderlying(underlying).symbol();
        base.symbol = _getBaseSymbol(underlyingSymbol);
        base.tokenAddr = address(0);
        base.decimals = 0;
        return base;
    }

    function _getBaseSymbol(string memory pairSymbol) internal pure returns (string memory) {
        uint baseLength;
        for (baseLength = 0; baseLength < bytes(pairSymbol).length; baseLength++) {
            if (bytes(pairSymbol)[baseLength] == "-") break;
        }
        string memory base = new string(baseLength);
        assembly {
            mstore(add(base, 0x20), mload(add(pairSymbol, 0x20)))
        }
        return base;
    }

    // convert config value to 10^18
    function _c2w(uint x) internal pure returns (uint) {
        return x * 10**14; // convert config value to internal wad form
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
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !Address.isContract(address(this));
    }
}

// SPDX-License-Identifier: GPL
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/SignedSafeMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

library LibMathSigned {
    int private constant _WAD = 10 ** 18;

    function WAD() internal pure returns (int) {
        return _WAD;
    }

    function neg(int a) internal pure returns (int) {
        return int(0) - a;
    }

    function abs(int a) internal pure returns (int) {
        return a >= 0 ? a: neg(a);
    }

    function wmul(int x, int y) internal pure returns (int z) {
        z = roundHalfUp(x * y,  _WAD) / _WAD;
    }

    // solium-disable-next-line security/no-assign-params
    function wdiv(int x, int y) internal pure returns (int z) {
        if (y < 0) {
            y = -y;
            x = -x;
        }
        z = roundHalfUp(x * _WAD, y) / y;
    }

    // ROUND_HALF_UP rule helper. You have to call roundHalfUp(x, y) / y to finish the rounding operation
    // 0.5 ≈ 1, 0.4 ≈ 0, -0.5 ≈ -1, -0.4 ≈ 0
    function roundHalfUp(int x, int y) internal pure returns (int) {
        require(y > 0, "RoundHalfUp: only supports y > 0");
        if (x >= 0) {
            return x + y / 2;
        }
        return x - y / 2;
    }
}


library LibMathUnsigned {
    uint private constant _WAD = 10**18;
    uint private constant _POSITIVE_INT256_MAX = 2**255 - 1;

    function WAD() internal pure returns (uint) {
        return _WAD;
    }

    function POSITIVE_INT256_MAX() internal pure returns (uint) {
        return _POSITIVE_INT256_MAX;
    }

    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = (x * y + _WAD / 2) / _WAD;
    }

    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = (x * _WAD + y / 2) / y;
    }

    function wfrac(uint x, uint y, uint z) internal pure returns (uint r) {
        r = x * y / z;
    }
}

// Uniswap's FixedPoint library
// see https://github.com/Uniswap/uniswap-lib/blob/master/contracts/libraries/FixedPoint.sol
library FixedPoint {
    using SafeMath for uint;
    // range: [0, 2**112 - 1]
    // resolution: 1 / 2**112
    struct uq112x112 {
        uint224 _x;
    }

    uint8 private constant RESOLUTION = 112;
    uint256 private constant Q112 = 0x10000000000000000000000000000;

    // returns a UQ112x112 which represents the ratio of the numerator to the denominator
    // lossy if either numerator or denominator is greater than 112 bits
    function fraction(uint256 numerator, uint256 denominator) internal pure returns (uq112x112 memory) {
        require(denominator > 0, "FixedPoint::fraction: division by zero");
        if (numerator == 0) return FixedPoint.uq112x112(0);

        if (numerator <= type(uint144).max) {
            uint256 result = (numerator << RESOLUTION).div(denominator);
            require(result <= type(uint224).max, "FixedPoint::fraction: overflow");
            return uq112x112(uint224(result));
        } else {
            uint256 result = FullMath.mulDiv(numerator, Q112, denominator);
            require(result <= type(uint224).max, "FixedPoint::fraction: overflow");
            return uq112x112(uint224(result));
        }
    }
}

library FullMath {
    function fullMul(uint256 x, uint256 y) private pure returns (uint256 l, uint256 h) {
        uint256 mm = mulmod(x, y, type(uint256).max);
        l = x * y;
        h = mm - l;
        if (mm < l) h -= 1;
    }

    function fullDiv(uint256 l, uint256 h, uint256 d) private pure returns (uint256) {
        uint256 dNeg = type(uint256).max - d + 1;
        uint256 pow2 = d & dNeg;
        
        d /= pow2;
        l /= pow2;
        uint256 pow2Neg = type(uint256).max - pow2 + 1;
        l += h * (pow2Neg / pow2 + 1);
        uint256 r = 1;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        return l * r;
    }

    function mulDiv(uint256 x, uint256 y, uint256 d) internal pure returns (uint256) {
        (uint256 l, uint256 h) = fullMul(x, y);
        uint256 mm = mulmod(x, y, d);
        if (mm > l) h -= 1;
        l -= mm;
        require(h < d, "FullMath::mulDiv: overflow");
        return fullDiv(l, h, d);
    }
}

// SPDX-License-Identifier: GPL
pragma solidity ^0.8.0;
import "./LibMath.sol";

library Types {

    using LibMathUnsigned for uint;
    using LibMathSigned for int;

    enum Side {FLAT, SHORT, LONG}

    enum Status {DORMANT, TRADING, SETTLING, SETTLED}

    // 0 for normal, 1 for emergency, 2 for all pairs settled
    enum UnderlyingStatus {NORMAL, EMERGENCY, SETTLED}

    function counterSide(Side side) internal pure returns (Side) {
        if (side == Side.LONG) {
            return Side.SHORT;
        } else if (side == Side.SHORT) {
            return Side.LONG;
        }
        return side;
    }

    struct AmmStateCache {
        uint x;
        uint y;

        Types.Status status;
        uint totalShares;
        int balance;

        uint feePerShare;
        uint openInterests;

        uint socialLoss; // 128-bit socialLossPerLong || 128-bit socialLossPerShort
    }

    function cacheAmmState(
        mapping(uint => AmmState) storage ammStates, uint expiry
    ) internal view returns (Types.AmmStateCache memory state) {
        AmmState storage ammState = ammStates[expiry];
        (state.x, state.y) = getXY(ammState.xy);
        state.status = ammState.status;
        state.totalShares = ammState.totalShares;
        state.balance = ammState.balance;
        state.feePerShare = ammState.feePerShare;
        state.openInterests = ammState.openInterests;
        state.socialLoss = ammState.socialLoss;
    }

    function writeAmmState(
        mapping(uint => AmmState) storage ammStates, uint expiry, AmmStateCache memory state
    ) internal {
        uint xy = (state.x << 128) + state.y;
        if (ammStates[expiry].xy != xy) ammStates[expiry].xy = xy;
        if (ammStates[expiry].status != state.status || ammStates[expiry].totalShares != state.totalShares
                || ammStates[expiry].balance != state.balance) {
            ammStates[expiry].status = state.status;
            ammStates[expiry].totalShares = uint120(state.totalShares);
            ammStates[expiry].balance = int128(state.balance);
        }

        if (ammStates[expiry].feePerShare != state.feePerShare
            || ammStates[expiry].openInterests != state.openInterests) {
            ammStates[expiry].feePerShare = uint128(state.feePerShare);
            ammStates[expiry].openInterests = uint128(state.openInterests);
        }

        if (ammStates[expiry].socialLoss != state.socialLoss) ammStates[expiry].socialLoss = state.socialLoss;
    }

    struct Ctx {
        uint currQuarterIndex;
        // 3 的含义: 同一个underlying内部同时只允许最多三个到期日
        uint[3] expiries;

        uint[3] markPrices;
        Types.QuoteParam param;
    }

    struct PairInfo {
        uint expiry;
        uint fairPrice;
        Status status;
        bool dormantPair;
    }

    struct ActivePairs {
        Status perpetualStatus;

        // pairs info for currQuarter & nextQuarter
        PairInfo[2] quarterlyPairs;
    }

    struct Base {
        string symbol;
        address tokenAddr; // for chainlink base is ZERO_ADDRESS
        uint decimals; // for chainlink base is 0
    }

    struct QuoteInfo {
        address quote;
        uint56 scaler;
    }

    struct QuoteParam {
        // fee ratio related configs
        uint16 priceChangeRatioThreshold;
        uint16 poolFeeRatioLow;
        uint16 poolFeeRatioHigh;
        uint16 poolFeeVersusReserveFee;

        uint16 initialMarginRatio;
        uint16 maintenanceMarginRatio;
        uint16 maxUserTradeOpenInterestRatio;

        uint8 quoteType;        // 0 - unsupported, 1 - stablecoin, 2 - non-stablecoin
        uint128 threshold; // minimum amount required to maintain a pool, checked when initPool/removeLq, wad form
    }

    struct AmmState {
        // 128-bit x || 128-bit y in UNINITIALIZED/TRADING/SETTLING, settlementPrice for SETTLED
        uint xy;

        Types.Status status;
        // totalShares may always change with balance, keep them in the same slot
        uint120 totalShares;
        int128 balance;

        uint128 feePerShare;
        uint128 openInterests;

        // 128-bit socialLossPerLong || 128-bit socialLossPerShort
        uint socialLoss;
    }

    function getFairPrice(Types.AmmState storage state) internal view returns (uint) {
        (uint x, uint y) = getXY(state.xy);
        if (y == 0) return 0;
        return x.wdiv(y);
    }

    function getXY(uint xy) internal pure returns (uint x, uint y) {
        x = xy >> 128;
        y = uint(uint128(xy));
    }

    struct PositionCache {
        uint shares;
        uint entryFeePerShare;

        int size; // position size, positive for LONG, negative for SHORT
        // entry cost for current position, keeps average cost the same when reducing position to realize pnl
        uint entryNotional;
        uint entrySocialLoss; // entry social loss, keeps average the same when reducing position
    }

    struct AccountCache {
        int balance; // account balance
        uint currQuarterIndex;
        PositionCache[3] positions;
    }

    struct Position {
        uint128 shares;
        uint128 entryFeePerShare;

        int128 size; // position size, positive for LONG, negative for SHORT
        uint128 entryNotional; // entry cost for current position, keeps average cost the same when reducing position to realize pnl
        uint128 entrySocialLoss; // entry social loss, keeps average the same when reducing position
    }

    struct Account {
        int248 balance; // account balance
        uint8 currQuarterIndex; // current quarter index
        Position[3] positions;
    }

    struct TradeOp {
        uint opIndex;   // the pair to interact with, 0 for perpetual, 1 for curr quarter, 2 for next quarter
        address trader; // involved trader
        int size;
        uint price;
        uint tradingFee;
        uint reserveFee;
    }

    struct LiquidityOp {
        uint opIndex;   // the pair to interact with, 0 for perpetual, 1 for curr quarter, 2 for next quarter
        address trader; // involved trader
        int shares;     // shares > 0 && size < 0 when addLq, shares < 0 & size > 0 when removeLq
        int size;       // shares > 0 && size < 0 when addLq, shares < 0 & size > 0 when removeLq
        uint price;
        int amount;
    }

    struct LiquidateOp {
        address liquidator;
        address target;
        uint insuranceFund;
    }

    struct MarginOp {
        address fromOrTo; // funder when deposit, and receipt when withdraw
        address trader;   // involved trader
        address quote;
        uint amount;
        uint scaler;
    }

    struct AccountData {
        uint128 totalDeposit;
        uint128 totalWithdrawal;
        uint128 totalLpDeposit;
        int128 totalLpWithdrawal;
        uint claimedFee;
    }
}

// SPDX-License-Identifier: GPL
pragma solidity ^0.8.0;

import "../library/LibTypes.sol";

interface IUnderlying {
    function deposit(address trader, uint amount) external payable;
    function withdraw(address trader, address to, uint amount) external payable returns (uint);
    function settle(address trader) external;
    function trade(address trader, uint expiry, int size, uint limitPrice, uint deadline) external;
    function addLiquidity(address trader, uint expiry, uint marginAmount, uint targetPrice, uint slippage, uint deadline) external;
    function removeLiquidity(address trader, uint expiry, uint shares, uint targetPrice, uint slippage, uint deadline) external;
    function update() external;
    function liquidate(address liquidator, address target, uint deadline) external;

    // view functions
    function symbol() external view returns (string memory);
    function market() external view returns (address);
    function totalReserveFee() external view returns (uint);
    function insuranceFund() external view returns (uint);
    function currQuarterIndex() external view returns (uint);
    function perpetualSettlingTime() external view returns (uint);
    function quarterlySettlingTime() external view returns (uint);
    function underlyingStatus() external view returns (Types.UnderlyingStatus);
    function quoteInfo() external view returns (Types.QuoteInfo memory);
    function getExpiries() external view returns (uint[3] memory);
    function ammStates(uint expiry) external view returns (Types.AmmState memory);
    function getAccount(address trader) external view returns (Types.Account memory);
    function accountsData(address trader) external view returns (Types.AccountData memory);
    function getActivePairs() external view returns (Types.ActivePairs memory);
    function totalAccounts() external view returns (uint);
    function accountList(uint index) external view returns (address);
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
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SignedSafeMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SignedSafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SignedSafeMath {
    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        return a / b;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        return a - b;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        return a + b;
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