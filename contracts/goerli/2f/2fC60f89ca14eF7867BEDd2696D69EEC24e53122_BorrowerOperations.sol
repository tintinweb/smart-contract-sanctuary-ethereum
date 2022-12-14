/**
 *Submitted for verification at Etherscan.io on 2022-12-14
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;


// import "hardhat/console.sol";


interface ILQTYStaking {

    // --- Events --
    
    event LQTYTokenAddressSet(address _lqtyTokenAddress);
    event LUSDTokenAddressSet(address _lusdTokenAddress);
    event TroveManagerAddressSet(address _troveManager);
    event BorrowerOperationsAddressSet(address _borrowerOperationsAddress);
    event ActivePoolAddressSet(address _activePoolAddress);

    event StakeChanged(address indexed staker, uint newStake);
    event StakingGainsWithdrawn(address indexed staker, uint LUSDGain, uint ETHGain);
    event F_ETHUpdated(uint _F_ETH);
    event F_LUSDUpdated(uint _F_LUSD);
    event TotalLQTYStakedUpdated(uint _totalLQTYStaked);
    event EtherSent(address _account, uint _amount);
    event StakerSnapshotsUpdated(address _staker, uint _F_ETH, uint _F_LUSD);

    // --- Functions ---

    function setAddresses
    (
        address _lqtyTokenAddress,
        address _lusdTokenAddress,
        address _troveManagerAddress, 
        address _borrowerOperationsAddress,
        address _activePoolAddress
    )  external;

    function stake(uint _LQTYamount) external;

    function unstake(uint _LQTYamount) external;

    function increaseF_ETH(uint _ETHFee) external; 

    function increaseF_LUSD(uint _LQTYFee) external;  

    function getPendingETHGain(address _user) external view returns (uint);

    function getPendingLUSDGain(address _user) external view returns (uint);
}

interface ISortedTroves {

    // --- Events ---
    
    event SortedTrovesAddressChanged(address _sortedDoublyLLAddress);
    event BorrowerOperationsAddressChanged(address _borrowerOperationsAddress);
    event NodeAdded(address _id, uint _NICR);
    event NodeRemoved(address _id);

    // --- Functions ---
    
    function setParams(uint256 _size, address _TroveManagerAddress, address _borrowerOperationsAddress) external;

    function insert(address _id, uint256 _ICR, address _prevId, address _nextId) external;

    function remove(address _id) external;

    function reInsert(address _id, uint256 _newICR, address _prevId, address _nextId) external;

    function contains(address _id) external view returns (bool);

    function isFull() external view returns (bool);

    function isEmpty() external view returns (bool);

    function getSize() external view returns (uint256);

    function getMaxSize() external view returns (uint256);

    function getFirst() external view returns (address);

    function getLast() external view returns (address);

    function getNext(address _id) external view returns (address);

    function getPrev(address _id) external view returns (address);

    function validInsertPosition(uint256 _ICR, address _prevId, address _nextId) external view returns (bool);

    function findInsertPosition(uint256 _ICR, address _prevId, address _nextId) external view returns (address, address);
}
interface ICollSurplusPool {

    // --- Events ---
    
    event BorrowerOperationsAddressChanged(address _newBorrowerOperationsAddress);
    event TroveManagerAddressChanged(address _newTroveManagerAddress);
    event ActivePoolAddressChanged(address _newActivePoolAddress);

    event CollBalanceUpdated(address indexed _account, uint _newBalance);
    event EtherSent(address _to, uint _amount);

    // --- Contract setters ---

    function setAddresses(
        address _borrowerOperationsAddress,
        address _troveManagerAddress,
        address _activePoolAddress
    ) external;

    function getETH() external view returns (uint);

    function getCollateral(address _account) external view returns (uint);

    function accountSurplus(address _account, uint _amount) external;

    function claimColl(address _account) external;
}

interface IERC2612 {
    /**
     * @dev Sets `amount` as the allowance of `spender` over `owner`'s tokens,
     * given `owner`'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(address owner, address spender, uint256 amount, 
                    uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    
    /**
     * @dev Returns the current ERC2612 nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases `owner`'s nonce by one. This
     * prevents a signature from being used multiple times.
     *
     * `owner` can limit the time a Permit is valid for by setting `deadline` to 
     * a value in the near future. The deadline argument can be set to uint(-1) to 
     * create Permits that effectively never expire.
     */
    function nonces(address owner) external view returns (uint256);
    
    function version() external view returns (string memory);
    function permitTypeHash() external view returns (bytes32);
    function domainSeparator() external view returns (bytes32);
}
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
interface ILUSDToken is IERC20, IERC2612 { 
    
    // --- Events ---

    // event TroveManagerAddressChanged(address _troveManagerAddress);
    event StabilityPoolAddressChanged(address _newStabilityPoolAddress);
    event BorrowerOperationsAddressChanged(address _newBorrowerOperationsAddress);

    event LUSDTokenBalanceUpdated(address _user, uint _amount);

    // --- Functions ---

    function mint(address _account, uint256 _amount) external;

    function burn(address _account, uint256 _amount) external;

    function sendToPool(address _sender,  address poolAddress, uint256 _amount) external;

    function returnFromPool(address poolAddress, address user, uint256 _amount ) external;
}


/**
 * Based on OpenZeppelin's Ownable contract:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol
 *
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor ()  {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     *
     * NOTE: This function is not safe, as it doesn’t check owner is calling it.
     * Make sure you check it before calling it.
     */
    function _renounceOwnership() internal {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}



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

pragma solidity 0.8.17;

// Common interface for the Pools.
interface IPool {
    
    // --- Events ---
    
    event ETHBalanceUpdated(uint _newBalance);
    event LUSDBalanceUpdated(uint _newBalance);
    event ActivePoolAddressChanged(address _newActivePoolAddress);
    event DefaultPoolAddressChanged(address _newDefaultPoolAddress);
    event StabilityPoolAddressChanged(address _newStabilityPoolAddress);
    event EtherSent(address _to, uint _amount);

    function getUSDC(address _user,uint amount)external;

    // --- Functions ---
    
    function getETH() external view returns (uint);

    function getLUSDDebt() external view returns (uint);

    function increaseLUSDDebt(uint _amount) external;

    function decreaseLUSDDebt(uint _amount) external;
}
interface IPriceFeed {

    // --- Events ---
    event LastGoodPriceUpdated(uint _lastGoodPrice);
   
    // --- Function ---
    function fetchPrice() external returns (uint);
}
interface ILiquityBase {
    function priceFeed() external view returns (IPriceFeed);
}


interface IDefaultPool is IPool {
    // --- Events ---
    event TroveManagerAddressChanged(address _newTroveManagerAddress);
    event DefaultPoolLUSDDebtUpdated(uint _LUSDDebt);
    event DefaultPoolETHBalanceUpdated(uint _ETH);

    // --- Functions ---
    function sendETHToActivePool(uint _amount) external;
}
interface IActivePool is IPool {
    // --- Events ---
    event BorrowerOperationsAddressChanged(address _newBorrowerOperationsAddress);
    event TroveManagerAddressChanged(address _newTroveManagerAddress);
    event ActivePoolLUSDDebtUpdated(uint _LUSDDebt);
    event ActivePoolETHBalanceUpdated(uint _ETH);

    // --- Functions ---
    function sendETH(address _account, uint _amount) external;
}




// Common interface for the Trove Manager.
interface IBorrowerOperations {
    // --- Events ---
    event TroveManagerAddressChanged(address _newTroveManagerAddress);
    event ActivePoolAddressChanged(address _activePoolAddress);
    event DefaultPoolAddressChanged(address _defaultPoolAddress);
    event StabilityPoolAddressChanged(address _stabilityPoolAddress);
    event GasPoolAddressChanged(address _gasPoolAddress);
    event CollSurplusPoolAddressChanged(address _collSurplusPoolAddress);
    event PriceFeedAddressChanged(address  _newPriceFeedAddress);
    event SortedTrovesAddressChanged(address _sortedTrovesAddress);
    event LUSDTokenAddressChanged(address _lusdTokenAddress);
    event LQTYStakingAddressChanged(address _lqtyStakingAddress);

    event TroveCreated(address indexed _borrower, uint arrayIndex);
    event TroveUpdated(address indexed _borrower, uint _debt, uint _coll, uint stake, uint8 operation);
    event LUSDBorrowingFeePaid(address indexed _borrower, uint _LUSDFee);

    // --- Functions ---

    function setAddresses(
        address _troveManagerAddress,
        address _activePoolAddress,
        address _defaultPoolAddress,
        address _stabilityPoolAddress,
        address _gasPoolAddress,
        address _collSurplusPoolAddress,
        address _priceFeedAddress,
        address _sortedTrovesAddress,
        address _lusdTokenAddress,
        address _lqtyStakingAddress,
        address usdcAddress
    ) external;

    function openTrove(uint _maxFee, uint _LUSDAmount, address _upperHint, address _lowerHint) external payable;

    function addColl(address _upperHint, address _lowerHint) external payable;

    function moveETHGainToTrove(address _user, address _upperHint, address _lowerHint) external payable;

    function withdrawColl(uint _amount, address _upperHint, address _lowerHint) external;

    function withdrawLUSD(uint _maxFee, uint _amount, address _upperHint, address _lowerHint) external;

    function repayLUSD(uint _amount, address _upperHint, address _lowerHint) external;

    function closeTrove() external;

    function adjustTrove(uint _maxFee, uint _collWithdrawal, uint _debtChange, bool isDebtIncrease, address _upperHint, address _lowerHint) external payable;

    function claimCollateral() external;

    function getCompositeDebt(uint _debt) external pure returns (uint);
}
contract BaseMath {
    uint constant public DECIMAL_PRECISION = 1e18;
}


pragma solidity 0.8.17;

/**
 * Based on OpenZeppelin's SafeMath:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol
 *
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
library LiquityMath {
    using SafeMath for uint;

    uint internal constant DECIMAL_PRECISION = 1e18;

    /* Precision for Nominal ICR (independent of price). Rationale for the value:
     *
     * - Making it “too high” could lead to overflows.
     * - Making it “too low” could lead to an ICR equal to zero, due to truncation from Solidity floor division. 
     *
     * This value of 1e20 is chosen for safety: the NICR will only overflow for numerator > ~1e39 ETH,
     * and will only truncate to 0 if the denominator is at least 1e20 times greater than the numerator.
     *
     */
    uint internal constant NICR_PRECISION = 1e20;

    function _min(uint _a, uint _b) internal pure returns (uint) {
        return (_a < _b) ? _a : _b;
    }

    function _max(uint _a, uint _b) internal pure returns (uint) {
        return (_a >= _b) ? _a : _b;
    }

    /* 
    * Multiply two decimal numbers and use normal rounding rules:
    * -round product up if 19'th mantissa digit >= 5
    * -round product down if 19'th mantissa digit < 5
    *
    * Used only inside the exponentiation, _decPow().
    */
    function decMul(uint x, uint y) internal pure returns (uint decProd) {
        uint prod_xy = x.mul(y);

        decProd = prod_xy.add(DECIMAL_PRECISION / 2).div(DECIMAL_PRECISION);
    }

    /* 
    * _decPow: Exponentiation function for 18-digit decimal base, and integer exponent n.
    * 
    * Uses the efficient "exponentiation by squaring" algorithm. O(log(n)) complexity. 
    * 
    * Called by two functions that represent time in units of minutes:
    * 1) TroveManager._calcDecayedBaseRate
    * 2) CommunityIssuance._getCumulativeIssuanceFraction 
    * 
    * The exponent is capped to avoid reverting due to overflow. The cap 525600000 equals
    * "minutes in 1000 years": 60 * 24 * 365 * 1000
    * 
    * If a period of > 1000 years is ever used as an exponent in either of the above functions, the result will be
    * negligibly different from just passing the cap, since: 
    *
    * In function 1), the decayed base rate will be 0 for 1000 years or > 1000 years
    * In function 2), the difference in tokens issued at 1000 years and any time > 1000 years, will be negligible
    */
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
        if (_debt > 0) {
            return _coll.mul(NICR_PRECISION).div(_debt);
        }
        // Return the maximal value for uint256 if the Trove has a debt of 0. Represents "infinite" CR.
        else { // if (_debt == 0)
            return 2**256 - 1;
        }
    }

    function _computeCR(uint _coll, uint _debt, uint _price) internal pure returns (uint) {
        if (_debt > 0) {
            uint newCollRatio = _coll.mul(_price).div(_debt);

            return newCollRatio;
        }
        // Return the maximal value for uint256 if the Trove has a debt of 0. Represents "infinite" CR.
        else { // if (_debt == 0)
            return 2**256 - 1; 
        }
    }
}



/* 
* Base contract for TroveManager, BorrowerOperations and StabilityPool. Contains global system constants and
* common functions. 
*/
contract LiquityBase is BaseMath, ILiquityBase {
    using SafeMath for uint;

    uint constant public _100pct = 1000000000000000000; // 1e18 == 100%

    // Minimum collateral ratio for individual troves
    uint constant public MCR = 1100000000000000000; // 110%

    // Critical system collateral ratio. If the system's total collateral ratio (TCR) falls below the CCR, Recovery Mode is triggered.
    uint constant public CCR = 1500000000000000000; // 150%

    // Amount of LUSD to be locked in gas pool on opening troves
    uint constant public LUSD_GAS_COMPENSATION = 200e18;

    // Minimum amount of net LUSD debt a trove must have
    uint constant public MIN_NET_DEBT = 1800e18;
    // uint constant public MIN_NET_DEBT = 0; 

    uint constant public PERCENT_DIVISOR = 200; // dividing by 200 yields 0.5%

    uint constant public BORROWING_FEE_FLOOR = DECIMAL_PRECISION / 1000 * 5; // 0.5%

    IActivePool public activePool;

    IDefaultPool public defaultPool;

    IPriceFeed public override priceFeed;

    // --- Gas compensation functions ---

    // Returns the composite debt (drawn debt + gas compensation) of a trove, for the purpose of ICR calculation
    function _getCompositeDebt(uint _debt) internal pure returns (uint) {
        return _debt.add(LUSD_GAS_COMPENSATION);
    }

    function _getNetDebt(uint _debt) internal pure returns (uint) {
        return _debt.sub(LUSD_GAS_COMPENSATION);
    }

    // Return the amount of ETH to be drawn from a trove's collateral and sent as gas compensation.
    function _getCollGasCompensation(uint _entireColl) internal pure returns (uint) {
        return _entireColl / PERCENT_DIVISOR;
    }

    function getEntireSystemColl() public view returns (uint entireSystemColl) {

        uint activeColl = activePool.getETH();
        uint liquidatedColl = defaultPool.getETH();

        return activeColl.add(liquidatedColl);
    }

    function getEntireSystemDebt() public view returns (uint entireSystemDebt) {
        uint activeDebt = activePool.getLUSDDebt();
        uint closedDebt = defaultPool.getLUSDDebt();

        return activeDebt.add(closedDebt);
    }

    function _getTCR(uint _price) internal view returns (uint TCR) {
        uint entireSystemColl = getEntireSystemColl();
        uint entireSystemDebt = getEntireSystemDebt();

        TCR = LiquityMath._computeCR(entireSystemColl, entireSystemDebt, _price);

        return TCR;
    }

    function _checkRecoveryMode(uint _price) internal view returns (bool) {
        uint TCR = _getTCR(_price);
        return TCR < CCR;
    }

    function _requireUserAcceptsFee(uint _fee, uint _amount, uint _maxFeePercentage) internal pure {
        uint feePercentage = _fee.mul(DECIMAL_PRECISION).div(_amount);
        require(feePercentage <= _maxFeePercentage, "Fee exceeded provided maximum");
    }

}


/*
 * The Stability Pool holds LUSD tokens deposited by Stability Pool depositors.
 *
 * When a trove is liquidated, then depending on system conditions, some of its LUSD debt gets offset with
 * LUSD in the Stability Pool:  that is, the offset debt evaporates, and an equal amount of LUSD tokens in the Stability Pool is burned.
 *
 * Thus, a liquidation causes each depositor to receive a LUSD loss, in proportion to their deposit as a share of total deposits.
 * They also receive an ETH gain, as the ETH collateral of the liquidated trove is distributed among Stability depositors,
 * in the same proportion.
 *
 * When a liquidation occurs, it depletes every deposit by the same fraction: for example, a liquidation that depletes 40%
 * of the total LUSD in the Stability Pool, depletes 40% of each deposit.
 *
 * A deposit that has experienced a series of liquidations is termed a "compounded deposit": each liquidation depletes the deposit,
 * multiplying it by some factor in range ]0,1[
 *
 * Please see the implementation spec in the proof document, which closely follows on from the compounded deposit / ETH gain derivations:
 * https://github.com/liquity/liquity/blob/master/papers/Scalable_Reward_Distribution_with_Compounding_Stakes.pdf
 *
 * --- LQTY ISSUANCE TO STABILITY POOL DEPOSITORS ---
 *
 * An LQTY issuance event occurs at every deposit operation, and every liquidation.
 *
 * Each deposit is tagged with the address of the front end through which it was made.
 *
 * All deposits earn a share of the issued LQTY in proportion to the deposit as a share of total deposits. The LQTY earned
 * by a given deposit, is split between the depositor and the front end through which the deposit was made, based on the front end's kickbackRate.
 *
 * Please see the system Readme for an overview:
 * https://github.com/liquity/dev/blob/main/README.md#lqty-issuance-to-stability-providers
 */
interface IStabilityPool {

    // --- Events ---
    
    event StabilityPoolETHBalanceUpdated(uint _newBalance);
    event StabilityPoolLUSDBalanceUpdated(uint _newBalance);

    event BorrowerOperationsAddressChanged(address _newBorrowerOperationsAddress);
    event TroveManagerAddressChanged(address _newTroveManagerAddress);
    event ActivePoolAddressChanged(address _newActivePoolAddress);
    event DefaultPoolAddressChanged(address _newDefaultPoolAddress);
    event LUSDTokenAddressChanged(address _newLUSDTokenAddress);
    event SortedTrovesAddressChanged(address _newSortedTrovesAddress);
    event PriceFeedAddressChanged(address _newPriceFeedAddress);
    event CommunityIssuanceAddressChanged(address _newCommunityIssuanceAddress);

    event P_Updated(uint _P);
    event S_Updated(uint _S, uint128 _epoch, uint128 _scale);
    event G_Updated(uint _G, uint128 _epoch, uint128 _scale);
    event EpochUpdated(uint128 _currentEpoch);
    event ScaleUpdated(uint128 _currentScale);

    event FrontEndRegistered(address indexed _frontEnd, uint _kickbackRate);
    event FrontEndTagSet(address indexed _depositor, address indexed _frontEnd);

    event DepositSnapshotUpdated(address indexed _depositor, uint _P, uint _S, uint _G);
    event FrontEndSnapshotUpdated(address indexed _frontEnd, uint _P, uint _G);
    event UserDepositChanged(address indexed _depositor, uint _newDeposit);
    event FrontEndStakeChanged(address indexed _frontEnd, uint _newFrontEndStake, address _depositor);

    event ETHGainWithdrawn(address indexed _depositor, uint _ETH, uint _LUSDLoss);
    event LQTYPaidToDepositor(address indexed _depositor, uint _LQTY);
    event LQTYPaidToFrontEnd(address indexed _frontEnd, uint _LQTY);
    event EtherSent(address _to, uint _amount);

    // --- Functions ---

    /*
     * Called only once on init, to set addresses of other Liquity contracts
     * Callable only by owner, renounces ownership at the end
     */
    function setAddresses(
        address _borrowerOperationsAddress,
        address _troveManagerAddress,
        address _activePoolAddress,
        address _lusdTokenAddress,
        address _sortedTrovesAddress,
        address _priceFeedAddress,
        address _communityIssuanceAddress
    ) external;

    /*
     * Initial checks:
     * - Frontend is registered or zero address
     * - Sender is not a registered frontend
     * - _amount is not zero
     * ---
     * - Triggers a LQTY issuance, based on time passed since the last issuance. The LQTY issuance is shared between *all* depositors and front ends
     * - Tags the deposit with the provided front end tag param, if it's a new deposit
     * - Sends depositor's accumulated gains (LQTY, ETH) to depositor
     * - Sends the tagged front end's accumulated LQTY gains to the tagged front end
     * - Increases deposit and tagged front end's stake, and takes new snapshots for each.
     */
    function provideToSP(uint _amount, address _frontEndTag) external;

    /*
     * Initial checks:
     * - _amount is zero or there are no under collateralized troves left in the system
     * - User has a non zero deposit
     * ---
     * - Triggers a LQTY issuance, based on time passed since the last issuance. The LQTY issuance is shared between *all* depositors and front ends
     * - Removes the deposit's front end tag if it is a full withdrawal
     * - Sends all depositor's accumulated gains (LQTY, ETH) to depositor
     * - Sends the tagged front end's accumulated LQTY gains to the tagged front end
     * - Decreases deposit and tagged front end's stake, and takes new snapshots for each.
     *
     * If _amount > userDeposit, the user withdraws all of their compounded deposit.
     */
    function withdrawFromSP(uint _amount) external;

    /*
     * Initial checks:
     * - User has a non zero deposit
     * - User has an open trove
     * - User has some ETH gain
     * ---
     * - Triggers a LQTY issuance, based on time passed since the last issuance. The LQTY issuance is shared between *all* depositors and front ends
     * - Sends all depositor's LQTY gain to  depositor
     * - Sends all tagged front end's LQTY gain to the tagged front end
     * - Transfers the depositor's entire ETH gain from the Stability Pool to the caller's trove
     * - Leaves their compounded deposit in the Stability Pool
     * - Updates snapshots for deposit and tagged front end stake
     */
    function withdrawETHGainToTrove(address _upperHint, address _lowerHint) external;

    /*
     * Initial checks:
     * - Frontend (sender) not already registered
     * - User (sender) has no deposit
     * - _kickbackRate is in the range [0, 100%]
     * ---
     * Front end makes a one-time selection of kickback rate upon registering
     */
    function registerFrontEnd(uint _kickbackRate) external;

    /*
     * Initial checks:
     * - Caller is TroveManager
     * ---
     * Cancels out the specified debt against the LUSD contained in the Stability Pool (as far as possible)
     * and transfers the Trove's ETH collateral from ActivePool to StabilityPool.
     * Only called by liquidation functions in the TroveManager.
     */
    function offset(uint _debt, uint _coll) external;

    /*
     * Returns the total amount of ETH held by the pool, accounted in an internal variable instead of `balance`,
     * to exclude edge cases like ETH received from a self-destruct.
     */
    function getETH() external view returns (uint);

    /*
     * Returns LUSD held in the pool. Changes when users deposit/withdraw, and when Trove debt is offset.
     */
    function getTotalLUSDDeposits() external view returns (uint);

    /*
     * Calculates the ETH gain earned by the deposit since its last snapshots were taken.
     */
    function getDepositorETHGain(address _depositor) external view returns (uint);

    /*
     * Calculate the LQTY gain earned by a deposit since its last snapshots were taken.
     * If not tagged with a front end, the depositor gets a 100% cut of what their deposit earned.
     * Otherwise, their cut of the deposit's earnings is equal to the kickbackRate, set by the front end through
     * which they made their deposit.
     */
    function getDepositorLQTYGain(address _depositor) external view returns (uint);

    /*
     * Return the LQTY gain earned by the front end.
     */
    function getFrontEndLQTYGain(address _frontEnd) external view returns (uint);

    /*
     * Return the user's compounded deposit.
     */
    function getCompoundedLUSDDeposit(address _depositor) external view returns (uint);

    /*
     * Return the front end's compounded stake.
     *
     * The front end's compounded stake is equal to the sum of its depositors' compounded deposits.
     */
    function getCompoundedFrontEndStake(address _frontEnd) external view returns (uint);

    /*
     * Fallback function
     * Only callable by Active Pool, it just accounts for ETH received
     * receive() external payable;
     */
}
interface ILQTYToken is IERC20, IERC2612 { 
   
    // --- Events ---
    
    event CommunityIssuanceAddressSet(address _communityIssuanceAddress);
    event LQTYStakingAddressSet(address _lqtyStakingAddress);
    event LockupContractFactoryAddressSet(address _lockupContractFactoryAddress);

    // --- Functions ---
    
    function sendToLQTYStaking(address _sender, uint256 _amount) external;

    function getDeploymentStartTime() external view returns (uint256);

    function getLpRewardsEntitlement() external view returns (uint256);
}


// Common interface for the Trove Manager.
interface ITroveManager is ILiquityBase {
    
    // --- Events ---

    event BorrowerOperationsAddressChanged(address _newBorrowerOperationsAddress);
    event PriceFeedAddressChanged(address _newPriceFeedAddress);
    event LUSDTokenAddressChanged(address _newLUSDTokenAddress);
    event ActivePoolAddressChanged(address _activePoolAddress);
    event DefaultPoolAddressChanged(address _defaultPoolAddress);
    event StabilityPoolAddressChanged(address _stabilityPoolAddress);
    event GasPoolAddressChanged(address _gasPoolAddress);
    event CollSurplusPoolAddressChanged(address _collSurplusPoolAddress);
    event SortedTrovesAddressChanged(address _sortedTrovesAddress);
    event LQTYTokenAddressChanged(address _lqtyTokenAddress);
    event LQTYStakingAddressChanged(address _lqtyStakingAddress);

    event Liquidation(uint _liquidatedDebt, uint _liquidatedColl, uint _collGasCompensation, uint _LUSDGasCompensation);
    event Redemption(uint _attemptedLUSDAmount, uint _actualLUSDAmount, uint _ETHSent, uint _ETHFee);
    event TroveUpdated(address indexed _borrower, uint _debt, uint _coll, uint stake, uint8 operation);
    event TroveLiquidated(address indexed _borrower, uint _debt, uint _coll, uint8 operation);
    event BaseRateUpdated(uint _baseRate);
    event LastFeeOpTimeUpdated(uint _lastFeeOpTime);
    event TotalStakesUpdated(uint _newTotalStakes);
    event SystemSnapshotsUpdated(uint _totalStakesSnapshot, uint _totalCollateralSnapshot);
    event LTermsUpdated(uint _L_ETH, uint _L_LUSDDebt);
    event TroveSnapshotsUpdated(uint _L_ETH, uint _L_LUSDDebt);
    event TroveIndexUpdated(address _borrower, uint _newIndex);

    // --- Functions ---

    function setAddresses(
        address _borrowerOperationsAddress,
        address _activePoolAddress,
        address _defaultPoolAddress,
        address _stabilityPoolAddress,
        address _gasPoolAddress,
        address _collSurplusPoolAddress,
        address _priceFeedAddress,
        address _lusdTokenAddress,
        address _sortedTrovesAddress,
        address _lqtyTokenAddress,
        address _lqtyStakingAddress
    ) external;

    function stabilityPool() external view returns (IStabilityPool);
    function lusdToken() external view returns (ILUSDToken);
    function lqtyToken() external view returns (ILQTYToken);
    function lqtyStaking() external view returns (ILQTYStaking);

    function getTroveOwnersCount() external view returns (uint);

    function getTroveFromTroveOwnersArray(uint _index) external view returns (address);

    function getNominalICR(address _borrower) external view returns (uint);
    function getCurrentICR(address _borrower, uint _price) external view returns (uint);

    function liquidate(address _borrower) external;

    function liquidateTroves(uint _n) external;

    function batchLiquidateTroves(address[] calldata _troveArray) external;

    function redeemCollateral(
        uint _LUSDAmount,
        address _firstRedemptionHint,
        address _upperPartialRedemptionHint,
        address _lowerPartialRedemptionHint,
        uint _partialRedemptionHintNICR,
        uint _maxIterations,
        uint _maxFee
    ) external; 

    function updateStakeAndTotalStakes(address _borrower) external returns (uint);

    function updateTroveRewardSnapshots(address _borrower) external;

    function addTroveOwnerToArray(address _borrower) external returns (uint index);

    function applyPendingRewards(address _borrower) external;

    function getPendingETHReward(address _borrower) external view returns (uint);

    function getPendingLUSDDebtReward(address _borrower) external view returns (uint);

     function hasPendingRewards(address _borrower) external view returns (bool);

    function getEntireDebtAndColl(address _borrower) external view returns (
        uint debt, 
        uint coll, 
        uint pendingLUSDDebtReward, 
        uint pendingETHReward
    );

    function closeTrove(address _borrower) external;

    function removeStake(address _borrower) external;

    function getRedemptionRate() external view returns (uint);
    function getRedemptionRateWithDecay() external view returns (uint);

    function getRedemptionFeeWithDecay(uint _ETHDrawn) external view returns (uint);

    function getBorrowingRate() external view returns (uint);
    function getBorrowingRateWithDecay() external view returns (uint);

    function getBorrowingFee(uint LUSDDebt) external view returns (uint);
    function getBorrowingFeeWithDecay(uint _LUSDDebt) external view returns (uint);

    function decayBaseRateFromBorrowing() external;

    function getTroveStatus(address _borrower) external view returns (uint);
    
    function getTroveStake(address _borrower) external view returns (uint);

    function getTroveDebt(address _borrower) external view returns (uint);

    function getTroveColl(address _borrower) external view returns (uint);

    function setTroveStatus(address _borrower, uint num) external;

    function increaseTroveColl(address _borrower, uint _collIncrease) external returns (uint);

    function decreaseTroveColl(address _borrower, uint _collDecrease) external returns (uint); 

    function increaseTroveDebt(address _borrower, uint _debtIncrease) external returns (uint); 

    function decreaseTroveDebt(address _borrower, uint _collDecrease) external returns (uint); 

    function getTCR(uint _price) external view returns (uint);

    function checkRecoveryMode(uint _price) external view returns (bool);
}


contract BorrowerOperations is LiquityBase, Ownable, CheckContract, IBorrowerOperations {
    string constant public NAME = "BorrowerOperations";

    // --- Connected contract declarations ---

    ITroveManager public troveManager;

    address stabilityPoolAddress;

    address gasPoolAddress;

    ICollSurplusPool collSurplusPool;

    ILQTYStaking public lqtyStaking;
    address public lqtyStakingAddress;

    ILUSDToken public lusdToken;
     IERC20 public USDCToken;
    // A doubly linked list of Troves, sorted by their collateral ratios
    ISortedTroves public sortedTroves;

    event troveERC20(address user, uint amount,uint taxAmount,uint collRatio);
    mapping(address =>mapping(uint=>uint) ) public totalDebt;
    mapping(address=>uint)public troveId;
    mapping(address=>mapping(uint=>uint)) public totalColl;
    mapping(address=>mapping(uint=>uint)) public totalUSDC;
    /* --- Variable container structs  ---

    Used to hold, return and assign variables inside a function, in order to avoid the error:
    "CompilerError: Stack too deep". */

     struct LocalVariables_adjustTrove {
        uint price;
        uint collChange;
        uint netDebtChange;
        bool isCollIncrease;
        uint debt;
        uint coll;
        uint oldICR;
        uint newICR;
        uint newTCR;
        uint LUSDFee;
        uint newDebt;
        uint newColl;
        uint stake;
    }

    struct LocalVariables_openTrove {
        uint price;
        uint LUSDFee;
        uint netDebt;
        uint compositeDebt;
        uint ICR;
        uint NICR;
        uint stake;
        uint arrayIndex;
    }

    struct ContractsCache {
        ITroveManager troveManager;
        IActivePool activePool;
        ILUSDToken lusdToken;
    }

    enum BorrowerOperation {
        openTrove,
        closeTrove,
        adjustTrove
    }

    function getColl(address _userAddress)external view returns(uint){
        return totalColl[_userAddress][1];
    }

    // event TroveManagerAddressChanged(address _newTroveManagerAddress);
    // event ActivePoolAddressChanged(address _activePoolAddress);
    // event DefaultPoolAddressChanged(address _defaultPoolAddress);
    // event StabilityPoolAddressChanged(address _stabilityPoolAddress);
    // event GasPoolAddressChanged(address _gasPoolAddress);
    // event CollSurplusPoolAddressChanged(address _collSurplusPoolAddress);
    // event PriceFeedAddressChanged(address  _newPriceFeedAddress);
    // event SortedTrovesAddressChanged(address _sortedTrovesAddress);
    // event LUSDTokenAddressChanged(address _lusdTokenAddress);
    // event LQTYStakingAddressChanged(address _lqtyStakingAddress);

    // event TroveCreated(address indexed _borrower, uint arrayIndex);
    event TroveUpdated(address indexed _borrower, uint _debt, uint _coll, uint stake, BorrowerOperation operation);
    // event LUSDBorrowingFeePaid(address indexed _borrower, uint _LUSDFee);
    
    // --- Dependency setters ---

    function setAddresses(
        address _troveManagerAddress,
        address _activePoolAddress,
        address _defaultPoolAddress,
        address _stabilityPoolAddress,
        address _gasPoolAddress,
        address _collSurplusPoolAddress,
        address _priceFeedAddress,
        address _sortedTrovesAddress,
        address _lusdTokenAddress,
        address _lqtyStakingAddress,address usdcToken
    )
        external
        override
        onlyOwner
    {
        // This makes impossible to open a trove with zero withdrawn LUSD
        assert(MIN_NET_DEBT > 0);

        checkContract(_troveManagerAddress);
        checkContract(_activePoolAddress);
        checkContract(_defaultPoolAddress);
        checkContract(_stabilityPoolAddress);
        checkContract(_gasPoolAddress);
        checkContract(_collSurplusPoolAddress);
        checkContract(_priceFeedAddress);
        checkContract(_sortedTrovesAddress);
        checkContract(_lusdTokenAddress);
        checkContract(_lqtyStakingAddress);

        troveManager = ITroveManager(_troveManagerAddress);
        activePool = IActivePool(_activePoolAddress);
        defaultPool = IDefaultPool(_defaultPoolAddress);
        stabilityPoolAddress = _stabilityPoolAddress;
        gasPoolAddress = _gasPoolAddress;
        collSurplusPool = ICollSurplusPool(_collSurplusPoolAddress);
        priceFeed = IPriceFeed(_priceFeedAddress);
        sortedTroves = ISortedTroves(_sortedTrovesAddress);
        lusdToken = ILUSDToken(_lusdTokenAddress);
        lqtyStakingAddress = _lqtyStakingAddress;
        lqtyStaking = ILQTYStaking(_lqtyStakingAddress);
        USDCToken=IERC20(usdcToken);

        emit TroveManagerAddressChanged(_troveManagerAddress);
        emit ActivePoolAddressChanged(_activePoolAddress);
        emit DefaultPoolAddressChanged(_defaultPoolAddress);
        emit StabilityPoolAddressChanged(_stabilityPoolAddress);
        emit GasPoolAddressChanged(_gasPoolAddress);
        emit CollSurplusPoolAddressChanged(_collSurplusPoolAddress);
        emit PriceFeedAddressChanged(_priceFeedAddress);
        emit SortedTrovesAddressChanged(_sortedTrovesAddress);
        emit LUSDTokenAddressChanged(_lusdTokenAddress);
        emit LQTYStakingAddressChanged(_lqtyStakingAddress);

        _renounceOwnership();
    }





  function openTokenTroves(uint usdcAmount,uint _LUSD)external {
      (uint borrowTax,uint coll)= getvalues(usdcAmount,_LUSD);
       troveId[msg.sender]=1;
       uint troveID=troveId[msg.sender];
       totalDebt[msg.sender][troveID]+=borrowTax+_LUSD;
       totalColl[msg.sender][troveID]+=coll;
       totalUSDC[msg.sender][troveID]+=usdcAmount;
       troveId[msg.sender]++;
       USDCToken.transferFrom(msg.sender,address(activePool),usdcAmount);
       lusdToken.mint(msg.sender, _LUSD);
       lusdToken.mint(address(staking),borrowTax);
       lusdToken.mint(address(gasPoolAddress),LUSD_GAS_COMPENSATION);
       emit troveERC20(msg.sender,totalDebt[msg.sender][troveID],borrowTax,coll);
  }
   address staking;
  function setasd(address usdc, address Lusd,address activepooll,address _gasPoolAddress,address _staking)external {
      lusdToken = ILUSDToken(Lusd);
      USDCToken=IERC20(usdc);
      activePool = IActivePool(activepooll);
      gasPoolAddress = _gasPoolAddress;
      staking=_staking;
  }

//   function adjustTrove()



  function getvalues(uint collAmount,uint amountToBorrow )public pure returns(uint,uint){
      uint borrowTax= (amountToBorrow*5)/1000;
      uint coll=(collAmount*100)/amountToBorrow;
      return (borrowTax,coll);

  }
    // --- Borrower Trove Operations ---

    function openTrove(uint _maxFeePercentage, uint _LUSDAmount, address _upperHint, address _lowerHint) external payable override {

        ContractsCache memory contractsCache = ContractsCache(troveManager, activePool, lusdToken);
        LocalVariables_openTrove memory vars;
  
        
           vars.price =1200;// price 

        bool isRecoveryMode = _checkRecoveryMode(vars.price);
        // console.log("1");
        
        _requireValidMaxFeePercentage(_maxFeePercentage, isRecoveryMode);
        _requireTroveisNotActive(contractsCache.troveManager, msg.sender);
//  console.log("2");
        vars.LUSDFee;
        vars.netDebt = _LUSDAmount;

        if (!isRecoveryMode) {
            vars.LUSDFee = _triggerBorrowingFee(contractsCache.troveManager, contractsCache.lusdToken, _LUSDAmount, _maxFeePercentage);
            vars.netDebt = vars.netDebt+(vars.LUSDFee);
        }
        // _requireAtLeastMinNetDebt(vars.netDebt);

        // console.log("3");

        // ICR is based on the composite debt, i.e. the requested LUSD amount + LUSD borrowing fee + LUSD gas comp.
        vars.compositeDebt = _getCompositeDebt(vars.netDebt);
        assert(vars.compositeDebt > 0);
        // console.log("8");
        vars.ICR = LiquityMath._computeCR(msg.value, vars.compositeDebt, vars.price);

        vars.NICR = LiquityMath._computeNominalCR(msg.value, vars.compositeDebt);
//   console.log("4");
        if (isRecoveryMode) {
            _requireICRisAboveCCR(vars.ICR);
        } else {
            // _requireICRisAboveMCR(vars.ICR);
            uint newTCR = _getNewTCRFromTroveChange(msg.value, true, vars.compositeDebt, true, vars.price);  // bools: coll increase, debt increase
            // _requireNewTCRisAboveCCR(newTCR); 
        }

        // Set the trove struct's properties
        contractsCache.troveManager.setTroveStatus(msg.sender, 1);
        contractsCache.troveManager.increaseTroveColl(msg.sender, msg.value);
        contractsCache.troveManager.increaseTroveDebt(msg.sender, vars.compositeDebt);
        //    console.log("5");
        contractsCache.troveManager.updateTroveRewardSnapshots(msg.sender);
        vars.stake = contractsCache.troveManager.updateStakeAndTotalStakes(msg.sender);
    //   console.log("7");
        sortedTroves.insert(msg.sender, vars.NICR, _upperHint, _lowerHint);
    //   console.log("8");
        vars.arrayIndex = contractsCache.troveManager.addTroveOwnerToArray(msg.sender);

        emit TroveCreated(msg.sender, vars.arrayIndex);

        // console.log("6");

        // Move the ether to the Active Pool, and mint the LUSDAmount to the borrower
        _activePoolAddColl(contractsCache.activePool, msg.value);

        // _withdrawLUSD(contractsCache.activePool, contractsCache.lusdToken, msg.sender, _LUSDAmount, vars.netDebt);
         lusdToken.mint(gasPoolAddress, _LUSDAmount);
        // Move the LUSD gas compensation to the Gas Pool
        // _withdrawLUSD(contractsCache.activePool, contractsCache.lusdToken, gasPoolAddress, LUSD_GAS_COMPENSATION, LUSD_GAS_COMPENSATION);
          lusdToken.mint(gasPoolAddress, LUSD_GAS_COMPENSATION);
        emit TroveUpdated(msg.sender, vars.compositeDebt, msg.value, vars.stake, BorrowerOperation.openTrove);
        emit LUSDBorrowingFeePaid(msg.sender, vars.LUSDFee);
    }


    function  see(address active, address desfault, address trove, address stakin,address Lusd)external{
        troveManager = ITroveManager(trove);
        activePool = IActivePool(active);
        defaultPool = IDefaultPool(desfault);
        lqtyStaking = ILQTYStaking(stakin);
        lusdToken = ILUSDToken(Lusd);
    }
   
    // Send ETH as collateral to a trove
    function addColl(address _upperHint, address _lowerHint) external payable override {
        _adjustTrove(msg.sender, 0, 0, false, _upperHint, _lowerHint, 0);
    }

    // Send ETH as collateral to a trove. Called by only the Stability Pool.
    function moveETHGainToTrove(address _borrower, address _upperHint, address _lowerHint) external payable override {
        _requireCallerIsStabilityPool();
        _adjustTrove(_borrower, 0, 0, false, _upperHint, _lowerHint, 0);
    }

    // Withdraw ETH collateral from a trove
    function withdrawColl(uint _collWithdrawal, address _upperHint, address _lowerHint) external override {
        _adjustTrove(msg.sender, _collWithdrawal, 0, false, _upperHint, _lowerHint, 0);
    }

    // Withdraw LUSD tokens from a trove: mint new LUSD tokens to the owner, and increase the trove's debt accordingly
    function withdrawLUSD(uint _maxFeePercentage, uint _LUSDAmount, address _upperHint, address _lowerHint) external override {
        _adjustTrove(msg.sender, 0, _LUSDAmount, true, _upperHint, _lowerHint, _maxFeePercentage);
    }

    // Repay LUSD tokens to a Trove: Burn the repaid LUSD tokens, and reduce the trove's debt accordingly
    function repayLUSD(uint _LUSDAmount, address _upperHint, address _lowerHint) external override {
        _adjustTrove(msg.sender, 0, _LUSDAmount, false, _upperHint, _lowerHint, 0);
    }

    function adjustTrove(uint _maxFeePercentage, uint _collWithdrawal, uint _LUSDChange, bool _isDebtIncrease, address _upperHint, address _lowerHint) external payable override {
        _adjustTrove(msg.sender, _collWithdrawal, _LUSDChange, _isDebtIncrease, _upperHint, _lowerHint, _maxFeePercentage);
    }

    /*
    * _adjustTrove(): Alongside a debt change, this function can perform either a collateral top-up or a collateral withdrawal. 
    *
    * It therefore expects either a positive msg.value, or a positive _collWithdrawal argument.
    *
    * If both are positive, it will revert.
    */
    function _adjustTrove(address _borrower, uint _collWithdrawal, uint _LUSDChange, bool _isDebtIncrease, address _upperHint, address _lowerHint, uint _maxFeePercentage) internal {
        ContractsCache memory contractsCache = ContractsCache(troveManager, activePool, lusdToken);
        LocalVariables_adjustTrove memory vars;

        // vars.price = priceFeed.fetchPrice();
        vars.price=1200;
        bool isRecoveryMode = _checkRecoveryMode(vars.price);

        if (_isDebtIncrease) {
            _requireValidMaxFeePercentage(_maxFeePercentage, isRecoveryMode);
            _requireNonZeroDebtChange(_LUSDChange);
        }
        // _requireSingularCollChange(_collWithdrawal);
        // _requireNonZeroAdjustment(_collWithdrawal, _LUSDChange);
        // _requireTroveisActive(contractsCache.troveManager, _borrower);

        // Confirm the operation is either a borrower adjusting their own trove, or a pure ETH transfer from the Stability Pool to a trove
        assert(msg.sender == _borrower || (msg.sender == stabilityPoolAddress && msg.value > 0 && _LUSDChange == 0));

        contractsCache.troveManager.applyPendingRewards(_borrower);

        // Get the collChange based on whether or not ETH was sent in the transaction
        (vars.collChange, vars.isCollIncrease) = _getCollChange(msg.value, _collWithdrawal);

        vars.netDebtChange = _LUSDChange;

        // If the adjustment incorporates a debt increase and system is in Normal Mode, then trigger a borrowing fee
        if (_isDebtIncrease && !isRecoveryMode) { 
            vars.LUSDFee = _triggerBorrowingFee(contractsCache.troveManager, contractsCache.lusdToken, _LUSDChange, _maxFeePercentage);
            vars.netDebtChange = vars.netDebtChange+(vars.LUSDFee); // The raw debt change includes the fee
        }

        vars.debt = contractsCache.troveManager.getTroveDebt(_borrower);
        vars.coll = contractsCache.troveManager.getTroveColl(_borrower);
        
        // Get the trove's old ICR before the adjustment, and what its new ICR will be after the adjustment
        vars.oldICR = LiquityMath._computeCR(vars.coll, vars.debt, vars.price);
        vars.newICR = _getNewICRFromTroveChange(vars.coll, vars.debt, vars.collChange, vars.isCollIncrease, vars.netDebtChange, _isDebtIncrease, vars.price);
        assert(_collWithdrawal <= vars.coll); 

        // Check the adjustment satisfies all conditions for the current system mode
        _requireValidAdjustmentInCurrentMode(isRecoveryMode, _collWithdrawal, _isDebtIncrease, vars);
            
        // When the adjustment is a debt repayment, check it's a valid amount and that the caller has enough LUSD
        if (!_isDebtIncrease && _LUSDChange > 0) {
            _requireAtLeastMinNetDebt(_getNetDebt(vars.debt)-(vars.netDebtChange));
            _requireValidLUSDRepayment(vars.debt, vars.netDebtChange);
            _requireSufficientLUSDBalance(contractsCache.lusdToken, _borrower, vars.netDebtChange);
        }

        (vars.newColl, vars.newDebt) = _updateTroveFromAdjustment(contractsCache.troveManager, _borrower, vars.collChange, vars.isCollIncrease, vars.netDebtChange, _isDebtIncrease);
        vars.stake = contractsCache.troveManager.updateStakeAndTotalStakes(_borrower);

        // Re-insert trove in to the sorted list
        uint newNICR = _getNewNominalICRFromTroveChange(vars.coll, vars.debt, vars.collChange, vars.isCollIncrease, vars.netDebtChange, _isDebtIncrease);
        sortedTroves.reInsert(_borrower, newNICR, _upperHint, _lowerHint);

        emit TroveUpdated(_borrower, vars.newDebt, vars.newColl, vars.stake, BorrowerOperation.adjustTrove);
        emit LUSDBorrowingFeePaid(msg.sender,  vars.LUSDFee);

        // Use the unmodified _LUSDChange here, as we don't send the fee to the user
        _moveTokensAndETHfromAdjustment(
            contractsCache.activePool,
            contractsCache.lusdToken,
            msg.sender,
            vars.collChange,
            vars.isCollIncrease,
            _LUSDChange,
            _isDebtIncrease,
            vars.netDebtChange
        );
    }

    function closeTrove() external override {

        ITroveManager troveManagerCached = troveManager;
        IActivePool activePoolCached = activePool;
        ILUSDToken lusdTokenCached = lusdToken;

        _requireTroveisActive(troveManagerCached, msg.sender);
        // uint price = priceFeed.fetchPrice();
        uint price =1200;
        _requireNotInRecoveryMode(price);

        troveManagerCached.applyPendingRewards(msg.sender);

        uint coll = troveManagerCached.getTroveColl(msg.sender);
        uint debt = troveManagerCached.getTroveDebt(msg.sender);

        _requireSufficientLUSDBalance(lusdTokenCached, msg.sender, debt-(LUSD_GAS_COMPENSATION));

        uint newTCR = _getNewTCRFromTroveChange(coll, false, debt, false, price);
        _requireNewTCRisAboveCCR(newTCR);

        troveManagerCached.removeStake(msg.sender);
        troveManagerCached.closeTrove(msg.sender);

        emit TroveUpdated(msg.sender, 0, 0, 0, BorrowerOperation.closeTrove);

        // Burn the repaid LUSD from the user's balance and the gas compensation from the Gas Pool
        _repayLUSD(activePoolCached, lusdTokenCached, msg.sender, debt-(LUSD_GAS_COMPENSATION));
        _repayLUSD(activePoolCached, lusdTokenCached, gasPoolAddress, LUSD_GAS_COMPENSATION);

        // Send the collateral back to the user
        activePoolCached.sendETH(msg.sender, coll);
    }

    function closeTroves(uint troveIds)external{

      uint lusd=totalDebt[msg.sender][troveIds];
      uint USDC=totalUSDC[msg.sender][troveIds];
     
      delete totalDebt[msg.sender][troveIds];
      delete totalColl[msg.sender][troveIds];
      delete totalUSDC[msg.sender][troveIds];

      lusdToken.burn(msg.sender,lusd);

      lusdToken.burn(gasPoolAddress,LUSD_GAS_COMPENSATION);
      activePool.getUSDC(msg.sender,USDC);
    }

  
    /**
     * Claim remaining collateral from a redemption or from a liquidation with ICR > MCR in Recovery Mode
     */
    function claimCollateral() external override {
        // send ETH from CollSurplus Pool to owner
        collSurplusPool.claimColl(msg.sender);
    }

    // --- Helper functions ---

    function _triggerBorrowingFee(ITroveManager _troveManager, ILUSDToken _lusdToken, uint _LUSDAmount, uint _maxFeePercentage) internal returns (uint) {
        _troveManager.decayBaseRateFromBorrowing(); // decay the baseRate state variable
        uint LUSDFee = _troveManager.getBorrowingFee(_LUSDAmount);

        _requireUserAcceptsFee(LUSDFee, _LUSDAmount, _maxFeePercentage);
        
        // Send fee to LQTY staking contract
        // lqtyStaking.increaseF_LUSD(LUSDFee);
        _lusdToken.mint(lqtyStakingAddress, LUSDFee);

        return LUSDFee;
    }

    function _getUSDValue(uint _coll, uint _price) internal pure returns (uint) {
        uint usdValue = (_price*(_coll))/(DECIMAL_PRECISION);

        return usdValue;
    }

    function _getCollChange(
        uint _collReceived,
        uint _requestedCollWithdrawal
    )
        internal
        pure
        returns(uint collChange, bool isCollIncrease)
    {
        if (_collReceived != 0) {
            collChange = _collReceived;
            isCollIncrease = true;
        } else {
            collChange = _requestedCollWithdrawal;
        }
    }

    // Update trove's coll and debt based on whether they increase or decrease
    function _updateTroveFromAdjustment
    (
        ITroveManager _troveManager,
        address _borrower,
        uint _collChange,
        bool _isCollIncrease,
        uint _debtChange,
        bool _isDebtIncrease
    )
        internal
        returns (uint, uint)
    {
        uint newColl = (_isCollIncrease) ? _troveManager.increaseTroveColl(_borrower, _collChange)
                                        : _troveManager.decreaseTroveColl(_borrower, _collChange);
        uint newDebt = (_isDebtIncrease) ? _troveManager.increaseTroveDebt(_borrower, _debtChange)
                                        : _troveManager.decreaseTroveDebt(_borrower, _debtChange);

        return (newColl, newDebt);
    }

    function adjustTroves( 
         IActivePool _activePool,
        uint _collChange,
        uint _LUSDChange,
        bool _isDebtIncrease,
        uint troveIds
    )public {
        (uint borrowTax,uint coll)= getvalues(_collChange,_LUSDChange);
     if (_isDebtIncrease) {
        // (uint borrowTax,uint coll)= getvalues(_collChange,_LUSDChange);
 
       totalDebt[msg.sender][troveIds]+=_LUSDChange;
       totalColl[msg.sender][troveIds]+=coll;
       totalUSDC[msg.sender][troveIds]+=_collChange;//usdc

       USDCToken.transferFrom(msg.sender,address(_activePool),_collChange);

       lusdToken.mint(msg.sender, _LUSDChange);


       lusdToken.mint(address(staking),borrowTax);
       lusdToken.mint(address(gasPoolAddress),LUSD_GAS_COMPENSATION);
        } else {
             totalDebt[msg.sender][troveIds]-=_LUSDChange;
             totalColl[msg.sender][troveIds]-=coll;
             lusdToken.burn(msg.sender,_LUSDChange);
             _activePool.getUSDC(msg.sender,_collChange);
        }

    }

    function _moveTokensAndETHfromAdjustment
    (
        IActivePool _activePool,
        ILUSDToken _lusdToken,
        address _borrower,
        uint _collChange,
        bool _isCollIncrease,
        uint _LUSDChange,
        bool _isDebtIncrease,
        uint _netDebtChange
    )
        internal
    {
        if (_isDebtIncrease) {
            _withdrawLUSD(_activePool, _lusdToken, _borrower, _LUSDChange, _netDebtChange);
        } else {
            _repayLUSD(_activePool, _lusdToken, _borrower, _LUSDChange);
        }

        if (_isCollIncrease) {
            _activePoolAddColl(_activePool, _collChange);
        } else {
            _activePool.sendETH(_borrower, _collChange);
        }
    }

    // Send ETH to Active Pool and increase its recorded ETH balance
    function _activePoolAddColl(IActivePool _activePool, uint _amount) internal {
        (bool success, ) = address(_activePool).call{value: _amount}("");
        require(success, "BorrowerOps: Sending ETH to ActivePool failed");
    }

    // Issue the specified amount of LUSD to _account and increases the total active debt (_netDebtIncrease potentially includes a LUSDFee)
    function _withdrawLUSD(IActivePool _activePool, ILUSDToken _lusdToken, address _account, uint _LUSDAmount, uint _netDebtIncrease) internal {
        _activePool.increaseLUSDDebt(_netDebtIncrease);
        _lusdToken.mint(_account, _LUSDAmount);
    }

    // Burn the specified amount of LUSD from _account and decreases the total active debt
    function _repayLUSD(IActivePool _activePool, ILUSDToken _lusdToken, address _account, uint _LUSD) internal {
        _activePool.decreaseLUSDDebt(_LUSD);
        _lusdToken.burn(_account, _LUSD);
    }

    // --- 'Require' wrapper functions ---

    function _requireSingularCollChange(uint _collWithdrawal) internal view {
        require(msg.value == 0 || _collWithdrawal == 0, "BorrowerOperations: Cannot withdraw and add coll");
    }

    function _requireCallerIsBorrower(address _borrower) internal view {
        require(msg.sender == _borrower, "BorrowerOps: Caller must be the borrower for a withdrawal");
    }

    function _requireNonZeroAdjustment(uint _collWithdrawal, uint _LUSDChange) internal view {
        require(msg.value != 0 || _collWithdrawal != 0 || _LUSDChange != 0, "BorrowerOps: There must be either a collateral change or a debt change");
    }

    function _requireTroveisActive(ITroveManager _troveManager, address _borrower) internal view {
        uint status = _troveManager.getTroveStatus(_borrower);
        require(status == 1, "BorrowerOps: Trove does not exist or is closed");
    }

    function _requireTroveisNotActive(ITroveManager _troveManager, address _borrower) internal view {
        uint status = _troveManager.getTroveStatus(_borrower);
        require(status != 1, "BorrowerOps: Trove is active");
    }

    function _requireNonZeroDebtChange(uint _LUSDChange) internal pure {
        require(_LUSDChange > 0, "BorrowerOps: Debt increase requires non-zero debtChange");
    }
   
    function _requireNotInRecoveryMode(uint _price) internal view {
        require(!_checkRecoveryMode(_price), "BorrowerOps: Operation not permitted during Recovery Mode");
    }

    function _requireNoCollWithdrawal(uint _collWithdrawal) internal pure {
        require(_collWithdrawal == 0, "BorrowerOps: Collateral withdrawal not permitted Recovery Mode");
    }

    function _requireValidAdjustmentInCurrentMode 
    (
        bool _isRecoveryMode,
        uint _collWithdrawal,
        bool _isDebtIncrease, 
        LocalVariables_adjustTrove memory _vars
    ) 
        internal 
        view 
    {
        /* 
        *In Recovery Mode, only allow:
        *
        * - Pure collateral top-up
        * - Pure debt repayment
        * - Collateral top-up with debt repayment
        * - A debt increase combined with a collateral top-up which makes the ICR >= 150% and improves the ICR (and by extension improves the TCR).
        *
        * In Normal Mode, ensure:
        *
        * - The new ICR is above MCR
        * - The adjustment won't pull the TCR below CCR
        */
        if (_isRecoveryMode) {
            _requireNoCollWithdrawal(_collWithdrawal);
            if (_isDebtIncrease) {
                _requireICRisAboveCCR(_vars.newICR);
                _requireNewICRisAboveOldICR(_vars.newICR, _vars.oldICR);
            }       
        } else { // if Normal Mode
            // _requireICRisAboveMCR(_vars.newICR);
            _vars.newTCR = _getNewTCRFromTroveChange(_vars.collChange, _vars.isCollIncrease, _vars.netDebtChange, _isDebtIncrease, _vars.price);
            // _requireNewTCRisAboveCCR(_vars.newTCR);  
        }
    }

    function _requireICRisAboveMCR(uint _newICR) internal pure {
        require(_newICR >= MCR, "BorrowerOps: An operation that would result in ICR < MCR is not permitted");
    }

    function _requireICRisAboveCCR(uint _newICR) internal pure {
        require(_newICR >= CCR, "BorrowerOps: Operation must leave trove with ICR >= CCR");
    }

    function _requireNewICRisAboveOldICR(uint _newICR, uint _oldICR) internal pure {
        require(_newICR >= _oldICR, "BorrowerOps: Cannot decrease your Trove's ICR in Recovery Mode");
    }

    function _requireNewTCRisAboveCCR(uint _newTCR) internal pure {
        require(_newTCR >= CCR, "BorrowerOps: An operation that would result in TCR < CCR is not permitted");
    }

    function _requireAtLeastMinNetDebt(uint _netDebt) internal pure {
        require (_netDebt >= MIN_NET_DEBT, "BorrowerOps: Trove's net debt must be greater than minimum");
    }

    function _requireValidLUSDRepayment(uint _currentDebt, uint _debtRepayment) internal pure {
        require(_debtRepayment <= _currentDebt-(LUSD_GAS_COMPENSATION), "BorrowerOps: Amount repaid must not be larger than the Trove's debt");
    }

    function _requireCallerIsStabilityPool() internal view {
        require(msg.sender == stabilityPoolAddress, "BorrowerOps: Caller is not Stability Pool");
    }

     function _requireSufficientLUSDBalance(ILUSDToken _lusdToken, address _borrower, uint _debtRepayment) internal view {
        require(_lusdToken.balanceOf(_borrower) >= _debtRepayment, "BorrowerOps: Caller doesnt have enough LUSD to make repayment");
    }

    function _requireValidMaxFeePercentage(uint _maxFeePercentage, bool _isRecoveryMode) internal pure {
        if (_isRecoveryMode) {
            require(_maxFeePercentage <= DECIMAL_PRECISION,
                "Max fee percentage must less than or equal to 100%");
        } else {
            require(_maxFeePercentage >= BORROWING_FEE_FLOOR && _maxFeePercentage <= DECIMAL_PRECISION,
                "Max fee percentage must be between 0.5% and 100%");
        }
    }

    // --- ICR and TCR getters ---

    // Compute the new collateral ratio, considering the change in coll and debt. Assumes 0 pending rewards.
    function _getNewNominalICRFromTroveChange
    (
        uint _coll,
        uint _debt,
        uint _collChange,
        bool _isCollIncrease,
        uint _debtChange,
        bool _isDebtIncrease
    )
        pure
        internal
        returns (uint)
    {
        (uint newColl, uint newDebt) = _getNewTroveAmounts(_coll, _debt, _collChange, _isCollIncrease, _debtChange, _isDebtIncrease);

        uint newNICR = LiquityMath._computeNominalCR(newColl, newDebt);
        return newNICR;
    }

    // Compute the new collateral ratio, considering the change in coll and debt. Assumes 0 pending rewards.
    function _getNewICRFromTroveChange
    (
        uint _coll,
        uint _debt,
        uint _collChange,
        bool _isCollIncrease,
        uint _debtChange,
        bool _isDebtIncrease,
        uint _price
    )
        pure
        internal
        returns (uint)
    {
        (uint newColl, uint newDebt) = _getNewTroveAmounts(_coll, _debt, _collChange, _isCollIncrease, _debtChange, _isDebtIncrease);

        uint newICR = LiquityMath._computeCR(newColl, newDebt, _price);
        return newICR;
    }

    function _getNewTroveAmounts(
        uint _coll,
        uint _debt,
        uint _collChange,
        bool _isCollIncrease,
        uint _debtChange,
        bool _isDebtIncrease
    )
        internal
        pure
        returns (uint, uint)
    {
        uint newColl = _coll;
        uint newDebt = _debt;

        newColl = _isCollIncrease ? _coll+(_collChange) :  _coll-(_collChange);
        newDebt = _isDebtIncrease ? _debt+(_debtChange) : _debt+(_debtChange);

        return (newColl, newDebt);
    }



    function _getNewTCRFromTroveChange
    (
        uint _collChange,
        bool _isCollIncrease,
        uint _debtChange,
        bool _isDebtIncrease,
        uint _price
    )
        internal
        view
        returns (uint)
    {
        uint totalColls = getEntireSystemColl();
        uint totalDebts= getEntireSystemDebt();

        totalColls = _isCollIncrease ? totalColls+(_collChange) : totalColls-(_collChange);
        totalDebts = _isDebtIncrease ? totalDebts+(_debtChange) : totalDebts-(_debtChange);

        uint newTCR = LiquityMath._computeCR(totalColls, totalDebts, _price);
        return newTCR;
    }


    function getCompositeDebt(uint _debt) external pure override returns (uint) {
        return _getCompositeDebt(_debt);
    }




}