// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// import "../libraries/math/SafeMath.sol";

import { IChainlinkFlags, ISecondaryPriceFeed, IPriceFeed } from "../oracle/PriceFeed.sol";
// import "../oracle/interfaces/ISecondaryPriceFeed.sol";
// import "../oracle/interfaces/IChainlinkFlags.sol";
import { IPancakePair } from "../amm/PancakePair.sol";

interface IVaultPriceFeed {
    function adjustmentBasisPoints(address _token) external view returns (uint256);
    function isAdjustmentAdditive(address _token) external view returns (bool);
    function setAdjustment(address _token, bool _isAdditive, uint256 _adjustmentBps) external;
    function setUseV2Pricing(bool _useV2Pricing) external;
    function setIsAmmEnabled(bool _isEnabled) external;
    function setIsSecondaryPriceEnabled(bool _isEnabled) external;
    function setSpreadBasisPoints(address _token, uint256 _spreadBasisPoints) external;
    function setSpreadThresholdBasisPoints(uint256 _spreadThresholdBasisPoints) external;
    function setFavorPrimaryPrice(bool _favorPrimaryPrice) external;
    function setPriceSampleSpace(uint256 _priceSampleSpace) external;
    function setMaxStrictPriceDeviation(uint256 _maxStrictPriceDeviation) external;
    function getPrice(address _token, bool _maximise, bool _includeAmmPrice, bool _useSwapPricing) external view returns (uint256);
    function getAmmPrice(address _token) external view returns (uint256);
    function getLatestPrimaryPrice(address _token) external view returns (uint256);
    function getPrimaryPrice(address _token, bool _maximise) external view returns (uint256);
    function setTokenConfig(
        address _token,
        address _priceFeed,
        uint256 _priceDecimals,
        bool _isStrictStable
    ) external;
}

contract VaultPriceFeed is IVaultPriceFeed {
    // using SafeMath for uint256;

    uint256 public constant PRICE_PRECISION = 10 ** 30;
    uint256 public constant ONE_USD = PRICE_PRECISION;
    uint256 public constant BASIS_POINTS_DIVISOR = 10000;
    uint256 public constant MAX_SPREAD_BASIS_POINTS = 50;
    uint256 public constant MAX_ADJUSTMENT_INTERVAL = 2 hours;
    uint256 public constant MAX_ADJUSTMENT_BASIS_POINTS = 20;

    // Identifier of the Sequencer offline flag on the Flags contract
    address constant private FLAG_ARBITRUM_SEQ_OFFLINE = address(bytes20(bytes32(uint256(keccak256("chainlink.flags.arbitrum-seq-offline")) - 1)));

    address public gov;
    address public chainlinkFlags;

    bool public isAmmEnabled = true;
    bool public isSecondaryPriceEnabled = true;
    bool public useV2Pricing = false;
    bool public favorPrimaryPrice = false;
    uint256 public priceSampleSpace = 3;
    uint256 public maxStrictPriceDeviation = 0;
    address public secondaryPriceFeed;
    uint256 public spreadThresholdBasisPoints = 30;

    address public btc;
    address public eth;
    address public bnb;
    address public bnbBusd;
    address public ethBnb;
    address public btcBnb;

    mapping (address => address) public priceFeeds;
    mapping (address => uint256) public priceDecimals;
    mapping (address => uint256) public spreadBasisPoints;
    // Chainlink can return prices for stablecoins
    // that differs from 1 USD by a larger percentage than stableSwapFeeBasisPoints
    // we use strictStableTokens to cap the price to 1 USD
    // this allows us to configure stablecoins like DAI as being a stableToken
    // while not being a strictStableToken
    mapping (address => bool) public strictStableTokens;

    mapping (address => uint256) public override adjustmentBasisPoints;
    mapping (address => bool) public override isAdjustmentAdditive;
    mapping (address => uint256) public lastAdjustmentTimings;

    modifier onlyGov() {
        require(msg.sender == gov, "VaultPriceFeed: forbidden");
        _;
    }

    constructor() {
        gov = msg.sender;
    }

    function setGov(address _gov) external onlyGov {
        gov = _gov;
    }

    function setChainlinkFlags(address _chainlinkFlags) external onlyGov {
        chainlinkFlags = _chainlinkFlags;
    }

    function setAdjustment(address _token, bool _isAdditive, uint256 _adjustmentBps) external override onlyGov {
        require(
            lastAdjustmentTimings[_token]+(MAX_ADJUSTMENT_INTERVAL) < block.timestamp,
            "VaultPriceFeed: adjustment frequency exceeded"
        );
        require(_adjustmentBps <= MAX_ADJUSTMENT_BASIS_POINTS, "invalid _adjustmentBps");
        isAdjustmentAdditive[_token] = _isAdditive;
        adjustmentBasisPoints[_token] = _adjustmentBps;
        lastAdjustmentTimings[_token] = block.timestamp;
    }

    function setUseV2Pricing(bool _useV2Pricing) external override onlyGov {
        useV2Pricing = _useV2Pricing;
    }

    function setIsAmmEnabled(bool _isEnabled) external override onlyGov {
        isAmmEnabled = _isEnabled;
    }

    function setIsSecondaryPriceEnabled(bool _isEnabled) external override onlyGov {
        isSecondaryPriceEnabled = _isEnabled;
    }

    function setSecondaryPriceFeed(address _secondaryPriceFeed) external onlyGov {
        secondaryPriceFeed = _secondaryPriceFeed;
    }

    function setTokens(address _btc, address _eth, address _bnb) external onlyGov {
        btc = _btc;
        eth = _eth;
        bnb = _bnb;
    }

    function setPairs(address _bnbBusd, address _ethBnb, address _btcBnb) external onlyGov {
        bnbBusd = _bnbBusd;
        ethBnb = _ethBnb;
        btcBnb = _btcBnb;
    }

    function setSpreadBasisPoints(address _token, uint256 _spreadBasisPoints) external override onlyGov {
        require(_spreadBasisPoints <= MAX_SPREAD_BASIS_POINTS, "VaultPriceFeed: invalid _spreadBasisPoints");
        spreadBasisPoints[_token] = _spreadBasisPoints;
    }

    function setSpreadThresholdBasisPoints(uint256 _spreadThresholdBasisPoints) external override onlyGov {
        spreadThresholdBasisPoints = _spreadThresholdBasisPoints;
    }

    function setFavorPrimaryPrice(bool _favorPrimaryPrice) external override onlyGov {
        favorPrimaryPrice = _favorPrimaryPrice;
    }

    function setPriceSampleSpace(uint256 _priceSampleSpace) external override onlyGov {
        require(_priceSampleSpace > 0, "VaultPriceFeed: invalid _priceSampleSpace");
        priceSampleSpace = _priceSampleSpace;
    }

    function setMaxStrictPriceDeviation(uint256 _maxStrictPriceDeviation) external override onlyGov {
        maxStrictPriceDeviation = _maxStrictPriceDeviation;
    }

    function setTokenConfig(
        address _token,
        address _priceFeed,
        uint256 _priceDecimals,
        bool _isStrictStable
    ) external override onlyGov {
        priceFeeds[_token] = _priceFeed;
        priceDecimals[_token] = _priceDecimals;
        strictStableTokens[_token] = _isStrictStable;
    }

    function getPrice(address _token, bool _maximise, bool _includeAmmPrice, bool /* _useSwapPricing */) public override view returns (uint256) {
        uint256 price = useV2Pricing ? getPriceV2(_token, _maximise, _includeAmmPrice) : getPriceV1(_token, _maximise, _includeAmmPrice);

        uint256 adjustmentBps = adjustmentBasisPoints[_token];
        if (adjustmentBps > 0) {
            bool isAdditive = isAdjustmentAdditive[_token];
            if (isAdditive) {
                price = (price*(BASIS_POINTS_DIVISOR+(adjustmentBps)))/(BASIS_POINTS_DIVISOR);
            } else {
                price = (price*(BASIS_POINTS_DIVISOR-(adjustmentBps)))/(BASIS_POINTS_DIVISOR);
            }
        }

        return price;
    }

    function getPriceV1(address _token, bool _maximise, bool _includeAmmPrice) public view returns (uint256) {
        uint256 price = getPrimaryPrice(_token, _maximise);

        if (_includeAmmPrice && isAmmEnabled) {
            uint256 ammPrice = getAmmPrice(_token);
            if (ammPrice > 0) {
                if (_maximise && ammPrice > price) {
                    price = ammPrice;
                }
                if (!_maximise && ammPrice < price) {
                    price = ammPrice;
                }
            }
        }

        if (isSecondaryPriceEnabled) {
            price = getSecondaryPrice(_token, price, _maximise);
        }

        if (strictStableTokens[_token]) {
            uint256 delta = price > ONE_USD ? price-(ONE_USD) : ONE_USD-(price);
            if (delta <= maxStrictPriceDeviation) {
                return ONE_USD;
            }

            // if _maximise and price is e.g. 1.02, return 1.02
            if (_maximise && price > ONE_USD) {
                return price;
            }

            // if !_maximise and price is e.g. 0.98, return 0.98
            if (!_maximise && price < ONE_USD) {
                return price;
            }

            return ONE_USD;
        }

        uint256 _spreadBasisPoints = spreadBasisPoints[_token];

        if (_maximise) {
            return (price*(BASIS_POINTS_DIVISOR+(_spreadBasisPoints)))/(BASIS_POINTS_DIVISOR);
        }

        return (price*(BASIS_POINTS_DIVISOR-(_spreadBasisPoints)))/(BASIS_POINTS_DIVISOR);
    }

    function getPriceV2(address _token, bool _maximise, bool _includeAmmPrice) public view returns (uint256) {
        uint256 price = getPrimaryPrice(_token, _maximise);

        if (_includeAmmPrice && isAmmEnabled) {
            price = getAmmPriceV2(_token, _maximise, price);
        }

        if (isSecondaryPriceEnabled) {
            price = getSecondaryPrice(_token, price, _maximise);
        }

        if (strictStableTokens[_token]) {
            uint256 delta = price > ONE_USD ? price-(ONE_USD) : ONE_USD-(price);
            if (delta <= maxStrictPriceDeviation) {
                return ONE_USD;
            }

            // if _maximise and price is e.g. 1.02, return 1.02
            if (_maximise && price > ONE_USD) {
                return price;
            }

            // if !_maximise and price is e.g. 0.98, return 0.98
            if (!_maximise && price < ONE_USD) {
                return price;
            }

            return ONE_USD;
        }

        uint256 _spreadBasisPoints = spreadBasisPoints[_token];

        if (_maximise) {
            return (price*(BASIS_POINTS_DIVISOR+(_spreadBasisPoints)))/(BASIS_POINTS_DIVISOR);
        }

        return (price*(BASIS_POINTS_DIVISOR-(_spreadBasisPoints)))/(BASIS_POINTS_DIVISOR);
    }

    function getAmmPriceV2(address _token, bool _maximise, uint256 _primaryPrice) public view returns (uint256) {
        uint256 ammPrice = getAmmPrice(_token);
        if (ammPrice == 0) {
            return _primaryPrice;
        }

        uint256 diff = ammPrice > _primaryPrice ? ammPrice-(_primaryPrice) : _primaryPrice-(ammPrice);
        if (diff*(BASIS_POINTS_DIVISOR) < _primaryPrice*(spreadThresholdBasisPoints)) {
            if (favorPrimaryPrice) {
                return _primaryPrice;
            }
            return ammPrice;
        }

        if (_maximise && ammPrice > _primaryPrice) {
            return ammPrice;
        }

        if (!_maximise && ammPrice < _primaryPrice) {
            return ammPrice;
        }

        return _primaryPrice;
    }

    function getLatestPrimaryPrice(address _token) public override view returns (uint256) {
        address priceFeedAddress = priceFeeds[_token];
        require(priceFeedAddress != address(0), "VaultPriceFeed: invalid price feed");

        IPriceFeed priceFeed = IPriceFeed(priceFeedAddress);

        int256 price = priceFeed.latestAnswer();
        require(price > 0, "VaultPriceFeed: invalid price");

        return uint256(price);
    }

    function getPrimaryPrice(address _token, bool _maximise) public override view returns (uint256) {
        address priceFeedAddress = priceFeeds[_token];
        require(priceFeedAddress != address(0), "VaultPriceFeed: invalid price feed");

        if (chainlinkFlags != address(0)) {
            bool isRaised = IChainlinkFlags(chainlinkFlags).getFlag(FLAG_ARBITRUM_SEQ_OFFLINE);
            if (isRaised) {
                    // If flag is raised we shouldn't perform any critical operations
                revert("Chainlink feeds are not being updated");
            }
        }

        IPriceFeed priceFeed = IPriceFeed(priceFeedAddress);

        uint256 price = 0;
        uint80 roundId = priceFeed.latestRound();

        for (uint80 i = 0; i < priceSampleSpace; i++) {
            if (roundId <= i) { break; }
            uint256 p;

            if (i == 0) {
                int256 _p = priceFeed.latestAnswer();
                require(_p > 0, "VaultPriceFeed: invalid price");
                p = uint256(_p);
            } else {
                (, int256 _p, , ,) = priceFeed.getRoundData(roundId - i);
                require(_p > 0, "VaultPriceFeed: invalid price");
                p = uint256(_p);
            }

            if (price == 0) {
                price = p;
                continue;
            }

            if (_maximise && p > price) {
                price = p;
                continue;
            }

            if (!_maximise && p < price) {
                price = p;
            }
        }

        require(price > 0, "VaultPriceFeed: could not fetch price");
        // normalise price precision
        uint256 _priceDecimals = priceDecimals[_token];
        return (price*(PRICE_PRECISION))/(10 ** _priceDecimals);
    }

    function getSecondaryPrice(address _token, uint256 _referencePrice, bool _maximise) public view returns (uint256) {
        if (secondaryPriceFeed == address(0)) { return _referencePrice; }
        return ISecondaryPriceFeed(secondaryPriceFeed).getPrice(_token, _referencePrice, _maximise);
    }

    function getAmmPrice(address _token) public override view returns (uint256) {
        if (_token == bnb) {
            // for bnbBusd, reserve0: BNB, reserve1: BUSD
            return getPairPrice(bnbBusd, true);
        }

        if (_token == eth) {
            uint256 price0 = getPairPrice(bnbBusd, true);
            // for ethBnb, reserve0: ETH, reserve1: BNB
            uint256 price1 = getPairPrice(ethBnb, true);
            // this calculation could overflow if (price0 / 10**30) * (price1 / 10**30) is more than 10**17
            return (price0*(price1))/(PRICE_PRECISION);
        }

        if (_token == btc) {
            uint256 price0 = getPairPrice(bnbBusd, true);
            // for btcBnb, reserve0: BTC, reserve1: BNB
            uint256 price1 = getPairPrice(btcBnb, true);
            // this calculation could overflow if (price0 / 10**30) * (price1 / 10**30) is more than 10**17
            return (price0*(price1))/(PRICE_PRECISION);
        }

        return 0;
    }

    // if divByReserve0: calculate price as reserve1 / reserve0
    // if !divByReserve1: calculate price as reserve0 / reserve1
    function getPairPrice(address _pair, bool _divByReserve0) public view returns (uint256) {
        (uint256 reserve0, uint256 reserve1, ) = IPancakePair(_pair).getReserves();
        if (_divByReserve0) {
            if (reserve0 == 0) { return 0; }
            return (reserve1*(PRICE_PRECISION))/(reserve0);
        }
        if (reserve1 == 0) { return 0; }
        return (reserve0*(PRICE_PRECISION))/(reserve1);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IPancakePair
{
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

contract PancakePair is IPancakePair
{
    uint112 private reserve0;           // uses single storage slot, accessible via getReserves
    uint112 private reserve1;           // uses single storage slot, accessible via getReserves
    uint32  private blockTimestampLast; // uses single storage slot, accessible via getReserves

    function setReserves(uint256 balance0, uint256 balance1) external {
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = uint32(block.timestamp);
    }

    function getReserves() public override view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IPriceFeed {
    function description() external view returns (string memory);
    function aggregator() external view returns (address);
    function latestAnswer() external view returns (int256);
    function latestRound() external view returns (uint80);
    function getRoundData(uint80 roundId) external view returns (uint80, int256, uint256, uint256, uint80);
}

interface ISecondaryPriceFeed {
    function getPrice(address _token, uint256 _referencePrice, bool _maximise) external view returns (uint256);
}

interface IChainlinkFlags {
  function getFlag(address) external view returns (bool);
}


contract PriceFeed is IPriceFeed {
    int256 public answer;
    uint80 public roundId;
    string public override description = "PriceFeed";
    address public override aggregator;

    uint256 public decimals;

    address public gov;

    mapping (uint80 => int256) public answers;
    mapping (address => bool) public isAdmin;

    constructor() {
        gov = msg.sender;
        isAdmin[msg.sender] = true;
    }

    function setAdmin(address _account, bool _isAdmin) public {
        require(msg.sender == gov, "PriceFeed: forbidden");
        isAdmin[_account] = _isAdmin;
    }

    function latestAnswer() public override view returns (int256) {
        return answer;
    }

    function latestRound() public override view returns (uint80) {
        return roundId;
    }

    function setLatestAnswer(int256 _answer) public {
        require(isAdmin[msg.sender], "PriceFeed: forbidden");
        roundId = roundId + 1;
        answer = _answer;
        answers[roundId] = _answer;
    }

    // returns roundId, answer, startedAt, updatedAt, answeredInRound
    function getRoundData(uint80 _roundId) public override view
        returns (uint80, int256, uint256, uint256, uint80)
    {
        return (_roundId, answers[_roundId], 0, 0, 0);
    }
}