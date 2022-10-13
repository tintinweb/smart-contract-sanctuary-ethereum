// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract SessionFacet {
    bytes32 internal constant NAMESPACE = keccak256("diamond.storage.SessionFacet");

    struct Session {
        uint256 nftTokenId;
        address highestBidder;
        uint256 highestBid;
        bool active;
    }

    struct DiamondStorage {
        mapping(uint256 => Session) session;   
    }

    function getStorage() internal pure returns (DiamondStorage storage s) {
        bytes32 position = NAMESPACE;
        assembly {
            s.slot := position
        }
    }

    function setSession(uint256 _nftTokenId, address _highestBidder, uint256 _highestBid, bool _active) external {
        DiamondStorage storage s = getStorage();
        s.session[_nftTokenId] = Session(_nftTokenId, _highestBidder, _highestBid, _active);
    }

    function getSession(uint256 _nftTokenId) external view returns (Session memory) {
        return getStorage().session[_nftTokenId];
    }
}