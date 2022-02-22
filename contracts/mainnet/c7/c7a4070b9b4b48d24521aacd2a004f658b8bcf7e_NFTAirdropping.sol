/**
 *Submitted for verification at Etherscan.io on 2022-02-22
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

//import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

interface IERC721
{
  function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

contract NFTAirdropping
{
  function airDropERC721 (IERC721 _token, address[] calldata _to, uint256[] calldata ids) public
  {
    require(_to.length == ids.length,"recievers and IDs are of different length");
    for (uint256 i=0; i < _to.length; i++)
    {
      _token.safeTransferFrom(msg.sender,_to[i],ids[i]);
    }
  }
}