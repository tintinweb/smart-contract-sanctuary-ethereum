pragma solidity 0.4.26;


import "./exchange/Exchange.sol";


contract WyvernExchange is Exchange{

    string public constant name = "Project Wyvern Exchange";
    string public constant version = "2.2";
    string public constant codename = "Lambton Worm";
 

    constructor(
        ProxyRegistry registryAddress,
        TokenTransferProxy tokenTransferProxyAddress,
        ERC20 tokenAddress,
        address protocolFeeAddress
    ) public {
        registry = registryAddress;
        tokenTransferProxy = tokenTransferProxyAddress;
        exchangeToken = tokenAddress;
        protocolFeeRecipient = protocolFeeAddress;
        owner = msg.sender;
    }
 }

pragma solidity ^0.4.21;


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

pragma solidity ^0.4.21;

import "./ERC20Basic.sol";


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.4.21;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
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

}

pragma solidity ^0.4.21;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
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

pragma solidity 0.4.26;
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
    function() public payable {
        address _impl = implementation();
        require(_impl != address(0));

        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize)
            let result := delegatecall(gas, _impl, ptr, calldatasize, 0, 0)
            let size := returndatasize
            returndatacopy(ptr, 0, size)

            switch result
                case 0 {
                    revert(ptr, size)
                }
                default {
                    return(ptr, size)
                }
        }
    }
}

pragma solidity 0.4.26;

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

pragma solidity 0.4.26;

import './Proxy.sol';
import './OwnedUpgradeabilityStorage.sol';

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
    function upgradeToAndCall(address implementation, bytes data)
        public
        payable
        onlyProxyOwner
    {
        upgradeTo(implementation);
        require(address(this).delegatecall(data));
    }
}

/*

  Token transfer proxy. Uses the authentication table of a ProxyRegistry contract to grant ERC20 `transferFrom` access.
  This means that users only need to authorize the proxy contract once for all future protocol versions.

*/

pragma solidity 0.4.26;

import "../../lib/token/ERC20/ERC20.sol";

import "./ProxyRegistry.sol";

contract TokenTransferProxy {

    /* Authentication registry. */
    ProxyRegistry public registry;

    /**
     * Call ERC20 `transferFrom`
     *
     * @dev Authenticated contract only
     * @param token ERC20 token address
     * @param from From address
     * @param to To address
     * @param amount Transfer amount
     */
    function transferFrom(address token, address from, address to, uint amount)
        public
        returns (bool)
    {
        require(registry.contracts(msg.sender));
        return ERC20(token).transferFrom(from, to, amount);
    }

}

/*

  Proxy registry; keeps a mapping of AuthenticatedProxy contracts and mapping of contracts authorized to access them.  
  
  Abstracted away from the Exchange (a) to reduce Exchange attack surface and (b) so that the Exchange contract can be upgraded without users needing to transfer assets to new proxies.

*/

pragma solidity 0.4.26;

import "../../lib/ownership/Ownable.sol";

import "./OwnableDelegateProxy.sol";

contract ProxyRegistry is Ownable {
    /* DelegateProxy implementation contract. Must be initialized. */
    address public delegateProxyImplementation;

    /* Authenticated proxies by user. */
    mapping(address => OwnableDelegateProxy) public proxies;

    /* Contracts pending access. */
    mapping(address => uint256) public pending;

    /* Contracts allowed to call those proxies. */
    mapping(address => bool) public contracts;

    /* Delay period for adding an authenticated contract.
       This mitigates a particular class of potential attack on the Wyvern DAO (which owns this registry) - if at any point the value of assets held by proxy contracts exceeded the value of half the WYV supply (votes in the DAO),
       a malicious but rational attacker could buy half the Wyvern and grant themselves access to all the proxy contracts. A delay period renders this attack nonthreatening - given two weeks, if that happened, users would have
       plenty of time to notice and transfer their assets.
    */
    uint256 public DELAY_PERIOD = 2 weeks;

    /* Addresses allowed to call registerProxy.*/
    mapping(address => bool) public managers;

    modifier isManager() {
        require(managers[msg.sender] == true);
        _;
    }

    function addManager(address address_) external onlyOwner {
        managers[address_] = true;
    }

    function removerManger(address address_) external onlyOwner {
        require(address_ != owner);
        managers[address_] = false;
    }

    /**
     * Start the process to enable access for specified contract. Subject to delay period.
     *
     * @dev ProxyRegistry owner only
     * @param addr Address to which to grant permissions
     */
    function startGrantAuthentication(address addr) public onlyOwner {
        require(!contracts[addr] && pending[addr] == 0);
        pending[addr] = now;
    }

    /**
     * End the process to nable access for specified contract after delay period has passed.
     *
     * @dev ProxyRegistry owner only
     * @param addr Address to which to grant permissions
     */
    function endGrantAuthentication(address addr) public onlyOwner {
        require(
            !contracts[addr] &&
                pending[addr] != 0 &&
                ((pending[addr] + DELAY_PERIOD) < now)
        );
        pending[addr] = 0;
        contracts[addr] = true;
    }

    /**
     * Revoke access for specified contract. Can be done instantly.
     *
     * @dev ProxyRegistry owner only
     * @param addr Address of which to revoke permissions
     */

    function revokeAuthentication(address addr) public onlyOwner {
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
        isManager
        returns (OwnableDelegateProxy proxy)
    {
        require(proxies[msg.sender] == address(0));
        proxy = new OwnableDelegateProxy(
            msg.sender,
            delegateProxyImplementation,
            abi.encodeWithSignature(
                "initialize(address,address)",
                msg.sender,
                address(this)
            )
        );
        proxies[msg.sender] = proxy;
        return proxy;
    }
}

pragma solidity 0.4.26;


import "./proxy/OwnedUpgradeabilityProxy.sol";

contract OwnableDelegateProxy is OwnedUpgradeabilityProxy {
    constructor(
        address owner,
        address initialImplementation,
        bytes calldata
    ) public {
        setUpgradeabilityOwner(owner);
        _upgradeTo(initialImplementation);
        require(initialImplementation.delegatecall(calldata));
    }
}

/* 

  Proxy contract to hold access to assets on behalf of a user (e.g. ERC20 approve) and execute calls under particular conditions.

*/

pragma solidity 0.4.26;

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
    enum HowToCall {Call, DelegateCall}

    /* Event fired when the proxy access is revoked or unrevoked. */
    event Revoked(bool revoked);

    /**
     * Initialize an AuthenticatedProxy
     *
     * @param addrUser Address of user on whose behalf this proxy will act
     * @param addrRegistry Address of ProxyRegistry contract which will manage this proxy
     */
    function initialize(address addrUser, ProxyRegistry addrRegistry) public {
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
    function setRevoke(bool revoke) public {
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
     * @param calldata Calldata to send
     * @return Result of the call (success or failure)
     */
    function proxy(
        address dest,
        HowToCall howToCall,
        bytes calldata
    ) public returns (bool result) {
        require(
            msg.sender == user || (!revoked && registry.contracts(msg.sender))
        );
        if (howToCall == HowToCall.Call) {
            result = dest.call(calldata);
        } else if (howToCall == HowToCall.DelegateCall) {
            result = dest.delegatecall(calldata);
        }
        return result;
    }

    /**
     * Execute a message call and assert success
     *
     * @dev Same functionality as `proxy`, just asserts the return value
     * @param dest Address to which the call will be sent
     * @param howToCall What kind of call to make
     * @param calldata Calldata to send
     */
    function proxyAssert(
        address dest,
        HowToCall howToCall,
        bytes calldata
    ) public {
        require(proxy(dest, howToCall, calldata));
    }
}

/*

  Abstract over fixed-price sales and Dutch auctions, with the intent of easily supporting additional methods of sale later.

  Separated into a library for convenience, all the functions are inlined.

*/

pragma solidity 0.4.26;

import "../../lib/math/SafeMath.sol";

/**
 * @title SaleKindInterface
 * @author Project Wyvern Developers
 */
library SaleKindInterface {

    enum Side { Buy, Sell }

   
    enum SaleKind { FixedPrice, DutchAuction }

  
    function validateParameters(SaleKind saleKind, uint expirationTime)
        pure
        internal
        returns (bool)
    {
        /* Auctions must have a set expiration date. */
        return (saleKind == SaleKind.FixedPrice || expirationTime > 0);
    }

  
    function canSettleOrder(uint listingTime, uint expirationTime)
        view
        internal
        returns (bool)
    {
        return (listingTime < now) && (expirationTime == 0 || now < expirationTime);
    }


    function calculateFinalPrice(Side side, SaleKind saleKind, uint basePrice, uint extra, uint listingTime, uint expirationTime)
        view
        internal
        returns (uint finalPrice)
    {
        if (saleKind == SaleKind.FixedPrice) {
            return basePrice;
        } else if (saleKind == SaleKind.DutchAuction) {
            uint diff = SafeMath.div(SafeMath.mul(extra, SafeMath.sub(now, listingTime)), SafeMath.sub(expirationTime, listingTime));
            if (side == Side.Sell) {
                /* Sell-side - start price: basePrice. End price: basePrice - extra. */
                return SafeMath.sub(basePrice, diff);
            } else {
                /* Buy-side - start price: basePrice. End price: basePrice + extra. */
                return SafeMath.add(basePrice, diff);
            }
        }
    }

}

pragma solidity 0.4.26;

import "../../lib/token/ERC20/ERC20.sol";
import "../../lib/math/SafeMath.sol";
import "../../lib/ownership/Ownable.sol";

import "../registry/ProxyRegistry.sol";
import "../registry/TokenTransferProxy.sol";
import "../registry/AuthenticatedProxy.sol";
import "../common/ArrayUtils.sol";
import "../common/ReentrancyGuarded.sol";
import "./SaleKindInterface.sol";

contract ExchangeCore is ReentrancyGuarded, Ownable {
    /* The token used to pay exchange fees. */
    ERC20 public exchangeToken;
    ProxyRegistry public registry;
    TokenTransferProxy public tokenTransferProxy;

    mapping(bytes32 => bool) public cancelledOrFinalized;

    mapping(bytes32 => bool) public approvedOrders;

    uint256 public minimumMakerProtocolFee = 0;

    uint256 public minimumTakerProtocolFee = 0;

    address public protocolFeeRecipient;

    enum FeeMethod {
        ProtocolFee,
        SplitFee
    }

    uint256 public constant INVERSE_BASIS_POINT = 10000;

   

    struct Sig {
      
        uint8 v;
        
        bytes32 r;
        
        bytes32 s;
    }

    struct Order {
       
        address exchange;
        address maker;
        address taker;
        uint256 makerRelayerFee;
        /* Taker relayer fee of the order, or maximum taker fee for a taker order. */
        uint256 takerRelayerFee;
        /* Maker protocol fee of the order, unused for taker order. */
        uint256 makerProtocolFee;
        /* Taker protocol fee of the order, or maximum taker fee for a taker order. */
        uint256 takerProtocolFee;
        /* Order fee recipient or zero address for taker order. */
        address feeRecipient;
        /* Fee method (protocol token or split fee). */
        FeeMethod feeMethod;
        /* Side (buy/sell). */
        SaleKindInterface.Side side;
        /* Kind of sale. */
        SaleKindInterface.SaleKind saleKind;
        /* Target. */
        address target;
        /* HowToCall. */
        AuthenticatedProxy.HowToCall howToCall;
        /* Calldata. */
        bytes calldata;
        /* Calldata replacement pattern, or an empty byte array for no replacement. */
        bytes replacementPattern;
        /* Static call target, zero-address for no static call. */
        address staticTarget;
        /* Static call extra data. */
        bytes staticExtradata;
        /* Token used to pay for the order, or the zero-address as a sentinel value for Ether. */
        address paymentToken;
        /* Base price of the order (in paymentTokens). */
        uint256 basePrice;
        /* Auction extra parameter - minimum bid increment for English auctions, starting/ending price difference. */
        uint256 extra;
        /* Listing timestamp. */
        uint256 listingTime;
        /* Expiration timestamp - 0 for no expiry. */
        uint256 expirationTime;
        /* Order salt, used to prevent duplicate hashes. */
        uint256 salt;
    }

    event OrderApprovedPartOne(
        bytes32 indexed hash,
        address exchange,
        address indexed maker,
        address taker,
        uint256 makerRelayerFee,
        uint256 takerRelayerFee,
        uint256 makerProtocolFee,
        uint256 takerProtocolFee,
        address indexed feeRecipient,
        FeeMethod feeMethod,
        SaleKindInterface.Side side,
        SaleKindInterface.SaleKind saleKind,
        address target
    );
    event OrderApprovedPartTwo(
        bytes32 indexed hash,
        AuthenticatedProxy.HowToCall howToCall,
        bytes calldata,
        bytes replacementPattern,
        address staticTarget,
        bytes staticExtradata,
        address paymentToken,
        uint256 basePrice,
        uint256 extra,
        uint256 listingTime,
        uint256 expirationTime,
        uint256 salt,
        bool orderbookInclusionDesired
    );
    event OrderCancelled(bytes32 indexed hash);
    event OrdersMatched(
        bytes32 buyHash,
        bytes32 sellHash,
        address indexed maker,
        address indexed taker,
        uint256 price,
        bytes32 indexed metadata
    );

  
    function changeMinimumMakerProtocolFee(uint256 newMinimumMakerProtocolFee)
        public
        onlyOwner
    {
        minimumMakerProtocolFee = newMinimumMakerProtocolFee;
    }

    function changeMinimumTakerProtocolFee(uint256 newMinimumTakerProtocolFee)
        public
        onlyOwner
    {
        minimumTakerProtocolFee = newMinimumTakerProtocolFee;
    }

    function changeProtocolFeeRecipient(address newProtocolFeeRecipient)
        public
        onlyOwner
    {
        protocolFeeRecipient = newProtocolFeeRecipient;
    }

    function transferTokens(
        address token,
        address from,
        address to,
        uint256 amount
    ) internal {
        if (amount > 0) {
            require(tokenTransferProxy.transferFrom(token, from, to, amount),"wef");
        }
    }

    function chargeProtocolFee(
        address from,
        address to,
        uint256 amount
    ) internal {
        transferTokens(exchangeToken, from, to, amount);
    }

    function staticCall(
        address target,
        bytes memory calldata,
        bytes memory extradata
    ) public view returns (bool result) {
        bytes memory combined = new bytes(calldata.length + extradata.length);
        uint256 index;
        assembly {
            index := add(combined, 0x20)
        }
        index = ArrayUtils.unsafeWriteBytes(index, extradata);
        ArrayUtils.unsafeWriteBytes(index, calldata);
        assembly {
            result := staticcall(
                gas,
                target,
                add(combined, 0x20),
                mload(combined),
                mload(0x40),
                0
            )
        }
        return result;
    }

    function sizeOf(Order memory order) internal pure returns (uint256) {
        return ((0x14 * 7) +
            (0x20 * 9) +
            4 +
            order.calldata.length +
            order.replacementPattern.length +
            order.staticExtradata.length);
    }

   
    function hashOrder(Order memory order)
        internal
        pure
        returns (bytes32 hash)
    {
        /* Unfortunately abi.encodePacked doesn't work here, stack size constraints. */
        uint256 size = sizeOf(order);
        bytes memory array = new bytes(size);
        uint256 index;
        assembly {
            index := add(array, 0x20)
        }
        index = ArrayUtils.unsafeWriteAddress(index, order.exchange);
        index = ArrayUtils.unsafeWriteAddress(index, order.maker);
        index = ArrayUtils.unsafeWriteAddress(index, order.taker);
        index = ArrayUtils.unsafeWriteUint(index, order.makerRelayerFee);
        index = ArrayUtils.unsafeWriteUint(index, order.takerRelayerFee);
        index = ArrayUtils.unsafeWriteUint(index, order.makerProtocolFee);
        index = ArrayUtils.unsafeWriteUint(index, order.takerProtocolFee);
        index = ArrayUtils.unsafeWriteAddress(index, order.feeRecipient);
        index = ArrayUtils.unsafeWriteUint8(index, uint8(order.feeMethod));
        index = ArrayUtils.unsafeWriteUint8(index, uint8(order.side));
        index = ArrayUtils.unsafeWriteUint8(index, uint8(order.saleKind));
        index = ArrayUtils.unsafeWriteAddress(index, order.target);
        index = ArrayUtils.unsafeWriteUint8(index, uint8(order.howToCall));
        index = ArrayUtils.unsafeWriteBytes(index, order.calldata);
        index = ArrayUtils.unsafeWriteBytes(index, order.replacementPattern);
        index = ArrayUtils.unsafeWriteAddress(index, order.staticTarget);
        index = ArrayUtils.unsafeWriteBytes(index, order.staticExtradata);
        index = ArrayUtils.unsafeWriteAddress(index, order.paymentToken);
        index = ArrayUtils.unsafeWriteUint(index, order.basePrice);
        index = ArrayUtils.unsafeWriteUint(index, order.extra);
        index = ArrayUtils.unsafeWriteUint(index, order.listingTime);
        index = ArrayUtils.unsafeWriteUint(index, order.expirationTime);
        index = ArrayUtils.unsafeWriteUint(index, order.salt);
        assembly {
            hash := keccak256(add(array, 0x20), size)
        }
        return hash;
    }

    function hashToSign(Order memory order) internal pure returns (bytes32) {
        return keccak256("\x19Ethereum Signed Message:\n32", hashOrder(order));
    }

    function requireValidOrder(Order memory order, Sig memory sig)
        internal
        view
        returns (bytes32)
    {
        bytes32 hash = hashToSign(order);
        require(validateOrder(hash, order, sig),"invalid order");
        return hash;
    }

    function validateOrderParameters(Order memory order)
        internal
        view
        returns (bool)
    {
        /* Order must be targeted at this protocol version (this Exchange contract). */
        if (order.exchange != address(this)) {
            return false;
        }

        /* Order must possess valid sale kind parameter combination. */
        if (
            !SaleKindInterface.validateParameters(
                order.saleKind,
                order.expirationTime
            )
        ) {
            return false;
        }

        /* If using the split fee method, order must have sufficient protocol fees. */
        if (
            order.feeMethod == FeeMethod.SplitFee &&
            (order.makerProtocolFee < minimumMakerProtocolFee ||
                order.takerProtocolFee < minimumTakerProtocolFee)
        ) {
            return false;
        }

        return true;
    }

    function validateOrder(
        bytes32 hash,
        Order memory order,
        Sig memory sig
    ) internal view returns (bool) {
        
        if (!validateOrderParameters(order)) {
            return false;
        }

        /* Order must have not been canceled or already filled. */
        if (cancelledOrFinalized[hash]) {
            return false;
        }

      
        if (approvedOrders[hash]) {
            return true;
        }

        /* or (b) ECDSA-signed by maker. */
        if (ecrecover(hash, sig.v, sig.r, sig.s) == order.maker) {
            return true;
        }

        return false;
    }

  
    function approveOrder(Order memory order, bool orderbookInclusionDesired)
        internal
    {
        /* CHECKS */

        /* Assert sender is authorized to approve order. */
        require(msg.sender == order.maker,"not approved ");

        /* Calculate order hash. */
        bytes32 hash = hashToSign(order);

        /* Assert order has not already been approved. */
        require(!approvedOrders[hash],"approved wrong");

        /* EFFECTS */

        /* Mark order as approved. */
        approvedOrders[hash] = true;

        /* Log approval event. Must be split in two due to Solidity stack size limitations. */
        {
            emit OrderApprovedPartOne(
                hash,
                order.exchange,
                order.maker,
                order.taker,
                order.makerRelayerFee,
                order.takerRelayerFee,
                order.makerProtocolFee,
                order.takerProtocolFee,
                order.feeRecipient,
                order.feeMethod,
                order.side,
                order.saleKind,
                order.target
            );
        }
        {
            emit OrderApprovedPartTwo(
                hash,
                order.howToCall,
                order.calldata,
                order.replacementPattern,
                order.staticTarget,
                order.staticExtradata,
                order.paymentToken,
                order.basePrice,
                order.extra,
                order.listingTime,
                order.expirationTime,
                order.salt,
                orderbookInclusionDesired
            );
        }
    }

    function cancelOrder(Order memory order, Sig memory sig) internal {
        /* CHECKS */

        /* Calculate order hash. */
        bytes32 hash = requireValidOrder(order, sig);

        /* Assert sender is authorized to cancel order. */
        require(msg.sender == order.maker,"cant cancel");

        /* EFFECTS */

        /* Mark order as cancelled, preventing it from being matched. */
        cancelledOrFinalized[hash] = true;

        /* Log cancel event. */
        emit OrderCancelled(hash);
    }

   
    function calculateCurrentPrice(Order memory order)
        internal
        view
        returns (uint256)
    {
        return
            SaleKindInterface.calculateFinalPrice(
                order.side,
                order.saleKind,
                order.basePrice,
                order.extra,
                order.listingTime,
                order.expirationTime
            );
    }

  
    function calculateMatchPrice(Order memory buy, Order memory sell)
        internal
        view
        returns (uint256)
    {
        /* Calculate sell price. */
        uint256 sellPrice = SaleKindInterface.calculateFinalPrice(
            sell.side,
            sell.saleKind,
            sell.basePrice,
            sell.extra,
            sell.listingTime,
            sell.expirationTime
        );

        /* Calculate buy price. */
        uint256 buyPrice = SaleKindInterface.calculateFinalPrice(
            buy.side,
            buy.saleKind,
            buy.basePrice,
            buy.extra,
            buy.listingTime,
            buy.expirationTime
        );

        /* Require price cross. */
        require(buyPrice >= sellPrice,"price in order");

        /* Maker/taker priority. */
        return sell.feeRecipient != address(0) ? sellPrice : buyPrice;
    }

   
    function executeFundsTransfer(Order memory buy, Order memory sell)
        internal
        returns (uint256)
    {
        /* Only payable in the special case of unwrapped Ether. */
        if (sell.paymentToken != address(0)) {
            require(msg.value == 0,"paymant token");
        }

        /* Calculate match price. */
        uint256 price = calculateMatchPrice(buy, sell);

        /* If paying using a token (not Ether), transfer tokens. This is done prior to fee payments to that a seller will have tokens before being charged fees. */
        if (price > 0 && sell.paymentToken != address(0)) {
            transferTokens(sell.paymentToken, buy.maker, sell.maker, price);
        }

        /* Amount that will be received by seller (for Ether). */
        uint256 receiveAmount = price;

        /* Amount that must be sent by buyer (for Ether). */
        uint256 requiredAmount = price;

        /* Determine maker/taker and charge fees accordingly. */
        if (sell.feeRecipient != address(0)) {
            /* Sell-side order is maker. */

            /* Assert taker fee is less than or equal to maximum fee specified by buyer. */
            require(sell.takerRelayerFee <= buy.takerRelayerFee,"wrong fee sell/buy");

            if (sell.feeMethod == FeeMethod.SplitFee) {
                /* Assert taker fee is less than or equal to maximum fee specified by buyer. */
                require(sell.takerProtocolFee <= buy.takerProtocolFee,"wrongbuy protcol fee taker");

                /* Maker fees are deducted from the token amount that the maker receives. Taker fees are extra tokens that must be paid by the taker. */

                if (sell.makerRelayerFee > 0) {
                    uint256 makerRelayerFee = SafeMath.div(
                        SafeMath.mul(sell.makerRelayerFee, price),
                        INVERSE_BASIS_POINT
                    );
                    if (sell.paymentToken == address(0)) {
                        receiveAmount = SafeMath.sub(
                            receiveAmount,
                            makerRelayerFee
                        );
                        sell.feeRecipient.transfer(makerRelayerFee);
                    } else {
                        transferTokens(
                            sell.paymentToken,
                            sell.maker,
                            sell.feeRecipient,
                            makerRelayerFee
                        );
                    }
                }

                if (sell.takerRelayerFee > 0) {
                    uint256 takerRelayerFee = SafeMath.div(
                        SafeMath.mul(sell.takerRelayerFee, price),
                        INVERSE_BASIS_POINT
                    );
                    if (sell.paymentToken == address(0)) {
                        requiredAmount = SafeMath.add(
                            requiredAmount,
                            takerRelayerFee
                        );
                        sell.feeRecipient.transfer(takerRelayerFee);
                    } else {
                        transferTokens(
                            sell.paymentToken,
                            buy.maker,
                            sell.feeRecipient,
                            takerRelayerFee
                        );
                    }
                }

                if (sell.makerProtocolFee > 0) {
                    uint256 makerProtocolFee = SafeMath.div(
                        SafeMath.mul(sell.makerProtocolFee, price),
                        INVERSE_BASIS_POINT
                    );
                    if (sell.paymentToken == address(0)) {
                        receiveAmount = SafeMath.sub(
                            receiveAmount,
                            makerProtocolFee
                        );
                        protocolFeeRecipient.transfer(makerProtocolFee);
                    } else {
                        transferTokens(
                            sell.paymentToken,
                            sell.maker,
                            protocolFeeRecipient,
                            makerProtocolFee
                        );
                    }
                }

                if (sell.takerProtocolFee > 0) {
                    uint256 takerProtocolFee = SafeMath.div(
                        SafeMath.mul(sell.takerProtocolFee, price),
                        INVERSE_BASIS_POINT
                    );
                    if (sell.paymentToken == address(0)) {
                        requiredAmount = SafeMath.add(
                            requiredAmount,
                            takerProtocolFee
                        );
                        protocolFeeRecipient.transfer(takerProtocolFee);
                    } else {
                        transferTokens(
                            sell.paymentToken,
                            buy.maker,
                            protocolFeeRecipient,
                            takerProtocolFee
                        );
                    }
                }
            } else {
                /* Charge maker fee to seller. */
                chargeProtocolFee(
                    sell.maker,
                    sell.feeRecipient,
                    sell.makerRelayerFee
                );

                /* Charge taker fee to buyer. */
                chargeProtocolFee(
                    buy.maker,
                    sell.feeRecipient,
                    sell.takerRelayerFee
                );
            }
        } else {
            /* Buy-side order is maker. */

            /* Assert taker fee is less than or equal to maximum fee specified by seller. */
            require(buy.takerRelayerFee <= sell.takerRelayerFee,"qwdqwd");

            if (sell.feeMethod == FeeMethod.SplitFee) {
                /* The Exchange does not escrow Ether, so direct Ether can only be used to with sell-side maker / buy-side taker orders. */
                require(sell.paymentToken != address(0),"evws");

                /* Assert taker fee is less than or equal to maximum fee specified by seller. */
                require(buy.takerProtocolFee <= sell.takerProtocolFee,"wegfwe");

                if (buy.makerRelayerFee > 0) {
                    makerRelayerFee = SafeMath.div(
                        SafeMath.mul(buy.makerRelayerFee, price),
                        INVERSE_BASIS_POINT
                    );
                    transferTokens(
                        sell.paymentToken,
                        buy.maker,
                        buy.feeRecipient,
                        makerRelayerFee
                    );
                }

                if (buy.takerRelayerFee > 0) {
                    takerRelayerFee = SafeMath.div(
                        SafeMath.mul(buy.takerRelayerFee, price),
                        INVERSE_BASIS_POINT
                    );
                    transferTokens(
                        sell.paymentToken,
                        sell.maker,
                        buy.feeRecipient,
                        takerRelayerFee
                    );
                }

                if (buy.makerProtocolFee > 0) {
                    makerProtocolFee = SafeMath.div(
                        SafeMath.mul(buy.makerProtocolFee, price),
                        INVERSE_BASIS_POINT
                    );
                    transferTokens(
                        sell.paymentToken,
                        buy.maker,
                        protocolFeeRecipient,
                        makerProtocolFee
                    );
                }

                if (buy.takerProtocolFee > 0) {
                    takerProtocolFee = SafeMath.div(
                        SafeMath.mul(buy.takerProtocolFee, price),
                        INVERSE_BASIS_POINT
                    );
                    transferTokens(
                        sell.paymentToken,
                        sell.maker,
                        protocolFeeRecipient,
                        takerProtocolFee
                    );
                }
            } else {
                /* Charge maker fee to buyer. */
                chargeProtocolFee(
                    buy.maker,
                    buy.feeRecipient,
                    buy.makerRelayerFee
                );

                /* Charge taker fee to seller. */
                chargeProtocolFee(
                    sell.maker,
                    buy.feeRecipient,
                    buy.takerRelayerFee
                );
            }
        }

        if (sell.paymentToken == address(0)) {
            /* Special-case Ether, order must be matched by buyer. */
            require(msg.value >= requiredAmount,"sdvs");
            sell.maker.transfer(receiveAmount);
            /* Allow overshoot for variable-price auctions, refund difference. */
            uint256 diff = SafeMath.sub(msg.value, requiredAmount);
            if (diff > 0) {
                buy.maker.transfer(diff);
            }
        }

        /* This contract should never hold Ether, however, we cannot assert this, since it is impossible to prevent anyone from sending Ether e.g. with selfdestruct. */

        return price;
    }

    
    function ordersCanMatch(Order memory buy, Order memory sell)
        internal
        view
        returns (bool)
    {
        return (/* Must be opposite-side. */
        (buy.side == SaleKindInterface.Side.Buy &&
            sell.side == SaleKindInterface.Side.Sell) &&
            /* Must use same fee method. */
            (buy.feeMethod == sell.feeMethod) &&
            /* Must use same payment token. */
            (buy.paymentToken == sell.paymentToken) &&
            /* Must match maker/taker addresses. */
            (sell.taker == address(0) || sell.taker == buy.maker) &&
            (buy.taker == address(0) || buy.taker == sell.maker) &&
            /* One must be maker and the other must be taker (no bool XOR in Solidity). */
            ((sell.feeRecipient == address(0) &&
                buy.feeRecipient != address(0)) ||
                (sell.feeRecipient != address(0) &&
                    buy.feeRecipient == address(0))) &&
            /* Must match target. */
            (buy.target == sell.target) &&
            /* Must match howToCall. */
            (buy.howToCall == sell.howToCall) &&
            /* Buy-side order must be settleable. */
            SaleKindInterface.canSettleOrder(
                buy.listingTime,
                buy.expirationTime
            ) &&
            /* Sell-side order must be settleable. */
            SaleKindInterface.canSettleOrder(
                sell.listingTime,
                sell.expirationTime
            ));
    }

    function atomicMatch(
        Order memory buy,
        Sig memory buySig,
        Order memory sell,
        Sig memory sellSig,
        bytes32 metadata
    ) internal reentrancyGuard {
        /* CHECKS */

        /* Ensure buy order validity and calculate hash if necessary. */
        bytes32 buyHash;
        if (buy.maker == msg.sender) {
            require(validateOrderParameters(buy),"Buyhash bad");
        } else {
            buyHash = requireValidOrder(buy, buySig);
        }

        /* Ensure sell order validity and calculate hash if necessary. */
        bytes32 sellHash;
        if (sell.maker == msg.sender) {
            require(validateOrderParameters(sell),"SEllhash bad");
        } else {
            sellHash = requireValidOrder(sell, sellSig);
        }
        /* Must be matchable. */
        require(ordersCanMatch(buy, sell),"buy sell mis");

        /* Target must exist (prevent malicious selfdestructs just prior to order settlement). */
        uint256 size;
        address target = sell.target;
        assembly {
            size := extcodesize(target)
        }
        require(size > 0,"sife=0");

        /* Must match calldata after replacement, if specified. */

        if (buy.replacementPattern.length > 0) {
            ArrayUtils.guardedArrayReplace(
                buy.calldata,
                sell.calldata,
                buy.replacementPattern
            );
        }
        if (sell.replacementPattern.length > 0) {
            ArrayUtils.guardedArrayReplace(
                sell.calldata,
                buy.calldata,
                sell.replacementPattern
            );
        }
        require(ArrayUtils.arrayEq(buy.calldata, sell.calldata),"buysellcalldatamismatch");

        /* Retrieve delegateProxy contract. */
        OwnableDelegateProxy delegateProxy = registry.proxies(sell.maker);

        /* Proxy must exist. */
        require(delegateProxy != address(0),"delegateproxyaddresserror");

        /* Assert implementation. */
        require(
            delegateProxy.implementation() ==
                registry.delegateProxyImplementation(),"delegateproxybadimplementation"
        );

        /* Access the passthrough AuthenticatedProxy. */
        AuthenticatedProxy proxy = AuthenticatedProxy(delegateProxy);

        /* EFFECTS */

        /* Mark previously signed or approved orders as finalized. */
        if (msg.sender != buy.maker) {
            cancelledOrFinalized[buyHash] = true;
        }
        if (msg.sender != sell.maker) {
            cancelledOrFinalized[sellHash] = true;
        }

        /* Execute funds transfer and pay fees. */
        uint256 price = executeFundsTransfer(buy, sell);

        /* Execute specified call through proxy. */
        require(proxy.proxy(sell.target, sell.howToCall, sell.calldata),"callproxyfailed");

        /* Log match event. */
        emit OrdersMatched(
            buyHash,
            sellHash,
            sell.feeRecipient != address(0) ? sell.maker : buy.maker,
            sell.feeRecipient != address(0) ? buy.maker : sell.maker,
            price,
            metadata
        );
    }
    
}

pragma solidity 0.4.26;

import "./ExchangeCore.sol";

/**
 * @title Exchange
 * @author Project Wyvern Developers
 */
contract Exchange is ExchangeCore {
    
    function guardedArrayReplace(bytes array, bytes desired, bytes mask)
        public
        pure
        returns (bytes)
    {
        ArrayUtils.guardedArrayReplace(array, desired, mask);
        return array;
    }

    function testCopy(bytes arrToCopy)
        public
        pure
        returns (bytes)
    {
        bytes memory arr = new bytes(arrToCopy.length);
        uint index;
        assembly {
            index := add(arr, 0x20)
        }
        ArrayUtils.unsafeWriteBytes(index, arrToCopy);
        return arr;
    }
    function testCopyAddress(address addr)
        public
        pure
        returns (bytes)
    {
        bytes memory arr = new bytes(0x14);
        uint index;
        assembly {
            index := add(arr, 0x20)
        }
        ArrayUtils.unsafeWriteAddress(index, addr);
        return arr;
    }

    function calculateFinalPrice(SaleKindInterface.Side side, SaleKindInterface.SaleKind saleKind, uint basePrice, uint extra, uint listingTime, uint expirationTime)
        public
        view
        returns (uint)
    {
        return SaleKindInterface.calculateFinalPrice(side, saleKind, basePrice, extra, listingTime, expirationTime);
    }
    function hashOrder_(
        address[7] addrs,
        uint[9] uints,
        FeeMethod feeMethod,
        SaleKindInterface.Side side,
        SaleKindInterface.SaleKind saleKind,
        AuthenticatedProxy.HowToCall howToCall,
        bytes calldata,
        bytes replacementPattern,
        bytes staticExtradata)
        public
        pure
        returns (bytes32)
    {
        return hashOrder(
          Order(addrs[0], addrs[1], addrs[2], uints[0], uints[1], uints[2], uints[3], addrs[3], feeMethod, side, saleKind, addrs[4], howToCall, calldata, replacementPattern, addrs[5], staticExtradata, ERC20(addrs[6]), uints[4], uints[5], uints[6], uints[7], uints[8])
        );
    }

    function hashToSign_(
        address[7] addrs,
        uint[9] uints,
        FeeMethod feeMethod,
        SaleKindInterface.Side side,
        SaleKindInterface.SaleKind saleKind,
        AuthenticatedProxy.HowToCall howToCall,
        bytes calldata,
        bytes replacementPattern,
        bytes staticExtradata)
        public
        pure
        returns (bytes32)
    { 
        return hashToSign(
          Order(addrs[0], addrs[1], addrs[2], uints[0], uints[1], uints[2], uints[3], addrs[3], feeMethod, side, saleKind, addrs[4], howToCall, calldata, replacementPattern, addrs[5], staticExtradata, ERC20(addrs[6]), uints[4], uints[5], uints[6], uints[7], uints[8])
        );
    }

    function validateOrderParameters_ (
        address[7] addrs,
        uint[9] uints,
        FeeMethod feeMethod,
        SaleKindInterface.Side side,
        SaleKindInterface.SaleKind saleKind,
        AuthenticatedProxy.HowToCall howToCall,
        bytes calldata,
        bytes replacementPattern,
        bytes staticExtradata)
        view
        public
        returns (bool)
    {
        Order memory order = Order(addrs[0], addrs[1], addrs[2], uints[0], uints[1], uints[2], uints[3], addrs[3], feeMethod, side, saleKind, addrs[4], howToCall, calldata, replacementPattern, addrs[5], staticExtradata, ERC20(addrs[6]), uints[4], uints[5], uints[6], uints[7], uints[8]);
        return validateOrderParameters(
          order
        );
    }

    function validateOrder_ (
        address[7] addrs,
        uint[9] uints,
        FeeMethod feeMethod,
        SaleKindInterface.Side side,
        SaleKindInterface.SaleKind saleKind,
        AuthenticatedProxy.HowToCall howToCall,
        bytes calldata,
        bytes replacementPattern,
        bytes staticExtradata,
        uint8 v,
        bytes32 r,
        bytes32 s)
        view
        public
        returns (bool)
    {
        Order memory order = Order(addrs[0], addrs[1], addrs[2], uints[0], uints[1], uints[2], uints[3], addrs[3], feeMethod, side, saleKind, addrs[4], howToCall, calldata, replacementPattern, addrs[5], staticExtradata, ERC20(addrs[6]), uints[4], uints[5], uints[6], uints[7], uints[8]);
        return validateOrder(
          hashToSign(order),
          order,
          Sig(v, r, s)
        );
    }

    function approveOrder_ (
        address[7] addrs,
        uint[9] uints,
        FeeMethod feeMethod,
        SaleKindInterface.Side side,
        SaleKindInterface.SaleKind saleKind,
        AuthenticatedProxy.HowToCall howToCall,
        bytes calldata,
        bytes replacementPattern,
        bytes staticExtradata,
        bool orderbookInclusionDesired) 
        public
    {
        Order memory order = Order(addrs[0], addrs[1], addrs[2], uints[0], uints[1], uints[2], uints[3], addrs[3], feeMethod, side, saleKind, addrs[4], howToCall, calldata, replacementPattern, addrs[5], staticExtradata, ERC20(addrs[6]), uints[4], uints[5], uints[6], uints[7], uints[8]);
        return approveOrder(order, orderbookInclusionDesired);
    }

    function cancelOrder_(
        address[7] addrs,
        uint[9] uints,
        FeeMethod feeMethod,
        SaleKindInterface.Side side,
        SaleKindInterface.SaleKind saleKind,
        AuthenticatedProxy.HowToCall howToCall,
        bytes calldata,
        bytes replacementPattern,
        bytes staticExtradata,
        uint8 v,
        bytes32 r,
        bytes32 s)
        public
    {

        return cancelOrder(
          Order(addrs[0], addrs[1], addrs[2], uints[0], uints[1], uints[2], uints[3], addrs[3], feeMethod, side, saleKind, addrs[4], howToCall, calldata, replacementPattern, addrs[5], staticExtradata, ERC20(addrs[6]), uints[4], uints[5], uints[6], uints[7], uints[8]),
          Sig(v, r, s)
        );
    }

  
    function calculateCurrentPrice_(
        address[7] addrs,
        uint[9] uints,
        FeeMethod feeMethod,
        SaleKindInterface.Side side,
        SaleKindInterface.SaleKind saleKind,
        AuthenticatedProxy.HowToCall howToCall,
        bytes calldata,
        bytes replacementPattern,
        bytes staticExtradata)
        public
        view
        returns (uint)
    {
        return calculateCurrentPrice(
          Order(addrs[0], addrs[1], addrs[2], uints[0], uints[1], uints[2], uints[3], addrs[3], feeMethod, side, saleKind, addrs[4], howToCall, calldata, replacementPattern, addrs[5], staticExtradata, ERC20(addrs[6]), uints[4], uints[5], uints[6], uints[7], uints[8])
        );
    }

    function ordersCanMatch_(
        address[14] addrs,
        uint[18] uints,
        uint8[8] feeMethodsSidesKindsHowToCalls,
        bytes calldataBuy,
        bytes calldataSell,
        bytes replacementPatternBuy,
        bytes replacementPatternSell,
        bytes staticExtradataBuy,
        bytes staticExtradataSell)
        public
        view
        returns (bool)
    {
        Order memory buy = Order(addrs[0], addrs[1], addrs[2], uints[0], uints[1], uints[2], uints[3], addrs[3], FeeMethod(feeMethodsSidesKindsHowToCalls[0]), SaleKindInterface.Side(feeMethodsSidesKindsHowToCalls[1]), SaleKindInterface.SaleKind(feeMethodsSidesKindsHowToCalls[2]), addrs[4], AuthenticatedProxy.HowToCall(feeMethodsSidesKindsHowToCalls[3]), calldataBuy, replacementPatternBuy, addrs[5], staticExtradataBuy, ERC20(addrs[6]), uints[4], uints[5], uints[6], uints[7], uints[8]);
        Order memory sell = Order(addrs[7], addrs[8], addrs[9], uints[9], uints[10], uints[11], uints[12], addrs[10], FeeMethod(feeMethodsSidesKindsHowToCalls[4]), SaleKindInterface.Side(feeMethodsSidesKindsHowToCalls[5]), SaleKindInterface.SaleKind(feeMethodsSidesKindsHowToCalls[6]), addrs[11], AuthenticatedProxy.HowToCall(feeMethodsSidesKindsHowToCalls[7]), calldataSell, replacementPatternSell, addrs[12], staticExtradataSell, ERC20(addrs[13]), uints[13], uints[14], uints[15], uints[16], uints[17]);
        return ordersCanMatch(
          buy,
          sell
        );
    }

    function orderCalldataCanMatch(bytes buyCalldata, bytes buyReplacementPattern, bytes sellCalldata, bytes sellReplacementPattern)
        public
        pure
        returns (bool)
    {
        if (buyReplacementPattern.length > 0) {
          ArrayUtils.guardedArrayReplace(buyCalldata, sellCalldata, buyReplacementPattern);
        }
        if (sellReplacementPattern.length > 0) {
          ArrayUtils.guardedArrayReplace(sellCalldata, buyCalldata, sellReplacementPattern);
        }
        return ArrayUtils.arrayEq(buyCalldata, sellCalldata);
    }

    function calculateMatchPrice_(
        address[14] addrs,
        uint[18] uints,
        uint8[8] feeMethodsSidesKindsHowToCalls,
        bytes calldataBuy,
        bytes calldataSell,
        bytes replacementPatternBuy,
        bytes replacementPatternSell,
        bytes staticExtradataBuy,
        bytes staticExtradataSell)
        public
        view
        returns (uint)
    {
        Order memory buy = Order(addrs[0], addrs[1], addrs[2], uints[0], uints[1], uints[2], uints[3], addrs[3], FeeMethod(feeMethodsSidesKindsHowToCalls[0]), SaleKindInterface.Side(feeMethodsSidesKindsHowToCalls[1]), SaleKindInterface.SaleKind(feeMethodsSidesKindsHowToCalls[2]), addrs[4], AuthenticatedProxy.HowToCall(feeMethodsSidesKindsHowToCalls[3]), calldataBuy, replacementPatternBuy, addrs[5], staticExtradataBuy, ERC20(addrs[6]), uints[4], uints[5], uints[6], uints[7], uints[8]);
        Order memory sell = Order(addrs[7], addrs[8], addrs[9], uints[9], uints[10], uints[11], uints[12], addrs[10], FeeMethod(feeMethodsSidesKindsHowToCalls[4]), SaleKindInterface.Side(feeMethodsSidesKindsHowToCalls[5]), SaleKindInterface.SaleKind(feeMethodsSidesKindsHowToCalls[6]), addrs[11], AuthenticatedProxy.HowToCall(feeMethodsSidesKindsHowToCalls[7]), calldataSell, replacementPatternSell, addrs[12], staticExtradataSell, ERC20(addrs[13]), uints[13], uints[14], uints[15], uints[16], uints[17]);
        return calculateMatchPrice(
          buy,
          sell
        );
    }

    function atomicMatch_(
        address[14] addrs,
        uint[18] uints,
        uint8[8] feeMethodsSidesKindsHowToCalls,
        bytes calldataBuy,
        bytes calldataSell,
        bytes replacementPatternBuy,
        bytes replacementPatternSell,
        bytes staticExtradataBuy,
        bytes staticExtradataSell,
        uint8[2] vs,
        bytes32[5] rssMetadata)
        public
        payable
    {

        return atomicMatch(
          Order(addrs[0], addrs[1], addrs[2], uints[0], uints[1], uints[2], uints[3], addrs[3], FeeMethod(feeMethodsSidesKindsHowToCalls[0]), SaleKindInterface.Side(feeMethodsSidesKindsHowToCalls[1]), SaleKindInterface.SaleKind(feeMethodsSidesKindsHowToCalls[2]), addrs[4], AuthenticatedProxy.HowToCall(feeMethodsSidesKindsHowToCalls[3]), calldataBuy, replacementPatternBuy, addrs[5], staticExtradataBuy, ERC20(addrs[6]), uints[4], uints[5], uints[6], uints[7], uints[8]),
          Sig(vs[0], rssMetadata[0], rssMetadata[1]),
          Order(addrs[7], addrs[8], addrs[9], uints[9], uints[10], uints[11], uints[12], addrs[10], FeeMethod(feeMethodsSidesKindsHowToCalls[4]), SaleKindInterface.Side(feeMethodsSidesKindsHowToCalls[5]), SaleKindInterface.SaleKind(feeMethodsSidesKindsHowToCalls[6]), addrs[11], AuthenticatedProxy.HowToCall(feeMethodsSidesKindsHowToCalls[7]), calldataSell, replacementPatternSell, addrs[12], staticExtradataSell, ERC20(addrs[13]), uints[13], uints[14], uints[15], uints[16], uints[17]),
          Sig(vs[1], rssMetadata[2], rssMetadata[3]),
          rssMetadata[4]
        );
    }
    
}

/*

  Token recipient. Modified very slightly from the example on http://ethereum.org/dao (just to index log parameters).

*/

pragma solidity 0.4.26;

import "../../lib/token/ERC20/ERC20.sol";


contract TokenRecipient {
    event ReceivedEther(address indexed sender, uint256 amount);
    event ReceivedTokens(
        address indexed from,
        uint256 value,
        address indexed token,
        bytes extraData
    );

    /**
     * @dev Receive tokens and generate a log event
     * @param from Address from which to transfer tokens
     * @param value Amount of tokens to transfer
     * @param token Address of token
     * @param extraData Additional data to log
     */
    function receiveApproval(
        address from,
        uint256 value,
        address token,
        bytes extraData
    ) public {
        ERC20 t = ERC20(token);
        require(t.transferFrom(from, this, value));
        emit ReceivedTokens(from, value, token, extraData);
    }

    /**
     * @dev Receive Ether and generate a log event
     */
    function() public payable {
        emit ReceivedEther(msg.sender, msg.value);
    }
}

/*

  Simple contract extension to provide a contract-global reentrancy guard on functions.

*/

pragma solidity 0.4.26;

/**
 * @title ReentrancyGuarded
 * @author Project Wyvern Developers
 */
contract ReentrancyGuarded {

    bool reentrancyLock = false;

    /* Prevent a contract function from being reentrant-called. */
    modifier reentrancyGuard {
        if (reentrancyLock) {
            revert();
        }
        reentrancyLock = true;
        _;
        reentrancyLock = false;
    }

}

/*

  Various functions for manipulating arrays in Solidity.
  This library is completely inlined and does not need to be deployed or linked.

*/

pragma solidity 0.4.26;

import "../../lib/math/SafeMath.sol";

/**
 * @title ArrayUtils
 * @author Project Wyvern Developers
 */
library ArrayUtils {

    /**
     * Replace bytes in an array with bytes in another array, guarded by a bitmask
     * Efficiency of this function is a bit unpredictable because of the EVM's word-specific model (arrays under 32 bytes will be slower)
     * 
     * @dev Mask must be the size of the byte array. A nonzero byte means the byte array can be changed.
     * @param array The original array
     * @param desired The target array
     * @param mask The mask specifying which bits can be changed
     * @return The updated byte array (the parameter will be modified inplace)
     */
    function guardedArrayReplace(bytes memory array, bytes memory desired, bytes memory mask)
        internal
        pure
    {
        require(array.length == desired.length,"missmatch array lenght");
        require(array.length == mask.length,"missmatch masklength");

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

    /**
     * Test if two arrays are equal
     * Source: https://github.com/GNSPS/solidity-bytes-utils/blob/master/contracts/BytesLib.sol
     * 
     * @dev Arrays must be of equal length, otherwise will return false
     * @param a First array
     * @param b Second array
     * @return Whether or not all bytes in the arrays are equal
     */
    function arrayEq(bytes memory a, bytes memory b)
        internal
        pure
        returns (bool)
    {
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

    /**
     * Unsafe write byte array into a memory location
     *
     * @param index Memory location
     * @param source Byte array to write
     * @return End memory index
     */
    function unsafeWriteBytes(uint index, bytes source)
        internal
        pure
        returns (uint)
    {
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

    /**
     * Unsafe write address into a memory location
     *
     * @param index Memory location
     * @param source Address to write
     * @return End memory index
     */
    function unsafeWriteAddress(uint index, address source)
        internal
        pure
        returns (uint)
    {
        uint conv = uint(source) << 0x60;
        assembly {
            mstore(index, conv)
            index := add(index, 0x14)
        }
        return index;
    }

    /**
     * Unsafe write uint into a memory location
     *
     * @param index Memory location
     * @param source uint to write
     * @return End memory index
     */
    function unsafeWriteUint(uint index, uint source)
        internal
        pure
        returns (uint)
    {
        assembly {
            mstore(index, source)
            index := add(index, 0x20)
        }
        return index;
    }

    /**
     * Unsafe write uint8 into a memory location
     *
     * @param index Memory location
     * @param source uint8 to write
     * @return End memory index
     */
    function unsafeWriteUint8(uint index, uint8 source)
        internal
        pure
        returns (uint)
    {
        assembly {
            mstore8(index, source)
            index := add(index, 0x1)
        }
        return index;
    }

}