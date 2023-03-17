/**
 *Submitted for verification at Etherscan.io on 2023-03-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
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
    function tryDiv(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
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

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

interface IVaultInterface {
    function execute(
        address,
        bytes memory
    ) external payable returns (bytes memory);
}

interface IParaSpacePool {
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
        //timestamp of last update
        uint40 lastUpdateTimestamp;
        //the id of the reserve. Represents the position in the list of the active reserves
        uint16 id;
        //xToken address
        address xTokenAddress;
        //variableDebtToken address
        address variableDebtTokenAddress;
        //address of the interest rate strategy
        address interestRateStrategyAddress;
        //address of the auction strategy
        address auctionStrategyAddress;
        //the current treasury balance, scaled
        uint128 accruedToTreasury;
    }

    struct ReserveConfigurationMap {
        uint256 data;
    }

    function getUserAccountData(
        address user
    )
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

    function getReserveData(
        address asset
    ) external view returns (ReserveData memory);
}

interface IparaSpaceStrategyInterface {
    function getWETHAddress() external view returns (address);

    function state() external view returns (address);

    function getPoolAddress() external view returns (address);

    function getPWETHAddress() external view returns (address);
}

interface IparaSpaceStatusInterface {
    function getLastTime(address vault) external view returns (uint256);
}

contract ParaSpaceSupplyMonitor {
    using SafeMath for uint256;
    address public owner;
    address public paraSpaceStrategy;
    address public poolCore;
    address public WETH;
    address public pWETH;
    address public vaultState;

    constructor(address _owner) {
        owner = _owner;
        paraSpaceStrategy = 0xA58e39c5B8e50b2fC3D83715837F79AAF79E0Bec; //0xA58e39c5B8e50b2fC3D83715837F79AAF79E0Bec
        poolCore = IparaSpaceStrategyInterface(paraSpaceStrategy)
            .getPoolAddress(); //0x638a98BBB92a7582d07C52ff407D49664DC8b3Ee
        WETH = IparaSpaceStrategyInterface(paraSpaceStrategy).getWETHAddress();
        pWETH = IparaSpaceStrategyInterface(paraSpaceStrategy)
            .getPWETHAddress(); //0xaA4b6506493582f169C9329AC0Da99fff23c2911
        vaultState = IparaSpaceStrategyInterface(paraSpaceStrategy).state();
    }

    function setParaSpaceStrategy(address _paraSpaceStrategy) external {
        require(msg.sender == owner, " only owner set  Para Space Strategy");
        paraSpaceStrategy = _paraSpaceStrategy;
    }

    function isParaSpaceWethLiquidityInsufficient(
        uint256 _wEthAmountThreshold
    ) internal view returns (bool) {
        uint256 _wEthCash; // 1e18
        _wEthCash = IERC20(WETH).balanceOf(pWETH);
        if (_wEthAmountThreshold >= _wEthCash) {
            return true;
        }
        return false;
    }

    function isParaSpaceExceedBorrwRateThreshold(
        uint128 _ethBorrowRate
    ) internal view returns (bool) {
        uint128 _currentEthBorrowRate; //_ethBorrowRate 1e25
        IParaSpacePool.ReserveData memory reserveData;
        reserveData = IParaSpacePool(poolCore).getReserveData(WETH);
        _currentEthBorrowRate = reserveData.currentVariableBorrowRate;
        if (_currentEthBorrowRate >= _ethBorrowRate) {
            return true;
        }
        return false;
    }

    function getParaSpaceMarketRateAndLiquidity(
        address _underlying
    ) external view returns (uint256, uint256, uint256) {
        uint128 _currentBorrowRate; //_ethBorrowRate 1e25
        uint128 _currentLiquidityRate; //_ethLiquidityRate 1e25
        uint256 _Cash; // 1e18
        address _aToken;
        IParaSpacePool.ReserveData memory reserveData;
        reserveData = IParaSpacePool(poolCore).getReserveData(_underlying);
        _currentBorrowRate = reserveData.currentVariableBorrowRate;
        _currentLiquidityRate = reserveData.currentLiquidityRate;
        _aToken = reserveData.xTokenAddress;
        _Cash = IERC20(_underlying).balanceOf(_aToken);
        return (_currentLiquidityRate, _currentBorrowRate, _Cash);
    }

    function hasSupplyWethTokens(address _vault) internal view returns (bool) {
        uint256 aTokenAoumnt;
        aTokenAoumnt = IERC20(pWETH).balanceOf(_vault);

        if (aTokenAoumnt > 0) {
            return true;
        }
        return false;
    }

    function getPwethV3PoolLiquidityInternal() internal view returns (uint256) {
        uint256 _balance;
        _balance = IERC20(WETH).balanceOf(pWETH);
        return _balance;
    }

    function getEthBalance(address vault) external view returns (uint256) {
        return address(vault).balance;
    }

    function getEthBalanceInternal(
        address vault
    ) internal view returns (uint256) {
        return address(vault).balance;
    }

    function getVaultExitLastTimeInternal(
        address vault
    ) internal view returns (uint256) {
        uint256 lastestTime;
        lastestTime = IparaSpaceStatusInterface(vaultState).getLastTime(vault);
        return lastestTime;
    }

    function getVaultAllowedEnterTime(
        address vault,
        uint256 interval
    ) external view returns (uint256) {
        uint256 lastestTime;
        uint256 enterTime;
        lastestTime = IparaSpaceStatusInterface(vaultState).getLastTime(vault);
        enterTime = lastestTime + interval;
        return enterTime;
    }

    function isVaultAllowedEnterPeriod(
        address vault,
        uint256 interval
    ) external view returns (bool) {
        uint256 lastestTime;
        uint256 enterTime;
        lastestTime = IparaSpaceStatusInterface(vaultState).getLastTime(vault);
        enterTime = lastestTime + interval;
        return block.timestamp >= enterTime;
    }

    function encodeEnterInput(
        uint256 amount
    ) internal pure returns (bytes memory encodedInput) {
        return abi.encodeWithSignature("enter(uint256)", amount);
    }

    function encodeExitInput()
        internal
        pure
        returns (bytes memory encodedInput)
    {
        return abi.encodeWithSignature("exit()");
    }

    function executeExit(
        address _vault
    ) internal view returns (bool canExec, bytes memory execPayload) {
        bytes memory args = encodeExitInput();
        execPayload = abi.encodeWithSelector(
            IVaultInterface(_vault).execute.selector,
            paraSpaceStrategy,
            args
        );
        return (true, execPayload);
    }

    function executeEnter(
        address _vault
    ) internal view returns (bool canExec, bytes memory execPayload) {
        uint256 amount;
        amount = address(_vault).balance;
        bytes memory args = encodeEnterInput(amount);
        execPayload = abi.encodeWithSelector(
            IVaultInterface(_vault).execute.selector,
            paraSpaceStrategy,
            args
        );
        return (true, execPayload);
    }

    function checker(
        address _vault,
        uint256 _wEthCashThreshold,
        uint256 _vaultAllowedEnterEthBalanceThreshold,
        uint256 _vaultAllowedEnterWethCashThreshold,
        uint256 _interval
    ) external view returns (bool canExec, bytes memory execPayload) {
        uint256 _vaultEthCash;
        uint256 _vaultExitLastTime;
        uint256 _poolWethCash;
        _vaultEthCash = getEthBalanceInternal(_vault);
        _vaultExitLastTime = getVaultExitLastTimeInternal(_vault);
        _poolWethCash = getPwethV3PoolLiquidityInternal();
        if (hasSupplyWethTokens(_vault)) {
            if (isParaSpaceWethLiquidityInsufficient(_wEthCashThreshold)) {
                return executeExit(_vault);
            }
        }
        if (
            _vaultEthCash >= _vaultAllowedEnterEthBalanceThreshold &&
            _poolWethCash >= _vaultAllowedEnterWethCashThreshold &&
            block.timestamp >= _vaultExitLastTime + _interval
        ) {
            return executeEnter(_vault);
        }

        return (false, bytes("monitor is ok"));
    }
}