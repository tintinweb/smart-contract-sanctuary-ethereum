/**
 *Submitted for verification at Etherscan.io on 2022-07-20
*/

// SPDX-License-Identifier: MIT
// File: contracts/interfaces/ISortedTroves.sol


pragma solidity ^0.8.7;

interface ISortedTroves {

    // --- Events ---
    event NodeAdded(address _borrow, uint8 _typeId, uint _NCR);
    event NodeRemoved(address _borrow, uint8 _typeId);

    // --- Functions ---
    function setSort(address _borrow, uint8 _opType, uint _coll, uint _debt, uint _prevId, uint _nextId) external;

    // function insert(address _borrow, uint8 _opType, uint _coll, uint _debt, uint _prevId, uint _nextId) external;

    // function remove(address _borrow, uint8 _opType) external;

    // function reInsert(address _borrow, uint8 _opType, uint _coll, uint _debt, uint _prevId, uint _nextId) external;

    function contains(uint _id) external view returns (bool);

    function isFull() external view returns (bool);

    function isEmpty() external view returns (bool);

    function getSize() external view returns (uint);

    function getMaxSize() external view returns (uint);

    function getFirst() external view returns (uint);

    function getLast() external view returns (uint);

    function getNext(uint _id) external view returns (uint);

    function getPrev(uint _id) external view returns (uint);

    function getUserAddrAndTroveManagerAddr(uint _id) external view returns (address _user, address _troveAddr);

    function getOperatorIdByCallerAddr(address _callerAddr) external view returns (uint8);

    function findInsertPosition(uint _coll, uint _debt, uint _prevId, uint _nextId) external view returns (uint, uint);

    function getRedeemHints(uint _USDAamount, uint _price, uint _maxIterations) external view returns (uint firstRedeemHint, uint parialCollHint, uint paritalDebtHint, uint truncatedUSDAamount);

}
// File: contracts/interfaces/IBaseRate.sol


pragma solidity =0.8.7;

interface IBaseRate {
    function getBorrowingRate() external view returns (uint);
    function decayBaseRateFromBorrowing() external;
    function getRedemptionRate() external view returns (uint);
    function getRedemptionRateWithDecay() external view returns (uint);
    function updateBaseRateFromRedemption(uint _CollDrawn, uint _price, uint _totalUSDASupply) external returns (uint);
}
// File: contracts/interfaces/IOracle.sol


pragma solidity =0.8.7;


interface IOracle {
    function get() external returns (bool, uint);
}
// File: contracts/interfaces/IERC20.sol


pragma solidity =0.8.7;

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    
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
// File: contracts/libraries/SafeMath.sol


pragma solidity =0.8.7;


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
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
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
    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

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
    function mul(uint a, uint b) internal pure returns (uint) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
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
    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint c = a / b;
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
    function mod(uint a, uint b) internal pure returns (uint) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
// File: contracts/libraries/ArchimedesMath.sol


pragma solidity =0.8.7;


library ArchimedesMath {
    using SafeMath for uint;

    uint256 internal constant DECIMAL_PRECISION = 1e18;

    // 为什么选取1e20
	/*
	 * 主要是通过 Coll * NICE_PRECISION / Debt
	 * Coll and Debt uint
	 * 太小了 => 分子就越趋近于0 => 除法以后更小了
	 * 太大了 => 乘积之后考虑溢出(假设分子1e39)
	 * 如果计算被截断=0，需要分母至少是1e20的倍数
	 */
    uint internal constant NICR_PRECISION = 1e20;

    function _min(uint _a, uint _b) internal pure returns (uint) {
        return (_a < _b) ? _a : _b;
    }

    function _max(uint _a, uint _b) internal pure returns (uint) {
        return (_a >= _b) ? _a : _b;
    }

    function decMul(uint x, uint y) internal pure returns (uint decProd) {
        uint prod_xy = x.mul(y);

        decProd = prod_xy.add(DECIMAL_PRECISION / 2).div(DECIMAL_PRECISION);
    }

    function _decPow(uint _base, uint _minutes) internal pure returns (uint) {
       
        if (_minutes > 525600000) {_minutes = 525600000;}  // cap to avoid overflow
    
        if (_minutes == 0) {return DECIMAL_PRECISION;}

        uint y = DECIMAL_PRECISION;
        uint x = _base;
        uint n = _minutes;

        // Exponentiation-by-squaring
        while (n > 1) {
            if (n % 2 == 0) {
                x = decMul(x, x);
                n = n.div(2);
            } else { // if (n % 2 != 0)
                y = decMul(x, y);
                x = decMul(x, x);
                n = (n.sub(1)).div(2);
            }
        }

        return decMul(x, y);
    }

    function _getAbsoluteDifference(uint _a, uint _b) internal pure returns (uint) {
        return (_a >= _b) ? _a.sub(_b) : _b.sub(_a);
    }

    function _computeNominalCR(uint _coll, uint _debt) internal pure returns (uint) {
        // if (_debt > 0) {
        //     return _coll.mul(NICR_PRECISION).div(_debt);
        // }
        // // Return the maximal value for uint if the Trove has a debt of 0. Represents "infinite" CR.
        // else {
        //     return 2**256 - 1;
        // }
        if (_coll > 0) {
            return _debt.mul(DECIMAL_PRECISION).div(_coll);
        } else {
            return 2**256 - 1;
        }
    }

    function _computeCR(uint _coll, uint _debt, uint _price) internal pure returns (uint) {
        // if (_debt > 0) {
        //     uint newCollRatio = _coll.mul(_price).div(_debt);
        //     return newCollRatio;
        // }
        // // Return the maximal value for uint if the Trove has a debt of 0. Represents "infinite" CR.
        // else {
        //     return 2**256 - 1; 
        // }
        require(_coll > 0 && _price >0, "collateral and price not great than 0");
        uint256 newCollRatio = _debt.mul(DECIMAL_PRECISION).mul(DECIMAL_PRECISION).div(_coll.mul(_price));
        return newCollRatio;
    }

    function _generateSortedNodeId(address _borrow, uint8 _opType) internal pure returns (uint) {
        return (uint(_opType)<<160)|(uint(uint160(_borrow)));
    }

    function _parseSortedNodeId(uint _id) internal pure returns (address, uint8) {
        address _borrow = address(uint160(_id));
        uint8 _opType = uint8(_id>>160);
        return (_borrow, _opType);
    }
    
}
// File: contracts/redeem/RedeemOperations.sol


pragma solidity ^0.8.7;






// import "./interfaces/IRedeemOperations.sol";


interface ITroveOperations {
    function sendColl(address _id, uint _collAmount) external;
    function updateTrove(address _id, uint _coll, uint _debt) external;

    function getCollateralAndDebt(address _id) external view returns (uint _coll, uint _debt);
}


contract RedeemOperations {
// contract RedeemOperations is IRedeemOperations {
    using SafeMath for uint;

	struct SingleRedemptionValues {
		uint USDALot;
		uint CollLot;
		bool cancelledPartial;
        address troveAddr;
        address borrowAddr;
	}

	struct RedemptionTotals {
		uint remainingUSDA;
		uint totalUSDABorRedeem;
		uint totalUSDALevRedeem;
		uint totalCollBorDrawn;
		uint totalCollLevDrawn;
		uint redeemFeeViaBor;
		uint redeemFeeViaLev;
		uint decayedBaseRate;
		uint totalUSDASupplyAtStart;
	}

    uint public constant maxRedeemSize = 1000;
    uint public constant DECIMAL_PRECISION = 1e18;
    address public owner;
    string public name;

    // -- Redeem --
    address public incomePool;  // 平台收益池地址
	IERC20 public usdaToken;
	ISortedTroves public sortedTroves;  // 排序合约
	IOracle public oracle;  // 平台价格预言机
	IBaseRate public baseRate;  // BaseRate合约
    ITroveOperations public borrowTroves;   // borrow管理合约
    ITroveOperations public leverageTroves; // leverage管理合约

    uint public lastGoodPrice;  // 抵押品在平台当前的价格

    event Redemption(
		address _redeemer,
		uint _actualUSDAAmount,
		uint _collBorDrawn,
		uint _collLevDrawn,
		uint _redeemBorFee,
		uint _redeemLevFee
	);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    function setParams(
        address _USDAAddr,
        address _oracleAddr,
        address _baseRateAddr,
        address _sortedTrovesAddr,
        address _borrowOperationAddr, 
        address _leverageOperationAddr
    ) external onlyOwner {
        usdaToken = IERC20(_USDAAddr);
        oracle = IOracle(_oracleAddr);
        baseRate = IBaseRate(_baseRateAddr);
        sortedTroves = ISortedTroves(_sortedTrovesAddr);
        borrowTroves = ITroveOperations(_borrowOperationAddr);
        leverageTroves = ITroveOperations(_leverageOperationAddr);
    }

    /**
     * Redemption with USDA
     * @dev _firstRedemptionHint,_upperPartialRedemptionHint,_lowerPartialRedemptionHint,_partialRedemptionHintNPCR
     * 将由外部进行预先计算,作为参数提供给合约,减少执行的消耗
	 * 这里有一个**限制**:不能支持type(uint256).Max的iterations,最大范围将由定义的记录被redeemed borrowers定长array的长度限定
     * @param _USDAamount 赎回者提供的总的赎回金(USDA)
     * @param _firstRedemptionHint 排在将被赎回列表中的第一位的Trove地址
     * @param _upperPartialRedemptionHint 最后一次赎回时该Trove在排序链表的Prev-Trove地址
     * @param _lowerPartialRedemptionHint 最后一次赎回时该Trove在排序链表的Next-Trove地址
     * @param _partialRedemptionHintNCR  最后一次赎回时该Trove部分赎回后的NPCR
    */
    function redeemCollateral(
        uint _USDAamount, 
        uint _firstRedemptionHint, 
        uint _upperPartialRedemptionHint, 
        uint _lowerPartialRedemptionHint, 
        uint _partialRedemptionHintNCR, 
        uint _maxFeePercentage
    ) 
        external  
    {
        // check conditions
        require(_maxFeePercentage > 0, "RedeemOperations: FeePercentage less than 0");
		require(_USDAamount > 0, "RedeemOperations: Redeem USDA amount less than 0");
        require(usdaToken.balanceOf(msg.sender) > _USDAamount, "RedeemOperations: USDA balance less than redeem");

        RedemptionTotals memory totals;

        // get oracle price
        uint price = _updateFromOracle();

		totals.totalUSDASupplyAtStart = usdaToken.totalSupply();
		totals.remainingUSDA = _USDAamount;
        uint currentNode = _firstRedemptionHint;

        // TODO: support for redeem fees to each redeemed address
        // address[] memory redeemedBorrowers = new address[](maxRedeemSize);
		// uint[] memory collOfBorrowers = new uint[](maxRedeemSize);
        // address[] memory collOfTroves = new address[](maxRedeemSize);
        // uint index = 0;

        uint _maxIterations = maxRedeemSize;
        while (currentNode != 0 && totals.remainingUSDA > 0 && _maxIterations > 0) {
            _maxIterations--;
            uint nextNodeToCheck = sortedTroves.getNext(currentNode);
            SingleRedemptionValues memory singleRedeem = _redeemCollateral(
                currentNode,
                totals.remainingUSDA,
                price,
                _upperPartialRedemptionHint,
                _lowerPartialRedemptionHint,
                _partialRedemptionHintNCR
            );

            if (singleRedeem.cancelledPartial) break;

            if (singleRedeem.troveAddr == address(borrowTroves)) {
                // borrow
                totals.totalUSDABorRedeem = totals.totalUSDABorRedeem.add(singleRedeem.USDALot);
                totals.totalCollBorDrawn = totals.totalCollBorDrawn.add(singleRedeem.CollLot);
            } else if (singleRedeem.troveAddr == address(leverageTroves)) {
                // leverage
                totals.totalUSDALevRedeem = totals.totalUSDALevRedeem.add(singleRedeem.USDALot);
                totals.totalCollLevDrawn = totals.totalCollLevDrawn.add(singleRedeem.CollLot);
            }

            totals.remainingUSDA = totals.remainingUSDA.sub(singleRedeem.USDALot);

            currentNode = nextNodeToCheck;

            // TODO: record redeemed info
            // redeemedBorrowers[index] = singleRedeem.borrowAddr;
            // collOfBorrowers[index] = singleRedeem.CollLot;
            // collOfTroves[index] = singleRedeem.troveAddr;
            // index++;
        }

        baseRate.updateBaseRateFromRedemption(totals.totalCollBorDrawn.add(totals.totalCollLevDrawn), price, totals.totalUSDASupplyAtStart);

        uint _redemptionRate = baseRate.getRedemptionRate();

        totals.redeemFeeViaBor = _redemptionRate.mul(totals.totalCollBorDrawn).div(DECIMAL_PRECISION);
        totals.redeemFeeViaLev = _redemptionRate.mul(totals.totalCollLevDrawn).div(DECIMAL_PRECISION);
        
        // send collateral
        if (totals.totalCollBorDrawn > 0) {
            require(totals.redeemFeeViaBor < totals.totalCollBorDrawn, "RedeemTroves: Fee more than collaterals");
            ITroveOperations(address(borrowTroves)).sendColl(msg.sender, totals.totalCollBorDrawn.sub(totals.redeemFeeViaBor));
        
        }
        if (totals.totalCollLevDrawn > 0) {
            require(totals.redeemFeeViaLev < totals.totalCollLevDrawn, "RedeemTroves: Fee more than collaterals");
            ITroveOperations(address(leverageTroves)).sendColl(msg.sender, totals.totalCollLevDrawn.sub(totals.redeemFeeViaBor));
        }


        uint totalUSDARedeem = totals.totalUSDABorRedeem.add(totals.totalUSDALevRedeem);
        // burn usda
        // usdaToken.burn(msg.sender, totalUSDARedeem);

        // TODO: distribute redeem fee 
        // ITroveOperations(address(borrowTroves)).sendColl(incomePool, redeemFeeViaBor);
        // ITroveOperations(address(leverageTroves)).sendColl(incomePool, redeemFeeViaBor);

        // for (uint idx = 0; idx < index; idx++) {
        //     uint collValue = collOfBorrowers[idx];
        //     address feeTo = redeemedBorrowers[idx];
        //     if (collValue > 0 && feeTo != address(0)) {
        //         // everyone redeemed user to  
        //         uint fees = _redemptionRate.mul(collValue).div(DECIMAL_PRECISION);
        //         ITroveOperations(collOfTroves[idx]).sendColl(feeTo, fees);
        //     }
        // }

        emit Redemption(msg.sender, totalUSDARedeem, totals.totalCollBorDrawn, totals.totalCollLevDrawn, totals.redeemFeeViaBor, totals.redeemFeeViaLev);
    }

    function _redeemCollateral(
        uint _nodeId, 
        uint _maxUSDAamount, 
        uint _price, 
        uint _upperPartialRedemptionHint, 
        uint _lowerPartialRedemptionHint, 
        uint _partialRedemptionHintNCR
    ) 
        internal 
        returns (SingleRedemptionValues memory singleRedeem) 
    {
        // from nodeId to parse borrow and troveManager address
        (singleRedeem.borrowAddr, singleRedeem.troveAddr) = sortedTroves.getUserAddrAndTroveManagerAddr(_nodeId);

        uint8 _opType = sortedTroves.getOperatorIdByCallerAddr(singleRedeem.troveAddr);
        (uint coll, uint debt) = ITroveOperations(singleRedeem.troveAddr).getCollateralAndDebt(singleRedeem.borrowAddr);
        singleRedeem.USDALot = ArchimedesMath._min(_maxUSDAamount, debt);
        singleRedeem.CollLot = singleRedeem.USDALot.mul(DECIMAL_PRECISION).div(_price);

        // after redeem new coll/debt
        uint newDebt = debt.sub(singleRedeem.USDALot);
        uint newColl = coll.sub(singleRedeem.CollLot);
        if (newDebt == 0) {
            // close borrow'f trove
            ITroveOperations(singleRedeem.troveAddr).updateTrove(singleRedeem.borrowAddr, 0, 0);
            // remove sortedtroves
            sortedTroves.setSort(singleRedeem.borrowAddr, _opType, 0, 0, 0, 0);
        } else {
            // TODO: partional redeem to valid
            uint newNCR = ArchimedesMath._computeNominalCR(newColl, newDebt);
            if (newNCR != _partialRedemptionHintNCR) {
                singleRedeem.cancelledPartial = true;
                return singleRedeem;
            }
            
            // update borrow's trove
            ITroveOperations(singleRedeem.troveAddr).updateTrove(singleRedeem.borrowAddr, newColl, newDebt);
            // update sortedtroves
            sortedTroves.setSort(singleRedeem.borrowAddr, _opType, newColl, newDebt, _upperPartialRedemptionHint, _lowerPartialRedemptionHint);
        }
        return singleRedeem;
    }

    function _updateFromOracle() internal returns (uint) {
        (bool updated, uint price) = oracle.get();
        if (updated) {
            lastGoodPrice = price;
        } else {
            price = lastGoodPrice;
        }
        return price;
    }
}