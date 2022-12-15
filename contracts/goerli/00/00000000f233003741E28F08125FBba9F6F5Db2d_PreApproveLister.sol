// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title PreApproveLister
 * @notice A contract that allows the owner to add and remove operators
 *         to the registry.
 */
contract PreApproveLister {
    // =============================================================
    //                           CONSTANTS
    // =============================================================

    /**
     * @dev The address of the pre-approve registry.
     */
    address public constant PRE_APPROVE_REGISTRY = 0x000000000000B89C3cBDBBecb313Bd896b09144d;

    // =============================================================
    //                            STORAGE
    // =============================================================

    /**
     * @dev The owner of the contract.
     */
    address public owner;

    /**
     * @dev Whether the contract has already been initialized.
     */
    bool internal _initialized;

    /**
     * @dev Whether the contract is locked.
     *      When a contract is locked:
     *      - Operators cannot be added by the owner.
     *      - Operators can still be removed by the owner.
     *      - Anyone can purge operators.
     *      - Contract cannot be unlocked.
     */
    bool public locked;

    /**
     * @dev An account authorized to lock the contract, besides the contract owner.
     *      This is for the worse case scenario where the contract owner is a
     *      multisig and is compromised, with all the signers changed; we still
     *      can use an EOA to lock the contract and purge all the operators.
     */
    address public locker;

    /**
     * @dev A backup locker in case locker's private key is lost.
     */
    address public backupLocker;

    // =============================================================
    //                   CONSTRUCTOR / INITIALIZER
    // =============================================================

    constructor() payable {}

    /**
     * @dev Initializer.
     */
    function initialize(address owner_, address locker_) external payable {
        require(!_initialized);
        owner = owner_;
        _initialized = true;
        locker = locker_;
    }

    // =============================================================
    //               PUBLIC / EXTERNAL WRITE FUNCTIONS
    // =============================================================

    /**
     * @dev Adds the `operator` to the pre-approve list maintained by the caller (lister).
     * @param operator The account that can manage NFTs on behalf of
     *                 collectors subscribed to the caller.
     */
    function addOperator(address operator) external payable onlyOwner onlyUnlocked {
        /// @solidity memory-safe-assembly
        assembly {
            // Silence compiler warning on unused variable.
            let t := operator
            // Copy over the function selector and the operator to memory.
            calldatacopy(returndatasize(), returndatasize(), 0x24)
            if iszero(
                call(
                    gas(), // Remaining gas.
                    PRE_APPROVE_REGISTRY, // The pre-approve registry.
                    returndatasize(), // Send 0 ETH.
                    returndatasize(), // Start of calldata.
                    0x24, // Length of calldata.
                    returndatasize(), // Start of returndata in memory.
                    returndatasize() // Length of returndata.
                )
            ) {
                // This is to prevent gas under-estimation.
                revert(0, 0)
            }
        }
    }

    /**
     * @dev Removes the `operator` from the pre-approve list maintained by the caller (lister).
     * @param operator The account that can manage NFTs on behalf of
     *                 collectors subscribed to the caller.
     */
    function removeOperator(address operator) external payable onlyOwner {
        /// @solidity memory-safe-assembly
        assembly {
            // Silence compiler warning on unused variable.
            let t := operator
            // Copy over the function selector and the operator to memory.
            calldatacopy(returndatasize(), returndatasize(), 0x24)
            if iszero(
                call(
                    gas(), // Remaining gas.
                    PRE_APPROVE_REGISTRY, // The pre-approve registry.
                    returndatasize(), // Send 0 ETH.
                    returndatasize(), // Start of calldata.
                    0x24, // Length of calldata.
                    returndatasize(), // Start of returndata in memory.
                    returndatasize() // Length of returndata.
                )
            ) {
                // This is to prevent gas under-estimation.
                revert(0, 0)
            }
        }
    }

    /**
     * @dev Allows anyone to purge operators when the contract is locked.
     * @param count Number of operators to remove.
     */
    function purgeOperators(uint256 count) external payable onlyLocked {
        /// @solidity memory-safe-assembly
        assembly {
            // Grab the free memory pointer.
            let m := mload(0x40)

            for {} count { count := sub(count, 1) } {
                // Store the function selector of:
                // `bytes4(keccak256("operatorAt(address,uint256)"))`.
                mstore(0x00, 0x1085efc7)
                mstore(0x20, address()) // Store the address of the contract.
                mstore(0x40, 0) // Store 0.
                if iszero(
                    staticcall(
                        gas(), // Remaining gas.
                        PRE_APPROVE_REGISTRY, // The pre-approve registry.
                        0x1c, // Start of calldata.
                        0x44, // Length of calldata.
                        0x20, // Start of returndata in memory.
                        0x20 // Length of returndata.
                    )
                ) {
                    // This is to prevent gas under-estimation.
                    revert(0, 0)
                }
                // The operator is already stored in slot 0x20.

                // Store the function selector of:
                // `bytes4(keccak256("removeOperator(address)"))`.
                mstore(0x00, 0xac8a584a)

                if iszero(
                    call(
                        gas(), // Remaining gas.
                        PRE_APPROVE_REGISTRY, // The pre-approve registry.
                        0, // Send 0 ETH.
                        0x1c, // Start of calldata.
                        0x24, // Length of calldata.
                        0x00, // Start of returndata in memory.
                        0x00 // Length of returndata.
                    )
                ) {
                    // This is to prevent gas under-estimation.
                    revert(0, 0)
                }
            }
            // Restore the free memory pointer.
            mstore(0x40, m)
        }
    }

    /**
     * @dev Allows the contract owner to set a backup locker address.
     * @param backup The backup locker address.
     */
    function setBackupLocker(address backup) external payable onlyOwner {
        require(backup != address(0), "Backup cannot be zero.");
        require(backupLocker == address(0), "Already set.");
        backupLocker = backup;
    }

    /**
     * @dev Locks the ability to add new operators.
     *      This function is to be used when the contract owner is compromised.
     */
    function lock() external payable onlyOwnerOrLocker onlyUnlocked {
        locked = true;
    }

    // =============================================================
    //                  INTERNAL / PRIVATE HELPERS
    // =============================================================

    /**
     * @dev Require the caller to be the contract owner.
     */
    modifier onlyOwner() virtual {
        require(msg.sender == owner, "Unauthorized.");
        _;
    }

    /**
     * @dev Require the caller to be either the contract owner or locker.
     */
    modifier onlyOwnerOrLocker() virtual {
        require(
            msg.sender == owner || msg.sender == locker || msg.sender == backupLocker,
            "Unauthorized."
        );
        _;
    }

    /**
     * @dev Require that the contract is not locked.
     */
    modifier onlyUnlocked() virtual {
        require(!locked, "Locked.");
        _;
    }

    /**
     * @dev Require that the contract is locked.
     */
    modifier onlyLocked() virtual {
        require(locked, "Not locked.");
        _;
    }
}