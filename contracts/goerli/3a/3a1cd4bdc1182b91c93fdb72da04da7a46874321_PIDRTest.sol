// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract PIDRTest {

    uint seed = 0;
    uint salePrice = 0.01 ether;

    struct Artwork {
        uint idArtwork;
        address owner;
    }

    Artwork internal artwork;

    constructor() {
        artwork = Artwork(0, msg.sender);
    }

    modifier ownerOnly() {
        require(msg.sender == artwork.owner);
        _;
    }

    function _generateRandom() private returns (uint) {
        uint rand = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, seed)));
        seed ++;
        return rand;
    }

    function _changeID() private {
        artwork.idArtwork = _generateRandom();
    }

    function _changeOwner(address _newOwner) internal {
        artwork.owner = _newOwner;
        _changeID();
    }
}