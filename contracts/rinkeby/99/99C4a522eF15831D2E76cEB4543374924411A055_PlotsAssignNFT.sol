/**
 *Submitted for verification at Etherscan.io on 2022-02-25
*/

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface myIERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

contract Governance {

    address public _governance;

    constructor() {
        _governance = tx.origin;
    }

    event GovernanceTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyGovernance {
        require(msg.sender == _governance, "not governance");
        _;
    }

    function setGovernance(address governance)  public  onlyGovernance
    {
        require(governance != address(0), "new governance the zero address");
        emit GovernanceTransferred(_governance, governance);
        _governance = governance;
    }
}

contract PlotsAssignNFT is Governance{
 
    address public plot_nft = address(0xF5d56c3F506EA5C0605fAd06784b5Fe7c498EbCe);
    address public POST_TRANS = address(0x0);

    struct Nft_p {
        address nft_addr;
        uint256 token_id;
        uint256 blocknum;
    }
    
    // Array with all assign id
    uint256[] private _allAssigns;
    
    // Mapping from plot id to position in _allAssigns array
    mapping(uint256 => uint256) private _allAssignsIndex;

    mapping(uint256 => Nft_p) public assign_plot;
    mapping(address => mapping(uint256 => uint256)) public plot_find_at;

    event PlotNftAssigned(address nft_addr, uint256 erc721TokenId, uint256 plot_id, bool expend);
    event CleanAssign(uint256 plot_id);

    constructor() { }
    
    function assignNFTtoPlot(address nft_addr,uint256 erc721TokenId, uint256 plot_id) external
    {
        require(isApprovedOrOwner(nft_addr, msg.sender, erc721TokenId), "You must be owner or approved for ERC721 token");
        require(isApprovedOrOwner(plot_nft, msg.sender, plot_id), "You must be owner or approved for Plot NFT");

        Nft_p memory x = assign_plot[plot_id];

        if(x.nft_addr==address(0x0) && x.token_id == 0)
        {
            _allAssignsIndex[plot_id] = _allAssigns.length;
            _allAssigns.push(plot_id);
            emit PlotNftAssigned(nft_addr,erc721TokenId,plot_id,true);
        }
        else
        {
            emit PlotNftAssigned(nft_addr,erc721TokenId,plot_id,false);
        }

        plot_find_at[x.nft_addr][x.token_id] = 0; 

        assign_plot[plot_id] = Nft_p(nft_addr, erc721TokenId, block.number);
        plot_find_at[nft_addr][erc721TokenId] = plot_id; 
    }

    function assignClear(uint256 plot_id) external
    {
        Nft_p memory x = assign_plot[plot_id];
        if( x.nft_addr != address(0x0) )
        {
                if( isApprovedOrOwner(x.nft_addr, msg.sender, x.token_id) )
                {
                    plot_find_at[x.nft_addr][x.token_id] = 0; 
                }
                require(isApprovedOrOwner(plot_nft, msg.sender, plot_id), "You must be owner or approved for Plot NFT");
                assign_plot[plot_id] = Nft_p(address(0), 0, 0);

                uint256 lastAssignIndex = (_allAssigns.length-1);
                uint256 plotIndex = _allAssignsIndex[plot_id];
                uint256 lastPlotId = _allAssigns[lastAssignIndex];
                _allAssigns[plotIndex] = lastPlotId;
                _allAssignsIndex[lastPlotId] = plotIndex;
                _allAssigns.pop();
                _allAssignsIndex[plot_id] = 0;

                emit CleanAssign(plot_id);
        }
    
    }
    
    function totalAssigns() public view returns (uint256) {
        return _allAssigns.length;
    }
    
    function assignByIndex(uint256 index) public view returns (uint256) {
        require(index < totalAssigns(), "index out of bounds");
        return _allAssigns[index];
    }

    function setPostTransContract(address newcontract) public onlyGovernance
    {
        POST_TRANS = newcontract;
    }

    function isApprovedOrOwner(address nftAddress, address spender, uint256 tokenId) private view returns (bool) {
        myIERC721 implementation = myIERC721(nftAddress);
        address owner = implementation.ownerOf(tokenId);
        return (spender == owner  || spender == POST_TRANS  || implementation.getApproved(tokenId) == spender || implementation.isApprovedForAll(owner, spender));
    }

}