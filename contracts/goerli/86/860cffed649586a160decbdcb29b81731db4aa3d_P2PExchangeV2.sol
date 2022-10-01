/**
 *Submitted for verification at Etherscan.io on 2022-10-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}
abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


contract P2PExchangeV2 is ReentrancyGuard,Ownable {

    string public name = "PolkaBridge: P2P Exchange V2";
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct UserInfo {
        uint256 amount;
        uint256 latestDepositedTime;
         uint256 latestWithdrawTime;
        uint256 totalFee;

        // uint256[] inTime;
        // uint256[] inAmount;
        // uint256[] outTime;
        // uint256[] outAmount;
        
    }

    struct Fee{
        uint256 totalProfitFee;
        uint256 totalGasFee;
        uint256 latestProfitFee;//after withdraw
        uint256 latestGasFee;//after withdraw
        
        
    }

    mapping(address => mapping(address => UserInfo)) public users; // user address => token address => amount 
    mapping(address => Fee) public FeeList; //token - feeprofit

    address public WETH;
    address[] public tokenList;
    uint256 public fee;//x100
    
   

    event Deposit(
        address indexed _from,
        address indexed _token,
        uint256 _amount
    );
    
    event DepositETH(address indexed _from, uint256 _amount);

    event Withdraw(
 
        address indexed _token,
        address indexed _to,
        uint256 _amount
    );


    event WithdrawETH(
       address indexed _to,
        uint256 _amount
    );



    constructor(address _WETH, uint256 _fee) {
        WETH = _WETH; //native token for chain
        fee = _fee;//input x100 25
       
      
    }

    
    //returns owner of the contract
    function getTokenAddress(uint256 _index) public view returns (address[] memory) {
        address[] memory tokens = new address[](1);
        tokens[0]=address(tokenList[_index]);
        return tokens;
    }

    
    //returns balance of token inside the contract
    function getTokenBalance(address _token) public view returns (uint256) {
        return IERC20(_token).balanceOf(address(this));
    }

  
    function updateFee(address _token, uint256 _profitFee,uint256 _gasFee) private{
        FeeList[_token].totalProfitFee=FeeList[_token].totalProfitFee.add(_profitFee);
        FeeList[_token].totalGasFee=FeeList[_token].totalGasFee.add(_gasFee);

        FeeList[_token].latestProfitFee=FeeList[_token].latestProfitFee.add(_profitFee);
        FeeList[_token].latestGasFee=FeeList[_token].latestGasFee.add(_gasFee);
    }

    // transfer token into polkabridge vault
    function deposit(address _token, uint256 _amount) external {
        
        require(_token != address(0) && _amount > 0, "invalid token or amount");
         if (IERC20(_token).balanceOf(address(this))==0) tokenList.push(_token);
         
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);

        // UserInfo storage user = users[msg.sender][_token];
        users[msg.sender][_token].amount = users[msg.sender][_token].amount.add(_amount);
        users[msg.sender][_token].latestDepositedTime = block.timestamp;

        //users[msg.sender][_token].inTime.push(block.timestamp);
        //users[msg.sender][_token].inAmount.push(_amount);

       

        emit Deposit(msg.sender, _token, _amount);
    }

    // transfer coin into polkabridge vault
    function depositETH() external payable {
        users[msg.sender][WETH].amount =users[msg.sender][WETH].amount.add(msg.value);
        users[msg.sender][WETH].latestDepositedTime = block.timestamp;
        //users[msg.sender][WETH].inTime.push(block.timestamp);
       // users[msg.sender][WETH].inAmount.push(msg.value);

    
        emit DepositETH(msg.sender, msg.value);
    }


    // user can withdraw all his funds after deposit token
    function withdraw( 
        address _user,
        address _token,
        uint256 _amount,
        uint256 _amountTokenForGas//in backend cal
        )
        external onlyOwner
        nonReentrant
    {
        
        require(_token != address(0) && _user != address(0), "invalid address");
        require(
            users[_user][_token].amount >= _amount && _amount > 0,
            "Seller have insufficient funds in the pool."
        );
        uint256 tokenBalance = IERC20(_token).balanceOf(address(this));
        require(
            tokenBalance >= _amount && _amount > 0,
            "Insufficient funds in the pool."
        );


        uint256 feeAmount=_amount.mul(fee).div(10000);//fee

        uint256 sendAmount = _amount.sub(feeAmount); 
        IERC20(_token).safeTransfer(_user, sendAmount);
       
        users[_user][_token].amount=  users[_user][_token].amount.sub(_amount);
        users[_user][_token].latestWithdrawTime = block.timestamp;
        users[_user][_token].totalFee = users[_user][_token].totalFee.add(feeAmount);

        //users[_user][_token].outTime.push(block.timestamp);
        //users[_user][_token].outAmount.push(_amount);

        updateFee(_token,feeAmount,_amountTokenForGas);

        emit Withdraw(_token,_user, _amount);
    }

    // user cancel transaction after deposit coin
    function withdrawETH(address _user,uint256 _amount, uint256 _amountTokenForGas)//in backend cal
     external 
      onlyOwner 
      nonReentrant {
        
        require( _user != address(0), "invalid address");
        require(
            users[_user][WETH].amount >= _amount && _amount > 0,
            "Seller have insufficient ETH in the pool."
        );

        uint256 feeAmount=_amount.mul(fee).div(10000); //fee

        uint256 sendAmount = _amount.sub(feeAmount);

        payable(_user).transfer(sendAmount);
        users[_user][WETH].amount =users[_user][WETH].amount.sub(_amount);
        users[_user][WETH].latestWithdrawTime = block.timestamp;
         users[_user][WETH].totalFee =   users[_user][WETH].totalFee.add(feeAmount);

       // users[_user][WETH].outTime.push(block.timestamp);
       // users[_user][WETH].outAmount.push(_amount);

        updateFee(WETH,feeAmount,_amountTokenForGas);


        emit WithdrawETH(_user,_amount);
    }

    // given user address and token, return deposit time and deposited amount
    function getUserInfo(address _user, address _token)
        public
        view
        returns (uint256 , uint256,uint256 )
    {
       return( users[_user][_token].latestDepositedTime,users[_user][_token].latestWithdrawTime,users[_user][_token].amount);
    }

    function getUserEthInfo(address _user)
        public
        view
          returns (uint256 , uint256,uint256 )
    {
      return( users[_user][WETH].latestDepositedTime,users[_user][WETH].latestWithdrawTime,users[_user][WETH].amount);
    }

    // function getUserInData(address _user,address _token) public view returns(uint256[] memory,uint256[] memory ){ 
  
    //     uint256[] memory inTimes = new uint256[](users[_user][_token].inTime.length);
    //     uint256[] memory inAmounts = new uint256[](users[_user][_token].inAmount.length);
        
    //     uint256 j=0;
    //     for (uint i = 0; i < users[_user][_token].inTime.length; i++) {
            
    //             inTimes[j] = uint256(users[_user][_token].inTime[i]);
    //             j++;
            
    //     }
    //     j=0;
    //     for (uint i = 0; i < users[_user][_token].inAmount.length; i++) {
            
    //             inAmounts[j] = uint256(users[_user][_token].inAmount[i]);
    //             j++;
            
    //     }

    //     return (inTimes,inAmounts);
    // }

    // function getUserOutData(address _user,address _token) public view returns(uint256[] memory,uint256[] memory ){ 
  
    //     uint256[] memory outTimes = new uint256[](users[_user][_token].outTime.length);
    //     uint256[] memory outAmounts = new uint256[](users[_user][_token].outAmount.length);
        
    //     uint256 j=0;
    //     for (uint i = 0; i < users[_user][_token].outTime.length; i++) {
            
    //             outTimes[j] = uint256(users[_user][_token].outTime[i]);
    //             j++;
            
    //     }
    //     j=0;
    //     for (uint i = 0; i < users[_user][_token].outAmount.length; i++) {
            
    //             outAmounts[j] = uint256(users[_user][_token].outAmount[i]);
    //             j++;
            
    //     }

    //     return (outTimes,outAmounts);
    // }

    // return eth balance in reserve
    function getEthInReserve() public view returns (uint256 _amount) {
        return address(this).balance;
    }

    // withdraw token
    function superWithdrawToken(address _token) external onlyOwner nonReentrant {
        uint256 balance = IERC20(_token).balanceOf(address(this));
        require(balance > 0, "not enough amount");
        IERC20(_token).safeTransfer(msg.sender, balance);
    }

     // withdraw token
    function superWithdrawTokenWithAmount(address _token,uint256 _amount) external onlyOwner nonReentrant {
        
        IERC20(_token).safeTransfer(msg.sender, _amount);
    }

    // withdraw ETH
    function superWithdrawETH() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "not enough amount");
        payable(msg.sender).transfer(balance);
    }

      function superWithdrawETHWithAmount(uint256 _amount) external onlyOwner nonReentrant {
      
        payable(msg.sender).transfer(_amount);
    }

    // withdraw all
    function superWithdrawAll() external onlyOwner nonReentrant{
        //withdraw all tokens
        for (uint256 i = 0; i < tokenList.length; i++) {
            uint256 balance = IERC20(tokenList[i]).balanceOf(address(this));
            if(balance>0){
                IERC20(tokenList[i]).safeTransfer(msg.sender, balance);
            }
        }
        //withdraw ETH
        if(address(this).balance>0){
          payable(msg.sender).transfer(address(this).balance);
        }
    }

     // withdraw all fee
    function superWithdrawAllFee() external onlyOwner nonReentrant{
        //withdraw all tokens
        for (uint256 i = 0; i < tokenList.length; i++) {
            
            uint256 amount = FeeList[tokenList[i]].latestProfitFee.add(FeeList[tokenList[i]].latestGasFee);

            if(amount>0){
                IERC20(tokenList[i]).safeTransfer(msg.sender, amount);
                FeeList[tokenList[i]].latestProfitFee=0;
                FeeList[tokenList[i]].latestGasFee=0;
            }
            
        }
        //withdraw ETH
        uint256 ethAmount=FeeList[WETH].latestProfitFee.add(FeeList[WETH].latestGasFee);
        if(ethAmount>0){

            payable(msg.sender).transfer(ethAmount);
            FeeList[WETH].latestProfitFee=0;
            FeeList[WETH].latestGasFee=0;

        }

    }

       // withdraw token
    function superWithdrawTokenFee(address _token) external onlyOwner nonReentrant {
        
         uint256 amount = FeeList[_token].latestProfitFee.add(FeeList[_token].latestGasFee);
        if(amount>0){
         IERC20(_token).safeTransfer(msg.sender, amount);

         FeeList[_token].latestProfitFee=0;
         FeeList[_token].latestGasFee=0;
        }
    }

       // withdraw token
    function superWithdrawETHFee() external onlyOwner nonReentrant {
        
        uint256 amount = FeeList[WETH].latestProfitFee.add(FeeList[WETH].latestGasFee);
        if(amount>0){
          payable(msg.sender).transfer(amount);

         FeeList[WETH].latestProfitFee=0;
         FeeList[WETH].latestGasFee=0;
        }
    }

}