// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import {ILandToken} from "../../../common/interfaces/ILandToken.sol";

/// @title Tunnel migration on L1
/// @author The Sandbox
/// @notice Contract handling the migration of LAND tokens from a tunnel to a new one
contract LandTunnelMigration {
    ILandToken public immutable landToken;
    address public immutable newLandTunnel;
    address public immutable oldLandTunnel;
    address private admin;

    event TunnelLandsMigrated(address indexed oldLandTunnel, address indexed newLandTunnel, uint256[] ids);
    event TunnelQuadsMigrated(
        address indexed oldLandTunnel,
        address indexed newLandTunnel,
        uint256[] sizes,
        uint256[] x,
        uint256[] y
    );
    event AdminChanged(address indexed _newAdmin);

    modifier isAdmin() {
        require(admin == msg.sender, "LandTunnelMigration: !AUTHORISED");
        _;
    }

    /// @notice Constructor of the tunnel migration contract
    /// @param _landToken LAND token address
    /// @param _newLandTunnel the tunnel address to migrate to
    /// @param _oldLandTunnel the tunnel address to migrate from
    /// @param _admin admin of the contract
    constructor(
        address _landToken,
        address _newLandTunnel,
        address _oldLandTunnel,
        address _admin
    ) {
        require(_admin != address(0), "LandTunnelMigration: admin can't be zero address");
        require(_landToken != address(0), "LandTunnelMigration: landToken can't be zero address");
        require(_newLandTunnel != address(0), "LandTunnelMigration: new Tunnel can't be zero address");
        require(_oldLandTunnel != address(0), "LandTunnelMigration: old Tunnel can't be zero address");

        admin = _admin;
        landToken = ILandToken(_landToken);
        newLandTunnel = _newLandTunnel;
        oldLandTunnel = _oldLandTunnel;

        emit AdminChanged(_admin);
    }

    /// @dev Transfers all the passed land ids from the old land tunnel to the new land tunnel
    /// @notice This method needs super operator role to execute
    /// @param ids of land tokens to be migrated
    function migrateLandsToTunnel(uint256[] memory ids) external isAdmin {
        landToken.batchTransferFrom(oldLandTunnel, newLandTunnel, ids, "");
        emit TunnelLandsMigrated(oldLandTunnel, newLandTunnel, ids);
    }

    /// @dev Transfers all the passed quads from the old land tunnel to the new land tunnel
    /// @notice This method needs super operator role to execute
    /// @param sizes of land quads to be migrated
    /// @param x coordinate of land quads to be migrated
    /// @param y coordinate of land quads to be migrated
    function migrateQuadsToTunnel(
        uint256[] memory sizes,
        uint256[] memory x,
        uint256[] memory y
    ) external isAdmin {
        landToken.batchTransferQuad(oldLandTunnel, newLandTunnel, sizes, x, y, "");
        emit TunnelQuadsMigrated(oldLandTunnel, newLandTunnel, sizes, x, y);
    }

    /// @notice changes admin to new admin
    /// @param _newAdmin the new admin to be set
    function changeAdmin(address _newAdmin) external isAdmin {
        require(_newAdmin != address(0), "LandTunnelMigration: admin can't be zero address");
        admin = _newAdmin;
        emit AdminChanged(_newAdmin);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

/// @title ILandToken
/// @author The Sandbox
/// @notice Interface of the LAND token including quad methods
interface ILandToken {
    /// @notice transfer multiple quad (aligned to a quad tree with size 3, 6, 12 or 24 only)
    /// @param from current owner of the quad
    /// @param to destination
    /// @param sizes list of sizes for each quad
    /// @param xs list of bottom left x coordinates for each quad
    /// @param ys list of bottom left y coordinates for each quad
    /// @param data additional data
    function batchTransferQuad(
        address from,
        address to,
        uint256[] calldata sizes,
        uint256[] calldata xs,
        uint256[] calldata ys,
        bytes calldata data
    ) external;

    /// @notice transfer one quad (aligned to a quad tree with size 3, 6, 12 or 24 only)
    /// @param from current owner of the quad
    /// @param to destination
    /// @param size size of the quad
    /// @param x The top left x coordinate of the quad
    /// @param y The top left y coordinate of the quad
    /// @param data additional data
    function transferQuad(
        address from,
        address to,
        uint256 size,
        uint256 x,
        uint256 y,
        bytes calldata data
    ) external;

    /// @notice Transfer many tokens between 2 addresses.
    /// @param from The sender of the token.
    /// @param to The recipient of the token.
    /// @param ids The ids of the tokens.
    /// @param data Additional data.
    function batchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        bytes calldata data
    ) external;
}