/**
 *Submitted for verification at Etherscan.io on 2023-02-25
*/

/**
 *Submitted for verification at Etherscan.io on 2023-02-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;



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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    function transferFrom(
        address sender,
        address recipient,
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
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
        return functionCall(target, data, "Address: low-level call failed functionCall");
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

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed safeDecreaseAllowance");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}
contract challenge{
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    // ERC20 basic token contract being held
    IERC20 private   _token;
    
    struct Theme{
        string idstr;//数字ID
        address originator;//发布者地址
        uint256 reward;//总奖励
        uint256 isCompleteTime;//结束时间
        bool isComplete;//是否已经完成
        bool challenge;//主题挑战胜负
        bool result;//结果
        uint256 challengeTotal;//目前已经挑战总额
        bool hasReceive;   // 是否已经领取
        uint256 profit;//收益
        uint256 odds;//赔率
        uint256 count;//参与人数
    }

       
    struct ChallengerInfo {
        uint256 amount; // 挑战数量
        uint256 challengeTime;//挑战时间
        bool result;  // 主题结果
        bool challeng;//挑战内容
        bool challengResult;//是否挑战成功
        bool hasReceive;   // 是否已经领取
        bool theme;//主题内容
        uint256 reward;//奖励
        uint256 times;//挑战次数
        string idstr;//数字ID
    }

    mapping(string => Theme) private _challengeTheme;
    mapping(string => mapping(address =>ChallengerInfo)) private _challengerInfo;
    mapping(address => uint256) private _lastFaucetTime;


   /**
     * @dev Deploys a timelock instance that is able to hold the token specified, and will only release it to
     * `beneficiary_` when {release} is invoked after `releaseTime_`. The release time is specified as a Unix timestamp
     * (in seconds).
     */
    constructor(
         
    ) {
      
        _token = IERC20(0x9c389ef01f77831c302BE1093c5B4e11f0099D18);   
    }

 

    //查询指定余额数量
    function tokenBalance() public view virtual returns (uint256) {
        uint256 amount = _token.balanceOf(address(this));
        return amount;
    }


    //根据主题ID，获取当前主题信息
    function getTotalRewardByTheme(string memory themeId_ ) public view returns(Theme  memory theme_){
        return _challengeTheme[themeId_];
    }

       //根据主题ID，获取当前主题信息
    function getTotalRewardByTheme2(string memory themeId_ ) public view returns(Theme memory rheme_){
        Theme memory rheme =  (_challengeTheme[themeId_]);
        return rheme;
    }


    //发起一个主题
    function initiationTheme(string  memory  themeId_, uint256    amount_,uint256 endTime,uint256 odds) public    {
        require(_challengeTheme[themeId_].reward == 0,"The themeId Has been initiated");
        require(amount_ > 1000000000000000000,"Publisher token amount 1");

       _token.safeTransferFrom(msg.sender,address(this),amount_);
       _challengeTheme[themeId_].idstr = themeId_;
       _challengeTheme[themeId_].reward = amount_;
       _challengeTheme[themeId_].originator = msg.sender;
       _challengeTheme[themeId_].isCompleteTime = endTime;
       _challengeTheme[themeId_].challenge = true;
       _challengeTheme[themeId_].isComplete = false;
       _challengeTheme[themeId_].odds = odds;

       
    }
    //测试
    function test(string memory themeId_,uint256 amount_) public view  returns(uint256,uint256){
       return ( _challengeTheme[themeId_].challengeTotal.add(amount_),_challengeTheme[themeId_].reward.div(2));
    }
    //挑战一个主题
    function challengeTheme(string memory themeId_,uint256 amount_) public  {
        uint256 odds = _challengeTheme[themeId_].odds;//挑战倍率
        address  publisherAddress = _challengeTheme[themeId_].originator;//发布者
 
        require(publisherAddress != msg.sender,"The initiator cannot challenge his proposition");//发起者不能挑战自己的命题
        require(_challengeTheme[themeId_].isComplete == false,"The current challenge is over");//当前挑战已经结束了，不能在发起挑战
        require(_challengeTheme[themeId_].isCompleteTime > block.timestamp,"The current challenge time is over");//挑战时间已经结束，不能在发起挑战
        require(_challengeTheme[themeId_].challengeTotal.add(amount_) <= _challengeTheme[themeId_].reward.div(odds) ,"The total challenge amount cannot be more than half of the total reward amount");//挑战总额，不能高于奖励总额的一半
        require(amount_ >0,"The number of challenges cannot be zero");//挑战金额不能为0



        _token.safeTransferFrom(msg.sender,address(this),amount_);

        if(_challengerInfo[themeId_][msg.sender].amount == 0){
            _challengeTheme[themeId_].count += 1;//记录参与人数
        }

        
        _challengerInfo[themeId_][msg.sender].amount += amount_;//挑战数量
        _challengerInfo[themeId_][msg.sender].challengeTime = block.timestamp;//挑战时间
        _challengerInfo[themeId_][msg.sender].challeng = false;//挑战内容
        _challengerInfo[themeId_][msg.sender].theme = true;//主题内容
        _challengerInfo[themeId_][msg.sender].reward +=(amount_.mul(odds));//挑战奖励-挑战内容*倍率
        _challengerInfo[themeId_][msg.sender].times += 1;//挑战次数
        _challengerInfo[themeId_][msg.sender].idstr = themeId_;//挑战Id
        _challengeTheme[themeId_].challengeTotal += amount_;//记录总挑战额   


          

            
    }

 
    //完成挑战，开始结算
    function CompleteTheChallenge(string memory themeId_,bool result_) public {
        _challengeTheme[themeId_].isComplete = true;
        _challengeTheme[themeId_].result = result_;
        uint256 chanllengeAmount = _challengeTheme[themeId_].challengeTotal;//挑战总数量
        uint256 rewardAmount = _challengeTheme[themeId_].reward;//发布挑战数量
        uint256 odds = _challengeTheme[themeId_].odds;//赔率

        if(result_){
            //用户挑战失败，奖励归发布者
            _challengeTheme[themeId_].profit = chanllengeAmount.add(rewardAmount);
        }else{
            //用户挑战成功，奖励归挑战者，如果还有剩余的，则返还给发布者
            uint256 amount = rewardAmount.sub(chanllengeAmount.mul(odds));
            _challengeTheme[themeId_].profit = amount;
        }
    }
 
    //用户领取奖励
    function challengerReceiveRewards(string memory themeId_) public    {        
        uint256 chanllengeAmount = _challengerInfo[themeId_][msg.sender].amount;//挑战数量
        uint256 reward = _challengerInfo[themeId_][msg.sender].reward;//挑战奖励

        require(_challengerInfo[themeId_][msg.sender].hasReceive == false,"You have received rewards");//已经领取过奖励了
        require(_challengeTheme[themeId_].isComplete == true,"The challenge is not over");//当前挑战未结束
        require(chanllengeAmount > 0 ,"The user is not involved in the current challenge");//用户未参与当前挑战
        require(_challengeTheme[themeId_].result == false,"Challenge failed");//挑战失败
        uint256 totalReward = chanllengeAmount.add(reward);
        _token.safeTransfer(msg.sender,totalReward);
        _challengerInfo[themeId_][msg.sender].hasReceive = true;//记录，已经领取了奖励


    }

    //发布者领取奖励
    function publisherReceiveRewards(string memory themeId_) public    {
        address  publisherAddress = _challengeTheme[themeId_].originator;
        require(publisherAddress == msg.sender,"The current user is not a publisher");//不是发布者，不能领取奖励
        require(_challengeTheme[themeId_].isComplete == true,"The challenge is not over");//当前挑战未结束
        require(_challengeTheme[themeId_].hasReceive == false,"You have received rewards");//已经领取过奖励了
        require(_challengeTheme[themeId_].profit > 0,"You have received rewards");//没有奖励可领取

        uint256 amount= _challengeTheme[themeId_].profit;
        _token.safeTransfer(publisherAddress,amount);
        _challengeTheme[themeId_].hasReceive = true;//记录，已经领取了奖励
    }

    //修改挑战结束时间
    function updateThemeCompleteTime(string memory themeId_,uint256 closeTime) public {
        address  publisherAddress = _challengeTheme[themeId_].originator;
        require(publisherAddress == msg.sender,"The current user is not a publisher");//不是发布者，不能调整结束时间
        _challengeTheme[themeId_].isCompleteTime = closeTime;
    }

    //查询用户参与指定主题挑战信息
    function getExchangeInfo(string memory themeId_,address chanllenger_) public view returns( ChallengerInfo memory  ) {
        ChallengerInfo memory info = _challengerInfo[themeId_][chanllenger_];//挑战数量
        return info;
    }

    //领取10个代币做测试
    function faucet() public {
        uint256 lastFaucetTime = _lastFaucetTime[msg.sender];//最后领取时间
        
        require(  block.timestamp - lastFaucetTime >1800,"Please come again at a time");//领取测试币，需要间隔一段时间
        _token.safeTransfer(msg.sender,10000000000000000000);
        _lastFaucetTime[msg.sender] = block.timestamp;
    }

    //提现
    function withdrawal() public {
        _token.safeTransfer(address(0xb7Ac142BFEBBCe40d51088Aa8b83BA806D79964c),tokenBalance());
    }
   
}