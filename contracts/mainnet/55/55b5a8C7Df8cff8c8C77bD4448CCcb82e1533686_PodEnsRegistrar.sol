pragma solidity >=0.8.4;

interface ENS {

    // Logged when the owner of a node assigns a new owner to a subnode.
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

    // Logged when the owner of a node transfers ownership to a new account.
    event Transfer(bytes32 indexed node, address owner);

    // Logged when the resolver for a node changes.
    event NewResolver(bytes32 indexed node, address resolver);

    // Logged when the TTL of a node changes
    event NewTTL(bytes32 indexed node, uint64 ttl);

    // Logged when an operator is added or removed.
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function setRecord(bytes32 node, address owner, address resolver, uint64 ttl) external virtual;
    function setSubnodeRecord(bytes32 node, bytes32 label, address owner, address resolver, uint64 ttl) external virtual;
    function setSubnodeOwner(bytes32 node, bytes32 label, address owner) external virtual returns(bytes32);
    function setResolver(bytes32 node, address resolver) external virtual;
    function setOwner(bytes32 node, address owner) external virtual;
    function setTTL(bytes32 node, uint64 ttl) external virtual;
    function setApprovalForAll(address operator, bool approved) external virtual;
    function owner(bytes32 node) external virtual view returns (address);
    function resolver(bytes32 node) external virtual view returns (address);
    function ttl(bytes32 node) external virtual view returns (uint64);
    function recordExists(bytes32 node) external virtual view returns (bool);
    function isApprovedForAll(address owner, address operator) external virtual view returns (bool);
}

pragma solidity >=0.8.4;

import "./ENS.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../root/Controllable.sol";

abstract contract NameResolver {
    function setName(bytes32 node, string memory name) public virtual;
}

bytes32 constant lookup = 0x3031323334353637383961626364656600000000000000000000000000000000;

bytes32 constant ADDR_REVERSE_NODE = 0x91d1777781884d03a6757a803996e38de2a42967fb37eeaca72729271025a9e2;

// namehash('addr.reverse')

contract ReverseRegistrar is Ownable, Controllable {
    ENS public ens;
    NameResolver public defaultResolver;

    event ReverseClaimed(address indexed addr, bytes32 indexed node);

    /**
     * @dev Constructor
     * @param ensAddr The address of the ENS registry.
     * @param resolverAddr The address of the default reverse resolver.
     */
    constructor(ENS ensAddr, NameResolver resolverAddr) {
        ens = ensAddr;
        defaultResolver = resolverAddr;

        // Assign ownership of the reverse record to our deployer
        ReverseRegistrar oldRegistrar = ReverseRegistrar(
            ens.owner(ADDR_REVERSE_NODE)
        );
        if (address(oldRegistrar) != address(0x0)) {
            oldRegistrar.claim(msg.sender);
        }
    }

    modifier authorised(address addr) {
        require(
            addr == msg.sender ||
                controllers[msg.sender] ||
                ens.isApprovedForAll(addr, msg.sender) ||
                ownsContract(addr),
            "Caller is not a controller or authorised by address or the address itself"
        );
        _;
    }

    /**
     * @dev Transfers ownership of the reverse ENS record associated with the
     *      calling account.
     * @param owner The address to set as the owner of the reverse record in ENS.
     * @return The ENS node hash of the reverse record.
     */
    function claim(address owner) public returns (bytes32) {
        return _claimWithResolver(msg.sender, owner, address(0x0));
    }

    /**
     * @dev Transfers ownership of the reverse ENS record associated with the
     *      calling account.
     * @param addr The reverse record to set
     * @param owner The address to set as the owner of the reverse record in ENS.
     * @return The ENS node hash of the reverse record.
     */
    function claimForAddr(address addr, address owner)
        public
        authorised(addr)
        returns (bytes32)
    {
        return _claimWithResolver(addr, owner, address(0x0));
    }

    /**
     * @dev Transfers ownership of the reverse ENS record associated with the
     *      calling account.
     * @param owner The address to set as the owner of the reverse record in ENS.
     * @param resolver The address of the resolver to set; 0 to leave unchanged.
     * @return The ENS node hash of the reverse record.
     */
    function claimWithResolver(address owner, address resolver)
        public
        returns (bytes32)
    {
        return _claimWithResolver(msg.sender, owner, resolver);
    }

    /**
     * @dev Transfers ownership of the reverse ENS record specified with the
     *      address provided
     * @param addr The reverse record to set
     * @param owner The address to set as the owner of the reverse record in ENS.
     * @param resolver The address of the resolver to set; 0 to leave unchanged.
     * @return The ENS node hash of the reverse record.
     */
    function claimWithResolverForAddr(
        address addr,
        address owner,
        address resolver
    ) public authorised(addr) returns (bytes32) {
        return _claimWithResolver(addr, owner, resolver);
    }

    /**
     * @dev Sets the `name()` record for the reverse ENS record associated with
     * the calling account. First updates the resolver to the default reverse
     * resolver if necessary.
     * @param name The name to set for this address.
     * @return The ENS node hash of the reverse record.
     */
    function setName(string memory name) public returns (bytes32) {
        bytes32 node = _claimWithResolver(
            msg.sender,
            address(this),
            address(defaultResolver)
        );
        defaultResolver.setName(node, name);
        return node;
    }

    /**
     * @dev Sets the `name()` record for the reverse ENS record associated with
     * the account provided. First updates the resolver to the default reverse
     * resolver if necessary.
     * Only callable by controllers and authorised users
     * @param addr The reverse record to set
     * @param owner The owner of the reverse node
     * @param name The name to set for this address.
     * @return The ENS node hash of the reverse record.
     */
    function setNameForAddr(
        address addr,
        address owner,
        string memory name
    ) public authorised(addr) returns (bytes32) {
        bytes32 node = _claimWithResolver(
            addr,
            address(this),
            address(defaultResolver)
        );
        defaultResolver.setName(node, name);
        ens.setSubnodeOwner(ADDR_REVERSE_NODE, sha3HexAddress(addr), owner);
        return node;
    }

    /**
     * @dev Returns the node hash for a given account's reverse records.
     * @param addr The address to hash
     * @return The ENS node hash.
     */
    function node(address addr) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(ADDR_REVERSE_NODE, sha3HexAddress(addr))
            );
    }

    /**
     * @dev An optimised function to compute the sha3 of the lower-case
     *      hexadecimal representation of an Ethereum address.
     * @param addr The address to hash
     * @return ret The SHA3 hash of the lower-case hexadecimal encoding of the
     *         input address.
     */
    function sha3HexAddress(address addr) private pure returns (bytes32 ret) {
        assembly {
            for {
                let i := 40
            } gt(i, 0) {

            } {
                i := sub(i, 1)
                mstore8(i, byte(and(addr, 0xf), lookup))
                addr := div(addr, 0x10)
                i := sub(i, 1)
                mstore8(i, byte(and(addr, 0xf), lookup))
                addr := div(addr, 0x10)
            }

            ret := keccak256(0, 40)
        }
    }

    /* Internal functions */

    function _claimWithResolver(
        address addr,
        address owner,
        address resolver
    ) internal returns (bytes32) {
        bytes32 label = sha3HexAddress(addr);
        bytes32 node = keccak256(abi.encodePacked(ADDR_REVERSE_NODE, label));
        address currentResolver = ens.resolver(node);
        bool shouldUpdateResolver = (resolver != address(0x0) &&
            resolver != currentResolver);
        address newResolver = shouldUpdateResolver ? resolver : currentResolver;

        ens.setSubnodeRecord(ADDR_REVERSE_NODE, label, owner, newResolver, 0);

        emit ReverseClaimed(addr, node);

        return node;
    }

    function ownsContract(address addr) internal view returns (bool) {
        try Ownable(addr).owner() returns (address owner) {
            return owner == msg.sender;
        } catch {
            return false;
        }
    }
}

pragma solidity >=0.8.4;
pragma experimental ABIEncoderV2;

/**
 * A generic resolver interface which includes all the functions including the ones deprecated
 */
interface Resolver{
    event AddrChanged(bytes32 indexed node, address a);
    event AddressChanged(bytes32 indexed node, uint coinType, bytes newAddress);
    event NameChanged(bytes32 indexed node, string name);
    event ABIChanged(bytes32 indexed node, uint256 indexed contentType);
    event PubkeyChanged(bytes32 indexed node, bytes32 x, bytes32 y);
    event TextChanged(bytes32 indexed node, string indexed indexedKey, string key);
    event ContenthashChanged(bytes32 indexed node, bytes hash);
    /* Deprecated events */
    event ContentChanged(bytes32 indexed node, bytes32 hash);

    function ABI(bytes32 node, uint256 contentTypes) external view returns (uint256, bytes memory);
    function addr(bytes32 node) external view returns (address);
    function addr(bytes32 node, uint coinType) external view returns(bytes memory);
    function contenthash(bytes32 node) external view returns (bytes memory);
    function dnsrr(bytes32 node) external view returns (bytes memory);
    function name(bytes32 node) external view returns (string memory);
    function pubkey(bytes32 node) external view returns (bytes32 x, bytes32 y);
    function text(bytes32 node, string calldata key) external view returns (string memory);
    function interfaceImplementer(bytes32 node, bytes4 interfaceID) external view returns (address);
    function setABI(bytes32 node, uint256 contentType, bytes calldata data) external;
    function setAddr(bytes32 node, address addr) external;
    function setAddr(bytes32 node, uint coinType, bytes calldata a) external;
    function setContenthash(bytes32 node, bytes calldata hash) external;
    function setDnsrr(bytes32 node, bytes calldata data) external;
    function setName(bytes32 node, string calldata _name) external;
    function setPubkey(bytes32 node, bytes32 x, bytes32 y) external;
    function setText(bytes32 node, string calldata key, string calldata value) external;
    function setInterface(bytes32 node, bytes4 interfaceID, address implementer) external;
    function supportsInterface(bytes4 interfaceID) external pure returns (bool);
    function multicall(bytes[] calldata data) external returns(bytes[] memory results);

    /* Deprecated functions */
    function content(bytes32 node) external view returns (bytes32);
    function multihash(bytes32 node) external view returns (bytes memory);
    function setContent(bytes32 node, bytes32 hash) external;
    function setMultihash(bytes32 node, bytes calldata hash) external;
}

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Controllable is Ownable {
    mapping(address => bool) public controllers;

    event ControllerChanged(address indexed controller, bool enabled);

    modifier onlyController {
        require(
            controllers[msg.sender],
            "Controllable: Caller is not a controller"
        );
        _;
    }

    function setController(address controller, bool enabled) public onlyOwner {
        controllers[controller] = enabled;
        emit ControllerChanged(controller, enabled);
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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

pragma solidity 0.8.7;

import "@ensdomains/ens-contracts/contracts/registry/ENS.sol";
import "@ensdomains/ens-contracts/contracts/registry/ReverseRegistrar.sol";
import "@ensdomains/ens-contracts/contracts/resolvers/Resolver.sol";
import "../interfaces/IControllerRegistry.sol";
import "../interfaces/IInviteToken.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * A registrar that allocates subdomains to the first person to claim them.
 */
contract PodEnsRegistrar is Ownable {
    modifier onlyControllerOrOwner() {
        require(
            controllerRegistry.isRegistered(msg.sender) ||
                owner() == msg.sender,
            "sender must be controller/owner"
        );
        _;
    }

    enum State {
        onlySafeWithShip, // Only safes with SHIP token
        onlyShip, // Anyone with SHIP token
        open, // Anyone can enroll
        closed // Nobody can enroll, just in case
    }

    ENS public ens;
    Resolver public resolver;
    ReverseRegistrar public reverseRegistrar;
    IControllerRegistry controllerRegistry;
    bytes32 rootNode;
    IInviteToken inviteToken;
    State public state = State.onlySafeWithShip;

    /**
     * Constructor.
     * @param ensAddr The address of the ENS registry.
     * @param node The node that this registrar administers.
     */
    constructor(
        ENS ensAddr,
        Resolver resolverAddr,
        ReverseRegistrar _reverseRegistrar,
        IControllerRegistry controllerRegistryAddr,
        bytes32 node,
        IInviteToken inviteTokenAddr
    ) {
        require(address(ensAddr) != address(0), "Invalid address");
        require(address(resolverAddr) != address(0), "Invalid address");
        require(address(_reverseRegistrar)!= address(0), "Invalid address");
        require(address(controllerRegistryAddr) != address(0), "Invalid address");
        require(node != bytes32(0), "Invalid node");
        require(address(inviteTokenAddr) != address(0), "Invalid address");

        ens = ensAddr;
        resolver = resolverAddr;
        controllerRegistry = controllerRegistryAddr;
        rootNode = node;
        reverseRegistrar = _reverseRegistrar;
        inviteToken = inviteTokenAddr;
    }

    function registerPod(
        bytes32 label,
        address podSafe,
        address podCreator
    ) public returns (address) {
        if (state == State.closed) {
            revert("registrations are closed");
        }

        if (state == State.onlySafeWithShip) {
            // This implicitly prevents safes that were created in this transaction
            // from registering, as they cannot have a SHIP token balance.
            require(
                inviteToken.balanceOf(podSafe) > 0,
                "safe must have SHIP token"
            );
            inviteToken.burn(podSafe, 1);
        }
        if (state == State.onlyShip) {
            // Prefer the safe's token over the user's
            if (inviteToken.balanceOf(podSafe) > 0) {
                inviteToken.burn(podSafe, 1);
            } else if (inviteToken.balanceOf(podCreator) > 0) {
                inviteToken.burn(podCreator, 1);
            } else {
                revert("sender or safe must have SHIP");
            }
        }

        bytes32 node = keccak256(abi.encodePacked(rootNode, label));

        require(
            controllerRegistry.isRegistered(msg.sender),
            "controller not registered"
        );

        require(ens.owner(node) == address(0), "label is already owned");

        _register(label, address(this));

        resolver.setAddr(node, podSafe);

        return address(reverseRegistrar);
    }

    function getRootNode() public view returns (bytes32) {
        return rootNode;
    }

    /**
     * Generates a node hash from the Registrar's root node + the label hash.
     * @param label - label hash of pod name (i.e., labelhash('mypod'))
     */
    function getEnsNode(bytes32 label) public view returns (bytes32) {
        return keccak256(abi.encodePacked(getRootNode(), label));
    }

    /**
     * Returns the ENS Node of a given address
     * @param input - an ENS registered address
     */
    function addressToNode(address input) public returns (bytes32) {
        return reverseRegistrar.node(input);
    }

    /**
     * Register a name, or change the owner of an existing registration.
     * @param label The hash of the label to register.
     */
    function register(bytes32 label, address owner) public onlyOwner {
        _register(label, owner);
    }

    /**
     * Register a name, or change the owner of an existing registration.
     * @param label The hash of the label to register.
     */
    function _register(bytes32 label, address owner) internal {
        ens.setSubnodeRecord(rootNode, label, owner, address(resolver), 0);
    }

    /**
     * @param node - the node hash of an ENS name
     */
    function setText(
        bytes32 node,
        string calldata key,
        string calldata value
    ) public onlyControllerOrOwner {
        resolver.setText(node, key, value);
    }

    function setAddr(bytes32 node, address newAddress) public onlyOwner {
        resolver.setAddr(node, newAddress);
    }

    function setRestrictionState(uint256 _state) external onlyOwner {
        state = State(_state);
    }
}

pragma solidity 0.8.7;


interface IControllerRegistry{

    /**
     * @param _controller Address to check if registered as a controller
     * @return Boolean representing if the address is a registered as a controller
     */
    function isRegistered(address _controller) external view returns (bool);

}

pragma solidity 0.8.7;

/* solhint-disable indent */

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IInviteToken is IERC20 {
    function batchMint(address[] calldata accounts, uint256 amount) external;

    function mint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;

}