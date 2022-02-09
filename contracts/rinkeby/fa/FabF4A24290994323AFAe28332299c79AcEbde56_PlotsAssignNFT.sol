/**
 *Submitted for verification at Etherscan.io on 2022-02-09
*/

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface myIERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

contract PlotsAssignNFT {
 
    address public plot_nft = address(0xFc7C3de5Fe729E18828Fce6590C4c7B3568609Bf);

    struct Nft_p {
        address nft_addr;
        uint256 token_id;
    }
    
    // Array with all assign id
    uint256[] private _allAssigns;
    
    // Mapping from plot id to position in _allAssigns array
    mapping(uint256 => uint256) private _allAssignsIndex;

    mapping(uint256 => Nft_p) public assign_plot;
    mapping(address => mapping(uint256 => uint256)) public plot_find_at;

    event PlotNftAssigned(address nft_addr, uint256 erc721TokenId, uint256 plot_id);
    event CleanAssign(uint256 plot_id);

    constructor() { }
    

    function assignNFTtoPlot(address nft_addr,uint256 erc721TokenId, uint256 plot_id) external
    {
        require(isApprovedOrOwner(nft_addr, msg.sender, erc721TokenId), "You must be owner or approved for ERC721 token");
        require(isApprovedOrOwner(plot_nft, msg.sender, plot_id), "You must be owner or approved for Plot NFT");

        Nft_p memory x = assign_plot[plot_id];
        plot_find_at[x.nft_addr][x.token_id] = 0; 

        assign_plot[plot_id] = Nft_p(nft_addr, erc721TokenId);
        plot_find_at[nft_addr][erc721TokenId] = plot_id;
        
        _allAssignsIndex[plot_id] = _allAssigns.length;
        _allAssigns.push(plot_id);

        emit PlotNftAssigned(nft_addr,erc721TokenId,plot_id);
    }

    function assignClear(uint256 plot_id) external
    {
        Nft_p memory x = assign_plot[plot_id];
        if( isApprovedOrOwner(x.nft_addr, msg.sender, x.token_id) )
        {
            plot_find_at[x.nft_addr][x.token_id] = 0; 
        }
        require(isApprovedOrOwner(plot_nft, msg.sender, plot_id), "You must be owner or approved for Plot NFT");
        assign_plot[plot_id] = Nft_p(address(0), 0);

        uint256 lastAssignIndex = (_allAssigns.length-1);
        uint256 plotIndex = _allAssignsIndex[plot_id];
        uint256 lastPlotId = _allAssigns[lastAssignIndex];
        _allAssigns[plotIndex] = lastPlotId;
        _allAssignsIndex[lastPlotId] = plotIndex;
        _allAssigns.pop();
        _allAssignsIndex[plot_id] = 0;

        emit CleanAssign(plot_id);
    }
    
    function totalAssigns() public view returns (uint256) {
        return _allAssigns.length;
    }
    
    function assignByIndex(uint256 index) public view returns (uint256) {
        require(index < totalAssigns(), "index out of bounds");
        return _allAssigns[index];
    }

    function isApprovedOrOwner(address nftAddress, address spender, uint256 tokenId) private view returns (bool) {
        myIERC721 implementation = myIERC721(nftAddress);
        address owner = implementation.ownerOf(tokenId);
        return (spender == owner || implementation.getApproved(tokenId) == spender || implementation.isApprovedForAll(owner, spender));
    }

}