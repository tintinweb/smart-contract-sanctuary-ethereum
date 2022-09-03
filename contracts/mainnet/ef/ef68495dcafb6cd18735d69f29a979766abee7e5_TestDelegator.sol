/**
 *Submitted for verification at Etherscan.io on 2022-09-02
*/

// File: contracts/TestAdminStorage.sol

pragma solidity ^0.6.12;

contract TestAdminStorage{

    address public admin;

    address public implementation;
}

// File: contracts/TestDelegator.sol

pragma solidity ^0.6.12;

contract TestDelegator is TestAdminStorage {

    event NewImplementation(
        address oldImplementation,
        address newImplementation
    );
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);
    event NewAdmin(address oldAdmin, address newAdmin);

    constructor(
        address _nft,
        address _implementation
    ) public {
        admin = msg.sender;
        delegateTo(
            _implementation,
            abi.encodeWithSignature(
                "initialize(address)",
                _nft
            )
        );
        _setImplementation(_implementation);
    }

    function _setImplementation(address implementation_) public {
        require(msg.sender == admin, "UNAUTHORIZED");

        address oldImplementation = implementation;
        implementation = implementation_;

        emit NewImplementation(oldImplementation, implementation);
    }

    /**
     * @notice transfer of admin rights. msg.sender must be admin
     * @dev Admin function for update admin
 
     */
    function _setAdmin(address newAdmin) public {
        // Check caller is admin
        require(msg.sender == admin, "UNAUTHORIZED");

        // Save current values for inclusion in log
        address oldAdmin = admin;

        // Store admin with value newAdmin
        admin = newAdmin;

        emit NewAdmin(oldAdmin, admin);
    }

    function delegateTo(address callee, bytes memory data)
        internal
        returns (bytes memory)
    {
        (bool success, bytes memory returnData) = callee.delegatecall(data);
        assembly {
            if eq(success, 0) {
                revert(add(returnData, 0x20), returndatasize())
            }
        }
        return returnData;
    }

    receive() external payable{}

    /**
     * @notice Delegates execution to an implementation contract
     * @dev It returns to the external caller whatever the implementation returns or forwards reverts
    //  */
    fallback() external payable {
        // delegate all other functions to current implementation
        (bool success, ) = implementation.delegatecall(msg.data);
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
}