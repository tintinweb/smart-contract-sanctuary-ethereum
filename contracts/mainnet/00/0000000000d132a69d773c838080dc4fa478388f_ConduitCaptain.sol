/**
 *Submitted for verification at Etherscan.io on 2022-08-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/**
 * @title ConduitCaptainInterface
 * @author 0age
 * @notice ConduitCaptainInterface contains function endpoints, events, and error
 *         declarations for the ConduitCaptain contract.
 */
interface ConduitCaptainInterface {
    /**
     * @dev Emit an event whenever a revoker role is updated by the owner.
     *
     * @param revoker The address of the new revoker role.
     */
    event RevokerUpdated(address revoker);

    /**
     * @dev Revert with an error when attempting to set a conduit controller
     *      that does not contain contract code.
     */
    error InvalidConduitController(address conduitController);

    /**
     * @dev Revert with an error when attempting to call closeChannel from an
     *      account that does not currently hold the revoker role.
     */
    error InvalidRevoker();

    /**
     * @dev Revert with an error when attempting to register a revoker and
     *      supplying the null address.
     */
    error RevokerIsNullAddress();

    /**
     * @notice Initiate conduit ownership transfer by assigning a new potential
     *         owner for the given conduit. Only callable by the owner.
     *
     * @param conduit           The conduit for which to initiate ownership
     *                          transfer.
     * @param newPotentialOwner The new potential owner to set.
     */
    function transferConduitOwnership(
        address conduit,
        address newPotentialOwner
    ) external;

    /**
     * @notice Clear the currently set potential owner, if any, from a conduit.
     *         Only callable by the owner.
     *
     * @param conduit The conduit for which to cancel ownership transfer.
     */
    function cancelConduitOwnershipTransfer(address conduit) external;

    /**
     * @notice Accept ownership of a given conduit once this contract has been
     *         set as the current potential owner. Only callable by the owner.
     *
     * @param conduit The conduit for which to accept ownership transfer.
     */
    function acceptConduitOwnership(address conduit) external;

    /**
     * @notice Open or close a channel on a given conduit, thereby allowing the
     *         specified account to execute transfers against that conduit.
     *         Extreme care must be taken when updating channels, as malicious
     *         or vulnerable channels can transfer any ERC20, ERC721 and ERC1155
     *         tokens where the token holder has granted the conduit approval.
     *         Only the owner may call this function.
     *
     * @param conduit The conduit for which to open or close the channel.
     * @param channel The channel to open or close on the conduit.
     * @param isOpen  A boolean indicating whether to open or close the channel.
     */
    function updateChannel(
        address conduit,
        address channel,
        bool isOpen
    ) external;

    /**
     * @notice Close a channel on a given conduit, thereby preventing the
     *         specified account from executing transfers against that conduit.
     *         Only the designated revoker may call this function.
     *
     * @param conduit The conduit for which to close the channel.
     * @param channel The channel to close on the conduit.
     */
    function closeChannel(address conduit, address channel) external;

    /**
     * @notice Set a revoker role that can close channels. Only the owner may
     *         call this function.
     *
     * @param revoker The account to set as the revoker.
     */
    function updateRevoker(address revoker) external;

    /**
     * @notice External view function to retrieve the address of the revoker
     *         role that can close channels.
     *
     * @return revoker The account set as the revoker.
     */
    function getRevoker() external view returns (address revoker);

    /**
     * @notice External view function to retrieve the address of the
     *         ConduitController referenced by the contract
     *
     * @return conduitController The address of the ConduitController.
     */
    function getConduitController()
        external
        view
        returns (address conduitController);
}


/**
 * @title ConduitControllerInterface
 * @author 0age
 * @notice ConduitControllerInterface contains relevant external function
 *         interfaces for a conduit controller contract.
 */
interface ConduitControllerInterface {
    /**
     * @notice Initiate conduit ownership transfer by assigning a new potential
     *         owner for the given conduit. Once set, the new potential owner
     *         may call `acceptOwnership` to claim ownership of the conduit.
     *         Only the owner of the conduit in question may call this function.
     *
     * @param conduit The conduit for which to initiate ownership transfer.
     */
    function transferOwnership(address conduit, address newPotentialOwner)
        external;

    /**
     * @notice Clear the currently set potential owner, if any, from a conduit.
     *         Only the owner of the conduit in question may call this function.
     *
     * @param conduit The conduit for which to cancel ownership transfer.
     */
    function cancelOwnershipTransfer(address conduit) external;

    /**
     * @notice Accept ownership of a supplied conduit. Only accounts that the
     *         current owner has set as the new potential owner may call this
     *         function.
     *
     * @param conduit The conduit for which to accept ownership.
     */
    function acceptOwnership(address conduit) external;

    /**
     * @notice Open or close a channel on a given conduit, thereby allowing the
     *         specified account to execute transfers against that conduit.
     *         Extreme care must be taken when updating channels, as malicious
     *         or vulnerable channels can transfer any ERC20, ERC721 and ERC1155
     *         tokens where the token holder has granted the conduit approval.
     *         Only the owner of the conduit in question may call this function.
     *
     * @param conduit The conduit for which to open or close the channel.
     * @param channel The channel to open or close on the conduit.
     * @param isOpen  A boolean indicating whether to open or close the channel.
     */
    function updateChannel(
        address conduit,
        address channel,
        bool isOpen
    ) external;
}


/**
 * @title   TwoStepOwnableInterface
 * @author  OpenSea Protocol
 * @notice  TwoStepOwnableInterface contains all external function interfaces,
 *          events and errors for the TwoStepOwnable contract.
 */
interface TwoStepOwnableInterface {
    /**
     * @dev Emit an event whenever the contract owner registers a new potential
     *      owner.
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
     * @dev Revert with an error when attempting to set an initial owner when
     *      one has already been set.
     */
    error OwnerAlreadySet(address currentOwner);

    /**
     * @dev Revert with an error when attempting to call a function with the
     *      onlyOwner modifier from an account other than that of the owner.
     */
    error CallerIsNotOwner();

    /**
     * @dev Revert with an error when attempting to register an initial owner
     *      and supplying the null address.
     */
    error InitialOwnerIsNullAddress();

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
     * @notice Clear the currently set potential owner, if any. Only the owner
     *         of this contract may call this function.
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


/**
 * @title   TwoStepOwnable
 * @author  OpenSea Protocol Team
 * @notice  TwoStepOwnable provides access control for inheriting contracts,
 *          where the ownership of the contract can be exchanged via a two step
 *          process. A potential owner is set by the current owner by calling
 *          `transferOwnership`, then accepted by the new potential owner by
 *          calling `acceptOwnership`.
 */
abstract contract TwoStepOwnable is TwoStepOwnableInterface {
    // The address of the owner.
    address private _owner;

    // The address of the new potential owner.
    address private _potentialOwner;

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        // Ensure that the caller is the owner.
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
     * @notice Clear the currently set potential owner, if any. Only the owner
     *         of this contract may call this function.
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

        // Set the caller as the owner of this contract.
        _setOwner(msg.sender);
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
     * @notice Internal function that sets the inital owner of the base
     *         contract. The initial owner must not already be set.
     *         To be called in the constructor or when initializing a proxy.
     *
     * @param initialOwner The address to set for initial ownership.
     */
    function _setInitialOwner(address initialOwner) internal {
        // Ensure that an initial owner has been supplied.
        if (initialOwner == address(0)) {
            revert InitialOwnerIsNullAddress();
        }

        // Ensure that the owner has not already been set.
        if (_owner != address(0)) {
            revert OwnerAlreadySet(_owner);
        }

        // Set the initial owner.
        _setOwner(initialOwner);
    }

    /**
     * @notice Private function that sets a new owner and emits a corresponding
     *         event.
     *
     * @param newOwner The address to assign as the new owner.
     */
    function _setOwner(address newOwner) private {
        // Emit an event indicating that the new owner has been set.
        emit OwnershipTransferred(_owner, newOwner);

        // Set the new owner.
        _owner = newOwner;
    }
}


/**
 * @title ConduitCaptain
 * @author 0age
 * @notice ConduitCaptain is an owned contract where the owner can in turn update
 *         conduits that are owned by the contract. It allows for designating an
 *         account that may revoke channels from conduits.
 */
contract ConduitCaptain is TwoStepOwnable, ConduitCaptainInterface {
    // Set the conduit controller as an immutable argument.
    ConduitControllerInterface private immutable _CONDUIT_CONTROLLER;

    // Designate a storage variable for the revoker role.
    address private _revoker;

    /**
     * @dev Initialize contract by setting the conduit controller, the initial
     *      owner, and the initial revoker role.
     */
    constructor(
        address conduitController,
        address initialOwner,
        address initialRevoker
    ) {
        // Ensure that a contract is deployed to the given conduit controller.
        if (conduitController.code.length == 0) {
            revert InvalidConduitController(conduitController);
        }

        // Set the conduit controller as an immutable argument.
        _CONDUIT_CONTROLLER = ConduitControllerInterface(conduitController);

        // Set the initial owner.
        _setInitialOwner(initialOwner);

        // Set the initial revoker.
        _setRevoker(initialRevoker);
    }

    /**
     * @notice Initiate conduit ownership transfer by assigning a new potential
     *         owner for the given conduit. Only callable by the owner.
     *
     * @param conduit           The conduit for which to initiate ownership
     *                          transfer.
     * @param newPotentialOwner The new potential owner to set.
     */
    function transferConduitOwnership(
        address conduit,
        address newPotentialOwner
    ) external override onlyOwner {
        // Call the conduit controller to transfer conduit ownership.
        _CONDUIT_CONTROLLER.transferOwnership(conduit, newPotentialOwner);
    }

    /**
     * @notice Clear the currently set potential owner, if any, from a conduit.
     *         Only callable by the owner.
     *
     * @param conduit The conduit for which to cancel ownership transfer.
     */
    function cancelConduitOwnershipTransfer(address conduit)
        external
        override
        onlyOwner
    {
        // Call the conduit controller to cancel conduit ownership transfer.
        _CONDUIT_CONTROLLER.cancelOwnershipTransfer(conduit);
    }

    /**
     * @notice Accept ownership of a given conduit once this contract has been
     *         set as the current potential owner. Only callable by the owner.
     *
     * @param conduit The conduit for which to accept ownership transfer.
     */
    function acceptConduitOwnership(address conduit)
        external
        override
        onlyOwner
    {
        // Call the conduit controller to accept conduit ownership.
        _CONDUIT_CONTROLLER.acceptOwnership(conduit);
    }

    /**
     * @notice Open or close a channel on a given conduit, thereby allowing the
     *         specified account to execute transfers against that conduit.
     *         Extreme care must be taken when updating channels, as malicious
     *         or vulnerable channels can transfer any ERC20, ERC721 and ERC1155
     *         tokens where the token holder has granted the conduit approval.
     *         Only the owner may call this function.
     *
     * @param conduit The conduit for which to open or close the channel.
     * @param channel The channel to open or close on the conduit.
     * @param isOpen  A boolean indicating whether to open or close the channel.
     */
    function updateChannel(
        address conduit,
        address channel,
        bool isOpen
    ) external override onlyOwner {
        // Call the conduit controller to update channel status on the conduit.
        _CONDUIT_CONTROLLER.updateChannel(conduit, channel, isOpen);
    }

    /**
     * @notice Close a channel on a given conduit, thereby preventing the
     *         specified account from executing transfers against that conduit.
     *         Only the designated revoker may call this function.
     *
     * @param conduit The conduit for which to close the channel.
     * @param channel The channel to close on the conduit.
     */
    function closeChannel(address conduit, address channel) external override {
        // Revert if the caller is not the revoker.
        if (msg.sender != _revoker) {
            revert InvalidRevoker();
        }

        // Call the conduit controller to close the channel on the conduit.
        _CONDUIT_CONTROLLER.updateChannel(conduit, channel, false);
    }

    /**
     * @notice Set a revoker role that can close channels. Only the owner may
     *         call this function.
     *
     * @param revoker The account to set as the revoker.
     */
    function updateRevoker(address revoker) external override onlyOwner {
        // Assign the new revoker role.
        _setRevoker(revoker);
    }

    /**
     * @notice External view function to retrieve the address of the revoker
     *         role that can close channels.
     *
     * @return revoker The account set as the revoker.
     */
    function getRevoker() external view override returns (address revoker) {
        return _revoker;
    }

    /**
     * @notice External view function to retrieve the address of the
     *         ConduitController referenced by the contract
     *
     * @return conduitController The address of the ConduitController.
     */
    function getConduitController()
        external
        view
        override
        returns (address conduitController)
    {
        return address(_CONDUIT_CONTROLLER);
    }

    /**
     * @notice Internal function to set a revoker role that can close channels.
     *
     * @param revoker The account to set as the revoker.
     */
    function _setRevoker(address revoker) internal {
        // Revert if no address is supplied for the revoker role.
        if (revoker == address(0)) {
            revert RevokerIsNullAddress();
        }

        // Assign the new revoker role.
        _revoker = revoker;
        emit RevokerUpdated(revoker);
    }
}