/**
 *Submitted for verification at Etherscan.io on 2022-02-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IERC1155 {
  function safeTransferFrom( address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
}

contract Airdrop {

  function bulkAirdropERC1155(IERC1155 _tokencontractaddress, uint256  _tokenid, uint256  _sendingamount, address[] calldata _receiveraddresses) public {
    for (uint256 i = 0; i < _receiveraddresses.length; i++) {
      _tokencontractaddress.safeTransferFrom(msg.sender,_receiveraddresses[i], _tokenid, _sendingamount, "");
    }
  }
}