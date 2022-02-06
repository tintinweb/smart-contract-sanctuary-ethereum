/**
 *Submitted for verification at Etherscan.io on 2022-02-06
*/

// File: localhost/SetExchange/common/StaticCaller.sol


pragma solidity ^0.8.3;

/**
 * @title StaticCaller
 * @author Wyvern Protocol Developers
 */
contract StaticCaller {

    function staticCall(address target, bytes memory data) internal view returns (bool result)
    {
        assembly {
            result := staticcall(gas(), target, add(data, 0x20), mload(data), mload(0x40), 0)
        }
        return result;
    }

    function staticCallUint(address target, bytes memory data) internal view returns (uint ret)
    {
        bool result;
        assembly {
            let size := 0x20
            let free := mload(0x40)
            result := staticcall(gas(), target, add(data, 0x20), mload(data), free, size)
            ret := mload(free)
        }
        require(result, "Static call failed");
        return ret;
    }

}

// File: localhost/SetExchange/@openzeppelin/contracts/token/ERC20/IERC20.sol



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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: localhost/SetExchange/common/TokenRecipient.sol


pragma solidity ^0.8.3;


contract TokenRecipient{
    event ReceivedEther(address indexed sender, uint amount);
    event ReceivedTokens(address indexed from, uint256 value, address indexed token, bytes extraData);

    function receiveApproval(address from, uint256 value, address token, bytes memory extraData) public {
        IERC20 t = IERC20(token);
        require(t.transferFrom(from, address(this), value), "ERC20 token transfer failed");
        emit ReceivedTokens(from, value, token, extraData);
    }
   
    fallback () payable external {
        emit ReceivedEther(msg.sender, msg.value);
    }
    receive () payable external {
        emit ReceivedEther(msg.sender, msg.value);
    }
}
// File: localhost/SetExchange/registry/proxy/OwnedUpgradeabilityStorage.sol


pragma solidity ^0.8.3;

contract OwnedUpgradeabilityStorage {

    address internal _implementation;
    address private _upgradeabilityOwner;
    
    function upgradeabilityOwner() public view returns (address) {
        return _upgradeabilityOwner;
    }

    function setUpgradeabilityOwner(address newUpgradeabilityOwner) internal {
        _upgradeabilityOwner = newUpgradeabilityOwner;
    }
}

// File: localhost/SetExchange/registry/proxy/Proxy.sol


pragma solidity ^0.8.3;


abstract contract Proxy {
  
    function implementation() virtual public view returns (address);
    function proxyType() virtual public pure returns (uint256 proxyTypeId);
    
    function _fallback() private{
        
        address _impl = implementation();
        require(_impl != address(0), "Proxy implementation required");

        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), _impl, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)

            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }
    
    
    fallback () payable external{
      _fallback();
    }
    
    receive() payable external{
        _fallback();
    }
    
}

// File: localhost/SetExchange/registry/proxy/OwnedUpgradeabilityProxy.sol


pragma solidity ^0.8.3;



contract OwnedUpgradeabilityProxy is Proxy, OwnedUpgradeabilityStorage {
    
    event ProxyOwnershipTransferred(address previousOwner, address newOwner);
    event Upgraded(address indexed implementation);
    
    function implementation() override public view returns (address) {
        return _implementation;
    }
   
    function proxyType() override public pure returns (uint256 proxyTypeId) {
        return 2;
    }
    
    function _upgradeTo(address implem) internal {
        require(_implementation != implem, "Proxy already uses this implementation");
        _implementation = implem;
        emit Upgraded(implem);
    }
    
    modifier onlyProxyOwner() {
        require(msg.sender == proxyOwner(), "Only the proxy owner can call this method");
        _;
    }
    
    function proxyOwner() public view returns (address) {
        return upgradeabilityOwner();
    }
   
    function transferProxyOwnership(address newOwner) public onlyProxyOwner {
        require(newOwner != address(0), "New owner cannot be the null address");
        emit ProxyOwnershipTransferred(proxyOwner(), newOwner);
        setUpgradeabilityOwner(newOwner);
    }
   
    //重点是下面的 
   
    function upgradeTo(address implem) public onlyProxyOwner {
        _upgradeTo(implem);
    }
   
    function upgradeToAndCall(address implem, bytes memory data) payable public onlyProxyOwner {
        upgradeTo(implem);
        (bool success,) = address(this).delegatecall(data);
        require(success, "Call failed after proxy upgrade");
    }
}

// File: localhost/SetExchange/registry/OwnableDelegateProxy.sol


pragma solidity ^0.8.3;


contract OwnableDelegateProxy is OwnedUpgradeabilityProxy {


    constructor(address owner, address initialImplementation, bytes memory data)  {
        setUpgradeabilityOwner(owner);
        _upgradeTo(initialImplementation);
        (bool success,) = initialImplementation.delegatecall(data);
        require(success, "OwnableDelegateProxy failed implementation");
    }
    

}
// File: localhost/SetExchange/registry/ProxyRegistryInterface.sol


pragma solidity ^0.8.3;


interface ProxyRegistryInterface {
    function delegateProxyImplementation() external returns (address);
    function proxies(address owner) external returns (OwnableDelegateProxy);
}

// File: localhost/SetExchange/@openzeppelin/contracts/utils/Context.sol



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

// File: localhost/SetExchange/@openzeppelin/contracts/access/Ownable.sol



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

// File: localhost/SetExchange/registry/ProxyRegistry.sol


pragma solidity ^0.8.3;




contract ProxyRegistry is Ownable, ProxyRegistryInterface {
    
    address public override delegateProxyImplementation;
    mapping(address => OwnableDelegateProxy) public override proxies;
    //Contracts pending access. 
    mapping(address => uint) public pending;
    //Contracts allowed to call those proxies. 
    mapping(address => bool) public contracts;
    uint public DELAY_PERIOD = 2 weeks;

    function startGrantAuthentication (address addr) public onlyOwner{
        require(!contracts[addr] && pending[addr] == 0, "Contract is already allowed in registry, or pending");
        pending[addr] = block.timestamp;
    }

    function endGrantAuthentication (address addr) public onlyOwner{
        require(!contracts[addr] && pending[addr] != 0 && ((pending[addr] + DELAY_PERIOD) < block.timestamp), "Contract is no longer pending or has already been approved by registry");
        pending[addr] = 0;
        contracts[addr] = true;
    }

    function revokeAuthentication (address addr) public onlyOwner{
        contracts[addr] = false;
    }
    
     function grantAuthentication (address addr) public onlyOwner{
        contracts[addr] = true;
    }
   
    function registerProxyOverride() public returns (OwnableDelegateProxy proxy){
        proxy = new OwnableDelegateProxy(msg.sender, delegateProxyImplementation, abi.encodeWithSignature("initialize(address,address)", msg.sender, address(this)));
        proxies[msg.sender] = proxy;
        return proxy;
    }
    
    function registerProxyFor(address user) public returns (OwnableDelegateProxy proxy){
        require(address(proxies[user]) == address(0), "User already has a proxy");
        proxy = new OwnableDelegateProxy(user, delegateProxyImplementation, abi.encodeWithSignature("initialize(address,address)", user, address(this)));
        proxies[user] = proxy;
        return proxy;
    }
    
     function registerProxy() public returns (OwnableDelegateProxy proxy){
        return registerProxyFor(msg.sender);
    }

    function transferAccessTo(address from, address to) public{
        OwnableDelegateProxy proxy = proxies[from];
        /* CHECKS */
        require(msg.sender == from, "Proxy transfer can only be called by the proxy");
        require(address(proxies[to]) == address(0), "Proxy transfer has existing proxy as destination");
        /* EFFECTS */
        delete proxies[from];
        proxies[to] = proxy;
    }

}
// File: localhost/SetExchange/registry/AuthenticatedProxy.sol


pragma solidity ^0.8.3;




contract AuthenticatedProxy is TokenRecipient, OwnedUpgradeabilityStorage {

    bool initialized = false;
    address public user;
    ProxyRegistry public registry;
    bool public revoked;
    enum HowToCall { Call, DelegateCall }
    event Revoked(bool revoked);
    function initialize (address addrUser, ProxyRegistry addrRegistry) public {
        require(!initialized, "Authenticated proxy already initialized");
        initialized = true;
        user = addrUser;
        registry = addrRegistry;
    }
   //Set the revoked flag (allows a user to revoke ProxyRegistry access)
    function setRevoke(bool revoke) public{
        require(msg.sender == user, "Authenticated proxy can only be revoked by its user");
        revoked = revoke;
        emit Revoked(revoke);
    }
    //Execute a message call from the proxy contract
    function proxy(address dest, HowToCall howToCall, bytes memory data) public  returns (bool result){
        require(msg.sender == user || (!revoked && registry.contracts(msg.sender)), "Authenticated proxy can only be called by its user, or by a contract authorized by the registry as long as the user has not revoked access");
        bytes memory ret;
        if (howToCall == HowToCall.Call) {
            (result, ret) = dest.call(data);
        } else if (howToCall == HowToCall.DelegateCall) {
            (result, ret) = dest.delegatecall(data);
        }
        return result;
    }
    //Execute a message call and assert success
    function proxyAssert(address dest, HowToCall howToCall, bytes memory data) public{
        require(proxy(dest, howToCall, data), "Proxy assertion failed");
    }

}

// File: localhost/SetExchange/@openzeppelin/contracts/utils/math/SafeMath.sol



pragma solidity ^0.8.0;

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

// File: localhost/SetExchange/common/ArrayUtils.sol


pragma solidity ^0.8.3;


library ArrayUtils {

    function guardedArrayReplace(bytes memory array, bytes memory desired, bytes memory mask)  internal  pure{
        require(array.length == desired.length, "Arrays have different lengths");
        require(array.length == mask.length, "Array and mask have different lengths");

        uint words = array.length / 0x20;
        uint index = words * 0x20;
        assert(index / 0x20 == words);
        uint i;

        for (i = 0; i < words; i++) {
            /* Conceptually: array[i] = (!mask[i] && array[i]) || (mask[i] && desired[i]), bitwise in word chunks. */
            assembly {
                let commonIndex := mul(0x20, add(1, i))
                let maskValue := mload(add(mask, commonIndex))
                mstore(add(array, commonIndex), or(and(not(maskValue), mload(add(array, commonIndex))), and(maskValue, mload(add(desired, commonIndex)))))
            }
        }

        /* Deal with the last section of the byte array. */
        if (words > 0) {
            /* This overlaps with bytes already set but is still more efficient than iterating through each of the remaining bytes individually. */
            i = words;
            assembly {
                let commonIndex := mul(0x20, add(1, i))
                let maskValue := mload(add(mask, commonIndex))
                mstore(add(array, commonIndex), or(and(not(maskValue), mload(add(array, commonIndex))), and(maskValue, mload(add(desired, commonIndex)))))
            }
        } else {
            /* If the byte array is shorter than a word, we must unfortunately do the whole thing bytewise.
               (bounds checks could still probably be optimized away in assembly, but this is a rare case) */
            for (i = index; i < array.length; i++) {
                array[i] = ((mask[i] ^ 0xff) & array[i]) | (mask[i] & desired[i]);
            }
        }
    }

    function arrayEq(bytes memory a, bytes memory b) internal  pure  returns (bool){
        bool success = true;
        assembly {
            let length := mload(a)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(b))
            case 1 {
                // cb is a circuit breaker in the for loop since there's
                //  no said feature for inline assembly loops
                // cb = 1 - don't breaker
                // cb = 0 - break
                let cb := 1

                let mc := add(a, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(b, 0x20)
                // the next line is the loop condition:
                // while(uint(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function arrayDrop(bytes memory _bytes, uint _start) internal  pure  returns (bytes memory){

        uint _length = SafeMath.sub(_bytes.length, _start);
        return arraySlice(_bytes, _start, _length);
    }

    function arrayTake(bytes memory _bytes, uint _length) internal pure returns (bytes memory){

        return arraySlice(_bytes, 0, _length);
    }

    function arraySlice(bytes memory _bytes, uint _start, uint _length) internal pure returns (bytes memory){

        bytes memory tempBytes;
        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function unsafeWriteBytes(uint index, bytes memory source) internal pure returns (uint){
        if (source.length > 0) {
            assembly {
                let length := mload(source)
                let end := add(source, add(0x20, length))
                let arrIndex := add(source, 0x20)
                let tempIndex := index
                for { } eq(lt(arrIndex, end), 1) {
                    arrIndex := add(arrIndex, 0x20)
                    tempIndex := add(tempIndex, 0x20)
                } {
                    mstore(tempIndex, mload(arrIndex))
                }
                index := add(index, length)
            }
        }
        return index;
    }
    
     function unsafeWriteAddress(uint index, address source) internal pure returns (uint){
        uint conv = uint(uint160(source)) << 0x60;
        assembly {
            mstore(index, conv)
            index := add(index, 0x14)
        }
        return index;
    }

    function unsafeWriteUint(uint index, uint source) internal  pure returns (uint){
        assembly {
            mstore(index, source)
            index := add(index, 0x20)
        }
        return index;
    }
   
    function unsafeWriteUint8(uint index, uint8 source) internal pure  returns (uint){
        assembly {
            mstore8(index, source)
            index := add(index, 0x1)
        }
        return index;
    }

}


// File: localhost/SetExchange/static/StaticUtil.sol


pragma solidity ^0.8.3;




contract StaticUtil is StaticCaller {

    address public atomicizer;

    function any(bytes memory, address[7] memory, AuthenticatedProxy.HowToCall[2] memory, uint[6] memory, bytes memory, bytes memory)
        public
        pure
        returns (uint)
    {
        /*
           Accept any call.
           Useful e.g. for matching-by-transaction, where you authorize the counter-call by sending the transaction and don't need to re-check it.
           Return fill "1".
        */

        return 1;
    }

    function anySingle(bytes memory,  address[7] memory, AuthenticatedProxy.HowToCall, uint[6] memory, bytes memory)
        public
        pure
    {
        /* No checks. */
    }

    function anyNoFill(bytes memory, address[7] memory, AuthenticatedProxy.HowToCall[2] memory, uint[6] memory, bytes memory, bytes memory)
        public
        pure
        returns (uint)
    {
        /*
           Accept any call.
           Useful e.g. for matching-by-transaction, where you authorize the counter-call by sending the transaction and don't need to re-check it.
           Return fill "0".
        */

        return 0;
    }

    function anyAddOne(bytes memory, address[7] memory, AuthenticatedProxy.HowToCall[2] memory, uint[6] memory uints, bytes memory, bytes memory)
        public
        pure
        returns (uint)
    {
        /*
           Accept any call.
           Useful e.g. for matching-by-transaction, where you authorize the counter-call by sending the transaction and don't need to re-check it.
           Return the current fill plus 1.
        */

        return uints[5] + 1;
    }

    function split(bytes memory extra,
                   address[7] memory addresses, AuthenticatedProxy.HowToCall[2] memory howToCalls, uint[6] memory uints,
                   bytes memory data, bytes memory counterdata)
        public
        view
        returns (uint)
    {
        (address[2] memory targets, bytes4[2] memory selectors, bytes memory firstExtradata, bytes memory secondExtradata) = abi.decode(extra, (address[2], bytes4[2], bytes, bytes));

        /* Split into two static calls: one for the call, one for the counter-call, both with metadata. */

        /* Static call to check the call. */
        require(staticCall(targets[0], abi.encodeWithSelector(selectors[0], firstExtradata, addresses, howToCalls[0], uints, data)));

        /* Static call to check the counter-call. */
        require(staticCall(targets[1], abi.encodeWithSelector(selectors[1], secondExtradata, [addresses[3], addresses[4], addresses[5], addresses[0], addresses[1], addresses[2], addresses[6]], howToCalls[1], uints, counterdata)));

        return 1;
    }

    function splitAddOne(bytes memory extra,
                   address[7] memory addresses, AuthenticatedProxy.HowToCall[2] memory howToCalls, uint[6] memory uints,
                   bytes memory data, bytes memory counterdata)
        public
        view
        returns (uint)
    {
        split(extra,addresses,howToCalls,uints,data,counterdata);
        return uints[5] + 1;
    }

    function and(bytes memory extra,
                 address[7] memory addresses, AuthenticatedProxy.HowToCall[2] memory howToCalls, uint[6] memory uints,
                 bytes memory data, bytes memory counterdata)
        public
        view
    {
        (address[] memory addrs, bytes4[] memory selectors, uint[] memory extradataLengths, bytes memory extradatas) = abi.decode(extra, (address[], bytes4[], uint[], bytes));

        require(addrs.length == extradataLengths.length);
        
        uint j = 0;
        for (uint i = 0; i < addrs.length; i++) {
            bytes memory extradata = new bytes(extradataLengths[i]);
            for (uint k = 0; k < extradataLengths[i]; k++) {
                extradata[k] = extradatas[j];
                j++;
            }
            require(staticCall(addrs[i], abi.encodeWithSelector(selectors[i], extradata, addresses, howToCalls, uints, data, counterdata)));
        }
    }

    function or(bytes memory extra,
                address[7] memory addresses, AuthenticatedProxy.HowToCall[2] memory howToCalls, uint[6] memory uints,
                bytes memory data, bytes memory counterdata)
        public
        view
    {
        (address[] memory addrs, bytes4[] memory selectors, uint[] memory extradataLengths, bytes memory extradatas) = abi.decode(extra, (address[], bytes4[], uint[], bytes));

        require(addrs.length == extradataLengths.length, "Different number of static call addresses and extradatas");
        
        uint j = 0;
        for (uint i = 0; i < addrs.length; i++) {
            bytes memory extradata = new bytes(extradataLengths[i]);
            for (uint k = 0; k < extradataLengths[i]; k++) {
                extradata[k] = extradatas[j];
                j++;
            }
            if (staticCall(addrs[i], abi.encodeWithSelector(selectors[i], extradata, addresses, howToCalls, uints, data, counterdata))) {
                return;
            }
        }

        revert("No static calls succeeded");
    }

    function sequenceExact(bytes memory extra,
        address[7] memory addresses, AuthenticatedProxy.HowToCall howToCall, uint[6] memory uints,
        bytes memory cdata)
        public
        view
    {
        (address[] memory addrs, uint[] memory extradataLengths, bytes4[] memory selectors, bytes memory extradatas) = abi.decode(extra, (address[], uint[], bytes4[], bytes));

        /* Assert DELEGATECALL to atomicizer library with given call sequence, split up predicates accordingly.
           e.g. transferring two CryptoKitties in sequence. */

        require(addrs.length == extradataLengths.length);

        (address[] memory caddrs, uint[] memory cvals, uint[] memory clengths, bytes memory calldatas) = abi.decode(ArrayUtils.arrayDrop(cdata, 4), (address[], uint[], uint[], bytes));

        require(addresses[2] == atomicizer);
        require(howToCall == AuthenticatedProxy.HowToCall.DelegateCall);
        require(addrs.length == caddrs.length); // Exact calls only

        for (uint i = 0; i < addrs.length; i++) {
            require(cvals[i] == 0);
        }

        sequence(caddrs, clengths, calldatas, addresses, uints, addrs, extradataLengths, selectors, extradatas);
    }

    function dumbSequenceExact(bytes memory extra,
        address[7] memory addresses, AuthenticatedProxy.HowToCall[2] memory howToCalls, uint[6] memory uints,
        bytes memory cdata, bytes memory)
        public
        view
        returns (uint)
    {
        sequenceExact(extra, addresses, howToCalls[0], uints, cdata);

        return 1;
    }

    function sequenceAnyAfter(bytes memory extra,
        address[7] memory addresses, AuthenticatedProxy.HowToCall howToCall, uint[6] memory uints,
        bytes memory cdata)
        public
        view
    {
        (address[] memory addrs, uint[] memory extradataLengths, bytes4[] memory selectors, bytes memory extradatas) = abi.decode(extra, (address[], uint[], bytes4[], bytes));

        /* Assert DELEGATECALL to atomicizer library with given call sequence, split up predicates accordingly.
           e.g. transferring two CryptoKitties in sequence. */

        require(addrs.length == extradataLengths.length);

        (address[] memory caddrs, uint[] memory cvals, uint[] memory clengths, bytes memory calldatas) = abi.decode(ArrayUtils.arrayDrop(cdata, 4), (address[], uint[], uint[], bytes));

        require(addresses[2] == atomicizer);
        require(howToCall == AuthenticatedProxy.HowToCall.DelegateCall);
        require(addrs.length <= caddrs.length); // Extra calls OK

        for (uint i = 0; i < addrs.length; i++) {
            require(cvals[i] == 0);
        }

        sequence(caddrs, clengths, calldatas, addresses, uints, addrs, extradataLengths, selectors, extradatas);
    }

    function sequence(
        address[] memory caddrs, uint[] memory clengths, bytes memory calldatas,
        address[7] memory addresses, uint[6] memory uints,
        address[] memory addrs, uint[] memory extradataLengths, bytes4[] memory selectors, bytes memory extradatas)
        internal
        view
    {
        uint j = 0;
        uint l = 0;
        for (uint i = 0; i < addrs.length; i++) {
            bytes memory extradata = new bytes(extradataLengths[i]);
            for (uint k = 0; k < extradataLengths[i]; k++) {
                extradata[k] = extradatas[j];
                j++;
            }
            bytes memory data = new bytes(clengths[i]);
            for (uint m = 0; m < clengths[i]; m++) {
                data[m] = calldatas[l];
                l++;
            }
            addresses[2] = caddrs[i];
            require(staticCall(addrs[i], abi.encodeWithSelector(selectors[i], extradata, addresses, AuthenticatedProxy.HowToCall.Call, uints, data)));
        }
        require(j == extradatas.length);
    }

}

// File: localhost/SetExchange/static/StaticERC1155.sol


pragma solidity ^0.8.3;




contract StaticERC1155 {

function transferERC1155Exact(bytes memory extra,
	address[7] memory addresses, AuthenticatedProxy.HowToCall howToCall, uint[6] memory,
	bytes memory data)
	public
	pure
{
	// Decode extradata
	(address token, uint256 tokenId, uint256 amount) = abi.decode(extra, (address, uint256, uint256));

	// Call target = token to give
	require(addresses[2] == token);
	// Call type = call
	require(howToCall == AuthenticatedProxy.HowToCall.Call);
	// Assert calldata
	require(ArrayUtils.arrayEq(data, abi.encodeWithSignature("safeTransferFrom(address,address,uint256,uint256,bytes)", addresses[1], addresses[4], tokenId, amount, "")));
}

function swapOneForOneERC1155(bytes memory extra,
	address[7] memory addresses, AuthenticatedProxy.HowToCall[2] memory howToCalls, uint[6] memory uints,
	bytes memory data, bytes memory counterdata)
	public
	pure
	returns (uint)
{
	// Zero-value
	require(uints[0] == 0);

	// Decode extradata
	(address[2] memory tokenGiveGet, uint256[2] memory nftGiveGet, uint256[2] memory nftAmounts) = abi.decode(extra, (address[2], uint256[2], uint256[2]));

	// Call target = token to give
	require(addresses[2] == tokenGiveGet[0], "ERC1155: call target must equal address of token to give");
	// Assert more than zero
	require(nftAmounts[0] > 0,"ERC1155: give amount must be larger than zero");
	// Call type = call
	require(howToCalls[0] == AuthenticatedProxy.HowToCall.Call, "ERC1155: call must be a direct call");
	// Assert calldata
	require(ArrayUtils.arrayEq(data, abi.encodeWithSignature("safeTransferFrom(address,address,uint256,uint256,bytes)", addresses[1], addresses[4], nftGiveGet[0], nftAmounts[0], "")));

	// Countercall target = token to get
	require(addresses[5] == tokenGiveGet[1], "ERC1155: countercall target must equal address of token to get");
	// Assert more than zero
	require(nftAmounts[1] > 0,"ERC1155: take amount must be larger than zero");
	// Countercall type = call
	require(howToCalls[1] == AuthenticatedProxy.HowToCall.Call, "ERC1155: countercall must be a direct call");
	// Assert countercalldata
	require(ArrayUtils.arrayEq(counterdata, abi.encodeWithSignature("safeTransferFrom(address,address,uint256,uint256,bytes)", addresses[4], addresses[1], nftGiveGet[1], nftAmounts[1], "")));

	// Mark filled
	return 1;
}

function swapOneForOneERC1155Decoding(bytes memory extra,
	address[7] memory addresses, AuthenticatedProxy.HowToCall[2] memory howToCalls, uint[6] memory uints,
	bytes memory data, bytes memory counterdata)
	public
	pure
	returns (uint)
{
	// Calculate function signature
	bytes memory sig = ArrayUtils.arrayTake(abi.encodeWithSignature("safeTransferFrom(address,address,uint256,uint256,bytes)"), 4);

	// Zero-value
	require(uints[0] == 0);

	// Decode extradata
	(address[2] memory tokenGiveGet, uint256[2] memory nftGiveGet, uint256[2] memory nftAmounts) = abi.decode(extra, (address[2],uint256[2],uint256[2]));

	// Call target = token to give
	require(addresses[2] == tokenGiveGet[0], "ERC1155: call target must equal address of token to give");
	// Call type = call
	require(howToCalls[0] == AuthenticatedProxy.HowToCall.Call, "ERC1155: call must be a direct call");
	// Assert signature
	require(ArrayUtils.arrayEq(sig, ArrayUtils.arrayTake(data, 4)));
	// Decode and assert calldata	
	require(ArrayUtils.arrayEq(data, abi.encodeWithSignature("safeTransferFrom(address,address,uint256,uint256,bytes)", addresses[1], addresses[4], nftGiveGet[0], nftAmounts[0], "")));
	// Decode and assert countercalldata
	require(ArrayUtils.arrayEq(counterdata, abi.encodeWithSignature("safeTransferFrom(address,address,uint256,uint256,bytes)", addresses[4], addresses[1], nftGiveGet[1], nftAmounts[1], "")));

	// Mark filled
	return 1;
}

}

// File: localhost/SetExchange/static/StaticERC721.sol


pragma solidity ^0.8.3;




contract StaticERC721 {

    function transferERC721Exact(bytes memory extra,
        address[7] memory addresses, AuthenticatedProxy.HowToCall howToCall, uint[6] memory,
        bytes memory data)
        public
        pure
    {
        // Decode extradata
        (address token, uint tokenId) = abi.decode(extra, (address, uint));

        // Call target = token to give
        require(addresses[2] == token);
        // Call type = call
        require(howToCall == AuthenticatedProxy.HowToCall.Call);
        // Assert calldata
        require(ArrayUtils.arrayEq(data, abi.encodeWithSignature("transferFrom(address,address,uint256)", addresses[1], addresses[4], tokenId)));
    }

    function swapOneForOneERC721(bytes memory extra,
        address[7] memory addresses, AuthenticatedProxy.HowToCall[2] memory howToCalls, uint[6] memory uints,
        bytes memory data, bytes memory counterdata)
        public
        pure
        returns (uint)
    {
        // Zero-value
        require(uints[0] == 0);

        // Decode extradata
        (address[2] memory tokenGiveGet, uint[2] memory nftGiveGet) = abi.decode(extra, (address[2],uint[2]));

        // Call target = token to give
        require(addresses[2] == tokenGiveGet[0], "ERC721: call target must equal address of token to give");
        // Call type = call
        require(howToCalls[0] == AuthenticatedProxy.HowToCall.Call, "ERC721: call must be a direct call");
        // Assert calldata
        require(ArrayUtils.arrayEq(data, abi.encodeWithSignature("transferFrom(address,address,uint256)", addresses[1], addresses[4], nftGiveGet[0])));

        // Countercall target = token to get
        require(addresses[5] == tokenGiveGet[1], "ERC721: countercall target must equal address of token to get");
        // Countercall type = call
        require(howToCalls[1] == AuthenticatedProxy.HowToCall.Call, "ERC721: countercall must be a direct call");
        // Assert countercalldata
        require(ArrayUtils.arrayEq(counterdata, abi.encodeWithSignature("transferFrom(address,address,uint256)", addresses[4], addresses[1], nftGiveGet[1])));

        // Mark filled
        return 1;
    }

    function swapOneForOneERC721Decoding(bytes memory extra,
        address[7] memory addresses, AuthenticatedProxy.HowToCall[2] memory howToCalls, uint[6] memory uints,
        bytes memory data, bytes memory counterdata)
        public
        pure
        returns (uint)
    {
        // Calculate function signature
        bytes memory sig = ArrayUtils.arrayTake(abi.encodeWithSignature("transferFrom(address,address,uint256)"), 4);

        // Zero-value
        require(uints[0] == 0);

        // Decode extradata
        (address[2] memory tokenGiveGet, uint[2] memory nftGiveGet) = abi.decode(extra, (address[2],uint[2]));

        // Call target = token to give
        require(addresses[2] == tokenGiveGet[0], "ERC721: call target must equal address of token to give");
        // Call type = call
        require(howToCalls[0] == AuthenticatedProxy.HowToCall.Call, "ERC721: call must be a direct call");
        // Assert signature
        require(ArrayUtils.arrayEq(sig, ArrayUtils.arrayTake(data, 4)));
        // Decode calldata
        (address callFrom, address callTo, uint256 nftGive) = abi.decode(ArrayUtils.arrayDrop(data, 4), (address, address, uint256));
        // Assert from
        require(callFrom == addresses[1]);
        // Assert to
        require(callTo == addresses[4]);
        // Assert NFT
        require(nftGive == nftGiveGet[0]);

        // Countercall target = token to get
        require(addresses[5] == tokenGiveGet[1], "ERC721: countercall target must equal address of token to get");
        // Countercall type = call
        require(howToCalls[1] == AuthenticatedProxy.HowToCall.Call, "ERC721: countercall must be a direct call");
        // Assert signature
        require(ArrayUtils.arrayEq(sig, ArrayUtils.arrayTake(counterdata, 4)));
        // Decode countercalldata
        (address countercallFrom, address countercallTo, uint256 nftGet) = abi.decode(ArrayUtils.arrayDrop(counterdata, 4), (address, address, uint256));
        // Assert from
        require(countercallFrom == addresses[4]);
        // Assert to
        require(countercallTo == addresses[1]);
        // Assert NFT
        require(nftGet == nftGiveGet[1]);

        // Mark filled
        return 1;
    }

}

// File: localhost/SetExchange/static/StaticERC20.sol


pragma solidity ^0.8.3;




contract StaticERC20 {

    function transferERC20Exact(bytes memory extra,
        address[7] memory addresses, AuthenticatedProxy.HowToCall howToCall, uint[6] memory,
        bytes memory data)
        public
        pure
    {
        // Decode extradata
        (address token, uint amount) = abi.decode(extra, (address, uint));

        // Call target = token to give
        require(addresses[2] == token);
        // Call type = call
        require(howToCall == AuthenticatedProxy.HowToCall.Call);
        // Assert calldata
        require(ArrayUtils.arrayEq(data, abi.encodeWithSignature("transferFrom(address,address,uint256)", addresses[1], addresses[4], amount)));
    }

    function swapExact(bytes memory extra,
        address[7] memory addresses, AuthenticatedProxy.HowToCall[2] memory howToCalls, uint[6] memory uints,
        bytes memory data, bytes memory counterdata)
        public
        pure
        returns (uint)
    {
        // Zero-value
        require(uints[0] == 0);

        // Decode extradata
        (address[2] memory tokenGiveGet, uint[2] memory amountGiveGet) = abi.decode(extra, (address[2], uint[2]));

        // Call target = token to give
        require(addresses[2] == tokenGiveGet[0]);
        // Call type = call
        require(howToCalls[0] == AuthenticatedProxy.HowToCall.Call);
        // Assert calldata
        require(ArrayUtils.arrayEq(data, abi.encodeWithSignature("transferFrom(address,address,uint256)", addresses[1], addresses[4], amountGiveGet[0])));

        require(addresses[5] == tokenGiveGet[1]);
        // Countercall type = call
        require(howToCalls[1] == AuthenticatedProxy.HowToCall.Call);
        // Assert countercalldata
        require(ArrayUtils.arrayEq(counterdata, abi.encodeWithSignature("transferFrom(address,address,uint256)", addresses[4], addresses[1], amountGiveGet[1])));

        // Mark filled.
        return 1;
    }

    function swapForever(bytes memory extra,
        address[7] memory addresses, AuthenticatedProxy.HowToCall[2] memory howToCalls, uint[6] memory uints,
        bytes memory data, bytes memory counterdata)
        public
        pure
        returns (uint)
    {
        // Calculate function signature
        bytes memory sig = ArrayUtils.arrayTake(abi.encodeWithSignature("transferFrom(address,address,uint256)"), 4);

        // Zero-value
        require(uints[0] == 0);

        // Decode extradata
        (address[2] memory tokenGiveGet, uint[2] memory numeratorDenominator) = abi.decode(extra, (address[2], uint[2]));

        // Call target = token to give
        require(addresses[2] == tokenGiveGet[0]);
        // Call type = call
        require(howToCalls[0] == AuthenticatedProxy.HowToCall.Call);
        // Check signature
        require(ArrayUtils.arrayEq(sig, ArrayUtils.arrayTake(data, 4)));
        // Decode calldata
        (address callFrom, address callTo, uint256 amountGive) = abi.decode(ArrayUtils.arrayDrop(data, 4), (address, address, uint256));
        // Assert from
        require(callFrom == addresses[1]);
        // Assert to
        require(callTo == addresses[4]);

        // Countercall target = token to get
        require(addresses[5] == tokenGiveGet[1]);
        // Countercall type = call
        require(howToCalls[1] == AuthenticatedProxy.HowToCall.Call);
        // Check signature
        require(ArrayUtils.arrayEq(sig, ArrayUtils.arrayTake(counterdata, 4)));
        // Decode countercalldata
        (address countercallFrom, address countercallTo, uint256 amountGet) = abi.decode(ArrayUtils.arrayDrop(counterdata, 4), (address, address, uint256));
        // Assert from
        require(countercallFrom == addresses[4]);
        // Assert to
        require(countercallTo == addresses[1]);

        // Assert ratio
        // ratio = min get/give
        require(SafeMath.mul(amountGet, numeratorDenominator[1]) >= SafeMath.mul(amountGive, numeratorDenominator[0]));

        // Order will be set with maximumFill = 2 (to allow signature caching)
        return 1;
    }


}

// File: localhost/SetExchange/WyvernStatic.sol


pragma solidity ^0.8.3;





/**
 * @title WyvernStatic
 * @author Wyvern Protocol Developers
 */
contract WyvernStatic is StaticERC20, StaticERC721, StaticERC1155, StaticUtil {

    string public constant name = "Wyvern Static";

    constructor (address atomicizerAddress){
        atomicizer = atomicizerAddress;
    }

    function test () 
        public
        pure
    {
    }
}