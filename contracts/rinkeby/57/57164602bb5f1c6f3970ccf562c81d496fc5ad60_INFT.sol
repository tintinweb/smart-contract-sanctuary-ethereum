/**
 *Submitted for verification at Etherscan.io on 2022-04-01
*/

//SPDX-License-Identifier:GPL-3.0

pragma solidity ^0.8.0;

interface IERC721{
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function approve(address to, uint256 tokenId) external ;
    function getApproved(uint256 tokenId) external view returns (address);
    function transferFrom(address from, address to, uint256 tokenId) external ;
    function safeTransferFrom(address from, address to, uint256 tokenId,bytes memory data) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external ;
    }

interface IERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

interface IERC721TokenReceiver {
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes memory _data) external returns(bytes4);
}

interface IERC721Metadata /* is ERC721 */ {
    function name() external view returns (string memory );
    function symbol() external view returns (string memory );
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface IERC1155Metadata_URI {
    function uri(uint256 tokenid) external view returns (string memory);
}

interface ERC721Enumerable{
    function totalSupply() external view returns (uint256);
    function tokenByIndex(uint256 index) external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
}

abstract contract ERC721 is IERC165,IERC721,IERC721Metadata,IERC1155Metadata_URI,ERC721Enumerable{

    mapping(address=>uint) _balances;
    mapping(uint=>address) _owners; //tokenid=>owner
    mapping(address=>mapping(address=>bool)) _operatorapprovals;//owner=>operator=>allow?
    mapping(uint=>address) _tokenapprovals;//token=>operator
    string _name;
    string _symbol; 
    mapping(uint=>string) _tokenuris;

    uint[] _alltoken;
    mapping(uint=>uint) _alltokenindex;

    function _addtokentoallenum(uint tokenid)private{
        _alltoken.push(tokenid);
        _alltokenindex[tokenid]=_alltoken.length-1;
    }
    function _removetokenfromallenum(uint tokenid)private{
        uint index=_alltokenindex[tokenid];
        uint lastindex=_alltoken.length-1;

        if(index!=lastindex){
            uint lastid=_alltoken[lastindex];
            _alltoken[index]=lastid;
            _alltokenindex[lastid]=index;
        }
        _alltoken.pop();
        delete _alltokenindex[tokenid];
    }

    mapping(address=>mapping(uint=>uint)) _ownedtoken;
    mapping(uint=>uint)_ownedtokenindex;

    function _addtokentoownerenum(address owner,uint tokenid)private{
        uint index=_balances[owner]-1;
        _ownedtoken[owner][index]=tokenid;
        _ownedtokenindex[tokenid]=index;
    }
    function _removetokenfromownerenum(address owner,uint tokenid)private{
        uint index=_ownedtokenindex[tokenid];
        uint lastindex=_balances[owner];

        if(index!=lastindex){
            uint lastid=_ownedtoken[owner][lastindex];
            _ownedtoken[owner][index]=lastid;
            _ownedtokenindex[lastid]=index;
        }
        delete _ownedtoken[owner][lastindex];
        delete _ownedtokenindex[tokenid];
    }

    constructor(string memory name_,string memory symbol_){
        _name=name_;
        _symbol=symbol_;
    }

    function name() public override view returns (string memory ){
        return _name;
    }

     function symbol() public override view returns (string memory ){
         return _symbol;
     }

     function tokenURI(uint256 tokenId) public override view returns (string memory){
         return _tokenuris[tokenId];
     }

     function uri(uint256 tokenid)public override view returns (string memory){
         return tokenURI(tokenid);
     }

    function supportsInterface(bytes4 interfaceId) public override pure returns (bool){
        return interfaceId==type(IERC165).interfaceId
        ||interfaceId==type(IERC721).interfaceId
        ||interfaceId==type(IERC721Metadata).interfaceId
        ||interfaceId==type(IERC1155Metadata_URI).interfaceId
        ||interfaceId==type(ERC721Enumerable).interfaceId;
    }

    function balanceOf(address owner )public override view returns(uint){
        require(owner!=address(0));
        return _balances[owner];
    }

    function ownerOf(uint tokenid)public override view returns(address){
        address owner=_owners[tokenid];
        require(owner!=address(0));
        return owner;
    }

    function setApprovalForAll(address operator,bool approved) public override{
        require(msg.sender!=operator);
        _operatorapprovals[msg.sender][operator]=approved;

        emit ApprovalForAll(msg.sender,operator,approved);
    }

    function isApprovedForAll(address owner,address operator)public view override returns(bool){
        return _operatorapprovals[owner][operator];
    }

    function approve(address to,uint tokenid)public override{
        address owner=ownerOf(tokenid);
        require(to!=owner);
        require(msg.sender==owner||isApprovedForAll(owner,msg.sender));
        _approved(to,tokenid);
    }

    function getApproved(uint tokenid)public override view returns(address){
        require(_owners[tokenid]!=address(0));
        return _tokenapprovals[tokenid];
    }

    function transferFrom(address from,address to,uint tokenid)public override{
        require(from!=address(0));
        require(to!=address(0));

        address owner=ownerOf(tokenid);
        require(owner==from);

        require(msg.sender==owner||msg.sender==getApproved(tokenid)||
        isApprovedForAll(owner,msg.sender));

        _balances[from]-=1;
        _balances[to]+=1;
        _owners[tokenid]=to;

        emit Transfer(from,to,tokenid);

        _removetokenfromownerenum(from,tokenid);
        _addtokentoownerenum(to,tokenid);
    }

    function safeTransferFrom(address from,address to,uint tokenid,bytes memory data)public override{
        transferFrom(from,to,tokenid);

        require(_checkonerc721recieved(from,to,tokenid,data));
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override{
        safeTransferFrom(from,to,tokenId,"");
    }

    function _approved(address to,uint tokenid)internal {
        _tokenapprovals[tokenid]=to;
        address owner=ownerOf(tokenid);
        emit Approval(owner,to,tokenid);
    }

    function totalSupply() public override view returns (uint256){
        return _alltoken.length;
    }

    function tokenByIndex(uint256 index) public override view returns (uint256){
        require(index<_alltoken.length);
        return _alltoken[index];
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public override view returns (uint256){
        require(index<_balances[owner]);
        return _ownedtoken[owner][index];
    }

    function _checkonerc721recieved(address from,address to,uint tokenid,bytes memory data)private returns(bool){
        if(to.code.length<=0)return true;

        IERC721TokenReceiver reciever=IERC721TokenReceiver(to);
        try reciever.onERC721Received(msg.sender,from,tokenid,data) returns(bytes4 interfaceId){
            return interfaceId==type(IERC721TokenReceiver).interfaceId;
        }catch Error(string memory reason){
            revert(reason);
        }catch{
            revert();
        }
    }

    function _mint(address to,uint tokenid,string memory uri_) internal {
        require(to!=address(0));
        require(_owners[tokenid]==address(0));
        _balances[to]+=1;
        _owners[tokenid]=to;
        _tokenuris[tokenid]=uri_; 

        emit Transfer(address(0),to,tokenid);

        _addtokentoallenum(tokenid);
        _addtokentoownerenum(to,tokenid);
    }

    function _safemint(address to,uint tokenid,string memory uri_,bytes  memory data)internal{
        _mint(to,tokenid,uri_);

        require(_checkonerc721recieved(address(0),to,tokenid,data));
    }

     function _safemint(address to,uint tokenid,string memory uri_)internal{
        _safemint(to,tokenid,uri_,"");
    }

    function _burn(uint tokenid)internal{
        address owner=ownerOf(tokenid);
        require(msg.sender==owner||msg.sender==getApproved(tokenid)||isApprovedForAll(owner,msg.sender));

        _approved(address(0),tokenid);

        _balances[owner]-=1;
        delete _owners[tokenid];
        delete _tokenuris[tokenid];

        emit Transfer(owner,address(0),tokenid);

        _removetokenfromallenum(tokenid);
        _removetokenfromownerenum(owner,tokenid);
    }
}

contract INFT is ERC721{
    constructor() ERC721("Khun NFT","INFT"){

    }
    function create(uint tokenid,string memory uri)public{
        _mint(msg.sender,tokenid,uri);
    }

    function burn(uint tokenid)public{
        _burn(tokenid);
    }
}