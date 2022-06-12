/**
 *Submitted for verification at Etherscan.io on 2022-06-11
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

/**
 * @title ConduitCreatorInterface
 * @author 0age
 * @notice ConduitCreatorInterface contains function endpoints and an error
 *         declaration for the ConduitCreator contract.
 */
interface ConduitCreatorInterface {
    // Declare custom error for an invalid conduit creator.
    error InvalidConduitCreator();

    /**
     * @notice Deploy a new conduit on a given conduit controller using a
     *         supplied conduit key and assigning an initial owner for the
     *         deployed conduit. Only callable by the conduit creator.
     *
     * @param conduitController The conduit controller used to deploy the
     *                          conduit.
     * @param conduitKey        The conduit key used to deploy the
     *                          conduit.
     * @param initialOwner      The initial owner to set for the new
     *                          conduit.
     *
     * @return conduit The address of the newly deployed conduit.
     */
    function createConduit(
        ConduitControllerInterface conduitController,
        bytes32 conduitKey,
        address initialOwner
    ) external returns (address conduit);

    /**
     * @notice Initiate conduit ownership transfer by assigning a new potential
     *         owner for the given conduit. Only callable by the conduit
     *         creator.
     *
     * @param conduitController The conduit controller used to deploy the
     *                          conduit.
     * @param conduit           The conduit for which to initiate ownership
     *                          transfer.
     */
    function transferOwnership(
        ConduitControllerInterface conduitController,
        address conduit,
        address newPotentialOwner
    ) external;

    /**
     * @notice Clear the currently set potential owner, if any, from a conduit.
     *         Only callable by the conduit creator.
     *
     * @param conduitController The conduit controller used to deploy the
     *                          conduit.
     * @param conduit           The conduit for which to cancel ownership
     *                          transfer.
     */
    function cancelOwnershipTransfer(
        ConduitControllerInterface conduitController,
        address conduit
    ) external;
}

/**
 * @title ConduitControllerInterface
 * @author 0age
 * @notice ConduitControllerInterface contains relevant external function
 *         interfaces for a conduit controller contract.
 */
interface ConduitControllerInterface {
    /**
     * @notice Deploy a new conduit using a supplied conduit key and assign an
     *         initial owner for the deployed conduit.
     *
     * @param conduitKey   The conduit key used to deploy the conduit.
     * @param initialOwner The initial owner to set for the new conduit.
     *
     * @return conduit The address of the newly deployed conduit.
     */
    function createConduit(bytes32 conduitKey, address initialOwner)
        external
        returns (address conduit);

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
}

/**
 * @title ConduitCreator
 * @author 0age
 * @notice ConduitCreator allows a specific account to create new conduits on
           arbitrary conduit controllers.
 */
contract ConduitCreator is ConduitCreatorInterface {
    // Set the conduit creator as an immutable argument.
    address internal immutable _CONDUIT_CREATOR;

    /**
     * @notice Modifier to ensure that only the conduit creator can call a given
     *         function.
     */
    modifier onlyCreator() {
        // Ensure that the caller is the conduit creator.
        if (msg.sender != _CONDUIT_CREATOR) {
            revert InvalidConduitCreator();
        }

        // Proceed with function execution.
        _;
    }

    /**
     * @dev Initialize contract by setting the conduit creator.
     */
    constructor(address conduitCreator) {
        // Set the conduit creator as an immutable argument.
        _CONDUIT_CREATOR = conduitCreator;
    }

    /**
     * @notice Deploy a new conduit on a given conduit controller using a
     *         supplied conduit key and assigning an initial owner for the
     *         deployed conduit. Only callable by the conduit creator.
     *
     * @param conduitController The conduit controller used to deploy the
     *                          conduit.
     * @param conduitKey        The conduit key used to deploy the
     *                          conduit.
     * @param initialOwner      The initial owner to set for the new
     *                          conduit.
     *
     * @return conduit The address of the newly deployed conduit.
     */
    function createConduit(
        ConduitControllerInterface conduitController,
        bytes32 conduitKey,
        address initialOwner
    ) external override onlyCreator returns (address conduit) {
        // Call the conduit controller to create the conduit.
        conduit = conduitController.createConduit(conduitKey, initialOwner);
    }

    /**
     * @notice Initiate conduit ownership transfer by assigning a new potential
     *         owner for the given conduit. Only callable by the conduit
     *         creator.
     *
     * @param conduitController The conduit controller used to deploy the
     *                          conduit.
     * @param conduit           The conduit for which to initiate ownership
     *                          transfer.
     */
    function transferOwnership(
        ConduitControllerInterface conduitController,
        address conduit,
        address newPotentialOwner
    ) external override onlyCreator {
        // Call the conduit controller to transfer conduit ownership.
        conduitController.transferOwnership(conduit, newPotentialOwner);
    }

    /**
     * @notice Clear the currently set potential owner, if any, from a conduit.
     *         Only callable by the conduit creator.
     *
     * @param conduitController The conduit controller used to deploy the
     *                          conduit.
     * @param conduit           The conduit for which to cancel ownership
     *                          transfer.
     */
    function cancelOwnershipTransfer(
        ConduitControllerInterface conduitController,
        address conduit
    ) external override onlyCreator {
        // Call the conduit controller to cancel ownership transfer.
        conduitController.cancelOwnershipTransfer(conduit);
    }
}