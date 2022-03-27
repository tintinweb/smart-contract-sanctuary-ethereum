// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/****************************************
 * @author: squeebo_nft                 *
 * @team:   GoldenX                     *
 ****************************************
 *   Blimpie-ERC721 provides low-gas    *
 *           mints + transfers          *
 ****************************************/

import "./MetaFightClubCitizensCore.sol";
import "./PaymentSplitterMod.sol";
import "./IERC721Batch.sol";
import "./IERC721.sol";
import "./ERC721Receiver.sol";
import "./IERC721Enumerable.sol";


contract MetaFightClubCitizens is MetaFightClubCitizensCore, IERC721Batch, IERC721Enumerable {


  using Address for address;


  mapping(uint256 => address) private _tokenApprovals;
  mapping(address => mapping(address => bool)) private _operatorApprovals;

  constructor(){
  }
   

   

  function isContract(address _addr) private view returns (bool aContract){
  uint32 size;
  assembly {
    size := extcodesize(_addr)
  }
  return (size > 0);
}

  function transferInternal( uint tokenId, address recipient ) external{
    require(ownerOf(tokenId) == msg.sender, "MFCC: transfer of token that is not own");
    require(recipient != address(0),        "MFCC: transfer to the zero address");

    // Clear approvals from the previous owner
    _approve(address(0), tokenId);
    _beforeTokenTransfer(msg.sender, recipient);
    owners[ tokenId ].owner = recipient;

    emit Transfer(msg.sender, recipient, tokenId);
  }


  //IERC721Batchboth
  function isOwnerOf( address account, uint[] calldata tokenIds ) external view override returns( bool ){
    for(uint i; i < tokenIds.length; ++i ){
      if( owners[ tokenIds[i] ].owner != account )
        return false;
    }

    return true;
  }

  function transferBatch( address from, address to, uint[] calldata tokenIds, bytes calldata data ) external override{
    for(uint i; i < tokenIds.length; ++i ){
      safeTransferFrom( from, to, tokenIds[i], data );
    }
  }

  function walletOfOwner( address account ) external view override returns( uint[] memory ){
    uint quantity = balanceOf( account );
    uint[] memory wallet = new uint[]( quantity );
    for( uint i; i < quantity; ++i ){
      wallet[i] = tokenOfOwnerByIndex( account, i );
    }
    return wallet;
  }


  //IERC165
  function supportsInterface(bytes4 interfaceId) public view virtual override( IERC165, MetaFightClubCitizensCore ) returns( bool ){
    return
      interfaceId == type(IERC721Enumerable).interfaceId ||
      interfaceId == type(IERC721).interfaceId ||
      super.supportsInterface(interfaceId);
  }


  //IERC721Enumerable
  function tokenOfOwnerByIndex(address owner, uint index) public view override returns( uint tokenId ){
    uint count;
    uint total = _offset + TOTAL_SUPPLY;
    for( uint i = _offset; i < total; ++i ){
      if( owner == owners[i].owner ){
        if( count == index )
          return i;
        else
          ++count;
      }
    }

    revert("ERC721Enumerable: owner index out of bounds");
  }

  function tokenByIndex(uint index) external view override returns (uint) {
    return index + _offset;
  }

  function totalSupply() public view override returns (uint) {
    return TOTAL_SUPPLY;
  }


  //IERC721
  function balanceOf( address owner ) public view virtual override returns( uint ){
    require(owner != address(0), "ERC721: balance query for the zero address");
    return balances[ owner ];
  }

  function ownerOf( uint tokenId ) public view override returns( address ){
    address owner = owners[tokenId].owner;
    require(owner != address(0), "ERC721: query for nonexistent token");
    return owner;
  }



  //IERC721 implementation
  function approve(address to, uint256 tokenId) public virtual override {
    address owner = ownerOf(tokenId);
    require(to != owner, "ERC721: approval to current owner");

    require(
      _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
      "ERC721: approve caller is not owner nor approved for all"
    );

    _approve(to, tokenId);
  }

  function getApproved(uint256 tokenId) public view virtual override returns (address) {
    require(_exists(tokenId), "ERC721: approved query for nonexistent token");
    return _tokenApprovals[tokenId];
  }

  function setApprovalForAll(address operator, bool approved) public virtual override {
    require(operator != _msgSender(), "ERC721: approve to caller");

    _operatorApprovals[_msgSender()][operator] = approved;
    emit ApprovalForAll(_msgSender(), operator, approved);
  }

  function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
    return _operatorApprovals[owner][operator];
  }

  function transferFrom(address from, address to, uint256 tokenId) public virtual override {
    //solhint-disable-next-line max-line-length
    require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

    _transfer(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override{
    safeTransferFrom(from, to, tokenId, "");
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
    require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
    _safeTransfer(from, to, tokenId, _data);
  }


  //internals
  function _approve(address to, uint tokenId) internal {
    _tokenApprovals[tokenId] = to;
    emit Approval(ownerOf(tokenId), to, tokenId);
  }

  function _beforeTokenTransfer(address from, address to) internal {
    if( from != address(0) )
      --balances[ from ];

    if( to != address(0) )
      ++balances[ to ];
  }

  function _burn(uint tokenId) internal override{
    address owner_ = ownerOf(tokenId);
    _beforeTokenTransfer(owner_, address(0));

    // Clear approvals
    _approve(owner(), tokenId);
    owners[tokenId].owner = address(0);
    emit Transfer(owner_, address(0), tokenId);
  }

  function _checkOnERC721Received(address from, address to, uint tokenId, bytes memory _data) private returns( bool ){
    if (isContract(to)){
        try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
        return retval == IERC721Receiver.onERC721Received.selector;
      } catch (bytes memory reason) {
        if (reason.length == 0) {
          revert("ERC721: transfer to non ERC721Receiver implementer");
        } else {
          assembly {
            revert(add(32, reason), mload(reason))
          }
        }
      }
    }else{
      return true;
    }
      
  }

  function _isApprovedOrOwner(address spender, uint tokenId) internal view returns (bool) {
    require(_exists(tokenId), "ERC721: operator query for nonexistent token");
    address owner = ownerOf(tokenId);
    return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
  }

  function _mint(address to, uint tokenId) internal override{
    require(to != address(0), "ERC721: mint to the zero address");
    require(!_exists(tokenId), "ERC721: token already minted");

    _beforeTokenTransfer(address(0), to);
    owners[ tokenId ].epoch = uint32(block.timestamp);
    owners[ tokenId ].owner = to;

    emit Transfer(address(0), to, tokenId);
  }

  function _safeTransfer(address from, address to, uint tokenId, bytes memory _data) internal{
    _transfer(from, to, tokenId);
    require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
  }

  function _transfer(address from, address to, uint tokenId) internal override {
    require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
    require(to != address(0), "ERC721: transfer to the zero address");

    // Clear approvals from the previous owner
    _approve(address(0), tokenId);
    _beforeTokenTransfer(from, to);

    uint32 hearts = getHearts( tokenId );
    owners[ tokenId ].baseHearts = hearts <3 ? 1 : hearts/2;
    owners[ tokenId ].owner = to;

    emit Transfer(from, to, tokenId);
  }

  function finalize() external onlyOwner {
    selfdestruct(payable(owner()));
  }
}