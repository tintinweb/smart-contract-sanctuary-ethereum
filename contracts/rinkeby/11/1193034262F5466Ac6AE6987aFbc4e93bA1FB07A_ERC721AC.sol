pragma solidity^0.8.13;//SPDX-License-Identifier: MIT
interface IERC721{event Transfer(address indexed from,address indexed to,uint256 indexed tokenId);event Approval(address indexed owner,address indexed approved,uint256 indexed tokenId);event ApprovalForAll(address indexed owner,address indexed operator,bool approved);function balanceOf(address owner)external view returns(uint256 balance);function ownerOf(uint256 tokenId)external view returns(address owner);function safeTransferFrom(address from,address to,uint256 tokenId)external;function transferFrom(address from,address to,uint256 tokenId)external;function approve(address to,uint256 tokenId)external;function getApproved(uint256 tokenId)external view returns(address operator);function setApprovalForAll(address operator,bool _approved)external;function isApprovedForAll(address owner,address operator)external view returns(bool);function safeTransferFrom(address from,address to,uint256 tokenId,bytes calldata data)external;}
interface IERC721Metadata{function name()external view returns(string memory);function symbol()external view returns(string memory);function tokenURI(uint256 tokenId)external view returns(string memory);}
interface IOwlWarLand{function BURN(address _t,uint256 _a)external;} 
contract ERC721AC is IERC721,IERC721Metadata{
    address private _owner;
    mapping(uint256=>address)private _tokenApprovals;
    mapping(address=>mapping(address=>bool))private _operatorApprovals;
    uint256 public count;
    IOwlWarLand private iOWL;
    struct OWL{
        address owner;
        uint256 parent1;
        uint256 parent2;
        uint256 time;
        uint256 gen;
        uint256 sex;
        string cid;
    }
    struct GEN{
        uint256 maxCount;
        uint256 currentCount;
    }
    mapping(uint256=>OWL)public owl;
    mapping(uint256=>GEN)public gen;
    mapping(address=>uint256[])private tokens;
    modifier onlyOwner(){
        require(_owner==msg.sender);_;
    }
    constructor(){
        _owner=msg.sender;
        gen[1].maxCount=168;
        gen[2].maxCount=1680;//TESTING VARIABLES
    }
    function supportsInterface(bytes4 f)external pure returns(bool){
        return f==type(IERC721).interfaceId||f==type(IERC721Metadata).interfaceId;
    }
    function balanceOf(address o)external view override returns(uint256){
        return tokens[o].length;
    }
    function ownerOf(uint256 k)public view override returns(address){
        return owl[k].owner;
    }
    function owner()external view returns(address){
        return _owner;
    }
    function name()external pure override returns(string memory){
        return"Whooli Hootie Conservation Club";
    }
    function symbol()external pure override returns(string memory){
        return"WHCC";
    }
    function tokenURI(uint256 k)external view override returns(string memory){
        return string(abi.encodePacked("ipfs://",owl[k].cid));
    }
    function approve(address t,uint256 k)external override{
        require(msg.sender==ownerOf(k)||isApprovedForAll(ownerOf(k),msg.sender));
        _tokenApprovals[k]=t;
        emit Approval(ownerOf(k),t,k);
    }
    function getApproved(uint256 tokenId)public view override returns(address){
        return _tokenApprovals[tokenId];
    }
    function setApprovalForAll(address p,bool a)external override{
        _operatorApprovals[msg.sender][p]=a;
        emit ApprovalForAll(msg.sender,p,a);
    }
    function isApprovedForAll(address o,address p)public view override returns(bool){
        return _operatorApprovals[o][p];
    }
    function transferFrom(address f,address t,uint256 k)public override{unchecked{
        require(f==ownerOf(k)||getApproved(k)==f||isApprovedForAll(ownerOf(k),f));
        _tokenApprovals[k]=address(0);
        emit Approval(ownerOf(k),t,k);
        for(uint256 i=0;i<tokens[f].length;i++)if(tokens[f][i]==k){
            tokens[f][i]=tokens[f][tokens[f].length-1];
            tokens[f].pop();
            break;
        }
        tokens[t].push(k);
        owl[k].parent1=0;
        owl[k].parent2=0;
        owl[k].owner=t;
        emit Transfer(f,t,k);
    }}
    function safeTransferFrom(address f,address t,uint256 k)external override{
        transferFrom(f,t,k);
    }
    function safeTransferFrom(address f,address t,uint256 k,bytes memory d)external override{
        d=d;
        transferFrom(f,t,k);
    }
    function PLAYERITEMS(address a)external view returns(uint256[]memory,uint256[]memory,uint256[]memory,uint256[]memory,uint256[]memory,uint256[]memory,uint256[]memory){unchecked{
        uint256[]memory arr=tokens[a];
        uint256[]memory r0=new uint256[](arr.length);
        uint256[]memory r1=new uint256[](arr.length);
        uint256[]memory r2=new uint256[](arr.length);
        uint256[]memory r3=new uint256[](arr.length);
        uint256[]memory r4=new uint256[](arr.length);
        uint256[]memory r5=new uint256[](arr.length);
        uint256[]memory r6=new uint256[](arr.length);
        for(uint256 i=0;i<arr.length;i++){
            r0[i]=owl[arr[i]].parent1;
            r1[i]=owl[arr[i]].parent2;
            r2[i]=owl[arr[i]].time;
            r3[i]=owl[arr[i]].gen;
            r4[i]=owl[arr[i]].sex;
            r5[i]=arr[i];
            r6[i]=gen[owl[arr[i]].gen+1].currentCount<gen[owl[arr[i]].gen+1].maxCount?1:0;
        }
        return(r0,r1,r2,r3,r4,r5,r6);
    }}
    function getBalance()external view returns(uint256){
        return address(this).balance;
    }
    function TokenAddress(address a)external onlyOwner{
        iOWL=IOwlWarLand(a);
    }
    function GENPREP(uint256 k, uint256 m)external onlyOwner{
        gen[k].maxCount=m;
    }
    function DISTRIBUTE()external{unchecked{
        bool s;
        (s,)=payable(payable(_owner)).call{value:address(this).balance/gen[1].currentCount<168?95:5*100}("");
        for(uint256 i=1;i<=count;i++){
            (s,)=payable(payable(owl[i].owner)).call{value:address(this).balance/count}("");
        }
        require(s);
    }}
    function _mint(address a, uint256 g,uint256 s,string memory r)private{unchecked{
        require(gen[g].currentCount<gen[g].maxCount);
        count++;
        gen[g].currentCount++;
        owl[count].owner=a;
        owl[count].sex=s;
        owl[count].cid=r;
        owl[count].gen=g;
        tokens[a].push(count);
        emit Transfer(address(0),msg.sender,count);
    }}
    function AIRDROP(address a,uint256 s,string memory r)external onlyOwner{
        _mint(a,1,s,r);
    }
    function MINT(uint256 s,string memory r)external payable{unchecked{
        require(msg.value>=0.00 ether); /***[DEPLOYMENT SET TO 0.88]***/
        _mint(msg.sender,1,s,r);
    }}
    function BREED(uint256 p,uint256 q,uint256 s,string memory r)external payable{unchecked{
        bool existed;
        for(uint256 i=0;tokens[msg.sender].length>i;i++){
            if(((owl[tokens[msg.sender][i]].parent1==p&&owl[tokens[msg.sender][i]].parent2==q)||
            (owl[tokens[msg.sender][i]].parent2==p&&owl[tokens[msg.sender][i]].parent1==q))){
                existed=true;
                break;
            }
        }
        require(!existed&& //never mint before
            owl[p].gen==owl[q].gen&& //must be same gen
            owl[p].owner==msg.sender&&owl[q].owner==msg.sender&& //must only owner of p and q
            (owl[p].sex==0&&owl[q].sex==1||owl[q].sex==0&&owl[p].sex==1)&& //must be different sex
            owl[p].time+0<block.timestamp&&owl[q].time+0<block.timestamp);//time [DEPLOYMENT 604800]

        iOWL.BURN(msg.sender,30); //must have 30 OWL token
        _mint(msg.sender,owl[p].gen+1,s,r);
        owl[count].parent1=p;
        owl[count].parent2=q;
        owl[p].time=block.timestamp;
        owl[q].time=block.timestamp;
    }}
}