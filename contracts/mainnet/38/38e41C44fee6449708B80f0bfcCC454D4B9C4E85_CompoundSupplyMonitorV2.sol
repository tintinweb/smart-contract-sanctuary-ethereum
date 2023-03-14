/**
 *Submitted for verification at Etherscan.io on 2023-03-14
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

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

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
            uint256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

interface IVaultInterface {
    function execute(
        address,
        bytes memory
    ) external payable returns (bytes memory);
}

interface IComet {
    struct TotalsCollateral {
        uint128 totalSupplyAsset;
        uint128 _reserved;
    }

    struct UserBasic {
        int104 principal;
        uint64 baseTrackingIndex;
        uint64 baseTrackingAccrued;
        uint16 assetsIn;
        uint8 _reserved;
    }

    struct UserCollateral {
        uint128 balance;
        uint128 _reserved;
    }

    function baseToken() external view returns (address);

    function supply(address asset, uint256 amount) external;

    function withdraw(address asset, uint256 amount) external;

    function totalsCollateral(
        address asset
    ) external view returns (TotalsCollateral memory);

    function userBasic(
        address account
    ) external view returns (UserBasic memory);

    function userCollateral(
        address account,
        address asset
    ) external view returns (UserCollateral memory);
}

interface IcometStrategyInterface {
    function WETH() external view returns (address);

    function comet() external view returns (address);

    function state() external view returns (address);
}

interface IcometStatusInterface {
    function getLastTime(address vault) external view returns (uint256);
}

contract CompoundSupplyMonitorV2 {
    using SafeMath for uint256;
    address public owner;
    address public compoundStrategy;
    address public WETH;
    address public pool;
    address public vaultState;

    constructor(address _owner) {
        owner = _owner;
        compoundStrategy = 0x8C93468cCF7072b01BD71D7372312F955CDa5B5F; //0x8C93468cCF7072b01BD71D7372312F955CDa5B5F
        WETH = IcometStrategyInterface(compoundStrategy).WETH();
        pool = IcometStrategyInterface(compoundStrategy).comet();
        vaultState = IcometStrategyInterface(compoundStrategy).state();
    }

    function setCompoundStrategy(address _compoundStrategy) external {
        require(msg.sender == owner, " only owner set compound Strategy");
        compoundStrategy = _compoundStrategy;
    }

    function getCTokenLiquidity(
        address underlying,
        address cToken
    ) external view returns (uint256) {
        uint256 _balance;
        _balance = IERC20(underlying).balanceOf(cToken);
        return _balance;
    }

    function getCwethV3PoolLiquidityInternal() internal view returns (uint256) {
        uint256 _balance;
        _balance = IERC20(WETH).balanceOf(pool);
        return _balance;
    }

    function isCompoundV3WethLiquidityInsufficient(
        uint256 _WethAmountThreshold
    ) internal view returns (bool) {
        uint256 _wEthCash; // 1e18
        _wEthCash = getCwethV3PoolLiquidityInternal();

        if (_WethAmountThreshold >= _wEthCash) {
            return true;
        }
        return false;
    }

    function hasSupplyWETH(address _vault) internal view returns (bool) {
        /*
            struct UserBasic {
            int104 principal;
            uint64 baseTrackingIndex;
            uint64 baseTrackingAccrued;
            uint16 assetsIn;
            uint8 _reserved;
        }

            */
        IComet.UserBasic memory _userBasic = IComet(pool).userBasic(_vault);
        if (_userBasic.principal > 0) {
            return true;
        }
        return false;
    }

    function getEthBalance(address vault) external view returns (uint256) {
        return address(vault).balance;
    }

    function getEthBalanceInternal(
        address vault
    ) internal view returns (uint256) {
        return address(vault).balance;
    }

    function getUserBasic(address _vault) external view returns (int104) {
        /*
            struct UserBasic {
            int104 principal;
            uint64 baseTrackingIndex;
            uint64 baseTrackingAccrued;
            uint16 assetsIn;
            uint8 _reserved;
            }

            */

        IComet.UserBasic memory _userBasic = IComet(pool).userBasic(_vault);
        return _userBasic.principal;
    }

    function getBaseTokenBalance(
        address _pool,
        address _vault
    ) external view returns (uint256) {
        uint256 _balance;
        _balance = IERC20(_pool).balanceOf(_vault);
        return _balance;
    }

    function getUserCollateral(
        address _pool,
        address _vault,
        address _asset
    ) external view returns (uint128, uint128) {
        /*
    
            struct UserCollateral {
            uint128 balance;
            uint128 _reserved;
            }
            */

        IComet.UserCollateral memory _userCollateral = IComet(_pool)
            .userCollateral(_vault, _asset);

        return (_userCollateral.balance, _userCollateral._reserved);
    }

    function getVaultExitLastTimeInternal(
        address vault
    ) internal view returns (uint256) {
        uint256 lastestTime;
        lastestTime = IcometStatusInterface(vaultState).getLastTime(vault);
        return lastestTime;
    }

    function getVaultAllowedEnterTime(
        address vault,
        uint256 interval
    ) external view returns (uint256) {
        uint256 lastestTime;
        uint256 enterTime;
        lastestTime = IcometStatusInterface(vaultState).getLastTime(vault);
        enterTime = lastestTime + interval;
        return enterTime;
    }

    function isVaultAllowedEnterPeriod(
        address vault,
        uint256 interval
    ) external view returns (bool) {
        uint256 lastestTime;
        uint256 enterTime;
        lastestTime = IcometStatusInterface(vaultState).getLastTime(vault);
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
            compoundStrategy,
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
            compoundStrategy,
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
        _poolWethCash = getCwethV3PoolLiquidityInternal();
        if (hasSupplyWETH(_vault)) {
            if (isCompoundV3WethLiquidityInsufficient(_wEthCashThreshold)) {
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