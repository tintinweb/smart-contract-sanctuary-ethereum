/**
 *Submitted for verification at Etherscan.io on 2022-02-04
*/

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface myIERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

contract PlotsUnion {
  
    address public plot_nft = address(0xFc7C3de5Fe729E18828Fce6590C4c7B3568609Bf);
    mapping(uint256 => uint256) private union_plot;

    uint256[] private _allUnion;
    mapping(uint256 => uint256) private _allUnionIndex;

    constructor() { }
    
    function UnionPlots(uint256 matrix, uint256 plot_id) external
    {     
        if( checkUnion( msg.sender, matrix, plot_id ) )
        {
            union_plot[plot_id] = matrix;
            _addUnion(plot_id);
        }
    }

    function ReleasePlots(uint256 plot_id) external
    {     
         if(  isApprovedOrOwner(plot_nft, msg.sender, plot_id ) )
         {
            union_plot[plot_id] = 0;
            _removeUnion(plot_id);
         }
    }

    function checkUnion(address owner, uint256 matrix, uint256 plot_id) public view returns (bool result)
    {
        
        require( ((plot_id%24)+matrix) <=24, "matrix too large, over limit");
        bool res = false;
        for(uint256 j=0;j<matrix;j++)
        {
            for(uint256 i=plot_id;i<plot_id+matrix;i++)
            {
                res = false;
                if(  isApprovedOrOwner(plot_nft, owner, j*24+i ) )
                {
                    res = true;  
                }
                else
                {
                    return false;
                }
            }
        }
        return res;

    }

    function isApprovedOrOwner(address nftAddress, address spender, uint256 tokenId) private view returns (bool) {
        myIERC721 implementation = myIERC721(nftAddress);
        address owner = implementation.ownerOf(tokenId);
        return (spender == owner || implementation.getApproved(tokenId) == spender || implementation.isApprovedForAll(owner, spender));
    }

    function _addUnion(uint256 tokenId) private {
        _allUnionIndex[tokenId] = _allUnion.length;
        _allUnion.push(tokenId);
    }

    function _removeUnion(uint256 tokenId) private {

        uint256 lastIndex = _allUnion.length-1;
        uint256 uIndex = _allUnionIndex[tokenId];
        uint256 lastId = _allUnion[lastIndex];

        _allUnion[uIndex] = lastId; 
        _allUnionIndex[lastId] = uIndex; 

        _allUnion.pop();
        _allUnionIndex[tokenId] = 0;
    }

    function totalUnion() public view returns (uint256) {
        return _allUnion.length;
    }

    function GetUnions() public view returns (uint256[] memory ) 
    {
    
            uint256[] memory array = new uint256[](_allUnion.length);
            for(uint256 i=0;i<_allUnion.length;i++)
            {
                array[ i] = _allUnion[i];
            }  
            return array;
    }  

    function ListUnions() public view returns (uint256[2][] memory ) 
    {
            uint256[] memory dat = new uint256[](2);
            uint256[2][] memory array = new uint256[2][](_allUnion.length);

            for(uint256 i=0;i<_allUnion.length;i++)
            {
                dat[0] = _allUnion[i]; 
                dat[1] = union_plot[_allUnion[i]];
                array[i] = [ dat[0], dat[1] ];
            }  
            return array;
    }  

}