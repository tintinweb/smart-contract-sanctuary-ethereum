pragma solidity ^0.4.25;

import "./huggyattack.sol";
import "./erc721.sol";
import "./safemath.sol";

contract HuggyOwnership is HuggyAttack, ERC721 {

  using SafeMath for uint256;

  mapping (uint => address) huggyApprovals;

  function balanceOf(address _owner) external view returns (uint256) {
    return ownerHuggyCount[_owner];
  }

  function ownerOf(uint256 _tokenId) external view returns (address) {
    return huggyToOwner[_tokenId];
  }

  function _transfer(address _from, address _to, uint256 _tokenId) private {
    ownerHuggyCount[_to] = ownerHuggyCount[_to].add(1);
    ownerHuggyCount[msg.sender] = ownerHuggyCount[msg.sender].sub(1);
    huggyToOwner[_tokenId] = _to;
    emit Transfer(_from, _to, _tokenId);
  }

  function transferFrom(address _from, address _to, uint256 _tokenId) external payable {
      require (huggyToOwner[_tokenId] == msg.sender || huggyApprovals[_tokenId] == msg.sender);
      _transfer(_from, _to, _tokenId);
    }

  function approve(address _approved, uint256 _tokenId) external payable onlyOwnerOf(_tokenId) {
      huggyApprovals[_tokenId] = _approved;
      emit Approval(msg.sender, _approved, _tokenId);
    }

}