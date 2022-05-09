/**
 *Submitted for verification at Etherscan.io on 2022-05-09
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

// Part: IActivePool

interface IActivePool {
    // --- Events ---
    event BorrowerOpsAddressChanged(address _newBorrowerOpsAddress);
    event VaultManagerAddressChanged(address _newVaultManagerAddress);
    event ActivePoolUSDCDebtUpdated(uint _USDCDebt);
    event ActivePooloMATICBalanceUpdated(uint oMATIC);
    event SentoMATICActiveVault(address _to,uint _amount );
    event ActivePoolReceivedMATIC(uint _MATIC);
    event BorrowersRewardsPoolAddressChanged(address _borrowersRewardsPoolAddress);
    event StabilityPoolAddressChanged(address _stabilityPoolAddress);
    event oMATICSent(address _to, uint _amount);

    // --- Functions ---
    function sendoMATIC(address _account, uint _amount) external;
    function receiveoMATIC(uint new_coll) external;
    function getoMATIC() external view returns (uint);
    function getUSDCDebt() external view returns (uint);
    function increaseUSDCDebt(uint _amount) external;
    function decreaseUSDCDebt(uint _amount) external;


}

// Part: IBorrowersRewardsPool

interface IBorrowersRewardsPool  {
    // --- Events ---
    event VaultManagerAddressChanged(address _newVaultManagerAddress);
    event BorrowersRewardsPoolborrowersoMATICRewardsBalanceUpdated(uint _borrowersoMATICRewards);
    event BorrowersRewardsPoolborrowersoMATICRewardsBalanceUpdated_before(uint _borrowersoMATICRewards);
    event borrowersoMATICRewardsSent(address activePool, uint _amount);
    event BorrowersRewardsPooloMATICBalanceUpdated(uint _OrumwithdrawalborrowersoMATICRewards);
    event  ActivePoolAddressChanged(address _activePoolAddress);

    // --- Functions ---
    function sendborrowersoMATICRewardsToActivePool(uint _amount) external;
    function receiveoMATICBorrowersRewardsPool(uint new_coll) external;
    function getBorrowersoMATICRewards() external view returns (uint);

    function setAddresses(
        address _vaultManagerAddress,
        address _activePoolAddress,
        address _oMATICTokenAddress,
        address _rewardsPoolAddress
    ) external;
}

// Part: ICollSurplusPool

interface ICollSurplusPool {

    // --- Events ---
    
    event BorrowerOpsAddressChanged(address _newBorrowerOpsAddress);
    event VaultManagerAddressChanged(address _newVaultManagerAddress);
    event ActivePoolAddressChanged(address _newActivePoolAddress);

    event CollBalanceUpdated(address indexed _account, uint _newBalance);
    event oMATICSent(address _to, uint _amount);
    event CollSurplusoMATICBalanceUpdated(uint _oMATIC);
    event Test_event_call_sruplus(uint number_coll);

    // --- Contract setters ---

    function setAddresses(
        address _borrowerOpsAddress,
        address _vaultManagerAddress,
        address _activePoolAddress,
        address _oMATICTokenAddress
    ) external;

    function getoMATIC() external view returns (uint);

    function getCollateral(address _account) external view returns (uint);

    function accountSurplus(address _account, uint _amount) external;

    function claimColl(address _account) external;

    function receiveoMATICInCollSurplusPool(uint new_coll) external;
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

// Part: IGasPool

interface IGasPool  {
    // --- Events ---


    // --- Functions ---
    function sendToLiquidator(uint _amount, address _liquidator) external;

    function approveWhileCloseVault() external;

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
    // function checkpointToken() external;
    function veForAt(address _user, uint _timestamp) external view returns (uint);
    function checkpointTotalSupply() external;
    function claimable(address _addr) external view returns (uint);
    function applyAdmin() external;
    function commitAdmin(address _addr) external;
    function toggleAllowCheckpointToken() external;
    
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

interface IStabilityPool {
    // Events
    event P_Updated(uint _P);
    event S_Updated(uint _S, uint128 _epoch, uint128 _scale);
    event G_Updated(uint _G, uint128 _epoch, uint128 _scale);
    event EpochUpdated(uint128 _currentEpoch);
    event ScaleUpdated(uint128 _currentScale);
    event StabilityPoolUSDCBalanceUpdated(uint _newBalance);
    event StabilityPoolReceivedMATIC(uint value);
    event USDCTokenAddressChanged(address _usdcTokenAddress);
    event SentoMATICStabilityPool(address _to,uint _amount);
    event USDCSent(address _to,uint _amount);
    event DepositSnapshotUpdated(address _depositor, uint _P, uint _G);

    // Functions

    function provideToStabilityPool(uint _amount) external;
    
    function decreaseLentAmount(uint _amount) external;

    function allowBorrow() external view returns (bool);

    function withdrawFromStabilityPool(uint _amount) external;

    function sendUSDCtoBorrower(address _to, uint _amount) external;

    function getDepositorOrumGain(address _depositor) external returns (uint);

    function getUSDCDeposits() external returns (uint);

    function getUtilisationRatio() external view returns (uint);

    function convertOUSDCToUSDC(uint _amount) external returns (uint);

    function convertUSDCToOUSDC(uint _amount) external returns (uint);

    function rewardsOffset(uint _rewards) external;
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

// Part: IOrumBase

interface IOrumBase {
    function priceFeed() external view returns (IPriceFeed);
}

// Part: IUSDCToken

interface IUSDCToken is IERC20, IERC2612 { 
    
    // --- Events ---

    event StabilityPoolAddressChanged(address _newStabilityPoolAddress);

    event USDCTokenBalanceUpdated(address _user, uint _amount);

    // --- Functions ---

    function mint(address _account, uint256 _amount) external;

    function burn(address _account, uint256 _amount) external;

    function sendToPool(address _sender,  address poolAddress, uint256 _amount) external;

    function returnFromPool(address poolAddress, address user, uint256 _amount ) external;
}

// Part: IoMATICToken

interface IoMATICToken is IERC20, IERC2612 { 
    
    // --- Events ---


    // --- Functions ---

    function mint(address _account, uint256 _amount) external;

    function burn(address _account, uint256 _amount) external;

    function sendToPool(address _sender,  address poolAddress, uint256 _amount) external;

    function returnFromPool(address poolAddress, address user, uint256 _amount ) external;
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

library OrumMath {
    using SafeMath for uint;

    uint internal constant DECIMAL_PRECISION = 1e18;

    uint internal constant USDC_DECIMAL_PRECISION = 1e6;

    /* Precision for Nominal ICR (independent of price). Rationale for the value:
    *
    * - Making it "too high" could lead to overflows.
    * - Making it "too low" could lead to an ICR equal to zero, due to truncation from Solidity floor division.
    *
    * This value of 1e20 is chosen for safety: the NICR will only overflow for numerator > ~1e39 oMATIC,
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
            return _coll.mul(NICR_PRECISION).div(_debt).mul(USDC_DECIMAL_PRECISION).div(DECIMAL_PRECISION);
        }
        // Return the maximal value for uint256 if the Vault has a debt of 0. Represents "infinite" CR.
        else { // if (_debt == 0)
            return 2**256 - 1;
        }
    }

    function _computeCR(uint _coll, uint _debt, uint _price) internal pure returns (uint) {
        if (_debt > 0) {
            uint newCollRatio = _coll.mul(_price).div(_debt).mul(USDC_DECIMAL_PRECISION).div(DECIMAL_PRECISION);

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
    event USDCTokenAddressChanged(address _newUSDCTokenAddress);
    event ActivePoolAddressChanged(address _activePoolAddress);
    event StabilityPoolAddressChanged(address _stabilityPoolAddress);
    event GasPoolAddressChanged(address _gasPoolAddress);
    event CollSurplusPoolAddressChanged(address _collSurplusPoolAddress);
    event SortedVaultsAddressChanged(address _sortedVaultsAddress);
    event OrumRevenueAddressChanged(address _orumRevenueAddress);
    event oMATICTokenAddressChanged(address _newoMATICTokenAddress);
    event BorrowersRewardsPoolAddressChanged(address _borrowersRewardsPoolAddress);

    event Liquidation(uint _liquidatedDebt, uint _liquidatedColl, uint _collGasCompensation, uint _USDCGasCompensation);
    event Test_LiquidationoMATICFee(uint _oMATICFee);
    event Redemption(uint _attemptedUSDCAmount, uint _actualUSDCAmount, uint _oMATICSent, uint _oMATICFee);
    event VaultUpdated(address indexed _borrower, uint _debt, uint _coll, uint stake, uint8 operation);
    event VaultLiquidated(address indexed _borrower, uint _debt, uint _coll, uint8 operation);
    event BaseRateUpdated(uint _baseRate);
    event LastFeeOpTimeUpdated(uint _lastFeeOpTime);
    event TotalStakesUpdated(uint _newTotalStakes);
    event VaultIndexUpdated(address _borrower, uint _newIndex);
    event TEST_error(uint _debtInoMATIC, uint _collToSP, uint _collToOrum, uint _totalCollProfits);
    event TEST_liquidationfee(uint _totalCollToSendToSP, uint _totalCollToSendToOrumRevenue);
    event TEST_account(address _borrower, uint _amount);
    event TEST_normalModeCheck(bool _mode, address _borrower, uint _amount, uint _coll, uint _debt, uint _price);
    event TEST_debt(uint _debt);
    event TEST_offsetValues(uint _debtInoMATIC, uint debtToOffset, uint collToSendToSP, uint collToSendToOrumRevenue, uint _totalCollProfit, uint _stakingRToRedistribute);
    event Coll_getOffsetValues(uint _debt, uint _coll, uint _stakingRToRedistribute);
    event LTermsUpdated(uint _L_STAKINGR);
    event VaultSnapshotsUpdated(uint L_STAKINGR);
    event SystemSnapshotsUpdated(uint totalStakesSnapshot, uint totalCollateralSnapshot);
    // --- Functions ---
    function getVaultOwnersCount() external view returns (uint);

    function getVaultFromVaultOwnersArray(uint _index) external view returns (address);

    function getNominalICR(address _borrower) external view returns (uint);

    function getCurrentICR(address _borrower, uint _price) external view returns (uint);

    function liquidate(address _borrower) external;

    function liquidateVaults(uint _n) external;

    function batchLiquidateVaults(address[] calldata _VaultArray) external; 

    function addVaultOwnerToArray(address _borrower) external returns (uint index);

    function getEntireDebtAndColl(address _borrower) external view returns (
        uint debt, 
        uint coll,
        uint pendingStakingReward
    );

    function closeVault(address _borrower) external;

    function getBorrowingRate() external view returns (uint);

    function getBorrowingRateWithDecay() external view returns (uint);

    function getBorrowingFee(uint USDCDebt) external view returns (uint);

    function getBorrowingFeeWithDecay(uint _USDCDebt) external view returns (uint);

    function decayBaseRateFromBorrowing() external;

    function getVaultStatus(address _borrower) external view returns (uint);

    function getVaultDebt(address _borrower) external view returns (uint);

    function getVaultColl(address _borrower) external view returns (uint);

    function setVaultStatus(address _borrower, uint num) external;

    function increaseVaultColl(address _borrower, uint _collIncrease) external returns (uint);

    function decreaseVaultColl(address _borrower, uint _collDecrease) external returns (uint); 

    function increaseVaultDebt(address _borrower, uint _debtIncrease) external returns (uint); 

    function decreaseVaultDebt(address _borrower, uint _collDecrease) external returns (uint); 

    function getTCR(uint _price) external view returns (uint);

    function checkRecoveryMode(uint _price) external view returns (bool);

    function applyStakingRewards(address _borrower) external;

    function updateVaultRewardSnapshots(address _borrower) external;

    function getPendingStakingoMaticReward(address _borrower) external view returns (uint);

    function removeStake(address _borrower) external;

    function updateStakeAndTotalStakes(address _borrower) external returns (uint);

    function hasPendingRewards(address _borrower) external view returns (bool);

    function redistributeStakingRewards(uint _coll) external;

    
}

// Part: OrumBase

/* 
* Base contract for VaultManager, BorrowerOps and StabilityPool. Contains global system constants and
* common functions. 
*/
contract OrumBase is IOrumBase {
    using SafeMath for uint;

    uint constant public DECIMAL_PRECISION = 1e18;

    uint constant public USDC_DECIMAL_PRECISION = 1e6;

    uint constant public _100pct = 1000000000000000000; // 1e18 == 100%

    // Minimum collateral ratio for individual Vaults
    uint public MCR = 1100000000000000000; // 110%;

    // Critical system collateral ratio. If the system's total collateral ratio (TCR) falls below the CCR, Recovery Mode is triggered.
    uint public CCR = 1500000000000000000; // 150%

    // Amount of USDC to be locked in gas pool on opening vaults
    uint public USDC_GAS_COMPENSATION = 10e6;

    // Minimum amount of net USDC debt a vault must have
    uint public MIN_NET_DEBT = 50e6;

    uint public PERCENT_DIVISOR = 200; // dividing by 200 yields 0.5%

    uint public BORROWING_FEE_FLOOR = DECIMAL_PRECISION / 10000 * 75 ; // 0.75%

    uint public TREASURY_LIQUIDATION_PROFIT = DECIMAL_PRECISION / 100 * 20; // 20%
    


    address public contractOwner;

    IActivePool public activePool;

    IBorrowersRewardsPool public borrowersRewardsPool; 


    IPriceFeed public override priceFeed;

    constructor() {
        contractOwner = msg.sender;
    }
    // --- Gas compensation functions ---

    // Returns the composite debt (drawn debt + gas compensation) of a vault, for the purpose of ICR calculation
    function _getCompositeDebt(uint _debt) internal view  returns (uint) {
        return _debt.add(USDC_GAS_COMPENSATION);
    }
    function _getNetDebt(uint _debt) internal view returns (uint) {
        return _debt.sub(USDC_GAS_COMPENSATION);
    }
    // Return the amount of oMATIC to be drawn from a vault's collateral and sent as gas compensation.
    function _getCollGasCompensation(uint _entireColl) internal view returns (uint) {
        return _entireColl / PERCENT_DIVISOR;
    }
    
    function getEntireSystemColl() public view returns (uint entireSystemColl) {
        uint activeColl = activePool.getoMATIC();
        uint borrowerRewards = borrowersRewardsPool.getBorrowersoMATICRewards();
        return activeColl.add(borrowerRewards);
    }

    function getEntireSystemDebt() public view returns (uint entireSystemDebt) {
        uint activeDebt = activePool.getUSDCDebt();
        return activeDebt;
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
    string public constant NAME = "VaultManager";
    using SafeMath for uint256;

    // --- Connected contract declarations ---
    address public borrowerOpsAddress;

    IStabilityPool public stabilityPool;

    address gasPoolAddress;
    address orumRevenueAddress;

    IoMATICToken public oMaticToken;

    ICollSurplusPool collSurplusPool;
    IOrumRevenue orumRevenue;
    IGasPool public gasPool;

    IUSDCToken public usdcToken;
    // A doubly linked list of Vaults, sorted by their sorted by their collateral ratios
    ISortedVaults public sortedVaults;

    uint public baseRate;

    // --- Data structures ---
    uint256 public constant SECONDS_IN_ONE_MINUTE = 60;
    /*
     * Half-life of 12h. 12h = 720 min
     * (1/2) = d^720 => d = (1/2)^(1/720)
     */
    uint256 public constant MINUTE_DECAY_FACTOR = 999037758833783000;
    uint256 public constant REDEMPTION_FEE_FLOOR = (DECIMAL_PRECISION / 10000) * 75; // 0.75%
    uint256 public constant MAX_BORROWING_FEE = (DECIMAL_PRECISION / 100) * 5; // 5%

    // The timestamp of the latest fee operation (redemption or new USDC issuance)
    uint256 public lastFeeOperationTime;

    enum Status {
        nonExistent,
        active,
        closedByOwner,
        closedByLiquidation
    }

    // Store the necessary data for a vault
    struct Vault {
        uint256 debt;
        uint256 coll;
        uint stake;
        Status status;
        uint128 arrayIndex;
    }

    mapping(address => Vault) public Vaults;

    uint public totalStakes;

    // Snapshot of the value of totalStakes, taken immediately after the latest liquidation
    uint public totalStakesSnapshot;

    // Snapshot of the total collateral across the ActivePool and DefaultPool, immediately after the latest liquidation.
    uint public totalCollateralSnapshot;

    /*
    * L_STAKINGR track the sums of accumulated liquidation rewards per unit staked. During its lifetime, each stake earns:
    *
    * An oMATIC gain of ( stake * [L_STAKINGR - L_STAKINGR(0)] )
    *
    * Where L_STAKINGR(0)  are snapshots of L_STAKINGR for the active Vault taken at the instant the stake was made
    */
    uint public L_STAKINGR;

    // Map addresses with active vaults to their StakingRewardSnapshot
    mapping (address => StakingRewardSnapshot) public stakingRewardSnapshots;

    // Object containing the oMATIC snapshots for a given active vault
    struct StakingRewardSnapshot { uint STAKINGR;}

    // Array of all active vault addresses - used to to compute an approximate hint off-chain, for the sorted list insertion
    address[] public VaultOwners;

    // Error trackers for the vault redistribution calculation
    uint public lastSTAKINGRError_Redistribution;

    /*
     * --- Variable container structs for liquidations ---
     *
     * These structs are used to hold, return and assign variables inside the liquidation functions,
     * in order to avoid the error: "CompilerError: Stack too deep".
     *
     */

    struct LocalVariables_OuterLiquidationFunction {
        uint256 price;
        uint256 USDCInStabPool;
        bool recoveryModeAtStart;
        uint256 liquidatedDebt;
        uint256 liquidatedColl;
    }

    struct LocalVariables_InnerSingleLiquidateFunction {
        uint256 collToLiquidate;
        uint pendingStakingReward;
    }

    struct LocalVariables_LiquidationSequence {
        uint256 remainingUSDCInStabPool;
        uint256 i;
        uint256 ICR;
        address user;
        bool backToNormalMode;
        uint256 entireSystemDebt;
        uint256 entireSystemColl;
    }

    struct LiquidationValues {
        uint256 entireVaultDebt;
        uint256 entireVaultColl;
        uint256 collGasCompensation;
        uint256 USDCGasCompensation;
        uint256 debtToOffset;
        uint256 collToSendToSP;
        uint256 collToSendToOrumRevenue;
        uint stakingRToRedistribute;
        uint256 collSurplus;
    }
    
    struct LiquidationTotals {
        uint totalCollInSequence;
        uint totalDebtInSequence;
        uint totalCollGasCompensation;
        uint totalUSDCGasCompensation;
        uint totalDebtToOffset;
        uint totalCollToSendToSP;
        uint totalCollToSendToOrumRevenue;
        uint totalStakingRToRedistribute;
        uint totalCollSurplus;
    }

    struct ContractsCache {
        IActivePool activePool;
        IBorrowersRewardsPool borrowersRewardsPool;
        IUSDCToken usdcToken;
        ISortedVaults sortedVaults;
        ICollSurplusPool collSurplusPool;
        address gasPoolAddress;
    }

    enum VaultManagerOperation {
        applyStakingRewards,
        liquidateInNormalMode,
        liquidateInRecoveryMode,
        redeemCollateral
    }

    function setAddresses(
        address _borrowerOpsAddress,
        address _activePoolAddress,
        address _borrowersRewardsPoolAddress,
        address _stabilityPoolAddress,
        address _gasPoolAddress,
        address _collSurplusPoolAddress,
        address _priceFeedAddress,
        address _usdcTokenAddress,
        address _sortedVaultsAddress,
        address _orumRevenueAddress,
        address _oMATICTokenAddress
    )
        external
        onlyOwner
    {
        checkContract(_borrowerOpsAddress);
        checkContract(_activePoolAddress);
        checkContract(_stabilityPoolAddress);
        checkContract(_borrowersRewardsPoolAddress);
        checkContract(_gasPoolAddress);
        checkContract(_collSurplusPoolAddress);
        checkContract(_priceFeedAddress);
        checkContract(_usdcTokenAddress);
        checkContract(_sortedVaultsAddress);
        checkContract(_orumRevenueAddress);
        checkContract(_oMATICTokenAddress);
        checkContract(_gasPoolAddress);

        borrowerOpsAddress = _borrowerOpsAddress;
        activePool = IActivePool(_activePoolAddress);
        borrowersRewardsPool = IBorrowersRewardsPool(_borrowersRewardsPoolAddress);
        stabilityPool = IStabilityPool(_stabilityPoolAddress);
        gasPoolAddress = _gasPoolAddress;
        collSurplusPool = ICollSurplusPool(_collSurplusPoolAddress);
        priceFeed = IPriceFeed(_priceFeedAddress);
        usdcToken = IUSDCToken(_usdcTokenAddress);
        sortedVaults = ISortedVaults(_sortedVaultsAddress);
        orumRevenueAddress = _orumRevenueAddress;
        orumRevenue = IOrumRevenue(_orumRevenueAddress);
        oMaticToken = IoMATICToken(_oMATICTokenAddress);
        gasPool = IGasPool(_gasPoolAddress);

        emit BorrowerOpsAddressChanged(_borrowerOpsAddress);
        emit ActivePoolAddressChanged(_activePoolAddress);
        emit BorrowersRewardsPoolAddressChanged(_borrowersRewardsPoolAddress);
        emit StabilityPoolAddressChanged(_stabilityPoolAddress);
        emit GasPoolAddressChanged(_gasPoolAddress);
        emit CollSurplusPoolAddressChanged(_collSurplusPoolAddress);
        emit PriceFeedAddressChanged(_priceFeedAddress);
        emit USDCTokenAddressChanged(_usdcTokenAddress);
        emit SortedVaultsAddressChanged(_sortedVaultsAddress);
        emit OrumRevenueAddressChanged(_orumRevenueAddress);
        emit oMATICTokenAddressChanged(_oMATICTokenAddress);

    }

    // --- Getters ---

    function getVaultOwnersCount() external view override returns (uint) {
        return VaultOwners.length;
    }

    function getVaultFromVaultOwnersArray(uint _index) external view override returns (address) {
        return VaultOwners[_index];
    }

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
        IBorrowersRewardsPool borrowersRewardsPoolCached = borrowersRewardsPool;

        LocalVariables_OuterLiquidationFunction memory vars;
        LiquidationTotals memory totals;

        vars.price = priceFeed.fetchPrice();
        vars.recoveryModeAtStart = _checkRecoveryMode(vars.price);

        // Perform the appropriate liquidation sequence - tally values and obtain their totals.
        if (vars.recoveryModeAtStart) {
            totals = _getTotalFromBatchLiquidateRecoveryMode(activePoolCached, borrowersRewardsPool, vars.price,  _vaultArray);
        } else { 
            totals = _getTotalsFromBatchLiquidateNormalMode(activePoolCached, borrowersRewardsPool,vars.price, _vaultArray);
        }

        require(totals.totalDebtInSequence > 0, "VaultManager: nothing to liquidate");

        // Move liquidated oMATIC and USDC to the appropriate pools
        // stabilityPool.offset(totals.totalDebtToOffset, totals.totalCollToSendToSP);
        // Send fees to the orum revenue
        activePoolCached.sendoMATIC(orumRevenueAddress, totals.totalCollToSendToOrumRevenue);
        emit TEST_liquidationfee(totals.totalCollToSendToSP, totals.totalCollToSendToOrumRevenue);

        // _redistributeStakingRewards(activePoolCached, borrowersRewardsPoolCached, totals.totalStakingRToRedistribute);
        if (totals.totalCollSurplus > 0) {
            activePoolCached.sendoMATIC(address(collSurplusPool), totals.totalCollSurplus);
            collSurplusPool.receiveoMATICInCollSurplusPool(totals.totalCollSurplus);
        }

        vars.liquidatedDebt = totals.totalDebtInSequence;
        vars.liquidatedColl = totals.totalCollInSequence.sub(totals.totalCollGasCompensation).sub(totals.totalCollSurplus);
        emit Liquidation(vars.liquidatedDebt, vars.liquidatedColl, totals.totalCollGasCompensation, totals.totalUSDCGasCompensation);
        // Send gas compensation to caller
        _sendGasCompensation(activePoolCached, msg.sender, totals.totalUSDCGasCompensation, totals.totalCollGasCompensation);
    }

    function _getTotalFromBatchLiquidateRecoveryMode
    (
        IActivePool _activePool,
        IBorrowersRewardsPool _borrowersRewardsPool,
        uint _price,
        address[] memory _vaultArray
    )
        internal
        returns(LiquidationTotals memory totals)
    {
        LocalVariables_LiquidationSequence memory vars;
        LiquidationValues memory singleLiquidation;

        // vars.remainingUSDCInStabPool = _USDCInStabPool;
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
                if (vars.ICR >= CCR) { break; }

                uint TCR = OrumMath._computeCR(vars.entireSystemColl, vars.entireSystemDebt, _price);

                singleLiquidation = _liquidateRecoveryMode(_activePool, _borrowersRewardsPool, vars.user, vars.ICR, TCR, _price);

                // Update aggregate trackers
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
                singleLiquidation = _liquidateNormalMode(_activePool, _borrowersRewardsPool, vars.user, _price);
                // Add liquidation values to their respective running totals
                totals = _addLiquidationValuesToTotals(totals, singleLiquidation);

            } else continue; // In Normal Mode skip vaults with ICR >= MCR
        }
    }

    function _liquidateNormalMode(
        IActivePool _activePool,
        IBorrowersRewardsPool _borrowersRewardsPool,
        address _borrower,
        uint _price
    )
        internal
        returns (LiquidationValues memory singleLiquidation)
    {
        LocalVariables_InnerSingleLiquidateFunction memory vars;

        (singleLiquidation.entireVaultDebt, singleLiquidation.entireVaultColl, vars.pendingStakingReward) = getEntireDebtAndColl(_borrower);

        _movePendingVaultRewardsToActivePool(_activePool, _borrowersRewardsPool, vars.pendingStakingReward);
        _removeStake(_borrower);

        singleLiquidation.collGasCompensation = _getCollGasCompensation(singleLiquidation.entireVaultColl);
        singleLiquidation.USDCGasCompensation = USDC_GAS_COMPENSATION;
        uint collToLiquidate = singleLiquidation.entireVaultColl.sub(singleLiquidation.collGasCompensation);
        (singleLiquidation.debtToOffset,
        singleLiquidation.collToSendToSP,
        singleLiquidation.collToSendToOrumRevenue,
        singleLiquidation.stakingRToRedistribute) = _getOffsetValues(singleLiquidation.entireVaultDebt, collToLiquidate, _price);

        _closeVault(_borrower, Status.closedByLiquidation);
        emit VaultLiquidated(_borrower, singleLiquidation.entireVaultDebt, singleLiquidation.entireVaultColl, uint8(VaultManagerOperation.liquidateInNormalMode));
        emit VaultUpdated(_borrower, 0, 0, 0, uint8(VaultManagerOperation.liquidateInNormalMode));
        return singleLiquidation;
    }

    // Liquidate one vault, in Recovery Mode.
    function _liquidateRecoveryMode(
        IActivePool _activePool,
        IBorrowersRewardsPool _borrowersRewardsPool,
        address _borrower,
        uint _ICR,
        uint _TCR,
        uint _price
    )
        internal
        returns (LiquidationValues memory singleLiquidation)
    {
        LocalVariables_InnerSingleLiquidateFunction memory vars;
        if (VaultOwners.length <= 1) {return singleLiquidation;} // don't liquidate if last vault
        (singleLiquidation.entireVaultDebt, singleLiquidation.entireVaultColl, vars.pendingStakingReward) = getEntireDebtAndColl(_borrower);

        singleLiquidation.collGasCompensation = _getCollGasCompensation(singleLiquidation.entireVaultColl);
        singleLiquidation.USDCGasCompensation = USDC_GAS_COMPENSATION;
        vars.collToLiquidate = singleLiquidation.entireVaultColl.sub(singleLiquidation.collGasCompensation);
        
        // If ICR <= 100%, purely redistribute the Vault across all active Vaults
        if (_ICR <= _100pct) {
            _movePendingVaultRewardsToActivePool( _activePool, _borrowersRewardsPool, vars.pendingStakingReward);
            _removeStake(_borrower);

             (singleLiquidation.debtToOffset,
            singleLiquidation.collToSendToSP,
            singleLiquidation.collToSendToOrumRevenue,
            singleLiquidation.stakingRToRedistribute) = _getOffsetValues(singleLiquidation.entireVaultDebt, vars.collToLiquidate, _price);

            _closeVault(_borrower, Status.closedByLiquidation);
            emit VaultLiquidated(_borrower, singleLiquidation.entireVaultDebt, singleLiquidation.entireVaultColl, uint8(VaultManagerOperation.liquidateInRecoveryMode));
            emit VaultUpdated(_borrower, 0, 0, 0, uint8(VaultManagerOperation.liquidateInRecoveryMode));
            
        // If 100% < ICR < MCR, offset as much as possible, and redistribute the remainder
        } else if ((_ICR > _100pct) && (_ICR < MCR)) {
            _movePendingVaultRewardsToActivePool( _activePool, _borrowersRewardsPool,  vars.pendingStakingReward);
            _removeStake(_borrower);

            (singleLiquidation.debtToOffset,
            singleLiquidation.collToSendToSP,
            singleLiquidation.collToSendToOrumRevenue,
            singleLiquidation.stakingRToRedistribute) = _getOffsetValues(singleLiquidation.entireVaultDebt, vars.collToLiquidate, _price);

            _closeVault(_borrower, Status.closedByLiquidation);
            emit VaultLiquidated(_borrower, singleLiquidation.entireVaultDebt, singleLiquidation.entireVaultColl, uint8(VaultManagerOperation.liquidateInRecoveryMode));
            emit VaultUpdated(_borrower, 0, 0, 0, uint8(VaultManagerOperation.liquidateInRecoveryMode));
        /*
        * If 110% <= ICR < current TCR (accounting for the preceding liquidations in the current sequence)
        * and there is USDC in the Stability Pool, only offset, with no redistribution,
        * but at a capped rate of 1.1 and only if the whole debt can be liquidated.
        * The remainder due to the capped rate will be claimable as collateral surplus.
        */
        } else if ((_ICR >= MCR) && (_ICR < _TCR)) {
            _movePendingVaultRewardsToActivePool(_activePool, _borrowersRewardsPool, vars.pendingStakingReward);
            _removeStake(_borrower);

            singleLiquidation = _getCappedOffsetVals(singleLiquidation.entireVaultDebt, singleLiquidation.entireVaultColl, _price);
            _closeVault(_borrower, Status.closedByLiquidation);
            if (singleLiquidation.collSurplus > 0) {
                collSurplusPool.accountSurplus(_borrower, singleLiquidation.collSurplus);
            }

            emit VaultLiquidated(_borrower, singleLiquidation.entireVaultDebt, singleLiquidation.collToSendToSP, uint8(VaultManagerOperation.liquidateInRecoveryMode));
            emit VaultUpdated(_borrower, 0, 0, 0, uint8(VaultManagerOperation.liquidateInRecoveryMode));

        } else {
            LiquidationValues memory zeroVals;
            return zeroVals;
        }

        return singleLiquidation;
    }
    /*
    * This function is used when the liquidateVaults sequence starts during Recovery Mode. However, it
    * handle the case where the system *leaves* Recovery Mode, part way through the liquidation sequence
    */
    function _getTotalsFromLiquidateVaultsSequenceRecoveryMode
    (
        ContractsCache memory _contractsCache,
        uint _price,
        uint _n
    )
        internal
        returns(LiquidationTotals memory totals)
    {
        LocalVariables_LiquidationSequence memory vars;
        LiquidationValues memory singleLiquidation;
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
                if (vars.ICR >= CCR) { break; }

                uint TCR = OrumMath._computeCR(vars.entireSystemColl, vars.entireSystemDebt, _price);
                singleLiquidation = _liquidateRecoveryMode(_contractsCache.activePool, _contractsCache.borrowersRewardsPool, vars.user, vars.ICR, TCR, _price);
                // Update aggregate trackers
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
                singleLiquidation = _liquidateNormalMode(_contractsCache.activePool, _contractsCache.borrowersRewardsPool, vars.user, _price);

                // Add liquidation values to their respective running totals
                totals = _addLiquidationValuesToTotals(totals, singleLiquidation);

            }  else break;  // break if the loop reaches a Vault with ICR >= MCR

            vars.user = nextUser;
        }
    }

    function _getTotalsFromLiquidateVaultsSequenceNormalMode
    (
        IActivePool _activePool,
        IBorrowersRewardsPool _borrowersRewardsPool,
        uint _price,
        uint _n
    )
        internal
        returns(LiquidationTotals memory totals)
    {
        LocalVariables_LiquidationSequence memory vars;
        LiquidationValues memory singleLiquidation;
        ISortedVaults sortedVaultsCached = sortedVaults;

        for (vars.i = 0; vars.i < _n; vars.i++) {
            vars.user = sortedVaultsCached.getLast();
            vars.ICR = getCurrentICR(vars.user, _price);

            if (vars.ICR < MCR) {
                singleLiquidation = _liquidateNormalMode(_activePool, _borrowersRewardsPool, vars.user, _price);

                // Add liquidation values to their respective running totals
                totals = _addLiquidationValuesToTotals(totals, singleLiquidation);

            } else break;  // break if the loop reaches a Vault with ICR >= MCR
        }
    }

    // --- Liquidation helper functions ---

    function _addLiquidationValuesToTotals(LiquidationTotals memory oldTotals, LiquidationValues memory singleLiquidation)
    internal pure returns(LiquidationTotals memory newTotals) {
        // Tally all the values with their respective running totals
        newTotals.totalCollGasCompensation = oldTotals.totalCollGasCompensation.add(singleLiquidation.collGasCompensation);
        newTotals.totalUSDCGasCompensation = oldTotals.totalUSDCGasCompensation.add(singleLiquidation.USDCGasCompensation);
        newTotals.totalDebtInSequence = oldTotals.totalDebtInSequence.add(singleLiquidation.entireVaultDebt);
        newTotals.totalCollInSequence = oldTotals.totalCollInSequence.add(singleLiquidation.entireVaultColl);
        newTotals.totalDebtToOffset = oldTotals.totalDebtToOffset.add(singleLiquidation.debtToOffset);
        newTotals.totalCollToSendToSP = oldTotals.totalCollToSendToSP.add(singleLiquidation.collToSendToSP);
        newTotals.totalStakingRToRedistribute = oldTotals.totalStakingRToRedistribute.add(singleLiquidation.stakingRToRedistribute);
        newTotals.totalCollSurplus = oldTotals.totalCollSurplus.add(singleLiquidation.collSurplus);
        newTotals.totalCollToSendToOrumRevenue = oldTotals.totalCollToSendToOrumRevenue.add(singleLiquidation.collToSendToOrumRevenue);

        return newTotals;
    }

    function _getTotalsFromBatchLiquidateNormalMode
    (
        IActivePool _activePool,
        IBorrowersRewardsPool _borrowersRewardsPool,
        uint _price,
        address[] memory _vaultArray
    )
        internal
        returns(LiquidationTotals memory totals)
    {
        LocalVariables_LiquidationSequence memory vars;
        LiquidationValues memory singleLiquidation;


        for (vars.i = 0; vars.i < _vaultArray.length; vars.i++) {
            vars.user = _vaultArray[vars.i];
            vars.ICR = getCurrentICR(vars.user, _price);

            if (vars.ICR < MCR) {
                singleLiquidation = _liquidateNormalMode(_activePool, _borrowersRewardsPool, vars.user, _price);
                // Add liquidation values to their respective running totals
                totals = _addLiquidationValuesToTotals(totals, singleLiquidation);
            }
        }
    }

    /*
    *  Get its offset coll/debt and oMATIC gas comp, and close the vault.
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
        uint cappedCollPortion = _entireVaultDebt.mul(MCR).div(_price).mul(DECIMAL_PRECISION).div(USDC_DECIMAL_PRECISION);
        singleLiquidation.collGasCompensation = _getCollGasCompensation(cappedCollPortion);
        singleLiquidation.USDCGasCompensation = USDC_GAS_COMPENSATION;
        singleLiquidation.debtToOffset = _entireVaultDebt;
        uint totalProfits = cappedCollPortion.sub(singleLiquidation.collGasCompensation);
        singleLiquidation.collToSendToOrumRevenue = _getTreasuryLiquidationProfit(totalProfits);
        singleLiquidation.collToSendToSP = totalProfits - singleLiquidation.collToSendToOrumRevenue;
        singleLiquidation.collSurplus = _entireVaultColl.sub(cappedCollPortion);
        singleLiquidation.stakingRToRedistribute = 0;
    }

    /*
    * Liquidate a sequence of vaults. Closes a maximum number of n under-collateralized Vaults,
    * starting from the one with the lowest collateral ratio in the system, and moving upwards
    */
    function liquidateVaults(uint _n) external override {
        ContractsCache memory contractsCache = ContractsCache(
            activePool,
            borrowersRewardsPool,
            IUSDCToken(address(0)),
            sortedVaults,
            ICollSurplusPool(address(0)),
            address(0)
        );
        IStabilityPool stabilityPoolCached = stabilityPool;
        LocalVariables_OuterLiquidationFunction memory vars;
        LiquidationTotals memory totals;
        vars.price = priceFeed.fetchPrice();
        vars.recoveryModeAtStart = _checkRecoveryMode(vars.price);

        // Perform the appropriate liquidation sequence - tally the values, and obtain their totals
        if (vars.recoveryModeAtStart) {
            totals = _getTotalsFromLiquidateVaultsSequenceRecoveryMode(contractsCache, vars.price, _n);
        } else { // if !vars.recoveryModeAtStart
            totals = _getTotalsFromLiquidateVaultsSequenceNormalMode(contractsCache.activePool, contractsCache.borrowersRewardsPool, vars.price, _n);
        }
        require(totals.totalDebtInSequence > 0, "VaultManager: nothing to liquidate");
        emit TEST_debt(totals.totalDebtToOffset);
        // Move liquidated oMATIC and USDC to the appropriate pools
        // stabilityPool.offset(totals.totalDebtToOffset, totals.totalCollToSendToSP);
        // Send fees to the orum revenue
        contractsCache.activePool.sendoMATIC(orumRevenueAddress, totals.totalCollToSendToOrumRevenue);
        // Only for testing
        emit TEST_liquidationfee(totals.totalCollToSendToSP, totals.totalCollToSendToOrumRevenue);

        if (totals.totalCollSurplus > 0) {
            contractsCache.activePool.sendoMATIC(address(collSurplusPool), totals.totalCollSurplus);
            collSurplusPool.receiveoMATICInCollSurplusPool(totals.totalCollSurplus);
        }
        vars.liquidatedDebt = totals.totalDebtInSequence;
        vars.liquidatedColl = totals.totalCollInSequence.sub(totals.totalCollGasCompensation).sub(totals.totalCollSurplus);
        emit Liquidation(vars.liquidatedDebt, vars.liquidatedColl, totals.totalCollGasCompensation, totals.totalUSDCGasCompensation);
        // Send gas compensation to caller
        _sendGasCompensation(contractsCache.activePool, msg.sender, totals.totalUSDCGasCompensation, totals.totalCollGasCompensation);
    }

    /* In a full liquidation, returns the values for a vault's coll and debt to be offset, and coll and debt to be
    * redistributed to active vaults.
    */
    function _getOffsetValues
    (
        uint _debt,
        uint _coll,
        uint _price
    )
        internal
        // view
        returns (uint debtToOffset, uint collToSendToSP, uint collToSendToOrumRevenue, uint stakingRToRedistribute)
    {
        /*
        * Offset as much debt & collateral as possible against the Stability Pool, and redistribute the remainder
        * between all active vaults.
        *
        *  If the vault's debt is larger than the deposited USDC in the Stability Pool:
        *
        *  - Offset an amount of the vault's debt equal to the USDC in the Stability Pool
        *  - Send a fraction of the vault's collateral to the Stability Pool and the OrumFeeDistribution contract. 
        *    The exact amount of collateral going to the OrumFeeDistribution is 20% of the total liquidation profit, 
        *    ideally, 20% * (MCR - 100)% = 0.2 * 0.35 = 0.07 or 7%.
        *    The exact amount of collateral going to the Stability pool is collateral equal in value to the debt offset + 80% of the profit
        *    Ideally, 100% + 80% * (MCR - 100) = 1 + 0.8 * .35 = 1.28 or 128%.
        */
            debtToOffset = _debt;
            collToSendToSP = _coll;
            stakingRToRedistribute = _coll.sub(collToSendToSP);
            emit Coll_getOffsetValues(_debt, _coll, stakingRToRedistribute);


            // get the debt to offset in terms of the collateral i.e, oMATIC
            uint _debtInoMATIC = debtToOffset.mul(DECIMAL_PRECISION).div(_price).mul(DECIMAL_PRECISION).div(USDC_DECIMAL_PRECISION);
            uint _totalCollProfit = 0; 

            if (collToSendToSP > _debtInoMATIC) {
               _totalCollProfit =  uint(OrumMath._max(int(collToSendToSP - _debtInoMATIC), 0));
               collToSendToOrumRevenue = _getTreasuryLiquidationProfit(_totalCollProfit);
               collToSendToSP = collToSendToSP - collToSendToOrumRevenue;
            }
            else{
               collToSendToOrumRevenue = 0;
               stakingRToRedistribute = _coll;
            }

            emit TEST_offsetValues(_debtInoMATIC, debtToOffset, collToSendToSP, collToSendToOrumRevenue, _totalCollProfit, stakingRToRedistribute);
    }

    function _sendGasCompensation(IActivePool _activePool, address _liquidator, uint _USDC, uint _oMATIC) internal {
        if (_USDC > 0) {
        gasPool.sendToLiquidator(_USDC, _liquidator);
        }

        if (_oMATIC > 0) {
            _activePool.sendoMATIC(_liquidator, _oMATIC);
        }
    }

    // Move a Vault's pending debt and collateral rewards from distributions, from the Default Pool to the Active Pool
    function _movePendingVaultRewardsToActivePool(IActivePool _activePool, IBorrowersRewardsPool _borrowersRewardsPool, uint _oMATIC_Staking_Reward) internal {
        _borrowersRewardsPool.sendborrowersoMATICRewardsToActivePool(_oMATIC_Staking_Reward);
    }

    function checkRecoveryMode(uint _price) external view override returns (bool) {
        return _checkRecoveryMode(_price);
    }

    // --- Helper functions ---

    // Return the nominal collateral ratio (ICR) of a given Vault, without the price. Takes a vault's pending coll and debt rewards from redistributions into account.
    function getNominalICR(address _borrower) public view override returns (uint) {
        (uint currentoMATIC, uint currentUSDCDebt) = _getCurrentVaultAmounts(_borrower);

        uint NICR = OrumMath._computeNominalCR(currentoMATIC, currentUSDCDebt);
        return NICR;
    }

    // Return the current collateral ratio (ICR) of a given Vault. Takes a vault's pending coll and debt rewards from redistributions into account.
    function getCurrentICR(address _borrower, uint _price) public view override returns (uint) {
        (uint currentoMATIC, uint currentUSDCDebt) = _getCurrentVaultAmounts(_borrower);

        uint ICR = OrumMath._computeCR(currentoMATIC, currentUSDCDebt, _price);
        return ICR;
    }

    function _getCurrentVaultAmounts(address _borrower) internal view returns (uint, uint) {

        uint pendingStakingoMaticReward = getPendingStakingoMaticReward(_borrower);

        uint currentoMATIC = Vaults[_borrower].coll.add(pendingStakingoMaticReward);
        uint currentUSDCDebt = Vaults[_borrower].debt;

        return (currentoMATIC, currentUSDCDebt);
    }

    function applyStakingRewards(address _borrower) external override {
        _requireCallerIsBorrowerOps();
        return _applyStakingRewards(activePool, borrowersRewardsPool, _borrower);
    }

    // Add the borrowers's coll and debt rewards earned from redistributions, to their Vault
    function _applyStakingRewards(IActivePool _activePool, IBorrowersRewardsPool _borrowersRewardsPool, address _borrower) internal {
        if (hasPendingRewards(_borrower)) {
            _requireVaultIsActive(_borrower);

            // Compute pending rewards
            uint pendingStakingoMaticReward = getPendingStakingoMaticReward(_borrower);

            // Apply pending rewards to vault's state
            Vaults[_borrower].coll = Vaults[_borrower].coll.add(pendingStakingoMaticReward);

            _updateVaultRewardSnapshots(_borrower);

            // Transfer from DefaultPool to ActivePool
            _movePendingVaultRewardsToActivePool(_activePool, _borrowersRewardsPool, pendingStakingoMaticReward);

            emit VaultUpdated(
                _borrower,
                Vaults[_borrower].debt,
                Vaults[_borrower].coll,
                Vaults[_borrower].stake,
                uint8(VaultManagerOperation.applyStakingRewards)
            );
        }
    }

    // Update borrower's snapshots of L_STAKINGR  to reflect the current values
    function updateVaultRewardSnapshots(address _borrower) external override {
        _requireCallerIsBorrowerOps();
       return _updateVaultRewardSnapshots(_borrower);
    }

    function _updateVaultRewardSnapshots(address _borrower) internal {
        stakingRewardSnapshots[_borrower].STAKINGR = L_STAKINGR;
        emit VaultSnapshotsUpdated(L_STAKINGR);
    }

    // Get the borrower's pending accumulated oMATIC reward, earned by their stake
    function getPendingStakingoMaticReward(address _borrower) public view override returns (uint) {
        uint snapshotSTAKINGR = stakingRewardSnapshots[_borrower].STAKINGR;
        uint rewardPerUnitStaked = L_STAKINGR.sub(snapshotSTAKINGR);

        if ( rewardPerUnitStaked == 0 || Vaults[_borrower].status != Status.active) { return 0; }

        uint stake = Vaults[_borrower].stake;

        uint pendingStakingoMaticReward = stake.mul(rewardPerUnitStaked).div(DECIMAL_PRECISION);

        return pendingStakingoMaticReward;
    }

    function hasPendingRewards(address _borrower) public view override returns (bool) {
        /*
        * A Vault has pending rewards if its snapshot is less than the current rewards per-unit-staked sum:
        * this indicates that rewards have occured since the snapshot was made, and the user therefore has
        * pending rewards
        */
        if (Vaults[_borrower].status != Status.active) {return false;}
       
        return (stakingRewardSnapshots[_borrower].STAKINGR < L_STAKINGR);
    }

    // Return the Vaults entire debt and coll, including pending rewards from redistributions.
    function getEntireDebtAndColl(
        address _borrower
    )
        public
        view
        override
        returns (uint debt, uint coll, uint pendingStakingReward)
    {
        debt = Vaults[_borrower].debt;
        coll = Vaults[_borrower].coll;

        pendingStakingReward = getPendingStakingoMaticReward(_borrower);
        coll = coll.add(pendingStakingReward);
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

    function redistributeStakingRewards(uint _coll) external override {

        /*
        * Add distributed coll and debt rewards-per-unit-staked to the running totals. Division uses a "feedback"
        * error correction, to keep the cumulative error low in the running totals L_STAKINGR:
        *
        * 1) Form numerators which compensate for the floor division errors that occurred the last time this
        * function was called.
        * 2) Calculate "per-unit-staked" ratios.
        * 3) Multiply each ratio back by its denominator, to reveal the current floor division error.
        * 4) Store these errors for use in the next correction when this function is called.
        * 5) Note: static analysis tools complain about this "division before multiplication", however, it is intended.
        */
        uint oMATICNumerator = _coll.mul(DECIMAL_PRECISION).add(lastSTAKINGRError_Redistribution);

        // Get the per-unit-staked terms
        uint oMATICSTAKINGRewardPerUnitStaked = oMATICNumerator.div(totalStakes);

        lastSTAKINGRError_Redistribution = oMATICNumerator.sub(oMATICSTAKINGRewardPerUnitStaked.mul(totalStakes));

        // Add per-unit-staked terms to the running totals
        L_STAKINGR = L_STAKINGR.add(oMATICSTAKINGRewardPerUnitStaked);

        emit LTermsUpdated(L_STAKINGR);
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

        stakingRewardSnapshots[_borrower].STAKINGR = 0;

        _removeVaultOwner(_borrower, VaultOwnersArrayLength);
        sortedVaults.remove(_borrower);
    }

    // Push the owner's address to the Vault owners list, and record the corresponding array index on the Vault struct
    function addVaultOwnerToArray(address _borrower) external override returns (uint index) {
        _requireCallerIsBorrowerOps();
        return _addVaultOwnerToArray(_borrower);
    }

    function _addVaultOwnerToArray(address _borrower) internal returns (uint128 index) {
        /* Max array size is 2**128 - 1, i.e. ~3e30 vaults. No risk of overflow, since vaults have minimum USDC
        debt of liquidation reserve plus MIN_NET_DEBT. 3e30 USDC dwarfs the value of all wealth in the world ( which is < 1e15 USD). */

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

    // Check whether or not the system *would be* in Recovery Mode, given an oMATIC:USD price, and the entire system coll and debt.
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

    // --- Borrowing fee functions ---

    function getBorrowingRate() public view override returns (uint) {
        return _calcBorrowingRate(baseRate);
    }

    function _calcBorrowingRate(uint _baseRate) internal view returns (uint) {
        return OrumMath._min(
            BORROWING_FEE_FLOOR.add(_baseRate),
            MAX_BORROWING_FEE
        );
    }

    function getBorrowingFee(uint _USDCDebt) external view override returns (uint) {
        return _calcBorrowingFee(getBorrowingRate(), _USDCDebt);
    }

    function getBorrowingFeeWithDecay(uint _USDCDebt) external view override returns (uint) {
        return _calcBorrowingFee(getBorrowingRateWithDecay(), _USDCDebt);
    }

    function _calcBorrowingFee(uint _borrowingRate, uint _USDCDebt) internal pure returns (uint) {
        return _borrowingRate.mul(_USDCDebt).div(DECIMAL_PRECISION);
    }

    function getBorrowingRateWithDecay() public view override returns (uint) {
        return _calcBorrowingRate(_calcDecayedBaseRate());
    }

    function _calcDecayedBaseRate() internal view returns (uint) {
        uint minutesPassed = _minutesPassedSinceLastFeeOp();
        uint decayFactor = OrumMath._decPow(MINUTE_DECAY_FACTOR, minutesPassed);

        return baseRate.mul(decayFactor).div(DECIMAL_PRECISION);
    }

    // Updates the baseRate state variable based on time elapsed since the last redemption or USDC borrowing operation.
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

    function _requireUSDCBalanceCoversRedemption(IUSDCToken _usdcToken, address _redeemer, uint _amount) internal view {
        require(_usdcToken.balanceOf(_redeemer) >= _amount, "VaultManager: Requested redemption amount must be <= user's USDC token balance");
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
        checkContract(_orumFeeDistributionAddress);
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
    function changeGasCompensation(uint _USDCGasCompensation) external onlyOwner{
        USDC_GAS_COMPENSATION = _USDCGasCompensation;
    }

    function changeTreasuryLiquidationProfit(uint _percent) external onlyOwner{
        TREASURY_LIQUIDATION_PROFIT = DECIMAL_PRECISION / 100 * _percent;
    }
}