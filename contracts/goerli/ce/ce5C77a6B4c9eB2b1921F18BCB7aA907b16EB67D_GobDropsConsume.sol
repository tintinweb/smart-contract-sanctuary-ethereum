// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnershipTransferred(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import "solmate/auth/Owned.sol";

interface IGobDrops {
        function transferFrom(address from, address to, uint256 id) external;
}

contract GobDropsConsume is Owned {

    address public gobDrops;

    constructor(
        address _owner,
        address _gobDrops
    ) Owned(_owner) {
        gobDrops = _gobDrops;
    }

    /// @dev Emitted when multiple tokens are consumed.
    event BulkConsume(
        uint indexed gooeyTokenId,
        uint[] indexed gobDropTokenIds,
        address indexed caller
    );

    /// @dev Emitted when a single token is consumed.
    event SingleConsume(
        uint indexed gooeyTokenId,
        uint indexed gobDropTokenId
    );

    /// @notice Function to consume multiple gobDrops for a single gobbler.
    /// @param gooeyTokenId The tokenId of the gobbler to consume gobDrops for.
    /// @param gobDropTokenIds The tokenIds of the gobDrops to consume.
    function bulkConsume(
        uint gooeyTokenId,
        uint[] calldata gobDropTokenIds
    ) external {
        for (uint i = 0; i < gobDropTokenIds.length; i++) {
            IGobDrops(gobDrops).transferFrom(msg.sender, address(0), gobDropTokenIds[i]);
        }
        emit BulkConsume(gooeyTokenId, gobDropTokenIds, msg.sender);
    }

    /// @notice Function to consume a single gobDrop for a single gobbler.
    /// @param gooeyTokenId The tokenId of the gobbler to consume gobDrops for.
    /// @param gobDropTokenId The tokenId of the gobDrop to consume.
    function singleConsume(
        uint gooeyTokenId,
        uint gobDropTokenId
    ) external {
        IGobDrops(gobDrops).transferFrom(msg.sender, address(0), gobDropTokenId);
        emit SingleConsume(gooeyTokenId, gobDropTokenId);
    }

    /// @notice Owner function to update the Gob Drops contract address.
    /// @param _gobDrops The new Gob Drops address.
    function updateGobDrops(address _gobDrops) external onlyOwner {
        gobDrops = _gobDrops;
    }

}