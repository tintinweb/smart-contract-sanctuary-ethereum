// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./NFTLiquidationStorage.sol";
/**
 * @title NFTLiquidationCore
 * @dev Storage for the nft liquidation is at this address, while execution is delegated to the `nftLiquidationImplementation`.
 * OTokens should reference this contract as their nft liquidation.
 */
contract NFTLiquidationProxy is NFTLiquidationProxyStorage {

    /**
      * @notice Emitted when pendingNFTLiquidationImplementation is changed
      */
    event NewPendingImplementation(address oldPendingImplementation, address newPendingImplementation);

    /**
      * @notice Emitted when pendingNFTLiquidationImplementation is accepted, which means nft liquidation implementation is updated
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

    constructor() public {
        // Set admin to caller
        admin = msg.sender;
    }

    /*** Admin Functions ***/
    function _setPendingImplementation(address newPendingImplementation) public {
        require(msg.sender == admin, "only admin");

        address oldPendingImplementation = pendingNFTLiquidationImplementation;

        pendingNFTLiquidationImplementation = newPendingImplementation;

        emit NewPendingImplementation(oldPendingImplementation, pendingNFTLiquidationImplementation);
    }

    /**
    * @notice Accepts new implementation of nft liquidation. msg.sender must be pendingImplementation
    * @dev Admin function for new implementation to accept it's role as implementation
    */
    function _acceptImplementation() public {
        // Check caller is pendingImplementation and pendingImplementation ≠ address(0)
        require(msg.sender == pendingNFTLiquidationImplementation && pendingNFTLiquidationImplementation != address(0), "only from pending implementation");

        // Save current values for inclusion in log
        address oldImplementation = nftLiquidationImplementation;
        address oldPendingImplementation = pendingNFTLiquidationImplementation;

        nftLiquidationImplementation = pendingNFTLiquidationImplementation;

        pendingNFTLiquidationImplementation = address(0);

        emit NewImplementation(oldImplementation, nftLiquidationImplementation);
        emit NewPendingImplementation(oldPendingImplementation, pendingNFTLiquidationImplementation);
    }

    /**
      * @notice Begins transfer of admin rights. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
      * @dev Admin function to begin change of admin. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
      * @param newPendingAdmin New pending admin.
      */
    function _setPendingAdmin(address newPendingAdmin) public {
        // Check caller = admin
        require(msg.sender == admin, "only admin");

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
    function _acceptAdmin() public returns (uint) {
        // Check caller is pendingAdmin and pendingAdmin ≠ address(0)
        require(msg.sender == pendingAdmin && msg.sender != address(0), "only pending admin");

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
    fallback () payable external {
        // delegate all other functions to current implementation
        (bool success, ) = nftLiquidationImplementation.delegatecall(msg.data);

        assembly {
              let free_mem_ptr := mload(0x40)
              returndatacopy(free_mem_ptr, 0, returndatasize())

              switch success
              case 0 { revert(free_mem_ptr, returndatasize()) }
              default { return(free_mem_ptr, returndatasize()) }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

contract NFTLiquidationProxyStorage {
    /**
    * @notice Administrator for this contract
    */
    address public admin;

    /**
    * @notice Pending administrator for this contract
    */
    address public pendingAdmin;

    /**
    * @notice Active brains of NFTLiquidationProxy
    */
    address public nftLiquidationImplementation;

    /**
    * @notice Pending brains of NFTLiquidationProxy
    */
    address public pendingNFTLiquidationImplementation;
}

contract NFTLiquidationV1Storage is NFTLiquidationProxyStorage {
    /**
     * @dev Guard variable for re-entrancy checks
     */
    bool internal _notEntered;

    /**
     * @notice Comptroller
     */
    address public comptroller;

    /**
     * @notice OEther
     */
    address public oEther;

    /**
     * @notice Protocol Fee Recipient
     */
    address payable public protocolFeeRecipient;

    /**
     * @notice Protocol Fee
     */
    uint256 public protocolFeeMantissa;

    /**
     * @notice Extra repay amount(unit is main repay token)
     */
    uint256 public extraRepayAmount;

    /**
     * @notice Requested seize NFT index array
     */
    uint256[] public seizeIndexes_;
}