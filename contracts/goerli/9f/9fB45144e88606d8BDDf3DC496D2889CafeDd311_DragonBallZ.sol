// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./ERC721.sol";

contract DragonBallZ is NFTCollection {
    string public name;

    string public symbol;

    uint256 public tokenCount;

    mapping (uint256 => string) private _tokenURIs;

    constructor(string memory _name , string memory _symbol){
        name = _name;
        symbol = _symbol;
    }

    //https: url : consist all the information regarding metaData
    function tokenURI(uint256 _tokenId) public view returns (string memory){
        require(_owners[_tokenId] != address(0) , "Token id does not exit");
        return _tokenURIs[_tokenId];
    }

    //create a new NFT inside our collection
    function mint (string memory _tokenURI) public {
        tokenCount += 1;
        _balances[msg.sender] += 1;
        _owners[tokenCount] = msg.sender; 
        _tokenURIs[tokenCount] = _tokenURI;

        emit Transfer(address(0),msg.sender,tokenCount); 
    }

    //  function supportsInterface(bytes4 interfaceID) public pure override returns (bool){
    //     return interfaceID == 0x5b5e139f || interfaceID==0x80ac58cd ;
    //  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;


contract NFTCollection{
/*

   _balances -   0x1 : 12;

    _owners -  1 : 02x;

    _operatorApprovals -    
    01x :{
        0x2 : true;
     }

    _tokenApprovals - 
    
    1 : 02x

 */

    mapping(address => uint256) internal _balances;

    mapping(uint256 => address) internal _owners;

    mapping(address => mapping(address => bool)) private _operatorApprovals;

    mapping (uint256 => address) private _tokenApprovals;

    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    function balanceOf(address _owner) public view returns (uint256){
            require(_owner != address(0) , "Address is Invalid");
            return _balances[_owner];
    }

    function ownerOf(uint256 _tokenId) public view returns (address){
        address owner = _owners[_tokenId];
        require(owner != address(0) , "Invalid Token Id");
        return owner;
    }

    function setApprovalForAll(address _operator, bool _approved) external{
        _operatorApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender , _operator,_approved );
    }

    function isApprovedForAll(address _owner, address _operator) public view returns (bool){
       return  _operatorApprovals[_owner][_operator];
    }

    function approve(address _approved, uint256 _tokenId) public payable{
        address owner = ownerOf(_tokenId);
        require(msg.sender == owner || isApprovedForAll(owner,msg.sender) , "Msg.sender is not the owner or operator");
        _tokenApprovals[_tokenId] = _approved;
        emit Approval(owner , _approved , _tokenId);
    }
    
     function getApproved(uint256 _tokenId) public view returns (address){
        require(_owners[_tokenId] != address(0) , "Token Id is invalid");
        return _tokenApprovals[_tokenId];
     }

     function transferFrom(address _from, address _to, uint256 _tokenId) public payable{
        address owner = ownerOf(_tokenId);
        require(msg.sender == owner || getApproved(_tokenId) == msg.sender || isApprovedForAll(owner, msg.sender) , "Msg.sender is not owner or approved address for transfer");
        require(owner == _from , "from address is not the owner");
        require(_to != address(0), "Addrss is the Zero address");
        
        approve(address(0) , _tokenId);

        _balances[_from] -= 1;
        _balances[_to] += 1;
        _owners[_tokenId] = _to;

        emit Transfer(_from, _to , _tokenId);
     }

     function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) public{
        transferFrom(_from,_to,_tokenId);
        require(_checkOnERC721Received() , "Reciever not implement");
     }
    
    function _checkOnERC721Received() private pure returns(bool){
        return true;
    }

     function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable{
        safeTransferFrom(_from,_to,_tokenId ,"");
     }


   //   function supportsInterface(bytes4 interfaceID) view external  returns (bool){
   //       return interfaceID == 0x80ac58cd;
   //   }
}