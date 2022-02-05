/**
 *Submitted for verification at Etherscan.io on 2022-02-05
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

// File: localhost/SetExchange/common/EIP1271.sol


pragma solidity ^0.8.3;

abstract contract ERC1271 {

  // bytes4(keccak256("isValidSignature(bytes,bytes)")
  bytes4 constant internal MAGICVALUE = 0x20c13b0b;

  /**
   * @dev Should return whether the signature provided is valid for the provided data
   * @param _data Arbitrary length data signed on the behalf of address(this)
   * @param _signature Signature byte array associated with _data
   *
   * MUST return the bytes4 magic value 0x20c13b0b when function passes.
   * MUST NOT modify state (using STATICCALL for solc < 0.5, view modifier for solc > 0.5)
   * MUST allow external calls
   */
  function isValidSignature(
      bytes memory _data,
      bytes memory _signature)
      virtual
      public
      view
      returns (bytes4 magicValue);
}

// File: localhost/SetExchange/common/EIP712.sol


pragma solidity ^0.8.3;

/**
 * @title EIP712
 * @author Wyvern Protocol Developers
 */
contract EIP712 {

    struct EIP712Domain {
        string  name;
        string  version;
        uint256 chainId;
        address verifyingContract;
    }

    bytes32 constant EIP712DOMAIN_TYPEHASH = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );

    bytes32 DOMAIN_SEPARATOR;

    function hash(EIP712Domain memory eip712Domain)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(
            EIP712DOMAIN_TYPEHASH,
            keccak256(bytes(eip712Domain.name)),
            keccak256(bytes(eip712Domain.version)),
            eip712Domain.chainId,
            eip712Domain.verifyingContract
        ));
    }

}

// File: localhost/SetExchange/common/ReentrancyGuarded.sol


pragma solidity ^0.8.3;

contract ReentrancyGuarded {

    bool reentrancyLock = false;
    modifier reentrancyGuard {
        if (reentrancyLock) {
            revert();
        }
        reentrancyLock = true;
        _;
        reentrancyLock = false;
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

// File: localhost/SetExchange/exchange/ExchangeCore.sol


pragma solidity ^0.8.3;







//import "../common/Console.sol";


contract ExchangeCore is ReentrancyGuarded, StaticCaller,EIP712 {
    bytes4 constant internal EIP_1271_MAGICVALUE = 0x20c13b0b;
   
     struct Order {
        address registry;
        address maker;
        address staticTarget;
        bytes4 staticSelector;
        bytes staticExtradata;
        uint maximumFill;
        uint listingTime;
        uint expirationTime;
        uint salt;
    }
    
    // uint basePrice;
    // address paymentToken;
    // address payoutAddress;
    
    struct Call {      
        address target;      
        AuthenticatedProxy.HowToCall howToCall;        
        bytes data;
    } 
    
    /* Order typehash for EIP 712 compatibility. */
    bytes32 constant ORDER_TYPEHASH = keccak256(
        "Order(address registry,address maker,address staticTarget,bytes4 staticSelector,bytes staticExtradata,uint256 maximumFill,uint256 listingTime,uint256 expirationTime,uint256 salt)"
    );

    mapping(address => bool) public registries;
    mapping(address => mapping(bytes32 => uint)) public fills;
    mapping(address => mapping(bytes32 => bool)) public approved;

    event OrderApproved     (bytes32 indexed hash, address registry, address indexed maker, address staticTarget, bytes4 staticSelector, bytes staticExtradata, uint maximumFill, uint listingTime, uint expirationTime, uint salt, bool orderbookInclusionDesired);
    event OrderFillChanged  (bytes32 indexed hash, address indexed maker, uint newFill);
    event OrdersMatched     (bytes32 firstHash, bytes32 secondHash, address indexed firstMaker, address indexed secondMaker, uint newFirstFill, uint newSecondFill, bytes32 indexed metadata);

    
    function hashOrder(Order memory order) internal pure returns (bytes32 hash){
        /* Per EIP 712. */
        return keccak256(abi.encode(
            ORDER_TYPEHASH,
            order.registry,
            order.maker,
            order.staticTarget,
            order.staticSelector,
            keccak256(order.staticExtradata),
            order.maximumFill,
            order.listingTime,
            order.expirationTime,
            order.salt
        ));
    }

    function hashToSign(bytes32 orderHash) internal view returns (bytes32 hash){
        /* Calculate the string a user must sign. */
        return keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            orderHash
        ));
    }
   
    function exists(address what) internal view returns (bool){
        uint size;
        assembly {
            size := extcodesize(what)
        }
        return size > 0;
    }
    
    function validateOrderParameters(Order memory order, bytes32 hash) internal view returns (bool)
    {
        /* Order must be listed and not be expired. */
        if (order.listingTime > block.timestamp || (order.expirationTime != 0 && order.expirationTime <= block.timestamp)) {
            return false;
        }

        /* Order must not have already been completely filled. */
        if (fills[order.maker][hash] >= order.maximumFill) {
            return false;
        }

        /* Order static target must exist. */
        if (!exists(order.staticTarget)) {
            return false;
        }

        return true;
    }
    
     function validateOrderAuthorization(bytes32 hash, address maker, bytes memory signature) internal view returns (bool){
        /* Memoized authentication. If order has already been partially filled, order must be authenticated. */
        if (fills[maker][hash] > 0) {
            return true;
        }
        /* Order authentication. Order must be either: */
        /* (a): sent by maker */
        if (maker == msg.sender) {
            return true;
        }
        /* (b): previously approved */
        if (approved[maker][hash]) {
            return true;
        }

        /* Calculate hash which must be signed. */
        bytes32 calculatedHashToSign = hashToSign(hash);
        /* Determine whether signer is a contract or account. */
        bool isContract = exists(maker);

        /* (c): Contract-only authentication: EIP/ERC 1271. */
        if (isContract) {
            if (ERC1271(maker).isValidSignature(abi.encodePacked(calculatedHashToSign), signature) == EIP_1271_MAGICVALUE) {
                return true;
            }
            return false;
        }
        /* (d): Account-only authentication: ECDSA-signed by maker. */
        (uint8 v, bytes32 r, bytes32 s) = abi.decode(signature, (uint8, bytes32, bytes32));
        
        //return true;
        if (ecrecover(calculatedHashToSign, v, r, s) == maker) {
            return true;
        }
        return false;
    }
    
//   function ecrecoverSig(bytes32 orderHash, bytes memory signature) external view returns (address){
       
//         /* Calculate hash which must be signed. */
//         bytes32 calculatedHashToSign = hashToSign(orderHash);
//         /* (d): Account-only authentication: ECDSA-signed by maker. */
//         (uint8 v, bytes32 r, bytes32 s) = abi.decode(signature, (uint8, bytes32, bytes32));
//         return ecrecover(calculatedHashToSign, v, r, s);
//     }
    
//     function ecrecoverSigVrs(bytes32 orderHash,uint8 v,bytes32 r,bytes32 s) external view returns (address){
        
//         /* Calculate hash which must be signed. */
//         bytes32 calculatedHashToSign = hashToSign(orderHash);
//         return ecrecover(calculatedHashToSign, v, r, s) ;
//     }
    
    function approveOrderHash(bytes32 hash)  internal{
        /* CHECKS */
        /* Assert order has not already been approved. */
        require(!approved[msg.sender][hash], "Order has already been approved");
        /* EFFECTS */
        /* Mark order as approved. */
        approved[msg.sender][hash] = true;
    }

    function approveOrder(Order memory order, bool orderbookInclusionDesired) internal{
        /* CHECKS */
        /* Assert sender is authorized to approve order. */
        require(order.maker == msg.sender, "Sender is not the maker of the order and thus not authorized to approve it");
        /* Calculate order hash. */
        bytes32 hash = hashOrder(order);
        /* Approve order hash. */
        approveOrderHash(hash);
        /* Log approval event. */
        emit OrderApproved(hash, order.registry, order.maker, order.staticTarget, order.staticSelector, order.staticExtradata, order.maximumFill, order.listingTime, order.expirationTime, order.salt, orderbookInclusionDesired);
    }

    function setOrderFill(bytes32 hash, uint fill) internal{
        /* CHECKS */
        /* Assert fill is not already set. */
        require(fills[msg.sender][hash] != fill, "Fill is already set to the desired value");
        /* EFFECTS */
        /* Mark order as accordingly filled. */
        fills[msg.sender][hash] = fill;
        /* Log order fill change event. */
        emit OrderFillChanged(hash, msg.sender, fill);
    }
    
     function encodeStaticCall(Order memory order, Call memory call, Order memory counterorder, Call memory countercall, address matcher, uint value, uint fill)
        internal
        pure
        returns (bytes memory)
    {
        /* This array wrapping is necessary to preserve static call target function stack space. */
        address[7] memory addresses = [order.registry, order.maker, call.target, counterorder.registry, counterorder.maker, countercall.target, matcher];
        
        AuthenticatedProxy.HowToCall[2] memory howToCalls = [call.howToCall, countercall.howToCall];
        
        uint[6] memory uints = [value, order.maximumFill, order.listingTime, order.expirationTime, counterorder.listingTime, fill];
        
        return abi.encodeWithSelector(order.staticSelector, order.staticExtradata, addresses, howToCalls, uints, call.data, countercall.data);
    }
    
     function executeStaticCall(Order memory order, Call memory call, Order memory counterorder, Call memory countercall, address matcher, uint value, uint fill)
        internal
        view
        returns (uint)
    {
        return staticCallUint(order.staticTarget, encodeStaticCall(order, call, counterorder, countercall, matcher, value, fill));
    }
    
     function executeCall(ProxyRegistryInterface registry, address maker, Call memory call)
        internal
        returns (bool)
    {
        /* Assert valid registry. */
        require(registries[address(registry)]);

        /* Assert target exists. */
        require(exists(call.target), "Call target does not exist");

        /* Retrieve delegate proxy contract. */
        OwnableDelegateProxy delegateProxy = registry.proxies(maker);

        /* Assert existence. */
        require(address(delegateProxy) != address(0x0), "Delegate proxy does not exist for maker");

        /* Assert implementation. */
        require(delegateProxy.implementation() == registry.delegateProxyImplementation(), "Incorrect delegate proxy implementation for maker");

        /* Typecast. */
        AuthenticatedProxy proxy = AuthenticatedProxy(payable(address(delegateProxy)));

        /* Execute order. */
        return proxy.proxy(call.target, call.howToCall, call.data);
    }
    
    function payEthToProxy(ProxyRegistryInterface registry, address maker,uint256 price)
        internal
        returns (bool)
    {
        
        require(registries[address(registry)]);
        OwnableDelegateProxy delegateProxy = registry.proxies(maker);
        require(address(delegateProxy) != address(0x0), "Delegate proxy does not exist for maker");
        require(delegateProxy.implementation() == registry.delegateProxyImplementation(), "Incorrect delegate proxy implementation for maker");
        AuthenticatedProxy proxy = AuthenticatedProxy(payable(address(delegateProxy)));
        (bool success,)=address(proxy).call{value: price}(abi.encodeWithSignature("nonExistingFunction()"));
        //require(payable(proxy).send(price));
        return success;
    }
    
     function atomicMatch(Order memory firstOrder, Call memory firstCall, Order memory secondOrder, Call memory secondCall, bytes memory signatures, bytes32 metadata)
        internal
        reentrancyGuard
    {
        /* CHECKS */

        /* Calculate first order hash. */
        bytes32 firstHash = hashOrder(firstOrder);

        /* Check first order validity. */
        require(validateOrderParameters(firstOrder, firstHash), "First order has invalid parameters");

        /* Calculate second order hash. */
        bytes32 secondHash = hashOrder(secondOrder);

        /* Check second order validity. */
        require(validateOrderParameters(secondOrder, secondHash), "Second order has invalid parameters");

        /* Prevent self-matching (possibly unnecessary, but safer). */
        require(firstHash != secondHash, "Self-matching orders is prohibited");
        {
            /* Calculate signatures (must be awkwardly decoded here due to stack size constraints). */
            (bytes memory firstSignature, bytes memory secondSignature) = abi.decode(signatures, (bytes, bytes));
            
             /* Check first order authorization. */
             require(validateOrderAuthorization(firstHash, firstOrder.maker, firstSignature), "First order failed authorization");

             /* Check second order authorization. */
             require(validateOrderAuthorization(secondHash, secondOrder.maker, secondSignature), "Second order failed authorization");
             //Console.log("firstHash",firstHash);
        }

        /* INTERACTIONS */

        /* Transfer any msg.value.
          This is the first "asymmetric" part of order matching: if an order requires Ether, it must be the first order. */
        if (msg.value > 0) {
            //payable(address(uint160(firstOrder.maker))).transfer(msg.value);
           require(payEthToProxy(ProxyRegistryInterface(secondOrder.registry), secondOrder.maker,msg.value), "payEthToProxy call failed");
        }

        /* Execute first call, assert success.
          This is the second "asymmetric" part of order matching: execution of the second order can depend on state changes in the first order, but not vice-versa. */
        require(executeCall(ProxyRegistryInterface(firstOrder.registry), firstOrder.maker, firstCall), "First call failed");
        /* Execute second call, assert success. */
        require(executeCall(ProxyRegistryInterface(secondOrder.registry), secondOrder.maker, secondCall), "Second call failed");
        /* Static calls must happen after the effectful calls so that they can check the resulting state. */

        /* Fetch previous first order fill. */
        uint previousFirstFill = fills[firstOrder.maker][firstHash];
        /* Fetch previous second order fill. */
        uint previousSecondFill = fills[secondOrder.maker][secondHash];
        
        /* Execute first order static call, assert success, capture returned new fill. */
        uint firstFill = executeStaticCall(firstOrder, firstCall, secondOrder, secondCall, msg.sender, msg.value, previousFirstFill);
        /* Execute second order static call, assert success, capture returned new fill. */
        uint secondFill = executeStaticCall(secondOrder, secondCall, firstOrder, firstCall, msg.sender, uint(0), previousSecondFill);
        
        /* EFFECTS */
        /* Update first order fill, if necessary. */
        if (firstOrder.maker != msg.sender) {
            if (firstFill != previousFirstFill) {
                fills[firstOrder.maker][firstHash] = firstFill;
            }
        }

        /* Update second order fill, if necessary. */
        if (secondOrder.maker != msg.sender) {
            if (secondFill != previousSecondFill) {
                fills[secondOrder.maker][secondHash] = secondFill;
            }
        }
        
        /* LOGS */
        /* Log match event. */
        emit OrdersMatched(firstHash, secondHash, firstOrder.maker, secondOrder.maker, firstFill, secondFill, metadata);
    }
    
}
// File: localhost/SetExchange/exchange/Exchange.sol


pragma solidity ^0.8.3;


contract Exchange is ExchangeCore {
    
    /* external ABI-encodable method wrappers. */

    function hashOrder_(address registry, address maker, address staticTarget, bytes4 staticSelector, bytes calldata staticExtradata, uint maximumFill, uint listingTime, uint expirationTime, uint salt)
        external
        pure
        returns (bytes32 hash)
    {
        return hashOrder(Order(registry, maker, staticTarget, staticSelector, staticExtradata, maximumFill, listingTime, expirationTime, salt));
    }

    function hashToSign_(bytes32 orderHash)
        external
        view
        returns (bytes32 hash)
    {
        return hashToSign(orderHash);
    }
    
     function validateOrderParameters_(address registry, address maker, address staticTarget, bytes4 staticSelector, bytes calldata staticExtradata, uint maximumFill, uint listingTime, uint expirationTime, uint salt)
        external
        view
        returns (bool)
    {
        Order memory order = Order(registry, maker, staticTarget, staticSelector, staticExtradata, maximumFill, listingTime, expirationTime, salt);
        return validateOrderParameters(order, hashOrder(order));
    }

    function validateOrderAuthorization_(bytes32 hash, address maker, bytes calldata signature)
        external
        view
        returns (bool)
    {
        return validateOrderAuthorization(hash, maker, signature);
    }

    function approveOrderHash_(bytes32 hash)
        external
    {
        return approveOrderHash(hash);
    }

    function approveOrder_(address registry, address maker, address staticTarget, bytes4 staticSelector, bytes calldata staticExtradata, uint maximumFill, uint listingTime, uint expirationTime, uint salt, bool orderbookInclusionDesired)
        external
    {
        return approveOrder(Order(registry, maker, staticTarget, staticSelector, staticExtradata, maximumFill, listingTime, expirationTime, salt), orderbookInclusionDesired);
    }

    function setOrderFill_(bytes32 hash, uint fill)
        external
    {
        return setOrderFill(hash, fill);
    }
    
    
    function atomicMatch_(address[8] memory addr,uint[8] memory uints, bytes4[2] memory staticSelectors,
        bytes memory firstExtradata, bytes memory firstCalldata, bytes memory secondExtradata, bytes memory secondCalldata,
        uint8[2] memory howToCalls, bytes32 metadata, bytes memory signatures)
        public
        payable
    {
        return atomicMatch(
            Order(addr[0], addr[1], addr[2], staticSelectors[0], firstExtradata, uints[0], uints[1], uints[2], uints[3]),
            Call(addr[3], AuthenticatedProxy.HowToCall(howToCalls[0]), firstCalldata),
            Order(addr[4], addr[5], addr[6], staticSelectors[1], secondExtradata, uints[4], uints[5], uints[6], uints[7]),
            Call(addr[7], AuthenticatedProxy.HowToCall(howToCalls[1]), secondCalldata),
            signatures,
            metadata
        );
    }
   
}
// File: localhost/SetExchange/WyvernExchange.sol


pragma solidity ^0.8.3;


contract WyvernExchange is Exchange {

    string public constant name = "Wyvern Exchange";
  
    string public constant version = "3.1";

    string public constant codename = "Ancalagon";

    //constructor (uint chainId, address[] memory registryAddrs, string memory customPersonalSignPrefix){
    constructor (uint chainId, address[] memory registryAddrs){
        DOMAIN_SEPARATOR = hash(EIP712Domain({
            name              : name,
            version           : version,
            chainId           : chainId,
            verifyingContract : address(this)
        }));
        for (uint i = 0; i < registryAddrs.length; i++) {
          registries[registryAddrs[i]] = true;
        }
    }
}