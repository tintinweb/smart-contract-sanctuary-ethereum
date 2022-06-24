/**
 *Submitted for verification at Etherscan.io on 2022-06-24
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.8.1;



// Part: ManagerStorage

contract ManagerStorage {
    /**
    * @notice Administrator for this contract
    */
    address public admin;

    /**
    * @notice Pending administrator for this contract
    */
    address public pendingAdmin;

    /**
    * @notice Active brains of Manager
    */
    address public managerImplementation;

    /**
    * @notice Pending brains of Manager
    */
    address public pendingManagerImplementation;

}

// Part: ManagerStorageV1

contract ManagerStorageV1 is ManagerStorage {
    string constant signMessage = "\x19Ethereum Signed Message:\n32";
    address public orangeSinger;
    address public nftAddr;
    mapping(uint256 => Campaign) public campaigns;
    mapping(bytes32 => uint256) participated;
    struct Campaign {
        uint256 cid;
        uint256 minted;
        uint256 limit;
        uint256 limitPerUser;
        bool isUsed;
    }
}

// File: ManagerProxy.sol

contract ManagerProxy is ManagerStorageV1 {

    /**
      * @notice Emitted when pendingManagerImplementation is changed
      */
    event NewPendingImplementation(address oldPendingImplementation, address newPendingImplementation);

    /**
      * @notice Emitted when pendingManagerImplementation is accepted, which means manager implementation is updated
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

        require(msg.sender == admin, "only owner");

        address oldPendingImplementation = pendingManagerImplementation;

        pendingManagerImplementation = newPendingImplementation;

        emit NewPendingImplementation(oldPendingImplementation, pendingManagerImplementation);

    }

    /**
    * @notice Accepts new implementation of Manager. msg.sender must be pendingImplementation
    * @dev Admin function for new implementation to accept it's role as implementation
    */
    function _acceptImplementation() public {
        // Check caller is pendingImplementation and pendingImplementation ≠ address(0)
        require(msg.sender == pendingManagerImplementation && pendingManagerImplementation != address(0), "illegal pendingManagerImplementation");

        // Save current values for inclusion in log
        address oldImplementation = managerImplementation;
        address oldPendingImplementation = pendingManagerImplementation;
        managerImplementation = pendingManagerImplementation;

        pendingManagerImplementation = address(0);

        emit NewImplementation(oldImplementation, managerImplementation);
        emit NewPendingImplementation(oldPendingImplementation, pendingManagerImplementation);

    }


    /**
      * @notice Begins transfer of admin rights. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
      * @dev Admin function to begin change of admin. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
      * @param newPendingAdmin New pending admin.
      */
    function _setPendingAdmin(address newPendingAdmin) public {
        // Check caller = admin
        require(msg.sender == admin, "only owner");

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
        require(msg.sender == pendingAdmin && msg.sender != address(0), "illegal pendingAdmin");

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
    fallback() payable external {
        // delegate all other functions to current implementation
        (bool success,) = managerImplementation.delegatecall(msg.data);

        assembly {
            let free_mem_ptr := mload(0x40)
            returndatacopy(free_mem_ptr, 0, returndatasize())

            switch success
            case 0 {revert(free_mem_ptr, returndatasize())}
            default {return (free_mem_ptr, returndatasize())}
        }
    }
}