// SPDX-License-Identifier: MIT
// File contracts/LPI/LPIS.sol

pragma solidity ^0.8.0;
// Lyfe Price Index Share
// LPI Utility Token

// Lyfebloc: https://lyfebloc.com

import "./ERC20PermissionedMint.sol";


contract LPIS is ERC20PermissionedMint {

    // Core
    ERC20PermissionedMint public LPI_TKN;

    /* ========== CONSTRUCTOR ========== */

    constructor(
      address _creator_address,
      address _timelock_address,
      address _lpi_address
    ) 
    ERC20PermissionedMint(_creator_address, _timelock_address, "Lyfe Price Index Share", "LPIS") 
    {
      LPI_TKN = ERC20PermissionedMint(_lpi_address);
      
      _mint(_creator_address, 100000000e18); // Genesis mint
    }


    /* ========== RESTRICTED FUNCTIONS ========== */

    function setLPIAddress(address lpi_contract_address) external onlyByOwnGov {
        require(lpi_contract_address != address(0), "Zero address detected");

        LPI_TKN = ERC20PermissionedMint(lpi_contract_address);

        emit LPIAddressSet(lpi_contract_address);
    }

    /* ========== EVENTS ========== */
    event LPIAddressSet(address addr);
}