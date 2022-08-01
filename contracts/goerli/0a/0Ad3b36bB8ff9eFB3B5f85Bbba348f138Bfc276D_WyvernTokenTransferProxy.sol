/*

  << Project Wyvern Token Transfer Proxy >.

*/
// SPDX-License-Identifier: None
pragma solidity 0.8.12;

import "./registry/TokenTransferProxy.sol";

contract WyvernTokenTransferProxy is TokenTransferProxy {

    constructor (ProxyRegistry registryAddr)
    {
        registry = registryAddr;
    }

}

/*

  Token transfer proxy. Uses the authentication table of a ProxyRegistry contract to grant ERC20 `transferFrom` access.
  This means that users only need to authorize the proxy contract once for all future protocol versions.

*/
// SPDX-License-Identifier: None

pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "./ProxyRegistry.sol";

contract TokenTransferProxy is Context {

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
        require(registry.contracts(_msgSender()), "Callers ProxyRegistry should be true");
        return IERC20(token).transferFrom(from, to, amount);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/ContextMetaTx.sol)

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

/*

  Proxy registry; keeps a mapping of AuthenticatedProxy contracts and mapping of contracts authorized to access them.  
  
  Abstracted away from the Exchange (a) to reduce Exchange attack surface and (b) so that the Exchange contract can be upgraded without users needing to transfer assets to new proxies.

*/
// SPDX-License-Identifier: None

pragma solidity 0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./OwnableDelegateProxy.sol";
import "../common/meta-transactions/NativeMetaTransaction.sol";

/**
 * @title ProxyRegistry
 * @author Wyvern Protocol Developers
 */
contract ProxyRegistry is ContextMixin, Ownable, NativeMetaTransaction {

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


    constructor() {
        _initializeEIP712();
    }

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

    function _msgSender() internal view override returns (address sender) {
        return ContextMixin.msgSender();
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.12;

import "./EIP712Base.sol";

contract NativeMetaTransaction is EIP712Base {
    bytes32 private constant META_TRANSACTION_TYPEHASH =
    keccak256(
        bytes(
            "MetaTransaction(uint256 nonce,address from,bytes functionSignature)"
        )
    );
    event MetaTransactionExecuted(
        address userAddress,
        address payable relayerAddress,
        bytes functionSignature
    );
    mapping(address => uint256) private nonces;

    /*
     * Meta transaction structure.
     * No point of including value field here as if user is doing value transfer then he has the funds to pay for gas
     * He should call the desired function directly in that case.
     */
    struct MetaTransaction {
        uint256 nonce;
        address from;
        bytes functionSignature;
    }

    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) external payable returns (bytes memory) {
        MetaTransaction memory metaTx =
        MetaTransaction({
        nonce: nonces[userAddress],
        from: userAddress,
        functionSignature: functionSignature
        });

        require(
            verify(userAddress, metaTx, sigR, sigS, sigV),
            "Signer and signature do not match"
        );

        // increase nonce for user (to avoid re-use)
        nonces[userAddress] += 1;

        emit MetaTransactionExecuted(
            userAddress,
            payable(msg.sender),
            functionSignature
        );

        // Append userAddress and relayer address at the end to extract it from calling context
        (bool success, bytes memory returnData) =
        address(this).call(
            abi.encodePacked(functionSignature, userAddress)
        );
        require(success, "Function call not successful");

        return returnData;
    }

    function hashMetaTransaction(MetaTransaction memory metaTx)
    public
    pure
    returns (bytes32)
    {
        return
        keccak256(
            abi.encode(
                META_TRANSACTION_TYPEHASH,
                metaTx.nonce,
                metaTx.from,
                keccak256(metaTx.functionSignature)
            )
        );
    }

    function getNonce(address user) public view returns (uint256 nonce) {
        nonce = nonces[user];
    }

    function verify(
        address signer,
        MetaTransaction memory metaTx,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) public view returns (bool) {
        require(signer != address(0), "NativeMetaTransaction: INVALID_SIGNER");
        return
        signer ==
        ecrecover(
            toTypedMessageHash(hashMetaTransaction(metaTx)),
            sigV,
            sigR,
            sigS
        );
    }
}

// SPDX-License-Identifier: None
pragma solidity 0.8.12;

import "../../common/meta-transactions/ContextMixin.sol";
import "./Proxy.sol";
import "./OwnedUpgradeabilityStorage.sol";
/**
 * @title OwnedUpgradeabilityProxy
 * @dev This contract combines an upgradeability proxy with basic authorization control functionalities
 */
contract OwnedUpgradeabilityProxy 
is Proxy,
 OwnedUpgradeabilityStorage,
 ContextMixin
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

    function _msgSender() internal view returns (address sender) {
        return ContextMixin.msgSender();
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.12;

abstract contract ContextMixin {
    function msgSender() internal view returns (address payable sender) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
            // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                mload(add(array, index)),
                0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = payable(msg.sender);
        }
        return sender;
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.12;

import "./Initializable.sol";

contract EIP712Base is Initializable {
    struct EIP712Domain {
        string name;
        string version;
        address verifyingContract;
        bytes32 salt;
    }

    string public constant ERC712_NAME = "JUNGLE META-TX";

    string public constant ERC712_VERSION = "1";

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH =
    keccak256(
        bytes(
            "EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)"
        )
    );
    bytes32 internal domainSeperator;

    // supposed to be called once while initializing.
    // one of the contracts that inherits this contract follows proxy pattern
    // so it is not possible to do this in a constructor
    function _initializeEIP712() internal initializer {
        _setDomainSeperator();
    }

    function _setDomainSeperator() internal {
        domainSeperator = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(ERC712_NAME)),
                keccak256(bytes(ERC712_VERSION)),
                address(this),
                bytes32(getChainId())
            )
        );
    }

    function getDomainSeperator() public view returns (bytes32) {
        return domainSeperator;
    }

    function getChainId() public view returns (uint256 id) {
        assembly {
            id := chainid()
        }
    }

    /**
     * Accept message hash and returns hash message in EIP712 compatible form
     * So that it can be used to recover signer from signature signed using EIP712 formatted data
     * https://eips.ethereum.org/EIPS/eip-712
     * "\\x19" makes the encoding deterministic
     * "\\x01" is the version byte to make it compatible to EIP-191
     */
    function toTypedMessageHash(bytes32 messageHash)
    internal
    view
    returns (bytes32)
    {
        return
        keccak256(
            abi.encodePacked("\x19\x01", getDomainSeperator(), messageHash)
        );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.12;

contract Initializable {
    bool inited = false;

    modifier initializer() {
        require(!inited, "already inited");
        _;
        inited = true;
    }
}