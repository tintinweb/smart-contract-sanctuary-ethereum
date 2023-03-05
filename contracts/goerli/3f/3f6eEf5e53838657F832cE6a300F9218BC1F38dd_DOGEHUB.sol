//SPDX-License-Identifier: MIT

pragma solidity ^0.8;

import "./Ownable.sol";

interface DOGGY {
    function ownerOf(uint256 tokenId) external view returns (address);
    function balanceOf(address owner) external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
}

interface iFURFRAME {
    function mintFURFRAME(address to, uint tokenId) external;
    function exist(uint tokenId) external view returns (bool);
    function ownerOf(uint tokenId) external view returns (address);
    function transferFrom(address from, address to, uint id) external;
}


contract DOGEHUB is Ownable {
    DOGGY _0N1;
    iFURFRAME _FURFRAME;

    bool public MINT = false;

    constructor(address DGY, address FURFRAME) {
        _0N1 = DOGGY(DGY);
        _FURFRAME = iFURFRAME(FURFRAME);
    }

    function setMint()
    public onlyOwner {
        MINT = !MINT;
    }

    function mintFURFRAME(uint tokenId)
    public {
        require(MINT, "error MINT");
        require(!_FURFRAME.exist(tokenId), "error FURFRAME.exist");
        require(msg.sender == _0N1.ownerOf(tokenId), "error 0N1.owner");
        _FURFRAME.mintFURFRAME(msg.sender, tokenId);
    }

    function batchMintFURFRAME()
    public {
        require(MINT, "error MINT");
        uint i = 0;
        uint balance = _0N1.balanceOf(msg.sender);
        while (i < balance) {
            uint tokenId = _0N1.tokenOfOwnerByIndex(msg.sender, i);
            if (!_FURFRAME.exist(tokenId)) {
                require(!_FURFRAME.exist(tokenId), "error FURFRAME.exist");
                require(msg.sender == _0N1.ownerOf(tokenId), "error 0N1.owner");
                _FURFRAME.mintFURFRAME(msg.sender, tokenId);
            }
            i++;
        }
    }

    function recallFURFRAME(uint tokenId)
    public {
        require(_FURFRAME.exist(tokenId), "error FURFRAME.exist");
        require(msg.sender != _FURFRAME.ownerOf(tokenId), "error FURFRAME.owner");
        require(msg.sender == _0N1.ownerOf(tokenId), "error 0N1.owner");

        address frameOwner = _FURFRAME.ownerOf(tokenId);
        _FURFRAME.transferFrom(frameOwner, msg.sender, tokenId);
    }

    function batchRecallFURFRAME()
    public {
        uint i = 0;
        uint balance = _0N1.balanceOf(msg.sender);
        while (i < balance) {
            uint tokenId = _0N1.tokenOfOwnerByIndex(msg.sender, i);
            require(msg.sender == _0N1.ownerOf(tokenId), "error 0N1.owner");
            require(_FURFRAME.exist(tokenId), "error FURFRAME.exist");
            if (msg.sender != _FURFRAME.ownerOf(tokenId)) {
                address frameOwner = _FURFRAME.ownerOf(tokenId);
                _FURFRAME.transferFrom(frameOwner, msg.sender, tokenId);
            }
            i++;
        }
    }

    function transferFURFRAME(address to, uint tokenId)
    public {
        require(msg.sender == _FURFRAME.ownerOf(tokenId), "error FURFRAME.owner");
        require(_FURFRAME.exist(tokenId), "error FURFRAME.exist");

        _FURFRAME.transferFrom(msg.sender, to, tokenId);
    }
}