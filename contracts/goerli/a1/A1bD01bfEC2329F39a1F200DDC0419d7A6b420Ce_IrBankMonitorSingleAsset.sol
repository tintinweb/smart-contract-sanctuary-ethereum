/**
 *Submitted for verification at Etherscan.io on 2023-02-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        require(b > 0, errorMessage);
        return a / b;
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

interface CTokenInterface {
    function getCash() external view returns (uint256);

    function decimals() external view returns (uint8);

    function underlying() external view returns (address);
}

interface IrBankStrategyInterface {
    function pool() external view returns (address);
}

interface StakingRewardsInterface {
    function paused() external view returns (bool);
}

interface StakingRewardsHelperInterface {
    struct UserStaked {
        address stakingTokenAddress;
        uint256 balance;
    }

    function getUserStaked(address account)
        external
        view
        returns (UserStaked[] memory);

    function factory() external view returns (address);
}

interface StakingRewardsFactoryInterface {
    function getStakingToken(address underlying)
        external
        view
        returns (address);

    function getStakingRewards(address stakingToken)
        external
        view
        returns (address);
}

interface IVaultInterface {
    function execute(address, bytes memory)
        external
        payable
        returns (bytes memory);
}

interface IrBankOracleInterface {
    function getUnderlyingPrice(address cToken) external view returns (uint256);
}

interface IStdReference {
    /// A structure returned whenever someone requests for standard reference data.
    struct ReferenceData {
        uint256 rate; // base/quote exchange rate, multiplied by 1e18.
        uint256 lastUpdatedBase; // UNIX epoch of the last time when base price gets updated.
        uint256 lastUpdatedQuote; // UNIX epoch of the last time when quote price gets updated.
    }

    /// Returns the price data for the given base/quote pair. Revert if not available.
    function getReferenceData(string memory _base, string memory _quote)
        external
        view
        returns (ReferenceData memory);

    /// Similar to getReferenceData, but with multiple base/quote pairs at once.
    function getReferenceDataBulk(
        string[] memory _bases,
        string[] memory _quotes
    ) external view returns (ReferenceData[] memory);
}

contract IrBankMonitorSingleAsset {
    using SafeMath for uint256;
    address public irBankStrategy;
    address public stakeRewardsHelper;
    address public irbankOracle;
    address public bandOracle;
    address public owner;
    mapping(address => bool) public whitelisted;

    constructor(address _owner) {
        owner = _owner;
        irBankStrategy = 0x9Ff79fb606224D07c508A6f978e3A30f97F7C23d;//0x2bd1c1c279d9841E60499404b92627a382b28055
        //stakeRewardsHelper = 0x2FD46501682D90d55E97fbd702a87C39f587A44F; //0x970D6b8c1479ec2bfE5a82dC69caFe4003099bC0;
        irbankOracle = 0x65F19195e488B9C1A1Ac08ca115f197C992bC776; //0x2424C30E589Caea191C06F41d1f5b90348dbeD7d;
        bandOracle = 0x61704EFB8b8120c03C210cAC5f5193BF8c80852a; //0xDA7a001b254CD22e46d3eAB04d937489c93174C3;
    }

    modifier onlyWhitelisted() {
        require(
            whitelisted[msg.sender] || msg.sender == owner,
            "exit all: Not whitelisted"
        );
        _;
    }

    function _getIrBankUnderlyingPriceInternal(address pToken)
        internal
        view
        returns (uint256)
    {
        uint256 price;
        price = IrBankOracleInterface(irbankOracle).getUnderlyingPrice(pToken);
        return price;
    }

    function getIrBankUnderlyingPrice(address pToken)
        external
        view
        returns (uint256)
    {
        uint256 price;
        price = IrBankOracleInterface(irbankOracle).getUnderlyingPrice(pToken);
        return price;
    }

    function _getBandPriceInternal(
        string memory _base,
        string memory _quote,
        uint256 baseUnit
    ) internal view returns (uint256) {
        uint256 price;
        IStdReference.ReferenceData memory data = IStdReference(bandOracle)
            .getReferenceData(_base, _quote);
        price = data.rate.mul(1e18).div(baseUnit);
        return price;
    }

    function getBandPrice(
        string memory _base,
        string memory _quote,
        uint256 baseUnit
    ) external view returns (uint256) {
        uint256 price;
        IStdReference.ReferenceData memory data = IStdReference(bandOracle)
            .getReferenceData(_base, _quote);
        price = data.rate.mul(1e18).div(baseUnit);
        return price;
    }

    function isCompareOracleDeviate(
        address pToken,
        string memory underlyingSymbol,
        uint256 baseUnit,
        uint256 ratio
    ) internal view returns (bool) {
        uint256 irbankPrice;
        uint256 bandPrice;
        uint256 priceGap;

        irbankPrice = _getIrBankUnderlyingPriceInternal(pToken);
        bandPrice = _getBandPriceInternal(underlyingSymbol, "USD", baseUnit);
        if (!(bandPrice > 0)) {
            return true;
        }

        if (irbankPrice >= bandPrice) {
            priceGap = irbankPrice - bandPrice;
            if (bandPrice.mul(ratio).div(100) < priceGap) {
                return true;
            }
        } else {
            priceGap = bandPrice - irbankPrice;
            if (bandPrice.mul(ratio).div(100) < priceGap) {
                return true;
            }
        }
        return false;
    }

    function getOracleDeviate(
        address pToken,
        string memory underlyingSymbol,
        uint256 baseUnit,
        uint256 ratio
    ) external view returns (uint256, uint256) {
        uint256 irbankPrice;
        uint256 bandPrice;
        uint256 curentPriceGap;
        uint256 priceDeviationThreshold;

        irbankPrice = _getIrBankUnderlyingPriceInternal(pToken);
        bandPrice = _getBandPriceInternal(underlyingSymbol, "USD", baseUnit);
        if (!(bandPrice > 0)) {
            return (0, 0);
        }

        if (irbankPrice >= bandPrice) {
            curentPriceGap = irbankPrice - bandPrice;
            priceDeviationThreshold = bandPrice.mul(ratio).div(100);
            return (priceDeviationThreshold, curentPriceGap);
        } else {
            curentPriceGap = bandPrice - irbankPrice;
            priceDeviationThreshold = bandPrice.mul(ratio).div(100);
            return (priceDeviationThreshold, curentPriceGap);
        }
    }

    function _getCashInternal(address pToken) internal view returns (uint256) {
        uint256 cash;
        cash = CTokenInterface(pToken).getCash();
        return cash;
    }

    function getMarketCash(address pToken) external view returns (uint256) {
        uint256 cash;
        cash = CTokenInterface(pToken).getCash();
        return cash;
    }

    function isLiquidityInsufficient(address pToken, uint256 cashThreshold)
        internal
        view
        returns (bool)
    {
        bool cashThresholdStatus;
        cashThresholdStatus = _getCashInternal(pToken) <= cashThreshold;
        if (cashThresholdStatus) {
            return true;
        }
        return false;
    }

    function isPoolPaused(address stakerReward) internal view returns (bool) {
        bool pause;
        pause = StakingRewardsInterface(stakerReward).paused();
        return pause;
    }

    function hasStakedAmount(address account) internal view returns (bool) {
        /*
        struct UserStaked {
        address stakingTokenAddress;
        uint256 balance;
        }
   */
        StakingRewardsHelperInterface.UserStaked memory userStake;
        StakingRewardsHelperInterface.UserStaked[]
            memory userAllStakes = StakingRewardsHelperInterface(
                stakeRewardsHelper
            ).getUserStaked(account);
        for (uint256 i = 0; i < userAllStakes.length; i++) {
            userStake = userAllStakes[i];
            if (userStake.balance != 0) {
                return true;
            }
        }
        return false;
    }

    function getStakedAmount(address account)
        external
        view
        returns (StakingRewardsHelperInterface.UserStaked[] memory)
    {
        /*
        struct UserStaked {
        address stakingTokenAddress;
        uint256 balance;
        }
   */
        StakingRewardsHelperInterface.UserStaked[]
            memory userAllStakes = StakingRewardsHelperInterface(
                stakeRewardsHelper
            ).getUserStaked(account);
        return userAllStakes;
    }

    function encodeExitAllInputs()
        internal
        pure
        returns (bytes memory encodedInput)
    {
        return abi.encodeWithSignature("exitAll()");
    }

    function setWhitelist(address _account, bool _whitelist) external {
        require(msg.sender == owner, " only owner set whiteliste");
        whitelisted[_account] = _whitelist;
    }

    function executeExit(address _vault)
        internal
        view
        returns (bool canExec, bytes memory execPayload)
    {
        bytes memory args = encodeExitAllInputs();
        execPayload = abi.encodeWithSelector(
            IVaultInterface(_vault).execute.selector,
            irBankStrategy,
            args
        );
        return (true, execPayload);
    }

    function checker(
        address _vault,
        address _underlying,
        uint256 _cashThreshold,
        string memory _underlyingSymbol,
        uint256 _ratio
    ) external view returns (bool canExec, bytes memory execPayload) {
        address _stakeRewardsHelper;
        address _factory;
        address _pToken;
        address _stakeReward;
        uint256 _decimals;
        uint256 _baseUnit;
        _stakeRewardsHelper = IrBankStrategyInterface(irBankStrategy).pool();
        _factory = StakingRewardsHelperInterface(_stakeRewardsHelper).factory();
        _pToken = StakingRewardsFactoryInterface(_factory).getStakingToken(
            _underlying
        );
        _stakeReward = StakingRewardsFactoryInterface(_factory)
            .getStakingRewards(_pToken);
        _decimals = IERC20(_underlying).decimals();
        _baseUnit = 10**_decimals;
        if (hasStakedAmount(_vault)) {
            if (isLiquidityInsufficient(_pToken, _cashThreshold)) {
                return executeExit(_vault);
            }
            if (isPoolPaused(_stakeReward)) {
                return executeExit(_vault);
            }
            if (
                isCompareOracleDeviate(
                    _pToken,
                    _underlyingSymbol,
                    _baseUnit,
                    _ratio
                )
            ) {
                return executeExit(_vault);
            }
        }
        canExec = false;
        return (canExec, bytes("monitor is ok!"));
    }
}