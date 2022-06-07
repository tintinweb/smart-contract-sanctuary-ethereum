//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

import "./interfaces/IMAIL.sol";
import "./interfaces/IMAILDeployer.sol";
import "./interfaces/InterestRateModelInterface.sol";
import "./interfaces/AggregatorV3Interface.sol";
import "./interfaces/InterestViewBalancesInterface.sol";
import "./interfaces/IOracle.sol";

import "./lib/IntMath.sol";
import "./lib/IntERC20.sol";

import "./BridgeTokens.sol";
import {MailData, MailMetadata, ERC20Metada} from "./Structs.sol";

contract InterestViewMAIL is Ownable, BridgeTokens {
    using SafeCast for *;
    using IntMath for uint256;
    using IntERC20 for address;

    IOracle private constant ORACLE =
        IOracle(0x077E94a52fc66BDBEEa84C8d76e3cC35A040AC5f);

    IMAILDeployer private constant MAIL_DEPLOYER =
        IMAILDeployer(0xDD02a8A5630b4fD156e5311550746965E17279a3);

    InterestViewBalancesInterface private constant INTEREST_VIEW_BALANCES =
        InterestViewBalancesInterface(
            0x2b122FB8E1B4b21bC3b0Bc57199b21d07E58Ec5c
        );

    // Token Address -> Chainlink feed with ETH base.
    mapping(address => AggregatorV3Interface) public getUSDFeeds;

    function getMAILPoolData(IMAIL mail, address account)
        external
        view
        returns (ERC20Metada memory, MailData[] memory data)
    {
        data = new MailData[](5);

        // [BTC, WETH, USDC, USDT]
        for (uint256 i; i < BRIDGE_TOKENS_ARRAY.length; i++) {
            address token = BRIDGE_TOKENS_ARRAY[i];

            data[i].usdPrice = getUSDPrice(token).toUint128();

            Market memory market = mail.marketOf(token);
            Account memory mailAccount = mail.accountOf(token, account);

            InterestRateModelInterface model = InterestRateModelInterface(
                MAIL_DEPLOYER.getInterestRateModel(token)
            );

            (uint256 allowance, uint256 balance) = INTEREST_VIEW_BALANCES
                .getUserBalanceAndAllowance(account, address(mail), token);

            data[i].cash = mail.getCash(token);
            data[i].allowance = allowance;
            data[i].balance = balance.toUint128();
            data[i].ltv = MAIL_DEPLOYER.maxLTVOf(token).toUint128();
            data[i].totalElastic = market.loan.elastic;
            data[i].totalBase = market.loan.base;
            data[i].totalSupply = mail.totalSupplyOf(token).toUint128();
            data[i].borrow = mailAccount.principal;
            data[i].supply = mailAccount.balance;
            data[i].supplyRate = model
                .getSupplyRatePerBlock(
                    mail.getCash(token),
                    market.loan.elastic,
                    market.totalReserves,
                    MAIL_DEPLOYER.reserveFactor()
                )
                .toUint128();
            data[i].borrowRate = model
                .getBorrowRatePerBlock(
                    mail.getCash(token),
                    market.loan.elastic,
                    market.totalReserves
                )
                .toUint128();
        }

        {
            address riskyToken = mail.RISKY_TOKEN();
            data[4].usdPrice = getRiskyTokenUSDPrice(riskyToken).toUint128();

            Market memory market = mail.marketOf(riskyToken);
            Account memory mailAccount = mail.accountOf(riskyToken, account);

            InterestRateModelInterface model = InterestRateModelInterface(
                MAIL_DEPLOYER.riskyTokenInterestRateModel()
            );

            (uint256 allowance, uint256 balance) = INTEREST_VIEW_BALANCES
                .getUserBalanceAndAllowance(account, address(mail), riskyToken);

            data[4].cash = mail.getCash(riskyToken);
            data[4].allowance = allowance;
            data[4].balance = balance.toUint128();
            data[4].ltv = MAIL_DEPLOYER.riskyTokenLTV().toUint128();
            data[4].totalElastic = market.loan.elastic;
            data[4].totalBase = market.loan.base;
            data[4].totalSupply = mail.totalSupplyOf(riskyToken).toUint128();
            data[4].borrow = mailAccount.principal;
            data[4].supply = mailAccount.balance;
            data[4].supplyRate = model
                .getSupplyRatePerBlock(
                    mail.getCash(riskyToken),
                    market.loan.elastic,
                    market.totalReserves,
                    MAIL_DEPLOYER.reserveFactor()
                )
                .toUint128();
            data[4].borrowRate = model
                .getBorrowRatePerBlock(
                    mail.getCash(riskyToken),
                    market.loan.elastic,
                    market.totalReserves
                )
                .toUint128();
        }

        return (getERC20Metada(mail.RISKY_TOKEN()), data);
    }

    function getSupplyRate(
        address mail,
        address token,
        uint256 amount,
        bool isRiskyToken
    ) external view returns (uint256) {
        InterestRateModelInterface model;

        if (isRiskyToken) {
            model = InterestRateModelInterface(
                MAIL_DEPLOYER.riskyTokenInterestRateModel()
            );
        } else {
            model = InterestRateModelInterface(
                MAIL_DEPLOYER.getInterestRateModel(token)
            );
        }

        Market memory market = IMAIL(mail).marketOf(token);

        uint256 cash = IMAIL(mail).getCash(token);

        if (amount >= cash) cash - amount;

        return
            model.getSupplyRatePerBlock(
                cash,
                market.loan.elastic,
                market.totalReserves,
                MAIL_DEPLOYER.reserveFactor()
            );
    }

    function getBorrowRate(
        address mail,
        address token,
        uint256 amount,
        bool isRiskyToken
    ) external view returns (uint256) {
        InterestRateModelInterface model;

        if (isRiskyToken) {
            model = InterestRateModelInterface(
                MAIL_DEPLOYER.riskyTokenInterestRateModel()
            );
        } else {
            model = InterestRateModelInterface(
                MAIL_DEPLOYER.getInterestRateModel(token)
            );
        }

        Market memory market = IMAIL(mail).marketOf(token);

        uint256 cash = IMAIL(mail).getCash(token);

        if (amount >= cash) cash - amount;

        return
            model.getBorrowRatePerBlock(
                cash,
                market.loan.elastic,
                market.totalReserves
            );
    }

    function getERC20Metada(address token)
        public
        view
        returns (ERC20Metada memory)
    {
        string memory name = token.safeName();
        string memory symbol = token.safeSymbol();
        uint256 decimals = token.safeDecimals();

        return ERC20Metada(token, name, symbol, decimals);
    }

    function getRiskyTokenUSDPrice(address riskyToken)
        public
        view
        returns (uint256)
    {
        uint256 one = 10**riskyToken.safeDecimals();
        uint256 wethAmount = ORACLE.getUNIV3Price(riskyToken, one);
        return (getUSDPrice(WETH) * wethAmount) / 1 ether;
    }

    function getMAILMarketMetadata(address token)
        public
        view
        returns (MailMetadata memory)
    {
        address mailMarket = MAIL_DEPLOYER.getMarket(token);

        address predictedAddress = MAIL_DEPLOYER.predictMarketAddress(token);

        string memory name = token.safeName();
        string memory symbol = token.safeSymbol();

        bool isDeployed = mailMarket != address(0);

        return MailMetadata(isDeployed, name, symbol, token, predictedAddress);
    }

    function getUSDPrice(address token) public view returns (uint256) {
        AggregatorV3Interface feed = getUSDFeeds[token];

        (, int256 answer, , , ) = feed.latestRoundData();

        return answer.toUint256().toBase(feed.decimals());
    }

    function getTokenUSDPrices(address[] calldata tokens)
        external
        view
        returns (uint256[] memory tokenPrices)
    {
        tokenPrices = new uint256[](tokens.length);

        for (uint256 i; i < tokens.length; i++) {
            address token = tokens[i];

            tokenPrices[i] = getUSDPrice(token);
        }
    }

    function getManyMailSummaryData(
        address[] calldata tokens,
        address[] calldata riskyTokens
    )
        external
        view
        returns (uint256[][] memory borrowRates, uint256[][] memory supplyRates)
    {
        borrowRates = new uint256[][](riskyTokens.length);
        supplyRates = new uint256[][](riskyTokens.length);

        address[] memory models = new address[](tokens.length);

        InterestRateModelInterface riskyModel = InterestRateModelInterface(
            MAIL_DEPLOYER.riskyTokenInterestRateModel()
        );

        for (uint256 i; i < tokens.length; i++) {
            address token = tokens[i];

            models[i] = MAIL_DEPLOYER.getInterestRateModel(token);
        }

        for (uint256 i; i < riskyTokens.length; i++) {
            address riskyToken = riskyTokens[i];

            IMAIL mail = IMAIL(MAIL_DEPLOYER.getMarket(riskyToken));

            uint256[] memory borrow = new uint256[](models.length + 1);
            uint256[] memory supply = new uint256[](models.length + 1);

            for (uint256 j; j < models.length; j++) {
                InterestRateModelInterface model = InterestRateModelInterface(
                    models[j]
                );
                address token = tokens[j];
                Market memory market = mail.marketOf(token);

                uint256 cash = mail.getCash(token);
                uint256 totalBorrow = market.loan.elastic;

                borrow[j] = model.getBorrowRatePerBlock(
                    cash,
                    totalBorrow,
                    market.totalReserves
                );

                supply[j] = model.getSupplyRatePerBlock(
                    cash,
                    totalBorrow,
                    market.totalReserves,
                    MAIL_DEPLOYER.reserveFactor()
                );
            }

            Market memory riskyMarket = mail.marketOf(riskyToken);

            uint256 rCash = mail.getCash(riskyToken);
            uint256 rTotalBorrow = riskyMarket.loan.elastic;

            borrow[models.length] = riskyModel.getBorrowRatePerBlock(
                rCash,
                rTotalBorrow,
                riskyMarket.totalReserves
            );

            supply[models.length] = riskyModel.getSupplyRatePerBlock(
                rCash,
                rTotalBorrow,
                riskyMarket.totalReserves,
                MAIL_DEPLOYER.reserveFactor()
            );

            borrowRates[i] = borrow;
            supplyRates[i] = supply;
        }
    }

    function setFeed(address token, AggregatorV3Interface feed)
        external
        onlyOwner
    {
        getUSDFeeds[token] = feed;
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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "../lib/Rebase.sol";

import {Market, Account} from "../Structs.sol";

interface IMAIL {
    function getCash(address token) external view returns (uint256);

    function marketOf(address token)
        external
        view
        returns (Market memory market);

    //solhint-disable-next-line func-name-mixedcase
    function RISKY_TOKEN() external view returns (address);

    function totalSupplyOf(address) external view returns (uint256);

    function accountOf(address token, address account)
        external
        view
        returns (Account memory);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IMAILDeployer {
    //solhint-disable-next-line func-name-mixedcase
    function ROUTER() external view returns (address);

    //solhint-disable-next-line func-name-mixedcase
    function ORACLE() external view returns (address);

    function riskyToken() external view returns (address);

    function getInterestRateModel(address token)
        external
        view
        returns (address);

    function predictMarketAddress(address _riskytoken)
        external
        view
        returns (address);

    function getMarket(address token) external view returns (address);

    function treasury() external view returns (address);

    function reserveFactor() external view returns (uint256);

    function riskyTokenInterestRateModel() external view returns (address);

    function getFeesLength() external view returns (uint256);

    function riskyTokenLTV() external view returns (uint256);

    function maxLTVOf(address token) external view returns (uint256);

    function liquidationFee() external view returns (uint256);

    function liquidatorPortion() external view returns (uint256);

    event MarketCreated(address indexed market);

    event SetReserveFactor(uint256 amount);

    event SetTreasury(address indexed account);

    event SetInterestRateModel(
        address indexed token,
        address indexed interestRateModel
    );

    event NewUniSwapFee(uint256 indexed fee);

    event SetNewTokenLTV(address indexed token, uint256 amount);

    event SetLiquidationFee(uint256 indexed fee);

    event SetLiquidatorPortion(uint256 indexed portion);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface InterestRateModelInterface {
    function getBorrowRatePerBlock(
        uint256 cash,
        uint256 totalBorrowAmount,
        uint256 reserves
    ) external view returns (uint256);

    function getSupplyRatePerBlock(
        uint256 cash,
        uint256 totalBorrowAmount,
        uint256 reserves,
        uint256 reserveFactor
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

// @dev This is taken from chainlink github repo
// @link https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol
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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface InterestViewBalancesInterface {
    function getUserBalances(address account, address[] calldata tokens)
        external
        view
        returns (uint256 nativeBalance, uint256[] memory balances);

    function getUserBalanceAndAllowance(
        address user,
        address spender,
        address token
    ) external view returns (uint256 allowance, uint256 balance);

    function getUserBalancesAndAllowances(
        address user,
        address spender,
        address[] calldata tokens
    )
        external
        view
        returns (uint256[] memory allowances, uint256[] memory balances);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IOracle {
    function getETHPrice(address token, uint256 amount)
        external
        view
        returns (uint256);

    function getUNIV3Price(address riskytoken, uint256 amount)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: CC-BY-4.0
pragma solidity 0.8.13;

/**
 * @dev We assume that all numbers passed to {bmul} and {bdiv} have a mantissa of 1e18
 *
 * @notice We copied from https://github.com/Uniswap/v3-core/blob/main/contracts/libraries/FullMath.sol
 * @notice We modified line 67 per this post https://ethereum.stackexchange.com/questions/96642/unary-operator-cannot-be-applied-to-type-uint256
 */
// taken from https://medium.com/coinmonks/math-in-solidity-part-3-percents-and-proportions-4db014e080b1
// license is CC-BY-4.0
library IntMath {
    // Base Mantissa of all numbers in Interest Protocol
    uint256 private constant BASE = 1e18;

    /**
     * @dev Adjusts the price to have 18 decimal houses to work easier with most {ERC20}.
     *
     * @param price The price of the token
     * @param decimals The current decimals the price has
     * @return uint256 the new price supporting 18 decimal houses
     */
    function toBase(uint256 price, uint8 decimals)
        internal
        pure
        returns (uint256)
    {
        uint256 baseDecimals = 18;

        if (decimals == baseDecimals) return price;

        if (decimals < baseDecimals)
            return price * 10**(baseDecimals - decimals);

        return price / 10**(decimals - baseDecimals);
    }

    /**
     * @dev Adjusts the price to have `decimal` houses to work easier with most {ERC20}.
     *
     * @param price The price of the token
     * @param decimals The current decimals the price has
     * @return uint256 the new price supporting `decimals` decimal houses
     */
    function fromBase(uint256 price, uint8 decimals)
        internal
        pure
        returns (uint256)
    {
        uint256 baseDecimals = 18;

        if (decimals == baseDecimals) return price;

        if (decimals < baseDecimals)
            return price / 10**(baseDecimals - decimals);

        return price * 10**(decimals - baseDecimals);
    }

    /**
     * @dev Function ensures that the return value keeps the right mantissa
     */
    function bmul(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDiv(x, y, BASE);
    }

    /**
     * @dev Function ensures that the return value keeps the right mantissa
     */
    function bdiv(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDiv(x, BASE, y);
    }

    /**
     * @dev Returns the smallest of two numbers.
     * Taken from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/Math.sol
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    //solhint-disable
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        require(denominator > prod1);

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // Compute remainder using mulmod
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        // Subtract 256 bit number from 512 bit number
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator
        // Compute largest power of two divisor of denominator.
        // Always >= 1.
        uint256 twos = denominator & (~denominator + 1);
        // Divide denominator by power of two
        assembly {
            denominator := div(denominator, twos)
        }

        // Divide [prod1 prod0] by the factors of two
        assembly {
            prod0 := div(prod0, twos)
        }
        // Shift in bits from prod1 into prod0. For this we need
        // to flip `twos` such that it is 2**256 / twos.
        // If twos is zero, then it becomes one
        assembly {
            twos := add(div(sub(0, twos), twos), 1)
        }
        prod0 |= prod1 * twos;

        // Invert denominator mod 2**256
        // Now that denominator is an odd number, it has an inverse
        // modulo 2**256 such that denominator * inv = 1 mod 2**256.
        // Compute the inverse by starting with a seed that is correct
        // correct for four bits. That is, denominator * inv = 1 mod 2**4
        uint256 inv = (3 * denominator) ^ 2;
        // Now use Newton-Raphson iteration to improve the precision.
        // Thanks to Hensel's lifting lemma, this also works in modular
        // arithmetic, doubling the correct bits in each step.
        inv *= 2 - denominator * inv; // inverse mod 2**8
        inv *= 2 - denominator * inv; // inverse mod 2**16
        inv *= 2 - denominator * inv; // inverse mod 2**32
        inv *= 2 - denominator * inv; // inverse mod 2**64
        inv *= 2 - denominator * inv; // inverse mod 2**128
        inv *= 2 - denominator * inv; // inverse mod 2**256

        // Because the division is now exact we can divide by multiplying
        // with the modular inverse of denominator. This will give us the
        // correct result modulo 2**256. Since the precoditions guarantee
        // that the outcome is less than 2**256, this is the final result.
        // We don't need to compute the high bits of the result and prod1
        // is no longer required.
        result = prod0 * inv;
        return result;
    }

    /**
     * @notice This was copied from Uniswap without any modifications.
     * https://github.com/Uniswap/v2-core/blob/master/contracts/libraries/Math.sol
     * babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
     */
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @dev All credits to boring crypto https://github.com/boringcrypto/BoringSolidity/blob/master/contracts/libraries/BoringERC20.sol
 */
library IntERC20 {
    /// @notice Provides a safe ERC20.decimals version which returns '18' as fallback value.
    /// @param token The address of the ERC-20 token contract.
    /// @return (uint8) Token decimals.
    function safeDecimals(address token) internal view returns (uint8) {
        require(isContract(token), "IntERC20: not a contract");

        (bool success, bytes memory data) = token.staticcall(
            abi.encodeWithSelector(IERC20Metadata.decimals.selector)
        );
        return success && data.length == 32 ? abi.decode(data, (uint8)) : 18;
    }

    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function returnDataToString(bytes memory data)
        internal
        pure
        returns (string memory)
    {
        if (data.length >= 64) {
            return abi.decode(data, (string));
        } else if (data.length == 32) {
            uint8 i = 0;
            while (i < 32 && data[i] != 0) {
                i++;
            }
            bytes memory bytesArray = new bytes(i);
            for (i = 0; i < 32 && data[i] != 0; i++) {
                bytesArray[i] = data[i];
            }
            return string(bytesArray);
        } else {
            return "???";
        }
    }

    /// @notice Provides a safe ERC20.symbol version which returns '???' as fallback string.
    /// @param token The address of the ERC-20 token contract.
    /// @return (string) Token symbol.
    function safeSymbol(address token) internal view returns (string memory) {
        require(isContract(token), "IntERC20: not a contract");

        (bool success, bytes memory data) = token.staticcall(
            abi.encodeWithSelector(IERC20Metadata.symbol.selector)
        );
        return success ? returnDataToString(data) : "???";
    }

    /// @notice Provides a safe ERC20.name version which returns '???' as fallback string.
    /// @param token The address of the ERC-20 token contract.
    /// @return (string) Token symbol.
    function safeName(address token) internal view returns (string memory) {
        require(isContract(token), "IntERC20: not a contract");

        (bool success, bytes memory data) = token.staticcall(
            abi.encodeWithSelector(IERC20Metadata.name.selector)
        );
        return success ? returnDataToString(data) : "???";
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

contract BridgeTokens {
    address internal constant BTC = 0xbdBFEBE240a4606119bC950Eec3e0Ed05719d739;

    address internal constant WETH = 0xbA8d9f4d5c14f2CC644CcC06bB298FbD6DaC349C;

    address internal constant USDC = 0xf3706E14c4aE1bd94f65909f9aB9e30D8C1b7B16;

    address internal constant USDT = 0xb306ee3d2092166cb942D1AE2210A7641f73c11F;

    //solhint-disable-next-line var-name-mixedcase
    address[] internal BRIDGE_TOKENS_ARRAY = [
        0xbdBFEBE240a4606119bC950Eec3e0Ed05719d739, // BTC
        0xbA8d9f4d5c14f2CC644CcC06bB298FbD6DaC349C, // WETH
        0xf3706E14c4aE1bd94f65909f9aB9e30D8C1b7B16, // USDC
        0xb306ee3d2092166cb942D1AE2210A7641f73c11F // USDT
    ];
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./lib/Rebase.sol";

struct Market {
    uint128 lastAccruedBlock;
    uint128 totalReserves;
    uint256 totalRewardsPerToken;
    Rebase loan;
}

struct Account {
    uint256 rewardDebt;
    uint128 balance;
    uint128 principal;
}

struct MailData {
    uint256 allowance;
    uint256 cash;
    uint128 balance;
    uint128 ltv;
    uint128 usdPrice;
    uint128 supply;
    uint128 borrow;
    uint128 totalSupply;
    uint128 totalElastic;
    uint128 totalBase;
    uint128 supplyRate;
    uint128 borrowRate;
}

struct MailMetadata {
    bool isDeployed;
    string name;
    string symbol;
    address token;
    address predictedAddress;
}

struct ERC20Metada {
    address token;
    string name;
    string symbol;
    uint256 decimals;
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
pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";

import "./IntMath.sol";

struct Rebase {
    uint128 elastic;
    uint128 base;
}

/**
 *
 * @dev This library provides a collection of functions to manipulate a base and elastic values saved in a Rebase struct.
 * In a pool context, the base represents the amount of tokens deposited or withdrawn from an investor.
 * The elastic value represents how the pool tokens performed over time by incurring losses or profits.
 * With this library, one can easily calculate how much loss or profit each investor incurred based on their tokens
 * invested.
 *
 * @notice We use the {SafeCast} Open Zeppelin library for safely converting from uint256 to uint128 memory storage efficiency.
 * Therefore, it is important to keep in mind of the upperbound limit number this library supports.
 *
 */
library RebaseLibrary {
    using SafeCast for uint256;
    using IntMath for uint256;

    /**
     * @dev Calculates a base value from an elastic value using the ratio of a {Rebase} struct.
     *
     * @param total {Rebase} struct, which represents a base/elastic pair.
     * @param elastic The new base is calculated from this elastic.
     * @param roundUp Rounding logic due to solidity always rounding down.
     * @return base The calculated base.
     *
     */
    function toBase(
        Rebase memory total,
        uint256 elastic,
        bool roundUp
    ) internal pure returns (uint256 base) {
        if (total.elastic == 0) {
            base = elastic;
        } else {
            base = elastic.mulDiv(total.base, total.elastic);
            if (roundUp && base.mulDiv(total.elastic, total.base) < elastic) {
                base += 1;
            }
        }
    }

    /**
     * @dev Calculates the elastic value from a base value using the ratio of a {Rebase} struct.
     *
     * @param total {Rebase} struct, which represents a base/elastic pair.
     * @param base The new base, which the new elastic will be calculated from.
     * @param roundUp Rounding logic due to solidity always rounding down.
     * @return elastic The calculated elastic.
     *
     */
    function toElastic(
        Rebase memory total,
        uint256 base,
        bool roundUp
    ) internal pure returns (uint256 elastic) {
        if (total.base == 0) {
            elastic = base;
        } else {
            elastic = base.mulDiv(total.elastic, total.base);
            if (roundUp && elastic.mulDiv(total.base, total.elastic) < base) {
                elastic += 1;
            }
        }
    }

    /**
     * @dev Calculates new values to a {Rebase} pair by incrementing the elastic value.
     * This function maintains the ratio of the current pair.
     *
     * @param total {Rebase} struct which represents a base/elastic pair.
     * @param elastic The new elastic to be added to the pair.
     * A new base will be calculated based on the new elastic using {toBase} function.
     * @param roundUp Rounding logic due to solidity always rounding down.
     * @return (total, base) A pair of the new {Rebase} pair values and new calculated base.
     *
     */
    function add(
        Rebase memory total,
        uint256 elastic,
        bool roundUp
    ) internal pure returns (Rebase memory, uint256 base) {
        base = toBase(total, elastic, roundUp);
        total.elastic += elastic.toUint128();
        total.base += base.toUint128();
        return (total, base);
    }

    /**
     * @dev Calculates new values to a {Rebase} pair by reducing the base.
     * This function maintains the ratio of the current pair.
     *
     * @param total {Rebase} struct, which represents a base/elastic pair.
     * @param base The number to be subtracted from the base.
     * The new elastic will be calculated based on the new base value via the {toElastic} function.
     * @param roundUp Rounding logic due to solidity always rounding down.
     * @return (total, elastic) A pair of the new {Rebase} pair values and the new elastic based on the updated base.
     *
     */
    function sub(
        Rebase memory total,
        uint256 base,
        bool roundUp
    ) internal pure returns (Rebase memory, uint256 elastic) {
        elastic = toElastic(total, base, roundUp);
        total.elastic -= elastic.toUint128();
        total.base -= base.toUint128();
        return (total, elastic);
    }

    /**
     * @dev Increases the base and elastic from a {Rebase} pair without keeping a specific ratio.
     *
     * @param total {Rebase} struct which represents a base/elastic pair that will be updated.
     * @param base The value to be added to the `total.base`.
     * @param elastic The value to be added to the `total.elastic`.
     * @return total The new {Rebase} pair calculated by adding the `base` and `elastic` values.
     *
     */
    function add(
        Rebase memory total,
        uint256 base,
        uint256 elastic
    ) internal pure returns (Rebase memory) {
        total.base += base.toUint128();
        total.elastic += elastic.toUint128();
        return total;
    }

    /**
     * @dev Decreases the base and elastic from a {Rebase} pair without keeping a specific ratio.
     *
     * @param total The base/elastic pair that will be updated.
     * @param base The value to be decreased from the `total.base`.
     * @param elastic The value to be decreased from the `total.elastic`.
     * @return total The new {Rebase} calculated by decreasing the base and pair from `total`.
     *
     */
    function sub(
        Rebase memory total,
        uint256 base,
        uint256 elastic
    ) internal pure returns (Rebase memory) {
        total.base -= base.toUint128();
        total.elastic -= elastic.toUint128();
        return total;
    }

    /**
     * @dev Adds elastic to a {Rebase} pair.
     *
     * @notice The `total` parameter is saved in storage. This will update the global state of the caller contract.
     *
     * @param total The {Rebase} struct, which will have its' elastic increased.
     * @param elastic The value to be added to the elastic of `total`.
     * @return newElastic The new elastic value after reducing `elastic` from `total.elastic`.
     *
     */
    function addElastic(Rebase storage total, uint256 elastic)
        internal
        returns (uint256 newElastic)
    {
        newElastic = total.elastic += elastic.toUint128();
    }

    /**
     * @dev Reduces the elastic of a {Rebase} pair.
     *
     * @notice The `total` parameter is saved in storage. The caller contract will have its' storage updated.
     *
     * @param total The {Rebase} struct to be updated.
     * @param elastic The value to be removed from the `total` elastic.
     * @return newElastic The new elastic after decreasing `elastic` from `total.elastic`.
     *
     */
    function subElastic(Rebase storage total, uint256 elastic)
        internal
        returns (uint256 newElastic)
    {
        newElastic = total.elastic -= elastic.toUint128();
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