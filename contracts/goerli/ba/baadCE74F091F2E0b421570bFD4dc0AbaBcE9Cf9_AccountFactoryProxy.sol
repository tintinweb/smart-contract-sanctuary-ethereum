// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {AccountFactoryBaseStorage} from "./AccountFactoryStorage.sol";

// solhint-disable max-line-length

/**
 * @title AccountFactoryCore
 * @dev Storage for the AccountFactory is at this address, while execution is delegated to the `accountFactoryImplementation`.
 */
contract AccountFactoryProxy is AccountFactoryBaseStorage {
    /**
     * @notice Emitted when pendingAccountFactoryImplementation is changed
     */
    event NewPendingImplementation(address oldPendingImplementation, address newPendingImplementation);

    /**
     * @notice Emitted when pendingAccountFactoryImplementation is accepted, which means AccountFactory implementation is updated
     */
    event NewImplementation(address oldImplementation, address newImplementation);

    /**
     * @notice Emitted when pendingAdmin is changed
     */
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    /**
     * @notice Emitted when pendingAdmin is accepted, which means admin is updated
     */
    event NewAdmin(address oldAdmin, address newAdmin);

    constructor() {
        // Set admin to caller
        admin = msg.sender;
    }

    /*** Admin Functions ***/
    function _setPendingImplementation(address newPendingImplementation) public {
        require(msg.sender == admin, "SET_PENDING_IMPLEMENTATION_OWNER_CHECK");

        address oldPendingImplementation = pendingAccountFactoryImplementation;

        pendingAccountFactoryImplementation = newPendingImplementation;

        emit NewPendingImplementation(oldPendingImplementation, pendingAccountFactoryImplementation);
    }

    /**
     * @notice Accepts new implementation of AccountFactory. msg.sender must be pendingImplementation
     * @dev Admin function for new implementation to accept it's role as implementation
     */
    function _acceptImplementation() public {
        // Check caller is pendingImplementation and pendingImplementation ≠ address(0)
        require(
            msg.sender == pendingAccountFactoryImplementation && pendingAccountFactoryImplementation != address(0),
            "ACCEPT_PENDING_IMPLEMENTATION_ADDRESS_CHECK"
        );

        // Save current values for inclusion in log
        address oldImplementation = accountFactoryImplementation;
        address oldPendingImplementation = pendingAccountFactoryImplementation;

        accountFactoryImplementation = pendingAccountFactoryImplementation;

        pendingAccountFactoryImplementation = address(0);

        emit NewImplementation(oldImplementation, accountFactoryImplementation);
        emit NewPendingImplementation(oldPendingImplementation, pendingAccountFactoryImplementation);
    }

    /**
     * @notice Begins transfer of admin rights. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
     * @dev Admin function to begin change of admin. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
     * @param newPendingAdmin New pending admin.
     */
    function _setPendingAdmin(address newPendingAdmin) public {
        // Check caller = admin
        require(msg.sender == admin, "SET_PENDING_ADMIN_OWNER_CHECK");
        // Save current value, if any, for inclusion in log
        address oldPendingAdmin = pendingAdmin;

        // Store pendingAdmin with value newPendingAdmin
        pendingAdmin = newPendingAdmin;

        // Emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin)
        emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);
    }

    /**
     * @notice Accepts transfer of admin rights. msg.sender must be pendingAdmin
     * @dev Admin function for pending admin to accept role and update admin
     */
    function _acceptAdmin() public {
        // Check caller is pendingAdmin and pendingAdmin ≠ address(0)
        require((msg.sender == pendingAdmin && msg.sender != address(0)), "ACCEPT_ADMIN_PENDING_ADMIN_CHECK");
        // Save current values for inclusion in log
        address oldAdmin = admin;
        address oldPendingAdmin = pendingAdmin;

        // Store admin with value pendingAdmin
        admin = pendingAdmin;

        // Clear the pending value
        pendingAdmin = address(0);

        emit NewAdmin(oldAdmin, admin);
        emit NewPendingAdmin(oldPendingAdmin, pendingAdmin);
    }

    /**
     * @dev Delegates execution to an implementation contract.
     * It returns to the external caller whatever the implementation returns
     * or forwards reverts.
     */
    function _fallback() private {
        // delegate all other functions to current implementation
        (bool success, ) = accountFactoryImplementation.delegatecall(msg.data);

        assembly {
            let free_mem_ptr := mload(0x40)
            returndatacopy(free_mem_ptr, 0, returndatasize())

            switch success
            case 0 {
                revert(free_mem_ptr, returndatasize())
            }
            default {
                return(free_mem_ptr, returndatasize())
            }
        }
    }

    /**
     * @dev fallback just executes _fallback
     */
    fallback() external payable {
        _fallback();
    }

    /**
     * @dev reveive executes _fallback, too
     */
    receive() external payable {
        _fallback();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract AccountFactoryBaseStorage {
    /**
     * @notice Administrator for this contract
     */
    address public admin;

    /**
     * @notice Pending administrator for this contract
     */
    address public pendingAdmin;

    /**
     * @notice Active logic of AccountFactory
     */
    address public accountFactoryImplementation;

    /**
     * @notice Pending logic of AccountFactory
     */
    address public pendingAccountFactoryImplementation;
}

contract AccountFactoryStorageGenesis is AccountFactoryBaseStorage {
    bool public initialized;

    // address that provides the logic for each account proxy deployed from this contract
    address public facetProvider;

    // address that provides the data regards to protocols and pools to the account
    address public dataProvider;

    // maps user address to account array
    mapping(address => address[]) internal accounts;

    // maps account address to user who created the account
    mapping(address => address) public user;

    // all accounts created as an array
    address[] public allAccounts;
}