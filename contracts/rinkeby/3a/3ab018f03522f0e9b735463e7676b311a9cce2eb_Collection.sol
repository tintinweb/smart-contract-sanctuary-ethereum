/**
 *Submitted for verification at Etherscan.io on 2022-05-25
*/

pragma solidity 0.8.6;



// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)



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



contract CFORole is Context {
    address private _cfo;

    event CFOTransferred(address indexed previousCFO, address indexed newCFO);

    constructor () {
        _transferCFOship(_msgSender());
        emit CFOTransferred(address(0), _msgSender());
    }

    function cfo() public view returns (address) {
        return _cfo;
    }

    modifier onlyCFO() {
        require(isCFO(), "CFOable: caller is not the CFO");
        _;
    }

    function isCFO() public view returns (bool) {
        return _msgSender() == _cfo;
    }

    function renounceCFOship() public onlyCFO {
        emit CFOTransferred(_cfo, address(0));
        _cfo = address(0);
    }

    function transferCFOship(address newCFO) public onlyCFO {
        _transferCFOship(newCFO);
    }

    function _transferCFOship(address newCFO) internal {
        require(newCFO != address(0), "Ownable: new cfo is the zero address");
        emit CFOTransferred(_cfo, newCFO);
        _cfo = newCFO;
    }
}





contract OperatorRole is Context {
    address private _Operator;

    event OperatorTransferred(address indexed previousOperator, address indexed newOperator);

    constructor () {
        _transferOperatorship(_msgSender());
        emit OperatorTransferred(address(0), _msgSender());
    }

    function Operator() public view returns (address) {
        return _Operator;
    }

    modifier onlyOperator() {
        require(isOperator(), "Operatorable: caller is not the Operator");
        _;
    }

    function isOperator() public view returns (bool) {
        return _msgSender() == _Operator;
    }

    function renounceOperatorship() public onlyOperator {
        emit OperatorTransferred(_Operator, address(0));
        _Operator = address(0);
    }

    function transferOperatorship(address newOperator) public onlyOperator {
        _transferOperatorship(newOperator);
    }

    function _transferOperatorship(address newOperator) internal {
        require(newOperator != address(0), "Ownable: new Operator is the zero address");
        emit OperatorTransferred(_Operator, newOperator);
        _Operator = newOperator;
    }
}




// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)





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


contract VerifySignature is Ownable {

    address public  signaturer;

    constructor() {
        signaturer = msg.sender;
    }

    function changeSignaturer(address value) public onlyOwner {
        signaturer = value;
    }

    function getMessageHash(address owner, address contract_addr, address to, uint _nonce) public pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(owner, contract_addr, to, _nonce));
    }

    function getMessageHash2(address owner, address contract_addr, address to, uint256 tokenId, uint256 genes, uint _nonce) public pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(owner, contract_addr, to, tokenId, genes, _nonce));
    }


    function getEthSignedMessageHash(bytes32 _messageHash) public pure returns (bytes32)
    {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }

    function verify(address to, uint _nonce, bytes memory signature) public view returns (bool)
    {
        bytes32 messageHash = getMessageHash(signaturer, address(this), to, _nonce);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return recoverSigner(ethSignedMessageHash, signature) == signaturer;
    }

    function verify2(address to, uint256 tokenId, uint256 genes, uint _nonce, bytes memory signature) public view returns (bool)
    {
        bytes32 messageHash = getMessageHash2(signaturer, address(this), to, tokenId, genes, _nonce);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return recoverSigner(ethSignedMessageHash, signature) == signaturer;
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) public pure returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig) public pure returns (bytes32 r, bytes32 s, uint8 v)
    {
        require(sig.length == 65, "invalid signature length");
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

}

// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)



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


// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)



// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
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



contract Collection is CFORole, OperatorRole, VerifySignature {
    using Address for address payable;
    using SafeMath for uint256;

    struct Event {
        uint256 event_id;
        uint256 price;
        string name;
        string event_type;
        bool start;
        uint256 total_supply;
        uint256 per_limit;
        uint256 supplied;
        mapping(address => uint256) buy_his_count;
        uint256 amount;
    }

    mapping (uint256 => Event) events;
    mapping (uint256 => bool) eventIdMap;
    uint256[] eventIds;

    event OpenEvent(uint256 eventId, uint256 price, string event_type, string name, uint256 total_supply, uint256 per_limit, address setter);
    event ReopenEvent(uint256 eventId, address setter);
    event CloseEvent(uint256 eventId, address setter);
    event Pay(uint256 eventId, uint256 price, uint256 num, string event_type, address payer);
    event ChangeEventProperty(uint256 eventId, string prop, uint256 from, uint256 to);
    event ChangeEventPropertyStr(uint256 eventId, string prop, string from, string to);

    /**
     * eventId is the index of sale event
     * price could be a number bte 0. If 0, it means free
     * name of sale event, connot be empty
     * total_supply defined that max supply of the event
     * per_limit defined that the limit everyone could buy
     */
    function startEvent(uint256 eventId, uint256 price, string memory event_type, string memory name, uint256 total_supply, uint256 per_limit) public onlyOperator {
        require(!_checkIsEventExist(eventId), 'event already exist');
        require(bytes(name).length > 0, 'event name connot be empty');

        events[eventId].event_id = eventId;
        events[eventId].price = price;
        events[eventId].event_type = event_type;
        events[eventId].name = name;
        events[eventId].total_supply = total_supply;
        events[eventId].per_limit = per_limit;
        events[eventId].start = true;

        eventIdMap[eventId] = true;
        eventIds.push(eventId);
        emit OpenEvent(eventId, price, event_type, name, total_supply, per_limit, _msgSender());
    }

    /**
     * restart a closed event
     */
    function restartEvent(uint256 eventId) public onlyOperator {
        require(_checkIsEventExist(eventId), 'event did not exist');
        require(!_checkIsEventDuring(eventId), 'event is during now');
        events[eventId].start = true;
        emit ReopenEvent(eventId, _msgSender());
    }

    function endEvent(uint256 eventId) public onlyOperator {
        require(_checkIsEventExist(eventId), 'event did not exist');
        require(_checkIsEventDuring(eventId), 'event has already closed');
        events[eventId].start = false;
        emit CloseEvent(eventId, _msgSender());
    }

    function setEventPrice(uint256 eventId, uint256 newPrice) public onlyOperator {
        require(_checkIsEventExist(eventId), 'event did not exist');
        require(!_checkIsEventDuring(eventId), 'event is during now');
        uint256 oldPrice = events[eventId].price;
        events[eventId].price = newPrice;
        emit ChangeEventProperty(eventId, 'price', oldPrice, newPrice);
    }

    function setEventType(uint256 eventId, string memory newType) public onlyOperator {
        require(_checkIsEventExist(eventId), 'event did not exist');
        require(!_checkIsEventDuring(eventId), 'event is during now');
        string memory oldType = events[eventId].event_type;
        events[eventId].event_type = newType;
        emit ChangeEventPropertyStr(eventId, 'event_type', oldType, newType);
    }

    function setTotalSupply(uint256 eventId, uint256 newTotalSupply) public onlyOperator {
        require(_checkIsEventExist(eventId), 'event did not exist');
        require(!_checkIsEventDuring(eventId), 'event is during now');
        uint256 oldTotalSupply = events[eventId].total_supply;
        events[eventId].total_supply = newTotalSupply;
        emit ChangeEventProperty(eventId, 'total_supply', oldTotalSupply, newTotalSupply);
    }
    
    function setTotalPerLimit(uint256 eventId, uint256 newPerLimit) public onlyOperator {
        require(_checkIsEventExist(eventId), 'event did not exist');
        require(!_checkIsEventDuring(eventId), 'event is during now');
        uint256 oldPerLimit = events[eventId].per_limit;
        events[eventId].per_limit = newPerLimit;
        emit ChangeEventProperty(eventId, 'per_limit', oldPerLimit, newPerLimit);
    }



    function pay(uint256 eventId, uint256 num, uint nonce, bytes memory signature) public payable {
        require(verify2(_msgSender(), eventId, num, nonce, signature), 'invalid signture');
        require(_checkIsEventExist(eventId), 'event did not exist');
        require(_checkIsEventDuring(eventId), 'event is during now');
        require(_checkIsEnoughSupply(eventId, num), 'Sold out');
        require(_checkIsUnderPerLimit(eventId, num), 'Purchase limit reached');

        events[eventId].supplied = events[eventId].supplied.add(num);
        events[eventId].buy_his_count[_msgSender()] = events[eventId].buy_his_count[_msgSender()].add(num);
        emit Pay(eventId, msg.value, num, events[eventId].event_type, _msgSender());
    }


    /**
     * wiehdraw all amount
     */
    function withdraw(address payable to) public onlyCFO {
        uint256 amount = address(this).balance;
        to.sendValue(amount);
    }

    /**
     * wiehdraw
     */
    function withdraw(address payable to, uint256 amount) public onlyCFO {
        to.sendValue(amount);
    }

    function getEventBalance(uint256 eventId) public onlyCFO view returns (uint256) {
        require(_checkIsEventExist(eventId), 'event did not exist');
        return events[eventId].amount;
    }

    function totalBalance() public view returns(uint256)  {
        return address(this).balance;
    }

    function getEventInfo(uint256 eventId) public view returns (uint256, string memory, string memory, bool, uint256, uint256, uint256) {
        require(_checkIsEventExist(eventId), 'event did not exist');
        return (
            events[eventId].price, 
            events[eventId].name, 
            events[eventId].event_type, 
            events[eventId].start, 
            events[eventId].total_supply, 
            events[eventId].supplied, 
            events[eventId].per_limit
        );
    }

    function getEventBuyCountOfAddress(uint256 eventId, address addr) public view returns (uint256) {
        require(_checkIsEventExist(eventId), 'event did not exist');

        return events[eventId].buy_his_count[addr];
    }

    /**
     * check whether the address exceeds the purchase limit
     */
    function getIsAddressOutOfEventBuyLimit(uint256 eventId, address addr) public view returns (bool) {
        require(_checkIsEventExist(eventId), 'event did not exist');
        if (events[eventId].per_limit == 0) {
            return true;
        }

        if (events[eventId].buy_his_count[addr] < events[eventId].per_limit) {
            return true;
        }

        return false;
    }

    function getAllEventIds() public view returns(uint256[] memory) {
        return eventIds;
    }


    function _checkIsEventExist(uint256 eventId) internal view returns (bool) {
        return eventIdMap[eventId];
    }

    function _checkIsEventDuring(uint256 eventId) internal view returns (bool) {
        return events[eventId].start;
    }


    function _checkIsEnoughSupply(uint256 eventId, uint256 num) internal view returns (bool) {
        if (num > 100) {
            return false;
        }
        return (events[eventId].total_supply == 0) || (events[eventId].total_supply >= events[eventId].supplied.add(num));
    }

    function _checkIsUnderPerLimit(uint256 eventId, uint256 num) internal view returns (bool) {
        if (num > 100) {
            return false;
        }
        return (events[eventId].per_limit == 0) || (events[eventId].per_limit >= events[eventId].buy_his_count[_msgSender()].add(num));
    }
    
}