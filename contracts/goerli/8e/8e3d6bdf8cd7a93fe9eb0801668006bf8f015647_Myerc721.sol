/**
 *Submitted for verification at Etherscan.io on 2022-08-02
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0 <0.9.0; 

interface ERC721 {

    function balanceOf(address _owner) external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function approve(address _approved, uint256 _tokenId) external payable;
    function setApprovalForAll(address _operator, bool _approved) external;
    function getApproved(uint256 _tokenId) external view returns (address);
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);

    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
}

contract Myerc721 is ERC721{

    string private name = "MyNFT";
    string private symbol = "NIK";

    // Mapping from token ID to owner address
    mapping(uint256 => address) private owners;

    // Mapping owner address to token count
    mapping(address => uint256) private balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private tokenApprovals;

    mapping(address=>mapping(address=>bool)) private allapproval;

    function mint(uint token) external {   //Mint the token
    owners[token] = msg.sender;
    balances[msg.sender] +=1;
    }

    function balanceOf(address owner) external view override returns (uint ownerBalance){
        require(owner!=address(0),"not a valid address");
        return balances[owner];
    }

    function ownerOf(uint tokenId) external view override returns (address ownerAddress){
        require(owners[tokenId]!=address(0));
        return owners[tokenId];
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) external override payable{
        require(msg.sender==owners[tokenId] || isApproveOneOrAll(from,msg.sender,tokenId));
        owners[tokenId]=to;
        balances[from]-=1;
        balances[to]+=1;
        tokenApprovals[tokenId]=address(0);

    }

    function isApproveOneOrAll(address owner, address sender , uint token) internal view returns(bool){
        if(tokenApprovals[token] == sender || allapproval[owner][sender] == true){
            return true;
        }
        else{
        return false;
         }
    }

    function transfer(address to, uint token) external payable{
        require(msg.sender==owners[token],"You are not the owner of this token");
        owners[token] = to;
        balances[to]+=1;
        balances[msg.sender]-=1;
        tokenApprovals[token]=address(0);
        emit Transfer(msg.sender,to,token);
    }

    function approve(address approved, uint256 tokenId) external override payable{
        require(msg.sender==owners[tokenId]);
        tokenApprovals[tokenId]= approved;
        emit Approval(msg.sender,approved,tokenId);
    }

    function getApproved(uint256 tokenId) external override view returns (address){
        require(owners[tokenId]!=address(0));
        return tokenApprovals[tokenId];
    }

    function setApprovalForAll(address to, bool approval) external override{
        allapproval[msg.sender][to]=approval;
        emit ApprovalForAll(msg.sender,to,approval);
    }

    function isApprovedForAll(address owner, address to) external  view override returns (bool){
        if(allapproval[owner][to]){
            return allapproval[owner][to];
        }
        else{
            return false;
        }

    }

}