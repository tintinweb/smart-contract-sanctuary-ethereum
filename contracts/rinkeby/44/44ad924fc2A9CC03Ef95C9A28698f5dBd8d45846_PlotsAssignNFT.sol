/**
 *Submitted for verification at Etherscan.io on 2022-01-31
*/

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface myIERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

contract PlotsAssignNFT {
 
    address public plot_nft = address(0xF296A1b5327ccC949bE8619D500C5534ed245156);

    struct Nft_p {
        address nft_addr;
        uint256 token_id;
    }

    mapping(uint256 => Nft_p) public assign_plot;
    mapping(address => mapping(uint256 => uint256)) public plot_find_at;

    event PlotNftAssigned(address nft_addr, uint256 erc721TokenId, uint256 plot_id);

    constructor() { }
    

    function assignNFTtoPlot(address nft_addr,uint256 erc721TokenId, uint256 plot_id) external
    {
        require(isApprovedOrOwner(nft_addr, msg.sender, erc721TokenId), "You must be owner or approved for ERC721 token");
        require(isApprovedOrOwner(plot_nft, msg.sender, plot_id), "You must be owner or approved for Plot NFT");

        Nft_p memory x = assign_plot[plot_id];
        plot_find_at[x.nft_addr][x.token_id] = 0; 

        assign_plot[plot_id] = Nft_p(nft_addr, erc721TokenId);
        plot_find_at[nft_addr][erc721TokenId] = plot_id;

        emit PlotNftAssigned(nft_addr,erc721TokenId,plot_id);
    }


    function isApprovedOrOwner(address nftAddress, address spender, uint256 tokenId) private view returns (bool) {
        myIERC721 implementation = myIERC721(nftAddress);
        address owner = implementation.ownerOf(tokenId);
        return (spender == owner || implementation.getApproved(tokenId) == spender || implementation.isApprovedForAll(owner, spender));
    }

}