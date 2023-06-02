// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

contract Stateless {

    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    function mint(uint256 tokenId) public {
        emit Transfer(address(0), msg.sender, tokenId);
    }

    function balanceOf(address _owner) external view returns (uint256) {
        return 1;
    }
    function ownerOf(uint256 _tokenId) external view returns (address) {
        return msg.sender;
    }
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) external payable{
        emit Transfer(_from, _to, _tokenId);
    }
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable{
        emit Transfer(_from, _to, _tokenId);
    }
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable {
        emit Transfer(_from, _to, _tokenId);
    }
    function approve(address _approved, uint256 _tokenId) external payable{
        emit Approval(address(0), _approved, _tokenId);
    }
    function setApprovalForAll(address _operator, bool _approved) external{
        emit ApprovalForAll(address(0), _operator, _approved);
    }
    function getApproved(uint256 _tokenId) external view returns (address){
        return msg.sender;
    }
    function isApprovedForAll(address _owner, address _operator) external view returns (bool){
        return true;
    }
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == bytes4(0x80ac58cd) || interfaceId == bytes4(0x150b7a02);
    }
}