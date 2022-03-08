/**
 *Submitted for verification at Etherscan.io on 2022-03-08
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;



// Part: CheckContract

contract CheckContract {
    /**
     * Check that the account is an already deployed non-destroyed contract.
     */
    function checkContract(address _account) internal view {
        require(_account != address(0), "Account cannot be zero address");

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(_account) }
        require(size > 0, "Account code size cannot be zero");
    }
}

// Part: ICollSurplusPool

interface ICollSurplusPool {

    // --- Events ---
    
    event BorrowerOpsAddressChanged(address _newBorrowerOpsAddress);
    event VaultManagerAddressChanged(address _newVaultManagerAddress);
    event ActivePoolAddressChanged(address _newActivePoolAddress);

    event CollBalanceUpdated(address indexed _account, uint _newBalance);
    event RoseSent(address _to, uint _amount);

    // --- Contract setters ---

    function setAddresses(
        address _borrowerOpsAddress,
        address _VaultManagerAddress,
        address _activePoolAddress
    ) external;

    function getROSE() external view returns (uint);

    function getCollateral(address _account) external view returns (uint);

    function accountSurplus(address _account, uint _amount) external;

    function claimColl(address _account) external;
}

// Part: IERC20

/**
 * Based on the OpenZeppelin IER20 interface:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol
 *
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

// Part: IERC2612

/**
 * @dev Interface of the ERC2612 standard as defined in the EIP.
 *
 * Adds the {permit} method, which can be used to change one's
 * {IERC20-allowance} without having to send a transaction, by signing a
 * message. This allows users to spend tokens without having to hold Ether.
 *
 * See https://eips.ethereum.org/EIPS/eip-2612.
 * 
 * Code adapted from https://github.com/OpenZeppelin/openzeppelin-contracts/pull/2237/
 */
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

// Part: IOrumRevenue

interface IOrumRevenue {
    // --- Events ---
    event CommitAdmin(address admin);
    event ApplyAdmin(address admin);
    event ToggleAllowCheckpointToken(bool toggleFlag);
    event CheckpointToken(uint time, uint tokens);
    event Claimed(address indexed recipient, uint amount, uint claimEpoch, uint maxEpoch);

    // --- Functions ---
    function checkpointToken() external;
    function veForAt(address _user, uint _timestamp) external view returns (uint);
    function checkpointTotalSupply() external;
    function claimable(address _addr) external view returns (uint);
    function applyAdmin() external;
    function commitAdmin(address _addr) external;
    function toggleAllowCheckpointToken() external;
    
}

// Part: IPool

// Common interface for the Pools.
interface IPool {
    
    // --- Events ---
    
    event ROSEBalanceUpdated(uint _newBalance);
    event OSDBalanceUpdated(uint _newBalance);
    event ActivePoolAddressChanged(address _newActivePoolAddress);
    event DefaultPoolAddressChanged(address _newDefaultPoolAddress);
    event StabilityPoolAddressChanged(address _newStabilityPoolAddress);
    event RoseSent(address _to, uint _amount);

    // --- Functions ---
    
    function getROSE() external view returns (uint);

    function getOSDDebt() external view returns (uint);

    function increaseOSDDebt(uint _amount) external;

    function decreaseOSDDebt(uint _amount) external;
}

// Part: IPriceFeed

interface IPriceFeed {
    // -- Events ---
    event LastGoodPriceUpdated(uint _lastGoodPrice);

    // ---Function---
    function fetchPrice() external view returns (uint);
}

// Part: ISortedVaults

// Common interface for the SortedVaults Doubly Linked List.
interface ISortedVaults {

    // --- Events ---
    
    event SortedVaultsAddressChanged(address _sortedDoublyLinkedListAddress);
    event BorrowerOpsAddressChanged(address _borrowerOpsAddress);
    event VaultManagerAddressChanged(address _vaultManagerAddress);
    event NodeAdded(address _id, uint _NICR);
    event NodeRemoved(address _id);

    // --- Functions ---
    
    function setParams(uint256 _size, address _VaultManagerAddress, address _borrowerOpsAddress) external;

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

// Part: IStabilityPool

/*
 * The Stability Pool holds OSD tokens deposited by Stability Pool depositors.
 *
 * When a Vault is liquidated, then depending on system conditions, some of its OSD debt gets offset with
 * OSD in the Stability Pool:  that is, the offset debt evaporates, and an equal amount of OSD tokens in the Stability Pool is burned.
 *
 * Thus, a liquidation causes each depositor to receive a OSD loss, in proportion to their deposit as a share of total deposits.
 * They also receive an ROSE gain, as the ROSE collateral of the liquidated Vault is distributed among Stability depositors,
 * in the same proportion.
 *
 * When a liquidation occurs, it depletes every deposit by the same fraction: for example, a liquidation that depletes 40%
 * of the total OSD in the Stability Pool, depletes 40% of each deposit.
 *
 * A deposit that has experienced a series of liquidations is termed a "compounded deposit": each liquidation depletes the deposit,
 * multiplying it by some factor in range ]0,1[
 *
 * Please see the implementation spec in the proof document, which closely follows on from the compounded deposit / ROSE gain derivations:
 * https://github.com/liquity/liquity/blob/master/papers/Scalable_Reward_Distribution_with_Compounding_Stakes.pdf
 */
interface IStabilityPool {

    // --- Events ---
    
    event StabilityPoolROSEBalanceUpdated(uint _newBalance);
    event StabilityPoolOSDBalanceUpdated(uint _newBalance);

    event BorrowerOpsAddressChanged(address _newBorrowerOpsAddress);
    event VaultManagerAddressChanged(address _newVaultManagerAddress);
    event ActivePoolAddressChanged(address _newActivePoolAddress);
    event DefaultPoolAddressChanged(address _newDefaultPoolAddress);
    event OSDTokenAddressChanged(address _newOSDTokenAddress);
    event SortedVaultsAddressChanged(address _newSortedVaultsAddress);
    event PriceFeedAddressChanged(address _newPriceFeedAddress);
    event CommunityIssuanceAddressChanged(address _newCommunityIssuanceAddress);

    event P_Updated(uint _P);
    event S_Updated(uint _S, uint128 _epoch, uint128 _scale);
    event G_Updated(uint _G, uint128 _epoch, uint128 _scale);
    event EpochUpdated(uint128 _currentEpoch);
    event ScaleUpdated(uint128 _currentScale);

    event DepositSnapshotUpdated(address indexed _depositor, uint _P, uint _S, uint _G);
    event UserDepositChanged(address indexed _depositor, uint _newDeposit);

    event ROSEGainWithdrawn(address indexed _depositor, uint _ROSE, uint _OSDLoss);
    event OrumPaidToDepositor(address indexed _depositor, uint _orum);
    event RoseSent(address _to, uint _amount);

    // --- Functions ---

    /*
     * Called only once on init, to set addresses of other Liquity contracts
     * Callable only by owner, renounces ownership at the end
     */
    function setAddresses(
        address _borrowerOpsAddress,
        address _VaultManagerAddress,
        address _activePoolAddress,
        address _osdTokenAddress,
        address _sortedVaultsAddress,
        address _priceFeedAddress,
        address _communityIssuanceAddress
    ) external;

    function provideToSP(uint _amount) external;

    function withdrawFromSP(uint _amount) external;

    function withdrawROSEGainToVault(address _upperHint, address _lowerHint) external;

    function offset(uint _debt, uint _coll) external;

    function getROSE() external view returns (uint);

    function getTotalOSDDeposits() external view returns (uint);

    function getDepositorROSEGain(address _depositor) external view returns (uint);

    function getDepositorOrumGain(address _depositor) external view returns (uint);

    function getCompoundedOSDDeposit(address _depositor) external view returns (uint);

    /*
     * Fallback function
     * Only callable by Active Pool, it just accounts for ROSE received
     * receive() external payable;
     */
}

// Part: OpenZeppelin/[email protected]/Context

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

// Part: SafeMath

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// Part: IActivePool

interface IActivePool is IPool {
    // --- Events ---
    event BorrowerOpsAddressChanged(address _newBorrowerOpsAddress);
    event VaultManagerAddressChanged(address _newVaultManagerAddress);
    event ActivePoolOSDDebtUpdated(uint _OSDDebt);
    event ActivePoolROSEBalanceUpdated(uint _ROSE);

    // --- Functions ---
    function sendROSE(address _account, uint _amount) external;
}

// Part: IDefaultPool

interface IDefaultPool is IPool {
    // --- Events ---
    event VaultManagerAddressChanged(address _newVaultManagerAddress);
    event DefaultPoolOSDDebtUpdated(uint _OSDDebt);
    event DefaultPoolROSEBalanceUpdated(uint _ROSE);

    // --- Functions ---
    function sendROSEToActivePool(uint _amount) external;
}

// Part: IOSDToken

interface IOSDToken is IERC20, IERC2612 { 
    
    // --- Events ---

    event VaultManagerAddressChanged(address _vaultManagerAddress);
    event StabilityPoolAddressChanged(address _newStabilityPoolAddress);
    event BorrowerOpsAddressChanged(address _newBorrowerOpsAddress);

    event OSDTokenBalanceUpdated(address _user, uint _amount);

    // --- Functions ---

    function mint(address _account, uint256 _amount) external;

    function burn(address _account, uint256 _amount) external;

    function sendToPool(address _sender,  address poolAddress, uint256 _amount) external;

    function returnFromPool(address poolAddress, address user, uint256 _amount ) external;
}

// Part: IOrumBase

interface IOrumBase {
    function priceFeed() external view returns (IPriceFeed);
}

// Part: OpenZeppelin/[email protected]/Ownable

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

// Part: OrumMath

// Based on Liquity's OrumMath library: https://github.com/liquity/dev/blob/main/packages/contracts/contracts/Dependencies/OrumMath.sol

library OrumMath {
    using SafeMath for uint;

    uint internal constant DECIMAL_PRECISION = 1e18;

    /* Precision for Nominal ICR (independent of price). Rationale for the value:
    *
    * - Making it "too high" could lead to overflows.
    * - Making it "too low" could lead to an ICR equal to zero, due to truncation from Solidity floor division.
    *
    * This value of 1e20 is chosen for safety: the NICR will only overflow for numerator > ~1e39 ROSE,
    * and will only truncate to 0 if the denominator is at least 1e20 times greater than the numerator.
    *
    */

    uint internal constant NICR_PRECISION = 1e20;

    function _min(uint _a, uint _b) internal pure returns (uint) {
        return (_a < _b) ? _a : _b;
    }
    function _max(int _a, int _b) internal pure returns (uint) {
        return (_a >= _b) ? uint(_a) : uint(_b);
    }

    /*
    * Multiply two decimal numbers and use normal rounding rules
    * - round product up if 19'th mantissa digit >= 5
    * - round product down if 19'th mantissa digit < 5
    * 
    * Used only inside exponentiation, _decPow().
    */

    function decMul(uint x, uint y) internal pure returns (uint decProd) {
        uint prod_xy = x.mul(y);
        decProd = prod_xy.add(DECIMAL_PRECISION/2).div(DECIMAL_PRECISION);
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
        if (_debt > 0) {
            return _coll.mul(NICR_PRECISION).div(_debt);
        }
        // Return the maximal value for uint256 if the Vault has a debt of 0. Represents "infinite" CR.
        else { // if (_debt == 0)
            return 2**256 - 1;
        }
    }

    function _computeCR(uint _coll, uint _debt, uint _price) internal pure returns (uint) {
        if (_debt > 0) {
            uint newCollRatio = _coll.mul(_price).div(_debt);

            return newCollRatio;
        }
        // Return the maximal value for uint256 if the Vault has a debt of 0. Represents "infinite" CR.
        else { // if (_debt == 0)
            return 2**256 - 1; 
        }
    }
}

// Part: IVaultManager

// Common interface for the Vault Manager.
interface IVaultManager is IOrumBase {
    
    // --- Events ---

    event BorrowerOpsAddressChanged(address _newBorrowerOpsAddress);
    event PriceFeedAddressChanged(address _newPriceFeedAddress);
    event OSDTokenAddressChanged(address _newOSDTokenAddress);
    event ActivePoolAddressChanged(address _activePoolAddress);
    event DefaultPoolAddressChanged(address _defaultPoolAddress);
    event StabilityPoolAddressChanged(address _stabilityPoolAddress);
    event GasPoolAddressChanged(address _gasPoolAddress);
    event CollSurplusPoolAddressChanged(address _collSurplusPoolAddress);
    event SortedVaultsAddressChanged(address _sortedVaultsAddress);
    event OrumRevenueAddressChanged(address _orumRevenueAddress);

    event Liquidation(uint _liquidatedDebt, uint _liquidatedColl, uint _collGasCompensation, uint _OSDGasCompensation);
    event Test_LiquidationROSEFee(uint _ROSEFee);
    event Redemption(uint _attemptedOSDAmount, uint _actualOSDAmount, uint _ROSESent, uint _ROSEFee);
    event VaultUpdated(address indexed _borrower, uint _debt, uint _coll, uint stake, uint8 operation);
    event VaultLiquidated(address indexed _borrower, uint _debt, uint _coll, uint8 operation);
    event BaseRateUpdated(uint _baseRate);
    event LastFeeOpTimeUpdated(uint _lastFeeOpTime);
    event TotalStakesUpdated(uint _newTotalStakes);
    event SystemSnapshotsUpdated(uint _totalStakesSnapshot, uint _totalCollateralSnapshot);
    event LTermsUpdated(uint _L_ROSE, uint _L_OSDDebt);
    event VaultSnapshotsUpdated(uint _L_ROSE, uint _L_OSDDebt);
    event VaultIndexUpdated(address _borrower, uint _newIndex);

    // --- Functions ---
    function getVaultOwnersCount() external view returns (uint);

    function getVaultFromVaultOwnersArray(uint _index) external view returns (address);

    function getNominalICR(address _borrower) external view returns (uint);
    function getCurrentICR(address _borrower, uint _price) external view returns (uint);

    function liquidate(address _borrower) external;

    function liquidateVaults(uint _n) external;

    function batchLiquidateVaults(address[] calldata _VaultArray) external;

    function redeemCollateral(
        uint _OSDAmount,
        address _firstRedemptionHint,
        address _upperPartialRedemptionHint,
        address _lowerPartialRedemptionHint,
        uint _partialRedemptionHintNICR,
        uint _maxIterations,
        uint _maxFee
    ) external; 

    function updateStakeAndTotalStakes(address _borrower) external returns (uint);

    function updateVaultRewardSnapshots(address _borrower) external;

    function addVaultOwnerToArray(address _borrower) external returns (uint index);

    function applyPendingRewards(address _borrower) external;

    function getPendingROSEReward(address _borrower) external view returns (uint);

    function getPendingOSDDebtReward(address _borrower) external view returns (uint);

    function hasPendingRewards(address _borrower) external view returns (bool);

    function getEntireDebtAndColl(address _borrower) external view returns (
        uint debt, 
        uint coll, 
        uint pendingOSDDebtReward, 
        uint pendingROSEReward
    );

    function closeVault(address _borrower) external;

    function removeStake(address _borrower) external;

    function getRedemptionRate() external view returns (uint);
    function getRedemptionRateWithDecay() external view returns (uint);

    function getRedemptionFeeWithDecay(uint _ROSEDrawn) external view returns (uint);

    function getBorrowingRate() external view returns (uint);
    function getBorrowingRateWithDecay() external view returns (uint);

    function getBorrowingFee(uint OSDDebt) external view returns (uint);
    function getBorrowingFeeWithDecay(uint _OSDDebt) external view returns (uint);

    function decayBaseRateFromBorrowing() external;

    function getVaultStatus(address _borrower) external view returns (uint);
    
    function getVaultStake(address _borrower) external view returns (uint);

    function getVaultDebt(address _borrower) external view returns (uint);

    function getVaultColl(address _borrower) external view returns (uint);

    function setVaultStatus(address _borrower, uint num) external;

    function increaseVaultColl(address _borrower, uint _collIncrease) external returns (uint);

    function decreaseVaultColl(address _borrower, uint _collDecrease) external returns (uint); 

    function increaseVaultDebt(address _borrower, uint _debtIncrease) external returns (uint); 

    function decreaseVaultDebt(address _borrower, uint _collDecrease) external returns (uint); 

    function getTCR(uint _price) external view returns (uint);

    function checkRecoveryMode(uint _price) external view returns (bool);
}

// Part: OrumBase

/* 
* Base contract for VaultManager, BorrowerOps and StabilityPool. Contains global system constants and
* common functions. 
*/
contract OrumBase is IOrumBase {
    using SafeMath for uint;

    uint constant public DECIMAL_PRECISION = 1e18;

    uint constant public _100pct = 1000000000000000000; // 1e18 == 100%

    // Minimum collateral ratio for individual Vaults
    uint public MCR = 1350000000000000000; // 135%;

    // Critical system collateral ratio. If the system's total collateral ratio (TCR) falls below the CCR, Recovery Mode is triggered.
    uint public CCR = 1750000000000000000; // 175%

    // Amount of OSD to be locked in gas pool on opening vaults
    uint public OSD_GAS_COMPENSATION = 10e18;

    // Minimum amount of net OSD debt a vault must have
    uint public MIN_NET_DEBT = 50e18;

    uint public PERCENT_DIVISOR = 200; // dividing by 200 yields 0.5%

    uint public BORROWING_FEE_FLOOR = DECIMAL_PRECISION / 10000 * 75 ; // 0.75%

    uint public TREASURY_LIQUIDATION_PROFIT = DECIMAL_PRECISION / 100 * 20; // 20%
    


    address public contractOwner;

    IActivePool public activePool;

    IDefaultPool public defaultPool;

    IPriceFeed public override priceFeed;

    constructor() {
        contractOwner = msg.sender;
    }
    // --- Gas compensation functions ---

    // Returns the composite debt (drawn debt + gas compensation) of a vault, for the purpose of ICR calculation
    function _getCompositeDebt(uint _debt) internal view  returns (uint) {
        return _debt.add(OSD_GAS_COMPENSATION);
    }
    function _getNetDebt(uint _debt) internal view returns (uint) {
        return _debt.sub(OSD_GAS_COMPENSATION);
    }
    // Return the amount of ROSE to be drawn from a vault's collateral and sent as gas compensation.
    function _getCollGasCompensation(uint _entireColl) internal view returns (uint) {
        return _entireColl / PERCENT_DIVISOR;
    }
    // // change system base values
    // function changeMCR(uint _newMCR) external {
    //     _requireCallerIsOwner();
    //     MCR = _newMCR;
    // }
    // function changeCCR(uint _newCCR) external {
    //     _requireCallerIsOwner();
    //     CCR = _newCCR;
    // }
    // function changeLiquidationReward(uint8 _PERCENT_DIVISOR) external {
    //     _requireCallerIsOwner();
    //     PERCENT_DIVISOR = _PERCENT_DIVISOR;
    // }
    // function changeTreasuryFeeShare(uint8 _percent) external {
    //     _requireCallerIsOwner();
    //     TREASURY_FEE_DIVISOR = DECIMAL_PRECISION / 100 * _percent;
    // }
    // function changeSPLiquidationProfit(uint8 _percent) external {
    //     _requireCallerIsOwner();
    //     STABILITY_POOL_LIQUIDATION_PROFIT = DECIMAL_PRECISION / 100 * _percent;
    // }
    // function changeBorrowingFee(uint8 _newBorrowFee) external {
    //     _requireCallerIsOwner();
    //     BORROWING_FEE_FLOOR = DECIMAL_PRECISION / 1000 * _newBorrowFee;
    // }
    // function changeMinNetDebt(uint _newMinDebt) external {
    //     _requireCallerIsOwner();
    //     MIN_NET_DEBT = _newMinDebt;
    // }
    // function changeGasCompensation(uint _OSDGasCompensation) external {
    //     _requireCallerIsOwner();
    //     OSD_GAS_COMPENSATION = _OSDGasCompensation;
    // }
    function getEntireSystemColl() public view returns (uint entireSystemColl) {
        uint activeColl = activePool.getROSE();
        uint liquidatedColl = defaultPool.getROSE();

        return activeColl.add(liquidatedColl);
    }

    function getEntireSystemDebt() public view returns (uint entireSystemDebt) {
        uint activeDebt = activePool.getOSDDebt();
        uint closedDebt = defaultPool.getOSDDebt();

        return activeDebt.add(closedDebt);
    }
    function _getTreasuryLiquidationProfit(uint _amount) internal view returns (uint){
        return _amount.mul(TREASURY_LIQUIDATION_PROFIT).div(DECIMAL_PRECISION);
    }
    function _getTCR(uint _price) internal view returns (uint TCR) {
        uint entireSystemColl = getEntireSystemColl();
        uint entireSystemDebt = getEntireSystemDebt();

        TCR = OrumMath._computeCR(entireSystemColl, entireSystemDebt, _price);
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

    function _requireCallerIsOwner() internal view {
        require(msg.sender == contractOwner, "OrumBase: caller not owner");
    }

    function changeOwnership(address _newOwner) external {
        require(msg.sender == contractOwner, "OrumBase: Caller not owner");
        contractOwner = _newOwner;
    }

}

// File: VaultManager.sol

contract VaultManager is OrumBase, Ownable, CheckContract, IVaultManager {
    string constant public NAME = "VaultManager";
    using SafeMath for uint256;

    // --- Connected contract declarations ---

    address public borrowerOpsAddress;

    IStabilityPool public stabilityPool;

    address gasPoolAddress;
    address orumRevenueAddress;

    ICollSurplusPool collSurplusPool;
    IOrumRevenue orumRevenue;

    IOSDToken public osdToken;

    // A doubly linked list of Vaults, sorted by their sorted by their collateral ratios
    ISortedVaults public sortedVaults;

    // --- Data structures ---

    uint constant public SECONDS_IN_ONE_MINUTE = 60;
    /*
     * Half-life of 12h. 12h = 720 min
     * (1/2) = d^720 => d = (1/2)^(1/720)
     */
    uint constant public MINUTE_DECAY_FACTOR = 999037758833783000;
    uint constant public REDEMPTION_FEE_FLOOR = DECIMAL_PRECISION / 10000 * 75; // 0.75%
    uint constant public MAX_BORROWING_FEE = DECIMAL_PRECISION / 100 * 5; // 5%

    // During bootsrap period redemptions are not allowed
    uint constant public BOOTSTRAP_PERIOD = 14 days;

    /*
    * BETA: 18 digit decimal. Parameter by which to divide the redeemed fraction, in order to calc the new base rate from a redemption.
    * Corresponds to (1 / ALPHA) in the white paper.
    */
    uint constant public BETA = 2;

    uint public baseRate;

    // The timestamp of the latest fee operation (redemption or new OSD issuance)
    uint public lastFeeOperationTime;

    enum Status {
        nonExistent,
        active,
        closedByOwner,
        closedByLiquidation,
        closedByRedemption
    }

    // Store the necessary data for a vault
    struct Vault {
        uint debt;
        uint coll;
        uint stake;
        Status status;
        uint128 arrayIndex;
    }

    mapping (address => Vault) public Vaults;

    uint public totalStakes;

    // Snapshot of the value of totalStakes, taken immediately after the latest liquidation
    uint public totalStakesSnapshot;

    // Snapshot of the total collateral across the ActivePool and DefaultPool, immediately after the latest liquidation.
    uint public totalCollateralSnapshot;

    /*
    * L_ROSE and L_OSDDebt track the sums of accumulated liquidation rewards per unit staked. During its lifetime, each stake earns:
    *
    * An ROSE gain of ( stake * [L_ROSE - L_ROSE(0)] )
    * A OSDDebt increase  of ( stake * [L_OSDDebt - L_OSDDebt(0)] )
    *
    * Where L_ROSE(0) and L_OSDDebt(0) are snapshots of L_ROSE and L_OSDDebt for the active Vault taken at the instant the stake was made
    */
    uint public L_ROSE;
    uint public L_OSDDebt;

    // Map addresses with active vaults to their RewardSnapshot
    mapping (address => RewardSnapshot) public rewardSnapshots;

    // Object containing the ROSE and OSD snapshots for a given active vault
    struct RewardSnapshot { uint ROSE; uint OSDDebt;}

    // Array of all active vault addresses - used to to compute an approximate hint off-chain, for the sorted list insertion
    address[] public VaultOwners;

    // Error trackers for the vault redistribution calculation
    uint public lastROSEError_Redistribution;
    uint public lastOSDDebtError_Redistribution;

    /*
    * --- Variable container structs for liquidations ---
    *
    * These structs are used to hold, return and assign variables inside the liquidation functions,
    * in order to avoid the error: "CompilerError: Stack too deep".
    **/

    struct LocalVariables_OuterLiquidationFunction {
        uint price;
        uint OSDInStabPool;
        bool recoveryModeAtStart;
        uint liquidatedDebt;
        uint liquidatedColl;
    }

    struct LocalVariables_InnerSingleLiquidateFunction {
        uint collToLiquidate;
        uint pendingDebtReward;
        uint pendingCollReward;
    }

    struct LocalVariables_LiquidationSequence {
        uint remainingOSDInStabPool;
        uint i;
        uint ICR;
        address user;
        bool backToNormalMode;
        uint entireSystemDebt;
        uint entireSystemColl;
    }

    struct LiquidationValues {
        uint entireVaultDebt;
        uint entireVaultColl;
        uint collGasCompensation;
        uint OSDGasCompensation;
        uint debtToOffset;
        uint collToSendToSP;
        uint collToSendToOrumRevenue;
        uint debtToRedistribute;
        uint collToRedistribute;
        uint collSurplus;
    }

    struct LiquidationTotals {
        uint totalCollInSequence;
        uint totalDebtInSequence;
        uint totalCollGasCompensation;
        uint totalOSDGasCompensation;
        uint totalDebtToOffset;
        uint totalCollToSendToSP;
        uint totalCollToSendToOrumRevenue;
        uint totalDebtToRedistribute;
        uint totalCollToRedistribute;
        uint totalCollSurplus;
    }

    struct ContractsCache {
        IActivePool activePool;
        IDefaultPool defaultPool;
        IOSDToken osdToken;
        ISortedVaults sortedVaults;
        ICollSurplusPool collSurplusPool;
        address gasPoolAddress;
    }
    // --- Variable container structs for redemptions ---

    struct RedemptionTotals {
        uint remainingOSD;
        uint totalOSDToRedeem;
        uint totalROSEDrawn;
        uint ROSEFee;
        uint ROSEToSendToRedeemer;
        uint decayedBaseRate;
        uint price;
        uint totalOSDSupplyAtStart;
    }

    struct SingleRedemptionValues {
        uint OSDLot;
        uint ROSELot;
        bool cancelledPartial;
    }

     enum VaultManagerOperation {
        applyPendingRewards,
        liquidateInNormalMode,
        liquidateInRecoveryMode,
        redeemCollateral
    }

    event TEST_error(uint _debtInRose, uint _collToSP, uint _collToOrum, uint _totalCollProfits);
    event TEST_liquidationfee(uint _totalCollToSendToSP, uint _totalCollToSendToOrumRevenue);
    event TEST_account(address _borrower, uint _amount);
    event TEST_normalModeCheck(bool _mode, address _borrower, uint _amount, uint _coll, uint _debt, uint _price);
    event TEST_debt(uint _debt);


    // --- Dependency setter ---

    function setAddresses(
        address _borrowerOpsAddress,
        address _activePoolAddress,
        address _defaultPoolAddress,
        address _stabilityPoolAddress,
        address _gasPoolAddress,
        address _collSurplusPoolAddress,
        address _priceFeedAddress,
        address _osdTokenAddress,
        address _sortedVaultsAddress,
        address _orumRevenueAddress
    )
        external
        onlyOwner
    {
        checkContract(_borrowerOpsAddress);
        checkContract(_activePoolAddress);
        checkContract(_defaultPoolAddress);
        checkContract(_stabilityPoolAddress);
        checkContract(_gasPoolAddress);
        checkContract(_collSurplusPoolAddress);
        checkContract(_priceFeedAddress);
        checkContract(_osdTokenAddress);
        checkContract(_sortedVaultsAddress);
        // checkContract(_orumRevenueAddress);

        borrowerOpsAddress = _borrowerOpsAddress;
        activePool = IActivePool(_activePoolAddress);
        defaultPool = IDefaultPool(_defaultPoolAddress);
        stabilityPool = IStabilityPool(_stabilityPoolAddress);
        gasPoolAddress = _gasPoolAddress;
        collSurplusPool = ICollSurplusPool(_collSurplusPoolAddress);
        priceFeed = IPriceFeed(_priceFeedAddress);
        osdToken = IOSDToken(_osdTokenAddress);
        sortedVaults = ISortedVaults(_sortedVaultsAddress);
        orumRevenueAddress = _orumRevenueAddress;
        // orumRevenue = IOrumRevenue(_orumRevenueAddress);
        

        emit BorrowerOpsAddressChanged(_borrowerOpsAddress);
        emit ActivePoolAddressChanged(_activePoolAddress);
        emit DefaultPoolAddressChanged(_defaultPoolAddress);
        emit StabilityPoolAddressChanged(_stabilityPoolAddress);
        emit GasPoolAddressChanged(_gasPoolAddress);
        emit CollSurplusPoolAddressChanged(_collSurplusPoolAddress);
        emit PriceFeedAddressChanged(_priceFeedAddress);
        emit OSDTokenAddressChanged(_osdTokenAddress);
        emit SortedVaultsAddressChanged(_sortedVaultsAddress);
        // emit OrumRevenueAddressChanged(_orumRevenueAddress);

    }

    // --- Getters ---

    function getVaultOwnersCount() external view override returns (uint) {
        return VaultOwners.length;
    }

    function getVaultFromVaultOwnersArray(uint _index) external view override returns (address) {
        return VaultOwners[_index];
    }

    // --- Vault Liquidation functions ---

    // Single liquidation function. Closes the vault if its ICR is lower than the minimum collateral ratio.
    function liquidate(address _borrower) external override {
        _requireVaultIsActive(_borrower);

        address[] memory borrowers = new address[](1);
        borrowers[0] = _borrower;
        batchLiquidateVaults(borrowers);
    }

    /*
    * Attempt to liquidate a custom list of troves provided by the caller.
    */
    function batchLiquidateVaults(address[] memory _vaultArray) public override {
        require(_vaultArray.length != 0, "VaultManager: Calldata address array must not be empty");

        IActivePool activePoolCached = activePool;
        IDefaultPool defaultPoolCached = defaultPool;
        IStabilityPool stabilityPoolCached = stabilityPool;

        LocalVariables_OuterLiquidationFunction memory vars;
        LiquidationTotals memory totals;

        vars.price = priceFeed.fetchPrice();
        vars.OSDInStabPool = stabilityPoolCached.getTotalOSDDeposits();
        vars.recoveryModeAtStart = _checkRecoveryMode(vars.price);

        // Perform the appropriate liquidation sequence - tally values and obtain their totals.
        if (vars.recoveryModeAtStart) {
            totals = _getTotalFromBatchLiquidate_RecoveryMode(activePoolCached, defaultPoolCached, vars.price, vars.OSDInStabPool, _vaultArray);
        } else {  //  if !vars.recoveryModeAtStart
            totals = _getTotalsFromBatchLiquidate_NormalMode(activePoolCached, defaultPoolCached, vars.price, vars.OSDInStabPool, _vaultArray);
        }

        require(totals.totalDebtInSequence > 0, "VaultManager: nothing to liquidate");

        // Move liquidated ROSE and OSD to the appropriate pools
        stabilityPoolCached.offset(totals.totalDebtToOffset, totals.totalCollToSendToSP);
        // Send fees to the orum revenue
        activePoolCached.sendROSE(orumRevenueAddress, totals.totalCollToSendToOrumRevenue);


        emit TEST_liquidationfee(totals.totalCollToSendToSP, totals.totalCollToSendToOrumRevenue);

        _redistributeDebtAndColl(activePoolCached, defaultPoolCached, totals.totalDebtToRedistribute, totals.totalCollToRedistribute);
        if (totals.totalCollSurplus > 0) {
            activePoolCached.sendROSE(address(collSurplusPool), totals.totalCollSurplus);
        }

        // Update system snapshots
        _updateSystemSnapshots_excludeCollRemainder(activePoolCached, totals.totalCollGasCompensation);

        vars.liquidatedDebt = totals.totalDebtInSequence;
        vars.liquidatedColl = totals.totalCollInSequence.sub(totals.totalCollGasCompensation).sub(totals.totalCollSurplus);
        emit Liquidation(vars.liquidatedDebt, vars.liquidatedColl, totals.totalCollGasCompensation, totals.totalOSDGasCompensation);
        // Send gas compensation to caller
        _sendGasCompensation(activePoolCached, msg.sender, totals.totalOSDGasCompensation, totals.totalCollGasCompensation);
    }

    // --- Inner single liquidation functions ---

    // Liquidate one vault, in Normal Mode.
    function _liquidateNormalMode(
        IActivePool _activePool,
        IDefaultPool _defaultPool,
        address _borrower,
        uint _OSDInStabPool,
        uint _price
    )
        internal
        returns (LiquidationValues memory singleLiquidation)
    {
        LocalVariables_InnerSingleLiquidateFunction memory vars;

        (singleLiquidation.entireVaultDebt,
        singleLiquidation.entireVaultColl,
        vars.pendingDebtReward,
        vars.pendingCollReward) = getEntireDebtAndColl(_borrower);

        _movePendingVaultRewardsToActivePool(_activePool, _defaultPool, vars.pendingDebtReward, vars.pendingCollReward);
        _removeStake(_borrower);

        singleLiquidation.collGasCompensation = _getCollGasCompensation(singleLiquidation.entireVaultColl);
        singleLiquidation.OSDGasCompensation = OSD_GAS_COMPENSATION;
        uint collToLiquidate = singleLiquidation.entireVaultColl.sub(singleLiquidation.collGasCompensation);

        (singleLiquidation.debtToOffset,
        singleLiquidation.collToSendToSP,
        singleLiquidation.collToSendToOrumRevenue,
        singleLiquidation.debtToRedistribute,
        singleLiquidation.collToRedistribute) = _getOffsetAndRedistributionVals(singleLiquidation.entireVaultDebt, collToLiquidate, _OSDInStabPool, _price);

        _closeVault(_borrower, Status.closedByLiquidation);
        emit VaultLiquidated(_borrower, singleLiquidation.entireVaultDebt, singleLiquidation.entireVaultColl, uint8(VaultManagerOperation.liquidateInNormalMode));
        emit VaultUpdated(_borrower, 0, 0, 0, uint8(VaultManagerOperation.liquidateInNormalMode));
        return singleLiquidation;
    }

    // Liquidate one vault, in Recovery Mode.
    function _liquidateRecoveryMode(
        IActivePool _activePool,
        IDefaultPool _defaultPool,
        address _borrower,
        uint _ICR,
        uint _OSDInStabPool,
        uint _TCR,
        uint _price
    )
        internal
        returns (LiquidationValues memory singleLiquidation)
    {
        LocalVariables_InnerSingleLiquidateFunction memory vars;
        if (VaultOwners.length <= 1) {return singleLiquidation;} // don't liquidate if last vault
        (singleLiquidation.entireVaultDebt,
        singleLiquidation.entireVaultColl,
        vars.pendingDebtReward,
        vars.pendingCollReward) = getEntireDebtAndColl(_borrower);

        singleLiquidation.collGasCompensation = _getCollGasCompensation(singleLiquidation.entireVaultColl);
        singleLiquidation.OSDGasCompensation = OSD_GAS_COMPENSATION;
        vars.collToLiquidate = singleLiquidation.entireVaultColl.sub(singleLiquidation.collGasCompensation);

        // If ICR <= 100%, purely redistribute the Vault across all active Vaults
        if (_ICR <= _100pct) {
            _movePendingVaultRewardsToActivePool(_activePool, _defaultPool, vars.pendingDebtReward, vars.pendingCollReward);
            _removeStake(_borrower);
           
            singleLiquidation.debtToOffset = 0;
            singleLiquidation.collToSendToSP = 0;
            singleLiquidation.collToSendToOrumRevenue = 0;
            singleLiquidation.debtToRedistribute = singleLiquidation.entireVaultDebt;
            singleLiquidation.collToRedistribute = vars.collToLiquidate;

            _closeVault(_borrower, Status.closedByLiquidation);
            emit VaultLiquidated(_borrower, singleLiquidation.entireVaultDebt, singleLiquidation.entireVaultColl, uint8(VaultManagerOperation.liquidateInRecoveryMode));
            emit VaultUpdated(_borrower, 0, 0, 0, uint8(VaultManagerOperation.liquidateInRecoveryMode));
            
        // If 100% < ICR < MCR, offset as much as possible, and redistribute the remainder
        } else if ((_ICR > _100pct) && (_ICR < MCR)) {
             _movePendingVaultRewardsToActivePool(_activePool, _defaultPool, vars.pendingDebtReward, vars.pendingCollReward);
            _removeStake(_borrower);

            (singleLiquidation.debtToOffset,
            singleLiquidation.collToSendToSP,
            singleLiquidation.collToSendToOrumRevenue,
            singleLiquidation.debtToRedistribute,
            singleLiquidation.collToRedistribute) = _getOffsetAndRedistributionVals(singleLiquidation.entireVaultDebt, vars.collToLiquidate, _OSDInStabPool, _price);

            _closeVault(_borrower, Status.closedByLiquidation);
            emit VaultLiquidated(_borrower, singleLiquidation.entireVaultDebt, singleLiquidation.entireVaultColl, uint8(VaultManagerOperation.liquidateInRecoveryMode));
            emit VaultUpdated(_borrower, 0, 0, 0, uint8(VaultManagerOperation.liquidateInRecoveryMode));
        /*
        * If 110% <= ICR < current TCR (accounting for the preceding liquidations in the current sequence)
        * and there is OSD in the Stability Pool, only offset, with no redistribution,
        * but at a capped rate of 1.1 and only if the whole debt can be liquidated.
        * The remainder due to the capped rate will be claimable as collateral surplus.
        */
        } else if ((_ICR >= MCR) && (_ICR < _TCR) && (singleLiquidation.entireVaultDebt <= _OSDInStabPool)) {
            _movePendingVaultRewardsToActivePool(_activePool, _defaultPool, vars.pendingDebtReward, vars.pendingCollReward);
            assert(_OSDInStabPool != 0);

            _removeStake(_borrower);
            singleLiquidation = _getCappedOffsetVals(singleLiquidation.entireVaultDebt, singleLiquidation.entireVaultColl, _price);
            // emit TEST_account(_borrower, singleLiquidation.collSurplus);
            _closeVault(_borrower, Status.closedByLiquidation);
            if (singleLiquidation.collSurplus > 0) {
                collSurplusPool.accountSurplus(_borrower, singleLiquidation.collSurplus);
            }

            emit VaultLiquidated(_borrower, singleLiquidation.entireVaultDebt, singleLiquidation.collToSendToSP, uint8(VaultManagerOperation.liquidateInRecoveryMode));
            emit VaultUpdated(_borrower, 0, 0, 0, uint8(VaultManagerOperation.liquidateInRecoveryMode));

        } else { // if (_ICR >= MCR && ( _ICR >= _TCR || singleLiquidation.entireVaultDebt > _OSDInStabPool))
            LiquidationValues memory zeroVals;
            return zeroVals;
        }

        return singleLiquidation;
    }

    /* In a full liquidation, returns the values for a vault's coll and debt to be offset, and coll and debt to be
    * redistributed to active vaults.
    */
    function _getOffsetAndRedistributionVals
    (
        uint _debt,
        uint _coll,
        uint _OSDInStabPool,
        uint _price
    )
        internal
        // view
        returns (uint debtToOffset, uint collToSendToSP, uint collToSendToOrumRevenue, uint debtToRedistribute, uint collToRedistribute)
    {
        if (_OSDInStabPool > 0) {
        /*
        * Offset as much debt & collateral as possible against the Stability Pool, and redistribute the remainder
        * between all active vaults.
        *
        *  If the vault's debt is larger than the deposited OSD in the Stability Pool:
        *
        *  - Offset an amount of the vault's debt equal to the OSD in the Stability Pool
        *  - Send a fraction of the vault's collateral to the Stability Pool and the OrumFeeDistribution contract. 
        *    The exact amount of collateral going to the OrumFeeDistribution is 20% of the total liquidation profit, 
        *    ideally, 20% * (MCR - 100)% = 0.2 * 0.35 = 0.07 or 7%.
        *    The exact amount of collateral going to the Stability pool is collateral equal in value to the debt offset + 80% of the profit
        *    Ideally, 100% + 80% * (MCR - 100) = 1 + 0.8 * .35 = 1.28 or 128%.
        */
            debtToOffset = OrumMath._min(_debt, _OSDInStabPool);
            collToSendToSP = _coll.mul(debtToOffset).div(_debt);
            debtToRedistribute = _debt.sub(debtToOffset);
            collToRedistribute = _coll.sub(collToSendToSP);


            // get the debt to offset in terms of the collateral i.e, ROSE
            uint _debtInROSE = debtToOffset.mul(DECIMAL_PRECISION).div(_price);

            uint _totalCollProfit = uint(OrumMath._max(int(collToSendToSP - _debtInROSE), 0));
            collToSendToOrumRevenue = _getTreasuryLiquidationProfit(_totalCollProfit);
            collToSendToSP = collToSendToSP - collToSendToOrumRevenue;
            // emit TEST_error(_debtInROSE, collToSendToSP, collToSendToOrumRevenue, _totalCollProfit);
        } else {
            debtToOffset = 0;
            collToSendToSP = 0;
            collToSendToOrumRevenue = 0;
            debtToRedistribute = _debt;
            collToRedistribute = _coll;
        }
    }

    /*
    *  Get its offset coll/debt and ROSE gas comp, and close the vault.
    */
    function _getCappedOffsetVals
    (
        uint _entireVaultDebt,
        uint _entireVaultColl,
        uint _price
    )
        internal
        view
        returns (LiquidationValues memory singleLiquidation)
    {
        singleLiquidation.entireVaultDebt = _entireVaultDebt;
        singleLiquidation.entireVaultColl = _entireVaultColl;
        uint cappedCollPortion = _entireVaultDebt.mul(MCR).div(_price);

        singleLiquidation.collGasCompensation = _getCollGasCompensation(cappedCollPortion);
        singleLiquidation.OSDGasCompensation = OSD_GAS_COMPENSATION;

        singleLiquidation.debtToOffset = _entireVaultDebt;
        uint totalProfits = cappedCollPortion.sub(singleLiquidation.collGasCompensation);
        singleLiquidation.collToSendToSP = _getTreasuryLiquidationProfit(totalProfits);
        singleLiquidation.collToSendToOrumRevenue = totalProfits - singleLiquidation.collToSendToSP;
        
        singleLiquidation.collSurplus = _entireVaultColl.sub(cappedCollPortion);
        singleLiquidation.debtToRedistribute = 0;
        singleLiquidation.collToRedistribute = 0;
    }

    /*
    * Liquidate a sequence of vaults. Closes a maximum number of n under-collateralized Vaults,
    * starting from the one with the lowest collateral ratio in the system, and moving upwards
    */
    function liquidateVaults(uint _n) external override {
        ContractsCache memory contractsCache = ContractsCache(
            activePool,
            defaultPool,
            IOSDToken(address(0)),
            sortedVaults,
            ICollSurplusPool(address(0)),
            address(0)
        );
        IStabilityPool stabilityPoolCached = stabilityPool;

        LocalVariables_OuterLiquidationFunction memory vars;

        LiquidationTotals memory totals;

        vars.price = priceFeed.fetchPrice();
        vars.OSDInStabPool = stabilityPoolCached.getTotalOSDDeposits();
        vars.recoveryModeAtStart = _checkRecoveryMode(vars.price);

        // Perform the appropriate liquidation sequence - tally the values, and obtain their totals
        if (vars.recoveryModeAtStart) {
            totals = _getTotalsFromLiquidateVaultsSequence_RecoveryMode(contractsCache, vars.price, vars.OSDInStabPool, _n);
        } else { // if !vars.recoveryModeAtStart
            totals = _getTotalsFromLiquidateVaultsSequence_NormalMode(contractsCache.activePool, contractsCache.defaultPool, vars.price, vars.OSDInStabPool, _n);
        }

        require(totals.totalDebtInSequence > 0, "VaultManager: nothing to liquidate");
        emit TEST_debt(totals.totalDebtToOffset);
        // Move liquidated ROSE and OSD to the appropriate pools
        stabilityPoolCached.offset(totals.totalDebtToOffset, totals.totalCollToSendToSP);
        // Send fees to the orum revenue
        contractsCache.activePool.sendROSE(orumRevenueAddress, totals.totalCollToSendToOrumRevenue);
        // Only for testing
        emit TEST_liquidationfee(totals.totalCollToSendToSP, totals.totalCollToSendToOrumRevenue);

        _redistributeDebtAndColl(contractsCache.activePool, contractsCache.defaultPool, totals.totalDebtToRedistribute, totals.totalCollToRedistribute);
        if (totals.totalCollSurplus > 0) {
            contractsCache.activePool.sendROSE(address(collSurplusPool), totals.totalCollSurplus);
        }

        // Update system snapshots
        _updateSystemSnapshots_excludeCollRemainder(contractsCache.activePool, totals.totalCollGasCompensation);

        vars.liquidatedDebt = totals.totalDebtInSequence;
        vars.liquidatedColl = totals.totalCollInSequence.sub(totals.totalCollGasCompensation).sub(totals.totalCollSurplus);
        emit Liquidation(vars.liquidatedDebt, vars.liquidatedColl, totals.totalCollGasCompensation, totals.totalOSDGasCompensation);

        // Send gas compensation to caller
        _sendGasCompensation(contractsCache.activePool, msg.sender, totals.totalOSDGasCompensation, totals.totalCollGasCompensation);
    }

    /*
    * This function is used when the liquidateVaults sequence starts during Recovery Mode. However, it
    * handle the case where the system *leaves* Recovery Mode, part way through the liquidation sequence
    */
    function _getTotalsFromLiquidateVaultsSequence_RecoveryMode
    (
        ContractsCache memory _contractsCache,
        uint _price,
        uint _OSDInStabPool,
        uint _n
    )
        internal
        returns(LiquidationTotals memory totals)
    {
        LocalVariables_LiquidationSequence memory vars;
        LiquidationValues memory singleLiquidation;

        vars.remainingOSDInStabPool = _OSDInStabPool;
        vars.backToNormalMode = false;
        vars.entireSystemDebt = getEntireSystemDebt();
        vars.entireSystemColl = getEntireSystemColl();

        vars.user = _contractsCache.sortedVaults.getLast();
        address firstUser = _contractsCache.sortedVaults.getFirst();
        for (vars.i = 0; vars.i < _n && vars.user != firstUser; vars.i++) {
            // we need to cache it, because current user is likely going to be deleted
            address nextUser = _contractsCache.sortedVaults.getPrev(vars.user);

            vars.ICR = getCurrentICR(vars.user, _price);

            if (!vars.backToNormalMode) {
                // Break the loop if ICR is greater than MCR and Stability Pool is empty
                if (vars.ICR >= MCR && vars.remainingOSDInStabPool == 0) { break; }

                uint TCR = OrumMath._computeCR(vars.entireSystemColl, vars.entireSystemDebt, _price);
                singleLiquidation = _liquidateRecoveryMode(_contractsCache.activePool, _contractsCache.defaultPool, vars.user, vars.ICR, vars.remainingOSDInStabPool, TCR, _price);

                // Update aggregate trackers
                vars.remainingOSDInStabPool = vars.remainingOSDInStabPool.sub(singleLiquidation.debtToOffset);
                vars.entireSystemDebt = vars.entireSystemDebt.sub(singleLiquidation.debtToOffset);
                vars.entireSystemColl = vars.entireSystemColl.
                    sub(singleLiquidation.collToSendToSP).
                    sub(singleLiquidation.collToSendToOrumRevenue).
                    sub(singleLiquidation.collGasCompensation).
                    sub(singleLiquidation.collSurplus);

                // Add liquidation values to their respective running totals
                totals = _addLiquidationValuesToTotals(totals, singleLiquidation);

                vars.backToNormalMode = !_checkPotentialRecoveryMode(vars.entireSystemColl, vars.entireSystemDebt, _price);
                // emit TEST_normalModeCheck(vars.backToNormalMode, vars.user, vars.ICR, vars.entireSystemColl, vars.entireSystemDebt, _price);
            }
            else if (vars.backToNormalMode && vars.ICR < MCR) {
                singleLiquidation = _liquidateNormalMode(_contractsCache.activePool, _contractsCache.defaultPool, vars.user, vars.remainingOSDInStabPool, _price);

                vars.remainingOSDInStabPool = vars.remainingOSDInStabPool.sub(singleLiquidation.debtToOffset);

                // Add liquidation values to their respective running totals
                totals = _addLiquidationValuesToTotals(totals, singleLiquidation);

            }  else break;  // break if the loop reaches a Vault with ICR >= MCR

            vars.user = nextUser;
        }
    }

    function _getTotalsFromLiquidateVaultsSequence_NormalMode
    (
        IActivePool _activePool,
        IDefaultPool _defaultPool,
        uint _price,
        uint _OSDInStabPool,
        uint _n
    )
        internal
        returns(LiquidationTotals memory totals)
    {
        LocalVariables_LiquidationSequence memory vars;
        LiquidationValues memory singleLiquidation;
        ISortedVaults sortedVaultsCached = sortedVaults;

        vars.remainingOSDInStabPool = _OSDInStabPool;

        for (vars.i = 0; vars.i < _n; vars.i++) {
            vars.user = sortedVaultsCached.getLast();
            vars.ICR = getCurrentICR(vars.user, _price);

            if (vars.ICR < MCR) {
                singleLiquidation = _liquidateNormalMode(_activePool, _defaultPool, vars.user, vars.remainingOSDInStabPool, _price);

                vars.remainingOSDInStabPool = vars.remainingOSDInStabPool.sub(singleLiquidation.debtToOffset);

                // Add liquidation values to their respective running totals
                totals = _addLiquidationValuesToTotals(totals, singleLiquidation);

            } else break;  // break if the loop reaches a Vault with ICR >= MCR
        }
    }
    function _getTotalFromBatchLiquidate_RecoveryMode
    (
        IActivePool _activePool,
        IDefaultPool _defaultPool,
        uint _price,
        uint _OSDInStabPool,
        address[] memory _vaultArray
    )
        internal
        returns(LiquidationTotals memory totals)
    {
        LocalVariables_LiquidationSequence memory vars;
        LiquidationValues memory singleLiquidation;

        vars.remainingOSDInStabPool = _OSDInStabPool;
        vars.backToNormalMode = false;
        vars.entireSystemDebt = getEntireSystemDebt();
        vars.entireSystemColl = getEntireSystemColl();

        for (vars.i = 0; vars.i < _vaultArray.length; vars.i++) {
            vars.user = _vaultArray[vars.i];
            // Skip non-active vaults
            if (Vaults[vars.user].status != Status.active) { continue; }
            vars.ICR = getCurrentICR(vars.user, _price);

            if (!vars.backToNormalMode) {

                // Skip this vault if ICR is greater than MCR and Stability Pool is empty
                if (vars.ICR >= MCR && vars.remainingOSDInStabPool == 0) { continue; }

                uint TCR = OrumMath._computeCR(vars.entireSystemColl, vars.entireSystemDebt, _price);

                singleLiquidation = _liquidateRecoveryMode(_activePool, _defaultPool, vars.user, vars.ICR, vars.remainingOSDInStabPool, TCR, _price);

                // Update aggregate trackers
                vars.remainingOSDInStabPool = vars.remainingOSDInStabPool.sub(singleLiquidation.debtToOffset);
                vars.entireSystemDebt = vars.entireSystemDebt.sub(singleLiquidation.debtToOffset);
                vars.entireSystemColl = vars.entireSystemColl.
                    sub(singleLiquidation.collToSendToSP).
                    sub(singleLiquidation.collToSendToOrumRevenue).
                    sub(singleLiquidation.collGasCompensation).
                    sub(singleLiquidation.collSurplus);

                // Add liquidation values to their respective running totals
                totals = _addLiquidationValuesToTotals(totals, singleLiquidation);

                vars.backToNormalMode = !_checkPotentialRecoveryMode(vars.entireSystemColl, vars.entireSystemDebt, _price);
            }

            else if (vars.backToNormalMode && vars.ICR < MCR) {
                singleLiquidation = _liquidateNormalMode(_activePool, _defaultPool, vars.user, vars.remainingOSDInStabPool, _price);
                vars.remainingOSDInStabPool = vars.remainingOSDInStabPool.sub(singleLiquidation.debtToOffset);

                // Add liquidation values to their respective running totals
                totals = _addLiquidationValuesToTotals(totals, singleLiquidation);

            } else continue; // In Normal Mode skip vaults with ICR >= MCR
        }
    }

    function _getTotalsFromBatchLiquidate_NormalMode
    (
        IActivePool _activePool,
        IDefaultPool _defaultPool,
        uint _price,
        uint _OSDInStabPool,
        address[] memory _vaultArray
    )
        internal
        returns(LiquidationTotals memory totals)
    {
        LocalVariables_LiquidationSequence memory vars;
        LiquidationValues memory singleLiquidation;

        vars.remainingOSDInStabPool = _OSDInStabPool;

        for (vars.i = 0; vars.i < _vaultArray.length; vars.i++) {
            vars.user = _vaultArray[vars.i];
            vars.ICR = getCurrentICR(vars.user, _price);

            if (vars.ICR < MCR) {
                singleLiquidation = _liquidateNormalMode(_activePool, _defaultPool, vars.user, vars.remainingOSDInStabPool, _price);
                vars.remainingOSDInStabPool = vars.remainingOSDInStabPool.sub(singleLiquidation.debtToOffset);

                // Add liquidation values to their respective running totals
                totals = _addLiquidationValuesToTotals(totals, singleLiquidation);
            }
        }
    }

    // --- Liquidation helper functions ---

    function _addLiquidationValuesToTotals(LiquidationTotals memory oldTotals, LiquidationValues memory singleLiquidation)
    internal pure returns(LiquidationTotals memory newTotals) {

        // Tally all the values with their respective running totals
        newTotals.totalCollGasCompensation = oldTotals.totalCollGasCompensation.add(singleLiquidation.collGasCompensation);
        newTotals.totalOSDGasCompensation = oldTotals.totalOSDGasCompensation.add(singleLiquidation.OSDGasCompensation);
        newTotals.totalDebtInSequence = oldTotals.totalDebtInSequence.add(singleLiquidation.entireVaultDebt);
        newTotals.totalCollInSequence = oldTotals.totalCollInSequence.add(singleLiquidation.entireVaultColl);
        newTotals.totalDebtToOffset = oldTotals.totalDebtToOffset.add(singleLiquidation.debtToOffset);
        newTotals.totalCollToSendToSP = oldTotals.totalCollToSendToSP.add(singleLiquidation.collToSendToSP);
        newTotals.totalDebtToRedistribute = oldTotals.totalDebtToRedistribute.add(singleLiquidation.debtToRedistribute);
        newTotals.totalCollToRedistribute = oldTotals.totalCollToRedistribute.add(singleLiquidation.collToRedistribute);
        newTotals.totalCollSurplus = oldTotals.totalCollSurplus.add(singleLiquidation.collSurplus);
        newTotals.totalCollToSendToOrumRevenue = oldTotals.totalCollToSendToOrumRevenue.add(singleLiquidation.collToSendToOrumRevenue);

        return newTotals;
    }

    function _sendGasCompensation(IActivePool _activePool, address _liquidator, uint _OSD, uint _ROSE) internal {
        if (_OSD > 0) {
            osdToken.returnFromPool(gasPoolAddress, _liquidator, _OSD);
        }

        if (_ROSE > 0) {
            _activePool.sendROSE(_liquidator, _ROSE);
        }
    }

    // Move a Vault's pending debt and collateral rewards from distributions, from the Default Pool to the Active Pool
    function _movePendingVaultRewardsToActivePool(IActivePool _activePool, IDefaultPool _defaultPool, uint _OSD, uint _ROSE) internal {
        _defaultPool.decreaseOSDDebt(_OSD);
        _activePool.increaseOSDDebt(_OSD);
        _defaultPool.sendROSEToActivePool(_ROSE);
    }

    // --- Redemption functions ---

    // Redeem as much collateral as possible from _borrower's Vault in exchange for OSD up to _maxOSDamount
    function _redeemCollateralFromVault(
        ContractsCache memory _contractsCache,
        address _borrower,
        uint _maxOSDamount,
        uint _price,
        address _upperPartialRedemptionHint,
        address _lowerPartialRedemptionHint,
        uint _partialRedemptionHintNICR
    )
        internal returns (SingleRedemptionValues memory singleRedemption)
    {
        // Determine the remaining amount (lot) to be redeemed, capped by the entire debt of the Vault minus the liquidation reserve
        singleRedemption.OSDLot = OrumMath._min(_maxOSDamount, Vaults[_borrower].debt.sub(OSD_GAS_COMPENSATION));

        // Get the ROSELot of equivalent value in USD
        singleRedemption.ROSELot = singleRedemption.OSDLot.mul(DECIMAL_PRECISION).div(_price);
        // console.log(singleRedemption.ROSELot);

        // Decrease the debt and collateral of the current Vault according to the OSD lot and corresponding ROSE to send
        uint newDebt = (Vaults[_borrower].debt).sub(singleRedemption.OSDLot);
        uint newColl = (Vaults[_borrower].coll).sub(singleRedemption.ROSELot);

        if (newDebt == OSD_GAS_COMPENSATION) {
            // No debt left in the Vault (except for the liquidation reserve), therefore the vault gets closed
            _removeStake(_borrower);
            _closeVault(_borrower, Status.closedByRedemption);
            _redeemCloseVault(_contractsCache, _borrower, OSD_GAS_COMPENSATION, newColl);
            emit VaultUpdated(_borrower, 0, 0, 0, uint8(VaultManagerOperation.redeemCollateral));

        } else {
            uint newNICR = OrumMath._computeNominalCR(newColl, newDebt);

            /*
            * If the provided hint is out of date, we bail since trying to reinsert without a good hint will almost
            * certainly result in running out of gas. 
            *
            * If the resultant net debt of the partial is less than the minimum, net debt we bail.
            */
            if (newNICR != _partialRedemptionHintNICR || _getNetDebt(newDebt) < MIN_NET_DEBT) {
                singleRedemption.cancelledPartial = true;
                return singleRedemption;
            }

            _contractsCache.sortedVaults.reInsert(_borrower, newNICR, _upperPartialRedemptionHint, _lowerPartialRedemptionHint);

            Vaults[_borrower].debt = newDebt;
            Vaults[_borrower].coll = newColl;
            _updateStakeAndTotalStakes(_borrower);

            emit VaultUpdated(
                _borrower,
                newDebt, newColl,
                Vaults[_borrower].stake,
                uint8(VaultManagerOperation.redeemCollateral)
            );
        }

        return singleRedemption;
    }

    /*
    * Called when a full redemption occurs, and closes the vault.
    * The redeemer swaps (debt - liquidation reserve) OSD for (debt - liquidation reserve) worth of ROSE, so the OSD liquidation reserve left corresponds to the remaining debt.
    * In order to close the vault, the OSD liquidation reserve is burned, and the corresponding debt is removed from the active pool.
    * The debt recorded on the vault's struct is zero'd elswhere, in _closeVault.
    * Any surplus ROSE left in the vault, is sent to the Coll surplus pool, and can be later claimed by the borrower.
    */
    function _redeemCloseVault(ContractsCache memory _contractsCache, address _borrower, uint _OSD, uint _ROSE) internal {
        _contractsCache.osdToken.burn(gasPoolAddress, _OSD);
        // Update Active Pool OSD, and send ROSE to account
        _contractsCache.activePool.decreaseOSDDebt(_OSD);

        // send ROSE from Active Pool to CollSurplus Pool
        _contractsCache.collSurplusPool.accountSurplus(_borrower, _ROSE);
        _contractsCache.activePool.sendROSE(address(_contractsCache.collSurplusPool), _ROSE);
    }

    function _isValidFirstRedemptionHint(ISortedVaults _sortedVaults, address _firstRedemptionHint, uint _price) internal view returns (bool) {
        if (_firstRedemptionHint == address(0) ||
            !_sortedVaults.contains(_firstRedemptionHint) ||
            getCurrentICR(_firstRedemptionHint, _price) < MCR
        ) {
            return false;
        }

        address nextVault = _sortedVaults.getNext(_firstRedemptionHint);
        return nextVault == address(0) || getCurrentICR(nextVault, _price) < MCR;
    }

    /* Send _OSDamount OSD to the system and redeem the corresponding amount of collateral from as many Vaults as are needed to fill the redemption
    * request.  Applies pending rewards to a Vault before reducing its debt and coll.
    *
    * Note that if _amount is very large, this function can run out of gas, specially if traversed vaults are small. This can be easily avoided by
    * splitting the total _amount in appropriate chunks and calling the function multiple times.
    *
    * Param `_maxIterations` can also be provided, so the loop through Vaults is capped (if it’s zero, it will be ignored).This makes it easier to
    * avoid OOG for the frontend, as only knowing approximately the average cost of an iteration is enough, without needing to know the “topology”
    * of the vault list. It also avoids the need to set the cap in stone in the contract, nor doing gas calculations, as both gas price and opcode
    * costs can vary.
    *
    * All Vaults that are redeemed from -- with the likely exception of the last one -- will end up with no debt left, therefore they will be closed.
    * If the last Vault does have some remaining debt, it has a finite ICR, and the reinsertion could be anywhere in the list, therefore it requires a hint.
    * A frontend should use getRedemptionHints() to calculate what the ICR of this Vault will be after redemption, and pass a hint for its position
    * in the sortedVaults list along with the ICR value that the hint was found for.
    *
    * If another transaction modifies the list between calling getRedemptionHints() and passing the hints to redeemCollateral(), it
    * is very likely that the last (partially) redeemed Vault would end up with a different ICR than what the hint is for. In this case the
    * redemption will stop after the last completely redeemed Vault and the sender will keep the remaining OSD amount, which they can attempt
    * to redeem later.
    */
    function redeemCollateral(
        uint _OSDamount,
        address _firstRedemptionHint,
        address _upperPartialRedemptionHint,
        address _lowerPartialRedemptionHint,
        uint _partialRedemptionHintNICR,
        uint _maxIterations,
        uint _maxFeePercentage
    )
        external
        override
    {
        ContractsCache memory contractsCache = ContractsCache(
            activePool,
            defaultPool,
            osdToken,
            sortedVaults,
            collSurplusPool,
            gasPoolAddress
        );
        RedemptionTotals memory totals;

        _requireValidMaxFeePercentage(_maxFeePercentage);
        totals.price = priceFeed.fetchPrice();
        _requireTCRoverMCR(totals.price);
        _requireAmountGreaterThanZero(_OSDamount);
        _requireOSDBalanceCoversRedemption(contractsCache.osdToken, msg.sender, _OSDamount);

        totals.totalOSDSupplyAtStart = getEntireSystemDebt();
        // Confirm redeemer's balance is less than total OSD supply
        assert(contractsCache.osdToken.balanceOf(msg.sender) <= totals.totalOSDSupplyAtStart);

        totals.remainingOSD = _OSDamount;
        address currentBorrower;

        if (_isValidFirstRedemptionHint(contractsCache.sortedVaults, _firstRedemptionHint, totals.price)) {
            currentBorrower = _firstRedemptionHint;
        } else {
            currentBorrower = contractsCache.sortedVaults.getLast();
            // Find the first vault with ICR >= MCR
            while (currentBorrower != address(0) && getCurrentICR(currentBorrower, totals.price) < MCR) {
                currentBorrower = contractsCache.sortedVaults.getPrev(currentBorrower);
            }
        }

        // Loop through the Vaults starting from the one with lowest collateral ratio until _amount of OSD is exchanged for collateral
        if (_maxIterations == 0) { _maxIterations = type(uint256).max; }
        while (currentBorrower != address(0) && totals.remainingOSD > 0 && _maxIterations > 0) {
            _maxIterations--;
            // Save the address of the Vault preceding the current one, before potentially modifying the list
            address nextUserToCheck = contractsCache.sortedVaults.getPrev(currentBorrower);

            _applyPendingRewards(contractsCache.activePool, contractsCache.defaultPool, currentBorrower);

            SingleRedemptionValues memory singleRedemption = _redeemCollateralFromVault(
                contractsCache,
                currentBorrower,
                totals.remainingOSD,
                totals.price,
                _upperPartialRedemptionHint,
                _lowerPartialRedemptionHint,
                _partialRedemptionHintNICR
            );

            if (singleRedemption.cancelledPartial) break; // Partial redemption was cancelled (out-of-date hint, or new net debt < minimum), therefore we could not redeem from the last Vault

            totals.totalOSDToRedeem  = totals.totalOSDToRedeem.add(singleRedemption.OSDLot);
            totals.totalROSEDrawn = totals.totalROSEDrawn.add(singleRedemption.ROSELot);

            totals.remainingOSD = totals.remainingOSD.sub(singleRedemption.OSDLot);
            currentBorrower = nextUserToCheck;
        }
        require(totals.totalROSEDrawn > 0, "VaultManager: Unable to redeem any amount");

        // Decay the baseRate due to time passed, and then increase it according to the size of this redemption.
        // Use the saved total OSD supply value, from before it was reduced by the redemption.
        _updateBaseRateFromRedemption(totals.totalROSEDrawn, totals.price, totals.totalOSDSupplyAtStart);

        // Calculate the ROSE fee
        totals.ROSEFee = _getRedemptionFee(totals.totalROSEDrawn);

        _requireUserAcceptsFee(totals.ROSEFee, totals.totalROSEDrawn, _maxFeePercentage);

        totals.ROSEToSendToRedeemer = totals.totalROSEDrawn.sub(totals.ROSEFee);

        emit Redemption(_OSDamount, totals.totalOSDToRedeem, totals.totalROSEDrawn, totals.ROSEFee);

        // Burn the total OSD that is cancelled with debt, and send the redeemed ROSE to msg.sender
        contractsCache.osdToken.burn(msg.sender, totals.totalOSDToRedeem);
        // Update Active Pool OSD, and send ROSE to account and orum revenue
        contractsCache.activePool.decreaseOSDDebt(totals.totalOSDToRedeem);
        contractsCache.activePool.sendROSE(msg.sender, totals.ROSEToSendToRedeemer);
        contractsCache.activePool.sendROSE(orumRevenueAddress, totals.ROSEFee);
    }

    // --- Helper functions ---

    // Return the nominal collateral ratio (ICR) of a given Vault, without the price. Takes a vault's pending coll and debt rewards from redistributions into account.
    function getNominalICR(address _borrower) public view override returns (uint) {
        (uint currentROSE, uint currentOSDDebt) = _getCurrentVaultAmounts(_borrower);

        uint NICR = OrumMath._computeNominalCR(currentROSE, currentOSDDebt);
        return NICR;
    }

    // Return the current collateral ratio (ICR) of a given Vault. Takes a vault's pending coll and debt rewards from redistributions into account.
    function getCurrentICR(address _borrower, uint _price) public view override returns (uint) {
        (uint currentROSE, uint currentOSDDebt) = _getCurrentVaultAmounts(_borrower);

        uint ICR = OrumMath._computeCR(currentROSE, currentOSDDebt, _price);
        return ICR;
    }

    function _getCurrentVaultAmounts(address _borrower) internal view returns (uint, uint) {
        uint pendingROSEReward = getPendingROSEReward(_borrower);
        uint pendingOSDDebtReward = getPendingOSDDebtReward(_borrower);

        uint currentROSE = Vaults[_borrower].coll.add(pendingROSEReward);
        uint currentOSDDebt = Vaults[_borrower].debt.add(pendingOSDDebtReward);

        return (currentROSE, currentOSDDebt);
    }

    function applyPendingRewards(address _borrower) external override {
        _requireCallerIsBorrowerOps();
        return _applyPendingRewards(activePool, defaultPool, _borrower);
    }

    // Add the borrowers's coll and debt rewards earned from redistributions, to their Vault
    function _applyPendingRewards(IActivePool _activePool, IDefaultPool _defaultPool, address _borrower) internal {
        if (hasPendingRewards(_borrower)) {
            _requireVaultIsActive(_borrower);

            // Compute pending rewards
            uint pendingROSEReward = getPendingROSEReward(_borrower);
            uint pendingOSDDebtReward = getPendingOSDDebtReward(_borrower);

            // Apply pending rewards to vault's state
            Vaults[_borrower].coll = Vaults[_borrower].coll.add(pendingROSEReward);
            Vaults[_borrower].debt = Vaults[_borrower].debt.add(pendingOSDDebtReward);

            _updateVaultRewardSnapshots(_borrower);

            // Transfer from DefaultPool to ActivePool
            _movePendingVaultRewardsToActivePool(_activePool, _defaultPool, pendingOSDDebtReward, pendingROSEReward);

            emit VaultUpdated(
                _borrower,
                Vaults[_borrower].debt,
                Vaults[_borrower].coll,
                Vaults[_borrower].stake,
                uint8(VaultManagerOperation.applyPendingRewards)
            );
        }
    }

    // Update borrower's snapshots of L_ROSE and L_OSDDebt to reflect the current values
    function updateVaultRewardSnapshots(address _borrower) external override {
        _requireCallerIsBorrowerOps();
       return _updateVaultRewardSnapshots(_borrower);
    }

    function _updateVaultRewardSnapshots(address _borrower) internal {
        rewardSnapshots[_borrower].ROSE = L_ROSE;
        rewardSnapshots[_borrower].OSDDebt = L_OSDDebt;
        emit VaultSnapshotsUpdated(L_ROSE, L_OSDDebt);
    }

    // Get the borrower's pending accumulated ROSE reward, earned by their stake
    function getPendingROSEReward(address _borrower) public view override returns (uint) {
        uint snapshotROSE = rewardSnapshots[_borrower].ROSE;
        uint rewardPerUnitStaked = L_ROSE.sub(snapshotROSE);

        if ( rewardPerUnitStaked == 0 || Vaults[_borrower].status != Status.active) { return 0; }

        uint stake = Vaults[_borrower].stake;

        uint pendingROSEReward = stake.mul(rewardPerUnitStaked).div(DECIMAL_PRECISION);

        return pendingROSEReward;
    }
    
    // Get the borrower's pending accumulated OSD reward, earned by their stake
    function getPendingOSDDebtReward(address _borrower) public view override returns (uint) {
        uint snapshotOSDDebt = rewardSnapshots[_borrower].OSDDebt;
        uint rewardPerUnitStaked = L_OSDDebt.sub(snapshotOSDDebt);

        if ( rewardPerUnitStaked == 0 || Vaults[_borrower].status != Status.active) { return 0; }

        uint stake =  Vaults[_borrower].stake;

        uint pendingOSDDebtReward = stake.mul(rewardPerUnitStaked).div(DECIMAL_PRECISION);

        return pendingOSDDebtReward;
    }

    function hasPendingRewards(address _borrower) public view override returns (bool) {
        /*
        * A Vault has pending rewards if its snapshot is less than the current rewards per-unit-staked sum:
        * this indicates that rewards have occured since the snapshot was made, and the user therefore has
        * pending rewards
        */
        if (Vaults[_borrower].status != Status.active) {return false;}
       
        return (rewardSnapshots[_borrower].ROSE < L_ROSE);
    }

    // Return the Vaults entire debt and coll, including pending rewards from redistributions.
    function getEntireDebtAndColl(
        address _borrower
    )
        public
        view
        override
        returns (uint debt, uint coll, uint pendingOSDDebtReward, uint pendingROSEReward)
    {
        debt = Vaults[_borrower].debt;
        coll = Vaults[_borrower].coll;

        pendingOSDDebtReward = getPendingOSDDebtReward(_borrower);
        pendingROSEReward = getPendingROSEReward(_borrower);

        debt = debt.add(pendingOSDDebtReward);
        coll = coll.add(pendingROSEReward);
    }

    function removeStake(address _borrower) external override {
        _requireCallerIsBorrowerOps();
        return _removeStake(_borrower);
    }

    // Remove borrower's stake from the totalStakes sum, and set their stake to 0
    function _removeStake(address _borrower) internal {
        uint stake = Vaults[_borrower].stake;
        totalStakes = totalStakes.sub(stake);
        Vaults[_borrower].stake = 0;
    }

    function updateStakeAndTotalStakes(address _borrower) external override returns (uint) {
        _requireCallerIsBorrowerOps();
        return _updateStakeAndTotalStakes(_borrower);
    }

    // Update borrower's stake based on their latest collateral value
    function _updateStakeAndTotalStakes(address _borrower) internal returns (uint) {
        uint newStake = _computeNewStake(Vaults[_borrower].coll);
        uint oldStake = Vaults[_borrower].stake;
        Vaults[_borrower].stake = newStake;

        totalStakes = totalStakes.sub(oldStake).add(newStake);
        emit TotalStakesUpdated(totalStakes);

        return newStake;
    }

    // Calculate a new stake based on the snapshots of the totalStakes and totalCollateral taken at the last liquidation
    function _computeNewStake(uint _coll) internal view returns (uint) {
        uint stake;
        if (totalCollateralSnapshot == 0) {
            stake = _coll;
        } else {
            /*
            * The following assert() holds true because:
            * - The system always contains >= 1 vault
            * - When we close or liquidate a vault, we redistribute the pending rewards, so if all vaults were closed/liquidated,
            * rewards would’ve been emptied and totalCollateralSnapshot would be zero too.
            */
            assert(totalStakesSnapshot > 0);
            stake = _coll.mul(totalStakesSnapshot).div(totalCollateralSnapshot);
        }
        return stake;
    }

    function _redistributeDebtAndColl(IActivePool _activePool, IDefaultPool _defaultPool, uint _debt, uint _coll) internal {
        if (_debt == 0) { return; }

        /*
        * Add distributed coll and debt rewards-per-unit-staked to the running totals. Division uses a "feedback"
        * error correction, to keep the cumulative error low in the running totals L_ROSE and L_OSDDebt:
        *
        * 1) Form numerators which compensate for the floor division errors that occurred the last time this
        * function was called.
        * 2) Calculate "per-unit-staked" ratios.
        * 3) Multiply each ratio back by its denominator, to reveal the current floor division error.
        * 4) Store these errors for use in the next correction when this function is called.
        * 5) Note: static analysis tools complain about this "division before multiplication", however, it is intended.
        */
        uint ROSENumerator = _coll.mul(DECIMAL_PRECISION).add(lastROSEError_Redistribution);
        uint OSDDebtNumerator = _debt.mul(DECIMAL_PRECISION).add(lastOSDDebtError_Redistribution);

        // Get the per-unit-staked terms
        uint ROSERewardPerUnitStaked = ROSENumerator.div(totalStakes);
        uint OSDDebtRewardPerUnitStaked = OSDDebtNumerator.div(totalStakes);

        lastROSEError_Redistribution = ROSENumerator.sub(ROSERewardPerUnitStaked.mul(totalStakes));
        lastOSDDebtError_Redistribution = OSDDebtNumerator.sub(OSDDebtRewardPerUnitStaked.mul(totalStakes));

        // Add per-unit-staked terms to the running totals
        L_ROSE = L_ROSE.add(ROSERewardPerUnitStaked);
        L_OSDDebt = L_OSDDebt.add(OSDDebtRewardPerUnitStaked);

        emit LTermsUpdated(L_ROSE, L_OSDDebt);

        // Transfer coll and debt from ActivePool to DefaultPool
        _activePool.decreaseOSDDebt(_debt);
        _defaultPool.increaseOSDDebt(_debt);
        _activePool.sendROSE(address(_defaultPool), _coll);
    }

    function closeVault(address _borrower) external override {
        _requireCallerIsBorrowerOps();
        return _closeVault(_borrower, Status.closedByOwner);
    }

    function _closeVault(address _borrower, Status closedStatus) internal {
        assert(closedStatus != Status.nonExistent && closedStatus != Status.active);

        uint VaultOwnersArrayLength = VaultOwners.length;
        _requireMoreThanOneVaultInSystem(VaultOwnersArrayLength);

        Vaults[_borrower].status = closedStatus;
        Vaults[_borrower].coll = 0;
        Vaults[_borrower].debt = 0;

        rewardSnapshots[_borrower].ROSE = 0;
        rewardSnapshots[_borrower].OSDDebt = 0;

        _removeVaultOwner(_borrower, VaultOwnersArrayLength);
        sortedVaults.remove(_borrower);
    }

    /*
    * Updates snapshots of system total stakes and total collateral, excluding a given collateral remainder from the calculation.
    * Used in a liquidation sequence.
    *
    * The calculation excludes a portion of collateral that is in the ActivePool:
    *
    * the total ROSE gas compensation from the liquidation sequence
    *
    * The ROSE as compensation must be excluded as it is always sent out at the very end of the liquidation sequence.
    */
    function _updateSystemSnapshots_excludeCollRemainder(IActivePool _activePool, uint _collRemainder) internal {
        totalStakesSnapshot = totalStakes;

        uint activeColl = _activePool.getROSE();
        uint liquidatedColl = defaultPool.getROSE();
        totalCollateralSnapshot = activeColl.sub(_collRemainder).add(liquidatedColl);

        emit SystemSnapshotsUpdated(totalStakesSnapshot, totalCollateralSnapshot);
    }

    // Push the owner's address to the Vault owners list, and record the corresponding array index on the Vault struct
    function addVaultOwnerToArray(address _borrower) external override returns (uint index) {
        _requireCallerIsBorrowerOps();
        return _addVaultOwnerToArray(_borrower);
    }

    function _addVaultOwnerToArray(address _borrower) internal returns (uint128 index) {
        /* Max array size is 2**128 - 1, i.e. ~3e30 vaults. No risk of overflow, since vaults have minimum OSD
        debt of liquidation reserve plus MIN_NET_DEBT. 3e30 OSD dwarfs the value of all wealth in the world ( which is < 1e15 USD). */

        // Push the Vaultowner to the array
        VaultOwners.push(_borrower);

        // Record the index of the new Vaultowner on their Vault struct
        index = uint128(VaultOwners.length.sub(1));
        Vaults[_borrower].arrayIndex = index;

        return index;
    }

    /*
    * Remove a Vault owner from the VaultOwners array, not preserving array order. Removing owner 'B' does the following:
    * [A B C D E] => [A E C D], and updates E's Vault struct to point to its new array index.
    */
    function _removeVaultOwner(address _borrower, uint VaultOwnersArrayLength) internal {
        Status vaultStatus = Vaults[_borrower].status;
        // It’s set in caller function `_closeVault`
        assert(vaultStatus != Status.nonExistent && vaultStatus != Status.active);

        uint128 index = Vaults[_borrower].arrayIndex;
        uint length = VaultOwnersArrayLength;
        uint idxLast = length.sub(1);

        assert(index <= idxLast);

        address addressToMove = VaultOwners[idxLast];

        VaultOwners[index] = addressToMove;
        Vaults[addressToMove].arrayIndex = index;
        emit VaultIndexUpdated(addressToMove, index);

        VaultOwners.pop();
    }

    // --- Recovery Mode and TCR functions ---

    function getTCR(uint _price) external view override returns (uint) {
        return _getTCR(_price);
    }

    function checkRecoveryMode(uint _price) external view override returns (bool) {
        return _checkRecoveryMode(_price);
    }

    // Check whether or not the system *would be* in Recovery Mode, given an ROSE:USD price, and the entire system coll and debt.
    function _checkPotentialRecoveryMode(
        uint _entireSystemColl,
        uint _entireSystemDebt,
        uint _price
    )
        internal
        view
    returns (bool)
    {
        uint TCR = OrumMath._computeCR(_entireSystemColl, _entireSystemDebt, _price);

        return TCR < CCR;
    }

    // --- Redemption fee functions ---

    /*
    * This function has two impacts on the baseRate state variable:
    * 1) decays the baseRate based on time passed since last redemption or OSD borrowing operation.
    * then,
    * 2) increases the baseRate based on the amount redeemed, as a proportion of total supply
    */
    function _updateBaseRateFromRedemption(uint _ROSEDrawn,  uint _price, uint _totalOSDSupply) internal returns (uint) {
        uint decayedBaseRate = _calcDecayedBaseRate();

        /* Convert the drawn ROSE back to OSD at face value rate (1 OSD:1 USD), in order to get
        * the fraction of total supply that was redeemed at face value. */
        uint redeemedOSDFraction = _ROSEDrawn.mul(_price).div(_totalOSDSupply);

        uint newBaseRate = decayedBaseRate.add(redeemedOSDFraction.div(BETA));
        newBaseRate = OrumMath._min(newBaseRate, DECIMAL_PRECISION); // cap baseRate at a maximum of 100%
        //assert(newBaseRate <= DECIMAL_PRECISION); // This is already enforced in the line above
        assert(newBaseRate > 0); // Base rate is always non-zero after redemption

        // Update the baseRate state variable
        baseRate = newBaseRate;
        emit BaseRateUpdated(newBaseRate);
        
        _updateLastFeeOpTime();

        return newBaseRate;
    }

    function getRedemptionRate() public view override returns (uint) {
        return _calcRedemptionRate(baseRate);
    }

    function getRedemptionRateWithDecay() public view override returns (uint) {
        return _calcRedemptionRate(_calcDecayedBaseRate());
    }

    function _calcRedemptionRate(uint _baseRate) internal pure returns (uint) {
        return OrumMath._min(
            REDEMPTION_FEE_FLOOR.add(_baseRate),
            DECIMAL_PRECISION // cap at a maximum of 100%
        );
    }

    function _getRedemptionFee(uint _ROSEDrawn) internal view returns (uint) {
        return _calcRedemptionFee(getRedemptionRate(), _ROSEDrawn);
    }

    function getRedemptionFeeWithDecay(uint _ROSEDrawn) external view override returns (uint) {
        return _calcRedemptionFee(getRedemptionRateWithDecay(), _ROSEDrawn);
    }

    function _calcRedemptionFee(uint _redemptionRate, uint _ROSEDrawn) internal pure returns (uint) {
        uint redemptionFee = _redemptionRate.mul(_ROSEDrawn).div(DECIMAL_PRECISION);
        require(redemptionFee < _ROSEDrawn, "VaultManager: Fee would eat up all returned collateral");
        return redemptionFee;
    }

    // --- Borrowing fee functions ---

    function getBorrowingRate() public view override returns (uint) {
        return _calcBorrowingRate(baseRate);
    }

    function getBorrowingRateWithDecay() public view override returns (uint) {
        return _calcBorrowingRate(_calcDecayedBaseRate());
    }

    function _calcBorrowingRate(uint _baseRate) internal view returns (uint) {
        return OrumMath._min(
            BORROWING_FEE_FLOOR.add(_baseRate),
            MAX_BORROWING_FEE
        );
    }

    function getBorrowingFee(uint _OSDDebt) external view override returns (uint) {
        return _calcBorrowingFee(getBorrowingRate(), _OSDDebt);
    }

    function getBorrowingFeeWithDecay(uint _OSDDebt) external view override returns (uint) {
        return _calcBorrowingFee(getBorrowingRateWithDecay(), _OSDDebt);
    }

    function _calcBorrowingFee(uint _borrowingRate, uint _OSDDebt) internal pure returns (uint) {
        return _borrowingRate.mul(_OSDDebt).div(DECIMAL_PRECISION);
    }


    // Updates the baseRate state variable based on time elapsed since the last redemption or OSD borrowing operation.
    function decayBaseRateFromBorrowing() external override {
        _requireCallerIsBorrowerOps();

        uint decayedBaseRate = _calcDecayedBaseRate();
        assert(decayedBaseRate <= DECIMAL_PRECISION);  // The baseRate can decay to 0

        baseRate = decayedBaseRate;
        emit BaseRateUpdated(decayedBaseRate);

        _updateLastFeeOpTime();
    }

    // --- Internal fee functions ---

    // Update the last fee operation time only if time passed >= decay interval. This prevents base rate griefing.
    function _updateLastFeeOpTime() internal {
        uint timePassed = block.timestamp.sub(lastFeeOperationTime);

        if (timePassed >= SECONDS_IN_ONE_MINUTE) {
            lastFeeOperationTime = block.timestamp;
            emit LastFeeOpTimeUpdated(block.timestamp);
        }
    }

    function _calcDecayedBaseRate() internal view returns (uint) {
        uint minutesPassed = _minutesPassedSinceLastFeeOp();
        uint decayFactor = OrumMath._decPow(MINUTE_DECAY_FACTOR, minutesPassed);

        return baseRate.mul(decayFactor).div(DECIMAL_PRECISION);
    }

    function _minutesPassedSinceLastFeeOp() internal view returns (uint) {
        return (block.timestamp.sub(lastFeeOperationTime)).div(SECONDS_IN_ONE_MINUTE);
    }

    // --- 'require' wrapper functions ---

    function _requireCallerIsBorrowerOps() internal view {
        require(msg.sender == borrowerOpsAddress, "VaultManager: Caller is not the BorrowerOps contract");
    }

    function _requireVaultIsActive(address _borrower) internal view {
        require(Vaults[_borrower].status == Status.active, "VaultManager: Vault does not exist or is closed");
    }

    function _requireOSDBalanceCoversRedemption(IOSDToken _osdToken, address _redeemer, uint _amount) internal view {
        require(_osdToken.balanceOf(_redeemer) >= _amount, "VaultManager: Requested redemption amount must be <= user's OSD token balance");
    }

    function _requireMoreThanOneVaultInSystem(uint VaultOwnersArrayLength) internal view {
        require (VaultOwnersArrayLength > 1 && sortedVaults.getSize() > 1, "VaultManager: Only one vault in the system");
    }

    function _requireAmountGreaterThanZero(uint _amount) internal pure {
        require(_amount > 0, "VaultManager: Amount must be greater than zero");
    }

    function _requireTCRoverMCR(uint _price) internal view {
        require(_getTCR(_price) >= MCR, "VaultManager: Cannot redeem when TCR < MCR");
    }

    function _requireValidMaxFeePercentage(uint _maxFeePercentage) internal pure {
        require(_maxFeePercentage >= REDEMPTION_FEE_FLOOR && _maxFeePercentage <= DECIMAL_PRECISION,
            "Max fee percentage must be between 0.5% and 100%");
    }

    // --- Vault property getters ---

    function getVaultStatus(address _borrower) external view override returns (uint) {
        return uint(Vaults[_borrower].status);
    }

    function getVaultStake(address _borrower) external view override returns (uint) {
        return Vaults[_borrower].stake;
    }

    function getVaultDebt(address _borrower) external view override returns (uint) {
        return Vaults[_borrower].debt;
    }

    function getVaultColl(address _borrower) external view override returns (uint) {
        return Vaults[_borrower].coll;
    }

    // --- Vault property setters, called by BorrowerOps ---

    function setVaultStatus(address _borrower, uint _num) external override {
        _requireCallerIsBorrowerOps();
        Vaults[_borrower].status = Status(_num);
    }

    function increaseVaultColl(address _borrower, uint _collIncrease) external override returns (uint) {
        _requireCallerIsBorrowerOps();
        uint newColl = Vaults[_borrower].coll.add(_collIncrease);
        Vaults[_borrower].coll = newColl;
        return newColl;
    }

    function decreaseVaultColl(address _borrower, uint _collDecrease) external override returns (uint) {
        _requireCallerIsBorrowerOps();
        uint newColl = Vaults[_borrower].coll.sub(_collDecrease);
        Vaults[_borrower].coll = newColl;
        return newColl;
    }

    function increaseVaultDebt(address _borrower, uint _debtIncrease) external override returns (uint) {
        _requireCallerIsBorrowerOps();
        uint newDebt = Vaults[_borrower].debt.add(_debtIncrease);
        Vaults[_borrower].debt = newDebt;
        return newDebt;
    }

    function decreaseVaultDebt(address _borrower, uint _debtDecrease) external override returns (uint) {
        _requireCallerIsBorrowerOps();
        uint newDebt = Vaults[_borrower].debt.sub(_debtDecrease);
        Vaults[_borrower].debt = newDebt;
        return newDebt;
    }
    // --- Owner only functions ---
    function changeTreasuryAddress(address _orumFeeDistributionAddress) external onlyOwner{
        // checkContract(_orumFeeDistributionAddress);
        orumRevenueAddress = _orumFeeDistributionAddress;
        emit OrumRevenueAddressChanged(_orumFeeDistributionAddress);
    }
    function changeBorrowFeeFloor(uint _newBorrowFeeFloor) external onlyOwner{
        BORROWING_FEE_FLOOR = DECIMAL_PRECISION / 1000 * _newBorrowFeeFloor;
    }
    function changeMCR(uint _newMCR) external onlyOwner{
        MCR = _newMCR;
    }
    function changeCCR(uint _newCCR) external onlyOwner{
        CCR = _newCCR;
    }
    function changeLiquidationReward(uint _newPERCENT_DIVISOR) external onlyOwner{
        PERCENT_DIVISOR = _newPERCENT_DIVISOR;
    }
    function changeMinNetDebt(uint _newMinDebt) external onlyOwner{
        MIN_NET_DEBT = _newMinDebt;
    }
    function changeGasCompensation(uint _OSDGasCompensation) external onlyOwner{
        OSD_GAS_COMPENSATION = _OSDGasCompensation;
    }

    function changeTreasuryLiquidationProfit(uint _percent) external onlyOwner{
        TREASURY_LIQUIDATION_PROFIT = DECIMAL_PRECISION / 100 * _percent;
    }
}