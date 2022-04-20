/*

  << Project Wyvern Proxy Registry >>

*/

pragma solidity 0.5.0;

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
    public
    {
        delegateProxyImplementation = address(new AuthenticatedProxy());
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

pragma solidity 0.5.0;

import "../openzeppelin/ownership/Ownable.sol";

import "./OwnableDelegateProxy.sol";

contract ProxyRegistry is Ownable {

    /* DelegateProxy implementation contract. Must be initialized. */
    address public delegateProxyImplementation;

    /* Authenticated proxies by user. */
    mapping(address => OwnableDelegateProxy) public proxies;

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

    function grantAuthentication(address addr) public
    onlyOwner {
        contracts[addr] = true;
    }

    /**
     * Start the process to enable access for specified contract. Subject to delay period.
     *
     * @dev ProxyRegistry owner only
     * @param addr Address to which to grant permissions
     */
    function startGrantAuthentication (address addr)
    public
    onlyOwner
    {
        require(!contracts[addr] && pending[addr] == 0);
        pending[addr] = now;
    }

    /**
     * End the process to nable access for specified contract after delay period has passed.
     *
     * @dev ProxyRegistry owner only
     * @param addr Address to which to grant permissions
     */
    function endGrantAuthentication (address addr)
    public
    onlyOwner
    {
        require(!contracts[addr] && pending[addr] != 0 && ((pending[addr] + DELAY_PERIOD) < now));
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
    public
    onlyOwner
    {
        contracts[addr] = false;
    }

    /**
     * Register a proxy contract with this registry
     *
     * @dev Must be called by the user which the proxy is for, creates a new AuthenticatedProxy
     * @return New AuthenticatedProxy contract
     */
    function registerProxy()
    public
    returns (OwnableDelegateProxy proxy)
    {
        require(address(proxies[msg.sender]) == address(0));
        proxy = new OwnableDelegateProxy(msg.sender, delegateProxyImplementation, abi.encodeWithSignature("initialize(address,address)", msg.sender, address(this)));
        proxies[msg.sender] = proxy;
        return proxy;
    }

}

/* 

  Proxy contract to hold access to assets on behalf of a user (e.g. ERC20 approve) and execute calls under particular conditions.

*/

pragma solidity 0.5.0;

import "./ProxyRegistry.sol";
import "../common/TokenRecipient.sol";
import "./proxy/OwnedUpgradeabilityStorage.sol";

/**
 * @title AuthenticatedProxy
 * @author Project Wyvern Developers
 */
contract AuthenticatedProxy is TokenRecipient, OwnedUpgradeabilityStorage {

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
    public
    {
        require(!initialized);
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
    public
    {
        require(msg.sender == user);
        revoked = revoke;
        emit Revoked(revoke);
    }

    /**
     * Execute a message call from the proxy contract
     *
     * @dev Can be called by the user, or by a contract authorized by the registry as long as the user has not revoked access
     * @param dest Address to which the call will be sent
     * @param howToCall Which kind of call to make
     * @param calldata1 Calldata to send
     * @return Result of the call (success or failure)
     */
    function proxy(address dest, HowToCall howToCall, bytes memory calldata1)
    public
    returns (bool result)
    {
        bool success;
        bytes memory returndata;
        require(msg.sender == user || (!revoked && registry.contracts(msg.sender)), "failed at msg.sender == user || (!revoked && registry.contracts(msg.sender))");
        if (howToCall == HowToCall.Call) {
            (success, returndata) = dest.call(calldata1);
        } else if (howToCall == HowToCall.DelegateCall) {
            (success, returndata) = dest.delegatecall(calldata1);
        }
        require(success, string(returndata));
        return result;
    }

    /**
     * Execute a message call and assert success
     *
     * @dev Same functionality as `proxy`, just asserts the return value
     * @param dest Address to which the call will be sent
     * @param howToCall What kind of call to make
     * @param calldata1 Calldata to send
     */
    function proxyAssert(address dest, HowToCall howToCall, bytes memory calldata1)
    public
    {
        require(proxy(dest, howToCall, calldata1), "failed at proxy(dest, howToCall, calldata)");
    }

}

pragma solidity ^0.5.0;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }
}

/*

  WyvernOwnableDelegateProxy

*/

pragma solidity 0.5.0;

import "./AuthenticatedProxy.sol";
import "./proxy/OwnedUpgradeabilityProxy.sol";

contract OwnableDelegateProxy is OwnedUpgradeabilityProxy {

    constructor(address owner, address initialImplementation, bytes memory calldata1)
    public
    {
        setUpgradeabilityOwner(owner);
        _upgradeTo(initialImplementation);
        (bool success,) = initialImplementation.delegatecall(calldata1);
        require(success);
    }

}

pragma solidity 0.5.0;

import './Proxy.sol';
import './OwnedUpgradeabilityStorage.sol';

/**
 * @title OwnedUpgradeabilityProxy
 * @dev This contract combines an upgradeability proxy with basic authorization control functionalities
 */
contract OwnedUpgradeabilityProxy is Proxy, OwnedUpgradeabilityStorage {
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
  * @dev Upgrades the implementation address
  * @param implementation representing the address of the new implementation to be set
  */
  function _upgradeTo(address implementation) internal {
    require(_implementation != implementation);
    _implementation = implementation;
    emit Upgraded(implementation);
  }

  /**
  * @dev Throws if called by any account other than the owner.
  */
  modifier onlyProxyOwner() {
    require(msg.sender == proxyOwner());
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
    require(newOwner != address(0));
    emit ProxyOwnershipTransferred(proxyOwner(), newOwner);
    setUpgradeabilityOwner(newOwner);
  }

  /**
   * @dev Allows the upgradeability owner to upgrade the current implementation of the proxy.
   * @param implementation representing the address of the new implementation to be set.
   */
  function upgradeTo(address implementation) public onlyProxyOwner {
    _upgradeTo(implementation);
  }

  /**
   * @dev Allows the upgradeability owner to upgrade the current implementation of the proxy
   * and delegatecall the new implementation for initialization.
   * @param implementation representing the address of the new implementation to be set.
   * @param data represents the msg.data to bet sent in the low level call. This parameter may include the function
   * signature of the implementation to be called with the needed payload
   */
  function upgradeToAndCall(address implementation, bytes memory data) payable public onlyProxyOwner {
    upgradeTo(implementation);
    bool success;
    (success,) = address(this).delegatecall(data);
    require(success);
  }
}

/*

  Token recipient. Modified very slightly from the example on http://ethereum.org/dao (just to index log parameters).

*/

pragma solidity 0.5.0;

import "../openzeppelin/token/ERC20/ERC20.sol";

/**
 * @title TokenRecipient
 * @author Project Wyvern Developers
 */
contract TokenRecipient {
    event ReceivedEther(address indexed sender, uint amount);
    event ReceivedTokens(address indexed from, uint256 value, address indexed token, bytes extraData);

    /**
     * @dev Receive tokens and generate a log event
     * @param from Address from which to transfer tokens
     * @param value Amount of tokens to transfer
     * @param token Address of token
     * @param extraData Additional data to log
     */
    function receiveApproval(address from, uint256 value, address token, bytes memory extraData) public {
        ERC20 t = ERC20(token);
        require(t.transferFrom(from, address(this), value));
        emit ReceivedTokens(from, value, token, extraData);
    }

    /**
     * @dev Receive Ether and generate a log event
     */
    function () payable external {
        emit ReceivedEther(msg.sender, msg.value);
    }
}

pragma solidity 0.5.0;

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

  /**
  * @dev Tells the address of the current implementation
  * @return address of the current implementation
  */
  function implementation() public view returns (address) {
    return _implementation;
  }

  /**
  * @dev Tells the proxy type (EIP 897)
  * @return Proxy type, 2 for forwarding proxy
  */
  function proxyType() public pure returns (uint256 proxyTypeId) {
    return 2;
  }
}

pragma solidity ^0.5.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 * Originally based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract ERC20 is IERC20 {
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;

  mapping (address => mapping (address => uint256)) private _allowed;

  uint256 private _totalSupply;

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param owner The address to query the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address owner) public view returns (uint256) {
    return _balances[owner];
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param owner address The address which owns the funds.
   * @param spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(
    address owner,
    address spender
   )
    public
    view
    returns (uint256)
  {
    return _allowed[owner][spender];
  }

  /**
  * @dev Transfer token for a specified address
  * @param to The address to transfer to.
  * @param value The amount to be transferred.
  */
  function transfer(address to, uint256 value) public returns (bool) {
    _transfer(msg.sender, to, value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param spender The address which will spend the funds.
   * @param value The amount of tokens to be spent.
   */
  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));

    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  /**
   * @dev Transfer tokens from one address to another
   * @param from address The address which you want to send tokens from
   * @param to address The address which you want to transfer to
   * @param value uint256 the amount of tokens to be transferred
   */
  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    public
    returns (bool)
  {
    require(value <= _allowed[from][msg.sender]);

    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
    _transfer(from, to, value);
    return true;
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed_[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param spender The address which will spend the funds.
   * @param addedValue The amount of tokens to increase the allowance by.
   */
  function increaseAllowance(
    address spender,
    uint256 addedValue
  )
    public
    returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].add(addedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed_[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param spender The address which will spend the funds.
   * @param subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseAllowance(
    address spender,
    uint256 subtractedValue
  )
    public
    returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].sub(subtractedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  /**
  * @dev Transfer token for a specified addresses
  * @param from The address to transfer from.
  * @param to The address to transfer to.
  * @param value The amount to be transferred.
  */
  function _transfer(address from, address to, uint256 value) internal {
    require(value <= _balances[from]);
    require(to != address(0));

    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(from, to, value);
  }

  /**
   * @dev Internal function that mints an amount of the token and assigns it to
   * an account. This encapsulates the modification of balances such that the
   * proper events are emitted.
   * @param account The account that will receive the created tokens.
   * @param value The amount that will be created.
   */
  function _mint(address account, uint256 value) internal {
    require(account != address(0));
    _totalSupply = _totalSupply.add(value);
    _balances[account] = _balances[account].add(value);
    emit Transfer(address(0), account, value);
  }

  /**
   * @dev Internal function that burns an amount of the token of a given
   * account.
   * @param account The account whose tokens will be burnt.
   * @param value The amount that will be burnt.
   */
  function _burn(address account, uint256 value) internal {
    require(account != address(0));
    require(value <= _balances[account]);

    _totalSupply = _totalSupply.sub(value);
    _balances[account] = _balances[account].sub(value);
    emit Transfer(account, address(0), value);
  }

  /**
   * @dev Internal function that burns an amount of the token of a given
   * account, deducting from the sender's allowance for said account. Uses the
   * internal burn function.
   * @param account The account whose tokens will be burnt.
   * @param value The amount that will be burnt.
   */
  function _burnFrom(address account, uint256 value) internal {
    require(value <= _allowed[account][msg.sender]);
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(
      value);
    _burn(account, value);
  }
}

pragma solidity ^0.5.0;

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

pragma solidity ^0.5.0;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

pragma solidity 0.5.0;

/**
 * @title Proxy
 * @dev Gives the possibility to delegate any call to a foreign implementation.
 */
contract Proxy {

  /**
  * @dev Tells the address of the implementation where every call will be delegated.
  * @return address of the implementation to which it will be delegated
  */
  function implementation() public view returns (address);

  /**
  * @dev Tells the type of proxy (EIP 897)
  * @return Type of proxy, 2 for upgradeable proxy
  */
  function proxyType() public pure returns (uint256 proxyTypeId);

  /**
  * @dev Fallback function allowing to perform a delegatecall to the given implementation.
  * This function will return whatever the implementation call returns
  */
  function () payable external {
    address _impl = implementation();
    require(_impl != address(0));

    assembly {
      let ptr := mload(0x40)
      calldatacopy(ptr, 0, calldatasize)
      let result := delegatecall(gas, _impl, ptr, calldatasize, 0, 0)
      let size := returndatasize
      returndatacopy(ptr, 0, size)

      switch result
      case 0 { revert(ptr, size) }
      default { return(ptr, size) }
    }
  }
}