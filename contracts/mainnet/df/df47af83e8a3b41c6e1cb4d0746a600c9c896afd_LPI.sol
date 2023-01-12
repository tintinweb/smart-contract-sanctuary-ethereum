// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// LPI Utility Token
// Lyfe Price Index
// Initial peg target is the US CPI-U (Consumer Price Index, All Urban Consumers)

// File contracts/LPI/LPI.sol

import "./ERC20PermissionedMint.sol";

contract LPI is ERC20PermissionedMint {

    /* ========== CONSTRUCTOR ========== */

    constructor(
      address _creator_address,
      address _timelock_address
    ) 
    ERC20PermissionedMint(_creator_address, _timelock_address, "Lyfe Price Index", "LPI") 
    {
      _mint(_creator_address, 100000000e18); // Genesis mint
    }

}