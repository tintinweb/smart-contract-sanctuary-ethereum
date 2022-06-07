pragma solidity>0.8.0;//SPDX-License-Identifier:None
interface IERC721{
    event Transfer(address indexed from,address indexed to,uint indexed tokenId);
    event Approval(address indexed owner,address indexed approved,uint indexed tokenId);
    event ApprovalForAll(address indexed owner,address indexed operator,bool approved);
    function balanceOf(address)external view returns(uint);
    function ownerOf(uint)external view returns(address);
    function safeTransferFrom(address,address,uint)external;
    function transferFrom(address,address,uint)external;
    function approve(address,uint)external;
    function getApproved(uint)external view returns(address);
    function setApprovalForAll(address,bool)external;
    function isApprovedForAll(address,address)external view returns(bool);
    function safeTransferFrom(address,address,uint,bytes calldata)external;
}
interface IERC721Metadata{
    function name()external view returns(string memory);
    function symbol()external view returns(string memory);
    function tokenURI(uint)external view returns(string memory);
}
contract LSG is IERC721,IERC721Metadata{
    uint public count;
    address private _owner;
    enum Pause{YES,NO}
    Pause status=Pause.YES;
    mapping(address=>uint)private _balances;
    mapping(uint=>address)private _owners;
    mapping(uint=>address)private _tokenApprovals;
    mapping(address=>mapping(address=>bool))private _operatorApprovals;
    constructor(){
        _owner=msg.sender;
    }
    function MINT(uint n)external{unchecked{
        require(status==Pause.NO);
        require(count<3334&&n<11);
        _balances[msg.sender]+=n;
        for(uint i=0;i<n;i++){
            (count++,_owners[count]=msg.sender);
            emit Transfer(address(0),msg.sender,count);
        }
    }}
    function supportsInterface(bytes4 a)external pure returns(bool){
        return a==type(IERC721).interfaceId||a==type(IERC721Metadata).interfaceId;
    }
    function balanceOf(address a)external view override returns(uint){
        return _balances[a];
    }
    function ownerOf(uint a)public view override returns(address){
        return _owners[a]; 
    }
    function owner()external view returns(address){
        return _owner;
    }
    function name()external pure override returns(string memory){
        return"Lunatic Support Group";
    }
    function symbol()external pure override returns(string memory){
        return"LSG";
    }
    function approve(address a,uint b)external override{
        require(msg.sender==ownerOf(b)||isApprovedForAll(ownerOf(b),msg.sender));
        _tokenApprovals[b]=a;
        emit Approval(ownerOf(b),a,b);
    }
    function getApproved(uint a)public view override returns(address){
        return _tokenApprovals[a];
    }
    function setApprovalForAll(address a,bool b)external override{
        _operatorApprovals[msg.sender][a]=b;
        emit ApprovalForAll(msg.sender,a,b);
    }
    function isApprovedForAll(address a,address b)public view override returns(bool){
        return _operatorApprovals[a][b];
    }
    function transferFrom(address a,address b,uint c)public override{unchecked{
        require(a==ownerOf(c)||getApproved(c)==a||isApprovedForAll(ownerOf(c),a));
        (_tokenApprovals[c]=address(0),_balances[a]-=1,_balances[b]+=1,_owners[c]=b);
        emit Approval(ownerOf(c),b,c);
        emit Transfer(a,b,c);
    }}
    function safeTransferFrom(address a,address b,uint c)external override{
        transferFrom(a,b,c);
    }
    function safeTransferFrom(address a,address b,uint c,bytes memory)external override{
        transferFrom(a,b,c);
    }
    function tokenURI(uint a)external pure override returns(string memory){unchecked{
        string memory b="0";
        if(a>0){
            uint256 temp=a;
            uint256 digits;
            while(temp!=0)(digits++,temp/=10);
            bytes memory buffer=new bytes(digits);
            while(a!=0)(digits-=1,buffer[digits]=bytes1(uint8(48+uint256(a%10))),a/=10);
            b=string(buffer);
        }
        return string(abi.encodePacked("ipfs://QmNevbpJQhSPmDJhBDhDnyc4RUhCPvNSsFjLyyzNxsh47D/",b,".json"));
    }} 
    function TogglePause()external{
        require(_owner==msg.sender);
        status=status==Pause.NO?Pause.YES:Pause.NO;
    }
}