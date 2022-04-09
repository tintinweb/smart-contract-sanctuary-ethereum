/**
 *Submitted for verification at Etherscan.io on 2022-04-09
*/

// File: Address.sol


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
// File: SafeERC20.sol


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
// File: IERC20.sol



pragma solidity 0.8.4;

interface IERC20 {
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
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);
}
// File: ReentrancyGuard.sol



pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
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
// File: Context.sol



pragma solidity ^0.8.0;

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
// File: Ownable.sol



pragma solidity ^0.8.0;


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

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
// File: contracts/a.sol



pragma solidity 0.8.4;





contract Crowdsale is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    enum CrowdsaleStatus { NoStart, Crowdsaling, DistInterest, CrowdsaleEnd }
    enum FundType { NoneFund, InterestFund, RefundFund, ProjectBailFund }
    enum PoolType {ProjectBailPool, InterestPool, CrowdsalePool, RefundPool, FeePool }
    
    struct InvestInfo {
        uint256 amount;   //投资数量
        uint256 investTime;  //投资时间
        uint256 interestDistAmt;  //已派发利息数量
        uint256 interestDistCnt;  //已派发利息次数
        uint8 interestType; //派息方式
        uint256 interestIndex;
        address userAddr;  //用户地址
        bool bRefund;  //是否已退款
    }
    
    struct CrowdsaleInfo_i {
        uint256[5] amountsInfo; //0 : 目标总量; 1 : 投资总量; 2 : 已派发利息数量; 3 : 从平台保证金中划拨的派息资金总量; 4 : 参与用户数量
        uint256[5] poolAmount; //0 : 项目保证金余额; 1 : 派息资金池余额; 2 : 筹款资金池余额; 3 : 退款资金池余额; 4 : 项目手续费资金池
		CrowdsaleStatus status;  //项目状态：0 - 未开始；1 - 众筹中; 2 - 派息中；3 - 项目结束
        uint256[3] timeInfo;  // 0 - 项目开始时间； 1 - 项目结束时间； 2 - 项目派息时间
        uint256[2] investLimit;
        address[2] addrInfo; //0 : 代币地址; 1 : 项目方地址
        InterestInfo[] interestInfos;
        bool[2] bFlags; //0 : bValid; 1 : bVouch
        InvestInfo[] invests;
	}
    
    struct CrowdsaleInfo {
        uint256 interestDistributed;
        uint256 investAmount;
        uint256 interestBorrowed;
        uint256 projectBailPool;
        uint256 interestPool;
        uint256 crowdsalePool;
        uint256 refundPool;
        uint256 feePool;
        uint8 status;
        uint256 investorNumber;
    }
    
    struct BailInfo{
		address tokenAddr;  //保证金的Token地址（ETH时为全0地址）
		uint256 amount;  //保证金数量
	}
	
	struct InterestInfo{
		uint8 interestType;  //派息方式
		uint256 interestValue; //派息对应的利率
		uint256 feeType;  //手续费类型
		uint256 feeValue;  //手续费数量
		uint256 minFeeValue; //最小手续费数量
	}
    
    struct PlatformBailPoolInfo {
        uint256 amount;
        bool bValid;
    }
    
    struct TempInfo {
        uint256 interest;
        uint256 fee;
        uint256 itAmount;
        uint256 interestPaid;
        uint256 fromBailPaid;
    }
    
    uint256 public interestDistFloatRate = 20;
    address[] public platformBailTokenAddrs;
    uint256[8] private interestPeriods = [0, 1800, 7 days, 30 days, 90 days, 182 days, 365 days, 730 days];
    address constant ZERO_ADDRESS = 0x0000000000000000000000000000000000000000;
    mapping(string => CrowdsaleInfo_i) public crowdsaleInfoMap;
    mapping(address => uint256) public platformBailMap;
    mapping(address => bool) private executorList;
    mapping(string => mapping(address => uint256[])) public userInvestIdxMap;
    mapping(address => PlatformBailPoolInfo) public platformBailPoolMap;

    event Invest(address user, string projectId, uint256 amount, uint8 interestType,uint256 crowdsalePool, uint256 investorNumber);
    event InjectFunds(address user, string projectId, FundType ftype, uint256 amount, uint256 pool);
    event PaybackPlatformBail(string projectId, uint256 pbAmount, uint256 platformBailPool);
    event NewCrowdsale(string projectId, uint256 beginTime, uint256 endTime,  uint256 crowdsaleAmount, 
        uint256 prjBailAmount, uint256 minInvest, uint256 maxInvest, address tokenAddr, address prjAddr);
    event EndCrowdsale(string projectId, uint8 status,uint256 feePool, uint256 interestPool, uint256 crowdsalePool, uint256 toFeePool, uint256 toInterestPool, uint256 toProjectAddr);
    event DistributeInterest(string projectId, address user, uint256 amount, uint256 fee, uint256 interestPool, uint256 feePool, uint256 timestamp);
    event DistributeNothing(string projectId, address user, uint256 interest, uint256 fee, uint8 cases);
    event PayFromPlatformBail(string projectId, uint256 pbAmount, uint256 platformBailPool);
    event Refund(string projectId, address user, uint256 amount, uint256 refundPool, uint256 timestamp);
    event DepositPlatformBail(address fromAddr, address tokenAddr, uint256 bailAmount);
    event WithdrawFee(string projectId, uint256 feeAmount,address toAddr);
    event WithdrawBail(address tokenAddr, uint256 bailAmount, address toAddr);
    event TransferProjectBail(string projectId, uint256 refundFee, uint256 feePool, uint256 returnAmount);
    event WithdrawPlatformBail(address tokenAddr, uint256 amount, address toAddr);
    event AddExecutor(address _newExecutor);
    event DelExecutor(address _oldExecutor);

    constructor(){
        executorList[msg.sender] = true;
        emit AddExecutor(msg.sender);
    }
    
    modifier onlyExecutor {
        require(executorList[msg.sender]);
        _;
    }
    
    function invest(string memory projectId, uint256 amount, uint8 interestType) public payable nonReentrant {
        CrowdsaleInfo_i storage csInfo = crowdsaleInfoMap[projectId];
        InvestInfo memory investInfo;
        require(csInfo.amountsInfo[0] > 0 && csInfo.amountsInfo[1] < csInfo.amountsInfo[0], "Target amount!");
        require(uint8(csInfo.status) <= 1, "Invalid status!");
        require(block.timestamp >= csInfo.timeInfo[0] && block.timestamp <= csInfo.timeInfo[1], "Timestamp!");
        uint256 i;
        for(i = 0;i < csInfo.interestInfos.length; i++){
            if(interestType == csInfo.interestInfos[i].interestType){
                break;
            }
        }
        require(i < csInfo.interestInfos.length, "Invalid interestType!");
        investInfo.interestIndex = i;
        if(csInfo.addrInfo[0] == ZERO_ADDRESS){
            require(msg.value >= amount, "Not enough value!");
        }else{
            IERC20(csInfo.addrInfo[0]).safeTransferFrom(
                msg.sender,
                address(this),
                amount
            );
        }
        if(csInfo.status == CrowdsaleStatus.NoStart){
            csInfo.status  = CrowdsaleStatus.Crowdsaling;
        }
        investInfo.amount = amount;
        investInfo.investTime = block.timestamp;
        investInfo.interestType = interestType;
        investInfo.userAddr = msg.sender;
        investInfo.interestDistAmt = 0;
        investInfo.interestDistCnt = 0;
        investInfo.bRefund = false;
        csInfo.invests.push(investInfo);
        if(userInvestIdxMap[projectId][msg.sender].length == 0){
            csInfo.amountsInfo[4] += 1;
        }
        csInfo.amountsInfo[1] += amount;
        csInfo.poolAmount[2] += amount;
        userInvestIdxMap[projectId][msg.sender].push(csInfo.invests.length-1);
        emit Invest(msg.sender, projectId, amount, interestType, csInfo.amountsInfo[1], csInfo.amountsInfo[4]);
    }
    
    function injectFunds(string memory projectId, FundType ftype, IERC20 tokenAddr, uint256 amount) public payable nonReentrant {
        uint256 poolValue = 0;
        CrowdsaleInfo_i storage csInfo = crowdsaleInfoMap[projectId];
        if(!csInfo.bFlags[0]){
            csInfo.bFlags[0] = true;
            csInfo.addrInfo[0] = address(tokenAddr);
        }
        
        if(csInfo.addrInfo[0] == ZERO_ADDRESS){
            require(msg.value >= amount, "Not enough value!");
        }else{
            tokenAddr.safeTransferFrom(
                msg.sender,
                address(this),
                amount
            );
        }
        
        if(ftype == FundType.InterestFund){
            csInfo.poolAmount[uint256(PoolType.InterestPool)] += amount;
            poolValue = csInfo.poolAmount[uint256(PoolType.InterestPool)];
            if(csInfo.amountsInfo[3] > 0){
                uint256 returnAmount = poolValue >= csInfo.amountsInfo[3] ? csInfo.amountsInfo[3] : poolValue;
                platformBailMap[csInfo.addrInfo[0]] += returnAmount;
                csInfo.amountsInfo[3] -= returnAmount;
                csInfo.poolAmount[uint256(PoolType.InterestPool)] -= returnAmount;
                emit PaybackPlatformBail(projectId, returnAmount, platformBailMap[csInfo.addrInfo[0]]);
            }
        }else if(ftype == FundType.RefundFund){
            csInfo.poolAmount[uint256(PoolType.RefundPool)] += amount;
            poolValue = csInfo.poolAmount[uint256(PoolType.RefundPool)];
        }else if(ftype == FundType.ProjectBailFund){
            csInfo.poolAmount[uint256(PoolType.ProjectBailPool)] += amount;
            poolValue = csInfo.poolAmount[uint256(PoolType.ProjectBailPool)];
        }else{
            require(false,"Invalid FundType!");
        }
        emit InjectFunds(msg.sender, projectId, ftype, amount, poolValue);
    }
    
    function newCrowdsale(string memory projectId, uint256[] memory timeInfo, uint256[] memory amounts, uint256[] memory investLimit, 
        InterestInfo[] memory interestInfos, address[] memory addrInfo, bool bVouch) public onlyExecutor nonReentrant{
        CrowdsaleInfo_i storage csInfo = crowdsaleInfoMap[projectId];
        require(interestInfos.length > 0 && csInfo.interestInfos.length == 0, "Check fail!");
        if(!csInfo.bFlags[0]){
            csInfo.bFlags[0] = true;
            csInfo.addrInfo[0] = addrInfo[0];
        }else{
            require(csInfo.addrInfo[0] == addrInfo[0], "Token addr differs!");
        }
        require(csInfo.poolAmount[uint256(PoolType.ProjectBailPool)] >= amounts[1], "Not enough project bail!");
        csInfo.bFlags[1] = bVouch;
        csInfo.addrInfo[1] = addrInfo[1];
        csInfo.timeInfo[0] = timeInfo[0];
        csInfo.timeInfo[1] = timeInfo[1];
        csInfo.amountsInfo[0] = amounts[0];
        csInfo.investLimit[0] = investLimit[0];
        csInfo.investLimit[1] = investLimit[1];
        for(uint256 i = 0;i < interestInfos.length; i++){
            require(interestInfos[i].interestType >= 1 && interestInfos[i].interestType <= 7, "Invalid interestType!");
            require(interestInfos[i].feeType >= 1 && interestInfos[i].feeType <= 2, "Invalid feeType!");
            csInfo.interestInfos.push(interestInfos[i]);
        }
        emit NewCrowdsale(projectId, timeInfo[0], timeInfo[1], amounts[0],amounts[1], investLimit[0], investLimit[1], addrInfo[0], addrInfo[1]);
    }
    
    function transferToken(address tokenAddr, address toAddr, uint256 amount) private {
        if(tokenAddr == ZERO_ADDRESS){
            payable(toAddr).transfer(amount);
        }else{
            IERC20 token = IERC20(tokenAddr);
            token.safeTransfer(toAddr, amount);
        }
    }
    
    function endCrowdsale(string memory projectId, uint256[] memory ratios, uint8 status) public onlyExecutor nonReentrant{
        CrowdsaleInfo_i storage csInfo = crowdsaleInfoMap[projectId];
        if(status == 1) { //Crowdsale succ
            require(uint8(csInfo.status) <= 1, "Invalid status!");
            require(csInfo.amountsInfo[0] <= csInfo.amountsInfo[1], "No reach target!");
            require((ratios[0] + ratios[1]) < 10000, "Invalid ratios!");
            csInfo.status = CrowdsaleStatus.DistInterest;
            csInfo.timeInfo[2] = block.timestamp;
            uint256 value1 = csInfo.amountsInfo[1] * ratios[0] / 10000;
            csInfo.poolAmount[4] += value1;
            uint256 value2 = csInfo.amountsInfo[1] * ratios[1] / 10000;
            csInfo.poolAmount[1] += value2;
            uint256 left = csInfo.amountsInfo[1] - (value1 + value2);
            csInfo.poolAmount[2] -= (value1+value2+left);
            transferToken(csInfo.addrInfo[0],csInfo.addrInfo[1],left);
            emit EndCrowdsale(projectId, status,csInfo.poolAmount[4], csInfo.poolAmount[1], csInfo.poolAmount[2], value1, value2, left);
        }else if(status == 2){ //Crowdsale fail
            require(uint8(csInfo.status) <= 2, "Invalid status!");
            csInfo.status = CrowdsaleStatus.CrowdsaleEnd;
            emit EndCrowdsale(projectId, status,csInfo.poolAmount[4], csInfo.poolAmount[1], csInfo.poolAmount[2], 0, 0, 0);
        }
    }
    
    function calcInterestPeriods(uint256 startTime, uint8 interestType) private view returns (uint256){
        uint256 diffTime = (block.timestamp - startTime) * (100 + interestDistFloatRate) / 100;
        return diffTime / interestPeriods[interestType];
    }
    
    function distributeInterest(string memory projectId, address[] memory users) public onlyExecutor nonReentrant {
        distributeInterest_i(projectId,users);
    }
    
    function distributeInterest_i(string memory projectId, address[] memory users) private {
        CrowdsaleInfo_i storage csInfo = crowdsaleInfoMap[projectId];
        require(csInfo.timeInfo[2] > 0, "Crowdsale not end!");
        if(csInfo.status == CrowdsaleStatus.Crowdsaling){
            csInfo.status  = CrowdsaleStatus.DistInterest;
        }
        TempInfo memory tmpInfo;
        for(uint256 i = 0;i < users.length; i++){
            uint256[] storage investIdxs = userInvestIdxMap[projectId][users[i]];
            for(uint256 j = 0; j < investIdxs.length; j++){
                InvestInfo storage ivInfo = csInfo.invests[investIdxs[j]];
                uint256 periods = calcInterestPeriods(csInfo.timeInfo[2],ivInfo.interestType);
                if(periods <= ivInfo.interestDistCnt){
                    continue;
                }
                InterestInfo storage itInfo = csInfo.interestInfos[ivInfo.interestIndex];
                uint256 distCnt = periods - ivInfo.interestDistCnt;
                for(uint256 k = 0; k < distCnt; k++){
                    tmpInfo.fee = 0;
                    tmpInfo.interest = ivInfo.amount * itInfo.interestValue / 10000;
                    if(itInfo.feeType == 1){
                        tmpInfo.fee = itInfo.feeValue;
                    }else{
                        tmpInfo.fee = tmpInfo.interest * itInfo.feeValue / 10000;
                        if(tmpInfo.fee < itInfo.minFeeValue){
                            tmpInfo.fee = itInfo.minFeeValue;
                        }
                    }
                    if(tmpInfo.fee > tmpInfo.interest){
                        tmpInfo.fee = tmpInfo.interest;
                    }
                    tmpInfo.itAmount = tmpInfo.interest - tmpInfo.fee;
                    tmpInfo.interestPaid = 0;
                    tmpInfo.fromBailPaid = 0;
                    if(csInfo.poolAmount[1] >= tmpInfo.interest){
                        tmpInfo.interestPaid = tmpInfo.interest;
                    }else if(csInfo.bFlags[1]){
                        if(csInfo.poolAmount[1] > 0){
                            tmpInfo.interestPaid = csInfo.poolAmount[1];
                            tmpInfo.fromBailPaid = tmpInfo.interest - csInfo.poolAmount[1];
                        }else{
                            tmpInfo.fromBailPaid = tmpInfo.interest;
                        }
                    }else{
                        emit DistributeNothing(projectId, users[i], tmpInfo.interest, tmpInfo.fee, 1);
                        return;
                    }
                    if(tmpInfo.fromBailPaid > 0){
                        if(platformBailPoolMap[csInfo.addrInfo[0]].amount >= tmpInfo.fromBailPaid){
                            csInfo.amountsInfo[3] += tmpInfo.fromBailPaid;
                            platformBailPoolMap[csInfo.addrInfo[0]].amount -= tmpInfo.fromBailPaid;
                            emit PayFromPlatformBail(projectId, tmpInfo.fromBailPaid, platformBailPoolMap[csInfo.addrInfo[0]].amount);
                        }else{
                            emit DistributeNothing(projectId, users[i], tmpInfo.interest, tmpInfo.fee, 2);
                            return;
                        }
                    }
                    if(tmpInfo.interestPaid > 0){
                        csInfo.poolAmount[1] -= tmpInfo.interestPaid;
                    }
                    ivInfo.interestDistCnt += 1;
                    ivInfo.interestDistAmt += tmpInfo.itAmount;
                    csInfo.poolAmount[4] += tmpInfo.fee;
                    csInfo.amountsInfo[2] += tmpInfo.interest;
                    if(tmpInfo.itAmount > 0){
                        transferToken(csInfo.addrInfo[0],users[i],tmpInfo.itAmount);
                    }
                    emit DistributeInterest(projectId, users[i], tmpInfo.itAmount, tmpInfo.fee, csInfo.poolAmount[1], csInfo.poolAmount[4], block.timestamp);
                }
            }
        }
    }
    
    function refund(string memory projectId, address[] memory users) onlyExecutor public nonReentrant {
        CrowdsaleInfo_i storage csInfo = crowdsaleInfoMap[projectId];
        csInfo.status  = CrowdsaleStatus.CrowdsaleEnd;
        for(uint256 i = 0;i < users.length; i++){
            uint256[] storage investIdxs = userInvestIdxMap[projectId][users[i]];
            for(uint256 j = 0; j < investIdxs.length; j++){
                InvestInfo storage ivInfo = csInfo.invests[investIdxs[j]];
                if(ivInfo.bRefund){
                    continue;
                }
                require(csInfo.poolAmount[3] >= ivInfo.amount, "Refund pool!");
                csInfo.poolAmount[3] -= ivInfo.amount;
                ivInfo.bRefund = true;
                transferToken(csInfo.addrInfo[0],users[i],ivInfo.amount);
                emit Refund(projectId, users[i], ivInfo.amount, csInfo.poolAmount[3], block.timestamp);
            }
        }
    }
    
    function getCrowdsaleInfo(string memory projectId) public view returns (CrowdsaleInfo memory info){
        CrowdsaleInfo_i storage csInfo = crowdsaleInfoMap[projectId];
        info.interestDistributed = csInfo.amountsInfo[2];
        info.investAmount = csInfo.amountsInfo[1];
        info.interestBorrowed = csInfo.amountsInfo[3];
        info.projectBailPool = csInfo.amountsInfo[0];
        info.interestPool = csInfo.poolAmount[1];
        info.crowdsalePool = csInfo.poolAmount[2];
        info.refundPool = csInfo.poolAmount[3];
        info.feePool = csInfo.poolAmount[4];
        info.status = uint8(csInfo.status);
        info.investorNumber = csInfo.amountsInfo[4];
    }
    
    function depositPlatformBail(BailInfo[] memory infos) public payable onlyExecutor nonReentrant {
        for(uint256 i = 0;i < infos.length; i++){
            if(infos[i].tokenAddr == ZERO_ADDRESS){
                require(msg.value >= infos[i].amount, "Not enough value!");
            }else{
                IERC20(infos[i].tokenAddr).safeTransferFrom(
                    msg.sender,
                    address(this),
                    infos[i].amount
                );
            }
            if(!platformBailPoolMap[infos[i].tokenAddr].bValid){
                platformBailPoolMap[infos[i].tokenAddr].bValid = true;
                platformBailTokenAddrs.push(infos[i].tokenAddr);
            }
            platformBailPoolMap[infos[i].tokenAddr].amount += infos[i].amount;
            emit DepositPlatformBail(msg.sender, infos[i].tokenAddr, infos[i].amount);
        }
    }
    
    function withdrawFee(string[] memory projectIds, address toAddr) public onlyExecutor nonReentrant {
        for(uint256 i = 0; i < projectIds.length; i++){
            CrowdsaleInfo_i storage csInfo = crowdsaleInfoMap[projectIds[i]];
            require(csInfo.bFlags[0], "ProjectId no valid!");
            transferToken(csInfo.addrInfo[0],toAddr,csInfo.poolAmount[4]);
            emit WithdrawFee(projectIds[i], csInfo.poolAmount[4], toAddr);
            csInfo.poolAmount[4] = 0;
        }
    }
    
    function withdrawPlatformBail(BailInfo[] memory infos, address toAddr) public  onlyExecutor nonReentrant{
        for(uint256 i = 0; i < infos.length; i++){
            require(platformBailPoolMap[infos[i].tokenAddr].amount >= infos[i].amount, "Amount!");
            platformBailPoolMap[infos[i].tokenAddr].amount -= infos[i].amount;
            transferToken(infos[i].tokenAddr,toAddr,infos[i].amount);
            emit WithdrawPlatformBail(infos[i].tokenAddr, infos[i].amount, toAddr);
        }
    }
    
    function transferProjectBail(string memory projectId, uint256 refundFee) public onlyExecutor nonReentrant {
        CrowdsaleInfo_i storage csInfo = crowdsaleInfoMap[projectId];
        require(csInfo.poolAmount[0] >= refundFee, "Amount!");
        csInfo.poolAmount[4] += refundFee;
        uint256 returnAmount = csInfo.poolAmount[0] - refundFee;
        transferToken(csInfo.addrInfo[0],csInfo.addrInfo[1],returnAmount);
        csInfo.poolAmount[0] = 0;
        emit TransferProjectBail(projectId, refundFee, csInfo.poolAmount[4], returnAmount);
    }
    
    function queryPlatformBail() public view returns(BailInfo[] memory infos) {
        uint256 cnt = platformBailTokenAddrs.length;
        infos = new BailInfo[](cnt);
        for(uint256 i = 0;i < cnt; i++){
            infos[i].tokenAddr = platformBailTokenAddrs[i];
            infos[i].amount = platformBailPoolMap[platformBailTokenAddrs[i]].amount;
        }
    }
	
	function queryPlatformBailByAddr(address tokenAddr) public view returns(BailInfo memory info){
    }
	
	function queryInterest(string memory projectId, uint256 interestType) public view returns(InterestInfo memory info){
    }
    
    function addExecutor(address _newExecutor) public onlyOwner {
        executorList[_newExecutor] = true;
        emit AddExecutor(_newExecutor);
    }
    
    function delExecutor(address _oldExecutor) public onlyOwner {
        executorList[_oldExecutor] = false;
        emit DelExecutor(_oldExecutor);
    }
}