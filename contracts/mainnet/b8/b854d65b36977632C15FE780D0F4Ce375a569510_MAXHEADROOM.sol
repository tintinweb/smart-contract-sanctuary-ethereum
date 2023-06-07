/**
 *Submitted for verification at Etherscan.io on 2023-06-07
*/

/**

MAXHEADROOM
This is a Test Contract - DO NOT PURCHASE 

*/

pragma solidity ^0.8.19;

// SPDX-License-Identifier: Unlicensed

interface IERC20 {

    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`
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
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract, setting the deployer as the initial owner.
     */
    constructor () {
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
}


//    MAXHEADROOM

contract MAXHEADROOM is Context, IERC20, Ownable {

	modifier contractAdmin() {
        require(isContractAdmin(_msgSender())  || isOwner(), "Admin: caller is not a contract Administrator");
        _;
    }

    modifier contractManager() {
        require(isContractManager(_msgSender())  || isOwner(), "Manager: caller is not a contract Manager");
        _;
    }

    using SafeMath for uint256;
    using Address for address;


    struct RValuesStruct {
        uint256 rAmount;
        uint256 rTransferAmount;
        uint256 rReflectionFee;
        uint256 rmarketingFee;
    }

    struct TValuesStruct {
        uint256 tTransferAmount;
        uint256 tReflectionFee;
        uint256 tmarketingFee;
    }

    struct ValuesStruct {
        uint256 rAmount;
        uint256 rTransferAmount;
        uint256 rReflectionFee;
        uint256 rmarketingFee;
        uint256 tTransferAmount;
        uint256 tReflectionFee;
        uint256 tmarketingFee;
    }

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) public automatedMarketMakerPairs;

    mapping (address => bool) private _isContractAdmin;
	mapping (address => bool) private _isContractManager;
			 



    mapping (address => bool) private _isExcluded;
    address[] private _excluded;

    uint256 private constant MAX = ~uint256(0);
    // 10 Billion Tokens 
    uint256 private _tTotal = 10 * 10**9 * 10**18 ;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tReflectionFeeTotal;
    
    string private _name = "MAXHEADROOM";
    string private _symbol = "MAXHEADROOM";
    uint8 private _decimals = 18;

    uint8 public _reflectionFee = 1;

    uint8 public _marketingFee = 1;
    /* Fee Ratio Reducer uses the Fee Base Rate and then only takes the Ratio Reducer percentage of the Base Fee. 
    eg. If the base fee is 1 and the feeRatioReducer is 30 then it will be 1 * 30 / 100 - producing a Actual Tax of 0.3 % 
    */
    uint8 public feeRatioReducer = 30; 

    address public marketingFeeWallet = 0x5ae4C9540A2eb9Ba42031eE4873cB449c9097dBa;


   
    bool public fairLaunchStarted = false;
    bool public fairLaunchCompleted = false;

	event ExcludeFromReward(address account);
    event ContractManagerChange(address account, bool status);
    event ContractAdminChange(address account, bool status);
    event FeesUpdated(uint8 reflectionFee, uint8 marketingFee);
    event ChangeMarketingWallet(address newAddress);
    event FairlaunchStarted(bool);
    event FairlaunchCompleted(bool);
    event ChangefeeRatioReducer(uint8 amount);
    event SetAMM(address pair, bool status);
    event ETHRecovered(uint256 amount);
    event ERC20Rescued(address tokenAddress, uint256 amount);

    constructor () {
        _rOwned[_msgSender()] = _rTotal;
 

        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isContractAdmin[owner()] = true;
		_isContractManager[owner()] = true;								   
        _isExcludedFromFee[address(this)] = true;
        
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
        if (_isExcluded[account]) return _tOwned[account];
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
        return _isExcluded[account];
    }

    function totalReflectionFees() public view returns (uint256) {
        return _tReflectionFeeTotal;
    }


    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            uint256 rAmount = _getValues(tAmount).rAmount;
            return rAmount;
        } else {
            uint256 rTransferAmount = _getValues(tAmount).rTransferAmount;
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

	
	function excludeFromReward(address account) external contractManager() {
        require(!_isExcluded[account], "Account already excluded");
        require(_excluded.length < 100, "Excluded list is too long");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);

        emit ExcludeFromReward(account);
    }

    //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    function _distributeFee(uint256 rReflectionFee, uint256 tReflectionFee) private {
        _rTotal = _rTotal.sub(rReflectionFee);
        _tReflectionFeeTotal = _tReflectionFeeTotal.add(tReflectionFee);
       
        
    }

    function _getValues(uint256 tAmount) private view returns (ValuesStruct memory) {
        TValuesStruct memory tvs = _getTValues(tAmount);
        RValuesStruct memory rvs = _getRValues(tAmount, tvs.tReflectionFee, tvs.tmarketingFee, _getRate()) ;

        return ValuesStruct(
            rvs.rAmount,
            rvs.rTransferAmount,
            rvs.rReflectionFee,
            rvs.rmarketingFee,
            tvs.tTransferAmount,
            tvs.tReflectionFee,
            tvs.tmarketingFee
        );
    }

    function _getTValues(uint256 tAmount) private view returns (TValuesStruct memory) {
        uint256 tReflectionFee = calculateReflectionFee(tAmount);
        uint256 tmarketingFee = calculatemarketingFee(tAmount);
        

        uint256 tTransferAmount = tAmount.sub(tReflectionFee).sub(tmarketingFee);
        return TValuesStruct(tTransferAmount, tReflectionFee, tmarketingFee);
    }

    function _getRValues(uint256 tAmount, uint256 tReflectionFee, uint256 tmarketingFee, uint256 currentRate) private pure returns (RValuesStruct memory) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rReflectionFee = tReflectionFee.mul(currentRate);
        uint256 rmarketingFee = tmarketingFee.mul(currentRate);
       
        uint256 rTransferAmount = rAmount.sub(rReflectionFee).sub(rmarketingFee);
        return RValuesStruct(rAmount, rTransferAmount, rReflectionFee, rmarketingFee);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _takeMarketingFee(uint256 rMarketingFee, uint256 tMarketingFee) private {
        
            _rOwned[marketingFeeWallet] = _rOwned[marketingFeeWallet].add(rMarketingFee);
            if(_isExcluded[marketingFeeWallet])
            _tOwned[marketingFeeWallet] = _tOwned[marketingFeeWallet].add(tMarketingFee);
    }

    function calculateReflectionFee(uint256 _amount) private view returns (uint256) {
        uint256 refFee = 0;       
        if(_reflectionFee > 0)
        {
            refFee = _calculateFeeAmount(_amount, _reflectionFee);
            if(feeRatioReducer < 100 && fairLaunchCompleted)
            {
                refFee = _calculateFeeAmount(refFee, feeRatioReducer);
            }
            return refFee;
        }
        else 
        {
            return 0;
        }
        
    }

    function calculatemarketingFee(uint256 _amount) private view returns (uint256) {
        uint256 mFee  = 0;       
        if(_marketingFee > 0)
        {
            mFee = _calculateFeeAmount(_amount, _marketingFee);
            if(feeRatioReducer < 100 && fairLaunchCompleted)
            {
                mFee = _calculateFeeAmount(mFee, feeRatioReducer);
            }
            return mFee;
        }
        else 
        {
            return 0;
        }
    }

    function _calculateFeeAmount(uint256 amount, uint256 fee) private pure returns (uint256) {
        return amount * fee / 100;
    }

    function removeAllFee() private {
        _reflectionFee = 0;
        _marketingFee = 0;
    }

    function restoreAllFee() private {
        _reflectionFee = 1;
        _marketingFee = 1;
	}

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }



    function isContractAdmin(address account) public view returns(bool) {
        return _isContractAdmin[account];
    }

	function isContractManager(address account) public view returns(bool) {
        return _isContractManager[account];
    }																	   


    function isOwner() public view returns(bool) {
        if(owner() == msg.sender)
        {
            return true;
        }
        return false;
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
        
        // block trading until owner has added liquidity and enabled trading
        if(!fairLaunchStarted && from != owner() ) {
            if(!_isExcludedFromFee[from])
            {
                revert("Trading not yet enabled!");
            }
        }

        //transfer amount, it will take reflections and Marketing Fee if set.
        _tokenTransfer(from,to,amount);

    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount) private {
        // Check if Transaction is a Uniswap Sale - True if Recipient is LP Contract Address
        if(automatedMarketMakerPairs[recipient])
        {
           _marketingFee = 0;
		   _reflectionFee = 0;
            
        }
        else if(automatedMarketMakerPairs[sender])
        {
            _marketingFee = 0;
			_reflectionFee = 1;
        }
        else 
        {
            _marketingFee = 1;
            _reflectionFee = 0;
        }

        //Only During Fair Launch there is a 99% Refection Fee Applied to transactions from non Fair Launch Approved Wallets
        if(fairLaunchStarted && !fairLaunchCompleted)
        {
            _reflectionFee = 99;
        }

        if(_isExcludedFromFee[sender] || _isExcludedFromFee[recipient])  {
            removeAllFee();
        }
                     
        ValuesStruct memory vs = _getValues(amount);
        _takeMarketingFee(vs.rmarketingFee, vs.tmarketingFee);
        _distributeFee(vs.rReflectionFee, vs.tReflectionFee);
       
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount, vs);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, vs);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, vs);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount, vs);
        }
       
            restoreAllFee();

    }

    function _transferStandard(address sender, address recipient, ValuesStruct memory vs) private {
        _rOwned[sender] = _rOwned[sender].sub(vs.rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(vs.rTransferAmount);
        emit Transfer(sender, recipient, vs.tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, ValuesStruct memory vs) private {
        _rOwned[sender] = _rOwned[sender].sub(vs.rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(vs.tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(vs.rTransferAmount);
        emit Transfer(sender, recipient, vs.tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount, ValuesStruct memory vs) private {
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(vs.rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(vs.rTransferAmount);
        emit Transfer(sender, recipient, vs.tTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount, ValuesStruct memory vs) private {
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(vs.rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(vs.tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(vs.rTransferAmount);
        emit Transfer(sender, recipient, vs.tTransferAmount);
    }

    function excludeFromFee(address[] calldata accounts) public contractAdmin {
        for (uint32 i = 0; i < accounts.length; i++)
          _isExcludedFromFee[accounts[i]] = true;
    }
   
    function setContractManager(address account, bool status) public contractManager {
		require(account != address(0), "Contract Manager Can't be the zero address");
        require(_isContractManager[account] != status, "Contract Manager Already Set");
		_isContractManager[account] = status;
		emit ContractManagerChange(account, status);
    }

    function setContractAdmin(address account, bool status) public contractManager {
        require(account != address(0), "Contract Admin Can't be the zero address");
        require(_isContractAdmin[account] != status, "Contract Admin Already Set");
		_isContractAdmin[account] = status;
        emit ContractAdminChange(account, status);
    }
  
    function includeInFee(address[] calldata accounts) public contractAdmin {
        for (uint32 i = 0; i < accounts.length; i++)
            _isExcludedFromFee[accounts[i]] = false;
    }

    function setmarketingWallet(address newWallet) external contractAdmin {
        require(newWallet != address(0), "Marketing Wallet Can't be the zero address");
        marketingFeeWallet = newWallet;

        emit ChangeMarketingWallet(newWallet);
    }
	
	function startFairlaunch() external onlyOwner {
        require(!fairLaunchStarted, "Fairlaunch Already enabled!");
        fairLaunchStarted = true;
        _reflectionFee = 99; // Only high Until Fair Launch Completed and can't be changed again. 
        emit FairlaunchStarted(true);
    }

    function completeFairlaunch() external onlyOwner {
        require(!fairLaunchCompleted, "Fairlaunch Already Completed!");
        if (!fairLaunchStarted) {
            fairLaunchStarted = true;
            emit FairlaunchStarted(true);
        }
		fairLaunchCompleted = true;
		restoreAllFee();
        emit FairlaunchCompleted(true);
    }


    function setAutomatedMarketMakerPair(address pair, bool status) public onlyOwner {
		require(automatedMarketMakerPairs[pair] != status, "AMM Pair Status already set. Nothing to change");
        automatedMarketMakerPairs[pair] = status;

        emit SetAMM(pair, status);
    }

    /**
     * @dev Function to recover any ETH sent to Contract by Mistake.
    */	
    function recoverETHFromContract(uint256 weiAmount) external contractAdmin{
        require(address(this).balance >= weiAmount, "insufficient ETH balance");
        payable(owner()).transfer(weiAmount);
		emit ETHRecovered(weiAmount);
    }
       
    /**
     * @dev Function to recover any ERC20 Tokens sent to Contract by Mistake.
    */
    function recoverAnyERC20TokensFromContract(address tokenAddr, address to) public contractAdmin {
		uint256 amount = IERC20(tokenAddr).balanceOf(address(this));
        bool success = IERC20(tokenAddr).transfer(to, amount);
        require(success, "ERC20 transfer failed!");

        emit ERC20Rescued(tokenAddr, amount);
    }

}