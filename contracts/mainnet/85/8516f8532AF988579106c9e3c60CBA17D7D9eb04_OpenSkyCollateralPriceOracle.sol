// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import '@openzeppelin/contracts/access/Ownable.sol';
import './interfaces/IOpenSkyCollateralPriceOracle.sol';
import './interfaces/IOpenSkySettings.sol';
import './libraries/helpers/Errors.sol';
import './interfaces/IOpenSkyPriceAggregator.sol';

/**
 * @title OpenSkyCollateralPriceOracle contract
 * @author OpenSky Labs
 * @dev Implements logics of the collateral price oracle for the OpenSky protocol
 **/
contract OpenSkyCollateralPriceOracle is Ownable, IOpenSkyCollateralPriceOracle {
    IOpenSkySettings public immutable SETTINGS;

    mapping(address => NFTPriceData[]) public nftPriceFeedMap;

    IOpenSkyPriceAggregator private _priceAggregator;

    uint256 internal _roundInterval;
    uint256 internal _timeInterval;

    struct NFTPriceData {
        uint256 roundId;
        uint256 price;
        uint256 timestamp;
        uint256 cumulativePrice;
    }

    constructor(IOpenSkySettings settings, IOpenSkyPriceAggregator priceAggregator) Ownable() {
        SETTINGS = settings;
        _priceAggregator = priceAggregator;
    }

    function setPriceAggregator(address priceAggregator) external onlyOwner {
        _priceAggregator = IOpenSkyPriceAggregator(priceAggregator);
        emit SetPriceAggregator(_msgSender(), priceAggregator);
    }

    /// @inheritdoc IOpenSkyCollateralPriceOracle
    function updatePrice(
        address nftAddress,
        uint256 price,
        uint256 timestamp
    ) public override onlyOwner {
        NFTPriceData[] storage prices = nftPriceFeedMap[nftAddress];
        NFTPriceData memory latestPriceData = prices.length > 0
            ? prices[prices.length - 1]
            : NFTPriceData({roundId: 0, price: 0, timestamp: 0, cumulativePrice: 0});
        require(timestamp > latestPriceData.timestamp, Errors.PRICE_ORACLE_INCORRECT_TIMESTAMP);
        uint256 cumulativePrice = latestPriceData.timestamp > 0
            ? latestPriceData.cumulativePrice + (timestamp - latestPriceData.timestamp) * latestPriceData.price
            : 0;
        uint256 roundId = latestPriceData.roundId + 1;
        NFTPriceData memory data = NFTPriceData({
            price: price,
            timestamp: timestamp,
            roundId: roundId,
            cumulativePrice: cumulativePrice
        });
        prices.push(data);

        emit UpdatePrice(nftAddress, price, timestamp, roundId);
    }

    /**
     * @notice Updates floor prices of NFT collections
     * @param nftAddresses Addresses of NFT collections
     * @param prices Floor prices of NFT collections
     * @param timestamp The timestamp when prices happened
     **/
    function updatePrices(
        address[] memory nftAddresses,
        uint256[] memory prices,
        uint256 timestamp
    ) external onlyOwner {
        require(nftAddresses.length == prices.length, Errors.PRICE_ORACLE_PARAMS_ERROR);
        for (uint256 i = 0; i < nftAddresses.length; i++) {
            updatePrice(nftAddresses[i], prices[i], timestamp);
        }
    }

    /// @inheritdoc IOpenSkyCollateralPriceOracle
    function setRoundInterval(uint256 roundInterval) external override onlyOwner {
        _roundInterval = roundInterval;
        emit SetRoundInterval(_msgSender(), roundInterval);
    }

    /// @inheritdoc IOpenSkyCollateralPriceOracle
    function setTimeInterval(uint256 timeInterval) external override onlyOwner {
        _timeInterval = timeInterval;
        emit SetTimeInterval(_msgSender(), timeInterval);
    }

    /// @inheritdoc IOpenSkyCollateralPriceOracle
    function getPrice(
        uint256 reserveId,
        address nftAddress,
        uint256 tokenId
    ) external view override returns (uint256) {
        if (!SETTINGS.inWhitelist(reserveId, nftAddress)) {
            return 0;
        }
        if (address(_priceAggregator) == address(0)) {
            return _getPrice(nftAddress);
        } else {
            uint256 price = _priceAggregator.getAssetPrice(nftAddress);
            return price > 0 ? price : _getPrice(nftAddress);
        }
    }

    function _getPrice(address nftAddress) internal view returns (uint256) {
        if (_timeInterval > 0) {
            return getTwapPriceByTimeInterval(nftAddress, _timeInterval);
        } else {
            return getTwapPriceByRoundInterval(nftAddress, _roundInterval);
        }
    }

    /**
     * @notice Returns the TWAP price of NFT during the particular round interval
     * @param nftAddress The address of the NFT
     * @param roundInterval The round interval
     * @return The price of the NFT
     **/
    function getTwapPriceByRoundInterval(address nftAddress, uint256 roundInterval) public view returns (uint256) {
        uint256 priceFeedLength = getPriceFeedLength(nftAddress);
        if (priceFeedLength == 0) {
            return 0;
        }
        uint256 currentRound = priceFeedLength - 1;
        NFTPriceData memory currentPriceData = nftPriceFeedMap[nftAddress][currentRound];
        if (roundInterval == 0 || priceFeedLength == 1) {
            return currentPriceData.price;
        }
        uint256 previousRound = currentRound > roundInterval ? currentRound - roundInterval : 0;
        NFTPriceData memory previousPriceData = nftPriceFeedMap[nftAddress][previousRound];
        return
            (currentPriceData.price *
                (block.timestamp - currentPriceData.timestamp) +
                currentPriceData.cumulativePrice -
                previousPriceData.cumulativePrice) / (block.timestamp - previousPriceData.timestamp);
    }

    /**
     * @notice Returns the TWAP price of NFT during the particular time interval
     * @param nftAddress The address of the NFT
     * @param timeInterval The time interval
     * @return The price of the NFT
     **/
    function getTwapPriceByTimeInterval(address nftAddress, uint256 timeInterval) public view returns (uint256) {
        uint256 priceFeedLength = getPriceFeedLength(nftAddress);
        if (priceFeedLength == 0) {
            return 0;
        }

        NFTPriceData memory currentPriceData = nftPriceFeedMap[nftAddress][priceFeedLength - 1];
        uint256 baseTimestamp = block.timestamp - timeInterval;

        if (currentPriceData.timestamp <= baseTimestamp) {
            return currentPriceData.price;
        }

        NFTPriceData memory firstPriceData = nftPriceFeedMap[nftAddress][0];
        if (firstPriceData.timestamp >= baseTimestamp) {
            return
                (currentPriceData.price *
                    (block.timestamp - currentPriceData.timestamp) +
                    (currentPriceData.cumulativePrice - firstPriceData.cumulativePrice)) /
                (block.timestamp - firstPriceData.timestamp);
        }

        uint256 roundIndex = priceFeedLength - 1;
        NFTPriceData storage basePriceData = nftPriceFeedMap[nftAddress][roundIndex];

        while (roundIndex > 0 && basePriceData.timestamp > baseTimestamp) {
            basePriceData = nftPriceFeedMap[nftAddress][--roundIndex];
        }

        uint256 cumulativePrice = currentPriceData.price *
            (block.timestamp - currentPriceData.timestamp) +
            (currentPriceData.cumulativePrice - basePriceData.cumulativePrice);
        cumulativePrice -= basePriceData.price * (baseTimestamp - basePriceData.timestamp);
        return cumulativePrice / timeInterval;
    }

    /**
     * @notice Returns the data of the particular price feed
     * @param nftAddress The address of the NFT
     * @param index The index of the feed
     * @return The data of the price feed
     **/
    function getPriceData(address nftAddress, uint256 index) external view returns (NFTPriceData memory) {
        return nftPriceFeedMap[nftAddress][index];
    }

    /**
     * @notice Returns the count of price feeds about the particular NFT
     * @param nftAddress The address of the NFT
     * @return length The count of price feeds
     **/
    function getPriceFeedLength(address nftAddress) public view returns (uint256 length) {
        return nftPriceFeedMap[nftAddress].length;
    }

    /**
     * @notice Returns the latest round id of the particular NFT
     * @param nftAddress The address of the NFT
     * @return The latest round id
     **/
    function getLatestRoundId(address nftAddress) external view returns (uint256) {
        uint256 len = getPriceFeedLength(nftAddress);
        if (len == 0) {
            return 0;
        }
        return nftPriceFeedMap[nftAddress][len - 1].roundId;
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
pragma solidity 0.8.10;

/**
 * @title IOpenSkyPriceOracle
 * @author OpenSky Labs
 * @notice Defines the basic interface for a price oracle.
 **/
interface IOpenSkyCollateralPriceOracle {
    /**
     * @dev Emitted on setPriceAggregator()
     * @param operator The address of the operator
     * @param priceAggregator The new price aggregator address
     **/
    event SetPriceAggregator(address indexed operator, address priceAggregator);

    /**
     * @dev Emitted on setRoundInterval()
     * @param operator The address of the operator
     * @param roundInterval The round interval
     **/
    event SetRoundInterval(address indexed operator, uint256 roundInterval);

    /**
     * @dev Emitted on setTimeInterval()
     * @param operator The address of the operator
     * @param timeInterval The time interval
     **/
    event SetTimeInterval(address indexed operator, uint256 timeInterval);

    /**
     * @dev Emitted on updatePrice()
     * @param nftAddress The address of the NFT
     * @param price The price of the NFT
     * @param timestamp The timestamp when the price happened
     * @param roundId The round id
     **/
    event UpdatePrice(address indexed nftAddress, uint256 price, uint256 timestamp, uint256 roundId);

    /**
     * @notice Sets round interval that is used for calculating TWAP price
     * @param roundInterval The round interval will be set
     **/
    function setRoundInterval(uint256 roundInterval) external;

    /**
     * @notice Sets time interval that is used for calculating TWAP price
     * @param timeInterval The time interval will be set
     **/
    function setTimeInterval(uint256 timeInterval) external;

    /**
     * @notice Returns the NFT price in ETH
     * @param reserveId The id of the reserve
     * @param nftAddress The address of the NFT
     * @param tokenId The id of the NFT
     * @return The price of the NFT
     **/
    function getPrice(
        uint256 reserveId,
        address nftAddress,
        uint256 tokenId
    ) external view returns (uint256);

    /**
     * @notice Updates the floor price of the NFT collection
     * @param nftAddress The address of the NFT
     * @param price The price of the NFT
     * @param timestamp The timestamp when the price happened
     **/
    function updatePrice(
        address nftAddress,
        uint256 price,
        uint256 timestamp
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
import '../libraries/types/DataTypes.sol';

interface IOpenSkySettings {
    event InitPoolAddress(address operator, address address_);
    event InitLoanAddress(address operator, address address_);
    event InitVaultFactoryAddress(address operator, address address_);
    event InitIncentiveControllerAddress(address operator, address address_);
    event InitWETHGatewayAddress(address operator, address address_);
    event InitPunkGatewayAddress(address operator, address address_);
    event InitDaoVaultAddress(address operator, address address_);

    event AddToWhitelist(address operator, uint256 reserveId, address nft);
    event RemoveFromWhitelist(address operator, uint256 reserveId, address nft);
    event SetReserveFactor(address operator, uint256 factor);
    event SetPrepaymentFeeFactor(address operator, uint256 factor);
    event SetOverdueLoanFeeFactor(address operator, uint256 factor);
    event SetMoneyMarketAddress(address operator, address address_);
    event SetTreasuryAddress(address operator, address address_);
    event SetACLManagerAddress(address operator, address address_);
    event SetLoanDescriptorAddress(address operator, address address_);
    event SetNftPriceOracleAddress(address operator, address address_);
    event SetInterestRateStrategyAddress(address operator, address address_);
    event AddLiquidator(address operator, address address_);
    event RemoveLiquidator(address operator, address address_);

    function poolAddress() external view returns (address);

    function loanAddress() external view returns (address);

    function vaultFactoryAddress() external view returns (address);

    function incentiveControllerAddress() external view returns (address);

    function wethGatewayAddress() external view returns (address);

    function punkGatewayAddress() external view returns (address);

    function inWhitelist(uint256 reserveId, address nft) external view returns (bool);

    function getWhitelistDetail(uint256 reserveId, address nft) external view returns (DataTypes.WhitelistInfo memory);

    function reserveFactor() external view returns (uint256); // treasury ratio

    function MAX_RESERVE_FACTOR() external view returns (uint256);

    function prepaymentFeeFactor() external view returns (uint256);

    function overdueLoanFeeFactor() external view returns (uint256);

    function moneyMarketAddress() external view returns (address);

    function treasuryAddress() external view returns (address);

    function daoVaultAddress() external view returns (address);

    function ACLManagerAddress() external view returns (address);

    function loanDescriptorAddress() external view returns (address);

    function nftPriceOracleAddress() external view returns (address);

    function interestRateStrategyAddress() external view returns (address);
    
    function isLiquidator(address liquidator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

library Errors {
    // common
    string public constant MATH_MULTIPLICATION_OVERFLOW = '100';
    string public constant MATH_ADDITION_OVERFLOW = '101';
    string public constant MATH_DIVISION_BY_ZERO = '102';

    string public constant ETH_TRANSFER_FAILED = '110';
    string public constant RECEIVE_NOT_ALLOWED = '111';
    string public constant FALLBACK_NOT_ALLOWED = '112';
    string public constant APPROVAL_FAILED = '113';

    // setting/factor
    string public constant SETTING_ZERO_ADDRESS_NOT_ALLOWED = '115';
    string public constant SETTING_RESERVE_FACTOR_NOT_ALLOWED = '116';
    string public constant SETTING_WHITELIST_INVALID_RESERVE_ID = '117';
    string public constant SETTING_WHITELIST_NFT_ADDRESS_IS_ZERO = '118';
    string public constant SETTING_WHITELIST_NFT_DURATION_OUT_OF_ORDER = '119';
    string public constant SETTING_WHITELIST_NFT_NAME_EMPTY = '120';
    string public constant SETTING_WHITELIST_NFT_SYMBOL_EMPTY = '121';
    string public constant SETTING_WHITELIST_NFT_LTV_NOT_ALLOWED = '122';

    // settings/acl
    string public constant ACL_ONLY_GOVERNANCE_CAN_CALL = '200';
    string public constant ACL_ONLY_EMERGENCY_ADMIN_CAN_CALL = '201';
    string public constant ACL_ONLY_POOL_ADMIN_CAN_CALL = '202';
    string public constant ACL_ONLY_LIQUIDATOR_CAN_CALL = '203';
    string public constant ACL_ONLY_AIRDROP_OPERATOR_CAN_CALL = '204';
    string public constant ACL_ONLY_POOL_CAN_CALL = '205';

    // lending & borrowing
    // reserve
    string public constant RESERVE_DOES_NOT_EXIST = '300';
    string public constant RESERVE_LIQUIDITY_INSUFFICIENT = '301';
    string public constant RESERVE_INDEX_OVERFLOW = '302';
    string public constant RESERVE_SWITCH_MONEY_MARKET_STATE_ERROR = '303';
    string public constant RESERVE_TREASURY_FACTOR_NOT_ALLOWED = '304';
    string public constant RESERVE_TOKEN_CAN_NOT_BE_CLAIMED = '305';

    // token
    string public constant AMOUNT_SCALED_IS_ZERO = '310';
    string public constant AMOUNT_TRANSFER_OVERFLOW = '311';

    //deposit
    string public constant DEPOSIT_AMOUNT_SHOULD_BE_BIGGER_THAN_ZERO = '320';

    // withdraw
    string public constant WITHDRAW_AMOUNT_NOT_ALLOWED = '321';
    string public constant WITHDRAW_LIQUIDITY_NOT_SUFFICIENT = '322';

    // borrow
    string public constant BORROW_DURATION_NOT_ALLOWED = '330';
    string public constant BORROW_AMOUNT_EXCEED_BORROW_LIMIT = '331';
    string public constant NFT_ADDRESS_IS_NOT_IN_WHITELIST = '332';

    // repay
    string public constant REPAY_STATUS_ERROR = '333';
    string public constant REPAY_MSG_VALUE_ERROR = '334';

    // extend
    string public constant EXTEND_STATUS_ERROR = '335';
    string public constant EXTEND_MSG_VALUE_ERROR = '336';

    // liquidate
    string public constant START_LIQUIDATION_STATUS_ERROR = '360';
    string public constant END_LIQUIDATION_STATUS_ERROR = '361';
    string public constant END_LIQUIDATION_AMOUNT_ERROR = '362';

    // loan
    string public constant LOAN_DOES_NOT_EXIST = '400';
    string public constant LOAN_SET_STATUS_ERROR = '401';
    string public constant LOAN_REPAYER_IS_NOT_OWNER = '402';
    string public constant LOAN_LIQUIDATING_STATUS_CAN_NOT_BE_UPDATED = '403';
    string public constant LOAN_CALLER_IS_NOT_OWNER = '404';
    string public constant LOAN_COLLATERAL_NFT_CAN_NOT_BE_CLAIMED = '405';

    string public constant FLASHCLAIM_EXECUTOR_ERROR = '410';
    string public constant FLASHCLAIM_STATUS_ERROR = '411';

    // money market
    string public constant MONEY_MARKET_DEPOSIT_AMOUNT_NOT_ALLOWED = '500';
    string public constant MONEY_MARKET_WITHDRAW_AMOUNT_NOT_ALLOWED = '501';
    string public constant MONEY_MARKET_APPROVAL_FAILED = '502';
    string public constant MONEY_MARKET_DELEGATE_CALL_ERROR = '503';
    string public constant MONEY_MARKET_REQUIRE_DELEGATE_CALL = '504';
    string public constant MONEY_MARKET_WITHDRAW_AMOUNT_NOT_MATCH = '505';

    // price oracle
    string public constant PRICE_ORACLE_HAS_NO_PRICE_FEED = '600';
    string public constant PRICE_ORACLE_INCORRECT_TIMESTAMP = '601';
    string public constant PRICE_ORACLE_PARAMS_ERROR = '602';
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IOpenSkyPriceAggregator {
    event SetAggregator(address indexed asset, address indexed aggregator);

    function getAssetPrice(address nftAddress) external view returns (uint256);
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
pragma solidity 0.8.10;

library DataTypes {
    struct ReserveData {
        uint256 reserveId;
        address underlyingAsset;
        address oTokenAddress;
        address moneyMarketAddress;
        uint128 lastSupplyIndex;
        uint256 borrowingInterestPerSecond;
        uint256 lastMoneyMarketBalance;
        uint40 lastUpdateTimestamp;
        uint256 totalBorrows;
        address interestModelAddress;
        uint256 treasuryFactor;
        bool isMoneyMarketOn;
    }

    struct LoanData {
        uint256 reserveId;
        address nftAddress;
        uint256 tokenId;
        address borrower;
        uint256 amount;
        uint128 borrowRate;
        uint128 interestPerSecond;
        uint40 borrowBegin;
        uint40 borrowDuration;
        uint40 borrowOverdueTime;
        uint40 liquidatableTime;
        uint40 extendableTime;
        uint40 borrowEnd;
        LoanStatus status;
    }

    enum LoanStatus {
        NONE,
        BORROWING,
        EXTENDABLE,
        OVERDUE,
        LIQUIDATABLE,
        LIQUIDATING
    }

    struct WhitelistInfo {
        bool enabled;
        string name;
        string symbol;
        uint256 LTV;
        uint256 minBorrowDuration;
        uint256 maxBorrowDuration;
        uint256 extendableDuration;
        uint256 overdueDuration;
    }
}