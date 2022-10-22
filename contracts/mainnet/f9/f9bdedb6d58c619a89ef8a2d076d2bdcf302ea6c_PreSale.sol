/**
 *Submitted for verification at Etherscan.io on 2022-10-22
*/

/**
 *  SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.7;


/*
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


// CAUTION
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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) internal {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);
   
    function approve(address spender, uint256 amount) external returns (bool);

    function decimals() external returns (uint8);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);    
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
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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


library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface AggregatorInterface {
    function latestAnswer() external view returns (int256);
}

contract PreSale is Ownable{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
     
     mapping(uint256 => uint256)  public preUsd;
     uint256 public minBuyUsd;
     
     uint256 public tokenDecimals;
     address public tokenAddress;

     address public usdAddress;
     //https://data.chain.link/ethereum/mainnet/stablecoins/usdt-eth
     address public usdOrcaleAddress;

     uint256 public r1StartTime;
     uint256 public r2StartTime;
     uint256 public r3StartTime;
     uint256 public endTime;

     uint256 public totalToken;
     mapping(uint256=>uint256) public rTotalToken;
     uint256 public saleToken;
     mapping(uint256=>uint256) public rSaleToken;

     bool public paused;
     uint256 public releaseTime;

     struct UserContribute{
         uint256 ethAmount;
         uint256 usdAmount;
         uint256 tokenAmount;
         uint256 preRawToken;
         uint256 tegToken;
         uint256 claimTotal; 
         uint256 lastClaimTime; 
         bool hasClaim;
     }
     
    mapping(address=>UserContribute) public userContributeList;

    bool private locked;
    
    modifier noReentrancy() {
        require(!locked);
        locked = true;
        _;
        locked = false;
    }

    bool inited; 
    address public devAddress;
    function init(
       address _usdOrcaleAddress,
       address _usdAddress,
       address _tokenAddress
    ) public {
        require(!inited,"invalid init");
        _setOwner(_msgSender());
        usdOrcaleAddress = _usdOrcaleAddress;
        usdAddress = _usdAddress;
        tokenAddress = _tokenAddress;
        preUsd[1] = 20 * 10 ** 3; //0.02U
        preUsd[2] = 25 * 10 ** 3; //0.025U
        preUsd[3] = 32 * 10 ** 3; //0.032U
        minBuyUsd = 10 * 10**6;
        tokenDecimals = IERC20(_tokenAddress).decimals();

        rTotalToken[1] = 90000000 * 10 ** tokenDecimals;
        rTotalToken[2] = 90000000 * 10 ** tokenDecimals;
        rTotalToken[3] = 90000000 * 10 ** tokenDecimals;
		inited =true;
    }
    
    function buyWithETH(uint256 amount) public payable {
        checkResult(amount);

        uint256 payAmount =  msg.value;
        
        require(payAmount >= ethBuyHelper(amount),"pay eth not enough");
        uint256 needUsd = usdBuyHelper(amount);
        require(needUsd >= minBuyUsd,"pay ETH not enough");

        buyResult(amount,0,payAmount);
    }

    function buyWithUSDT(uint256 amount) public {
        checkResult(amount);

        uint256 payAmount = usdBuyHelper(amount);
        require(payAmount >= minBuyUsd,"pay USD not enough");
        IERC20(usdAddress).safeTransferFrom(msg.sender,address(this),payAmount);

        buyResult(amount,1,payAmount);
    }

    function buyResult(uint256 amount,uint _type,uint256 payAmount) private {
       saleToken = saleToken.add(amount.mul(10 ** tokenDecimals));
       setRoundSaleToken(amount);

       UserContribute memory _userContribute = userContributeList[msg.sender];

       if(_type == 0)
        _userContribute.ethAmount = _userContribute.ethAmount.add(payAmount);
       else
        _userContribute.usdAmount = _userContribute.usdAmount.add(payAmount);

       _userContribute.tokenAmount = _userContribute.tokenAmount.add(amount.mul(10 ** tokenDecimals)) ;
       _userContribute.tegToken = _userContribute.tokenAmount.mul(10).div(100);//10%
       _userContribute.preRawToken = _userContribute.tokenAmount.sub(_userContribute.tegToken).div(86400).div(270);//90% will be released in 9 months

       userContributeList[msg.sender] = _userContribute;

       if(devAddress!=address(0)){
           if(_type == 0){
               //payable(devAddress).transfer(address(this).balance);
               payable(devAddress).call{
                    value: address(this).balance
                }("");
           }
            else{
                uint256 u = IERC20(usdAddress).balanceOf(address(this));
                if(u > 0){
                    IERC20(usdAddress).safeTransfer(devAddress,u);
                }
            }
       }

    }

    function checkResult(uint256 amount) internal view returns (bool) {
        require(!paused,"has paused");
        uint256 round = getRound();
        require(round > 0,"not start");
        require(round < 4,"has end");
		require(rTotalToken[round] >= rSaleToken[round].add(amount.mul(10 ** tokenDecimals)),"token not enough ");
        return true;
    }

    function getRound() public view returns(uint256){
        if(r1StartTime ==0 || r1StartTime > block.timestamp){
            return 0;
        }
        else if(r1StartTime  < block.timestamp &&  r2StartTime > block.timestamp){
            return 1;
        }
        else if( r2StartTime  < block.timestamp &&  r3StartTime > block.timestamp){
             return 2;
        }
        else if( r3StartTime  < block.timestamp &&  endTime > block.timestamp){
             return 3;
        }
        return 4;
    }

    function getRoundTime() public view returns(uint256,uint256){
       uint256 round = getRound();
       if(round <= 1){
           return (r1StartTime,r2StartTime);
       }
       else if(round == 2){
           return (r2StartTime,r3StartTime);
       }
       else{
           return (r3StartTime,endTime);
       }
      
    }

    function getRoundTokenTotal() public view returns(uint256){
       uint256 round = getRound();
       if(round <= 1){
           return rTotalToken[1];
       }
       else if(round == 2){
          return rTotalToken[2];
       }
       else{
          return rTotalToken[3];
       }
    }

    function getRoundSaleTotal() public view returns(uint256){
       uint256 round = getRound();
       if(round <= 1){
          return rSaleToken[1];
       }
       else if(round == 2){
          return rSaleToken[2];
       }
       else{
          return rSaleToken[3];
       }
    }

    function setRoundSaleToken(uint256 _amount) private {
       uint256 round = getRound();
       if(round <= 1){
          rSaleToken[1] = rSaleToken[1].add(_amount.mul(10 ** tokenDecimals));
       }
       else if(round == 2){
          rSaleToken[2] = rSaleToken[2].add(_amount.mul(10 ** tokenDecimals));
       }
       else{
          rSaleToken[3] = rSaleToken[3].add(_amount.mul(10 ** tokenDecimals));
       }
    }

    //1 usd = ? eth
    function getLastPrice() public view returns(uint256){
        return uint256(AggregatorInterface(usdOrcaleAddress).latestAnswer());
    }

     //? token = ? eth
    function ethBuyHelper(uint256 _amount) public view returns(uint256){
        uint256 lastETH =  getLastPrice();

        uint256 needUsd = usdBuyHelper(_amount);

        return needUsd.mul(lastETH).div(10**6);
        
    }

    //? token = ? usd
    function usdBuyHelper(uint256 _amount) public view returns(uint256){
        uint256 round = getRound();
        if(round <= 1){
            return _amount.mul(preUsd[1]);
        }
        else if(round >=3){
            return _amount.mul(preUsd[3]);
        }
        else{
            return _amount.mul(preUsd[2]);
        }
       
    }
    
   
   function claim() public noReentrancy{
        require(tx.origin==msg.sender,"must be human");
        require(releaseTime > 0 && releaseTime < block.timestamp,"not yet claim");
        
        uint256 claimTotal = 0;
        uint256 nowTime =  block.timestamp;
       
        UserContribute storage _userContribute = userContributeList[msg.sender];
        
        if(_userContribute.tokenAmount > 0 &&  _userContribute.hasClaim == false){
            
            if(nowTime > releaseTime){
                claimTotal =  nowTime - (_userContribute.lastClaimTime > 0 ? _userContribute.lastClaimTime : releaseTime);
                claimTotal = claimTotal.mul(_userContribute.preRawToken);
            }

            if(_userContribute.lastClaimTime == 0){
                claimTotal = claimTotal.add(_userContribute.tegToken);
            }

            if(_userContribute.claimTotal.add(claimTotal) > _userContribute.tokenAmount){
                claimTotal = _userContribute.tokenAmount.sub(_userContribute.claimTotal);
                _userContribute.claimTotal = _userContribute.tokenAmount;
                _userContribute.hasClaim = true;
            }
            else
                _userContribute.claimTotal = _userContribute.claimTotal.add(claimTotal);

            _userContribute.lastClaimTime = nowTime;

        }
       

         if(claimTotal > 0)
            IERC20(tokenAddress).safeTransfer(msg.sender,claimTotal);
        
    }

    //Read the available quantity
    function pending(address _address) public view returns(uint256){
          uint256 claimTotal = 0;
          uint256 nowTime =  block.timestamp;
          
          if(nowTime < releaseTime){
              return  0;
          }

          UserContribute memory _userContribute = userContributeList[_address];
          if(_userContribute.tokenAmount > 0 &&  _userContribute.hasClaim == false){
                
                claimTotal =  nowTime - (_userContribute.lastClaimTime > 0 ? _userContribute.lastClaimTime : releaseTime);
                claimTotal = claimTotal.mul(_userContribute.preRawToken);

                if(_userContribute.lastClaimTime == 0){
                    claimTotal = claimTotal.add(_userContribute.tegToken);
                }

                if(_userContribute.claimTotal.add(claimTotal) >= _userContribute.tokenAmount){
                    claimTotal = _userContribute.tokenAmount.sub(_userContribute.claimTotal);
                }
          }


          return claimTotal;
    }
    
    //Set a claim time
    function startClaim(uint256 _releaseTime) public onlyOwner{
        releaseTime = _releaseTime;
    }

    //change Sale startTime and endTime
    function changeSaleTime(
        uint256 _r1StartTime,
        uint256 _r2StartTime,
        uint256 _r3StartTime,
        uint256 _endTime
    )  public onlyOwner{
        r1StartTime = _r1StartTime;
        r2StartTime = _r2StartTime;
        r3StartTime = _r3StartTime;
        endTime = _endTime;
    }
  
    //change to pause
    function pause() public onlyOwner{
        paused = true;
    }

    //unpause
    function unpause() public onlyOwner{
        paused = false;
    }
    
    function setDevAddress(address _address) public onlyOwner{
        devAddress = _address;
    }

    function sweep(uint256 _type) public onlyOwner {
        if(_type == 0){
            payable(msg.sender).transfer(address(this).balance);
        }
        else if(_type == 1){
            uint256 amount = IERC20(usdAddress).balanceOf(address(this));
            if(amount > 0){
                IERC20(usdAddress).safeTransfer(msg.sender,amount);
            }
        }
        else{
            uint256 amount = IERC20(tokenAddress).balanceOf(address(this));
            if(amount > 0){
                IERC20(tokenAddress).safeTransfer(msg.sender,amount);
            }
        }
    }
}