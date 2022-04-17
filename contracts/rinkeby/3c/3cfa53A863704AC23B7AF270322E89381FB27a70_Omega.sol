/**
 *Submitted for verification at Etherscan.io on 2022-04-17
*/

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;



/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
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

// File: investLogic.sol

 
//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

 
abstract contract Context {
   function _msgSender() internal view virtual returns (address) {
       return msg.sender;
   }
 
   function _msgData() internal view virtual returns (bytes calldata) {
       this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
       return msg.data;
   }
}
 
abstract contract Ownable is Context {
   address private _owner;
 
   event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
 
   /**
    * @dev Initializes the contract setting the deployer as the initial owner.
    */
   constructor () {
       address msgSender = _msgSender();
       _owner = msgSender;
       emit OwnershipTransferred(address(0), msgSender);
   }
 
   /**
    * @dev Returns the address of the current owner.
    */
   function owner() public view virtual returns (address) {
       return _owner;
   }
 
   modifier onlyOwner() {
       require(owner() == _msgSender(), "Ownable: caller is not the owner");
       _;
   }
 
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
 
   function add(uint256 a, uint256 b) internal pure returns (uint256) {
       return a + b;
   }
 
   function sub(uint256 a, uint256 b) internal pure returns (uint256) {
       return a - b;
   }
 
   function mul(uint256 a, uint256 b) internal pure returns (uint256) {
       return a * b;
   }
 
   function div(uint256 a, uint256 b) internal pure returns (uint256) {
       return a / b;
   }
 
   function mod(uint256 a, uint256 b) internal pure returns (uint256) {
       return a % b;
   }
   function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
       unchecked {
           require(b <= a, errorMessage);
           return a - b;
       }
   }
 
   function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
       unchecked {
           require(b > 0, errorMessage);
           return a / b;
       }
   }
 
   function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
       unchecked {
           require(b > 0, errorMessage);
           return a % b;
       }
   }
}
 
contract Pausable is Ownable {
   event Pause();
   event Unpause();
 
   bool public paused = false;
 
 
   /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
   modifier whenNotPaused() {
       require(!paused);
       _;
   }
 
   /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
   modifier whenPaused() {
       require(paused);
       _;
   }
 
   /**
   * @dev called by the owner to pause, triggers stopped state
   */
   function pause() onlyOwner whenNotPaused public {
       paused = true;
       emit Pause();
   }
 
   /**
   * @dev called by the owner to unpause, returns to normal state
   */
   function unpause() onlyOwner whenPaused public {
       paused = false;
       emit Unpause();
   }
}
 
contract Omega is Ownable, Pausable {  
   
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    string public name = "Omega Pools";
 
    IERC20 private usdtToken;
    IERC20 private omegaToken;
 
    address[] private stakers;
    uint256 public currentPoolID;
   
    mapping(uint256=>uint256) public stakingStartTime; // to manage the time when the user started the staking
    mapping(uint256=>uint256) private withdrawTime; // to manage the time when the user started the staking
    mapping(uint256 => uint) private investmentPool;     // to manage the staking of usdtToken and distibue the profit as usdtToken B
    mapping(address => bool) private isStaking;
    mapping(uint256 =>uint256) private redeemedAt;
    mapping(uint256 =>uint256) private restakingAt;
    mapping(uint256 =>uint256) public stakedOmega; // Staked Omega amount of the Pool
    mapping(uint256 =>uint256) public userTerms;  // Time terms 1 month, 3 month or six of the Pool selected by the user
    mapping(uint256 =>uint256) public userRates;  // Rate of Pool according to Time Term
    mapping(uint256 =>address) public userToken;   // Token of the Pool selected by the user
    mapping(uint256 =>address) public poolOwner;
 
    // Events
    event Staketoken(address indexed sender, uint256 amount, uint256 indexed poolID);
    event RedeemInterest(uint256 indexed poolID, uint256 redeemTime, uint256 redeemAmount);
    event Restake(uint256 indexed poolID, uint256 restakeTime, uint256 restakeAmount);
    event Withdraw(uint256 indexed poolID, uint256 withdrawTime);
    event RestakeByAdmin(uint256 indexed poolID, uint256 restakeTime, uint256 restakeAmount);
   
    uint256 private totalInvestmentPoolBalance;
    address private usdtAddress; // Address to be used to transfer the usdt rewards 
 
    enum terms { one, three, six} //Months 0,1,2    
   
    uint256 private oneMonth = 60; //2592000
    uint256 private threeMonth = 180;   //7889238
    uint256 private sixMonth = 360;    //15778476
 
    uint256 private omegaPercent = 10;
 
    // mapping(address => mapping(address => uint256)) userAmount;
 
    constructor(IERC20 _token, IERC20 _omegaToken, address _usdtAddress) {
        usdtToken = _token;
        omegaToken = _omegaToken;
        usdtAddress = _usdtAddress;
    }
 
    /* Stakes Tokens (Deposit): An investor will deposit the usdtToken into the smart contracts
    to starting earning rewards.
       
    Core Thing: Transfer the stable coin from the investor's wallet to this smart contract. */
    function staketoken(uint _amount, terms time, address _stableCoinPair) public whenNotPaused {  
 
        require(_amount > 0, "staking balance cannot be 0");
 
        require(IERC20(_stableCoinPair).balanceOf(msg.sender) > _amount, "Not enough balance");
 
        uint256 omegaAmount = _amount.mul(omegaPercent).div(100);
 
        require(omegaToken.balanceOf(msg.sender) > omegaAmount, "Not enough balance of Omega");
        require((time == terms.one) || (time == terms.three) || (time == terms.six), "Terms should be 0,1 or 2");
        currentPoolID = currentPoolID + 1;
 
        IERC20(_stableCoinPair).safeTransferFrom(msg.sender, address(this), _amount);
        // Take 10% Omega
        omegaToken.safeTransferFrom(msg.sender, address(this), omegaAmount);
        // UPDATES
        if(time == terms.one){
            userTerms[currentPoolID] = oneMonth;  
            userRates[currentPoolID] = 2;        
        }else if(time == terms.three){
            userTerms[currentPoolID] = threeMonth;  
            userRates[currentPoolID] = 3;                  
        }else if(time == terms.six){
            userTerms[currentPoolID] = sixMonth;
            userRates[currentPoolID] = 5;                  
        }
        poolOwner[currentPoolID] = msg.sender;
        stakers.push(msg.sender);
 
        userToken[currentPoolID] = _stableCoinPair;
        stakingStartTime[currentPoolID] = block.timestamp;
        totalInvestmentPoolBalance += _amount;
        investmentPool[currentPoolID] = _amount;
        stakedOmega[currentPoolID] = omegaAmount;
        isStaking[msg.sender] = true;
 
        emit Staketoken(msg.sender, _amount, currentPoolID);
    }
 
    function calculateReward(uint256 stakeBalance, uint256 id) internal virtual returns(uint256){
        uint256 reward = stakeBalance.mul(userRates[id]).div(100);
        return reward;
    }
 
    function redeemInterest(uint256 poolID) public whenNotPaused {
       
        require(isStaking[msg.sender], "User have no staked tokens to get the reward");
        require(poolOwner[poolID] == msg.sender, "Caller is not the owner of the Pool");
        uint256 balance = investmentPool[poolID];
 
        require(balance > 0, "staking balance cannot be 0");
        require(block.timestamp - restakingAt[poolID] >= userTerms[poolID], "Amount has been used for restaking");
        uint256 startTime = stakingStartTime[poolID];
 
        require(block.timestamp - startTime >= userTerms[poolID], "No Interest to redeem");
 
        uint256 reward = calculateReward(balance, poolID);
        require(usdtToken.balanceOf(usdtAddress) > reward, "Not Enough tokens in the smart contract");
 
        usdtToken.safeTransferFrom(usdtAddress, msg.sender, reward);
        redeemedAt[poolID] = block.timestamp;
 
        emit RedeemInterest(poolID, redeemedAt[poolID], reward);
    }
 
    function restake(uint256 poolID) public whenNotPaused {
 
        require(isStaking[msg.sender], "User have no staked tokens to get the reward");
        require(poolOwner[poolID] == msg.sender, "Caller is not the owner of the Pool");
        uint balance = investmentPool[poolID];
 
        require(balance > 0, "staking balance cannot be 0");
        uint256 startTime = stakingStartTime[poolID];
 
        require(block.timestamp - startTime >=  userTerms[poolID], "cannot restake before terms");
        uint256 restakingAmount = calculateReward(balance, poolID);
 
        investmentPool[poolID] += restakingAmount;
        totalInvestmentPoolBalance += restakingAmount;  
        restakingAt[poolID] = block.timestamp;
        stakingStartTime[poolID] = block.timestamp;
 
 
        emit Restake(poolID, restakingAt[poolID], restakingAmount);
    }
 
    function withdraw(uint256 poolID) public whenNotPaused {
 
        require(isStaking[msg.sender], "User have no staked tokens to get the reward");
        require(poolOwner[poolID] == msg.sender, "Caller is not the owner of the Pool");
 
        uint balance = investmentPool[poolID];
        require(balance > 0, "staking balance cannot be 0");
        uint256 startTime = stakingStartTime[poolID];
        uint256 usdtReward = calculateReward(balance, poolID);
        uint256 stableCoinBalance = balance;
        uint256 stakedOmegaBalance = stakedOmega[poolID];
       
        require(usdtToken.balanceOf(usdtAddress) > usdtReward, "Not Enough USDT in the smart contract");
        require(IERC20(userToken[poolID]).balanceOf(address(this)) > stableCoinBalance, "Not Enough Stable Coin in the smart contract");
        require(omegaToken.balanceOf(address(this)) > stakedOmegaBalance, "Not Enough Omega in the smart contract");
 
        if(block.timestamp - startTime >= userTerms[poolID]){
            if((block.timestamp - redeemedAt[poolID] >= userTerms[poolID])){
               
                usdtToken.safeTransferFrom(usdtAddress, msg.sender, usdtReward);
 
                IERC20(userToken[poolID]).safeTransfer(msg.sender, stableCoinBalance);
 
                omegaToken.safeTransfer(msg.sender, stakedOmegaBalance);
 
            }else{
                IERC20(userToken[poolID]).safeTransfer(msg.sender, stableCoinBalance);
 
                omegaToken.safeTransfer(msg.sender, stakedOmegaBalance);
            }
        }else{
                IERC20(userToken[poolID]).safeTransfer(msg.sender, stableCoinBalance);
        }
        // UPDATES
        isStaking[msg.sender] = false;
        investmentPool[poolID] = 0;
        withdrawTime[poolID] = block.timestamp;
 
        emit Withdraw(poolID, withdrawTime[poolID]);
 
    }
 
    function calculateInterest(uint256 poolID) public whenNotPaused returns(uint256){
 
        require(isStaking[msg.sender], "User have no staked tokens to get the reward");
        require(poolOwner[poolID] == msg.sender, "Caller is not the owner of the Pool");
        uint256 balance = investmentPool[poolID];
 
        require(balance > 0, "staking balance cannot be 0");
        uint256 startTime = stakingStartTime[poolID];
 
        require(block.timestamp - startTime >= userTerms[poolID], "No Interest to redeem");
 
        uint256 reward = calculateReward(balance, poolID);
        return reward;
    }
   
    function restakeByAdmin(uint256 poolID, address Owner) external whenNotPaused onlyOwner{
 
        require(isStaking[Owner], "User have no staked tokens to get the reward");
        require(poolOwner[poolID] == Owner, "not the owner of the Pool");
        uint balance = investmentPool[poolID];
 
        require(balance > 0, "staking balance cannot be 0");
        uint256 startTime = stakingStartTime[poolID];
 
        require(block.timestamp - startTime >=  userTerms[poolID], "cannot restake before terms");
        uint256 restakingAmount = calculateReward(balance, poolID);
 
        investmentPool[poolID] += restakingAmount;
        totalInvestmentPoolBalance += restakingAmount;  
        restakingAt[poolID] = block.timestamp;
        stakingStartTime[poolID] = block.timestamp;
 
        emit RestakeByAdmin(poolID, restakingAt[poolID], restakingAmount);
    }
 
    function setOmegaToken(IERC20 _token) external onlyOwner whenNotPaused {
        omegaToken = _token;
    }
 
    function setUsdtToken(IERC20 _token) external onlyOwner whenNotPaused {
        usdtToken = _token;
    }
    
    function setUsdtAddress(address _usdtAddress) external onlyOwner whenNotPaused {
        usdtAddress = _usdtAddress;
    }

    function getUsdtAddress() external view onlyOwner whenNotPaused returns(address){
        return usdtAddress;
    }
 
    /**
        * @dev withdraw all bnb from the smart contract
    */
 
    function withdrawBNBFromContract(uint256 _amount, address payable _reciever) external onlyOwner returns(bool){
        _reciever.transfer(_amount);
        return true;
    }
 
    function withdrawTokenFromContract(address tokenAddress, uint256 amount, address receiver) external onlyOwner {
        require(IERC20(tokenAddress).balanceOf(address(this))>= amount, "Insufficient amount to transfer");
        IERC20(tokenAddress).safeTransfer(receiver,amount);
    }
}