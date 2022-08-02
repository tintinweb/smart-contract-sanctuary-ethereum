/**
 *Submitted for verification at Etherscan.io on 2022-08-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Synchron{
    /**
    * @notice Administrator for this contract
    */
    address public admin;
    /**
    * @notice Active brains of Knowhere
    */
    address public comptrollerImplementation;

    /**
    * @notice Pending brains of Knowhere
    */
    address public pendingComptrollerImplementation;

}

contract KnowhereProxy is Synchron{

    event NewPendingImplementation(address oldPendingImplementation, address newPendingImplementation);

    event NewImplementation(address oldImplementation, address newImplementation);
    /**
      * @notice Emitted when pendingAdmin is accepted, which means admin is updated
      */
    event NewAdmin(address oldAdmin, address newAdmin);

    receive() external payable {
        //assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    constructor() {
        // Set admin to caller
        admin = msg.sender;
    }

    /*** Admin Functions ***/
    function _setPendingImplementation(address newPendingImplementation) public  {
        
        require(admin == msg.sender,"KnowhereProxy:not permit");

        address oldPendingImplementation = pendingComptrollerImplementation;

        pendingComptrollerImplementation = newPendingImplementation;

        emit NewPendingImplementation(oldPendingImplementation, pendingComptrollerImplementation);

    }

    function _acceptImplementation() public returns(uint){

        require(pendingComptrollerImplementation == msg.sender && pendingComptrollerImplementation != address(0));

        // Save current values for inclusion in log
        address oldImplementation = comptrollerImplementation;
        address oldPendingImplementation = pendingComptrollerImplementation;

        comptrollerImplementation = pendingComptrollerImplementation;

        pendingComptrollerImplementation = address(0);

        emit NewImplementation(oldImplementation, comptrollerImplementation);

        emit NewPendingImplementation(oldPendingImplementation, pendingComptrollerImplementation);

        return 0;
    }

    function _updateAdmin(address _admin) public {
        require(admin == msg.sender,"KnowhereProxy:not permit");
        admin = _admin;
    }

    /**
     * @dev Delegates execution to an implementation contract.
     * It returns to the external caller whatever the implementation returns
     * or forwards reverts.
     */
    fallback() payable external {
        // delegate all other functions to current implementation
        (bool success, ) = comptrollerImplementation.delegatecall(msg.data);

        assembly {
              let free_mem_ptr := mload(0x40)
              returndatacopy(free_mem_ptr, 0, returndatasize())

              switch success
              case 0 { revert(free_mem_ptr, returndatasize()) }
              default { return(free_mem_ptr, returndatasize()) }
        }
    }

}