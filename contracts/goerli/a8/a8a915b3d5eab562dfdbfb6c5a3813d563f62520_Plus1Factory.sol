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
            mstore(ptr, 0x602d8060093d393df3363d3d373d3d3d363d7300000000000000000000000000)
            mstore(add(ptr, 0x13), shl(0x60, implementation))
            mstore(add(ptr, 0x27), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x36)
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
            mstore(ptr, 0x602d8060093d393df3363d3d373d3d3d363d7300000000000000000000000000)
            mstore(add(ptr, 0x13), shl(0x60, implementation))
            mstore(add(ptr, 0x27), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x36, salt)
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
            mstore(ptr, 0x602d8060093d393df3363d3d373d3d3d363d7300000000000000000000000000)
            mstore(add(ptr, 0x13), shl(0x60, implementation))
            mstore(add(ptr, 0x27), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x37), shl(0x60, deployer))
            mstore(add(ptr, 0x4b), salt)
            mstore(add(ptr, 0x6b), keccak256(ptr, 0x36))
            predicted := keccak256(add(ptr, 0x36), 0x55)
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnerUpdated(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnerUpdated(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function setOwner(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import "./ITokenOwner.sol";

interface IPlus1 {
    function init(
        address _owner,
        string memory _name,
        string memory _symbol,
        ITokenOwner _original,
        string memory _initialURI
    ) external;

    function original() external view returns (ITokenOwner);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITokenOwner {
    function ownerOf(uint256 tokenId) external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import "openzeppelin/contracts/proxy/Clones.sol";
import "solmate/auth/Owned.sol";
import "./IPlus1.sol";

/// ███╗   ██╗███████╗██████╗ ██╗   ██╗ ██████╗ ██╗   ██╗███████╗
/// ████╗  ██║██╔════╝██╔══██╗██║   ██║██╔═══██╗██║   ██║██╔════╝
/// ██╔██╗ ██║█████╗  ██████╔╝██║   ██║██║   ██║██║   ██║███████╗
/// ██║╚██╗██║██╔══╝  ██╔══██╗╚██╗ ██╔╝██║   ██║██║   ██║╚════██║
/// ██║ ╚████║███████╗██║  ██║ ╚████╔╝ ╚██████╔╝╚██████╔╝███████║
/// ╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝  ╚═══╝   ╚═════╝  ╚═════╝ ╚══════╝
/// work with us: nervous.net
///                       __        _
///                      /\ \     /' \
///                      \_\ \___/\_, \
///                     /\___  __\/_/\ \
///                     \/__/\ \_/  \ \ \
///                         \ \_\    \ \_\
///                          \/_/     \/_/
///
/// @title  Plus1Factory
/// @notice Efficently and permissionlessly create Plus1 contracts
/// @author Nervous / [email protected]
contract Plus1Factory is Owned {
    /// @notice Emitted when a Plus1 contract is added via factory
    /// @param original The original contract determining Plus1 mint/burn/tranfer approval
    /// @param plus1    The address of the Plus1 contract
    /// @param index    The index of the Plus1 contract
    event AddPlus1(
        address indexed original,
        address indexed plus1,
        uint256 index
    );

    address[] public originals;
    mapping(address => address[]) private _plus1s;
    IPlus1 public impl;

    /// @notice Construct the factory
    /// @param _impl The implementation of the Plus1 contract
    /// @param migrated The Plus1 contracts to start with
    constructor(IPlus1 _impl, address[] memory migrated) Owned(msg.sender) {
        impl = _impl;
        for (uint256 i = 0; i < migrated.length; i++) {
            IPlus1 plus1 = IPlus1(migrated[i]);
            address original = address(plus1.original());
            _store(original, address(plus1));
        }
    }

    /// @notice Update the implementation used for future Plus1 creations
    ///         This will not affect existing Plus1 contracts.
    /// @dev    Only callable by owner
    /// @param _impl The new implementation
    function setImplementation(address _impl) external onlyOwner {
        impl = IPlus1(_impl);
    }

    /// @notice Create a Plus1 ERC-721.
    /// @dev Emits `AddPlus1` event with the newly created contract's address.
    ///      Adds the new Plus1 to an array that can be looked up via original contract
    /// @param name     Name of the ERC-721 Plus1.
    /// @param symbol   Symbol of the ERC-721 Plus1.
    /// @param original Address of another contract (like an ERC-721) that determines ownership.
    ///                 Must implement `ownerOf(tokenId)`.
    /// @param baseURI  The base of the URI for metadata. ID will be appended in tokenURI(tokenId) calls.
    /// @return p1      The address of the new Plus1 contract.
    function createPlus1(
        string memory name,
        string memory symbol,
        ITokenOwner original,
        string memory baseURI
    ) external returns (IPlus1 p1) {
        p1 = IPlus1(Clones.clone(address(impl)));
        p1.init(msg.sender, name, symbol, original, baseURI);

        _store(address(original), address(p1));
    }

    /// @notice Get the count of original contracts that have been +1'd
    /// @return The current count.
    function originalsCount() external view returns (uint256) {
        return originals.length;
    }

    /// @notice Get slice of the array of original contracts that have been +1'd
    /// @param index Start index of the slice
    /// @param length Length of the slice
    /// @return The current count.
    function originalsSlice(uint256 index, uint256 length)
        external
        view
        returns (address[] memory)
    {
        address[] memory slice = new address[](length);

        for (uint256 i = 0; i < length; ++i) {
            slice[i] = originals[index + i];
        }
        return slice;
    }

    /// @notice Get the count of Plus1 contracts that have been created
    ///         for a given original.
    /// @param original Address of the contract from which this Plus1 was derived
    /// @return The current count of Plus1s for the given original.
    function plus1sCount(address original) external view returns (uint256) {
        return _plus1s[original].length;
    }

    /// @notice Get slice of the array of original contracts that have been +1'd
    /// @param original Address of the contract from which this Plus1 was derived
    /// @param index Start index of the slice
    /// @param length Length of the slice
    /// @return The current count.
    function plus1sSlice(
        address original,
        uint256 index,
        uint256 length
    ) external view returns (address[] memory) {
        address[] storage p1s = _plus1s[original];
        address[] memory slice = new address[](length);
        for (uint256 i = 0; i < length; ++i) {
            slice[i] = p1s[index + i];
        }
        return slice;
    }

    /// @notice Get the address of a Plus1 given its original and the index.
    /// @param original Address of the contract from which this Plus1 was derived
    /// @param index Index of the Plus1
    /// @return The address of the Plus1 contract.
    function plus1AtIndex(address original, uint256 index)
        external
        view
        returns (address)
    {
        return _plus1s[original][index];
    }

    function _store(address original, address p1) internal {
        address[] storage p1s = _plus1s[original];
        uint256 index = p1s.length;
        if (index == 0) {
            originals.push(original);
        }
        p1s.push(p1);
        emit AddPlus1(original, p1, index);
    }
}