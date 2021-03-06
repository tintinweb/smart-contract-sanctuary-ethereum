/**
 *Submitted for verification at Etherscan.io on 2021-05-18
*/

/*
   ____            __   __        __   _
  / __/__ __ ___  / /_ / /  ___  / /_ (_)__ __
 _\ \ / // // _ \/ __// _ \/ -_)/ __// / \ \ /
/___/ \_, //_//_/\__//_//_/\__/ \__//_/ /_\_\
     /___/

* Synthetix: CollateralStakingState.sol
*
* Latest source (may be newer): https://github.com/Synthetixio/synthetix/blob/master/contracts/CollateralStakingState.sol
* Docs: https://docs.synthetix.io/contracts/CollateralStakingState
*
* Contract Dependencies: 
*	- ICollateralStakingState
*	- Owned
*	- State
* Libraries: 
*	- DataTypesLib
*	- SafeDecimalMath
*	- SafeMath
*
* MIT License
* ===========
*
* Copyright (c) 2021 Synthetix
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*/



pragma solidity ^0.5.16;


// https://docs.synthetix.io/contracts/source/contracts/owned
contract Owned {
    address public owner;
    address public nominatedOwner;

    constructor(address _owner) public {
        require(_owner != address(0), "Owner address cannot be 0");
        owner = _owner;
        emit OwnerChanged(address(0), _owner);
    }

    function nominateNewOwner(address _owner) external onlyOwner {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    function acceptOwnership() external {
        require(msg.sender == nominatedOwner, "You must be nominated before you can accept ownership");
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    modifier onlyOwner {
        _onlyOwner();
        _;
    }

    function _onlyOwner() private view {
        require(msg.sender == owner, "Only the contract owner may perform this action");
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}


// Inheritance


// https://docs.synthetix.io/contracts/source/contracts/state
contract State is Owned {
    // the address of the contract that can modify variables
    // this can only be changed by the owner of this contract
    address public associatedContract;

    constructor(address _associatedContract) internal {
        // This contract is abstract, and thus cannot be instantiated directly
        require(owner != address(0), "Owner must be set");

        associatedContract = _associatedContract;
        emit AssociatedContractUpdated(_associatedContract);
    }

    /* ========== SETTERS ========== */

    // Change the associated contract to a new address
    function setAssociatedContract(address _associatedContract) external onlyOwner {
        associatedContract = _associatedContract;
        emit AssociatedContractUpdated(_associatedContract);
    }

    /* ========== MODIFIERS ========== */

    modifier onlyAssociatedContract {
        require(msg.sender == associatedContract, "Only the associated contract can perform this action");
        _;
    }

    /* ========== EVENTS ========== */

    event AssociatedContractUpdated(address associatedContract);
}


/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
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
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}


// Libraries


// https://docs.synthetix.io/contracts/source/libraries/safedecimalmath
library SafeDecimalMath {
    using SafeMath for uint;

    /* Number of decimal places in the representations. */
    uint8 public constant decimals = 18;
    uint8 public constant highPrecisionDecimals = 27;

    /* The number representing 1.0. */
    uint public constant UNIT = 10**uint(decimals);

    /* The number representing 1.0 for higher fidelity numbers. */
    uint public constant PRECISE_UNIT = 10**uint(highPrecisionDecimals);
    uint private constant UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR = 10**uint(highPrecisionDecimals - decimals);

    /**
     * @return Provides an interface to UNIT.
     */
    function unit() external pure returns (uint) {
        return UNIT;
    }

    /**
     * @return Provides an interface to PRECISE_UNIT.
     */
    function preciseUnit() external pure returns (uint) {
        return PRECISE_UNIT;
    }

    /**
     * @return The result of multiplying x and y, interpreting the operands as fixed-point
     * decimals.
     *
     * @dev A unit factor is divided out after the product of x and y is evaluated,
     * so that product must be less than 2**256. As this is an integer division,
     * the internal division always rounds down. This helps save on gas. Rounding
     * is more expensive on gas.
     */
    function multiplyDecimal(uint x, uint y) internal pure returns (uint) {
        /* Divide by UNIT to remove the extra factor introduced by the product. */
        return x.mul(y) / UNIT;
    }

    /**
     * @return The result of safely multiplying x and y, interpreting the operands
     * as fixed-point decimals of the specified precision unit.
     *
     * @dev The operands should be in the form of a the specified unit factor which will be
     * divided out after the product of x and y is evaluated, so that product must be
     * less than 2**256.
     *
     * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
     * Rounding is useful when you need to retain fidelity for small decimal numbers
     * (eg. small fractions or percentages).
     */
    function _multiplyDecimalRound(
        uint x,
        uint y,
        uint precisionUnit
    ) private pure returns (uint) {
        /* Divide by UNIT to remove the extra factor introduced by the product. */
        uint quotientTimesTen = x.mul(y) / (precisionUnit / 10);

        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen += 10;
        }

        return quotientTimesTen / 10;
    }

    /**
     * @return The result of safely multiplying x and y, interpreting the operands
     * as fixed-point decimals of a precise unit.
     *
     * @dev The operands should be in the precise unit factor which will be
     * divided out after the product of x and y is evaluated, so that product must be
     * less than 2**256.
     *
     * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
     * Rounding is useful when you need to retain fidelity for small decimal numbers
     * (eg. small fractions or percentages).
     */
    function multiplyDecimalRoundPrecise(uint x, uint y) internal pure returns (uint) {
        return _multiplyDecimalRound(x, y, PRECISE_UNIT);
    }

    /**
     * @return The result of safely multiplying x and y, interpreting the operands
     * as fixed-point decimals of a standard unit.
     *
     * @dev The operands should be in the standard unit factor which will be
     * divided out after the product of x and y is evaluated, so that product must be
     * less than 2**256.
     *
     * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
     * Rounding is useful when you need to retain fidelity for small decimal numbers
     * (eg. small fractions or percentages).
     */
    function multiplyDecimalRound(uint x, uint y) internal pure returns (uint) {
        return _multiplyDecimalRound(x, y, UNIT);
    }

    /**
     * @return The result of safely dividing x and y. The return value is a high
     * precision decimal.
     *
     * @dev y is divided after the product of x and the standard precision unit
     * is evaluated, so the product of x and UNIT must be less than 2**256. As
     * this is an integer division, the result is always rounded down.
     * This helps save on gas. Rounding is more expensive on gas.
     */
    function divideDecimal(uint x, uint y) internal pure returns (uint) {
        /* Reintroduce the UNIT factor that will be divided out by y. */
        return x.mul(UNIT).div(y);
    }

    /**
     * @return The result of safely dividing x and y. The return value is as a rounded
     * decimal in the precision unit specified in the parameter.
     *
     * @dev y is divided after the product of x and the specified precision unit
     * is evaluated, so the product of x and the specified precision unit must
     * be less than 2**256. The result is rounded to the nearest increment.
     */
    function _divideDecimalRound(
        uint x,
        uint y,
        uint precisionUnit
    ) private pure returns (uint) {
        uint resultTimesTen = x.mul(precisionUnit * 10).div(y);

        if (resultTimesTen % 10 >= 5) {
            resultTimesTen += 10;
        }

        return resultTimesTen / 10;
    }

    /**
     * @return The result of safely dividing x and y. The return value is as a rounded
     * standard precision decimal.
     *
     * @dev y is divided after the product of x and the standard precision unit
     * is evaluated, so the product of x and the standard precision unit must
     * be less than 2**256. The result is rounded to the nearest increment.
     */
    function divideDecimalRound(uint x, uint y) internal pure returns (uint) {
        return _divideDecimalRound(x, y, UNIT);
    }

    /**
     * @return The result of safely dividing x and y. The return value is as a rounded
     * high precision decimal.
     *
     * @dev y is divided after the product of x and the high precision unit
     * is evaluated, so the product of x and the high precision unit must
     * be less than 2**256. The result is rounded to the nearest increment.
     */
    function divideDecimalRoundPrecise(uint x, uint y) internal pure returns (uint) {
        return _divideDecimalRound(x, y, PRECISE_UNIT);
    }

    /**
     * @dev Convert a standard decimal representation to a high precision one.
     */
    function decimalToPreciseDecimal(uint i) internal pure returns (uint) {
        return i.mul(UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR);
    }

    /**
     * @dev Convert a high precision decimal to a standard decimal representation.
     */
    function preciseDecimalToDecimal(uint i) internal pure returns (uint) {
        uint quotientTimesTen = i / (UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR / 10);

        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen += 10;
        }

        return quotientTimesTen / 10;
    }
}


pragma experimental ABIEncoderV2;

library DataTypesLib {
    struct Loan {
        //  Acccount that created the loan
        address account;
        //  Amount of collateral deposited
        uint collateral;
        //  Amount of synths borrowed
        uint amount;
    }

    struct Fund {
        uint debt;
        uint donation;
    }

    struct Staking {
        //V1 + V2
        uint lastCollaterals;
        uint lastRewardPerToken;
        //V2
        uint collaterals;
        uint round;
        //??????
        uint rewards;
    }

    //aave
    struct ReserveConfigurationMap {
        uint256 data;
    }

    struct UserConfigurationMap {
        uint256 data;
    }

    struct ReserveData {
        //stores the reserve configuration
        ReserveConfigurationMap configuration;
        //the liquidity index. Expressed in ray
        uint128 liquidityIndex;
        //variable borrow index. Expressed in ray
        uint128 variableBorrowIndex;
        //the current supply rate. Expressed in ray
        uint128 currentLiquidityRate;
        //the current variable borrow rate. Expressed in ray
        uint128 currentVariableBorrowRate;
        //the current stable borrow rate. Expressed in ray
        uint128 currentStableBorrowRate;
        uint40 lastUpdateTimestamp;
        //tokens addresses
        address aTokenAddress;
        address stableDebtTokenAddress;
        address variableDebtTokenAddress;
        //address of the interest rate strategy
        address interestRateStrategyAddress;
        //the id of the reserve. Represents the position in the list of the active reserves
        uint8 id;
    }
}


interface ICollateralStakingState {
    function token() external view returns (address);

    function interestPool() external view returns (address);

    function canStaking() external view returns (bool);

    function totalCollateral() external view returns (uint);

    function getStaking(address account) external view returns (DataTypesLib.Staking memory);

    function surplus() external view returns (uint);

    function earned(uint total, address account) external view returns (uint);

    function calExtract(uint collateral, uint reward) external returns (uint);

    function extractUpdate(
        address account,
        uint amount,
        uint reward
    ) external returns (uint, uint);

    function pledgeUpdate(
        address account,
        uint collateral,
        uint reward
    ) external;

    function updateLastRecord(uint total) external;

    function updateLastBlockAndRewardPerToken(uint total) external;

    function savingsUpdate() external;
}


// Inheritance


contract CollateralStakingState is Owned, State, ICollateralStakingState {
    using SafeMath for uint;

    //???????????????
    address public token;
    //?????????
    address public interestPool;
    //????????????staking
    bool public canStaking;
    //????????????
    uint public totalCollateral;
    //????????????????????????token?????????????????????
    uint private lastRewardPerTokenStored;
    //????????????????????????
    uint private lastUpdateBlock;
    //???????????????+????????????
    uint private lastRecord;
    //???????????????????????????
    uint private unsecured;
    //
    uint private withdrawReward;
    //????????????
    uint private round;
    //???????????????????????????
    mapping(uint => uint) private roundRewardPerToken;
    //?????????staking??????
    mapping(address => DataTypesLib.Staking) public staking;

    constructor(
        address _owner,
        address _associatedContract,
        address _token,
        bool _canStaking,
        address _interestPool
    ) public Owned(_owner) State(_associatedContract) {
        token = _token;
        canStaking = _canStaking;
        interestPool = _interestPool;
    }

    /*
     * @notion ????????????????????????????????????
     *
     */
    function lastReward(uint total) internal view returns (uint) {
        //???????????????0???????????????????????????
        if (total == 0) {
            return 0;
        }
        //?????????????????????0???????????????????????????
        uint lastTotal = lastRecord;
        if (lastTotal == 0) {
            lastTotal = totalCollateral;
        }
        return total.sub(lastTotal);
    }

    /*
     * @notion ???????????????token?????????????????????
     *
     */
    function rewardPerToken(uint total) internal view returns (uint) {
        //?????????0??????????????????????????????????????????????????????????????????
        if (totalCollateral == 0 || block.number <= lastUpdateBlock) {
            return lastRewardPerTokenStored;
        }
        //??????token???????????? = ?????????token???????????? + (??????????????? / ???token)
        return lastRewardPerTokenStored.add(lastReward(total).mul(1e18).div(totalCollateral));
    }

    function earned(uint total, address account) public view returns (uint) {
        DataTypesLib.Staking memory s = staking[account];
        uint currentRewardPerToken = rewardPerToken(total);
        if (currentRewardPerToken == 0 || currentRewardPerToken <= s.lastRewardPerToken) {
            return s.rewards;
        }
        uint lastRewards =
            s.lastCollaterals == 0
                ? s.rewards
                : s.lastCollaterals.mul(currentRewardPerToken.sub(s.lastRewardPerToken)).div(1e18).add(s.rewards);
        //???????????????????????????
        if (s.round > 0 && roundRewardPerToken[s.round] == 0) {
            return lastRewards;
        }
        //?????????round=0???????????????????????????????????????currentRewardPerToken???0
        return s.collaterals.mul(currentRewardPerToken.sub(roundRewardPerToken[s.round])).div(1e18).add(lastRewards);
    }

    function updateLastBlockAndRewardPerToken(uint total) public onlyAssociatedContract {
        lastRewardPerTokenStored = rewardPerToken(total);
        lastUpdateBlock = block.number;
    }

    function updateLastRecord(uint total) public onlyAssociatedContract {
        lastRecord = total;
    }

    /**
     * V2??????(??????????????????)
     * ??????????????????????????????????????????????????????????????????????????????????????????rewardPerToken??????????????????????????????????????????????????????round
     * ???????????????????????????????????????rewardPerToken????????????????????????rewardPerToken????????????1
     * ????????????????????????????????????aave?????????????????????????????????????????????????????????????????????????????????
     * ????????????????????????????????????????????????aave????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????
     */

    /**
     * unsecured: ????????????????????????
     * totalCollateral: ????????????????????????
     * collateral: ?????????????????????????????????
     * reward: ????????????????????????
     * totalWithdraw: ??????????????? + ????????????
     * 1. unsecured???????????????unsecured???????????????
     *  totalCollateral:1000 | unsecured:2000 | collateral:1000 | reward:100 | totalWithdraw:(?????????:collateral+reward):1100
     *   |---> unsecured?????????????????????unsecured???1100?????????1000????????????100?????????
     *
     * 2. unsecured?????????????????????????????????????????????
     *  totalCollateral:1000 | unsecured:900 | collateral:1000 | reward:100 | totalWithdraw(?????????:collateral+reward):1100
     *   |---> ????????????1100???unsecured???????????????unsecured???900?????????200????????????totalCollateral???????????????
     *   |---> ??????200??????100????????????????????????totalCollateral?????????100???totalCollateral??????900
     *
     * 3. unsecured????????????????????????????????????
     *  totalCollateral:50 | unsecured:1100 | collateral:1000 | reward:200 | totalWithdraw:(?????????:collateral+reward):1200
     *   |---> ????????????1200???unsecured???????????????unsecured???1100?????????1000????????????100??????????????????100
     *   |---> ??????100????????????????????????totalCollateral?????????
     */
    function calExtract(uint collateral, uint reward) public onlyAssociatedContract returns (uint) {
        //???????????????
        uint totalWithdraw = collateral.add(reward);
        //1. unsecured???????????????unsecured???????????????
        if (unsecured >= totalWithdraw) {
            unsecured = unsecured.sub(collateral);
            //???????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????
            withdrawReward = withdrawReward.add(reward);
            return 0;
        }
        //2. unsecured?????????????????????????????????????????????
        if (unsecured >= collateral) {
            totalWithdraw = totalWithdraw.sub(unsecured);
            unsecured = unsecured.sub(collateral);
        } else {
            //3. unsecured????????????????????????????????????
            totalCollateral = totalCollateral.sub(collateral.sub(unsecured));
            totalWithdraw = totalWithdraw.sub(unsecured);
            unsecured = 0;
        }
        return totalWithdraw;
    }

    function pledgeUpdate(
        address account,
        uint collateral,
        uint reward
    ) public onlyAssociatedContract {
        DataTypesLib.Staking storage s = staking[account];
        //????????????
        s.rewards = reward;
        //????????????
        s.lastRewardPerToken = lastRewardPerTokenStored;
        //s.round==0 && round==0 ----> ???????????????????????????????????????
        //s.round==0 && round>0 && s.collaterals==0 ----> ???????????????????????????????????????
        //s.round>0 && s.round==round ----> ???????????????????????????n?????????
        if ((s.round == 0 && (round == 0 || (round > 0 && s.collaterals == 0))) || (s.round > 0 && s.round == round)) {
            s.collaterals = s.collaterals.add(collateral);
        } else {
            s.lastCollaterals = s.lastCollaterals.add(s.collaterals);
            s.collaterals = collateral;
        }
        s.round = round;
        //?????????????????????????????????
        unsecured = unsecured.add(collateral);
    }

    function extractUpdate(
        address account,
        uint amount,
        uint reward
    ) public onlyAssociatedContract returns (uint, uint) {
        DataTypesLib.Staking storage s = staking[account];
        //????????????
        s.rewards = reward;
        //?????????????????????????????????????????????????????????????????????????????????
        reward = 0;
        //????????????
        uint userCollateral = s.lastCollaterals.add(s.collaterals);
        if (amount >= userCollateral) {
            //??????????????????
            reward = s.rewards;
            //????????????????????????????????????
            amount = userCollateral;
            delete staking[account];
        } else {
            //???????????????????????????????????????????????????????????????????????????????????????
            if (s.round < round) {
                s.lastCollaterals = s.lastCollaterals.add(s.collaterals);
                s.collaterals = 0;
            }
            //??????????????????
            if (s.collaterals > amount) {
                //???????????????????????????
                s.collaterals = s.collaterals.sub(amount);
            } else {
                //????????????????????????????????????????????????
                s.lastCollaterals = s.lastCollaterals.sub(amount.sub(s.collaterals));
                s.collaterals = 0;
            }
            s.lastRewardPerToken = lastRewardPerTokenStored;
        }
        return (amount, reward);
    }

    function surplus() public view returns (uint) {
        return unsecured.sub(withdrawReward);
    }

    function savingsUpdate() public onlyAssociatedContract {
        //?????????????????????????????????????????????????????????????????????????????????
        totalCollateral = totalCollateral.add(unsecured);
        //?????????????????????
        unsecured = 0;
        withdrawReward = 0;
        //????????????
        roundRewardPerToken[round] = lastRewardPerTokenStored;
        round = round.add(1);
    }

    function getStaking(address account) external view returns (DataTypesLib.Staking memory) {
        DataTypesLib.Staking memory s = staking[account];
        return s;
    }
}