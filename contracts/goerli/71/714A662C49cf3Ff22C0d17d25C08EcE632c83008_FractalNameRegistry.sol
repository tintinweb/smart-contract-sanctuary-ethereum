//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IFractalNameRegistry.sol";

/// @notice A contract for registering Fractal DAO name strings
/// @notice These names are non-unique, and should not be used as the identifer of a DAO
contract FractalNameRegistry is IFractalNameRegistry {
    /// @notice Updates the DAO's registered aname
    /// @param _name The new DAO name
    function updateDAOName(string memory _name) external {
        emit FractalNameUpdated(msg.sender, _name);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFractalNameRegistry {
    event FractalNameUpdated(address indexed daoAddress, string daoName);

    /// @notice Updates the DAO's registered aname
    /// @param _name The new DAO name
    function updateDAOName(string memory _name) external;
}