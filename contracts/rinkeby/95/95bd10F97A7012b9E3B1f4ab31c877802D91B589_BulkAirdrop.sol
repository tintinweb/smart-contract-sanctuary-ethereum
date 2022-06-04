// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

interface IERC721 {
	function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

contract BulkAirdrop {

	constructor() {}

	function bulkAirdropERC712(IERC721 _token, address [] calldata _to, uint256 [] calldata _id) public {
		require(_to. length == _id.length, "Receivers and IDs are different length"); 
		for (uint256 i = 0; i<_to.length; i++) {
			_token.safeTransferFrom(msg.sender, _to[i], _id[i]);
		}
	}
}

// interface IERC721 {
//   function safeTransferFrom(address from, address to, uint256 tokenId) external;
// }

// contract BulkAirdrop {

//   function bulkAirdropERC721(IERC721 _token, address[] calldata _to, uint256[] calldata _id) public {
//     require(_to.length == _id.length, "Receivers and IDs are different length");
//     for (uint256 i = 0; i < _to.length; i++) {
//       _token.safeTransferFrom(msg.sender, _to[i], _id[i]);
//     }
//   }

// }