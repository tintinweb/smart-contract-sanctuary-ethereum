/**
 *Submitted for verification at Etherscan.io on 2022-09-27
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/// @title OnCHain Smart Contract Interface
interface OnChainInterface{
    function mint(address _address) external payable;
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}


/// @title Wrapper contract for on-chain NFT Contract
contract OnChainNFTWrapper{
    
    address ONCHAIN_NFT_CONTRACT_ADDRESS;

    constructor(address _ONCHAIN_NFT_CONTRACT_ADDRESS){
         ONCHAIN_NFT_CONTRACT_ADDRESS = _ONCHAIN_NFT_CONTRACT_ADDRESS;
    }


    // @notice minting is free
    function mint() external payable {
        OnChainInterface(ONCHAIN_NFT_CONTRACT_ADDRESS).mint(msg.sender);
    }
    
    function tokenURI(uint256 _tokenId) public view returns (string memory) {
        return OnChainInterface(ONCHAIN_NFT_CONTRACT_ADDRESS).tokenURI(_tokenId);
    }


}