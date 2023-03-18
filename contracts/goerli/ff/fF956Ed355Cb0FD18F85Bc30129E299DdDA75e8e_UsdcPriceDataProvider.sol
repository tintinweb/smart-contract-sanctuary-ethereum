// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

import "IERC20Metadata.sol";

import "AggregatorDataProvider.sol";
import "IPriceDataProvider.sol";

contract UsdcPriceDataProvider is
    AggregatorDataProvider, 
    IPriceDataProvider
{
    address public constant USDC_CONTACT_ADDRESS_MAINNET = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant USDC_CONTACT_ADDRESS_GOERLI = 0x07865c6E87B9F70255377e024ace6630C1Eaa37F;

    address public constant CHAINLINK_USDC_USD_FEED_MAINNET = 0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6;
    address public constant CHAINLINK_USDC_USD_FEED_GOERLI = 0xAb5c49580294Aff77670F839ea425f5b78ab3Ae7;
    uint8 public constant CHAINLINK_USDC_DECIMALS = 8;

    uint256 public constant DEPEG_TRIGGER_PRICE = 995 * 10**CHAINLINK_USDC_DECIMALS / 1000; // USDC below 0.995 USD triggers depeg alert
    uint256 public constant DEPEG_RECOVERY_PRICE = 999 * 10**CHAINLINK_USDC_DECIMALS / 1000; // USDC at/above 0.999 USD is find and/or is considered a recovery from a depeg alert
    uint256 public constant DEPEG_RECOVERY_WINDOW = 24 * 3600;

    uint256 public constant PRICE_INFO_HISTORY_DURATION = 7 * 24 * 3600; // keep price info for 1 week

    string public constant CHAINLINK_TEST_DESCRIPTION = "USDC / USD (Ganache)";
    uint256 public constant CHAINLINK_TEST_VERSION = 4;

    // see https://docs.chain.link/data-feeds/price-feeds/addresses
    // deviation: 0.25%
    // heartbeat: 86400 (=24 * 60 * 60)
    uint256 public constant CHAINLINK_USDC_USD_DEVIATION = 25 * 10**CHAINLINK_USDC_DECIMALS / 10000;

    // TODO evaluate margin over full chainlink price feed history
    uint256 public constant CHAINLINK_HEARTBEAT_MARGIN = 100;
    uint256 public constant CHAINLINK_USDC_USD_HEARTBEAT = 24 * 3600;

    uint8 public constant PRICE_HISTORY_SIZE = 20;

    IERC20Metadata private _token;

    PriceInfo private _depegPriceInfo;
    uint256 private _triggeredAt;
    uint256 private _depeggedAt;
    uint256 private _depeggedBlockNumber;

    constructor(address tokenAddress) 
        AggregatorDataProvider(
            CHAINLINK_USDC_USD_FEED_MAINNET, 
            CHAINLINK_USDC_USD_FEED_GOERLI, 
            CHAINLINK_USDC_USD_DEVIATION,
            CHAINLINK_USDC_USD_HEARTBEAT,
            CHAINLINK_HEARTBEAT_MARGIN,
            CHAINLINK_TEST_DESCRIPTION,
            CHAINLINK_USDC_DECIMALS,
            CHAINLINK_TEST_VERSION
        )
    {
        if(isMainnet()) {
            if(block.chainid == 1) {
                _token = IERC20Metadata(USDC_CONTACT_ADDRESS_MAINNET);
            } else if(block.chainid == 5) {
                _token = IERC20Metadata(USDC_CONTACT_ADDRESS_GOERLI);
            } else {
                revert("ERROR:UPDP-010:CHAIN_NOT_SUPPORTET");
            }
        } else if(isTestnet()) {
            _token = IERC20Metadata(tokenAddress);
        } else {
            revert("ERROR:UPDP-011:CHAIN_NOT_SUPPORTET");
        }

        _triggeredAt = 0;
        _depeggedAt = 0;
        _depeggedBlockNumber = 0;
    }


    function getLatestPriceInfo()
        public override
        view
        returns(PriceInfo memory priceInfo)
    {
        (
            uint80 roundId,
            int256 answer,
            , // startedAt unused
            uint256 updatedAt,
             // answeredInRound unused
        ) = latestRoundData();

        require(answer >= 0, "ERROR:UPDP-020:NEGATIVE_PRICE_VALUES_INVALID");

        uint256 price = uint256(answer);

        IPriceDataProvider.ComplianceState compliance = getComplianceState(roundId, price, updatedAt);
        IPriceDataProvider.StabilityState stability = getStability(roundId, price, updatedAt);

        // calculate event type, triggered at and depegged at
        IPriceDataProvider.EventType eventType = IPriceDataProvider.EventType.Update;
        uint256 triggeredAt = _triggeredAt;
        uint256 depeggedAt = _depeggedAt;
        
        // check all possible state changing transitions
        // enter depegged state
        if(stability == IPriceDataProvider.StabilityState.Depegged && _depeggedAt == 0) {
            eventType = IPriceDataProvider.EventType.DepegEvent;
            depeggedAt = updatedAt;
        // enter triggered state
        } else if(stability == IPriceDataProvider.StabilityState.Triggered && _triggeredAt == 0) {
            eventType = IPriceDataProvider.EventType.TriggerEvent;
            triggeredAt = updatedAt;
        // recover from triggered state
        } else if(stability == IPriceDataProvider.StabilityState.Stable && _triggeredAt > 0) {
            eventType = IPriceDataProvider.EventType.RecoveryEvent;
        }

        return PriceInfo(
            roundId,
            price,
            compliance,
            stability,
            eventType,
            triggeredAt,
            depeggedAt,
            updatedAt
        );
    }


    function processLatestPriceInfo()
        public override
        returns(PriceInfo memory priceInfo)
    {
        priceInfo = getLatestPriceInfo();

        if(priceInfo.eventType == IPriceDataProvider.EventType.DepegEvent) {
            _depegPriceInfo = priceInfo;
            _depeggedAt = priceInfo.depeggedAt;

            emit LogPriceDataDepegged(
                priceInfo.id,
                priceInfo.price,
                priceInfo.triggeredAt,
                priceInfo.depeggedAt);

        } else if(priceInfo.eventType == IPriceDataProvider.EventType.TriggerEvent) {
            _triggeredAt = priceInfo.triggeredAt;

            emit LogPriceDataTriggered(
                priceInfo.id,
                priceInfo.price,
                priceInfo.triggeredAt);

        } else if(priceInfo.eventType == IPriceDataProvider.EventType.RecoveryEvent) {
            _triggeredAt = 0;

            emit LogPriceDataRecovered(
                priceInfo.id,
                priceInfo.price,
                priceInfo.triggeredAt,
                priceInfo.createdAt);
        } else {
            emit LogPriceDataProcessed(
                priceInfo.id,
                priceInfo.price,
                priceInfo.createdAt);
        }

    }


    function forceDepegForNextPriceInfo()
        external override
        onlyOwner()
        onlyTestnet()
    {
        require(_triggeredAt > DEPEG_RECOVERY_WINDOW, "ERROR:UPDP-030:TRIGGERED_AT_TOO_SMALL");

        _triggeredAt -= DEPEG_RECOVERY_WINDOW;

        emit LogUsdcProviderForcedDepeg(_triggeredAt, block.timestamp);
    }

    function resetDepeg()
        external override
        onlyOwner()
        onlyTestnet()
    {
        _depegPriceInfo.id = 0;
        _depegPriceInfo.price = 0;
        _depegPriceInfo.compliance = IPriceDataProvider.ComplianceState.Undefined;
        _depegPriceInfo.stability = IPriceDataProvider.StabilityState.Undefined;
        _depegPriceInfo.triggeredAt = 0;
        _depegPriceInfo.depeggedAt = 0;
        _depegPriceInfo.createdAt = 0;

        _triggeredAt = 0;
        _depeggedAt = 0;

        emit LogUsdcProviderResetDepeg(block.timestamp);
    }


    function isNewPriceInfoEventAvailable()
        external override
        view
        returns(
            bool newEvent, 
            PriceInfo memory priceInfo,
            uint256 timeSinceEvent
        )
    {
        priceInfo = getLatestPriceInfo();
        newEvent = !(priceInfo.eventType == IPriceDataProvider.EventType.Undefined 
            || priceInfo.eventType == IPriceDataProvider.EventType.Update);
        timeSinceEvent = priceInfo.createdAt == 0 ? 0 : block.timestamp - priceInfo.createdAt;
    }


    function getCompliance(
        uint80 roundId,
        uint256 price,
        uint256 updatedAt
    )
        public view
        returns(
            bool priceDeviationIsValid,
            bool heartbeetIsValid,
            uint256 previousPrice,
            uint256 previousUpdatedAt
        )
    {
        if(roundId == 0) {
            return (
                true,
                true,
                0,
                0);
        }

        (
            , // roundId unused
            int256 previousPriceInt,
            , // startedAt unused
            uint256 previousUpdatedAtUint,
             // answeredInRound unused
        ) = getRoundData(roundId - 1);

        if(previousUpdatedAtUint == 0) {
            return (
                true,
                true,
                previousPrice,
                previousUpdatedAtUint);
        }

        previousPrice = uint256(previousPriceInt);

        return (
            !isExceedingDeviation(price, previousPrice),
            !isExceedingHeartbeat(updatedAt, previousUpdatedAtUint),
            previousPrice,
            previousUpdatedAtUint);
    }


    function getStability(
        uint256 roundId,
        uint256 price,
        uint256 updatedAt
    )
        public
        view
        returns(IPriceDataProvider.StabilityState stability)
    {
        // no price data available (yet)
        // only expected with test setup
        if(updatedAt == 0) {
            return IPriceDataProvider.StabilityState.Initializing;
        }

        // once depegged, state remains depegged
        if(_depeggedAt > 0) {
            return IPriceDataProvider.StabilityState.Depegged;
        }

        // check triggered state:
        // triggered and not recovered within recovery window
        if(_triggeredAt > 0) {

            // check if recovery run out of time and we have depegged
            if(updatedAt - _triggeredAt > DEPEG_RECOVERY_WINDOW) {
                return IPriceDataProvider.StabilityState.Depegged;
            }

            // check for recovery
            if(price >= DEPEG_RECOVERY_PRICE) {
                return IPriceDataProvider.StabilityState.Stable;
            }

            // remaining in triggered state
            return IPriceDataProvider.StabilityState.Triggered;
        } 

        // check potential change into triggerd state
        if(price <= DEPEG_TRIGGER_PRICE) {
            return IPriceDataProvider.StabilityState.Triggered;
        }

        // everything fine 
        return IPriceDataProvider.StabilityState.Stable;
    }


    function getComplianceState(
        uint256 roundId,
        uint256 price,
        uint256 updatedAt
    )
        public
        view
        returns(IPriceDataProvider.ComplianceState compliance)
    {
        (
            bool priceDeviationIsValid,
            bool heartbeetIsValid,
            uint256 previousPrice,
            uint256 previousUpdatedAt
        ) = getCompliance(uint80(roundId), price, updatedAt);

        if(previousUpdatedAt == 0) {
            return IPriceDataProvider.ComplianceState.Initializing;
        }

        if(priceDeviationIsValid && heartbeetIsValid) {
            return IPriceDataProvider.ComplianceState.Valid;
        }

        (
            bool previousPriceDeviationIsValid,
            bool previousHeartbeetIsValid,
            , // previousPrice not usedc
            uint256 prePreviousUpdatedAt
        ) = getCompliance(uint80(roundId-1), previousPrice, previousUpdatedAt);

        if((previousPriceDeviationIsValid && previousHeartbeetIsValid)
            || prePreviousUpdatedAt == 0)
        {
            return IPriceDataProvider.ComplianceState.FailedOnce;
        }

        return IPriceDataProvider.ComplianceState.FailedMultipleTimes;
    }

    function getDepegPriceInfo()
        public override
        view
        returns(PriceInfo memory priceInfo)
    {
        return _depegPriceInfo;
    }

    function getTargetPrice() external override view returns(uint256 targetPrice) {
        return 10 ** decimals();
    }

    function getTriggeredAt() external override view returns(uint256 triggeredAt) {
        return _triggeredAt;
    }

    function getDepeggedAt() external override view returns(uint256 depeggedAt) {
        return _depeggedAt;
    }

    function getAggregatorAddress() external override view returns(address priceInfoSourceAddress) {
        return getChainlinkAggregatorAddress();
    }

    function getHeartbeat() external override view returns(uint256 heartbeatSeconds) {
        return heartbeat();
    }

    function getDeviation() external override view returns(uint256 deviationLevel) {
        return deviation();
    }

    function getDecimals() external override view returns(uint8 priceInfoDecimals) {
        return decimals();
    }

    function getToken() external override view returns(address) {
        return address(_token);
    }

    function getOwner() external override view returns(address) {
        return owner();
    }

    function isMainnetProvider()
        public override
        view
        returns(bool)
    {
        return isMainnet();
    }

    function isTestnetProvider()
        public override
        view
        returns(bool)
    {
        return isTestnet();
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";

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

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

import "Ownable.sol";

// V2V3 combines AggregatorInterface and AggregatorV3Interface
import "AggregatorV2V3Interface.sol";

contract AggregatorDataProvider is 
    Ownable,
    AggregatorV2V3Interface
{
    // matches return data for latestRoundData
    struct ChainlinkRoundData {
        uint80 roundId;
        int256 answer;
        uint256 startedAt;
        uint256 updatedAt;
        uint80 answeredInRound;
    }

    uint256 public constant MAINNET = 1;
    uint256 public constant GOERLI = 5;

    uint256 public constant GANACHE = 1337;
    uint256 public constant GANACHE2 = 1234;
    uint256 public constant MUMBAI = 80001;
    
    AggregatorV2V3Interface private _aggregator;

    uint256 private _deviation;
    uint256 private _heartbeat;
    uint256 private _heartbeatMargin;

    string private _description;
    uint8 private _decimals;
    uint256 private _version;

    mapping(uint80 /* round id */ => ChainlinkRoundData) private _aggregatorData;
    uint80 [] private _roundIds;
    uint80 private _maxRoundId;

    modifier onlyTestnet() {
        require(isTestnet(), "ERROR:ADP-001:NOT_TEST_CHAIN");
        _;
    }

    constructor(
        address aggregatorAddressMainnet,
        address aggregatorAddressGoerli,
        uint256 deviationLevel, // 10**decimals() corresponding to 100%
        uint256 heartbeatSeconds,
        uint256 heartbeatMarginSeconds,
        string memory testDescription,
        uint8 testDecimals,
        uint256 testVersion
    ) 
        Ownable()
    {
        if(isMainnet()) {
            if(block.chainid == 1) {
                _aggregator = AggregatorV2V3Interface(aggregatorAddressMainnet);
            } else if(block.chainid == 5) {
                _aggregator = AggregatorV2V3Interface(aggregatorAddressGoerli);
            }
        } else if(isTestnet()) {
            _aggregator = AggregatorV2V3Interface(address(this));
        } else {
            revert("ERROR:ADP-010:CHAIN_NOT_SUPPORTET");
        }

        _description = testDescription;
        _decimals = testDecimals;
        _version = testVersion;

        _deviation = deviationLevel;
        _heartbeat = heartbeatSeconds;
        _heartbeatMargin = heartbeatMarginSeconds;

        _maxRoundId = 0;
    }

    function addRoundData(
        int256 answer,
        uint256 startedAt
    )
        external
    {
        _maxRoundId++;
        setRoundData(
            _maxRoundId,
            answer,
            startedAt,
            startedAt, // set updatedAt == startedAt
            _maxRoundId
        );
    }


    function setRoundData (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    )
        public
        onlyOwner()
        onlyTestnet()
    {
        // update max roundId if necessary
        if(roundId > _maxRoundId) {
            _maxRoundId = roundId;
        }

        _roundIds.push(roundId);
        _aggregatorData[roundId] = ChainlinkRoundData(
            roundId,
            answer,
            startedAt,
            updatedAt,
            answeredInRound
        );
    }

    function getRoundData(uint80 _roundId)
        public override
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        if(isMainnet()) {
            return _aggregator.getRoundData(_roundId);
        }

        ChainlinkRoundData memory data = _aggregatorData[_roundId];

        return (
            data.roundId,
            data.answer,
            data.startedAt,
            data.updatedAt,
            data.answeredInRound
        );
    }

    function getChainlinkAggregatorAddress() public view returns(address) {
        return address(_aggregator);
    }

    function isExceedingDeviation(uint256 price1, uint256 price2) 
        public 
        view 
        returns(bool isExceeding)
    {
        if(price1 >= price2) {
            if(price1 - price2 > _deviation) {
                return true;
            }
        }
        else if(price2 - price1 > _deviation) {
            return true;
        }

        return false;
    }

    function isExceedingHeartbeat(uint256 time1, uint256 time2) 
        public 
        view 
        returns(bool isExceeding)
    {
        if(time1 >= time2) {
            if(time1 - time2 > _heartbeat + _heartbeatMargin) {
                return true;
            }
        }
        else if(time2 - time1 > _heartbeat + _heartbeatMargin) {
            return true;
        }

        return false;
    }

    function deviation() public view returns (uint256) {
        return _deviation;
    }

    function heartbeat() public view returns (uint256) {
        return _heartbeat;
    }

    function heartbeatMargin() public view returns (uint256) {
        return _heartbeatMargin;
    }

    function latestAnswer() external override view returns (int256) {
        if(isMainnet()) {
            return _aggregator.latestAnswer();
        }

        return _aggregatorData[_maxRoundId].answer;
    }

    function latestTimestamp() external override view returns (uint256) {
        if(isMainnet()) {
            return _aggregator.latestTimestamp();
        }

        return _aggregatorData[_maxRoundId].updatedAt;
    }

    function latestRound() external override view returns (uint256) {
        if(isMainnet()) {
            return _aggregator.latestRound();
        }

        return _maxRoundId;
    }

    function getAnswer(uint256 roundId) external override view returns (int256) {
        if(isMainnet()) {
            return _aggregator.getAnswer(roundId);
        }

        return _aggregatorData[uint80(roundId)].answer;
    }

    function getTimestamp(uint256 roundId) external override view returns (uint256) {
        if(isMainnet()) {
            return _aggregator.getTimestamp(roundId);
        }

        return _aggregatorData[uint80(roundId)].updatedAt;
    }

    function description() public override view returns (string memory) {
        if(isMainnet()) {
            return _aggregator.description();
        }

        return _description;
    }

    function decimals() public override view returns(uint8) {
        if(isMainnet()) {
            return _aggregator.decimals();
        }

        return _decimals;
    }

    function version() public override view returns (uint256) {
        if(isMainnet()) {
            return _aggregator.version();
        }

        return _version;
    }

    function latestRoundData()
        public override
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        if(isMainnet()) {
            return _aggregator.latestRoundData();
        }

        return getRoundData(_maxRoundId);
    }

    function isMainnet()
        public
        view
        returns(bool)
    {
        return (block.chainid == MAINNET)
            || (block.chainid == GOERLI);
    }    

    function isTestnet()
        public
        view
        returns(bool)
    {
        return (block.chainid == GANACHE)
            || (block.chainid == GANACHE2)
            || (block.chainid == MUMBAI);
    }    
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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
pragma solidity ^0.8.0;

import "AggregatorInterface.sol";
import "AggregatorV3Interface.sol";

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface {}

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

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

interface IPriceDataProvider {

    enum ComplianceState {
        Undefined,
        Initializing,
        Valid,
        FailedOnce,
        FailedMultipleTimes
    }

    enum StabilityState {
        Undefined,
        Initializing,
        Stable,
        Triggered,
        Depegged
    }

    enum EventType {
        Undefined,
        Update,
        TriggerEvent,
        RecoveryEvent,
        DepegEvent
    }

    event LogPriceDataDeviationExceeded (
        uint256 priceId,
        uint256 priceDeviation,
        uint256 currentPrice,
        uint256 lastPrice);

    event LogPriceDataHeartbeatExceeded (
        uint256 priceId,
        uint256 timeDifference,
        uint256 currentCreatedAt,
        uint256 lastCreatedAt);

    event LogPriceDataTriggered (
        uint256 priceId,
        uint256 price,
        uint256 triggeredAt);

    event LogPriceDataRecovered (
        uint256 priceId,
        uint256 price,
        uint256 triggeredAt,
        uint256 recoveredAt);

    event LogPriceDataDepegged (
        uint256 priceId,
        uint256 price,
        uint256 triggeredAt,
        uint256 depeggedAt);

    event LogPriceDataProcessed (
        uint256 priceId,
        uint256 price,
        uint256 createdAt);

    event LogUsdcProviderForcedDepeg (
        uint256 updatedTriggeredAt,
        uint256 forcedDepegAt);

    event LogUsdcProviderResetDepeg (
        uint256 resetDepegAt);

    struct PriceInfo {
        uint256 id;
        uint256 price;
        ComplianceState compliance;
        StabilityState stability;
        EventType eventType;
        uint256 triggeredAt;
        uint256 depeggedAt;
        uint256 createdAt;
    }

    function processLatestPriceInfo()
        external 
        returns(PriceInfo memory priceInfo);

    // only on testnets
    function forceDepegForNextPriceInfo()
        external;

    // only on testnets
    function resetDepeg()
        external;

    function isNewPriceInfoEventAvailable()
        external
        view
        returns(
            bool newEvent, 
            PriceInfo memory priceInfo,
            uint256 timeSinceEvent);

    function getLatestPriceInfo()
        external
        view 
        returns(PriceInfo memory priceInfo);

    function getDepegPriceInfo()
        external
        view 
        returns(PriceInfo memory priceInfo);

    function getTargetPrice() external view returns(uint256 targetPrice);

    function getTriggeredAt() external view returns(uint256 triggeredAt);
    function getDepeggedAt() external view returns(uint256 depeggedAt);

    function getAggregatorAddress() external view returns(address aggregatorAddress);
    function getHeartbeat() external view returns(uint256 heartbeatSeconds);
    function getDeviation() external view returns(uint256 deviationLevel);
    function getDecimals() external view returns(uint8 aggregatorDecimals);

    function getToken() external view returns(address);
    function getOwner() external view returns(address);

    function isMainnetProvider() external view returns(bool);
    function isTestnetProvider() external view returns(bool);
}