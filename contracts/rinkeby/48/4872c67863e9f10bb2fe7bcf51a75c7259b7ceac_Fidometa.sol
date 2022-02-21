/**
 *Submitted for verification at Etherscan.io on 2022-02-21
*/

pragma solidity ^0.8.11;
// SPDX-License-Identifier: Unlicensed
interface IERC20 {

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

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
contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;
     mapping (address => bool) public frozenAccount;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     /* This generates a public event on the blockchain that will notify clients */
    event FrozenFunds(address target, bool frozen);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor ()  {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    /// @notice `freeze? Prevent | Allow` `target` from sending & receiving tokens
    /// @param target Address to be frozen
    /// @param freeze either to freeze it or not
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }
}

contract Fidometa is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromCommunity_charge;

    mapping (address => bool) private _isExcludedFromReward;

    mapping (address => bool) private _isExcludedFromEcoSysFee;

    mapping (address => bool) private _isExcludedFromSurcharge1;

    mapping (address => bool) private _isExcludedFromSurcharge2;

    mapping (address => bool) private _isExcludedFromSurcharge3;

    address[] private _excludedFromReward;
   
    uint256 private constant MAX = ~uint256(0);


    string private _name = "Fido Meta";
    string private _symbol = "FMC";
    uint8  private _decimals = 9;
    uint256 private _tTotal = 15000000000  * 10 ** uint256(_decimals);
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tCommunityChargeTotal;


    address private _ecoSysWallet;
    address private _surcharge_1_Wallet;
    address private _surcharge_2_Wallet;
    address private _surcharge_3_Wallet;

    uint256 public _community_charge = 5;
    uint256 public _ecoSysFee = 1;
    uint256 public _surcharge1 = 0;
    uint256 public _surcharge2 = 0;
    uint256 public _surcharge3 = 0;

    uint256 private _previousCommunityCharge = _community_charge;
    uint256 private _previousEcoSysFee  = _ecoSysFee;
    uint256 private _previousSurcharge1 = _surcharge1;
    uint256 private _previousSurcharge2 = _surcharge2;
    uint256 private _previousSurcharge3 = _surcharge3;
    
    uint256 public _maxTxAmount = 5000000 * 10 ** uint256(_decimals);

    struct LockDetails {
        uint256 startTime;
        uint256 timeInDays;
        uint256 lockedToken;
    }

    struct TValues {
        uint256 tTransferAmount;
        uint256 tCommunityCharge;
        uint256 tEcoSysFee;
        uint256 tSurcharge1;
        uint256 tSurcharge2;
        uint256 tSurcharge3;
    }

    struct MValues {
        uint256 rAmount;
        uint256 rTransferAmount;
        uint256 rCommunityCharge;
        uint256 tTransferAmount;
        uint256 tCommunityCharge;
        uint256 tEcoSysFee;
        uint256 tSurcharge1;
        uint256 tSurcharge2;
        uint256 tSurcharge3;
    }



    event UnlockEvent(uint startTime, uint millis_days,uint expiry);
    mapping(address => LockDetails) public locks;



    /* * @dev Lock a specific amount of tokens for specific days.
     * @param target The target address.
     * @param tAmount Amount that has to be locked
     * @param timeindays duration in days for locking
     */
     function lock(address target_, uint256 tAmount, uint256 timeindays) public onlyOwner{
        require(target_ != address(0), "Invalid target");
        require(tAmount >= 0, "Amount should be greater than or equal to 0");
        require(timeindays >= 0, "timeindays should be greater than or equal to 0");
        uint256 balanceOfTarget = balanceOf(target_); 
        require(balanceOfTarget != 0, "No token to lock.");
        require(tAmount <= balanceOfTarget, "tAmount should be less than or equal to available balance");
        uint256  lockedToken = locks[target_].lockedToken;
        if(lockedToken > 0){
            uint256 avl_to_lock =  balanceOfTarget - lockedToken;
            require(tAmount <= avl_to_lock, "Not Sufficient token to lock.");
            lockedToken = lockedToken + tAmount;
            locks[target_].lockedToken = lockedToken;
        }else{
           locks[target_] = LockDetails(block.timestamp, timeindays, tAmount);
        }
    }



    /** @dev Set community Charge, to be deducted from each transaction
     *  @param community_charge ,in percentage
     */
     function setCommunityCharge(uint8 community_charge)  public onlyOwner{
        require(community_charge <= 100, "Community Charge % should be less than equal to 100%");
        _community_charge = community_charge;
    }

   /** @dev Set Ecosystem Fee, to be deducted from each transaction
     * @param ecoSysFee ,in percentage
     */
    function setEcoSysFee(uint8 ecoSysFee)  public onlyOwner{
        require(ecoSysFee <= 100, "EcoSysFee % should be less than equal to 100%");
        _ecoSysFee = ecoSysFee;
    }

    /** @dev Set Surcharge-1, to be deducted from each transaction
     *  @param surcharge1 ,in percentage
     */

    function setSurcharge1(uint8 surcharge1)  public onlyOwner{
        require(surcharge1 <= 100, "surcharge1 % should be less than equal to 100%");
        _surcharge1 = surcharge1;
    }

    /** @dev Set Surcharge-2, to be deducted from each transaction
     *  @param surcharge2 ,in percentage
     */
    function setSurcharge2(uint8 surcharge2)  public onlyOwner{
        require(surcharge2 <= 100, "surcharge2 % should be less than equal to 100%");
        _surcharge2 = surcharge2;
    }

    /** @dev Set Surcharge-3, to be deducted from each transaction
     *  @param surcharge3 ,in percentage
     */
    function setSurcharge3(uint8 surcharge3)  public onlyOwner{
        require(surcharge3 <= 100, "surcharge3 % should be less than equal to 100%");
        _surcharge3 = surcharge3;
    }

    /** @dev Set EcoSysWallet, Where ecosystem fee will deposited
     *  @param ecoSysWallet ,it,s a wallet  where ecosystem fee will be deposited
     */
    function setEcoSysWallet(address ecoSysWallet) public onlyOwner {
        require(ecoSysWallet != address(0), "Ecosystem wallet wallet is not valid");
        _ecoSysWallet = ecoSysWallet;
        _isExcludedFromCommunity_charge[_ecoSysWallet] = true;
        _isExcludedFromEcoSysFee[_ecoSysWallet] =   true;
        _isExcludedFromReward[_ecoSysWallet]    =   true;
        _isExcludedFromSurcharge1[_ecoSysWallet] =  true;
        _isExcludedFromSurcharge2[_ecoSysWallet] =  true;
        _isExcludedFromSurcharge3[_ecoSysWallet] =  true;
    }

    /** @dev Set surcharge_1_wallet, Where surcharge1 fee will be deposited
     *  @param surcharge_1_wallet ,it,s a wallet  where surcharge1 fee will be deposited
     */
    function setSurcharge_1_Wallet(address surcharge_1_wallet) public onlyOwner {
        _surcharge_1_Wallet = surcharge_1_wallet;
        _isExcludedFromCommunity_charge[_surcharge_1_Wallet] = true;
        _isExcludedFromEcoSysFee[_surcharge_1_Wallet] = true;
        _isExcludedFromReward[_surcharge_1_Wallet] = true;
        _isExcludedFromSurcharge1[_surcharge_1_Wallet] = true;
        _isExcludedFromSurcharge2[_surcharge_1_Wallet] = true;
        _isExcludedFromSurcharge3[_surcharge_1_Wallet] = true;
    }

    /** @dev Set surcharge_2_wallet, Where surcharge_2 fee will deposited
     *  @param surcharge_2_wallet ,it,s a wallet where surcharge_2 fee will be deposited
     */
    function setSurcharge_2_Wallet(address surcharge_2_wallet) public onlyOwner {
        _surcharge_2_Wallet = surcharge_2_wallet;
        _isExcludedFromCommunity_charge[_surcharge_2_Wallet] = true;
        _isExcludedFromEcoSysFee[_surcharge_2_Wallet] = true;
        _isExcludedFromReward[_surcharge_2_Wallet] = true;
        _isExcludedFromSurcharge1[_surcharge_2_Wallet] = true;
        _isExcludedFromSurcharge2[_surcharge_2_Wallet] = true;
        _isExcludedFromSurcharge3[_surcharge_2_Wallet] = true;
    }

    /** @dev Set surcharge_3_wallet, Where surcharge_3 fee will deposited
     *  @param surcharge_3_wallet ,it,s a wallet where surcharge_3 fee will be deposited
     */
    function setSurcharge_3_Wallet(address surcharge_3_wallet) public onlyOwner {
        _surcharge_3_Wallet = surcharge_3_wallet;
        _isExcludedFromCommunity_charge[_surcharge_3_Wallet] = true;
        _isExcludedFromEcoSysFee[_surcharge_3_Wallet] = true;
        _isExcludedFromReward[_surcharge_3_Wallet] = true;
        _isExcludedFromSurcharge1[_surcharge_3_Wallet] = true;
        _isExcludedFromSurcharge2[_surcharge_3_Wallet] = true;
        _isExcludedFromSurcharge3[_surcharge_3_Wallet] = true;
    }

    /** @dev show surcharge-1 wallet currently set
     */
     function viewSurcharge_1_Wallet() public view  returns (address) {
        return _surcharge_1_Wallet;
    }

    /** @dev show surcharge-2 wallet currently set
     */
        function viewSurcharge_2_Wallet() public view  returns (address) {
        return _surcharge_2_Wallet;
    }

    /** @dev show surcharge-3 wallet currently set
     */
        function viewSurcharge_3_Wallet() public view  returns (address) {
        return _surcharge_3_Wallet;
    }

    /** @dev show Ecosystem wallet currently set
     */
         function viewEcoSysWallet() public view  returns (address) {
        return _ecoSysWallet;
    }


   /** @dev Burns a specific amount of tokens.
     * @param value The amount of lowest token units to be burned.
     */
    function burn(uint256 value) public onlyOwner {
      _burn(msg.sender, value);
    }
    
    
     /** @dev Mint a specific amount of tokens.
     * @param value The amount of lowest token units to be mint.
     */
    function mint(uint256 value) public onlyOwner {
      _mint(msg.sender, value);
    }
  
    /** @dev burn some token from an account
     */   
	function _burn(address account, uint256 amount) internal onlyOwner {
    require(account != address(0), "ERC20: burn from the zero address");
    require(amount <= balanceOf(account), "ERC20: burn amount exceeds balance");
    _tTotal = _tTotal.sub(amount);
    emit Transfer(account, address(0), amount);
  }

     /** @dev mint some token to an address
     */ 
    function _mint(address account, uint amount) internal onlyOwner {
        require(account != address(0), "ERC20: mint to the zero address");
        _tTotal = _tTotal.add(amount);
        emit Transfer(address(0), account, amount);
    }
   
    /** @dev show the startTime, locked amount and expiry of a target
     */ 
     function lockDetail(address target_) public view returns(uint startTime, uint lockedToken,uint unlockDateEpoch) {
        require(target_ != address(0), "Invalid target");
        uint256  startTimeOfLockedToken = locks[target_].startTime;
        uint256  timeInDaysOfLockedToken = locks[target_].timeInDays;
        uint256  lockedTokenQuantity = locks[target_].lockedToken;
        uint millis_days = timeInDaysOfLockedToken * 1 days;
        uint expiry = startTimeOfLockedToken + millis_days;
       return(startTimeOfLockedToken,lockedTokenQuantity,expiry);
    }

     /** @dev extend the locking time, for already locked token
     */    
     function extendLockTime(address target_, uint256 timeindays) external onlyOwner{
        require(timeindays >= 0, "TimeInDays should be greater than 0");
        uint256  lockedToken = locks[target_].lockedToken;
        require(lockedToken >= 0, "No tokens lock found");
        locks[target_].timeInDays = locks[target_].timeInDays + timeindays;
    }

     /** @dev Reduce the locking time, for already locked token
     */
    
    function reduceLockTime(address target_, uint256 timeindays) external onlyOwner{
        require(timeindays >= 0, "TimeInDays should be greater than 0");
        uint256  lockedToken = locks[target_].lockedToken;
        require(lockedToken >= 0, "No tokens lock found");
        uint256  lockedTokenTime = locks[target_].timeInDays;
        require(lockedTokenTime > 1, "Locking time can not be less than 1 Day");
        require(timeindays < lockedTokenTime, "timeindays is more than current lock time");

        locks[target_].timeInDays = locks[target_].timeInDays - timeindays;
    }

     /** @dev unlock token by owner on any address
     */
     function unlockToken(address target_, uint256 amount) external onlyOwner{
        require(amount >= 0, "Amount should be greater than 0");
        uint  lockedToken = locks[target_].lockedToken;
        require(lockedToken >= 0, "No locked token available");
	require(amount <= lockedToken, "Invalid Amount input");
        if(locks[target_].lockedToken == amount){
            delete locks[target_];
        }else{
            locks[target_].lockedToken = locks[target_].lockedToken - amount;
        }
    }

     /**release all locks on token by owner 
     */
     function releaseLock(address target_) external onlyOwner{
        uint  lockedToken = locks[target_].lockedToken;
        require(lockedToken >= 0, "No locked token available");
        delete locks[target_];
    }

    constructor ()  {
        _rOwned[_msgSender()] = _rTotal;
        
        //exclude owner and this contract from fees
        _isExcludedFromCommunity_charge[owner()] = true;
        _isExcludedFromCommunity_charge[address(this)] = true;

        _isExcludedFromEcoSysFee[owner()] = true;
        _isExcludedFromEcoSysFee[address(this)] = true;

        _isExcludedFromSurcharge1[owner()] = true;
        _isExcludedFromSurcharge1[address(this)] = true;

        _isExcludedFromSurcharge2[owner()] = true;
        _isExcludedFromSurcharge2[address(this)] = true;

        _isExcludedFromSurcharge3[owner()] = true;
        _isExcludedFromSurcharge3[address(this)] = true;

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcludedFromReward[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcludedFromReward[account];
    }

    //Shows total community charge deducted so far
    function totalCommunityCharge() public view returns (uint256) {
        return _tCommunityChargeTotal;
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (MValues memory m) = _getValues(tAmount);
            return m.rAmount;
        } else {
            (MValues memory m) = _getValues(tAmount);
            return m.rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    //exclude an address from getting community reward
    function excludeFromReward(address account) public onlyOwner() {
        require(!_isExcludedFromReward[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcludedFromReward[account] = true;
        _excludedFromReward.push(account);
    }

    //include an address from getting community reward
    function includeInReward(address account) external onlyOwner() {
        require(_isExcludedFromReward[account], "Account is already excluded");
        for (uint256 i = 0; i < _excludedFromReward.length; i++) {
            if (_excludedFromReward[i] == account) {
                _excludedFromReward[i] = _excludedFromReward[_excludedFromReward.length - 1];
                _tOwned[account] = 0;
                _isExcludedFromReward[account] = false;
                _excludedFromReward.pop();
                break;
            }
        }
    }
    //exclude from community charge
    function excludeFromCommunityCharge(address account) public onlyOwner {
        _isExcludedFromCommunity_charge[account] = true;
    }
    //include in community charge
    function includeInCommunityCharge(address account) public onlyOwner {
        _isExcludedFromCommunity_charge[account] = false;
    }


    //exclude from ecosystem fee
    function excludedFromEcoSysFee(address account) public onlyOwner {
        _isExcludedFromEcoSysFee[account] = true;
    }

   //include in ecosystem fee
    function includeInEcoSysFee(address account) public onlyOwner {
        _isExcludedFromEcoSysFee[account] = false;
    }

 


    //exclude from surcharge1
    function excludedFromSurcharge1(address account) public onlyOwner {
        _isExcludedFromSurcharge1[account] = true;
    }
    //include in surcharge1
    function includeInSurcharge1(address account) public onlyOwner {
        _isExcludedFromSurcharge1[account] = false;
    }


    //exclude from surcharge2
    function excludedFromSurcharge2(address account) public onlyOwner {
        _isExcludedFromSurcharge2[account] = true;
    }
    //include in surcharge2
    function includeInSurcharge2(address account) public onlyOwner {
        _isExcludedFromSurcharge2[account] = false;
    }


    //exclude from surcharge3
    function excludedFromSurcharge3(address account) public onlyOwner {
        _isExcludedFromSurcharge3[account] = true;
    }
    //include in surcharge3
    function includeInSurcharge3(address account) public onlyOwner {
        _isExcludedFromSurcharge3[account] = false;
    }

    
    /** it set the maximum amount of token an address can tranfer at once
    */
    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {
        _maxTxAmount = _tTotal.mul(maxTxPercent).div(
            10**2
        );
    }

  
    // it calculates ecosystem fee for an amount
        function calculateEcoSysFee(uint256 _amount) private view returns (uint256) {
        if (_ecoSysWallet == address(0)) return 0;
        return _amount.mul(_ecoSysFee).div(10**2);
    }

    // it calculates community charge for an amount
    function calculateCommunityCharge(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_community_charge).div(
            10**2
        );
    }

    // it calculates surcharge1  for an amount
        function calculateSurcharge1(uint256 _amount) private view returns (uint256) {
        if (_surcharge_1_Wallet == address(0)) return 0;
        return _amount.mul(_surcharge1).div(10**2);
    }

    // it calculates surcharge2 for an amount
        function calculateSurcharge2(uint256 _amount) private view returns (uint256) {
        if (_surcharge_2_Wallet == address(0)) return 0;
        return _amount.mul(_surcharge2).div(10**2);
    }
    
    // it calculates surcharge3  for an amount
        function calculateSurcharge3(uint256 _amount) private view returns (uint256) {
        if (_surcharge_3_Wallet == address(0)) return 0;
        return _amount.mul(_surcharge3).div(10**2);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tCommunityChargeTotal = _tCommunityChargeTotal.add(tFee);
    }


    function _getValues(uint256 tAmount) private view returns (MValues memory) {
       uint256 currentRate = _getRate();
        (TValues memory value) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rCommunityCharge) = _getRValues(tAmount, value.tCommunityCharge, currentRate);
        uint256 rEcoSysFee =   value.tEcoSysFee.mul(currentRate);
        uint256 rSurcharge1 =  value.tSurcharge1.mul(currentRate);
        uint256 rSurcharge2 =  value.tSurcharge2.mul(currentRate);
        uint256 rSurcharge3 =  value.tSurcharge3.mul(currentRate);
        rTransferAmount =  rTransferAmount.sub(rEcoSysFee).sub(rSurcharge1).sub(rSurcharge2).sub(rSurcharge3);
        MValues memory mValues = MValues({rAmount:rAmount,rTransferAmount:rTransferAmount, rCommunityCharge:rCommunityCharge, tTransferAmount:value.tTransferAmount,tCommunityCharge: value.tCommunityCharge,tEcoSysFee:value.tEcoSysFee,tSurcharge1:value.tSurcharge1,tSurcharge2:value.tSurcharge2,tSurcharge3:value.tSurcharge3 });
        return (mValues);
    }


    function _getTValues(uint256 tAmount) private view returns (TValues memory) {
        uint256   tCommunityCharge = calculateCommunityCharge(tAmount);
        uint256   tEcoSysFee = calculateEcoSysFee(tAmount);
        uint256   tSurcharge1 = calculateSurcharge1(tAmount);
        uint256   tSurcharge2 = calculateSurcharge2(tAmount);
        uint256   tSurcharge3 = calculateSurcharge3(tAmount);
         uint256 tTransferAmountEco = tAmount.sub(tCommunityCharge).sub(tEcoSysFee);
         uint256 tTransferAmount =  tTransferAmountEco.sub(tSurcharge1).sub(tSurcharge2).sub(tSurcharge3);
        TValues memory tvalue = TValues({tTransferAmount:tTransferAmount, tCommunityCharge:tCommunityCharge, tEcoSysFee:tEcoSysFee,tSurcharge1:tSurcharge1,tSurcharge2:tSurcharge2,tSurcharge3:tSurcharge3});
        return (tvalue);
    }

    function _getRValues(uint256 tAmount, uint256 tFee,uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        for (uint256 i = 0; i < _excludedFromReward.length; i++) {
            if (_rOwned[_excludedFromReward[i]] > rSupply || _tOwned[_excludedFromReward[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excludedFromReward[i]]);
            tSupply = tSupply.sub(_tOwned[_excludedFromReward[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

 function removeEcosysFee() private {
        if(_ecoSysFee == 0) return;
        _previousEcoSysFee = _ecoSysFee;
        _ecoSysFee = 0;
    }

     function removeSurcharge1() private {
        if(_surcharge1 == 0) return;
        _previousSurcharge1 = _surcharge1;
        _surcharge1 = 0;
    }

     function removeSurcharge2() private {
        if(_surcharge2 == 0) return;
        _previousSurcharge2 = _surcharge2;
        _surcharge2 = 0;
    }
     function removeSurcharge3() private {
        if(_surcharge3 == 0) return;
        _previousSurcharge3 = _surcharge3;
        _surcharge3 = 0;
    }
   
    
    function removeCommunityCharge() private {
        if(_community_charge == 0) return;
        _previousCommunityCharge = _community_charge;
        _community_charge = 0;
    }
    
    function restoreCommunityCharge() private {
        _community_charge = _previousCommunityCharge;
    }

     function restoreEcosysFee() private {
        _ecoSysFee = _previousEcoSysFee;
    }

     function restoreSurcharge1() private {
        _surcharge1 = _previousSurcharge1;
    }

         function restoreSurcharge2() private {
        _surcharge2 = _previousSurcharge2;
    }

         function restoreSurcharge3() private {
        _surcharge3 = _previousSurcharge3;
    }

    
    function isExcludedFromCommunityCharge(address account) public view returns(bool) {
        return _isExcludedFromCommunity_charge[account];
    }

     function isExcludedFromEcoSysFee(address account) public view returns(bool) {
        return _isExcludedFromEcoSysFee[account];
    }

     function isExcludedFromSurcharge1(address account) public view returns(bool) {
        return _isExcludedFromSurcharge1[account];
    }
    function isExcludedFromSurcharge2(address account) public view returns(bool) {
        return _isExcludedFromSurcharge2[account];
    }
    function isExcludedFromSurcharge3(address account) public view returns(bool) {
        return _isExcludedFromSurcharge3[account];
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

 

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if(from != owner() && to != owner())
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        
        //   if some token is locked, and  amount is greater than allowed withdrawable amount than checking that if loking period is finished,
        //  if locking period is finised than allow transfer and update locked token amount. if it is still in locking period error will be thrown.

        uint256 lockedToken = locks[from].lockedToken;
        if(lockedToken > 0){
            uint256 balance = balanceOf(from); 
            uint256 withdrawable = balance - lockedToken;
            uint256 millis_days = locks[from].timeInDays * 1 days;
            uint256 expiry = locks[from].startTime + millis_days; 
            
            if(amount > withdrawable){
                require(block.timestamp >= expiry, "Not Enough unlocked token available");
                uint256 required_from_locked_mode = amount - withdrawable;
                locks[from].lockedToken  = lockedToken - required_from_locked_mode;
            }
        }

        //indicates if fee should be deducted from transfer
        bool takeCommunityCharge = true;
        bool takeEcosysFee = true;
        bool takeSurcharge1 = true;
        bool takeSurcharge2 = true;
        bool takeSurcharge3 = true;
        
        //if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromCommunity_charge[from] || _isExcludedFromCommunity_charge[to]){
            takeCommunityCharge = false;
        }
         //if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromEcoSysFee[from] || _isExcludedFromEcoSysFee[to]){
            takeEcosysFee = false;
        }
         //if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromSurcharge1[from] || _isExcludedFromSurcharge1[to]){
            takeSurcharge1 = false;
        }
           //if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromSurcharge2[from] || _isExcludedFromSurcharge2[to]){
            takeSurcharge2 = false;
        }
           //if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromSurcharge3[from] || _isExcludedFromSurcharge3[to]){
            takeSurcharge3 = false;
        }

        _tokenTransfer(from,to,amount,takeCommunityCharge,takeEcosysFee,takeSurcharge1,takeSurcharge2,takeSurcharge3);

    }

     function _takeEcoSysCharge(uint256 tEcoSys) private {
        if (tEcoSys > 0) {
            uint256 currentRate = _getRate();
            uint256 rEcosys = tEcoSys.mul(currentRate);
            _rOwned[_ecoSysWallet] = _rOwned[_ecoSysWallet].add(rEcosys);
            if (_isExcludedFromEcoSysFee[_ecoSysWallet])
                _tOwned[_ecoSysWallet] = _tOwned[_ecoSysWallet].add(tEcoSys);
            emit Transfer(_msgSender(), _ecoSysWallet, tEcoSys);
        }
    }

     function _takeSurcharge1(uint256 tSurcharge1) private {
        if (tSurcharge1 > 0) {
            uint256 currentRate = _getRate();
            uint256 rSurcharge1 = tSurcharge1.mul(currentRate);
            _rOwned[_surcharge_1_Wallet] = _rOwned[_surcharge_1_Wallet].add(rSurcharge1);
            if (_isExcludedFromSurcharge1[_surcharge_1_Wallet])
                _tOwned[_surcharge_1_Wallet] = _tOwned[_surcharge_1_Wallet].add(tSurcharge1);
            emit Transfer(_msgSender(), _surcharge_1_Wallet, tSurcharge1);
        }
    }

    function _takeSurcharge2(uint256 tSurcharge2) private {
        if (tSurcharge2 > 0) {
            uint256 currentRate = _getRate();
            uint256 rSurcharge2 = tSurcharge2.mul(currentRate);
            _rOwned[_surcharge_2_Wallet] = _rOwned[_surcharge_2_Wallet].add(rSurcharge2);
            if (_isExcludedFromSurcharge1[_surcharge_2_Wallet])
                _tOwned[_surcharge_2_Wallet] = _tOwned[_surcharge_2_Wallet].add(tSurcharge2);
            emit Transfer(_msgSender(), _surcharge_2_Wallet, tSurcharge2);
        }
    }


        function _takeSurcharge3(uint256 tSurcharge3) private {
        if (tSurcharge3 > 0) {
            uint256 currentRate = _getRate();
            uint256 rSurcharge3 = tSurcharge3.mul(currentRate);
            _rOwned[_surcharge_3_Wallet] = _rOwned[_surcharge_3_Wallet].add(rSurcharge3);
            if (_isExcludedFromSurcharge3[_surcharge_3_Wallet])
                _tOwned[_surcharge_3_Wallet] = _tOwned[_surcharge_3_Wallet].add(tSurcharge3);
            emit Transfer(_msgSender(), _surcharge_3_Wallet, tSurcharge3);
        }
    }

    

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeCommunityCharge,bool takeEcosysFee,bool takeSurcharge1,bool takeSurcharge2,bool takeSurcharge3) private {
        if(!takeCommunityCharge)
            removeCommunityCharge();

        if(!takeEcosysFee)
            removeEcosysFee();

        if(!takeSurcharge1)
            removeSurcharge1();

        if(!takeSurcharge2)
            removeSurcharge2();

        if(!takeSurcharge3)
            removeSurcharge3();

         if (_isExcludedFromReward[sender] && !_isExcludedFromReward[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcludedFromReward[sender] && _isExcludedFromReward[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcludedFromReward[sender] && !_isExcludedFromReward[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcludedFromReward[sender] && _isExcludedFromReward[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
        
        if(!takeCommunityCharge)
            restoreCommunityCharge();
        if(!takeEcosysFee)
            restoreEcosysFee();
        if(!takeSurcharge1)
            restoreSurcharge1();
        if(!takeSurcharge2)
            restoreSurcharge2();
        if(!takeSurcharge3)
            restoreSurcharge3();
    }

  function transferWithLock(address recipient, uint256 tAmount, uint256 timeindays)  public onlyOwner {
        _transfer(_msgSender(),recipient,tAmount);
        lock(recipient, tAmount, timeindays);
    }

     function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (MValues memory mvalues) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(mvalues.rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(mvalues.rTransferAmount); 
        _takeEcoSysCharge(mvalues.tEcoSysFee);
        _takeSurcharge1(mvalues.tSurcharge1);
        _takeSurcharge2(mvalues.tSurcharge2);
        _takeSurcharge3(mvalues.tSurcharge3);
        _reflectFee(mvalues.rCommunityCharge, mvalues.tCommunityCharge);
        emit Transfer(sender, recipient, mvalues.tTransferAmount);
    }

      function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (MValues memory mvalues) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(mvalues.rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(mvalues.tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(mvalues.rTransferAmount); 
        _takeEcoSysCharge(mvalues.tEcoSysFee);
        _takeSurcharge1(mvalues.tSurcharge1);
        _takeSurcharge2(mvalues.tSurcharge2);
        _takeSurcharge3(mvalues.tSurcharge3);
        _reflectFee(mvalues.rCommunityCharge, mvalues.tCommunityCharge);
        emit Transfer(sender, recipient, mvalues.tTransferAmount);
    }

      function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (MValues memory mvalues) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(mvalues.rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(mvalues.rTransferAmount);
        _takeEcoSysCharge(mvalues.tEcoSysFee);
        _takeSurcharge1(mvalues.tSurcharge1);
        _takeSurcharge2(mvalues.tSurcharge2);
        _takeSurcharge3(mvalues.tSurcharge3);
        _reflectFee(mvalues.rCommunityCharge, mvalues.tCommunityCharge);
        emit Transfer(sender, recipient, mvalues.tTransferAmount);
    }  


    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
         (MValues memory mvalues) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(mvalues.rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(mvalues.tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(mvalues.rTransferAmount);
        _takeEcoSysCharge(mvalues.tEcoSysFee);
       _takeSurcharge1(mvalues.tSurcharge1);
        _takeSurcharge2(mvalues.tSurcharge2);
        _takeSurcharge3(mvalues.tSurcharge3);
        _reflectFee(mvalues.rCommunityCharge, mvalues.tCommunityCharge);
        emit Transfer(sender, recipient, mvalues.tTransferAmount);
    }

}