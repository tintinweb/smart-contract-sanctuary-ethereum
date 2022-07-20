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
// File: contracts/libraries/CheckContract.sol


pragma solidity =0.8.7;


contract CheckContract {
    /**
     * Check that the account is an already deployed non-destroyed contract.
     * See: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol#L12
     */
    function checkContract(address _account) internal view {
        require(_account != address(0), "Account cannot be zero address");

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(_account) }
        require(size > 0, "Account code size cannot be zero");
    }
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
// File: contracts/SortedTroves.sol


pragma solidity ^0.8.7;






interface ITroveOperations {
    function getCollateralAndDebt(address _id) external view returns (uint _coll, uint _debt);
}


contract SortedTroves is CheckContract, ISortedTroves {
    using SafeMath for uint;

    // Information for a node in the list
    struct Node {
        bool exists;
        uint nextId;                  // Id of next node (smaller NICR) in the list
        uint prevId;                  // Id of previous node (larger NICR) in the list
    }

    // Information for the list
    struct Linklist {
        uint head;                  // Head of the list. Also the node in the list with the largest NICR
        uint tail;                  // Tail of the list. Also the node in the list with the smallest NICR
        uint maxSize;                       // Maximum size of the list
        uint size;                          // Current size of the list
        mapping(uint => Node) nodes;     // Track the corresponding ids for each node in the list
    }

    enum ActivateOperation {
        invalid,
        activateByBorrow,
        activateByLeverage,
        activateByRedeem,
        activateByLiquidation
    }

    uint public constant DECIMAL_PRECISION = 1e18;
    address public owner;
    string public name;

    Linklist public data;

    address public borrowOperationAddr;
    // IBorrowerToSortedTroves public borrowOperator;
    address public leverageOperationAddr;
    // ILeverageToSortedTroves public leverageOperator;
    address public redeemOperationAddr;
    address public liquidationOperationAddr;

    constructor(string memory _name) {
        owner = msg.sender;
        name = _name;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    function setParams(
        uint size,
        address _borrowOperationAddr, 
        address _leverageOperationAddr, 
        address _redeemOperationAddr, 
        address _liquidationOperationAddr
    ) external onlyOwner {
        data.maxSize = size;
        borrowOperationAddr = _borrowOperationAddr;
        leverageOperationAddr = _leverageOperationAddr;
        redeemOperationAddr = _redeemOperationAddr;
        liquidationOperationAddr = _liquidationOperationAddr;
    }

    /**
     * Set to sorted link-list by user's nominal collateral ratio, specially borrowing and leverage can do this, 
     * @notice link-list nodeId will be bytes32 which concat user-address and operation-type-id to use, and using Mim-O(1) with params of _prevId and _nextId
     * @param _borrow The user's address
     * @param _coll The user's collateral(ibTKN) total amount
     * @param _debt The user's debt(USDA) total amount 
     * @param _prevId The upper hint nodeId of the _id and operation-type which should be computes before
     * @param _nextId The lower hint nodeId of the _id and operation-type which should be computes before
     */
    function setSort(address _borrow, uint8 _opType, uint _coll, uint _debt, uint _prevId, uint _nextId) external override {
        // TODO: Require check
        _requireCallerIsAllowedOperator();
        uint _nodeId = ArchimedesMath._generateSortedNodeId(_borrow, _opType);
        if (!contains(_nodeId)) {
            // insert
            uint _NCR = ArchimedesMath._computeNominalCR(_coll, _debt);
            _insert(_borrow, _opType, _NCR, _prevId, _nextId);
        } else if (_debt == 0) {
            // remove
            _remove(_borrow, _opType);
        } else {
            // reInsert
            _remove(_borrow, _opType);
            uint _NCR = ArchimedesMath._computeNominalCR(_coll, _debt);
            _insert(_borrow, _opType, _NCR, _prevId, _nextId);
        }
        
    }

    // /**
    //  * Insert into sorted link-list by user's nominal collateral ratio, specially borrowing and leverage can do this, 
    //  * @notice link-list nodeId will be bytes32 which concat user-address and operation-type-id to use, and using Mim-O(1) with params of _prevId and _nextId
    //  * @param _id The user's address
    //  * @param _coll The user's collateral(ibTKN) total amount
    //  * @param _debt The user's debt(USDA) total amount 
    //  * @param _prevId The upper hint nodeId of the _id and operation-type which should be computes before
    //  * @param _nextId The lower hint nodeId of the _id and operation-type which should be computes before
    //  */
    // function insert(address _id, uint8 _opType, uint _coll, uint _debt, bytes32 _prevId, bytes32 _nextId) external override {
    //     // TODO: Require check
    //     _requireCallerIsAllowedOperator();
    //     uint _NCR = ArchimedesMath._computeNominalCR(_coll, _debt);
    //     _insert(_id,_opType, _NCR, _prevId, _nextId);
    // }

    function _insert(address _borrow, uint8 _opType, uint _NCR, uint _prevId, uint _nextId) internal {
        uint _id = ArchimedesMath._generateSortedNodeId(_borrow, _opType);
        // TODO: Require check
        require(_opType == 1 || _opType == 2, "SortedTroves: opType only in 1 or 2");
        require(!isFull(), "SortedTroves: List is full");
        require(!contains(_id), "SortedTroves: List already contains the node");
        require(_borrow != address(0), "SortedTroves: Id cannot be zero");
        require(_NCR > 0, "SoretedTroves: NPCR must be positive");

        uint prevId = _prevId;
        uint nextId = _nextId;
        // TODO: valid insert position
        if (!_validInsertPosition(_NCR, _prevId, _nextId)) {
            (prevId, nextId) = _findInsertPosition(_NCR, _prevId, _nextId);
        }

        data.nodes[_id].exists = true;
        if (prevId == 0 && nextId == 0) {
            // insert as head and tail
            data.head = _id;
            data.tail = _id;
        } else if (prevId == 0) {
            // insert before `prevId` as the head
            data.nodes[_id].nextId = data.head;
            data.nodes[data.head].prevId = _id;
            data.head = _id;
        } else if (nextId == 0) {
            // insert after `nextId` as the tail
            data.nodes[_id].prevId = data.tail;
            data.nodes[data.tail].nextId = _id;
            data.tail = _id;
        } else {
            // insert at insert position 
            data.nodes[_id].nextId = nextId;
            data.nodes[_id].prevId = prevId;
            data.nodes[prevId].nextId = _id;
            data.nodes[nextId].prevId = _id;
        }

        data.size = data.size.add(1);
        emit NodeAdded(_borrow, _opType, _NCR);
    }

    // /**
    //  * Remove the nodeId by user address
    //  * @notice This will be executed by user's trove will be closed after someone operation.
    //  * @param _id The user's address
    //  */
    // function remove(address _id, uint8 _opType) external override {
    //     // TODO: Reuqire check
    //     _requireCallerIsAllowedOperator();
    //     _remove(_id, _opType);
    // }

    function _remove(address _borrow, uint8 _opType) internal {
        uint _id = ArchimedesMath._generateSortedNodeId(_borrow, _opType);
        require(_opType == 1 || _opType == 2, "SortedTroves: opType only in 1 or 2");
        require(contains(_id), "SortedTroves: List does not contain the id");

        if (data.size > 1) {
            if (_id == data.head) {
                data.head = data.nodes[_id].nextId;
                data.nodes[data.head].prevId = 0;
            } else if (_id == data.tail) {
                data.tail = data.nodes[_id].prevId;
                data.nodes[data.tail].nextId = 0;
            } else {
                data.nodes[data.nodes[_id].prevId].nextId = data.nodes[_id].nextId;
                data.nodes[data.nodes[_id].nextId].prevId = data.nodes[_id].prevId;
            }
        } else {
            data.head = 0;
            data.tail = 0;
        }

        delete data.nodes[_id];
        data.size = data.size.sub(1);

        emit NodeRemoved(_borrow, _opType);
    }
    
    // /**
    //  * Re-Insert into sorted link-list by user's nominal collateral ratio when user's coll/debt update. 
    //  * @notice link-list nodeId will be bytes32 which concat user-address and operation-type-id to use, and using Mim-O(1) with params of _prevId and _nextId
    //  * @param _id The user's address
    //  * @param _coll The user's collateral(ibTKN) total amount
    //  * @param _debt The user's debt(USDA) total amount 
    //  * @param _prevId The upper hint nodeId of the _id and operation-type which should be computes before
    //  * @param _nextId The lower hint nodeId of the _id and operation-type which should be computes before
    //  */
    // function reInsert(address _id, uint8 _opType, uint _coll, uint _debt, bytes32 _prevId, bytes32 _nextId) external override {
    //     // ITroveManager troveManagerCached = ITroveManager(troveManagerAddress);
    //     // TODO: Require
    //     _requireCallerIsAllowedOperator();
    //     _remove(_id, _opType);
    //     uint _newNCR = ArchimedesMath._computeNominalCR(_coll, _debt);
    //     _insert(_id, _opType, _newNCR, _prevId, _nextId);
    // }

    // -- view functions --
    function getSize() external view override returns (uint256) {
        return data.size;
    }

    function getMaxSize() external view override returns (uint256) {
        return data.maxSize;
    }

    function findInsertPosition(uint _coll, uint _debt, uint _prevId, uint _nextId) external view override returns (uint, uint) {
        uint _NCR = ArchimedesMath._computeNominalCR(_coll, _debt);
        return _findInsertPosition(_NCR, _prevId, _nextId);
    }

    /*
    function getRedeemHints(uint _USDAamount, uint _price, uint _maxIterations) 
        external 
        view 
        override 
        returns 
    (
        bytes32 firstRedeemHint, 
        uint partialRedeemHintNCR, 
        uint truncatedUSDAamount
    ) 
    {
        uint remainingUSDA = _USDAamount;
        bytes32 currNodeId = getFirst();

        firstRedeemHint = currNodeId;

        if (_maxIterations == 0) {
            _maxIterations = type(uint).max;
        }

        while (currNodeId != ZEROID && remainingUSDA > 0 && _maxIterations-- > 0) {
            (address currNodeAddr, address troveAddr) = getUserAddrAndTroveManagerAddr(currNodeId);
            (uint netColl, uint netUSDADebt) = ITroveOperations(troveAddr).getCollateralAndDebt(currNodeAddr);
            if (netUSDADebt > remainingUSDA) {
                uint maxRedeemableUSDA = ArchimedesMath._min(remainingUSDA, netUSDADebt);
                uint newColl = netColl.sub(maxRedeemableUSDA.mul(DECIMAL_PRECISION).div(_price));
                uint newDebt = netUSDADebt.sub(maxRedeemableUSDA);
                partialRedeemHintNCR = ArchimedesMath._computeNominalCR(newColl, newDebt);

                remainingUSDA = remainingUSDA.sub(maxRedeemableUSDA);
                break;
            } else {
                remainingUSDA = remainingUSDA.sub(netUSDADebt);
            }

            currNodeId = getNext(currNodeId);
        }
        truncatedUSDAamount = _USDAamount.sub(remainingUSDA);
    }
    */ 

    function getRedeemHints(uint _USDAamount, uint _price, uint _maxIterations) 
        external 
        view 
        override 
        returns 
    (
        uint firstRedeemHint, 
        uint parialCollHint,
        uint paritalDebtHint,
        uint truncatedUSDAamount
    ) 
    {
        uint remainingUSDA = _USDAamount;
        uint currNodeId = getFirst();

        firstRedeemHint = currNodeId;

        if (_maxIterations == 0) {
            _maxIterations = type(uint).max;
        }

        while (currNodeId != 0 && remainingUSDA > 0 && _maxIterations-- > 0) {
            (address currNodeAddr, address troveAddr) = getUserAddrAndTroveManagerAddr(currNodeId);
            (uint netColl, uint netUSDADebt) = ITroveOperations(troveAddr).getCollateralAndDebt(currNodeAddr);
            if (netUSDADebt > remainingUSDA) {
                uint maxRedeemableUSDA = ArchimedesMath._min(remainingUSDA, netUSDADebt);
                parialCollHint = netColl.sub(maxRedeemableUSDA.mul(DECIMAL_PRECISION).div(_price));
                paritalDebtHint = netUSDADebt.sub(maxRedeemableUSDA);
                // partialRedeemHintNCR = ArchimedesMath._computeNominalCR(newColl, newDebt);

                remainingUSDA = remainingUSDA.sub(maxRedeemableUSDA);
                break;
            } else {
                remainingUSDA = remainingUSDA.sub(netUSDADebt);
            }

            currNodeId = getNext(currNodeId);
        }
        truncatedUSDAamount = _USDAamount.sub(remainingUSDA);
    }

    function contains(uint _id) public view override returns (bool) {
        return data.nodes[_id].exists;
    }

    function isFull() public view override returns (bool) {
        return data.size == data.maxSize;
    }

    function isEmpty() public view override returns (bool) {
        return data.size == 0;
    }

    function getFirst() public view override returns (uint) {
        return data.head;
    }

    function getLast() public view override returns (uint) {
        return data.tail;
    }

    function getNext(uint _id) public view override returns (uint) {
        return data.nodes[_id].nextId;
    }

    function getPrev(uint _id) public view override returns (uint) {
        return data.nodes[_id].prevId;
    }

    function getUserAddrAndTroveManagerAddr(uint _id) public view override returns (address, address) {
        (address _borrow, uint8 _opType) = ArchimedesMath._parseSortedNodeId(_id);
        address _troveAddr = getTroveAddrByOpId(_opType);
        return (_borrow, _troveAddr);
    }

    function getOperatorIdByCallerAddr(address _callerAddr) public view override returns (uint8 _typeId) {
        ActivateOperation _typeEnum;
        if (_callerAddr == borrowOperationAddr) {
            _typeEnum = ActivateOperation.activateByBorrow;
        } else if (_callerAddr == leverageOperationAddr) {
            _typeEnum = ActivateOperation.activateByLeverage;
        } else if (_callerAddr == redeemOperationAddr) {
            _typeEnum = ActivateOperation.activateByRedeem;
        } else if (_callerAddr == liquidationOperationAddr) {
            _typeEnum = ActivateOperation.activateByLiquidation;
        } else {
            _typeEnum = ActivateOperation.invalid;
        }

        _typeId = uint8(_typeEnum);
    }

    function getTroveAddrByOpId(uint8 _opId) public view returns (address _opAddr) {
        if (ActivateOperation(_opId) == ActivateOperation.activateByBorrow) {
            _opAddr = borrowOperationAddr;
        } else if (ActivateOperation(_opId) == ActivateOperation.activateByLeverage) {
            _opAddr = leverageOperationAddr;
        } else if (ActivateOperation(_opId) == ActivateOperation.activateByRedeem) {
            _opAddr = redeemOperationAddr;
        } else if (ActivateOperation(_opId) == ActivateOperation.activateByLiquidation) {
            _opAddr = liquidationOperationAddr;
        } else {
            _opAddr = address(0);
        }
    }

    function _getNominalCR(uint _id) internal view returns (uint) {
        (address _borrow, uint8 _opType) = ArchimedesMath._parseSortedNodeId(_id);
        if (ActivateOperation(_opType) == ActivateOperation.activateByBorrow) {
            (uint coll, uint debt) = ITroveOperations(borrowOperationAddr).getCollateralAndDebt(_borrow);
            return ArchimedesMath._computeNominalCR(coll, debt);
        } else if (ActivateOperation(_opType) == ActivateOperation.activateByLeverage) {
            (uint coll, uint debt) = ITroveOperations(leverageOperationAddr).getCollateralAndDebt(_borrow);
            return ArchimedesMath._computeNominalCR(coll, debt);
        } else {
            return 0;
        }
    }

    function _validInsertPosition(uint _NCR, uint _prevId, uint _nextId) internal view returns (bool) {
        if (_prevId == 0 && _nextId == 0) {
            return isEmpty();
        } else if (_prevId == 0) {
            return data.head == _nextId && _NCR >= _getNominalCR(_nextId);
        } else if (_nextId == 0) {
            return data.tail == _prevId && _NCR <= _getNominalCR(_prevId);
        } else {
            return data.nodes[_prevId].nextId == _nextId && _getNominalCR(_prevId) >= _NCR && _NCR >= _getNominalCR(_nextId);
        }
    }

    function _findInsertPosition(uint _NCR, uint _prevId, uint _nextId) internal view returns (uint, uint) {
        uint prevId = _prevId;
        uint nextId = _nextId;
        if (prevId != 0) {
            if(!contains(prevId) || _NCR > _getNominalCR(prevId)) {
                prevId = 0;
            }
        }

        if (nextId != 0) {
            if (!contains(nextId) || _NCR < _getNominalCR(nextId)) {
                nextId = 0;
            }
        }

        if (prevId == 0 && nextId == 0) {
            return _descendList(_NCR, data.head);
        } else if (prevId == 0) {
            return _ascendList(_NCR, nextId);
        } else if (nextId == 0) {
            return _descendList(_NCR, prevId);
        } else {
            return _descendList(_NCR, prevId);
        }
    }

    function _descendList(uint _NCR, uint _startId) internal view returns (uint, uint) {
        if (data.head == _startId && _NCR >= _getNominalCR(_startId)) {
            return (0, _startId);
        }
        uint prevId = _startId;
        uint nextId = data.nodes[prevId].nextId;

        while (prevId != 0 && !_validInsertPosition(_NCR, prevId, nextId)) {
            prevId = data.nodes[prevId].nextId;
            nextId = data.nodes[prevId].nextId;
        }

        return (prevId, nextId);
    }

    function _ascendList(uint _NCR, uint _startId) internal view returns (uint, uint) {
        if (data.tail == _startId && _NCR <= _getNominalCR(_startId)) {
            return (_startId, 0);
        }

        uint nextId = _startId;
        uint prevId = data.nodes[nextId].prevId;

        while (nextId != 0 && !_validInsertPosition(_NCR, prevId, nextId)) {
            nextId = data.nodes[nextId].prevId;
            prevId = data.nodes[nextId].prevId;
        }

        return (prevId, nextId);
    }

    // --- require functions ---
    function _requireCallerIsAllowedOperator() internal view {
        require(
            msg.sender == borrowOperationAddr || 
            msg.sender == leverageOperationAddr || 
            msg.sender == redeemOperationAddr || 
            msg.sender == liquidationOperationAddr, 
            "SortedTroves: Permission denied"
        );
    }

}