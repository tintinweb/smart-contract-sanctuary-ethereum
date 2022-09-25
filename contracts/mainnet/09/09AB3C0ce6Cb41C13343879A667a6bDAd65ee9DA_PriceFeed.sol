// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;
import "./Interfaces/IPriceFeed.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Dependencies/CheckContract.sol";
import "./Dependencies/BaseMath.sol";
import "./Dependencies/DfrancMath.sol";
import "./Dependencies/Initializable.sol";

contract PriceFeed is Ownable, CheckContract, BaseMath, Initializable, IPriceFeed {
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
	mapping(address => uint256) public lastGoodIndex;

	modifier isController() {
		require(msg.sender == owner() || msg.sender == adminContract, "Invalid Permission");
		_;
	}

	function setAddresses(address _adminContract) external initializer onlyOwner {
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

	function addOracle(
		address _token,
		address _chainlinkOracle,
		address _chainlinkIndexOracle
	) external override isController {
		AggregatorV3Interface priceOracle = AggregatorV3Interface(_chainlinkOracle);
		AggregatorV3Interface indexOracle = AggregatorV3Interface(_chainlinkIndexOracle);

		registeredOracles[_token] = RegisterOracle(priceOracle, indexOracle, true);

		(
			ChainlinkResponse memory chainlinkResponse,
			ChainlinkResponse memory prevChainlinkResponse,
			ChainlinkResponse memory chainlinkIndexResponse,
			ChainlinkResponse memory prevChainlinkIndexResponse
		) = _getChainlinkResponses(priceOracle, indexOracle);

		require(
			!_chainlinkIsBroken(chainlinkResponse, prevChainlinkResponse) &&
				!_chainlinkIsFrozen(chainlinkResponse),
			"PriceFeed: Chainlink must be working and current"
		);
		require(
			!_chainlinkIsBroken(chainlinkIndexResponse, prevChainlinkIndexResponse),
			"PriceFeed: Chainlink must be working and current"
		);

		_storeChainlinkPrice(_token, chainlinkResponse);
		_storeChainlinkIndex(_token, chainlinkIndexResponse);

		emit RegisteredNewOracle(_token, _chainlinkOracle, _chainlinkIndexOracle);
	}

	function getDirectPrice(address _asset) public view returns (uint256 _priceAssetInDCHF) {
		RegisterOracle memory oracle = registeredOracles[_asset];
		(
			ChainlinkResponse memory chainlinkResponse,
			,
			ChainlinkResponse memory chainlinkIndexResponse,

		) = _getChainlinkResponses(oracle.chainLinkOracle, oracle.chainLinkIndex);

		uint256 scaledChainlinkPrice = _scaleChainlinkPriceByDigits(
			uint256(chainlinkResponse.answer),
			chainlinkResponse.decimals
		);

		uint256 scaledChainlinkIndexPrice = _scaleChainlinkPriceByDigits(
			uint256(chainlinkIndexResponse.answer),
			chainlinkIndexResponse.decimals
		);

		_priceAssetInDCHF = scaledChainlinkPrice.mul(1 ether).div(scaledChainlinkIndexPrice);
	}

	function fetchPrice(address _token) external override returns (uint256) {
		RegisterOracle storage oracle = registeredOracles[_token];
		require(oracle.isRegistered, "Oracle is not registered!");

		(
			ChainlinkResponse memory chainlinkResponse,
			ChainlinkResponse memory prevChainlinkResponse,
			ChainlinkResponse memory chainlinkIndexResponse,
			ChainlinkResponse memory prevChainlinkIndexResponse
		) = _getChainlinkResponses(oracle.chainLinkOracle, oracle.chainLinkIndex);

		uint256 lastTokenGoodPrice = lastGoodPrice[_token];
		uint256 lastTokenGoodIndex = lastGoodIndex[_token];

		bool isChainlinkOracleBroken = _chainlinkIsBroken(
			chainlinkResponse,
			prevChainlinkResponse
		) || _chainlinkIsFrozen(chainlinkResponse);

		bool isChainlinkIndexBroken = _chainlinkIsBroken(
			chainlinkIndexResponse,
			prevChainlinkIndexResponse
		);

		if (status == Status.chainlinkWorking) {
			if (isChainlinkOracleBroken || isChainlinkIndexBroken) {
				if (!isChainlinkOracleBroken) {
					lastTokenGoodPrice = _storeChainlinkPrice(_token, chainlinkResponse);
				}

				if (!isChainlinkIndexBroken) {
					lastTokenGoodIndex = _storeChainlinkIndex(_token, chainlinkIndexResponse);
				}

				_changeStatus(Status.chainlinkUntrusted);
				return _getIndexedPrice(lastTokenGoodPrice, lastTokenGoodIndex);
			}

			// If Chainlink price has changed by > 50% between two consecutive rounds
			if (_chainlinkPriceChangeAboveMax(chainlinkResponse, prevChainlinkResponse)) {
				return _getIndexedPrice(lastTokenGoodPrice, lastTokenGoodIndex);
			}

			lastTokenGoodPrice = _storeChainlinkPrice(_token, chainlinkResponse);
			lastTokenGoodIndex = _storeChainlinkIndex(_token, chainlinkIndexResponse);

			return _getIndexedPrice(lastTokenGoodPrice, lastTokenGoodIndex);
		}

		if (status == Status.chainlinkUntrusted) {
			if (!isChainlinkOracleBroken && !isChainlinkIndexBroken) {
				_changeStatus(Status.chainlinkWorking);
			}

			if (!isChainlinkOracleBroken) {
				lastTokenGoodPrice = _storeChainlinkPrice(_token, chainlinkResponse);
			}

			if (!isChainlinkIndexBroken) {
				lastTokenGoodIndex = _storeChainlinkIndex(_token, chainlinkIndexResponse);
			}

			return _getIndexedPrice(lastTokenGoodPrice, lastTokenGoodIndex);
		}

		return _getIndexedPrice(lastTokenGoodPrice, lastTokenGoodIndex);
	}

	function _getIndexedPrice(uint256 _price, uint256 _index) internal pure returns (uint256) {
		return _price.mul(1 ether).div(_index);
	}

	function _getChainlinkResponses(
		AggregatorV3Interface _chainLinkOracle,
		AggregatorV3Interface _chainLinkIndexOracle
	)
		internal
		view
		returns (
			ChainlinkResponse memory currentChainlink,
			ChainlinkResponse memory prevChainLink,
			ChainlinkResponse memory currentChainlinkIndex,
			ChainlinkResponse memory prevChainLinkIndex
		)
	{
		currentChainlink = _getCurrentChainlinkResponse(_chainLinkOracle);
		prevChainLink = _getPrevChainlinkResponse(
			_chainLinkOracle,
			currentChainlink.roundId,
			currentChainlink.decimals
		);

		if (address(_chainLinkIndexOracle) != address(0)) {
			currentChainlinkIndex = _getCurrentChainlinkResponse(_chainLinkIndexOracle);
			prevChainLinkIndex = _getPrevChainlinkResponse(
				_chainLinkIndexOracle,
				currentChainlinkIndex.roundId,
				currentChainlinkIndex.decimals
			);
		} else {
			currentChainlinkIndex = ChainlinkResponse(1, 1 ether, block.timestamp, true, 18);

			prevChainLinkIndex = currentChainlinkIndex;
		}

		return (currentChainlink, prevChainLink, currentChainlinkIndex, prevChainLinkIndex);
	}

	function _chainlinkIsBroken(
		ChainlinkResponse memory _currentResponse,
		ChainlinkResponse memory _prevResponse
	) internal view returns (bool) {
		return _badChainlinkResponse(_currentResponse) || _badChainlinkResponse(_prevResponse);
	}

	function _badChainlinkResponse(ChainlinkResponse memory _response)
		internal
		view
		returns (bool)
	{
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

	function _chainlinkIsFrozen(ChainlinkResponse memory _response)
		internal
		view
		returns (bool)
	{
		return block.timestamp.sub(_response.timestamp) > TIMEOUT;
	}

	function _chainlinkPriceChangeAboveMax(
		ChainlinkResponse memory _currentResponse,
		ChainlinkResponse memory _prevResponse
	) internal pure returns (bool) {
		uint256 currentScaledPrice = _scaleChainlinkPriceByDigits(
			uint256(_currentResponse.answer),
			_currentResponse.decimals
		);
		uint256 prevScaledPrice = _scaleChainlinkPriceByDigits(
			uint256(_prevResponse.answer),
			_prevResponse.decimals
		);

		uint256 minPrice = DfrancMath._min(currentScaledPrice, prevScaledPrice);
		uint256 maxPrice = DfrancMath._max(currentScaledPrice, prevScaledPrice);

		/*
		 * Use the larger price as the denominator:
		 * - If price decreased, the percentage deviation is in relation to the the previous price.
		 * - If price increased, the percentage deviation is in relation to the current price.
		 */
		uint256 percentDeviation = maxPrice.sub(minPrice).mul(DECIMAL_PRECISION).div(maxPrice);

		// Return true if price has more than doubled, or more than halved.
		return percentDeviation > MAX_PRICE_DEVIATION_FROM_PREVIOUS_ROUND;
	}

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

	function _changeStatus(Status _status) internal {
		status = _status;
		emit PriceFeedStatusChanged(_status);
	}

	function _storeChainlinkIndex(
		address _token,
		ChainlinkResponse memory _chainlinkIndexResponse
	) internal returns (uint256) {
		uint256 scaledChainlinkIndex = _scaleChainlinkPriceByDigits(
			uint256(_chainlinkIndexResponse.answer),
			_chainlinkIndexResponse.decimals
		);

		_storeIndex(_token, scaledChainlinkIndex);
		return scaledChainlinkIndex;
	}

	function _storeChainlinkPrice(address _token, ChainlinkResponse memory _chainlinkResponse)
		internal
		returns (uint256)
	{
		uint256 scaledChainlinkPrice = _scaleChainlinkPriceByDigits(
			uint256(_chainlinkResponse.answer),
			_chainlinkResponse.decimals
		);

		_storePrice(_token, scaledChainlinkPrice);
		return scaledChainlinkPrice;
	}

	function _storePrice(address _token, uint256 _currentPrice) internal {
		lastGoodPrice[_token] = _currentPrice;
		emit LastGoodPriceUpdated(_token, _currentPrice);
	}

	function _storeIndex(address _token, uint256 _currentIndex) internal {
		lastGoodIndex[_token] = _currentIndex;
		emit LastGoodIndexUpdated(_token, _currentIndex);
	}

	// --- Oracle response wrapper functions ---

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

	function _getPrevChainlinkResponse(
		AggregatorV3Interface _priceAggregator,
		uint80 _currentRoundId,
		uint8 _currentDecimals
	) internal view returns (ChainlinkResponse memory prevChainlinkResponse) {
		if (_currentRoundId == 0) {
			return prevChainlinkResponse;
		}

		unchecked {
			try _priceAggregator.getRoundData(_currentRoundId - 1) returns (
				uint80 roundId,
				int256 answer,
				uint256, /* startedAt */
				uint256 timestamp,
				uint80 /* answeredInRound */
			) {
				prevChainlinkResponse.roundId = roundId;
				prevChainlinkResponse.answer = answer;
				prevChainlinkResponse.timestamp = timestamp;
				prevChainlinkResponse.decimals = _currentDecimals;
				prevChainlinkResponse.success = true;
				return prevChainlinkResponse;
			} catch {
				return prevChainlinkResponse;
			}
		}
	}
}

// SPDX-License-Identifier: MIT
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

pragma solidity ^0.8.14;

interface IPriceFeed {
	struct ChainlinkResponse {
		uint80 roundId;
		int256 answer;
		uint256 timestamp;
		bool success;
		uint8 decimals;
	}

	struct RegisterOracle {
		AggregatorV3Interface chainLinkOracle;
		AggregatorV3Interface chainLinkIndex;
		bool isRegistered;
	}

	enum Status {
		chainlinkWorking,
		chainlinkUntrusted
	}

	// --- Events ---
	event PriceFeedStatusChanged(Status newStatus);
	event LastGoodPriceUpdated(address indexed token, uint256 _lastGoodPrice);
	event LastGoodIndexUpdated(address indexed token, uint256 _lastGoodIndex);
	event RegisteredNewOracle(
		address token,
		address chainLinkAggregator,
		address chianLinkIndex
	);

	// --- Function ---
	function addOracle(
		address _token,
		address _chainlinkOracle,
		address _chainlinkIndexOracle
	) external;

	function fetchPrice(address _token) external returns (uint256);

	function getDirectPrice(address _asset) external returns (uint256);
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

abstract contract BaseMath {
	uint256 public constant DECIMAL_PRECISION = 1 ether;
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
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/utils/Address.sol";

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
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
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
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
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
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
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

// SPDX-License-Identifier: MIT

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