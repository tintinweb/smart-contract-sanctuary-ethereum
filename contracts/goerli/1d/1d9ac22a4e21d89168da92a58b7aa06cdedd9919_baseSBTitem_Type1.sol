/**
 *Submitted for verification at Etherscan.io on 2022-08-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
contract baseSBTitem_Type1 {

    mapping(address => uint256) public balanceOf;
    mapping(uint256 => address) public ownerOf;
    mapping(uint256 => string) public tokenURI;
    string public name;
    string public symbol;
    address public owner;

    bytes32 private validator = 0xddc8e02dcd816f76b8a3f185785cd995996e1d01d976b1d4c05a9bc7718a3b1d;

    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    
    error NonTransfable();

    function initialize(string calldata _name,string calldata _symbol) external{
        require(owner == address(0));
        owner = msg.sender;
        name = _name;
        symbol = _symbol;
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) external payable{
        revert NonTransfable();
    }
    
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable{
        revert NonTransfable();
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) external payable{
        require(msg.sender == owner);
        if(_from != owner || _to == address(0)){
            revert NonTransfable();
        }
        ownerOf[_tokenId] = _to;
        balanceOf[_from] -= 1;
        balanceOf[_to] += 1;
        emit Transfer(_from,_to,_tokenId);
    }

    function approve(address _approved, uint256 _tokenId) external payable{
        revert NonTransfable();
    }

    function setApprovalForAll(address _operator, bool _approved) external{
        revert NonTransfable();
    }

    function getApproved(uint256 _tokenId) external view returns (address){
        revert NonTransfable();
    }

    function isApprovedForAll(address _owner, address _operator) external view returns (bool){
        revert NonTransfable();
    }

    function supportsInterface(bytes4 interfaceID) external pure returns (bool){
        return
            interfaceID == 0x80ac58cd ||
            interfaceID == 0x5b5e139f;
    }

    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns(bytes4){
    }

    function setOwner(address newOwner) external{
        require(msg.sender == owner,"OWNER ONLY");
        owner = newOwner;
    }

    function drop(address _to,uint256 _tokenId,string calldata _uri) external{
        require(msg.sender == owner,"OWNER ONLY");
        require(_to != address(0),"INVAILED ADDRESS");
        ownerOf[_tokenId] = _to;
        balanceOf[_to] = 1; 
        tokenURI[_tokenId] = _uri;
        emit Transfer(address(0),_to,_tokenId);
    }

    function batchDrop(address[] calldata _tos,uint256[] calldata _tokenIds,string[] calldata _uris) external{
        require(msg.sender == owner,"OWNER ONLY");
        require(_tos.length == _tokenIds.length,"INVAILED LENGTH");
        require(_tokenIds.length == _uris.length,"INVAILED LENGTH");
        for(uint256 i=0;i<_tokenIds.length;i++){
           unchecked{
                ownerOf[_tokenIds[i]] = _tos[i];
                balanceOf[_tos[i]] += 1; 
                tokenURI[_tokenIds[i]] = _uris[i];
                emit Transfer(address(0),_tos[i],_tokenIds[i]);
            }
        }        
    }

    function mint(address _owner,uint256 _tokenId,string calldata _uri,uint256 _salt,bytes calldata _signature) external{
        bytes32 messagehash = keccak256(abi.encode(_owner,_tokenId,_uri,_salt));
        require(verify(messagehash,_signature),"INVAILED");
        ownerOf[_tokenId] = _owner;
        balanceOf[_owner] += 1; 
        tokenURI[_tokenId] = _uri; 
        emit Transfer(address(0),_owner,_tokenId);
    }

    function setTokenURI(uint256 _tokenId,string calldata _uri) external {
        require(msg.sender == owner,"OWNER ONLY");
        tokenURI[_tokenId] = _uri;
    }

    function batchSetTokenURI(uint256[] calldata _tokenIds,string[] calldata _uris) external {
        require(msg.sender == owner,"OWNER ONLY");
        require(_tokenIds.length == _uris.length,"INVAILED LENGTH");
        for(uint256 i=0;i<_tokenIds.length;i++){
           unchecked{
                tokenURI[_tokenIds[i]] = _uris[i];
            }
        }
    }

    function setValidator(address _newValidator) external {
        validator = keccak256(abi.encodePacked(_newValidator));
    }

   function verify(bytes32 hash,bytes memory sig) public view returns (bool) {
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
        return keccak256(abi.encodePacked(ecrecover(hash, v, r, s))) == validator;
    }

}