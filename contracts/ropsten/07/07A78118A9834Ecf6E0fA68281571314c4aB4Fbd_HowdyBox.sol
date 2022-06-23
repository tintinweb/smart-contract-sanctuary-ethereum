/**
 *Submitted for verification at Etherscan.io on 2022-06-23
*/

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
     * by making the `nonReentrant` function external, and making it call a
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

// File: @openzeppelin/contracts/utils/Counters.sol


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: h.sol


pragma solidity ^0.8.4;






/** @title HowdyBox is a contract for managing P2P messaging services. 
* @author srvsmn
*/
contract HowdyBox is ReentrancyGuard, Ownable {

    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;

    IERC20 stableCoin ;
    uint nativeAntiSpamFee;
    uint stableAntiSpamFee;
    uint public serviceCharge;
    address payable public wallet;

    mapping(address => uint[]) private senders ;

    mapping(address => uint[]) private receipients ;

    // mapping(sender_address => mapping(receiver_address => boolean))
    mapping(address => mapping(address => bool)) private isSpam ;

    mapping(address => mapping(address => uint[])) private msgHistory ;

    mapping(address => mapping(address => bool)) public inConversation;

    Counters.Counter private _msgID;

    struct MsgInfo{
        address sender;
        address receiver;
        uint amount;
        uint deadline;
        uint version;
        uint createdAt;
        string msgHash;
        uint msgID;
        bool isNativeAntispamFee;
        bool isRead;
    }

    struct returnType{
                address sender;
                address receiver;
                uint amount;
                uint deadline;
                uint createdAt;
                bool isNativeAntispamFee;
            } 

    
    mapping(uint => MsgInfo) private createdMsgs;

    event emitHash(string hash);

    constructor(address _stableCoin, uint _nativeAntiSpamFee, uint _stableAntiSpamFee, uint _serviceCharge, address payable _wallet) {
        stableCoin = IERC20(_stableCoin);
        nativeAntiSpamFee = _nativeAntiSpamFee;
        stableAntiSpamFee = _stableAntiSpamFee;
        serviceCharge = _serviceCharge;
        wallet = _wallet;
    }

    /**
     * @dev send message to the receipient
     * @param _amount Antispam fee
     * @param _msgHash Hash of the message
     * @param _deadline Number of seconds after which the message should expire eg. 3600 for 1 hr
     * @param _receipient address of individual to whome message should be sent
     * @param _isNativeAntispamFee The antispam fee provided is in stable coin or native token. eg. true for eth and false for USDT
     * @param _version Version of encryption
     *
     */


    function sendMsg(uint _amount,string memory _msgHash, uint _deadline, address _receipient, bool _isNativeAntispamFee, uint _version ) public nonReentrant payable {
        
        (address addr0, address addr1) = msg.sender < _receipient ? (msg.sender, _receipient) : (_receipient, msg.sender);
        
        if(!inConversation[addr0][addr1]){
        
        if(_isNativeAntispamFee){
             require(msg.value >= nativeAntiSpamFee, 'Please provide antispam fee in native token to send msg');
        }else {
            require(_amount >= stableAntiSpamFee, 'Please provide antispam fee in stable coin to send msg');
        }

        }
        require(_receipient != address(0),'Message can not be sent to 0 address');
        require(msg.sender != _receipient, 'sender and receiver should br different');
        
        _msgID.increment();
        uint currentMsgID = _msgID.current();

        MsgInfo memory msgI = MsgInfo({
            sender: msg.sender,
            receiver: _receipient,
            amount: _amount,
            deadline: _deadline,
            version: _version,
            createdAt: block.timestamp,
            msgHash: _msgHash,
            msgID: currentMsgID,
            isNativeAntispamFee: _isNativeAntispamFee,
            isRead: false
        });
      //  uint[] storage d = senders[msg.sender];
       senders[msg.sender].push(currentMsgID);
       receipients[_receipient].push(currentMsgID);


        createdMsgs[currentMsgID] = msgI;

        if(!_isNativeAntispamFee){
            SafeERC20.safeTransferFrom(stableCoin,msg.sender,address(this),_amount);
        }
        
    }

    /**
     * @dev called by the recepient to read the message before the deadline is reached
     * Note: This function emits the event which contains the message hash
     * @param _id Message Id
     * @return message_hash return the message hash
     *
     */


    function readMsg(uint _id) public nonReentrant returns(string memory message_hash) {
        MsgInfo memory response = createdMsgs[_id];
        require(response.sender != address(0), 'Message at this id does not exist');
        require(response.receiver == msg.sender,'You can only read your message');

        if(!response.isRead){
             require(response.createdAt+response.deadline >= block.timestamp,'You can not read this message, as it has expired'); 
        }

        if(!response.isRead) {
            removeElement(response.sender, msg.sender, _id);

            (address addr0, address addr1) = response.sender < response.receiver ? (response.sender, response.receiver) : (response.receiver, response.sender);
            msgHistory[addr0][addr1].push(_id);

            createdMsgs[_id].isRead = true;

            if(response.amount > 0){
                uint charge = (response.amount * serviceCharge)/10000;
                if(response.isNativeAntispamFee){
                    wallet.transfer(charge);
                    payable(response.receiver).transfer(response.amount - charge);

                }else{
                        SafeERC20.safeTransfer(stableCoin, msg.sender, response.amount - charge);
                        SafeERC20.safeTransfer(stableCoin, wallet, charge);
                }
            
            }

        }
        
        //createdMsgs[_id] = createdMsgs[0];

        emit emitHash(response.msgHash);
        return response.msgHash;
    }

    /**
     * @dev To revert the sent message
      * Note: once the message is read it can not be reverted. This revert function can only be called by the sender of the message
     * @param _id Message id
     */


    function revertMsg(uint _id) public nonReentrant {
        MsgInfo memory response = createdMsgs[_id];

        require(response.sender != address(0), 'Message at this id does not exist');
        require(response.sender == msg.sender,'You can only revert your sent message');
        require(!response.isRead,'Viewed Message can not be reverted');

        removeElement(msg.sender, response.receiver, _id);

        // send money back based based on isNativespmafee
        //TODO

        if(response.isNativeAntispamFee){
            payable(response.receiver).transfer(response.amount);
        }else{
            SafeERC20.safeTransfer(stableCoin, msg.sender, response.amount);
        }
        
        createdMsgs[_id] = createdMsgs[0];

    }



    function removeElement(address _sender, address _receipient, uint _element) internal {
        int senderIndex = findIndex(_element, senders[_sender]);
        require(senderIndex >= 0,'You do not have this message in your sending array');
        removeElementfromSender(_sender, uint(senderIndex));

        int receipientIndex = findIndex(_element, receipients[_receipient]);
        require(receipientIndex >= 0,'You do not have this message in your receiving array');
        removeElementfromReceiver(_receipient, uint(receipientIndex));
    }

    function findIndex(uint element, uint[] memory arr) pure internal returns(int){
        uint len = arr.length;

        for(uint i = 0; i< len; i++){
            if(arr[i] == element)
                return int(i);
        }
        return -1;
    }

    function removeElementfromSender(address _sender, uint _index) internal {
        uint len = senders[_sender].length;
        senders[_sender][_index] = senders[_sender][len -1];
        senders[_sender].pop(); 
    }

    function removeElementfromReceiver(address _receipient, uint _index) internal {
        uint len = receipients[_receipient].length;
        receipients[_receipient][_index] = receipients[_receipient][len -1];
        receipients[_receipient].pop(); 
    }

    // having a conversation backup 

    /**
     * @dev To report a address as spammer
     * @param _spammer spammer address
     * @param _status send true to mark the address as spammer and vice versa
     */

    function reportSpamming(address _spammer, bool _status) public {
        isSpam[_spammer][msg.sender] = _status ;
    }

    /**
     * @dev check the spamming status
     * @param _sender spammer address
     * @param _receipient recipient of the spamming messages
     * @return spammingStatus status 
     */

    function isSpamming(address _sender, address _receipient) public view returns(bool spammingStatus){
        return isSpam[_sender][_receipient];
    }

    /**
     * @dev get all the read msg id's between the sender and the receiver 
     * @param _sender message sender address
     * @param _receipient message receiver address
     * @return readMsgIDS array of Message ID's 
     */

    function msgHistories(address _sender, address _receipient) public view returns(uint[] memory readMsgIDS){
        (address addr0, address addr1) = _sender < _receipient ? (_sender, _receipient) : (_receipient, _sender);

        return msgHistory[addr0][addr1] ;

    }

    /**
     * @dev To get the metadata of the message 
     * @param _id message ID
     * @return msgSender Message sender address
     * @return msgReceiver Message receiver address 
     * @return antispamFee amount given as fee
     * @return deadline total number of seconds after which message will expire once msg is created
     * @return createdAt Timestamp at which message is creted
     * @return AntispamFeeType True if fee is paid in native token(BNB,Eth) and false if fee is paid in stable coin
     */
     

     function msgMetaData(uint _id) public view returns(address msgSender,address msgReceiver ,uint antispamFee,uint deadline,uint createdAt,bool AntispamFeeType){
         MsgInfo memory response = createdMsgs[_id];
         return(response.sender, response.receiver, response.amount, response.deadline, response.createdAt,response.isNativeAntispamFee);

     }

     /**
     * @dev To get the metadata of the message 
     * Note: the object contains: sender, receiver, amount, deadline, createdAt, isNativeAntispamFee
     * @param _ids arrays of message ids
     * @return messageMetadata It is a object that contains array of objects(message metadata object)
     */

     function msgMetaDatas(uint[] memory _ids) public view returns(returnType[] memory messageMetadata){ 

         returnType[] memory history =  new returnType[](_ids.length);

         for(uint i=0; i< _ids.length; i++){
             (address _sender,address _receiver,uint _amount,uint _deadline,uint _createdAt,bool _isNativeAntispamFee) = msgMetaData(_ids[i]);
             returnType memory temp = returnType({
                 sender: _sender,
                 receiver: _receiver,
                 amount: _amount,
                 deadline: _deadline,
                 createdAt: _createdAt,
                 isNativeAntispamFee: _isNativeAntispamFee

             });
             history[i] = temp;

         }

         return history;
     }

     /**
     * @dev Once the message is received to the receipient and if they are intrested to start a conversation they the call this function. Once this function is called no antispam fee required to send the message 
    * Note: only the recepient of the message can start the conversatioin , the message id passed in the argument should not be a read message 
     * @param _id Message id
     */

     function startConversation(uint _id) public {
         MsgInfo memory response = createdMsgs[_id];

         require(response.receiver == msg.sender, 'Only the receipient can start the conversation');
         require(!response.isRead, 'once the msg is read can not start the conversation');
         (address addr0, address addr1) = response.sender < response.receiver ? (response.sender, response.receiver) : (response.receiver, response.sender);

         inConversation[addr0][addr1] = true;
         
     }
    /**
     * @dev Once the conversation is marked as end conversation then every time the message is sent you sender will have to pay the fee
     * Note: sender or receipient anyone can call the function, message Id passed can be read or unread
     * @param _id Message id
     */

     function endConversation(uint _id) public {
         MsgInfo memory response = createdMsgs[_id];

         require(response.sender == msg.sender || response.receiver == msg.sender, 'only the sender and receiver can end the conversation');
         (address addr0, address addr1) = response.sender < response.receiver ? (response.sender, response.receiver) : (response.receiver, response.sender);
         inConversation[addr0][addr1] = false;
     }

    /**
     * @dev return all the message id sent by the sender and which is yet not read
     * @param _sender sender address
     * @return messageIDs array of message id
     * Note: If the recepient has read the message , the message id is removed 
     */

     function sentMsgs(address _sender) public view returns(uint[] memory messageIDs){
         return senders[_sender];
     }

     /**
     * @dev return all the message id received by the receipient and which is yet not read
     * Note: If the recepient has read the message , the message id is removed 
     * @param _receipient receiver's address
     * @return messageIDs array of message id
     */

     function receivedMsgs(address _receipient) public view returns (uint[] memory messageIDs){
         return receipients[_receipient];
     }

     function totalMsgCount() public view returns(uint){
         return _msgID.current();
     }

     /**
     * @dev To set the minimum amount of antispam fee needed to be provided
     * Note: Only the contract admin can call this 
     * @param _nativeAntiSpamFee Antispam Fee to be provided in native token
     * @param _stableAntiSpamFee Antispam Fee to be provided in stable token
     */

     function setAntispamFee(uint _nativeAntiSpamFee, uint _stableAntiSpamFee) public onlyOwner {
        nativeAntiSpamFee = _nativeAntiSpamFee;
        stableAntiSpamFee = _stableAntiSpamFee;
    }

    /**
     * @dev To set the minimum amount of antispam fee needs to be provided
     * @return nativeAntispamFee Antispam Fee to be provided in native token
     * @return stableAntispamFee Antispam Fee to be provided in stable token
     */

    function getAntispamFee() public view returns(uint nativeAntispamFee , uint stableAntispamFee){
         return(nativeAntiSpamFee, stableAntiSpamFee);
     }

    /**
     * @dev To set the service charge deducted by contract 
     * @param _serviceCharge send the service charge percent (ie. if service charge is 5% then send 500)
     */

     function setServiceCharge(uint _serviceCharge) public onlyOwner{
         require(_serviceCharge < 10000,"service charge should be less than 100 percent");
         serviceCharge = _serviceCharge;
     }

     /**
     * @dev To set the wallet address which will receive the service charge fee 
     * @param _wallet wallet address
     */

     function setWallet(address payable _wallet) public onlyOwner{
         wallet = _wallet;
     }
}

/* 
1. using safe maths - done
2. allow native tokens - done
3. cut comission on transaction - done
4. add the conversation start thing - done
5. using ownable - done
6. balanceOf - new
*/