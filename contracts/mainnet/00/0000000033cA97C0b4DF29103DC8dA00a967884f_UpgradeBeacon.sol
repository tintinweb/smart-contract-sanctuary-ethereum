// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import { TwoStepOwnable } from "../access/TwoStepOwnable.sol";

// prettier-ignore
import { 
    UpgradeBeaconInterface 
} from "../interfaces/UpgradeBeaconInterface.sol";

/**
 * @title   UpgradeBeacon
 * @author  OpenSea Protocol Team
 * @notice  UpgradeBeacon is a ownable contract that is used as a beacon for a
 *          proxy, to retreive it's implementation.
 *
 */
contract UpgradeBeacon is TwoStepOwnable, UpgradeBeaconInterface {
    address private _implementation;

    /**
     * @notice Sets the owner of the beacon as the msg.sender.  Requires
     *         the caller to be an approved deployer.
     *
  
     */
    constructor() {
        // Ensure the origin is an approved deployer.
        require(
            (tx.origin == address(0x939C8d89EBC11fA45e576215E2353673AD0bA18A) ||
                tx.origin ==
                address(0xe80a65eB7a3018DedA407e621Ef5fb5B416678CA) ||
                tx.origin ==
                address(0x86D26897267711ea4b173C8C124a0A73612001da) ||
                tx.origin ==
                address(0x3B52ad533687Ce908bA0485ac177C5fb42972962)),
            "Deployment must originate from an approved deployer."
        );
    }

    /**
     * @notice Upgrades the beacon to a new implementation. Requires
     *         the caller must be the owner, and the new implementation
     *         must be a contract.
     *
     * @param newImplementationAddress The address to be set as the new
     *                                 implementation contract.
     */
    function upgradeTo(address newImplementationAddress)
        external
        override
        onlyOwner
    {
        _setImplementation(newImplementationAddress);
        emit Upgraded(newImplementationAddress);
    }

    function initialize(address owner_, address implementation_) external {
        // Ensure the origin is an approved deployer.
        require(
            (tx.origin == address(0x939C8d89EBC11fA45e576215E2353673AD0bA18A) ||
                tx.origin ==
                address(0xe80a65eB7a3018DedA407e621Ef5fb5B416678CA) ||
                tx.origin ==
                address(0x86D26897267711ea4b173C8C124a0A73612001da) ||
                tx.origin ==
                address(0x3B52ad533687Ce908bA0485ac177C5fb42972962)) &&
                _implementation == address(0),
            "Initialize must originate from an approved deployer, and the implementation must not be set."
        );

        // Call initialize.
        _initialize(owner_, implementation_);
    }

    function _initialize(address owner_, address implementation_) internal {
        // Set the Initial Owner
        _setInitialOwner(owner_);

        // Set the Implementation
        _setImplementation(implementation_);

        // Emit the Event
        emit Upgraded(implementation_);
    }

    /**
     * @notice This function returns the address to the implentation contract.
     */
    function implementation() external view override returns (address) {
        return _implementation;
    }

    /**
     * @notice Sets the implementation contract address for this beacon.
     *         Requires the address to be a contract.
     *
     * @param newImplementationAddress The address to be set as the new
     *                                 implementation contract.
     */
    function _setImplementation(address newImplementationAddress) internal {
        if (address(newImplementationAddress).code.length == 0) {
            revert InvalidImplementation(newImplementationAddress);
        }
        _implementation = newImplementationAddress;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../interfaces/TwoStepOwnableInterface.sol";

/**
 * @title   TwoStepOwnable
 * @author  OpenSea Protocol Team
 * @notice  TwoStepOwnable is a module which provides access control
 *          where the ownership of a contract can be exchanged via a
 *          two step process. A potential owner is set by the current
 *          owner using transferOwnership, then accepted by the new
 *          potential owner using acceptOwnership.
 */
contract TwoStepOwnable is TwoStepOwnableInterface {
    // The address of the owner.
    address private _owner;

    // The address of the new potential owner.
    address private _potentialOwner;

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        // Ensure the caller is the owner.
        if (msg.sender != _owner) {
            revert CallerIsNotOwner();
        }
        // Continue with function execution.
        _;
    }

    /**
     * @notice Initiate ownership transfer by assigning a new potential owner
     *         to this contract. Once set, the new potential owner may call
     *         `acceptOwnership` to claim ownership. Only the owner may call
     *         this function.
     *
     * @param newPotentialOwner The address for which to initiate ownership
     *                          transfer to.
     */
    function transferOwnership(address newPotentialOwner)
        external
        override
        onlyOwner
    {
        // Ensure the new potential owner is not an invalid address.
        if (newPotentialOwner == address(0)) {
            revert NewPotentialOwnerIsNullAddress();
        }

        // Emit an event indicating that the potential owner has been updated.
        emit PotentialOwnerUpdated(newPotentialOwner);

        // Set the new potential owner as the potential owner.
        _potentialOwner = newPotentialOwner;
    }

    /**
     * @notice Clear the currently set potential owner, if any.
     *         Only the owner of this contract may call this function.
     */
    function cancelOwnershipTransfer() external override onlyOwner {
        // Emit an event indicating that the potential owner has been cleared.
        emit PotentialOwnerUpdated(address(0));

        // Clear the current new potential owner.
        delete _potentialOwner;
    }

    /**
     * @notice Accept ownership of this contract. Only the account that the
     *         current owner has set as the new potential owner may call this
     *         function.
     */
    function acceptOwnership() external override {
        // Ensure the caller is the potential owner.
        if (msg.sender != _potentialOwner) {
            // Revert, indicating that caller is not current potential owner.
            revert CallerIsNotNewPotentialOwner();
        }

        // Emit an event indicating that the potential owner has been cleared.
        emit PotentialOwnerUpdated(address(0));

        // Clear the current new potential owner.
        delete _potentialOwner;

        // Emit an event indicating ownership has been transferred.
        emit OwnershipTransferred(_owner, msg.sender);

        // Set the caller as the owner of this contract.
        _owner = msg.sender;
    }

    /**
     * @notice An external view function that returns the potential owner.
     *
     * @return The address of the potential owner.
     */
    function potentialOwner() external view override returns (address) {
        return _potentialOwner;
    }

    /**
     * @notice A public view function that returns the owner.
     *
     * @return The address of the owner.
     */
    function owner() public view override returns (address) {
        return _owner;
    }

    /**
     * @notice Internal function that sets the inital owner of the
     *         base contract. The initial owner must not be set
     *         previously.
     *
     * @param initialOwner The address to set for initial ownership.
     */
    function _setInitialOwner(address initialOwner) internal {
        // Ensure the initial owner is not an invalid address.
        if (initialOwner == address(0)) {
            revert InitialOwnerIsNullAddress();
        }

        // Ensure the owner has not already been set.
        if (_owner != address(0)) {
            revert OwnerAlreadySet(_owner);
        }

        // Emit an event indicating ownership has been set.
        emit OwnershipTransferred(address(0), initialOwner);

        // Set the initial owner.
        _owner = initialOwner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @title   UpgradeBeaconInterface
 * @notice  UpgradeBeaconInterface contains all external function
 *          interfaces, events and errors related to the payable proxy.
 */
interface UpgradeBeaconInterface {
    /**
     * @dev Emit an event whenever the implementation has been upgraded.
     *
     * @param implementation  The new implementation address.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Revert with an error when attempting to call an operation
     *      while the caller is not the owner of the proxy.
     */
    error InvalidOwner();

    /**
     * @dev Revert with an error when attempting to set an non-contract
     *      address as the implementation.
     */
    error InvalidImplementation(address newImplementationAddress);

    /**
     * @notice Upgrades the beacon to a new implementation. Requires
     *         the caller must be the owner, and the new implementation
     *         must be a contract.
     *
     * @param newImplementationAddress The address to be set as the new
     *                                 implementation contract.
     */
    function upgradeTo(address newImplementationAddress) external;

    /**
     * @notice An external view function that returns the implementation.
     *
     * @return The address of the implementation.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @title   TwoStepOwnableInterface
 * @author  OpenSea Protocol Team
 * @notice  TwoStepOwnableInterface contains all external function interfaces,
 *          events and errors for the two step ownable access control module.
 */
interface TwoStepOwnableInterface {
    /**
     * @dev Emit an event whenever the contract owner registers a
     *      new potential owner.
     *
     * @param newPotentialOwner The new potential owner of the contract.
     */
    event PotentialOwnerUpdated(address newPotentialOwner);

    /**
     * @dev Emit an event whenever contract ownership is transferred.
     *
     * @param previousOwner The previous owner of the contract.
     * @param newOwner      The new owner of the contract.
     */
    event OwnershipTransferred(address previousOwner, address newOwner);

    /**
     * @dev Revert with an error when attempting to set an owner
     *      that is already set.
     */
    error OwnerAlreadySet(address currentOwner);

    /**
     * @dev Revert with an error when attempting to set the initial
     *      owner and supplying the null address.
     */
    error InitialOwnerIsNullAddress();

    /**
     * @dev Revert with an error when attempting to call an operation
     *      while the caller is not the owner.
     */
    error CallerIsNotOwner();

    /**
     * @dev Revert with an error when attempting to register a new potential
     *      owner and supplying the null address.
     */
    error NewPotentialOwnerIsNullAddress();

    /**
     * @dev Revert with an error when attempting to claim ownership of the
     *      contract with a caller that is not the current potential owner.
     */
    error CallerIsNotNewPotentialOwner();

    /**
     * @notice Initiate ownership transfer by assigning a new potential owner
     *         to this contract. Once set, the new potential owner may call
     *         `acceptOwnership` to claim ownership. Only the owner may call
     *         this function.
     *
     * @param newPotentialOwner The address for which to initiate ownership
     *                          transfer to.
     */
    function transferOwnership(address newPotentialOwner) external;

    /**
     * @notice Clear the currently set potential owner, if any.
     *         Only the owner of this contract may call this function.
     */
    function cancelOwnershipTransfer() external;

    /**
     * @notice Accept ownership of this contract. Only the account that the
     *         current owner has set as the new potential owner may call this
     *         function.
     */
    function acceptOwnership() external;

    /**
     * @notice An external view function that returns the potential owner.
     *
     * @return The address of the potential owner.
     */
    function potentialOwner() external view returns (address);

    /**
     * @notice An external view function that returns the owner.
     *
     * @return The address of the owner.
     */
    function owner() external view returns (address);
}