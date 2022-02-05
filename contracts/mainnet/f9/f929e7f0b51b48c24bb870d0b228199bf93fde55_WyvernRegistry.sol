/**
 *Submitted for verification at Etherscan.io on 2022-02-05
*/

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

// File: localhost/SetExchange/WyvernRegistry.sol


pragma solidity ^0.8.3;



/**
 * @title WyvernRegistry
 * @author Wyvern Protocol Developers
 */
contract WyvernRegistry is ProxyRegistry {

    string public constant name = "Wyvern Protocol Proxy Registry";

    /* Whether the initial auth address has been set. */
    bool public initialAddressSet = false;

    constructor (){   
        AuthenticatedProxy impl = new AuthenticatedProxy();
        impl.initialize(address(this), this);
        impl.setRevoke(true);
        delegateProxyImplementation = address(impl);
    }

    /** 
     * Grant authentication to the initial Exchange protocol contract
     *
     * @dev No delay, can only be called once - after that the standard registry process with a delay must be used
     * @param authAddress Address of the contract to grant authentication
     */
    function grantInitialAuthentication (address authAddress)
        onlyOwner
        public
    {   
        require(!initialAddressSet, "Wyvern Protocol Proxy Registry initial address already set");
        initialAddressSet = true;
        contracts[authAddress] = true;
    }   

}