// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
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
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import {StringUtils} from "../libraries/StringUtils.sol";
contract dustProtocol is Ownable{
    uint256 _userId; //用户注册Id
    uint256 pointId; //监察者Id
    uint256 _contentId; //事务Id

    address private thisOwner;
    
    //用户
    struct thisUser{
        uint256 userId;
        string userName;
        string userProfile;
        address userAdddress;
    }
    thisUser[] public _thisUser;

    constructor() payable{
        thisOwner = payable(msg.sender);
    }

    //注册
    function signUp(string memory _thisName,string memory _userProfile)internal{
        uint _userNameLength=StringUtils.strlen(_thisName);
        require(_userNameLength>=3 && _userNameLength<=20,"User name error!");
        _thisUser.push((thisUser(_userId,_thisName,_userProfile,msg.sender)));
        //用户ID+1
        _userId++;
    }

    //监察者
    struct supervisor{
        uint256 supervisorId;   //监察者Id
        uint256 voteWeight;     //监察者权重
        string supervisorName;  //监察者名字
        address supervisorAddress;  //监察者地址
    }
    supervisor[] public _supervisor;

    //添加审查者
    function addSupervisor(address waitAddress,string memory _supervisorName)internal{
        if(msg.sender==thisOwner){
            _supervisor.push(supervisor(pointId,5,_supervisorName,waitAddress));
        }
        else{
            _supervisor.push(supervisor(pointId,1,_supervisorName,waitAddress));
        }
        pointId++;
    }

    //事务
    struct contentThing{
        uint256 contentId;        //事务Id
        string contentName;       //事务名称  
        string contentWillThing;  //将要执行的委托内容
        uint256 tradeMoney;       //交易金额
        uint256 startTime;        //开始时间
        uint256 endTime;          //结束时间
        address sourceAddress;    //发起者
        address pointAddress;     //指定者
        bool sendContentWhether;      //发起者确认事务是否开始
        bool receiverContentWhether;   //接收者确认事务是否进行
        uint256 votedSum; //审查者或者监察者已经投的总数
    }
    contentThing[] public _waitContentThing;

    //用户创建事务
    function createThing(string memory _contentName,string memory _willThing,uint256 _tradeMoney,uint256 _endTime,address _pointAddress)internal{
        require(_pointAddress!=msg.sender && _pointAddress!=address(0),"Point address error!");
        uint _thisContentName=StringUtils.strlen(_contentName);
        require(_thisContentName>=3 && _thisContentName<=100,"Content name error!");

        //结束时间
        uint256 getEndTime=_endTime+block.timestamp;
        //转账金额
        uint256 transferMoney=_tradeMoney*10**17;
        //将事务信息推送
        _waitContentThing.push(
            contentThing({
            contentId:_contentId,
            contentName:_contentName,
            contentWillThing:_willThing,
            tradeMoney:transferMoney,
            startTime:block.timestamp,
            endTime:getEndTime,
            sourceAddress:msg.sender,
            pointAddress:_pointAddress,
            sendContentWhether:false,
            receiverContentWhether:true,
            votedSum:0}));
        _contentId++;
    }


}

//SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;
import "./Dust.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
contract timeFlow is dustProtocol{
    //合约地址：0x4AA72d9B7A2C61C7bC87D6fd8a95Ca4f2619C746
    using SafeERC20 for IERC20;
    //测试token
    address private dustToken=0xd9145CCE52D386f254917e481eB44e9943F39138;
    IERC20 private targetTokenContract = IERC20(dustToken);

    //用户
    mapping(address=>bool)private _thisAddressBool; //用户是否注册
    mapping(string=>bool)private _thisUserNameBool; //用户名是否注册
    mapping(string=>address)private nameToAddress;
    mapping(address=>uint256)private userAddressToId;
    mapping(uint256=>string)private userIdToName;
    //审查者
    mapping(address=>bool)private addressToBool;
    //role
    mapping(address=>bool) private addressToRole;
    //事务
    mapping(string=>uint256)private contentNameToId;
    mapping(uint256=>address)private contentIdToAddress;
    mapping(string=>bool)private contentNameToBool;

    //发送者证据记录.
    mapping(string=>string)public senderRecord;
    //交易指定者证据记录
    mapping(string=>string)public pointRecord;

    //审核者是否对某一事件投票
    struct supervisorIfVoted{
        uint256 votedContentId;  //等于事务Id
        address[] voteGroup;     //已经投票的地址          
        address contentSource;   //事务发起者
    }
    supervisorIfVoted[] public _supervisorIfVoted;

    //事务者对一事件已投票的证明
    mapping(address=>mapping(uint256=>bool))public supervisorVoteProof;
    
    
    //注册
    function registerDid(string memory _thisName,string memory _userProfile)public payable{
        require(_thisAddressBool[msg.sender]!=true,"This address had register!");
        require(_thisUserNameBool[_thisName]!=true,"This user name register!");
        _thisAddressBool[msg.sender]=true;  
        nameToAddress[_thisName]=msg.sender;
        userAddressToId[msg.sender]=_userId;
        userIdToName[_userId]=_thisName;
        signUp(_thisName,_userProfile);
    }

    //添加审查者
    function addSupervisors(address waitAddress,string memory _supervisorName)public onlyOwner{
        require(_thisAddressBool[waitAddress]==true,"This address not register!");
        require(addressToBool[waitAddress]!=true,"This address was a Supervisor!");
        addressToBool[waitAddress]=true;//是否已经为审查者
        addressToRole[waitAddress]=true;//为用户添加role的bool
        addSupervisor(waitAddress,_supervisorName);
    }

    //移除审查者
    function deleteSupervisors(address waitAddress)public onlyOwner{
        require(addressToBool[waitAddress]==true,"This address not a Supervisor!");
        addressToRole[waitAddress]=false;
        //将地址role转移到黑洞地址
        delete addressToRole[waitAddress];
    }

    //创建事务
    function createSomething(string memory _contentName,string memory _willThing,uint256 _tradeMoney,uint256 _endTime,address _pointAddress)public{
        require(_thisAddressBool[msg.sender]==true,"This address not register!");
        require(contentNameToBool[_contentName]!=true,"This contentName already existed!");
        address[] memory ballot;
        contentNameToId[_contentName]=_contentId;   //根据事务名字，得到Id
        contentIdToAddress[_contentId]=msg.sender;
        contentNameToBool[_contentName]=true;       //确定事务名字是否注册
        createThing(_contentName,_willThing,_tradeMoney,_endTime,_pointAddress);
        _supervisorIfVoted.push(supervisorIfVoted(_contentId,ballot,msg.sender));
    }

    //用户名字返回地址
    function userNameToAddress(string calldata name)public view returns(address){
        return nameToAddress[name];
    }

    //用户地址返回Id
    function addressToUserId(address userAddress)public view returns(uint256){
        return userAddressToId[userAddress];
    }

    //用户Id返回名字
    function userIdToUserName(uint256 thisUserId)public view returns(string memory){
        return userIdToName[thisUserId];
    }

    //事务名字返回Id
    function contentNameToContentId(string memory name)public view returns(uint256){
        return contentNameToId[name];
    }

    //事务Id返回地址
    function contentIdToContentAddress(uint256 contentId)public view returns(address){
        return contentIdToAddress[contentId];
    }

    //审核者对事务投票
    function voteContent(string memory contentName)public payable{
        //根据输入的name查找相应id
        uint256 getVotedId=contentNameToContentId(contentName);
        //是否是审查者
        require(addressToBool[msg.sender]==true,"This address not a Supervisor!");
        //判断地址是否投票
        require(supervisorVoteProof[msg.sender][getVotedId]!=true,"You already voted!");
        supervisorVoteProof[msg.sender][getVotedId]=true;
        //票数增加
        _waitContentThing[contentNameToContentId(contentName)].votedSum++;
        
        //将消息发送者地址push到数组里
        // address[] storage voteBallet=_supervisorIfVoted[getVotedId].voteGroup;
        // voteBallet.push(msg.sender);
        // if(voteBallet.length==2){
        //     require(voteBallet[0]!=voteBallet[1],"You've already voted!");
        // }
        // if(voteBallet.length==3){
        //     require(voteBallet[0]!=voteBallet[1]&&voteBallet[0]!=voteBallet[2]&&voteBallet[1]!=voteBallet[2],"You've already voted!");
        // }
        // if(voteBallet.length==4){
        //     require(voteBallet[0]!=voteBallet[1]&&voteBallet[0]!=voteBallet[2]&&voteBallet[1]!=voteBallet[2]&&voteBallet[0]!=voteBallet[3]&&voteBallet[1]!=voteBallet[3]&&voteBallet[2]!=voteBallet[3],"You've already voted!");
        // }
        // if(voteBallet.length==5){
        //     require(voteBallet[0]!=voteBallet[1]&&voteBallet[0]!=voteBallet[2]&&voteBallet[1]!=voteBallet[2]&&voteBallet[0]!=voteBallet[3]&&voteBallet[1]!=voteBallet[3]&&voteBallet[2]!=voteBallet[3]&&voteBallet[0]!=voteBallet[4]&&voteBallet[1]!=voteBallet[4]&&voteBallet[2]!=voteBallet[4]&&voteBallet[3]!=voteBallet[4],"You've already voted!");
        // }
    }

    //当票数大于等于4的时候执行时间锁
    function doTimeLock(string memory contentName)internal view returns(bool){
        uint256 totalVotes = _waitContentThing[contentNameToContentId(contentName)].votedSum;  //相应事务的总票数
        if(totalVotes>=1){
            return true;
        }else{
            return false;
        }
    }

    //发起者是否确定要发起该事务
    function judgeSendContent(bool _thisContent,string memory contentName)public{
        address getSenderAddress=_waitContentThing[contentNameToContentId(contentName)].sourceAddress;
        require(getSenderAddress==msg.sender,"You are not the initiator of the transaction!");
        _waitContentThing[contentNameToContentId(contentName)].sendContentWhether=_thisContent;  
    }

    //接收者是否确定进行该事务
    function judgeReceiverContent(bool _thisContent,string memory contentName)public{
        address getPointAddress=_waitContentThing[contentNameToContentId(contentName)].pointAddress;
        require(getPointAddress==msg.sender,"You are not the initiator of the transaction!");
        _waitContentThing[contentNameToContentId(contentName)].receiverContentWhether=_thisContent; 
    }

    //dustToken合约授权

    //dustToken合约转账
    function contractTransfer(uint256 amount)public payable{
        targetTokenContract.safeTransferFrom(msg.sender,address(this),amount);
    }

    //根据交易金额计算收取的费用
    function calculate(string memory contentName)internal view returns(uint256 cost){
        uint256 getTradeMoney=_waitContentThing[contentNameToContentId(contentName)].tradeMoney;
        uint256 number=10*17;
        if(getTradeMoney>=100*number && getTradeMoney<500*number){
            return getTradeMoney/40;   //2.5%
        }else if(getTradeMoney>=500*number && getTradeMoney<1000*number){
            return getTradeMoney/50;   //2%
        }else if(getTradeMoney>=1000*number && getTradeMoney<=10000*number){
            return getTradeMoney/55;   //1.81%
        }else if(getTradeMoney>10000*number){
            return getTradeMoney/80;   //1.25%
        }else{
            revert("getTradeMoney error!");
        }
    }

    //执行相应token时间锁
    function doWork(string memory contentName)public payable{
        require(_waitContentThing[contentNameToContentId(contentName)].sourceAddress==msg.sender,"You are not the initiator of the transaction!");//发起者是否为事务发起者
        require(doTimeLock(contentName),"Not enough votes, transaction fails!");//票数
        require(_waitContentThing[contentNameToContentId(contentName)].sendContentWhether,"The sender rejects the transaction!");//发起者确认
        //require(_waitContentThing[contentNameToContentId(contentName)].receiverContentWhether,"The sender rejects the transaction!");  //接收者确认
        require(block.timestamp>=_waitContentThing[contentNameToContentId(contentName)].endTime,"The transaction cannot be sent until the time node is reached!");//结束时间
        //支付协议费用
        targetTokenContract.safeTransferFrom(msg.sender,address(this),calculate(contentName));
        //发起交易
        targetTokenContract.safeTransferFrom(msg.sender,_waitContentThing[contentNameToContentId(contentName)].pointAddress,_waitContentThing[contentNameToContentId(contentName)].tradeMoney);
    }

    //发起者复议证据提交
    function senderProof(string calldata contentName,string calldata sendProofThing)public{
        require(_waitContentThing[contentNameToContentId(contentName)].sourceAddress==msg.sender,"Ypu are not this content owner!");
        senderRecord[contentName]=sendProofThing;
    }
    //得到发起者证据
    function getSenderProof(string calldata contentName)public view returns(string memory){
        return senderRecord[contentName];
    }

    //指定者复议证据提交
    function pointProof(string calldata contentName,string calldata pointProofThing)public{
        require(_waitContentThing[contentNameToContentId(contentName)].pointAddress==msg.sender,"Ypu are not this point owner!");
        pointRecord[contentName]=pointProofThing;
    }
    //得到指定者证据
    function getPointProof(string calldata contentName)public view returns(string memory){
        return pointRecord[contentName];
    }

    //查找合约余额
    function checkBalance()public view returns(uint256){
        return address(this).balance;
    }

    //部署者提取合约money
    function withdraw()external onlyOwner{
        uint256 contractBalance=address(this).balance;
        require(contractBalance>0,"Contract not money!");
        (bool success, )=msg.sender.call{value: contractBalance}("");
        require(success,"Withdraw error!");
    }

}

// SPDX-License-Identifier: MIT
// Source:
// https://github.com/ensdomains/ens-contracts/blob/master/contracts/ethregistrar/StringUtils.sol
pragma solidity >=0.6.8;

library StringUtils {
    /**
     * @dev Returns the length of a given string
     *
     * @param s The string to measure the length of
     * @return The length of the input string
     */
    function strlen(string memory s) internal pure returns (uint) {
        uint len;
        uint i = 0;
        uint bytelength = bytes(s).length;
        for(len = 0; i < bytelength; len++) {
            bytes1 b = bytes(s)[i];
            if(b < 0x80) {
                i += 1;
            } else if (b < 0xE0) {
                i += 2;
            } else if (b < 0xF0) {
                i += 3;
            } else if (b < 0xF8) {
                i += 4;
            } else if (b < 0xFC) {
                i += 5;
            } else {
                i += 6;
            }
        }
        return len;
    }
}