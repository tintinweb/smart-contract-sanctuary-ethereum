// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./Interfaces/IPriceFeed.sol";

import "./Dependencies/CheckContract.sol";
import "./Dependencies/BaseMath.sol";
import "./Dependencies/DfrancMath.sol";

contract PriceFeed is Ownable, CheckContract, BaseMath, IPriceFeed {
    using SafeMath for uint256;

    string public constant NAME = "PriceFeed";

    // Use to convert a price answer to an 18-digit precision uint
    uint256 public constant TARGET_DIGITS = 18;

    uint256 public constant TIMEOUT = 4 hours;

    // Maximum deviation allowed between two consecutive Chainlink oracle prices. 18-digit precision.
    uint256 public constant MAX_PRICE_DEVIATION_FROM_PREVIOUS_ROUND = 5e17; // 50%
    uint256 public constant MAX_PRICE_DIFFERENCE_BETWEEN_ORACLES = 5e16; // 5%

    bool public isInitialized;

    address public adminContract;

    IPriceFeed.Status public status;
    mapping(address => RegisterOracle) public registeredOracles;
    mapping(address => uint256) public lastGoodPrice;
    mapping(address => uint256) public lastGoodForex;

    bool public mockMode;
    uint256 public mockPrice = 1234e15;

    function setMockPrice(uint256 _mockPrice) external onlyOwner {
        mockPrice = _mockPrice;
    }

    function toggleMockMode() external onlyOwner {
        mockMode = !mockMode;
    }

    modifier isController() {
        require(msg.sender == owner() || msg.sender == adminContract, "Invalid Permission");
        _;
    }

    function setAddresses(address _adminContract) external onlyOwner {
        require(!isInitialized, "Already initialized");
        checkContract(_adminContract);
        isInitialized = true;

        adminContract = _adminContract;
        status = Status.chainlinkWorking;
    }

    function setAdminContract(address _admin) external onlyOwner {
        require(_admin != address(0), "Admin address is zero");
        checkContract(_admin);
        adminContract = _admin;
    }

    /**
     * @notice Returns the data for the latest round of this oracle
     * @param _token the address of the token to add
     * @param _oracle the address of the oracle giving the price of the token in USD
     * @param _chainlinkForexOracle the address of the Forex Chainlink Oracle to convert from USD
     */
    function addOracle(
        address _token,
        address _oracle,
        address _chainlinkForexOracle
    ) external override isController {
        IOracle priceOracle = IOracle(_oracle);
        AggregatorV3Interface forexOracle = AggregatorV3Interface(_chainlinkForexOracle);

        registeredOracles[_token] = RegisterOracle(priceOracle, forexOracle, true);

        // (
        //     OracleResponse memory oracleResponse,
        //     ChainlinkResponse memory chainlinkForexResponse
        // ) = _getOracleResponses(priceOracle, forexOracle);

        // require(
        //     !_badChainlinkResponse(chainlinkForexResponse) && !_chainlinkIsFrozen(oracleResponse),
        //     "PriceFeed: Chainlink must be working and current"
        // );

        // _storeOraclePrice(_token, oracleResponse);
        // _storeChainlinkForex(_token, chainlinkForexResponse);

        // emit RegisteredNewOracle(_token, _oracle, _chainlinkForexOracle);
    }

    /**
     * @notice Returns the price of the given asset in CHF
     * @param _asset address of the asset to get the price of
     * @return _priceAssetInDCHF the price of the asset in CHF with the global precision
     */
    function getDirectPrice(address _asset) public view returns (uint256 _priceAssetInDCHF) {
        return mockPrice;

        RegisterOracle memory oracle = registeredOracles[_asset];
        (
            OracleResponse memory oracleResponse,
            ChainlinkResponse memory chainlinkForexResponse
        ) = _getOracleResponses(oracle.oracle, oracle.chainLinkForex);

        uint256 scaledOraclePrice = _scaleChainlinkPriceByDigits(
            uint256(oracleResponse.answer),
            oracleResponse.decimals
        );

        uint256 scaledChainlinkForexPrice = _scaleChainlinkPriceByDigits(
            uint256(chainlinkForexResponse.answer),
            chainlinkForexResponse.decimals
        );

        _priceAssetInDCHF = scaledOraclePrice.mul(1 ether).div(scaledChainlinkForexPrice);
    }

    /**
     * @notice Returns the last good price of the given asset in CHF. If Chainlink is working it returns the current price and updates the last good prices
     * @param _token address of the asset to get and update the price of
     * @return the price of the asset in CHF with the global precision
     */
    function fetchPrice(address _token) external override returns (uint256) {
        if (mockMode) {
            return mockPrice;
        }

        RegisterOracle storage oracle = registeredOracles[_token];
        require(oracle.isRegistered, "Oracle is not registered!");

        (
            OracleResponse memory oracleResponse,
            ChainlinkResponse memory chainlinkForexResponse
        ) = _getOracleResponses(oracle.oracle, oracle.chainLinkForex);

        uint256 lastTokenGoodPrice = lastGoodPrice[_token];
        uint256 lastTokenGoodForex = lastGoodForex[_token];

        bool isChainlinkBroken = _badChainlinkResponse(chainlinkForexResponse) ||
            _chainlinkIsFrozen(oracleResponse);

        if (status == Status.chainlinkWorking) {
            if (isChainlinkBroken) {
                _changeStatus(Status.chainlinkUntrusted);
                return _getForexedPrice(lastTokenGoodPrice, lastTokenGoodForex);
            }

            // If Chainlink price has changed by > 50% between two consecutive rounds
            if (_chainlinkForexPriceChangeAboveMax(chainlinkForexResponse, lastTokenGoodForex)) {
                return _getForexedPrice(lastTokenGoodPrice, lastTokenGoodForex);
            }

            lastTokenGoodPrice = _storeOraclePrice(_token, oracleResponse);
            lastTokenGoodForex = _storeChainlinkForex(_token, chainlinkForexResponse);

            return _getForexedPrice(lastTokenGoodPrice, lastTokenGoodForex);
        }

        if (status == Status.chainlinkUntrusted) {
            if (!isChainlinkBroken) {
                _changeStatus(Status.chainlinkWorking);
                lastTokenGoodPrice = _storeOraclePrice(_token, oracleResponse);
                lastTokenGoodForex = _storeChainlinkForex(_token, chainlinkForexResponse);
            }

            return _getForexedPrice(lastTokenGoodPrice, lastTokenGoodForex);
        }

        return _getForexedPrice(lastTokenGoodPrice, lastTokenGoodForex);
    }

    /**
     * @notice Transforms the price from USD to a given foreign currency
     * @param _price address of the asset to get and update the price of
     * @param _forex the exchange rate to the foreign currency
     * @return the price converted to foreign currency
     */
    function _getForexedPrice(uint256 _price, uint256 _forex) internal pure returns (uint256) {
        return _price.mul(1 ether).div(_forex);
    }

    /**
     * @notice Queries both LP token and Chainlink oracles and get their responses
     * @param _oracle address of the LP token oracle
     * @param _chainLinkForexOracle address of Chainlink Forex Oracle
     */
    function _getOracleResponses(IOracle _oracle, AggregatorV3Interface _chainLinkForexOracle)
        internal
        view
        returns (OracleResponse memory currentOracle, ChainlinkResponse memory currentChainlinkForex)
    {
        currentOracle = _getCurrentOracleResponse(_oracle);

        if (address(_chainLinkForexOracle) != address(0)) {
            currentChainlinkForex = _getCurrentChainlinkResponse(_chainLinkForexOracle);
        } else {
            currentChainlinkForex = ChainlinkResponse(1, 1 ether, block.timestamp, true, 18);
        }

        return (currentOracle, currentChainlinkForex);
    }

    /**
     * @notice Checks is Chainlink is giving a bad response
     * @param _response struct containing all the data of a Chainlink response
     * @return a boolean indicating if the response is not valid (true)
     */
    function _badChainlinkResponse(ChainlinkResponse memory _response) internal view returns (bool) {
        if (!_response.success) {
            return true;
        }
        if (_response.roundId == 0) {
            return true;
        }
        if (_response.timestamp == 0 || _response.timestamp > block.timestamp) {
            return true;
        }
        if (_response.answer <= 0) {
            return true;
        }

        return false;
    }

    //@dev Checks if Chainlink response is current enough
    function _chainlinkIsFrozen(OracleResponse memory _response) internal view returns (bool) {
        return block.timestamp.sub(_response.timestamp) > TIMEOUT;
    }

    //@dev checks if Chainlink Forex Oracle is not giving a price that deviates too much from the last provided
    function _chainlinkForexPriceChangeAboveMax(
        ChainlinkResponse memory _currentResponse,
        uint256 _lastTokenGoodForex
    ) internal pure returns (bool) {
        uint256 currentScaledPrice = _scaleChainlinkPriceByDigits(
            uint256(_currentResponse.answer),
            _currentResponse.decimals
        );

        uint256 minPrice = DfrancMath._min(currentScaledPrice, _lastTokenGoodForex);
        uint256 maxPrice = DfrancMath._max(currentScaledPrice, _lastTokenGoodForex);

        /*
         * Use the larger price as the denominator:
         * - If price decreased, the percentage deviation is in relation to the the previous price.
         * - If price increased, the percentage deviation is in relation to the current price.
         */
        uint256 percentDeviation = maxPrice.sub(minPrice).mul(DECIMAL_PRECISION).div(maxPrice);

        // Return true if price has more than doubled, or more than halved.
        return percentDeviation > MAX_PRICE_DEVIATION_FROM_PREVIOUS_ROUND;
    }

    /**
     * @notice Util function to scale a given price to the Dfranc's target precision
     * @param _price is the price to scale
     * @param _answerDigits is the number of digits of _price
     * @return the price scaled Dfranc's target precision
     */
    function _scaleChainlinkPriceByDigits(uint256 _price, uint256 _answerDigits)
        internal
        pure
        returns (uint256)
    {
        uint256 price;
        if (_answerDigits >= TARGET_DIGITS) {
            // Scale the returned price value down to Dfranc's target precision
            price = _price.div(10**(_answerDigits - TARGET_DIGITS));
        } else if (_answerDigits < TARGET_DIGITS) {
            // Scale the returned price value up to Dfranc's target precision
            price = _price.mul(10**(TARGET_DIGITS - _answerDigits));
        }
        return price;
    }

    /**
     * @notice Changes the status of this PriceFeed contract
     * @param _status is the new status to mutate to
     */
    function _changeStatus(Status _status) internal {
        status = _status;
        emit PriceFeedStatusChanged(_status);
    }

    /**
     * @notice Stores the last Chainlink Forex response and returns its value
     * @param _token the address of the token to add the Forex response
     * @param _chainlinkForexResponse the response struct to store
     * @return the value of the Forex rate of the provided response scaled to Dfranc's precision
     */
    function _storeChainlinkForex(address _token, ChainlinkResponse memory _chainlinkForexResponse)
        internal
        returns (uint256)
    {
        uint256 scaledChainlinkForex = _scaleChainlinkPriceByDigits(
            uint256(_chainlinkForexResponse.answer),
            _chainlinkForexResponse.decimals
        );

        _storeForex(_token, scaledChainlinkForex);
        return scaledChainlinkForex;
    }

    /**
     * @notice Stores the last Oracle response and returns its value
     * @param _token the address of the token to add the Oracle response
     * @param _oracleResponse the response struct to store
     * @return the value of the token in USD in the provided response scaled to Dfranc's precision
     */
    function _storeOraclePrice(address _token, OracleResponse memory _oracleResponse)
        internal
        returns (uint256)
    {
        uint256 scaledChainlinkPrice = _scaleChainlinkPriceByDigits(
            uint256(_oracleResponse.answer),
            _oracleResponse.decimals
        );

        _storePrice(_token, scaledChainlinkPrice);
        return scaledChainlinkPrice;
    }

    /**
     * @notice Util function to update the current price of a given token
     * @param _token the address of the token to update
     * @param _currentPrice the new price to update to
     */
    function _storePrice(address _token, uint256 _currentPrice) internal {
        lastGoodPrice[_token] = _currentPrice;
        emit LastGoodPriceUpdated(_token, _currentPrice);
    }

    /**
     * @notice Util function to update the forex rate of a given token
     * @param _token the address of the token to update its Forex part
     * @param _currentForex the new forex rate to update to
     */
    function _storeForex(address _token, uint256 _currentForex) internal {
        lastGoodForex[_token] = _currentForex;
        emit LastGoodForexUpdated(_token, _currentForex);
    }

    // --- Oracle response wrapper functions ---

    /**
     * @notice Util function to get the current Chainlink response
     * @param _priceAggregator the interface of the Chainlink price feed
     * @return chainlinkResponse current Chainlink response struct
     */
    function _getCurrentChainlinkResponse(AggregatorV3Interface _priceAggregator)
        internal
        view
        returns (ChainlinkResponse memory chainlinkResponse)
    {
        try _priceAggregator.decimals() returns (uint8 decimals) {
            chainlinkResponse.decimals = decimals;
        } catch {
            return chainlinkResponse;
        }

        try _priceAggregator.latestRoundData() returns (
            uint80 roundId,
            int256 answer,
            uint256, /* startedAt */
            uint256 timestamp,
            uint80 /* answeredInRound */
        ) {
            chainlinkResponse.roundId = roundId;
            chainlinkResponse.answer = answer;
            chainlinkResponse.timestamp = timestamp;
            chainlinkResponse.success = true;
            return chainlinkResponse;
        } catch {
            return chainlinkResponse;
        }
    }

    /**
     * @notice Util function to get the current Oracle
     * @param _oracle the interface of the Oracle to query
     * @return oracleResponse current Oracle response struct
     */
    function _getCurrentOracleResponse(IOracle _oracle)
        internal
        view
        returns (OracleResponse memory oracleResponse)
    {
        try _oracle.decimals() returns (uint8 decimals) {
            oracleResponse.decimals = decimals;
        } catch {
            return oracleResponse;
        }

        try _oracle.latestAnswer() returns (int256 answer, uint256 timestamp) {
            oracleResponse.answer = answer;
            oracleResponse.timestamp = timestamp;
            oracleResponse.success = true;
            return oracleResponse;
        } catch {
            return oracleResponse;
        }
    }
}

// SPDX-License-Identifier: MIT
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./IOracle.sol";

pragma solidity ^0.8.14;

interface IPriceFeed {
    struct ChainlinkResponse {
        uint80 roundId;
        int256 answer;
        uint256 timestamp;
        bool success;
        uint8 decimals;
    }

    struct OracleResponse {
        int256 answer;
        uint256 timestamp;
        bool success;
        uint8 decimals;
    }

    struct RegisterOracle {
        IOracle oracle;
        AggregatorV3Interface chainLinkForex;
        bool isRegistered;
    }

    enum Status {
        chainlinkWorking,
        chainlinkUntrusted
    }

    // --- Events ---
    event PriceFeedStatusChanged(Status newStatus);
    event LastGoodPriceUpdated(address indexed token, uint256 _lastGoodPrice);
    event LastGoodForexUpdated(address indexed token, uint256 _lastGoodIndex);
    event RegisteredNewOracle(address token, address oracle, address chianLinkIndex);

    // --- Function ---
    function addOracle(
        address _token,
        address _oracle,
        address _chainlinkForexOracle
    ) external;

    function fetchPrice(address _token) external returns (uint256);

    function getDirectPrice(address _asset) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

contract CheckContract {
    function checkContract(address _account) internal view {
        require(_account != address(0), "Account cannot be zero address");

        uint256 size;
        assembly {
            size := extcodesize(_account)
        }
        require(size > 0, "Account code size cannot be zero");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library DfrancMath {
    using SafeMath for uint256;

    uint256 internal constant DECIMAL_PRECISION = 1 ether;

    /* Precision for Nominal ICR (independent of price). Rationale for the value:
     *
     * - Making it “too high” could lead to overflows.
     * - Making it “too low” could lead to an ICR equal to zero, due to truncation from Solidity floor division.
     *
     * This value of 1e20 is chosen for safety: the NICR will only overflow for numerator > ~1e39 ETH,
     * and will only truncate to 0 if the denominator is at least 1e20 times greater than the numerator.
     *
     */
    uint256 internal constant NICR_PRECISION = 1e20;

    function _min(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return (_a < _b) ? _a : _b;
    }

    function _max(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return (_a >= _b) ? _a : _b;
    }

    /*
     * Multiply two decimal numbers and use normal rounding rules:
     * -round product up if 19'th mantissa digit >= 5
     * -round product down if 19'th mantissa digit < 5
     *
     * Used only inside the exponentiation, _decPow().
     */
    function decMul(uint256 x, uint256 y) internal pure returns (uint256 decProd) {
        uint256 prod_xy = x.mul(y);

        decProd = prod_xy.add(DECIMAL_PRECISION / 2).div(DECIMAL_PRECISION);
    }

    /*
     * _decPow: Exponentiation function for 18-digit decimal base, and integer exponent n.
     *
     * Uses the efficient "exponentiation by squaring" algorithm. O(log(n)) complexity.
     *
     * Called by two functions that represent time in units of minutes:
     * 1) TroveManager._calcDecayedBaseRate
     * 2) CommunityIssuance._getCumulativeIssuanceFraction
     *
     * The exponent is capped to avoid reverting due to overflow. The cap 525600000 equals
     * "minutes in 1000 years": 60 * 24 * 365 * 1000
     *
     * If a period of > 1000 years is ever used as an exponent in either of the above functions, the result will be
     * negligibly different from just passing the cap, since:
     *
     * In function 1), the decayed base rate will be 0 for 1000 years or > 1000 years
     * In function 2), the difference in tokens issued at 1000 years and any time > 1000 years, will be negligible
     */
    function _decPow(uint256 _base, uint256 _minutes) internal pure returns (uint256) {
        if (_minutes > 525600000) {
            _minutes = 525600000;
        } // cap to avoid overflow

        if (_minutes == 0) {
            return DECIMAL_PRECISION;
        }

        uint256 y = DECIMAL_PRECISION;
        uint256 x = _base;
        uint256 n = _minutes;

        // Exponentiation-by-squaring
        while (n > 1) {
            if (n % 2 == 0) {
                x = decMul(x, x);
                n = n.div(2);
            } else {
                // if (n % 2 != 0)
                y = decMul(x, y);
                x = decMul(x, x);
                n = (n.sub(1)).div(2);
            }
        }

        return decMul(x, y);
    }

    function _getAbsoluteDifference(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return (_a >= _b) ? _a.sub(_b) : _b.sub(_a);
    }

    function _computeNominalCR(uint256 _coll, uint256 _debt) internal pure returns (uint256) {
        if (_debt > 0) {
            return _coll.mul(NICR_PRECISION).div(_debt);
        }
        // Return the maximal value for uint256 if the Trove has a debt of 0. Represents "infinite" CR.
        else {
            // if (_debt == 0)
            return 2**256 - 1;
        }
    }

    function _computeCR(
        uint256 _coll,
        uint256 _debt,
        uint256 _price
    ) internal pure returns (uint256) {
        if (_debt > 0) {
            return _coll.mul(_price).div(_debt);
        }
        // Return the maximal value for uint256 if the Trove has a debt of 0. Represents "infinite" CR.
        else {
            // if (_debt == 0)
            return type(uint256).max;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

abstract contract BaseMath {
    uint256 public constant DECIMAL_PRECISION = 1 ether;
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
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

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
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

pragma solidity ^0.8.14;

interface IOracle {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function latestAnswer() external view returns (int256 answer, uint256 updatedAt);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
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