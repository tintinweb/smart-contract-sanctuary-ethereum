//SPDX-License-Identifier: MIT 
pragma solidity ^0.8.9;

interface IERC721Receiver{
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
        ) external returns (bytes4);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./IERC721Receiver.sol";


contract ERC721{
    string public name;
    string public symbol;

    uint public nextTokenToMint;
    address public contractOwner;

    //token id => owner
    mapping(uint256 =>address) internal _owner;
    //owner =>token count
    mapping(address =>uint256) internal _balances;
    //token id =>approved address
    mapping(uint256 => address) internal _tokenApprovals;
    //owner =>(operator => yes/no) 
    mapping(address => mapping(address =>bool)) internal _operatorApprovals;
    //token id => token uri
    mapping (uint256 =>string) _tokenUris;

    event Transfer(address indexed _from,address indexed _to,uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    constructor(string memory _name, string memory _symbol){

        name = _name;
        symbol = _symbol;
        nextTokenToMint =0;
        contractOwner = msg.sender;
    }

    function balanceOf(address _owner) public view returns(uint256){
        require(_owner != address(0), "!add0");
        return _balances[_owner];
    }

    function ownerOf(uint256 _tokenId) public view returns(address){
        return _owner[_tokenId];
    }

     function safeTransferFrom(address _from, address _to, uint256 _tokenId) public payable {
        safeTransferFrom(_from, _to, _tokenId, "");
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) public payable {
        require(ownerOf(_tokenId) == msg.sender || _tokenApprovals[_tokenId] == msg.sender || _operatorApprovals[ownerOf(_tokenId)][msg.sender], "!Auth");
        _transfer(_from, _to, _tokenId);
        // trigger func check
        require(_checkOnERC721Received(_from, _to, _tokenId, _data), "!ERC721Implementer");
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) public payable{

        //unsafe to transfer this function without erc721 token
        require(ownerOf(_tokenId) == msg.sender || _tokenApprovals[_tokenId] == msg.sender || _operatorApprovals[ownerOf(_tokenId)][msg.sender], "!Auth");
        _transfer(_from, _to, _tokenId);
    }

    function approve(address _approved, uint256 _tokenId) public payable{
        require(ownerOf(_tokenId) == msg.sender, "!owner");
        _tokenApprovals[_tokenId] = _approved;
        emit Approval(ownerOf(_tokenId), _approved, _tokenId);
    }

    function setApprovalforAll(address _operator, bool _approved) public{
        _operatorApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function getApproved(uint256 _tokenId) public view returns(address){
        return _tokenApprovals[_tokenId];
    }

    function isApprovalForAll(address _owner, address _operator) public view returns(bool){
        return _operatorApprovals[_owner][_operator];
    }

    function mintTo(address _to, string memory _uri) public {
        require(contractOwner == msg.sender, "!owner");
        _owner[nextTokenToMint] =_to;
        _balances[_to] +=1;
        _tokenUris[nextTokenToMint] =_uri;
        emit Transfer(address(0), _to, nextTokenToMint);
        nextTokenToMint += 1;

    }

    function tokenURI (uint256 _tokenId) public view returns(string memory ){
        return _tokenUris[_tokenId];
    }

    function totalSupply() public view returns (uint256){
        return nextTokenToMint;
    }

    // INTERNAL FUNCTIONS
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        // check if to is an contract, if yes, to.code.length will always > 0
        if (to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    //unsafe transfer
    function _transfer(address _from, address _to,uint256 _tokenId)
 internal{
    require(ownerOf(_tokenId) == _from,"!owner");
    require(_to != address(0), "!toaddr");

    delete _tokenApprovals[_tokenId];
    _balances[_from] -=1;
    _balances[_to] +=1;
    _owner[_tokenId] = _to;

    emit Transfer(_from, _to, _tokenId);

 }
}