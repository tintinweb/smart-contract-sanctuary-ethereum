/**
 *Submitted for verification at Etherscan.io on 2022-05-10
*/

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/**
 * @title Union multi-Lands to one Estate for LofiTown land service
 * 
 */

interface myIERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

interface ILand {

    function plots(uint256 tokenId) external view returns (
        int128 x,
        int128 y,
        int128 t,
        uint256 mint_log,
        bool exists
    );
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

contract AdUnion is Governance{
  
    address public land_nft = address(0x9c6Def8771aF345023A0a0bc581E2f02BB214bD7);
    address public land_agent = address(0x0);

    uint256 maxMatrix = 4;
    uint256 _WIDTH_MAX = 71;

    mapping(address => bool) public _operators;
    mapping(uint256 => uint256) private union_lands;
    mapping(uint256 => uint256) private union_log;

    uint256[] private _allUnion;
    mapping(uint256 => uint256) private _allUnionIndex;

    event ToUnionFlat(uint256 land_id,uint256 matrix);	
    event ToReleaseLands(uint256 land_id);

    constructor() { }
    
    function UnionFlat( address sender, uint256 land_id,uint256 size) external returns (int8 result)
    {     
        require(_operators[msg.sender], "Operator invalid");

        if( checkUnion( sender, size, land_id ) )
        {
            union_lands[land_id] = size;
            union_log[land_id] = block.number;
            _addUnion(land_id);

            emit ToUnionFlat(land_id, size);
            return 1;
        }
        else if( checkUnionAgent( sender, size, land_id ) )
        {
            union_lands[land_id] = size;
            union_log[land_id] = block.number;
            _addUnion(land_id);

            emit ToUnionFlat(land_id, size);
            return 2;
        }
        else
           return -1;
    } 

    function ReleaseUnion(uint256 land_id) external
    {   
          require(_operators[msg.sender], "Operator invalid");

            uint256 head_id = find_union(land_id);  
            if( head_id != 0 )
            {
                union_lands[head_id] = 0;
                union_log[head_id] = block.number;
                _removeUnion(head_id);

                emit ToReleaseLands(land_id);
            }

    }

    function setMaxMatrix(uint256 _max) public onlyGovernance
    {
        maxMatrix = _max;
    }

    function setLandAgent(address agent_contract) public onlyGovernance {
        land_agent = agent_contract;
    }

    function addOperator(address operator) public onlyGovernance {
        _operators[operator] = true;
    }

    function removeOperator(address operator) public onlyGovernance {
        _operators[operator] = false;
    }

    function checkUnion(address owner, uint256 matrix, uint256 land_id) public view returns (bool result)
    {
        if( matrix > maxMatrix )
          return false;

        if( (land_id%_WIDTH_MAX)== 0 || ((land_id%_WIDTH_MAX)+matrix-1) > _WIDTH_MAX )
          return false;

        for(uint256 j=0;j<matrix;j++)
        {
            for(uint256 i=land_id;i<land_id+matrix;i++)
            {
                uint256 tokenId = j *_WIDTH_MAX +i;
                
                if( !isLandExist(land_nft,tokenId) )
                {
                   return false; 
                }

                if( !isApprovedOrOwner(land_nft, owner, tokenId ) )
                {
                    return false;   
                }

               if( _isUnionRange(tokenId) )
                   return false; 
            }
        }

        return true;
    }

    function checkUnionAgent(address owner, uint256 matrix, uint256 land_id) public view returns (bool result)
    {
        if(land_agent == address(0x0) )
          return false;

        if( matrix > maxMatrix )
          return false;

        if( (land_id%_WIDTH_MAX)== 0 || ((land_id%_WIDTH_MAX)+matrix-1) > _WIDTH_MAX )
          return false;

        for(uint256 j=0;j<matrix;j++)
        {
            for(uint256 i=land_id;i<land_id+matrix;i++)
            {
                uint256 tokenId = j *_WIDTH_MAX +i;

                if( !isLandExist(land_agent,tokenId) )
                {
                   return false; 
                }

                if( !isApprovedOrOwner(land_agent, owner, tokenId ) )
                {
                    return false;   
                }

               if( _isUnionRange(tokenId) )
                   return false; 
            }
        }

        return true;
    }

    function fastcheckUnion(uint256 matrix, uint256 land_id) public view returns (bool result)
    {
        if(  matrix > maxMatrix )
          return false;

        if( (land_id%_WIDTH_MAX)== 0 || ((land_id%_WIDTH_MAX)+matrix-1) > _WIDTH_MAX )
          return false;

        for(uint256 j=0;j<matrix;j++)
        {
            for(uint256 i=land_id;i<land_id+matrix;i++)
            {
               uint256 tokenId = j*_WIDTH_MAX+i;
               if( _isUnionRange(tokenId) )
                   return false; 
            }
        }
        return true;
    }

    function isApprovedOrOwner(address nftAddress, address spender, uint256 tokenId) private view returns (bool) {
        myIERC721 implementation = myIERC721(nftAddress);
        address owner = implementation.ownerOf(tokenId);
        return (spender == owner  || implementation.getApproved(tokenId) == spender || implementation.isApprovedForAll(owner, spender));
    }

    function isLandApprovedOrOwner(address spender, uint256 tokenId) external view returns (bool) {
        address owner = address(0x0);
        address owner_approveone = address(0x0);
        address agent = address(0x0);        
        address agent_approveone = address(0x0); 
        bool owner_approveall = false;
        bool agent_approveall = false;        
        if( isLandExist(land_nft,tokenId) )
        {
            myIERC721 implementation1 = myIERC721(land_nft);
            owner = implementation1.ownerOf(tokenId);
            owner_approveone = implementation1.getApproved(tokenId);
            if( implementation1.isApprovedForAll(owner, spender) )
               owner_approveall = true;
        }

        if( isLandExist(land_agent,tokenId) )
        {
            myIERC721 implementation2 = myIERC721(land_agent);
            agent = implementation2.ownerOf(tokenId);
            agent_approveone = implementation2.getApproved(tokenId);
            if( implementation2.isApprovedForAll(agent, spender) )
               agent_approveall = true;
        }

        return (spender == owner || spender == agent || spender == owner_approveone || spender == agent_approveone || owner_approveall || agent_approveall );
    }

    function isLandExist(address nftAddress, uint256 tokenId) private view returns (bool) {
        if( nftAddress == address(0x0) )
            return false; 
        ILand implementation = ILand(nftAddress);
        (,,,,bool isExist) = implementation.plots(tokenId);
        return isExist;
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
            uint256 size = union_lands[_allUnion[i]];
            for(uint256 k=0;k<size;k++)
            {
                for(uint256 j=0;j<size;j++)
                {
                    uint256 s = start_id + j + k*_WIDTH_MAX;
                    if( s == target)
                    {
                        return true;
                    }
                }
            }
        }    
        return false;
    }

    function find_union(uint256 target) private view returns(uint256 landid)
    { 
        for(uint256 i=0;i<_allUnion.length;i++)
        {
            uint256 start_id = _allUnion[i]; 
            uint256 size = union_lands[_allUnion[i]];
            for(uint256 k=0;k<size;k++)
            {
                for(uint256 j=0;j<size;j++)
                {
                    uint256 s = start_id + j + k*_WIDTH_MAX;
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

    function unionByIndex(uint256 index) public view returns (uint256) {
        require(index < totalUnion(), "index out of bounds");
        return _allUnion[index];
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
                dat[1] = union_lands[_allUnion[i]];
                array[i] = [ dat[0], dat[1] ];
            }  
            return array;
    }  

    function GetoneUnion(uint256 tokenId) public view returns (uint256 matrix, uint256 blocknum) 
    {
        return ( union_lands[tokenId], union_log[tokenId] );
    }

}