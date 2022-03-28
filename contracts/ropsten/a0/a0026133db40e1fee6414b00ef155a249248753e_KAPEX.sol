/**
 *Submitted for verification at Etherscan.io on 2022-03-28
*/

/**
 *Submitted for verification at BscScan.com on 2021-10-06
*/

pragma solidity 0.8.13;
// SPDX-License-Identifier: MIT
// Developed by: jawadklair

interface IBEP20 {

    /**  
     * @dev Returns the total tokens supply  
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
 
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data; // msg.data is used to handle array, bytes, string 
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
     * increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Kapex Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Kapex Address: unable to send value, recipient may have reverted");
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
      return functionCall(target, data, "Kapex Address: low-level call failed");
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
     * - the calling contract must have an BNB balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Kapex Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Kapex Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Kapex Address: call to non-contract");

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
abstract contract Ownable is Context {
    address internal _owner;

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
contract LockOwnable is Ownable {
    address private _previousOwner;
    uint256 private _lockTime;

    function getUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }
    
    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "KAPEX: You don't have permission to unlock");
        require(block.timestamp > _lockTime , "KAPEX: Contract is still locked");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
        _previousOwner = address(0);
    }
}

interface ISummitSwapFactory {

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface ISummitSwapRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}


contract KAPEX is Context, IBEP20, LockOwnable { // change contract name
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances; // total Owned tokens
    mapping (address => mapping (address => uint256)) private _allowances; // allowed allowance for spender

    mapping (address => bool) public _isPair;
    mapping (address => bool) public _isExcludedFromFee; // excluded address from all fee
    
    address payable public _kapexFeeManagerAddress = payable(0x0000000000000000000000000000000000000000); // kapex liquidity address
    address payable public _kapexLiquidityAddress = payable(0x0000000000000000000000000000000000000000); // kapex liquidity address

    string private _name = "Kapex Cryptocurrency"; // token name
    string private _symbol = "KAPEX"; // token symbol
    uint8 private constant _decimals = 9; // token decimals(1 token can be divided into 1e_decimals parts)

    uint256 private _totalSupply = 10**(10 + _decimals);

    uint256 public buyFee = 0;
    uint256 public buyFeeReducedEndTime = 0 minutes;

    uint256 public sellFee = 2500;
    uint256 public sellFeeIncreaseEndTime = 0 minutes;

    uint256 public _kapexTransactionFee = 1250; // 12.5%

    uint256 public _mintFee = 0;
    uint256 public _burnFee = 0;

    constructor () {
        _balances[_msgSender()] = _totalSupply;

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_kapexFeeManagerAddress] = true;
        _isExcludedFromFee[_kapexLiquidityAddress] = true;

        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    /**
     * @dev Creates `amount` tokens and assigns them to `account`, increasing  the total supply.
     */
    function mint(address account, uint256 amount) external {
        require(msg.sender == _kapexFeeManagerAddress, "KAPEX: can't mint");
        require(account != address(0), "KAPEX: mint to the zero address");

        uint256 deductedMintFee = amount.mul(_mintFee).div(10000);
        uint256 receivedAmount = amount.sub(deductedMintFee);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(receivedAmount);
        emit Transfer(address(0), account, receivedAmount);

        if(deductedMintFee > 0) {
            _balances[_kapexLiquidityAddress] = _balances[_kapexLiquidityAddress].add(deductedMintFee);
            emit Transfer(address(0), _kapexLiquidityAddress, deductedMintFee);
        }
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the total supply.
     */
    function _burn(address account, uint256 amount) internal virtual {
        uint256 accountBalance = _balances[account];

        require(accountBalance >= amount, "KAPEX: burn amount exceeds balance");

        uint256 deductedBurnFee = amount.mul(_burnFee).div(10000);
        uint256 burnedAmount = amount.sub(deductedBurnFee);

        _balances[account] = accountBalance.sub(amount);
        _totalSupply = _totalSupply.sub(burnedAmount);
        emit Transfer(account, address(0), burnedAmount);

        if(deductedBurnFee > 0) {
            _balances[_kapexLiquidityAddress] = _balances[_kapexLiquidityAddress].add(deductedBurnFee);
            emit Transfer(account, _kapexLiquidityAddress, deductedBurnFee);
        }
    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "KAPEX: transfer amount exceeds allowance"));
    }

    function setMintFee(uint256 mintFee) external onlyOwner {
        require(mintFee <= 2500, "KAPEX: mint fee should be be between 0% - 25% (0 - 2500)");
        _mintFee = mintFee;
    }

    function setBurnFee(uint256 burnFee) external onlyOwner {
        require(burnFee <= 2500, "KAPEX: burn fee should be between 0% - 25% (0 - 2500)");
        _burnFee = burnFee;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**  
     * @dev approves allowance of a spender
     */
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
    /**  
     * @dev transfers from a sender to recipient with subtracting spenders allowance with each successful transfer
     */
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "KAPEX: transfer amount exceeds allowance"));
         return true;
    }

    /**  
     * @dev approves allowance of a spender should set it to zero first than increase
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**  
     * @dev decrease allowance of spender that it can spend on behalf of owner
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "KAPEX: decreased allowance below zero"));
        return true;
    }

    /**  
     * @dev exclude an address from fee
     */
    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    
    /**  
     * @dev include an address for fee
     */
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    /**  
     * @dev set's kapex transaction fee
     */
    function setKapexTransactionFee(uint256 fee) external onlyOwner {
        require(fee <= 1250, "KAPEX: Transaction fee should be between 0% - 12.5% (0 - 1250)");
        require(block.timestamp > buyFeeReducedEndTime || fee >= buyFee, "KAPEX: Transaction fee should be between (buyFee)% - 12.5% (buyFee - 1250)");
        require(block.timestamp > sellFeeIncreaseEndTime || fee <= sellFee, "KAPEX: Transaction fee should be between 0% - (sellFee)% (0 - sellFee)");
        _kapexTransactionFee = fee;
    }

    /**  
     * @dev set's kapex liquidity provider address
     */
    function setKapexFeeManagerAddress(address payable kapexFeeManagerAddress) external onlyOwner {
        _isExcludedFromFee[_kapexFeeManagerAddress] = false;
        _kapexFeeManagerAddress = kapexFeeManagerAddress;
        _isExcludedFromFee[_kapexFeeManagerAddress] = true;
    }

    /**  
     * @dev set's kapex liquidity provider address
     */
    function setKapexLiquidityAddress(address payable kapexLiquidityAddress) external onlyOwner {
        _isExcludedFromFee[_kapexLiquidityAddress] = false;
        _kapexLiquidityAddress = kapexLiquidityAddress;
        _isExcludedFromFee[_kapexLiquidityAddress] = true;
    }

    /**  
     * @dev reduce buy fee for a certain amount of time
     */
    function setBuyFee(uint256 duration, uint256 newBuyFee) external onlyOwner {
        require(newBuyFee < _kapexTransactionFee, "KAPEX: Decreased buy fee should be less than (transfer fee)%");
        buyFee = newBuyFee;
        buyFeeReducedEndTime = block.timestamp.add(duration * 1 minutes);
    }

    /**  
     * @dev increase sell fee for a certain amount of time
     */
    function setSellFee(uint256 duration, uint256 newSellFee) external onlyOwner {
        require(newSellFee > _kapexTransactionFee && newSellFee <= 2500, "KAPEX: Increased sell fee should be between (transfer fee)% - 25%");
        sellFee = newSellFee;
        sellFeeIncreaseEndTime = block.timestamp.add(duration * 1 minutes);
    }
    
    /**  
     * @dev approves amount of token spender can spend on behalf of an owner
     */
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "KAPEX: approve from the zero address");
        require(spender != address(0), "KAPEX: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**  
     * @dev transfers token from sender to recipient also auto 
     * send collected fee to kapexLiquidityProvider address(contract).
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0) && to != address(0), "KAPEX: transfer from/to the Zero address");
        
        uint256 fee = _kapexTransactionFee;
        
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            fee = 0;
        }
        else if(_isPair[from] && block.timestamp <= buyFeeReducedEndTime) {
            fee = buyFee;
        }
        else if(_isPair[to] && block.timestamp <= sellFeeIncreaseEndTime) {
            fee = sellFee;
        }

        uint256 deducted = amount.mul(fee).div(10000);
        uint256 transferAmount = amount.sub(deducted);

        require(amount <=_balances[from],"KAPEX: transfer amount exceeds Balance");

        _balances[from] = _balances[from].sub(amount);
        _balances[to] = _balances[to].add(transferAmount);
        emit Transfer(from, to, transferAmount);

        if(deducted > 0) {
            _balances[_kapexFeeManagerAddress] = _balances[_kapexFeeManagerAddress].add(deducted);
            emit Transfer(from, _kapexFeeManagerAddress, deducted);
        }
    }

    /**  
     * @dev recovers any tokens stuck in Contract's balance
     * NOTE! if ownership is renounced then it will not work
     */
    function recoverTokens(address tokenAddress, address recipient, uint256 amountToRecover, uint256 recoverFeePercentage) public onlyOwner
    {
        IBEP20 token = IBEP20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));

        require(balance >= amountToRecover, "KAPEX: Not Enough Tokens in contract to recover");

        address feeRecipient = _msgSender();
        uint256 feeAmount = amountToRecover.mul(recoverFeePercentage).div(10000);
        amountToRecover = amountToRecover.sub(feeAmount);

        if(feeAmount > 0)
            token.transfer(feeRecipient, feeAmount);
        if(amountToRecover > 0)
            token.transfer(recipient, amountToRecover);
    }
    
    function togglePair(address pairAddress) public onlyOwner {
        _isPair[pairAddress] = !_isPair[pairAddress];
    }
}