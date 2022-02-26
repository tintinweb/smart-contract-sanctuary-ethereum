/**
 *Submitted for verification at Etherscan.io on 2022-02-26
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

contract PlotsUnion is Governance{
  
    address public plot_nft = address(0xF5d56c3F506EA5C0605fAd06784b5Fe7c498EbCe);

    address public POST_TRANS = address(0x0);
    uint256 maxMatrix = 3;

    mapping(uint256 => uint256) private union_plot;
    mapping(uint256 => uint256) private union_log;

    uint256[] private _allUnion;
    mapping(uint256 => uint256) private _allUnionIndex;

    event ToUnionPlots(uint256 matrix, uint256 plot_id);	
    event ToReleasePlots(uint256 plot_id);

    constructor() { }
    
    function UnionPlots(uint256 matrix, uint256 plot_id) external
    {     
        if( checkUnion( msg.sender, matrix, plot_id ) )
        {
            union_plot[plot_id] = matrix;
            union_log[plot_id] = block.number;
            _addUnion(plot_id);

            emit ToUnionPlots(matrix, plot_id);
        }
    } 

    function ReleasePlots(uint256 plot_id) external
    {     
        if( isApprovedOrOwner(plot_nft, msg.sender, plot_id ) )
        {
            uint256 head_id = find_union(plot_id);  
            if( head_id != 0 )
            {
                union_plot[head_id] = 0;
                union_log[head_id] = block.number;
                _removeUnion(head_id);

                emit ToReleasePlots(plot_id);
            }
        }
    }

    function setPostTransContract(address newcontract) public onlyGovernance
    {
        POST_TRANS = newcontract;
    }

    function setMaxMatrix(uint256 _max) public onlyGovernance
    {
        maxMatrix = _max;
    }

    function checkUnion(address owner, uint256 matrix, uint256 plot_id) public view returns (bool result)
    {
        if(  matrix < 2 || matrix > maxMatrix )
          return false;

        if( (plot_id%24)== 0 || ((plot_id%24)+matrix-1) > 24 )
          return false;

        for(uint256 j=0;j<matrix;j++)
        {
            for(uint256 i=plot_id;i<plot_id+matrix;i++)
            {
                uint256 tokenId = j*24+i;
                
                if( !isApprovedOrOwner(plot_nft, owner, tokenId ) )
                {
                    return false;   
                }

               if( _isUnionRange(tokenId) )
                   return false; 
            }
        }

        return true;
    }

    function fastcheckUnion(uint256 matrix, uint256 plot_id) public view returns (bool result)
    {
        if(  matrix < 2 || matrix > maxMatrix )
          return false;

        if( (plot_id%24)== 0 || ((plot_id%24)+matrix-1) > 24 )
          return false;

        for(uint256 j=0;j<matrix;j++)
        {
            for(uint256 i=plot_id;i<plot_id+matrix;i++)
            {
               uint256 tokenId = j*24+i;
               if( _isUnionRange(tokenId) )
                   return false; 
            }
        }
        return true;
    }

    function isApprovedOrOwner(address nftAddress, address spender, uint256 tokenId) private view returns (bool) {
        myIERC721 implementation = myIERC721(nftAddress);
        address owner = implementation.ownerOf(tokenId);
        return (spender == owner  || spender == POST_TRANS || implementation.getApproved(tokenId) == spender || implementation.isApprovedForAll(owner, spender));
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

    function _isUnionRange(uint256 target) public view returns(bool)
    {
        for(uint256 i=0;i<_allUnion.length;i++)
        {
            uint256 start_id = _allUnion[i]; 
            uint256 size = union_plot[_allUnion[i]];
            for(uint256 k=0;k<size;k++)
            {
                for(uint256 j=0;j<size;j++)
                {
                    uint256 s = start_id + j + k*24;
                    if( s == target)
                    {
                        return true;
                    }
                }
            }
        }    
        return false;
    }

    function find_union(uint256 target) private view returns(uint256 plotid)
    { 
        for(uint256 i=0;i<_allUnion.length;i++)
        {
            uint256 start_id = _allUnion[i]; 
            uint256 size = union_plot[_allUnion[i]];
            for(uint256 k=0;k<size;k++)
            {
                for(uint256 j=0;j<size;j++)
                {
                    uint256 s = start_id + j + k*24;
                    if( s == target)
                    {
                        return start_id;
                    }
                }
            }
        }     
        return 0;
    }


    function totalUnion() public view returns (uint256) {
        return _allUnion.length;
    }

    function GetUnions() public view returns (uint256[] memory ) 
    {
    
            uint256[] memory array = new uint256[](_allUnion.length);
            for(uint256 i=0;i<_allUnion.length;i++)
            {
                array[i] = _allUnion[i];
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

    function GetoneUnion(uint256 tokenId) public view returns (uint256 matrix, uint256 blocknum) 
    {
        return ( union_plot[tokenId], union_log[tokenId] );
    }

}