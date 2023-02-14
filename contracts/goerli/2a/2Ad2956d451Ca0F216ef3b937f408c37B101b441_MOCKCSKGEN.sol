// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRANDOMWORKER {
    function getRandomNumber(uint256 tokenId, address _msgSender)
        external
        returns (string memory);
}

interface INFTCORE {
    enum MintType{
        Mint,
        Whitelist
    }
    function getCurrentTokenId() external view returns (uint256);
    function getTotalSupply() external view returns (uint256);
    function mint(address _userAddr, string memory metadata, MintType _mintType) external;
}

contract MOCKCSKGEN {
    
    IRANDOMWORKER private iRandomWorker;
    INFTCORE public nftCore;

    constructor(
        address _nftCore,
        address _randomWokerAddr
    ) {
        nftCore = INFTCORE(_nftCore);
        iRandomWorker = IRANDOMWORKER(_randomWokerAddr);
    }

    /// @notice user call genToken to random item.
    function genToken() external payable {
        uint256 tokenId = nftCore.getCurrentTokenId();
        string memory results = iRandomWorker.getRandomNumber(tokenId, msg.sender);
        nftCore.mint(msg.sender, results, INFTCORE.MintType.Mint);
    }
 
}