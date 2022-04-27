/**
 *Submitted for verification at Etherscan.io on 2022-04-27
*/

pragma solidity ^0.8.0;
//SPDX-License-Identifier: MIT

interface IERC1155 {
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
    function safeTransferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
}

contract BulkAirdrop {
    function bulkAirdropERC1155(IERC1155 _token, address[] calldata _to, uint256[] calldata _id, uint256[] calldata _amount) public{
        require(_to.length == _id.length, "Receivers and IDs are different length");
        for(uint256 i=0; i<_to.length; i++){
           _token.safeTransferFrom(msg.sender, _to[i], _id[i], _amount[i], "");
        }
    }
}