/**
 *Submitted for verification at Etherscan.io on 2022-09-06
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/// @title GitAnchor
/// @author Luzian Scherrer
/// @dev byte20 would be enough to store a SHA1 but string is used in order to be more generic
contract GitAnchor {
    struct Anchor {
        uint256 timestamp;
        address origin;
    }
    mapping(string => Anchor) anchors;

    /// @notice Event when an anchor has been stored
    /// @param anchorHash The anchor's hash
    /// @param anchorTimestamp The anchor's timestamp
    /// @param anchorOrigin The EOA of the creator of the anchor
    event Anchored(string anchorHash, uint256 anchorTimestamp, address anchorOrigin);

    constructor() {
    }

    /// @notice Returns an achor for a given hash
    /// @param anchorHash The hash to get the anchor for
    /// @return The anchor's timestamp and the creators EOA
    function getAnchor(string memory anchorHash) public view returns (uint256, address) {
        Anchor memory _anchor = anchors[anchorHash];
        return (_anchor.timestamp, _anchor.origin);
    }

    /// @notice Helper function to check if a hash has been anchored
    /// @param anchorHash The hash to check for an anchor
    /// @return True if the hash has an anchor, otherweise false
    function isAnchored(string memory anchorHash) public view returns (bool) {
        return anchors[anchorHash].timestamp != 0;
    }

    /// @notice Store an anchor (blocktimestamp and EOA of the origin) for the given hash
    /// @param anchorHash The hash to store the anchor for
    function setAnchor(string memory anchorHash) public {
        require(!isAnchored(anchorHash), 'Anchor already set');
        Anchor memory _anchor = Anchor(block.timestamp, tx.origin);
        anchors[anchorHash] = _anchor;
        emit Anchored(anchorHash, _anchor.timestamp, _anchor.origin);
    }
}