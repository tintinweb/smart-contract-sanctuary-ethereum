//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "./OwnableEnsProxy.sol";

contract OwnableEnsProxyFactory {
    address private immutable _prototype;

    event OwnableEnsProxyCreated(
        address indexed owner,
        address ensProxyAddress
    );

    constructor(address ensRegistry) {
        OwnableEnsProxy ownableEnsProxy = new OwnableEnsProxy(
            ensRegistry,
            address(this)
        );
        _prototype = address(ownableEnsProxy);
    }

    function createEnsProxy() public {
        address contractAddress = Clones.clone(_prototype);
        emit OwnableEnsProxyCreated(msg.sender, contractAddress);
        OwnableEnsProxy(contractAddress).initializeFromFactory(msg.sender);
    }

    function ensProxyPrototype() public view returns (address) {
        return _prototype;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./EnsLibrary.sol";

contract OwnableEnsProxy is Ownable {
    address public immutable ensRegistry;
    address private immutable _factory;

    constructor(address _ensRegistry, address factory_) {
        ensRegistry = _ensRegistry;
        _factory = factory_;
    }

    function initializeFromFactory(address owner) public {
        require(msg.sender == _factory, "Only factory may set owner");
        _transferOwnership(owner);
    }

    function getAddressFromEnsNode(bytes32 ensNode)
        public
        view
        returns (address)
    {
        return EnsLibrary.ensNodeToAddressFromEnsRegistry(ensRegistry, ensNode);
    }

    /*
     * proxyDestination: the contract you want to proxy to
     * offsets: the offset in bytes into data where you want to insert a 32 byte ens addresses
     * ensNodes: the ens nodes you want to resolve and then replace in data
     * NOTE: offsets must be the same length as ensNodes
     * data: the data you want to pass along to the proxy contract
     */
    function forwardWithEnsParamaterResolution(
        address proxyDestination,
        uint256[] calldata offsets,
        bytes32[] calldata ensNodes,
        bytes calldata data
    ) public payable onlyOwner returns (bytes memory) {
        require(
            offsets.length == ensNodes.length,
            "offsets and ensNodes length doesn't match"
        );

        bytes memory dataCopy = new bytes(data.length);
        for (uint256 i = 0; i < data.length; i++) {
            dataCopy[i] = data[i];
        }
        for (uint256 i = 0; i < offsets.length; i++) {
            address ensAddr = getAddressFromEnsNode(ensNodes[i]);
            // mstore offsets are indexed at the end of the 32 byte value you want to store
            // so we have to add 32 to account for the size of the ens address
            uint256 offset = offsets[i] + 32;
            assembly {
                mstore(add(dataCopy, offset), ensAddr)
            }
        }
        (bool success, bytes memory returnData) = proxyDestination.call{
            value: msg.value
        }(dataCopy);
        require(success, "Proxy failed");
        return returnData;
    }

    /*
     * An extension of forwardWithEnsParamaterResolution that also allows you
     * to resolve the destination contract you are proxing to.
     */
    function forwardWithEnsParamaterAndEnsProxyDestinationResolution(
        bytes32 proxyDestinationEnsNode,
        uint256[] calldata offsets,
        bytes32[] calldata ensNodes,
        bytes calldata data
    ) public payable onlyOwner returns (bytes memory) {
        return
            forwardWithEnsParamaterResolution(
                getAddressFromEnsNode(proxyDestinationEnsNode),
                offsets,
                ensNodes,
                data
            );
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface EnsRegistry {
    function resolver(bytes32 node) external view returns (address);
}

interface EnsResolver {
    function addr(bytes32 node) external view returns (address);
}

library EnsLibrary {
    function ensNodeToAddressFromEnsRegistry(
        address ensRegistry,
        bytes32 ensNode
    ) internal view returns (address) {
        address resolver = EnsRegistry(ensRegistry).resolver(ensNode);
        require(resolver != address(0), "The resolver for ensNode DNE");
        address addr = EnsResolver(resolver).addr(ensNode);
        require(addr != address(0), "The address for resolver DNE");
        return addr;
    }
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