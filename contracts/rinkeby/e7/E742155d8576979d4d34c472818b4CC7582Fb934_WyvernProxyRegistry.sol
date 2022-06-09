/*

  << Project Wyvern Proxy Registry >>

*/
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.12;

import "./registry/ProxyRegistry.sol";
import "./registry/AuthenticatedProxy.sol";

/**
 * @title WyvernProxyRegistry
 * @author Project Wyvern Developers
 */
contract WyvernProxyRegistry is ProxyRegistry {

    string public constant name = "Project Wyvern Proxy Registry";

    /* Whether the initial auth address has been set. */
    bool public initialAddressSet = false;

    constructor ()
    {
        AuthenticatedProxy ap = new AuthenticatedProxy();
        delegateProxyImplementation = address(ap);
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
        require(!initialAddressSet);
        initialAddressSet = true;
        contracts[authAddress] = true;
    }

}

/*

  Proxy registry; keeps a mapping of AuthenticatedProxy contracts and mapping of contracts authorized to access them.  
  
  Abstracted away from the Exchange (a) to reduce Exchange attack surface and (b) so that the Exchange contract can be upgraded without users needing to transfer assets to new proxies.

*/
// SPDX-License-Identifier: None

pragma solidity 0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./OwnableDelegateProxy.sol";
import "./ProxyRegistryInterface.sol";

/**
 * @title ProxyRegistry
 * @author Wyvern Protocol Developers
 */
contract ProxyRegistry is Ownable, ProxyRegistryInterface {

    /* DelegateProxy implementation contract. Must be initialized. */
    address public override delegateProxyImplementation;

    /* Authenticated proxies by user. */
    mapping(address => OwnableDelegateProxy) public override proxies;

    /* Contracts pending access. */
    mapping(address => uint) public pending;

    /* Contracts allowed to call those proxies. */
    mapping(address => bool) public contracts;

    /* Delay period for adding an authenticated contract.
       This mitigates a particular class of potential attack on the Wyvern DAO (which owns this registry) - if at any point the value of assets held by proxy contracts exceeded the value of half the WYV supply (votes in the DAO),
       a malicious but rational attacker could buy half the Wyvern and grant themselves access to all the proxy contracts. A delay period renders this attack nonthreatening - given two weeks, if that happened, users would have
       plenty of time to notice and transfer their assets.
    */
    uint public DELAY_PERIOD = 2 weeks;

    /**
     * Start the process to enable access for specified contract. Subject to delay period.
     *
     * @dev ProxyRegistry owner only
     * @param addr Address to which to grant permissions
     */
    function startGrantAuthentication (address addr)
        external
        onlyOwner
    {
        require(!contracts[addr] && pending[addr] == 0, "Contract is already allowed in registry, or pending");
        pending[addr] = block.timestamp;
    }

    /**
     * End the process to enable access for specified contract after delay period has passed.
     *
     * @dev ProxyRegistry owner only
     * @param addr Address to which to grant permissions
     */
    function endGrantAuthentication (address addr)
        external
        onlyOwner
    {
        require(!contracts[addr] && pending[addr] != 0 && ((pending[addr] + DELAY_PERIOD) < block.timestamp), "Contract is no longer pending or has already been approved by registry");
        pending[addr] = 0;
        contracts[addr] = true;
    }

    /**
     * Revoke access for specified contract. Can be done instantly.
     *
     * @dev ProxyRegistry owner only
     * @param addr Address of which to revoke permissions
     */    
    function revokeAuthentication (address addr)
        external
        onlyOwner
    {
        contracts[addr] = false;
    }

    /**
     * Register a proxy contract with this registry
     *
     * @dev Must be called by the user which the proxy is for, creates a new AuthenticatedProxy
     * @return proxy New AuthenticatedProxy contract
     */
    function registerProxy()
        external
        returns (OwnableDelegateProxy proxy)
    {
        return registerProxyFor(_msgSender());
    }

    /**
     * Register a proxy contract with this registry, overriding any existing proxy
     *
     * @dev Must be called by the user which the proxy is for, creates a new AuthenticatedProxy
     * @return proxy New AuthenticatedProxy contract
     */
    function registerProxyOverride()
        external
        returns (OwnableDelegateProxy proxy)
    {
        proxy = new OwnableDelegateProxy(_msgSender(), delegateProxyImplementation, abi.encodeWithSignature("initialize(address,address)", _msgSender(), address(this)));
        proxies[_msgSender()] = proxy;
        return proxy;
    }

    /**
     * Register a proxy contract with this registry
     *
     * @dev Can be called by any user
     * @return proxy New AuthenticatedProxy contract
     */
    function registerProxyFor(address user)
        public
        returns (OwnableDelegateProxy proxy)
    {
        require(proxies[user] == OwnableDelegateProxy(payable(0)), "User already has a proxy");
        proxy = new OwnableDelegateProxy(user, delegateProxyImplementation, abi.encodeWithSignature("initialize(address,address)", user, address(this)));
        proxies[user] = proxy;
        return proxy;
    }

    /**
     * Transfer access
     */
    function transferAccessTo(address from, address to)
        external
    {
        OwnableDelegateProxy proxy = proxies[from];

        /* CHECKS */
        require(OwnableDelegateProxy(payable(_msgSender())) == proxy, "Proxy transfer can only be called by the proxy");
        require(proxies[to] == OwnableDelegateProxy(payable(0)), "Proxy transfer has existing proxy as destination");

        /* EFFECTS */
        delete proxies[from];
        proxies[to] = proxy;
    }

}

/* 

  Proxy contract to hold access to assets on behalf of a user (e.g. ERC20 approve) and execute calls under particular conditions.

*/

// SPDX-License-Identifier: None

pragma solidity 0.8.12;

import "./ProxyRegistry.sol";
import "../common/TokenRecipient.sol";
import "./proxy/OwnedUpgradeabilityStorage.sol";

/**
 * @title AuthenticatedProxy
 * @author Wyvern Protocol Developers
 */
contract AuthenticatedProxy is Context, TokenRecipient, OwnedUpgradeabilityStorage {

    /* Whether initialized. */
    bool initialized = false;

    /* Address which owns this proxy. */
    address public user;

    /* Associated registry with contract authentication information. */
    ProxyRegistry public registry;

    /* Whether access has been revoked. */
    bool public revoked;

    /* Delegate call could be used to atomically transfer multiple assets owned by the proxy contract with one order. */
    enum HowToCall { Call, DelegateCall }

    /* Event fired when the proxy access is revoked or unrevoked. */
    event Revoked(bool revoked);

    /**
     * Initialize an AuthenticatedProxy
     *
     * @param addrUser Address of user on whose behalf this proxy will act
     * @param addrRegistry Address of ProxyRegistry contract which will manage this proxy
     */
    function initialize (address addrUser, ProxyRegistry addrRegistry)
        external
    {
        require(!initialized, "Authenticated proxy already initialized");
        initialized = true;
        user = addrUser;
        registry = addrRegistry;
    }

    /**
     * Set the revoked flag (allows a user to revoke ProxyRegistry access)
     *
     * @dev Can be called by the user only
     * @param revoke Whether or not to revoke access
     */
    function setRevoke(bool revoke)
        external
    {
        require(_msgSender() == user, "Authenticated proxy can only be revoked by its user");
        revoked = revoke;
        emit Revoked(revoke);
    }

    /**
     * Execute a message call from the proxy contract
     *
     * @dev Can be called by the user, or by a contract authorized by the registry as long as the user has not revoked access
     * @param dest Address to which the call will be sent
     * @param howToCall Which kind of call to make
     * @param data Calldata to send
     * @return result Result of the call (success or failure)
     */
    function proxy(address dest, HowToCall howToCall, bytes memory data)
        public
        returns (bool result)
    {
        require(_msgSender() == user || (!revoked && registry.contracts(_msgSender())), "Authenticated proxy can only be called by its user, or by a contract authorized by the registry as long as the user has not revoked access");
        bytes memory ret;
        if (howToCall == HowToCall.Call) {
            (result, ret) = dest.call(data);
        } else if (howToCall == HowToCall.DelegateCall) {
            (result, ret) = dest.delegatecall(data);
        }
        return result;
    }

    /**
     * Execute a message call and assert success
     * 
     * @dev Same functionality as `proxy`, just asserts the return value
     * @param dest Address to which the call will be sent
     * @param howToCall What kind of call to make
     * @param data Calldata to send
     */
    function proxyAssert(address dest, HowToCall howToCall, bytes memory data)
        external
    {
        require(proxy(dest, howToCall, data), "Proxy assertion failed");
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

/*

  OwnableDelegateProxy

*/
// SPDX-License-Identifier: None
pragma solidity 0.8.12;

import "./proxy/OwnedUpgradeabilityProxy.sol";

/**
 * @title OwnableDelegateProxy
 * @author Wyvern Protocol Developers
 */
contract OwnableDelegateProxy is OwnedUpgradeabilityProxy {

    constructor(address owner, address initialImplementation, bytes memory data)
    {
        setUpgradeabilityOwner(owner);
        _upgradeTo(initialImplementation);
        (bool success,) = initialImplementation.delegatecall(data);
        require(success, "OwnableDelegateProxy failed implementation");
    }

}

// SPDX-License-Identifier: None


pragma solidity 0.8.12;

import "./OwnableDelegateProxy.sol";

/**
 * @title ProxyRegistryInterface
 * @author Wyvern Protocol Developers
 */
interface ProxyRegistryInterface {

    function delegateProxyImplementation() external returns (address);

    function proxies(address owner) external returns (OwnableDelegateProxy);

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

// SPDX-License-Identifier: None
pragma solidity 0.8.12;

import "@openzeppelin/contracts/utils/Context.sol";
import "./Proxy.sol";
import "./OwnedUpgradeabilityStorage.sol";
/**
 * @title OwnedUpgradeabilityProxy
 * @dev This contract combines an upgradeability proxy with basic authorization control functionalities
 */
contract OwnedUpgradeabilityProxy 
is Proxy,
 OwnedUpgradeabilityStorage,
 Context
 {
    /**
     * @dev Event to show ownership has been transferred
     * @param previousOwner representing the address of the previous owner
     * @param newOwner representing the address of the new owner
     */
    event ProxyOwnershipTransferred(address previousOwner, address newOwner);

    /**
     * @dev This event will be emitted every time the implementation gets upgraded
     * @param implementation representing the address of the upgraded implementation
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Tells the address of the current implementation
     * @return address of the current implementation
     */
    function implementation() override public view returns (address) {
        return _implementation;
    }

    /**
     * @dev Tells the proxy type (EIP 897)
     * @return proxyTypeId Proxy type, 2 for forwarding proxy
     */
    function proxyType() override public pure returns (uint256 proxyTypeId) {
        return 2;
    }

    /**
     * @dev Upgrades the implementation address
     * @param implementationAddress representing the address of the new implementation to be set
     */
    function _upgradeTo(address implementationAddress) internal {
        require(_implementation != implementationAddress, "Proxy already uses this implementation");
        _implementation = implementationAddress;
        emit Upgraded(implementationAddress);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyProxyOwner() {
        require(_msgSender() == proxyOwner(), "Only the proxy owner can call this method");
        _;
    }

    /**
     * @dev Tells the address of the proxy owner
     * @return the address of the proxy owner
     */
    function proxyOwner() public view returns (address) {
        return upgradeabilityOwner();
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferProxyOwnership(address newOwner) public onlyProxyOwner {
        require(newOwner != address(0), "New owner cannot be the null address");
        emit ProxyOwnershipTransferred(proxyOwner(), newOwner);
        setUpgradeabilityOwner(newOwner);
    }

    /**
     * @dev Allows the upgradeability owner to upgrade the current implementation of the proxy.
     * @param implementationAddress representing the address of the new implementation to be set.
     */
    function upgradeTo(address implementationAddress) public onlyProxyOwner {
        _upgradeTo(implementationAddress);
    }

    /**
     * @dev Allows the upgradeability owner to upgrade the current implementation of the proxy
     * and delegatecall the new implementation for initialization.
     * @param implementationAddress representing the address of the new implementation to be set.
     * @param data represents the msg.data to bet sent in the low level call. This parameter may include the function
     * signature of the implementation to be called with the needed payload
     */
    function upgradeToAndCall(address implementationAddress, bytes memory data) payable public onlyProxyOwner {
        upgradeTo(implementationAddress);
        (bool success,) = address(this).delegatecall(data);
        require(success, "Call failed after proxy upgrade");
    }

}

// SPDX-License-Identifier: None


pragma solidity 0.8.12;

/**
 * @title Proxy
 * @dev Gives the possibility to delegate any call to a foreign implementation.
 */
abstract contract Proxy {
    /**
     * @dev Tells the address of the implementation where every call will be delegated.
     * @return address of the implementation to which it will be delegated
     */
    function implementation() virtual public view returns (address);

    /**
     * @dev Tells the type of proxy (EIP 897)
     * @return proxyTypeId Type of proxy, 2 for upgradeable proxy
     */
    function proxyType() virtual external pure returns (uint256 proxyTypeId);

    /**
     * @dev Fallback function allowing to perform a delegatecall to the given implementation.
     * This function will return whatever the implementation call returns
     */
    fallback () external payable {
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
    receive() external payable {}
}

// SPDX-License-Identifier: None

pragma solidity 0.8.12;

/**
 * @title OwnedUpgradeabilityStorage
 * @dev This contract keeps track of the upgradeability owner
 */
contract OwnedUpgradeabilityStorage {

    // Current implementation
    address internal _implementation;

    // Owner of the contract
    address private _upgradeabilityOwner;

    /**
     * @dev Tells the address of the owner
     * @return the address of the owner
     */
    function upgradeabilityOwner() public view returns (address) {
        return _upgradeabilityOwner;
    }

    /**
     * @dev Sets the address of the owner
     */
    function setUpgradeabilityOwner(address newUpgradeabilityOwner) internal {
        _upgradeabilityOwner = newUpgradeabilityOwner;
    }

}

/*

  Token recipient. Modified very slightly from the example on http://ethereum.org/dao (just to index log parameters).

*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @title TokenRecipient
 * @author Wyvern Protocol Developers
 */
contract TokenRecipient is Context{
    event ReceivedEther(address indexed sender, uint amount);
    event ReceivedTokens(address indexed from, uint256 value, address indexed token, bytes extraData);

    /**
     * @dev Receive tokens and generate a log event
     * @param from Address from which to transfer tokens
     * @param value Amount of tokens to transfer
     * @param token Address of token
     * @param extraData Additional data to log
     */
    function receiveApproval(address from, uint256 value, address token, bytes memory extraData) external {
        IERC20 t = IERC20(token);
        require(t.transferFrom(from, address(this), value), "ERC20 token transfer failed");
        emit ReceivedTokens(from, value, token, extraData);
    }

    /**
     * @dev Receive Ether and generate a log event
     */
    fallback () external payable  {
        emit ReceivedEther(_msgSender(), msg.value);
    }
    receive() external payable {
        emit ReceivedEther(_msgSender(), msg.value);
    }
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