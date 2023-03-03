/**
 *Submitted for verification at Etherscan.io on 2023-03-02
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

interface IVaultInterface {
    function execute(address, bytes memory)
        external
        payable
        returns (bytes memory);
}

interface IAavePool {
    struct ReserveData {
        //stores the reserve configuration
        ReserveConfigurationMap configuration;
        //the liquidity index. Expressed in ray
        uint128 liquidityIndex;
        //the current supply rate. Expressed in ray
        uint128 currentLiquidityRate;
        //variable borrow index. Expressed in ray
        uint128 variableBorrowIndex;
        //the current variable borrow rate. Expressed in ray
        uint128 currentVariableBorrowRate;
        //the current stable borrow rate. Expressed in ray
        uint128 currentStableBorrowRate;
        //timestamp of last update
        uint40 lastUpdateTimestamp;
        //the id of the reserve. Represents the position in the list of the active reserves
        uint16 id;
        //aToken address
        address aTokenAddress;
        //stableDebtToken address
        address stableDebtTokenAddress;
        //variableDebtToken address
        address variableDebtTokenAddress;
        //address of the interest rate strategy
        address interestRateStrategyAddress;
        //the current treasury balance, scaled
        uint128 accruedToTreasury;
        //the outstanding unbacked aTokens minted through the bridging feature
        uint128 unbacked;
        //the outstanding debt borrowed against this asset in isolation mode
        uint128 isolationModeTotalDebt;
    }

    struct ReserveConfigurationMap {
        uint256 data;
    }

    function getUserAccountData(address user)
        external
        view
        returns (
            uint256 totalCollateralBase,
            uint256 totalDebtBase,
            uint256 availableBorrowsBase,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        );

    function getReserveData(address asset)
        external
        view
        returns (ReserveData memory);
}

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
            uint256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

interface ICurveRegistry {
    function get_best_rate(
        address _from,
        address _to,
        uint256 _amount
    ) external view returns (address, uint256);
}

contract LidoAaveMonitorV2 {
    using SafeMath for uint256;
    address public owner;
    address public aavePool;
    address public lidoAaveLeverageStrategy;
    address public chainlinkStEthBaseEth;
    address public curveRegistry;
    address public curveStEthBaseEthPool;
    address public wstETH;
    address public stETH;
    address public wETH;
    address public ETH;
    mapping(address => bool) public whitelisted;

    constructor(address _owner) {
        owner = _owner;
        aavePool = 0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2; //0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2
        lidoAaveLeverageStrategy = 0xEaCE2ac2eBB0fA433217f077156b3928a52a9a7a; //0x9dD4eB7Fd0942DC4eB7F4E90f3Af58fB00303101
        chainlinkStEthBaseEth = 0x86392dC19c0b719886221c78AB11eb8Cf5c52812; //0x86392dC19c0b719886221c78AB11eb8Cf5c52812
        curveRegistry = 0x99a58482BD75cbab83b27EC03CA68fF489b5788f; //0x99a58482BD75cbab83b27EC03CA68fF489b5788f
        curveStEthBaseEthPool = 0xDC24316b9AE028F1497c275EB9192a3Ea0f67022; //0xDC24316b9AE028F1497c275EB9192a3Ea0f67022
        wstETH = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0; //0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0
        stETH = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84; //0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84
        wETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; //0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
        ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    }

    modifier onlyWhitelisted() {
        require(
            whitelisted[msg.sender] || msg.sender == owner,
            "exit all: Not whitelisted"
        );
        _;
    }

    function encodeExitInput()
        internal
        pure
        returns (bytes memory encodedInput)
    {
        return abi.encodeWithSignature("exit()");
    }

    function setWhitelist(address _account, bool _whitelist) external {
        require(msg.sender == owner, " only owner set whiteliste");
        whitelisted[_account] = _whitelist;
    }

    function setLidoAaveLeverageStrategy(address _lidoAaveLeverageStrategy) external {
        require(msg.sender == owner, " only owner set Lido Aave Leverage Strategy");
        lidoAaveLeverageStrategy = _lidoAaveLeverageStrategy;
    }

    function getHealthFactor(address _vault) internal view returns (uint256) {
        (, , , , , uint256 hf) = IAavePool(aavePool).getUserAccountData(_vault);
        return hf;
    }

    function getAaveHealthFactor(address _vault)
        external
        view
        returns (uint256)
    {
        (, , , , , uint256 hf) = IAavePool(aavePool).getUserAccountData(_vault);
        return hf;
    }

    function isAaveWstETHLiquidityInsufficient(uint256 _wstEthAmountThreshold)
        internal
        view
        returns (bool)
    {
        uint256 _wstEthCash; // 1e18
        address _aWstEthToken;
        IAavePool.ReserveData memory reserveData;
        reserveData = IAavePool(aavePool).getReserveData(wstETH);
        _aWstEthToken = reserveData.aTokenAddress;
        _wstEthCash = IERC20(wstETH).balanceOf(_aWstEthToken);
        if (_wstEthAmountThreshold >= _wstEthCash) {
            return true;
        }
        return false;
    }

    function isAaveExceedBorrwRateThreshold(uint128 _ethBorrowRate)
        internal
        view
        returns (bool)
    {
        uint128 _currentEthBorrowRate; //_ethBorrowRate 1e25
        IAavePool.ReserveData memory reserveData;
        reserveData = IAavePool(aavePool).getReserveData(wETH);
        _currentEthBorrowRate = reserveData.currentVariableBorrowRate;
        if (_currentEthBorrowRate >= _ethBorrowRate) {
            return true;
        }
        return false;
    }

    function getAaveMarketBorrowRateAndLiquidity(address _underlying)
        external
        view
        returns (uint256, uint256)
    {
        uint128 _currentBorrowRate; //_ethBorrowRate 1e25
        uint256 _Cash; // 1e18
        address _aToken;
        IAavePool.ReserveData memory reserveData;
        reserveData = IAavePool(aavePool).getReserveData(_underlying);
        _currentBorrowRate = reserveData.currentVariableBorrowRate;
        _aToken = reserveData.aTokenAddress;
        _Cash = IERC20(_underlying).balanceOf(_aToken);
        return (_currentBorrowRate, _Cash);
    }

    function hasAwstEthBalance(address _vault) internal view returns (bool) {
        uint256 aTokenAoumnt;
        address _aWstEthToken;
        IAavePool.ReserveData memory reserveData;
        reserveData = IAavePool(aavePool).getReserveData(wstETH);
        _aWstEthToken = reserveData.aTokenAddress;
        aTokenAoumnt = IERC20(_aWstEthToken).balanceOf(_vault);

        if (aTokenAoumnt > 0) {
            return true;
        }
        return false;
    }

    function hasSupplyAllTokens(address _vault) internal view returns (bool) {
        /*
        (
        uint256 totalCollateralBase,
        uint256 totalDebtBase,
        uint256 availableBorrowsBase,
        uint256 currentLiquidationThreshold,
        uint256 ltv,
        uint256 healthFactor
        )
        */
        (uint256 totalCollateralBase, , , , , ) = IAavePool(aavePool)
            .getUserAccountData(_vault);
        if (totalCollateralBase > 0) {
            return true;
        }
        return false;
    }

    function isCurveEthLiquidityInsufficient(uint256 _ethAmountThreshold)
        internal
        view
        returns (bool)
    {
        uint256 _ethAmount;
        _ethAmount = address(curveStEthBaseEthPool).balance;
        if (_ethAmount <= _ethAmountThreshold) {
            return true;
        }
        return false;
    }

    function getCurveEthLiquidity(address _pool)
        external
        view
        returns (uint256)
    {
        uint256 _ethAmount;
        _ethAmount = address(_pool).balance;
        return _ethAmount;
    }

    function isStEthPriceUnanchoredFromChainLink(uint256 _anchorPrice)
        internal
        view
        returns (bool)
    {
        /*
        (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
        )
        */
        (, uint256 _price, , , ) = AggregatorV3Interface(chainlinkStEthBaseEth)
            .latestRoundData();
        if (_price <= _anchorPrice) {
            return true;
        }
        return false;
    }

    function getPriceChainLink(address _chainlinkAggregator)
        external
        view
        returns (uint256)
    {
        /*
        (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
        )
        */
        (, uint256 _price, , , ) = AggregatorV3Interface(_chainlinkAggregator)
            .latestRoundData();
        return _price;
    }

    function isStEthPriceUnanchoredFromCurve(uint256 _anchorPrice)
        internal
        view
        returns (bool)
    {
        (, uint256 _price) = ICurveRegistry(curveRegistry).get_best_rate(
            stETH,
            ETH,
            1e18
        );
        if (_price <= _anchorPrice) {
            return true;
        }
        return false;
    }

    function getStEthBaseEthPriceCurve() external view returns (uint256) {
        (, uint256 _price) = ICurveRegistry(curveRegistry).get_best_rate(
            stETH,
            ETH,
            1e18
        );

        return _price;
    }

    function isStEthPriceUnanchoredFromAggregator(uint256 _anchorPrice)
        internal
        view
        returns (bool)
    {
        bool price1Status = isStEthPriceUnanchoredFromChainLink(_anchorPrice);
        bool price1Status2 = isStEthPriceUnanchoredFromCurve(_anchorPrice);
        if (price1Status || price1Status2) {
            return true;
        }
        return false;
    }

    function isStEthPriceDeviation(uint256 _priceDeviationRatio)
        internal
        view
        returns (bool)
    {
        uint256 _priceGap;
        uint256 _priceChainlink;
        uint256 _priceCurve;
        (, _priceChainlink, , , ) = AggregatorV3Interface(chainlinkStEthBaseEth)
            .latestRoundData();

        (, _priceCurve) = ICurveRegistry(curveRegistry).get_best_rate(
            stETH,
            ETH,
            1e18
        );

        if (!(_priceChainlink > 0) || !(_priceCurve > 0)) {
            return true;
        }

        if (_priceCurve >= _priceChainlink) {
            _priceGap = _priceCurve - _priceChainlink;
            if (
                _priceChainlink.mul(_priceDeviationRatio).div(10000) < _priceGap
            ) {
                return true;
            }
        } else {
            _priceGap = _priceChainlink - _priceCurve;
            if (
                _priceChainlink.mul(_priceDeviationRatio).div(10000) < _priceGap
            ) {
                return true;
            }
        }
        return false;
    }

    function getStEthPriceDeviationRatio() external view returns (uint256) {
        uint256 _priceGap;
        uint256 _priceChainlink;
        uint256 _priceCurve;
        uint256 _priceDeviationRatio;
        (, _priceChainlink, , , ) = AggregatorV3Interface(chainlinkStEthBaseEth)
            .latestRoundData();

        (, _priceCurve) = ICurveRegistry(curveRegistry).get_best_rate(
            stETH,
            ETH,
            1e18
        );

        if (!(_priceChainlink > 0) || !(_priceCurve > 0)) {
            return 0;
        }

        if (_priceCurve >= _priceChainlink) {
            _priceGap = _priceCurve - _priceChainlink;
            _priceDeviationRatio = _priceGap.mul(1e20).div(_priceChainlink);
            return _priceDeviationRatio;
        } else {
            _priceGap = _priceChainlink - _priceCurve;
            _priceDeviationRatio = _priceGap.mul(1e20).div(_priceChainlink);
            return _priceDeviationRatio;
        }
    }

    function isNotHealth(address _vault, uint256 _healthFactor)
        internal
        view
        returns (bool)
    {
        uint256 vault_hf;
        vault_hf = getHealthFactor(_vault);
        if (vault_hf <= _healthFactor) {
            return true;
        }
        return false;
    }

    function healthFactorRiskExit(address _vault, uint256 _healthFactor)
        external
        onlyWhitelisted
    {
        bytes memory data;
        uint256 _hf;
        _hf = getHealthFactor(_vault);
        data = encodeExitInput();
        if (_hf <= _healthFactor) {
            IVaultInterface(_vault).execute(lidoAaveLeverageStrategy, data);
        }
    }

    function anchoredPriceRiskExit(address _vault, uint256 _anchorPrice)
        external
        onlyWhitelisted
    {
        /*
        (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
        )
        */
        bytes memory data;
        data = encodeExitInput();
        (, uint256 _price, , , ) = AggregatorV3Interface(chainlinkStEthBaseEth)
            .latestRoundData();
        if (_price <= _anchorPrice) {
            IVaultInterface(_vault).execute(lidoAaveLeverageStrategy, data);
        }
    }

    function executeExit(address _vault)
        internal
        view
        returns (bool canExec, bytes memory execPayload)
    {
        bytes memory args = encodeExitInput();
        execPayload = abi.encodeWithSelector(
            IVaultInterface(_vault).execute.selector,
            lidoAaveLeverageStrategy,
            args
        );
        return (true, execPayload);
    }

    function checker(
        address _vault,
        uint256 _healthFactorThreshold,
        uint256 _anchorEthPriceThreshold,
        uint256 _ethCurveCashThreshold,
        uint256 _wstEthCashThreshold,
        uint128 _ethBorrowRateThreshold,
        uint256 _priceDeviationRatio
    ) external view returns (bool canExec, bytes memory execPayload) {
        if (hasSupplyAllTokens(_vault)) {
            if (isNotHealth(_vault, _healthFactorThreshold)) {
                return executeExit(_vault);
            }
            if (isStEthPriceDeviation(_priceDeviationRatio)) {
                return executeExit(_vault);
            }
            if (isAaveWstETHLiquidityInsufficient(_wstEthCashThreshold)) {
                return executeExit(_vault);
            }
            if (isAaveExceedBorrwRateThreshold(_ethBorrowRateThreshold)) {
                return executeExit(_vault);
            }
            if (isCurveEthLiquidityInsufficient(_ethCurveCashThreshold)) {
                return executeExit(_vault);
            }
            if (isStEthPriceUnanchoredFromChainLink(_anchorEthPriceThreshold)) {
                return executeExit(_vault);
            }
            if (isStEthPriceUnanchoredFromCurve(_anchorEthPriceThreshold)) {
                return executeExit(_vault);
            }
        }

        return (false, bytes("monitor is ok"));
    }
}